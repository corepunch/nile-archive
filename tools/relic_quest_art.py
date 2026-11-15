#!/usr/bin/env python3
"""Register Relic Rush quest icons, item cards and collectible story pieces."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'games/relic-rush'
SOURCE = ROOT / 'art/quest-objects/source.png'
OUTPUT = ROOT / 'data/quest-objects.png'
# The props used on the Item recovered card.
FINDS = ROOT / 'data/finds'
KEYS = ['timber', 'lens', 'cable', 'chart', 'marker', 'tools', 'supplies', 'gear']
FIND_SIZE, FIND_PAINT = 320, 256
# Pixel boxes separate the two props whose painted silhouettes straddle the grid.
CROPS = [
    (0, 0, 443, 443), (443, 0, 887, 443), (887, 0, 1330, 443), (1330, 0, 1774, 443),
    (0, 443, 433, 887), (433, 443, 887, 887), (887, 443, 1330, 887), (1330, 443, 1774, 887),
]


def sprites(rewards):
    source = Image.open(SOURCE)
    if source.mode != 'RGBA' or source.size != (1774, 887):
        raise ValueError('Expected the authored 1774×887 RGBA source')
    for key, crop in zip(KEYS, CROPS):
        if key in rewards:
            reward = rewards[key]
            with Image.open(ROOT / reward['source']) as source_atlas:
                sprite = source_atlas.crop(reward['crop'])
        else:
            sprite = source.crop(crop)
        # Crop to visible paint plus an edge guard. Keep the original alpha
        # inside that crop and uniformly resize. No recolouring or masking.
        bounds = sprite.getchannel('A').point(lambda value: 255 if value >= 160 else 0).getbbox()
        left, top, right, bottom = bounds
        yield sprite.crop((max(0, left - 4), max(0, top - 4),
                           min(sprite.width, right + 4), min(sprite.height, bottom + 4)))


def atlas(rewards):
    out = Image.new('RGBA', (512, 256))
    for index, sprite in enumerate(sprites(rewards)):
        sprite.thumbnail((100, 87), Image.Resampling.LANCZOS)
        out.paste(sprite, (index % 4 * 128 + (128 - sprite.width) // 2,
                           index // 4 * 128 + (128 - sprite.height) // 2))
    return out


def finds(rewards):
    for key, sprite in zip(KEYS, sprites(rewards)):
        sprite.thumbnail((FIND_PAINT, FIND_PAINT), Image.Resampling.LANCZOS)
        out = Image.new('RGBA', (FIND_SIZE, FIND_SIZE))
        out.paste(sprite, ((FIND_SIZE - sprite.width) // 2, (FIND_SIZE - sprite.height) // 2))
        yield FINDS / f'{key}.png', out


def register_sprites(source_path, items, canvas_size, paint_size):
    with Image.open(ROOT / source_path) as source:
        assert source.mode == 'RGBA', 'quest sprites need authored alpha'
        for item in items:
            sprite = source.crop(item['crop'])
            sprite.thumbnail(tuple(paint_size), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', canvas_size)
            canvas.paste(sprite, ((canvas.width - sprite.width) // 2, (canvas.height - sprite.height) // 2))
            yield ROOT / item['runtime'], canvas


def same(path, expected):
    if not path.exists():
        return False
    with Image.open(path) as actual:
        return actual.size == expected.size and actual.mode == expected.mode and actual.tobytes() == expected.tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'art/board-states/manifest.json').read_text())
    quest = manifest['quest_objects']
    rewards = {'gear': quest['gear_reward'], **quest['reward_sources']}
    outputs = [(OUTPUT, atlas(rewards)), *finds(rewards)]
    for reward in quest['separate_rewards'].values():
        outputs.extend(register_sprites(reward['source'], [reward], reward['canvas'], reward['paint_size']))
    pieces = quest['story_pieces']
    for sheet in pieces['atlases']:
        outputs.extend(register_sprites(sheet['source'], sheet['items'].values(),
                                        pieces['canvas'], pieces['paint_size']))
    if args.check:
        for path, expected in outputs:
            if not same(path, expected):
                parser.error(f'{path.name} is out of date')
    else:
        for path, expected in outputs:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path, optimize=True)


if __name__ == '__main__':
    main()
