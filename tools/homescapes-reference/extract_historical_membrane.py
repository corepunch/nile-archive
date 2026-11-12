#!/usr/bin/env python3
"""Extract opaque cracked membrane fill from Homescapes 3.5.9 APK.

Usage: python3 tools/homescapes-reference/extract_historical_membrane.py <apk>
"""
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import sys
from zipfile import ZipFile
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'engine/art/homescapes'
MEMBER = 'assets/base_mm/textures/Match3/BubbleMembrane/fill.webp'
RECT = (462, 222, 539, 299)


def main():
    apk = Path(sys.argv[1])
    with ZipFile(apk) as archive:
        source = archive.read(MEMBER)
    image = Image.open(BytesIO(source)).convert('RGBA').crop(RECT)
    assert image.getchannel('A').getextrema() == (255, 255)
    output = DEST / 'sprites/membrane-fill-1.png'
    image.save(output)
    record = {'version': '3.5.9', 'archive': apk.name,
              'archive_sha256': sha256(apk.read_bytes()).hexdigest(),
              'member': MEMBER, 'member_sha256': sha256(source).hexdigest(),
              'rect': list(RECT), 'transform': 'crop decoded WebP, retain original RGBA',
              'output': 'sprites/' + output.name, 'sha256': sha256(output.read_bytes()).hexdigest(),
              'meaning': 'cracked membrane fill; one-layer association inferred from ceramic tile descriptions'}
    (DEST / 'historical-membrane-source.json').write_text(json.dumps(record, indent=2) + '\n')


if __name__ == '__main__':
    main()
