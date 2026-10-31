#!/usr/bin/env python3
"""Capture the actual game; Linux callers should run under xvfb-run -a."""
import os
from pathlib import Path
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT/'games/christmas-market'
SHOTS = [
    ('market', '480x900', ['--showcase']),
    ('phone-market', '390x844', ['--showcase']),
    ('main-character-board', '480x900', ['--level','4']),
    ('phone-board', '390x844', ['--level','4']),
    ('dialogue', '480x900', ['--dialog','intro','--frames','180']),
    ('main-character-dialogue', '390x844', ['--dialog','intro','--frames','180']),
    ('placement', '480x900', ['--city','2','--placing']),
    ('blocked-placement', '480x900', ['--city','2','--placing','blocked']),
    ('region', '480x900', ['--city','3','--zone','1']),
    ('shop', '480x900', ['--catalogue','building']),
    ('winter-wishes', '480x900', ['--expeditions']),
    ('reward', '480x900', ['--victory']),
    ('pause', '480x900', ['--level','4','--dialog','pause']),
    ('guide', '480x900', ['--level','4','--dialog','guide']),
    ('failed', '480x900', ['--level','4','--dialog','failed']),
    ('finale', '480x900', ['--dialog','finale']),
    ('footprints', '480x900', ['--showcase','--footprints']),
    ('art-states', '480x900', ['--art-states']),
    ('hud-states', '480x900', ['--hud-states']),
    ('specials-board', '480x900', ['--art-board']),
    ('building-card', '480x900', ['--card','2']),
] + [(f'building-review-{page}', '480x900', ['--building-review',str(page),'--footprints']) for page in range(1,4)]

def main():
    output = GAME/'docs/screenshots'
    output.mkdir(parents=True, exist_ok=True)
    tmp = ROOT/'build/shots/christmas-market.png'
    tmp.parent.mkdir(parents=True, exist_ok=True)
    for name,size,args in SHOTS:
        if sys.argv[1:] and name not in sys.argv[1:]:
            continue
        safe = ['--safe-area','0,47,0,34'] if size=='390x844' else []
        subprocess.run([str(ROOT/'build/christmas-market'),'--headless','--mute','--fresh','--size',size,
                        '--shot',str(tmp),*safe,*args],cwd=ROOT,env={**os.environ,'LIBGL_ALWAYS_SOFTWARE':'1'},check=True)
        im = Image.open(tmp).convert('RGB')
        im.resize(tuple(map(int,size.split('x'))),Image.Resampling.LANCZOS).save(output/f'{name}.jpg',quality=90)
        print(output/f'{name}.jpg',flush=True)
    tmp.unlink()

if __name__ == '__main__': main()
