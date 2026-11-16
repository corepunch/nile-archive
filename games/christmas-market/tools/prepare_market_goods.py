#!/usr/bin/env python3
"""Register the authored market pieces in one 4x4 runtime atlas.

Rows 1-3 are the market goods source. Row 4 reuses earlier painted festive
pieces for the later stalls' treasures and candy cane (kinds 12-15)."""
import argparse
from pathlib import Path
import sys

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SLOT = 128
COLUMNS, ROWS = 4, 3
# Kinds 12-15: (source, crop box), the festive pieces in the game's own sheets.
REUSED = [
    ('art/festive-pieces/source.png', (0, 0, 512, 512)),       # golden handbell
    ('art/icons.png', None),                                  # snowflake bauble, icon cell 3
    ('art/festive-pieces/source.png', (512, 512, 1024, 1024)), # plum bauble
    ('art/festive-pieces/source.png', (512, 0, 1024, 512)),    # candy cane
]
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_theme_art import fit_object, silhouette


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source = Image.open(ROOT / 'art/market-goods/source.png')
    assert source.mode == 'RGBA' and source.getchannel('A').getextrema() == (0, 255)
    mask = silhouette(Image.open(ROOT.parents[1] / 'engine/art/hex-tile/hex-mask-128.png')).filter(ImageFilter.MinFilter(5))
    atlas = Image.new('RGBA', (COLUMNS * SLOT, (ROWS + 1) * SLOT))
    for row in range(ROWS):
        for col in range(COLUMNS):
            sprite = source.crop((col * source.width // COLUMNS, row * source.height // ROWS,
                                  (col + 1) * source.width // COLUMNS, (row + 1) * source.height // ROWS))
            sprite = sprite.crop(sprite.getchannel('A').getbbox())
            frame, _, _ = fit_object(sprite, mask, 112, None)
            atlas.paste(frame, (col * SLOT, row * SLOT))
    for col, (path, box) in enumerate(REUSED):
        sheet = Image.open(ROOT / path).convert('RGBA')
        if box is None:   # tools/prepare_assets.py's icon grid: eight columns, first row ends at 232
            box = (round(3 * sheet.width / 8), 0, round(4 * sheet.width / 8), 232)
        sprite = sheet.crop(box)
        sprite = sprite.crop(sprite.getchannel('A').getbbox())
        frame, _, _ = fit_object(sprite, mask, 112, None)
        atlas.paste(frame, (col * SLOT, ROWS * SLOT))
    output = ROOT / 'data/market-goods.png'
    if args.check:
        previous = Image.open(output)
        assert atlas.size == previous.size and atlas.tobytes() == previous.tobytes(), output
    else:
        atlas.save(output, optimize=True)


if __name__ == '__main__':
    main()
