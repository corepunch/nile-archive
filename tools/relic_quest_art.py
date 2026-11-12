#!/usr/bin/env python3
"""Register the eight authored Relic Rush quest objects in a 4×2 runtime atlas."""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'games/relic-rush'
SOURCE = ROOT / 'art/quest-objects/source.png'
OUTPUT = ROOT / 'data/quest-objects.png'
# Pixel boxes separate the two props whose painted silhouettes straddle the grid.
CROPS = [
    (0, 0, 443, 443), (443, 0, 887, 443), (887, 0, 1330, 443), (1330, 0, 1774, 443),
    (0, 443, 433, 887), (433, 443, 887, 887), (887, 443, 1330, 887), (1330, 443, 1774, 887),
]


def atlas():
    source = Image.open(SOURCE)
    if source.mode != 'RGBA' or source.size != (1774, 887):
        raise ValueError('Expected the authored 1774×887 RGBA source')
    out = Image.new('RGBA', (512, 256))
    for index, crop in enumerate(CROPS):
        sprite = source.crop(crop)
        # Crop to visible paint plus an edge guard. Keep the original alpha
        # inside that crop and uniformly resize. No recolouring or masking.
        bounds = sprite.getchannel('A').point(lambda value: 255 if value >= 160 else 0).getbbox()
        left, top, right, bottom = bounds
        sprite = sprite.crop((max(0, left - 4), max(0, top - 4),
                              min(sprite.width, right + 4), min(sprite.height, bottom + 4)))
        sprite.thumbnail((100, 87), Image.Resampling.LANCZOS)
        out.paste(sprite, (index % 4 * 128 + (128 - sprite.width) // 2,
                           index // 4 * 128 + (128 - sprite.height) // 2))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected = atlas()
    if args.check:
        with Image.open(OUTPUT) as actual:
            if actual.size != expected.size or actual.mode != expected.mode or actual.tobytes() != expected.tobytes():
                parser.error('quest object atlas is out of date')
    else:
        expected.save(OUTPUT, optimize=True)


if __name__ == '__main__':
    main()
