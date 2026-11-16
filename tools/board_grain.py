#!/usr/bin/env python3
"""Generate a tileable, neutral grain texture for match-3 cell materials.

The texture holds no colour of its own. Dark stains are black and light
flecks are white, each with alpha set by how far the grain strays from the
mean. Drawn over a flat or gradient face it darkens and lightens that face
like stained paper or worn stone, so a skin chooses every colour. The game
cuts the hex out of it at draw time, so there is no separate mask.

    python3 tools/board_grain.py games/relic-rush/data/board-grain.png
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


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("out", type=Path)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--stain", type=float, default=.55, help="large soft blotches")
    parser.add_argument("--rings", type=float, default=.35, help="dark tide marks at blotch edges")
    parser.add_argument("--mottle", type=float, default=.3)
    parser.add_argument("--fibre", type=float, default=.18)
    parser.add_argument("--speck", type=float, default=.12)
    parser.add_argument("--strength", type=float, default=.9, help="alpha at the strongest grain")
    parser.add_argument("--check", action="store_true", help="fail if the file differs from a fresh render")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    size = args.size
    stain = normalise(layer(rng, size, OCTAVES["stain"]))
    mottle = normalise(layer(rng, size, OCTAVES["mottle"]))
    fibre = normalise(layer(rng, size, OCTAVES["fibre"]))
    speck = normalise(layer(rng, size, OCTAVES["speck"]))
    # Tide marks: dark where a stain blotch crosses its middle value.
    rings = [max(0.0, 1 - abs(s) * 6) for s in stain]

    grain = [args.stain * s - args.rings * r + args.mottle * m + args.fibre * f + args.speck * k
             for s, r, m, f, k in zip(stain, rings, mottle, fibre, speck)]
    mean = sum(grain) / len(grain)
    grain = normalise([g - mean for g in grain])

    shade = Image.new("L", (size, size))
    shade.putdata([255 if g > 0 else 0 for g in grain])
    alpha = Image.new("L", (size, size))
    alpha.putdata([min(255, round(abs(g) * 255 * args.strength)) for g in grain])
    # A touch of softening keeps the speckle from aliasing when a cell is small.
    alpha = alpha.filter(ImageFilter.GaussianBlur(.6))
    out = Image.merge("RGBA", (shade, shade, shade, alpha))
    if args.check:
        current = Image.open(args.out).convert("RGBA")
        assert current.size == out.size and current.tobytes() == out.tobytes(), f"Stale grain texture: {args.out}"
        return
    args.out.parent.mkdir(parents=True, exist_ok=True)
    out.save(args.out, optimize=True)


if __name__ == "__main__":
    main()
