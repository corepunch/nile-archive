"""Bake the square board's rounded sandstone rim and its leafy notch."""
import json
import math
from pathlib import Path

from PIL import Image

import board_frame
import board_frame_decor
import board_grain

CELL = 128
LEAF_PAD = 48
REACH, SHADOW = 17, 7

# Distance from the board, sandstone colour, and opacity. Negative distance
# is the contact shadow that falls just inside the floor's edge.
PROFILE = (
    (-SHADOW, (0, 0, 0), 0),
    (-3, (0, 0, 0), 80),
    (0, (0, 0, 0), 170),
    (2, (89, 65, 41), 255),
    (5, (150, 112, 70), 255),
    (7, (168, 132, 86), 255),
    (10, (168, 132, 86), 255),
    (11, (113, 57, 18), 255),
    (13, (100, 69, 38), 255),
    (15, (89, 58, 29), 255),
    (REACH, (82, 43, 14), 255),
)


def quadrant(x, y):
    if x >= 0 and y >= 0:
        return -min(x, y)
    return math.hypot(min(x, 0), min(y, 0))


def straight(x, y):
    return -y, x


def outside(x, y):
    return quadrant(x, y), y if x < y else x


def inside(x, y):
    # The two straight faces meet at a square re-entrant corner.
    return -max(x, y), min(x, y)


def diagonal(x, y):
    south = outside(x, y)
    north = outside(-x, -y)
    return south if south[0] <= north[0] else north


def bake(sample, grain):
    scale = 2
    side = CELL * scale
    bands = []
    for (a, lit, alpha), (b, shade, next_alpha) in zip(PROFILE, PROFILE[1:]):
        steps = (b - a) * 16
        for i in range(steps):
            f = i / steps
            bands.append((tuple(c + (d - c) * f for c, d in zip(lit, shade)),
                          round(alpha + (next_alpha - alpha) * f)))
    texture = grain.load()
    pixels = []
    for py in range(side):
        y = (py + .5) / scale - CELL / 2
        for px in range(side):
            x = (px + .5) / scale - CELL / 2
            depth, along = sample(x, y)
            if not -SHADOW < depth < REACH:
                pixels.append((0, 0, 0, 0))
                continue
            colour, alpha = bands[int((depth + SHADOW) * 16)]
            u = round(along * 2 + grain.width / 2) % grain.width
            v = round(max(0, depth) * (grain.height - 1) / REACH)
            r, g, b, strength = texture[u, v]
            # The stone's veins and occasional cracks stay visible across
            # the face. Fade them near the ports for a continuous joint.
            seam = max(0, min(1, (CELL / 2 - 1 - abs(along)) / 5))
            face = min(1, max(0, (depth - 3) / 5)) * seam
            mix = strength / 255 * face * .85
            # The pale shoulder of each deep, angled joint picks up light.
            cut = (along + depth * .62 + abs(depth - 11) * .24) % (CELL / 2) - CELL / 4
            joint = max(0, 1 - abs(cut) / 2.4) * .85 * face
            shoulder = max(0, 1 - abs(cut - 2.7) / 1.5) * .32 * face
            mottled = (a + (b - a) * mix for a, b in zip(colour, (r, g, b)))
            stone = [round(base + (dark - base) * joint + (lit - base) * shoulder)
                     for base, dark, lit in zip(mottled, (55, 34, 18), (234, 196, 145))]
            pixels.append((*stone, alpha))
    image = Image.new('RGBA', (side, side))
    image.putdata(pixels)
    return image.resize((CELL, CELL), Image.Resampling.BOX)


def plant(stone):
    reference = json.loads(board_frame_decor.SPEC.read_text())
    root = board_frame_decor.ROOT
    source = root / reference['source']
    spec = dict(reference['games']['relic-rush']['leaves'], scale=.38, turn=-45)
    side = CELL + 2 * LEAF_PAD
    with Image.open(source) as image:
        sprig = board_frame_decor.register(image, spec, side)

    corner = Image.new('RGBA', (side, side))
    mount = (2 - REACH, 2 - REACH)
    corner.alpha_composite(stone, (LEAF_PAD, LEAF_PAD))
    corner.alpha_composite(sprig, mount)
    spec['source'] = reference['source']
    spec['mount'] = mount
    spec['size'] = [side, side]
    return corner, spec, [source, root / reference['prompt'], board_frame_decor.SPEC]


def generate():
    grain = board_frame.stone_strip()
    sections = {
        'edge': straight,
        'outer': outside,
        'inner-bare': inside,
        'diagonal': diagonal,
    }
    sprites = {f'square-frame-{name}': bake(sample, grain) for name, sample in sections.items()}
    leafy, leaf_spec, assets = plant(sprites['square-frame-inner-bare'])
    sprites['square-frame-inner'] = leafy
    recipe_inputs = [Path(module.__file__) for module in (board_frame, board_frame_decor, board_grain)]
    return sprites, leaf_spec, [Path(__file__), *recipe_inputs, *assets]
