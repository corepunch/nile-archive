"""Export authored navigation cells without tinting or replacing their alpha.

python3 games/christmas-market/tools/prepare_hud.py [--check]
"""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'art/navigation/manifest.json').read_text())
    with Image.open(ROOT / manifest['source']) as sheet:
        assert sheet.mode == 'RGBA' and list(sheet.size) == manifest['size']
        assert sheet.getchannel('A').getextrema() == (0, 255)
        for asset in manifest['icons'].values():
            left, top, right, bottom = asset['box']
            assert 0 <= left < right <= sheet.width and 0 <= top < bottom <= sheet.height
            image = sheet.crop(asset['box'])
            image.thumbnail((152, 152), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', (160, 160))
            canvas.alpha_composite(image, ((160-image.width)//2, (160-image.height)//2))
            path = ROOT / asset['runtime']
            if args.check:
                with Image.open(path) as current:
                    assert current.mode == 'RGBA' and current.size == canvas.size and current.tobytes() == canvas.tobytes(), path
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                canvas.save(path, optimize=True)
    print('Christmas navigation: fifteen authored RGBA states ' + ('verified' if args.check else 'exported'))


if __name__ == '__main__':
    main()
