#!/usr/bin/env python3
"""Render a game's road tiles for the city camera with Scener.

    python3 tools/roads.py christmas-market            # writes games/<game>/data/roads.png
    python3 tools/roads.py christmas-market --style sandstone   # a second look: data/roads-sandstone.png
    python3 tools/roads.py christmas-market --keep DIR  # keep the scene and the single renders

The engine lays roads on whole tiles (engine/city.c): every building gets a flag tile
against its front, and the flags are joined by the shortest tile routes. A road
tile is drawn by which of its four neighbours it joins, so the atlas holds one piece
per combination: 8 x 4 cells, the left half with cell = mask, bit 0 +u (down-right),
bit 1 +v (down-left), bit 2 -u, bit 3 -v. Cell 0 stays empty. The right half holds
eight more looks of each straight road, which the engine picks from by tile so a long
street does not repeat: rows 0-1 along u, rows 2-3 along v. A cell is CELL_TILES tile
sides wide and its centre is the tile's centre; the engine relies on both.

The game's art/roads.json sets the period as well as the palette: sawn setts with kerbs
suit a town, while `rough`, a wide `gap`, `missing` and no `kerb` or `grout` give worn old
flagstones with the ground showing between them.

The pavement is modelled, not painted: setts a fifth of a tile wide (so pieces meet
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
N = 5                # stones per tile side
ROAD = 3             # the road's width in stones
SPACING = 8          # tiles between pieces in the scene
DIRS = ((1, 0), (0, 1), (-1, 0), (0, -1))   # bit order: +u, +v, -u, -v
COLUMNS, VARIANTS = 8, 8   # the atlas is 8 x 4 cells; a straight road has VARIANTS looks
STRAIGHT = (5, 10)         # along u, along v (engine/city.c: road_cell)
# (camera name, mask, seed, (column, row)): the fifteen pieces in the left half, cell = mask,
# then each straight's variants in the right half, two rows of four per direction
PIECES = [('road%d' % m, m, 1000 + m, (m % 4, m // 4)) for m in range(1, 16)] + [
    ('road%d-%d' % (m, k), m, 2000 + 100 * m + k, (4 + k % 4, 2 * n + k // 4))
    for n, m in enumerate(STRAIGHT) for k in range(VARIANTS)]

DEFAULTS = {
    'ppt': 100,                      # sprite pixels per tile side
    'setts': [[.66, .62, .58], [.60, .58, .57], [.70, .65, .59], [.58, .56, .58], [.67, .60, .55]],
    'jitter': .035,
    'kerb': [.76, .75, .74],
    'grout': [.36, .34, .35],
    'shoulder': None,                # e.g. snow: [.93, .96, 1.]
    'gap': [1.8, 2.8],               # joint width in cm, from .. to
    'rough': 0.,                     # cm a stone's corners wander: 0 is sawn paving, 2 is worn old flagstones
    'missing': 0.,                   # chance that a stone is gone and the ground shows
    'heights': [3., 4.2],            # stone heights in cm, from .. to
    'ambient': [.34, .38, .50],
    'sun': [-.779, .45, -1.5],       # Blender axes, as art/buildings.json's shadow sun
}


def f(v):
    s = '%.2f' % v
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def poly(points, h, colour, fillet=0., bevel=1.3, z=0.):
    """A stone: an outline in cm along the tile axes (u, v), extruded h upwards from z."""
    # the shape is drawn in its own xy and turned to lie flat: x = u, y = -v
    return ('<shape closed="1" v="%s" pos="0 %s 0" rot="-90 0 0" color="%s" shininess="4" specular="0.25">%s'
            '<extrude amount="%s"/><bevel amount="%s" bevelSegments="2"/></shape>') % (
        ' '.join('%s %s' % (f(u), f(-v)) for u, v in points), f(z), ' '.join(f(c) for c in colour),
        '<fillet radius="%s" segments="3"/>' % f(fillet) if fillet else '', f(h), f(bevel))


def rect(u0, v0, u1, v1): return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def arc(c, r, a0, a1, steps=None):
    """Points on a circle about c from angle a0 to a1 (radians)."""
    steps = steps or max(2, int(abs(a1 - a0) * r / 7) + 1)
    return [(c[0] + r * math.cos(a0 + (a1 - a0) * k / steps), c[1] + r * math.sin(a0 + (a1 - a0) * k / steps))
            for k in range(steps + 1)]


def band(c, r0, r1, a0, a1, gap=0.):
    """A stone of a ring about c: between two radii and two angles, less a joint."""
    g0, g1 = gap / 2 / max(r0, 1.), gap / 2 / r1
    sign = 1 if a1 > a0 else -1
    return arc(c, r1 - gap / 2, a0 + sign * g1, a1 - sign * g1) + arc(c, r0 + gap / 2, a1 - sign * g0, a0 + sign * g0)


def tinted(colour, rng, spread):
    tone = rng.uniform(-spread, spread)
    return [min(1., max(0., c + tone)) for c in colour]


KERB, KERB_H, BANK, BANK_H = 6., 5.4, 12., 3.4    # kerb and shoulder: width and height in cm


def ring(out, c, r, a0, a1, outward, cfg, rng):
    """Kerb stones, and the shoulder behind them, along an arc of radius r about c.
    outward is +1 when the ground lies outside the circle, -1 when inside it."""
    lo, hi = (r, r + KERB) if outward > 0 else (r - KERB, r)
    count = max(1, round(abs(a1 - a0) * r / (TILE / N))) if cfg['kerb'] else 0
    for k in range(count):
        b0, b1 = a0 + (a1 - a0) * k / count, a0 + (a1 - a0) * (k + 1) / count
        out.append(poly(band(c, lo, hi, b0, b1, .8), KERB_H, tinted(cfg['kerb'], rng, .025), bevel=1.2))
    if cfg['shoulder']:
        lo, hi = (r + KERB - 2, r + KERB + BANK - 2) if outward > 0 else (max(1., r - KERB - BANK + 2), r - KERB + 2)
        out.append(poly(band(c, lo, hi, a0, a1), BANK_H, cfg['shoulder'], bevel=2.6))


def piece(mask, cfg, rng):
    """One road tile. The road is three stones wide and a tile is five stones long; a turn is
    a quarter ring about the tile's corner, and the inside corners of a junction are rounded
    with the same radius, so every piece meets its neighbour square at the tile's edge."""
    p, half, h = TILE / N, TILE / 2, TILE / N * ROAD / 2
    arms = [d for d in range(4) if mask >> d & 1]
    out = []

    def sett(points, fillet=3.2):
        colour = tinted(rng.choice(cfg['setts']), rng, cfg['jitter'])
        height = rng.uniform(*cfg['heights'])
        rough = cfg['rough']
        if rough:
            if rng.random() < cfg['missing']: return
            if len(points) <= 4:   # a slab: every corner wanders, and a long side may break
                points = [(u + rng.uniform(-rough, rough), v + rng.uniform(-rough, rough)) for u, v in points]
            else:                  # a curved stone keeps its arc and shrinks a little about its middle
                cu, cv = sum(q[0] for q in points) / len(points), sum(q[1] for q in points) / len(points)
                k = 1 - rng.uniform(0, rough) / 30
                points = [(cu + (u - cu) * k, cv + (v - cv) * k) for u, v in points]
            fillet = fillet and fillet + rough * 1.5
        out.append(poly(points, height, colour, fillet, 1.3 + rough * .4))

    def edge(u0, v0, u1, v1, nu, nv):
        """A straight kerb stone on the side from (u0, v0) to (u1, v1), ground towards (nu, nv)."""
        lo, hi = (0, KERB)
        a, b = (u0 + nu * lo, v0 + nv * lo), (u1 + nu * hi, v1 + nv * hi)
        along = .4
        pts = rect(min(a[0], b[0]) + along * abs(nv), min(a[1], b[1]) + along * abs(nu),
                   max(a[0], b[0]) - along * abs(nv), max(a[1], b[1]) - along * abs(nu))
        if cfg['kerb']: out.append(poly(pts, KERB_H, tinted(cfg['kerb'], rng, .025), 1.4, 1.2))
        if cfg['shoulder']:
            a, b = (u0 + nu * (KERB - 2), v0 + nv * (KERB - 2)), (u1 + nu * (KERB + BANK - 2), v1 + nv * (KERB + BANK - 2))
            out.append(poly(rect(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])), BANK_H, cfg['shoulder'], 0, 2.6))

    if len(arms) == 2 and (arms[0] ^ arms[1]) & 1:
        # a turn: three courses of a quarter ring about the corner between the two arms
        su = 1 if 0 in arms else -1
        sv = 1 if 1 in arms else -1
        c = (su * half, sv * half)
        a0, a1 = math.atan2(0, -su), math.atan2(-sv, 0)
        if a1 - a0 > math.pi: a1 -= 2 * math.pi
        if a0 - a1 > math.pi: a1 += 2 * math.pi
        r0 = half - h
        if cfg['grout']: out.append(poly(band(c, r0, r0 + 2 * h, a0, a1), 1.6, cfg['grout'], bevel=.3))
        for course, count in enumerate((2, 3, 5)):
            for k in range(count):
                b0, b1 = a0 + (a1 - a0) * k / count, a0 + (a1 - a0) * (k + 1) / count
                sett(band(c, r0 + course * p, r0 + (course + 1) * p, b0, b1, rng.uniform(*cfg['gap'])), 0)
        ring(out, c, r0, a0, a1, -1, cfg, rng)
        ring(out, c, r0 + 2 * h, a0, a1, 1, cfg, rng)
        return out

    lo = -(ROAD // 2)
    cells = {(i, j) for i in range(lo, -lo + 1) for j in range(lo, -lo + 1)}
    for d in arms:
        cells |= {((-lo + 1) * DIRS[d][0] + k * abs(DIRS[d][1]), (-lo + 1) * DIRS[d][1] + k * abs(DIRS[d][0])) for k in range(lo, -lo + 1)}
    # where two arms meet, the inside corner is rounded: its cell is paved outside a quarter circle
    fillets = [(su, sv) for su in (1, -1) for sv in (1, -1) if (0 if su > 0 else 2) in arms and (1 if sv > 0 else 3) in arms]
    # a dead end is rounded off: its two far corners are quarter discs
    rounds = []
    if len(arms) == 1:
        du, dv = DIRS[arms[0]]
        rounds = [(-du * -lo + k * abs(dv) * -lo, -dv * -lo + k * abs(du) * -lo) for k in (-1, 1)]
    special = {(su * (-lo + 1), sv * (-lo + 1)) for su, sv in fillets} | set(rounds)
    # the bed the setts sit in shows through the joints
    for (i, j) in sorted(cells - set(rounds)) if cfg['grout'] else ():
        out.append(poly(rect((i - .5) * p, (j - .5) * p, (i + .5) * p, (j + .5) * p), 1.6, cfg['grout'], 0, .3))
    # setts: single cells, and pairs so the joints don't line up into a grid
    used = set(rounds)
    for (i, j) in sorted(cells):
        if (i, j) in used: continue
        di, dj = rng.choice(DIRS[:2])
        pair = rng.random() < .45 and (i + di, j + dj) in cells and (i + di, j + dj) not in used
        used.add((i, j))
        if pair: used.add((i + di, j + dj))
        gap = rng.uniform(*cfg['gap']) / 2
        sett(rect((i - .5) * p + gap, (j - .5) * p + gap, (i + .5 + (di if pair else 0)) * p - gap, (j + .5 + (dj if pair else 0)) * p - gap))
    for su, sv in fillets:
        c = (su * half, sv * half)
        a0, a1 = math.atan2(0, -su), math.atan2(-sv, 0)
        if a1 - a0 > math.pi: a1 -= 2 * math.pi
        if a0 - a1 > math.pi: a1 += 2 * math.pi
        r, corner = half - h, (su * h, sv * h)
        if cfg['grout']: out.append(poly([corner] + arc(c, r, a0, a1), 1.6, cfg['grout'], 0, .3))
        middle = (a0 + a1) / 2
        for b0, b1 in ((a0, middle), (middle, a1)):   # two wedge stones about the diagonal
            pts = [corner] + arc(c, r, b0, b1)
            cu, cv = sum(q[0] for q in pts) / len(pts), sum(q[1] for q in pts) / len(pts)
            sett([(cu + (q[0] - cu) * .88, cv + (q[1] - cv) * .88) for q in pts], 0)
        ring(out, c, r, a0, a1, -1, cfg, rng)
    for (i, j) in rounds:
        # the quarter disc is centred on the cell's corner nearest the tile's centre line
        du, dv = DIRS[arms[0]]
        c = ((i + .5 * du) * p if du else (i - .5 * (1 if i > 0 else -1)) * p,
             (j + .5 * dv) * p if dv else (j - .5 * (1 if j > 0 else -1)) * p)
        far = (c[0] - du * p + (0 if du else (1 if i > 0 else -1) * p), c[1] - dv * p + (0 if dv else (1 if j > 0 else -1) * p))
        a0 = math.atan2(-dv, -du)
        a1 = math.atan2(far[1] - c[1] + dv * p, far[0] - c[0] + du * p)
        if a1 - a0 > math.pi: a1 -= 2 * math.pi
        if a0 - a1 > math.pi: a1 += 2 * math.pi
        if cfg['grout']: out.append(poly([c] + arc(c, p, a0, a1), 1.6, cfg['grout'], 0, .3))
        sett([c] + arc(c, p - 1.2, a0, a1), 0)
        ring(out, c, p, a0, a1, 1, cfg, rng)
    # kerbs and shoulders along every straight side that is not a join to the next tile
    for (i, j) in sorted(cells - set(rounds)):
        for di, dj in DIRS:
            ni, nj = i + di, j + dj
            if (ni, nj) in cells or (ni, nj) in special or max(abs(ni), abs(nj)) > -lo + 1: continue
            cu, cv = (i + .5 * di) * p, (j + .5 * dj) * p     # the middle of that side
            edge(cu - abs(dj) * p / 2, cv - abs(di) * p / 2, cu + abs(dj) * p / 2, cv + abs(di) * p / 2, di, dj)
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
    for index, (name, mask, seed, _) in enumerate(PIECES):
        origin = (index * SPACING, 0., 0.)
        cx, cy = dot(origin, right), dot(origin, up)
        target = tuple(right[k] * cx + up[k] * cy for k in range(3))
        eye = tuple(target[k] + back[k] * 120. for k in range(3))
        lines.append('  <camera name="%s" pos="%s" look="%s" ortho="%s" size="%d %d"/>' % (
            name, ' '.join(f(c) for c in to_scener(eye)), ' '.join(f(c) for c in to_scener(target)),
            '%.4f' % (height / cfg['ppt'] * TILE), width, height))
        lines.append('  <group pos="%s 0 0" name="%s">' % (f(origin[0] * TILE), name))
        lines += ['    ' + l for l in piece(mask, cfg, random.Random(seed))]
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
    ap.add_argument('--style', help='a second look: reads art/roads-STYLE.json and writes data/roads-STYLE.png')
    ap.add_argument('--keep', help='keep the scene and single renders in this directory')
    args = ap.parse_args()
    from PIL import Image

    game = ROOT / 'games' / args.game
    cfg = dict(DEFAULTS)
    stem = 'roads-' + args.style if args.style else 'roads'
    if args.style and not (game / f'art/{stem}.json').exists(): sys.exit(f'no such style: {game.name}/art/{stem}.json')
    if (game / f'art/{stem}.json').exists(): cfg.update(json.loads((game / f'art/{stem}.json').read_text()))
    scener = find_scener()
    work = Path(args.keep or tempfile.mkdtemp(prefix='roads-'))
    work.mkdir(parents=True, exist_ok=True)
    text, width, height = scene(cfg)
    (work / 'roads.blks').write_text(text)
    shutil.copy(utilities(scener), work / 'utilities.xml')
    atlas = Image.new('RGBA', (width * COLUMNS, height * 4), (0, 0, 0, 0))
    for name, mask, seed, (column, row) in PIECES:
        subprocess.run([str(scener), '--render', str(work / 'roads.blks'), '--camera', name, '--format', 'png',
                        '--transparent', '--supersample', '4', '--output-dir', str(work)], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        shot = max(work.glob('*.png'), key=lambda q: q.stat().st_mtime)
        image = Image.open(shot).convert('RGBA')
        if image.size != (width, height): sys.exit(f'{shot}: {image.size}, expected {(width, height)}')
        atlas.paste(image, (column * width, row * height))
        shot.rename(work / f'{name}.png')
    out = game / f'data/{stem}.png'
    atlas.save(out, optimize=True)
    print(f'{out.relative_to(ROOT)}: {len(PIECES)} pieces, {width}x{height} each')
    if not args.keep: shutil.rmtree(work)


if __name__ == '__main__':
    main()
