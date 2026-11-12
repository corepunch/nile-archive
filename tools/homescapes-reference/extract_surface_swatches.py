#!/usr/bin/env python3
"""Extract original Homescapes surface swatches; no alpha or color is altered.

Requires Pillow, texture2ddecoder and zstd, as does decode_board_atlases.py.
Coordinates are in the vertically flipped decoded image, with exclusive ends.
"""
from hashlib import sha256
import json
from pathlib import Path
from zipfile import ZipFile

from PIL import Image
from decode_board_atlases import render_page
from story_index import SOURCE, decode

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'engine/art/homescapes'
SWATCHES = (
    ('honey-swatch', 'Honey', (480, 240, 599, 359)),
    ('carpet-swatch', 'Carpet', (481, 241, 599, 359)),
)


def main():
    records = []
    with ZipFile(SOURCE) as archive:
        for name, element, rect in SWATCHES:
            member = f'base_mm/Match3/vso/textures/Elements/{element}/Border.dds'
            source = archive.read(member)
            page, _, blocks = render_page(decode(source))
            sprite = page.transpose(Image.Transpose.FLIP_TOP_BOTTOM).crop(rect)
            output = DEST / 'sprites' / (name + '.png')
            sprite.save(output)
            records.append({'id': name, 'archive': 'reference/Homescapes.app/base.zip',
                'member': member, 'source_sha256': sha256(source).hexdigest(),
                'decoded_plane_sha256': blocks, 'flipped_rect': list(rect),
                'transform': 'vertically flip decoded texture, then crop; preserve RGBA',
                'alpha_range': list(sprite.getchannel('A').getextrema()),
                'output': 'sprites/' + output.name, 'sha256': sha256(output.read_bytes()).hexdigest()})
    (DEST / 'surface-swatches.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    main()
