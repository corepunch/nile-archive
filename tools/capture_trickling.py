#!/usr/bin/env python3
"""Capture vertical reference / diagonal refill with one test-binary start per game."""
import argparse
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--existing', action='store_true', help='Copy an existing full-suite run without rendering again.')
parser.add_argument('--game', choices=['relic-rush','christmas-market'])
args = parser.parse_args()
# Each suite starts once; its manifest owns every size and state.
if not args.existing and args.game != 'christmas-market':
    subprocess.run([str(ROOT/'build/test/relic-rush'), 'trickling-relic-rush'], cwd=ROOT, check=True)
if not args.existing and args.game != 'relic-rush':
    subprocess.run([str(ROOT/'build/test/christmas-market'), 'trickling-christmas-market'], cwd=ROOT, check=True)
for game in ([args.game] if args.game else ['relic-rush','christmas-market']):
    out = ROOT/'games'/game/'docs/review/trickling'
    out.mkdir(parents=True, exist_ok=True)
    for version, mode in [('reference-vertical','vertical'),('after','diagonal')]:
        for size in ['480x900','390x844']:
            source = ROOT/'build/shots/frames'/f'trickling-{game}-{mode}-{size}.png'
            shutil.copy2(source, out/f'{version}-{size}.png')
