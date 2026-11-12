#!/usr/bin/env python3
"""Register the single authored 48-state atlas; preserve its RGBA artwork."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops
from hex_tile_art import inspect

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engine/art/match3-elements/source.png'
PROMPT = SOURCE.with_name('prompt.txt')
MANIFEST = SOURCE.with_name('manifest.json')
OBJECT_SOURCE = SOURCE.with_name('source-v1.png')
MASK = ROOT / 'engine/art/hex-tile/hex-mask-128.png'
NAMES = ([f'stone-{hp}' for hp in (1, 2, 3)] +
         [f'crate-{kind}-{hp}' for kind in range(6) for hp in (1, 2)] +
         ['tunnel-in', 'tunnel-out', 'hidden-covered', 'hidden-partial',
          'hidden-revealed', 'growth', 'delivery', 'delivery-exit', 'object-goal'])
GAMES = ('relic-rush', 'christmas-market')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        spec = json.loads(MANIFEST.read_text())
        for path, sha in spec['fingerprints'].items():
            assert digest(ROOT / path) == sha, f'Stale element artwork: {path}'
        for row in spec['assets']:
            with Image.open(ROOT / row['runtime']) as image:
                assert image.mode == 'RGBA' and image.size == (128, 128)
                assert image.getchannel('A').getextrema() == (0, 255)
                if row['name'] != 'delivery':
                    assert inspect(image, strict=True)['pass'], f'Tile does not fill canonical mask: {row["runtime"]}'
        print('48 element states verified; all 46 tile surfaces pass strict canonical mask fit')
        return
    source = Image.open(SOURCE).convert('RGBA')
    objects = Image.open(OBJECT_SOURCE).convert('RGBA')
    mask = Image.open(MASK).getchannel('A')
    assert source.size == objects.size == (1448, 1086)
    assert len(NAMES) == 24
    assets, paths = [], [SOURCE, PROMPT, OBJECT_SOURCE, SOURCE.with_name('prompt-v1.txt'), MASK,
                        ROOT / 'engine/art/hex-tile/atlas-template-8x6-181.png', Path(__file__)]
    for theme, game in enumerate(GAMES):
        for index, name in enumerate(NAMES):
            row, column = divmod(theme * 24 + index, 8)
            box = [column * 181, row * 181, (column + 1) * 181, (row + 1) * 181]
            image = (objects if name == 'delivery' else source).crop(box).resize((128, 128), Image.Resampling.LANCZOS)
            if name != 'delivery':
                # The user's canonical mask defines the cutout. Full-bleed
                # paintings retain every authored strength/color inside it.
                image.putalpha(ImageChops.multiply(image.getchannel('A'), mask))
            path = ROOT / 'games' / game / 'data/board-states' / f'{name}.png'
            path.parent.mkdir(parents=True, exist_ok=True)
            image.save(path, optimize=True)
            paths.append(path)
            assets.append({'game': game, 'name': name, 'crop': box,
                           'source': str((OBJECT_SOURCE if name == 'delivery' else SOURCE).relative_to(ROOT)),
                           'mode': 'object' if name == 'delivery' else 'fill',
                           'runtime': str(path.relative_to(ROOT)), 'size': [128, 128]})
    spec = {'source': str(SOURCE.relative_to(ROOT)), 'prompt': str(PROMPT.relative_to(ROOT)),
            'generator': 'built-in ImageGen; 48-cell surface atlas authored together on 2026-11-12; two freestanding delivery icons retained from first 48-cell atlas',
            'source_size': list(source.size), 'grid': [8, 6],
            'transform': 'Fixed 181px cell crop, uniform resize to 128px; full-bleed surfaces cut with canonical engine hex mask. Delivery icons retain original authored alpha. No recoloring or derived damage states.',
            'mask': str(MASK.relative_to(ROOT)),
            'reproduction': 'python3 tools/match3_elements_art.py && python3 tools/match3_atlas.py',
            'review': 'docs/review/match3-elements/README.md', 'assets': assets,
            'fingerprints': {str(p.relative_to(ROOT)): digest(p) for p in paths}}
    MANIFEST.write_text(json.dumps(spec, indent=2) + '\n')
    print('Registered 48 original sprites for both game atlases')


if __name__ == '__main__':
    main()
