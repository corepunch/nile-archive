#!/usr/bin/env python3
"""Spatial crops/resizes only: preserve ImageGen's authored RGB and alpha."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
from prepare_character import main as prepare_character

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data'
REGISTRATION = ROOT / 'art' / 'registration.json'

def save(im, path):
    path = DATA / path
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)

def main():
    previous = json.loads(REGISTRATION.read_text()) if REGISTRATION.exists() else {}
    registration = {'buildings': [], 'icons': []}
    sheet = Image.open(ROOT / 'art/buildings.png').convert('RGBA')
    # Each crop retains its original alpha. Bounds follow the atlas gutters.
    for i in range(12):
        col, row = i % 4, i // 4
        bounds = [col*362, row*362, (col+1)*362, (row+1)*362]
        # The tree star extends above the nominal third-row boundary.
        if i == 5: bounds[3] = 712
        if i == 8: bounds[2] = 398
        if i == 9: bounds[1] = 714
        # Spatial cutouts separate neighboring art which crosses a cell gutter.
        # No alpha or colour inside an asset is reconstructed or recoloured.
        polygon = None
        if i == 8: polygon = [(0,724),(350,724),(398,955),(345,990),(210,1060),(0,1060)]
        if i == 9: polygon = [(400,1086),(380,970),(420,920),(470,830),(525,760),(530,714),(580,714),(620,830),(700,930),(724,970),(724,1086)]
        source = sheet
        if polygon:
            mask = Image.new('L',sheet.size)
            ImageDraw.Draw(mask).polygon(polygon,fill=255)
            source = Image.new('RGBA',sheet.size)
            source.paste(sheet,(0,0),mask)
        im = source.crop(bounds)
        box = im.getbbox()
        im = im.crop(box)
        save(im, f'buildings/{i}.png')
        entry = previous.get('buildings',[{}]*12)[i].copy()
        entry.update({'id':i, 'crop':bounds, 'trim':box, 'size':im.size, 'polygon':polygon})
        registration['buildings'].append(entry)
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
