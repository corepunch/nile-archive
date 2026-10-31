# Christmas Market's first twelve objects, modelled for the city camera with the shared
# kit: main facade and gable towards -Y, second side towards +X.
#
# art/building-reference-sheet.png is the direction. The sheet was painted from another
# angle, so each design is turned to suit. build_scene.py imports this; the rest of the
# catalogue is modelled there. Rebuild with: make buildings GAME=christmas-market REBUILD=1
import math

from mathutils import Matrix, Vector

from building_kit import *


# ------------------------------------------------------------------ palette

SNOW, SNOW_S = C("#DCE5F4"), C("#BCCBE4")
STONE, STONE_L, STONE_D = C("#A3947F"), C("#C2B49E"), C("#5E5346")
CREAM, CREAM_D = C("#EEDDB8"), C("#CDB78C")
FIR, FIR_L, FIR_D = C("#1F6E38"), C("#2F8F48"), C("#14512A")
XRED, XRED_D = C("#D3202B"), C("#99131F")
XGREEN = C("#1E7A3E")
NAVY, NAVY_D = C("#2F4F8F"), C("#1E3564")
IRON = C("#23242A")
AMBER, AMBER_D, BULB = C("#FFC766"), C("#C87F2E"), C("#FFCF6E")
CANDLE, ICE, ICE_L = C("#FFF3DA"), C("#A9DCF0"), C("#E2F5FC")
SKIN, TAN, TAN_L = C("#F2C9A4"), C("#C99A63"), C("#EFE0C4")
GINGER, GINGER_L = C("#B86A2C"), C("#D08E45")
STEEL, COAL, CARROT = C("#AAB6BE"), C("#23201E"), C("#F07A1C")


# ------------------------------------------------------------------ small helpers

def light(k, x, y, z, watts):
    """A point light in the current frame: Kit.lights is otherwise pivot-local."""
    k.lights.append((tuple(k.xf @ Vector((x, y, z))), watts))

def spline(pts, sub=6):
    """Catmull-Rom through pts."""
    pts = [Vector(p) for p in pts]
    pts = [pts[0]] + pts + [pts[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for j in range(sub):
            t = j / sub
            out.append(.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t))
    out.append(pts[-2])
    return [tuple(p) for p in out]

def rope(k, mat, pts, r, col, n=10):
    """A bent tube whose joints stay round."""
    k.path(mat, pts, r, col, n)
    for p in pts[1:-1]:
        k.ball(mat, p[0], p[1], p[2], r, col, n)

def resample(pts, step):
    """Points every step along a polyline."""
    out, pts = [], [Vector(p) for p in pts]
    for a, b in zip(pts, pts[1:]):
        n = max(1, round((b - a).length / step))
        out += [a.lerp(b, i / n) for i in range(n)]
    out.append(pts[-1])
    return out

def prism_y(k, mat, pts, y0, y1, col):
    """Extrudes a polygon, counter-clockwise in (x, z) seen from -Y, along y."""
    n = len(pts)
    v = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
    f = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
    f += [(n + i, n + (i + 1) % n, (i + 1) % n, i) for i in range(n)]
    k.add(mat, v, f, col)

def facing(x, y, z, a):
    """A frame at a point whose local -y points along world angle a."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")

SIDE = 0.   # a facing() angle: towards +X

# The common stall. The city camera looks down 40 degrees, so under a header it only sees
# about one unit lower per unit of depth: walls are tall, roofs steep and the lit interior
# shallow (YB is its back wall), or the goods would disappear under the eave.
X0, X1, Y0, Y1 = -1.1, 1.1, -.5, 1.
YB = Y0 + .62
ZW, RH, OV = G + 1.6, 1.4, .18


# ------------------------------------------------------------------ decoration

def snow_base(k):
    """The snowy plinth every reference stands on: cobbled rim, snow top at exactly G."""
    w, h = k.w, k.h
    k.box("stone", 0, 0, 0, w - .05, h - .05, .055, STONE_D)
    def run(a, b, across, along_x):
        s = a
        while s < b - .01:
            l = min(R.uniform(.3, .42), b - s)
            if b - s - l < .16:
                l = b - s
            z = R.uniform(.078, .09)
            c = J(STONE if R.random() < .7 else STONE_L, .06)
            if along_x:
                k.box("stone", s + l / 2, across, 0, l - .014, .19, z, c)
            else:
                k.box("stone", across, s + l / 2, 0, .19, l - .014, z, c)
            s += l
    run(-w / 2, w / 2, -h / 2 + .095, True)
    run(-w / 2, w / 2, h / 2 - .095, True)
    run(-h / 2 + .2, h / 2 - .2, w / 2 - .095, False)
    run(-h / 2 + .2, h / 2 - .2, -w / 2 + .095, False)
    k.box("slab", 0, 0, .03, w - .17, h - .17, G - .03, SNOW)
    # soft drifts along the rim
    per = 2 * (w + h)
    for i in range(int(per / .62)):
        t = (i + R.uniform(-.25, .25)) / int(per / .62) * per
        ins = R.uniform(.34, .42)
        if t < w:
            x, y = -w / 2 + t, -h / 2 + ins
        elif t < w + h:
            x, y = w / 2 - ins, -h / 2 + t - w
        elif t < 2 * w + h:
            x, y = w / 2 - (t - w - h), h / 2 - ins
        else:
            x, y = -w / 2 + ins, h / 2 - (t - 2 * w - h)
        x, y = max(-w / 2 + ins, min(w / 2 - ins, x)), max(-h / 2 + ins, min(h / 2 - ins, y))
        k.ball("slab", x, y, G - .02, R.uniform(.26, .34), J(SNOW, .012), 14, sz=.14)

def bow(k, x, y, z, s=.15, col=XRED):
    """A big satin bow in the frame's XZ plane, facing -y."""
    for side in (-1, 1):
        k.beam("glaze", (x + side * s * .1, y - .01, z - s * .1), (x + side * s * .62, y - .01, z - s * 1.25), s * .42, .035, XRED_D)
        k.ball("glaze", x + side * s * .72, y, z + s * .1, s * .62, col, 12, sx=1.15, sy=.55, sz=.8)
    k.ball("glaze", x, y - s * .22, z, s * .3, XRED_D, 10)

def garland(k, pts, r=.085, out=(0, -1, 0), bulbs=True, berries=True, step=None):
    """Evergreen rope with warm lights and red berries, offset along out."""
    out = Vector(out)
    step = step or r * 1.05
    for i, p in enumerate(resample(pts, step)):
        jit = Vector((R.uniform(-.012, .012), R.uniform(-.012, .012), R.uniform(-.012, .012)))
        q = p + jit
        k.ball("leaf", q.x, q.y, q.z, r * R.uniform(.92, 1.12), J(FIR if i % 3 else FIR_L, .08), 10)
        if bulbs and i % 3 == 1:
            q = p + out * r * .86 + Vector((0, 0, R.uniform(-.03, .03)))
            k.ball("flame", q.x, q.y, q.z, .027, BULB, 8)
        elif berries and i % 6 == 4:
            q = p + out * r * .84 + Vector((0, 0, R.uniform(-.03, .03)))
            k.ball("glaze", q.x, q.y, q.z, .036, XRED, 8)

def swag(a, b, sag, n=10):
    """A hanging curve between two points."""
    a, b = Vector(a), Vector(b)
    return [tuple(a.lerp(b, i / n) - Vector((0, 0, sag * 4 * (i / n) * (1 - i / n)))) for i in range(n + 1)]

def wreath(k, x, y, z, r=.26, top_bow=True):
    """A wreath in the frame's XZ plane."""
    n = max(10, round(2 * math.pi * r / .08))
    for i in range(n):
        a = 2 * math.pi * i / n
        k.ball("leaf", x + r * math.cos(a), y, z + r * math.sin(a), r * .36 * R.uniform(.92, 1.1), J(FIR if i % 2 else FIR_L, .08), 10)
        if i % 2 == 0:
            k.ball("flame" if i % 4 == 0 else "glaze", x + r * math.cos(a), y - r * .3, z + r * math.sin(a), .03, BULB if i % 4 == 0 else XRED, 8)
    if top_bow:
        bow(k, x, y - r * .3, z + r, r * .6)

def lantern(k, x, y, z, s=.14, watts=1.2):
    """An iron lantern standing at z: glowing body, four bars and a pointed cap."""
    h = s * 1.45
    k.lathe("matte", x, y, z, [(s * .4, 0), (s * .62, s * .1), (s * .62, s * .16), (s * .4, s * .16)], IRON, 8, smooth=False)
    k.lathe("flame", x, y, z + s * .14, [(s * .4, 0), (s * .5, h * .55), (s * .55, h), (s * .3, h)], AMBER, 12)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        c, n = math.cos(a), math.sin(a)
        k.beam("matte", (x + c * s * .45, y + n * s * .45, z + s * .12), (x + c * s * .62, y + n * s * .62, z + s * .14 + h), .03, .03, IRON)
    top = z + s * .14 + h
    k.lathe("matte", x, y, top, [(s * .78, 0), (s * .78, s * .07), (s * .14, s * .55), (s * .001, s * .6)], IRON, 8, smooth=False)
    k.ball("gold", x, y, top + s * .66, s * .14, GOLD, 8)
    k.ball("slab", x, y, top + s * .25, s * .5, SNOW, 10, sz=.4)
    if watts:
        light(k, x, y - s, z + h * .6, watts)

def lamp_post(k, x, y, z, h=1.1, s=.17, watts=1.6):
    """A black cast-iron post with a big lantern on top."""
    k.lathe("matte", x, y, z, [(.13, 0), (.11, .06), (.06, .18), (.042, .3), (.04, h - .12), (.075, h - .06), (.09, h)], IRON, 12)
    lantern(k, x, y, z + h, s, watts)

def _cone(k, mat, x, y, z0, z1, r, col, n=12, inner=.8, turn=0.):
    v, cols = [], []
    for i in range(n):
        a = 2 * math.pi * i / n + turn
        d = r * (1 if i % 2 == 0 else inner)
        v.append((x + d * math.cos(a), y + d * math.sin(a), z0 + (0 if i % 2 == 0 else (z1 - z0) * .08)))
    v.append((x, y, z1))
    f = [(i, (i + 1) % n, n) for i in range(n)] + [tuple(reversed(range(n)))]
    k.add(mat, v, f, col, True)

def fir(k, x, y, z, h, r, tiers=4, trunk=.14):
    """A stacked evergreen with snow on every tier; returns its tiers for decorating."""
    x, y = k.fit(x, y, r)
    k.tube("wood", (x, y, z), (x, y, z + h * trunk + .06), r * .18, r * .15, WOOD_D, 10)
    out, z0, top = [], z + h * trunk, z + h
    span = top - z0
    for i in range(tiers):
        t0, t1 = i / tiers, (i + 1) / tiers
        zb = z0 + span * (t0 * .86)
        zt = z0 + span * (.44 + t1 * .56 if i < tiers - 1 else 1)
        rb = r * (1 - t0 * .78)
        turn = R.uniform(0, 1)
        n = max(12, 2 * round(rb * 15))
        _cone(k, "leaf", x, y, zb, zt, rb, J(FIR if i % 2 else FIR_L, .06), n, inner=.84, turn=turn)
        # the snow: the upper part of the same cone, with a jagged lower edge
        f = .5
        _cone(k, "matte", x, y, zb + (zt - zb) * (1 - f) + .005, zt + .018, rb * f + .018, SNOW, n, inner=.55, turn=turn + .22)
        # tufts lying on the skirt, where the tier above cannot hide them
        for j in range(3 + round(rb * 11)):
            a = R.uniform(-2.9, .9)
            t = R.uniform(.08, .3)
            d = rb * (1 - t) * .88
            size = max(.04, min(.095, rb * .2)) * R.uniform(.8, 1.2)
            k.ball("slab", x + d * math.cos(a), y + d * math.sin(a), zb + (zt - zb) * t + size * .3, size, SNOW, 10, sz=.42)
        out.append((zb, zt, rb))
    return x, y, out

def trim_fir(k, x, y, tiers, per=3, ball=.04, lights=4, cols=(XRED, GOLD), a0=-2.6, a1=.5):
    """Baubles and lights on the camera-side half of a fir."""
    for zb, zt, rb in tiers:
        for i in range(per + lights):
            a = R.uniform(a0, a1)
            t = R.uniform(.02, .28)
            d = rb * (1 - t) * .9
            z = zb + (zt - zb) * t
            px, py = x + d * math.cos(a), y + d * math.sin(a)
            if i < per:
                k.ball("glaze", px, py, z, ball, R.choice(cols), 10)
            else:
                k.ball("flame", px, py, z, .026, BULB, 8)

def deco_fir(k, x, y, z, h=.9, r=.27, ribbon=True, tiers=3):
    """The small decorated fir that stands around the stalls."""
    x, y, t = fir(k, x, y, z, h, r, tiers)
    trim_fir(k, x, y, t, 1, .035, 3)
    if ribbon:
        zb, zt, rb = t[0]
        a = math.radians(-70)
        with k.at(facing(x + rb * .92 * math.cos(a), y + rb * .92 * math.sin(a), zb + (zt - zb) * .15, a)):
            bow(k, 0, -.01, 0, .09)
    return x, y, t

def chimney(k, x, y, z0, z1, s=.42):
    k.box("stone", x, y, z0, s - .06, s - .06, z1 - z0, STONE_D)
    h = s / 2
    pts = [(x - h, y - h), (x + h, y - h), (x + h, y + h), (x - h, y + h)]
    for a, b in zip(pts, pts[1:] + pts[:1]):
        k.wall(a, b, z0, z1, t=.09, course=.13, length=.24, col=lambda: J(STONE if R.random() < .7 else STONE_L, .07))
    k.box("stone", x, y, z1, s + .1, s + .1, .08, STONE_L)
    k.box("matte", x, y, z1 + .02, s - .14, s - .14, .08, COAL)
    k.ball("slab", x + s * .22, y, z1 + .1, s * .36, SNOW, 12, sz=.55)
    k.ball("slab", x - s * .18, y + .04, z1 + .1, s * .33, SNOW, 12, sz=.5)

def snow_sheet(k, s, xm, half, y0, y1, z, h, th=.15, lip=.15):
    """One slope's soft snow: gently lumpy, pouring over the eave and the gable end in waves."""
    L = math.hypot(half, h)
    D, N, ridge = Vector((s * half / L, 0, -h / L)), Vector((s * h / L, 0, half / L)), Vector((xm, 0, z + h))
    ph = [R.uniform(0, 6.28) for _ in range(7)]
    ya, yb = y0 - .07, y1 + .05
    l0, reach = -th * h / half, L + lip * .8      # l0: both slopes close exactly over the ridge
    def fn(u, v):
        y, l = ya + (yb - ya) * u, l0 + (reach - l0) * v
        b = (.022 * math.sin(y * 4.1 + ph[0]) * math.sin(l * 3.3 + ph[1]) + .012 * math.sin(y * 7.7 + l * 2 + ph[2])) * max(0, min(1, l / .4))
        p = ridge + D * l + Vector((0, y, 0)) + N * (th + b)
        e = max(0, (l - L) / (lip * .8))
        p -= N * (e * e * (lip + lip * .33 * math.sin(y * 8.3 + ph[3]) + lip * .16 * math.sin(y * 17 + ph[4])))
        f = max(0, 1 - (y - ya) / .1)
        p -= N * (f * f * (lip + lip * .3 * math.sin(l * 7.3 + ph[5]) + lip * .13 * math.sin(l * 15 + ph[6])))
        g = max(0, 1 - (yb - y) / .1)
        p -= N * (g * g * lip)
        return tuple(p)
    def col(u, v):
        return SNOW_S if v > .985 else SNOW
    k.surface("matte", fn, 34, 34, col)

def snow_gable(k, x0, x1, y0, y1, z, h, over=OV, fascia=WOOD_D, th=.15, lip=.15):
    """A timber roof deck under a thick, soft snow blanket, with its ridge along Y."""
    xm, xl, xr = (x0 + x1) / 2, x0 - over, x1 + over
    t = .13
    prism_y(k, "wood", [(xl, z - t), (xm, z + h - t), (xr, z - t), (xr, z), (xm, z + h), (xl, z)], y0 - over, y1 + over, fascia)
    half = xr - xm
    d = th * .65
    prism_y(k, "matte", [(xl - .03, z - .04), (xm, z + h - .05), (xr + .03, z - .04), (xr, z + d), (xm, z + h + d), (xl, z + d)],
            y0 - over - .05, y1 + over + .03, SNOW)
    for s in (-1, 1):
        snow_sheet(k, s, xm, half, y0 - over, y1 + over, z, h, th, lip)

def rake_garland(k, x0, x1, y0, z, h, over=OV, r=.09, bows=True, mid=True):
    """Garland down both edges of a -Y gable, with bows at the peak, ends and middle."""
    xm, xl, xr = (x0 + x1) / 2, x0 - over + .04, x1 + over - .04
    yy = y0 - over - .07
    zz = z - .08
    apex = (xm, yy, z + h - .17)
    garland(k, [(xl, yy, zz), apex, (xr, yy, zz)], r)
    if not bows:
        return
    bow(k, xm, yy - r * .8, apex[2] + .04, .19)
    for s in (-1, 1):
        bow(k, xm + s * (xr - xm) * .98, yy - r * .8, zz + .02, .15)
        if mid:
            bow(k, xm + s * (xr - xm) * .5, yy - r * .8, (zz + apex[2]) / 2 + .01, .12)

def side_garland(k, x1, y0, y1, z, over=OV, r=.085):
    """Garland along the +X eave."""
    xx = x1 + over - .02
    garland(k, [(xx, y0 - over, z - .16), (xx, y1 + over * .4, z - .16)], r, out=(1, 0, 0))
    for yy in ((y0 + y1) / 2 - .35, (y0 + y1) / 2 + .55):
        with k.at(facing(xx + r * .7, yy, z - .14, SIDE)):
            bow(k, 0, 0, 0, .13)


# ------------------------------------------------------------------ the shared stall


def shell(k, x0=X0, x1=X1, y0=Y0, y1=Y1, yb=YB, zw=ZW, post=WOOD, side=CREAM, back=None, plinth=True):
    """Floor, solid core behind the lit interior, side walls and corner posts. -Y stays open."""
    xm, ym, w, d = (x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0
    back = back or C("#8A5A2C")
    k.box("wood", xm, ym, G, w, d, .05, WOOD_D)
    k.box("matte", xm, (yb + y1) / 2, G, w - .1, y1 - yb, zw - G, back)
    k.box("matte", x0 + .06, ym, G, .12, d, zw - G, side)
    k.box("matte", x1 - .06, ym, G, .12, d, zw - G, side)
    if plinth:
        k.box("stone", x1 - .03, ym, G, .14, d, .3, STONE)
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        k.box("wood", x, y, G, .22, .22, zw - G, post)
    k.box("wood", xm, y0, zw - .2, w + .1, .24, .22, post)
    k.box("wood", x1 + .005, ym, zw - .16, .16, d, .18, post)
    if plinth:
        k.box("wood", x1 + .005, ym, G + .28, .16, d, .1, post)

def gable_wall(k, x0=X0, x1=X1, y0=Y0, y1=Y1, zw=ZW, h=RH, col=CREAM, beams=WOOD, king=True):
    """The attic, filled in plaster, with timbers on its -Y face."""
    xm = (x0 + x1) / 2
    prism_y(k, "matte", [(x0, zw - .04), (x1, zw - .04), (x1, zw + .08), (xm, zw + h - .06), (x0, zw + .08)], y0 + .02, y1 - .06, col)
    yy = y0 - .025
    if king:
        k.box("wood", xm, yy, zw, .15, .09, h - .3, beams)
    for s in (-1, 1):
        k.beam("wood", (xm + s * (x1 - xm) * .96, yy, zw + .04), (xm + s * .1, yy, zw + h * .66), .13, .09, beams)

def side_timber(k, x1=X1, y0=Y0, y1=Y1, zw=ZW, col=WOOD, gap=(0, 0)):
    """Diagonal timbers on the +X plaster wall, skipping the span in gap."""
    xx = x1 + .005
    ym = (y0 + y1) / 2
    for y in (ym - .55, ym + .55):
        if not gap[0] < y < gap[1]:
            k.box("wood", xx, y, G + .34, .13, .13, zw - G - .46, col)

def shop_window(k, y, z, w=.62, h=.72, x1=X1, frame=WOOD_D):
    """A big warm window on the +X wall, with a cross of mullions and a snowy sill."""
    xx = x1 + .02
    k.box("glow", xx - .02, y, z, .06, w, h, AMBER)
    for yy in (y - w / 2, y + w / 2):
        k.box("wood", xx + .02, yy, z - .04, .09, .1, h + .08, frame)
    for zz in (z - .05, z + h):
        k.box("wood", xx + .02, y, zz, .09, w + .1, .1, frame)
    k.box("wood", xx + .04, y, z + .02, .05, .07, h - .04, frame)
    k.box("wood", xx + .04, y, z + h * .55, .05, w - .04, .07, frame)
    k.ball("slab", xx + .05, y, z - .02, .09, SNOW, 12, sx=.8, sy=w * 5.4, sz=.42)
    k.lights.append(((xx + .3, y, z + h * .5), 1.4))

def inner_glow(k, x0=X0, x1=X1, yb=YB, z0=G + .05, z1=ZW - .2, col=AMBER_D, watts=10.):
    """The lit back wall of a stall and the warm light that fills it."""
    xm = (x0 + x1) / 2
    k.box("glow", xm, yb - .02, z0, x1 - x0 - .24, .04, z1 - z0, col)
    k.lights.append(((xm, (Y0 + yb) / 2 - .05, z1 - .1), watts))

def shelf(k, x0, x1, y, z, depth=.2, col=WOOD_D):
    k.box("wood", (x0 + x1) / 2, y, z, x1 - x0, depth, .05, col)

def front_swag(k, x0=X0, x1=X1, y0=Y0, zw=ZW, sag=.14):
    garland(k, swag((x0 + .05, y0 - .15, zw - .14), (x1 - .05, y0 - .15, zw - .14), sag), .06)


# ------------------------------------------------------------------ props

def barrel(k, x, y, z, r=.2, h=.42, cap=True):
    k.lathe("wood", x, y, z, [(r * .84, 0), (r, h * .5), (r * .84, h)], J(WOOD_L, .04), 16)
    for t in (.2, .72):
        k.lathe("matte", x, y, z + h * t, [(r * .98, 0), (r * 1.01, h * .1)], IRON, 16, smooth=False)
    if cap:
        k.ball("slab", x, y, z + h, r * .8, SNOW, 12, sz=.4)

def snow_crate(k, x, y, z, s=.3, h=None, rz=0.):
    h = h or s
    k.crate(x, y, z, s, h, rz)
    k.ball("slab", x, y, z + h + .05, s * .48, SNOW, 12, sz=.32)

def gift(k, x, y, z, s=.22, col=XRED, rib=GOLD, h=None, rz=0., topper=True):
    """A wrapped present: a body, two ribbon bands proud of it and a bow knot."""
    h = h or s * .85
    with k.at(Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z")):
        k.box("cloth", 0, 0, 0, s, s, h, col)
        k.box("cloth", 0, 0, -.002, s * .26, s + .014, h + .012, rib)
        k.box("cloth", 0, 0, -.002, s + .014, s * .26, h + .012, rib)
        if topper:
            k.ball("glaze", 0, 0, h + s * .1, s * .2, rib, 10, sz=.8)

def candle(k, x, y, z, r=.055, h=.2, flame=True):
    k.lathe("matte", x, y, z, [(r, 0), (r, h)], CANDLE, 12)
    if flame:
        k.ball("flame", x, y, z + h + .05, r * .55, FLAME_L, 8, sz=1.8)

def mug(k, x, y, z, col=XRED, r=.065):
    k.lathe("glaze", x, y, z, [(r * .85, 0), (r, r * 1.5)], col, 12, smooth=False)
    k.lathe("matte", x, y, z + r * 1.45, [(r * .9, 0), (r * .9, r * .1)], C("#6E3B1E"), 12, smooth=False)
    k.ball("slab", x, y, z + r * 1.7, r * .72, CANDLE, 10, sz=.6)

def candy_post(k, x, y, z0, z1, r=.1, turns=5):
    """A round post with a red and white spiral."""
    def fn(u, v):
        a = 2 * math.pi * u
        return (x + r * math.cos(a), y + r * math.sin(a), z0 + (z1 - z0) * v)
    def col(u, v):
        return XRED if (u + v * turns) % 1 < .5 else C("#FBF3E6")
    k.surface("glaze", fn, 24, int(turns * 12), col)

def gingerbread_man(k, x, y, z, s=.2):
    """Flat, iced and standing: head, body, arms and legs."""
    with k.at(Matrix.Translation((x, y, z))):
        for sd in (-1, 1):
            k.ball("matte", sd * s * .5, 0, s * .95, s * .24, GINGER, 10, sx=1.5, sy=.6)
            k.ball("matte", sd * s * .28, 0, s * .28, s * .25, GINGER, 10, sy=.6, sz=1.3)
        k.ball("matte", 0, 0, s * .8, s * .42, GINGER, 12, sy=.5, sz=1.1)
        k.ball("matte", 0, 0, s * 1.42, s * .36, GINGER_L, 12, sy=.5)
        for zz in (.62, .92):
            k.ball("matte", 0, -s * .21, s * zz, s * .08, CREAM, 8)
        for sd in (-1, 1):
            k.ball("matte", sd * s * .13, -s * .17, s * 1.48, s * .06, COAL, 8)

def gingerbread_house(k, x, y, z, s=.26):
    k.box("matte", x, y, z, s, s * .8, s * .55, GINGER)
    prism_y(k, "matte", [(x - s * .6, z + s * .5), (x + s * .6, z + s * .5), (x, z + s * .98)], y - s * .46, y + s * .46, SNOW)
    k.box("matte", x, y - s * .41, z, s * .24, .012, s * .32, XRED)

def reindeer(k, x, y, z, heading, s=1., pole=1.1):
    """A carousel reindeer on a gold pole; local +x is forward."""
    k.tube("gold", (x, y, z - .02), (x, y, z + pole), .036, .036, GOLD, 10)
    with k.at(Matrix.Translation((x, y, z)) @ Matrix.Rotation(heading, 4, "Z") @ Matrix.Scale(s, 4)):
        k.ball("matte", 0, 0, .46, .2, TAN, 14, sx=1.5, sy=.82, sz=.92)
        k.ball("matte", .17, 0, .49, .16, TAN_L, 12, sy=.9)
        k.tube("matte", (.2, 0, .56), (.33, 0, .78), .1, .07, TAN, 10)
        k.ball("matte", .37, 0, .84, .095, TAN, 12, sx=1.2)
        k.ball("matte", .47, 0, .81, .056, TAN_L, 10)
        k.ball("glaze", .52, 0, .82, .034, XRED, 8)
        for sd in (-1, 1):
            k.ball("matte", .39, sd * .082, .87, .018, COAL, 6)
            k.ball("matte", .3, sd * .1, .9, .036, TAN, 8, sz=.6, sy=1.5)
            rope(k, "wood", spline([(.33, sd * .04, .92), (.32, sd * .12, 1.04), (.24, sd * .22, 1.16)], 3), .022, WOOD_D, 6)
            rope(k, "wood", [(.32, sd * .12, 1.04), (.42, sd * .19, 1.14)], .02, WOOD_D, 6)
            # front legs lifted, back legs reaching
            rope(k, "matte", [(.17, sd * .09, .36), (.28, sd * .09, .24), (.22, sd * .09, .1)], .042, TAN, 8)
            k.ball("matte", .22, sd * .09, .08, .045, COAL, 8)
            rope(k, "matte", [(-.2, sd * .09, .36), (-.32, sd * .09, .22), (-.42, sd * .09, .12)], .046, TAN, 8)
            k.ball("matte", -.43, sd * .09, .11, .045, COAL, 8)
        k.ball("matte", -.31, 0, .57, .05, TAN_L, 8)
        k.ball("glaze", -.02, 0, .6, .15, XRED, 12, sx=1.25, sy=.96, sz=.42)
        k.ball("gold", -.02, 0, .55, .155, GOLD, 12, sx=.32, sy=.96, sz=.82)
        k.ball("matte", .18, 0, .6, .115, XGREEN, 10, sx=.42, sz=.75)
        k.ball("gold", .23, -.05, .55, .04, GOLD, 8)

def nutcracker(k, x, y, z, s=1.):
    """The toy soldier by the toymaker's door, facing -y."""
    with k.at(Matrix.Translation((x, y, z)) @ Matrix.Scale(s, 4)):
        k.lathe("wood", 0, 0, 0, [(.21, 0), (.21, .05), (.17, .07)], WOOD_L, 18)
        for sd in (-1, 1):
            k.ball("matte", sd * .08, -.03, .1, .07, COAL, 10, sy=1.35, sz=.75)
            k.tube("matte", (sd * .08, 0, .07), (sd * .08, 0, .2), .07, .07, COAL, 10)
            k.tube("matte", (sd * .08, 0, .2), (sd * .08, 0, .4), .064, .07, C("#F5EEDD"), 10)
        k.lathe("matte", 0, 0, .36, [(.17, 0), (.145, .1), (.15, .4), (.11, .45)], XRED, 16)
        k.box("matte", 0, -.14, .47, .08, .03, .3, CANDLE)
        for zz in (.54, .63, .71):
            k.ball("gold", 0, -.158, zz, .021, GOLD, 8)
        k.lathe("gold", 0, 0, .44, [(.16, 0), (.16, .06)], GOLD, 16)
        for sd in (-1, 1):
            k.ball("gold", sd * .165, 0, .78, .06, GOLD, 10, sz=.7)
            rope(k, "matte", [(sd * .19, 0, .76), (sd * .23, -.03, .6), (sd * .2, -.1, .47)], .052, XRED, 8)
            k.ball("matte", sd * .2, -.11, .46, .05, CANDLE, 8)
        k.ball("matte", 0, 0, .93, .125, SKIN, 14, sz=1.05)
        k.ball("matte", 0, -.05, .85, .095, CANDLE, 12, sx=1.1, sy=.9, sz=.9)
        k.ball("matte", 0, -.118, .905, .03, C("#E89A7C"), 8)
        for sd in (-1, 1):
            k.ball("matte", sd * .05, -.107, .96, .021, COAL, 6)
            k.ball("matte", sd * .118, -.02, .93, .05, CANDLE, 8)
        k.tube("matte", (0, 0, 1.0), (0, 0, 1.28), .13, .145, COAL, 16)
        k.tube("gold", (0, 0, 1.02), (0, 0, 1.07), .137, .138, GOLD, 16)
        k.box("glaze", 0, -.137, 1.11, .09, .02, .12, XRED)
        k.ball("gold", 0, -.15, 1.17, .03, GOLD, 8)
        k.ball("matte", 0, 0, 1.31, .07, XRED, 10, sz=.9)

def snowman(k, x, y, z, s=1.):
    """Three balls of snow, a top hat, a red scarf; faces -y."""
    with k.at(Matrix.Translation((x, y, z)) @ Matrix.Scale(s, 4)):
        k.ball("slab", 0, 0, .25, .3, SNOW, 18, sz=.92)
        k.ball("slab", 0, 0, .66, .23, SNOW, 18)
        k.ball("slab", 0, 0, 1.0, .17, SNOW, 18)
        for zz in (.42, .56, .72):
            k.ball("matte", 0, -math.sqrt(max(.23 ** 2 - (zz - .66) ** 2, .0)) if zz > .5 else -.27, zz, .03, COAL, 8)
        for sd in (-1, 1):
            k.ball("matte", sd * .058, -.15, 1.06, .023, COAL, 8)
        k.tube("matte", (0, -.15, 1.0), (.04, -.36, .99), .04, .006, CARROT, 10)
        k.lathe("glaze", 0, 0, .8, [(.1, 0), (.17, .02), (.19, .07), (.16, .12), (.1, .12)], XRED, 14)
        k.box("glaze", -.09, -.17, .54, .13, .06, .28, XRED, -.25)
        k.box("glaze", .09, -.17, .63, .12, .06, .2, XRED_D, .2)
        k.tube("matte", (0, 0, 1.12), (0, 0, 1.15), .25, .25, COAL, 16)
        k.tube("matte", (0, 0, 1.14), (0, 0, 1.42), .145, .155, COAL, 16)
        k.tube("glaze", (0, 0, 1.17), (0, 0, 1.22), .155, .157, XRED, 16)
        k.ball("leaf", .1, -.13, 1.22, .05, FIR_L, 8)
        k.ball("glaze", .05, -.15, 1.21, .03, XRED, 8)
        for sd in (-1, 1):
            k.beam("wood", (sd * .19, 0, .72), (sd * .5, -.02, .94), .035, .035, WOOD_D)
            k.beam("wood", (sd * .4, -.01, .86), (sd * .5, -.01, .82), .03, .03, WOOD_D)

def rail_fence(k, a, b, z=G, h=.3, n=4, post=.15, col=WOOD_L, wreathed=True, bow_at=(.5,), r=.075, out=(0, -1, 0)):
    """Posts, a rail and a garland on it, from a to b."""
    a3, b3 = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    for i in range(n + 1):
        p = a3.lerp(b3, i / n)
        k.box("wood", p.x, p.y, z, post, post, h + .05, J(WOOD, .04))
        k.ball("slab", p.x, p.y, z + h + .07, post * .62, SNOW, 10, sz=.5)
    k.beam("wood", (a3.x, a3.y, z + h * .86), (b3.x, b3.y, z + h * .86), .09, .09, col)
    k.beam("wood", (a3.x, a3.y, z + h * .4), (b3.x, b3.y, z + h * .4), .08, .07, WOOD)
    o = Vector(out) * .04
    if wreathed:
        garland(k, swag((a3.x + o.x, a3.y + o.y, z + h * .84), (b3.x + o.x, b3.y + o.y, z + h * .84), .05, 14), r, out=out)
    ang = math.atan2(out[1], out[0])
    for t in bow_at:
        p = a3.lerp(b3, t) + Vector(out) * .1
        with k.at(facing(p.x, p.y, z + h * .78, ang)):
            bow(k, 0, 0, 0, .12)


# ------------------------------------------------------------------ buildings

def arch(k):
    """The welcome arch: two stone piers, a timber arch, a steep snowy gable with a wreath."""
    px, py, s = 1.02, .1, .58
    zt = G + .72
    d = .78
    for sx in (-1, 1):
        x = sx * px
        k.box("stone", x, py, G, s - .06, s - .06, zt - G, STONE_D)
        pts = [(x - s / 2, py - s / 2), (x + s / 2, py - s / 2), (x + s / 2, py + s / 2), (x - s / 2, py + s / 2)]
        for a, b in zip(pts, pts[1:] + pts[:1]):
            k.wall(a, b, G, zt, t=.12, course=.2, length=.33, col=lambda: J(STONE if R.random() < .65 else STONE_L, .07))
        k.box("stone", x, py, zt, s + .12, s + .12, .08, STONE_L)
        k.ball("slab", x, py, zt + .1, s * .56, SNOW, 14, sz=.3)
        k.box("wood", x, py - .1, zt + .03, .26, .26, 1.22, WOOD_L)
        k.box("wood", x, py + .1, zt + .03, .26, .26, 1.22, WOOD)
    # the curved timber arch across the opening, springing from the piers
    zs, zr = G + .82, G + 1.98
    for yy, c in ((py - .13, WOOD_L), (py + .13, WOOD)):
        k.arch(0, zs, px - .14, .17, .15, col=c, n=9, mat="wood", y=yy)
    k.box("wood", 0, py, zr - .16, 2 * px + .38, .46, .2, WOOD)
    # gable wall, roof, wreath
    y0, y1 = py - d / 2, py + d / 2
    x0, x1 = -px - .12, px + .12
    h = 1.2
    prism_y(k, "wood", [(x0, zr), (x1, zr), (x1, zr + .05), (0, zr + h - .08), (x0, zr + .05)], y0 + .08, y1 - .04, C("#D3A566"))
    snow_gable(k, x0, x1, y0, y1, zr, h, .12)
    rake_garland(k, x0, x1, y0, zr, h, .12, .1, mid=False)
    wreath(k, 0, y0 - .03, zr + .3, .3)
    k.lights.append(((0, y0 - .55, zr + .3), 5.))
    # lanterns hanging from the posts, and bows on them
    for sx in (-1, 1):
        x = sx * (px - .3)
        k.beam("matte", (sx * (px - .1), py - .24, G + 1.32), (x, py - .24, G + 1.32), .05, .05, IRON)
        k.box("matte", x, py - .24, G + 1.14, .03, .03, .2, IRON)
        lantern(k, x, py - .24, G + .86, .14, 2.)
        bow(k, sx * (px + .02), py - .28, G + 1.5, .16)
    # the flanking firs in the snow
    deco_fir(k, -1.22, -.6, G, 1.06, .28)
    deco_fir(k, -.7, -.98, G, .8, .24)
    deco_fir(k, 1.26, -.42, G, 1.06, .24)
    deco_fir(k, .84, -.9, G, .84, .25)


def _logs(k, x, y, z, cols=4, rows=3, r=.13, depth=.7):
    for row in range(rows):
        n = cols - row
        for i in range(n):
            xx = x + (i - (n - 1) / 2) * 2 * r
            zz = z + r + row * r * 1.72
            k.tube("wood", (xx, y, zz), (xx, y + depth, zz), r, r, J(WOOD_L, .06), 12)
            k.tube("matte", (xx, y - .012, zz), (xx, y + .02, zz), r * .84, r * .84, J(C("#E7C387"), .04), 12)

def _gear(k, x, y, z, r=.24, col=STEEL):
    """A circular saw blade on a wall."""
    rot = Matrix.Rotation(math.pi / 2, 4, "X")
    k.lathe("matte", x, y, z, [(r, 0), (r, .04)], col, 24, smooth=False, m=rot)
    k.lathe("matte", x, y - .045, z, [(r * .3, 0), (r * .3, .03)], WOOD_D, 12, smooth=False, m=rot)
    for i in range(10):
        a = 2 * math.pi * i / 10
        k.box("matte", x + (r + .02) * math.cos(a), y - .02, z + (r + .02) * math.sin(a) - .035, .07, .03, .07, col)

def lumber(k):
    """Open timber workshop: log stacks, a bench, a big saw, planks leaning out front."""
    yb = Y0 + .62
    shell(k, yb=yb, post=WOOD, side=C("#A16A34"), back=C("#7E4F27"))
    # an open truss instead of a plastered gable
    prism_y(k, "matte", [(X0, ZW - .04), (X1, ZW - .04), (X1, ZW + .08), (0, ZW + RH - .06), (X0, ZW + .08)], Y0 + .26, Y1 - .06, C("#6B4422"))
    k.box("wood", 0, Y0, ZW + .02, 2 * X1 + .1, .2, .16, WOOD_L)
    k.box("wood", 0, Y0 + .01, ZW + .02, .2, .15, RH - .42, WOOD_L)   # shallower than the tie beam: no shared face
    for s in (-1, 1):
        k.beam("wood", (s * X1 * .95, Y0, ZW + .08), (s * .1, Y0, ZW + RH * .62), .18, .18, WOOD_L)
        k.beam("wood", (s * .5, Y0, ZW + .1), (s * .1, Y0, ZW + .48), .13, .14, WOOD)
    snow_gable(k, X0, X1, Y0, Y1, ZW, RH)
    rake_garland(k, X0, X1, Y0, ZW, RH)
    side_garland(k, X1, Y0, Y1, ZW)
    inner_glow(k, yb=yb, col=C("#B26C2A"), watts=16.)
    # the back wall: logs, a saw blade and a hand saw
    _logs(k, -.62, yb - .42, G + .05, 3, 3, .14, .4)
    _gear(k, .42, yb - .05, G + .5, .25)
    # a big hand saw hanging on the wall
    k.poly("matte", [(-.2, yb - .06, G + .82), (.02, yb - .06, G + .82), (-.06, yb - .06, G + .22), (-.14, yb - .06, G + .22)], STEEL)
    k.box("wood", -.09, yb - .08, G + .76, .26, .05, .17, WOOD_D)
    # the workbench and its load
    zb = G + .44
    k.box("wood", .36, Y0 + .02, zb, 1.2, .52, .1, WOOD_L)
    for x in (-.14, .86):
        for y in (Y0 - .18, Y0 + .18):
            k.box("wood", x, y, G, .13, .13, zb - G, WOOD)
    k.box("wood", .24, Y0 + .02, zb + .1, .74, .24, .08, C("#E7C387"))
    k.box("matte", .74, Y0 - .02, zb + .1, .2, .16, .13, STEEL)
    k.tube("wood", (.08, Y0 - .08, zb + .22), (.42, Y0 - .1, zb + .22), .05, .05, WOOD_D, 10)
    # hanging lanterns
    for x in (-.5, .9):
        k.box("matte", x, Y0 + .02, ZW - .42, .035, .035, .24, IRON)
        lantern(k, x, Y0 + .02, ZW - .72, .13, 2.5)
    # out front: leaning planks, barrel, crates and a stack of boards
    for i, x in enumerate((-1.2, -1.04, -.88)):
        k.beam("wood", (x, -1.12, G), (x + .06, Y0 - .16, G + 1.1), .14, .05, J(C("#D9A766"), .05))
    barrel(k, -.5, -.98, G, .22, .46)
    snow_crate(k, .02, -1.04, G, .36)
    for i, c in enumerate(("#D9A766", "#C69555", "#D9A766")):
        k.box("wood", .66, -1.14, G + i * .085, .78 - i * .08, .26, .08, C(c))
    k.ball("slab", .66, -1.14, G + .28, .24, SNOW, 12, sx=1.25, sz=.22)
    deco_fir(k, 1.3, -.92, G, .84, .2)
    # stacked firewood against the +X wall
    for row in range(3):
        for i in range(5 - row):
            y = .28 + (i - (4 - row) / 2) * .21
            z = G + .11 + row * .18
            k.tube("wood", (X1 + .1, y, z), (X1 + .31, y, z), .105, .105, J(WOOD_L, .05), 10)
            k.tube("matte", (X1 + .3, y, z), (X1 + .325, y, z), .085, .085, C("#E7C387"), 10)
    k.ball("slab", X1 + .22, .28, G + .53, .3, SNOW, 12, sy=1.25, sz=.2)


def _pretzel_path(s):
    pts = [(-.26, -.58), (-.05, -.08), (.28, .32), (.62, .58), (.92, .34), (.94, -.1), (.68, -.56), (.28, -.82), (0, -.86),
           (-.28, -.82), (-.68, -.56), (-.94, -.1), (-.92, .34), (-.62, .58), (-.28, .32), (.05, -.08), (.26, -.58)]
    return [(x * s, y * s) for x, y in pts]

def pretzel(k, x, y, z, s=.33):
    pts = spline([(x + px, y, z + pz) for px, pz in _pretzel_path(s)], 4)
    rope(k, "matte", pts, s * .2, C("#C78433"), 10)
    # coarse salt, big enough to read
    for i in range(3, len(pts) - 3, 5):
        p = pts[i]
        k.ball("matte", p[0], p[1] - s * .18, p[2], .028, CANDLE, 6)

def bakery(k):
    """Gingerbread bakery: pretzel on the gable, striped awning, gingerbread on the counter."""
    shell(k, post=WOOD, side=CREAM)
    gable_wall(k, king=False)
    snow_gable(k, X0, X1, Y0, Y1, ZW, RH)
    rake_garland(k, X0, X1, Y0, ZW, RH)
    side_garland(k, X1, Y0, Y1, ZW)
    chimney(k, .58, .55, ZW + .46, ZW + 1.46)
    pretzel(k, 0, Y0 - .07, ZW + .46, .36)
    inner_glow(k, col=C("#C57C30"), watts=14.)
    # back shelves of gingerbread
    shelf(k, -.9, .9, YB - .15, G + .42, .22)
    for x in (-.68, -.24, .24, .68):
        gingerbread_man(k, x, YB - .15, G + .47, .17)
    # the counter
    z = G + .44
    k.box("wood", 0, Y0 + .2, G, 2.0, .3, z - G, WOOD)
    k.box("wood", 0, Y0 + .16, z, 2.1, .42, .07, WOOD_L)
    garland(k, swag((-1., Y0 - .06, z - .03), (1., Y0 - .06, z - .03), .1), .07)
    for x in (-.5, .5):
        bow(k, x, Y0 - .12, z - .1, .11)
    # gingerbread out on the counter
    gingerbread_man(k, -.74, Y0 + .16, z + .07, .2)
    gingerbread_man(k, -.36, Y0 + .16, z + .07, .2)
    gingerbread_house(k, .1, Y0 + .18, z + .07, .36)
    gingerbread_man(k, .5, Y0 + .16, z + .07, .2)
    k.lathe("glaze", .82, Y0 + .16, z + .07, [(.06, 0), (.17, .05), (.2, .08), (.17, .08)], CANDLE, 16)
    for t in range(3):
        a = t * 2.1
        k.ball("matte", .82 + .08 * math.cos(a), Y0 + .16 + .08 * math.sin(a), z + .18, .07, GINGER_L, 10, sz=.5)
    # the red and white awning sits high, so the goods stay in view
    k.awning(X0 - .02, X1 + .02, Y0 - .22, Y0 + .1, ZW - .04, ZW + .26, (XRED, C("#FBF3E6")), n=8, hang=.16)
    # the +X wall
    side_timber(k, gap=(-.1, .8))
    shop_window(k, .25, G + .46, .78, .86)
    deco_fir(k, -1.26, -.92, G, .96, .26)
    deco_fir(k, -.1, -1.2, G, .62, .19, ribbon=False)
    deco_fir(k, 1.24, -.9, G, .96, .25)


def cocoa(k):
    """Hot cocoa kiosk: red and green, candy-cane posts, gold urn, a smoking chimney."""
    x0, x1, y0, y1 = -1.04, 1.04, -.5, .95
    zw, h = G + 1.56, 1.26
    yb = y0 + .6
    ym = (y0 + y1) / 2
    k.box("wood", 0, ym, G, x1 - x0, y1 - y0, .05, WOOD_D)
    k.box("matte", 0, (yb + y1) / 2, G, x1 - x0 - .1, y1 - yb, zw - G, XGREEN)
    k.box("matte", x0 + .06, ym, G, .12, y1 - y0, zw - G, XGREEN)
    k.box("matte", x1 - .05, ym, G, .1, y1 - y0, zw - G, C("#E7C387"))
    for x in (x1 + .002,):
        k.box("wood", x, y1, G, .2, .2, zw - G, XGREEN)
    # candy-cane corner posts and a green header
    zc = G + .56
    for x, y in ((x0 + .03, y0 - .02), (x1 - .03, y0 - .02)):
        candy_post(k, x, y, zc, zw - .1, .11, 6)
    k.box("wood", 0, y0, zw - .2, x1 - x0 + .24, .24, .22, XGREEN)
    prism_y(k, "matte", [(x0, zw - .04), (x1, zw - .04), (x1, zw + .08), (0, zw + h - .06), (x0, zw + .08)], y0 + .02, y1 - .06, C("#2B6E45"))
    k.box("wood", 0, y0 - .025, zw, .13, .08, h - .4, C("#E7C387"))
    for s in (-1, 1):
        k.beam("wood", (s * .9, y0 - .025, zw + .05), (s * .1, y0 - .025, zw + h * .6), .12, .08, C("#E7C387"))
    snow_gable(k, x0, x1, y0, y1, zw, h)
    rake_garland(k, x0, x1, y0, zw, h)
    side_garland(k, x1, y0, y1, zw)
    cx, cy = .5, .55
    chimney(k, cx, cy, zw + .42, zw + 1.26, .38)
    # a soft plume of smoke, drifting to the right of the screen
    for dx, dy, dz, r in ((.0, .0, 1.38, .09), (.06, .04, 1.5, .13), (.14, .08, 1.63, .17), (.3, .1, 1.72, .15), (.34, .22, 1.86, .22), (.54, .26, 1.92, .2), (.56, .36, 2.1, .16)):
        k.ball("matte", cx + dx, cy + dy, zw + dz, r, C("#DADDE3"), 12, sz=.8)
    # the red counter on -Y and +X, with wreaths on its panels
    k.box("matte", 0, y0 + .08, G, x1 - x0 + .1, .2, zc - G, XRED)
    k.box("matte", x1 - .01, ym, G, .14, y1 - y0, zc - G, XRED)
    k.box("wood", 0, y0 + .14, zc, x1 - x0 + .22, .46, .07, C("#E7C387"))
    k.box("wood", x1 + .02, ym, zc - .02, .24, y1 - y0 + .02, .07, C("#DDB678"))
    k.box("matte", 0, y0 + .07, G + .01, x1 - x0 + .15, .24, .09, XGREEN)
    k.box("matte", x1 + .005, ym, G + .01, .17, y1 - y0, .09, XGREEN)
    with k.at(Matrix.Translation((0, y0 - .04, 0))):
        for x in (-.54, .54):
            wreath(k, x, 0, G + .34, .15, top_bow=False)
            bow(k, x, -.05, G + .47, .08)
    with k.at(facing(x1 + .08, .24, 0, SIDE)):
        wreath(k, 0, 0, G + .34, .15, top_bow=False)
        bow(k, 0, -.05, G + .47, .08)
    # the lit back wall and its tins
    k.box("glow", 0, yb - .02, zc, x1 - x0 - .24, .04, zw - zc - .2, C("#B6843F"))
    k.lights.append(((0, y0 + .2, zw - .32), 12.))
    k.box("wood", -.42, yb - .13, G + .84, 1.0, .2, .05, WOOD_D)
    for x, c in ((-.74, XRED), (-.44, CANDLE), (-.14, XGREEN)):
        k.lathe("glaze", x, yb - .13, G + .89, [(.09, 0), (.09, .2), (.05, .24)], c, 12)
    # the big urn: a gold samovar with dark bands, a lid and a spigot
    ux, uy = .3, y0 + .2
    zt = zc + .07
    bright = C("#F4C64C")
    k.lathe("gold", ux, uy, zt, [(.17, 0), (.17, .05), (.09, .1), (.2, .16), (.23, .3), (.23, .5), (.19, .62)], bright, 20)
    k.lathe("matte", ux, uy, zt + .22, [(.238, 0), (.238, .05)], XRED_D, 20, smooth=False)
    k.lathe("matte", ux, uy, zt + .46, [(.238, 0), (.238, .05)], XRED_D, 20, smooth=False)
    k.lathe("gold", ux, uy, zt + .6, [(.2, 0), (.2, .03), (.1, .12), (.03, .16)], GOLD_D, 16)
    k.ball("gold", ux, uy, zt + .8, .055, bright, 10)
    k.tube("gold", (ux, uy - .2, zt + .26), (ux, uy - .33, zt + .24), .04, .034, GOLD_D, 10)
    k.box("matte", ux, uy - .33, zt + .25, .03, .03, .09, COAL)
    for sd in (-1, 1):
        rope(k, "matte", [(ux + sd * .22, uy, zt + .54), (ux + sd * .33, uy, zt + .46), (ux + sd * .23, uy, zt + .34)], .024, COAL, 6)
    k.lights.append(((ux - .35, uy - .4, zt + .35), 2.))
    # mugs and a jar of canes
    for x, c in ((-.8, XRED), (-.28, C("#FBF3E6")), (-.08, XRED), (.78, C("#FBF3E6"))):
        mug(k, x, y0 + .02, zt, c, .075)
    k.lathe("glass", -.56, y0 + .18, zt, [(.1, 0), (.11, .24), (.1, .28)], GLASS, 12)
    for dx, dy in ((-.04, .0), (.04, .02), (0, -.04)):
        candy_post(k, -.56 + dx, y0 + .18 + dy, zt + .02, zt + .42, .024, 3)
    gift(k, .8, y0 + .22, zt, .2, XRED, GOLD)
    # the barrel with its small fir, and the firs on the corners
    barrel(k, -1.3, -.3, G, .17, .34, cap=False)
    fir(k, -1.3, -.3, G + .3, .62, .19, 3, trunk=.05)
    deco_fir(k, -1.2, -1.0, G, .78, .22, ribbon=False)
    deco_fir(k, 1.26, -.86, G, .92, .24)
    deco_fir(k, .16, -1.22, G, .54, .17, ribbon=False)


def _door(k, s, z, r=.3, h=.72):
    """An arched planked door in a wall frame, with its wreath, knob and snow hood."""
    k.arch_fill(s, z, z + h - r, r, C("#7C4A22"), y=-.05, mat="wood")
    k.arch(s, z + h - r, r, .08, .1, col=WOOD_D, y=-.06, n=9, mat="wood")
    for sd in (-1, 1):
        k.box("wood", s + sd * (r + .04), -.06, z, .08, .1, h - r, WOOD_D)
    for d in (-.14, 0, .14):
        k.box("wood", s + d, -.075, z, .05, .012, h - .06 - abs(d) * 1.2, C("#935A2B"))
    k.ball("gold", s + r * .7, -.11, z + .34, .028, GOLD, 8)
    wreath(k, s, -.11, z + h - .24, .15, top_bow=True)
    k.arch(s, z + h - r, r + .08, .075, .2, col=SNOW, y=-.1, n=9, mat="slab")
    k.box("stone", s, -.22, G, 2 * r + .34, .34, .05, STONE_L)

def toys(k):
    """Toymaker's workshop: a cottage with door, toy window, dormer and the nutcracker."""
    yb = Y0 + .5
    shell(k, yb=yb, post=WOOD, side=CREAM, back=C("#8B5A2B"))
    gable_wall(k, king=False)
    # the left part of the facade is solid: door and plaster
    xd = -.12
    k.box("matte", (X0 + xd) / 2, Y0 + .08, G, xd - X0, .12, ZW - G - .18, CREAM)
    k.box("wood", xd, Y0, G, .2, .22, ZW - G, WOOD)
    with k.at(wall_frame((X0, Y0), (X1, Y0))):
        _door(k, .52, G + .03, .3, 1.0)
    for x in (X0 + .13, X0 + .92):
        k.box("wood", x, Y0 + .005, G + .02, .09, .08, ZW - G - .2, WOOD)
    k.box("wood", (X0 + xd) / 2, Y0 + .005, G + 1.14, xd - X0, .08, .09, WOOD)
    # the lit toy window on the right
    inner_glow(k, xd, X1, yb=yb, col=C("#D08A36"), watts=12.)
    shelf(k, xd + .1, X1 - .1, yb - .12, G + .62, .2)
    for i, (c, rb) in enumerate(((XRED, GOLD), (XGREEN, GOLD), (GOLD, XRED), (XRED, XGREEN))):
        gift(k, xd + .26 + i * .27, yb - .12, G + .67, .2, c, rb)
    zc = G + .44
    k.box("wood", (xd + X1) / 2, Y0 + .1, zc, X1 - xd + .1, .44, .08, WOOD_L)
    k.box("wood", (xd + X1) / 2, Y0 + .08, G, X1 - xd - .1, .1, zc - G, WOOD)
    gift(k, .14, Y0 + .1, zc + .08, .26, XRED, GOLD)
    gift(k, .46, Y0 + .1, zc + .08, .3, XGREEN, XRED)
    k.lathe("glaze", .86, Y0 + .1, zc + .08, [(.13, 0), (.13, .19)], XRED, 14, smooth=False)
    k.lathe("gold", .86, Y0 + .1, zc + .07, [(.14, 0), (.14, .035)], GOLD, 14, smooth=False)
    k.lathe("gold", .86, Y0 + .1, zc + .25, [(.14, 0), (.14, .035)], GOLD, 14, smooth=False)
    # the gable window and timbers
    with k.at(wall_frame((X0, Y0), (X1, Y0))):
        k.window(1.1, ZW + .26, ZW + .46, .2, fill=AMBER, trim=WOOD_D, trim_mat="wood")
    k.box("wood", 0, Y0 - .07, ZW + .24, .05, .03, .4, WOOD_D)
    k.box("wood", 0, Y0 - .07, ZW + .44, .4, .03, .05, WOOD_D)
    snow_gable(k, X0, X1, Y0, Y1, ZW, RH)
    rake_garland(k, X0, X1, Y0, ZW, RH)
    side_garland(k, X1, Y0, Y1, ZW)
    chimney(k, -.5, .8, ZW + .5, ZW + 1.5, .4)
    # the dormer on the +X slope
    with k.at(facing(.84, .36, 0, SIDE)):
        dz, dh = ZW + .56, .42
        k.box("matte", 0, .32, dz - .14, .56, .64, dh + .14, CREAM)
        k.box("glow", 0, -.012, dz + .06, .34, .03, dh - .12, AMBER)
        k.box("wood", 0, -.04, dz + .06, .05, .03, dh - .1, WOOD_D)
        k.box("wood", 0, -.04, dz + dh * .55, .34, .03, .05, WOOD_D)
        for s in (-1, 1):
            k.box("wood", s * .27, -.0, dz - .04, .08, .08, dh + .04, WOOD)
        k.box("wood", 0, -.0, dz - .05, .6, .09, .08, WOOD)
        prism_y(k, "matte", [(-.3, dz + dh), (.3, dz + dh), (0, dz + dh + .34)], .0, .62, CREAM)
        snow_gable(k, -.3, .3, .0, .62, dz + dh, .36, .05, th=.07, lip=.05)
    # a lantern on an iron arm beside the door
    k.beam("matte", (X0 + .13, Y0 - .02, G + 1.14), (X0 + .13, Y0 - .24, G + 1.14), .04, .04, IRON)
    lantern(k, X0 + .13, Y0 - .24, G + .78, .13, 1.8)
    # the +X wall
    side_timber(k, gap=(-.3, .9))
    shop_window(k, .25, G + .46, .9, .86)
    # the nutcracker, a barrel and firs
    nutcracker(k, .1, -.98, G, 1.02)
    barrel(k, -.9, -.86, G, .18, .34)
    deco_fir(k, -1.28, -1.12, G, .76, .2, ribbon=False)
    deco_fir(k, .78, -1.08, G, .8, .23)
    deco_fir(k, 1.3, -.66, G, .96, .19)


def _roll(k, x, y, z, h, r, col, stripe):
    """A standing roll of wrapping paper with a bright stripe around it."""
    k.tube("matte", (x, y, z), (x, y, z + h), r, r, col, 12)
    for t in (.22, .6):
        k.tube("matte", (x, y, z + h * t), (x, y, z + h * (t + .13)), r + .008, r + .008, stripe, 12)

def _tent_face(k, a, ym, ze, half, h, th=.13):
    """One snowy slope of the pavilion's square tent, with a wavy eave."""
    ph = [R.uniform(0, 6.28) for _ in range(4)]
    L = math.hypot(half, h)
    nrm, down = Vector((0, -h / L, half / L)), Vector((0, -half / L, -h / L))
    l0, reach, grow = -th * h / half, L + .12, th * 1.4     # grow: neighbouring faces overlap at the hips
    def fn(u, v):
        l = l0 + (reach - l0) * v
        x = (half * max(l, 0) / L * 1.0 + grow) * (2 * u - 1)
        p = Vector((x, 0, ze + h)) + down * l
        b = .02 * math.sin(x * 4.3 + ph[0]) * math.sin(l * 4 + ph[1])
        p += nrm * (th + b * max(0, min(1, l)))
        e = max(0, (l - L) / .12)
        p -= nrm * (e * e * (.15 + .05 * math.sin(x * 8.7 + ph[2]) + .025 * math.sin(x * 17 + ph[3])))
        return tuple(p)
    with k.at(Matrix.Translation((0, ym, 0)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")):
        k.surface("matte", fn, 34, 30, SNOW)

def gifts(k):
    """Gift wrapping pavilion: posts, drapes, a counter of parcels, a snowy tent with a red opening."""
    ym, hw = .2, 1.0
    x0, x1, y0, y1 = -hw, hw, ym - hw + .16, ym + hw
    yb = y0 + .55
    ze = G + 1.72
    k.box("wood", 0, (y0 + y1) / 2, G, x1 - x0, y1 - y0, .05, WOOD_L)
    k.box("cloth", 0, (yb + y1) / 2, G, x1 - x0 - .1, y1 - yb, ze - G, C("#A71E28"))
    k.box("cloth", x0 + .05, (y0 + y1) / 2, G, .1, y1 - y0, ze - G, XRED)
    k.box("wood", x1 - .05, (y0 + y1) / 2, G, .1, y1 - y0, ze - G, C("#B9803F"))
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        k.box("wood", x, y, G, .2, .2, ze - G + .02, WOOD)
    for a, b in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1))):
        k.beam("wood", (a[0], a[1], ze - .1), (b[0], b[1], ze - .1), .22, .22, WOOD)
    k.lights.append(((0, y0 + .2, ze - .4), 18.))
    k.lights.append(((.4, y0 - .4, G + .9), 2.))
    # shelf of parcels on the back wall
    z = G + .42
    shelf(k, x0 + .2, x1 - .2, yb - .14, z, .24)
    for i, (c, rb) in enumerate(((XGREEN, XRED), (GOLD, XRED), (XRED, GOLD), (CANDLE, XRED), (XGREEN, GOLD))):
        gift(k, x0 + .36 + i * .32, yb - .14, z + .05, .25, c, rb)
    # rolls of paper by the left post
    for i, (x, y, c, st) in enumerate(((-.8, y0 + .14, XRED, GOLD), (-.62, y0 + .3, C("#FBF3E6"), XRED), (-.84, y0 + .36, XGREEN, CANDLE), (-.62, y0 + .02, GOLD, XRED))):
        _roll(k, x, y, G + .05, 1.04 - i * .07, .08, c, st)
    # the counter, with a red cloth and parcels
    zc = G + .44
    k.box("wood", .24, y0 + .1, G, 1.34, .36, zc - G, WOOD_L)
    k.box("cloth", .24, y0 + .08, zc, 1.46, .5, .06, XRED)
    k.box("cloth", .24, y0 - .15, zc - .14, 1.46, .03, .17, XRED)
    k.box("gold", .24, y0 - .165, zc - .14, 1.46, .02, .04, GOLD)
    for x in (-.2, .68):
        k.box("wood", x, y0 - .085, G + .06, .36, .03, .22, WOOD)
    gift(k, -.2, y0 + .08, zc + .06, .26, XGREEN, XRED)
    gift(k, .22, y0 + .1, zc + .06, .32, C("#FBF3E6"), XRED)
    gift(k, .64, y0 + .08, zc + .06, .26, XRED, GOLD)
    gift(k, .24, y0 + .1, zc + .34, .17, GOLD, XRED)
    # the tent: a steep square of timber under snow, and a gold finial
    half, h = hw + .18, 1.24
    Rr = half * math.sqrt(2)
    rot = Matrix.Rotation(math.pi / 4, 4, "Z")
    k.lathe("wood", 0, ym, ze - .03, [(Rr, 0), (Rr, .08), (.02, h + .08)], WOOD_D, 4, smooth=False, m=rot)
    for a in (-math.pi / 2, 0, math.pi / 2, math.pi):
        _tent_face(k, a, ym, ze + .03, half, h)
    top = ze + h + .03 + .13 * math.hypot(half, h) / half
    k.lathe("gold", 0, ym, top - .03, [(.13, 0), (.06, .1), (.11, .18), (.05, .28), (.001, .5)], GOLD, 12)
    k.ball("gold", 0, ym, top + .21, .08, GOLD, 10)
    # red tent cloth showing through the snow on both camera faces, framed in gold
    L = math.hypot(half, h)
    for a in (-math.pi / 2, 0):
        with k.at(Matrix.Translation((0, ym, 0)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")):
            nrm, down = Vector((0, -h / L, half / L)), Vector((0, -half / L, -h / L))
            def on(x, l, lift):
                return tuple(Vector((x, 0, ze + .03 + h)) + down * l + nrm * (.13 + lift))
            lo = L * .66
            wd = half * .46
            k.poly("cloth", [on(-wd, lo, .04), on(wd, lo, .04), on(0, .05, .04)], XRED)
            k.poly("cloth", [on(-wd * .5, lo, .05), on(wd * .5, lo, .05), on(0, lo * .4, .05)], C("#7E141D"))
            for sd in (-1, 1):
                k.beam("gold", on(sd * wd * 1.03, lo, .04), on(0, .08, .04), .07, .05, GOLD)
            # a soft roll of snow along its lower edge
            for x in resample([(-wd - .04, 0, 0), (wd + .04, 0, 0)], .11):
                p = on(x.x, lo + .03, .03)
                k.ball("slab", p[0], p[1], p[2], R.uniform(.075, .105), SNOW, 10, sz=.8)
    # garland along the eave with big bows
    ge = ym - half - .11
    garland(k, [(-half, ge, ze - .1), (half, ge, ze - .1)], .1)
    gx = half + .12
    garland(k, [(gx, ym - half, ze - .1), (gx, ym + half * .7, ze - .1)], .095, out=(1, 0, 0))
    for x, s in ((-half + .08, .2), (0, .22), (half - .1, .2)):
        bow(k, x, ge - .09, ze - .08, s)
    for yy in (ym - .2, ym + .6):
        with k.at(facing(gx + .08, yy, ze - .08, SIDE)):
            bow(k, 0, 0, 0, .17)
    # red drapes drawn back to the front posts
    for x, s in ((x0 + .12, 1), (x1 - .12, -1)):
        k.ball("cloth", x + s * .14, y0 - .03, ze - .36, .24, XRED, 14, sx=.8, sy=.3, sz=1.05)
        k.tube("cloth", (x + s * .08, y0 - .03, ze - .55), (x + s * .01, y0 - .03, G + .1), .11, .08, XRED, 10)
        k.ball("gold", x + s * .05, y0 - .11, G + .72, .055, GOLD, 8)
    for x in (-.42, .42):
        k.box("matte", x, y0 - .02, ze - .55, .03, .03, .4, IRON)
        lantern(k, x, y0 - .02, ze - .84, .13, 2.2)
    # the +X wall: a wreath, and parcels stacked against it
    with k.at(facing(x1 + .02, .22, 0, SIDE)):
        wreath(k, 0, 0, G + 1.04, .22)
    gift(k, x1 + .17, -.1, G, .26, XGREEN, XRED)
    gift(k, x1 + .17, .24, G, .3, XRED, GOLD)
    gift(k, x1 + .17, .24, G + .26, .18, GOLD, XRED)
    # firs and the crate of parcels outside
    deco_fir(k, -1.28, -.92, G, 1.0, .22)
    deco_fir(k, 1.3, -.72, G, 1.0, .2)
    deco_fir(k, -.54, -1.24, G, .66, .2, ribbon=False)
    k.crate(.68, -1.24, G, .3)
    gift(k, .68, -1.24, G + .36, .22, XRED, GOLD)
    gift(k, .22, -1.28, G, .24, XGREEN, XRED)


def _iron_arm(k, x, y, zb, reach=.32, s=.14):
    """A curling iron bracket on a post, carrying a lantern."""
    rope(k, "matte", spline([(x, y, zb + .5), (x, y - reach * .6, zb + .54), (x, y - reach, zb + .5)], 4), .024, IRON, 6)
    k.beam("matte", (x, y, zb + .2), (x, y - reach * .6, zb + .52), .022, .022, IRON)
    k.box("matte", x, y - reach, zb + .36, .024, .024, .14, IRON)
    lantern(k, x, y - reach, zb + .03, s, 2.)

def candles(k):
    """Candlelight shop: blue timbers, a wreathed gable, candles on every shelf, iron lanterns."""
    shell(k, post=NAVY, side=CREAM, back=C("#8C6230"))
    gable_wall(k, col=CREAM, beams=NAVY, king=False)
    snow_gable(k, X0, X1, Y0, Y1, ZW, RH)
    rake_garland(k, X0, X1, Y0, ZW, RH)
    side_garland(k, X1, Y0, Y1, ZW)
    chimney(k, .58, .55, ZW + .46, ZW + 1.46)
    wreath(k, 0, Y0 - .08, ZW + .44, .31)
    k.lights.append(((0, Y0 - .5, ZW + .5), 1.2))
    inner_glow(k, col=C("#BE7A30"), watts=9.)
    shelf(k, -.9, .9, YB - .15, G + .42, .22)
    for i in range(6):
        candle(k, -.75 + i * .3, YB - .15, G + .47, .06, .2 + (i % 2) * .08)
    # the counter with its candles
    zc = G + .44
    k.box("matte", 0, Y0 + .2, G, 1.96, .3, zc - G, NAVY)
    k.box("wood", 0, Y0 + .16, zc, 2.1, .42, .07, WOOD_L)
    for x in (-.64, 0, .64):
        k.box("matte", x, Y0 + .035, G + .07, .5, .03, .27, NAVY_D)
    for x, h, r in ((-.8, .26, .075), (-.58, .16, .075), (-.36, .32, .085), (-.12, .2, .07), (.12, .3, .085), (.36, .16, .075), (.6, .34, .085), (.84, .2, .075)):
        candle(k, x, Y0 + .14, zc + .07, r, h)
    k.lights.append(((0, Y0 - .2, zc + .55), 2.6))
    garland(k, swag((-1., Y0 - .03, zc - .02), (1., Y0 - .03, zc - .02), .08), .065, bulbs=True)
    bow(k, 0, Y0 - .09, zc - .09, .11)
    front_swag(k, sag=.08)
    # blue timbers, a big window on the +X wall
    side_timber(k, col=NAVY, gap=(-.4, 1.1))
    shop_window(k, .25, G + .46, .92, .88, frame=NAVY)
    k.box("wood", 0, Y0, G, 2 * X1 + .18, .24, .1, NAVY_D)
    _iron_arm(k, X0 - .02, Y0 - .1, G + .62, .24, .15)
    _iron_arm(k, X1 + .02, Y0 - .1, G + .62, .24, .15)
    deco_fir(k, -1.28, -.84, G, .86, .2)
    deco_fir(k, -.3, -1.14, G, .62, .19, ribbon=False)
    deco_fir(k, .5, -1.12, G, .76, .23)
    deco_fir(k, 1.3, -.72, G, .86, .19)


def carousel(k):
    """Reindeer carousel: round deck, gold poles, garlanded canopy, red and white peak."""
    door = math.radians(-60)
    z0, zd = G, G + .16
    Rp = 1.12
    k.lathe("wood", 0, 0, z0, [(Rp, 0), (Rp, .11)], XRED_D, 48, smooth=False)
    k.lathe("wood", 0, 0, z0 + .09, [(Rp - .08, 0), (Rp - .08, .07)], C("#C6803F"), 48, smooth=False)
    with k.at(radial_frame(0, 0, 1.16, door)):
        k.box("wood", 0, -.05, z0, .66, .22, .07, XRED)
    # fence ring with garland and bows, open at the door
    Rf, nf = 1.38, 18
    step = (2 * math.pi - .86) / nf
    for i in range(nf + 1):
        a0 = door + .43 + i * step
        a1 = a0 + step
        px, py = Rf * math.cos(a0), Rf * math.sin(a0)
        k.box("wood", px, py, z0, .13, .13, .34, J(WOOD_L, .04), a0)
        k.ball("slab", px, py, z0 + .36, .085, SNOW, 10, sz=.5)
        if i < nf:
            qx, qy = Rf * math.cos(a1), Rf * math.sin(a1)
            k.beam("wood", (px, py, z0 + .24), (qx, qy, z0 + .24), .07, .07, WOOD)
            garland(k, [(px, py, z0 + .24), (qx, qy, z0 + .24)], .078, out=(math.cos(a0), math.sin(a0), 0))
            if i % 3 == 0 and i not in (6, 9):
                with k.at(radial_frame(0, 0, Rf + .09, (a0 + a1) / 2)):
                    bow(k, 0, 0, z0 + .26, .11)
    # the central drum
    zc = zd + 1.84
    k.lathe("gold", 0, 0, zd, [(.34, 0), (.34, .1), (.25, .14), (.25, zc - zd - .12), (.34, zc - zd - .06), (.34, zc - zd)], GOLD, 24)
    k.lathe("flame", 0, 0, zd + .2, [(.26, 0), (.26, 1.36)], C("#FFB84E"), 24)
    for i in range(10):
        a = 2 * math.pi * i / 10
        cx, cy = .28 * math.cos(a), .28 * math.sin(a)
        k.tube("gold", (cx, cy, zd + .1), (cx, cy, zc - .05), .026, .026, GOLD_D, 8)
    with k.at(radial_frame(0, 0, .31, door)):
        wreath(k, 0, 0, zd + .7, .18)
    k.lights.append(((.2, -.44, zd + .75), 9.))
    k.lights.append(((-.72, -.74, zd + 1.2), 5.))
    k.lights.append(((.86, -.4, zd + 1.2), 5.))
    # reindeer on the camera side, more behind
    for a, sc in ((-122, 1.06), (-8, 1.06), (70, 1.), (160, 1.)):
        t = math.radians(a)
        reindeer(k, .72 * math.cos(t), .72 * math.sin(t), zd - .02, t + math.pi / 2, sc, zc - zd + .05)
    # slim gold posts holding the canopy
    Rc = 1.14
    for i in range(8):
        a = door + math.pi / 8 + i * math.pi / 4
        cx, cy = .99 * math.cos(a), .99 * math.sin(a)
        k.tube("gold", (cx, cy, zd), (cx, cy, zc + .05), .042, .042, GOLD, 10)
    # canopy: warm underside, gold band, striped peak, snow around its rim
    k.lathe("wood", 0, 0, zc, [(Rc, 0), (.1, .1)], C("#D9A350"), 40)
    k.lathe("gold", 0, 0, zc - .02, [(Rc + .03, 0), (Rc + .05, .05), (Rc + .05, .2), (Rc, .22)], GOLD, 48)
    zr, zp = zc + .2, zc + 1.2
    def roof(rt):
        return zr + (zp - zr) * (1 - rt) ** 1.05
    n = 12
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n + door, 2 * math.pi * (i + 1) / n + door
        def fn(u, v, a0=a0, a1=a1):
            a = a0 + (a1 - a0) * u
            rt = 1 - v
            d = Rc * rt + .001
            return (d * math.cos(a), d * math.sin(a), roof(rt))
        k.surface("cloth", fn, 3, 5, XRED if i % 2 else C("#FBF3E6"))
    # the snow skirt: wavy upper edge, pouring over the band
    ph = [R.uniform(0, 6.28) for _ in range(5)]
    def skirt(u, v):
        a = 2 * math.pi * u + door
        inner = .84 + .05 * math.sin(a * 5 + ph[0]) + .035 * math.sin(a * 9 + ph[1])
        rad = inner + (Rc + .13 - inner) * v
        rt = min(rad, Rc) / Rc
        z = roof(rt) + .1 * min(1, v * 6) * (1 + .22 * math.sin(a * 7 + rad * 4 + ph[2]))
        e = max(0, (rad - Rc) / .13)
        z -= e * e * (.22 + .06 * math.sin(a * 11 + ph[3]) + .03 * math.sin(a * 23 + ph[4]))
        return (rad * math.cos(a), rad * math.sin(a), z)
    k.surface("matte", skirt, 96, 18, SNOW)
    # finial
    k.lathe("gold", 0, 0, zp - .04, [(.14, 0), (.1, .1), (.05, .14), (.04, .2)], GOLD, 14)
    k.ball("gold", 0, 0, zp + .27, .13, GOLD, 16)
    # swags of garland hung from the band, with bows and lights
    ns = 10
    for i in range(ns):
        a0, a1 = 2 * math.pi * i / ns + door + .1, 2 * math.pi * (i + 1) / ns + door + .1
        rr = Rc + .08
        p, q = (rr * math.cos(a0), rr * math.sin(a0), zc - .02), (rr * math.cos(a1), rr * math.sin(a1), zc - .02)
        am = (a0 + a1) / 2
        garland(k, swag(p, q, .13, 7), .072, out=(math.cos(am), math.sin(am), 0))
        with k.at(radial_frame(0, 0, rr + .06, a0)):
            bow(k, 0, 0, zc + .02, .15)


def rink(k):
    """Winter skating rink: pale ice, low garlanded fence, four tall lanterns, firs in the corners."""
    hs = 1.1
    k.box("matte", 0, 0, G - .02, 2 * hs - .1, 2 * hs - .1, .03, C("#6E9CBD"))
    k.box("glaze", 0, 0, G, 2 * hs - .02, 2 * hs - .02, .04, ICE)
    # skate marks, big enough to read, each a layer above the ice
    for i, (x, y, r, sy) in enumerate(((-.42, .15, .62, .42), (.45, -.3, .56, .36), (.25, .55, .38, .8))):
        pts = []
        for j in range(26):
            a = j / 25 * 5.2 + i
            pts.append((x + r * math.cos(a), y + r * sy * math.sin(a), G + .05 + i * .002))
        for a, b in zip(pts, pts[1:]):
            k.beam("matte", a, b, .028, .004, ICE_L)
    # warm pools of lantern light on the ice
    warm = C("#F6E3BC")
    for i, (x, y, r) in enumerate(((-.72, .72, .36), (.72, -.72, .36), (-.72, -.72, .32), (.72, .72, .32))):
        def fn(u, v, x=x, y=y, r=r, i=i):
            a = 2 * math.pi * u
            return (x + r * v * math.cos(a), y + r * v * math.sin(a), G + .056 + i * .001)
        k.surface("matte", fn, 24, 4, lambda u, v: tuple(a + (b - a) * v ** .8 for a, b in zip(warm, ICE)))
    # the fence is low: two of its runs stand between the camera and the ice
    for a, b, out in (((-hs, -hs), (hs, -hs), (0, -1, 0)), ((hs, -hs), (hs, hs), (1, 0, 0)),
                      ((-hs, hs), (hs, hs), (0, 1, 0)), ((-hs, -hs), (-hs, hs), (-1, 0, 0))):
        rail_fence(k, a, b, G, .3, 4, out=out)
    for x, y in ((-hs, -hs), (hs, -hs), (hs, hs), (-hs, hs)):
        k.box("wood", x, y, G, .22, .22, .44, WOOD_L)
        k.ball("slab", x, y, G + .46, .13, SNOW, 10, sz=.4)
        lamp_post(k, x, y, G + .44, .42, .17, 1.6)
    # firs tucked outside the corners
    a = 1.31
    deco_fir(k, -a, a, G, 1.24, .19, tiers=3)
    deco_fir(k, a, -a, G, .82, .18)
    deco_fir(k, a, a, G, 1.02, .19)
    deco_fir(k, -a, -a, G, 1.02, .19)


def tree(k):
    """The Christmas tree: a huge decorated fir, star on top, parcels and a low fence."""
    hs = 1.28
    rail_fence(k, (-hs, -hs), (hs, -hs), G, .24, 5, .13, out=(0, -1, 0), bow_at=(.2, .5, .8), r=.07)
    rail_fence(k, (hs, -hs), (hs, hs), G, .24, 5, .13, out=(1, 0, 0), bow_at=(.2, .5, .8), r=.07)
    rail_fence(k, (-hs, hs), (hs, hs), G, .24, 5, .13, out=(0, 1, 0), bow_at=(), r=.07)
    rail_fence(k, (-hs, -hs), (-hs, hs), G, .24, 5, .13, out=(-1, 0, 0), bow_at=(), r=.07)
    for x_, y_ in ((hs, -hs), (-hs, hs)):
        k.box("wood", x_, y_, G, .19, .19, .31, WOOD_L)
        k.ball("slab", x_, y_, G + .33, .11, SNOW, 10, sz=.5)
    k.lathe("slab", 0, 0, G - .01, [(1.08, 0), (.9, .07), (.001, .08)], SNOW, 24)
    # the tree
    h = 3.1
    x, y, tiers = fir(k, 0, .08, G + .06, h, 1.06, 8, trunk=.07)
    trim_fir(k, x, y, tiers, 5, .08, 9, cols=(XRED, GOLD, XRED, C("#F8D34E")))
    k.lights.append(((.3, -1.2, G + 1.4), 6.))
    # ribbon bows on the lower tiers
    for (zb, zt, rb), a in zip(tiers[:3] + tiers[:2], (-90, -30, -70, -130, -5)):
        t = math.radians(a)
        with k.at(facing(x + rb * .84 * math.cos(t), y + rb * .84 * math.sin(t), zb + (zt - zb) * .15, t)):
            bow(k, 0, 0, 0, .12)
    # the star: a faceted five-pointed star turned to the camera
    zs = G + .06 + h + .24
    with k.at(facing(x, y, zs, math.radians(-60))):
        rim = []
        for i in range(10):
            t = math.pi / 2 + i * math.pi / 5
            d = .38 if i % 2 == 0 else .17
            rim.append((d * math.cos(t), 0, d * math.sin(t)))
        verts = rim + [(0, -.13, 0), (0, .13, 0)]
        faces = [(i, (i + 1) % 10, 10) for i in range(10)] + [((i + 1) % 10, i, 11) for i in range(10)]
        k.add("gold", verts, faces, C("#FFD23E"))
    k.lights.append(((x + .22, y - .5, zs + .12), 2.))
    k.box("gold", x, y, zs - .3, .07, .07, .16, GOLD)
    # parcels at its foot, on the camera sides
    for px, py, s, c, rb, rz in ((-.76, -1.0, .32, XRED, GOLD, .1), (-.36, -1.04, .26, XGREEN, XRED, -.2), (.04, -1.0, .36, XRED, CANDLE, .25),
                                  (.46, -1.02, .26, GOLD, XRED, -.1), (.84, -.94, .3, XGREEN, GOLD, .15), (1.02, -.5, .28, XRED, GOLD, .3),
                                  (1.04, -.06, .26, GOLD, XRED, -.2)):
        gift(k, px, py, G, s, c, rb, rz=rz)
    # two lanterns on posts, left and right
    for x_, y_ in ((-hs, -hs), (hs, hs)):
        k.box("wood", x_, y_, G, .24, .24, .34, WOOD_L)
        k.ball("slab", x_, y_, G + .36, .14, SNOW, 10, sz=.4)
        lamp_post(k, x_, y_, G + .34, .46, .17, 1.4)


def firs(k):
    """Lantern firs: a big fir, a small fir, an iron lamp with a wreath, a snowy rock."""
    x, y, t = fir(k, -.42, .1, G, 1.96, .56, 5)
    trim_fir(k, x, y, t, 2, .05, 7)
    x, y, t = fir(k, .52, .44, G, 1.38, .4, 4)
    trim_fir(k, x, y, t, 1, .045, 5)
    # the lamp
    px, py = .16, -.3
    lamp_post(k, px, py, G, 1.5, .25, 3.)
    wreath(k, px, py - .03, G + 1.02, .2)
    # a snowy rock and a drift
    k.ball("stone", -.36, -.56, G + .1, .22, STONE, 12, sx=1.15, sz=.82)
    k.ball("stone", -.08, -.68, G + .05, .13, STONE_L, 10, sz=.8)
    k.ball("slab", -.36, -.54, G + .24, .19, SNOW, 12, sx=1.1, sz=.42)


def bench(k):
    """Snowman bench: a garlanded park bench, a fir behind and the snowman at its end."""
    x, y, t = fir(k, -.46, .62, G, 1.3, .36, 3)
    trim_fir(k, x, y, t, 1, .04, 4)
    x, y, t = fir(k, .74, .66, G, .78, .22, 3)
    trim_fir(k, x, y, t, 1, .035, 2)
    # the bench, facing -Y
    bx0, bx1, by, zs = -.84, .2, -.12, G + .34
    bw = C("#B47436")
    for x in (bx0, bx1):
        rope(k, "matte", spline([(x, by - .24, G), (x, by - .2, zs - .02), (x, by + .14, zs - .02), (x, by + .26, G)], 3), .04, IRON, 8)
        rope(k, "matte", spline([(x, by - .24, zs + .2), (x, by - .12, zs + .28), (x, by + .08, zs + .24), (x, by + .28, zs + .56)], 3), .038, IRON, 8)
        k.beam("matte", (x, by - .2, zs), (x, by - .24, zs + .2), .04, .04, IRON)
        k.beam("matte", (x, by + .14, zs), (x, by + .24, zs + .46), .04, .04, IRON)
    for i in range(4):
        k.box("wood", (bx0 + bx1) / 2, by - .17 + i * .105, zs, bx1 - bx0 + .1, .09, .05, J(bw, .05))
    for i in range(3):
        t = i * .17
        k.box("wood", (bx0 + bx1) / 2, by + .15 + t * .34, zs + .1 + t * .96, bx1 - bx0 + .1, .05, .12, J(bw, .05))
    # a little snow on the seat
    k.ball("slab", bx0 + .26, by - .04, zs + .05, .18, SNOW, 12, sx=1.1, sy=.8, sz=.24)
    # garland over the bench back
    gy, gz = by + .32, zs + .58
    garland(k, swag((bx0 - .02, gy, gz), (bx1 + .02, gy, gz), .08), .085)
    for x in (bx0, bx1):
        bow(k, x, gy - .09, gz, .16)
    snowman(k, .6, -.02, G, .98)
    # a little lantern at its feet and a sprig of holly
    lantern(k, .74, -.62, G, .15, 1.4)
    k.ball("leaf", .36, -.62, G + .05, .09, FIR_L, 10)
    k.ball("glaze", .36, -.69, G + .1, .04, XRED, 8)
    k.ball("leaf", .25, -.58, G + .04, .08, FIR, 10)

# ------------------------------------------------------------------ the list
#
# The game indexes these by order.

ITEMS = [dict(zip(("key", "title", "w", "h"), row)) for row in (
    ("arch", "Welcome arch", 3, 3),
    ("lumber", "Lumber workshop", 3, 3),
    ("bakery", "Gingerbread bakery", 3, 3),
    ("cocoa", "Hot cocoa kiosk", 3, 3),
    ("toys", "Toymaker's workshop", 3, 3),
    ("gifts", "Gift wrapping pavilion", 3, 3),
    ("candles", "Candlelight shop", 3, 3),
    ("carousel", "Reindeer carousel", 3, 3),
    ("rink", "Winter skating rink", 3, 3),
    ("tree", "Christmas tree", 3, 3),
    ("firs", "Lantern firs", 2, 2),
    ("bench", "Snowman bench", 2, 2),
)]


KEYS = {it["key"] for it in ITEMS}


def model(it, i):
    """A wish's geometry, on its snowy base and clamped to its footprint."""
    R.seed(7 + i)
    k = Kit(it["w"], it["h"])
    snow_base(k)
    globals()[it["key"]](k)
    hw, hh = it["w"] / 2, it["h"] / 2
    for b in k.buckets.values():   # nothing may leave the footprint
        b["v"] = [(max(-hw, min(hw, v[0])), max(-hh, min(hh, v[1])), v[2]) for v in b["v"]]
    return k
