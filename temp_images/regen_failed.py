#!/usr/bin/env python3
"""Regenerate the few failed masters with stricter prompts that force
darker subject colors (so rembg cannot eat the body)."""

import json
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

PROJECT_ROOT = Path("/Users/zwcn3212/Godot/test1")
RAW_DIR = PROJECT_ROOT / "temp_images" / "artwork_raw"
REM_DIR = PROJECT_ROOT / "temp_images" / "artwork_rembg"
RAW_DIR.mkdir(parents=True, exist_ok=True)
REM_DIR.mkdir(parents=True, exist_ok=True)

COMMON_DARK = (
    "Original tactical-anime 2D game asset for an original urban-night extraction game, "
    "crisp readable silhouette, anime cel-shaded style with flat color shading and clean lineart, "
    "DEEP DARK navy and dark slate metal as primary fill, charcoal gray, muted olive accents, "
    "small subtle amber practical lights only. "
    "SubJECT MUST BE DARK COLORED (very dark navy / charcoal / dark slate). "
    "Flat solid #00FF00 chroma-key background covering entire canvas behind subject, "
    "one centered subject, no text, no logo, no watermark, no ground plane, no cast shadow, "
    "no reflection, no border. "
    "Negative prompt: white background, pale colors, light tones, washed out, "
    "isometric, cinematic scene, floor, backdrop, dramatic cast shadow, photorealism, "
    "3D render, UI text, busy background, scenery."
)

CONTAINER_VIEW = (
    "Strict top-down 64x64 overhead orthographic view of one centered object, "
    "camera directly overhead; show only upward-facing surfaces; "
    "no front, side, underside, floor plane, or cast shadow."
)

JOBS = [
    ("supply_crate_closed_master.png",
     COMMON_DARK + " " + CONTAINER_VIEW +
     "DEEP DARK navy-charcoal military supply crate, lid fully closed, square footprint, "
     "dark slate metal panels with muted olive side panels and a small amber seal in the center, "
     "deep dark overall color, no light tones anywhere on the crate body."),
    ("vending_machine_closed_master.png",
     COMMON_DARK + " " + CONTAINER_VIEW +
     "DEEP DARK teal compact vending machine, sealed intact front, square footprint, "
     "deep dark teal body, very small amber maintenance light only, no readable brand or text, "
     "deep dark overall color, no light tones anywhere on the machine body."),
    ("metal_shelf_searched_master.png",
     COMMON + "" +  # use original COMMON for shelf
     "Strict top-down 64x128 overhead orthographic view of one centered tall metal warehouse shelf, "
     "two-by-one vertical tile footprint, cardboard boxes flipped open and empty, empty shelves visible, "
     "no items scattered on the ground, dark charcoal metal frame, dark slate shelves, "
     "no green visible anywhere on the canvas, dark color palette overall. "
     "camera directly overhead; show only upward-facing surfaces; "
     "no front, side, underside, floor plane, or cast shadow."
     if False else
     "Original tactical-anime 2D game asset for an original urban-night extraction game, "
     "crisp readable silhouette, anime cel-shaded style with flat color shading and clean lineart, "
     "restrained navy, slate, wet concrete gray and muted olive palette, subtle amber practical lights, "
     "small red accents only for hostile danger. "
     "DEEP DARK charcoal-gray tall metal warehouse shelf, vertical two-by-one footprint, "
     "cardboard boxes flipped open and empty, empty shelves visible, dark color palette, "
     "NO green anywhere on the canvas. Strict top-down 64x128 overhead orthographic view, "
     "camera directly overhead; show only upward-facing surfaces; "
     "no front, side, underside, floor plane, or cast shadow. "
     "Flat solid #00FF00 chroma-key background covering entire canvas, no text, no logo, no watermark, "
     "no ground plane, no cast shadow, no reflection, no border. "
     "Negative prompt: green background, light tones, washed out, isometric, cinematic scene, "
     "floor, backdrop, photorealism, 3D render, UI text."),
]

COMMON = (
    "Original tactical-anime 2D game asset for an original urban-night extraction game, "
    "crisp readable silhouette, anime cel-shaded style with flat color shading and clean lineart, "
    "restrained navy, slate, wet concrete gray and muted olive palette, subtle amber practical lights, "
    "small red accents only for hostile danger, cyan-violet glow only on pyroxene technology. "
    "Flat solid #00FF00 chroma-key background, one centered subject, no text, no logo, no watermark, "
    "no ground plane, no cast shadow, no reflection, no border. "
    "Negative prompt: isometric, cinematic scene, floor, backdrop, dramatic cast shadow, "
    "photorealism, 3D render, UI text, busy background, scenery."
)

def call_matrix(requests):
    args = json.dumps({"requests": requests})
    proc = subprocess.run(
        ["mcode-tools", "connector", "call", "connector__matrix__generate_image",
         "--args", args],
        capture_output=True, text=True
    )
    if proc.returncode != 0:
        print("STDERR:", proc.stderr)
        raise RuntimeError(proc.stderr)
    return json.loads(proc.stdout.strip())


def get_url(nid):
    proc = subprocess.run(["mcode-tools", "get-asset-url", nid], capture_output=True, text=True)
    data = json.loads(proc.stdout.strip())
    return data.get("download_url") or data.get("url")


def download(url, dest):
    with urllib.request.urlopen(url, timeout=60) as r:
        dest.write_bytes(r.read())


def rembg(src, dst):
    from PIL import Image
    from rembg import remove
    img = Image.open(src).convert("RGBA")
    out = remove(img)
    dst.parent.mkdir(parents=True, exist_ok=True)
    out.save(dst, "PNG")
    return True


def main():
    targets_by_group = {
        "supply_crate_closed_master.png": PROJECT_ROOT / "Art/source/urban_night/props/containers/masters/supply_crate_closed_master.png",
        "vending_machine_closed_master.png": PROJECT_ROOT / "Art/source/urban_night/props/containers/masters/vending_machine_closed_master.png",
        "metal_shelf_searched_master.png": PROJECT_ROOT / "Art/source/urban_night/props/furniture/masters/metal_shelf_searched_master.png",
    }

    req_payload = [
        {"prompt": p, "aspect_ratio": "1:1", "resolution": "1K", "output_file": fname}
        for fname, p in JOBS
    ]

    print(f"[matrix] {len(req_payload)} requests...")
    res = call_matrix(req_payload)
    success = res.get("success_items") or []
    failures = res.get("failure_items") or []
    if failures:
        print(f"  failures: {failures}")
    print(f"  ok: {len(success)}")

    for item in success:
        actual_fn = item.get("file_name") or item.get("output_file")
        nid = item.get("node_id")
        url = get_url(nid)
        if not url:
            print(f"  ! no url for {actual_fn}")
            continue
        # Match by stem to our target dictionary
        stem = Path(actual_fn).stem
        canonical = stem + ".png"
        raw = RAW_DIR / actual_fn
        download(url, raw)
        print(f"  downloaded {actual_fn}")
        final = targets_by_group.get(canonical)
        if not final:
            print(f"  ! no target for {canonical}")
            continue
        tmp = REM_DIR / final.name
        rembg(raw, tmp)
        shutil.copy2(tmp, final)
        print(f"  -> {final.relative_to(PROJECT_ROOT)}")
        time.sleep(0.3)


if __name__ == "__main__":
    main()