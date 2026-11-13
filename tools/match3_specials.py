#!/usr/bin/env python3
"""Model the match-3 power-ups in Scener and render one sprite per board axis.

    python3 tools/match3_specials.py                  # both portrait games
    python3 tools/match3_specials.py relic-rush --sheet /tmp/specials.png
    python3 tools/match3_specials.py --check          # the committed scenes are this tool's (no Scener needed)

Rockets, the bomb and the rainbow ball are solids of revolution and tiles on a sphere, so they are
modelled once and rendered rather than painted three times: every rocket axis is the same lathe turned
about the view direction, the bomb's belt is a real band around its sphere, and each rainbow tile is a
patch of the sphere's own latitude and longitude. A game supplies only its palette and tile bevel.

Each game gets `art/board-theme/specials/specials.blks` (the scene, one orthographic camera per sprite)
and the five transparent renders beside it. tools/match3_theme_art.py registers them into the atlas;
run tools/match3_atlas.py afterwards.
"""
import argparse
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ('ray-row', 'ray-column', 'ray-diagonal', 'bomb', 'prism')
SIZE = 512          # px per render; the atlas importer scales it to the board
VIEW = 124.         # cm across each orthographic view
SPACING = 400.      # cm between models, so no light or shadow reaches a neighbour
# Screen angle of each rocket's upper tip from vertical (counter-clockwise), on the flat-top board's axes.
ROCKET_TURN = {'ray-row': 60., 'ray-column': 0., 'ray-diagonal': -60.}
ROCKET_LEAN = 13.   # the upper tip leans this far towards the viewer, so its dome shows
BOMB_POSE = (40., 52.)   # the fuse: turned to the upper left, then leaning towards the viewer
BALL_LEAN = 14.
RAINBOW = {'red': (.94, .09, .11), 'yellow': (1., .80, .03), 'green': (.13, .78, .10), 'cyan': (.06, .70, 1.),
           'blue': (.08, .33, .96), 'pink': (.98, .17, .62), 'orange': (1., .47, .04)}
# Tile rows from the upper pole down: latitude, tile height in degrees, tiles around, longitude of the first
# tile (0 faces the viewer, positive to the right), colours in order. No tile matches a neighbour.
BALL_ROWS = (   # the poles stay bare, as on the Homescapes ball
    (39, 37, 6, 0, ('red', 'yellow', 'green', 'pink', 'green', 'cyan')),
    (0, 35, 6, 0, ('orange', 'green', 'pink', 'blue', 'yellow', 'red')),
    (-39, 37, 6, 0, ('green', 'cyan', 'orange', 'red', 'pink', 'blue')),
)
THEMES = {
    'relic-rush': dict(
        rocket=(.72, .19, .14), rocket_trim=(.95, .70, .24), bomb=(.05, .47, .49), bomb_trim=(.95, .69, .22),
        fuse=(.86, .66, .40), fuse_dark=(.60, .38, .18), core=(.15, .03, .28), gloss=19,
        # a cut-stone plaque: a flat face and a chamfer
        tile=((0, 1.05), (.40, 1.03), (.64, .99), (.72, .93), (.93, .44), (.985, .28), (1.0, -.25))),
    'christmas-market': dict(
        rocket=(.80, .10, .22), rocket_trim=(.99, .88, .64), bomb=(.06, .50, .29), bomb_trim=(.95, .68, .22),
        fuse=(.88, .70, .44), fuse_dark=(.62, .40, .20), core=(.16, .03, .30), gloss=22,
        # a glass sweet: a pillow that rolls over to its edge
        tile=((0, 1.06), (.35, 1.03), (.60, .95), (.78, .80), (.90, .58), (.97, .30), (1.0, -.25))),
}


def f(v):
    s = '%.3f' % v
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def vec(v):
    return ' '.join(f(c) for c in v)


def arc(cx, cy, rx, ry, a0, a1, n=10):
    """Points of an ellipse arc from angle a0 to a1 (degrees)."""
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def lathe(name, profile, attrs, inner=''):
    """A profile and its lathe. Profiles run from the lowest point up; x is the radius."""
    pts = ' '.join(f'{f(max(0., x))} {f(y)}' for x, y in profile)
    open_tag = f'<lathe shape="{name}" segments="72" {attrs}'
    return [f'<shape id="{name}" closed="0" v="{pts}"/>', open_tag + (f'>{inner}</lathe>' if inner else '/>')]


def rocket(key, theme):
    """A capped cylinder along Y: dome, collar, banded waist, collar, dome."""
    body, trim, gloss = vec(theme['rocket']), vec(theme['rocket_trim']), theme['gloss']
    look = f'shininess="{gloss}" specular="1"'
    lines = []
    for sign, side in ((-1, 'low'), (1, 'high')):
        dome = arc(0, 38, 25, 12, 0, 90)                         # rim out at the collar, pole on the axis
        collar = [(24, 15)] + arc(34, 22, 7, 7, -90, 0) + arc(34, 33, 7, 7, 0, 90) + [(24, 40)]
        for part, profile, colour in (('dome', dome, trim), ('collar', collar, body)):
            profile = [(x, y * sign) for x, y in profile]
            if sign < 0:
                profile.reverse()
            lines += lathe(f'{key}-{part}-{side}', profile, f'color="{colour}" {look}')
    # Four bands wound round the waist, two of them in view: half of every turn of 4u + 0.74v is trim. A shape takes one
    # gradient, so the waist is cut into rings that darken towards each collar, where its shadow falls;
    # every ring continues its neighbour's band.
    half, rings, wind = 16., 14, .74
    for i in range(rings):
        y0, y1 = -half + 2 * half * i / rings, -half + 2 * half * (i + 1) / rings
        shade = 1 - .5 * (abs(y0 + y1) / 2 / half) ** 2.5
        tint = lambda c: vec([x * shade for x in c])
        lines += lathe(f'{key}-waist-{i}', [(28, y0), (28, y1)], f'color="1 1 1" {look}',
                       f'<gradient type="uv" tile="4 {f(wind / rings)}" offset="{f(.30 + wind * i / rings)}" repeat="1" edge="0.5" '
                       f'from="{tint(theme["rocket"])}" to="{tint(theme["rocket_trim"])}"/>')
    return lines, (ROCKET_TURN[key], ROCKET_LEAN)


def bomb(theme):
    """A sphere seen from near its pole: a belt above the equator, a socket at the pole and a short fuse."""
    body, trim, gloss = vec(theme['bomb']), vec(theme['bomb_trim']), theme['gloss']
    look = f'shininess="{gloss}" specular="1"'
    r = 44.
    lines = [f'<sphere radius="{f(r)}" rings="48" slices="72" color="{body}" {look}/>']
    lo, hi, lift = 7., 24., 2.2          # the belt: latitudes on the sphere, standing proud of it
    belt = ([(r * math.cos(math.radians(lo)), r * math.sin(math.radians(lo)))] +
            [((r + lift) * math.cos(math.radians(a)), (r + lift) * math.sin(math.radians(a)))
             for a in [lo + 1.5 + (hi - lo - 3) * i / 12 for i in range(13)]] +
            [(r * math.cos(math.radians(hi)), r * math.sin(math.radians(hi)))])
    lines += lathe('bomb-belt', belt, f'color="{trim}" {look}')
    # the socket: a collar sunk into the pole, its bore darker, and the fuse standing in it
    top = r * math.cos(math.radians(22))
    socket = [(21, top - 4)] + arc(15.5, top + 3, 5.6, 4.4, -20, 90, 8) + arc(15.5, top + 3, 5.6, 4.4, 90, 180, 6) + [(9.9, top - 2)]
    lines += lathe('bomb-socket', socket, f'color="{trim}" {look}')
    lines.append(f'<cylinder pos="0 {f(top - 1.4)} 0" radius="10.6" height="4" sides="48" color="{vec([c * .45 for c in theme["bomb"]])}" shininess="4" specular="0"/>')
    rope = f'<gradient type="uv" tile="1 2.5" repeat="1" edge="0.5" from="{vec(theme["fuse"])}" to="{vec(theme["fuse_dark"])}"/>'
    lines.append(f'<group pos="0 {f(top)} 0" rot="-26 0 0">')
    lines += ['  ' + l for l in lathe('bomb-fuse', [(7, 0), (7, 24)], 'color="1 1 1" shininess="12"', rope)]
    lines += ['  <sphere pos="0 25 0" radius="7.4" scale="1 0.72 1" color="0.96 0.33 0.08" shininess="20"/>',
              '  <sphere pos="0 28.4 0" radius="3.8" color="1 0.86 0.36" unlit="1" castShadow="0"/>',
              '</group>']
    return lines, BOMB_POSE


def tile_points(lat, lon, dlat, dlon, radius, height, profile, around=40):
    """One enamel tile: a rounded square in latitude and longitude, raised off the sphere along its profile.

    The grid runs around the tile (u) and from its centre to its rim (v), so the rim is a clean loop."""
    rows = []
    for extent, rise in profile:
        ring = []
        for i in range(around + 1):
            a = 2 * math.pi * i / around
            c, s = math.cos(a), math.sin(a)
            p = math.copysign(abs(c) ** .5, c) * extent     # superellipse, exponent 4: a rounded square
            q = math.copysign(abs(s) ** .5, s) * extent
            la, lo = math.radians(lat + q * dlat / 2), math.radians(lon + p * dlon / 2)
            rr = radius + height * rise
            ring.append((rr * math.cos(la) * math.sin(lo), rr * math.sin(la), rr * math.cos(la) * math.cos(lo)))
        rows.append(ring)
    return rows


def ball(theme):
    """A dark sphere carrying rows of enamel tiles; every tile is a patch of the sphere's own grid."""
    r, gap, height = 41., 7., 5.5
    lines = [f'<sphere radius="{f(r)}" rings="48" slices="72" color="{vec(theme["core"])}" shininess="24"/>']
    for lat, dlat, count, first, colours in BALL_ROWS:
        dlon = 360 / count - gap / math.cos(math.radians(lat))
        for i in range(count):
            rows = tile_points(lat, first + i * 360 / count, dlat, dlon, r, height, theme['tile'])
            pts = ' '.join(vec(p) for ring in rows for p in ring)
            lines.append(f'<surface segments="{len(rows[0]) - 1} {len(rows) - 1}" twoSided="1" castShadow="0" '
                         f'color="{vec(RAINBOW[colours[i]])}" shininess="{theme["gloss"] + 10}" specular="1" points="{pts}">'
                         '<gradient type="uv" tile="0 1" power="3" from="1.08 1.08 1.08" to="0.5 0.46 0.56"/></surface>')
    return lines, (0., BALL_LEAN)


def scene(game):
    theme = THEMES[game]
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           f'<!-- {game} match-3 power-ups, written by nile-archive tools/match3_specials.py.',
           '     Generated: edit the tool, not this file. One orthographic camera per sprite. -->',
           '<scene ambient="0.70 0.67 0.74" background="0 0 0" skyReflection="0.6">',
           '  <sun dir="0.55 -0.85 -0.75" color="1 0.97 0.92" intensity="0.8" castShadows="0"/>',    # key, upper left
           '  <sun dir="-0.8 0.3 -0.5" color="0.75 0.82 1" intensity="0.2" castShadows="0"/>',       # fill, right
           '  <sun dir="-0.55 0.6 0.55" color="1 0.8 0.6" intensity="0.3" castShadows="0"/>']        # bounce, behind and below
    for n, key in enumerate(SPRITES):
        lines, (turn, lean) = rocket(key, theme) if key in ROCKET_TURN else bomb(theme) if key == 'bomb' else ball(theme)
        x = n * SPACING
        out.append(f'  <camera name="{key}" pos="{f(x)} 0 600" look="{f(x)} 0 0" ortho="{f(VIEW)}" size="{SIZE} {SIZE}"/>')
        # lean about the screen's horizontal first, then turn in the screen plane: the axis keeps its screen angle
        out.append(f'  <group name="{key}" pos="{f(x)} 0 0" rot="0 0 {f(turn)}"><group rot="{f(lean)} 0 0">')
        out += ['    ' + line for line in lines]
        out.append('  </group></group>')
    return '\n'.join(out + ['</scene>', ''])


def render(game, scener='scener', log=print):
    """Write the game's scene and render its five sprites beside it."""
    out = ROOT / 'games' / game / 'art/board-theme/specials'
    out.mkdir(parents=True, exist_ok=True)
    path = out / 'specials.blks'
    path.write_text(scene(game))
    if not shutil.which(scener):
        raise SystemExit(f'{scener} is required to render {path.relative_to(ROOT)}')
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([scener, '--render', str(path), '--format', 'png', '--transparent', '--supersample', '4',
                        '--output-dir', tmp], check=True, stdout=subprocess.DEVNULL)
        for key in SPRITES:
            shutil.move(Path(tmp) / f'{key}.png', out / f'{key}.png')
    log(f'{game}: rendered {len(SPRITES)} power-ups to {out.relative_to(ROOT)}')
    return out


def sheet(paths, target):
    from PIL import Image
    tiles = [Image.open(p / f'{key}.png').convert('RGBA') for p in paths for key in SPRITES]
    image = Image.new('RGBA', (SIZE * len(SPRITES), SIZE * len(paths)), (74, 92, 78, 255))
    for i, tile in enumerate(tiles):
        image.alpha_composite(tile, (i % len(SPRITES) * SIZE, i // len(SPRITES) * SIZE))
    image.save(target)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('games', nargs='*', default=sorted(THEMES))
    ap.add_argument('--scener', default='scener')
    ap.add_argument('--sheet', help='also write a review sheet of every rendered sprite')
    ap.add_argument('--check', action='store_true', help='verify the committed scenes and renders, writing nothing')
    a = ap.parse_args()
    unknown = [g for g in a.games if g not in THEMES]
    if unknown:
        sys.exit(f'No power-up theme for {unknown}')
    if a.check:
        for g in a.games:
            out = ROOT / 'games' / g / 'art/board-theme/specials'
            assert (out / 'specials.blks').read_text() == scene(g), f'Stale {g} power-up scene: run python3 tools/match3_specials.py'
            assert all((out / f'{key}.png').is_file() for key in SPRITES), f'{g}: missing power-up renders'
            print(f'{g}: power-up scene and {len(SPRITES)} renders verified')
        sys.exit()
    done = [render(g, a.scener) for g in a.games]
    if a.sheet:
        sheet(done, a.sheet)
