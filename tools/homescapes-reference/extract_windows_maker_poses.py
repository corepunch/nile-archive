#!/usr/bin/env python3
"""Extract the classic maker's authored dough and topping layers from Windows 9.2.601."""

import argparse
from hashlib import sha256
import json
from pathlib import Path
from xml.etree import ElementTree

from PIL import Image, ImageChops, ImageDraw
from decode_board_atlases import render_page
from decode_plxe import decode, load_keys

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'engine/art/homescapes'
DEST = ART / 'maker-source'
INVENTORY = ART / 'maker-charge-sources.json'
PACK = Path('Match3_CarryGenerator/atlases')
DDS = 'Match3_CarryGenerator.dds'
XML = 'Match3_CarryGenerator.xml'
PREFIX = 'textures/particles/Match3/Match3_CarryGenerator/Match3/CarryGenerator/'
EXPECTED = {
    DDS: 'db0d49b775bfc44b60b42b89d4e1c4b20bf75f70201e4bcf016b982a0ea9a643',
    XML: '6cfe01cd03380be31b9c5319872567bd46e81866eb2a647278b6e0615000ae34',
}
RAW, HEATED, GLAZE = '_0034_01', '_0033_02', '_0031_glaze'
GREEN = ('_0012_Green-3', '_0013_Green-4', '_0014_Green-5', '_0015_Green-6', '_0016_Green-1')
YELLOW = ('_0009_Yelow-3', '_0010_Yelow-2', '_0011_Yelow-1')
STAGES = ((), (RAW,), (HEATED,), (HEATED, GLAZE),
          (HEATED, GLAZE, *GREEN), (HEATED, GLAZE, *GREEN, *YELLOW))


def mesh_frame(atlas, frame):
    x, y, width, height = (int(frame.attrib[key]) for key in ('x', 'y', 'width', 'height'))
    if (width, height) != (276, 274):
        raise ValueError('Expected a shared 276 × 274 source frame')
    region = atlas.crop((x, y, x + width, y + height))
    vertices = [tuple(map(int, item.split(','))) for item in frame.findtext('vertices').strip(';').split(';')]
    triangles = [tuple(map(int, item.split(','))) for item in frame.findtext('indices').strip(';').split(';')]
    # Polygon-packed frames can overlap other frames. Keep only the pixels
    # addressed by the original sprite mesh, preserving the authored opacity.
    mask = Image.new('L', region.size)
    draw = ImageDraw.Draw(mask)
    for triangle in triangles:
        draw.polygon([vertices[index] for index in triangle], fill=255)
    region.putalpha(ImageChops.multiply(region.getchannel('A'), mask))
    return region.transpose(Image.Transpose.FLIP_TOP_BOTTOM), vertices, triangles


def extract(source, library, check):
    data = {}
    for filename, expected in EXPECTED.items():
        data[filename] = (source / PACK / filename).read_bytes()
        if sha256(data[filename]).hexdigest() != expected:
            raise ValueError(f'Unexpected original file: {filename}')
    xml = decode(data[XML], XML, load_keys(library.read_bytes()))
    frames = ElementTree.fromstring(xml)
    if frames.attrib.get('coords') != 'left-bottom':
        raise ValueError('Expected bottom-origin source atlas coordinates')
    by_id = {frame.attrib.get('id'): frame for frame in frames}
    atlas, _, hashes = render_page(data[DDS])

    records = {}
    for layer in (RAW, HEATED, GLAZE, *GREEN, *YELLOW):
        frame = by_id[PREFIX + layer]
        image, vertices, triangles = mesh_frame(atlas, frame)
        name = f'windows-charge{layer}.png'
        output = DEST / name
        if check:
            with Image.open(output) as actual:
                if actual.size != image.size or actual.convert('RGBA').tobytes() != image.tobytes():
                    raise ValueError(f'Original pixels differ for {layer}')
        else:
            image.save(output)
        records[layer] = {'output': name, 'frame': frame.attrib, 'vertices': vertices,
                          'triangles': triangles, 'rgba_sha256': sha256(image.tobytes()).hexdigest()}

    inventory = {
        'source': 'Homescapes 9.2.601.0 Windows x64, Microsoft Store 9NQ9KLZNV9SH',
        'source_folder': str(Path('res_base/res/packs') / PACK),
        'source_sha256': EXPECTED,
        'unpacked_bc7_sha256': hashes[0],
        'decoded_xml_sha256': sha256(xml).hexdigest(),
        'coordinate_transform': 'crop in raw DDS coordinates, apply source mesh, then flip vertically',
        'reference': 'https://www.youtube.com/watch?v=6XNxRO7CMs0',
        'stages': STAGES,
        'layers': records,
    }
    encoded = json.dumps(inventory, indent=2) + '\n'
    if check:
        if INVENTORY.read_text() != encoded:
            raise ValueError('Source inventory differs')
    else:
        INVENTORY.write_text(encoded)
    print(f"{'Verified' if check else 'Extracted'} {len(records)} original maker charge layers")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'reference/homescapes-analysis/windows-9.2.601')
    parser.add_argument('--library', type=Path, required=True, help='Known archived x86 library for PLXE v5')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    extract(args.source, args.library, args.check)


if __name__ == '__main__':
    main()
