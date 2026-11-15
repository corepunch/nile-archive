#!/usr/bin/env python3
"""Register paintings for mosaic reveals and verify the decoded runtime images.

A picture with a "mosaic" entry also gets a tesserae version for play: the
painting is cut into small, slightly irregular stone tiles, each a single
colour, set in dark grout. The finished painting replaces it on the win.
"""
import argparse
from io import BytesIO
import json
from pathlib import Path
import random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps, ImageStat

ROOT = Path(__file__).resolve().parents[1]
SUPERSAMPLE = 3


def tesserae(image, tile, grout, jitter, seed):
    """Cut `image` into jittered quads of about `tile` pixels with `grout` pixels between them."""
    rng = random.Random(seed)
    w, h = image.size
    cols, rows = round(w / tile), round(h / tile)
    tw, th = w / cols, h / rows
    stones = image.resize((cols, rows), Image.Resampling.BOX).load()   # each stone's average colour
    # Grout follows the painting's local tone, so seams never read as a black net.
    bed = ImageEnhance.Brightness(image.filter(ImageFilter.GaussianBlur(tile))).enhance(.5)
    canvas = bed.resize((w * SUPERSAMPLE, h * SUPERSAMPLE), Image.Resampling.BILINEAR)
    draw = ImageDraw.Draw(canvas)
    corner = [[(c * tw + (rng.uniform(-jitter, jitter) * tw if 0 < c < cols else 0),
                r * th + (rng.uniform(-jitter, jitter) * th if 0 < r < rows else 0))
               for c in range(cols + 1)] for r in range(rows + 1)]

    def quad(points, inset, shift=0):
        cx, cy = sum(p[0] for p in points) / 4, sum(p[1] for p in points) / 4
        out = []
        for x, y in points:
            dx, dy = x - cx, y - cy
            k = max(0, 1 - inset / max(1e-6, (dx * dx + dy * dy) ** .5))
            out.append(((cx + dx * k + shift) * SUPERSAMPLE, (cy + dy * k + shift) * SUPERSAMPLE))
        return out

    for r in range(rows):
        for c in range(cols):
            points = [corner[r][c], corner[r][c + 1], corner[r + 1][c + 1], corner[r + 1][c]]
            shade = rng.uniform(.95, 1.05)   # hand-cut stones never match exactly
            base = tuple(min(255, round(v * shade)) for v in stones[c, r])
            lit = tuple(min(255, round(v * 1.14 + 8)) for v in base)
            draw.polygon(quad(points, grout * .7), fill=lit)              # a lit upper-left edge
            draw.polygon(quad(points, grout * .7 + .8, .45), fill=base)   # the stone's face
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
            stones = tesserae(image, cut["tile"], cut["grout"], cut["jitter"], cut["seed"])
            settle(ROOT / cut["runtime"], encode(stones), args.check, name + " mosaic")
        print(f"{name}: {image.width}×{image.height} authored painting")


if __name__ == "__main__":
    main()
