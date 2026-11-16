#!/usr/bin/env python3
"""Generate a tileable, neutral grain texture for match-3 cell tiles.

The texture holds no colour of its own. Dark stains are black and light
flecks are white, each with alpha set by how far the grain strays from the
mean. Laid over a flat or gradient face it darkens and lightens that face
like stained paper or worn stone. tools/board_tiles.py bakes it into the
board tile sprites; run this directly only to preview the grain.

    python3 tools/board_grain.py /tmp/grain.png --seed 11
"""
import argparse
import random
from pathlib import Path

from PIL import Image, ImageFilter

# (cells across, cells down, weight): blotchy stains, mottling, streaked fibres, speckle.
OCTAVES = {
    "stain": [(3, 3, .55), (6, 6, .3), (12, 12, .15)],
    "mottle": [(24, 24, .6), (48, 48, .4)],
    "fibre": [(96, 12, .5), (12, 96, .5)],
    "speck": [(256, 256, 1.0)],
}


def tileable_noise(rng, size, cells_x, cells_y):
    """Smooth value noise that wraps at the edges."""
    grid = Image.new("L", (cells_x, cells_y))
    grid.putdata([rng.randrange(256) for _ in range(cells_x * cells_y)])
    tiled = Image.new("L", (cells_x * 3, cells_y * 3))
    for x in range(3):
        for y in range(3):
            tiled.paste(grid, (x * cells_x, y * cells_y))
    big = tiled.resize((size * 3, size * 3), Image.Resampling.BICUBIC)
    return big.crop((size, size, size * 2, size * 2))


def layer(rng, size, octaves):
    out = [0.0] * (size * size)
    for cx, cy, weight in octaves:
        for i, v in enumerate(tileable_noise(rng, size, cx, cy).getdata()):
            out[i] += weight * (v / 255 - .5)
    return out


def normalise(values):
    peak = max(abs(v) for v in values) or 1
    return [v / peak for v in values]


DEFAULTS = {"size": 512, "seed": 7, "stain": .55, "rings": .35, "mottle": .3, "fibre": .18,
            "speck": .12, "strength": .9}


def render(size=512, seed=7, stain=.55, rings=.35, mottle=.3, fibre=.18, speck=.12, strength=.9):
    """The grain as an RGBA image: black stains and white flecks with alpha."""
    rng = random.Random(seed)
    stains = normalise(layer(rng, size, OCTAVES["stain"]))
    mottles = normalise(layer(rng, size, OCTAVES["mottle"]))
    fibres = normalise(layer(rng, size, OCTAVES["fibre"]))
    specks = normalise(layer(rng, size, OCTAVES["speck"]))
    # Tide marks: dark where a stain blotch crosses its middle value.
    tides = [max(0.0, 1 - abs(v) * 6) for v in stains]
    grain = [stain * s - rings * r + mottle * m + fibre * f + speck * k
             for s, r, m, f, k in zip(stains, tides, mottles, fibres, specks)]
    mean = sum(grain) / len(grain)
    grain = normalise([g - mean for g in grain])
    shade = Image.new("L", (size, size))
    shade.putdata([255 if g > 0 else 0 for g in grain])
    alpha = Image.new("L", (size, size))
    alpha.putdata([min(255, round(abs(g) * 255 * strength)) for g in grain])
    # A touch of softening keeps the speckle from aliasing when a cell is small.
    alpha = alpha.filter(ImageFilter.GaussianBlur(.6))
    return Image.merge("RGBA", (shade, shade, shade, alpha))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("out", type=Path)
    for key, value in DEFAULTS.items():
        parser.add_argument("--" + key, type=type(value), default=value)
    args = parser.parse_args()
    params = {key: getattr(args, key) for key in DEFAULTS}
    render(**params).save(args.out, optimize=True)


if __name__ == "__main__":
    main()
