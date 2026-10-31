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
    subprocess.run([str(ROOT/'build/test/relic-rush'), 'resource-icons'], cwd=ROOT, check=True)
for source in (ROOT/'build/shots/frames').glob('resource-icons-*.png'):
    name = source.name.removeprefix('resource-icons-')
    if 'states' not in name:
        shutil.copy2(source, OUT/f'{version}-{name}')
