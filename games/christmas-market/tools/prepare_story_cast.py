#!/usr/bin/env python3
"""Register the ImageGen story busts on the existing dialogue canvas."""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SIZE = (320, 480)
# Crop windows on the 1536×1024 sheet. Include the full visible silhouette.
CROPS = {
    'theo': (8, 0, 512, 511),
    'agnes': (580, 0, 1006, 511),
    'henrik': (1025, 0, 1523, 511),
    'pip': (6, 512, 488, 1022),
    'wren': (545, 512, 990, 1022),
}
NEW_CROPS = {
    'alder': (62, 0, 600, 618),
    'finch': (642, 0, 1227, 618),
    'mary': (0, 624, 621, 1242),
    'rosa': (644, 624, 1254, 1242),
}


def export(key, atlas, crop, check):
    # Keep the atlas's right-facing pose. Dialogue mirrors the right slot.
    bust = atlas.crop(crop)
    bust.thumbnail(SIZE, Image.Resampling.LANCZOS)
    image = Image.new('RGBA', SIZE)
    image.paste(bust, ((SIZE[0] - bust.width) // 2, SIZE[1] - bust.height))
    path = ROOT / 'data/story/characters' / f'{key}.png'
    if check:
        # PNG compression can vary between platforms. The art contract is the
        # decoded RGBA canvas, including the authored alpha.
        with Image.open(path) as saved:
            assert saved.mode == image.mode and saved.size == image.size and saved.tobytes() == image.tobytes(), (
                f'Stale story bust: {path}')
    else:
        image.save(path, 'PNG')


def prepare(check=False):
    for name, size, crops in (
        ('story-cast.png', (1536, 1024), CROPS),
        ('new-story-cast.png', (1254, 1254), NEW_CROPS),
    ):
        with Image.open(ROOT / 'art' / name) as atlas:
            assert atlas.mode == 'RGBA' and atlas.size == size
            for key, crop in crops.items():
                export(key, atlas, crop, check)
    print(f'Christmas Market: {len(CROPS) + len(NEW_CROPS)} painted supporting busts')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    prepare(parser.parse_args().check)
