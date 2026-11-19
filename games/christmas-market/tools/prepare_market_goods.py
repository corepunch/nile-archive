#!/usr/bin/env python3
"""Register the painted match pieces and boosters with their original alpha."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SLOT = 128
COLUMNS, ROWS = 4, 5
EDGE_PADDING = 4
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_theme_art import fit_object, silhouette


def open_sheet(path):
    with Image.open(ROOT / path) as source:
        assert source.mode == 'RGBA' and source.getchannel('A').getextrema() == (0, 255), path
        return source.copy()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    goods = json.loads((ROOT / 'art/manifest.json').read_text())['market_goods']
    sizes = goods['piece_max_side']
    source = open_sheet(goods['source'])
    edits = goods.get('source_overrides', {})
    edited_sheets = {key: open_sheet(edit['source']) for key, edit in edits.items()}
    mask = silhouette(Image.open(ROOT.parents[1] / 'engine/art/hex-tile/hex-mask-128.png')).filter(ImageFilter.MinFilter(5))
    atlas = Image.new('RGBA', (COLUMNS * SLOT, ROWS * SLOT))
    sprites = [(f'market-{kind}', name) for kind, name in enumerate(goods['frames'])]
    sprites.extend(goods['toolbar_only'].items())
    assert len(sprites) == 18
    assert edited_sheets.keys() <= dict(sprites).keys()
    frames = {}
    for slot, (key, name) in enumerate(sprites):
        sheet = edited_sheets.get(key, source)
        row, col = divmod(slot, COLUMNS)
        left, top = col * sheet.width // COLUMNS, row * sheet.height // ROWS
        bay = (left, top, (col + 1) * sheet.width // COLUMNS, (row + 1) * sheet.height // ROWS)
        sprite = sheet.crop(bay)
        x0, y0, x1, y1 = silhouette(sprite).getbbox()
        # Include the painted edge while cropping away stray gutter pixels.
        crop = (max(0, x0 - EDGE_PADDING), max(0, y0 - EDGE_PADDING),
                min(sprite.width, x1 + EDGE_PADDING), min(sprite.height, y1 + EDGE_PADDING))
        frame, fitted, offset = fit_object(sprite.crop(crop), mask, sizes.get(name, 112), None)
        x, y = col * SLOT, row * SLOT
        atlas.paste(frame, (x, y))
        source_crop = [left + crop[0], top + crop[1], left + crop[2], top + crop[3]]
        frames[key] = dict(name=name, source_crop=source_crop, fitted_size=fitted,
                           offset=offset, registered_box=[x, y, SLOT, SLOT])
        if key in edits:
            frames[key]['source'] = edits[key]['source']
    record = ROOT / goods['transforms']
    content = json.dumps(dict(source=goods['source'], frames=frames), indent=2) + '\n'
    output = ROOT / goods['runtime']
    if args.check:
        previous = Image.open(output)
        assert atlas.size == previous.size and atlas.tobytes() == previous.tobytes(), output
        assert record.read_text() == content, record
    else:
        atlas.save(output, optimize=True)
        record.write_text(content)


if __name__ == '__main__':
    main()
