#!/usr/bin/env python3
"""Render a game's road tiles for the city camera with Scener.

    python3 tools/roads.py christmas-market            # writes games/<game>/data/roads.png
    python3 tools/roads.py christmas-market --keep DIR  # keep the scene and the single renders

The engine lays roads on whole tiles (engine/city.c): every building gets a flag tile
against its front, and the flags are joined by the shortest tile routes. A road
tile is drawn by which of its four neighbours it joins, so the atlas holds one piece
per combination: 4 x 4 cells, cell = mask, bit 0 +u (down-right), bit 1 +v (down-left),
bit 2 -u, bit 3 -v. Cell 0 stays empty. A cell is CELL_TILES tile sides wide and its
centre is the tile's centre; the engine relies on both.

The pavement is modelled, not painted: setts on a 1/10-tile lattice (so pieces meet
without a seam), kerb stones along every open side and, when the game's
art/roads.json asks for it, a soft shoulder outside the kerb. Colours are display
values, as in a Scener scene.
"""
import argparse
import json
import math
import random
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import city_camera  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
TILE = 160.          # cm per tile, as the building scenes
CELL_TILES = 1.6     # a cell's width in tile sides (engine/city.c: ROAD_CELL_TILES)
CELL_ASPECT = .7     # a cell's height over its width
N = 10               # lattice cells per tile side
ROAD = 3             # the road is ROAD lattice cells either side of the centre line
SPACING = 8          # tiles between pieces in the scene
DIRS = ((1, 0), (0, 1), (-1, 0), (0, -1))   # bit order: +u, +v, -u, -v

DEFAULTS = {
    'ppt': 100,                      # sprite pixels per tile side
    'setts': [[.66, .62, .58], [.60, .58, .57], [.70, .65, .59], [.58, .56, .58], [.67, .60, .55]],
    'jitter': .035,
    'kerb': [.76, .75, .74],
    'grout': [.36, .34, .35],
    'shoulder': None,                # e.g. snow: [.93, .96, 1.]
    'ambient': [.34, .38, .50],
    'sun': [-.779, .45, -1.5],       # Blender axes, as art/buildings.json's shadow sun
}


def f(v):
    s = '%.2f' % v
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def paved(i, j, mask):
    """Is lattice cell (i, j) of a tile (each -N/2 .. N/2-1) road, for this piece?"""
    a, b = -ROAD <= i < ROAD, -ROAD <= j < ROAD
    if a and b: return True
    if b and ((i >= ROAD and mask & 1) or (i < -ROAD and mask & 4)): return True
    if a and ((j >= ROAD and mask & 2) or (j < -ROAD and mask & 8)): return True
    return False


def box(u, v, w, d, h, colour, radius, bevel, z=0.):
    """A rounded stone, centre (u, v) in cm along the tile axes, standing on z."""
    return ('<soft-box width="%s" height="%s" depth="%s" radius="%s" bevel="%s" segments="2" pos="%s %s %s" '
            'color="%s" shininess="4" specular="0.25"/>') % (
        f(w), f(h), f(d), f(radius), f(bevel), f(u), f(z + h / 2), f(v), ' '.join(f(c) for c in colour))


def piece(mask, cfg, rng):
    half, p = N // 2, TILE / N
    cells = {(i, j) for i in range(-half, half) for j in range(-half, half) if paved(i, j, mask)}
    out = []
    # the bed the setts sit in shows through the joints
    for (i0, i1, j0, j1) in ([(-ROAD, ROAD, -ROAD, ROAD)] +
                             [(ROAD, half, -ROAD, ROAD)] * bool(mask & 1) + [(-ROAD, ROAD, ROAD, half)] * bool(mask & 2) +
                             [(-half, -ROAD, -ROAD, ROAD)] * bool(mask & 4) + [(-ROAD, ROAD, -half, -ROAD)] * bool(mask & 8)):
        out.append(box((i0 + i1) * p / 2, (j0 + j1) * p / 2, (i1 - i0) * p, (j1 - j0) * p, 1.6, cfg['grout'], .5, .3))
    # setts: single cells, and pairs so the joints don't line up into a grid
    used = set()
    for (i, j) in sorted(cells):
        if (i, j) in used: continue
        di, dj = rng.choice(DIRS[:2])
        pair = rng.random() < .45 and (i + di, j + dj) in cells and (i + di, j + dj) not in used
        used.add((i, j))
        if pair: used.add((i + di, j + dj))
        w, d = (p * (2 if pair and di else 1), p * (2 if pair and dj else 1))
        base = rng.choice(cfg['setts'])
        tone = rng.uniform(-cfg['jitter'], cfg['jitter'])
        colour = [min(1., max(0., c + tone)) for c in base]
        gap = rng.uniform(1.6, 2.6)
        out.append(box((i + .5) * p + (w - p) / 2, (j + .5) * p + (d - p) / 2, w - gap, d - gap,
                       rng.uniform(3., 4.2), colour, 3.2, 1.3))
    # kerbs and shoulders along every side that is not a join to the next tile
    kt, kh, st = 5.5, 5.2, 11.
    for (i, j) in sorted(cells):
        for di, dj in DIRS:
            ni, nj = i + di, j + dj
            if (ni, nj) in cells or not (-half <= ni < half and -half <= nj < half): continue
            cu, cv = (i + .5 + di * .5) * p, (j + .5 + dj * .5) * p     # the middle of that side
            tone = rng.uniform(-.025, .025)
            colour = [min(1., c + tone) for c in cfg['kerb']]
            w, d = (kt, p - .8) if di else (p - .8, kt)
            out.append(box(cu + di * kt / 2, cv + dj * kt / 2, w, d, kh, colour, 1.6, 1.2))
            if cfg['shoulder']:
                w, d = (st, p + 2) if di else (p + 2, st)
                out.append(box(cu + di * (kt + st / 2 - 2), cv + dj * (kt + st / 2 - 2), w, d, 3.4, cfg['shoulder'], 4.5, 3.))
    # outside corners of the kerb line
    for i in range(-half, half + 1):
        for j in range(-half, half + 1):
            around = [(i - 1, j - 1) in cells, (i, j - 1) in cells, (i - 1, j) in cells, (i, j) in cells]
            if sum(around) != 1: continue
            su, sv = (1 if around[0] or around[2] else -1), (1 if around[0] or around[1] else -1)
            if abs(i) == half or abs(j) == half: continue   # at the tile's edge the road runs on
            out.append(box(i * p + su * kt / 2, j * p + sv * kt / 2, kt, kt, kh, cfg['kerb'], 1.6, 1.2))
            if cfg['shoulder']:
                out.append(box(i * p + su * (kt + st / 2 - 2), j * p + sv * (kt + st / 2 - 2), st, st, 3.4, cfg['shoulder'], 4.5, 3.))
    return out


def scene(cfg):
    yaw, elev = math.radians(city_camera.YAW), math.radians(city_camera.ELEVATION)
    a = math.pi / 2 - elev
    # Blender axes (x = u, y = -v, z up), as tools/scener_buildings.py frames buildings
    right = (math.cos(yaw), math.sin(yaw), 0.)
    up = (-math.sin(yaw) * math.cos(a), math.cos(yaw) * math.cos(a), math.sin(a))
    back = (math.sin(yaw) * math.sin(a), -math.cos(yaw) * math.sin(a), math.cos(a))
    to_scener = lambda q: (q[0] * TILE, q[2] * TILE, -q[1] * TILE)
    dot = lambda q, r: sum(x * y for x, y in zip(q, r))
    width = round(cfg['ppt'] * CELL_TILES)
    height = round(width * CELL_ASPECT)
    sun = to_scener(cfg['sun'])
    length = math.sqrt(dot(sun, sun))
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<!-- Road tiles for the city camera, written by nile-archive tools/roads.py. Generated: edit that. -->',
             '<scene ambient="%s" background="0 0 0">' % ' '.join(f(c) for c in cfg['ambient']),
             '  <include src="utilities.xml"/>',
             '  <sun dir="%s" color="1 0.97 0.92" intensity="0.95" castShadows="1"/>' % ' '.join('%.4f' % (c / length) for c in sun)]
    for mask in range(1, 16):
        origin = (mask * SPACING, 0., 0.)
        cx, cy = dot(origin, right), dot(origin, up)
        target = tuple(right[k] * cx + up[k] * cy for k in range(3))
        eye = tuple(target[k] + back[k] * 120. for k in range(3))
        lines.append('  <camera name="road%d" pos="%s" look="%s" ortho="%s" size="%d %d"/>' % (
            mask, ' '.join(f(c) for c in to_scener(eye)), ' '.join(f(c) for c in to_scener(target)),
            '%.4f' % (height / cfg['ppt'] * TILE), width, height))
        lines.append('  <group pos="%s 0 0" name="road%d">' % (f(origin[0] * TILE), mask))
        lines += ['    ' + l for l in piece(mask, cfg, random.Random(1000 + mask))]
        lines.append('  </group>')
    return '\n'.join(lines + ['</scene>', '']), width, height


def find_scener():
    import os
    for candidate in (os.environ.get('SCENER'), shutil.which('scener'), str(ROOT.parent / 'orion-ui/build/bin/scener')):
        if candidate and Path(candidate).exists(): return Path(candidate).resolve()
    sys.exit('Scener not found: set SCENER, or build ../orion-ui with `make scener`')


def utilities(scener):
    """utilities.xml (soft-box): beside an installed Scener, or in an orion-ui checkout."""
    import os
    roots = []
    if scener.stat().st_size < 4096:   # an installed launcher script: follow its exec line
        roots = [Path(l.split()[1]).parents[1] for l in scener.read_text(errors='ignore').splitlines()
                 if l.startswith('exec ') and len(l.split()) > 1]
    roots += [scener.parents[1], scener.parents[2], Path(os.environ.get('ORION_UI') or ROOT.parent / 'orion-ui')]
    for r in roots:
        for sub in ('share/scener/scenes/utilities.xml', 'apps/scener/scenes/utilities.xml'):
            if (r / sub).exists(): return r / sub
    sys.exit('Scener\'s utilities.xml not found: set ORION_UI to an orion-ui checkout')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('game')
    ap.add_argument('--keep', help='keep the scene and single renders in this directory')
    args = ap.parse_args()
    from PIL import Image

    game = ROOT / 'games' / args.game
    cfg = dict(DEFAULTS)
    if (game / 'art/roads.json').exists(): cfg.update(json.loads((game / 'art/roads.json').read_text()))
    scener = find_scener()
    work = Path(args.keep or tempfile.mkdtemp(prefix='roads-'))
    work.mkdir(parents=True, exist_ok=True)
    text, width, height = scene(cfg)
    (work / 'roads.blks').write_text(text)
    shutil.copy(utilities(scener), work / 'utilities.xml')
    atlas = Image.new('RGBA', (width * 4, height * 4), (0, 0, 0, 0))
    for mask in range(1, 16):
        subprocess.run([str(scener), '--render', str(work / 'roads.blks'), '--camera', f'road{mask}', '--format', 'png',
                        '--transparent', '--supersample', '4', '--output-dir', str(work)], check=True,
                       stdout=subprocess.DEVNULL)
        shot = max(work.glob('*.png'), key=lambda q: q.stat().st_mtime)
        image = Image.open(shot).convert('RGBA')
        if image.size != (width, height): sys.exit(f'{shot}: {image.size}, expected {(width, height)}')
        atlas.paste(image, (mask % 4 * width, mask // 4 * height))
        shot.rename(work / f'road{mask:02d}.png')
    out = game / 'data/roads.png'
    atlas.save(out, optimize=True)
    print(f'{out.relative_to(ROOT)}: 15 pieces, {width}x{height} each')
    if not args.keep: shutil.rmtree(work)


if __name__ == '__main__':
    main()
