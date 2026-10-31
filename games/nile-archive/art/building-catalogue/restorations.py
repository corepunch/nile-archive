# Nile Archive's five story restorations, imported by build_scene.py.
#
# The models follow the painted references in art/building-0.png ... building-4.png.
# The order of BUILDINGS is the order the game indexes them by.
import math

from mathutils import Matrix, Vector

from building_kit import *


BUILDINGS = [
    dict(key="gardener_house", title="Gardener's house", w=2, h=2),
    dict(key="isis_temple", title="Temple of Isis", w=3, h=2),
    dict(key="archive", title="Archive", w=3, h=2),
    dict(key="fountain", title="Fountain", w=2, h=2),
    dict(key="workshop", title="Workshop", w=2, h=2),
]

P = G + .03   # the top of the pavers: everything on the ground starts here or lower

STUCCO, STUCCO_D = C("#F4EBD8"), C("#D9C8A6")
PAVER = C("#E6CFA2")
SAND_WALL, SAND_TOP = C("#DFBF84"), C("#EAD29E")
TURQUOISE, TURQUOISE_L = C("#18ABB0"), C("#62DCD0")
BASALT, BASALT_L = C("#4A4250"), C("#6A5E68")
TERRACOTTA, TERRACOTTA_D = C("#C4683C"), C("#94472A")
SOIL = C("#3A2614")
EARTH = C("#8C6A42")
WHITE_FLOWER, PINK, MAGENTA, YELLOW = C("#FFF6E6"), C("#E77FC0"), C("#D93A8E"), C("#FFD35C")
LINEN = C("#F4EEE2")
PAD = C("#3FA648")
EMBER = C("#3A1608")


# ------------------------------------------------------------------ ground and masses

def paving(k, tile=.33):
    """Pale pavers over the whole slab, with gaps down to the darker slab."""
    nx, ny = round(k.w / tile), round(k.h / tile)
    sx, sy = k.w / nx, k.h / ny
    for i in range(nx):
        for j in range(ny):
            k.box("stone", -k.w / 2 + (i + .5) * sx, -k.h / 2 + (j + .5) * sy, G - .005, sx - .022, sy - .022, .035, J(PAVER, .035))


def tray(k, mat, x0, x1, y0, y1, z0, z1, t, zf, col):
    """A box with a sunken top: the walls and the floor are one mesh, so no seams."""
    i0, i1, j0, j1 = x0 + t, x1 - t, y0 + t, y1 - t
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1),
         (i0, j0, z1), (i1, j0, z1), (i1, j1, z1), (i0, j1, z1),
         (i0, j0, zf), (i1, j0, zf), (i1, j1, zf), (i0, j1, zf)]
    f = [(3, 2, 1, 0), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7),
         (4, 5, 9, 8), (5, 6, 10, 9), (6, 7, 11, 10), (7, 4, 8, 11),
         (8, 9, 13, 12), (9, 10, 14, 13), (10, 11, 15, 14), (11, 8, 12, 15), (12, 13, 14, 15)]
    k.add(mat, v, f, col)


def arch_wall(k, mat, cx, r, rz, y0, y1, zs, zt, col, n=14):
    """The wall over an opening: an arc below, flat on top. One mesh; piers go either side."""
    v = []
    for i in range(n + 1):
        a = math.pi * (1 - i / n)
        x, z = cx + r * math.cos(a), zs + rz * math.sin(a)
        v += [(x, y0, zt), (x, y0, z), (x, y1, zt), (x, y1, z)]
    f = []
    for i in range(n):
        s = 4 * i
        f += [(s + 1, s + 5, s + 4, s), (s + 3, s + 2, s + 6, s + 7), (s + 3, s + 7, s + 5, s + 1), (s, s + 4, s + 6, s + 2)]
    f += [(0, 2, 3, 1), (4 * n + 1, 4 * n + 3, 4 * n + 2, 4 * n)]
    k.add(mat, v, f, col)


def arch_trim(k, mat, cx, r, rz, y, zs, t, d, col, n=14):
    """A flat band following an elliptical arch, on a wall facing -y."""
    v = []
    for i in range(n + 1):
        a = math.pi * (1 - i / n)
        ca, sa = math.cos(a), math.sin(a)
        for rr, zz in ((r, rz), (r + t, rz + t)):
            v += [(cx + rr * ca, y - d, zs + zz * sa), (cx + rr * ca, y, zs + zz * sa)]
    f = []
    for i in range(n):
        s = 4 * i
        f += [(s, s + 4, s + 6, s + 2), (s + 3, s + 7, s + 5, s + 1), (s + 2, s + 6, s + 7, s + 3), (s + 1, s + 5, s + 4, s)]
    k.add(mat, v, f, col)


def band(k, mat, x, y, z, prof, col, n=22):
    """A revolved profile with no caps: a rim or a hoop that leaves the inside open."""
    def fn(u, v):
        f = v * (len(prof) - 1)
        i = min(int(f), len(prof) - 2)
        r = prof[i][0] + (prof[i + 1][0] - prof[i][0]) * (f - i)
        h = prof[i][1] + (prof[i + 1][1] - prof[i][1]) * (f - i)
        t = 2 * math.pi * u
        return (x + r * math.cos(t), y + r * math.sin(t), z + h)
    k.surface(mat, fn, n, max(2, (len(prof) - 1) * 2), col)


def dome_blocks(k, cx, cy, z, r, courses=6, width=.3, sink=.03, col=None):
    """A brick dome: one solid shell with fat, separate blocks over it."""
    k.lathe("stone", cx, cy, z, [(max(r * math.cos(math.pi / 2 * i / 10), .001), r * math.sin(math.pi / 2 * i / 10)) for i in range(11)], SAND_DK, 28)
    ri, ro = r - sink, r + sink
    top = math.pi / 2 * .9
    for j in range(courses):
        a0, a1 = top * j / courses + .012, top * (j + 1) / courses - .012
        count = max(5, round(2 * math.pi * r * math.cos(a0) / width))
        for i in range(count):
            t0 = 2 * math.pi * (i + (.5 if j % 2 else 0)) / count + .012
            t1 = t0 + 2 * math.pi / count - .024
            pts = []
            for a in (a0, a1):
                for rad, t in ((ro, t0), (ro, t1), (ri, t1), (ri, t0)):
                    pts.append((cx + rad * math.cos(a) * math.cos(t), cy + rad * math.cos(a) * math.sin(t), z + rad * math.sin(a)))
            f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
            k.add("stone", pts, f, col() if col else sand())


# ------------------------------------------------------------------ plants

def frond(k, top, a, L, rise=.32, droop=.8, width=.2, spread=1.):
    out = Vector((math.cos(a), math.sin(a), 0))
    side = Vector((-out.y, out.x, 0))
    base = J(R.choice(LEAVES), .04)
    def fn(u, v):
        w = L * width * math.sin(math.pi * min(v * .92 + .08, 1))
        p = top + out * L * v * spread + Vector((0, 0, L * (rise * v - droop * v * v)))
        return tuple(p + side * (u - .5) * 2 * w - Vector((0, 0, abs(u - .5) * w * .6)))
    k.surface("leaf", fn, 2, 7, lambda u, v: tuple(c * (.72 + .4 * (1 - abs(u - .5) * 2)) for c in base))


def reach(k, x, y, a, L):
    """The length a frond at angle a can have before it leaves the footprint."""
    best = L
    ca, sa = math.cos(a), math.sin(a)
    if abs(ca) > 1e-3:
        best = min(best, ((k.w / 2 if ca > 0 else -k.w / 2) - x) / ca)
    if abs(sa) > 1e-3:
        best = min(best, ((k.h / 2 if sa > 0 else -k.h / 2) - y) / sa)
    return max(best * .97, .05)


def palm(k, x, y, z, h=1., L=.5, fronds=9, r=.085):
    """Like the kit's palm, but stays where it is put: fronds near an edge stand more upright."""
    top = Vector((x, y, z + h))
    k.tube("wood", (x, y, z), tuple(top), r, r * .68, WOOD, 10)
    for i in range(fronds):
        a = 2 * math.pi * i / fronds + R.uniform(-.12, .12)
        q = reach(k, x, y, a, L) / L
        size = L * (.6 + .4 * q)   # near an edge a frond stands up instead of being cut short
        frond(k, top, a, size, rise=.32 + (1 - q) * .95, spread=L * q / size)
    for i in range(max(3, fronds // 2)):
        a = 2 * math.pi * (i + .5) / max(3, fronds // 2) + R.uniform(-.2, .2)
        frond(k, top + Vector((0, 0, .03)), a, reach(k, x, y, a, L * .62), rise=.85, droop=.9)
    k.blob(top.x, top.y, top.z, r * 1.05)


def fern(k, x, y, z, L=.3, n=7):
    """A leafy pot plant: upright outer leaves and a tuft in the middle."""
    top = Vector((x, y, z))
    for i in range(n):
        a = 2 * math.pi * i / n + R.uniform(-.15, .15)
        frond(k, top, a, reach(k, x, y, a, L), rise=1.15, droop=.8, width=.2)
    for i in range(max(3, n // 2)):
        a = 2 * math.pi * (i + .5) / max(3, n // 2) + R.uniform(-.2, .2)
        frond(k, top, a, reach(k, x, y, a, L * .62), rise=2.1, droop=1.1, width=.2)


def bush(k, x, y, z, r, flower, flowers=8, sz=.85):
    """A round shrub dotted with flowers."""
    for i in range(3):
        a = 2 * math.pi * i / 3 + R.uniform(0, 1)
        k.blob(x + r * .4 * math.cos(a), y + r * .4 * math.sin(a), z + r * .5, r * .62)
    k.blob(x, y, z + r * .85, r * .68)
    for i in range(flowers):
        a = 2 * math.pi * i / flowers + R.uniform(-.3, .3)
        e = R.uniform(.25, 1.25)
        k.ball("matte", x + r * .95 * math.cos(a) * math.cos(e), y + r * .95 * math.sin(a) * math.cos(e), z + r * .55 + r * .85 * math.sin(e), max(r * .2, .045), J(flower, .03), 10)


def vine(k, x, y, ztop, length, flower=None, sway=.08, n=5, r=.1, face=(0, -1)):
    """Greenery trailing down a wall from ztop; the wall's outside is `face`."""
    fx, fy = face
    for i in range(n):
        t = i / max(n - 1, 1)
        s = sway * math.sin(t * 5 + x * 7)
        px, py = x + s * abs(fy), y + s * abs(fx)
        rr = r * (1 - .35 * t)
        k.ball("leaf", px + fx * rr * .3, py + fy * rr * .3, ztop - length * t, rr, J(R.choice(LEAVES), .04), 12, sx=1 if fy else .6, sy=1 if fx else .6)
        if flower:
            for j in range(2):
                dz = R.uniform(-.6, .6) * rr
                ds = R.uniform(-.8, .8) * rr
                k.ball("matte", px + fx * rr * .75 + ds * abs(fy), py + fy * rr * .75 + ds * abs(fx), ztop - length * t + dz, .045, J(flower, .03), 10)


# ------------------------------------------------------------------ props

def pot(k, x, y, z, r, col=TERRACOTTA, band=None, mat="clay"):
    """A round planter; returns the height of the soil to plant in."""
    k.lathe(mat, x, y, z, [(r * .62, 0), (r * .94, r * .62), (r * 1.02, r * 1.05), (r * .84, r * 1.42), (r * .96, r * 1.56), (r * .96, r * 1.68), (r * .82, r * 1.68)], col, 18)
    if band:
        k.lathe("gold", x, y, z + r * .78, [(r * 1.0, 0), (r * 1.05, r * .1), (r * 1.05, r * .3), (r * 1.0, r * .4)], band, 18)
    k.lathe("matte", x, y, z + r * 1.6, [(r * .82, 0), (r * .82, r * .09)], SOIL, 14)
    return z + r * 1.69


def vase(k, x, y, z, s, col=TERRACOTTA, band=None, mat="clay"):
    """A big-bellied jar with a narrow neck."""
    k.lathe(mat, x, y, z, [(s * .45, 0), (s * .95, s * .7), (s, s * 1.0), (s * .78, s * 1.5), (s * .42, s * 1.82), (s * .42, s * 2.0), (s * .56, s * 2.14), (s * .36, s * 2.14)], col, 18)
    if band:
        k.lathe("gold", x, y, z + s * .84, [(s * .98, 0), (s * 1.03, s * .08), (s * 1.03, s * .24), (s * .96, s * .34)], band, 18)
    k.lathe("matte", x, y, z + s * 2.06, [(s * .37, 0), (s * .37, s * .09)], DARK, 12)


def table(k, x, y, z, sx, sy, h, top=WOOD_L, leg=WOOD):
    k.box("wood", x, y, z + h, sx, sy, .06, top)
    for a in (-1, 1):
        for b in (-1, 1):
            k.box("wood", x + a * (sx / 2 - .05), y + b * (sy / 2 - .05), z, .08, .08, h, leg)
    return z + h + .06


def planter(k, x, y, z, sx, sy, h, flower, flowers=7):
    k.box("stone", x, y, z, sx, sy, h, J(SAND_PALE, .03))
    k.box("stone", x, y, z + h, sx + .03, sy + .03, .035, PAVER)
    k.box("glaze", x, y - sy / 2 - .008, z + h * .3, sx * .7, .025, h * .4, TEAL)
    k.lathe("matte", x, y, z + h + .03, [(min(sx, sy) * .48, 0), (min(sx, sy) * .48, .012)], SOIL, 12, sx=max(sx / sy, 1), sy=max(sy / sx, 1))
    bush(k, x, y, z + h + .02, min(sx, sy) * .62, flower, flowers)


def bookshelf(k, cx, y, z0, w, h, rows=3):
    """A wooden shelf against a wall, opening towards local -y."""
    d = .12
    k.box("wood", cx, y + .01, z0, w, .05, h, WOOD_D)
    for s in (-1, 1):
        k.box("wood", cx + s * (w / 2 - .035), y - d / 2, z0, .08, d + .02, h, WOOD_L)
    k.box("wood", cx, y - d / 2, z0 + h, w + .05, d + .05, .07, WOOD_L)
    rh = (h - .05) / rows
    for r in range(rows):
        z = z0 + r * rh
        k.box("wood", cx, y - d / 2 - .002, z, w - .08, d, .05, WOOD)
        x = cx - w / 2 + .09
        while x < cx + w / 2 - .12:
            bw = R.choice((.09, .11, .13))
            if x + bw > cx + w / 2 - .08:
                break
            k.box("matte", x + bw / 2, y - d / 2 + .004, z + .05, bw * .92, d * .8, rh * R.uniform(.62, .82), R.choice((RED, TEAL, CANVAS, GOLD, TURQUOISE, CLAY_L)))
            x += bw


def swag(k, x_out, x_in, y, z_top, z_bot, col, folds=2.5, depth=.022):
    """A drape gathered towards its outer side: wide at the top, narrow below."""
    def fn(u, v):
        wid = 1 - .86 * v ** .75
        x = x_out + (x_in - x_out) * u * wid
        return (x, y + depth * math.sin(u * math.pi * 2 * folds), z_top - (z_top - z_bot) * v)
    k.surface("cloth", fn, 10, 6, col)


def curtain(k, x, y, ztop, zbot, w, col=LINEN, folds=2.5):
    """A loose linen curtain hanging from ztop, falling in folds and gathered low down."""
    def fn(u, v):
        wid = w * (1 - .55 * math.sin(math.pi * min(v * 1.2, 1)) ** 2)
        return (x + (u - .5) * wid, y + .03 * math.sin(u * math.pi * 2 * folds), ztop - (ztop - zbot) * v)
    k.surface("cloth", fn, 12, 6, col)


def brazier_bowl(k, x, y, z, r=.17, s=.13, light=3.):
    k.lathe("gold", x, y, z, [(r * .35, 0), (r * .5, r * .3), (r, r * .75), (r * 1.08, r), (r * .85, r)], GOLD, 18)
    k.lathe("matte", x, y, z + r * .92, [(r * .85, 0), (r * .85, r * .05)], EMBER, 14)
    k.flame(x, y, z + r * .92, s, light)


def papyrus_column(k, x, y, z0, z1, r=.135):
    """Sandstone shaft, gold base rings, a flaring teal capital with a gold collar."""
    h = z1 - z0
    k.lathe("gold", x, y, z0, [(r * 1.55, 0), (r * 1.55, .05), (r * 1.25, .1), (r * 1.25, .14)], GOLD, 20)
    k.lathe("glaze", x, y, z0 + .1, [(r * 1.18, 0), (r * 1.18, .1), (r * 1.08, .13)], TEAL, 20)
    k.lathe("stone", x, y, z0 + .2, [(r * 1.1, 0), (r, h * .34), (r * .9, h - .54)], SAND_WALL, 20)
    zc = z0 + h - .38
    k.lathe("gold", x, y, zc, [(r * .98, 0), (r * 1.06, .03), (r * 1.06, .07), (r * .96, .09)], GOLD, 20)
    k.lathe("glaze", x, y, zc + .07, [(r * .96, 0), (r * 1.12, .08), (r * 1.55, .24)], TEAL, 20)
    k.lathe("gold", x, y, zc + .29, [(r * 1.58, 0), (r * 1.66, .03), (r * 1.66, .08), (r * 1.3, .09)], GOLD, 20)
    k.box("stone", x, y, zc + .36, r * 2.5, r * 2.5, h - (zc + .36 - z0) + .01, SAND_TOP)


def block_top(k, x0, x1, y0, y1, z, col, tile=.36, th=.04):
    """A roof or floor laid in separate big blocks, the top of each at z + th."""
    nx, ny = max(1, round((x1 - x0) / tile)), max(1, round((y1 - y0) / tile))
    sx, sy = (x1 - x0) / nx, (y1 - y0) / ny
    for i in range(nx):
        for j in range(ny):
            k.box("stone", x0 + (i + .5) * sx, y0 + (j + .5) * sy, z, sx - .02, sy - .02, th, J(col, .03))


def block_ring(k, x0, x1, y0, y1, z0, z1, t, col):
    """A kerb of big blocks round a rectangle; the sides never overlap at the corners."""
    h = z1 - z0
    k.wall((x0, y0 + t / 2), (x1, y0 + t / 2), z0, z1, t=t, course=h, length=.56, col=col)
    k.wall((x1 - t / 2, y0 + t), (x1 - t / 2, y1 - t), z0, z1, t=t, course=h, length=.56, col=col)
    k.wall((x1, y1 - t / 2), (x0, y1 - t / 2), z0, z1, t=t, course=h, length=.56, col=col)
    k.wall((x0 + t / 2, y1 - t), (x0 + t / 2, y0 + t), z0, z1, t=t, course=h, length=.56, col=col)


def seated_statue(k, x, y, z):
    """A dark enthroned Isis facing -y: plinth, throne, lap, torso, gold collar and sun disc."""
    k.box("stone", x, y, z, .5, .56, .1, J(SAND_WALL, .03))
    k.box("gold", x, y, z + .1, .46, .52, .05, GOLD)
    zs = z + .15
    k.box("glaze", x, y + .17, zs, .34, .16, .62, BASALT)                # the throne's back
    k.box("glaze", x, y + .02, zs, .36, .3, .3, BASALT)                  # the seat
    k.box("glaze", x, y - .1, zs + .3, .3, .26, .1, BASALT_L)            # the lap
    k.box("glaze", x, y - .18, zs, .28, .1, .32, BASALT_L)               # the shins
    k.lathe("glaze", x, y + .03, zs + .36, [(.14, 0), (.13, .16), (.16, .28), (.1, .36)], BASALT_L, 16, sy=.72)
    for s in (-1, 1):
        k.tube("glaze", (x + s * .16, y + .03, zs + .62), (x + s * .15, y - .17, zs + .42), .05, .045, BASALT_L, 10)
    k.lathe("gold", x, y + .03, zs + .62, [(.12, 0), (.17, .05), (.11, .1)], GOLD, 18, sy=.78)
    k.lathe("glaze", x, y + .05, zs + .68, [(.11, 0), (.13, .18), (.09, .28)], TEAL_D, 14, sy=.8)   # the wig
    k.ball("glaze", x, y - .01, zs + .82, .095, C("#8A7468"), 14)
    k.lathe("gold", x, y + .03, zs + .93, [(.1, 0), (.11, .03), (.07, .07)], GOLD, 14)
    k.ball("gold", x, y + .03, zs + 1.08, .09, YELLOW, 14)


# ------------------------------------------------------------------ buildings

def gardener_house(k):
    paving(k)
    x0, x1, y0, y1 = -.62, .66, -.5, .62
    zt, zf = G + 1.26, G + 1.06
    tray(k, "stone", x0, x1, y0, y1, G, zt, .12, zf, STUCCO)
    # the sandstone showing through the stucco, low down and at the corners
    for x, z, w, h in ((-.5, G + .22, .22, .14), (-.34, G + .62, .2, .11), (.32, G + .16, .22, .14), (.46, G + .98, .2, .12), (-.46, G + .9, .2, .12)):
        k.box("stone", x, y0 - .004, z, w, .03, h, J(STUCCO_D, .04))
    for y, z, w, h in ((-.2, G + .2, .22, .14), (.34, G + .12, .24, .13), (.1, G + 1.0, .22, .12)):
        k.box("stone", x1 + .004, y, z, .03, w, h, J(STUCCO_D, .04))
    k.box("wood", (x0 + x1) / 2, (y0 + y1) / 2, zf - .02, x1 - x0 - .14, y1 - y0 - .14, .05, EARTH)
    # the door, with a sandstone frame and a lintel
    dx = -.1
    k.box("stone", dx, y0 - .02, P, .54, .05, .78, J(SAND_PALE, .02))
    k.box("wood", dx, y0 - .05, P, .36, .05, .68, WOOD_L)
    for s in (-.085, .085):
        k.box("wood", dx + s, y0 - .065, P + .08, .13, .03, .24, WOOD)
        k.box("wood", dx + s, y0 - .065, P + .37, .13, .03, .24, WOOD)
    k.ball("gold", dx + .13, y0 - .09, P + .33, .035, GOLD, 10)
    k.box("stone", dx, y0 - .045, P + .78, .66, .1, .1, SAND_PALE)
    # stacked blocks either side of the door, a step and a turquoise mat
    k.box("stone", dx, y0 - .1, G, .5, .12, .08, J(SAND_PALE, .02))
    for s, h in ((-1, 3), (1, 2)):
        for i in range(h):
            k.box("stone", dx + s * .37, y0 - .13 + i * .02, G + i * .1, .2, .2, .1, J(SAND_PALE, .03))
    k.box("cloth", dx, -.84, P, .54, .24, .025, TURQUOISE)
    k.box("cloth", dx, -.84, P + .025, .38, .13, .012, GOLD)
    # the window on +x
    with k.at(wall_frame((x1, y0), (x1, y1))):
        k.window(.56, G + .52, G + .72, .17, fill=C("#2A5E62"), fill_mat="glaze", trim=SAND_PALE)
    # flowering creepers over the front wall and down the corner
    vine(k, -.42, y0 - .02, zt - .04, .6, WHITE_FLOWER, n=5, r=.11)
    vine(k, .4, y0 - .02, zt - .04, .55, WHITE_FLOWER, n=4, r=.11)
    for x, y in ((-.42, y0 + .03), (.4, y0 + .03)):
        k.ball("leaf", x, y, zt + .03, .12, LEAVES[1], 12, sy=.9, sz=.7)
    vine(k, x1 + .02, -.08 + .5, zt - .03, .32, None, n=3, r=.09, face=(1, 0))
    # the roof terrace: cushions and sacks under the canopy
    cz = zf + .03
    k.box("cloth", -.3, -.1, cz, .36, .62, .09, TEAL_D)
    k.box("cloth", -.34, .02, cz + .09, .2, .3, .1, TURQUOISE)
    k.box("cloth", -.32, -.26, cz + .09, .2, .18, .08, TEAL_L)
    k.box("stone", .28, .22, cz, .34, .26, .1, J(SANDS[1], .03))
    k.box("stone", .06, .36, cz, .26, .22, .08, J(SANDS[2], .03))
    k.box("stone", .36, -.1, cz, .22, .24, .07, J(SANDS[0], .03))
    # four posts, a teal canvas sagging between them, gold-hemmed
    px0, px1, py0, py1 = x0 + .13, x1 - .13, y0 + .13, y1 - .13
    zc = zt + .56
    for x in (px0, px1):
        for y in (py0, py1):
            h = zc - zf + (.08 if y > 0 else 0)
            k.tube("wood", (x, y, zf), (x, y, zf + h), .05, .045, WOOD_L, 10)
            k.ball("wood", x, y, zf + h + .01, .06, WOOD, 10)
    k.box("wood", (px0 + px1) / 2, py0, zc - .05, px1 - px0 + .2, .08, .08, WOOD)
    k.box("wood", (px0 + px1) / 2, py1, zc + .03, px1 - px0 + .2, .08, .08, WOOD)
    e = .05
    def cloth_height(u, v):
        return zc + .05 + .08 * v - .05 * math.sin(math.pi * u) * math.sin(math.pi * v)
    def cloth(u, v):
        return (px0 - e + (px1 - px0 + 2 * e) * u, py0 - e + (py1 - py0 + 2 * e) * v, cloth_height(u, v))
    def cloth_col(u, v):
        return GOLD if .05 < min(u, 1 - u) < .1 else (TURQUOISE if min(v, 1 - v) > .1 else TURQUOISE_L)
    k.surface("cloth", cloth, 60, 20, cloth_col)
    # the hems: a hanging valance along -y and +x
    k.box("cloth", (px0 + px1) / 2, py0 - e - .01, zc - .04, px1 - px0 + 2 * e, .035, .09, TEAL)
    k.box("gold", (px0 + px1) / 2, py0 - e - .02, zc - .06, px1 - px0 + 2 * e, .03, .035, GOLD)
    k.box("cloth", px1 + e + .01, (py0 + py1) / 2, zc - .04, .035, py1 - py0 + 2 * e, .09, TEAL)
    # palms behind
    palm(k, -.8, .06, G, 2.0, .74, 12, r=.1)
    palm(k, .84, .8, G, 1.5, .34, 9, r=.07)
    # planters
    top = pot(k, -.8, -.7, P, .17)
    fern(k, -.8, -.7, top, .2, 9)
    top = pot(k, -.84, -.3, P, .12)
    fern(k, -.84, -.3, top, .16, 7)
    top = pot(k, -.5, -.84, P, .11, TEAL, GOLD, "glaze")
    fern(k, -.5, -.84, top, .16, 5)
    top = pot(k, .32, -.72, P, .14)
    fern(k, .32, -.72, top, .28, 8)
    # the lily bowl at the front corner
    k.lathe("glaze", .72, -.76, P, [(.1, 0), (.2, .08), (.215, .15), (.19, .17), (.17, .12)], TEAL, 22)
    band(k, "gold", .72, -.76, P + .09, [(.205, 0), (.225, .03), (.215, .06)], TERRACOTTA, 22)
    k.lathe("water", .72, -.76, P + .12, [(.178, 0), (.178, .015)], TURQUOISE, 20)
    for x, y in ((.67, -.8), (.78, -.72)):
        k.lathe("leaf", x, y, P + .135, [(.06, 0), (.06, .008)], PAD, 12)
    k.ball("matte", .7, -.7, P + .16, .04, PINK, 10)
    # the +x side: a little table, pots
    tz = table(k, .84, -.04, P, .26, .4, .24)
    k.box("stone", .84, -.04, tz, .16, .22, .03, TEAL_L)
    k.lathe("clay", .84, -.14, tz, [(.03, 0), (.05, .05), (.03, .1)], TERRACOTTA, 12)
    top = pot(k, .86, -.44, P, .1, TERRACOTTA_D)
    fern(k, .86, -.44, top, .14, 6)
    top = pot(k, .84, .36, P, .14)
    fern(k, .84, .36, top, .16, 8)


def isis_temple(k):
    paving(k)
    zp = G + .32
    h_col = 1.56
    zc = zp + h_col
    # the platform: wide in the middle, set back at the corners for the plants
    k.box("stone", 0, .2, G, 2.0, 1.52, zp - G - .03, SAND_DK)
    for s in (-1, 1):
        k.box("stone", s * 1.22, .39, G, .44, 1.14, zp - G - .03, SAND_DK)
    k.wall((-1.0, -.56), (1.0, -.56), G, zp - .04, t=.06, course=.14, length=.42)
    k.wall((1.45, -.17), (1.45, .96), G, zp - .04, t=.05, course=.14, length=.42)
    block_top(k, -1.03, 1.03, -.59, .98, zp - .03, PAVER, .34)
    for s in (-1, 1):
        block_top(k, min(s * 1.03, s * 1.47), max(s * 1.03, s * 1.47), -.2, .98, zp - .03, PAVER, .34)
    # the stair, each riser with a teal stripe
    for i in range(3):
        yf = -.97 + i * .125
        zs = P + (i + 1) * .075
        k.box("stone", 0, (yf - .55) / 2, G, 1.06, -.55 - yf, zs - G, J(SAND_TOP, .02))
        k.box("glaze", 0, yf - .01, zs - .06, .82, .03, .05, TEAL)
    # pedestals with braziers, glyph plaques facing the camera
    for s in (-1, 1):
        x = s * .74
        k.box("stone", x, -.76, G, .38, .38, .42, J(SAND_WALL, .02))
        k.box("stone", x, -.76, G + .42, .42, .42, .05, SAND_TOP)
        k.box("glaze", x, -.76 - .19, G + .1, .22, .03, .22, TEAL)
        k.emblem(x, -.76 - .207, G + .21, .075)
        k.box("glaze", x + .19, -.76, G + .1, .03, .22, .22, TEAL)
        k.ball("gold", x + .21, -.76, G + .21, .06, GOLD, 12, sx=.4)
        brazier_bowl(k, x, -.76, G + .47, .16, .13, 1.4)
    # the piers behind the statues, each with a lotus panel
    for s in (-1, 1):
        x = s * .9
        k.box("stone", x, .34, zp, .42, .68, h_col, sand())
        k.box("glaze", x, -.015, zp + .62, .22, .03, .84, TEAL)
        k.box("gold", x, -.03, zp + .95, .08, .03, .46, GOLD)
        k.emblem(x, -.045, zp + 1.3, .085)
        k.box("glaze", x + s * .215, .34, zp + .5, .03, .34, .8, TEAL)
        k.ball("gold", x + s * .235, .34, zp + .9, .08, GOLD, 12, sx=.4)
        seated_statue(k, x, -.29, zp)
    # the back wall, with a teal-curtained doorway
    k.box("stone", 0, .8, zp, 2.9, .34, h_col, SAND_WALL)
    k.box("stone", 0, .44, zp, 1.14, .42, h_col, SAND_WALL)   # the sanctum, its doorway curtained in teal
    k.box("matte", 0, .215, zp, .94, .03, h_col - .1, C("#1B3A40"))
    def drape(u, v, x0, x1):
        return (x0 + (x1 - x0) * u, .195 - .025 * math.sin(u * math.pi * 7), zp + (h_col - .1) * (1 - v))
    for x0, x1 in ((-.46, -.08), (.08, .46)):
        k.surface("cloth", lambda u, v, x0=x0, x1=x1: drape(u, v, x0, x1), 14, 3, lambda u, v: GOLD if .42 < u < .58 else TURQUOISE)
    # the columns: a pair in front, a pair at the sanctum door, the corners
    for x, y in ((-.43, -.4), (.43, -.4), (-.62, .14), (.62, .14), (-1.25, -.03), (1.25, -.03), (-1.25, .72), (1.25, .72)):
        papyrus_column(k, x, y, zp, zc)
    # the +x wall between the corner columns, low and carved
    k.box("stone", 1.27, .35, zp, .12, .6, .42, J(SAND_WALL, .02))
    k.box("glaze", 1.335, .35, zp + .12, .03, .4, .18, TEAL)
    k.ball("gold", 1.355, .35, zp + .21, .06, GOLD, 12, sx=.4)
    # the lintel over everything, blocks on its visible sides
    k.box("stone", 0, .21, zc, 2.92, 1.5, .17, SAND_TOP)
    k.wall((-1.47, -.55), (1.47, -.55), zc + .005, zc + .165, t=.05, course=.17, length=.5, col=SAND_TOP)
    k.wall((1.47, -.54), (1.47, .96), zc + .005, zc + .165, t=.04, course=.17, length=.5, col=SAND_TOP)
    zb = zc + .17
    # the side wings of the roof, a step higher, laid in blocks; the back of the roof likewise
    for s in (-1, 1):
        k.box("stone", s * 1.25, .21, zb, .44, 1.5, .12, SAND_WALL)
        block_top(k, min(s * 1.02, s * 1.48), max(s * 1.02, s * 1.48), -.55, .97, zb + .12, SAND_TOP, .34, .05)
    block_top(k, -1.02, 1.02, .52, .97, zb, SAND_TOP, .34, .04)
    # the raised centre: a frieze block with a winged sun, and a sunken cap of big blocks
    k.box("stone", 0, .01, zb, 2.04, 1.02, .4, SAND_WALL)
    k.box("glaze", 0, -.515, zb + .035, 1.86, .03, .33, TEAL)
    k.box("gold", 0, -.53, zb + .035, 1.86, .025, .04, GOLD)
    k.box("gold", 0, -.53, zb + .325, 1.86, .025, .04, GOLD)
    fz = zb + .2
    for s in (-1, 1):
        for i, (span, dz, th) in enumerate(((.8, .06, .065), (.68, -.01, .06), (.54, -.075, .055))):
            k.beam("gold", (s * .1, -.55, fz + dz * .55), (s * (.12 + span), -.55, fz + dz + .05), th, .03, GOLD if i != 1 else C("#F2C85A"))
    with k.at(Matrix.Translation((0, -.56, fz)) @ Matrix.Rotation(math.pi / 2, 4, "X")):
        k.lathe("gold", 0, 0, 0, [(.13, 0), (.13, .03)], YELLOW, 20)
    k.box("glaze", 1.03, .01, zb + .07, .025, .86, .26, TEAL)
    k.box("gold", 1.045, .01, zb + .18, .02, .86, .04, GOLD)
    zq = zb + .4
    k.box("stone", 0, .01, zq - .02, 2.2, 1.16, .06, C("#C8A66E"))
    block_ring(k, -1.14, 1.14, -.6, .62, zq, zq + .2, .24, SAND_TOP)
    # palms in teal pots, flower boxes at the front corners
    for s in (-1, 1):
        top = pot(k, s * 1.28, -.46, P, .15, TEAL, GOLD, "glaze")
        palm(k, s * 1.28, -.46, top, .26, .34, 9, r=.05)
        planter(k, s * 1.2, -.84, P, .36, .24, .17, PINK if s < 0 else C("#F0A040"), 8)


def archive(k):
    paving(k)
    # the plan: x0..x1 along the front, front to back
    x0, x1, y0, y1 = -1.46, 1.2, -.62, .9
    zf = G + 1.22            # the upper floor
    zt = G + 2.32            # the top of the upper pillars
    # ---- ground floor
    # the main arch on -y spans ax0..ax1; a second on +x; solid masonry round them
    ax0, ax1 = -.02, .82
    acx, ar = (ax0 + ax1) / 2, (ax1 - ax0) / 2
    zs, rz = G + .5, .46
    ztop = zf - .12
    k.box("stone", -.74, .14, G, 1.42, 1.5, ztop - G, SANDS[1])                 # the left block
    k.wall((x0 + .02, y0), (ax0, y0), G, ztop, t=.06, course=.27, length=.52)
    k.box("stone", ax1 - .4, .35, G, .86 + .4, 1.1, ztop - G, SANDS[1])         # the core behind the alcoves
    k.box("stone", (ax1 + x1) / 2, -.46, G, x1 - ax1, .32, ztop - G, sand())     # the front corner pier
    k.wall((ax1, y0 - .005), (x1, y0 - .005), G, ztop, t=.04, course=.27, length=.5)
    k.wall((x1 + .005, y0), (x1 + .005, -.3), G, ztop, t=.04, course=.27, length=.5)
    k.box("stone", 1.1, .7, G, .2, .4, ztop - G, sand())                         # the back pier
    k.wall((x1 + .005, .5), (x1 + .005, y1), G, ztop, t=.04, course=.27, length=.5)
    # the alcove floor and the arch's walls
    k.box("stone", acx, -.34, P, ax1 - ax0 + .1, .56, .02, EARTH)
    k.box("stone", ax0 - .05, -.42, G, .1, .4, ztop - G, sand())
    arch_wall(k, "stone", acx, ar, rz, y0 - .03, y0 + .1, zs, ztop, SANDS[0])
    arch_trim(k, "glaze", acx, ar - .005, rz - .005, y0 - .03, zs, .07, .03, TEAL)
    arch_trim(k, "gold", acx, ar + .065, rz + .065, y0 - .03, zs, .035, .025, GOLD)
    for s in (-1, 1):
        k.box("glaze", acx + s * (ar + .025), y0 - .045, P, .075, .03, zs - P, TEAL)
    k.box("stone", acx, -.48, zs + rz - .02, ax1 - ax0 + .02, .26, ztop - zs - rz + .02, SANDS[1])
    bookshelf(k, acx, -.18, P + .02, ar * 2 - .1, .86, 3)
    swag(k, ax0 + .02, acx - .04, y0 + .12, zs + rz * .9, zs - .1, TURQUOISE)
    swag(k, ax1 - .02, acx + .04, y0 + .12, zs + rz * .9, zs - .1, TURQUOISE)
    # the +x alcove: same arch, seen from the side
    ay0, ay1 = -.3, .5
    bcy, br = (ay0 + ay1) / 2, (ay1 - ay0) / 2
    frame = wall_frame((x1, ay0), (x1, ay1))
    with k.at(frame):
        arch_wall(k, "stone", br, br, rz, -.03, .1, zs, ztop, SANDS[0])
        arch_trim(k, "glaze", br, br - .005, rz - .005, -.03, zs, .07, .03, TEAL)
        arch_trim(k, "gold", br, br + .065, rz + .065, -.03, zs, .035, .025, GOLD)
        for s in (-1, 1):
            k.box("glaze", br + s * (br + .025), -.045, P, .075, .03, zs - P, TEAL)
        k.box("stone", br, .19, zs + rz - .02, 2 * br + .02, .22, ztop - zs - rz + .02, SANDS[1])
        bookshelf(k, br, .24, P, 2 * br - .1, .7, 2)
        swag(k, .02, br - .04, .12, zs + rz * .9, zs - .1, TURQUOISE)
        swag(k, 2 * br - .02, br + .04, .12, zs + rz * .9, zs - .1, TURQUOISE)
    # the small arched door between the stair and the main arch
    door = -.42
    with k.at(Matrix.Translation((0, y0 - .03, 0))):
        k.window(door, P, P + .42, .19, fill=TEAL_D, fill_mat="glaze", trim=SAND_PALE)
        k.box("wood", door, -.04, P, .05, .02, .62, GOLD_D)
    # ---- the stair on the left, against the front wall, climbing towards -x
    n = 5
    sx0, sx1 = -.72, -1.16
    tread = (sx0 - sx1) / n
    rise = (zf - .05 - P) / (n + 1)
    for i in range(n):
        x = sx0 - (i + .5) * tread
        k.box("stone", x, -.81, G, tread + .004, .36, P + (i + 1) * rise - G, J(SAND_PALE, .025))
    k.box("stone", (x0 + sx1) / 2, -.81, G, sx1 - x0, .36, zf - .05 - G, J(SAND_PALE, .02))     # the landing
    # the stair's outer wall reads as a stepped silhouette, with a teal jar beside it
    vase(k, -.6, -.86, P, .11, TEAL, GOLD, "glaze")
    # ---- the band between the floors
    k.box("stone", (x0 + x1) / 2 + .02, .14, ztop, x1 - x0 + .08, 1.62, .12, PAVER)
    k.box("glaze", (sx1 + x1) / 2 + .01, y0 - .075, ztop - .1, x1 - sx1 + .03, .03, .1, TEAL)
    k.box("gold", (sx1 + x1) / 2 + .01, y0 - .09, ztop - .1, x1 - sx1 + .03, .025, .03, GOLD)
    k.box("glaze", x1 + .055, .14, ztop - .1, .03, 1.56, .1, TEAL)
    k.box("gold", x1 + .07, .14, ztop - .1, .025, 1.56, .03, GOLD)
    # ---- the upper floor
    k.box("stone", -.1, .69, zf, 2.1, .4, zt - zf, SANDS[1])     # the back wall, shelves on it
    bookshelf(k, -.62, .49, zf, .88, .84, 3)
    bookshelf(k, .34, .49, zf, .88, .84, 3)
    pillars = [(-1.32, -.5), (-.04, -.5), (1.06, -.5), (1.06, .76), (-1.32, .76)]
    for x, y in pillars:
        k.box("stone", x, y, zf, .3, .3, .12, J(SAND_PALE, .02))
        k.box("stone", x, y, zf + .12, .25, .25, zt - zf - .36, sand())
        k.box("glaze", x, y, zt - .24, .27, .27, .12, TEAL)
        k.box("gold", x, y, zt - .12, .31, .31, .04, GOLD)
        k.box("stone", x, y, zt - .08, .34, .34, .08, SAND_PALE)
    # the balustrade: a lattice of fat balusters between two rails
    def rail(a, b):
        a, b = Vector(a), Vector(b)
        L = (b - a).length
        ang = math.atan2(b.y - a.y, b.x - a.x)
        mid = a.lerp(b, .5)
        k.box("stone", mid.x, mid.y, zf, L, .11, .08, J(SAND_PALE, .02), ang)
        k.box("stone", mid.x, mid.y, zf + .36, L + .02, .15, .07, PAVER, ang)
        m = max(2, round(L / .2))
        for i in range(m):
            p = a.lerp(b, (i + .5) / m)
            k.box("wood", p.x, p.y, zf + .08, L / m * .5, .08, .28, J(WOOD_L, .05), ang)
        k.box("wood", mid.x, mid.y, zf + .2, L, .06, .05, WOOD_L, ang)
    rail((-1.18, -.5), (-.17, -.5))
    rail((.09, -.5), (.92, -.5))
    rail((1.06, -.36), (1.06, .62))
    # a table with scrolls, a palm in a teal pot
    tz = table(k, .42, .02, zf, .54, .36, .24, WOOD_L, WOOD)
    for x, c in ((.3, CANVAS), (.42, TEAL_L), (.54, CANVAS)):
        k.tube("matte", (x, -.06, tz + .045), (x, .1, tz + .045), .045, .045, c, 10)
    top = pot(k, -.74, -.14, zf, .15, TEAL, GOLD, "glaze")
    fern(k, -.74, -.14, top, .34, 9)
    # linen curtains tied to the pillars
    for x, y, w in ((-1.14, -.42, .26), (-.22, -.42, .26), (.14, -.42, .26), (.88, -.42, .24)):
        curtain(k, x, y, zt - .03, zf + .2, w)
    with k.at(wall_frame((1.0, -.34), (1.0, .66))):
        curtain(k, .14, 0, zt - .03, zf + .2, .26)
        curtain(k, .86, 0, zt - .03, zf + .2, .26)
    # ---- the pergola: long beams, then rafters, then battens, each on the last
    zb = zt
    for y in (-.5, .76):
        k.box("wood", -.1, y, zb, 2.8, .13, .1, WOOD)
    k.box("wood", -.1, .13, zb + .002, 2.76, .11, .095, WOOD)
    for x in (-1.32, 1.06):
        k.box("wood", x, .13, zb - .004, .12, 1.26, .08, WOOD_D)
    for i in range(9):
        x = -1.4 + i * .35
        k.box("wood", x, 0, zb + .1, .1, 1.96, .09, J(WOOD_L, .05))
    for y in (-.86, -.42, .02, .46, .9):
        k.box("wood", 0, y, zb + .19, 2.94, .08, .07, J(WOOD_L, .06))
    # greenery over the pergola, thick towards the back and +x
    zg = zb + .29
    for i in range(56):
        x = -.5 + 1.95 * R.random()
        y = .92 - (.2 + .9 * ((x + .5) / 1.95)) * R.random() ** 1.2
        k.ball("leaf", x, y, zg + R.uniform(0, .03), R.uniform(.08, .13), J(R.choice(LEAVES), .05), 10, sz=.6)
    for x, y in ((.1, .8), (.62, .62), (1.2, .4), (.92, .78), (1.3, .08), (.3, .55), (.86, .2)):
        k.ball("matte", x, y, zg + .06, .05, MAGENTA, 8)
    palm(k, .3, .76, zf, 1.72, .5, 9, r=.07)
    # bougainvillea up the +x corner and creepers on the front
    for i in range(8):
        t = i / 7
        y, z = .72 + .1 * math.sin(i * 1.7), P + .12 + t * 1.75
        rr = .13 - .03 * t
        k.ball("leaf", 1.33, y, z, rr, J(R.choice(LEAVES), .05), 12, sx=.75)
        for j in range(3):
            a = R.uniform(0, 2 * math.pi)
            k.ball("matte", 1.33 + rr * .55, y + rr * .9 * math.cos(a), z + rr * .9 * math.sin(a), .06, J(MAGENTA, .05), 10)
    k.ball("leaf", -.12, y0 - .03, ztop - .02, .13, LEAVES[0], 12, sy=.6)
    vine(k, -.12, y0 - .06, ztop - .04, .62, None, n=5, r=.1)
    # ---- the forecourt: a rug, a low reading table, tall jars
    k.box("cloth", acx, -.82, P, .84, .3, .025, TURQUOISE)
    k.box("cloth", acx, -.82, P + .025, .66, .16, .012, GOLD)
    k.box("cloth", acx, -.82, P + .037, .5, .07, .01, TEAL_D)
    tz = table(k, acx - .2, -.82, P + .02, .32, .22, .15, WOOD_L, WOOD)
    k.tube("matte", (acx - .3, -.82, tz + .04), (acx - .1, -.82, tz + .04), .04, .04, CANVAS, 10)
    vase(k, .92, -.84, P, .12, TEAL, GOLD, "glaze")
    top = pot(k, 1.36, -.2, P, .12, TERRACOTTA)
    fern(k, 1.36, -.2, top, .14, 7)
    top = pot(k, -.2, -.84, P, .11, TERRACOTTA)
    fern(k, -.2, -.84, top, .15, 6)


def lobed_bowl(k, z, r, depth, lobes, ball, water):
    """A gold bowl from a narrow foot, its rim a ring of fat scallops, water inside."""
    k.lathe("gold", 0, 0, z, [(r * .22, 0), (r * .62, depth * .42), (r * .92, depth * .9), (r * .96, depth), (r * .78, depth * 1.02), (r * .74, depth * .8)], GOLD, 28)
    k.lathe("water", 0, 0, z + depth * .78, [(r * .8, 0), (r * .8, depth * .1)], water, 28)
    for i in range(lobes):
        t = 2 * math.pi * i / lobes
        m = Matrix.Rotation(t - math.pi / 2, 4, "Z") @ Matrix.Rotation(-.32, 4, "X")
        prof = [(.001, 0), (ball * .7, ball * .35), (ball, ball * .85), (ball * .62, ball * 1.45), (.001, ball * 2)]
        k.lathe("gold", (r - ball * .05) * math.cos(t), (r - ball * .05) * math.sin(t), z + depth * .45, prof, GOLD if i % 2 else C("#F2C85A"), 10, True, 1, .5, m=m)


def fountain(k):
    paving(k)
    Rb = .76                          # the basin's outer wall
    k.lathe("stone", 0, 0, G, [(Rb, 0), (Rb, .17)], SANDS[0], 44)
    k.lathe("glaze", 0, 0, G + .05, [(Rb + .012, 0), (Rb + .012, .1)], TEAL, 44, smooth=False)
    k.lathe("gold", 0, 0, G + .03, [(Rb + .016, 0), (Rb + .016, .028)], GOLD, 44)
    for i in range(12):
        a = 2 * math.pi * i / 12
        k.ball("gold", (Rb + .012) * math.cos(a), (Rb + .012) * math.sin(a), G + .1, .03, GOLD, 8)
    k.ring(0, 0, G + .17, G + .3, Rb - .02, .17, .13, .28, col=SAND_PALE)
    zw = G + .24
    k.lathe("water", 0, 0, zw - .06, [(Rb - .09, 0), (Rb - .09, .06)], TURQUOISE, 40)
    k.lathe("water", 0, 0, zw + .003, [(.5, 0), (.5, .002)], C("#2BC4BE"), 40)
    # lilies
    for x, y, r, c in ((-.46, -.32, .1, PINK), (.08, -.52, .11, C("#C86CE0")), (.5, -.14, .1, PINK), (-.54, .16, .09, C("#C86CE0")), (.34, .36, .09, PINK)):
        k.lathe("leaf", x, y, zw + .006, [(r, 0), (r, .012)], PAD, 14)
        k.lathe("leaf", x + r * .9, y - r * .7, zw + .005, [(r * .68, 0), (r * .68, .01)], LEAVES[0], 12)
        k.lathe("matte", x, y, zw + .018, [(r * .3, 0), (r * .78, .05), (r * .55, .09)], c, 10, smooth=False)
        k.ball("matte", x, y, zw + .085, .035, YELLOW, 8)
    # the tiers: sandstone stem, a wide gold bowl, a smaller one, a jet
    z1, z2 = G + .58, G + .94
    k.lathe("gold", 0, 0, zw, [(.2, 0), (.18, .05), (.13, .07)], GOLD, 20)
    k.lathe("stone", 0, 0, zw + .05, [(.13, 0), (.095, z1 - zw - .05), (.14, z1 - zw + .05)], SAND_PALE, 18)
    lobed_bowl(k, z1 - .02, .42, .17, 13, .105, TURQUOISE)
    k.lathe("stone", 0, 0, z1 + .1, [(.09, 0), (.065, z2 - z1 - .1), (.09, z2 - z1)], SAND_PALE, 14)
    k.lathe("gold", 0, 0, z1 + .13, [(.11, 0), (.11, .03)], GOLD, 14)
    lobed_bowl(k, z2 - .02, .25, .13, 9, .08, TURQUOISE_L)
    k.lathe("gold", 0, 0, z2 + .08, [(.08, 0), (.04, .12), (.06, .17)], GOLD, 12)
    k.lathe("water", 0, 0, z2 + .22, [(.055, 0), (.045, .1), (.02, .24), (.001, .3)], WATER_L, 12)
    # water falling from each bowl into the next
    for i in range(6):
        a = 2 * math.pi * (i + .5) / 6
        ca, sa = math.cos(a), math.sin(a)
        rt, rb = .47, .55
        k.path("water", [(rt * ca, rt * sa, z1 + .16), ((rb - .03) * ca, (rb - .03) * sa, z1 + .04), (rb * ca, rb * sa, zw + .005)], .03, WATER_L, 8)
    for i in range(5):
        a = 2 * math.pi * (i + .2) / 5
        ca, sa = math.cos(a), math.sin(a)
        rt, rb = .28, .33
        k.path("water", [(rt * ca, rt * sa, z2 + .13), ((rb - .02) * ca, (rb - .02) * sa, z2 + .02), (rb * ca, rb * sa, z1 + .15)], .025, WATER_L, 8)
    # the four corners: a plinth, a teal pot, a small palm
    d = .73
    for sx, sy, lift in ((-1, -1, 1.), (-1, 1, 1.), (1, 1, 1.), (1, -1, .7)):
        x, y = sx * d, sy * d
        k.box("stone", x, y, P, .3, .3, .16, J(SAND_PALE, .02))
        k.box("gold", x, y, P + .16, .26, .26, .03, GOLD)
        k.box("glaze", x, y - .15, P + .03, .18, .02, .1, TEAL)
        k.box("glaze", x + .15, y, P + .03, .02, .18, .1, TEAL)
        top = pot(k, x, y, P + .19, .1, TEAL, GOLD, "glaze")
        palm(k, x, y, top, .3 * lift, .3, 11, r=.04)
    # flower boxes along the visible sides, a flowering shrub at the front
    planter(k, -.3, -.87, P, .3, .18, .08, PINK, 7)
    planter(k, .26, -.87, P, .3, .18, .08, C("#E8A040"), 7)
    for y, flower in ((-.22, PINK), (.24, C("#E8A040"))):
        k.box("stone", .86, y, P, .2, .3, .1, J(SAND_PALE, .02))
        k.box("glaze", .965, y, P + .03, .02, .2, .05, TEAL)
        bush(k, .86, y, P + .1, .12, flower, 6)


def workshop(k):
    paving(k)
    # the wall along -x, chunky sandstone with a soft top
    wx, wy0, wy1, zw = -.86, -.8, .5, G + 1.2
    k.box("stone", wx, (wy0 + wy1) / 2, G, .14, wy1 - wy0 - .08, zw - G - .02, SAND_DK)
    k.wall((wx + .08, wy0), (wx + .08, wy1), G, zw, t=.06, course=.22, length=.42)
    k.tube("stone", (wx, wy0, zw), (wx, wy1, zw), .1, .1, SAND_TOP, 12)
    k.ball("stone", wx, wy0, zw, .1, SAND_TOP, 12)
    k.ball("stone", wx, wy1, zw, .1, SAND_TOP, 12)
    # the kiln: a brick drum, a brick dome, a clay chimney
    cx, cy, Rd = .1, .34, .56
    zb = G + .72
    brick = lambda: J(C("#E6CCA0"), .05)
    k.lathe("stone", cx, cy, G, [(Rd - .04, 0), (Rd - .04, zb - G)], SAND_DK, 30)
    k.ring(cx, cy, G, zb, Rd, .13, .24, .36, col=brick)
    dome_blocks(k, cx, cy, zb - .02, Rd + .04, 6, .32, .03, col=lambda: J(C("#EAD3AA"), .05))
    zt = zb + Rd
    nx, ny = cx + .01, cy
    k.lathe("clay", nx, ny, zt - .05, [(.19, 0), (.17, .1), (.11, .26), (.12, .42), (.16, .5), (.18, .58), (.12, .58), (.1, .48)], C("#D9A063"), 18)
    band(k, "clay", nx, ny, zt + .02, [(.185, 0), (.17, .05), (.15, .1)], CLAY_D, 18)
    k.lathe("matte", nx, ny, zt + .46, [(.11, 0), (.11, .012)], DARK, 14)
    # the firebox, built forward from the drum so the fire shows under the awning
    fx, fy0, fy1 = .12, -.42, -.08
    k.box("stone", fx, (fy0 + fy1) / 2, G, .56, fy1 - fy0, .6, C("#D8BB8C"))
    k.box("stone", fx, (fy0 + fy1) / 2 - .01, G + .6, .62, fy1 - fy0 + .04, .06, SAND_TOP)
    with k.at(Matrix.Translation((0, fy0, 0))):
        k.window(fx, P, P + .18, .19, fill=EMBER, fill_mat="matte", trim=C("#B98A5C"), y=-.005)
    my = fy0 - .05
    k.lathe("flame", fx, my, P, [(.17, 0), (.17, .02)], FLAME, 14, sy=.45)
    k.flame(fx - .09, my, P + .01, .1, 0)
    k.flame(fx + .09, my, P + .01, .1, 0)
    k.flame(fx, my, P + .01, .14, 2.5)
    # posts and the two striped awnings, meeting at the middle post
    stripes = (RED, C("#CF5A30"), RED, C("#CF5A30"), RED, C("#E8B84A"))
    z0, z1 = G + .96, G + 1.2
    for x, y in ((-.68, -.82), (.46, -.82), (.88, -.82), (.88, .56)):
        k.tube("wood", (x, y, G), (x, y, z0), .06, .055, WOOD_L, 10)
        k.ball("wood", x, y, z0 + .01, .07, WOOD, 10)
    k.box("wood", -.11, -.82, z0 - .08, 1.26, .09, .08, WOOD)
    k.box("wood", .67, -.82, z0 - .08, .5, .09, .08, WOOD)
    k.box("wood", .88, -.13, z0 - .08, .09, 1.44, .08, WOOD)
    k.awning(-.76, .42, -.9, -.28, z0 + .03, z1, stripes, n=15, hang=.1)
    with k.at(Matrix.Rotation(math.pi / 2, 4, "Z")):
        k.awning(-.9, .62, -.96, -.46, z0, G + 1.14, stripes, n=18, hang=.1)
    # the big worktable with jars
    tz = table(k, -.46, -.52, P, .56, .46, .3)
    k.box("wood", -.46, -.52, tz, .44, .34, .015, WOOD_D)
    vase(k, -.6, -.46, tz, .07, TERRACOTTA)
    vase(k, -.34, -.6, tz, .065, TERRACOTTA_D)
    k.lathe("clay", -.46, -.44, tz, [(.05, 0), (.1, .06), (.1, .1), (.05, .1)], CLAY_L, 14)
    # a stool with a half-thrown pot, baskets at the wall
    tz = table(k, -.0, -.84, P, .26, .26, .16)
    k.lathe("clay", -.0, -.84, tz, [(.05, 0), (.1, .08), (.08, .15), (.09, .17), (.07, .17)], TERRACOTTA, 14)
    for x, y, r in ((-.78, -.88, .11), (-.38, -.88, .12)):
        k.lathe("matte", x, y, P, [(r * .75, 0), (r * 1.05, r), (r * .98, r * 1.5), (r * .78, r * 1.55), (r * .74, r * 1.2)], J(BASKET, .05), 14)
        k.lathe("matte", x, y, P + r * 1.15, [(r * .76, 0), (r * .76, .015)], SOIL, 12)
    # the little domed oven, a shelf table and the jars in the +x bay
    ox, oy = .66, .16
    k.lathe("stone", ox, oy, P, [(.23, 0), (.24, .2), (.19, .36), (.09, .46), (.06, .5), (.09, .56), (.05, .56)], C("#E2C396"), 20)
    with k.at(radial_frame(ox, oy, .2, math.radians(-30))):
        k.window(0, P + .02, P + .13, .1, fill=EMBER, fill_mat="matte", trim=C("#C99B6A"), y=-.04)
    tz = table(k, .62, -.3, P, .34, .3, .24)
    vase(k, .55, -.3, tz, .07, TERRACOTTA)
    k.lathe("clay", .7, -.32, tz, [(.05, 0), (.09, .07), (.08, .12), (.06, .12)], TERRACOTTA_D, 14)
    vase(k, .86, -.16, P, .12, TEAL, GOLD, "glaze")
    vase(k, .64, -.78, P, .12, C("#D08A52"))
    k.lathe("clay", .86, -.62, P, [(.08, 0), (.12, .1), (.1, .2), (.08, .2)], TERRACOTTA, 16)
    k.ball("clay", .22, -.92, P + .045, .05, CLAY_D, 10)
    # greenery: a palm behind the wall, a plant at the back corner
    palm(k, -.62, .66, G, 1.72, .74, 12, r=.1)
    top = pot(k, .84, .8, P, .11, TERRACOTTA)
    fern(k, .84, .8, top, .16, 7)
