"""Real-game before/after capture matrix for building art and ground shadows."""
from pathlib import Path
import subprocess
import sys
from PIL import Image

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parents[1]
label = sys.argv[1]
assert label in ('before', 'after')
OUT = GAME / 'docs/review/painted-buildings'
OUT.mkdir(parents=True, exist_ok=True)
tmp = ROOT / 'build/building-captures'
tmp.mkdir(exist_ok=True)
scenes = {
    'village': ['--showcase'],
    'registration': ['--showcase', '--footprints'],
    'placement': ['--city', '6', '--placing'],
    'dragging': ['--city', '6', '--placing', 'dragging', '--frames', '30'],
    'blocked': ['--city', '6', '--placing', 'blocked'],
    'card': ['--card', '6'],
    'reward': ['--level', '6', '--victory', '--frames', '60'],
}
if len(sys.argv) > 2:
    scenes = {sys.argv[2]: scenes[sys.argv[2]]}
for size in ('480x900', '390x844'):
    for name, args in scenes.items():
        png = tmp / f'{label}-{name}-{size}.png'
        extra = ['--safe-area', '0,47,0,34'] if size == '390x844' else []
        subprocess.run([str(ROOT / 'build/relic-rush'), '--headless', '--mute', '--fresh',
                        '--size', size, '--shot', str(png), *args, *extra], cwd=ROOT, check=True)
        with Image.open(png) as im:
            im.convert('RGB').save(OUT / f'{label}-{name}-{size}.jpg', quality=88)
        png.unlink()
print(OUT)
