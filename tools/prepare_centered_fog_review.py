#!/usr/bin/env python3

import argparse
import json
from pathlib import Path

from PIL import Image, ImageStat


def transparent_master(source):
    rgba = source.convert("RGBA")
    pixels = []
    for red, green, blue, original_alpha in rgba.getdata():
        excess = green - max(red, blue)
        alpha = original_alpha
        if green > 110 and excess > 35:
            alpha = round(original_alpha * max(0.0, 1.0 - (excess - 35) / 65.0))
            if alpha > 0:
                green = min(green, max(red, blue))
        pixels.append((red, green, blue, alpha) if alpha else (0, 0, 0, 0))
    rgba.putdata(pixels)
    return rgba


def padded_image(image, size, padding):
    canvas = Image.new("RGBA", (size, size))
    inner = image.resize((size - 2 * padding, size - 2 * padding), Image.Resampling.LANCZOS)
    canvas.paste(inner, (padding, padding))
    return canvas


def repeat_tile(tile, count):
    result = Image.new("RGBA", (tile.width * count, tile.height * count))
    for row in range(count):
        for column in range(count):
            result.paste(tile, (column * tile.width, row * tile.height))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--suffix", default="09")
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    suffix = args.suffix
    source = Image.open(args.source)
    extracted = transparent_master(source)
    master = padded_image(extracted, 1024, 64)
    tile = padded_image(extracted, 64, 4)
    master.save(args.out_dir / f"fog_centered_alpha_master_{suffix}.png")
    tile.save(args.out_dir / f"fog_centered_64_{suffix}.png")
    repeated = repeat_tile(tile, 4)
    repeated.save(args.out_dir / f"fog_centered_grid_4x4_{suffix}.png")
    checker = Image.new("RGBA", (512, 512))
    for row in range(512):
        for column in range(512):
            shade = 75 if (row // 32 + column // 32) % 2 else 130
            checker.putpixel((column, row), (shade, shade, shade, 255))
    Image.alpha_composite(
        checker, repeated.resize((512, 512), Image.Resampling.NEAREST)
    ).save(args.out_dir / f"preview_checker_{suffix}.png")
    ground_dir = Path(__file__).resolve().parents[1] / "Art/tilesets/urban_night/ground"
    tiles = [
        Image.open(ground_dir / "brick_paving/brick_wet_a.png").convert("RGBA"),
        Image.open(ground_dir / "asphalt/asphalt_wet_a.png").convert("RGBA"),
    ]
    ground = Image.new("RGBA", (512, 512))
    for row in range(8):
        for column in range(8):
            ground.paste(tiles[0 if 2 <= column <= 4 else 1], (column * 64, row * 64))
    covered = Image.alpha_composite(ground, repeat_tile(tile, 8))
    comparison = Image.new("RGBA", (1024, 512))
    comparison.paste(ground, (0, 0))
    comparison.paste(covered, (512, 0))
    comparison.save(args.out_dir / f"preview_ground_before_after_{suffix}.png")
    alpha = tile.getchannel("A")
    for edge in [
        (0, 0, 64, 4), (0, 60, 64, 64), (0, 0, 4, 64), (60, 0, 64, 64)
    ]:
        assert alpha.crop(edge).getextrema() == (0, 0)
    metadata = {
        "provider": "MiniMax image-01",
        "source_size": list(source.size),
        "source_format": source.format,
        "alpha_master_size": list(master.size),
        "runtime_size": list(tile.size),
        "guaranteed_transparent_border_pixels": 4,
        "alpha_range": list(alpha.getextrema()),
        "alpha_mean": ImageStat.Stat(alpha).mean[0],
        "nontransparent_bbox": alpha.getbbox(),
        "processing": "green-key alpha extraction; preserve source colors; no crop; scale into padded transparent canvas",
        "review": "All outputs delivered without model visual scoring, filtering or selection.",
    }
    (args.out_dir / f"technical_metadata_{suffix}.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
