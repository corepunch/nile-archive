#!/usr/bin/env python3
"""Prepare the painted Pause plate and pack four shared campaign actions."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
RELIC = ROOT / "games/relic-rush"
MANIFEST = ROOT / "art/match3-buttons/manifest.json"
sys.path.insert(0, str(RELIC / "tools"))
from prepare_bonus_gems import bevel, pack, png_matches


def pause_parts(source, box):
    # Recover the ivory face beneath the bars from undisturbed paint on either side.
    base = source.copy()
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        left, right = source.getpixel((x0 - 1, y)), source.getpixel((x1, y))
        for x in range(x0, x1):
            weight = (x - x0 + 1) / (x1 - x0 + 1)
            base.putpixel((x, y), tuple(round(a + (b - a) * weight) for a, b in zip(left, right)))
    glyph = source.crop(box)
    darkness = ImageChops.subtract(base.crop(box).getchannel("G"), glyph.getchannel("G"))
    glyph.putalpha(darkness.point(lambda a: min(255, max(0, (a - 8) * 4))))
    return base, glyph


def navigation_glyph(source, box):
    # The old navigation marks are cream on dark painted faces.
    shape = source.crop(box).getchannel("B").point(lambda a: min(255, max(0, (a - 82) * 3)))
    ink = bevel(Image.new("RGB", shape.size, (123, 63, 28)), shape, 2, shadow=.55, highlight=1.5)
    ink.putalpha(shape)
    return ink


def write(path, image, check):
    if check:
        assert png_matches(path, image), f"Stale {path.relative_to(ROOT)}. Run tools/match3_buttons.py"
    else:
        image.save(path, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads(MANIFEST.read_text())
    recipe = json.loads((RELIC / "art/board-states/manifest.json").read_text())["bonus_gems"]
    with Image.open(ROOT / spec["source"]) as source:
        base, pause = pause_parts(source, spec["pause_glyph"])
    write(ROOT / spec["base"], base, args.check)
    glyphs = {"pause": pause}
    for name, box in spec["navigation_crops"].items():
        with Image.open(ROOT / spec["navigation_dir"] / f"{name}-normal.png") as source:
            glyphs[name] = navigation_glyph(source, box)
    atlas = pack({**recipe, "columns": spec["columns"], "icon_sizes": spec["icon_sizes"]},
                 icons=[glyphs[key] for key in spec["columns"]])
    for path in spec["runtime"]:
        write(ROOT / path, atlas, args.check)


if __name__ == "__main__":
    main()
