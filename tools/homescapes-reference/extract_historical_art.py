#!/usr/bin/env python3
"""Extract hand-selected original Match3 regions from Homescapes 3.5.9 APK."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from zipfile import ZipFile

from decode_board_atlases import render_page

ROOT = Path(__file__).resolve().parents[2]
REGIONS = Path(__file__).with_name('historical-regions.json')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'engine/art/homescapes/sprites')
    args = parser.parse_args()
    data = json.loads(REGIONS.read_text())
    if sha256(args.apk.read_bytes()).hexdigest() != data['apk_sha256']:
        parser.error('APK SHA-256 does not match historical source')
    args.output.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.apk) as apk:
        pages = {}
        for region in data['regions']:
            number = region['page']
            if number not in pages:
                pages[number] = render_page(apk.read(f'assets/base_mm/atlases/Match3_{number:02}.dds'))[0]
            sprite = pages[number].crop(region['rect'])
            if region.get('rotation'):
                sprite = sprite.rotate(region['rotation'])
            sprite.save(args.output / (region['id'] + '.png'))


if __name__ == '__main__':
    main()
