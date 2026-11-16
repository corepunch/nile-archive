"""Register match pieces and wallet icons from their authored atlases."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / 'art/board-states/manifest.json').read_text())
SPEC = MANIFEST['resource_pieces']


def fit_sprite(tile, name, size, extent):
    transparent, opaque = tile.getchannel('A').getextrema()
    assert transparent == 0 and opaque >= 250, name
    alpha = tile.getchannel('A').point(lambda value: 255 if value > SPEC['content_alpha'] else 0)
    x0, y0, x1, y1 = alpha.getbbox()
    pad = SPEC['padding']
    sprite = tile.crop((max(0, x0-pad), max(0, y0-pad), min(tile.width, x1+pad), min(tile.height, y1+pad)))
    sprite.thumbnail((extent, extent), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (size, size))
    canvas.paste(sprite, ((size-sprite.width)//2, (size-sprite.height)//2))
    return canvas


def register(spec, check):
    atlas = Image.open(ROOT / spec['source'])
    assert atlas.mode == 'RGBA'
    cols, rows = spec['grid']
    width, height = atlas.size
    for name, slot in spec['slots'].items():
        size, extent = spec.get('resize', {}).get(name, (SPEC['size'], SPEC['extent']))
        row, col = divmod(slot - 1, cols)
        tile = atlas.crop((col*width//cols, row*height//rows, (col+1)*width//cols, (row+1)*height//rows))
        canvas = fit_sprite(tile, name, size, extent)
        target = ROOT / 'data' / 'resource-pieces' / f'{name}.png'
        if check:
            assert Image.open(target).tobytes() == canvas.tobytes(), f'Outdated sprite: {target.name}'
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            canvas.save(target, optimize=True)


def register_campaign(spec, check):
    atlas = Image.open(ROOT / spec['source'])
    revision = spec['revision']
    revised = Image.open(ROOT / revision['source'])
    assert revised.mode == 'RGBA'
    edges = spec['row_edges']
    assert atlas.mode == 'RGBA' and edges[0] == 0 and edges[-1] == atlas.height
    rows, size = spec['rows'], spec['cell_size']
    columns = max(map(len, rows))
    packed = Image.new('RGBA', (columns * size, len(rows) * size))
    for row, keys in enumerate(rows):
        for col, key in enumerate(keys):
            box = revision['boxes'].get(key)
            tile = revised.crop(box) if box else atlas.crop((col*atlas.width//columns, edges[row],
                                                             (col+1)*atlas.width//columns, edges[row+1]))
            packed.paste(fit_sprite(tile, key, size, spec['extent']), (col*size, row*size))
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
    for spec in (SPEC, SPEC['timber_emerald'], MANIFEST['wallet_icons']):
        register(spec, args.check)
    register_campaign(MANIFEST['campaign_pieces'], args.check)


if __name__ == '__main__':
    main()
