#!/usr/bin/env python3

import argparse
import json
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps, ImageStat


def periodic_density(source):
    density = ImageOps.grayscale(source)
    for horizontal in (True, False):
        width, height = density.size
        span = width if horizontal else height
        edge_width = max(1, span // 8)
        weights = []
        for coordinate in range(span):
            distance = min(coordinate, span - 1 - coordinate)
            strength = max(0.0, 1.0 - distance / edge_width)
            weights.append(round(127.5 * strength * strength))
        strip = Image.new("L", (span, 1))
        strip.putdata(weights)
        if horizontal:
            mask = strip.resize((width, height))
            reflected = ImageOps.mirror(density)
        else:
            mask = strip.transpose(Image.Transpose.ROTATE_90).resize((width, height))
            reflected = ImageOps.flip(density)
        density = Image.composite(reflected, density, mask)
    return match_edges(density)


def match_edges(image):
    result = image.copy()
    width, height = result.size
    for row in range(height):
        result.putpixel((width - 1, row), result.getpixel((0, row)))
    for column in range(width):
        result.putpixel((column, height - 1), result.getpixel((column, 0)))
    return result


def smoke_overlay(density, alpha_base, alpha_scale, smoke_rgb):
    alpha = density.point(lambda value: round(255 * (alpha_base + alpha_scale * value / 255)))
    overlay = Image.new("RGBA", density.size, (*smoke_rgb, 0))
    overlay.putalpha(alpha)
    return overlay


def repeated(image, count):
    width, height = image.size
    preview = Image.new("RGBA", (width * count, height * count))
    for row in range(count):
        for column in range(count):
            preview.paste(image, (column * width, row * height))
    return preview


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--suffix", default="02")
    parser.add_argument("--alpha-base", type=float, default=0.10)
    parser.add_argument("--alpha-scale", type=float, default=0.55)
    parser.add_argument("--blur-radius", type=float, default=0.0)
    parser.add_argument("--compare-tile", type=Path)
    parser.add_argument("--smoke-rgb", type=int, nargs=3, default=[151, 158, 163])
    args = parser.parse_args()
    if args.blur_radius < 0:
        parser.error("--blur-radius must be nonnegative")
    if any(channel < 0 or channel > 255 for channel in args.smoke_rgb):
        parser.error("--smoke-rgb channels must be in [0, 255]")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    source = Image.open(args.source).convert("RGB")
    density = periodic_density(source)
    if args.blur_radius > 0:
        width, height = density.size
        padding = max(1, round(args.blur_radius * 4))
        wrapped = ImageOps.expand(density, border=padding)
        for row in range(wrapped.height):
            for column in range(wrapped.width):
                wrapped.putpixel(
                    (column, row),
                    density.getpixel(((column - padding) % width, (row - padding) % height)),
                )
        density = match_edges(
            wrapped.filter(ImageFilter.GaussianBlur(args.blur_radius)).crop(
                (padding, padding, padding + width, padding + height)
            )
        )
    suffix = args.suffix
    master = smoke_overlay(density, args.alpha_base, args.alpha_scale, args.smoke_rgb)
    master.save(args.out_dir / f"fog_smoke_alpha_master_{suffix}.png")
    tile_density = match_edges(density.resize((64, 64), Image.Resampling.LANCZOS))
    tile = smoke_overlay(tile_density, args.alpha_base, args.alpha_scale, args.smoke_rgb)
    tile.save(args.out_dir / f"fog_smoke_64_{suffix}.png")
    repeated(tile, 2).save(args.out_dir / f"fog_smoke_repeat_2x2_{suffix}.png")
    repeated(tile, 4).save(args.out_dir / f"fog_smoke_repeat_4x4_{suffix}.png")
    repeated(master, 2).save(args.out_dir / f"fog_smoke_master_repeat_2x2_{suffix}.png")
    enlarged = repeated(tile, 4).resize((512, 512), Image.Resampling.NEAREST)
    checker = Image.new("RGBA", (512, 512))
    for row in range(512):
        for column in range(512):
            shade = 80 if (column // 32 + row // 32) % 2 else 140
            checker.putpixel((column, row), (shade, shade, shade, 255))
    Image.alpha_composite(checker, enlarged).save(args.out_dir / f"preview_checker_{suffix}.png")
    ground_dir = Path(__file__).resolve().parents[1] / "Art/tilesets/urban_night/ground"
    ground_paths = [
        ground_dir / "brick_paving/brick_wet_a.png",
        ground_dir / "asphalt/asphalt_wet_a.png",
    ]
    ground_tiles = [Image.open(path).convert("RGBA") for path in ground_paths]
    map_image = Image.new("RGBA", (512, 512))
    for row in range(8):
        for column in range(8):
            texture = ground_tiles[0 if 2 <= column <= 4 else 1].resize((64, 64))
            map_image.paste(texture, (column * 64, row * 64))
    fogged = Image.alpha_composite(map_image, repeated(tile, 8))
    comparison = Image.new("RGBA", (1024, 512))
    comparison.paste(map_image, (0, 0))
    comparison.paste(fogged, (512, 0))
    comparison.save(args.out_dir / f"preview_ground_before_after_{suffix}.png")
    if args.compare_tile:
        previous_tile = Image.open(args.compare_tile).convert("RGBA")
        previous = Image.alpha_composite(map_image, repeated(previous_tile, 8))
        comparison.paste(previous, (0, 0))
        comparison.save(args.out_dir / f"preview_previous_vs_{suffix}.png")
    alpha = master.getchannel("A")
    metadata = {
        "provider": "MiniMax image-01",
        "source_size": list(source.size),
        "alpha_master_size": list(master.size),
        "runtime_size": list(tile.size),
        "alpha_range": list(alpha.getextrema()),
        "alpha_mean": ImageStat.Stat(alpha).mean[0],
        "alpha_formula": f"round(255 * ({args.alpha_base} + {args.alpha_scale} * grayscale / 255))",
        "smoke_rgb": args.smoke_rgb,
        "blur_radius_master_pixels": args.blur_radius,
        "processing": "grayscale density; mirrored edge crossfade over 1/8 width; periodic Gaussian blur when requested; edge matching; alpha mapping; Lanczos downsample",
        "review": "All outputs delivered without model visual scoring, filtering or selection.",
    }
    for row in range(64):
        assert tile.getpixel((0, row)) == tile.getpixel((63, row))
        assert tile.getpixel((row, 0)) == tile.getpixel((row, 63))
    (args.out_dir / f"technical_metadata_{suffix}.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
