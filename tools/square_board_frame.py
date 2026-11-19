"""Bake full-size tiles for the empty cells bordering a square board."""
import json
import math
from pathlib import Path

from PIL import Image, ImageFilter

import board_frame_decor

CELL = 128
REACH = 17

# Distance from the board into the frame cell, and the lit sandstone colour.
# Like Cradle of Rome, the rim is a flat face with only a slight rounding at
# its edges; the board sits higher and casts SHADOW across its inner part.
PROFILE = (
    (0, (120, 84, 44)),
    (1.5, (182, 138, 80)),
    (13.5, (188, 144, 84)),
    (14.5, (222, 182, 116)),
    (15.5, (170, 120, 64)),
    (REACH, (66, 36, 14)),
)
# The board's cast shadow: full strength at its edge, gone by this depth.
SHADOW = 7
SHADOW_STRENGTH = .6


def frame_masks():
    """Neighbour bits run clockwise from north, interleaving edges and corners."""
    canonical = set()
    for mask in range(1, 256):
        for k in range(0, 8, 2):
            if mask & (1 << k | 1 << ((k + 2) % 8)):
                mask &= ~(2 << k)  # This corner is already covered by a side.
        rotations = [(mask << k | mask >> (8 - k)) & 255 for k in range(0, 8, 2)]
        canonical.add(min(rotations))
    return sorted(canonical)


def contour(mask):
    sides = [k for k in range(4) if mask & (1 << (2 * k))]
    corners = [(k, (k + 1) % 4) for k in range(4) if mask & (2 << (2 * k))]
    half = CELL / 2

    def sample(x, y):
        distance = (y, CELL - x, CELL - y, x)
        along = (x - half, y - half, half - x, half - y)
        depth, run = REACH, 0
        for side in sides:
            if distance[side] < depth:
                depth, run = distance[side], along[side]
        for a, b in corners:
            corner = math.hypot(distance[a], distance[b])
            if corner < depth:
                depth, run = corner, half - min(distance[a], distance[b])
        return depth, run

    return sample


def bake(sample, grain):
    scale = 2
    side = CELL * scale
    bands = []
    for (a, lit), (b, shade) in zip(PROFILE, PROFILE[1:]):
        steps = round((b - a) * 16)
        for i in range(steps):
            f = i / steps
            bands.append(tuple(c + (d - c) * f for c, d in zip(lit, shade)))
    texture = grain.load()
    pixels = []
    for py in range(side):
        y = (py + .5) / scale
        for px in range(side):
            x = (px + .5) / scale
            depth, along = sample(x, y)
            if depth >= REACH:
                pixels.append((0, 0, 0, 0))
                continue
            colour = bands[int(depth * 16)]
            u = int(along + CELL / 2)
            v = 42 + int(depth * 2)
            # Multiply the painted stone grain over the coloured face.
            # Fade the grain near the joins so adjacent cells meet cleanly.
            seam = max(0, min(1, (CELL / 2 - 1 - abs(along)) / 5))
            face = min(1, max(0, (depth - 3) / 5)) * seam
            grain_weight = min(1, depth / 3) * seam
            multiply = 1 - (1 - texture[u, v] / 255) * grain_weight * .83
            # The pale shoulder of each deep, angled joint picks up light.
            cut = (along + depth * .62 + abs(depth - 11) * .24) % (CELL / 2) - CELL / 4
            joint = max(0, 1 - abs(cut) / 2.4) * .85 * face
            shoulder = max(0, 1 - abs(cut - 2.7) / 1.5) * .32 * face
            # The board casts a soft shadow across the inner half of the rim.
            fade = min(1, depth / SHADOW)
            shade = 1 - SHADOW_STRENGTH * (1 - fade * fade * (3 - 2 * fade))
            mottled = (c * multiply for c in colour)
            stone = [round((base + (dark - base) * joint + (lit - base) * shoulder) * shade)
                     for base, dark, lit in zip(mottled, (55, 34, 18), (234, 196, 145))]
            pixels.append((*stone, 255))
    image = Image.new('RGBA', (side, side))
    image.putdata(pixels)
    return image.resize((CELL, CELL), Image.Resampling.BOX)


def foliage():
    reference = json.loads(board_frame_decor.SPEC.read_text())
    root = board_frame_decor.ROOT
    source = root / reference['source']
    # All canonical leafy layouts have their first inside corner at NE.
    spec = dict(reference['games']['relic-rush']['leaves'], scale=.35, turn=-119)
    with Image.open(source) as image:
        sprig = board_frame_decor.register(image, spec, 2 * CELL)
    mount = (CELL - REACH + 1, 36)
    x, y = (CELL - coord for coord in mount)
    left, top, right, bottom = sprig.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    assert x < left and y < top and right < x + CELL and bottom < y + CELL, 'Leaves must fit the frame cell'
    tile = sprig.crop((x, y, x + CELL, y + CELL))
    spec['source'] = reference['source']
    spec['mount'] = mount
    spec['size'] = [CELL, CELL]
    return tile, spec, [source, root / reference['prompt'], board_frame_decor.SPEC]


def generate(grain_source):
    with Image.open(grain_source) as image:
        grain = image.convert('L').resize((CELL, CELL), Image.Resampling.LANCZOS)
    # Widen the painted fissures at atlas resolution. Map pale sandstone
    # to white so Multiply keeps the face bright between the dark cracks.
    grain = grain.filter(ImageFilter.MinFilter(5))
    grain = grain.point(lambda value: round(255 * max(0, min(1, (value - 75) / (211 - 75)))))
    leaves, leaf_spec, assets = foliage()
    sprites = {}
    for mask in frame_masks():
        name = f'square-frame-{mask}'
        sprites[name] = bake(contour(mask), grain)
        if (mask & 5) == 5:  # North and east rails meet.
            planted = sprites[name].copy()
            planted.alpha_composite(leaves)
            sprites[f'{name}-leaf'] = planted
    texture_inputs = [grain_source.with_name(name) for name in (
        'stone-grain.png', 'stone-grain-prompt.txt', 'stone-cracks.png', 'stone-cracks-prompt.txt',
    )]
    return sprites, leaf_spec, [Path(__file__), Path(board_frame_decor.__file__), *texture_inputs, *assets]
