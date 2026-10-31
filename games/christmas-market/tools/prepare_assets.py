#!/usr/bin/env python3
"""Spatial crops/resizes only: preserve ImageGen's authored RGB and alpha."""
import json
from pathlib import Path
from PIL import Image
from prepare_character import main as prepare_character

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data'
REGISTRATION = ROOT / 'art' / 'registration.json'

def save(im, path):
    path = DATA / path
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)

def main():
    registration = {'icons': []}
    # Buildings are Blender renders now: tools/render_buildings.py and prepare_catalogue.py.
    names = [f'tile-sets/festive/{i}' for i in range(6)] + [
        'board-states/'+s for s in ['ray-row','ray-column','ray-diagonal','bomb','prism',
        'sand','chain','ice-2','ice-1','selected','hint','guide','cell-mask']]
    names += ['board-states/'+tool+'-'+state for tool in ['pickaxe','dynamite','sunburst']
              for state in ['normal','selected','pressed','hover','disabled']]
    names += ['expedition-hud/pause-'+state for state in ['normal','selected','pressed','hover','disabled']]
    names += ['expedition-hud/complete']
    assert len(names) == 40
    sheet = Image.open(ROOT / 'art/icons.png').convert('RGBA')
    for i, name in enumerate(names):
        x,y = i%8,i//8
        rows = [0,232,422,607,786,992]
        bounds = [round(x*sheet.width/8),rows[y],round((x+1)*sheet.width/8),rows[y+1]]
        im = sheet.crop(bounds)
        # The authored rows are not equal height. Keep the whole source cell,
        # with the same registration for every control in its state family.
        save(im.resize((128,128),Image.Resampling.LANCZOS),name+'.png')
        registration['icons'].append({'path':name+'.png','crop':bounds,'output':[128,128]})
    terrain = Image.open(ROOT / 'art/terrain.png').convert('RGB')
    save(terrain.resize((1920,2880),Image.Resampling.LANCZOS),'island.jpg')
    save(terrain.resize((600,900),Image.Resampling.LANCZOS),'winter.jpg')
    prepare_character()
    REGISTRATION.write_text(json.dumps(registration,indent=2)+'\n')

if __name__ == '__main__': main()
