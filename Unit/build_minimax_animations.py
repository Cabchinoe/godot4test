#!/usr/bin/env python3
"""Build runtime character sprites from MiniMax-generated source art."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "Art/source/urban_night/characters"
TILE_SIZE = 64
MASTER_SIZE = 512

CHARACTERS = {
    "rabbit_soldier": {
        "raw": SOURCE_DIR / "rabbit_soldier_raw_01.png",
        "master": SOURCE_DIR / "rabbit_soldier_master_01.png",
        "static": ROOT / "Unit/player2.png",
        "walk": ROOT / "Unit/player2_walk.png",
        "crop": (160, 60, 780, 950),
        "shadow_seed": None,
        "aim_raw": SOURCE_DIR / "rabbit_soldier_aim_raw_01.png",
        "aim_master": SOURCE_DIR / "rabbit_soldier_aim_master_01.png",
        "aim": ROOT / "Unit/player2_aim.png",
        "aim_crop": (150, 35, 800, 930),
    },
    "eagle_soldier": {
        "raw": SOURCE_DIR / "eagle_soldier_raw_01.png",
        "master": SOURCE_DIR / "eagle_soldier_master_01.png",
        "static": None,
        "walk": ROOT / "Unit/eagle_soldier_walk.png",
        "crop": (120, 120, 960, 940),
        "shadow_seed": (360, 390),
    },
}


def is_green_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return green > 40 and green >= red + 10 and green >= blue + 5


def remove_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    width, height = image.size
    pixels = image.load()
    transparent = Image.new("L", image.size, 255)
    alpha = transparent.load()
    queue: deque[tuple[int, int]] = deque()
    visited = bytearray(width * height)

    def visit(x: int, y: int) -> None:
        index = y * width + x
        if visited[index] or not is_green_background(pixels[x, y]):
            return
        visited[index] = 1
        queue.append((x, y))

    for x in range(width):
        visit(x, 0)
        visit(x, height - 1)
    for y in range(height):
        visit(0, y)
        visit(width - 1, y)

    while queue:
        x, y = queue.popleft()
        alpha[x, y] = 0
        if x > 0:
            visit(x - 1, y)
        if x + 1 < width:
            visit(x + 1, y)
        if y > 0:
            visit(x, y - 1)
        if y + 1 < height:
            visit(x, y + 1)

    image.putalpha(transparent)
    return image


def erase_connected_shadow(image: Image.Image, seed: tuple[int, int] | None) -> None:
    if seed is None:
        return

    pixels = image.load()
    width, height = image.size
    seed_color = pixels[seed[0], seed[1]]
    queue: deque[tuple[int, int]] = deque([seed])
    visited = bytearray(width * height)

    while queue:
        x, y = queue.popleft()
        index = y * width + x
        if visited[index]:
            continue
        visited[index] = 1
        red, green, blue, alpha = pixels[x, y]
        distance = abs(red - seed_color[0]) + abs(green - seed_color[1]) + abs(blue - seed_color[2])
        if alpha == 0 or distance > 24:
            continue
        pixels[x, y] = (red, green, blue, 0)
        for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= next_x < width and 0 <= next_y < height:
                queue.append((next_x, next_y))


def make_master(config: dict) -> Image.Image:
    raw = Image.open(config["raw"]).convert("RGBA")
    sprite = remove_background(raw)
    cropped = sprite.crop(config["crop"])
    cropped.thumbnail((440, 480), Image.Resampling.LANCZOS)
    master = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE))
    offset_x = (MASTER_SIZE - cropped.width) // 2
    offset_y = (MASTER_SIZE - cropped.height) // 2
    master.alpha_composite(cropped, (offset_x, offset_y))
    erase_connected_shadow(master, config["shadow_seed"])
    master.save(config["master"])
    return master


def move_patch(canvas: Image.Image, base: Image.Image, box: tuple[int, int, int, int], offset: tuple[int, int]) -> None:
    patch = base.crop(box)
    clear = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]))
    canvas.alpha_composite(clear, (box[0], box[1]))
    canvas.alpha_composite(patch, (box[0] + offset[0], box[1] + offset[1]))


def make_walk_sheet(master: Image.Image, output_path: Path) -> Image.Image:
    base = master.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet = Image.new("RGBA", (TILE_SIZE * 4, TILE_SIZE))
    poses = [
        ((0, 0), (0, 0), (0, 0)),
        ((-1, -1), (-2, -1), (2, 1)),
        ((0, 0), (0, 0), (0, 0)),
        ((1, -1), (2, 1), (-2, -1)),
    ]

    for frame, (body_offset, left_leg_offset, right_leg_offset) in enumerate(poses):
        canvas = Image.new("RGBA", (TILE_SIZE, TILE_SIZE))
        canvas.alpha_composite(base, body_offset)
        move_patch(canvas, base, (18, 45, 34, 64), left_leg_offset)
        move_patch(canvas, base, (33, 45, 50, 64), right_leg_offset)
        sheet.alpha_composite(canvas, (frame * TILE_SIZE, 0))

    sheet.save(output_path)
    return base


def make_aim_sheet(master: Image.Image, output_path: Path) -> None:
    base = master.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    sheet = Image.new("RGBA", (TILE_SIZE * 4, TILE_SIZE))
    poses = [(0, 0, 0.0), (0, 1, -0.5), (0, 0, 0.4), (0, 1, -0.5)]

    for frame, (offset_x, offset_y, angle) in enumerate(poses):
        animated = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
        canvas = Image.new("RGBA", (TILE_SIZE, TILE_SIZE))
        canvas.alpha_composite(animated, (offset_x, offset_y))
        sheet.alpha_composite(canvas, (frame * TILE_SIZE, 0))

    sheet.save(output_path)


def main() -> None:
    for name, config in CHARACTERS.items():
        if not config["raw"].exists():
            raise FileNotFoundError(f"Missing MiniMax source art: {config['raw']}")
        master = make_master(config)
        static = make_walk_sheet(master, config["walk"])
        if config["static"] is not None:
            static.save(config["static"])
        print(f"Built {name}: {config['master'].name}, {config['walk'].name}")

        if "aim_raw" in config:
            aim_config = {
                "raw": config["aim_raw"],
                "master": config["aim_master"],
                "crop": config["aim_crop"],
                "shadow_seed": None,
            }
            aim_master = make_master(aim_config)
            make_aim_sheet(aim_master, config["aim"])
            print(f"Built {name} aim: {config['aim_master'].name}, {config['aim'].name}")


if __name__ == "__main__":
    main()
