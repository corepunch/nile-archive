#!/usr/bin/env python3
"""Register Relic Rush quest icons, compact props and props laid out for the board."""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / 'games/relic-rush'
SOURCE = ROOT / 'art/quest-objects/source.png'
CRANK_CHOICES = ROOT / 'art/quest-objects/crank-choices.png'
CRANK_CROP = (768, 512, 1536, 1024)  # selected lower-right variation, without rotation
OUTPUT = ROOT / 'data/quest-objects.png'
# The compact props used on the Item recovered card and in clustered finds.
FINDS = ROOT / 'data/finds'
KEYS = ['timber', 'lens', 'cable', 'chart', 'marker', 'tools', 'supplies', 'crank']
FIND_SIZE, FIND_PAINT = 320, 256
# Pixel boxes separate the two props whose painted silhouettes straddle the grid.
CROPS = [
    (0, 0, 443, 443), (443, 0, 887, 443), (887, 0, 1330, 443), (1330, 0, 1774, 443),
    (0, 443, 433, 887), (433, 443, 887, 887), (887, 443, 1330, 887), (1330, 443, 1774, 887),
]


def sprites():
    source = Image.open(SOURCE)
    if source.mode != 'RGBA' or source.size != (1774, 887):
        raise ValueError('Expected the authored 1774×887 RGBA source')
    for key, crop in zip(KEYS, CROPS):
        if key == 'crank':
            with Image.open(CRANK_CHOICES) as variants:
                sprite = variants.crop(CRANK_CROP)
        else:
            sprite = source.crop(crop)
        # Crop to visible paint plus an edge guard. Keep the original alpha
        # inside that crop and uniformly resize. No recolouring or masking.
        bounds = sprite.getchannel('A').point(lambda value: 255 if value >= 160 else 0).getbbox()
        left, top, right, bottom = bounds
        yield sprite.crop((max(0, left - 4), max(0, top - 4),
                           min(sprite.width, right + 4), min(sprite.height, bottom + 4)))


def atlas():
    out = Image.new('RGBA', (512, 256))
    for index, sprite in enumerate(sprites()):
        sprite.thumbnail((100, 87), Image.Resampling.LANCZOS)
        out.paste(sprite, (index % 4 * 128 + (128 - sprite.width) // 2,
                           index // 4 * 128 + (128 - sprite.height) // 2))
    return out


def finds():
    for key, sprite in zip(KEYS, sprites()):
        sprite.thumbnail((FIND_PAINT, FIND_PAINT), Image.Resampling.LANCZOS)
        out = Image.new('RGBA', (FIND_SIZE, FIND_SIZE))
        out.paste(sprite, ((FIND_SIZE - sprite.width) // 2, (FIND_SIZE - sprite.height) // 2))
        yield FINDS / f'{key}.png', out


def footprints(size, cells):
    """The same flat-top cell positions and canvas scale as object_crop."""
    axials = [(1.5*q, math.sqrt(3)*(r + q/2)) for q, r in cells]
    xs, ys = zip(*axials)
    cx, cy = (min(xs) + max(xs))/2, (min(ys) + max(ys))/2
    radius = min(size[0]/(max(xs) - min(xs) + 2), size[1]/(max(ys) - min(ys) + math.sqrt(3)))
    for x, y in axials:
        x, y = size[0]/2 + (x - cx)*radius, size[1]/2 + (y - cy)*radius
        mask = Image.new('L', size)
        ImageDraw.Draw(mask).polygon([(x + radius*math.cos(math.pi*i/3), y + radius*math.sin(math.pi*i/3))
                                      for i in range(6)], fill=255)
        yield mask


def check_fit(sprite, key, cells, overlay_dir):
    solid = sprite.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    union = Image.new('L', sprite.size)
    for cell, mask in zip(cells, footprints(sprite.size, cells)):
        coverage = ImageChops.multiply(solid, mask).histogram()[255] / mask.histogram()[255]
        assert coverage >= .07, f'{key} barely reaches cell {cell}: {coverage:.1%} covered'
        union = ImageChops.lighter(union, mask)
    outside = ImageChops.subtract(solid, union)
    spill = outside.histogram()[255] / solid.histogram()[255]
    assert spill <= .005, f'{key} spills {spill:.1%} of its solid paint outside the cells'
    if overlay_dir:
        overlay = Image.new('RGBA', sprite.size, '#102027')
        overlay.paste('#35535b', (0, 0), union)
        overlay.alpha_composite(sprite)
        overlay.paste('#ff4d43', (0, 0), outside)
        overlay.save(overlay_dir / f'{key}.png')
    return solid


def silhouette_overlap(exposed, covered):
    overlap = ImageChops.darker(exposed, covered).histogram()[255]
    extent = ImageChops.lighter(exposed, covered).histogram()[255]
    return overlap / extent


def state_crop(source, placement):
    sprite = source.crop(placement['crop'])
    if placement.get('angle'):
        sprite = sprite.rotate(placement['angle'], resample=Image.Resampling.BICUBIC, expand=True)
        bounds = sprite.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
        sprite = sprite.crop(bounds)
    return sprite


def place_state(sprite, size, offset):
    canvas = Image.new('RGBA', size)
    x, y = ((outer - inner)//2 + shift for outer, inner, shift in zip(size, sprite.size, offset))
    assert 0 <= x <= canvas.width - sprite.width and 0 <= y <= canvas.height - sprite.height
    canvas.paste(sprite, (x, y))
    return canvas


def authored_finds(spec, overlay_dir):
    if overlay_dir:
        overlay_dir.mkdir(parents=True, exist_ok=True)
    with Image.open(ROOT / spec['source']) as source:
        assert source.mode == 'RGBA', 'authored finds need alpha'
        for key, item in spec['items'].items():
            shapes = {}
            for state, placement in item['states'].items():
                name = f'{key}-{state}'
                sprite = state_crop(source, placement)
                sprite.thumbnail(tuple(placement['paint_size']), Image.Resampling.LANCZOS)
                canvas = place_state(sprite, item['canvas'], placement.get('offset', (0, 0)))
                shapes[state] = check_fit(canvas, name, item['cells'], overlay_dir)
                yield ROOT / placement['runtime'], canvas
            assert silhouette_overlap(shapes['exposed'], shapes['covered']) >= .90, (
                f'{key} shifts visibly between the covered and exposed states')


def compact_silhouettes(spec, compact):
    with Image.open(ROOT / spec['source']) as source:
        assert source.mode == 'RGBA', 'compact silhouettes need authored alpha'
        for key, placement in spec['items'].items():
            sprite = state_crop(source, placement)
            scale = placement['side'] / max(sprite.size)
            sprite = sprite.resize(tuple(round(d * scale) for d in sprite.size), Image.Resampling.LANCZOS)
            exposed = compact[FINDS / f'{key}.png']
            covered = place_state(sprite, exposed.size, placement.get('offset', (0, 0)))
            shapes = [im.getchannel('A').point(lambda a: 255 if a >= 128 else 0) for im in (exposed, covered)]
            assert silhouette_overlap(*shapes) >= .90, f'{key} silhouette does not align with the original'
            yield ROOT / placement['runtime'], covered


def story_pieces(spec):
    with Image.open(ROOT / spec['source']) as source:
        assert source.mode == 'RGBA', 'story pieces need authored alpha'
        for item in spec['items'].values():
            sprite = state_crop(source, item)
            sprite.thumbnail(tuple(spec['paint_size']), Image.Resampling.LANCZOS)
            yield ROOT / item['runtime'], place_state(sprite, spec['canvas'], (0, 0))


def same(path, expected):
    if not path.exists():
        return False
    with Image.open(path) as actual:
        return actual.size == expected.size and actual.mode == expected.mode and actual.tobytes() == expected.tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--overlay-dir', type=Path, help='Write review images with the flat-top footprints')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'art/board-states/manifest.json').read_text())
    quest = manifest['quest_objects']
    compact = dict(finds())
    outputs = [(OUTPUT, atlas()), *compact.items(), *authored_finds(quest['laid_out'], args.overlay_dir),
               *compact_silhouettes(quest['compact_silhouettes'], compact),
               *authored_finds(quest['standalone_finds'], args.overlay_dir),
               *story_pieces(quest['story_pieces'])]
    if args.check:
        for path, expected in outputs:
            if not same(path, expected):
                parser.error(f'{path.name} is out of date')
    else:
        for path, expected in outputs:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path, optimize=True)


if __name__ == '__main__':
    main()
