"""Register the selected resource sprites from their authored atlas."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPEC = json.loads((ROOT / 'art/board-states/manifest.json').read_text())['resource_pieces']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    atlas = Image.open(ROOT / SPEC['source'])
    assert atlas.mode == 'RGBA'
    cols, rows = SPEC['grid']
    width, height = atlas.size
    size, extent, pad = (SPEC[key] for key in ('size', 'extent', 'padding'))
    for name, slot in SPEC['slots'].items():
        row, col = divmod(slot - 1, cols)
        tile = atlas.crop((col*width//cols, row*height//rows, (col+1)*width//cols, (row+1)*height//rows))
        transparent, opaque = tile.getchannel('A').getextrema()
        assert transparent == 0 and opaque >= 250, name
        alpha = tile.getchannel('A').point(lambda value: 255 if value > SPEC['content_alpha'] else 0)
        x0, y0, x1, y1 = alpha.getbbox()
        sprite = tile.crop((max(0, x0-pad), max(0, y0-pad), min(tile.width, x1+pad), min(tile.height, y1+pad)))
        sprite.thumbnail((extent, extent), Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', (size, size))
        canvas.paste(sprite, ((size-sprite.width)//2, (size-sprite.height)//2))
        target = ROOT / 'data' / 'resource-pieces' / f'{name}.png'
        if args.check:
            assert Image.open(target).tobytes() == canvas.tobytes(), f'Outdated sprite: {target.name}'
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            canvas.save(target, optimize=True)


if __name__ == '__main__':
    main()
