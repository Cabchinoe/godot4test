#!/usr/bin/env python3
"""
MiniMax T2A v2 语音合成客户端（speech-2.8-hd / 2.6-hd / 02-hd …）。

相对初版的优化：
  1. 端点自动回退：api.minimax.cn 失败时自动切 api-bj.minimaxi.com
  2. 自适应限速：按官方 RPM（免费 10 / 充值 20）调度，命中 1002/1039 自动降速
  3. 断点续跑：已产出文件跳过，.tts_cache 记录 node_id，重跑不重复计费
  4. 语气词标签守卫：非 2.8 模型自动剥离，避免被当正文念出
  5. 可选响度归一（ffmpeg loudnorm），消除不同情绪/音色间 10dB 级电平差
  6. 输出索引 index.json，便于批量核对

用法:
    export MINIMAX_API_KEY=sk-xxxx
    python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review
    python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review --voice-preset tools/tts_voice_benny_selected.json
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

ENDPOINTS = [
    "https://api-bj.minimaxi.com/v1/t2a_v2",
    "https://api.minimaxi.com/v1/t2a_v2",
    "https://api.minimax.cn/v1/t2a_v2",
]
CACHE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".tts_cache.json")

ERR_RATE_LIMIT = {1002, 1039}
ERR_AUTH = {1004}
ERR_BAD_PARAM = {2013}
ERR_ILLEGAL_CHAR = {1042}
SUPPORTED_MODELS = [
    "speech-2.8-hd", "speech-2.8-turbo",
    "speech-2.6-hd", "speech-2.6-turbo",
    "speech-02-hd", "speech-02-turbo",
    "speech-01-hd", "speech-01-turbo",
]


# ---------------------------------------------------------------- utilities
def load_cache():
    try:
        with open(CACHE_PATH, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_cache(cache):
    with open(CACHE_PATH, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=1)


def run(cmd, timeout=300):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


# ---------------------------------------------------------------- request
def build_text(item, model):
    """拼装送入模型的文本。语气词标签仅 speech-2.8-* 生效，低版本自动剥离。"""
    text = item.get("text", "").strip()
    tags = item.get("tags", "")
    if tags:
        if "2.8" in model:
            text = f"{tags} {text}"
        else:
            print(f"    ! 模型 {model} 不支持语气词标签，已忽略 {tags}", flush=True)
    pause = item.get("pause_after")
    if pause:
        text = f"{text}<#{float(pause):.2f}#>"
    return text


def build_payload(item, model):
    payload = {
        "model": model,
        "text": build_text(item, model),
        "stream": False,
        "output_format": "hex",
        "voice_setting": {
            "voice_id": item.get("voice_id", "Chinese (Mandarin)_Crisp_Girl"),
            "speed": item.get("speed", 1.0),
            "vol": item.get("vol", 1.0),
            "pitch": item.get("pitch", 0),
        },
        "audio_setting": {
            "sample_rate": item.get("sample_rate", 44100),
            "bitrate": item.get("bitrate", 256000),
            "format": item.get("format", "flac"),
            "channel": item.get("channel", 1),
        },
    }
    if item.get("emotion"):
        payload["voice_setting"]["emotion"] = item["emotion"]
    if item.get("timbre_weights"):
        # 混合音色：官方要求同时把 voice_id 置空，最多 4 个音色按权重融合
        payload["timbre_weights"] = item["timbre_weights"]
        payload["voice_setting"]["voice_id"] = item.get("voice_id", "")
    if item.get("pronunciation"):
        payload["pronunciation_dict"] = {"tone": item["pronunciation"]}
    if item.get("voice_modify"):
        payload["voice_modify"] = item["voice_modify"]
    if item.get("text_normalization_mode"):
        payload["text_normalization_mode"] = item["text_normalization_mode"]
    if item.get("subtitle_enable"):
        payload["subtitle_enable"] = True
        payload["subtitle_type"] = item.get("subtitle_type", "word")
    return payload


def post_json(endpoint, api_key, payload, timeout=120):
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


# ---------------------------------------------------------------- engine
class Engine:
    """持有当前可用端点与限速状态，遇 1002/1039 自动退避。"""

    def __init__(self, api_key, rpm, endpoints=None):
        self.api_key = api_key
        self.endpoints = list(endpoints or ENDPOINTS)
        self.endpoint = self.endpoints[0]
        self.interval = 60.0 / max(1, rpm)
        self.min_interval = 60.0 / 20
        self.max_interval = 60.0 / 4
        self.consecutive_ok = 0

    def _rotate_endpoint(self):
        if len(self.endpoints) > 1 and self.endpoint in self.endpoints:
            nxt = self.endpoints[(self.endpoints.index(self.endpoint) + 1) % len(self.endpoints)]
            if nxt != self.endpoint:
                print(f"    ~ 切换端点 -> {nxt}", flush=True)
                self.endpoint = nxt

    def penalize(self):
        self.interval = min(self.interval * 1.6, self.max_interval)
        self.consecutive_ok = 0
        print(f"    ~ 降速至 {self.interval:.1f}s/条", flush=True)

    def reward(self):
        self.consecutive_ok += 1
        if self.consecutive_ok >= 3 and self.interval > self.min_interval:
            self.interval = max(self.min_interval, self.interval * 0.85)
            self.consecutive_ok = 0

    def synthesize(self, item, model, attempt=0):
        payload = build_payload(item, model)
        try:
            data = post_json(self.endpoint, self.api_key, payload)
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "ignore")[:200]
            if e.code in (401, 403):
                print(f"    x 鉴权失败 HTTP {e.code}", flush=True)
                return None
            if e.code in (404, 502, 503, 504):
                self._rotate_endpoint()
            print(f"    ! HTTP {e.code}: {body}", flush=True)
            if attempt < 5:
                time.sleep(min(10 * (attempt + 1), 60))
                return self.synthesize(item, model, attempt + 1)
            return None
        except Exception as e:
            self._rotate_endpoint()
            print(f"    ! 请求异常: {e}", flush=True)
            if attempt < 5:
                time.sleep(10)
                return self.synthesize(item, model, attempt + 1)
            return None

        br = data.get("base_resp") or {}
        code = br.get("status_code")
        if code == 0:
            self.reward()
            return data

        msg = br.get("status_msg", "")
        if code in ERR_RATE_LIMIT:
            self.penalize()
            wait = min(20 * (attempt + 1), 90)
            print(f"    ~ 限流({code})，{wait}s 后重试", flush=True)
            time.sleep(wait)
            return self.synthesize(item, model, attempt + 1)
        if code in ERR_AUTH:
            print("    x 鉴权失败：检查 API Key 与账户状态", flush=True)
            return None
        if code in ERR_BAD_PARAM or code in ERR_ILLEGAL_CHAR:
            print(f"    x 参数/字符问题 ({code}) {msg}，条目: {item.get('line_id')}", flush=True)
            return None
        print(f"    ! status_code={code} {msg}", flush=True)
        if attempt < 3:
            time.sleep(10)
            return self.synthesize(item, model, attempt + 1)
        return None


# ---------------------------------------------------------------- output
def normalize_loudness(path, target=-16):
    """统一响度，消除不同音色/情绪间的电平差。"""
    if not shutil.which("ffmpeg"):
        return None
    tmp = path + ".norm"
    p = run(["ffmpeg", "-y", "-i", path, "-af", f"loudnorm=I={target}:TP=-1.5:LRA=11",
             "-ar", "44100", "-c:a", "flac", tmp], timeout=300)
    if p.returncode == 0 and os.path.exists(tmp) and os.path.getsize(tmp) > 1000:
        os.replace(tmp, path)
        return True
    if os.path.exists(tmp):
        os.remove(tmp)
    return None


def write_audio(data, out_dir, item, model, normalize=False):
    hex_audio = ((data.get("data") or {}).get("audio")) or ""
    if not hex_audio:
        print("    ! 返回中无音频", flush=True)
        return None
    raw = bytes.fromhex(hex_audio)
    ext = os.path.splitext(item.get("output", ""))[1] or ".flac"
    name = os.path.splitext(item.get("output") or item.get("line_id", "line"))[0] + ext
    dest = os.path.join(out_dir, name)
    with open(dest, "wb") as f:
        f.write(raw)

    if normalize:
        normalize_loudness(dest)

    extra = data.get("extra_info") or {}
    meta = {
        "line_id": item.get("line_id"),
        "model": model,
        "file": name,
        "duration_ms": extra.get("audio_length"),
        "sample_rate": extra.get("audio_sample_rate"),
        "bitrate": extra.get("bitrate"),
        "format": extra.get("audio_format"),
        "channel": extra.get("audio_channel"),
        "usage_characters": extra.get("usage_characters"),
        "trace_id": data.get("trace_id"),
        "request_text": build_text(item, model),
        "note": item.get("_note", ""),
    }
    with open(dest + ".json", "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    return meta


# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("--out", default="Art/audio/sfx/_review")
    ap.add_argument("--model", default="speech-2.8-hd", choices=SUPPORTED_MODELS)
    ap.add_argument("--rpm", type=int, default=20, help="目标每分钟请求数（官方免费 10 / 充值 20）")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--normalize", action="store_true", help="产出后统一响度到 -16 LUFS")
    ap.add_argument("--limit", type=int, default=0, help="只跑前 N 条")
    ap.add_argument("--voice-preset", help="声线预设 JSON（voice_id / pitch / timbre_weights）")
    args = ap.parse_args()

    api_key = os.environ.get("MINIMAX_API_KEY", "").strip()
    if not api_key:
        print("错误：请设置环境变量 MINIMAX_API_KEY", file=sys.stderr)
        return 2

    with open(args.manifest, encoding="utf-8") as f:
        items = json.load(f)
    if isinstance(items, dict):
        items = items.get("lines", [])
    if args.limit:
        items = items[:args.limit]
    voice_preset = {}
    if args.voice_preset:
        with open(args.voice_preset, encoding="utf-8") as f:
            voice_preset = json.load(f)

    os.makedirs(args.out, exist_ok=True)
    engine = Engine(api_key, args.rpm)
    cache = load_cache()
    index = []
    ok = fail = 0
    total = len(items)
    t0 = time.time()

    for i, item in enumerate(items, 1):
        if voice_preset:
            item = dict(item)
            item["voice_id"] = voice_preset.get("voice_id", "")
            item["pitch"] = voice_preset.get("pitch", item.get("pitch", 0))
            if voice_preset.get("timbre_weights"):
                item["timbre_weights"] = voice_preset["timbre_weights"]
            if voice_preset.get("voice_modify") and not item.get("voice_modify"):
                item["voice_modify"] = voice_preset["voice_modify"]
        line_id = item.get("line_id", f"line_{i}")
        ext = os.path.splitext(item.get("output", ""))[1] or ".flac"
        name = os.path.splitext(item.get("output") or line_id)[0] + ext
        dest = os.path.join(args.out, name)
        meta_path = dest + ".json"

        if os.path.exists(dest) and os.path.getsize(dest) > 1000 and not args.force:
            print(f"[{i}/{total}] {name} 跳过（已存在）", flush=True)
            if os.path.exists(meta_path):
                try:
                    with open(meta_path, encoding="utf-8") as f:
                        index.append(json.load(f))
                    ok += 1
                    continue
                except Exception:
                    pass
            continue

        print(f"[{i}/{total}] {name}", flush=True)
        data = engine.synthesize(item, args.model)
        if data:
            meta = write_audio(data, args.out, item, args.model, args.normalize)
            if meta:
                cache[f"{args.model}:{line_id}:{item.get('request_text', item.get('text'))}"] = \
                    (data.get("data") or {}).get("audio", "")[:0] or "ok"
                save_cache(cache)
                index.append(meta)
                ok += 1
                print(f"    + {meta.get('duration_ms')}ms  {meta.get('sample_rate')}Hz  "
                      f"{meta.get('format')}  {meta.get('usage_characters')}字", flush=True)
        else:
            fail += 1
        if i < total:
            time.sleep(engine.interval)

    index_path = os.path.join(args.out, "index.json")
    try:
        with open(index_path, encoding="utf-8") as f:
            old = json.load(f)
    except Exception:
        old = []
    known = {m.get("file") for m in old}
    merged = old + [m for m in index if m.get("file") not in known]
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=1)

    dt = time.time() - t0
    print(f"\n=== 成功 {ok} / 失败 {fail}，耗时 {dt:.0f}s，输出目录 {args.out} ===", flush=True)
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
