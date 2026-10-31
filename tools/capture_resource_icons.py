#!/usr/bin/env python3
"""Capture resource/hex review cases in one test-binary start (Xvfb on Linux)."""
import argparse
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'docs/review/resource-icons'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--existing', action='store_true', help='Copy a completed suite run without rerendering.')
parser.add_argument('--before', action='store_true', help='Label captures before applying an art change.')
args = parser.parse_args()
OUT.mkdir(parents=True, exist_ok=True)
version = 'before' if args.before else 'after'
if not args.existing:
    subprocess.run([str(ROOT/'build/test/relic-rush'), 'frame resource-icons-default-480x900',
        'frame resource-icons-default-390x844', 'shot floating-hud', 'shot phone-floating-hud',
        'shot art-jewels', 'shot art-resources', 'shot guide'], cwd=ROOT, check=True)
# Reuse each game's canonical pack/HUD captures instead of rendering another
# board per pack and size. Explicit sources also exclude stale scratch PNGs.
sources = {
    'default-480x900': 'frames/resource-icons-default-480x900',
    'default-390x844': 'frames/resource-icons-default-390x844',
    'relics-480x900': 'relic-rush/floating-hud',
    'relics-390x844': 'relic-rush/phone-floating-hud',
    'jewels-480x900': 'relic-rush/art-jewels',
    'resources-480x900': 'relic-rush/art-resources',
    'guide': 'relic-rush/guide',
}
for name, source in sources.items():
    shutil.copy2(ROOT/'build/shots'/(source+'.png'), OUT/f'{version}-{name}.png')
