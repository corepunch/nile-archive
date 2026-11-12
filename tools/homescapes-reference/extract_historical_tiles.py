#!/usr/bin/env python3
"""Extract intact and fractured ceramic tiles from Homescapes 3.5.9.

Usage: PYTHONPATH=<texture2ddecoder-dir> python3 tools/homescapes-reference/extract_historical_tiles.py <apk>
Requires Pillow and texture2ddecoder. The original version predates the bundled
9.2.601 build; the state association is an inference from the tile appearance
and published descriptions, not a decoded sprite-name mapping.
"""
from hashlib import sha256
import json
from pathlib import Path
import sys
from zipfile import ZipFile

from decode_board_atlases import render_page

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'engine/art/homescapes'
MEMBER = 'assets/base_mm/atlases/Match3_04.dds'
REGIONS = [('ceramic-tile-2', (264, 1276, 341, 1353)),
           ('ceramic-tile-1', (344, 1276, 416, 1353)),
           ('membrane-fill-2', (275, 1287, 331, 1343))]


def main():
    apk = Path(sys.argv[1])
    with ZipFile(apk) as z:
        data = z.read(MEMBER)
    page, _, hashes = render_page(data)
    records = []
    for name, rect in REGIONS:
        sprite = page.crop(rect)
        output = DEST / 'sprites' / (name + '.png')
        sprite.save(output)
        records.append({'id': name, 'version': '3.5.9', 'archive': apk.name,
            'archive_sha256': sha256(apk.read_bytes()).hexdigest(), 'member': MEMBER,
            'member_sha256': sha256(data).hexdigest(), 'plane_sha256': hashes,
            'rect': list(rect), 'transform': 'crop decoded color and original opacity plane',
            'output': 'sprites/' + output.name, 'sha256': sha256(output.read_bytes()).hexdigest(),
            'mapping_evidence': 'https://homescapes.fandom.com/wiki/Ceramic_Tiles',
            'mapping_status': 'inferred from intact/fractured appearance; atlas names undecoded'})
    (DEST / 'historical-tile-sources.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    main()
