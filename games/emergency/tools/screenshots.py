#!/usr/bin/env python3
"""Render the campaign and actual simulation stages using the shared launcher."""
import os
from pathlib import Path
import subprocess
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'games/emergency/docs/screenshots'
STAGES=[('menu',[]),('outskirts',['--level','1']),('suburbs',['--level','2']),('square',['--level','3']),('district',['--level','4']),('centre',['--level','5']),('repaired',['--level','3','--preview','repaired']),('complete',['--level','5','--preview','complete']),('pause',['--level','1','--pause']),('briefing',['--level','1','--dialog','--frames','150'])]
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    env=dict(os.environ,SDL_VIDEODRIVER='dummy',SDL_AUDIODRIVER='dummy')
    for name,args in STAGES:
        tmp=ROOT/'build'/('emergency-'+name+'.png')
        subprocess.run([str(ROOT/'build/emergency'),'--fresh','--mute','--size','1368x1026','--shot',str(tmp),*args],cwd=ROOT,env=env,check=True)
        Image.open(tmp).convert('RGB').save(OUT/(name+'.jpg'),quality=86)
if __name__=='__main__': main()
