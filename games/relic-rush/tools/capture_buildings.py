"""Real-game before/after capture matrix for building art and ground shadows."""
from pathlib import Path
import os
import subprocess
import sys
import tarfile
import tempfile
import io
from PIL import Image

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parents[1]
label = sys.argv[1]
# The before fixture uses main's Lua with the same current sprite data.
# The integration renderer supplies gold debug outlines in both fixtures.
workspace = tempfile.TemporaryDirectory(prefix='building-review-')
fixture_root = Path(workspace.name)
if label == 'before':
    blob = subprocess.check_output(['git', 'archive', '6a56346',
                                   'games/relic-rush/lua', 'games/nile-archive/lua'])
    with tarfile.open(fileobj=io.BytesIO(blob)) as archive:
        archive.extractall(fixture_root)
def original(game):
    return ['--lua', str(fixture_root / f'games/{game}/lua')] if label == 'before' else []
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
    'reward': ['--level', '6', '--victory', '--frames', '120'],
}
if len(sys.argv) > 2:
    scenes = {sys.argv[2]: scenes[sys.argv[2]]}
for size in ('480x900', '390x844'):
    for name, args in scenes.items():
        png = tmp / f'{label}-{name}-{size}.png'
        extra = ['--safe-area', '0,47,0,34'] if size == '390x844' else []
        source = original('relic-rush')
        for flag, env in (('--lua', 'RR_CAPTURE_LUA'), ('--data', 'RR_CAPTURE_DATA')):
            if os.environ.get(env): source += [flag, os.environ[env]]
        binary = os.environ.get('RR_CAPTURE_BINARY', str(ROOT / 'build/relic-rush'))
        subprocess.run([binary, '--headless', '--mute', '--fresh',
                        '--size', size, '--shot', str(png), *args, *extra, *source], cwd=ROOT, check=True)
        with Image.open(png) as im:
            im.convert('RGB').save(OUT / f'{label}-{name}-{size}.jpg', quality=88)
        png.unlink()
for size in ('1200x900', '1368x1026', '1600x900'):
    png = tmp / f'{label}-nile-registration-{size}.png'
    subprocess.run([str(ROOT / 'build/nile-archive'), '--headless', '--mute', '--fresh',
                    '--size', size, '--screen', 'island', '--footprints', '--shot', str(png), *original('nile-archive')], cwd=ROOT, check=True)
    with Image.open(png) as im:
        im.convert('RGB').save(OUT / f'{label}-nile-registration-{size}.jpg', quality=88)
    png.unlink()
print(OUT)
