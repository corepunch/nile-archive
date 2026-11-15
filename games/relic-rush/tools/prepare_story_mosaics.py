#!/usr/bin/env python3
"""Register paintings for mosaic reveals and verify the decoded runtime images.

A picture with a "mosaic" entry also gets a stone version for play: every
board cell is paved with small flat-top hexagonal stones, each a single
colour, cut to fit the cell, with a thin dark joint between cells. The
finished painting replaces it on the win.
"""
import argparse
from io import BytesIO
import json
import math
from pathlib import Path
import random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps, ImageStat

ROOT = Path(__file__).resolve().parents[1]
SUPERSAMPLE = 3
ROOT3 = math.sqrt(3)


def hexagon(cx, cy, radius):
    return [(cx + radius * math.cos(k * math.pi / 3), cy + radius * math.sin(k * math.pi / 3)) for k in range(6)]


def in_hexagon(dx, dy, radius):
    dx, dy = abs(dx), abs(dy)
    return dy <= ROOT3 / 2 * radius and ROOT3 * dx + dy <= ROOT3 * radius


def hex_stones(image, cells_across, per_cell, grout, joint, seed):
    """Pave each board cell of `image` with hexagonal stones.

    The runtime lays the picture centred across a board `cells_across` cell
    radii wide, so a cell's radius here is the width over that. Stones are
    `per_cell` to a cell radius, which puts a stone on every cell centre and,
    when per_cell % 3 == 1, a stone corner on every cell corner.
    """
    rng = random.Random(seed)
    w, h = image.size
    big = w / cells_across
    small = big / per_cell
    soft = image.filter(ImageFilter.GaussianBlur(small * .55)).load()   # a stone's average colour
    bed = image.filter(ImageFilter.GaussianBlur(small * 2))
    canvas = ImageEnhance.Brightness(bed).enhance(.3).resize((w * SUPERSAMPLE, h * SUPERSAMPLE))   # joints
    grouted = ImageEnhance.Brightness(bed).enhance(.55)
    reach = math.ceil(max(w, h) / big)
    tile_w, tile_h = math.ceil(2 * big) + 4, math.ceil(ROOT3 * big) + 4
    for q in range(-reach, reach + 1):
        for r in range(-reach, reach + 1):
            cx, cy = w / 2 + 1.5 * big * q, h / 2 + ROOT3 * big * (r + q / 2)
            if not (-big < cx < w + big and -big < cy < h + big):
                continue
            left, top = math.floor(cx - big) - 2, math.floor(cy - ROOT3 / 2 * big) - 2
            box = (left, top, left + tile_w, top + tile_h)
            tile = grouted.crop(box).resize((tile_w * SUPERSAMPLE, tile_h * SUPERSAMPLE))
            draw = ImageDraw.Draw(tile)

            def local(points, shift=0):
                return [((x - left + shift) * SUPERSAMPLE, (y - top + shift) * SUPERSAMPLE) for x, y in points]

            for a in range(-per_cell - 1, per_cell + 2):
                for b in range(-per_cell - 1, per_cell + 2):
                    dx, dy = 1.5 * small * a, ROOT3 * small * (b + a / 2)
                    if not in_hexagon(dx, dy, big + small):
                        continue
                    # A stone cut by the cell's edge takes its colour from the part inside.
                    pull = 0 if in_hexagon(dx, dy, big - small) else .5 * small / max(1e-6, math.hypot(dx, dy))
                    sx = min(w - 1, max(0, round(cx + dx * (1 - pull))))
                    sy = min(h - 1, max(0, round(cy + dy * (1 - pull))))
                    shade = rng.uniform(.95, 1.05)   # hand-cut stones never match exactly
                    base = tuple(min(255, round(v * shade)) for v in soft[sx, sy])
                    lit = tuple(min(255, round(v * 1.12 + 8)) for v in base)
                    face = small - grout / ROOT3
                    draw.polygon(local(hexagon(cx + dx, cy + dy, face)), fill=lit)              # a lit upper-left edge
                    draw.polygon(local(hexagon(cx + dx, cy + dy, face - .8), .4), fill=base)   # the stone's face
            mask = Image.new("L", tile.size, 0)
            ImageDraw.Draw(mask).polygon(local(hexagon(cx, cy, big - joint / ROOT3)), fill=255)
            canvas.paste(tile, (left * SUPERSAMPLE, top * SUPERSAMPLE), mask)
    return canvas.resize((w, h), Image.Resampling.LANCZOS)


def encode(image):
    encoded = BytesIO()
    image.save(encoded, format="JPEG", quality=91, subsampling=0, optimize=True)
    return encoded


def settle(path, encoded, check, name):
    if not check:
        path.write_bytes(encoded.getvalue())
        return
    with Image.open(path) as actual, Image.open(encoded) as expected:
        assert actual.format == "JPEG" and actual.mode == "RGB", name
        assert actual.size == expected.size, name
        # Allow minor JPEG encoder differences between platforms.
        error = ImageStat.Stat(ImageChops.difference(actual, expected))
        assert max(error.mean) <= 0.5, (
            f"{name}: rebuild with python3 games/relic-rush/tools/prepare_story_mosaics.py"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    manifest = json.loads((ROOT / "art/board-states/manifest.json").read_text())
    for name, mosaic in manifest["story_mosaics"]["pictures"].items():
        path = ROOT / mosaic["runtime"]
        with Image.open(ROOT / mosaic["source"]) as master:
            image = ImageOps.fit(master.convert("RGB"), mosaic["size"], Image.Resampling.LANCZOS)
        settle(path, encode(image), args.check, name)
        cut = mosaic.get("mosaic")
        if cut:
            stones = hex_stones(image, cut["cells_across"], cut["stones_per_cell"], cut["grout"], cut["joint"],
                                cut["seed"])
            settle(ROOT / cut["runtime"], encode(stones), args.check, name + " mosaic")
        print(f"{name}: {image.width}×{image.height} authored painting")


if __name__ == "__main__":
    main()
