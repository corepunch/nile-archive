#!/usr/bin/env python3
"""Turn the pictures the test build rendered into documentation images. Starts no game.

    make shots

Screens are tests: add one to tests/games/<game>.lua. The test binaries write PNGs to
build/shots/<game>/, and scratch frames to build/shots/frames/.
"""
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / 'build/shots'
# Christmas Market's documentation images are at logical size.
LOGICAL = {'christmas-market': 90}


def logical_sizes(game):
    spec = (ROOT / f'tests/games/{game}.lua').read_text()
    return {name: tuple(map(int, size.split('x'))) for name, size in re.findall(r'shot\("([^"]+)", "(\d+x\d+)"', spec)}


def main():
    for folder in sorted(p for p in SHOTS.iterdir() if p.is_dir() and p.name != 'frames'):
        game = folder.name
        out = ROOT / f'games/{game}/docs/screenshots'
        out.mkdir(parents=True, exist_ok=True)
        sizes = logical_sizes(game)
        for png in sorted(folder.glob('*.png')):
            im = Image.open(png).convert('RGB')
            if game in LOGICAL:
                im = im.resize(sizes.get(png.stem, (480, 900)), Image.Resampling.LANCZOS)
            im.save(out / f'{png.stem}.jpg', quality=LOGICAL.get(game, 86))
    frames = SHOTS / 'frames'
    if frames.is_dir():
        for mode in ('skins', 'layers'):
            im = Image.open(frames / f'ui-{mode}.png').convert('RGB')
            im.thumbnail((1200, 1000))
            im.save(ROOT / f'docs/screenshots/ui-{mode}.jpg', quality=86)
        subprocess.run([sys.executable, str(ROOT / 'tools/make_reels.py'), str(frames), str(ROOT / 'games/relic-rush/docs/screenshots')], check=True)
        motion = [Image.open(frames / f'motion-{i}.png').convert('RGB').resize((600, 450), Image.Resampling.LANCZOS) for i in range(16)]
        motion = [im.quantize(colors=128, method=Image.Quantize.MEDIANCUT) for im in motion]
        motion[0].save(ROOT / 'docs/screenshots/motion-reel.gif', save_all=True, append_images=motion[1:], duration=100, loop=0, optimize=True)
        # the result dialogs arriving on the motion module, 6 frames apart
        for game, prefix, size in (('christmas-market', 'christmas-market-reward-entrance', (240, 450)), ('nile-archive', 'nile-reward-entrance', (600, 450))):
            reel = [Image.open(frames / f'{prefix}-{i}.png').convert('RGB').resize(size, Image.Resampling.LANCZOS) for i in range(16)]
            reel = [im.quantize(colors=128, method=Image.Quantize.MEDIANCUT) for im in reel]
            reel[0].save(ROOT / f'games/{game}/docs/screenshots/reward-entrance-reel.gif', save_all=True, append_images=reel[1:], duration=100, loop=0, optimize=True)
    print('documentation images written')


if __name__ == '__main__':
    main()
