#!/usr/bin/env python3
"""Make the oil artwork. Homescapes draws oil in a shader (oil.fsh) rather
than from a sprite: a golden liquid (its OIL_COLOR, 1.0/0.88/0.44) with two
layers of bubbles scrolling through it. These seamless tiles feed the same
look through the engine's SDF patch (engine/match3_elements_view.lua):

  oil-material.png  golden liquid with slow swirls; tiles seamlessly
  oil-bubbles.png   translucent bubbles on transparency; tiles seamlessly
  goal-oil.png      HUD goal icon, the carpet icon's rounded hex in oil
  oil-can-2.png     oil can blocker, two hits left: sealed red can, brass fittings
  oil-can-1.png     one hit left: the same can dented, cap off, oil dripping

Homescapes' oil can (OIL_CAN) art is not in our extract, so both can states
are drawn here together, from one shape, so they stay registered.

    python3 tools/oil_art.py          # write them
    python3 tools/oil_art.py --check  # fail if any is stale
"""
import argparse
import io
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageChops

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


RED, BRASS, OIL = (214, 58, 42), (226, 176, 70), (240, 178, 50)


def cylinder(mask, rgb, left, right, light=.32, floor=.5):
    """Fill mask with rgb shaded as a vertical cylinder spanning left..right."""
    w, h = mask.size
    shade = Image.new('RGB', (w, h))
    px = shade.load()
    for x in range(w):
        t = (x - left) / max(1, right - left)
        k = floor + (1.25 - floor) * max(0., math.cos((t - light) * math.pi * .9)) + .35 * max(0., 1 - abs(t - light) / .05)
        col = tuple(min(255, int(c * k)) for c in rgb)
        for y in range(h): px[x, y] = col
    out = Image.new('RGBA', (w, h))
    out.paste(shade, (0, 0), mask)
    return out


def oil_can(hp, size=TILE, ss=4):
    S = size * ss
    def P(x, y): return (x * S, y * S)
    def mask(draw_fn):
        m = Image.new('L', (S, S)); draw_fn(ImageDraw.Draw(m)); return m
    layers = []
    body_l, body_r, top, bottom = .22, .70, .44, .84
    # Handle behind the body, then the spout.
    handle = mask(lambda d: d.arc([*P(.08, .46), *P(.36, .80)], 90, 270, fill=255, width=int(.055 * S)))
    layers.append(cylinder(handle, BRASS, .08 * S, .3 * S))
    spout_pts = [P(.60, .44), P(.66, .38), P(.93, .13), P(.95, .17), P(.70, .47)]
    if hp == 1: spout_pts = [P(.60, .44), P(.66, .38), P(.88, .20), P(.92, .27), P(.70, .47)]   # bent
    spout = mask(lambda d: d.polygon(spout_pts, fill=255))
    layers.append(cylinder(spout, BRASS, .6 * S, .95 * S, light=.4))
    # Body: cylinder with a rounded bottom rim.
    body = mask(lambda d: d.rounded_rectangle([*P(body_l, top), *P(body_r, bottom)], radius=int(.05 * S), fill=255))
    layers.append(cylinder(body, RED, body_l * S, body_r * S))
    # Shoulder cone up to the neck, with the top ellipse.
    cone = mask(lambda d: (d.polygon([P(body_l + .01, top + .02), P(.39, .29), P(.53, .29), P(body_r - .01, top + .02)], fill=255),
                            d.ellipse([*P(body_l, top - .035), *P(body_r, top + .045)], fill=255)))
    layers.append(cylinder(cone, (196, 50, 38), body_l * S, body_r * S, light=.3, floor=.55))
    neck = mask(lambda d: d.rectangle([*P(.40, .22), *P(.52, .31)], fill=255))
    layers.append(cylinder(neck, BRASS, .40 * S, .52 * S))
    if hp == 2:   # sealed: a brass cap knob
        cap = mask(lambda d: d.rounded_rectangle([*P(.38, .15), *P(.54, .23)], radius=int(.025 * S), fill=255))
        layers.append(cylinder(cap, BRASS, .38 * S, .54 * S))
    # Label band with an oil drop.
    band = mask(lambda d: d.rectangle([*P(body_l, .58), *P(body_r, .71)], fill=255))
    layers.append(cylinder(ImageChops.multiply(band, body), (238, 196, 92), body_l * S, body_r * S))
    drop = mask(lambda d: (d.ellipse([*P(.415, .615), *P(.475, .685)], fill=255), d.polygon([P(.418, .64), P(.445, .585), P(.472, .64)], fill=255)))
    layers.append(cylinder(drop, (176, 92, 18), .41 * S, .48 * S, floor=.8))
    # Bottom rim shadow line.
    rim = mask(lambda d: d.rounded_rectangle([*P(body_l, bottom - .035), *P(body_r, bottom)], radius=int(.03 * S), fill=255))
    layers.append(cylinder(rim, (150, 36, 28), body_l * S, body_r * S))
    if hp == 1:
        # Dent: a dark crescent with a lit lip, and a scratch.
        dent = mask(lambda d: d.ellipse([*P(.50, .47), *P(.66, .57)], fill=255))
        dent = ImageChops.multiply(dent, body)
        layers.append(cylinder(dent, (168, 40, 30), .5 * S, .66 * S, light=.8, floor=.75))
        lip = mask(lambda d: d.arc([*P(.50, .47), *P(.66, .57)], 200, 330, fill=255, width=int(.012 * S)))
        layers.append(cylinder(ImageChops.multiply(lip, body), (255, 150, 120), .5 * S, .66 * S, floor=.9))
        scratch = mask(lambda d: d.line([P(.28, .74), P(.36, .79)], fill=255, width=int(.01 * S)))
        layers.append(cylinder(ImageChops.multiply(scratch, body), (250, 190, 170), .2 * S, .7 * S, floor=.9))
        # Oil: a glint in the open neck, a drip from the bent spout, a puddle.
        glint = mask(lambda d: d.ellipse([*P(.41, .205), *P(.51, .245)], fill=255))
        layers.append(cylinder(glint, OIL, .41 * S, .51 * S, floor=.8))
        drip = mask(lambda d: (d.ellipse([*P(.885, .27), *P(.935, .33)], fill=255), d.polygon([P(.888, .29), P(.91, .24), P(.932, .29)], fill=255)))
        layers.append(cylinder(drip, OIL, .885 * S, .935 * S, light=.3, floor=.75))
        puddle = mask(lambda d: (d.ellipse([*P(.52, .80), *P(.90, .89)], fill=255), d.ellipse([*P(.78, .76), *P(.94, .84)], fill=255)))
        under = Image.new('RGBA', (S, S)); under.paste(cylinder(puddle, OIL, .52 * S, .94 * S, light=.35, floor=.75), (0, 0))
        layers.insert(0, under)
    art = Image.new('RGBA', (S, S))
    for layer in layers: art = Image.alpha_composite(art, layer)
    # Gloss: a soft vertical streak down the body's lit side, as on the pieces.
    streak = mask(lambda d: d.rounded_rectangle([*P(.30, top + .03), *P(.34, bottom - .05)], radius=int(.02 * S), fill=120))
    streak = ImageChops.multiply(streak.filter(ImageFilter.GaussianBlur(.008 * S)), body)
    gloss = Image.new('RGBA', (S, S), (255, 255, 255, 0)); gloss.putalpha(streak)
    art = Image.alpha_composite(art, gloss)
    # Chunky dark outline around the whole silhouette, like the board art.
    edge = art.getchannel('A').point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MaxFilter(int(.022 * S) | 1))
    outline = Image.new('RGBA', (S, S), (70, 22, 14, 0)); outline.putalpha(edge)
    art = Image.alpha_composite(outline, art)
    # Soft contact shadow under the can.
    shadow = mask(lambda d: d.ellipse([*P(.16, .80), *P(.80, .90)], fill=110)).filter(ImageFilter.GaussianBlur(.02 * S))
    base = Image.new('RGBA', (S, S), (40, 20, 10, 0)); base.putalpha(shadow)
    art = Image.alpha_composite(base, art)
    art = art.resize((size, size), Image.Resampling.LANCZOS)
    # Free-standing: keep the drawing inside the board's 112px object box.
    box = art.getchannel('A').getbbox()
    crop = art.crop(box); crop.thumbnail((108, 108), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (size, size)); out.paste(crop, ((size - crop.width) // 2, (size - crop.height) // 2))
    return out


def encode(image):
    buf = io.BytesIO()
    image.save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true')
    check = parser.parse_args().check
    for name, image in (('oil-material', material().convert('RGBA')), ('oil-bubbles', bubble_layer()), ('goal-oil', icon()),
                        ('oil-can-2', oil_can(2)), ('oil-can-1', oil_can(1))):
        path, data = OUT / f'{name}.png', encode(image)
        if check:
            assert path.read_bytes() == data, f'{path.relative_to(ROOT)} is stale: run python3 tools/oil_art.py'
        else:
            path.write_bytes(data)
        print(f'{path.relative_to(ROOT)}: {"verified" if check else "written"}')


if __name__ == '__main__':
    main()
