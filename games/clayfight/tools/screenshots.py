#!/usr/bin/env python3
"""Capture and review the arcade runtime with one combined game start."""
from pathlib import Path
import subprocess
from PIL import Image
GAME=Path(__file__).resolve().parents[1]
ROOT=GAME.parents[1]
TEMP=GAME/'build/arcade-review'
OUT=GAME/'docs/screenshots'
REVIEW=GAME/'docs/review/arcade/after'
for path in (TEMP,OUT,REVIEW):path.mkdir(parents=True,exist_ok=True)
subprocess.run([str(ROOT/'build/clayfight-arcade'),'-nosound','-creatures','data/creatures'],cwd=GAME,check=True)
for file in TEMP.glob('*.bmp'):
 if not file.name.startswith('reel-'):Image.open(file).save(REVIEW/(file.stem+'.png'))
frames=[Image.open(file).convert('RGB') for file in sorted(TEMP.glob('reel-*.bmp'))]
frames[0].save(REVIEW/'fight.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True)
for name,source in {'fight':'clay-fight','select':'select','campaign':'campaign','menu':'menu'}.items():
 Image.open(REVIEW/(source+'.png')).save(OUT/(name+'.png'))
 print(OUT/(name+'.png'))
