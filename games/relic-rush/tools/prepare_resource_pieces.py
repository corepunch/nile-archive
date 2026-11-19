"""Register match pieces and wallet icons from their authored atlases."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_buttons import alpha_center
from match3_theme_art import fit_object

MANIFEST = json.loads((ROOT / 'art/board-states/manifest.json').read_text())
SPEC = MANIFEST['resource_pieces']


def fit_sprite(tile, name, size, extent, square_inset=None):
    transparent, opaque = tile.getchannel('A').getextrema()
    assert transparent == 0 and opaque >= 250, name
    alpha = tile.getchannel('A').point(lambda value: 255 if value > SPEC['content_alpha'] else 0)
    x0, y0, x1, y1 = alpha.getbbox()
    pad = SPEC['padding']
    sprite = tile.crop((max(0, x0-pad), max(0, y0-pad), min(tile.width, x1+pad), min(tile.height, y1+pad)))
    if square_inset is not None:
        mask = Image.new('L', (size, size))
        mask.paste(255, (square_inset, square_inset, size - square_inset, size - square_inset))
        return fit_object(sprite, mask, extent, None, anchor=alpha_center)[0]
    sprite.thumbnail((extent, extent), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (size, size))
    canvas.paste(sprite, ((size-sprite.width)//2, (size-sprite.height)//2))
    return canvas


def register_piece(tile, name, size, extent, check, folder=ROOT / 'art/registered/resource-pieces'):
    canvas = fit_sprite(tile, name, size, extent)
    target = folder / f'{name}.png'
    if check:
        assert Image.open(target).tobytes() == canvas.tobytes(), f'Outdated sprite: {target.name}'
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(target, optimize=True)


def register(spec, check):
    source = Image.open(ROOT / spec['source'])
    edits = spec.get('source_overrides', {})
    cols, rows = spec['grid']
    for name, slot in spec['slots'].items():
        atlas = Image.open(ROOT / edits[name]['source']) if name in edits else source
        assert atlas.mode == 'RGBA'
        width, height = atlas.size
        size, extent = spec.get('resize', {}).get(name, (SPEC['size'], SPEC['extent']))
        row, col = divmod(slot - 1, cols)
        tile = atlas.crop((col*width//cols, row*height//rows, (col+1)*width//cols, (row+1)*height//rows))
        register_piece(tile, name, size, extent, check)


def register_campaign(spec, check):
    atlas = Image.open(ROOT / spec['source'])
    replacements, square_insets = {}, {}
    for revision in spec['revisions']:
        with Image.open(ROOT / revision['source']) as revised:
            assert revised.mode == 'RGBA'
            replacements.update({key: revised.crop(box) for key, box in revision['boxes'].items()})
            if 'square_inset' in revision:
                square_insets.update(dict.fromkeys(revision['boxes'], revision['square_inset']))
    for key, (size, extent) in SPEC['from_campaign'].items():
        register_piece(replacements[key], key, size, extent, check)
    edges = spec['row_edges']
    assert atlas.mode == 'RGBA' and edges[0] == 0 and edges[-1] == atlas.height
    rows, size = spec['rows'], spec['cell_size']
    columns = max(map(len, rows))
    extents = spec.get('extent_overrides', {})
    packed = Image.new('RGBA', (columns * size, len(rows) * size))
    for row, keys in enumerate(rows):
        for col, key in enumerate(keys):
            tile = replacements.get(key)
            if tile is None:
                tile = atlas.crop((col*atlas.width//columns, edges[row],
                                   (col+1)*atlas.width//columns, edges[row+1]))
            canvas = fit_sprite(tile, key, size, extents.get(key, spec['extent']), square_insets.get(key))
            packed.paste(canvas, (col*size, row*size))
    target = ROOT / spec['runtime']
    if check:
        with Image.open(target) as current:
            assert (current.mode, current.size, current.tobytes()) == (packed.mode, packed.size, packed.tobytes()), target
    else:
        packed.save(target, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    for spec in (SPEC, MANIFEST['wallet_icons']):
        register(spec, args.check)
    register_campaign(MANIFEST['campaign_pieces'], args.check)


if __name__ == '__main__':
    main()
