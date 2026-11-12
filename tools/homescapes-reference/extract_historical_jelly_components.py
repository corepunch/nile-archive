#!/usr/bin/env python3
"""Extract candidate original jelly components from Homescapes 3.5.9.

These are individual source components, not a reconstructed six-state set.
The source game’s placement and state mapping are not established here.
"""
import argparse
from hashlib import sha256
from pathlib import Path
from zipfile import ZipFile

from decode_board_atlases import render_page

ROOT = Path(__file__).resolve().parents[2]
APK_SHA256 = '8b1a2ac9b4bbf7c4cd3122fcde18e806d3623695c841c6af0c7e14148e1cb093'
# Pixel bounds on decoded 1408×1408 pages. Each region retains its authored
# alpha; 180 degrees restores the atlas sprites' game-facing orientation.
COMPONENTS = (
    ('jelly-square-source', 3, (329, 1001, 447, 1119)),
    ('jelly-flower-frame-source', 3, (3, 1244, 113, 1353)),
    ('jelly-flower-fill-source', 3, (119, 1243, 230, 1353)),
    ('jelly-flower-three-pale-source', 4, (367, 1, 478, 111)),
    ('jelly-flower-five-pale-source', 4, (483, 1, 594, 111)),
    ('jelly-flower-dark-source', 4, (599, 1, 710, 111)),
    ('jelly-cherry-clear-source', 4, (769, 653, 863, 743)),
    ('jelly-cherry-soft-source', 4, (871, 651, 969, 745)),
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'engine/art/homescapes/sprites')
    args = parser.parse_args()
    if sha256(args.apk.read_bytes()).hexdigest() != APK_SHA256:
        parser.error('APK SHA-256 does not match historical source')
    args.output.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.apk) as apk:
        pages = {}
        for name, page, rect in COMPONENTS:
            if page not in pages:
                pages[page] = render_page(apk.read(f'assets/base_mm/atlases/Match3_{page:02}.dds'))[0]
            pages[page].crop(rect).rotate(180).save(args.output / f'{name}.png')


if __name__ == '__main__':
    main()
