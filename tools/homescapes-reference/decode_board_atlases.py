#!/usr/bin/env python3
"""Reconstruct the five Homescapes Match3 atlas pages and export board sprites."""
import argparse
from hashlib import sha256
import html
import json
from pathlib import Path
import struct
from tempfile import TemporaryDirectory
from zipfile import ZipFile

from extract_gems import DEST as GEMS
from sprite_metadata import bundled_references
from story_index import SOURCE, decode

OUTPUT = GEMS.parent / 'board-art'
REGIONS = Path(__file__).with_name('board_regions.json')
PAGES = [f'Match3_{index:02}' for index in range(5)]
BLOCK_SIZE = 8
DISTANCE_FORMATS = {61: (5, 1), 64: (13, 33), 62: (16, 8225), 63: (20, 73761)}


def read_streams(data, *, allow_trailer=False):
    if len(data) < 128 or data[:4] != b'DDS ' or data[84:88] != b'etc2':
        raise ValueError('Expected an ETC2-tagged DDS')
    height, width, _, planes = struct.unpack_from('<4I', data, 12)
    if not (0 < width <= 8192 and 0 < height <= 8192 and 1 <= planes <= 3):
        raise ValueError('Unsupported texture size or plane count')
    offset = 128
    streams = []
    for _ in range(planes):
        if offset + 16 > len(data):
            raise ValueError(f'Truncated stream header at {offset}')
        words, commands, entries, literals = struct.unpack_from('<4I', data, offset)
        end = offset + 4 + 4 * words
        if (words != 3 + commands + 2 * entries + literals or end > len(data)
                or entries > 60 or literals % 2):
            raise ValueError(f'Invalid board stream layout at {offset}')
        commands_end = offset + 16 + 4 * commands
        dictionary_end = commands_end + BLOCK_SIZE * entries
        streams.append((offset, data[offset + 16:commands_end],
                        data[commands_end:dictionary_end], data[dictionary_end:end]))
        offset = end
    if offset != len(data) and not allow_trailer:
        raise ValueError('Streams do not span the DDS payload')
    return width, height, streams


class Bits:
    def __init__(self, data):
        self.data = ''.join(f'{byte:08b}' for byte in data)
        self.pos = 0

    def take(self, width):
        end = self.pos + width
        if end > len(self.data):
            raise ValueError('Truncated atlas command')
        value = int(self.data[self.pos:end], 2)
        self.pos = end
        return value

    def short_run(self):
        end = self.data.find('1', self.pos, self.pos + 8)
        if end < 0:
            raise ValueError('Invalid short run')
        length = end - self.pos + 1
        self.pos = end + 1
        return length


def unpack_blocks(commands, dictionary, literals, block_count):
    bits = Bits(commands)
    blocks = []
    literal_pos = 0
    distance = 0
    while len(blocks) < block_count:
        count = 1
        op = bits.take(2)
        # 110 + five bits multiplies the next operation's run length.
        # 111 selects a run of 13-bit backward distances.
        while op == 3:
            if bits.take(1):
                op = 4
                break
            count *= bits.take(5) + 2
            if count > block_count - len(blocks):
                raise ValueError('Atlas run exceeds plane size')
            op = bits.take(2)
        if op < 2 and count == 1:
            count = bits.short_run()
        if count > block_count - len(blocks):
            raise ValueError('Atlas run exceeds plane size')

        if op == 0:
            if not blocks:
                raise ValueError('Atlas repeats a block before any output')
            blocks.extend([blocks[-1]] * count)
        elif op == 1:
            end = literal_pos + count * BLOCK_SIZE
            if end > len(literals):
                raise ValueError('Atlas run exceeds literal data')
            blocks.extend(literals[i:i + BLOCK_SIZE] for i in range(literal_pos, end, BLOCK_SIZE))
            literal_pos = end
        else:
            # A dictionary run starts with a six-bit selector. The reserved
            # selectors select the distance format for the entire run.
            selector = bits.take(6) if op == 2 else 64
            if selector < 60:
                for index in range(count):
                    entry = selector if index == 0 else bits.take(6)
                    start = entry * BLOCK_SIZE
                    if entry >= 60 or start >= len(dictionary):
                        raise ValueError('Atlas dictionary entry out of range')
                    blocks.append(dictionary[start:start + BLOCK_SIZE])
                continue
            for _ in range(count):
                if selector != 60:
                    width, base = DISTANCE_FORMATS[selector]
                    distance = bits.take(width) + base
                if not 0 < distance <= len(blocks):
                    raise ValueError('Atlas backward distance out of range')
                blocks.append(blocks[-distance])
    if literal_pos != len(literals) or '1' in bits.data[bits.pos:]:
        raise ValueError('Unused data at end of atlas stream')
    return b''.join(blocks)


def unpack_dds(data, *, allow_trailer=False):
    width, height, streams = read_streams(data, allow_trailer=allow_trailer)
    count = ((width + 3) // 4) * ((height + 3) // 4)
    return width, height, [unpack_blocks(cmd, entries, literals, count)
                           for _, cmd, entries, literals in streams]


def render_page(data, *, allow_trailer=False):
    from PIL import Image
    import texture2ddecoder as texture

    width, height, planes = unpack_dds(data, allow_trailer=allow_trailer)
    if len(planes) < 2:
        raise ValueError('Expected Match3 color and opacity planes')

    def image(decoder, plane):
        return Image.frombytes('RGBA', (width, height), decoder(plane, width, height), 'raw', 'BGRA')

    color = image(texture.decode_etc2, planes[0])
    color.putalpha(image(texture.decode_eacr, planes[1]).getchannel('R'))
    auxiliary = image(texture.decode_etc2, planes[2]).convert('RGB') if len(planes) == 3 else None
    return color, auxiliary, [sha256(plane).hexdigest() for plane in planes]


def gallery(pages, sprites):
    thumbnails = []
    for item in sprites:
        label = html.escape(item['label'])
        path = html.escape(item['file'], quote=True)
        detail = html.escape(f"{item['id']} · {item['page']}")
        thumbnails.append(f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{label}"></a>'
                          f'<figcaption>{label}<small>{detail}</small></figcaption></figure>')
    sheets = []
    for item in pages:
        name = item['id']
        sheets.append(f'<figure><a href="{item["color"]}"><img loading="lazy" src="{item["color"]}" alt="{name}"></a>'
                      f'<figcaption>{name} · <a href="{item["auxiliary"]}">Auxiliary plane</a></figcaption></figure>')
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Homescapes board atlas</title>
<style>
body{{font:16px system-ui,sans-serif;background:#f6f3ee;color:#28232c;max-width:1260px;margin:auto;padding:1.5rem}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:.8rem}}
.sheets{{grid-template-columns:repeat(auto-fill,minmax(275px,1fr))}}
figure{{margin:0;padding:.6rem;border-radius:.4rem;background:#fff;text-align:center}}
img{{width:100%;height:105px;object-fit:contain;background:#e7ded4}}.sheets img{{height:auto;aspect-ratio:1}}
figcaption{{font-size:.9rem}}small{{display:block;overflow-wrap:anywhere;color:#625764}}
</style></head><body><h1>Homescapes board atlas</h1>
<p>Original board textures from Homescapes 9.2.601. Click an image to open its full PNG.
The <a href="manifest.json">manifest</a> records source files, regions and orientation.
Browse the <a href="prefab-references.json">prefab names and settings</a> recovered from the bundle.</p>
<h2>Identified sprites</h2><div class="grid">{''.join(thumbnails)}</div>
<h2>Complete atlas pages</h2><div class="grid sheets">{''.join(sheets)}</div>
</body></html>'''


def export(source, output):
    from PIL import Image

    regions = json.loads(REGIONS.read_text(encoding='utf-8'))
    output.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(prefix='.board-art-', dir=output.parent) as work:
        root = Path(work) / 'art'
        (root / 'pages').mkdir(parents=True)
        (root / 'sprites').mkdir()
        pages, sprites = [], []
        flip = Image.Transpose.FLIP_TOP_BOTTOM
        for page, name in enumerate(PAGES):
            source_file = source / (name + '.dds')
            data = source_file.read_bytes()
            color, auxiliary, hashes = render_page(data)
            if color.size != (1576, 1576) or auxiliary is None:
                raise ValueError(f'Unexpected atlas size for {name}')
            file = f'pages/{name}.png'
            auxiliary_file = f'pages/{name}-auxiliary.png'
            color.transpose(flip).save(root / file)
            auxiliary.transpose(flip).save(root / auxiliary_file)
            pages.append({'id': name, 'source': source_file.name, 'source_sha256': sha256(data).hexdigest(),
                          'block_sha256': hashes, 'color': file, 'auxiliary': auxiliary_file,
                          'orientation': 'vertical flip of packed data'})
            for region in regions:
                if region.get('page') != page:
                    continue
                x0, y0, x1, y1 = region['rect']
                if not (0 <= x0 < x1 <= color.width and 0 <= y0 < y1 <= color.height):
                    raise ValueError(f'Invalid crop for {region["id"]}')
                sprite = color.crop(region['rect'])
                for left, top, right, bottom in region.get('exclude', []):
                    if not (x0 <= left < right <= x1 and y0 <= top < bottom <= y1):
                        raise ValueError(f'Invalid exclusion for {region["id"]}')
                    sprite.paste((0, 0, 0, 0), (left - x0, top - y0, right - x0, bottom - y0))
                sprite = sprite.transpose(flip)
                if not sprite.getchannel('A').getbbox():
                    raise ValueError(f'Empty crop for {region["id"]}')
                file = f'sprites/{region["id"]}.png'
                sprite.save(root / file)
                sprites.append({**region, 'page': name, 'file': file, 'orientation': 'vertical flip of packed data'})
        supplemental = [region for region in regions if 'source' in region]
        if supplemental:
            with ZipFile(SOURCE) as archive:
                for region in supplemental:
                    member = region['source']
                    wrapped = archive.read(member)
                    # The named web texture appends a third stream after the
                    # declared color and opacity. Its static crop uses those two planes.
                    color, _, hashes = render_page(decode(wrapped), allow_trailer=region['id'] == 'web-2')
                    x0, y0, x1, y1 = region['rect']
                    if not (0 <= x0 < x1 <= color.width and 0 <= y0 < y1 <= color.height):
                        raise ValueError(f'Invalid crop for {region["id"]}')
                    file = f'sprites/{region["id"]}.png'
                    color.crop(region['rect']).transpose(flip).save(root / file)
                    sprites.append({**region, 'page': Path(member).parent.name + '/' + Path(member).name,
                                    'file': file, 'source_sha256': sha256(wrapped).hexdigest(),
                                    'block_sha256': hashes, 'orientation': 'vertical flip of packed data'})
        if len(sprites) != len(regions) or len({item['id'] for item in sprites}) != len(regions):
            raise ValueError('Missing or duplicate atlas region')
        order = {region['id']: index for index, region in enumerate(regions)}
        sprites.sort(key=lambda item: order[item['id']])
        (root / 'manifest.json').write_text(json.dumps({'pages': pages, 'sprites': sprites}, indent=2) + '\n',
                                            encoding='utf-8')
        (root / 'prefab-references.json').write_text(json.dumps(bundled_references(), indent=2) + '\n',
                                                     encoding='utf-8')
        (root / 'index.html').write_text(gallery(pages, sprites), encoding='utf-8')
        root.rename(output)
    print(f'{len(pages)} decoded pages and {len(sprites)} sprites: {output}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=GEMS / 'board-atlases')
    parser.add_argument('--output', type=Path, default=OUTPUT)
    args = parser.parse_args()
    if args.output.exists() or args.output.is_symlink():
        parser.error(f'Destination already exists: {args.output}')
    try:
        export(args.source, args.output)
    except ModuleNotFoundError as error:
        parser.error(f'{error}. Install Pillow and texture2ddecoder to export PNGs.')


if __name__ == '__main__':
    main()
