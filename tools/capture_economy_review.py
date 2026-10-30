"""Capture economy comparisons with the actual native game renderer.

python3 tools/capture_economy_review.py --before-ref ac69ea7
Linux: run under Xvfb with LIBGL_ALWAYS_SOFTWARE=1. Uses existing Pillow only.
"""
import argparse
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--before-ref', help='Optional base commit to capture alongside current code')
args = parser.parse_args()

relic = {
    'result': ['--victory', '--frames', '120'], 'island': ['--city', '1'],
    'shop': ['--catalogue'], 'wonder': ['--card', '1'],
    'expansion': ['--city', '2', '--open', '1', '--zone', '1'],
    'finale-island': ['--city', '10'],
}
new_relic = {'replay-result': ['--replay-victory', '--frames', '120'],
             **{f'expeditions-{n}': ['--expeditions', '--expedition-page', str(n)] for n in range(1, 5)}}
nile = {n: ['--screen', n] for n in ['win', 'chapters', 'build', 'island']}
new_nile = {n: ['--screen', n] for n in ['purchase', 'opening', 'first-build', 'first-win']}
sets = [
    ('relic-rush', [('480x900', []), ('390x844', ['--safe-area', '0,47,0,34'])], relic, new_relic, (640, 1000)),
    ('nile-archive', [(s, []) for s in ['1200x900', '1368x1026', '1600x900']], nile, new_nile, (1200, 1000)),
]
with tempfile.TemporaryDirectory(prefix='economy-review-') as directory:
    temp = Path(directory)
    if args.before_ref:
        blob = subprocess.check_output(['git', 'archive', args.before_ref,
                                       'games/relic-rush/lua', 'games/relic-rush/data',
                                       'games/nile-archive/lua', 'games/nile-archive/data'], cwd=ROOT)
        # The archive is from our own Git tree and contains only these paths.
        with tarfile.open(fileobj=io.BytesIO(blob)) as archive:
            for member in archive.getmembers():
                path = Path(member.name)
                assert not path.is_absolute() and '..' not in path.parts
            archive.extractall(temp)
    for game, sizes, old_shots, new_shots, max_size in sets:
        output = ROOT / f'games/{game}/docs/review/economy'
        output.mkdir(parents=True, exist_ok=True)
        for phase in (['before', 'after'] if args.before_ref else ['after']):
            for size, extra in sizes:
                for name, screen in (old_shots if phase == 'before' else {**old_shots, **new_shots}).items():
                    png = temp / 'capture.png'
                    old = temp / f'games/{game}'
                    source = ['--lua', str(old / 'lua'), '--data', str(old / 'data')] if phase == 'before' else []
                    subprocess.run([str(ROOT / f'build/{game}'), '--headless', '--fresh', '--mute',
                                    '--size', size, *source, *extra, *screen, '--shot', str(png)],
                                   cwd=ROOT, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    image = Image.open(png).convert('RGB')
                    image.thumbnail(max_size, Image.Resampling.LANCZOS)
                    image.save(output / f'{phase}-{name}-{size}.jpg', quality=90, subsampling=0, optimize=True)
                print(game, phase, size, flush=True)
