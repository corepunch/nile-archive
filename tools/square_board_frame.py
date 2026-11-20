"""Bake full-size tiles for the empty cells bordering a square board."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

import board_frame_decor

CELL = 128
REACH = 17

# Distance from the board into the frame cell, and the lit sandstone colour.
# Like Cradle of Rome, the rim is a flat face with only a slight rounding at
# its edges; the board sits higher and casts SHADOW across its inner part.
PROFILE = (
    (0, (116, 74, 40)),
    (1.5, (175, 129, 75)),
    (13.5, (196, 153, 91)),
    (14.5, (225, 184, 115)),
    (15.5, (184, 136, 78)),
    (REACH, (97, 61, 33)),
)
# The board's cast shadow: full strength at its edge, gone by this depth.
SHADOW = 8.5
SHADOW_STRENGTH = .72
# The stone in turn casts a soft shadow on the backdrop inside its tile.
RIM_SHADOW = 7
RIM_SHADOW_ALPHA = 92
NEIGHBOURS = ((0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1))
MARKET = Path(__file__).resolve().parents[1] / 'games/christmas-market'


def canonical_frame(mask):
    """Find the baked mask and the quarter-turns that restore its orientation."""
    for k in range(0, 8, 2):
        if mask & (1 << k | 1 << ((k + 2) % 8)):
            mask &= ~(2 << k)  # This corner is already covered by a side.
    rotations = [(mask << k | mask >> (8 - k)) & 255 for k in range(0, 8, 2)]
    best = min(rotations)
    return best, -rotations.index(best) % 4


def frame_masks():
    return sorted({canonical_frame(mask)[0] for mask in range(1, 256)})


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
    spec = dict(reference['games']['relic-rush']['leaves'], scale=.25, turn=-133)
    with Image.open(source) as image:
        sprig = board_frame_decor.register(image, spec, 2 * CELL)
    # Set the stem at the bend, with the fan pointing into the empty cell.
    mount = (CELL - REACH - 1, REACH + 2)
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
    # Keep hairline fissures legible with a restrained Multiply pass.
    grain = grain.filter(ImageFilter.MinFilter(3)).point(lambda value: min(255, round(value * 1.10)))
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


def painted_christmas(folder):
    """Read the eight painted rail profiles and the shared holly sprig."""
    catalog = folder / 'styles.json'
    spec = json.loads(catalog.read_text())
    source = folder / spec['source']
    profiles = {}
    with Image.open(source) as image:
        assert image.mode == 'RGBA' and len(spec['styles']) == 8
        for index, (key, label) in enumerate(spec['styles'].items()):
            rail, crop = painted_bay(image, index)
            # Use the straight cross-section inside the painted end bevels.
            end = round(rail.width * .06)
            crop[0] += end
            crop[2] -= end
            strip = image.crop(crop).resize((CELL, REACH), Image.Resampling.LANCZOS)
            profiles[key] = (label, join_profile(strip), dict(style=key, crop=crop, size=list(strip.size)))
        sprig, crop = painted_bay(image, 8)
    sprig.thumbnail((52, 52), Image.Resampling.LANCZOS)
    offset = (CELL - REACH + 3 - sprig.width, REACH - 4)
    leaf = Image.new('RGBA', (CELL, CELL))
    leaf.paste(sprig, offset)
    foliage_spec = dict(crop=crop, size=list(sprig.size), offset=list(offset))
    return spec['active'], profiles, leaf, foliage_spec, [Path(__file__), catalog, source, folder / spec['prompt']]


def painted_bay(image, index):
    row, col = divmod(index, 3)
    left, top = col * image.width // 3, row * image.height // 3
    bay = image.crop((left, top, (col + 1) * image.width // 3, (row + 1) * image.height // 3))
    x0, y0, x1, y1 = bay.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    crop = [left + x0, top + y0, left + x1, top + y1]
    return image.crop(crop), crop


def join_profile(strip):
    """Blend the ends over a few pixels so repeated rails have no gaps."""
    pixels = strip.load()
    for y in range(strip.height):
        left, right = pixels[0, y], pixels[strip.width - 1, y]
        edge = tuple((a + b) // 2 for a, b in zip(left, right))
        for step in range(6):
            for x in (step, strip.width - 1 - step):
                pixels[x, y] = tuple(round(a + (b - a) * step / 6) for a, b in zip(edge, pixels[x, y]))
    return strip


def bake_painted(mask, strip):
    """Wrap the painted cross-section around the same contour as sandstone."""
    sample, texture = contour(mask), strip.load()
    scale = 2
    side = CELL * scale
    pixels = []
    for py in range(side):
        for px in range(side):
            depth, run = sample((px + .5) / scale, (py + .5) / scale)
            if depth >= REACH:
                fade = 1 - (depth - REACH) / RIM_SHADOW
                pixels.append((24, 17, 12, round(RIM_SHADOW_ALPHA * fade * fade)))
            else:
                # This lateral sample stays consistent down each rail.
                pixels.append(texture[int(run + CELL / 2), int(depth)])
    image = Image.new('RGBA', (side, side))
    image.putdata(pixels)
    return image.resize((CELL, CELL), Image.Resampling.BOX)


def generate_christmas(folder):
    active, profiles, leaf, foliage_spec, inputs = painted_christmas(folder)
    _, strip, rail = profiles[active]
    sprites = {}
    for mask in frame_masks():
        key = f'square-frame-{mask}'
        sprites[key] = bake_painted(mask, strip)
        if (mask & 5) == 5:
            planted = sprites[key].copy()
            planted.alpha_composite(leaf)
            sprites[key + '-leaf'] = planted
    return sprites, foliage_spec, rail, inputs


def review(output):
    """Compare the eight finishes on identical stepped boards."""
    active, profiles, leaf, _, _ = painted_christmas(MARKET / 'art/square-frame')
    cells = MARKET / 'art/registered/square-cells'
    floors = [Image.open(cells / f'square-{kind}.png').convert('RGBA') for kind in ('plain', 'target')]
    shape = ('..##.', '.####', '#####', '.###.', '..##.')
    plays = {(q, row) for row, line in enumerate(shape) for q, char in enumerate(line) if char == '#'}
    tiles = []
    leafy = [False, True, False, True]
    for q in range(-1, 6):
        for row in range(-1, 6):
            if (q, row) in plays:
                continue
            mask = sum(1 << i for i, (x, y) in enumerate(NEIGHBOURS) if (q + x, row + y) in plays)
            if mask:
                canonical, turn = canonical_frame(mask)
                plants = (canonical & 5) == 5 and mask & (2 << (2 * turn)) != 0
                tiles.append((q, row, canonical, turn, plants and leafy[turn]))
                if plants:
                    leafy[turn] = not leafy[turn]
    row_height = 268
    sheet = Image.new('RGB', (960, 2 * row_height), '#142722')
    ink = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=17)
    step = 34
    for index, (key, (label, strip, _)) in enumerate(profiles.items(), 1):
        preview = Image.new('RGBA', (7 * step, 7 * step))
        for q, row in plays:
            floor = floors[(q + 2 * row) % 3 == 0].resize((step - 1, step - 1), Image.Resampling.LANCZOS)
            preview.alpha_composite(floor, ((q + 1) * step, (row + 1) * step))
        baked = {mask: bake_painted(mask, strip) for mask in {tile[2] for tile in tiles}}
        for q, row, mask, turn, planted in tiles:
            frame = baked[mask]
            if planted:
                frame = Image.alpha_composite(frame, leaf)
            frame = frame.rotate(-90 * turn).resize((step, step), Image.Resampling.LANCZOS)
            preview.alpha_composite(frame, ((q + 1) * step, (row + 1) * step))
        x, y = (index - 1) % 4 * 240, (index - 1) // 4 * row_height
        title = f'{index}  {label}' + ('  ·  In game' if key == active else '')
        ink.text((x + 120, y + 15), title, '#f7e9cf', font=font, anchor='mt')
        sheet.paste(preview, (x + 1, y + 16), preview)
        swatch = strip.resize((160, 21), Image.Resampling.LANCZOS)
        sheet.paste(swatch, (x + 40, y + 236), swatch)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=94)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review', required=True, type=Path)
    review(parser.parse_args().review)
