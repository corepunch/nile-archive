#!/usr/bin/env python3
"""Recover the named legacy maker progress background without changing its canvas."""
import argparse
import hashlib
import io
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MEMBER = 'assets/base_mm/textures/Match3/CarryGenerator/progress_back.webp'
SHA256 = '079de773b88d0043398fe4a0e64e2b528835c60b5993d6cbc57b3a04481693ea'
OUTPUT = ROOT / 'engine/art/homescapes/sprites/donut-maker-legacy-progress-back-source.png'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, default=ROOT / 'reference/homescapes-analysis/historical/homescapes-1.1.0.900.apk')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    with ZipFile(args.apk) as archive:
        data = archive.read(MEMBER)
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError('Unexpected original progress background')
    image = Image.open(io.BytesIO(data)).convert('RGBA')
    assert image.size == (460, 420) and image.getbbox() == (158, 287, 308, 335)
    if args.check:
        with Image.open(OUTPUT) as actual:
            assert actual.convert('RGBA').tobytes() == image.tobytes()
    else:
        image.save(OUTPUT)
    print(f'{OUTPUT}: verified {image.size}, alpha bounds {image.getbbox()}')


if __name__ == '__main__':
    main()
