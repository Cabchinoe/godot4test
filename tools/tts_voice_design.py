#!/usr/bin/env python3
"""
MiniMax 音色设计（Voice Design）客户端：POST /v1/voice_design

用一段自然语言描述造出一个专属音色，产出可直接用于 T2A v2 的 voice_id。
与「从 303 个系统音色里挑」的本质区别：系统音色是通用播音/角色声库，
设计目标是"什么场景都能用"，因此都偏播报腔；音色设计是按角色定制的专属声线。

一次只设计一个音色、只产出一条试听，供人工筛选。

用法:
    export MINIMAX_API_KEY=sk-xxxx
    python3 tools/tts_voice_design.py --preset A
    python3 tools/tts_voice_design.py --prompt "..." --text "试听文本" --voice-id benny_x
"""
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

ENDPOINTS = ["https://api.minimax.cn/v1/voice_design",
             "https://api-bj.minimaxi.com/v1/voice_design"]
REGISTRY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voice_registry.json")
PROMPTS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voice_prompts_benny.json")


def post(endpoint, api_key, payload, timeout=180):
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def design(api_key, prompt, preview_text, voice_id=None, endpoints=None):
    payload = {"prompt": prompt, "preview_text": preview_text}
    if voice_id:
        payload["voice_id"] = voice_id

    last = None
    for attempt in range(6):
        ep = (endpoints or ENDPOINTS)[attempt % len(endpoints or ENDPOINTS)]
        try:
            data = post(ep, api_key, payload)
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "ignore")[:200]
            print(f"  ! HTTP {e.code}: {body}", flush=True)
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(min(15 * (attempt + 1), 60))
                continue
            return None
        except Exception as e:
            print(f"  ! 请求异常: {e}", flush=True)
            time.sleep(10)
            continue

        br = data.get("base_resp") or {}
        code = br.get("status_code")
        if code == 0:
            return data
        msg = br.get("status_msg", "")
        print(f"  ! status_code={code} {msg}", flush=True)
        if code in (1002, 1039):      # 限流
            time.sleep(min(20 * (attempt + 1), 90))
            continue
        if code == 1008:              # 余额不足
            print("  x 余额不足", flush=True)
            return None
        if code == 2013:              # 参数异常
            return None
        last = data
        time.sleep(8)
    return last


def load_registry():
    try:
        with open(REGISTRY, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {"voices": []}


def save_registry(reg):
    with open(REGISTRY, "w", encoding="utf-8") as f:
        json.dump(reg, f, ensure_ascii=False, indent=1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", help="从 voice_prompts_benny.json 取预设描述")
    ap.add_argument("--prompt", help="直接传描述（覆盖 --preset）")
    ap.add_argument("--text", help="试听文本（覆盖预设）")
    ap.add_argument("--voice-id", help="自定义 voice_id（8-256 字符，首字符为字母）")
    ap.add_argument("--out", default="Art/audio/sfx/_review")
    ap.add_argument("--tag", default="", help="文件名前缀标签，默认用 preset")
    args = ap.parse_args()

    api_key = os.environ.get("MINIMAX_API_KEY", "").strip()
    if not api_key:
        print("错误：请设置环境变量 MINIMAX_API_KEY", file=sys.stderr)
        return 2

    prompt, text, tag = args.prompt, args.text, args.tag
    if not prompt:
        if not args.preset:
            print("错误：需要 --preset 或 --prompt", file=sys.stderr)
            return 2
        with open(PROMPTS_FILE, encoding="utf-8") as f:
            presets = json.load(f)
        if args.preset not in presets:
            print(f"错误：预设不存在，可选: {list(presets)}", file=sys.stderr)
            return 2
        p = presets[args.preset]
        prompt = p["prompt"]
        text = text or p.get("preview_text")
        tag = tag or args.preset

    os.makedirs(args.out, exist_ok=True)
    print(f"=== 音色设计 · {tag or 'custom'} ===", flush=True)
    print(f"描述: {prompt[:120]}...", flush=True)
    print(f"试听: {text}", flush=True)

    data = design(api_key, prompt, text, args.voice_id)
    if not data:
        print("x 音色设计失败", flush=True)
        return 1

    vid = data.get("voice_id")
    trial = data.get("trial_audio")
    print(f"\nvoice_id = {vid}", flush=True)
    if not trial:
        print("! 未返回试听音频", flush=True)
        return 1

    name = f"voice_design_{tag or 'custom'}.flac"
    dest = os.path.join(args.out, name)
    with open(dest, "wb") as f:
        f.write(bytes.fromhex(trial))

    reg = load_registry()
    reg["voices"] = [v for v in reg["voices"] if v.get("tag") != tag]
    reg["voices"].append({
        "tag": tag or "custom",
        "voice_id": vid,
        "prompt": prompt,
        "preview_text": text,
        "file": name,
        "created": time.strftime("%Y-%m-%d %H:%M:%S"),
    })
    save_registry(reg)

    dur = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", dest], capture_output=True, text=True)
    sr = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=sample_rate,channels",
                         "-of", "csv=p=0", dest], capture_output=True, text=True)
    print(f"试听已保存: {dest}", flush=True)
    print(f"时长 {dur.stdout.strip()}s · 规格 {sr.stdout.strip()}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
