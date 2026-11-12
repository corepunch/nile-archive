#!/usr/bin/env python3
"""Extract original Homescapes goal panel icons as lossless RGBA PNGs.

Requires the source application archive and Pillow. WebP decoding changes the
container, not the pixels. Run from any directory; --check verifies outputs.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/Homescapes.app/base.zip'
DEST = ROOT / 'engine/art/homescapes/sprites'
MANIFEST = ROOT / 'engine/art/homescapes/generator-goal-sources.json'
PREFIX = 'base_mm/Match3/vso/textures/UI/Match3TargetsBase/'
NAMES = ['box', 'carry', 'chip_0', 'chip_1', 'chip_2', 'chip_3', 'chip_4',
         'chip_5', 'jelly', 'lock', 'piggy', 'target_generator', 'trash']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    rows = []
    with ZipFile(SOURCE) as archive:
        for name in NAMES:
            member = PREFIX + name + '.webp'
            source = archive.read(member)
            with Image.open(io.BytesIO(source)) as image:
                rgba = image.convert('RGBA')
                out = io.BytesIO()
                rgba.save(out, format='PNG', optimize=False)
                pixels = digest(rgba.tobytes())
                size = list(rgba.size)
            data = out.getvalue()
            filename = 'goal-' + name.replace('_', '-') + '.png'
            target = DEST / filename
            if args.check:
                if not target.exists() or target.read_bytes() != data:
                    raise SystemExit(f'Output differs: {target}')
            else:
                target.write_bytes(data)
            rows.append({'id': filename[:-4], 'archive': 'reference/Homescapes.app/base.zip',
                         'member': member, 'source_sha256': digest(source), 'size': size,
                         'rgba_sha256': pixels, 'png_sha256': digest(data),
                         'transform': 'WebP decoded to RGBA PNG; no pixel edits'})
    manifest = json.dumps({'reproduce': 'python3 tools/homescapes-reference/extract_generator_goals.py',
                           'sprites': rows}, indent=2) + '\n'
    if args.check:
        if not MANIFEST.exists() or MANIFEST.read_text() != manifest:
            raise SystemExit(f'Manifest differs: {MANIFEST}')
    else:
        MANIFEST.write_text(manifest)
    print(f'{"Verified" if args.check else "Extracted"} {len(rows)} goal sprites')


if __name__ == '__main__':
    main()
