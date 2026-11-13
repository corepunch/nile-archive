#!/usr/bin/env python3
"""Make the carpet goal icon: one rounded flat-top hex of the original
Homescapes carpet swatch inside a smooth green rim, the pebbles set in under
it, lit from above, with a soft drop shadow. It follows Homescapes' own
square carpet goal and the board's rounded carpet patch.

Only the swatch's paint is used; the shape and shading are computed here.
    python3 tools/carpet_goal_icon.py          # write the icon
    python3 tools/carpet_goal_icon.py --check  # fail if it is stale
"""
import argparse
import io
import math
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SWATCH = ROOT / 'engine/art/homescapes/sprites/carpet-swatch.png'
OUT = ROOT / 'engine/art/match3/goal-carpet.png'
SIZE, SS = 128, 4            # output side, supersampling
RADIUS = .45                 # centre to vertex, of the side
CORNER = .14                 # convex corner rounding, of the side
RIM = .06                    # smooth rim band inside the edge
RIM_COLOUR = (22, 128, 30)   # sampled from the swatch's mid-tone green
INSET = .07                  # pebbles darken as they pass under the rim


def hex_distance(x, y, r):
    """Signed distance to a flat-top hexagon of apothem r (Inigo Quilez)."""
    kx, ky, kz = -0.866025404, 0.5, 0.577350269
    x, y = abs(x), abs(y)
    d = min(kx * x + ky * y, 0)
    x, y = x - 2 * d * kx, y - 2 * d * ky
    x -= max(-kz * r, min(kz * r, x))
    y -= r
    return math.hypot(x, y) * (-1 if y < 0 else 1)


def render():
    side = SIZE * SS
    swatch = Image.open(SWATCH).convert('RGB')
    tile = swatch.resize((side, side), Image.Resampling.LANCZOS)   # about ten pebbles across, as Homescapes' icon
    paint = Image.new('RGB', (side, side))
    for x in range(0, side, tile.width):
        for y in range(0, side, tile.height):
            paint.paste(tile, (x, y))
    apothem = RADIUS * side * math.sqrt(3) / 2
    corner, rim, inset = CORNER * side, RIM * side, INSET * side
    centre = side / 2 - .02 * side   # a little high, leaving room for the shadow
    src, out = paint.load(), Image.new('RGBA', (side, side))
    px, mask = out.load(), Image.new('L', (side, side))
    mk = mask.load()
    for y in range(side):
        for x in range(side):
            dx, dy = x + .5 - side / 2, y + .5 - centre
            d = hex_distance(dx, dy, apothem - corner) - corner
            if d > SS: continue
            a = max(0., min(1., .5 - d / SS))
            mk[x, y] = int(a * 255)
            depth = -d   # inside distance
            light = -dy / (math.hypot(dx, dy) or 1)   # +1 at the top edge, -1 at the bottom
            if depth < rim:
                # Rounded rim: brightest along its crown, lit from above.
                t = depth / rim
                crown = math.sin(math.pi * max(0., min(1., t)))
                shade = .78 + .34 * crown + .22 * light * crown
                r, g, b = RIM_COLOUR
            else:
                r, g, b = src[x, y]
                shade = 1 - .45 * max(0., 1 - (depth - rim) / inset)   # set in under the rim
            shade *= 1.1 - .2 * (y / side)   # gentle top-to-bottom falloff
            px[x, y] = (min(255, int(r * shade)), min(255, int(g * shade)), min(255, int(b * shade)), int(a * 255))
    shadow = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    shadow.putalpha(mask.point(lambda v: v * 95 // 255))
    moved = Image.new('RGBA', (side, side))
    moved.paste(shadow, (0, int(.035 * side)))
    moved = moved.filter(ImageFilter.GaussianBlur(.025 * side))
    icon = Image.alpha_composite(moved, out)
    return icon.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


def encode(image):
    buf = io.BytesIO()
    image.save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true')
    data = encode(render())
    if parser.parse_args().check:
        assert OUT.read_bytes() == data, f'{OUT.relative_to(ROOT)} is stale: run python3 tools/carpet_goal_icon.py'
        print(f'{OUT.relative_to(ROOT)}: verified')
        return
    OUT.write_bytes(data)
    print(f'wrote {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
