#!/usr/bin/env python3
"""BGM 入库构建工具：把音乐模型产出的短曲剪成可无缝循环的正式 BGM。

输入：音乐模型生成的原始音频（mp3 / wav，任意采样率）。
输出：符合 doc/sfx_asset_manifest.md §3 规范的正式 BGM
      —— 48kHz / 立体声 / MP3 128kbps / 峰值 ≤ -1dBFS / 时长落在 60~120s。

处理链路：
  1. 包络分析 → 定位「正文起点」与「正文终点」（跳过淡入 intro 与尾部 fade-out / 衰减）
  2. 无缝循环单元：把尾巴 C 秒与开头 C 秒做等功率交叉淡化，
     单元首尾相接处采样连续（循环点无爆音、无停顿）
  3. 按目标时长重复单元（每个接缝都落在设计好的连续点上）
  4. EBU R128 两遍响度归一（默认 -16 LUFS / TP -1.5dBTP），再编码入库

用法：
    python3 tools/build_bgm_loop.py --src <原始音频> --out <正式 BGM 路径> \
        [--target 90] [--crossfade 2.5] [--loudness -16] [--bitrate 128k]
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

SR = 48000
FRAME = 0.05  # 包络分析帧长（秒）


# --------------------------------------------------------------------------- #
# ffmpeg / ffprobe 封装
# --------------------------------------------------------------------------- #
def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def probe_duration(path: Path) -> float:
    res = run([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(path),
    ])
    return float(res.stdout.strip())


def decode_pcm(path: Path) -> np.ndarray:
    """解码为 48kHz 双声道 float32。"""
    res = subprocess.run(
        ["ffmpeg", "-v", "quiet", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
        capture_output=True,
    )
    return np.frombuffer(res.stdout, dtype=np.float32).reshape(-1, 2)


def envelope(mono: np.ndarray) -> np.ndarray:
    """50ms 帧 RMS（dB）。"""
    hop = int(SR * FRAME)
    n = len(mono) // hop
    if n == 0:
        return np.zeros(0)
    frames = mono[: n * hop].reshape(n, hop)
    rms = np.sqrt((frames.astype(np.float64) ** 2).mean(axis=1) + 1e-12)
    return 20 * np.log10(rms + 1e-12)


def moving_avg(x: np.ndarray, win: int) -> np.ndarray:
    if win <= 1 or x.size < win:
        return x
    kernel = np.ones(win) / win
    return np.convolve(x, kernel, mode="same")






def detect_body(env: np.ndarray, min_len_s: float = 12.0) -> tuple[int, int]:
    """定位循环正文区间（帧索引）。

    默认不做任何取舍：整曲作为正文，只裁掉尾部「淡出到全静音」的那一段，
    避免循环时出现一段空白。其余取舍由人工试听后用 --start / --end 指定。
    """
    n = env.size
    if n < 20:
        return 0, n
    floor = float(np.percentile(env, 5))
    for i in range(n - 1, 0, -1):
        if env[i] > floor + 6.0:
            return 0, i + 1
    return 0, n


# --------------------------------------------------------------------------- #
# 构建
# --------------------------------------------------------------------------- #
def build_unit(src: Path, dst: Path, start_s: float, end_s: float, crossfade: float) -> float:
    """把 src[start_s:end_s] 剪成无缝循环单元 → dst（48kHz WAV）。返回单元时长。"""
    length = end_s - start_s
    c = min(crossfade, length / 3.0)
    if c < 0.8:
        raise ValueError(f"正文太短（{length:.2f}s），无法做 {crossfade}s 交叉淡化")

    graph = (
        f"[0:a]atrim=start={start_s:.4f}:end={end_s:.4f},asetpts=PTS-STARTPTS[body];"
        f"[body]asplit=3[b1][b2][b3];"
        f"[b1]atrim=start=0:end={c:.4f},asetpts=PTS-STARTPTS[head];"
        f"[b2]atrim=start={c:.4f}:end={length - c:.4f},asetpts=PTS-STARTPTS[mid];"
        f"[b3]atrim=start={length - c:.4f}:end={length:.4f},asetpts=PTS-STARTPTS[tail];"
        f"[tail][head]acrossfade=d={c:.4f}:c1=qsin:c2=qsin[seam];"
        f"[seam][mid]concat=n=2:v=0:a=1[out]"
    )
    res = run([
        "ffmpeg", "-y", "-v", "error", "-i", str(src),
        "-filter_complex", graph, "-map", "[out]",
        "-ar", str(SR), "-ac", "2", "-c:a", "pcm_s16le", str(dst),
    ])
    if res.returncode != 0:
        raise RuntimeError(f"构建循环单元失败：\n{res.stderr}")
    return length - c


def repeat_unit(unit: Path, dst: Path, times: int) -> None:
    """把单元重复 times 次 → dst（48kHz WAV）。"""
    inputs: list[str] = []
    for _ in range(times):
        inputs += ["-i", str(unit)]
    chains = "".join(f"[{i}:a]" for i in range(times))
    graph = f"{chains}concat=n={times}:v=0:a=1[out]"
    res = run([
        "ffmpeg", "-y", "-v", "error", *inputs,
        "-filter_complex", graph, "-map", "[out]",
        "-ar", str(SR), "-ac", "2", "-c:a", "pcm_s16le", str(dst),
    ])
    if res.returncode != 0:
        raise RuntimeError(f"拼接重复失败：\n{res.stderr}")


def loudnorm_two_pass(src: Path, dst: Path, target_lufs: float, bitrate: str) -> None:
    """EBU R128 两遍响度归一 → MP3 入库格式。"""
    tp = -1.5
    lra = 11.0
    probe = run([
        "ffmpeg", "-hide_banner", "-i", str(src),
        "-af", f"loudnorm=I={target_lufs}:TP={tp}:LRA={lra}:print_format=json",
        "-f", "null", "-",
    ])
    match = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", probe.stderr, re.S)
    if not match:
        raise RuntimeError("响度测量失败：\n" + probe.stderr[-2000:])
    m = json.loads(match.group(0))
    filt = (
        f"loudnorm=I={target_lufs}:TP={tp}:LRA={lra}"
        f":measured_I={m['input_i']}:measured_LRA={m['input_lra']}"
        f":measured_TP={m['input_tp']}:measured_thresh={m['input_thresh']}"
        f":offset={m.get('target_offset', 0.0)}:linear=true:print_format=summary"
    )
    res = run([
        "ffmpeg", "-y", "-v", "error", "-i", str(src), "-af", filt,
        "-ar", str(SR), "-ac", "2", "-c:a", "libmp3lame", "-b:a", bitrate, str(dst),
    ])
    if res.returncode != 0:
        raise RuntimeError(f"编码失败：\n{res.stderr}")


# --------------------------------------------------------------------------- #
# 客观体检
# --------------------------------------------------------------------------- #
def seam_check(path: Path) -> dict:
    """检查循环接缝是否连续：回绕点的相邻采样跳变 vs 曲内典型跳变。"""
    pcm = decode_pcm(path)
    mono = pcm.mean(axis=1)
    diff = np.abs(np.diff(mono))
    typical = float(np.median(diff)) or 1e-9
    # 回绕点 = 末尾最后采样 → 开头第一个采样
    wrap = float(abs(mono[0] - mono[-1]))
    p95 = float(np.percentile(diff, 95))
    return {
        "wrap_jump": round(wrap, 6),
        "median_jump": round(typical, 6),
        "p95_jump": round(p95, 6),
        "ratio_vs_median": round(wrap / typical, 1) if typical else None,
        "ratio_vs_p95": round(wrap / p95, 2) if p95 else None,
        "seam_ok": bool(wrap <= p95),
    }


def peak_db(path: Path) -> float:
    res = run(["ffmpeg", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"])
    m = re.search(r"max_volume:\s*(-?\d+(?:\.\d+)?) dB", res.stderr)
    return float(m.group(1)) if m else float("nan")


def clipped_samples(path: Path) -> int:
    """统计连续满幅采样（削波）数量。"""
    pcm = decode_pcm(path)
    sat = np.abs(pcm) >= 0.999
    return int(np.sum(np.all(sat, axis=1)))


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="BGM 无缝循环入库构建")
    ap.add_argument("--src", required=True, type=Path, help="原始音频（模型产出）")
    ap.add_argument("--out", required=True, type=Path, help="正式 BGM 输出路径（.mp3）")
    ap.add_argument("--target", type=float, default=90.0, help="目标时长（秒）")
    ap.add_argument("--crossfade", type=float, default=2.5, help="交叉淡化长度（秒）")
    ap.add_argument("--loudness", type=float, default=-16.0, help="目标响度（LUFS）")
    ap.add_argument("--bitrate", default="128k", help="MP3 码率")
    ap.add_argument("--start", type=float, default=None, help="正文起点（秒）；缺省=整曲起点")
    ap.add_argument("--end", type=float, default=None, help="正文终点（秒）；缺省=自动裁掉尾部淡出")
    ap.add_argument("--keep-temp", action="store_true", help="保留中间 WAV")
    args = ap.parse_args()

    src: Path = args.src
    out: Path = args.out
    if not src.exists():
        print(f"[失败] 找不到源文件：{src}", file=sys.stderr)
        return 1

    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="bgm_build_"))
    unit_wav = tmp / "unit.wav"
    full_wav = tmp / "full.wav"

    # 1) 正文区间：默认整曲，只裁掉尾部淡出到静音的一段
    pcm = decode_pcm(src)
    total = probe_duration(src)
    env = envelope(pcm.mean(axis=1))
    auto_start, auto_end = detect_body(env)
    start_s = args.start if args.start is not None else auto_start * FRAME
    end_s = args.end if args.end is not None else auto_end * FRAME
    start_s = max(0.0, min(start_s, total - 1.0))
    end_s = max(start_s + args.crossfade * 3, min(end_s, total))
    print(f"[分析] {src.name}")
    print(f"       总时长 {total:.2f}s ｜ 循环正文 {start_s:.2f}s ~ {end_s:.2f}s"
          f"（{'' if args.start is None else '起点为指定值；'}"
          f"{'' if args.end is None else '终点为指定值；'}"
          f"尾部淡出裁掉 {total - end_s:.2f}s）")

    # 2) 无缝循环单元
    unit_len = build_unit(src, unit_wav, start_s, end_s, args.crossfade)
    print(f"       循环单元 {unit_len:.2f}s（交叉淡化 {min(args.crossfade, unit_len / 3):.2f}s）")

    # 3) 重复到目标时长
    times = max(1, int(round(args.target / unit_len)))
    if times * unit_len > 120.0:  # 规范上限
        times = max(1, times - 1)
    if times * unit_len < 60.0:  # 规范下限
        times = max(times, int(np.ceil(60.0 / unit_len)))
    repeat_unit(unit_wav, full_wav, times)
    print(f"       重复 {times} 次 → {times * unit_len:.2f}s")

    # 4) 响度归一 + 编码
    loudnorm_two_pass(full_wav, out, args.loudness, args.bitrate)

    # 5) 客观体检
    dur = probe_duration(out)
    pk = peak_db(out)
    clip = clipped_samples(out)
    seam = seam_check(out)
    probe = run([
        "ffprobe", "-v", "error", "-show_entries",
        "stream=codec_name,sample_rate,channels,bit_rate", "-of", "default=noprint_wrappers=1", str(out),
    ]).stdout.strip().replace("\n", " ")

    print(f"[输出] {out}")
    print(f"       {probe}")
    print(f"       时长 {dur:.2f}s ｜ 峰值 {pk:.2f} dBFS ｜ 削波采样 {clip}")
    print(f"       循环接缝：回绕跳变 {seam['wrap_jump']} / 曲内 P95 {seam['p95_jump']}"
          f" → {'连续 OK' if seam['seam_ok'] else '不连续，需检查'}")

    if not args.keep_temp:
        for f in tmp.glob("*"):
            f.unlink()
        tmp.rmdir()
    return 0


if __name__ == "__main__":
    sys.exit(main())
