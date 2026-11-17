#!/usr/bin/env python3
"""Register Relic Rush story pieces for alternate board art packs."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def register_sprites(source_path, items, canvas_size, paint_size):
    with Image.open(ROOT / source_path) as source:
        assert source.mode == 'RGBA', 'story pieces need authored alpha'
        for item in items:
            sprite = source.crop(item['crop'])
            sprite.thumbnail(tuple(paint_size), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', canvas_size)
            canvas.paste(sprite, ((canvas.width - sprite.width) // 2, (canvas.height - sprite.height) // 2))
            yield ROOT / item['runtime'], canvas


def same(path, expected):
    if not path.exists():
        return False
    with Image.open(path) as actual:
        return actual.size == expected.size and actual.mode == expected.mode and actual.tobytes() == expected.tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'art/board-states/manifest.json').read_text())
    pieces = manifest['story_pieces']
    outputs = [
        output
        for sheet in pieces['atlases']
        for output in register_sprites(sheet['source'], sheet['items'].values(),
                                       pieces['canvas'], pieces['paint_size'])
    ]
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
