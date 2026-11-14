#!/usr/bin/env python3
"""Draw Relic Rush's placeholder story mosaic for board 8 (the relay floor).

PLACEHOLDER: a procedural stand-in for the authored painting, so the reveal
can be played. It lays a flat scene out as tesserae; see the asset catalogue.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / 'games/relic-rush'
OUTPUT = ROOT / 'data/reveal-08.jpg'
W, H, SS = 720, 800, 2

SKY, SEA, SEA_LIGHT = (62, 84, 124), (74, 118, 150), (118, 160, 176)
STONE, STONE_DARK, SHADE = (205, 184, 142), (160, 134, 98), (58, 50, 62)
AMBER, GLOW, CABLE, RED = (236, 168, 62), (250, 222, 150), (40, 36, 44), (176, 74, 56)
SKIN, COAT, GROUT = (214, 160, 120), (58, 120, 110), (72, 62, 58)


def scene():
    """The relay as its keepers drew it: camp lamp, cable, tide room, keeper."""
    im = Image.new('RGB', (W * SS, H * SS), SKY)
    d = ImageDraw.Draw(im)
    def P(*xy): return [(x * SS, y * SS) for x, y in zip(xy[::2], xy[1::2])]
    def line(points, fill, width): d.line(P(*points), fill=fill, width=width * SS, joint='curve')
    # Sea with long swells.
    d.rectangle(P(0, 470, W, H), fill=SEA)
    for i in range(7):
        y = 500 + i * 44
        line([0, y, 120, y - 10, 240, y, 360, y - 10, 480, y, 600, y - 10, 720, y], SEA_LIGHT, 7)
    # Headland on the left with the camp lamp on its bracket.
    d.polygon(P(0, 330, 150, 300, 300, 330, 380, 420, 330, 520, 0, 560), fill=STONE)
    d.polygon(P(0, 500, 330, 470, 330, 520, 0, 560), fill=STONE_DARK)
    line([190, 310, 190, 190], SHADE, 14)
    line([190, 200, 250, 200], SHADE, 12)
    for a in range(-150, 160, 30):
        r = math.radians(a - 60)
        line([250 + 44 * math.cos(r), 170 + 44 * math.sin(r), 250 + 120 * math.cos(r), 170 + 120 * math.sin(r)], GLOW, 9)
    d.ellipse(P(214, 134, 286, 206), fill=AMBER, outline=SHADE, width=7 * SS)
    # Cliff on the right with the arched tide room.
    d.polygon(P(430, 800, 450, 300, 560, 220, 720, 200, 720, 800), fill=STONE)
    d.polygon(P(430, 800, 450, 300, 500, 330, 490, 800), fill=STONE_DARK)
    d.pieslice(P(500, 420, 690, 610), 180, 360, fill=SHADE)
    d.rectangle(P(500, 514, 690, 680), fill=SHADE)
    # The shutter lamp and its answering flash.
    for a in (-24, 0, 24):
        r = math.radians(200 + a)
        line([560 + 40 * math.cos(r), 560 + 40 * math.sin(r), 560 + 170 * math.cos(r), 560 + 170 * math.sin(r)], GLOW, 9)
    d.ellipse(P(528, 528, 592, 592), fill=AMBER, outline=GLOW, width=6 * SS)
    for x in (540, 560, 580):
        line([x, 524, x, 596], SHADE, 5)
    # The keeper, one hand on the shutter.
    d.ellipse(P(626, 520, 662, 556), fill=SKIN)
    d.polygon(P(616, 560, 672, 560, 680, 680, 608, 680), fill=COAT)
    line([622, 580, 590, 566], SKIN, 10)
    # The cable from the bracket to the tide room, torn in the middle.
    line([190, 310, 230, 380, 300, 400, 356, 404], CABLE, 13)
    line([424, 440, 470, 470, 510, 560, 530, 600], CABLE, 13)
    for dx, dy in ((14, -12), (20, 2), (12, 14)):
        line([356, 404, 356 + dx, 404 + dy], RED, 5)
        line([424, 440, 424 - dx, 440 - dy], RED, 5)
    return im.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))


def tesserae(src):
    """Staggered rows of hand-cut tiles: one sampled colour each, set in grout."""
    rng = random.Random(8)
    out = Image.new('RGB', (W * SS, H * SS), GROUT)
    d = ImageDraw.Draw(out)
    px, size = src.load(), 13
    for row in range(-1, H // size + 2):
        for col in range(-1, W // size + 2):
            cx = (col + (.5 if row % 2 else 0)) * size + rng.uniform(-1.2, 1.2)
            cy = row * size + rng.uniform(-1.2, 1.2)
            r, g, b = px[min(W - 1, max(0, int(cx))), min(H - 1, max(0, int(cy)))]
            k = rng.uniform(.86, 1.1)
            half = size / 2 - 1.1
            quad = [((cx + sx * half + rng.uniform(-1, 1)) * SS, (cy + sy * half + rng.uniform(-1, 1)) * SS)
                    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            d.polygon(quad, fill=tuple(min(255, int(c * k)) for c in (r, g, b)))
    return out.resize((W, H), Image.LANCZOS)


if __name__ == '__main__':
    tesserae(scene()).save(OUTPUT, quality=90)
    print(OUTPUT)
