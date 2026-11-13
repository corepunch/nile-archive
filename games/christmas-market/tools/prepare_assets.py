#!/usr/bin/env python3
"""Register ImageGen artwork using spatial crops, resizes and board masks."""
import argparse
import json
import sys
from math import sqrt
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
from prepare_character import main as prepare_character
from prepare_story_cast import prepare as prepare_story_cast

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from fit_match3_edges import thin_ring

DATA = ROOT / 'data'
REGISTRATION = ROOT / 'art' / 'registration.json'

def save(im, path):
    path = DATA / path
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)

ALPHA = 40   # the sheet's 40 icons are separate regions above this alpha; fainter glow joins its nearest icon

def artwork_blobs(sheet):
    """Label 8-connected regions of visible artwork; return labels and each region's bounds."""
    w, h = sheet.size
    alpha = sheet.getchannel('A').tobytes()
    labels = [-1] * (w * h)
    blobs = []
    for start in range(w * h):
        if alpha[start] <= ALPHA or labels[start] >= 0: continue
        k = len(blobs)
        labels[start] = k
        stack, box = [start], [w, h, 0, 0]
        while stack:
            i = stack.pop()
            x, y = i % w, i // w
            box = [min(box[0], x), min(box[1], y), max(box[2], x + 1), max(box[3], y + 1)]
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if labels[j] < 0 and alpha[j] > ALPHA:
                            labels[j] = k
                            stack.append(j)
        blobs.append(box)
    return labels, blobs

def centre(b): return ((b[0] + b[2]) / 2, (b[1] + b[3]) / 2)
def inside(p, b): return b[0] <= p[0] < b[2] and b[1] <= p[1] < b[3]

def isolate(sheet, labels, keep, bounds, near):
    """Crop bounds, keeping only this icon's region and the faint glow just around it."""
    w, h = sheet.size
    out = Image.new('RGBA', (bounds[2] - bounds[0], bounds[3] - bounds[1]), (0, 0, 0, 0))
    src, dst = sheet.load(), out.load()
    for y in range(max(0, bounds[1]), min(h, bounds[3])):
        for x in range(max(0, bounds[0]), min(w, bounds[2])):
            k = labels[y * w + x]
            if k in keep or (k < 0 and inside((x, y), near)):
                dst[x - bounds[0], y - bounds[1]] = src[x, y]
    return out

SIZE = 128
APOTHEM = sqrt(3) / 2
# Source boxes span the six tips of the painted frames in their 128px crops.
GOLD_FRAMES = {
    'ray-row': (5, 32, 118, 113),
    'ray-column': (7, 31, 117, 113),
    'ray-diagonal': (12, 10, 121, 111),
    'bomb': (11, 10, 123, 110),
    'prism': (11, 10, 121, 110),
    'selected': (9, 12, 116, 109),
    'hint': (13, 11, 119, 107),
}

def hex_alpha():
    side = SIZE * 8
    lo, hi = (1 - APOTHEM) * side / 2, (1 + APOTHEM) * side / 2
    mask = Image.new('L', (side, side))
    ImageDraw.Draw(mask).polygon([
        (side, side / 2), (side * .75, hi), (side * .25, hi),
        (0, side / 2), (side * .25, lo), (side * .75, lo),
    ], fill=255)
    return mask.resize((SIZE, SIZE), Image.Resampling.LANCZOS)

def fit_board_art(sheet, registration):
    def original(name):
        path = f'board-states/{name}.png'
        crop = next(entry['crop'] for entry in registration['icons'] if entry['path'] == path)
        return sheet.crop(crop).resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    mask = hex_alpha()
    for name, (left, top, right, bottom) in GOLD_FRAMES.items():
        mid = (top + bottom) / 2
        half = (bottom - top) / (2 * APOTHEM)
        im = original(name).transform((SIZE, SIZE), Image.Transform.EXTENT,
                                      (left, mid - half, right, mid + half), Image.Resampling.BICUBIC)
        im.putalpha(ImageChops.multiply(im.getchannel('A'), mask))
        save(im, f'board-states/{name}.png')
    save(thin_ring(original('chain'), (63.5, 59.5), (46, 43)), 'board-states/chain-board.png')
    registration['board_fit'] = {
        'mask': '128px regular flat-top hex, radius 64px',
        'gold_frame_source_boxes': GOLD_FRAMES,
        'chain-board': {'wire_center': [63.5, 59.5], 'wire_size': [92, 86],
                        'radius': 46, 'radial_thickness_scale': .5},
    }

# The sheet's excavation tile served the engine's former snow layer; its cell
# keeps its place in the reading order but is no longer registered.
UNREGISTERED = {'board-states/sand'}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--board-fit', action='store_true', help='only register the gold frames and board tinsel')
    args = parser.parse_args()
    sheet = Image.open(ROOT / 'art/icons.png').convert('RGBA')
    if args.board_fit:
        registration = json.loads(REGISTRATION.read_text())
        fit_board_art(sheet, registration)
        REGISTRATION.write_text(json.dumps(registration, indent=2)+'\n')
        return
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
    labels, blobs = artwork_blobs(sheet)
    rows = [0,232,422,607,786,992]
    cells = []
    for i in range(len(names)):
        x,y = i%8,i//8
        cells.append([round(x*sheet.width/8),rows[y],round((x+1)*sheet.width/8),rows[y+1]])
    # Pieces and square controls are cropped square around their own artwork,
    # then scaled evenly, so they keep their authored proportions. Every
    # member of a family (six pieces; each tool's five states; Pause) shares
    # one square side. Hex board states keep the whole source cell: they are
    # registered to the board slot.
    family_of = {}
    for name in names:
        if name.startswith('tile-sets/'): family_of[name] = 'pieces'
        elif name.startswith('board-states/') and name.split('/')[1].split('-')[0] in ('pickaxe','dynamite','sunburst'):
            family_of[name] = name.split('/')[1].split('-')[0]
        elif name.startswith('expedition-hud/'): family_of[name] = name.split('/')[1].split('-')[0]
    # Reading order: rows of icons, left to right, matches the names above.
    assert len(blobs) == len(names), f'expected {len(names)} icons on the sheet, found {len(blobs)}'
    order = sorted(range(len(blobs)), key=lambda k: (blobs[k][1] // 150, blobs[k][0]))
    art = {name: blobs[order[i]] for i, name in enumerate(names) if name in family_of}
    own = {name: order[i] for i, name in enumerate(names)}
    side = {}
    for name, box in art.items():
        f = family_of[name]
        side[f] = max(side.get(f, 0), box[2]-box[0], box[3]-box[1])
    for i, name in enumerate(names):
        if name in UNREGISTERED: continue
        bounds = cells[i]
        if name in art:
            cx, cy = centre(art[name])
            half = side[family_of[name]] / 2 + 4   # a hairline of transparent margin
            bounds = [round(cx-half), round(cy-half), round(cx+half), round(cy+half)]
        if name in art:
            b = art[name]
            im = isolate(sheet, labels, {own[name]}, bounds, [b[0]-10, b[1]-10, b[2]+10, b[3]+10])
        else:
            im = sheet.crop(bounds)
        save(im.resize((128,128),Image.Resampling.LANCZOS),name+'.png')
        registration['icons'].append({'path':name+'.png','crop':bounds,'output':[128,128]})
    fit_board_art(sheet, registration)
    terrain = Image.open(ROOT / 'art/terrain.png').convert('RGB')
    save(terrain.resize((1920,2880),Image.Resampling.LANCZOS),'island.jpg')
    backdrop = Image.open(ROOT / 'art/winter-market.png').convert('RGB')
    save(backdrop.resize((600,900),Image.Resampling.LANCZOS),'winter.jpg')
    prepare_character()
    prepare_story_cast()
    REGISTRATION.write_text(json.dumps(registration,indent=2)+'\n')

if __name__ == '__main__': main()
