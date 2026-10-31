# Nile Archive's buildings and decorations, as procedural Blender geometry on the game's grid.
#
# tools/building_kit.py holds the toolbox and the conventions; the palette and the
# objects are Nile Archive's own. The five story restorations are in restorations.py.
# Rebuild the master and re-render with: make buildings GAME=nile-archive REBUILD=1
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3] / "tools"))
sys.path.insert(0, str(HERE))
from building_kit import *
import restorations


# ------------------------------------------------------------------ decoration kit (as in Relic Rush)

def blade(k, p, out, L, w, rise=.4, droop=.8, col=None):
    """One broad leaf: out is its direction on the ground."""
    p, out = Vector(p), Vector((out[0], out[1], 0)).normalized()
    side = Vector((-out.y, out.x, 0))
    base = col or J(R.choice(LEAVES), .04)
    def fn(u, v):
        wid = w * math.sin(math.pi * (v * .92 + .08))
        q = p + out * L * v + Vector((0, 0, L * (rise * v - droop * v * v))) + side * (u - .5) * 2 * wid - Vector((0, 0, abs(u - .5) * wid * .6))
        return tuple(q)
    k.surface("leaf", fn, 2, 6, lambda u, v: tuple(c * (.72 + .4 * (1 - abs(u - .5) * 2)) for c in base))

def bloom(k, x, y, z, r, col, centre=None):
    for i in range(5):
        a = 2 * math.pi * i / 5
        k.ball("matte", x + r * .62 * math.cos(a), y + r * .62 * math.sin(a), z, r * .62, col, 8, sz=.55)
    k.ball("matte", x, y, z + r * .12, r * .38, centre or C("#F4C430"), 8)

def rock(k, x, y, z, r, col=None, sz=.8):
    k.ball("matte", x, y, z + r * sz * .8, r, col or J(GREY, .06), 9, sz=sz, sx=R.uniform(.9, 1.1))

def plinth(k, s=.5, h=.16):
    k.box("stone", 0, 0, 0, s, s, h, SAND_PALE)
    return h

def petals(k, heads, r, col, centre=None):
    for x, y, h in heads:
        k.tube("leaf", (x, y, 0), (x, y, h), .012, .012, C("#3F8F2F"), 5)
        bloom(k, x, y, h, r, col() if callable(col) else col, centre)
def low_leaves(k, n=7, L=.3):
    for i in range(n):
        a = 2 * math.pi * i / n
        blade(k, (0, 0, .01), (math.cos(a), math.sin(a)), L, .09, rise=1.0, droop=1.2)


# ------------------------------------------------------------------ Nile palette and helpers
#
# Painted limestone, whitewashed mud brick, lapis, turquoise and gold, the
# colours of Nile Archive's island. Same casual rules as Relic Rush: few, big,
# soft shapes; nothing smaller than about a tenth of a tile.

LIME, LIME_D, LIME_L = C("#E6D3A3"), C("#C7AC78"), C("#F3E6C2")
MUD, MUD_L = C("#B98B5C"), C("#D3A976")
WASH = C("#F1E7CF")
LAPIS, LAPIS_L = C("#2B5CAE"), C("#4E88D8")
OCHRE = C("#B9552F")
PAPY = C("#7DBA3E")
LINEN = C("#F0E4C6")
INK = C("#2B2420")
SKIN = C("#B97A4A")
PINK = C("#EE86AE")
DATE = C("#C8641E")
DOOR = C("#3A2614")
SLAB = C("#CDB283")   # the paved base of every building

def face(a, b, t=.24):
    """A frame on a wall's outer surface: x along it, -y out."""
    return wall_frame(a, b) @ Matrix.Translation((0, -t / 2, 0))

def lime():
    return J(R.choice((LIME, LIME, LIME_L)), .03)

def frustum(k, mat, x, y, z, sx, sy, h, tx, ty, col, rz=0.):
    """A battered block: the top is inset by tx, ty on each side (pylons, towers, mastabas)."""
    hx, hy = sx / 2, sy / 2
    v = [(-hx, -hy, 0), (hx, -hy, 0), (hx, hy, 0), (-hx, hy, 0),
         (-hx + tx, -hy + ty, h), (hx - tx, -hy + ty, h), (hx - tx, hy - ty, h), (-hx + tx, hy - ty, h)]
    f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    k.add(mat, v, f, col, m=Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z"))

def pyramid(k, mat, x, y, z, s, h, col):
    hs = s / 2
    v = [(x - hs, y - hs, z), (x + hs, y - hs, z), (x + hs, y + hs, z), (x - hs, y + hs, z), (x, y, z + h)]
    k.add(mat, v, [(3, 2, 1, 0), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)], col)

def cornice(k, x, y, z, sx, sy, band=None):
    """The flared top of an Egyptian wall: a painted band and a pale lip."""
    k.box("glaze", x, y, z, sx + .06, sy + .06, .08, band or TEAL)
    k.box("stone", x, y, z + .08, sx + .14, sy + .14, .1, LIME_L)

def column(k, x, y, z, h, r=.12, band=TEAL):
    """A papyrus column: pale shaft, painted bands and an open flower capital."""
    k.lathe("stone", x, y, z, [(r * 1.15, 0), (r, .08), (r * .92, h * .78)], J(LIME, .02), 14)
    for i, c in enumerate((band, GOLD, band)):
        k.lathe("glaze", x, y, z + h * .62 + i * .05, [(r * .97, 0), (r * .97, .05)], c, 14)
    k.lathe("glaze", x, y, z + h * .78, [(r * .92, 0), (r * 1.5, h * .18), (r * 1.55, h * .2)], PAPY, 14)
    k.box("stone", x, y, z + h * .98, r * 2.6, r * 2.6, h * .06, LIME_L)

def stripes(k, x, y, z, sx, sy, h, cols, n=8, mat="glaze"):
    """Stacked bands, like a painted nemes cloth or a banded pot."""
    for i in range(n):
        k.box(mat, x, y, z + i * h / n, sx, sy, h / n, cols[i % len(cols)])

def doorway(k, a, b, s, w, h, z=0.):
    """A dark door on the outside of wall a-b with a pale frame and a lintel."""
    with k.at(face(a, b, 0)):
        k.box("matte", s, -.012, z, w, .03, h, DOOR)
        for side in (-1, 1):
            k.box("stone", s + side * (w / 2 + .05), -.02, z, .1, .05, h, LIME_L)
        k.box("stone", s, -.03, z + h, w + .26, .07, .12, LIME_L)
        k.box("glaze", s, -.05, z + h + .02, w * .6, .02, .07, LAPIS)

def slot(k, a, b, s, z, w=.12, h=.22, col=DOOR):
    with k.at(face(a, b, 0)):
        k.box("matte", s, -.012, z, w, .03, h, col)

def relief(k, a, b, s, z, w, h, cols=(OCHRE, LAPIS, GOLD)):
    """A painted panel on a wall: three figures as coloured blocks."""
    with k.at(face(a, b, 0)):
        k.box("matte", s, -.01, z, w, .02, h, J(LIME_L, .02))
        for i, c in enumerate(cols):
            px = s + (i - (len(cols) - 1) / 2) * w / (len(cols) + .4)
            k.box("matte", px, -.022, z + h * .14, w * .13, .02, h * .52, c)
            k.ball("matte", px, -.026, z + h * .76, w * .07, INK, 8, sy=.3)

def flag(k, x, y, z, h, col, d=(0, -1)):
    k.tube("wood", (x, y, z), (x, y, z + h), .035, .03, WOOD_D, 8)
    k.ball("gold", x, y, z + h + .02, .05, GOLD, 10)
    dx, dy = d
    p = [(x, y, z + h - .04), (x + dx * .42, y + dy * .42, z + h - .14), (x, y, z + h - .36)]
    k.poly("cloth", p, col)

def jar(k, x, y, z, r=.12, col=None, band=None):
    k.lathe("clay", x, y, z, [(r * .45, 0), (r, r * .8), (r * .95, r * 1.5), (r * .45, r * 2.1), (r * .5, r * 2.35), (r * .38, r * 2.4)], col or J(POT, .06), 14)
    if band:
        k.lathe("glaze", x, y, z + r * 1.15, [(r * 1.01, 0), (r * 1.01, r * .22)], band, 14)

def date_palm(k, x, y, z, h=1., L=.5, fronds=7, dates=True):
    k.palm(x, y, z, h, L, fronds)
    x, y = k.fit(x, y, L * 1.02)
    if dates:
        for a in (.6, 2.6, 4.5):
            k.ball("matte", x + .08 * math.cos(a), y + .08 * math.sin(a), z + h - .1, .06, DATE, 8, sz=1.4)

def head(k, x, y, z, s, nemes=True, face_dir=(1, 0)):
    """A royal head facing face_dir: a striped nemes cloth with lappets, a uraeus and a beard."""
    fx, fy = face_dir
    f, side = Vector((fx, fy, 0)), Vector((-fy, fx, 0))
    c = Vector((x, y, z + s * .55))
    k.ball("stone", c.x + fx * s * .06, c.y + fy * s * .06, c.z, s * .4, J(LIME_D, .02), 14, sz=1.15)
    if nemes:
        b = c - f * s * .14
        n = 7
        for i in range(n):   # a dome of solid bands, so the stripes stay crisp
            t0, t1 = math.pi / 2 * i / n, math.pi / 2 * (i + 1) / n
            r = s * .46
            k.lathe("glaze", b.x, b.y, b.z + s * .12, [(r * math.cos(t0), r * math.sin(t0)), (max(r * math.cos(t1), .001), r * math.sin(t1))],
                    GOLD if i % 2 else LAPIS, 16)
        k.lathe("glaze", b.x, b.y, b.z - s * .2, [(s * .46, 0), (s * .46, s * .32)], LAPIS, 16)
        for sd in (-1, 1):
            p = c + side * sd * s * .38 + f * s * .02
            for i in range(5):
                k.lathe("glaze", p.x, p.y, z - s * .45 + i * s * .18, [(s * .12, 0), (s * .12, s * .18)], GOLD if i % 2 else LAPIS, 8,
                        sx=.7 if fx else 1.4, sy=1.4 if fx else .7)
        u = c + f * s * .36
        k.box("gold", u.x, u.y, c.z + s * .32, s * .1, s * .1, s * .2, GOLD)
    for sd in (-1, 1):
        e = c + f * s * .43 + side * sd * s * .15
        k.ball("matte", e.x, e.y, e.z + s * .06, s * .06, INK, 8)
    d = c + f * s * .3
    k.box("matte", d.x, d.y, c.z - s * .7, s * .12, s * .12, s * .32, LAPIS)

def seated_cat(k, x, y, z, s, col=INK, collar=GOLD):
    k.ball("matte", x, y, z + s * .35, s * .32, col, 12, sx=.8, sz=1.3)
    k.ball("matte", x + s * .1, y - s * .05, z + s * .85, s * .2, col, 12)
    for side in (-1, 1):
        k.lathe("matte", x + s * .08, y - s * .05 + side * s * .12, z + s * .98, [(s * .07, 0), (.001, s * .2)], col, 6)
    k.lathe("gold", x + s * .02, y - s * .03, z + s * .62, [(s * .2, 0), (s * .2, s * .05)], collar, 14)
    k.path("matte", [(x - s * .25, y, z + s * .05), (x - s * .1, y + s * .3, z + s * .05)], s * .05, col, 6)

def lotus(k, x, y, z, r, col=PINK):
    for i in range(6):
        a = 2 * math.pi * i / 6
        k.lathe("matte", x + r * .3 * math.cos(a), y + r * .3 * math.sin(a), z, [(.001, 0), (r * .3, r * .3), (.001, r * .8)], col, 6,
                m=Matrix.Rotation(.5, 4, Vector((-math.sin(a), math.cos(a), 0))))
    k.ball("matte", x, y, z + r * .25, r * .25, C("#FFD24A"), 8)

def pad(k, x, y, z, r):
    k.lathe("leaf", x, y, z, [(.001, 0), (r, 0), (r, .015)], J(C("#3E9B45"), .05), 14, smooth=False)

def pool(k, x, y, z, sx, sy, rim=.14, depth=.08, rimcol=None):
    k.box("water", x, y, z, sx - rim, sy - rim, depth, WATER)
    for s in (-1, 1):
        k.box("stone", x, y + s * (sy - rim) / 2, z, sx + rim, rim, depth + .06, rimcol or LIME_L)
        k.box("stone", x + s * (sx - rim) / 2, y, z, rim, sy - rim, depth + .06, rimcol or LIME_L)

def stair(k, x, y, z, w, n, step=.12, run=.12, d=(0, -1)):
    """Steps going down from z along d."""
    dx, dy = d
    for i in range(n):
        h = (n - i) * step
        k.box("stone", x + dx * run * (i + .5), y + dy * run * (i + .5), z - h, w if dy else run, run if dy else w, h, J(LIME_L, .02))

def wheel(k, x, y, z, r, axis="Y"):
    rot = Matrix.Rotation(math.pi / 2, 4, "X" if axis == "Y" else "Y")
    k.lathe("wood", x, y, z, [(r, -.03), (r, .03)], WOOD_D, 16, m=rot)
    k.lathe("gold", x, y, z, [(r * .25, -.05), (r * .25, .05)], GOLD, 10, m=rot)
    for i in range(4):
        a = math.pi * i / 4
        d = Vector((math.cos(a), 0, math.sin(a))) if axis == "Y" else Vector((0, math.cos(a), math.sin(a)))
        c = Vector((x, y, z))
        k.beam("wood", tuple(c - d * r), tuple(c + d * r), .04, .04, WOOD_L)

def sail_boat(k, x, y, z, L, W, hull=WOOD, sail=True):
    """A felucca along X: a crescent hull, mast and lateen sail."""
    def fn(u, v):
        t = (u - .5) * 2
        rise = .18 * t ** 4 + .02
        wid = W * .5 * (1 - t * t) ** .6
        a = math.pi * v
        return (x + t * L / 2, y + wid * math.cos(a), z + rise + .2 * (1 - math.sin(a) * .9) * (1 - t * t) ** .3 - .2)
    k.surface("wood", fn, 14, 6, lambda u, v: J(hull, .02) if v < .5 or v > .5 else hull)
    k.box("wood", x, y, z + .02, L * .74, W * .8, .04, WOOD_L)
    if sail:
        k.tube("wood", (x + L * .08, y, z), (x + L * .08, y, z + 1.3), .03, .025, WOOD_D, 8)
        p = [(x - L * .38, y + .02, z + .2), (x + L * .4, y + .02, z + 1.45), (x + L * .1, y + .02, z + .3)]
        k.poly("cloth", p, LINEN)
        k.beam("wood", (x - L * .4, y, z + .19), (x + L * .42, y, z + 1.47), .03, .03, WOOD_D)


# ------------------------------------------------------------------ monuments (story landmarks)

def small_pyramid(k):
    for i in range(4):
        s = 1.66 - .36 * i
        k.box("stone", 0, 0, G + i * .3, s, s, .3, J(LIME, .02))
    pyramid(k, "gold", 0, 0, G + 1.2, .3, .3, GOLD)
    doorway(k, (.83, -.83), (.83, .83), .83, .3, .26, G)
    k.puff(.8, -.8, G, .14)
    k.puff(-.8, -.82, G, .13)
    date_palm(k, -.72, .72, G, .8, .38, 6)

def nilometer(k):
    pool(k, -.05, .05, G, 1.5, 1.5, .18, .06)
    for i in range(4):
        k.box("stone", -.42 + i * .2, .05, G, .2, 1.1, .06 + .07 * i, J(LIME_L, .02))
    k.box("stone", .38, .05, G, .34, .34, .14, LIME_D)
    k.lathe("stone", .38, .05, G + .14, [(.1, 0), (.09, 1.1)], LIME, 12)
    for i in range(6):
        k.lathe("glaze", .38, .05, G + .3 + i * .15, [(.095, 0), (.095, .04)], LAPIS if i % 2 else GOLD, 12)
    k.ball("gold", .38, .05, G + 1.28, .1, GOLD, 12)
    for x, y in ((-.82, -.82), (.82, -.82), (.82, .82)):
        k.box("stone", x, y, G, .28, .28, .4, J(LIME, .02))
        k.box("glaze", x, y, G + .4, .32, .32, .06, TEAL)
    date_palm(k, -.76, .76, G, .9, .4, 6)

def band_plinth(k, x, y, z, sx, sy, h, col=LIME_D, band=TEAL):
    """A plinth with a painted stripe just under its top."""
    k.box("stone", x, y, z, sx, sy, h, col)
    k.box("glaze", x, y, z + h - .11, sx + .04, sy + .04, .06, band)

def sphinx(k):
    band_plinth(k, 0, 0, G, 2.7, 1.5, .3)
    z = G + .3
    k.ball("stone", -.32, 0, z, .42, J(LIME, .02), 16, sx=2.2, sy=1.3, sz=.95)
    for side in (-1, 1):
        k.box("stone", .5, side * .27, z, 1.0, .24, .2, J(LIME, .02))
        k.ball("stone", 1.0, side * .27, z + .08, .13, LIME, 10, sz=.7)
    k.ball("stone", .45, 0, z + .36, .32, J(LIME, .02), 14, sx=1.2, sz=1.25)
    head(k, .62, 0, z + .66, .48)
    k.path("stone", [(-1.15, .3, z + .1), (-1.25, .52, z + .06), (-.9, .6, z + .04)], .06, LIME, 8)
    for x in (-1.15, 1.15):
        k.puff(x, -.6, G, .12)

def barque_shrine(k):
    k.box("stone", 0, 0, G, 2.5, 1.5, .18, LIME_L)
    k.box("stone", 0, 0, G + .18, 1.8, .9, .3, LIME)
    k.box("glaze", 0, 0, G + .37, 1.84, .94, .06, TEAL)
    sail_boat(k, 0, 0, G + .62, 1.7, .5, GOLD_D, sail=False)
    k.box("gold", 0, 0, G + .6, 1.1, .3, .06, GOLD)
    k.box("gold", 0, 0, G + .66, .5, .3, .3, GOLD)
    cornice(k, 0, 0, G + .96, .5, .3, LAPIS)
    for x in (-.9, .9):
        for y in (-.5, .5):
            column(k, x, y, G + .18, 1.15, .07)
    k.box("cloth", 0, 0, G + 1.36, 2.0, 1.2, .06, LAPIS)
    cornice(k, 0, 0, G + 1.42, 1.9, 1.1, TEAL)
    for x in (-1.15, 1.15):
        k.puff(x, -.62, G, .1)

def pylon_gate(k):
    for x in (-.85, .85):
        frustum(k, "stone", x, 0, G, 1.1, 1.1, 1.85, .16, .1, J(LIME, .02))
        cornice(k, x, 0, G + 1.85, .78, .9, TEAL)
        relief(k, (x - .5, -.5), (x + .5, -.5), .5, G + .5, .58, .9)
        flag(k, x + (.32 if x > 0 else -.32), -.62, G, 2.0, (OCHRE if x < 0 else LAPIS), (-1 if x < 0 else 1, 0))
    k.box("stone", 0, 0, G, .64, .8, 1.25, LIME_D)
    cornice(k, 0, 0, G + 1.25, .6, .8, LAPIS)
    doorway(k, (-.32, -.4), (.32, -.4), .32, .36, .85, G)
    k.ball("gold", 0, -.44, G + 1.36, .1, GOLD, 12, sy=.3)
    for s in (-1, 1):
        k.box("glaze", s * .2, -.44, G + 1.38, .26, .03, .06, LAPIS)

def hypostyle(k):
    k.box("stone", 0, 0, G, 2.8, 2.8, .14, LIME_L)
    for x in (-1.05, -.35, .35, 1.05):
        for y in (-1.05, -.35, .35, 1.05):
            column(k, x, y, G + .14, 1.25 if abs(x) > .5 or abs(y) > .5 else 1.55, .13, TEAL if (x + y) % 1.4 < .1 else LAPIS)
    k.box("stone", 0, 0, G + 1.42, 2.7, 2.7, .14, LIME)
    cornice(k, 0, 0, G + 1.56, 2.6, 2.6, TEAL)
    k.box("stone", 0, 0, G + 1.74, 1.1, 1.1, .3, LIME_D)
    cornice(k, 0, 0, G + 2.04, 1.0, 1.0, LAPIS)
    for x in (-1.2, 1.2):
        k.puff(x, -1.24, G, .12)

def sun_temple(k):
    k.box("stone", 0, 0, G, 2.8, 2.8, .1, LIME_L)
    k.wall((-1.3, 1.3), (1.3, 1.3), G, G + .7, .24, .35, .6)
    k.wall((-1.3, -1.3), (-1.3, 1.3), G, G + .7, .24, .35, .6)
    for p in ((-1.3, 1.3), (1.3, 1.3), (-1.3, -1.3)):
        k.box("glaze", p[0], p[1], G + .7, .3, .3, .08, TEAL)
    k.box("stone", -.2, .2, G + .1, .7, .7, .3, LIME_D)
    obelisk(k, -.2, .2, G + .4, .32, 1.9)
    k.ball("gold", -.2, .2, G + 2.55, .2, GOLD, 16, sx=.3)
    k.box("stone", .7, -.6, G + .1, .5, .36, .32, LIME)
    k.brazier(.7, -.6, G + .42, .1)
    for x, y in ((.85, .6), (-.7, -.85)):
        k.box("stone", x, y, G + .1, .36, .36, .2, LIME_D)
        seated_cat(k, x, y, G + .3, .45, LIME_D, TEAL)
    date_palm(k, 1.0, 1.0, G, 1.0, .44, 7)

def obelisk(k, x, y, z, s, h):
    rot = Matrix.Rotation(math.pi / 4, 4, "Z")
    k.lathe("stone", x, y, z, [(s * .7, 0), (s * .5, h)], J(C("#D99A6C"), .02), 4, smooth=False, m=rot)
    k.lathe("gold", x, y, z + h, [(s * .5, 0), (.001, s * .5)], GOLD, 4, smooth=False, m=rot)
    for i in range(4):
        k.box("glaze", x - s * .5, y, z + h * (.25 + .15 * i), .02, s * .25, s * .12, LAPIS)

def lighthouse(k):
    k.box("stone", 0, 0, G, 1.7, 1.7, .16, LIME_L)
    frustum(k, "stone", 0, 0, G + .16, 1.3, 1.3, 1.0, .1, .1, J(LIME, .02))
    cornice(k, 0, 0, G + 1.16, 1.1, 1.1, TEAL)
    for s in (-.3, .3):
        slot(k, (.65, -.65), (.65, .65), .65 + s, G + .55)
        slot(k, (-.65, -.65), (.65, -.65), .65 + s, G + .55)
    doorway(k, (-.65, -.65), (.65, -.65), .65, .3, .42, G + .16)
    k.lathe("stone", 0, 0, G + 1.34, [(.42, 0), (.38, .62)], LIME, 8, smooth=False)
    k.lathe("glaze", 0, 0, G + 1.96, [(.44, 0), (.44, .07)], LAPIS, 8, smooth=False)
    k.lathe("stone", 0, 0, G + 2.03, [(.26, 0), (.24, .4)], LIME_L, 16)
    for i in range(4):
        a = math.pi / 4 + math.pi * i / 2
        k.box("stone", .24 * math.cos(a), .24 * math.sin(a), G + 2.43, .08, .08, .3, LIME_L)
    k.brazier(0, 0, G + 2.43, .12)
    k.lathe("gold", 0, 0, G + 2.73, [(.3, 0), (.001, .25)], GOLD, 16)

def sacred_lake(k):
    pool(k, 0, 0, G, 2.7, 2.7, .2, .06)
    for i in range(3):
        k.box("stone", -.2, -1.1 + i * .14, G, 1.0, .14, .05 + (2 - i) * .04, LIME_L)
    for x, y, r in ((.4, .3, .2), (-.5, .45, .17), (.6, -.4, .15), (-.2, .9, .14), (.9, .8, .13)):
        pad(k, x, y, G + .07, r)
    for x, y in ((.38, .26), (-.5, .42), (.88, .78)):
        lotus(k, x, y, G + .085, .14)
    for x, y in ((-1.18, 1.18), (1.18, 1.18), (-1.18, -1.18)):
        papyrus(k, x, y, G, .4)
    date_palm(k, 1.15, -1.15, G, 1.0, .4, 6)

def great_pyramid(k):
    k.box("stone", 0, 0, G, 3.8, 3.8, .12, LIME_L)
    n = 13
    for i in range(n):
        s = 3.4 * (1 - i / n)
        k.box("stone", 0, 0, G + .12 + i * .2, s, s, .2, J(LIME, .015))
    pyramid(k, "gold", 0, 0, G + .12 + n * .2, 3.4 / n + .02, .28, GOLD)
    y1 = -3.4 * (1 - 1 / n) / 2
    doorway(k, (-1.5, y1), (1.5, y1), 1.5, .3, .4, G + .32)
    for x in (-1.75, 1.75):
        obelisk(k, x, -1.75, G + .12, .14, .8)
    for y in (-1.0, .4):
        k.puff(1.78, y, G, .1)
    date_palm(k, 1.62, 1.62, G, .9, .32, 6)


# ------------------------------------------------------------------ buildings

def mud_house(k):
    k.box("stone", 0, .1, G, 1.3, 1.3, 1.0, J(WASH, .02))
    k.box("stone", 0, .1, G + 1.0, 1.38, 1.38, .07, LIME_D)
    k.box("stone", -.36, .44, G + 1.07, .5, .58, .5, J(WASH, .02))
    k.box("cloth", .25, -.1, G + 1.45, .8, .8, .04, TEAL)
    for x, y in ((-.1, -.45), (.6, -.45), (.6, .35)):
        k.tube("wood", (x, y, G + 1.07), (x, y, G + 1.45), .025, .025, WOOD_D, 6)
    doorway(k, (.65, -.55), (.65, .75), .55, .28, .58, G)
    slot(k, (-.65, -.55), (.65, -.55), .35, G + .55, .18, .2)
    slot(k, (-.65, -.55), (.65, -.55), .95, G + .55, .18, .2)
    for i in range(5):
        k.box("stone", -.55 + i * .2, -.72, G, .2, .22, .2 + i * .2, J(LIME_L, .02))
    jar(k, .8, -.75, G, .1, band=LAPIS)
    date_palm(k, .75, .78, G, .9, .35, 6)

def pottery(k):
    k.box("stone", -.3, .35, G, 1.0, .9, .75, J(MUD_L, .03))
    k.box("stone", -.3, .35, G + .75, 1.06, .96, .06, MUD)
    k.box("cloth", -.3, -.3, G + .6, 1.0, .5, .04, OCHRE)
    for x in (-.75, .15):
        k.tube("wood", (x, -.5, G), (x, -.5, G + .6), .03, .03, WOOD_D, 6)
    doorway(k, (-.8, -.1), (.2, -.1), .7, .26, .5, G)
    k.lathe("clay", .5, .45, G, [(.38, 0), (.36, .3), (.22, .62), (.08, .72), (.001, .74)], J(CLAY, .03), 16)
    k.box("glow", .5, .07, G + .1, .2, .04, .18, FLAME)
    k.lights.append(((.5, -.05, G + .2), .8))
    k.lathe("wood", .3, -.45, G, [(.06, 0), (.06, .26), (.2, .26), (.2, .3)], WOOD_L, 14)
    k.lathe("clay", .3, -.45, G + .3, [(.08, 0), (.1, .1), (.05, .16)], CLAY_L, 12)
    for x, y, r, b in ((-.8, -.8, .1, TEAL), (.75, -.75, .09, None), (.8, -.4, .08, LAPIS), (-.55, -.78, .08, None)):
        jar(k, x, y, G, r, band=b)

def bakery(k):
    k.box("stone", -.35, .2, G, 1.7, 1.1, .85, J(MUD_L, .03))
    cornice(k, -.35, .2, G + .85, 1.7, 1.1, OCHRE)
    doorway(k, (-1.2, -.35), (.5, -.35), .85, .3, .55, G)
    slot(k, (-1.2, -.35), (.5, -.35), .35, G + .45, .2, .18)
    slot(k, (-1.2, -.35), (.5, -.35), 1.35, G + .45, .2, .18)
    for y in (-.4, .35):
        k.lathe("clay", 1.0, y, G, [(.3, 0), (.29, .2), (.18, .45), (.001, .52)], J(CLAY, .03), 16)
        k.box("glow", 1.29, y, G + .06, .04, .16, .14, FLAME)
        k.lights.append(((1.36, y, G + .14), .6))
    k.box("wood", .3, -.72, G, .6, .3, .3, WOOD_L)
    for i in range(4):
        k.ball("matte", .12 + i * .12, -.72, G + .33, .06, C("#D39446"), 10, sz=.6)
    k.basket(-.9, -.7, G, .14)
    k.box("cloth", -.35, -.55, G + .62, 1.6, .4, .04, LINEN)

def weaver(k):
    k.box("stone", -.6, .45, G, 1.6, .7, .7, J(WASH, .02))
    cornice(k, -.6, .45, G + .7, 1.6, .7, LAPIS)
    for x in (-1.35, -.15, .95):
        for y in (-.75, .05):
            k.tube("wood", (x, y, G), (x, y, G + .9), .035, .035, WOOD, 8)
    k.awning(-1.4, 1.0, -.85, .1, G + .85, G + .95, (LINEN, OCHRE), 6, .08)
    k.box("wood", -.3, -.35, G + .15, 1.0, .6, .04, WOOD_D)
    for i, c in enumerate((OCHRE, LAPIS, GOLD, TEAL, OCHRE, LAPIS)):
        k.box("cloth", -.7 + i * .16, -.35, G + .19, .1, .5, .02, c)
    for x in (-.8, .2):
        for y in (-.62, -.08):
            k.box("wood", x, y, G, .06, .06, .19, WOOD_D)
    for i, c in enumerate((OCHRE, LAPIS, GOLD)):
        k.tube("cloth", (.75, -.85 + i * .2, G + .14), (1.35, -.85 + i * .2, G + .14), .09, .09, c, 12)
    jar(k, 1.25, .7, G, .1, band=TEAL)

def scribe_school(k):
    k.box("stone", 0, .25, G, 2.6, 1.3, .95, J(LIME, .02))
    cornice(k, 0, .25, G + .95, 2.6, 1.3, TEAL)
    for x in (-1.0, -.35, .35, 1.0):
        column(k, x, -.65, G, .95, .09)
    k.box("stone", 0, -.42, G + .95, 2.6, .55, .1, LIME_L)
    k.box("glaze", 0, -.7, G + .95, 2.62, .04, .08, LAPIS)
    doorway(k, (-1.3, -.4), (1.3, -.4), 1.3, .36, .6, G)
    relief(k, (-1.3, -.4), (1.3, -.4), .55, G + .25, .5, .5)
    relief(k, (-1.3, -.4), (1.3, -.4), 2.05, G + .25, .5, .5)
    for i in range(3):
        k.tube("cloth", (1.35, -.6 + i * .2, G + .1), (1.35, -.6 + i * .2, G + .3), .05, .05, LINEN, 10)
    k.box("wood", 1.36, -.4, G, .2, .7, .1, WOOD)

def granary(k):
    for a, b in (((-1.4, -.9), (1.4, -.9)), ((1.4, -.9), (1.4, .9)), ((1.4, .9), (-1.4, .9)), ((-1.4, .9), (-1.4, -.9))):
        k.wall(a, b, G, G + .35, .16, .35, .5, col=MUD_L)
    for x, y, r in ((-.75, .3, .42), (.15, .3, .42), (.95, .3, .36)):
        k.lathe("clay", x, y, G, [(r, 0), (r, .45), (r * .7, .95), (r * .2, 1.12), (.001, 1.14)], J(MUD_L, .03), 18)
        k.box("matte", x + r * .7, y - r * .7, G + .7, .14, .04, .16, DOOR, -math.pi / 4)
    k.box("cloth", -.4, -.5, G, .9, .3, .02, LINEN)
    for i in range(4):
        k.ball("cloth", -.7 + i * .2, -.5, G + .1, .1, C("#D9C08A"), 10, sz=1.1)
    for i in range(3):
        k.box("stone", .5, -.55 + i * .12, G, .3, .12, .35 - i * .1, LIME_L)

def bazaar(k):
    for x, y, cols in ((-.75, .55, (LINEN, OCHRE)), (.55, .55, (LINEN, LAPIS)), (-.35, -.75, (LINEN, TEAL))):
        for dx in (-.5, .5):
            for dy in (-.3, .3):
                k.tube("wood", (x + dx, y + dy, G), (x + dx, y + dy, G + .85 + (.15 if dy > 0 else 0)), .03, .03, WOOD_D, 6)
        k.awning(x - .58, x + .58, y - .38, y + .38, G + .82, G + 1.02, cols, 5, .1)
        k.box("wood", x, y - .15, G, .9, .3, .3, WOOD_L)
        for i in range(3):
            k.basket(x - .3 + i * .3, y - .15, G + .3, .11)
    k.box("cloth", .7, -.65, G, .9, .6, .02, OCHRE)
    k.box("cloth", .7, -.65, G + .02, .7, .4, .01, GOLD)
    for x, y in ((1.15, -.15), (1.2, -1.15), (.3, -1.2)):
        jar(k, x, y, G, .12, band=LAPIS)

def villa(k):
    k.box("stone", -.25, .3, G, 2.2, 1.9, .9, J(WASH, .02))
    k.box("stone", -.25, .3, G + .9, 2.3, 2.0, .07, LIME_D)
    k.box("stone", -.65, .55, G + .97, 1.3, 1.3, .7, J(WASH, .02))
    cornice(k, -.65, .55, G + 1.67, 1.3, 1.3, TEAL)
    for x in (.2, .7):
        column(k, x, -.4, G + .97, .65, .06)
    k.box("cloth", .45, .2, G + 1.62, .8, 1.3, .04, OCHRE)
    doorway(k, (.85, -.65), (.85, 1.25), .6, .3, .6, G)
    for s in (.3, .9, 1.5):
        slot(k, (-1.35, -.65), (.85, -.65), s, G + .45, .2, .22)
    slot(k, (-1.3, -.1), (0, -.1), .4, G + 1.3, .2, .22)
    slot(k, (-1.3, -.1), (0, -.1), .9, G + 1.3, .2, .22)
    pool(k, .9, -1.05, G, .9, .7, .1, .05)
    lotus(k, .9, -1.05, G + .06, .1)
    date_palm(k, -1.2, -1.15, G, 1.1, .4, 7)
    k.puff(1.25, .9, G, .16)
    k.puff(1.25, .3, G, .14)

def dovecote(k):
    k.box("stone", 0, 0, G, 1.4, 1.4, .1, MUD)
    frustum(k, "stone", 0, 0, G + .1, 1.1, 1.1, 1.9, .16, .16, J(MUD_L, .03))
    for z in (.55, .9, 1.25, 1.6):
        for s in (-.25, 0, .25):
            slot(k, (-.55 + .16 * (z / 1.9), -.55 + .16 * (z / 1.9)), (.55 - .16 * (z / 1.9), -.55 + .16 * (z / 1.9)), .55 + s, G + z, .08, .08)
            slot(k, (.55 - .16 * (z / 1.9), -.55 + .16 * (z / 1.9)), (.55 - .16 * (z / 1.9), .55 - .16 * (z / 1.9)), .55 + s, G + z, .08, .08)
    for i in range(4):
        for j in range(4):
            if i in (0, 3) or j in (0, 3):
                k.ball("clay", -.3 + i * .2, -.3 + j * .2, G + 2.0, .1, J(MUD_L, .03), 10, sz=1.3)
    for x, y, z in ((.2, -.35, G + 2.1), (.4, .3, G + 2.12), (-.4, -.1, G + 2.1)):
        k.ball("matte", x, y, z, .07, C("#F4F1EA"), 10, sx=1.4)
    doorway(k, (-.55, -.55), (.55, -.55), .55, .26, .44, G + .1)

def watchtower(k):
    k.box("stone", 0, 0, G, 1.5, 1.5, .12, LIME_L)
    frustum(k, "stone", 0, 0, G + .12, 1.15, 1.15, 1.9, .1, .1, J(LIME_D, .02))
    k.box("stone", 0, 0, G + 2.02, 1.05, 1.05, .1, LIME)
    for s in (-.36, 0, .36):
        for x, y in ((s, -.45), (s, .45), (-.45, s), (.45, s)):
            if (x, y) != (0, 0):
                k.box("stone", x, y, G + 2.12, .18, .18, .18, LIME_L)
    flag(k, .2, .2, G + 2.12, .7, LAPIS, (1, 0))
    doorway(k, (-.57, -.57), (.57, -.57), .57, .3, .5, G + .12)
    slot(k, (.55, -.55), (.55, .55), .55, G + 1.3, .1, .3)
    slot(k, (-.55, -.55), (.55, -.55), .55, G + 1.3, .1, .3)
    k.crate(-.6, -.62, G, .22)

def winery(k):
    k.box("stone", -.7, .7, G, 1.4, 1.4, .8, J(MUD_L, .03))
    cornice(k, -.7, .7, G + .8, 1.4, 1.4, OCHRE)
    doorway(k, (-1.4, 0), (0, 0), .7, .28, .5, G)
    for x in (.2, .8, 1.3):
        for y in (-1.3, -.6, .1):
            k.tube("wood", (x, y, G), (x, y, G + 1.0), .035, .035, WOOD, 8)
    for y in (-1.3, -.6, .1):
        k.beam("wood", (.15, y, G + 1.0), (1.35, y, G + 1.0), .05, .05, WOOD_D)
    for x, y in ((.4, -.9), (1.0, -.9), (.5, -.25), (1.05, -.3), (.8, -1.2)):
        k.ball("leaf", x, y, G + 1.06, .22, J(C("#4FA63A"), .06), 12, sz=.4)
        for i in range(3):
            k.ball("matte", x + .1 * math.cos(i * 2), y + .1 * math.sin(i * 2), G + .92, .05, C("#6B2E6E"), 8)
    k.box("stone", -.6, -.75, G, .8, .6, .3, LIME)
    k.box("water", -.6, -.75, G + .24, .66, .46, .04, C("#7A1F3D"))
    for x, y in ((-1.2, -1.2), (-.2, -1.25), (-1.25, -.4)):
        jar(k, x, y, G, .11, band=GOLD)

def bastet_shrine(k):
    k.box("stone", 0, 0, G, 2.6, 2.6, .12, LIME_L)
    frustum(k, "stone", -.2, .3, G + .12, 1.5, 1.4, 1.2, .08, .08, J(LIME, .02))
    cornice(k, -.2, .3, G + 1.32, 1.34, 1.24, TEAL)
    doorway(k, (-.95, -.4), (.55, -.4), .75, .34, .7, G + .12)
    relief(k, (.55, -.4), (.55, 1.0), .7, G + .4, .7, .55, (GOLD, INK, GOLD))
    k.box("stone", -.2, -1.0, G + .12, .5, .9, .02, LIME_D)
    for x in (-.65, .25):
        k.box("stone", x, -.85, G + .12, .3, .3, .25, LIME_D)
        seated_cat(k, x, -.85, G + .37, .55)
    k.brazier(.9, -.5, G + .12, .25)
    date_palm(k, .95, .95, G, 1.0, .42, 7)
    k.puff(-1.1, -1.1, G, .14)

def felucca_dock(k):
    k.box("water", .0, -.35, G - .06, 3.9, 1.25, .06, WATER)
    for i in range(12):
        k.box("wood", -1.75 + i * .32, .55, G, .3, .8, .07, J(WOOD_L, .05))
    for x in (-1.7, -.5, .7, 1.7):
        k.tube("wood", (x, .18, G - .06), (x, .18, G + .32), .06, .06, WOOD_D, 8)
    sail_boat(k, .1, -.45, G, 2.6, .7, WOOD)
    k.box("cloth", -.3, -.45, G + .05, .5, .4, .2, OCHRE)
    k.crate(1.35, .6, G + .07, .26)
    k.crate(1.6, .78, G + .07, .2)
    jar(k, -1.5, .7, G + .07, .1, band=TEAL)
    k.path("matte", [(1.7, .18, G + .3), (1.2, -.2, G + .2), (1.05, -.42, G + .25)], .015, LINEN, 4)

def chariot_stable(k):
    k.box("stone", -.3, .6, G, 3.2, 1.2, .9, J(MUD_L, .03))
    cornice(k, -.3, .6, G + .9, 3.2, 1.2, LAPIS)
    for x in (-1.6, -.85, -.1, .65, 1.4):
        column(k, x, -.15, G, .9, .08)
    k.box("stone", -.1, -.05, G + .9, 3.4, .45, .1, LIME_L)
    for s in (.5, 1.25, 2.0, 2.75):
        k.box("matte", -1.9 + s, -.01, G, .5, .02, .6, DOOR)
    k.box("cloth", -.1, -.05, G + 1.0, 3.4, .45, .03, TEAL)
    k.box("wood", .6, -.9, G + .2, .5, .5, .3, GOLD_D)
    k.box("wood", .6, -.9, G + .5, .52, .52, .05, GOLD)
    wheel(k, .6, -1.2, G + .25, .25, "Y")
    wheel(k, .6, -.6, G + .25, .25, "Y")
    k.beam("wood", (.85, -.9, G + .3), (1.8, -.9, G + .45), .05, .05, WOOD_D)
    for x, y in ((-1.4, -1.1), (-1.0, -1.2)):
        k.ball("matte", x, y, G + .1, .18, C("#D9B85A"), 10, sz=.6)

def sculptor_yard(k):
    k.box("stone", -.9, .6, G, 1.8, 1.0, .8, J(WASH, .02))
    cornice(k, -.9, .6, G + .8, 1.8, 1.0, OCHRE)
    doorway(k, (-1.8, .1), (0, .1), 1.2, .3, .55, G)
    k.box("stone", .9, .5, G, .6, .6, .9, LIME_D)
    head(k, .9, .5, G + .9, .5)
    for x in (.45, 1.35):
        for y in (.05, .95):
            k.tube("wood", (x, y, G), (x, y, G + 1.6), .03, .03, WOOD, 6)
    k.beam("wood", (.45, .05, G + 1.3), (1.35, .05, G + 1.3), .04, .04, WOOD_D)
    k.beam("wood", (.45, .05, G + .7), (1.35, .05, G + .7), .04, .04, WOOD_D)
    k.box("stone", -.5, -.6, G, .7, .5, .5, J(LIME_L, .02))
    k.box("stone", .3, -.75, G, .5, .5, .4, J(LIME, .02))
    k.box("stone", .3, -.75, G + .4, .3, .32, .3, J(LIME, .02))
    k.ball("stone", .3, -.75, G + .82, .14, LIME, 12)
    for x, y in ((-1.4, -.8), (1.4, -.9), (1.0, -.5)):
        k.box("stone", x, y, G, .22, .22, .16, LIME_L, x)
    k.beam("wood", (-1.0, -1.1, G + .03), (-.7, -1.2, G + .03), .04, .04, WOOD_L)

def pharaoh_garden(k):
    k.box("stone", 0, .5, G, 3.6, 2.6, .3, LIME_L)
    k.box("stone", 0, .9, G + .3, 3.6, 1.8, .3, LIME)
    for z, y in ((0, -.8), (.3, 0)):
        k.box("glaze", 0, y - .02, G + z + .26, 3.62, .04, .05, TEAL)
    pool(k, .0, -1.15, G, 2.4, 1.2, .14, .06)
    for x in (-.7, 0, .7):
        pad(k, x, -1.15, G + .07, .16)
        lotus(k, x + .08, -1.1, G + .08, .12)
    k.box("stone", 0, 1.25, G + .6, .9, .9, .1, LIME_L)
    for x in (-.35, .35):
        for y in (.9, 1.6):
            column(k, x, y, G + .7, .85, .07)
    k.box("cloth", 0, 1.25, G + 1.55, 1.0, 1.0, .05, LAPIS)
    cornice(k, 0, 1.25, G + 1.6, .9, .9, GOLD)
    for x in (-1.5, 1.5):
        date_palm(k, x, 1.3, G + .6, 1.1, .38, 7)
        k.puff(x, .3, G + .3, .2)
    for i in range(6):
        x = -1.5 + i * .6
        k.blob(x, -.25, G + .38, .1)
        bloom(k, x, -.25, G + .46, .09, (PINK, C("#FFD93B"), LAPIS_L)[i % 3])
    stair(k, 0, .1, G + .3, .6, 2, .15, .12)


# ------------------------------------------------------------------ trees

def date_palm_1(k): date_palm(k, 0, 0, 0, .95, .44, 7)
def doum_palm(k):
    k.tube("wood", (0, 0, 0), (0, 0, .45), .08, .07, C("#8C6A44"), 10)
    for s in (-1, 1):
        top = (s * .2, s * .05, .82)
        k.tube("wood", (0, 0, .45), top, .06, .05, C("#8C6A44"), 10)
        for i in range(8):
            a = 2 * math.pi * i / 8
            blade(k, top, (math.cos(a), math.sin(a)), .26, .1, rise=.7, droop=1.2)
def cypress_t(k):
    k.tube("wood", (0, 0, 0), (0, 0, .2), .08, .07, WOOD, 10)
    prof = [(.001, 0), (.2, .02), (.26, .24), (.2, .62), (.09, 1.05), (.001, 1.28)]
    k.lathe("leaf", 0, 0, .14, prof, lambda h: tuple(c * (.55 + .5 * h / 1.2) for c in C("#3B7F3A")), 16)
def acacia(k):
    k.tube("wood", (0, 0, 0), (0, 0, .4), .06, .05, C("#7D6040"), 8)
    for a in (0, 2.1, 4.2):
        k.tube("wood", (0, 0, .4), (.22 * math.cos(a), .22 * math.sin(a), .68), .04, .03, C("#7D6040"), 8)
    for x, y in ((0, 0), (.18, .12), (-.16, .14), (.05, -.2)):
        k.ball("leaf", x, y, .74, .3, J(C("#6FA83A"), .06), 14, sz=.28)
def fig(k):
    k.tube("wood", (0, 0, 0), (0, 0, .45), .09, .07, C("#8A7656"), 10)
    k.blob(-.12, .08, .62, .24)
    k.blob(.14, -.06, .6, .22)
    k.blob(0, 0, .86, .24)
    for x, y, z in ((-.2, -.18, .6), (.24, -.15, .76), (0, -.24, .86)):
        k.ball("matte", x, y, z, .045, C("#6E3A6E"), 8)
def pomegranate(k):
    k.tube("wood", (0, 0, 0), (0, 0, .4), .07, .05, WOOD, 10)
    k.blob(-.1, .05, .58, .22)
    k.blob(.12, -.05, .56, .2)
    k.blob(0, 0, .78, .22)
    for x, y, z in ((-.22, -.16, .5), (.2, -.2, .62), (0, -.24, .78), (.26, .06, .5), (-.08, -.12, .92)):
        k.ball("matte", x, y, z, .055, C("#C8232E"), 10)
def olive(k):
    k.path("wood", [(0, 0, 0), (.06, .02, .22), (-.04, 0, .42), (.02, 0, .55)], .07, C("#7A6A55"), 10)
    for x, y, z, r in ((-.16, .06, .62, .2), (.16, -.04, .6, .2), (0, .0, .82, .22)):
        k.ball("leaf", x, y, z, r, J(C("#94AE6A"), .05), 14, sz=.85)
    for x, y, z in ((-.24, -.12, .58), (.2, -.2, .64), (-.02, -.2, .8)):
        k.ball("matte", x, y, z, .03, C("#3E3A2A"), 6)
def palm_grove(k):
    date_palm(k, -.4, .35, 0, 1.25, .5, 7)
    date_palm(k, .4, .3, 0, 1.0, .46, 7, dates=False)
    date_palm(k, 0, -.42, 0, .8, .42, 6)
    k.puff(.55, -.55, 0, .14)
def twin_palms(k):
    date_palm(k, -.3, .25, 0, 1.3, .6, 7)
    date_palm(k, .34, -.25, 0, .9, .54, 7, dates=False)
    k.puff(.3, .45, 0, .16)
def sycamore(k):
    k.lathe("wood", 0, 0, 0, [(.24, 0), (.15, .12), (.13, .55)], C("#8A7656"), 14)
    for x, y, z, r in ((-.32, .1, .82, .44), (.32, -.08, .78, .42), (.0, .3, .9, .4), (0, -.04, 1.16, .48)):
        k.blob(x, y, z, r)
    for x, y, z in ((-.4, -.3, .72), (.36, -.38, .7), (.0, -.42, .96), (.55, .1, .72)):
        k.ball("matte", x, y, z, .05, C("#C9A34A"), 8)
def tamarisk(k):
    k.path("wood", [(0, 0, 0), (.05, 0, .3), (-.03, 0, .55)], .1, C("#7D6A58"), 10)
    for i in range(7):
        a = 2 * math.pi * i / 7
        x, y = .38 * math.cos(a), .38 * math.sin(a)
        k.tube("wood", (0, 0, .5), (x, y, .78), .035, .025, C("#7D6A58"), 6)
        k.ball("leaf", x, y, .86, .26, J(C("#7FA868"), .06), 12, sz=1.2)
        k.ball("matte", x * 1.05, y * 1.05 - .08, 1.0, .1, PINK, 10, sz=.8)
    k.ball("leaf", 0, 0, 1.08, .32, J(C("#7FA868"), .06), 12, sz=1.1)
    k.ball("matte", 0, -.12, 1.3, .12, PINK, 10, sz=.8)


# ------------------------------------------------------------------ shrubs

def shrub(k): k.puff(0, 0, 0, .28)
def papyrus(k, x=0., y=0., z=0., s=1.):
    for i in range(9):
        a, d = i * 2.4, (.04 + .2 * math.sqrt(i / 9)) * s
        px, py, h = x + d * math.cos(a), y + d * math.sin(a), R.uniform(.55, .9) * s
        tx, ty = px + (px - x) * .4, py + (py - y) * .4
        k.tube("leaf", (px, py, z), (tx, ty, z + h), .018, .014, C("#5E9E35"), 6)
        k.lathe("leaf", tx, ty, z + h, [(.001, 0), (.12 * s, .07 * s), (.13 * s, .09 * s)], J(PAPY, .05), 10)
def aloe(k):
    for i in range(9):
        a = 2 * math.pi * i / 9
        blade(k, (0, 0, .02), (math.cos(a), math.sin(a)), .36, .07, rise=2.0 - .4 * (i % 3), droop=1.4, col=J(C("#6FA58A"), .05))
    k.tube("leaf", (0, 0, 0), (0, 0, .7), .015, .012, C("#6FA58A"), 6)
    k.ball("matte", 0, 0, .74, .05, C("#F28C1E"), 8, sz=2)
def oleander(k):
    k.puff(0, 0, 0, .28)
    for x, y, z in ((-.28, -.14, .36), (.1, -.3, .3), (.28, -.05, .42), (-.05, -.15, .58), (.02, .1, .66)):
        bloom(k, x, y, z, .075, PINK)
def henna(k):
    k.puff(0, 0, 0, .26)
    for x, y, z in ((-.3, -.1, .3), (-.14, -.3, .24), (.12, -.3, .34), (.32, -.1, .3), (.1, -.14, .56), (-.15, -.16, .52)):
        bloom(k, x, y, z, .06, C("#FFF6E8"), C("#F7D27A"))
def reeds(k):
    for i in range(10):
        a, d = i * 2.4, .06 + .28 * math.sqrt(i / 10)
        x, y = d * math.cos(a), d * math.sin(a)
        h = R.uniform(.5, .85)
        k.tube("leaf", (x, y, 0), (x + x * .2, y + y * .2, h), .022, .012, J(R.choice(LEAVES), .04), 6)
        if i % 3 == 0:
            k.tube("matte", (x + x * .2, y + y * .2, h), (x + x * .2, y + y * .2, h + .16), .035, .035, C("#C9A060"), 8)
def potted_tree(k):
    k.lathe("clay", 0, 0, 0, [(.13, 0), (.2, .22), (.22, .28), (.17, .28)], POT, 16)
    k.lathe("glaze", 0, 0, .14, [(.18, 0), (.2, .06)], LAPIS, 16)
    k.tube("wood", (0, 0, .24), (0, 0, .5), .025, .025, WOOD, 8)
    k.blob(0, 0, .68, .27)
def hedge(k):
    k.box("hedge", 0, 0, 0, .86, .86, .5, J(C("#4FA544"), .04))
    for x, y in ((-.2, -.43), (.25, -.43), (.43, -.1), (.43, .25)):
        bloom(k, x, y, .36, .05, C("#FFF6E8"))


# ------------------------------------------------------------------ flowers

def blue_lotus(k):
    k.lathe("clay", 0, 0, 0, [(.26, 0), (.34, .12), (.36, .16), (.3, .16), (.3, .06)], J(LIME, .02), 18)
    k.lathe("water", 0, 0, .06, [(.31, 0), (.31, .08)], WATER, 18)
    for x, y, r in ((-.1, .06, .12), (.12, -.08, .1), (.08, .14, .09)):
        pad(k, x, y, .145, r)
    lotus(k, -.08, -.1, .15, .14, LAPIS_L)
    lotus(k, .12, .1, .15, .12, LAPIS_L)
def poppies(k):
    low_leaves(k)
    petals(k, ((-.16, -.1, .3), (.14, -.12, .36), (.02, .12, .44), (.2, .16, .26)), .09, C("#E0312A"), INK)
def chamomile(k):
    low_leaves(k)
    petals(k, ((-.22, -.14, .22), (.16, -.2, .26), (.24, .1, .3), (-.1, .16, .34), (.0, -.02, .4)), .08, C("#FFF8EC"), C("#F4C430"))
def cornflowers(k):
    low_leaves(k, 6, .26)
    petals(k, ((-.16, -.1, .36), (.14, -.14, .42), (.18, .12, .5), (-.1, .16, .46)), .08, C("#4E7BE8"), C("#2C3E8E"))
def flower_box(k):
    k.box("stone", 0, 0, 0, .74, .46, .24, LIME_L)
    k.box("glaze", 0, -.235, .07, .6, .02, .08, LAPIS)
    k.box("matte", 0, 0, .22, .64, .36, .03, C("#5A3A20"))
    for x, y, c in ((-.22, -.08, PINK), (0, -.08, C("#FFD93B")), (.22, -.08, PINK), (-.12, .08, C("#FFF0E0")), (.12, .08, C("#E0312A"))):
        k.blob(x, y, .3, .06)
        bloom(k, x, y, .36, .08, c)
def irises(k):
    for i in range(8):
        a = 2 * math.pi * i / 8
        blade(k, (0, 0, .02), (math.cos(a), math.sin(a)), .32, .05, rise=2.4, droop=1.6, col=J(C("#4FA05A"), .05))
    for x, y, h in ((-.12, -.08, .5), (.12, -.1, .44), (.04, .12, .56)):
        k.tube("leaf", (x, y, 0), (x, y, h), .014, .014, C("#3F8F2F"), 5)
        k.lathe("matte", x, y, h, [(.02, 0), (.1, .06), (.04, .14), (.001, .18)], C("#7B4FC8"), 8)
        k.ball("matte", x, y - .03, h + .04, .03, C("#FFD24A"), 6)
def flower_bed(k):
    k.box("matte", 0, 0, 0, 1.8, 1.8, .06, C("#5A3A20"))
    for s in (-1, 1):
        k.box("stone", 0, s * .92, 0, 1.96, .16, .16, LIME_L)
        k.box("stone", s * .92, 0, 0, .16, 1.7, .16, LIME_L)
    cols = (PINK, C("#FFD93B"), C("#E0312A"), LAPIS_L)
    for j, y in enumerate((-.56, -.18, .2, .58)):
        for i, x in enumerate((-.58, -.2, .2, .58)):
            k.blob(x, y, .12, .13)
            bloom(k, x, y, .24, .11, cols[(i + j) % 4])
def pattern_bed(k):
    k.box("stone", 0, 0, 0, 1.9, 1.9, .1, LIME_L)
    k.box("matte", 0, 0, .1, 1.7, 1.7, .03, C("#5A3A20"))
    for i in range(5):
        for j in range(5):
            x, y = -.68 + i * .34, -.68 + j * .34
            if (i + j) % 2 == 0:
                k.blob(x, y, .2, .1)
                bloom(k, x, y, .28, .09, (C("#E0312A"), C("#FFD93B"), LAPIS_L)[(i * j) % 3])
            else:
                k.box("hedge", x, y, .13, .2, .2, .14, J(C("#4FA544"), .04))
    k.lathe("stone", 0, 0, .13, [(.12, 0), (.1, .3)], LIME, 12)
    k.ball("gold", 0, 0, .48, .08, GOLD, 10)


# ------------------------------------------------------------------ statues

def broken_column(k):
    k.box("stone", 0, 0, 0, .5, .5, .1, LIME_L)
    k.lathe("stone", 0, .08, .1, [(.16, 0), (.14, .55), (.12, .6), (.15, .64)], J(LIME, .02), 14)
    k.lathe("glaze", 0, .08, .4, [(.145, 0), (.145, .05)], TEAL, 14)
    k.lathe("stone", .1, -.25, 0, [(.13, -.18), (.13, .18)], LIME, 14, m=Matrix.Rotation(math.pi / 2, 4, "Y") @ Matrix.Rotation(.3, 4, "X"))
    k.blob(-.28, -.24, .06, .07)
def pharaoh_head(k):
    k.box("stone", 0, 0, 0, .56, .56, .12, LIME_D)
    head(k, 0, 0, .3, .52, face_dir=(1, 0))
def bastet_cat(k):
    k.box("stone", 0, 0, 0, .44, .44, .2, LIME_L)
    k.box("glaze", 0, 0, .1, .48, .48, .05, TEAL)
    seated_cat(k, 0, 0, .24, .7)
def obelisk_1(k):
    k.box("stone", 0, 0, 0, .44, .44, .14, LIME_L)
    obelisk(k, 0, 0, .14, .22, 1.25)
def sundial(k):
    k.lathe("stone", 0, 0, 0, [(.24, 0), (.24, .08), (.12, .14), (.1, .42), (.26, .48), (.26, .54)], LIME_L, 18)
    k.lathe("gold", 0, 0, .54, [(.24, 0), (.24, .02)], GOLD, 18)
    k.prism("gold", [(-.02, .56), (.02, .56), (.0, .76)], -.18, .1, GOLD_D)
    for i in range(8):
        a = math.pi * i / 4
        k.box("glaze", .18 * math.cos(a), .18 * math.sin(a), .56, .03, .03, .01, LAPIS)
def scribe_statue(k):
    k.box("stone", 0, 0, 0, .5, .5, .16, LIME_L)
    k.box("matte", 0, 0, .16, .36, .4, .12, LINEN)
    k.ball("matte", -.02, 0, .4, .14, SKIN, 12, sx=.8, sz=1.4)
    k.ball("matte", .02, 0, .68, .1, SKIN, 12)
    k.ball("matte", -.01, 0, .74, .1, INK, 10, sz=.6)
    k.box("matte", .14, 0, .28, .06, .24, .03, LINEN)
    for side in (-1, 1):
        k.tube("matte", (0, side * .12, .48), (.13, side * .06, .3), .035, .03, SKIN, 6)
    k.ball("matte", .1, -.05, .7, .02, INK, 6)
def golden_scarab(k):
    k.box("stone", 0, 0, 0, .5, .5, .18, LIME_L)
    k.box("glaze", 0, 0, .09, .54, .54, .05, LAPIS)
    k.ball("gold", -.03, 0, .32, .17, GOLD, 16, sx=1.25, sz=.7)
    k.ball("gold", .17, 0, .3, .08, GOLD, 10, sz=.7)
    k.beam("glaze", (-.2, 0, .43), (.12, 0, .43), .02, .02, LAPIS)
    for s in (-1, 1):
        for dx in (-.1, .05):
            k.tube("gold", (dx, s * .12, .28), (dx + .03, s * .2, .22), .015, .015, GOLD_D, 6)
    k.ball("gold", .05, 0, .62, .12, C("#F06A2A"), 14, sx=.2)
def colossus(k):
    k.box("stone", 0, 0, 0, 1.4, 1.2, .25, LIME_D)
    k.box("glaze", 0, 0, .14, 1.44, 1.24, .06, TEAL)
    k.box("stone", -.25, 0, .29, .7, .8, .9, J(LIME, .02))
    k.box("stone", .15, 0, .29, .5, .6, .45, J(LIME, .02))
    for side in (-1, 1):
        k.box("stone", .3, side * .16, .29, .3, .2, .45, LIME)
    k.ball("stone", -.12, 0, .9, .26, LIME, 14, sy=1.3, sz=1.5)
    head(k, -.1, 0, 1.35, .4)
    relief(k, (-.6, -.4), (.1, -.4), .35, .4, .5, .45)
def anubis(k):
    k.box("wood", 0, 0, 0, 1.6, .9, .45, GOLD_D)
    for i in range(3):
        k.box("glaze", -.5 + i * .5, -.455, .1, .34, .02, .24, LAPIS)
        k.box("glaze", .805, -.25 + i * .25, .1, .02, .16, .24, LAPIS)
    k.box("gold", 0, 0, .45, 1.6, .9, .05, GOLD)
    z = .5
    k.ball("matte", -.2, 0, z, .2, INK, 14, sx=2.2, sz=.9)
    for side in (-1, 1):
        k.box("matte", .2, side * .1, z, .55, .1, .08, INK)
    k.ball("matte", .25, 0, z + .32, .13, INK, 12, sz=1.2)
    k.lathe("matte", .4, 0, z + .32, [(.07, 0), (.03, .16)], INK, 8, m=Matrix.Rotation(math.pi / 2, 4, "Y"))
    for side in (-1, 1):
        k.lathe("matte", .22, side * .07, z + .44, [(.05, 0), (.001, .2)], INK, 6)
    k.lathe("gold", .2, 0, z + .14, [(.11, 0), (.11, .05)], GOLD, 12)
    k.path("matte", [(-.62, 0, z + .04), (-.8, .1, z + .02)], .04, INK, 6)


# ------------------------------------------------------------------ water

def birdbath(k):
    k.lathe("stone", 0, 0, 0, [(.2, 0), (.2, .06), (.08, .12), (.07, .4), (.3, .5), (.32, .56), (.27, .56), (.27, .5)], LIME_L, 18)
    k.lathe("water", 0, 0, .5, [(.27, 0), (.27, .03)], WATER, 18)
    k.box("glaze", 0, 0, .44, .02, .02, .02, LAPIS)
    k.ball("matte", .12, -.1, .62, .06, C("#F4F1EA"), 10, sx=1.4)
def small_fountain(k):
    k.lathe("stone", 0, 0, 0, [(.42, 0), (.42, .16), (.36, .16), (.36, .06)], LIME_L, 22)
    k.lathe("water", 0, 0, .06, [(.37, 0), (.37, .07)], WATER, 22)
    k.lathe("stone", 0, 0, .1, [(.08, 0), (.07, .45), (.2, .5), (.2, .56), (.17, .56), (.17, .5)], LIME, 16)
    k.lathe("water", 0, 0, .6, [(.17, 0), (.17, .03)], WATER, 16)
    k.lathe("water", 0, 0, .63, [(.03, 0), (.02, .16)], WATER_L, 8)
    lotus(k, 0, 0, .74, .08, LAPIS_L)
def lotus_pond(k):
    k.lathe("stone", 0, 0, 0, [(.9, 0), (.9, .1), (.8, .1), (.8, .02)], LIME_L, 28)
    k.lathe("water", 0, 0, .02, [(.82, 0), (.82, .06)], WATER, 28)
    for x, y, r in ((-.3, .2, .18), (.3, -.3, .16), (.4, .35, .14), (-.35, -.35, .13), (0, -.05, .12)):
        pad(k, x, y, .085, r)
    for x, y, c in ((-.28, .2, PINK), (.3, -.28, C("#FFF6E8")), (.02, -.04, LAPIS_L)):
        lotus(k, x, y, .1, .13, c)
    papyrus(k, .62, .62, 0, .6)
def ibis_pond(k):
    k.lathe("stone", 0, 0, 0, [(.92, 0), (.92, .08), (.84, .08), (.84, .02)], LIME_L, 28)
    k.lathe("water", 0, 0, .02, [(.85, 0), (.85, .05)], WATER, 28)
    for x, y in ((-.2, -.1), (.35, .2)):
        ibis_bird(k, x, y, .06, .9)
    for x, y in ((.6, -.5), (-.55, .5)):
        pad(k, x, y, .075, .14)
    reeds_at(k, -.6, -.55)
def ibis_bird(k, x, y, z, s=1.):
    for side in (-1, 1):
        k.tube("matte", (x, y + side * .04 * s, z), (x, y + side * .03 * s, z + .3 * s), .012 * s, .012 * s, INK, 5)
    k.ball("matte", x - .02 * s, y, z + .38 * s, .12 * s, C("#F4F1EA"), 12, sx=1.5, sz=.8)
    k.ball("matte", x - .14 * s, y, z + .4 * s, .06 * s, INK, 8, sx=1.4, sz=.7)
    k.path("matte", [(x + .08 * s, y, z + .42 * s), (x + .14 * s, y, z + .56 * s), (x + .17 * s, y, z + .6 * s)], .025 * s, INK, 6)
    k.path("matte", [(x + .17 * s, y, z + .6 * s), (x + .27 * s, y, z + .52 * s), (x + .32 * s, y, z + .42 * s)], .012 * s, INK, 5)
def reeds_at(k, x, y):
    for i in range(6):
        a, d = i * 2.4, .03 + .12 * math.sqrt(i / 6)
        px, py = x + d * math.cos(a), y + d * math.sin(a)
        k.tube("leaf", (px, py, 0), (px, py, R.uniform(.4, .6)), .018, .01, J(R.choice(LEAVES), .04), 6)
def shaduf(k):
    k.lathe("stone", -.3, .3, 0, [(.55, 0), (.55, .14), (.47, .14), (.47, .04)], LIME_L, 24)
    k.lathe("water", -.3, .3, .04, [(.48, 0), (.48, .07)], WATER, 24)
    for y in (-.25, .05):
        k.tube("wood", (.45, y - .2, 0), (.45, y, 1.0), .04, .04, WOOD, 8)
    k.tube("wood", (.45, -.25, 1.0), (.45, .1, 1.0), .03, .03, WOOD_D, 8)
    k.beam("wood", (.8, -.12, .55), (-.25, -.12, 1.4), .05, .05, WOOD_L)
    k.ball("clay", .82, -.12, .48, .14, C("#8A6A44"), 10)
    k.path("matte", [(-.25, -.12, 1.4), (-.25, -.12, .55)], .01, LINEN, 4)
    k.lathe("clay", -.25, -.12, .38, [(.06, 0), (.1, .1), (.07, .18)], POT, 12)
    jar(k, .7, .6, 0, .12, band=LAPIS)
    k.puff(-.7, -.7, 0, .14)


# ------------------------------------------------------------------ garden furniture

def bench(k):
    for x in (-.3, .3):
        k.box("stone", x, 0, 0, .12, .34, .26, LIME_D)
    k.box("stone", 0, 0, .26, .8, .38, .08, LIME_L)
    k.box("cloth", 0, 0, .34, .6, .3, .05, LAPIS)
    k.box("cloth", -.2, 0, .39, .14, .2, .06, OCHRE)
def lamp_post(k):
    k.box("stone", 0, 0, 0, .3, .3, .12, LIME_L)
    column(k, 0, 0, .12, .8, .06)
    k.lathe("gold", 0, 0, .98, [(.04, 0), (.12, .06), (.1, .1)], GOLD, 14)
    k.flame(0, 0, 1.06, .07, 1.5)
def torch(k):
    k.tube("wood", (0, 0, 0), (0, 0, .85), .035, .045, WOOD, 8)
    for z in (.3, .55):
        k.lathe("gold", 0, 0, z, [(.05, 0), (.05, .03)], GOLD, 10)
    k.lathe("matte", 0, 0, .85, [(.05, 0), (.1, .1), (.1, .14)], C("#7B5A33"), 10)
    k.flame(0, 0, .96, .09, 1.6)
def signpost(k):
    k.tube("wood", (0, 0, 0), (0, 0, .9), .04, .04, WOOD, 8)
    k.box("wood", .12, 0, .62, .34, .04, .14, WOOD_L, -.2)
    k.box("wood", -.06, -.1, .4, .04, .3, .12, WOOD_L)
    k.box("glaze", .12, -.025, .66, .22, .01, .05, LAPIS, -.2)
    k.ball("gold", 0, 0, .92, .05, GOLD, 10)
def standard(k):
    k.box("stone", 0, 0, 0, .3, .3, .14, LIME_L)
    k.tube("wood", (0, 0, .14), (0, 0, 1.15), .03, .03, GOLD_D, 8)
    k.lathe("gold", 0, 0, 1.15, [(.12, 0), (.12, .02)], GOLD, 14, m=Matrix.Rotation(math.pi / 2, 4, "X"))
    k.ball("gold", 0, 0, 1.28, .1, GOLD, 14, sy=.25)
    for i, c in enumerate((LAPIS, OCHRE, TEAL)):
        k.box("cloth", 0, -.03 - i * .02, .7 - i * .05, .05, .03, .35, c)
def grain_mill(k):
    k.box("stone", 0, 0, 0, .6, .4, .18, LIME_D)
    frustum(k, "stone", 0, 0, .18, .5, .34, .1, .03, .03, LIME)
    k.ball("stone", .02, 0, .32, .1, LIME_L, 12, sx=1.8, sz=.6)
    k.lathe("matte", 0, -.32, 0, [(.13, 0), (.16, .16), (.14, .18)], BASKET, 14)
    k.lathe("matte", 0, -.32, .14, [(.13, 0), (.13, .02)], C("#E8D6A4"), 14)
def feast_mat(k):
    k.box("cloth", 0, 0, 0, 1.6, 1.3, .02, OCHRE)
    k.box("cloth", 0, 0, .02, 1.36, 1.06, .01, GOLD)
    k.box("cloth", 0, 0, .03, 1.24, .94, .01, OCHRE)
    k.box("wood", 0, 0, .04, .7, .5, .18, WOOD_L)
    for x, y, c in ((-.2, -.1, C("#D9402E")), (.2, .1, C("#7DBB33")), (0, .12, C("#E9C32E"))):
        k.lathe("clay", x, y, .22, [(.07, 0), (.12, .06), (.13, .08)], POT, 12)
        k.ball("matte", x, y, .32, .06, c, 10)
    k.basket(.55, -.4, .03, .14)
    jar(k, -.6, .4, .03, .1, band=LAPIS)
    for x, y in ((-.62, -.4), (.6, .42)):
        k.ball("cloth", x, y, .1, .14, LAPIS, 10, sx=1.3, sz=.5)
def shade_canopy(k):
    for x in (-.7, .7):
        for y in (-.7, .7):
            k.tube("wood", (x, y, 0), (x, y, 1.0), .035, .035, GOLD_D, 8)
            k.ball("gold", x, y, 1.02, .05, GOLD, 8)
    k.awning(-.78, .78, -.78, .78, .92, 1.02, (LINEN, LAPIS), 6, .1)
    k.box("cloth", 0, 0, 0, 1.2, 1.2, .1, LINEN)
    for x, y, c in ((-.35, .3, OCHRE), (.3, .32, TEAL), (-.3, -.3, LAPIS)):
        k.ball("cloth", x, y, .18, .17, c, 12, sx=1.2, sz=.55)
    k.box("wood", .25, -.25, .1, .3, .3, .12, WOOD_L)
    jar(k, .25, -.25, .22, .05, band=GOLD)
def vine_pergola(k):
    for x in (-.65, .65):
        for y in (-.65, .65):
            column(k, x, y, 0, 1.0, .06)
    for y in (-.65, .65):
        k.beam("wood", (-.85, y, 1.02), (.85, y, 1.02), .06, .06, WOOD)
    for x in (-.4, -.1, .2, .5):
        k.beam("wood", (x, -.85, 1.1), (x, .85, 1.1), .04, .05, WOOD_L)
    for x, y in ((-.5, -.5), (.3, -.55), (-.2, .3), (.5, .4), (0, -.1)):
        k.ball("leaf", x, y, 1.16, .26, J(C("#4FA63A"), .06), 12, sz=.4)
    for x, y in ((-.55, -.65), (.35, -.7), (.62, -.2), (.62, .3)):
        for i in range(3):
            k.ball("matte", x + .04 * (i - 1), y, .98 - i * .06, .045, C("#6B2E6E"), 8)
    k.box("stone", 0, 0, 0, .7, .3, .3, LIME_L)
def palanquin(k):
    for s in (-1, 1):
        k.beam("wood", (-.85, s * .42, .38), (.85, s * .42, .38), .06, .06, GOLD_D)
    k.box("wood", 0, 0, .3, .9, .7, .3, GOLD)
    k.box("glaze", 0, -.351, .36, .7, .01, .14, LAPIS)
    for x in (-.4, .4):
        for y in (-.3, .3):
            k.tube("gold", (x, y, .6), (x, y, 1.1), .025, .025, GOLD, 6)
    k.box("cloth", 0, 0, 1.1, 1.0, .8, .05, LAPIS)
    cornice(k, 0, 0, 1.15, .9, .7, GOLD)
    k.ball("cloth", 0, 0, .66, .2, OCHRE, 12, sx=1.6, sz=.4)
    for x in (-.4, .4):
        for y in (-.3, .3):
            k.box("wood", x, y, 0, .08, .08, .3, WOOD_D)
def kiosk(k):
    k.box("stone", 0, 0, 0, 1.6, 1.6, .14, LIME_L)
    for x in (-.6, -.2, .2, .6):
        for y in (-.6, .6):
            column(k, x, y, .14, 1.0, .07)
    for y in (-.2, .2):
        for x in (-.6, .6):
            column(k, x, y, .14, 1.0, .07)
    k.box("stone", 0, 0, 1.14, 1.5, 1.5, .1, LIME)
    cornice(k, 0, 0, 1.24, 1.4, 1.4, TEAL)
    k.box("glaze", 0, 0, .14, .5, .5, .3, LAPIS)
    k.box("gold", 0, 0, .44, .56, .56, .04, GOLD)


# ------------------------------------------------------------------ supplies

def crates(k):
    k.crate(-.12, .08, 0, .4)
    k.crate(.2, -.18, 0, .3)
    k.crate(-.08, .06, .44, .28)
def amphorae(k):
    jar(k, -.15, .12, 0, .16, band=LAPIS)
    jar(k, .18, -.08, 0, .14, band=TEAL)
    jar(k, -.1, -.25, 0, .12)
def campfire(k):
    for i in range(8):
        a = 2 * math.pi * i / 8
        rock(k, .28 * math.cos(a), .28 * math.sin(a), 0, .09, J(LIME_D, .06), .7)
    for a in (0, 2.1, 4.2):
        k.beam("wood", (.18 * math.cos(a), .18 * math.sin(a), .02), (0, 0, .2), .06, .06, WOOD)
    k.flame(0, 0, .1, .14, 2.5)
def scribe_desk(k):
    k.box("wood", 0, 0, 0, .5, .4, .4, WOOD)
    k.box("wood", 0, 0, .4, .56, .46, .05, WOOD_L)
    k.box("cloth", 0, 0, .45, .4, .3, .01, LINEN)
    k.tube("cloth", (-.2, .12, .48), (.2, .12, .48), .04, .04, LINEN, 10)
    k.box("matte", .14, -.08, .46, .12, .05, .02, INK)
    k.box("matte", .1, -.08, .48, .02, .02, .02, OCHRE)
    k.tube("matte", (-.1, -.1, .46), (.08, -.04, .5), .008, .008, C("#D0B070"), 4)
def grain_baskets(k):
    for x, y, r in ((-.15, .1, .18), (.18, -.08, .15), (-.1, -.25, .12)):
        k.lathe("matte", x, y, 0, [(r * .7, 0), (r, r * .9), (r, r * 1.3)], J(BASKET, .05), 14)
        k.ball("matte", x, y, r * 1.25, r * .9, C("#E3C77A"), 12, sz=.4)
def treasure_chest(k):
    k.box("wood", 0, 0, 0, .56, .38, .3, GOLD_D)
    k.box("wood", 0, 0, .3, .6, .42, .06, GOLD)
    k.box("glaze", 0, -.195, .08, .4, .02, .16, LAPIS)
    k.ball("gold", 0, -.21, .16, .05, GOLD, 10)
    k.prism("wood", [(-.19, .36), (.19, .36), (0, .48)], -.28, .28, GOLD_D)
    for x, y in ((.36, -.2), (.3, -.32), (.42, -.06)):
        k.lathe("gold", x, y, 0, [(.05, 0), (.05, .02)], GOLD, 12)
def tent(k):
    ex, ey, rz = .66, .7, 1.05
    k.prism("cloth", [(-ey, 0), (ey, 0), (0, rz)], -ex, ex, LINEN)
    a, b, c, d = Vector((-ex, -ey, 0)), Vector((ex, -ey, 0)), Vector((ex, 0, rz)), Vector((-ex, 0, rz))
    lift = (b - a).cross(d - a).normalized() * .012
    for t0, t1, col in ((0, .18, OCHRE), (.42, .52, LAPIS)):
        k.poly("cloth", [tuple(a.lerp(d, t0) + lift), tuple(b.lerp(c, t0) + lift), tuple(b.lerp(c, t1) + lift), tuple(a.lerp(d, t1) + lift)], col)
    door = [(-.3, 0), (.3, 0), (0, .7)]
    k.poly("glow", [(ex + .012, y, z) for y, z in door], C("#C47A28"))
    for x in (-ex - .05, ex + .06):
        k.tube("wood", (x, 0, 0), (x, 0, rz + .12), .04, .04, WOOD, 10)
        k.ball("gold", x, 0, rz + .16, .07, GOLD, 12)
    k.tube("wood", (-ex, 0, rz + .02), (ex, 0, rz + .02), .04, .04, WOOD, 10)
    k.box("cloth", .84, 0, 0, .24, .55, .02, OCHRE)
    jar(k, .8, -.75, 0, .09, band=LAPIS)
def dig_site(k):
    k.box("matte", 0, 0, 0, 1.4, 1.4, .02, C("#C9A26A"))
    k.box("matte", -.1, .1, -.01, 1.0, .9, .04, C("#9C7A4C"))
    for i in range(4):
        k.box("stone", -.4 + i * .25, .1, .03, .2, .5, .06 + (i % 2) * .04, LIME)
    k.lathe("stone", .2, .35, .02, [(.1, -.12), (.1, .12)], LIME, 12, m=Matrix.Rotation(math.pi / 2, 4, "X"))
    for x in (-.65, .65):
        for y in (-.65, .65):
            k.tube("wood", (x, y, 0), (x, y, .3), .025, .025, WOOD, 6)
    for y in (-.65, .65):
        k.path("matte", [(-.65, y, .26), (.65, y, .26)], .01, LINEN, 4)
    for x in (-.65, .65):
        k.path("matte", [(x, -.65, .26), (x, .65, .26)], .01, LINEN, 4)
    k.beam("wood", (.5, -.4, 0), (.8, -.7, .5), .03, .03, WOOD_L)
    k.box("wood", .48, -.38, 0, .12, .04, .14, GREY)
    k.basket(-.55, -.75, 0, .12)
def reed_boat(k):
    def fn(u, v):
        t = (u - .5) * 2
        wid = .38 * (1 - t * t) ** .7
        a = math.pi * v
        return (t * .85, wid * math.cos(a), .25 * t ** 4 + .18 - .16 * math.sin(a) * (1 - t * t) ** .3)
    k.surface("wood", fn, 14, 6, C("#C9A764"))
    for i in range(5):
        x = -.6 + i * .3
        w = .38 * (1 - (x / .85) ** 2) ** .7
        k.beam("matte", (x, -w, .19), (x, w, .19), .03, .03, C("#8C6A3A"))
    for side in (-1, 1):
        k.ball("matte", side * .86, 0, .44, .07, C("#C9A764"), 10, sz=1.4)
    k.beam("wood", (-.2, .5, .02), (.5, -.4, .3), .03, .03, WOOD_D)
    k.box("wood", -.24, .52, 0, .14, .04, .04, WOOD_D)
def cart(k):
    k.box("wood", 0, 0, .28, 1.2, .8, .08, WOOD_L)
    for s in (-1, 1):
        k.box("wood", 0, s * .38, .36, 1.2, .05, .2, WOOD)
    wheel(k, 0, -.48, .28, .28, "Y")
    wheel(k, 0, .48, .28, .28, "Y")
    k.beam("wood", (.6, -.2, .3), (.95, -.2, .12), .04, .04, WOOD_D)
    k.beam("wood", (.6, .2, .3), (.95, .2, .12), .04, .04, WOOD_D)
    for x, y in ((-.3, -.15), (.1, .12), (.3, -.18)):
        jar(k, x, y, .36, .09, band=LAPIS)
    k.basket(-.3, .2, .36, .12)


# ------------------------------------------------------------------ animals

def crocodile(k):
    rock(k, -.05, .12, 0, .3, J(LIME_D, .06), .4)
    c = C("#5E7A3A")
    k.ball("matte", -.05, 0, .14, .14, c, 12, sx=2.0, sz=.6)
    k.ball("matte", .28, -.05, .12, .08, c, 10, sx=2.0, sz=.6)
    k.path("matte", [(-.32, 0, .1), (-.4, .2, .06), (-.3, .36, .04)], .05, c, 6)
    for x, y in ((-.15, -.12), (.12, -.12), (-.15, .12), (.12, .12)):
        k.ball("matte", x, y, .05, .04, c, 8, sz=.6)
    for s in (-1, 1):
        k.ball("matte", .2, s * .05, .2, .025, C("#F2D23A"), 6)
def ibis(k):
    k.box("stone", 0, 0, 0, .3, .3, .06, LIME_L)
    ibis_bird(k, -.05, 0, .06, 1.3)
def falcon(k):
    k.box("stone", 0, 0, 0, .3, .3, .08, LIME_L)
    k.tube("wood", (0, 0, .08), (0, 0, .62), .03, .025, WOOD, 8)
    k.tube("wood", (-.2, 0, .62), (.2, 0, .62), .025, .025, WOOD_L, 8)
    k.ball("matte", 0, 0, .78, .12, C("#8A6A44"), 14, sz=1.3)
    k.ball("matte", .03, 0, .78, .09, C("#E8D6B0"), 10, sz=1.1)
    k.ball("matte", .02, 0, .97, .08, C("#5A4632"), 12)
    k.lathe("gold", .1, 0, .97, [(.025, 0), (.001, .06)], GOLD, 6, m=Matrix.Rotation(math.pi / 2, 4, "Y"))
    for s in (-1, 1):
        k.ball("matte", -.02, s * .1, .76, .06, C("#5A4632"), 10, sz=1.8)
        k.ball("matte", .07, s * .035, .99, .015, INK, 6)
def cat(k):
    k.box("stone", 0, 0, 0, .34, .34, .08, LIME_L)
    seated_cat(k, 0, 0, .08, .55, C("#C9883A"), LAPIS)
def hippo(k):
    c = C("#5E86B8")
    k.ball("matte", -.05, 0, .2, .2, c, 14, sx=1.5, sz=.85)
    k.ball("matte", .25, 0, .25, .13, c, 12, sx=1.2)
    k.ball("matte", .36, 0, .21, .1, c, 10, sx=.8, sz=.8)
    for s in (-1, 1):
        k.ball("matte", .24, s * .08, .36, .03, c, 6)
        k.ball("matte", .32, s * .05, .32, .02, INK, 6)
        for x in (-.2, .1):
            k.tube("matte", (x, s * .12, 0), (x, s * .12, .1), .05, .05, c, 8)
    for x in (-.12, 0, .12):
        bloom(k, x, -.12, .32, .03, C("#2B2420"))


# ------------------------------------------------------------------ rocks

def boulder(k):
    rock(k, -.04, .06, 0, .36, J(C("#D6B07A"), .05))
    rock(k, .24, -.2, 0, .17, J(C("#C99E68"), .05))
    k.blob(-.2, -.14, .08, .09)
def turquoise(k):
    rock(k, 0, .06, 0, .3, J(C("#C99E68"), .05), .55)
    for x, y, h, r, c in ((0, 0, .72, .1, TEAL_L), (.15, -.1, .46, .08, C("#5FD3C0")), (-.15, -.1, .54, .08, TEAL), (.02, -.22, .32, .06, C("#7FE0E5"))):
        k.lathe("water", x, y, .14, [(r, 0), (r * 1.15, h * .7), (.001, h)], c, 6, smooth=False)
    k.lights.append(((.0, -.3, .4), .6))
def desert_rocks(k):
    for x, y, r in ((-.3, .26, .58), (.42, .22, .38), (.1, -.34, .34), (-.56, -.42, .22)):
        rock(k, x, y, 0, r, J(C("#D2A872"), .05))
    for x, y in ((.7, -.7), (-.75, .7)):
        aloe_at(k, x, y)
def aloe_at(k, x, y):
    for i in range(6):
        a = 2 * math.pi * i / 6
        blade(k, (x, y, .02), (math.cos(a), math.sin(a)), .2, .05, rise=2.0, droop=1.4, col=J(C("#6FA58A"), .05))


# Catalogue keys that differ from the builder's name (the helper shares the name).
BUILDERS = {"date_palm": date_palm_1, "cypress": cypress_t, "obelisk": obelisk_1}


# The list of what exists. Types are positions in the game's list and saves store them:
# the five restorations come first, then the catalogue. Append only.
CATALOGUE = [dict(zip(("key", "title", "cat", "w", "h", "gold", "stars", "like"), row))
             for row in json.loads((HERE / "catalogue.json").read_text())]
BASED = ("story", "wonder", "building")   # these stand on a slab; decorations stand on the grass
# One-tile decorations grow to fill their tile, so they read beside the island
# painting: each is scaled about its ground pivot, bevels and lights included, until
# it reaches just inside the tile's edge. It always fits its footprint, so what the
# player sees is what they place. MAX_SCALE keeps slim props from towering over
# the scene. Larger objects stay at their modelled size.
FILL, MAX_SCALE = .48, 2.


def model_scale(it, reach):
    if it["cat"] in BASED or (it["w"], it["h"]) != (1, 1):
        return 1.
    return max(1., min(MAX_SCALE, FILL / reach))


STORY = [dict(it, cat="story") for it in restorations.BUILDINGS]

assemble("NileArchiveBuildings", STORY + CATALOGUE,
         {it["key"]: BUILDERS.get(it["key"]) or globals().get(it["key"]) or getattr(restorations, it["key"]) for it in STORY + CATALOGUE},
         blend_argument(HERE / "nile_archive_buildings.blend"), slab=lambda it: it["cat"] in BASED, slab_color=SLAB, model_scale=model_scale)
