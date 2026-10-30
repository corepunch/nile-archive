#!/usr/bin/env python3
"""Compare the original executable and the port with identical data and ticks.

Requires a built original checkout and locally supplied retail resources. Output
and working directories are temporary; neither checkout is modified.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / 'games/clayfight'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path, help='Original Clayfight executable')
    args = parser.parse_args()
    original = args.original.resolve()
    binaries = [original, ROOT / 'build/clayfight']
    data = ['-data', str(GAME / 'data/primalrage'), '-creatures', str(GAME / 'data/creatures'), '-nosound']
    scenes = {name: ['-warp', name] for name in ('menu', 'start', 'options', 'select', 'map')}
    for i, name in enumerate(('sauron', 'armadon', 'blizzard', 'vertigo', 'talon', 'chaos', 'diablo')):
        scenes[name] = ['-fight', name, 'sauron', '-stage', str(i), '-cpu']
    scenes['clay'] = ['-fight', 'boxer', 'lizard', '-cpu']
    frames = 0
    with tempfile.TemporaryDirectory(prefix='clay-parity-') as temp:
        work = Path(temp)
        for name, switches in scenes.items():
            folders = [work / name / str(i) for i in range(2)]
            for binary, folder in zip(binaries, folders):
                folder.mkdir(parents=True)
                subprocess.run([str(binary), *data, *switches, '-shots', str(folder / 'f'),
                                '-every', '120', '-tics', '601'], cwd=work, check=True,
                               capture_output=True, timeout=60)
            for old in sorted(folders[0].glob('*.bmp')):
                new = folders[1] / old.name
                with Image.open(old) as a, Image.open(new) as b:
                    if a.size != b.size or ImageChops.difference(a.convert('RGB'), b.convert('RGB')).getbbox():
                        raise AssertionError(f'{name}/{old.name}: framebuffer differs')
                frames += 1
            print(f'{name}: six frames identical', flush=True)
    print(f'parity: {frames} pixel-identical frames across {len(scenes)} scenes')


if __name__ == '__main__':
    main()
