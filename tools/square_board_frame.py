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
REACH, SHADOW = 20, 7

# Distance from the board, sandstone colour, and opacity. Negative distance
# is the contact shadow that falls just inside the floor's edge.
PROFILE = (
    (-SHADOW, (32, 20, 10), 0),
    (-3, (31, 20, 11), 175),
    (0, (40, 27, 16), 245),
    (3, (60, 40, 24), 255),
    (6, (104, 74, 45), 255),
    (9, (164, 127, 83), 255),
    (14, (174, 136, 91), 255),
    (16, (200, 158, 107), 255),
    (18, (139, 101, 62), 255),
    (REACH, (84, 55, 30), 255),
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
    depth = -quadrant(-x, -y)
    # Round the outer silhouette of the notch while keeping its contact
    # line at the square floor edge.
    rounding = max(0, min(1, (depth - 8) / 10))
    depth -= rounding * max(0, 12 - abs(x - y)) ** 2 / 48
    return depth, x if x < y else y


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
            light = min(1, max(0, (depth - 3) / 5))
            mix = strength / 255 * seam * light * .85
            # Cut a shallow angled masonry joint across the mottled face.
            cut = (along + depth * .62 + abs(depth - 11) * .24) % (CELL / 2) - CELL / 4
            joint = max(0, 1 - abs(cut) / 1.7) * .68 * light * seam
            mottled = (a + (b - a) * mix for a, b in zip(colour, (r, g, b)))
            pixels.append((*[round(a + (b - a) * joint) for a, b in zip(mottled, (69, 45, 26))], alpha))
    image = Image.new('RGBA', (side, side))
    image.putdata(pixels)
    return image.resize((CELL, CELL), Image.Resampling.BOX)


def plant(stone):
    reference = json.loads(board_frame_decor.SPEC.read_text())
    root = board_frame_decor.ROOT
    source = root / reference['source']
    spec = dict(reference['games']['relic-rush']['leaves'], scale=.29, turn=-45)
    side = CELL + 2 * LEAF_PAD
    with Image.open(source) as image:
        sprig = board_frame_decor.register(image, spec, side)

    corner = Image.new('RGBA', (side, side))
    mount = (-22, -22)
    # Keep the plant wholly within the empty square, even under the
    # translucent part of the stone's shadow.
    x, y = mount
    pivot = side // 2
    corner.paste(sprig.crop((0, 0, pivot - x, pivot - y)), mount)
    corner.alpha_composite(stone, (LEAF_PAD, LEAF_PAD))
    spec['source'] = reference['source']
    spec['mount'] = mount
    spec['size'] = [side, side]
    spec['clip'] = [0, 0, pivot, pivot]
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
