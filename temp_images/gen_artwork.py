#!/usr/bin/env python3
"""
Generate tactical-anime game art masters via matrix image generation,
then run rembg to produce transparent-background PNGs at the proper
locations under Art/source/urban_night/.../masters/.

Usage:
  python3 gen_artwork.py           # generate everything
  python3 gen_artwork.py enemies   # only the named group
"""

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path("/Users/zwcn3212/Godot/test1")
RAW_DIR = PROJECT_ROOT / "temp_images" / "artwork_raw"
REM_DIR = PROJECT_ROOT / "temp_images" / "artwork_rembg"
RAW_DIR.mkdir(parents=True, exist_ok=True)
REM_DIR.mkdir(parents=True, exist_ok=True)

SOURCE_ROOT = PROJECT_ROOT / "Art" / "source" / "urban_night"
TARGETS = {
    "enemies":   SOURCE_ROOT / "enemies" / "masters",
    "containers": SOURCE_ROOT / "props" / "containers" / "masters",
    "furniture": SOURCE_ROOT / "props" / "furniture" / "masters",
    "loot":       SOURCE_ROOT / "props" / "loot" / "masters",
}
for d in TARGETS.values():
    d.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Prompt templates (from doc §6)
# ---------------------------------------------------------------------------
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

ENEMY_VIEW = (
    "Match the exact runtime battle-sprite camera, facing direction, character scale, bottom anchor, "
    "and front three-quarter chibi-proportioned presentation of the supplied Benny sprite-sheet reference. "
    "Feet point toward the bottom of the frame. The enemy must look like it stands beside Benny "
    "on the same tactical battlefield. Do not use strict overhead top-down, isometric, side view, "
    "or a different camera angle."
)

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------

ENEMIES = [
    # (out_filename, prompt)
    ("raider_infantry_idle_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full body centered battle sprite of a street raider infantryman: "
     "worn rain poncho, pieced-together chest armor, short compact carbine held across the torso, "
     "rectangular scavenger backpack with loose utility straps, wide shoulders and clear carbine silhouette, "
     "navy-gray clothing, faded orange-red armband, idle standing pose, designed to read beside a chibi character at 64x80 pixels."),

    ("raider_infantry_walk_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full character sheet showing a street raider infantryman walking, with 4 sequential walking frames "
     "laid out horizontally left-to-right on one image, transparent-friendly flat background. "
     "Worn rain poncho, pieced chest armor, short compact carbine across torso, scavenger backpack, "
     "navy-gray clothing, faded orange-red armband. "
     "All four frames must share the same bottom anchor, scale and front three-quarter chibi-proportioned view."),

    ("raider_scout_idle_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full body centered battle sprite of a fast raider scout: "
     "narrow hooded rain cape, improvised respirator mask, folding SMG held low, small signal flare pouch on thigh, "
     "slim forward-leaning silhouette, muted olive-gray cloth with thin cold-cyan reflective strip, "
     "no bulky shield or backpack, idle standing pose, designed to read beside a chibi character at 64x80 pixels."),

    ("raider_scout_walk_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full character sheet showing a fast raider scout walking, with 4 sequential walking frames "
     "laid out horizontally left-to-right on one image. "
     "Narrow hooded rain cape, respirator mask, folding SMG, thigh signal flare pouch, slim forward lean, "
     "muted olive-gray cloth with thin cold-cyan reflective strip. "
     "All four frames must share the same bottom anchor, scale and front three-quarter chibi view."),

    ("raider_bulwark_idle_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full body centered battle sprite of a heavy raider bulwark: "
     "large salvaged rectangular riot shield held in front, thick patchwork armor, short shotgun tucked behind the shield, "
     "short broad body, charcoal gray materials with weathered amber-yellow safety stripe, clear shield-first silhouette, "
     "idle standing pose, designed to read beside a chibi character at 64x80 pixels."),

    ("raider_bulwark_walk_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full character sheet showing a heavy raider bulwark walking, with 4 sequential walking frames "
     "laid out horizontally left-to-right on one image. "
     "Large rectangular riot shield held forward, thick patchwork armor, short shotgun tucked behind shield, "
     "short broad body, charcoal gray with weathered amber-yellow safety stripe. "
     "All four frames share the same bottom anchor, scale and front three-quarter chibi view."),

    ("pyroxene_hound_idle_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full creature centered battle sprite of a four-legged pyroxene hound: "
     "low mechanical beast, graphite armor plates split by small cyan-violet crystal growths, cutting foreclaws, "
     "low stance, long spine with asymmetric crystal cluster, no human anatomy, idle standing pose, "
     "designed to read beside a chibi character at 64x80 pixels."),

    ("pyroxene_hound_walk_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full creature sheet showing a pyroxene hound walking, with 4 sequential walking frames "
     "laid out horizontally left-to-right on one image. "
     "Four-legged mechanical beast, graphite armor with cyan-violet crystal growths along spine and joints, "
     "cutting foreclaws, low stance. All four frames share the same bottom anchor, scale and view."),

    ("pyroxene_sentry_idle_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single compact pyroxene sentry machine centered: "
     "triangular three-leg chassis, single circular sensor eye glowing cyan-violet, side-mounted energy emitter, "
     "crystal cooling fins, small amber maintenance indicator, readable mechanical silhouette, no text, "
     "idle standing pose, designed to read beside a chibi character at 64x80 pixels."),

    ("pyroxene_sentry_walk_master.png",
     COMMON + " " + ENEMY_VIEW +
     "Single full sheet showing a pyroxene sentry machine moving, with 4 sequential frames "
     "laid out horizontally left-to-right on one image. "
     "Triangular three-leg chassis, single cyan-violet sensor eye, side energy emitter, crystal cooling fins, "
     "small amber maintenance indicator. All four frames share the same bottom anchor, scale and view."),
]

CONTAINERS = [
    # supply crate states
    ("supply_crate_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark slate metal military supply crate, "
     "muted olive panels, small amber seal in the center, lid closed, wet urban night palette. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. One centered object, square footprint."),
    ("supply_crate_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark slate metal military supply crate with lid hinged back, "
     "showing a few generic dark supply modules inside, muted olive panels, small amber seal. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed supply crate."),
    ("supply_crate_empty_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark slate metal military supply crate open and empty, "
     "lid hinged back, interior compartments visible and empty, muted olive panels, small amber seal. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed supply crate."),

    # medical locker
    ("medical_locker_closed_master.png",
     COMMON +
     "Strict top-down 128x128 overhead view of one centered dark green battered metal field medical locker, "
     "2x2 tile footprint, subtle worn medical cross marking with no text, doors closed. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("medical_locker_open_master.png",
     COMMON +
     "Strict top-down 128x128 overhead view of one centered dark green battered metal field medical locker, "
     "doors open, showing 2 or 3 dark shelves and generic medical cases, subtle worn medical cross with no text. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed medical locker."),
    ("medical_locker_empty_master.png",
     COMMON +
     "Strict top-down 128x128 overhead view of one centered dark green battered metal field medical locker, "
     "doors half open with empty interior, subtle worn medical cross with no text. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed medical locker."),

    # trash bin
    ("trash_bin_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark gray wet urban metal trash bin, "
     "hinged lid closed, small rain stains, square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("trash_bin_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark gray wet urban metal trash bin with hinged lid open, "
     "a few muted junk bags visible inside. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed trash bin. No loose trash on the ground."),
    ("trash_bin_empty_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered dark gray wet urban metal trash bin with hinged lid half open, "
     "interior empty. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed trash bin."),

    # vending machine
    ("vending_machine_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered old dark teal compact vending machine, "
     "sealed intact front, no readable brand or text, small amber maintenance light visible. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("vending_machine_breached_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered old dark teal compact vending machine with pried-open door "
     "and broken pickup flap, a few generic supplies visible inside, small amber maintenance light visible. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed vending machine."),
    ("vending_machine_empty_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered old dark teal compact vending machine with pried-open door, "
     "empty slots, unlit display, small amber maintenance light visible. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed vending machine."),
]

FURNITURE = [
    # metal shelf searched
    ("metal_shelf_searched_master.png",
     COMMON +
     "Strict top-down 64x128 overhead view of one centered tall metal warehouse shelf, "
     "two-by-one vertical tile footprint, cardboard boxes flipped open, empty shelves visible, "
     "no items scattered on the ground. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Restrained navy and slate palette, muted amber practical lights."),

    # refrigerator
    ("refrigerator_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered household refrigerator with door open to the side, "
     "showing empty wire shelves and a small amount of condensation droplets, square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("refrigerator_empty_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered household refrigerator with door slightly ajar, "
     "interior empty, no food visible, square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed refrigerator."),

    # tool case
    ("tool_case_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered low-value engineer tool case, "
     "dark navy-gray hard shell, amber tamper seal, square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("tool_case_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered low-value engineer tool case with lid open, "
     "showing generic wrench and cable silhouettes inside, dark navy-gray hard shell, amber seal. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed tool case."),

    # ammo crate
    ("ammo_crate_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered military ammo crate, "
     "olive-gray metal with orange-red hazard label (no text, no logo), square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("ammo_crate_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered military ammo crate with lid open, "
     "showing generic modular magazines and parts inside, olive-gray metal with orange-red hazard label. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed ammo crate. Avoid real brand markings."),

    # field cache
    ("field_cache_closed_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered canvas field cache pouch, "
     "waterproof sealed flap, dark olive-gray fabric, square footprint. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow."),
    ("field_cache_open_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered canvas field cache pouch with flap open, "
     "showing rolled textile and small medical pouches inside, dark olive-gray fabric. "
     "camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, "
     "or cast shadow. Identical footprint and anchor to closed field cache."),
]

LOOT = [
    ("ground_loot_pile_master.png",
     COMMON +
     "Strict top-down 64x64 overhead view of one centered compact loot pile: "
     "one small dark canvas field pouch, one folded muted textile roll, one generic metal component, "
     "compact pile contained within one grid cell, readable from directly overhead, no weapons, no text, "
     "no visible ground plane and no cast shadow. Pile must be small enough that a character can stand on the same cell."),
]

# group -> (requests list, target dir)
GROUPS = {
    "enemies":    (ENEMIES,    TARGETS["enemies"]),
    "containers": (CONTAINERS, TARGETS["containers"]),
    "furniture":  (FURNITURE,  TARGETS["furniture"]),
    "loot":       (LOOT,       TARGETS["loot"]),
}

# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def call_matrix(requests, batch_size=5):
    """Call connector__matrix__generate_image in batches of `batch_size`."""
    import subprocess as sp
    all_results = []
    for i in range(0, len(requests), batch_size):
        chunk = requests[i:i + batch_size]
        args = json.dumps({"requests": chunk})
        print(f"[matrix] batch {i//batch_size + 1}: {len(chunk)} requests", flush=True)
        proc = sp.run(
            ["mcode-tools", "connector", "call", "connector__matrix__generate_image",
             "--args", args],
            capture_output=True, text=True
        )
        if proc.returncode != 0:
            print("STDERR:", proc.stderr, flush=True)
            raise RuntimeError(f"matrix call failed: {proc.stderr}")
        out = proc.stdout.strip()
        try:
            data = json.loads(out)
        except json.JSONDecodeError as e:
            print("RAW OUT:", out[:2000], flush=True)
            raise
        # Success and failure entries
        success = data.get("success_items") or data.get("success") or []
        failure = data.get("failure_items") or data.get("failure") or []
        all_results.extend(success)
        if failure:
            print(f"  ! {len(failure)} failures in batch:", flush=True)
            for f in failure:
                print("    -", f, flush=True)
        time.sleep(1)
    return all_results


def get_urls(node_ids):
    """Resolve short-lived URLs for each node_id."""
    import subprocess as sp
    urls = {}
    for nid in node_ids:
        proc = sp.run(
            ["mcode-tools", "get-asset-url", nid],
            capture_output=True, text=True
        )
        if proc.returncode != 0:
            print(f"  ! failed to resolve {nid}: {proc.stderr.strip()}", flush=True)
            continue
        try:
            data = json.loads(proc.stdout.strip())
            url = (
                data.get("download_url")
                or data.get("url")
                or data.get("file_url")
                or data.get("temp_url")
            )
            urls[nid] = url
        except json.JSONDecodeError:
            urls[nid] = proc.stdout.strip()
        time.sleep(0.3)
    return urls


def download(url, dest):
    import urllib.request
    with urllib.request.urlopen(url, timeout=60) as r:
        data = r.read()
    with open(dest, "wb") as f:
        f.write(data)


def rembg_process(src, dst):
    """Use rembg Python API directly (no CLI / no gradio dep).

    Reads the source image (any common format), removes background,
    writes a transparent PNG to dst.
    """
    try:
        from PIL import Image
        from rembg import remove
    except Exception as e:
        print(f"  ! rembg import failed: {e}", flush=True)
        return False
    try:
        src_img = Image.open(src).convert("RGBA")
        out_img = remove(src_img)
        if dst.suffix.lower() != ".png":
            dst = dst.with_suffix(".png")
        dst.parent.mkdir(parents=True, exist_ok=True)
        out_img.save(dst, "PNG")
        return True
    except Exception as e:
        print(f"  ! rembg failed for {src.name}: {e}", flush=True)
        return False


def process_group(name):
    items, target_dir = GROUPS[name]
    print(f"\n=== Group: {name} ({len(items)} items) ===", flush=True)

    # Build requests in expected schema
    req_payload = [
        {
            "prompt": prompt,
            "aspect_ratio": "1:1",
            "resolution": "1K",
            "output_file": fname,
        }
        for fname, prompt in items
    ]

    success = call_matrix(req_payload, batch_size=4)
    print(f"[matrix] got {len(success)} successful items", flush=True)
    if not success:
        print("[matrix] nothing succeeded; aborting group", flush=True)
        return

    # Map output_file -> (node_id, actual_file_name)
    file_to_node = {}
    for item in success:
        fn = item.get("file_name") or item.get("output_file") or ""
        nid = item.get("node_id") or item.get("id")
        # Use the original requested fname as our canonical output key
        canonical = item.get("output_file") or fn
        if nid and fn:
            file_to_node[canonical] = (nid, fn)

    # Get URLs
    print(f"[urls] resolving {len(file_to_node)} urls...", flush=True)
    urls = get_urls([nid for nid, _ in file_to_node.values()])

    # Download each into RAW_DIR
    downloaded = []
    for canonical, (nid, actual_fn) in file_to_node.items():
        url = urls.get(nid)
        if not url:
            print(f"  ! no url for {canonical} ({nid})", flush=True)
            continue
        # save with actual extension returned by server
        out_path = RAW_DIR / actual_fn
        try:
            download(url, out_path)
            downloaded.append((canonical, out_path))
            print(f"  ok {actual_fn}", flush=True)
        except Exception as e:
            print(f"  ! download failed for {canonical}: {e}", flush=True)
        time.sleep(0.2)

    # rembg each, save into final target dir (always as .png)
    print(f"[rembg] processing {len(downloaded)} files...", flush=True)
    for canonical, src in downloaded:
        final = target_dir / canonical  # canonical ends in .png by request
        if final.suffix.lower() != ".png":
            final = final.with_suffix(".png")
        tmp = REM_DIR / final.name
        ok = rembg_process(src, tmp)
        if ok:
            shutil.copy2(tmp, final)
            print(f"  -> {final.relative_to(PROJECT_ROOT)}", flush=True)
        else:
            # fallback: copy raw
            shutil.copy2(src, final)
            print(f"  -> (raw fallback) {final.relative_to(PROJECT_ROOT)}", flush=True)


def main():
    sel = sys.argv[1:]
    if not sel:
        sel = list(GROUPS.keys())
    for name in sel:
        if name not in GROUPS:
            print(f"unknown group: {name}", file=sys.stderr)
            continue
        process_group(name)
    print("\nAll done.", flush=True)


if __name__ == "__main__":
    main()