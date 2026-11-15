#!/usr/bin/env python3
"""Register the eight authored Relic Rush quest objects in a 4×2 runtime atlas."""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'games/relic-rush'
SOURCE = ROOT / 'art/quest-objects/source.png'
CRANK_CHOICES = ROOT / 'art/quest-objects/crank-choices.png'
CRANK_CROP = (768, 512, 1536, 1024)  # selected lower-right variation, without rotation
OUTPUT = ROOT / 'data/quest-objects.png'
# The same props at board size: one padded file each, drawn across the cells
# that bury it and on the Item recovered card.
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


def same(path, expected):
    if not path.exists():
        return False
    with Image.open(path) as actual:
        return actual.size == expected.size and actual.mode == expected.mode and actual.tobytes() == expected.tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    outputs = [(OUTPUT, atlas()), *finds()]
    if args.check:
        for path, expected in outputs:
            if not same(path, expected):
                parser.error(f'{path.name} is out of date')
    else:
        FINDS.mkdir(exist_ok=True)
        for path, expected in outputs:
            expected.save(path, optimize=True)


if __name__ == '__main__':
    main()
