#!/usr/bin/env python3
"""Make the oil artwork. Homescapes draws oil in a shader (oil.fsh) rather
than from a sprite: a golden liquid (its OIL_COLOR, 1.0/0.88/0.44) with two
layers of bubbles scrolling through it. These seamless tiles feed the same
look through the engine's SDF patch (engine/match3_elements_view.lua):

  oil-material.png  golden liquid with slow swirls; tiles seamlessly
  oil-bubbles.png   translucent bubbles on transparency; tiles seamlessly
  goal-oil.png      HUD goal icon, the carpet icon's rounded hex in oil

    python3 tools/oil_art.py          # write them
    python3 tools/oil_art.py --check  # fail if any is stale
"""
import argparse
import io
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from carpet_goal_icon import hex_distance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'engine/art/match3'
TILE = 128
DEEP, LIGHT = (205, 138, 30), (255, 225, 112)   # around Homescapes' OIL_COLOR
# Seamless bubbles: centre (in tile units), radius (px). Positions wrap.
BUBBLES = [(.12, .18, 9), (.47, .09, 5), (.78, .31, 11), (.29, .55, 6), (.63, .66, 8),
           (.91, .83, 5), (.08, .86, 7), (.40, .92, 4), (.70, .02, 4), (.20, .36, 3)]


def swirl(u, v):
    """Seamless 0..1 field from whole-period sines over the tile."""
    t = 2 * math.pi
    s = (math.sin(t * (u + .35 * math.sin(t * v))) + .6 * math.sin(t * (2 * v + .25 * math.sin(t * 2 * u)))
         + .35 * math.sin(t * (3 * u + 2 * v)))
    return .5 + s / 3.9


def material(size=TILE):
    image = Image.new('RGB', (size, size))
    px = image.load()
    for y in range(size):
        for x in range(size):
            f = swirl(x / size, y / size)
            glint = max(0., f - .8) * 2.2   # soft bright crests, like light on a liquid
            px[x, y] = tuple(min(255, int(DEEP[c] + (LIGHT[c] - DEEP[c]) * (.25 + .6 * f) + 30 * glint)) for c in range(3))
    return image


def bubble_layer(size=TILE, ss=4):
    side = size * ss
    image = Image.new('RGBA', (side, side))
    px = image.load()
    for y in range(side):
        for x in range(side):
            r = g = b = a = 0.
            for (bu, bv, rad) in BUBBLES:
                rad *= ss
                # Nearest wrapped copy, so bubbles crossing an edge stay whole.
                dx = (x + .5 - bu * side + side / 2) % side - side / 2
                dy = (y + .5 - bv * side + side / 2) % side - side / 2
                d = math.hypot(dx, dy)
                if d > rad + ss: continue
                edge = max(0., min(1., (rad - d) / ss + .5))
                rim = max(0., 1 - abs(d - rad * .86) / (rad * .2))
                spot = max(0., 1 - math.hypot(dx + rad * .35, dy + rad * .35) / (rad * .32))
                alpha = edge * (.16 + .5 * rim + .8 * spot)
                if alpha > a: r, g, b, a = 255, 246, 214, alpha
            px[x, y] = (int(r), int(g), int(b), int(min(1., a) * 255))
    return image.resize((size, size), Image.Resampling.LANCZOS)


def icon(size=TILE, ss=4):
    """The carpet goal icon's shape, filled with oil and a few bubbles."""
    side = size * ss
    liquid = material(side // 2).resize((side, side), Image.Resampling.BICUBIC)
    bubbles = bubble_layer(size).resize((side, side), Image.Resampling.BICUBIC)
    apothem, corner, rim = .45 * side * math.sqrt(3) / 2, .14 * side, .06 * side
    centre = side / 2 - .02 * side
    src, bub = liquid.load(), bubbles.load()
    out, mask = Image.new('RGBA', (side, side)), Image.new('L', (side, side))
    px, mk = out.load(), mask.load()
    for y in range(side):
        for x in range(side):
            dx, dy = x + .5 - side / 2, y + .5 - centre
            d = hex_distance(dx, dy, apothem - corner) - corner
            if d > ss: continue
            a = max(0., min(1., .5 - d / ss))
            mk[x, y] = int(a * 255)
            depth, light = -d, -dy / (math.hypot(dx, dy) or 1)
            if depth < rim:   # rounded amber rim, lit from above
                crown = math.sin(math.pi * max(0., min(1., depth / rim)))
                shade = .72 + .36 * crown + .2 * light * crown
                r, g, b = 196, 118, 22
            else:
                r, g, b = src[x, y]
                shade = 1 - .4 * max(0., 1 - (depth - rim) / (.07 * side))
                br, bg_, bb, ba = bub[x, y]
                k = ba / 255 * .9
                r, g, b = r + (br - r) * k, g + (bg_ - g) * k, b + (bb - b) * k
            # Gloss: a soft crescent of light in the upper left, as on a glossy liquid.
            g_off = math.hypot((dx + .1 * side) / 1.6, dy + .2 * side) / (.16 * side)
            gloss = max(0., 1 - g_off) ** 2 * .35 if depth > rim else 0
            shade *= 1.08 - .16 * (y / side)
            px[x, y] = tuple(min(255, int(c * shade + 255 * gloss)) for c in (r, g, b)) + (int(a * 255),)
    shadow = Image.new('RGBA', (side, side))
    shadow.putalpha(mask.point(lambda v: v * 95 // 255))
    moved = Image.new('RGBA', (side, side))
    moved.paste(shadow, (0, int(.035 * side)))
    moved = moved.filter(ImageFilter.GaussianBlur(.025 * side))
    return Image.alpha_composite(moved, out).resize((size, size), Image.Resampling.LANCZOS)


def encode(image):
    buf = io.BytesIO()
    image.save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true')
    check = parser.parse_args().check
    for name, image in (('oil-material', material().convert('RGBA')), ('oil-bubbles', bubble_layer()), ('goal-oil', icon())):
        path, data = OUT / f'{name}.png', encode(image)
        if check:
            assert path.read_bytes() == data, f'{path.relative_to(ROOT)} is stale: run python3 tools/oil_art.py'
        else:
            path.write_bytes(data)
        print(f'{path.relative_to(ROOT)}: {"verified" if check else "written"}')


if __name__ == '__main__':
    main()
