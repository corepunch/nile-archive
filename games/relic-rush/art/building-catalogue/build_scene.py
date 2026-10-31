# Relic Rush's 96 buildings, as procedural Blender geometry on the game's grid.
#
# tools/building_kit.py holds the toolbox and the conventions. Rebuild the master and
# re-render with: python3 tools/buildings.py relic-rush --rebuild
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3] / "tools"))
from building_kit import *


# ------------------------------------------------------------------ buildings
#
# Casual style: few, big, soft shapes. A building reads at a glance from its
# silhouette and two or three colours; nothing smaller than about a tenth of a tile.

def face(a, b, t=.24):
    """A frame on a wall's outer surface: x along it, -y out."""
    return wall_frame(a, b) @ Matrix.Translation((0, -t / 2, 0))

def post(k, x, y, h, s=.22, col=WOOD):
    k.box("wood", x, y, G, s, s, h, col)


def camp(k):
    ex, ey, rz = .62, .74, 1.34
    k.prism("cloth", [(-ey, G), (ey, G), (0, rz)], -ex, ex, CANVAS)
    a, b, c, d = Vector((-ex, -ey, G)), Vector((ex, -ey, G)), Vector((ex, 0, rz)), Vector((-ex, 0, rz))
    nrm = (b - a).cross(d - a).normalized()
    lift = nrm * .012
    k.poly("cloth", [tuple(a + lift), tuple(b + lift), tuple(b.lerp(c, .16) + lift), tuple(a.lerp(d, .16) + lift)], TEAL)
    # a big compass star on the visible slope
    mid, up, side = a.lerp(c, .56) + lift * 1.5, (d - a).normalized(), Vector((1, 0, 0))
    star = []
    for i in range(8):
        t = math.pi * i / 4
        rad = .34 if i % 2 == 0 else .12
        star.append(tuple(mid + side * rad * math.cos(t) + up * rad * math.sin(t)))
    k.poly("gold", star, GOLD)
    # the doorway on +x
    door = [(-.4, G), (.4, G), (0, G + .84)]
    k.poly("glow", [(ex + .012, y, z) for y, z in door], C("#C47A28"))
    for (y0, z0), (y1, z1) in ((door[0], door[2]), (door[1], door[2])):
        k.beam("cloth", (ex + .03, y0, z0), (ex + .03, y1, z1), .12, .05, TEAL)
    # poles and ridge
    for x in (-ex - .05, ex + .06):
        k.tube("wood", (x, 0, G), (x, 0, rz + .12), .05, .05, WOOD, 12)
        k.ball("gold", x, 0, rz + .17, .09, GOLD, 14)
    k.tube("wood", (-ex, 0, rz + .03), (ex, 0, rz + .03), .05, .05, WOOD, 12)
    # rug, crate, shrubs
    k.box("cloth", .84, 0, G, .28, .66, .03, RED)
    k.box("cloth", .84, 0, G + .03, .28, .14, .012, GOLD)
    k.crate(.8, -.76, G, .3)
    k.puff(-.78, -.86, G, .16)
    k.puff(.8, .8, G, .2)
    k.puff(-.8, .8, G, .2)


def well(k):
    k.lathe("stone", 0, 0, G, [(.66, 0), (.66, .5)], SAND_DK, 32)
    k.ring(0, 0, G, G + .52, .72, .28, .26, .64)
    k.ring(0, 0, G + .52, G + .66, .75, .3, .14, .42, col=SAND_PALE)
    k.lathe("water", 0, 0, G + .54, [(.62, 0), (.62, .05)], WATER, 32)
    k.lathe("water", 0, 0, G + .59, [(.26, 0), (.26, .004)], WATER_L, 24)
    with k.at(radial_frame(0, 0, .86, math.radians(-45))):
        k.box("glaze", 0, -.015, G + .2, .4, .04, .28, TEAL)
        k.emblem(0, -.04, G + .34, .1)
    rot = math.radians(-45)
    k.box("stone", 1.0 * math.cos(rot), 1.0 * math.sin(rot), G, .2, .56, .1, sand(), rot)
    # posts and a fat log
    for x in (-.74, .74):
        k.box("stone", x, .14, G, .38, .38, .74, sand())
        k.box("wood", x, .14, G + .74, .22, .22, .96, WOOD)
    k.tube("wood", (-.94, .14, G + 1.56), (.94, .14, G + 1.56), .12, .12, WOOD_L, 16)
    for x in (-.94, .94):
        k.lathe("wood", x, .14, G + 1.56, [(.12, -.02), (.12, .02)], WOOD_D, 16, m=Matrix.Rotation(math.pi / 2, 4, "Y"))
    k.tube("matte", (0, .14, G + 1.44), (0, .14, G + 1.2), .035, .035, C("#D0AE72"), 10)
    k.lathe("wood", 0, .14, G + .94, [(.15, 0), (.2, .27), (.17, .27), (.14, .05)], WOOD_L, 18)
    k.lathe("gold", 0, .14, G + 1.04, [(.178, 0), (.19, .07)], GOLD, 18)
    k.puff(-.82, -.82, G, .19)
    k.puff(.82, .8, G, .21)


def workshop(k):
    hw, hd = 1.26, .78
    k.box("wood", 0, 0, G, 2 * hw, 2 * hd, .04, WOOD_D)
    # plank back and side walls
    n = 7
    for i in range(n):
        k.box("wood", -hw + (i + .5) * 2 * hw / n, hd, G, 2 * hw / n, .1, 1.62, J(WOOD, .1))
    n = 4
    for i in range(n):
        k.box("wood", -hw, -hd + (i + .5) * 2 * hd / n, G, .1, 2 * hd / n, 1.12, J(WOOD, .1))
    for x in (-hw, hw):
        for y in (-hd, hd):
            post(k, x, y, 1.72 if y > 0 else 1.46)
    k.box("wood", 0, -hd, G + 1.42, 2 * hw + .1, .24, .16, WOOD_L)
    for x in (-hw, hw):
        k.beam("wood", (x, -hd, G + 1.5), (x, hd, G + 1.76), .18, .16, WOOD_L)
    k.awning(-hw + .04, hw - .04, -.14, hd + .06, G + 1.6, G + 1.9, (RED, CANVAS), n=7)
    # a big hammer and a saw blade on the back wall
    k.box("wood", -.35, hd - .08, G + .78, .08, .05, .58, WOOD_L)
    k.box("matte", -.35, hd - .09, G + 1.28, .26, .08, .14, C("#8FA0A6"))
    k.box("gold", .35, hd - .08, G + .92, .5, .05, .2, GOLD)
    k.box("wood", .68, hd - .08, G + .92, .16, .07, .2, WOOD_D)
    # bench, block, scroll
    k.box("wood", .02, -.08, G + .5, 1.34, .62, .13, WOOD_L)
    for x in (-.5, .54):
        k.box("wood", x, -.08, G, .18, .46, .5, WOOD)
    k.box("stone", .36, -.1, G + .63, .32, .26, .2, sand())
    k.tube("matte", (-.5, -.1, G + .71), (.0, -.1, G + .71), .075, .075, CANVAS, 12)
    # barrel, crate, shrub
    k.lathe("wood", .86, -.16, G, [(.19, 0), (.24, .22), (.19, .46), (.15, .44)], WOOD_L, 18)
    k.lathe("gold", .86, -.16, G + .19, [(.238, 0), (.242, .07)], C("#7A6A50"), 18)
    k.crate(-.94, -.48, G, .42)
    k.lights.append(((-.1, .1, G + 1.3), 14.))
    k.puff(.3, -.86, G, .14)
    k.puff(1.3, .84, G, .2)


def market(k):
    hw, hd = 1.2, .66
    for x in (-hw, hw):
        for y in (-hd, hd):
            k.tube("wood", (x, y, G), (x, y, G + 1.58), .08, .08, WOOD_L, 14)
            k.ball("wood", x, y, G + 1.62, .11, WOOD, 14)
    k.beam("wood", (-hw, hd, G + 1.55), (hw, hd, G + 1.55), .13, .13, WOOD)
    k.beam("wood", (-hw, .02, G + 1.4), (hw, .02, G + 1.4), .12, .12, WOOD)
    for x in (-hw, hw):
        k.beam("wood", (x, -hd, G + 1.4), (x, hd, G + 1.55), .13, .13, WOOD)
    k.awning(-hw - .03, hw + .03, -.14, hd + .05, G + 1.5, G + 1.66, (TEAL, C("#EFD9A0")), n=7, hang=.17)
    # counter with three baskets
    k.box("wood", 0, .2, G, 1.9, .62, .44, J(WOOD, .03))
    k.box("wood", 0, .2, G + .44, 2.0, .72, .09, WOOD_L)
    k.box("cloth", 0, -.13, G + .08, .72, .04, .36, TEAL_L)
    k.box("cloth", 0, -.14, G + .2, .72, .04, .09, GOLD)
    for x in (-.62, 0, .62):
        k.basket(x, .2, G + .53, .22)
    # rug, a basket and a crate on the floor
    k.box("cloth", 0, -.62, G, .72, .66, .03, TEAL)
    k.box("cloth", 0, -.62, G + .03, .18, .66, .012, GOLD)
    k.basket(-.94, -.62, G, .24)
    k.crate(.94, -.6, G, .36)
    k.puff(-1.32, .76, G, .17)
    k.puff(1.32, .76, G, .17)


def gateway(k):
    """The Sunstone courtyard: a dry plaza under a mosaic sun. The key stays for old saves."""
    # pavers
    for i in range(9):
        for j in range(6):
            x, y = -1.33 + i * .3325, -.83 + j * .3325
            k.box("stone", x, y, G - .005, .315, .315, .035, J(SAND_PALE, .04))
    z = G + .03
    # the mosaic: rings of colour, a gold star, a raised sun
    cx, cy = 0, -.18
    k.lathe("glaze", cx, cy, z - .005, [(.001, 0), (.78, 0), (.78, .012), (.001, .012)], SAND_PALE, 48, smooth=False)
    k.lathe("gold", cx, cy, z, [(.001, 0), (.7, 0), (.7, .018), (.001, .018)], GOLD, 48)
    k.lathe("glaze", cx, cy, z + .004, [(.001, 0), (.67, 0), (.67, .022), (.001, .022)], TEAL_D, 48, smooth=False)
    star = []
    for i in range(32):
        t = 2 * math.pi * i / 32
        rad = .64 if i % 2 == 0 else .36
        star.append((cx + rad * math.cos(t), cy + rad * math.sin(t), z + .034))
    k.poly("gold", star, GOLD)
    k.lathe("glaze", cx, cy, z + .03, [(.001, 0), (.29, 0), (.29, .012), (.001, .012)], SAND_PALE, 32, smooth=False)
    k.lathe("gold", cx, cy, z + .038, [(.2, 0), (.2, .025), (.12, .07), (.001, .085)], GOLD, 28)
    # two steles at the back, each with a teal panel, a gold sun and a lantern
    for x in (-.78, .92):
        k.box("stone", x, .72, G, .46, .32, .16, J(SAND_PALE, .03))
        k.box("stone", x, .72, G + .16, .38, .26, 1.1, sand())
        k.box("gold", x, .72, G + 1.26, .44, .32, .06, GOLD)
        k.box("gold", x, .72, G + 1.32, .26, .2, .07, GOLD_D)
        k.ball("gold", x, .72, G + 1.42, .05, GOLD, 12)
        k.box("glaze", x, .585, G + .36, .28, .02, .76, TEAL_D)
        star = []
        for i in range(16):
            t = 2 * math.pi * i / 16
            rad = .115 if i % 2 == 0 else .065
            star.append((x + rad * math.cos(t), .57, G + .78 + rad * math.sin(t)))
        k.poly("gold", star, GOLD)
        k.beam("gold", (x + .19, .6, G + 1.1), (x + .33, .5, G + 1.1), .03, .03, GOLD_D)
        k.box("gold", x + .33, .5, G + .96, .11, .11, .03, GOLD_D)
        k.lathe("glow", x + .33, .5, G + .98, [(.045, 0), (.06, .06), (.045, .11)], GLOW, 12)
        k.box("gold", x + .33, .5, G + 1.08, .13, .13, .03, GOLD_D)
        k.lights.append(((x + .33, .4, G + 1.0), 1.2))
    # the planted back wall between them
    for i in range(6):
        k.puff(-.42 + i * .18, .8, G, .17)
    # low benches curving round the mosaic, with gold-starred teal fronts
    for side in (-1, 1):
        for i in range(5):
            t = math.radians(150 + i * 15) if side < 0 else math.radians(-30 + i * 15)
            x, y = cx + 1.05 * math.cos(t), cy + 1.05 * math.sin(t)
            if abs(x) > 1.36:
                continue
            k.box("stone", x, y, G, .13, .27, .2, sand(), t)
            k.box("gold", x, y, G + .2, .15, .28, .03, J(SAND_PALE, .03), t)
    # corner planters
    for x, y, flower in ((-1.2, -.76, C("#EE8A1E")), (1.2, -.76, C("#EE8A1E")), (-1.2, .3, C("#D94FA8")), (1.22, .4, C("#D94FA8"))):
        k.box("stone", x, y, G, .36, .36, .3, sand())
        k.box("glaze", x, y - .185, G + .08, .22, .02, .15, TEAL)
        k.box("glaze", x + .185, y, G + .08, .02, .22, .15, TEAL)
        k.box("stone", x, y, G + .3, .4, .4, .04, J(SAND_PALE, .03))
        k.puff(x, y, G + .34, .13)
        for i in range(3):
            t = 2 * math.pi * i / 3
            k.ball("matte", x + .07 * math.cos(t), y + .07 * math.sin(t), G + .56, .04, flower, 10)
    k.palm(-1.18, .74, G, 1.25, .62, 7)


def lodge(k):
    x0, x1, y0, y1 = -1.3, .9, -1.2, 1.3
    cx, cy, sx, sy = (x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0
    zp, z1, z2 = G + .1, G + 1.06, G + 1.92
    a, b, c = (x0, y0), (x1, y0), (x1, y1)
    k.box("stone", cx, cy, G, sx + .14, sy + .14, .1, SAND_DK)
    k.box("stone", cx, cy, zp, sx - .14, sy - .14, z2 - zp, SAND_DK)
    k.wall(a, b, zp, z1)
    k.wall(b, c, zp, z1)
    with k.at(face(a, b)):
        k.window(sx * .32, zp + .26, zp + .52, .2)
        k.window(sx * .76, zp + .26, zp + .52, .2)
    with k.at(face(b, c)):
        k.window(sy * .5, zp, zp + .5, .28, fill=J(WOOD, .02), fill_mat="wood")
        k.ball("gold", sy * .5 + .16, -.05, zp + .32, .04, GOLD, 10)
    # upper floor: plaster with fat timbers
    k.box("matte", cx, cy, z1, sx + .02, sy + .02, z2 - z1, PLASTER)
    k.box("wood", cx, cy, z1 - .06, sx + .14, sy + .14, .14, WOOD)
    k.box("wood", cx, cy, z2 - .08, sx + .14, sy + .14, .14, WOOD)
    for p in (a, b, c):
        k.box("wood", p[0], p[1], z1, .15, .15, z2 - z1, WOOD)
    with k.at(wall_frame(a, b) @ Matrix.Translation((0, -.02, 0))):
        k.window(sx * .32, z1 + .24, z1 + .46, .19, trim=WOOD_L, trim_mat="wood")
        k.window(sx * .76, z1 + .24, z1 + .46, .19, trim=WOOD_L, trim_mat="wood")
    with k.at(wall_frame(b, c) @ Matrix.Translation((0, -.02, 0))):
        k.window(sy * .5, z1 + .24, z1 + .46, .22, trim=WOOD_L, trim_mat="wood")
    # porch: columns, a floor and a solid rail above
    bx = x1 + .26
    k.box("wood", bx, cy, z1 - .08, .56, sy * .72, .13, WOOD_L)
    k.box("wood", bx + .22, cy, z1 + .05, .1, sy * .72, .26, WOOD)
    for y in (cy - sy * .33, cy + sy * .33):
        k.tube("stone", (bx + .16, y, zp), (bx + .16, y, z1 - .08), .09, .09, SAND_PALE, 14)
    k.box("stone", x1 + .32, cy, G, .22, .8, .08, SAND_PALE)
    k.box("stone", x1 + .15, cy, G, .22, .8, .17, SAND_PALE)
    # roof
    red = lambda: J(CLAY if R.random() < .85 else CLAY_L, .025)
    k.hip_roof(cx, cy, z2 + .02, sx + .56, sy + .56, .86, "clay", red, ("clay", CLAY_L))
    k.box("stone", -.8, .9, z2 + .36, .34, .34, .62, sand())
    k.box("stone", -.8, .9, z2 + .98, .44, .44, .1, SAND_PALE)
    # pots
    for x, y, r in ((1.28, -1.26, .15), (-.1, -1.36, .13)):
        k.lathe("matte", x, y, G, [(r * .7, 0), (r, r * .9), (r * 1.05, r * 1.25), (r * .85, r * 1.25)], POT, 16)
        k.blob(x, y, G + r * 1.65, r * .95)
    k.puff(1.32, 1.34, G, .17)
    k.puff(-1.36, 1.36, G, .15)


def archive(k):
    hp = 1.24
    k.wall((-hp, -hp), (hp, -hp), G, G + .24, t=.24, course=.24, length=.72, col=SAND_PALE)
    k.wall((hp, -hp), (hp, hp), G, G + .24, t=.24, course=.24, length=.72, col=SAND_PALE)
    k.box("stone", 0, 0, G, 2 * hp - .1, 2 * hp - .1, .24, SAND_DK)
    z0 = G + .24
    k.box("stone", 0, -1.4, G, 1.3, .2, .08, SAND_PALE)
    k.box("stone", 0, -1.28, G, 1.3, .2, .16, SAND_PALE)
    hc, zt = .92, z0 + 1.02
    k.box("stone", 0, 0, z0, 2 * hc, 2 * hc, zt - z0, SAND_DK)
    def shelf(a, b):
        with k.at(face(a, b, t=0)):
            k.box("wood", hc, -.04, z0 + .06, 1.3, .08, .84, WOOD_D)
            for row in range(2):
                z = z0 + .12 + row * .4
                k.box("wood", hc, -.1, z - .05, 1.24, .12, .06, WOOD_L)
                x = hc - .56
                while x < hc + .52:
                    w = R.choice((.14, .18, .22))
                    k.box("matte", x + w / 2, -.12, z, w * .94, .1, R.uniform(.24, .3), R.choice((RED, TEAL, CANVAS, GOLD)))
                    x += w
    shelf((-hc, -hc), (hc, -hc))
    shelf((hc, -hc), (hc, hc))
    hk = 1.1
    def col(x, y):
        h = zt - z0
        k.lathe("stone", x, y, z0, [(.15, 0), (.12, .08), (.12, h - .1)], SAND_PALE, 16)
        k.lathe("gold", x, y, z0 + h - .12, [(.12, 0), (.19, .1), (.19, .13)], GOLD, 16)
    for x in (-1.08, -.42, .46, hk):
        col(x, -hk)
    for y in (-.46, .44, 1.08):
        col(hk, y)
    for a, b in (((-hk - .14, -hk), (hk + .14, -hk)), ((hk, -hk), (hk, hk + .14))):
        k.beam("stone", (a[0], a[1], zt + .1), (b[0], b[1], zt + .1), .32, .2, SAND_PALE)
        k.beam("glaze", (a[0], a[1], zt + .23), (b[0], b[1], zt + .23), .3, .08, TEAL)
    for a, b in (((-hk - .14, -hk), (-hk - .14, hk)), ((-hk - .14, hk), (hk, hk))):
        k.beam("stone", (a[0], a[1], zt + .14), (b[0], b[1], zt + .14), .3, .28, SAND_PALE)
    # roof with a gold ridge, a finial and a diamond on each visible pane
    eave, s = zt + .27, 2.78
    k.hip_roof(0, 0, eave, s, s, .82, "glaze", lambda: J(TEAL if R.random() < .85 else TEAL_L, .025), ("gold", GOLD))
    top = eave + .82
    k.lathe("gold", 0, 0, top + .03, [(.001, 0), (.2, .22), (.001, .5)], GOLD, 4)
    apex = Vector((0, 0, top))
    for c, ax in ((Vector((0, -s / 2, eave)), Vector((1, 0, 0))), (Vector((s / 2, 0, eave)), Vector((0, 1, 0)))):
        mid, up = c.lerp(apex, .42), (apex - c).normalized()
        nrm = ax.cross(up).normalized()
        nrm = -nrm if nrm.z < 0 else nrm
        for lift, rd, mat, col_ in ((.13, .25, "gold", GOLD), (.136, .13, "glaze", TEAL_L)):
            k.poly(mat, [tuple(mid + nrm * lift + ax * rd), tuple(mid + nrm * lift + up * rd), tuple(mid + nrm * lift - ax * rd), tuple(mid + nrm * lift - up * rd)], col_)
    k.brazier(-.98, -1.36, G, .28)
    k.brazier(.98, -1.36, G, .28)
    k.puff(-1.36, -1.36, G, .13)
    k.puff(1.38, -1.0, G, .1)
    k.puff(1.38, 1.36, G, .13)
    k.puff(-1.38, 1.38, G, .13)


def observatory(k):
    r, ztop, door = .7, G + 2.0, math.radians(-45)
    k.ring(0, 0, G, G + .16, r + .12, .3, .16, .8, col=SAND_PALE)
    k.lathe("stone", 0, 0, G, [(r - .06, 0), (r - .06, ztop - G)], SAND_DK, 32)
    k.ring(0, 0, G + .16, ztop, r, .28, .36, .68)
    def opening(a, z0, zs, rad, fill):
        with k.at(radial_frame(0, 0, r + .14, a)):
            k.box("stone", 0, .02, z0 - .05, 2 * rad + .4, .08, zs - z0 + rad + .26, SAND_PALE)
            k.window(0, z0, zs, rad, fill=fill, trim=C("#F0DDAE"), y=-.02)
    opening(door, G + .16, G + .46, .26, FLAME)
    opening(math.radians(-100), G + 1.2, G + 1.4, .15, GLOW)
    opening(math.radians(8), G + 1.2, G + 1.4, .15, GLOW)
    k.box("stone", .78, -.78, G, .34, .4, .08, SAND_PALE, door)
    # gold band and dome
    k.lathe("gold", 0, 0, ztop, [(r + .15, 0), (r + .17, .05), (r + .17, .14), (r + .12, .17)], GOLD, 40)
    zd, Rd = ztop + .17, r + .08
    k.lathe("glaze", 0, 0, zd, [(max(Rd * math.cos(math.pi / 2 * i / 12), .001), Rd * math.sin(math.pi / 2 * i / 12)) for i in range(13)], TEAL, 40)
    for i in range(6):
        a = 2 * math.pi * i / 6 + .26
        pts = [(Rd * math.cos(p) * math.cos(a), Rd * math.cos(p) * math.sin(a), zd + Rd * math.sin(p)) for p in [j * math.pi / 2 / 9 for j in range(10)]]
        k.path("gold", pts, .03, GOLD, 8)
    k.ball("gold", 0, 0, zd + Rd + .06, .11, GOLD, 14)
    # a fat telescope, aimed up and right on screen
    aim, base = Vector((.7, .56, .5)).normalized(), Vector((.06, .06, zd + .36))
    k.tube("gold", tuple(base), tuple(base + aim * .88), .13, .13, GOLD, 18)
    k.tube("gold", tuple(base + aim * .5), tuple(base + aim * .9), .19, .19, GOLD, 18)
    k.tube("matte", tuple(base + aim * .9), tuple(base + aim * .92), .14, .14, C("#16323A"), 18)
    k.tube("gold", tuple(base + aim * .44), tuple(base + aim * .52), .22, .22, GOLD_D, 18)
    # shrubs
    k.puff(-.78, -.74, G, .2)
    k.puff(.82, -.28, G, .15)
    k.puff(-.8, .62, G, .18)
    k.puff(.7, .8, G, .18)


def fountain(k):
    with k.at(Matrix.Rotation(math.radians(45), 4, "Z")):
        # tiers in a frame facing the camera: local -y points at the front corner
        def tier(y0, y1, hx, z1):
            a, b, c = (-hx, y0), (hx, y0), (hx, y1)
            k.wall(a, b, G, z1, t=.2, course=.3, length=.6)
            k.wall(b, c, G, z1, t=.2, course=.3, length=.6)
            k.wall((-hx, y1), a, G, z1, t=.2, course=.3, length=.6)
            k.box("stone", 0, (y0 + y1) / 2, G, 2 * hx - .1, y1 - y0 - .1, z1 - G - .02, SAND_DK)
        k.ring(0, -.92, G, G + .24, .62, .2, .24, .36, col=SAND_PALE)
        k.lathe("water", 0, -.92, G + .02, [(.58, 0), (.58, .16)], WATER, 32)
        tier(-.44, .22, .66, G + .6)
        k.box("water", 0, -.1, G + .6, 1.14, .46, .03, WATER)
        k.box("stone", 0, -.38, G + .6, 1.26, .14, .07, SAND_PALE)
        tier(.22, .86, .6, G + 1.16)
        k.box("water", 0, .54, G + 1.16, 1.0, .46, .03, WATER)
        k.box("stone", 0, .26, G + 1.16, 1.14, .14, .07, SAND_PALE)
        k.box("water", 0, -.5, G + .16, .46, .05, .5, WATER_L)
        k.box("water", 0, .18, G + .62, .4, .05, .58, WATER_L)
        # back wall, niche, carved jade mask
        k.box("stone", 0, 1.0, G + 1.16, 1.3, .16, 1.1, SAND_DK)
        k.wall((-.7, .86), (.7, .86), G + 1.16, G + 2.24, t=.22, course=.36, length=.64)
        hz = G + 1.52
        k.box("glaze", 0, .68, hz, .5, .14, .56, TEAL_L)
        k.box("glaze", 0, .6, hz + .34, .56, .08, .1, TEAL)
        k.box("glaze", 0, .56, hz + .12, .13, .12, .22, TEAL)
        k.box("matte", 0, .6, hz + .01, .2, .03, .07, C("#0B3B3A"))
        for s in (-1, 1):
            k.box("glaze", s * .29, .7, hz + .14, .08, .12, .24, TEAL)
            k.box("flame", s * .13, .6, hz + .24, .09, .01, .05, C("#BFFFF0"))
        k.box("gold", 0, .66, hz + .56, .6, .2, .08, GOLD)
        k.box("gold", 0, .63, hz + .64, .2, .12, .12, GOLD)
        k.tube("water", (0, .58, hz + .03), (0, .46, G + 1.17), .08, .13, WATER_L, 14)
        # torches and greenery
        k.brazier(-.7, -.86, G, .3)
        k.brazier(.7, -.86, G, .3)
        k.palm(-1.4, .3, G, 1.25, .46)
        k.palm(1.4, .3, G, 1.0, .42)
        k.puff(-1.24, -.38, G, .17)
        k.puff(1.26, -.36, G, .17)
        k.puff(0, 1.5, G, .2)


def temple(k):
    tiers = [(1.84, G, G + .5), (1.38, G + .5, G + 1.0), (.94, G + 1.0, G + 1.5)]
    gap = .62   # half width of the notch the stair climbs through
    for i, (hs, z0, z1) in enumerate(tiers):
        if i == 0:
            k.wall((-hs, -hs), (-gap, -hs), z0, z1, t=.2, course=.25, length=.74)
            k.wall((gap, -hs), (hs, -hs), z0, z1, t=.2, course=.25, length=.74)
            for s in (-1, 1):
                x = s * (hs + gap) / 2
                k.box("stone", x, -1.6, z0, hs - gap, .46, z1 - z0 - .01, SAND_DK)
                k.box("stone", x, -1.6, z1 - .01, hs - gap + .03, .54, .05, SAND_PALE)
            k.box("stone", 0, .12, z0, 2 * hs - .08, 2 * hs - .54, z1 - z0 - .01, SAND_DK)
            k.box("stone", 0, .12, z1 - .01, 2 * hs + .06, 2 * hs - .54, .05, SAND_PALE)
        else:
            k.box("stone", 0, 0, z0, 2 * hs - .08, 2 * hs - .08, z1 - z0 - .01, SAND_DK)
            k.box("stone", 0, 0, z1 - .01, 2 * hs + .06, 2 * hs + .06, .05, SAND_PALE)
            k.wall((-hs, -hs), (hs, -hs), z0, z1, t=.2, course=.25, length=.74)
        k.wall((hs, -hs), (hs, hs), z0, z1, t=.2, course=.25, length=.74)
    # two big jade plaques per side of the middle tier
    for s in (-.92, .92):
        k.box("glaze", s, -1.49, G + .6, .36, .04, .28, TEAL)
    for s in (-.7, .7):
        k.box("glaze", 1.49, s, G + .6, .04, .36, .28, TEAL)
    # stair on -y: one flight from the ground through the notch, clearing the upper tier corners
    sw, n, y0, y1, z0, z1 = .84, 6, -1.97, -.92, G + .34, G + 1.56
    for i in range(n + 1):
        t = i / n
        k.box("glaze", 0, y0 + (y1 - y0) * t + .08, G, sw, .2, z0 + (z1 - z0) * t - G, TEAL if i % 2 else TEAL_L)
    for s in (-1, 1):
        x = s * (sw / 2 + .08)
        k.beam("gold", (x, -1.92, G + .46), (x, -.9, G + 1.68), .16, .16, GOLD)
        k.box("gold", x, -1.9, G, .2, .18, .52, GOLD)
    # the shrine
    zs, zt, hs = G + 1.5, G + 2.3, .62
    a, b, c = (-hs, -hs), (hs, -hs), (hs, hs)
    gold = lambda: J(GOLD, .05)
    k.box("gold", 0, 0, zs, 2 * hs - .1, 2 * hs - .1, zt - zs, GOLD_D)
    k.wall(a, b, zs, zt, t=.16, course=.27, length=.56, col=gold, mat="gold")
    k.wall(b, c, zs, zt, t=.16, course=.27, length=.56, col=gold, mat="gold")
    with k.at(face(a, b, t=.16)):
        k.window(hs, zs, zs + .34, .24, fill=C("#3A1E0A"), fill_mat="matte", trim=C("#F6C64E"), trim_mat="gold")
    with k.at(face(b, c, t=.16)):
        k.box("glaze", hs, -.02, zs + .2, .6, .04, .42, TEAL)
        k.emblem(hs, -.045, zs + .41, .16)
    k.box("gold", 0, 0, zt, 2 * hs + .22, 2 * hs + .22, .1, GOLD)
    k.box("gold", 0, 0, zt + .1, .92, .92, .36, C("#F0B93A"))
    k.box("gold", 0, 0, zt + .46, 1.08, 1.08, .08, GOLD)
    k.box("glaze", 0, 0, zt + .54, .6, .6, .18, TEAL)
    k.box("gold", 0, 0, zt + .72, .34, .34, .14, GOLD)
    with k.at(Matrix.Translation((0, -.47, zt + .28)) @ Matrix.Rotation(math.pi / 2, 4, "X")):
        k.lathe("gold", 0, 0, 0, [(.17, 0), (.17, .05)], C("#FFD35C"), 24)
        k.lathe("glaze", 0, 0, .05, [(.09, 0), (.09, .012)], TEAL, 20)
    k.brazier(-.8, -.8, zs, .22)
    k.brazier(.8, -.8, zs, .22)
    # idols at the foot of the stair
    for s in (-1, 1):
        x = s * .98
        k.box("stone", x, -1.78, G, .34, .34, .12, SAND_PALE)
        k.box("gold", x, -1.78, G + .12, .28, .28, .34, GOLD)
        k.box("glaze", x, -1.93, G + .24, .16, .03, .12, TEAL)
    # palms behind, shrubs on the ledges
    k.palm(-1.6, 1.6, G, 2.1, .5)
    k.palm(1.6, 1.6, G, 1.85, .46)
    for x, y, z, r in ((1.62, -1.62, G + .5, .17), (-1.62, -1.62, G + .5, .17), (1.62, .1, G + .5, .17),
                       (1.17, -1.17, G + 1.0, .15), (1.17, .4, G + 1.0, .15), (-1.17, -1.17, G + 1.0, .15)):
        k.puff(x, y, z, r)


# ------------------------------------------------------------------ new buildings
#
# Income buildings beyond the ten wonders. Same kit, same casual proportions.

def gable(k, x0, x1, y0, y1, z, h, mat, col, cap, over=.18):
    """A pitched roof with its ridge along x: two tiled slopes and end walls."""
    ym = (y0 + y1) / 2
    k.prism("wood", [(y0, z), (y1, z), (ym, z + h - .04)], x0, x1, WOOD_D)
    a, b = Vector((x0 - over, y0 - over, z - .06)), Vector((x1 + over, y0 - over, z - .06))
    c, d = Vector((x1 + over, ym, z + h)), Vector((x0 - over, ym, z + h))
    k.pane(mat, a, b, c, d, col)
    e, f = Vector((x1 + over, y1 + over, z - .06)), Vector((x0 - over, y1 + over, z - .06))
    k.pane(mat, e, f, d, c, col)
    k.beam(cap[0], tuple(d + Vector((0, 0, .06))), tuple(c + Vector((0, 0, .06))), .15, .13, cap[1])


def thatch():
    return J(STRAW, .05)


def log_cabin(k):
    hx, hy, top = .72, .72, G + .86
    for i in range(5):
        z = G + .09 + i * .17
        k.tube("wood", (-hx - .1, -hy, z), (hx + .1, -hy, z), .09, .09, J(WOOD_L, .06), 12)
        k.tube("wood", (hx, -hy - .1, z + .08), (hx, hy + .1, z + .08), .09, .09, J(WOOD_L, .06), 12)
    k.box("wood", 0, 0, G, 2 * hx - .05, 2 * hy - .05, top - G, WOOD_D)
    with k.at(wall_frame((hx, -hy), (hx, hy)) @ Matrix.Translation((0, -.09, 0))):
        k.window(hy, G + .02, G + .36, .24, fill=WOOD, fill_mat="wood", trim=WOOD_D, trim_mat="wood")
    with k.at(wall_frame((-hx, -hy), (hx, -hy)) @ Matrix.Translation((0, -.09, 0))):
        k.window(hx, G + .34, G + .52, .17, trim=WOOD_D, trim_mat="wood")
    gable(k, -hx, hx, -hy, hy, top, .78, "clay", lambda: J(CLAY_D if R.random() < .5 else CLAY, .04), ("wood", WOOD_L))
    k.box("stone", -.42, .42, top + .32, .28, .28, .68, sand())
    k.crate(.84, -.82, G, .26)
    k.puff(-.8, -.84, G, .14)


def apothecary(k):
    r = .62
    k.ring(0, 0, G, G + .85, r, .22, .28, .54)
    k.lathe("stone", 0, 0, G, [(r - .06, 0), (r - .06, .8)], SAND_DK, 24)
    with k.at(radial_frame(0, 0, r + .11, math.radians(-45))):
        k.window(0, G + .02, G + .36, .22, fill=WOOD, fill_mat="wood", trim=SAND_PALE)
    with k.at(radial_frame(0, 0, r + .11, math.radians(-105))):
        k.window(0, G + .36, G + .52, .13)
    k.lathe("clay", 0, 0, G + .82, [(r + .24, 0), (r + .2, .08), (.05, .96)], STRAW, 24)
    k.ball("gold", 0, 0, G + 1.82, .08, TEAL_L, 12)
    for x, y, c in ((.82, -.3, TEAL_L), (.82, -.62, RED), (.5, -.84, C("#7A52C4"))):
        k.lathe("matte", x, y, G, [(.05, 0), (.11, .08), (.11, .16), (.05, .22), (.05, .28), (.075, .28)], c, 14)
    k.puff(-.82, -.82, G, .15)
    k.puff(.82, .82, G, .16)
    k.puff(-.82, .82, G, .14)


def mess_hall(k):
    x0, x1, y0, y1 = -1.2, 1.2, -.72, .72
    zt = G + .95
    k.box("stone", 0, 0, G, 2.3, 1.34, zt - G, SAND_DK)
    k.wall((x0, y0), (x1, y0), G, zt, t=.2, course=.32, length=.6)
    k.wall((x1, y0), (x1, y1), G, zt, t=.2, course=.32, length=.6)
    with k.at(face((x0, y0), (x1, y0), t=.2)):
        for s in (.5, 1.2, 1.9):
            k.window(s, G + .3, G + .54, .17)
    with k.at(face((x1, y0), (x1, y1), t=.2)):
        k.window(.72, G + .02, G + .42, .26, fill=WOOD, fill_mat="wood")
    gable(k, x0, x1, y0, y1, zt, .86, "clay", lambda: J(CLAY if R.random() < .85 else CLAY_L, .025), ("clay", CLAY_L))
    k.box("stone", -.7, .1, zt + .26, .3, .3, .86, sand())
    k.box("stone", -.7, .1, zt + 1.12, .38, .38, .09, SAND_PALE)
    k.puff(1.36, -.84, G, .12)
    k.puff(-1.36, -.84, G, .12)


def stilt_house(k):
    hx, hy = 1.15, .7
    for x in (-hx, 0, hx):
        for y in (-hy, hy):
            k.box("wood", x, y, G, .18, .18, .62, WOOD)
    k.box("wood", 0, 0, G + .58, 2 * hx + .2, 2 * hy + .2, .12, WOOD_L)
    n = 6
    for i in range(n):
        k.box("wood", -hx + .1 + (i + .5) * (2 * hx - .2) / n, -hy + .1, G + .7, (2 * hx - .2) / n, .08, .72, J(WOOD_L, .08))
    k.box("wood", 0, .02, G + .7, 2 * hx - .24, 2 * hy - .24, .72, WOOD)
    with k.at(wall_frame((-hx + .1, -hy + .06), (hx - .1, -hy + .06))):
        k.window(.55, G + .92, G + 1.08, .15, trim=WOOD_D, trim_mat="wood")
        k.window(1.55, G + .92, G + 1.08, .15, trim=WOOD_D, trim_mat="wood")
    with k.at(wall_frame((hx - .1, -hy + .1), (hx - .1, hy - .1))):
        k.window(hy - .1, G + .72, G + 1.02, .2, fill=WOOD_D, fill_mat="wood", trim=WOOD_D, trim_mat="wood")
    k.hip_roof(0, 0, G + 1.42, 2 * hx + .34, 2 * hy + .34, .72, "clay", thatch, ("wood", WOOD_L))
    # ladder on the right
    for s in (-1, 1):
        k.beam("wood", (hx + .36, s * .17, G), (hx + .12, s * .17, G + .66), .06, .06, WOOD_D)
    for i in range(3):
        t = (i + .6) / 3
        k.beam("wood", (hx + .36 - .24 * t, -.2, G + .66 * t), (hx + .36 - .24 * t, .2, G + .66 * t), .05, .05, WOOD_L)
    k.puff(-1.0, .0, G, .17)
    k.puff(.2, -.85, G, .11)


def map_room(k):
    x0, x1, y0, y1 = -1.15, 1.15, -.74, .74
    zt = G + 1.4
    k.box("matte", 0, 0, G + .32, x1 - x0, y1 - y0, zt - G - .32, PLASTER)
    k.wall((x0, y0), (x1, y0), G, G + .34, t=.2, course=.34, length=.6)
    k.wall((x1, y0), (x1, y1), G, G + .34, t=.2, course=.34, length=.6)
    k.box("stone", 0, 0, G, 2.2, 1.38, .34, SAND_DK)
    for x, y in ((x0, y0), (x1, y0), (x1, y1)):
        k.box("wood", x, y, G + .34, .16, .16, zt - G - .34, WOOD)
    with k.at(wall_frame((x0, y0), (x1, y0)) @ Matrix.Translation((0, -.01, 0))):
        k.window(.62, G + .52, G + .82, .22, trim=WOOD_L, trim_mat="wood")
        k.window(1.68, G + .52, G + .82, .22, trim=WOOD_L, trim_mat="wood")
    with k.at(wall_frame((x1, y0), (x1, y1)) @ Matrix.Translation((0, -.01, 0))):
        k.window(.74, G + .34, G + .72, .26, fill=WOOD, fill_mat="wood", trim=WOOD_L, trim_mat="wood")
    k.box("stone", x1 + .15, 0, G, .22, .78, .18, SAND_PALE)
    k.hip_roof(0, 0, zt + .02, 2.56, 1.76, .7, "glaze", lambda: J(TEAL if R.random() < .85 else TEAL_L, .025), ("gold", GOLD))
    # a brass globe on the ridge
    k.lathe("gold", 0, 0, zt + .76, [(.1, 0), (.05, .08), (.05, .12)], GOLD, 12)
    k.ball("glaze", 0, 0, zt + 1.08, .22, TEAL_L, 18)
    k.path("gold", [(.26 * math.cos(t * math.pi / 8), 0, zt + 1.08 + .26 * math.sin(t * math.pi / 8)) for t in range(-4, 13)], .025, GOLD, 8)
    k.puff(1.36, -.84, G, .12)
    k.puff(-1.36, -.84, G, .12)


def greenhouse(k):
    hx, hy, zw = 1.25, .78, G + .92
    k.wall((-hx, -hy), (hx, -hy), G, G + .24, t=.18, course=.24, length=.6, col=SAND_PALE)
    k.wall((hx, -hy), (hx, hy), G, G + .24, t=.18, course=.24, length=.6, col=SAND_PALE)
    k.wall((-hx, -hy), (-hx, hy), G, G + .24, t=.18, course=.24, length=.6, col=SAND_PALE)
    k.wall((-hx, hy), (hx, hy), G, G + .24, t=.18, course=.24, length=.6, col=SAND_PALE)
    k.box("matte", 0, 0, G, 2 * hx - .1, 2 * hy - .1, .1, C("#6B4A2B"))
    # plants inside, glass over them
    for x in (-.8, 0, .8):
        k.palm(x, .2, G + .1, .42, .34, 6)
        k.blob(x + .2, -.3, G + .3, .18)
    ridge = G + 1.62
    for i in range(7):
        x = -hx + 2 * hx * i / 6
        for y in (-hy, hy):
            k.box("gold", x, y, G + .24, .05, .05, zw - G - .24, GOLD)
            k.beam("gold", (x, y, zw), (x, 0, ridge), .05, .05, GOLD)
    for y in (-hy, hy):
        k.beam("gold", (-hx, y, zw), (hx, y, zw), .07, .07, GOLD)
    k.beam("gold", (-hx - .04, 0, ridge), (hx + .04, 0, ridge), .1, .1, GOLD)
    for y in (-hy, hy):
        k.box("gold", hx, y, zw, .06, .06, .02, GOLD)
    for y0 in (-hy, hy):
        k.poly("glass", [(-hx, y0, G + .24), (hx, y0, G + .24), (hx, y0, zw), (-hx, y0, zw)], GLASS)
        k.poly("glass", [(-hx, y0, zw), (hx, y0, zw), (hx, 0, ridge), (-hx, 0, ridge)], GLASS)
    for x0 in (-hx, hx):
        k.poly("glass", [(x0, -hy, G + .24), (x0, hy, G + .24), (x0, hy, zw), (x0, 0, ridge), (x0, -hy, zw)], GLASS)
    k.puff(1.36, -.86, G, .1)


def trading_post(k):
    hx, hy = 1.0, 1.0
    z1, z2 = G + .95, G + 1.72
    k.box("stone", 0, 0, G, 2 * hx - .06, 2 * hy - .06, z1 - G, SAND_DK)
    k.wall((-hx, -hy), (hx, -hy), G, z1)
    k.wall((hx, -hy), (hx, hy), G, z1)
    k.box("wood", 0, 0, z1 - .05, 2 * hx + .18, 2 * hy + .18, .12, WOOD)
    k.box("wood", 0, 0, z1, 2 * hx, 2 * hy, z2 - z1, WOOD_L)
    for s in range(-3, 4):
        k.box("wood", s * .28, -hy - .01, z1, .03, .02, z2 - z1, WOOD)
        k.box("wood", hx + .01, s * .28, z1, .02, .03, z2 - z1, WOOD)
    with k.at(wall_frame((-hx, -hy), (hx, -hy))):
        k.window(1.0, z1 + .22, z1 + .42, .18, trim=WOOD_D, trim_mat="wood")
    with k.at(wall_frame((hx, -hy), (hx, hy))):
        k.window(1.0, z1 + .22, z1 + .42, .18, trim=WOOD_D, trim_mat="wood")
    k.hip_roof(0, 0, z2 + .02, 2 * hx + .46, 2 * hy + .46, .72, "clay", thatch, ("wood", WOOD))
    # an open stall counter on +x
    with k.at(face((hx, -hy), (hx, hy))):
        k.window(1.0, G + .02, G + .4, .28, fill=C("#6E421E"), fill_mat="wood")
    k.box("wood", hx + .3, .62, G, .34, .5, .42, WOOD_L)
    k.basket(hx + .3, .62, G + .42, .15)
    k.box("wood", -.42, -hy - .3, G, .5, .34, .42, WOOD_L)
    k.basket(-.42, -hy - .3, G + .42, .16)
    k.crate(hx + .28, -.9, G, .34)
    k.crate(.56, -hy - .28, G, .3)
    k.puff(-1.28, -1.28, G, .15)
    k.puff(1.3, 1.3, G, .15)


def water_mill(k):
    x0, x1, y0, y1 = -1.25, .55, -.72, 1.25
    z1 = G + 1.16
    k.box("stone", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0 - .06, y1 - y0 - .06, z1 - G, SAND_DK)
    k.wall((x0, y0), (x1, y0), G, z1)
    k.wall((x1, y0), (x1, y1), G, z1)
    with k.at(face((x0, y0), (x1, y0))):
        k.window(.9, G + .02, G + .44, .28, fill=WOOD, fill_mat="wood")
    with k.at(face((x1, y0), (x1, y1))):
        k.window(1.55, G + .52, G + .76, .17)
    gable(k, x0, x1, y0, y1, z1, .92, "clay", lambda: J(CLAY if R.random() < .85 else CLAY_L, .025), ("clay", CLAY_L))
    # the channel and the wheel on +x
    k.box("stone", .98, .1, G, .84, 1.5, .08, SAND_PALE)
    k.box("water", .98, .1, G + .08, .66, 1.36, .03, WATER)
    wheel = Matrix.Translation((.98, .1, G + .75)) @ Matrix.Rotation(math.pi / 2, 4, "Y")
    with k.at(wheel):
        k.lathe("wood", 0, 0, -.28, [(.1, 0), (.1, .62)], WOOD_D, 16)
        for z in (-.26, .26):
            for i in range(10):
                a0, a1 = 2 * math.pi * i / 10, 2 * math.pi * (i + 1) / 10
                k.beam("wood", (.62 * math.cos(a0), .62 * math.sin(a0), z), (.62 * math.cos(a1), .62 * math.sin(a1), z), .07, .08, WOOD)
        for i in range(10):
            a = 2 * math.pi * i / 10
            ca, sa = math.cos(a), math.sin(a)
            k.beam("wood", (.66 * ca, .66 * sa, -.3), (.66 * ca, .66 * sa, .3), .2, .05, WOOD_L)
            k.beam("wood", (.1 * ca, .1 * sa, 0), (.62 * ca, .62 * sa, 0), .06, .06, WOOD_D)
    k.puff(-1.3, -1.28, G, .16)
    k.puff(.4, -1.26, G, .14)


def clock_tower(k):
    hx, zt = .62, G + 2.4
    k.box("stone", 0, 0, G, 2 * hx - .06, 2 * hx - .06, zt - G, SAND_DK)
    k.wall((-hx, -hx), (hx, -hx), G, zt, t=.2, course=.38, length=.62)
    k.wall((hx, -hx), (hx, hx), G, zt, t=.2, course=.38, length=.62)
    with k.at(face((hx, -hx), (hx, hx), t=.2)):
        k.window(hx, G + .02, G + .4, .26, fill=WOOD, fill_mat="wood")
    with k.at(face((-hx, -hx), (hx, -hx), t=.2)):
        k.window(hx, G + .9, G + 1.08, .15)
    k.box("gold", 0, 0, zt, 2 * hx + .2, 2 * hx + .2, .1, GOLD)
    k.box("stone", 0, 0, zt + .1, 2 * hx, 2 * hx, .72, SAND_PALE)
    for frame in (wall_frame((-hx, -hx), (hx, -hx)), wall_frame((hx, -hx), (hx, hx))):
        with k.at(frame @ Matrix.Translation((hx, -.0, zt + .46)) @ Matrix.Rotation(math.pi / 2, 4, "X")):
            k.lathe("gold", 0, 0, 0, [(.33, 0), (.33, .045)], GOLD, 24)
            k.lathe("matte", 0, 0, .04, [(.27, 0), (.27, .012)], C("#FFF4D8"), 24)
            k.box("matte", 0, .1, .052, .04, .22, .012, DARK)
            k.box("matte", .07, 0, .052, .16, .04, .012, DARK)
    k.hip_roof(0, 0, zt + .84, 2 * hx + .34, 2 * hx + .34, .7, "glaze", lambda: J(TEAL if R.random() < .85 else TEAL_L, .025), ("gold", GOLD))
    k.ball("gold", 0, 0, zt + 1.72, .1, GOLD, 14)
    k.puff(-.82, -.84, G, .15)
    k.puff(.84, .82, G, .15)


def lighthouse(k):
    def stripe(h):
        return RED if int((h + .01) / .46) % 2 else CANVAS
    k.ring(0, 0, G, G + .28, .74, .3, .28, .66)
    k.lathe("stone", 0, 0, G, [(.66, 0), (.66, .28)], SAND_DK, 24)
    k.lathe("matte", 0, 0, G + .28, [(.54 - .2 * (i / 10), i * .23) for i in range(11)], stripe, 28)
    with k.at(radial_frame(0, 0, .56, math.radians(-45))):
        k.window(0, G + .3, G + .58, .18, fill=WOOD, fill_mat="wood", y=.03)
    with k.at(radial_frame(0, 0, .42, math.radians(-90))):
        k.window(0, G + 1.48, G + 1.62, .1, y=.03)
    zt = G + 2.58
    k.lathe("gold", 0, 0, zt, [(.42, 0), (.48, .06), (.48, .12), (.3, .12)], GOLD, 24)
    for i in range(6):
        a = 2 * math.pi * i / 6
        k.tube("gold", (.36 * math.cos(a), .36 * math.sin(a), zt + .12), (.36 * math.cos(a), .36 * math.sin(a), zt + .3), .025, .025, GOLD, 8)
    k.lathe("glow", 0, 0, zt + .12, [(.24, 0), (.24, .42)], FLAME_L, 16)
    k.lathe("clay", 0, 0, zt + .52, [(.46, 0), (.38, .05), (.04, .44)], RED, 24)
    k.ball("gold", 0, 0, zt + 1.02, .08, GOLD, 12)
    k.lights.append(((.6, -.6, zt + .3), 2.))
    k.puff(-.86, -.84, G, .12)
    k.puff(.86, .86, G, .12)


def treehouse(k):
    # the trunk, flared, and a platform halfway up
    k.lathe("wood", 0, 0, G, [(.62, 0), (.42, .14), (.34, .4), (.32, 1.4), (.26, 2.2)], WOOD, 20)
    k.lathe("wood", 0, 0, G + .98, [(1.02, 0), (1.02, .1), (.3, .1)], WOOD_L, 20)
    for i in range(6):
        a = 2 * math.pi * i / 6 + .3
        k.beam("wood", (.3 * math.cos(a), .3 * math.sin(a), G + .6), (.9 * math.cos(a), .9 * math.sin(a), G + 1.0), .09, .09, WOOD_D)
    # hut facing the camera, in a rotated frame
    with k.at(Matrix.Rotation(math.radians(45), 4, "Z")):
        k.box("wood", 0, -.2, G + 1.08, .94, .72, .62, WOOD_L)
        for s in (-1, 1):
            k.box("wood", s * .46, -.56, G + 1.08, .08, .08, .62, WOOD)
        k.window(0, G + 1.1, G + 1.36, .17, fill=WOOD_D, fill_mat="wood", trim=WOOD_D, trim_mat="wood", y=-.56)
        k.hip_roof(0, -.2, G + 1.7, 1.28, 1.06, .52, "clay", thatch, ("wood", WOOD))
        # a rope bridge rail and a ladder at the front
        for s in (-1, 1):
            k.beam("wood", (s * .18, -1.0, G), (s * .18, -.96, G + 1.0), .06, .06, WOOD_D)
        for i in range(5):
            z = G + .16 + i * .19
            k.beam("wood", (-.2, -.98, z), (.2, -.98, z), .05, .05, WOOD_L)
    # canopy
    for x, y, z, r in ((.0, .55, 2.5, .72), (-.72, .1, 2.15, .55), (.72, .55, 2.2, .55), (-.2, .96, 2.0, .46)):
        k.blob(x, y, G + z, r)
    k.puff(-1.28, -1.28, G, .15)
    k.puff(1.28, -1.28, G, .15)
    k.puff(1.28, 1.28, G, .15)


def aviary(k):
    r = 1.2
    k.ring(0, 0, G, G + .28, r, .24, .28, .7, col=SAND_PALE)
    k.lathe("matte", 0, 0, G, [(r - .08, 0), (r - .08, .22)], C("#6B9A42"), 28)
    # plants and perches inside
    k.palm(-.3, .3, G + .22, .92, .5, 7)
    k.puff(.5, .4, G + .22, .22)
    k.puff(.1, -.5, G + .22, .17)
    k.lathe("water", -.42, -.3, G + .22, [(.22, 0), (.22, .03)], WATER, 18)
    birds = ((.42, -.42, 1.1, RED), (-.42, .1, 1.5, TEAL_L), (.1, .4, 1.3, C("#F0C030")))
    for x, y, z, c in birds:
        k.tube("wood", (x, y, G + .22), (x, y, G + z), .025, .025, WOOD, 7)
        k.tube("wood", (x - .14, y, G + z), (x + .14, y, G + z), .022, .022, WOOD, 7)
        k.ball("matte", x, y, G + z + .1, .09, c, 12, sz=1.2)
    # cage: gold ribs on a dome, with a jade cap
    Rd, zc = r + .02, G + .28
    H = 1.95
    for i in range(16):
        a = 2 * math.pi * i / 16
        pts = [(Rd * math.cos(p) * math.cos(a), Rd * math.cos(p) * math.sin(a), zc + H * math.sin(p)) for p in [j * math.pi / 2 / 10 for j in range(11)]]
        k.path("gold", pts, .022, GOLD, 6)
    for z in (.25, .55, .8):
        t = math.asin(z)
        pts = [(Rd * math.cos(t) * math.cos(a * math.pi / 16), Rd * math.cos(t) * math.sin(a * math.pi / 16), zc + H * z) for a in range(33)]
        k.path("gold", pts, .02, GOLD, 6)
    k.lathe("glaze", 0, 0, zc + H - .1, [(.3, 0), (.26, .08), (.08, .24)], TEAL, 18)
    k.ball("gold", 0, 0, zc + H + .22, .1, GOLD, 12)
    with k.at(radial_frame(0, 0, r + .13, math.radians(-45))):
        k.window(0, G + .03, G + .34, .22, fill=WOOD, fill_mat="wood", trim=GOLD, trim_mat="gold", y=.01)
    k.puff(-1.28, -1.28, G, .14)
    k.puff(1.28, 1.28, G, .14)


def beached_ship(k):
    L, W = 1.8, .62
    def hull(u, v, side):
        x = -L + 2 * L * u
        t = abs(2 * u - 1) ** 2.4
        half = W * (1 - t * .92)
        y = side * half * (1 - (1 - v) ** 2 * .75)
        lift = .5 * (2 * u - 1) ** 4
        z = G + .1 + lift + (.92 + .34 * (2 * u - 1) ** 2 - lift) * v
        return (x, y, z)
    for s in (-1, 1):
        k.surface("wood", lambda u, v, s=s: hull(u, v, s), 24, 6, lambda u, v: J(WOOD if int(v * 6) % 2 else WOOD_L, .04))
    k.surface("wood", lambda u, v: (lambda a, b: (a[0], a[1] + (b[1] - a[1]) * v, a[2] - .05))(hull(u, 1, -1), hull(u, 1, 1)), 18, 2, WOOD_D)
    k.tube("wood", (-.1, 0, G + .9), (-.1, 0, G + 2.5), .07, .05, WOOD_D, 12)
    k.tube("wood", (.95, 0, G + .95), (.95, 0, G + 2.0), .06, .045, WOOD_D, 12)
    # a tattered sail on the main mast, a yard above it
    k.beam("wood", (-.1, -.72, G + 2.25), (-.1, .72, G + 2.25), .07, .07, WOOD)
    k.surface("cloth", lambda u, v: (-.1 + .2 * math.sin(math.pi * v) * .9, -.66 + 1.32 * u, G + 2.2 - .92 * v), 8, 6, lambda u, v: J(CANVAS, .03))
    k.beam("wood", (.95, -.5, G + 1.76), (.95, .5, G + 1.76), .06, .06, WOOD)
    k.surface("cloth", lambda u, v: (.95 + .14 * math.sin(math.pi * v) * .9, -.45 + .9 * u, G + 1.72 - .6 * v), 6, 5, lambda u, v: J(CANVAS_D, .03))
    k.surface("cloth", lambda u, v: (-.05 + .5 * u, 0, G + 2.5 - .24 * v * (1 - u * .9)), 4, 2, TEAL)
    # wheel-house and crates on the sand
    k.box("wood", -1.0, 0, G + .95, .62, .66, .42, WOOD_L)
    k.box("wood", -1.0, 0, G + 1.37, .74, .78, .08, WOOD)
    k.crate(.84, -.82, G, .28)
    k.crate(1.2, -.82, G, .24)
    k.puff(-1.62, -.84, G, .13)
    k.puff(-.7, -.86, G, .1)


def amphitheater(k):
    cx, cy = 0, -.55
    # three curved rows of big steps, opening toward the camera corner
    for row in range(3):
        r, z = .98 + row * .44, G + .24 * (row + 1)
        n = 6 + row
        for i in range(n):
            a = math.radians(-22 + 224 * (i + .5) / n)
            w = 2 * r * math.tan(math.radians(224 / n / 2))
            k.box("stone", cx + r * math.cos(a), cy + r * math.sin(a), G, .44, w * .98, z - G, sand(), a)
    # stage and columns
    k.lathe("stone", cx, cy, G, [(.7, 0), (.7, .14)], SAND_PALE, 28)
    k.lathe("clay", cx, cy, G + .14, [(.54, 0), (.54, .012)], RED, 24)
    for a in (-30, 210):
        x, y = cx + 1.98 * math.cos(math.radians(a)), cy + 1.98 * math.sin(math.radians(a))
        x, y = max(-1.8, min(1.8, x)), max(-1.32, min(1.32, y))
        k.lathe("stone", x, y, G, [(.17, 0), (.14, .08), (.14, 1.0)], SAND_PALE, 16)
        k.lathe("gold", x, y, G + .98, [(.14, 0), (.2, .1), (.2, .13)], GOLD, 16)
    k.puff(1.72, 1.24, G, .14)
    k.puff(-1.72, 1.24, G, .14)


def museum(k):
    hx, hy = 1.62, 1.1
    z0 = G + .24
    k.wall((-hx, -hy), (hx, -hy), G, z0, t=.2, course=.24, length=.72, col=SAND_PALE)
    k.wall((hx, -hy), (hx, hy), G, z0, t=.2, course=.24, length=.72, col=SAND_PALE)
    k.box("stone", 0, 0, G, 2 * hx - .1, 2 * hy - .1, .24, SAND_DK)
    zt = z0 + 1.12
    k.box("stone", 0, .2, z0, 2 * hx - .36, 2 * hy - .5, zt - z0, SAND_DK)
    k.wall((hx - .18, -hy + .3), (hx - .18, hy - .1), z0, zt, course=.37, length=.66)
    k.wall((-hx + .18, -hy + .32), (hx - .18, -hy + .32), z0, zt, course=.37, length=.66)
    with k.at(face((-hx + .18, -hy + .32), (hx - .18, -hy + .32))):
        k.window(hx - .18, z0 + .02, z0 + .5, .3, fill=C("#6E421E"), fill_mat="wood")
        for s in (.62, 2.26):
            k.window(s, z0 + .42, z0 + .62, .16)
    with k.at(face((hx - .18, -hy + .3), (hx - .18, hy - .1))):
        k.window(.46, z0 + .42, z0 + .62, .16)
        k.window(1.42, z0 + .42, z0 + .62, .16)
    # portico: six fat columns under a pediment
    for x in (-1.45, -.87, -.29, .29, .87, 1.45):
        k.lathe("stone", x, -hy + .1, z0, [(.15, 0), (.12, .08), (.12, zt - z0 - .1)], SAND_PALE, 16)
        k.lathe("gold", x, -hy + .1, zt - .12, [(.12, 0), (.19, .1), (.19, .13)], GOLD, 16)
    k.box("stone", 0, .0, zt, 2 * hx + .1, 2 * hy + .02, .16, SAND_PALE)
    k.box("glaze", 0, -hy - .005, zt + .03, 2 * hx - .1, .02, .08, TEAL)
    k.prism("stone", [(-hy - .01, zt + .16), (hy, zt + .16), (hy, zt + .25), (-hy - .01, zt + .25)], -hx - .06, hx + .06, SAND_PALE)
    ridge = zt + .25 + .72
    k.pane("clay", (-hx - .1, -hy - .08, zt + .25), (hx + .1, -hy - .08, zt + .25), (hx + .1, 0, ridge), (-hx - .1, 0, ridge), lambda: J(TEAL if R.random() < .85 else TEAL_L, .025))
    k.pane("clay", (hx + .1, hy + .08, zt + .25), (-hx - .1, hy + .08, zt + .25), (-hx - .1, 0, ridge), (hx + .1, 0, ridge), lambda: J(TEAL if R.random() < .85 else TEAL_L, .025))
    k.prism("stone", [(-hy, zt + .25), (hy, zt + .25), (0, ridge - .04)], hx - .02, hx + .02, SAND_PALE)
    k.beam("gold", (-hx - .1, 0, ridge + .06), (hx + .1, 0, ridge + .06), .14, .12, GOLD)
    k.box("stone", 0, -1.33, G, 1.3, .2, .08, SAND_PALE)
    k.box("stone", 0, -1.22, G, 1.3, .2, .16, SAND_PALE)
    k.puff(-1.78, -1.28, G, .13)
    k.puff(1.8, -1.28, G, .13)


def hanging_gardens(k):
    tiers = ((1.82, G, G + .54), (1.34, G + .54, G + 1.08), (.86, G + 1.08, G + 1.62))
    for hs, z0, z1 in tiers:
        k.box("stone", 0, 0, z0, 2 * hs - .08, 2 * hs - .08, z1 - z0, SAND_DK)
        k.wall((-hs, -hs), (hs, -hs), z0, z1, t=.2, course=.27, length=.74)
        k.wall((hs, -hs), (hs, hs), z0, z1, t=.2, course=.27, length=.74)
        k.box("matte", 0, 0, z1, 2 * hs - .1, 2 * hs - .1, .03, C("#5F9A42"))
    # hedges along each ledge, and overhanging shrubs
    for hs, z in ((1.58, G + .57), (1.1, G + 1.11)):
        for i in range(-3, 4):
            if i:
                k.blob(i * hs / 3.2, -hs, z + .1, R.uniform(.14, .2))
            k.blob(hs, i * hs / 3.2, z + .1, R.uniform(.14, .2))
    # top pavilion and a stream
    k.box("stone", 0, 0, G + 1.65, 1.2, 1.2, .14, SAND_PALE)
    for x, y in ((-.5, -.5), (.5, -.5), (.5, .5), (-.5, .5)):
        k.lathe("stone", x, y, G + 1.79, [(.1, 0), (.08, .05), (.08, .62)], SAND_PALE, 12)
    k.hip_roof(0, 0, G + 2.42, 1.5, 1.5, .55, "glaze", lambda: J(TEAL if R.random() < .85 else TEAL_L, .025), ("gold", GOLD))
    k.ball("gold", 0, 0, G + 3.08, .1, GOLD, 12)
    k.box("water", 0, -1.14, G + 1.1, .36, .38, .03, WATER)
    k.box("water", 0, -1.46, G + .56, .36, .05, .56, WATER_L)
    k.box("water", 0, -1.63, G + .56, .36, .38, .03, WATER)
    k.box("water", 0, -1.94, G, .36, .05, .58, WATER_L)
    k.palm(-1.56, 1.56, G + .54, .95, .46)
    k.palm(1.56, 1.56, G + .54, .8, .42)
    for x, y, z, r in ((1.58, -1.58, G + .54, .15), (-1.58, -1.58, G + .54, .15), (1.1, -1.1, G + 1.08, .13), (-1.1, -1.1, G + 1.08, .13)):
        k.puff(x, y, z, r)
    k.puff(-1.86, -1.86, G, .12)
    k.puff(1.86, -1.86, G, .12)


# ------------------------------------------------------------------ decorations
#
# Decorations stand straight on the grass (z = 0), with no slab.

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

# trees
def palm_young(k): k.palm(0, 0, 0, .78, .42, 6)
def fan_palm(k):
    k.tube("wood", (0, 0, 0), (0, 0, .5), .1, .07, WOOD, 10)
    for i in range(9):
        a = 2 * math.pi * i / 9
        blade(k, (0, 0, .5), (math.cos(a), math.sin(a)), .46, .13, rise=.7, droop=1.2)
    k.blob(0, 0, .52, .08)
def banana(k):
    for x, y, h in ((-.1, .04, .42), (.1, .08, .34), (0, -.1, .26)):
        k.tube("leaf", (x, y, 0), (x, y, h), .07, .05, C("#6DAE3A"), 10)
        for i in range(4):
            a = 2 * math.pi * i / 4 + x * 9
            blade(k, (x, y, h), (math.cos(a), math.sin(a)), .36, .1, rise=.9, droop=1.2)
    for dz in (0, .07, .14):
        k.ball("matte", .15, -.14, .34 - dz, .055 + dz * .1, C("#F0CE3A"), 8)
def papaya(k):
    k.tube("wood", (0, 0, 0), (0, 0, .92), .07, .05, C("#A98A58"), 10)
    k.palm(0, 0, .35, .55, .34, 6)
    for a in (0, 1.6, 3.2, 4.7):
        k.ball("matte", .09 * math.cos(a), .09 * math.sin(a), .8, .06, C("#F28C1E"), 8, sz=1.25)
def jungle_tree(k):
    k.tube("wood", (0, 0, 0), (0, 0, .5), .1, .07, WOOD, 10)
    k.blob(-.08, .06, .68, .26)
    k.blob(.14, -.04, .62, .22)
    k.blob(.02, -.02, .9, .24)
def cypress(k):
    k.tube("wood", (0, 0, 0), (0, 0, .2), .08, .07, WOOD, 10)
    prof = [(.001, 0), (.2, .02), (.27, .24), (.22, .62), (.1, 1.0), (.001, 1.22)]
    k.lathe("leaf", 0, 0, .14, prof, lambda h: tuple(c * (.55 + .5 * h / 1.2) for c in C("#3B8F3A")), 16)
def frangipani(k):
    k.tube("wood", (0, 0, 0), (0, 0, .36), .08, .06, C("#7D6848"), 10)
    k.tube("wood", (0, 0, .34), (-.2, .08, .6), .05, .04, C("#7D6848"), 8)
    k.tube("wood", (0, 0, .34), (.2, -.06, .56), .05, .04, C("#7D6848"), 8)
    for x, y, z, r in ((-.2, .08, .72, .2), (.2, -.06, .68, .18), (0, 0, .86, .2)):
        k.blob(x, y, z, r)
    for x, y, z in ((-.28, -.06, .86), (.16, -.2, .78), (.0, -.15, 1.0), (.28, .03, .8), (-.08, -.2, .68)):
        bloom(k, x, y, z, .055, C("#FFF0E0"), C("#F7B733"))
def bamboo(k):
    for i in range(13):
        a, d = i * 2.4, .14 + .55 * math.sqrt(i / 13)
        x, y, h = d * math.cos(a), d * math.sin(a), R.uniform(1.2, 1.9)
        k.tube("leaf", (x, y, 0), (x, y, h), .05, .04, C("#7CBF3F"), 8)
        for z in (.5, .9, 1.3):
            if z < h:
                k.tube("leaf", (x, y, z), (x, y, z + .025), .058, .058, C("#4F8F2A"), 8)
        for j in range(4):
            t = j * 1.57 + a
            blade(k, (x, y, h), (math.cos(t), math.sin(t)), .3, .06, rise=.4, droop=1.1)
def twin_palms(k):
    k.palm(-.3, .25, 0, 1.3, .62, 7)
    k.palm(.34, -.25, 0, .9, .56, 7)
    k.puff(.3, .45, 0, .16)
def mango(k):
    k.lathe("wood", 0, 0, 0, [(.2, 0), (.13, .12), (.11, .6)], WOOD, 14)
    for x, y, z, r in ((-.28, .1, .88, .46), (.3, -.08, .82, .42), (0, .02, 1.22, .48)):
        k.blob(x, y, z, r)
    for x, y, z in ((-.48, -.3, .72), (.42, -.38, .68), (.05, -.42, .96), (.6, .1, .7), (-.2, -.34, 1.2)):
        k.ball("matte", x, y, z, .07, C("#F29A1E"), 10, sz=1.2)
def kapok(k):
    k.lathe("wood", 0, 0, 0, [(.62, 0), (.34, .1), (.22, .34), (.17, 1.1), (.15, 1.6)], lambda h: J(C("#9A7A52"), .02), 8)
    for x, y, z, r in ((-.45, -.05, 1.62, .46), (.48, -.15, 1.6, .44), (.05, .42, 1.62, .5), (0, -.3, 1.74, .46), (.0, .05, 2.1, .56)):
        k.blob(x, y, z, r)

# bushes
def shrub(k): k.puff(0, 0, 0, .28)
def fern(k):
    for i in range(9):
        a = 2 * math.pi * i / 9
        blade(k, (0, 0, .02), (math.cos(a), math.sin(a)), .42, .1, rise=1.2, droop=1.3)
def monstera(k):
    for i in range(7):
        a = 2 * math.pi * i / 7
        blade(k, (0, 0, .05), (math.cos(a), math.sin(a)), .42, .19, rise=1.2 - .1 * (i % 3), droop=1.3, col=J(C("#2E9A42"), .08))
    for i in range(3):
        a = i * 2.1
        blade(k, (0, 0, .1), (math.cos(a), math.sin(a)), .3, .14, rise=2.2, droop=1.8, col=J(C("#3FB23C"), .06))
def flower_shrub(k):
    k.puff(0, 0, 0, .28)
    for x, y, z in ((-.28, -.14, .36), (.1, -.3, .3), (.28, -.05, .42), (-.05, -.15, .58), (.02, .1, .66)):
        bloom(k, x, y, z, .075, C("#F2589A"))
def berry(k):
    k.puff(0, 0, 0, .28)
    for x, y, z in ((-.3, -.1, .3), (-.14, -.3, .24), (.12, -.3, .34), (.32, -.1, .3), (.1, -.14, .56), (-.15, -.16, .52), (.26, -.2, .46)):
        k.ball("matte", x, y, z, .05, C("#D9304A"), 8)
def reeds(k):
    for i in range(10):
        a, d = i * 2.4, .06 + .28 * math.sqrt(i / 10)
        x, y = d * math.cos(a), d * math.sin(a)
        h = R.uniform(.5, .85)
        k.tube("leaf", (x, y, 0), (x + x * .2, y + y * .2, h), .022, .012, J(R.choice(LEAVES), .04), 6)
        if i % 3 == 0:
            k.tube("matte", (x + x * .2, y + y * .2, h), (x + x * .2, y + y * .2, h + .16), .035, .035, C("#6E421E"), 8)
def topiary(k):
    k.lathe("matte", 0, 0, 0, [(.13, 0), (.2, .22), (.22, .28), (.17, .28)], POT, 16)
    k.tube("wood", (0, 0, .24), (0, 0, .5), .025, .025, WOOD, 8)
    k.blob(0, 0, .68, .27)
def hedge(k): k.box("hedge", 0, 0, 0, .86, .86, .56, J(C("#4FB544"), .04))

# flowers
def petals(k, heads, r, col, centre=None):
    for x, y, h in heads:
        k.tube("leaf", (x, y, 0), (x, y, h), .012, .012, C("#3F8F2F"), 5)
        bloom(k, x, y, h, r, col() if callable(col) else col, centre)
def low_leaves(k, n=7, L=.3):
    for i in range(n):
        a = 2 * math.pi * i / n
        blade(k, (0, 0, .01), (math.cos(a), math.sin(a)), L, .09, rise=1.0, droop=1.2)
def orchid(k):
    low_leaves(k)
    petals(k, ((-.16, -.1, .34), (.14, -.12, .42), (.02, .12, .5)), .1, C("#E864C0"), C("#FFF0A0"))
def hibiscus(k):
    k.puff(0, 0, 0, .2)
    for x, y, z in ((-.2, -.18, .28), (.2, -.16, .26), (.02, -.2, .46)):
        bloom(k, x, y, z, .12, C("#E23B2E"), C("#FFD24A"))
def daisies(k):
    low_leaves(k)
    petals(k, ((-.22, -.14, .22), (.16, -.2, .26), (.24, .1, .3), (-.1, .16, .34), (.0, -.02, .4)), .085, C("#FFD93B"), C("#B5651D"))
def blue_lily(k):
    low_leaves(k, 6, .26)
    for x, y, h in ((-.16, -.1, .36), (.14, -.14, .42), (.18, .12, .5), (-.1, .16, .46)):
        k.tube("leaf", (x, y, 0), (x, y, h), .014, .014, C("#3F8F2F"), 5)
        k.lathe("matte", x, y, h, [(.02, 0), (.09, .1), (.05, .18), (.001, .22)], C("#4E7BE8"), 10)
def flower_box(k):
    k.box("wood", 0, 0, 0, .74, .46, .24, WOOD_L)
    k.box("matte", 0, 0, .22, .64, .36, .03, C("#5A3A20"))
    for x, y, c in ((-.22, -.08, C("#F2589A")), (0, -.08, C("#FFD93B")), (.22, -.08, C("#F2589A")), (-.12, .08, C("#FFF0E0")), (.12, .08, C("#E23B2E"))):
        k.blob(x, y, .3, .06)
        bloom(k, x, y, .36, .08, c)
def bromeliad(k):
    for i in range(10):
        a = 2 * math.pi * i / 10
        blade(k, (0, 0, .02), (math.cos(a), math.sin(a)), .36, .08, rise=1.3, droop=1.2, col=J(C("#47A83F"), .05))
    k.lathe("matte", 0, 0, .05, [(.02, 0), (.09, .1), (.07, .32), (.001, .42)], C("#EA3F52"), 12)
def flower_bed(k):
    k.box("matte", 0, 0, 0, 1.8, 1.8, .06, C("#5A3A20"))
    for s in (-1, 1):
        k.box("stone", 0, s * .92, 0, 1.96, .16, .16, SAND_PALE)
        k.box("stone", s * .92, 0, 0, .16, 1.7, .16, SAND_PALE)
    cols = (C("#F2589A"), C("#FFD93B"), C("#E23B2E"), C("#FFF0E0"))
    for j, y in enumerate((-.56, -.18, .2, .58)):
        for i, x in enumerate((-.58, -.2, .2, .58)):
            k.blob(x, y, .12, .13)
            bloom(k, x, y, .24, .11, cols[(i + j) % 4])
def rainbow_bed(k):
    k.lathe("stone", 0, 0, 0, [(.96, 0), (.96, .12)], SAND_PALE, 32)
    k.lathe("matte", 0, 0, .1, [(.84, 0), (.84, .03)], C("#5A3A20"), 32)
    rings = ((.68, 12, C("#E23B2E")), (.46, 9, C("#FFD93B")), (.25, 5, C("#F2589A")))
    for rad, n, c in rings:
        for i in range(n):
            a = 2 * math.pi * i / n
            x, y = rad * math.cos(a), rad * math.sin(a)
            k.blob(x, y, .2, .09)
            bloom(k, x, y, .28, .09, c)
    k.blob(0, 0, .22, .13)
    bloom(k, 0, 0, .36, .12, C("#4E7BE8"))

# statues
def broken_column(k):
    z = plinth(k, .62, .14)
    k.lathe("stone", 0, 0, z, [(.21, 0), (.18, .06), (.18, .62)], J(SAND_PALE, .02), 16)
    k.lathe("stone", .16, -.24, z - .02, [(.15, -.13), (.15, .13)], J(SAND_PALE, .02), 14, m=Matrix.Rotation(math.pi / 2, 4, "X"))
    k.blob(-.2, -.2, .22, .1)
    k.blob(.04, -.1, z + .68, .11)
def idol_head(k):
    z = plinth(k, .66, .16)
    c = J(GREY, .03)
    k.box("stone", 0, 0, z, .46, .42, .62, c)
    k.box("stone", 0, -.215, z + .36, .48, .1, .09, tuple(v * .82 for v in c))
    k.box("stone", 0, -.25, z + .16, .11, .1, .22, tuple(v * .9 for v in c))
    k.box("stone", 0, -.215, z + .08, .26, .05, .05, DARK)
    for s in (-1, 1):
        k.box("glaze", s * .13, -.215, z + .27, .09, .03, .05, TEAL_L)
    k.box("gold", 0, 0, z + .62, .54, .5, .07, GOLD)
def jaguar(k):
    z = plinth(k, .74, .14)
    c = TEAL
    k.ball("glaze", 0, .1, z + .17, .19, c, 14, sx=1.05, sy=1.5, sz=.9)
    k.ball("glaze", 0, -.14, z + .36, .17, c, 14, sz=1.05)
    k.box("glaze", 0, -.28, z + .28, .13, .08, .08, TEAL_L)
    for s in (-1, 1):
        k.ball("glaze", s * .13, -.05, z + .5, .055, c, 10)
        k.box("flame", s * .07, -.3, z + .4, .05, .01, .03, C("#FFD24A"))
        k.ball("glaze", s * .13, -.3, z + .06, .07, TEAL_L, 10, sy=1.5, sz=.8)
    k.path("glaze", [(.18, .34, z + .1), (.28, .2, z + .08), (.28, .04, z + .1)], .04, c, 8)
    k.ball("gold", 0, -.14, z + .54, .05, GOLD, 8)
def obelisk(k):
    z = plinth(k, .6, .16)
    k.lathe("stone", 0, 0, z, [(.26, 0), (.15, 1.1)], SAND_PALE, 4)
    k.lathe("gold", 0, 0, z + 1.1, [(.15, 0), (.001, .2)], GOLD, 4)
    k.emblem(0, -.2, z + .4, .09)
def sundial(k):
    k.lathe("stone", 0, 0, 0, [(.24, 0), (.2, .08), (.1, .16), (.1, .46), (.28, .54), (.28, .6)], SAND_PALE, 20)
    k.lathe("gold", 0, 0, .6, [(.25, 0), (.25, .02)], GOLD, 24)
    k.prism("gold", [(-.03, .62), (.2, .62), (-.03, .84)], -.02, .02, GOLD_D)
def explorer(k):
    z = plinth(k, .64, .2)
    c = BRONZE
    for s in (-1, 1):
        k.tube("gold", (s * .08, .0, z), (s * .08, .0, z + .36), .06, .05, c, 10)
    k.lathe("gold", 0, 0, z + .33, [(.11, 0), (.15, .1), (.14, .34), (.05, .36)], c, 14)
    k.ball("gold", 0, 0, z + .78, .12, c, 14)
    k.lathe("gold", 0, 0, z + .82, [(.2, 0), (.2, .025), (.1, .025), (.09, .12), (.001, .13)], c, 16)
    k.tube("gold", (.13, 0, z + .64), (.28, -.2, z + .78), .04, .03, c, 8)
    k.tube("gold", (-.13, 0, z + .64), (-.18, 0, z + .36), .04, .03, c, 8)
    k.ball("glaze", .3, -.23, z + .8, .05, TEAL_L, 10)
def gold_idol(k):
    z = plinth(k, .66, .22)
    k.box("gold", 0, 0, z, .3, .26, .3, GOLD)
    k.box("gold", 0, 0, z + .3, .34, .3, .28, C("#F6C64E"))
    k.box("gold", 0, -.16, z + .4, .08, .05, .12, GOLD_D)
    k.box("matte", 0, -.15, z + .34, .16, .02, .03, DARK)
    for s in (-1, 1):
        k.box("glaze", s * .09, -.15, z + .47, .07, .02, .04, TEAL_L)
    k.box("gold", 0, 0, z + .58, .44, .36, .06, GOLD)
    k.lathe("glaze", 0, 0, z + .64, [(.11, 0), (.001, .2)], TEAL_L, 6)
def stone_arch(k):
    for s in (-1, 1):
        k.box("stone", s * .66, 0, 0, .46, .5, .16, sand())
        for i in range(3 if s < 0 else 2):
            k.box("stone", s * .66, 0, .16 + i * .32, .36, .38, .32, sand())
    for i in range(5):   # the right of the arch has fallen
        a0, a1 = math.pi - math.pi * (i + 1) / 7, math.pi - math.pi * i / 7
        v = []
        for d in (-.19, .19):
            for rd, ang in ((.48, a0), (.48, a1), (.78, a1), (.78, a0)):
                v.append((rd * math.cos(ang), d, .98 + rd * math.sin(ang) * .9))
        k.add("stone", v, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], J(SAND_PALE, .03))
    k.box("stone", .42, -.52, 0, .34, .3, .22, sand(), .5)
    k.puff(-.72, -.7, 0, .15)
    k.puff(.74, .68, 0, .17)
    k.blob(-.62, .0, 1.2, .16)
def giant_head(k):
    c = J(GREY, .02)
    k.ball("matte", 0, .06, .72, .72, c, 20, sx=.92, sy=.9, sz=1.0)
    dk = tuple(v * .78 for v in c)
    # a band, brow, nose, lips and eyes, facing the camera corner
    with k.at(Matrix.Rotation(math.radians(45), 4, "Z")):
        k.box("stone", 0, -.62, .96, .92, .16, .14, dk)
        k.box("stone", 0, -.68, .56, .22, .18, .32, c)
        k.box("stone", 0, -.64, .28, .46, .1, .1, dk)
        for s in (-1, 1):
            k.box("stone", s * .27, -.63, .72, .2, .04, .08, DARK)
            k.box("stone", s * .66, -.2, .4, .14, .2, .42, dk)
    k.lathe("gold", 0, .06, 1.34, [(.34, 0), (.34, .1), (.2, .16), (.001, .2)], GOLD, 20)
    k.puff(-.74, -.74, 0, .14)
    k.puff(.74, -.74, 0, .14)

# water
def birdbath(k):
    k.lathe("stone", 0, 0, 0, [(.24, 0), (.18, .08), (.09, .16), (.09, .46), (.3, .58), (.36, .64), (.3, .64)], SAND_PALE, 20)
    k.lathe("water", 0, 0, .6, [(.3, 0), (.3, .02)], WATER, 20)
    k.ball("matte", .1, 0, .7, .06, C("#E9EEF0"), 10, sy=1.2)
    k.ball("matte", .1, -.08, .77, .04, C("#E9EEF0"), 8)
def small_fountain(k):
    k.lathe("stone", 0, 0, 0, [(.42, 0), (.44, .2), (.36, .2)], SAND_PALE, 24)
    k.lathe("water", 0, 0, .04, [(.38, 0), (.38, .13)], WATER, 24)
    k.lathe("stone", 0, 0, .15, [(.09, 0), (.07, .34), (.2, .44), (.2, .48)], SAND_PALE, 16)
    k.lathe("water", 0, 0, .6, [(.17, 0), (.17, .025)], WATER_L, 16)
    k.tube("water", (0, 0, .62), (0, 0, .82), .035, .018, WATER_L, 8)
    for a in (0, 1.57, 3.14, 4.71):
        k.path("water", [(.17 * math.cos(a), .17 * math.sin(a), .62), (.24 * math.cos(a), .24 * math.sin(a), .25)], .018, WATER_L, 6)
def lily_pond(k):
    k.ring(0, 0, 0, .18, .86, .22, .18, .46, col=SAND_PALE)
    k.lathe("water", 0, 0, .01, [(.8, 0), (.8, .11)], WATER, 32)
    for x, y, r in ((-.3, -.22, .17), (.25, -.35, .14), (.34, .2, .18), (-.2, .3, .14), (.0, -.02, .12)):
        k.ball("leaf", x, y, .125, r, C("#3FB23C"), 14, sz=.07)
    bloom(k, -.3, -.22, .16, .09, C("#F58ABE"))
    bloom(k, .34, .2, .16, .09, C("#FFF0E0"))
    k.puff(.74, .74, 0, .11)
def duck_pond(k):
    k.lathe("matte", 0, 0, 0, [(.92, 0), (.86, .05)], C("#8D7A55"), 32)
    k.lathe("water", 0, 0, .03, [(.82, 0), (.82, .03)], WATER, 32)
    for x, y, c in ((-.24, -.18, C("#FAF6E8")), (.26, .14, C("#FFD93B"))):
        k.ball("matte", x, y, .14, .13, c, 12, sx=1.25, sz=.8)
        k.ball("matte", x + .1, y - .06, .27, .08, c, 10)
        k.ball("matte", x + .17, y - .1, .27, .035, C("#F28C1E"), 8, sx=1.3, sz=.6)
    for x, y in ((-.68, .55), (-.5, .7)):
        k.tube("leaf", (x, y, 0), (x, y, .46), .02, .012, C("#58BB37"), 6)
        k.tube("matte", (x, y, .46), (x, y, .6), .03, .03, C("#6E421E"), 8)
    k.puff(.72, -.68, 0, .1)
def spring_rocks(k):
    for x, y, z, r in ((-.24, .36, 0, .48), (.4, .3, 0, .36), (-.05, .5, .42, .36), (-.5, -.06, 0, .24)):
        rock(k, x, y, z, r)
    k.lathe("water", .05, -.32, .02, [(.52, 0), (.52, .05)], WATER, 28)
    k.ring(.05, -.32, 0, .12, .58, .14, .12, .3, col=GREY)
    k.box("water", .03, .12, .08, .34, .03, .86, WATER_L)
    k.box("water", .03, .34, .9, .34, .4, .03, WATER_L)
    k.puff(.74, .72, 0, .12)
    k.puff(-.74, .62, 0, .13)

# garden furniture
def bench(k):
    for x in (-.32, .32):
        k.box("wood", x, 0, 0, .1, .3, .26, WOOD)
        k.box("wood", x, .16, 0, .08, .06, .58, WOOD)
    for dy in (-.08, .06):
        k.box("wood", 0, dy, .26, .86, .13, .05, WOOD_L)
    for z in (.4, .52):
        k.box("wood", 0, .16, z, .86, .05, .09, WOOD_L)
def lantern(k):
    k.lathe("gold", 0, 0, 0, [(.13, 0), (.08, .1), (.03, .14)], BRONZE, 12)
    k.tube("gold", (0, 0, .1), (0, 0, .78), .028, .028, BRONZE, 8)
    k.box("gold", 0, 0, .78, .2, .2, .03, GOLD)
    k.box("glow", 0, 0, .81, .14, .14, .18, FLAME_L)
    k.lathe("gold", 0, 0, .99, [(.15, 0), (.001, .1)], GOLD, 4)
    k.lights.append(((.15, -.15, .9), .8))
def tiki(k):
    k.tube("wood", (0, 0, 0), (0, 0, .78), .05, .04, WOOD_L, 10)
    for z in (.18, .36):
        k.tube("wood", (0, 0, z), (0, 0, z + .03), .056, .056, WOOD_D, 10)
    k.lathe("matte", 0, 0, .74, [(.06, 0), (.13, .1), (.12, .13), (.08, .13)], BASKET, 12)
    k.flame(0, 0, .82, .1, .8)
def signpost(k):
    k.box("wood", 0, 0, 0, .1, .1, .96, WOOD)
    k.prism("wood", [(-.34, .68), (.28, .68), (.38, .77), (.28, .86), (-.34, .86)], -.03, .03, WOOD_L)
    with k.at(Matrix.Rotation(math.pi / 2, 4, "Z")):
        k.prism("wood", [(-.3, .44), (.26, .44), (.36, .52), (.26, .6), (-.3, .6)], -.03, .03, TEAL)
    k.ball("gold", 0, 0, .98, .06, GOLD, 10)
def flagpole(k):
    k.box("stone", 0, 0, 0, .34, .34, .14, SAND_PALE)
    k.tube("wood", (0, 0, .14), (0, 0, 1.46), .03, .022, WOOD_L, 8)
    k.ball("gold", 0, 0, 1.5, .05, GOLD, 10)
    k.surface("cloth", lambda u, v: (.42 * u, -.42 * u * .0 + .03 * math.sin(u * 6), 1.42 - .3 * v), 8, 3, lambda u, v: TEAL if .3 < v < .7 else GOLD)
def pump(k):
    k.box("stone", 0, 0, 0, .52, .4, .14, sand())
    k.tube("matte", (0, .06, .14), (0, .06, .7), .07, .06, C("#5F6E73"), 12)
    k.tube("matte", (0, .06, .54), (0, -.2, .5), .04, .03, C("#5F6E73"), 8)
    k.beam("wood", (0, .06, .72), (.34, .1, .86), .05, .05, WOOD_L)
    k.lathe("wood", -.02, -.26, .14, [(.09, 0), (.12, .16), (.1, .16)], WOOD_L, 12)
    k.lathe("water", -.02, -.26, .14, [(.09, 0), (.09, .13)], WATER, 12)
def picnic(k):
    for i in range(6):
        for j in range(6):
            k.box("cloth", -.72 + i * .24 + .12, -.72 + j * .24 + .12, 0, .24, .24, .02, RED if (i + j) % 2 else CANVAS)
    k.basket(-.32, .2, .02, .2)
    k.tube("glaze", (.24, .3, .02), (.24, .3, .24), .05, .05, TEAL, 10)
    k.tube("glaze", (.24, .3, .24), (.24, .3, .32), .022, .022, TEAL, 8)
    for x, y in ((.3, -.26), (-.1, -.3)):
        k.lathe("matte", x, y, .02, [(.1, 0), (.12, .02), (.1, .02)], CANVAS, 14)
        k.ball("matte", x, y, .06, .045, R.choice(FRUIT), 8)
    k.puff(.8, .8, 0, .12)
def hammock(k):
    for s in (-1, 1):
        k.tube("wood", (s * .74, 0, 0), (s * .74, 0, 1.1), .08, .06, WOOD, 10)
    k.palm(-.74, 0, 1.0, .28, .52, 7)
    k.palm(.74, 0, 1.0, .28, .52, 7)
    k.surface("cloth", lambda u, v: (-.62 + 1.24 * u, -.2 + .4 * v, .9 - .54 * math.sin(math.pi * u) + .08 * (2 * v - 1) ** 2), 12, 4, lambda u, v: TEAL if int(u * 8) % 2 else CANVAS)
    k.puff(.3, .7, 0, .13)
def pergola(k):
    for x, y in ((-.72, -.72), (.72, -.72), (.72, .72), (-.72, .72)):
        k.box("wood", x, y, 0, .16, .16, 1.2, WOOD)
    for y in (-.72, .72):
        k.box("wood", 0, y, 1.2, 1.9, .12, .12, WOOD_L)
    for x in (-.62, -.31, 0, .31, .62):
        k.box("wood", x, 0, 1.32, .09, 1.82, .09, WOOD_L)
    for x, y, r in ((-.5, -.42, .2), (.1, -.1, .24), (.5, .4, .22), (-.3, .4, .18), (.55, -.5, .17)):
        k.blob(x, y, 1.44, r)
    for x, y in ((-.4, -.68), (.28, -.68), (.72, -.2), (.7, .32)):
        k.tube("leaf", (x, y, 1.2), (x, y, .7), .014, .014, C("#3F8F2F"), 5)
        bloom(k, x, y, .68, .08, C("#B65AE0"))
    k.box("wood", 0, .1, .28, .9, .28, .05, WOOD_L)
    for x in (-.34, .34):
        k.box("wood", x, .1, 0, .1, .24, .28, WOOD)
def swing(k):
    for x in (-.74, .74):
        k.beam("wood", (x, -.32, 0), (x, 0, 1.28), .1, .1, WOOD)
        k.beam("wood", (x, .32, 0), (x, 0, 1.28), .1, .1, WOOD)
    k.beam("wood", (-.84, 0, 1.28), (.84, 0, 1.28), .14, .14, WOOD_L)
    for x in (-.42, .42):
        k.tube("matte", (x, 0, 1.22), (x, 0, .42), .018, .018, C("#D0AE72"), 6)
    k.box("wood", 0, 0, .38, 1.0, .3, .06, WOOD_L)
    k.box("cloth", 0, 0, .44, .86, .24, .04, RED)
    k.puff(-.78, .72, 0, .13)
    k.puff(.78, -.72, 0, .13)
def gazebo(k):
    k.lathe("stone", 0, 0, 0, [(.92, 0), (.88, .14), (.001, .14)], SAND_PALE, 8)
    for i in range(8):
        a = 2 * math.pi * i / 8 + math.pi / 8
        k.tube("stone", (.74 * math.cos(a), .74 * math.sin(a), .14), (.74 * math.cos(a), .74 * math.sin(a), 1.08), .05, .05, SAND_PALE, 10)
    k.lathe("gold", 0, 0, 1.08, [(.86, 0), (.86, .07)], GOLD, 8)
    k.lathe("glaze", 0, 0, 1.15, [(.98, 0), (.84, .08), (.1, .68)], TEAL, 8)
    k.lathe("gold", 0, 0, 1.82, [(.11, 0), (.04, .12), (.001, .32)], GOLD, 8)

# camp props
def crates(k):
    k.crate(-.14, -.1, 0, .44, .36, .1)
    k.crate(.2, .2, 0, .36, .3, -.25)
    k.crate(-.08, -.04, .42, .32, .26, .4)
def barrels(k):
    for x, y, z in ((-.2, -.12, 0), (.22, -.14, 0), (.0, .22, 0)):
        k.lathe("wood", x, y, z, [(.16, 0), (.2, .22), (.16, .44), (.13, .42)], WOOD_L, 14)
        k.lathe("gold", x, y, z + .18, [(.2, 0), (.205, .06)], C("#7A6A50"), 14)
def campfire(k):
    for i in range(8):
        a = 2 * math.pi * i / 8
        rock(k, .34 * math.cos(a), .34 * math.sin(a), 0, .1)
    k.beam("wood", (-.24, -.04, .06), (.22, .1, .16), .08, .08, WOOD_D)
    k.beam("wood", (.2, -.14, .06), (-.12, .18, .16), .08, .08, WOOD)
    k.flame(0, 0, .08, .17, 1.5)
def field_scope(k):
    for a in (0, 2.1, 4.2):
        k.beam("wood", (.3 * math.cos(a), .3 * math.sin(a), 0), (0, 0, .62), .05, .05, WOOD_L)
    aim, base = Vector((.7, .5, .5)).normalized(), Vector((-.12, -.08, .66))
    k.tube("gold", tuple(base), tuple(base + aim * .56), .05, .05, GOLD, 12)
    k.tube("gold", tuple(base + aim * .3), tuple(base + aim * .58), .08, .08, GOLD, 12)
    k.tube("matte", tuple(base + aim * .58), tuple(base + aim * .59), .06, .06, C("#16323A"), 12)
def globe(k):
    k.lathe("wood", 0, 0, 0, [(.26, 0), (.2, .06), (.05, .14), (.05, .3)], WOOD, 16)
    k.ball("glaze", 0, 0, .56, .24, TEAL_L, 18)
    k.path("gold", [(.3 * math.cos(t * math.pi / 8), 0, .56 + .3 * math.sin(t * math.pi / 8)) for t in range(-6, 7)], .02, GOLD, 6)
    for x, y, z, r in ((.1, -.18, .62, .09), (-.12, -.16, .5, .08), (.06, -.2, .44, .06)):
        k.ball("matte", x, y, z, r, C("#6FBF43"), 8, sy=.5)
def chest(k):
    k.box("wood", 0, 0, 0, .72, .46, .3, WOOD_L)
    k.tube("matte", (-.36, 0, .3), (.36, 0, .3), .23, .23, WOOD, 18)
    for x in (-.25, .25):
        k.box("gold", x, -.235, 0, .08, .02, .3, GOLD)
        k.tube("gold", (x - .04, 0, .3), (x + .04, 0, .3), .24, .24, GOLD, 14)
    k.box("gold", 0, -.24, .2, .12, .03, .14, GOLD)
    for x, y in ((.42, -.34), (.3, -.4), (.44, -.2), (-.42, -.38)):
        k.lathe("gold", x, y, 0, [(.06, 0), (.06, .02)], C("#FFD35C"), 10)
def supply_tent(k):
    k.prism("cloth", [(-.68, 0), (.68, 0), (0, .96)], -.72, .72, TEAL)
    k.poly("glow", [(.73, -.3, 0), (.73, .3, 0), (.73, 0, .62)], C("#C47A28"))
    for y0, z0 in ((-.3, 0), (.3, 0)):
        k.beam("cloth", (.75, y0, z0), (.75, 0, .62), .08, .03, GOLD)
    for x in (-.76, .78):
        k.tube("wood", (x, 0, 0), (x, 0, 1.02), .035, .035, WOOD, 8)
    k.crate(.78, -.72, 0, .28)
    k.puff(-.78, -.82, 0, .1)
def dig_site(k):
    k.lathe("matte", 0, 0, 0, [(.92, 0), (.82, .05), (.52, .09), (.5, .03), (.001, .03)], C("#A5825A"), 24)
    k.lathe("matte", 0, 0, .03, [(.48, 0), (.48, .004)], C("#3F2A18"), 24)
    k.box("stone", -.1, .06, .04, .3, .22, .12, SAND_PALE, .4)
    k.box("gold", .14, -.14, .04, .14, .14, .08, GOLD, .3)
    for x, y in ((-.74, -.74), (.74, -.74), (.74, .74), (-.74, .74)):
        k.box("wood", x, y, 0, .08, .08, .36, WOOD_L)
    k.beam("wood", (.62, .0, .12), (.28, -.42, .6), .04, .04, WOOD_L)
    k.box("matte", .63, .03, .02, .14, .14, .14, C("#7A8A8E"))
    k.crate(-.66, .3, 0, .26)
def rowboat(k):
    L, W = .92, .42
    def hull(u, v, s):
        x = -L + 2 * L * u
        t = abs(2 * u - 1) ** 2.2
        return (x, s * W * (1 - t * .9) * (1 - (1 - v) ** 2 * .6), .08 + (.28 + .08 * (2 * u - 1) ** 2) * v)
    for s in (-1, 1):
        k.surface("wood", lambda u, v, s=s: hull(u, v, s), 14, 4, lambda u, v: TEAL if v > .75 else J(WOOD_L, .04))
    k.surface("wood", lambda u, v: (lambda a, b: (a[0], a[1] + (b[1] - a[1]) * v, a[2] - .1))(hull(u, 1, -1), hull(u, 1, 1)), 14, 2, WOOD_D)
    for x in (-.3, .3):
        k.box("wood", x, 0, .3, .16, 2 * W * .9, .04, WOOD_L)
    k.beam("wood", (-.4, -.42, .05), (.5, -.62, .05), .05, .03, WOOD)
    k.puff(.8, .76, 0, .1)
def cart(k):
    with k.at(Matrix.Rotation(math.radians(0), 4, "Z")):
        k.box("wood", 0, 0, .34, 1.32, .86, .08, WOOD_L)
        for s in (-1, 1):
            k.box("wood", 0, s * .43, .42, 1.32, .06, .22, WOOD)
            k.box("wood", s * .66, 0, .42, .06, .86, .22, WOOD)
            with k.at(Matrix.Translation((.0, s * .5, .3)) @ Matrix.Rotation(math.pi / 2, 4, "X")):
                k.lathe("wood", 0, 0, -.03, [(.3, 0), (.3, .06)], WOOD_D, 18)
                k.lathe("gold", 0, 0, -.05, [(.07, 0), (.07, .1)], GOLD, 10)
        k.beam("wood", (.66, 0, .36), (.98, 0, .16), .07, .07, WOOD)
        for x, y in ((-.34, -.14), (.1, .2), (.36, -.18)):
            k.basket(x, y, .42, .17)

# animals
def turtle(k):
    rock(k, 0, .12, 0, .32, sz=.5)
    k.ball("glaze", 0, -.02, .24, .22, C("#3E8E5A"), 14, sy=1.2, sz=.62)
    k.ball("matte", .02, -.3, .2, .07, C("#8CBF5F"), 10)
    for x, y in ((-.18, -.18), (.18, -.18), (-.16, .18), (.16, .18)):
        k.ball("matte", x, y, .13, .05, C("#8CBF5F"), 8, sz=.6)
def perch(k, colour):
    k.box("stone", 0, 0, 0, .3, .3, .08, SAND_PALE)
    k.tube("wood", (0, 0, .08), (0, 0, .62), .03, .025, WOOD, 8)
    k.tube("wood", (-.26, 0, .62), (.26, 0, .62), .025, .025, WOOD_L, 8)
def toucan(k):
    perch(k, None)
    k.ball("matte", 0, 0, .78, .13, C("#22262B"), 14, sz=1.25)
    k.ball("matte", 0, -.1, .76, .08, C("#FFF0D0"), 10)
    k.ball("matte", 0, -.03, .96, .09, C("#22262B"), 12)
    k.lathe("matte", 0, -.08, .96, [(.055, 0), (.03, .22), (.001, .26)], C("#F28C1E"), 10, m=Matrix.Rotation(math.pi / 2, 4, "X"))
def parrot(k):
    perch(k, None)
    k.ball("matte", 0, 0, .78, .12, C("#D9302E"), 14, sz=1.35)
    k.ball("matte", 0, -.03, .98, .09, C("#D9302E"), 12)
    k.ball("matte", 0, -.11, .97, .035, C("#FFD93B"), 8)
    k.ball("matte", .12, .02, .76, .06, C("#2F7BE0"), 10, sz=1.6)
    k.ball("matte", -.12, .02, .76, .06, C("#2F7BE0"), 10, sz=1.6)
    k.lathe("matte", 0, .08, .66, [(.055, 0), (.02, -.3)], C("#2F7BE0"), 8)
def monkey(k):
    rock(k, 0, .05, 0, .32, sz=.56)
    c, f = C("#7A4E2A"), C("#E2BE92")
    z = .36
    k.ball("matte", 0, .04, z + .12, .14, c, 14, sz=1.2)
    k.ball("matte", 0, -.03, z + .34, .13, c, 14)
    k.ball("matte", 0, -.11, z + .32, .08, f, 10, sz=.8)
    for s in (-1, 1):
        k.ball("matte", s * .13, -.03, z + .38, .05, f, 8)
        k.tube("matte", (s * .12, -.0, z + .18), (s * .2, -.12, z + .02), .035, .03, c, 8)
        k.tube("matte", (s * .08, -.04, z + .04), (s * .13, -.2, z - .02), .04, .035, c, 8)
    k.path("matte", [(0, .16, z + .08), (.18, .24, z + .06), (.28, .14, z + .2)], .022, c, 6)
def capybara(k):
    c, f = C("#9A6E44"), C("#6E4A2A")
    k.ball("matte", 0, .08, .24, .2, c, 14, sy=1.5, sz=.95)
    k.ball("matte", 0, -.26, .28, .13, c, 12, sy=1.2)
    k.ball("matte", 0, -.38, .26, .065, f, 8)
    for s in (-1, 1):
        k.ball("matte", s * .09, -.2, .4, .03, f, 8)
        for y in (-.1, .24):
            k.tube("matte", (s * .12, y, 0), (s * .12, y, .14), .04, .04, f, 8)

# rocks
def boulder(k):
    rock(k, -.04, .06, 0, .36)
    rock(k, .24, -.2, 0, .17)
    k.blob(-.2, -.14, .08, .09)
def crystal(k):
    rock(k, 0, .06, 0, .3, sz=.55)
    for x, y, h, r, c in ((0, 0, .72, .1, TEAL_L), (.15, -.1, .46, .08, C("#7FE0F5")), (-.15, -.1, .54, .08, TEAL), (.02, -.22, .32, .06, C("#7FE0F5"))):
        k.lathe("water", x, y, .14, [(r, 0), (r * 1.15, h * .7), (.001, h)], c, 6, smooth=False)
    k.lights.append(((.0, -.3, .4), .6))
def mossy_rocks(k):
    for x, y, r in ((-.3, .26, .58), (.42, .22, .38), (.1, -.34, .34), (-.56, -.42, .22)):
        rock(k, x, y, 0, r)
    for x, y, z, r in ((-.28, .08, .68, .22), (-.05, .44, .62, .22), (.44, .05, .44, .14), (.1, -.42, .36, .13)):
        k.ball("leaf", x, y, z, r, C("#6FBF43"), 12, sz=.42)
    k.puff(.76, -.74, 0, .12)


# The catalogue is the list of what exists: name, category, footprint, price, unlock.
CATALOGUE = [dict(zip(("key", "title", "cat", "w", "h", "gold", "stars", "like"), row))
             for row in json.loads((HERE / "catalogue.json").read_text())]
BASED = ("wonder", "building")   # these stand on a slab; decorations stand on the grass

assemble("RelicRushBuildings", CATALOGUE, {it["key"]: globals()[it["key"]] for it in CATALOGUE},
         blend_argument(HERE / "relic_rush_buildings.blend"), slab=lambda it: it["cat"] in BASED)
