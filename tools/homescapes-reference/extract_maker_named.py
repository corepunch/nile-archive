#!/usr/bin/env python3
"""Extract named 3.5.9 maker atlas regions without inventing placement."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from zipfile import ZipFile
from decode_board_atlases import render_page

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).with_name('maker-named-regions.json')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    if sha256(args.apk.read_bytes()).hexdigest() != manifest['archive_sha256']:
        raise ValueError('Unexpected APK')
    output = ROOT / 'engine/art/homescapes/sprites'
    pages = {}
    with ZipFile(args.apk) as archive:
        for record in manifest['records']:
            page = record['page']
            if page not in pages:
                pages[page] = render_page(archive.read(f'assets/base_mm/atlases/Match3_{page:02}.dds'))[0]
            a = record['attributes']
            x, y, w, h = (int(a[k]) for k in ('x', 'y', 'width', 'height'))
            image = pages[page].crop((x, y, x+w, y+h))
            target = output / record['output']
            if args.check:
                from PIL import Image
                with Image.open(target) as actual:
                    assert actual.convert('RGBA').tobytes() == image.convert('RGBA').tobytes(), target
            else:
                image.save(target)
    print(f"Verified {len(manifest['records'])} named regions")


if __name__ == '__main__':
    main()
