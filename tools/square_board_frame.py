"""Bake full-size tiles for the empty cells bordering a square board."""
import math
from pathlib import Path

from PIL import Image, ImageFilter

import board_frame_decor

CELL = 128
REACH = 17

# End depths and colours of the two planar faces and the outer chamfer.
# The inner bevel meets the flat top at a crisp ridge.
INNER_BEVEL = 6
FACES = (
    (INNER_BEVEL, (128, 86, 45)),
    (15.5, (185, 140, 87)),
    (REACH, (124, 79, 41)),
)
# The board casts a soft contact shadow on the inner bevel.
SHADOW_STRENGTH = .64
# The stone in turn casts a soft shadow on the backdrop inside its tile.
RIM_SHADOW = 7
RIM_SHADOW_ALPHA = 92


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
        depth, run = REACH + RIM_SHADOW, 0
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
    for end, colour in FACES:
        bands.extend([colour] * (round(end * 16) - len(bands)))
    texture = grain.load()
    pixels = []
    for py in range(side):
        y = (py + .5) / scale
        for px in range(side):
            x = (px + .5) / scale
            depth, along = sample(x, y)
            if depth >= REACH:
                fade = 1 - (depth - REACH) / RIM_SHADOW
                pixels.append((24, 17, 12, round(RIM_SHADOW_ALPHA * fade * fade)))
                continue
            colour = bands[int(depth * 16)]
            u = int(along + CELL / 2)
            v = 24 + int(depth * 3)
            # Multiply the painted stone grain over the coloured face.
            # Fade the grain near the joins so adjacent cells meet cleanly.
            seam = max(0, min(1, (CELL / 2 - 1 - abs(along)) / 5))
            face = min(1, max(0, (depth - 3) / 5)) * seam
            multiply = 1 - (1 - texture[u, v] / 255) * face * .86
            # The pale shoulder of each deep, angled joint picks up light.
            cut = (along + depth * .62 + abs(depth - 11) * .24) % (CELL / 2) - CELL / 4
            joint = max(0, 1 - abs(cut) / 2.4) * .85 * face
            shoulder = max(0, 1 - abs(cut - 2.7) / 1.5) * .32 * face
            # Keep the shadow on the inward plane so the ridge stays sharp.
            fade = min(1, depth / INNER_BEVEL)
            shade = 1 - SHADOW_STRENGTH * (1 - fade * fade * (3 - 2 * fade))
            mottled = (c * multiply for c in colour)
            stone = [round((base + (dark - base) * joint + (lit - base) * shoulder) * shade)
                     for base, dark, lit in zip(mottled, (55, 34, 18), (234, 196, 145))]
            pixels.append((*stone, 255))
    image = Image.new('RGBA', (side, side))
    image.putdata(pixels)
    return image.resize((CELL, CELL), Image.Resampling.BOX)


def foliage(source):
    # All canonical leafy layouts have their first inside corner at NE.
    spec = {'crop': [85, 90, 1168, 1105], 'anchor': [841, 366], 'scale': .10, 'turn': -29}
    with Image.open(source) as image:
        sprig = board_frame_decor.register(image, spec, 2 * CELL)
    mount = (94, REACH)
    x, y = (CELL - coord for coord in mount)
    left, top, right, bottom = sprig.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    assert x < left and y < top and right < x + CELL and bottom < y + CELL, 'Leaves must fit the frame cell'
    tile = sprig.crop((x, y, x + CELL, y + CELL))
    spec['source'] = source.relative_to(board_frame_decor.ROOT).as_posix()
    spec['mount'] = mount
    spec['size'] = [CELL, CELL]
    return tile, spec, [source, source.with_name('overhead-leaves-prompt.txt')]


def generate(grain_source):
    with Image.open(grain_source) as image:
        grain = image.convert('L').resize((CELL, CELL), Image.Resampling.LANCZOS)
    # Keep hairline fissures legible with a restrained Multiply pass.
    grain = grain.filter(ImageFilter.MinFilter(3)).point(lambda value: min(255, round(value * 1.10)))
    leaves, leaf_spec, assets = foliage(grain_source.with_name('overhead-leaves.png'))
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
