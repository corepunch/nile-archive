#!/usr/bin/env python3
"""Measure a building sprite's ground footprint for the city's building specs.

    python3 tools/footprint.py sprite.png [--bottom X,Y] [--left X] [--right X] [--overlay out.png]

Rendered buildings carry exact registration; this is for art drawn by hand. A
base's lower edge is a V whose two slopes come from the city camera (see
tools/city_camera.py). With no hints the script fits that V to the lowest opaque
pixel of every column; plants or props hanging below the base can fool it, so
read the corners off the sprite and pass them instead: --bottom is the base's
front corner, --left and --right the x of its side corners. It prints the pivot
(the footprint's ground centre), base_width and the w : h ratio to round to whole
tiles, and can draw the measured base over the sprite. Check the result in the
game with --footprints (see docs/BUILDINGS.md).
"""
import argparse
from PIL import Image, ImageDraw
from city_camera import U, V

LEFT_SLOPE, RIGHT_SLOPE = U[1] / U[0], V[1] / -V[0]


def drop(x, xb):
    """How far above the front corner the base's edge is at column x."""
    return (xb - x) * LEFT_SLOPE if x < xb else (x - xb) * RIGHT_SLOPE


def fit(alpha, w, h):
    low = []
    for x in range(w):
        ys = [y for y in range(h) if alpha[x, y] > 160]
        low.append(max(ys) if ys else None)
    best = None
    for xb in range(w):
        for yb in range(int(h * .6), h):
            score = sum(1 for x in range(w) if low[x] is not None and abs(low[x] - (yb - drop(x, xb))) <= 3)
            if best is None or score > best[0]:
                best = (score, xb, yb)
    _, xb, yb = best
    on = [x for x in range(w) if low[x] is not None and abs(low[x] - (yb - drop(x, xb))) <= 4]
    return (xb, yb), min(on), max(on)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('sprite')
    ap.add_argument('--bottom', help='X,Y of the base\'s front corner')
    ap.add_argument('--left', type=float, help='x of the base\'s left corner')
    ap.add_argument('--right', type=float, help='x of the base\'s right corner')
    ap.add_argument('--overlay', help='write the sprite with the measured base drawn over it')
    a = ap.parse_args()

    im = Image.open(a.sprite).convert('RGBA')
    w, h = im.size
    (xb, yb), xl, xr = fit(im.getchannel('A').load(), w, h)
    if a.bottom:
        xb, yb = (float(v) for v in a.bottom.split(','))
    xl = a.left if a.left is not None else xl
    xr = a.right if a.right is not None else xr

    left, right = (xl, yb - drop(xl, xb)), (xr, yb - drop(xr, xb))
    pivot = ((left[0] + right[0]) / 2, (left[1] + right[1]) / 2)
    print(f'{a.sprite}: {w}x{h} px')
    print(f'  front corner ({xb:g}, {yb:g}), left corner {left}, right corner {right}')
    print(f'  pivot = vec2({pivot[0]:.0f}, {pivot[1]:.0f}), base_width = {xr - xl:.0f}')
    ratio = ((xb - xl) / U[0]) / max(1, (xr - xb) / -V[0])
    print(f'  size w : h = {ratio:.2f} (round to whole tiles)')

    if a.overlay:
        out = im.copy()
        d = ImageDraw.Draw(out)
        top = (left[0] + right[0] - xb, left[1] + right[1] - yb)
        d.polygon([left, (xb, yb), right, top], outline=(255, 0, 255, 255))
        d.ellipse([pivot[0] - 3, pivot[1] - 3, pivot[0] + 3, pivot[1] + 3], fill=(255, 255, 0, 255))
        out.save(a.overlay)


if __name__ == '__main__':
    main()
