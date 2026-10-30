#!/usr/bin/env python3
"""Import a local Primal Rage PC copy into ignored runtime directories."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
GAME = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', nargs='?', type=Path, default=GAME.parents[1]/'reference/clayfight/primalrage')
args = parser.parse_args()
source=args.source.resolve()
if not (source/'INDEX').is_file() or not (source/'PRAGE.EXE').is_file():
    parser.error('source must contain INDEX and PRAGE.EXE')
destination=GAME/'data/primalrage'
if source != destination.resolve():
    destination.mkdir(parents=True,exist_ok=True)
    for file in source.iterdir():
        if file.is_file() and (file.suffix.upper()=='.GRA' or file.name.upper() in ('INDEX','PRAGE.EXE')):
            shutil.copy2(file,destination/file.name)
subprocess.run([sys.executable,'-I',str(GAME/'tools/pr2creature.py'),str(destination),str(GAME/'data/creatures/primalrage')],check=True)
print('Local runtime resources imported; data and derived creature files remain ignored by Git.')
