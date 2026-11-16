#!/usr/bin/env python3
"""Register the authored market pieces in one 4x3 runtime atlas."""
import argparse
from pathlib import Path
import sys

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SLOT = 128
COLUMNS, ROWS = 4, 3
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_theme_art import fit_object, silhouette


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source = Image.open(ROOT / 'art/market-goods/source.png')
    assert source.mode == 'RGBA' and source.getchannel('A').getextrema() == (0, 255)
    mask = silhouette(Image.open(ROOT.parents[1] / 'engine/art/hex-tile/hex-mask-128.png')).filter(ImageFilter.MinFilter(5))
    atlas = Image.new('RGBA', (COLUMNS * SLOT, ROWS * SLOT))
    for row in range(ROWS):
        for col in range(COLUMNS):
            sprite = source.crop((col * source.width // COLUMNS, row * source.height // ROWS,
                                  (col + 1) * source.width // COLUMNS, (row + 1) * source.height // ROWS))
            sprite = sprite.crop(sprite.getchannel('A').getbbox())
            frame, _, _ = fit_object(sprite, mask, 112, None)
            atlas.paste(frame, (col * SLOT, row * SLOT))
    output = ROOT / 'data/market-goods.png'
    if args.check:
        previous = Image.open(output)
        assert atlas.size == previous.size and atlas.tobytes() == previous.tobytes(), output
    else:
        atlas.save(output, optimize=True)


if __name__ == '__main__':
    main()
