#!/usr/bin/env python3

import argparse
import base64
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


PROJECT = Path(__file__).resolve().parents[1]
OUTPUT = PROJECT / "Art/tilesets/urban_night/_review/fog_of_war/edge_demos"
WIDTH, HEIGHT, TILE = 640, 384, 64
FOG_COLOR = (66, 84, 94)
MODES = [
    ("control", "0 · Hard edge / 对照", "4px 透明留边，硬边方块"),
    ("feather", "A · Soft edge / 短羽化", "4px 透明留边，8px 内侧羽化"),
    ("organic", "B · Organic edge / 不规则雾边", "4px 透明留边，7px 轮廓羽化"),
    ("merged", "C · Joined field / 相邻融合", "相邻覆盖区融合，需放宽逐格留边"),
]
EXEMPT = {(6, 1), (8, 4)}


def smoothstep(lower, upper, value):
    normalized = np.clip((value - lower) / (upper - lower), 0.0, 1.0)
    return normalized * normalized * (3.0 - 2.0 * normalized)


def tile_mask(mode, column, row):
    pixel_y, pixel_x = np.mgrid[0:TILE, 0:TILE].astype(float)
    pixel_x += 0.5
    pixel_y += 0.5
    edge = np.minimum.reduce([pixel_x, pixel_y, TILE - pixel_x, TILE - pixel_y])
    if mode == "control":
        return (edge >= 4).astype(float)
    if mode == "feather":
        return smoothstep(4, 12, edge)
    phase = ((column * 37 + row * 19) % 23) / 23 * np.pi * 2
    center_x = pixel_x - 32
    center_y = pixel_y - 32
    angle = np.arctan2(center_y / 0.88, center_x)
    radius = np.sqrt(center_x**2 + (center_y / 0.88) ** 2)
    boundary = 28 + 2.2 * np.sin(3 * angle + phase) + 1.6 * np.cos(5 * angle - phase)
    shape = smoothstep(0, 7, boundary - radius)
    return shape * smoothstep(4, 7, edge)


def opacity_grid(origin):
    result = np.zeros((HEIGHT // TILE, WIDTH // TILE))
    for row in range(result.shape[0]):
        for column in range(result.shape[1]):
            distance = max(abs(column - origin[0]), abs(row - origin[1]))
            if distance > 2:
                result[row, column] = min(0.8, (4 + distance - 2) / 10)
            if (column, row) in EXEMPT:
                result[row, column] = 0
    return result


def alpha_field(mode, origin, uniform=None):
    levels = opacity_grid(origin)
    if uniform is not None:
        levels = np.where(levels > 0, uniform, 0)
    result = np.zeros((HEIGHT, WIDTH))
    if mode != "merged":
        for row in range(levels.shape[0]):
            for column in range(levels.shape[1]):
                result[row * TILE:(row + 1) * TILE, column * TILE:(column + 1) * TILE] = (
                    tile_mask(mode, column, row) * levels[row, column]
                )
    else:
        filled = np.repeat(np.repeat(levels, TILE, axis=0), TILE, axis=1)
        image = Image.fromarray(np.uint8(np.rint(filled * 255)))
        result = np.asarray(image.filter(ImageFilter.GaussianBlur(11)), dtype=float) / 255
        pixel_y, pixel_x = np.mgrid[0:HEIGHT, 0:WIDTH]
        cloud = 0.93 + 0.045 * np.sin(pixel_x / 39 + pixel_y / 59) + 0.025 * np.cos(pixel_x / 73 - pixel_y / 37)
        result *= np.clip(cloud, 0.86, 1.0)
        result = np.minimum(result, np.where(filled > 0, filled, 0.8))
        for column, row in EXEMPT:
            result[row * TILE:(row + 1) * TILE, column * TILE:(column + 1) * TILE] = 0
    return np.clip(result, 0, 0.8)


def ground_image():
    base = PROJECT / "Art/tilesets/urban_night"
    asphalt = [Image.open(base / f"ground/asphalt/asphalt_wet_{letter}.png").convert("RGBA") for letter in "abcd"]
    pavement = [Image.open(base / f"ground/sidewalk/sidewalk_concrete_{letter}.png").convert("RGBA") for letter in "abcd"]
    image = Image.new("RGBA", (WIDTH, HEIGHT))
    for row in range(HEIGHT // TILE):
        for column in range(WIDTH // TILE):
            choices = pavement if row in (0, 5) or column == 4 else asphalt
            texture = choices[(column * 3 + row) % len(choices)]
            image.paste(texture, (column * TILE, row * TILE))
    for (column, row), name in zip(sorted(EXEMPT), ["supply_crate_closed_b.png", "medical_locker_closed_b.png"]):
        prop = Image.open(base / "props/containers" / name).convert("RGBA")
        image.alpha_composite(prop, (column * TILE, row * TILE))
    return image


def overlay(field):
    image = Image.new("RGBA", (WIDTH, HEIGHT), (*FOG_COLOR, 0))
    image.putalpha(Image.fromarray(np.uint8(np.rint(field * 255))))
    return image


def render(base, field):
    return Image.alpha_composite(base, overlay(field))


def font(size):
    path = Path("/System/Library/Fonts/PingFang.ttc")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default(size=size)


def comparison_sheet(images):
    sheet = Image.new("RGB", (WIDTH * 2, (HEIGHT + 60) * 2), (20, 29, 35))
    drawing = ImageDraw.Draw(sheet)
    for index, (mode, label, detail) in enumerate(MODES):
        left = (index % 2) * WIDTH
        top = (index // 2) * (HEIGHT + 60)
        drawing.text((left + 14, top + 7), label, font=font(21), fill=(223, 231, 232))
        drawing.text((left + 14, top + 34), detail, font=font(14), fill=(169, 189, 194))
        sheet.paste(images[mode].convert("RGB"), (left, top + 60))
    return sheet


def data_uri(image, image_format="PNG"):
    buffer = io.BytesIO()
    image.save(buffer, format=image_format, **({"quality": 88} if image_format == "WEBP" else {}))
    mime = "image/webp" if image_format == "WEBP" else "image/png"
    return f"data:{mime};base64,{base64.b64encode(buffer.getvalue()).decode()}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--visualization", type=Path, required=True)
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    base = ground_image()
    base.save(OUTPUT / "ground_reference.png")
    origins = [(1, 3), (3, 3)]
    fields = {mode: [alpha_field(mode, origin) for origin in origins] for mode, _, _ in MODES}
    stills = {mode: render(base, pair[0]) for mode, pair in fields.items()}
    for mode, image in stills.items():
        image.save(OUTPUT / f"demo_{mode}.png")
        overlay(fields[mode][0]).save(OUTPUT / f"alpha_field_{mode}.png")
        enlarged = image.crop((4 * TILE, 2 * TILE, 7 * TILE, 5 * TILE)).resize((576, 576), Image.Resampling.NEAREST)
        enlarged.save(OUTPUT / f"detail_{mode}.png")
    comparison_sheet(stills).save(OUTPUT / "comparison.png")
    for mode in ("feather", "organic", "merged"):
        strip = Image.new("RGB", (TILE * 4, TILE))
        for index, opacity in enumerate([0.5, 0.6, 0.7, 0.8]):
            preview = render(base, alpha_field(mode, origins[0], opacity))
            strip.paste(preview.crop((7 * TILE, 2 * TILE, 8 * TILE, 3 * TILE)).convert("RGB"), (index * TILE, 0))
        strip.resize((768, 192), Image.Resampling.NEAREST).save(OUTPUT / f"density_strip_{mode}.png")
    steps = [0.0] * 7 + [float((1 - np.cos(np.pi * value / 5)) / 2) for value in range(1, 6)] + [1.0] * 7
    frames = []
    for progress in steps:
        images = {
            mode: render(base, pair[0] * (1 - progress) + pair[1] * progress)
            for mode, pair in fields.items()
        }
        frame = comparison_sheet(images).resize((1024, 710), Image.Resampling.LANCZOS)
        frames.append(frame.quantize(colors=192))
    frames[0].save(
        OUTPUT / "fade_comparison.gif", save_all=True, append_images=frames[1:],
        duration=50, loop=0, optimize=False,
    )
    initial = {}
    for mode, pair in fields.items():
        initial[mode] = {
            "start": data_uri(overlay(pair[0])),
            "end": data_uri(overlay(pair[1])),
        }
    dataset = {"ground": data_uri(base, "WEBP"), "fields": initial, "width": WIDTH, "height": HEIGHT}
    template = (PROJECT / "tools/fog_edge_demo.html").read_text(encoding="utf-8")
    fragment = template.replace("__FOG_DATA__", json.dumps(dataset, separators=(",", ":")))
    assert "__FOG_DATA__" not in fragment
    assert len(fragment.encode()) < 1_000_000
    args.visualization.parent.mkdir(parents=True, exist_ok=True)
    args.visualization.write_text(fragment, encoding="utf-8")
    for mode in ("feather", "organic"):
        mask = tile_mask(mode, 0, 0)
        assert np.max(mask[:4]) == np.max(mask[-4:]) == np.max(mask[:, :4]) == np.max(mask[:, -4:]) == 0
    metadata = {
        "type": "procedural edge-treatment demo, not AI-generated art or in-engine capture",
        "world_size": [WIDTH, HEIGHT], "tile_size": 64, "vision_range": 2,
        "origins": origins, "opacity_steps": [0.5, 0.6, 0.7, 0.8],
        "fog_rgb": FOG_COLOR, "transition_seconds": 0.25,
        "exception_cells": sorted(EXEMPT),
        "modes": {mode: detail for mode, _, detail in MODES},
        "border_note": "A/B preserve 4px transparency; C explicitly relaxes per-grid padding.",
        "runtime_modified": False,
        "review": "All variants delivered without model visual evaluation or ranking.",
    }
    (OUTPUT / "technical_metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")
    print(f"Delivered {len(MODES)} comparison modes; visualization {len(fragment.encode())} bytes")
    print(OUTPUT)
    print(args.visualization)


if __name__ == "__main__":
    main()
