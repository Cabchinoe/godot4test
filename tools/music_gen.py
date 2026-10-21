#!/usr/bin/env python3
"""音乐生成模型调用工具 —— MiniMax 音乐生成（两条通路）。

通路 A（默认，Connector 代理，无需 API Key）：
    mcode-tools connector call connector__matrix__batch_text_to_music
    → 返回 node_id → mcode-tools get_asset_url → curl 落盘
    限制：prompt ≤300 字符、单次 ≤5 条、**没有 is_instrumental 开关**

通路 B（--direct，官方 API 直连，需 MINIMAX_API_KEY）：
    POST https://api.minimax.cn/v1/music_generation
    优势：prompt 1~2000 字符、**is_instrumental 硬开关（治人声）**、可指定 model
    详见 doc/music_generation.md

用法：
    # 一次最多 5 条（每条一个 --prompt，可给不同变体）
    python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw \
        --prompt "Instrumental. ..." \
        --prompt "Instrumental. ..."

    # 从 JSON 读（{"requests":[{"prompt":"...","output_file":"x.wav"}, ...]}）
    python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw --requests reqs.json

    # 生成后直接转成入库规格 MP3（48kHz/立体声/128k/-16 LUFS/TP-1.5，顺带消除削波）
    python3 tools/music_gen.py --out-dir ... --prompt "..." --to-mp3

    # 生成后剪成 N 秒无缝循环（复用 tools/build_bgm_loop.py）
    python3 tools/music_gen.py --out-dir ... --prompt "..." --loop 90

    # 官方直连（无人声硬开关）
    MINIMAX_API_KEY=sk-xxx python3 tools/music_gen.py --out-dir ... \
        --direct --model music-3.0 --prompt "Instrumental. ..." --to-mp3

产出：
    <out-dir>/<output_file>            模型原始产出（wav）
    <out-dir>/<output_file>.mp3        --to-mp3 时的入库规格成品
    <out-dir>/music_gen_manifest.json  node_id / 时长 / 峰值 / 削波 / 落盘路径
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

TOOL = "connector__matrix__batch_text_to_music"
PROMPT_MIN, PROMPT_MAX = 10, 300
# 官方直连（--direct）的限制：prompt 1~2000 字符
DIRECT_PROMPT_MIN, DIRECT_PROMPT_MAX = 1, 2000
MAX_REQUESTS = 5
DOWNLOAD_RETRIES = 3
CALL_TIMEOUT = 600

# 官方音乐生成 API 端点（与 tools/tts_minimax.py 同款回退顺序：国内优先，再华北，最后国际）
DIRECT_ENDPOINTS = [
    "https://api.minimax.cn/v1/music_generation",
    "https://api-bj.minimaxi.com/v1/music_generation",
    "https://api.minimax.io/v1/music_generation",
]
DIRECT_MODELS = ["music-3.0", "music-2.6", "music-cover",
                 "music-3.0-free", "music-2.6-free", "music-cover-free"]


# --------------------------------------------------------------------------- #
# 外部命令
# --------------------------------------------------------------------------- #
def run(cmd: list[str], timeout: int = 120) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


def build_requests(prompts: list[str], fmt: str, sample_rate: int,
                   bitrate: int, pmin: int = PROMPT_MIN,
                   pmax: int = PROMPT_MAX) -> tuple[list[dict], list[str]]:
    """组装 requests[]，同时做字符数校验。返回 (requests, 错误列表)。"""
    errors: list[str] = []
    if not prompts:
        errors.append("至少要给一条 --prompt")
    if len(prompts) > MAX_REQUESTS:
        errors.append(f"单次最多 {MAX_REQUESTS} 条，收到 {len(prompts)} 条")
    requests = []
    for i, p in enumerate(prompts):
        p = p.strip()
        if not (pmin <= len(p) <= pmax):
            errors.append(
                f"第 {i+1} 条 prompt 长度 {len(p)} 不在 {pmin}~{pmax}："
                f"{'过长' if len(p) > pmax else '过短'} —— 接口硬限制，需压缩措辞"
            )
            continue
        requests.append({
            "prompt": p,
            "format": fmt,
            "sample_rate": sample_rate,
            "bitrate": bitrate,
            "output_file": f"cand_{i+1:02d}.{fmt}",
        })
    return requests, errors


def call_connector(requests: list[dict], args_path: Path) -> dict:
    args_path.write_text(json.dumps({"requests": requests}, ensure_ascii=False, indent=2))
    res = run(["mcode-tools", "connector", "call", TOOL, "--args-file", str(args_path)],
              timeout=CALL_TIMEOUT)
    if res.returncode != 0:
        raise RuntimeError(f"connector 调用失败（exit {res.returncode}）：\n{res.stderr[-2000:]}")
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"connector 返回不是合法 JSON：\n{res.stdout[:2000]}") from exc


def download(node_id: str, dest: Path) -> tuple[bool, str]:
    """取临时直链并下载。get_asset_url 偶发失败，重试。"""
    for attempt in range(DOWNLOAD_RETRIES):
        res = run(["mcode-tools", "get_asset_url", node_id])
        try:
            url = json.loads(res.stdout)["download_url"]
        except Exception:
            if attempt == DOWNLOAD_RETRIES - 1:
                return False, f"取下载直链失败：{res.stderr or res.stdout}"[:300]
            time.sleep(3)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dl = run(["curl", "-sL", "--fail", url, "-o", str(dest)], timeout=300)
        if dl.returncode == 0 and dest.exists() and dest.stat().st_size > 0:
            return True, ""
        if attempt == DOWNLOAD_RETRIES - 1:
            return False, f"下载失败（curl exit {dl.returncode}）"
        time.sleep(3)
    return False, "下载失败"


# --------------------------------------------------------------------------- #
# 官方直连（--direct）：POST /v1/music_generation
# --------------------------------------------------------------------------- #
def call_direct_api(prompt: str, api_key: str, model: str, fmt: str,
                    sample_rate: int, bitrate: int,
                    instrumental: bool) -> bytes:
    """直连官方音乐生成 API，返回解码后的音频字节。

    官方接口与 Connector 包装层的关键差别：
      · 有 `is_instrumental` 硬开关（Connector 没暴露）—— 这是"无人声"能治本的字段
      · prompt 允许 1~2000 字符（Connector 只给 300）
    """
    import urllib.error
    import urllib.request

    payload = {
        "model": model,
        "prompt": prompt,
        "is_instrumental": instrumental,
        "audio_setting": {
            "sample_rate": sample_rate,
            "bitrate": bitrate,
            "format": fmt,
        },
    }
    body = json.dumps(payload).encode("utf-8")
    errors: list[str] = []
    for endpoint in DIRECT_ENDPOINTS:
        req = urllib.request.Request(
            endpoint, data=body, method="POST",
            headers={"Authorization": f"Bearer {api_key}",
                     "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=CALL_TIMEOUT) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            errors.append(f"{endpoint} → HTTP {e.code}: {e.read()[:400].decode('utf-8', 'replace')}")
            continue
        except Exception as e:                       # 网络抖动 / 端点不可达 → 试下一个
            errors.append(f"{endpoint} → {e}")
            continue

        base = data.get("base_resp") or {}
        if base.get("status_code") not in (0, None):
            errors.append(f"{endpoint} → {base.get('status_code')} {base.get('status_msg')}")
            continue
        audio = (data.get("data") or {}).get("audio")
        if not audio:
            errors.append(f"{endpoint} → 返回里没有 data.audio：{json.dumps(data)[:400]}")
            continue
        # data.audio 是 hex 编码
        return bytes.fromhex(audio)
    raise RuntimeError("所有端点都失败：\n" + "\n".join(errors))


def unique_path(dest: Path) -> Path:
    """避免覆盖已有文件。

    多轮生成常落在同一个 _raw/ 目录，模型给的 output_file 名字会重复
    （cand_01.wav / cand_02.wav …）。直接写会把上一轮的候选冲掉，
    所以这里加数字后缀另存。
    """
    if not dest.exists():
        return dest
    stem, suffix = dest.stem, dest.suffix
    i = 2
    while True:
        cand = dest.with_name(f"{stem}_{i}{suffix}")
        if not cand.exists():
            return cand
        i += 1


# --------------------------------------------------------------------------- #
# 客观体检（只测客观参数，不评价音乐内容）
# --------------------------------------------------------------------------- #
def probe(path: Path) -> dict:
    import numpy as np
    from build_bgm_loop import clipped_samples, decode_pcm, peak_db, probe_duration
    pcm = decode_pcm(path)
    return {
        "duration_s": round(probe_duration(path), 2),
        "peak_dbfs": peak_db(path),
        "clipped_samples": clipped_samples(path),
        "sample_rate": 48000,
        "channels": 2,
        "peak_samples": int(np.max(np.abs(pcm))),
    }


def to_mp3(src: Path, dst: Path) -> None:
    """转成入库规格 MP3：48kHz / 立体声 / 128kbps / -16 LUFS / TP -1.5 dBTP。
    loudnorm 同时消除模型输出的削波（模型普遍顶到 -0.0 dBFS）。"""
    from build_bgm_loop import loudnorm_two_pass
    tmp = src.with_suffix(".norm.wav")
    run(["ffmpeg", "-y", "-v", "error", "-i", str(src),
         "-ar", "48000", "-ac", "2", "-c:a", "pcm_s16le", str(tmp)])
    loudnorm_two_pass(tmp, dst, -16.0, "128k")
    tmp.unlink(missing_ok=True)


def to_loop(src: Path, dst: Path, target: float) -> None:
    """剪成无缝循环（复用 tools/build_bgm_loop.py 的包络检测 + 等功率交叉淡化 + 单元重复）。"""
    import math
    import tempfile

    from build_bgm_loop import (FRAME, build_unit, decode_pcm, detect_body, envelope,
                                loudnorm_two_pass, repeat_unit)

    pcm = decode_pcm(src)
    env = envelope(pcm.mean(axis=1))
    auto_start, auto_end = detect_body(env)
    start_s, end_s = auto_start * FRAME, auto_end * FRAME

    with tempfile.TemporaryDirectory(prefix="bgm_loop_") as td:
        unit = Path(td) / "unit.wav"
        full = Path(td) / "full.wav"
        unit_len = build_unit(src, unit, start_s, end_s, 2.5)
        times = max(1, int(round(target / unit_len)))
        if times * unit_len > 120.0:          # 项目规格上限
            times = max(1, times - 1)
        if times * unit_len < 60.0:           # 项目规格下限
            times = max(times, math.ceil(60.0 / unit_len))
        repeat_unit(unit, full, times)
        loudnorm_two_pass(full, dst, -16.0, "128k")


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(
        description="调用音乐生成模型并落盘（详见 .minimax/skills/music-generation/）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--out-dir", required=True, type=Path, help="落盘目录")
    ap.add_argument("--prompt", action="append", default=[],
                    help="一条 prompt（可重复，最多 5 条）")
    ap.add_argument("--requests", type=Path, help="requests JSON 文件（与 --prompt 二选一）")
    ap.add_argument("--format", default="wav", choices=["wav", "mp3"], help="模型输出格式")
    ap.add_argument("--sample-rate", type=int, default=44100,
                    choices=[16000, 24000, 32000, 44100])
    ap.add_argument("--bitrate", type=int, default=256000,
                    choices=[32000, 64000, 128000, 256000])
    ap.add_argument("--to-mp3", action="store_true",
                    help="额外产出入库规格 MP3（48k/立体声/128k/-16 LUFS）")
    ap.add_argument("--loop", type=float, metavar="SECONDS",
                    help="额外产出 N 秒无缝循环 MP3（走 build_bgm_loop 的响度归一）")
    ap.add_argument("--direct", action="store_true",
                    help="走官方 API 直连（POST /v1/music_generation），需 MINIMAX_API_KEY；"
                         "可传 1~2000 字符 prompt，并带 is_instrumental 硬开关")
    ap.add_argument("--model", default="music-3.0", choices=DIRECT_MODELS,
                    help="官方 API 模型（仅 --direct 有效）")
    ap.add_argument("--with-lyrics", action="store_true",
                    help="官方 API 关掉 is_instrumental（允许出人声；仅 --direct 有效）")
    args = ap.parse_args()

    pmin, pmax = (DIRECT_PROMPT_MIN, DIRECT_PROMPT_MAX) if args.direct else (PROMPT_MIN, PROMPT_MAX)
    max_reqs = 1 if args.direct else MAX_REQUESTS

    if args.requests:
        raw = json.loads(args.requests.read_text())
        requests = raw["requests"] if isinstance(raw, dict) else raw
        errors: list[str] = []
        if len(requests) > max_reqs:
            errors.append(f"单次最多 {max_reqs} 条，收到 {len(requests)} 条")
        for i, r in enumerate(requests):
            n = len(r.get("prompt", ""))
            if not (pmin <= n <= pmax):
                errors.append(f"第 {i+1} 条 prompt 长度 {n} 越界（{pmin}~{pmax}）")
            r.setdefault("format", args.format)
            r.setdefault("sample_rate", args.sample_rate)
            r.setdefault("bitrate", args.bitrate)
    else:
        prompts = [p.strip() for p in args.prompt]
        errors = []
        if not prompts:
            errors.append("至少要给一条 --prompt")
        if len(prompts) > max_reqs:
            errors.append(f"单次最多 {max_reqs} 条，收到 {len(prompts)} 条")
        requests = []
        for i, p in enumerate(prompts):
            if not (pmin <= len(p) <= pmax):
                errors.append(
                    f"第 {i+1} 条 prompt 长度 {len(p)} 不在 {pmin}~{pmax}："
                    f"{'过长' if len(p) > pmax else '过短'}"
                )
                continue
            requests.append({
                "prompt": p, "format": args.format,
                "sample_rate": args.sample_rate, "bitrate": args.bitrate,
                "output_file": f"cand_{i+1:02d}.{args.format}",
            })

    if errors:
        print("[参数错误]", file=sys.stderr)
        for e in errors:
            print("  -", e, file=sys.stderr)
        return 2

    out_dir: Path = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"items": [], "failed": []}

    if args.direct:
        api_key = os.environ.get("MINIMAX_API_KEY", "").strip()
        if not api_key:
            print("[失败] --direct 需要环境变量 MINIMAX_API_KEY（见 doc/music_generation.md）",
                  file=sys.stderr)
            return 2
        print(f"[1/3] 官方 API 直连（{args.model}, {len(requests)} 条, "
              f"is_instrumental={not args.with_lyrics}）……")
        for r in requests:
            dest = unique_path(out_dir / r["output_file"])
            entry = {"prompt_chars": len(r["prompt"]), "model": args.model,
                     "is_instrumental": not args.with_lyrics, "path": str(dest)}
            try:
                audio = call_direct_api(r["prompt"], api_key, args.model, r["format"],
                                        r["sample_rate"], r["bitrate"],
                                        instrumental=not args.with_lyrics)
                dest.write_bytes(audio)
                entry["downloaded"] = True
                entry.update(probe(dest))
            except Exception as exc:
                entry["downloaded"] = False
                entry["error"] = str(exc)
                manifest["failed"].append({"prompt": r["prompt"], "error": str(exc)})
            if entry.get("downloaded"):
                if args.to_mp3:
                    mp3 = dest.with_suffix(".mp3")
                    to_mp3(dest, mp3)
                    entry["mp3_path"] = str(mp3)
                    entry["mp3"] = probe(mp3)
                if args.loop:
                    lp = dest.with_name(dest.stem + "_loop.mp3")
                    to_loop(dest, lp, args.loop)
                    entry["loop_path"] = str(lp)
                    entry["loop"] = probe(lp)
            manifest["items"].append(entry)
            print(f"      {'OK  ' if entry.get('downloaded') else 'FAIL'} {dest.name} "
                  f"({entry.get('duration_s', '-')}s, 削波 {entry.get('clipped_samples', '-')})")
    else:
        args_path = out_dir / "_music_gen_request.json"
        print(f"[1/3] 调用 {TOOL}（{len(requests)} 条）……")
        result = call_connector(requests, args_path)
        if result.get("code") != 0:
            print(f"[失败] {result.get('message')} / {result.get('error')}", file=sys.stderr)
            return 1

        success = result.get("success_items", [])
        failed = result.get("failed_items", [])
        print(f"      成功 {len(success)} / 失败 {len(failed)}")

        print("[2/3] 下载产出……")
        manifest["failed"] = failed
        for item in success:
            node_id = item.get("node_id", "")
            name = item.get("file_name") or f"cand_{node_id}.{args.format}"
            dest = unique_path(out_dir / name)
            ok, err = download(node_id, dest)
            entry = {"node_id": node_id, "file_name": name, "path": str(dest),
                     "downloaded": ok}
            if not ok:
                entry["error"] = err
            else:
                try:
                    entry.update(probe(dest))
                except Exception as exc:
                    entry["probe_error"] = str(exc)
                if args.to_mp3:
                    mp3 = dest.with_suffix(".mp3")
                    to_mp3(dest, mp3)
                    entry["mp3_path"] = str(mp3)
                    entry["mp3"] = probe(mp3)
                if args.loop:
                    lp = dest.with_name(dest.stem + "_loop.mp3")
                    to_loop(dest, lp, args.loop)
                    entry["loop_path"] = str(lp)
                    entry["loop"] = probe(lp)
            manifest["items"].append(entry)
            print(f"      {'OK  ' if ok else 'FAIL'} {name} "
                  f"({entry.get('duration_s', '-')}s, 削波 {entry.get('clipped_samples', '-')})")

    mpath = out_dir / "music_gen_manifest.json"
    mpath.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f"[3/3] manifest → {mpath}")
    ok_count = sum(1 for it in manifest["items"] if it.get("downloaded"))
    if manifest["failed"]:
        print(f"注意：{len(manifest['failed'])} 条生成失败，明细见 manifest", file=sys.stderr)
    if manifest["items"] and ok_count == 0:
        print("[失败] 全部生成失败", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.exit(main())
