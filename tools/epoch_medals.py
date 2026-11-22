#!/usr/bin/env python3
"""Register the authored medallions and parchment for the epoch chooser."""

import argparse
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GAMES = ("relic-rush", "christmas-market")
CELL = 240


def trim_alpha(image):
    silhouette = image.getchannel("A").point(lambda value: 255 if value >= 64 else 0)
    left, top, right, bottom = silhouette.getbbox()
    return image.crop((max(0, left-3), max(0, top-3),
                       min(image.width, right+3), min(image.height, bottom+3)))


def register(game):
    with Image.open(game / "art/epoch-medals/source.png") as source:
        assert source.mode == "RGBA" and source.width * 2 == source.height * 3
        step = source.width // 3
        atlas = Image.new("RGBA", (CELL * 3, CELL * 2))
        for index in range(6):
            column, row = index % 3, index // 3
            x, y = column * step, row * step
            tile = trim_alpha(source.crop((x, y, x + step, y + step)))
            tile.thumbnail((CELL-16, CELL-16), Image.Resampling.LANCZOS)
            atlas.paste(tile, (column*CELL + (CELL-tile.width)//2, row*CELL + (CELL-tile.height)//2))
        return atlas


def write(path, artwork, check):
    if check:
        with Image.open(path) as current:
            assert current.mode == artwork.mode and current.size == artwork.size, f"Wrong image format: {path}"
            assert current.tobytes() == artwork.tobytes(), f"Stale epoch artwork: {path}"
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        artwork.save(path, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name in GAMES:
        game = ROOT / "games" / name
        write(game / "data/city/epochs/medals.png", register(game), args.check)
        print(f"{name}: 6 authored epoch medallions registered")
    engine = ROOT / "engine"
    with Image.open(engine / "art/epoch-scroll/source.png") as source:
        assert source.mode == "RGBA"
        scroll = trim_alpha(source)
        scroll.thumbnail((944, 944), Image.Resampling.LANCZOS)
    write(engine / "data/board/epoch-scroll.png", scroll, args.check)
    print("Match-3 epoch chooser: authored parchment registered")


if __name__ == "__main__":
    main()
