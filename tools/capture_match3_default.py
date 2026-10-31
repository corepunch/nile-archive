#!/usr/bin/env python3
"""Capture atlas reviews with one start per game (make build/test/<game> first)."""
import argparse
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / 'build/shots'
FRAMES = SHOTS / 'frames'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--existing', action='store_true', help='Copy a completed suite run without rerendering.')
args = parser.parse_args()
if not args.existing:
    subprocess.run([str(ROOT/'build/test/relic-rush'), 'frame resource-icons-default',
        'shot art-catalogue', 'shot hud-states', 'shot effect-bomb'], cwd=ROOT, check=True)
    subprocess.run([str(ROOT/'build/test/christmas-market'), 'shot art-states',
        'shot hud-states', 'frame atlas-christmas-market-effects'], cwd=ROOT, check=True)
out = ROOT/'docs/review/match3'
out.mkdir(parents=True, exist_ok=True)
for destination, source in {
    'default-board-480x900': 'resource-icons-default-480x900',
    'default-board-390x844': 'resource-icons-default-390x844',
    'default-board-states': 'resource-icons-default-board-states',
    'default-hud-states': 'resource-icons-default-hud-states',
}.items():
    shutil.copy2(FRAMES/(source+'.png'), out/(destination+'.png'))
sources = {
    'relic-rush': {'board': 'relic-rush/art-catalogue', 'hud': 'relic-rush/hud-states',
                   'effects': 'relic-rush/effect-bomb'},
    'christmas-market': {'board': 'christmas-market/art-states', 'hud': 'christmas-market/hud-states',
                        'effects': 'frames/atlas-christmas-market-effects'},
}
for game, captures in sources.items():
    out = ROOT/'games'/game/'docs/review/trickling'
    out.mkdir(parents=True, exist_ok=True)
    for name, source in captures.items():
        name = name if name == 'effects' else name + '-states'
        shutil.copy2(SHOTS/(source+'.png'), out/f'atlas-{name}.png')
