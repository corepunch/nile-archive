#!/usr/bin/env python3
"""Register the painted match pieces and boosters with their original alpha."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SLOT = 128
COLUMNS, SOURCE_ROWS, ROWS = 4, 6, 7
EDGE_PADDING = 4
# Room for the 106% live draw and its 108% selection pulse.
CELL_INSET = 9
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_buttons import alpha_center
from match3_theme_art import fit_object, silhouette


def open_sheet(path):
    with Image.open(ROOT / path) as source:
        assert source.mode == 'RGBA', path
        transparent, solid = source.getchannel('A').getextrema()
        assert transparent == 0 and solid >= 250, path
        return source.copy()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    goods = json.loads((ROOT / 'art/manifest.json').read_text())['market_goods']
    source = open_sheet(goods['source'])
    edits = goods.get('source_overrides', {})
    edited_sheets = {path: open_sheet(path) for path in {edit['source'] for edit in edits.values()}}
    mask = Image.new('L', (SLOT, SLOT))
    mask.paste(255, (CELL_INSET, CELL_INSET, SLOT - CELL_INSET, SLOT - CELL_INSET))
    max_side = SLOT - 2 * CELL_INSET + 2 * EDGE_PADDING
    atlas = Image.new('RGBA', (COLUMNS * SLOT, ROWS * SLOT))
    sprites = goods['frames']
    assert len(sprites) < COLUMNS * ROWS and edits.keys() <= sprites.keys()
    frames = {}
    for slot, (key, name) in enumerate(sprites.items()):
        edit = edits.get(key)
        if edit:
            sheet, bay = edited_sheets[edit['source']], edit['box']
        else:
            sheet = source
            row, col = divmod(slot, COLUMNS)
            assert row < SOURCE_ROWS
            bay = (col * sheet.width // COLUMNS, row * sheet.height // SOURCE_ROWS,
                   (col + 1) * sheet.width // COLUMNS, (row + 1) * sheet.height // SOURCE_ROWS)
        left, top = bay[:2]
        sprite = sheet.crop(bay)
        bounds = silhouette(sprite).getbbox()
        assert bounds, f'missing {key} in source box {bay}'
        x0, y0, x1, y1 = bounds
        # Include the painted edge while cropping away stray gutter pixels.
        crop = (max(0, x0 - EDGE_PADDING), max(0, y0 - EDGE_PADDING),
                min(sprite.width, x1 + EDGE_PADDING), min(sprite.height, y1 + EDGE_PADDING))
        frame, fitted, offset = fit_object(sprite.crop(crop), mask, max_side, None, anchor=alpha_center)
        center = [round(axis, 4) for axis in alpha_center(frame)]
        assert all(abs(axis - SLOT / 2) <= .5 for axis in center), (key, center)
        atlas_row, atlas_col = divmod(slot, COLUMNS)
        x, y = atlas_col * SLOT, atlas_row * SLOT
        atlas.paste(frame, (x, y))
        source_crop = [left + crop[0], top + crop[1], left + crop[2], top + crop[3]]
        frames[key] = dict(name=name, source_crop=source_crop, fitted_size=fitted,
                           offset=offset, alpha_center=center, registered_box=[x, y, SLOT, SLOT])
        if key in edits:
            frames[key]['source'] = edits[key]['source']
    record = ROOT / goods['transforms']
    content = json.dumps(dict(source=goods['source'], cell='square', cell_inset=CELL_INSET, frames=frames), indent=2) + '\n'
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
