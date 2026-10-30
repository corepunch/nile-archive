#!/usr/bin/env python3
"""Capture the real Clayfight software renderer without a display server."""
from pathlib import Path
import subprocess
from PIL import Image
GAME=Path(__file__).resolve().parents[1]
ROOT=GAME.parents[1]
TEMP=ROOT/'build/clayfight-shots'
OUT=GAME/'docs/screenshots'
TEMP.mkdir(parents=True,exist_ok=True)
OUT.mkdir(parents=True,exist_ok=True)
scenes={
 'fight':['-fight','boxer','lizard','-cpu'],
 'select':['-warp','select'],
 'campaign':['-warp','map','-hero','boxer'],
 'menu':['-warp','menu'],
}
for name,args in scenes.items():
 prefix=TEMP/(name+'-')
 subprocess.run([str(ROOT/'build/clayfight'),'-data',str(GAME/'data/primalrage'),'-creatures',str(GAME/'data/creatures'),'-nosound','-shots',str(prefix),'-tics','121','-every','120',*args],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
 Image.open(TEMP/(name+'-00120.bmp')).save(OUT/(name+'.png'))
 print(OUT/(name+'.png'))
