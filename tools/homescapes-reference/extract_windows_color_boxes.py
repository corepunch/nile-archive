#!/usr/bin/env python3
"""Extract the 36 original Windows 9.2.601 colored-box board sprites."""

import argparse
from hashlib import sha256
import json
from pathlib import Path
from xml.etree import ElementTree

from PIL import Image
from decode_board_atlases import render_page
from decode_plxe import decode, load_keys

ROOT = Path(__file__).resolve().parents[2]
PACK = Path('Match3_ColorBox/atlases')
ART = ROOT / 'engine/art/homescapes'
INVENTORY = ART / 'color-box-board-sources.json'
ATLAS = 'Match3_ColorBox.dds'
METADATA = 'Match3_ColorBox.xml'
EXPECTED = {
    ATLAS: 'ac330b6d52b02a7d6a3a0bca9a15b4de14097ec59359dc9affbd51f050b9abf1',
    METADATA: 'bc1752f19dacf9391360a1e7163593dc8984882fdb7358d1c32b956553711eee',
}


def extract(source, library, check):
    inputs = {}
    for filename, expected in EXPECTED.items():
        data = (source / PACK / filename).read_bytes()
        if sha256(data).hexdigest() != expected:
            raise ValueError(f'Unexpected original file: {filename}')
        inputs[filename] = data

    xml = decode(inputs[METADATA], METADATA, load_keys(library.read_bytes()))
    root = ElementTree.fromstring(xml)
    if root.attrib.get('coords') != 'left-bottom':
        raise ValueError('Expected bottom-origin source atlas coordinates')
    frames = {frame.attrib['id']: frame for frame in root.findall('frame') if 'id' in frame.attrib}
    atlas, _, hashes = render_page(inputs[ATLAS])

    records = {}
    for color in range(6):
        for health in range(1, 7):
            texture = f'Match3ColorBox{health}{color + 1}'
            frame = frames[texture]
            x, y, w, h = (int(frame.attrib[key]) for key in ('x', 'y', 'width', 'height'))
            if len(frame) or not (0 <= x < x + w <= atlas.width and 0 <= y < y + h <= atlas.height):
                raise ValueError(f'Unexpected rectangular frame: {texture}')
            sprite = atlas.crop((x, y, x + w, y + h)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            name = f'color-box-{color}-{health}'
            dest = ART / 'sprites' / f'{name}.png'
            if check:
                with Image.open(dest) as actual:
                    if actual.size != sprite.size or actual.convert('RGBA').tobytes() != sprite.tobytes():
                        raise ValueError(f'Original pixels differ for {name}')
            else:
                sprite.save(dest)
            records[name] = {
                'id': texture,
                'original_path': frame.attrib['path'],
                'rect': [x, y, x + w, y + h],
                'frame_size': [int(frame.attrib['frameWidth']), int(frame.attrib['frameHeight'])],
                'trim_offset': [int(frame.attrib['innerX']), int(frame.attrib['innerY'])],
                'rgba_sha256': sha256(sprite.tobytes()).hexdigest(),
            }

    if len({record['rgba_sha256'] for record in records.values()}) != 36:
        raise ValueError('Expected 36 distinct original sprites')
    inventory = {
        'source': 'Homescapes 9.2.601.0 Windows x64, Microsoft Store 9NQ9KLZNV9SH',
        'source_folder': str(Path('res_base/res/packs') / PACK),
        'source_sha256': EXPECTED,
        'unpacked_bc7_sha256': hashes[0],
        'decoded_xml_sha256': sha256(xml).hexdigest(),
        'coordinate_transform': 'crop raw DDS coordinates, flip cropped sprite vertically',
        'frames': records,
    }
    if check:
        if json.loads(INVENTORY.read_text()) != inventory:
            raise ValueError('Source inventory differs')
    else:
        INVENTORY.write_text(json.dumps(inventory, indent=2) + '\n')
    print(f"{'Verified' if check else 'Extracted'} {len(records)} original colored-box states")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'reference/homescapes-analysis/windows-9.2.601')
    parser.add_argument('--library', type=Path, required=True, help='Known archived x86 library for PLXE v5')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    extract(args.source, args.library, args.check)


if __name__ == '__main__':
    main()
