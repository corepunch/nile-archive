#!/usr/bin/env python3
"""Register separately paintable board decorations from the source atlas."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "engine/art/board-frame/decorations.json"


def register(source, spec, size):
    crop = spec["crop"]
    image = source.crop(crop)
    alpha = image.getchannel("A")
    # Clear the faint background matte outside the painting. The six-pixel
    # allowance preserves the sprite's own semitransparent edge pixels.
    painted = alpha.point(lambda value: 255 if value >= 64 else 0)
    image.putalpha(ImageChops.multiply(alpha, painted.filter(ImageFilter.MaxFilter(13))))
    x, y = (anchor - margin for anchor, margin in zip(spec["anchor"], crop[:2]))
    supersample = 3
    canvas = size * supersample
    centre = canvas / 2
    angle = math.radians(spec["turn"])
    scale = spec["scale"] * supersample
    a, b = math.cos(angle) / scale, math.sin(angle) / scale
    # Inverse transform. The authored stem or edge contact point sits at the
    # centre of the runtime canvas. RGB and authored alpha travel together.
    mapped = image.transform((canvas, canvas), Image.Transform.AFFINE,
                             (a, b, x - centre * (a + b), -b, a, y - centre * (a - b)),
                             Image.Resampling.BICUBIC)
    return mapped.resize((size, size), Image.Resampling.LANCZOS)


def main():
    spec = json.loads(SPEC.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", choices=tuple(spec["games"]))
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    assert (ROOT / spec["prompt"]).is_file()
    games = (args.game,) if args.game else spec["games"]
    with Image.open(ROOT / spec["source"]) as source:
        assert source.mode == "RGBA"
        for game in games:
            for key, sprite in spec["games"][game].items():
                registered = register(source, sprite, spec["size"])
                alpha = registered.getchannel("A")
                bounds = alpha.point(lambda a: 255 if a >= 64 else 0).getbbox()
                size = spec["size"]
                assert bounds and min(*bounds[:2], size - bounds[2], size - bounds[3]) >= 2, key
                path = ROOT / "games" / game / "data/board-frame" / f"{key}.png"
                if args.check:
                    with Image.open(path) as current:
                        assert current.mode == "RGBA" and current.size == registered.size, path
                        assert current.tobytes() == registered.tobytes(), f"Stale decoration: {path}"
                else:
                    registered.save(path, optimize=True)


if __name__ == "__main__":
    main()
