#!/usr/bin/env python3
"""Extract the Homescapes 6.3.2 colored-box goal icon without pixel edits."""
import argparse
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MEMBER = 'assets/base_mm/textures/Match3/PanelIcons/color_box.webp'
SHA256 = '1bdea1192a65e990d534ce3e56d1d4dc539f5fa9f2922ac72bd184d9e038cbdf'
SOURCE = ROOT / 'engine/art/homescapes/sources/color-box-goal.webp'
OUTPUT = ROOT / 'engine/art/homescapes/sprites/goal-color-box.png'
MANIFEST = ROOT / 'engine/art/homescapes/color-box-goal-source.json'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, help='Original Homescapes 6.3.2 APK')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.apk:
        with ZipFile(args.apk) as archive:
            data = archive.read(MEMBER)
    else:
        data = SOURCE.read_bytes()
    if digest(data) != SHA256:
        raise SystemExit('Source member SHA-256 does not match')
    with Image.open(io.BytesIO(data)) as image:
        rgba = image.convert('RGBA')
        pixels = digest(rgba.tobytes())
        size = list(rgba.size)
        out = io.BytesIO()
        rgba.save(out, format='PNG', optimize=False)
    png = out.getvalue()
    manifest = json.dumps({
        'source': 'Homescapes Android 6.3.2, https://apk.gold/download?file_id=2596500/homescapes',
        'member': MEMBER, 'source_sha256': SHA256, 'size': size,
        'rgba_sha256': pixels, 'png_sha256': digest(png),
        'transform': 'WebP decoded to RGBA PNG; no pixel edits',
        'meaning': 'Goal panel icon; not a strength-specific board sprite',
        'reproduce': 'python3 tools/homescapes-reference/extract_color_box_goal.py --apk /path/to/Homescapes-6.3.2.apk',
    }, indent=2) + '\n'
    if args.check:
        if SOURCE.read_bytes() != data or OUTPUT.read_bytes() != png or MANIFEST.read_text() != manifest:
            raise SystemExit('Output or provenance differs')
    else:
        SOURCE.write_bytes(data)
        OUTPUT.write_bytes(png)
        MANIFEST.write_text(manifest)
    print('Verified' if args.check else 'Extracted', 'colored-box goal icon')


if __name__ == '__main__':
    main()
