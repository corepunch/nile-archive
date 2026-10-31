# Christmas Market buildings and decorations as procedural Blender geometry.
#
# The master scene for games/christmas-market, made as docs/BUILDING_ART.md
# describes: every object is modelled on the game's grid, one collection each,
# named after its key, with its pivot at the footprint's ground centre.
# The first twelve rows follow the building direction sheet and are modelled in market_wishes.py
# (art/building-reference-sheet.png); the rest are extra shop objects.
#
# Convention: tools/building_kit.py and docs/BUILDINGS.md. 1 Blender unit = 1 tile side.
# World X = tile u (the front-left side, size.w). World Y = -v (the front-right side,
# size.h). The city camera comes from tools/city_camera.py.
#
#   make buildings GAME=christmas-market REBUILD=1
import json
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(globals().get("__file__", "."))) if "__file__" in globals() else "."
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "..", "tools"))
sys.path.insert(0, HERE)
import building_kit
import city_camera
import market_wishes
SCENE_NAME = "ChristmasMarketIso"
R = random.Random(12)
PREFIX = "cm_"


# ------------------------------------------------------------------ palette

def C(h):
    h = h.lstrip("#")
    def lin(v):
        v /= 255
        return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
    return tuple(lin(int(h[i:i + 2], 16)) for i in (0, 2, 4))

def J(col, j=.06):
    m = 1 + R.uniform(-j, j)
    return tuple(max(0, c * m * (1 + R.uniform(-j, j) * .25)) for c in col)

SNOW, SNOW_SH, SNOW_BLUE = C("#F4F8FC"), C("#DCE8F4"), C("#C6DAEE")
ICE, ICE_D = C("#BFE8F5"), C("#7FC4E0")
RINK_ICE = C("#7CC4E4")
WOOD, WOOD_L, WOOD_D = C("#7A4524"), C("#A2652F"), C("#4E2A14")
LOG = C("#8C5A30")
RED, RED_D, RED_L = C("#C42A2A"), C("#8E1C1E"), C("#E04A3C")
BARN = C("#A8382C")
GREEN, GREEN_D, GREEN_L = C("#1F6E3A"), C("#134A28"), C("#2F8C4A")
FIR = [C(h) for h in ("#1C5E3A", "#226B40", "#185234")]
GOLD, GOLD_D = C("#F0B83A"), C("#B5801C")
CREAM, PLASTER = C("#F2E3C2"), C("#EAD8B4")
STONE = [C(h) for h in ("#9EA4AE", "#B0B5BD", "#8E949E")]
STONE_L, STONE_D, SLATE = C("#C9CDD3"), C("#6C727C"), C("#4E5866")
COBBLE = C("#8B8F98")
TEAL, BLUE, BLUE_D = C("#2E8C88"), C("#3C6CB4"), C("#284A86")
GINGER, GINGER_D = C("#B8702E"), C("#8A4E1E")
PINK, MINT, LILAC = C("#F08AB0"), C("#7FD8B0"), C("#B08AE0")
GLOW, GLOW_L = C("#FFB04A"), C("#FFD27A")
DARK, IRON = C("#2A1A12"), C("#2C3036")
SKIN, CARROT, COAL = C("#F2C9A0"), C("#F07A1E"), C("#1E1E22")
HAY = C("#E2B54A")
BULBS = [C(h) for h in ("#FF4A3A", "#FFC83A", "#4AD86A", "#4AA8FF", "#FF7AD0")]
PRESENT = [C(h) for h in ("#D2302C", "#2C8A4C", "#2E62C0", "#E8B030", "#9A4AC8", "#F2F2F2")]
RIBBON = [C(h) for h in ("#F4C64A", "#F4F4F4", "#D2302C")]

def stone():
    return J(R.choice(STONE), .03)


# ------------------------------------------------------------------ materials

# Bevels give the soft toy edges; snow gets the widest.
BEVELS = {"stone": (.035, 2), "wood": (.025, 2), "paint": (.025, 2), "roof": (.03, 2),
          "snow": (.06, 3), "gold": (.015, 2), "cloth": (.02, 2), "candy": (.02, 2), "ice": (.03, 2)}

def make_material(name, rough=.7, metal=0., spec=.4, emit=0., bump=0., scale=20., sss=0., coat=0.):
    m = bpy.data.materials.new(PREFIX + name)
    m.use_nodes = True
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    a = nt.nodes.new("ShaderNodeAttribute")
    a.attribute_name = "col"
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    p.inputs["Specular IOR Level"].default_value = spec
    if coat:
        p.inputs["Coat Weight"].default_value = coat
    if sss:
        p.inputs["Subsurface Weight"].default_value = sss
        p.inputs["Subsurface Radius"].default_value = (.06, .08, .12)
        p.inputs["Subsurface Scale"].default_value = .4
    nt.links.new(a.outputs["Color"], p.inputs["Base Color"])
    if bump:
        tc = nt.nodes.new("ShaderNodeTexCoord")
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = scale
        noise.inputs["Detail"].default_value = 4
        nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
        b = nt.nodes.new("ShaderNodeBump")
        b.inputs["Strength"].default_value = bump
        b.inputs["Distance"].default_value = .02
        nt.links.new(noise.outputs["Fac"], b.inputs["Height"])
        nt.links.new(b.outputs["Normal"], p.inputs["Normal"])
    if emit:
        nt.links.new(a.outputs["Color"], p.inputs["Emission Color"])
        p.inputs["Emission Strength"].default_value = emit
    return m

def make_materials():
    return {
        "stone": make_material("stone", rough=.85, bump=.25, scale=14),
        "wood": make_material("wood", rough=.7, bump=.15, scale=30),
        "paint": make_material("paint", rough=.55),
        "roof": make_material("roof", rough=.7),
        "snow": make_material("snow", rough=.6, spec=.3, sss=.25, bump=.12, scale=9),
        "ice": make_material("ice", rough=.12, spec=.8, coat=.6),
        "gold": make_material("gold", rough=.3, metal=.75, spec=.6),
        "iron": make_material("iron", rough=.45, metal=.6),
        "cloth": make_material("cloth", rough=.9),
        "candy": make_material("candy", rough=.25, spec=.6, coat=.5),
        "glossy": make_material("glossy", rough=.15, spec=.7, coat=.8),
        "leaf": make_material("leaf", rough=.75, spec=.25, bump=.3, scale=40),
        "matte": make_material("matte", rough=.8),
        "glow": make_material("glow", rough=.5, emit=2.2),
        "bulb": make_material("bulb", rough=.3, emit=6.0),
        "slab": make_material("slab", rough=.9, bump=.3, scale=6),
    }


# ------------------------------------------------------------------ mesh kit
# Adapted from Relic Rush's kit: geometry collected by material, in
# pivot-local coordinates, with a transform stack for wall frames.

class Kit:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.buckets = {}
        self.lights = []
        self.xf = Matrix.Identity(4)

    class _At:
        def __init__(self, kit, m):
            self.kit, self.m = kit, m
        def __enter__(self):
            self.prev = self.kit.xf
            self.kit.xf = self.prev @ self.m
        def __exit__(self, *a):
            self.kit.xf = self.prev

    def at(self, m):
        return Kit._At(self, m)

    def add(self, mat, verts, faces, col, smooth=False, m=None):
        b = self.buckets.setdefault(mat, {"v": [], "f": [], "c": [], "s": []})
        base = len(b["v"])
        t = self.xf @ m if m is not None else self.xf
        cols = col if isinstance(col, list) else [col] * len(verts)
        for v, c in zip(verts, cols):
            b["v"].append(tuple(t @ Vector(v)))
            b["c"].append(c)
        for f in faces:
            b["f"].append(tuple(i + base for i in f))
            b["s"].append(smooth)

    def light(self, p, watts, colour=(1, .62, .28)):
        self.lights.append((tuple(self.xf @ Vector(p)), watts, colour))

    # ---- primitives

    def box(self, mat, x, y, z, sx, sy, sz, col, rz=0.):
        hx, hy = sx / 2, sy / 2
        v = [(-hx, -hy, 0), (hx, -hy, 0), (hx, hy, 0), (-hx, hy, 0),
             (-hx, -hy, sz), (hx, -hy, sz), (hx, hy, sz), (-hx, hy, sz)]
        f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.add(mat, v, f, col, m=Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z"))

    def beam(self, mat, a, b, w, d, col):
        a, b = Vector(a), Vector(b)
        x = (b - a).normalized()
        up = Vector((0, 0, 1)) if abs(x.z) < .95 else Vector((0, 1, 0))
        y = up.cross(x).normalized()
        z = x.cross(y)
        l = (b - a).length
        hw, hd = w / 2, d / 2
        pts = []
        for s in (0, l):
            for dy, dz in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd)):
                pts.append(tuple(a + x * s + y * dy + z * dz))
        f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.add(mat, pts, f, col)

    def tube(self, mat, a, b, r0, r1, col, n=10, smooth=True):
        a, b = Vector(a), Vector(b)
        x = (b - a).normalized()
        up = Vector((0, 0, 1)) if abs(x.z) < .95 else Vector((0, 1, 0))
        y = up.cross(x).normalized()
        z = x.cross(y)
        pts = []
        for c, r in ((a, r0), (b, r1)):
            for i in range(n):
                t = 2 * math.pi * i / n
                pts.append(tuple(c + (y * math.cos(t) + z * math.sin(t)) * r))
        f = [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        f += [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        self.add(mat, pts, f, col, smooth)

    def path(self, mat, pts, r, col, n=8):
        for i, (a, b) in enumerate(zip(pts, pts[1:])):
            self.tube(mat, a, b, r, r, col(i) if callable(col) else col, n)
            if 0 < i:
                self.ball(mat, a[0], a[1], a[2], r, col(i) if callable(col) else col, n)

    def lathe(self, mat, x, y, z, prof, col, n=18, smooth=True, sx=1., sy=1., m=None):
        pts, cols = [], []
        for r, h in prof:
            for i in range(n):
                t = 2 * math.pi * i / n
                pts.append((r * math.cos(t) * sx, r * math.sin(t) * sy, h))
                cols.append(col(h, t) if callable(col) else col)
        f = []
        for j in range(len(prof) - 1):
            for i in range(n):
                f.append((j * n + i, j * n + (i + 1) % n, (j + 1) * n + (i + 1) % n, (j + 1) * n + i))
        f += [tuple(reversed(range(n))), tuple(range((len(prof) - 1) * n, len(prof) * n))]
        t = Matrix.Translation((x, y, z))
        self.add(mat, pts, f, cols, smooth, m=t @ m if m else t)

    def ball(self, mat, x, y, z, r, col, n=12, sx=1., sy=1., sz=1., m=None):
        """Centred on (x, y, z)."""
        prof = [(max(r * math.sin(math.pi * i / 7), .001), r * sz * (1 - math.cos(math.pi * i / 7))) for i in range(8)]
        self.lathe(mat, x, y, z - r * sz, prof, col, n, True, sx, sy, m)

    def disc(self, mat, x, y, z, r, h, col, n=18):
        self.lathe(mat, x, y, z, [(r, 0), (r, h)], col, n)

    def surface(self, mat, fn, nu, nv, col, smooth=True):
        pts, cols = [], []
        for j in range(nv + 1):
            for i in range(nu + 1):
                u, v = i / nu, j / nv
                pts.append(fn(u, v))
                cols.append(col(u, v) if callable(col) else col)
        f = []
        for j in range(nv):
            for i in range(nu):
                a = j * (nu + 1) + i
                f.append((a, a + 1, a + nu + 2, a + nu + 1))
        self.add(mat, pts, f, cols, smooth)

    def poly(self, mat, pts, col, smooth=False):
        self.add(mat, pts, [tuple(range(len(pts)))], col, smooth)

    def prism(self, mat, pts, x0, x1, col):
        """Extrudes a polygon in (y, z) along x."""
        n = len(pts)
        v = [(x0, y, z) for y, z in pts] + [(x1, y, z) for y, z in pts]
        f = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        f += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.add(mat, v, f, col)

    def prism_y(self, mat, pts, y0, y1, col):
        """Extrudes a polygon in (x, z) along y."""
        n = len(pts)
        v = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
        f = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        f += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.add(mat, v, f, col)

    def slab(self, mat, a, b, c, d, t, col):
        """A quad a-b-c-d thickened by t along its upward normal."""
        a, b, c, d = map(Vector, (a, b, c, d))
        nrm = (b - a).cross(d - a).normalized()
        if nrm.z < 0:
            nrm = -nrm
        q = [a, b, c, d]
        v = [tuple(p) for p in q] + [tuple(p + nrm * t) for p in q]
        f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.add(mat, v, f, col)
        return nrm

    def torus(self, mat, frame, R_, r, col, nu=20, nv=8):
        """A ring in a frame's XZ plane (a wreath on a wall frame faces -y)."""
        def fn(u, v):
            a, b = 2 * math.pi * u, 2 * math.pi * v
            p = Vector(((R_ + r * math.cos(b)) * math.cos(a), r * math.sin(b), (R_ + r * math.cos(b)) * math.sin(a)))
            return tuple(frame @ p)
        self.surface(mat, fn, nu, nv, col)

    def star(self, mat, x, y, z, r, t, col, points=5, rz=math.radians(45)):
        """An upright five-point star; rz = 45 degrees faces the camera, 0 a wall frame's outside."""
        pts = []
        for i in range(points * 2):
            a = math.pi / 2 + math.pi * i / points
            d = r if i % 2 == 0 else r * .45
            pts.append((d * math.cos(a), d * math.sin(a)))
        with self.at(Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z")):
            self.prism_y(mat, pts, -t / 2, t / 2, col)

    # ---- masonry

    def wall(self, a, b, z0, z1, t=.2, course=.22, length=.42, col=None, mat="stone"):
        """Running-bond blocks from a to b."""
        a, b = Vector(a), Vector(b)
        L = (b - a).length
        ang = math.atan2(b.y - a.y, b.x - a.x)
        n = max(1, round((z1 - z0) / course))
        ch = (z1 - z0) / n
        for i in range(n):
            s = -(length * .5 if i % 2 else 0)
            while s < L - .01:
                l = length * R.uniform(.88, 1.12)
                s0, s1 = max(s, 0), min(s + l, L)
                if L - s1 < length * .3:
                    s1 = L
                s = s1 if s1 >= L else s + l
                mid = a + (b - a) * ((s0 + s1) * .5 / L)
                self.box(mat, mid.x, mid.y, z0 + i * ch, s1 - s0, t, ch, col() if callable(col) else stone(), ang)

    # ---- snow

    def snow_cap(self, x, y, z, sx, sy, t=.08, droop=True):
        """A soft snow pillow on a flat top, sagging a little over the edge."""
        self.box("snow", x, y, z, sx, sy, t, J(SNOW, .01))
        if droop:
            for _ in range(int((sx + sy) * 3)):
                if R.random() < .5:
                    px, py = x + R.uniform(-sx / 2, sx / 2), y - sy / 2 * R.choice((-1, 1))
                else:
                    px, py = x + sx / 2 * R.choice((-1, 1)), y + R.uniform(-sy / 2, sy / 2)
                self.ball("snow", px, py, z + t * .3, R.uniform(.035, .06), SNOW, 8, sz=.8)

    def icicles(self, a, b, n, length=.14):
        a, b = Vector(a), Vector(b)
        for i in range(n):
            p = a.lerp(b, (i + R.uniform(.2, .8)) / n)
            L = length * R.uniform(.5, 1.1)
            self.lathe("ice", p.x, p.y, p.z - L, [(.001, 0), (.022, L * .8), (.026, L)], ICE, 6)

    def lights_along(self, a, b, n, z_sag=.06, r=.03, wire=True, phase=0):
        """A string of coloured bulbs between a and b, sagging between its ends."""
        a, b = Vector(a), Vector(b)
        pts = []
        for i in range(n + 1):
            t = i / n
            p = a.lerp(b, t) - Vector((0, 0, z_sag * 4 * t * (1 - t)))
            pts.append(p)
        if wire:
            for p, q in zip(pts, pts[1:]):
                self.tube("iron", tuple(p), tuple(q), .007, .007, IRON, 5)
        for i, p in enumerate(pts[1:-1]):
            self.ball("bulb", p.x, p.y, p.z - r * .6, r, BULBS[(i + phase) % len(BULBS)], 8, sz=1.25)

    # ---- details

    def window(self, s, z0, w, h, frame=None, glow=GLOW, cross=True, sill=True, shutters=None):
        """A lit window on a wall frame (x along the wall, -y out)."""
        frame = frame or CREAM
        self.box("glow", s, -.02, z0, w, .04, h, glow)
        self.box("paint", s, -.05, z0 - .05, w + .1, .05, .05, frame)
        self.box("paint", s, -.05, z0 + h, w + .1, .05, .06, frame)
        for side in (-1, 1):
            self.box("paint", s + side * (w / 2 + .025), -.05, z0, .05, .05, h, frame)
            if shutters:
                self.box("paint", s + side * (w / 2 + .12), -.04, z0, .14, .04, h, shutters)
        if cross:
            self.box("paint", s, -.05, z0, .03, .03, h, frame)
            self.box("paint", s, -.05, z0 + h / 2, w, .03, .03, frame)
        if sill:
            self.box("paint", s, -.09, z0 - .07, w + .18, .1, .04, frame)
            self.box("snow", s, -.09, z0 - .03, w + .14, .09, .04, SNOW)

    def door(self, s, z0, w, h, col=WOOD_D, frame=None, wreath=True, arch=False):
        frame = frame or CREAM
        self.box("wood", s, -.03, z0, w, .05, h, col)
        for side in (-1, 1):
            self.box("paint", s + side * (w / 2 + .03), -.05, z0, .06, .06, h + .06, frame)
        self.box("paint", s, -.05, z0 + h, w + .12, .06, .06, frame)
        self.ball("gold", s + w * .3, -.07, z0 + h * .45, .025, GOLD, 8)
        if wreath:
            self.wreath(s, -.08, z0 + h * .7, min(w * .32, .15))

    def wreath(self, x, y, z, r):
        """A wreath hung on a wall frame's outside (-y)."""
        for i in range(12):
            a = 2 * math.pi * i / 12
            self.ball("leaf", x + r * math.cos(a), y, z + r * math.sin(a), r * .42, J(GREEN_L, .1), 8)
        for i in range(4):
            a = 2 * math.pi * (i + .5) / 4
            self.ball("glossy", x + r * math.cos(a), y - r * .3, z + r * math.sin(a), r * .16, RED, 8)
        self.ball("cloth", x, y - r * .35, z - r, r * .3, RED, 8, sx=1.6, sz=.8)

    def present(self, x, y, z, s, h, col, rib, rz=0.):
        self.box("paint", x, y, z, s, s, h, col, rz)
        self.box("cloth", x, y, z - .002, s + .012, s * .18, h + .014, rib, rz)
        self.box("cloth", x, y, z - .002, s * .18, s + .012, h + .014, rib, rz)
        for a in (rz + .6, rz + .6 + math.pi):
            self.ball("cloth", x + math.cos(a) * s * .14, y + math.sin(a) * s * .14, z + h + s * .08, s * .12, rib, 8, sx=1.5, sz=.8)

    def fir(self, x, y, z, h, r, tiers=4, snow=1., deco=0, star=False, lights=False, palette=None):
        """A layered fir: dark tiers under soft snow, optionally dressed."""
        self.tube("wood", (x, y, z), (x, y, z + h * .2), r * .12, r * .1, WOOD, 8)
        col = J(R.choice(FIR), .05)
        z0 = z + h * .12
        th = (h - h * .12) / tiers * 1.9
        tops = []
        for i in range(tiers):
            f = 1 - i / tiers
            ri = r * (.35 + .65 * f)
            zi = z0 + i * (h - h * .12 - th) / max(tiers - 1, 1)
            tops.append((ri, zi, th))
            ph = R.uniform(0, 6.28)
            prof = [(ri * .55, 0), (ri, th * .08), (ri * .96, th * .16), (.001, th)]
            self.lathe("leaf", x, y, zi, prof, lambda hh, t, col=col: tuple(c * (.7 + .5 * hh / th) for c in col), 20)
            if snow:
                def fn(u, v, ri=ri, zi=zi, ph=ph):
                    a = 2 * math.pi * u
                    edge = 1 - .7 * snow + .09 * math.sin(4 * a + ph) + .05 * math.sin(9 * a + 2 * ph)
                    t = edge + (1 - edge) * v ** .8
                    t = min(t, .985)
                    rr = ri * .96 * (1 - t) / (1 - .16) + .022
                    return (x + rr * math.cos(a), y + rr * math.sin(a), zi + th * .16 + (th * .84) * (t - .16) / .84 + .012)
                self.surface("snow", fn, 24, 3, J(SNOW, .01))
        if deco:
            for i in range(deco):
                ri, zi, th_ = tops[R.randrange(tiers)]
                t = R.uniform(.12, .5)
                a = R.uniform(math.radians(-150), math.radians(60))
                rr = ri * (1 - t) * .98 + .02
                self.ball("glossy", x + rr * math.cos(a), y + rr * math.sin(a), zi + th_ * t, r * .07 + .015,
                          R.choice(palette or PRESENT[:5]), 10)
        if lights:
            n = int(h * 18)
            for i in range(n):
                t = i / n
                zz = z0 + (h * .85) * t
                a = t * 2 * math.pi * 3.2
                rr = r * (1 - t * .92) * .92 + .03
                self.ball("bulb", x + rr * math.cos(a), y + rr * math.sin(a), zz, .022 + r * .01, BULBS[i % 4 if i % 4 != 2 else 1], 6)
        if star:
            self.star("gold", x, y, z + h + r * .12, r * .22 + .04, .05, GOLD)
            self.light((x - .2, y - .2, z + h), .6, (1, .82, .4))
        return tops


def wall_frame(a, b):
    """x along a->b, z up; walking counter-clockwise, -y points out of the building."""
    a, b = Vector(a), Vector(b)
    ang = math.atan2(b.y - a.y, b.x - a.x)
    return Matrix.Translation((a.x, a.y, 0)) @ Matrix.Rotation(ang, 4, "Z")

G = .1   # top of the base slab

def left_face(x0, x1, y0):
    """The -Y wall, seen on the left: x runs from x0 to x1."""
    return wall_frame((x0, y0), (x1, y0))

def right_face(y0, y1, x1):
    """The +X wall, seen on the right: x runs from y0 to y1."""
    return wall_frame((x1, y0), (x1, y1))


# ------------------------------------------------------------------ building parts

def gable(k, x0, x1, y0, y1, z, h, roof, wall, ridge="x", over=.12, rake=CREAM, lights=False, drip=True, snow=True,
          wall_mat="paint"):
    """A pitched roof under a thick blanket of snow, with its attic gables.
    ridge "x" runs the ridge along X (the slopes face -Y and +Y); "y" along Y."""
    if ridge == "x":
        s0, s1, t0, t1 = x0, x1, y0, y1
        P = lambda s, t, zz: (s, t, zz)
    else:
        s0, s1, t0, t1 = y0, y1, x0, x1
        P = lambda s, t, zz: (t, s, zz)
    tm = (t0 + t1) / 2
    run = tm - t0
    dz = over * h / run
    # attic: one closed prism of the wall colour
    v = [P(s0, t0, z), P(s0, t1, z), P(s0, tm, z + h), P(s1, t0, z), P(s1, t1, z), P(s1, tm, z + h)]
    k.add(wall_mat, v, [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], wall)
    lo = z - dz
    for side in (-1, 1):
        te = tm + side * (run + over)
        a, b = P(s0 - over, te, lo), P(s1 + over, te, lo)
        c, d = P(s1 + over, tm, z + h), P(s0 - over, tm, z + h)
        nrm = k.slab("roof", a, b, c, d, .07, roof() if callable(roof) else roof)
        if snow:
            A, B, Cc, D = (Vector(p) for p in (a, b, c, d))
            pull = .16
            sa, sb = A.lerp(D, pull) + nrm * .07, B.lerp(Cc, pull) + nrm * .07
            sc, sd = Cc + nrm * .07, D + nrm * .07
            sa, sb = sa + (sb - sa).normalized() * .03, sb - (sb - sa).normalized() * .03
            k.slab("snow", tuple(sa), tuple(sb), tuple(sc), tuple(sd), .1, J(SNOW, .01))
            if drip:
                n = int((s1 - s0 + 2 * over) * 5)
                for i in range(n + 1):
                    p = sa.lerp(sb, i / n)
                    k.ball("snow", p.x, p.y, p.z + .02, R.uniform(.05, .075), SNOW, 8, sz=.75)
                k.icicles(A + Vector((0, 0, -.01)), B + Vector((0, 0, -.01)), int((s1 - s0) * 3.5))
            if lights:
                k.lights_along(tuple(A + Vector((0, 0, -.04))), tuple(B + Vector((0, 0, -.04))), int((s1 - s0) * 6), .05)
    # rake trims on both gables
    for s in (s0 - over - .01, s1 + over + .01):
        for side in (-1, 1):
            k.beam("paint", P(s, tm + side * (run + over), lo + .02), P(s, tm, z + h + .03), .09, .06, rake)
    if snow:
        k.tube("snow", P(s0 - over, tm, z + h + .14), P(s1 + over, tm, z + h + .14), .09, .09, SNOW, 10)


def chimney(k, x, y, z0, z1, s=.24):
    k.box("stone", x, y, z0, s, s, z1 - z0, stone())
    k.box("stone", x, y, z1, s + .07, s + .07, .07, STONE_L)
    k.snow_cap(x, y, z1 + .07, s + .05, s + .05, .07, False)


def trims(k, x0, x1, y0, y1, z0, z1, col=CREAM, t=.07):
    for x, y in ((x0, y0), (x1, y0), (x1, y1)):
        k.box("paint", x, y, z0, t, t, z1 - z0, col)


def slab_snow(k, w, h, n=None):
    """Drifts on the base slab's corners and edges."""
    n = n or int((w + h) * 2)
    for _ in range(n):
        if R.random() < .5:
            x, y = R.uniform(-w / 2 + .12, w / 2 - .12), (h / 2 - .1) * R.choice((-1, 1))
        else:
            x, y = (w / 2 - .1) * R.choice((-1, 1)), R.uniform(-h / 2 + .12, h / 2 - .12)
        k.ball("snow", x, y, G, R.uniform(.06, .11), SNOW, 10, sz=.45)


def lamp(k, x, y, z=0., h=1.0, wreath=False):
    k.disc("iron", x, y, z, .07, .06, IRON, 12)
    k.tube("iron", (x, y, z), (x, y, z + h), .028, .022, IRON, 8)
    k.box("iron", x, y, z + h, .15, .15, .03, IRON)
    k.box("glow", x, y, z + h + .03, .1, .1, .14, GLOW_L)
    for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        k.tube("iron", (x + dx * .055, y + dy * .055, z + h + .03), (x + dx * .055, y + dy * .055, z + h + .17), .008, .008, IRON, 4)
    k.lathe("iron", x, y, z + h + .17, [(.11, 0), (.001, .08)], IRON, 4, m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.ball("snow", x, y, z + h + .21, .05, SNOW, 8, sz=.6)
    k.light((x - .12, y - .12, z + h + .1), .9)
    if wreath:
        with k.at(Matrix.Translation((x, y, 0)) @ Matrix.Rotation(math.radians(45), 4, "Z")):
            k.wreath(0, -.05, z + h * .62, .08)


def candy_cane(k, x, y, z, h, r=.035, rz=math.radians(45)):
    pts = [(0, 0, 0), (0, 0, h * .8)]
    for i in range(1, 7):
        a = math.pi * i / 6
        pts.append((-.11 * (1 - math.cos(a)), 0, h * .8 + .11 * math.sin(a)))
    rot = Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z")
    fine = []
    for p, q in zip(pts, pts[1:]):
        p, q = Vector(p), Vector(q)
        m = max(1, int((q - p).length / .05))
        for j in range(m):
            fine.append(tuple(rot @ p.lerp(q, j / m)))
    fine.append(tuple(rot @ Vector(pts[-1])))
    k.path("candy", fine, r, lambda i: RED if (i // 1) % 2 else SNOW, 10)


# ------------------------------------------------------------------ buildings
# Casual style: big soft shapes under thick snow, warm windows, a few strong colours.

def santa_workshop(k):
    x0, x1, y0, y1 = -1.15, 1.05, -1.05, 1.15
    z1 = G + 1.55
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, z1 - G, RED)
    k.box("stone", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0 + .06, y1 - y0 + .06, .22, STONE_D)
    trims(k, x0, x1, y0, y1, G + .22, z1, CREAM, .1)
    for (a, b) in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1))):
        with k.at(wall_frame(a, b)):
            k.box("paint", (Vector(b) - Vector(a)).length / 2, -.03, G + .8, (Vector(b) - Vector(a)).length, .06, .08, CREAM)
    with k.at(left_face(x0, x1, y0)):
        for s in (.45, 1.1, 1.75):
            k.window(s, G + .35, .3, .34, shutters=GREEN_D)
            k.window(s, G + 1.0, .28, .3, shutters=GREEN_D)
    with k.at(right_face(y0, y1, x1)):
        k.door(1.1, G + .22, .66, .62, col=GREEN_D, wreath=False)
        k.box("glow", 1.1, -.02, G + .22, .5, .03, .5, GLOW)
        k.wreath(1.1, -.09, G + 1.02, .16)
        k.window(.4, G + 1.0, .26, .3, shutters=GREEN_D)
        k.window(1.8, G + 1.0, .26, .3, shutters=GREEN_D)
        k.box("wood", 1.1, -.08, G + 1.36, .8, .05, .2, WOOD)          # the sign
        k.star("gold", 1.1, -.12, G + 1.46, .08, .03, GOLD, rz=0)
    gable(k, x0, x1, y0, y1, z1, 1.05, GREEN_D, RED, ridge="y", over=.16, lights=True)
    chimney(k, -.55, .6, z1 + .4, z1 + 1.15, .3)
    for (x, y, s, h) in ((1.33, -.2, .22, .18), (1.36, .3, .18, .24), (1.3, 1.0, .2, .16)):
        k.present(x, y, G, s, h, R.choice(PRESENT[:5]), R.choice(RIBBON[:2]), R.uniform(-.3, .3))
    candy_cane(k, 1.36, -.55, G, .5)
    candy_cane(k, 1.36, .62, G, .5)
    k.fir(-1.3, -1.32, G, .9, .28, tiers=3)
    slab_snow(k, 3, 3)


def gingerbread_house(k):
    x0, x1, y0, y1 = -.62, .62, -.6, .62
    z1 = G + .8
    k.box("paint", 0, .01, G, x1 - x0, y1 - y0, z1 - G, GINGER)
    icing = SNOW
    for a, b in (((x0, y0, G + .04), (x1, y0, G + .04)), ((x1, y0, G + .04), (x1, y1, G + .04)),
                 ((x0, y0, z1), (x1, y0, z1)), ((x1, y0, z1), (x1, y1, z1)),
                 ((x0, y0, G), (x0, y0, z1)), ((x1, y0, G), (x1, y0, z1)), ((x1, y1, G), (x1, y1, z1))):
        k.tube("candy", a, b, .035, .035, icing, 8)
    for i in range(9):   # scalloped icing under the eaves
        t = (i + .5) / 9
        k.ball("candy", x0 + (x1 - x0) * t, y0 - .02, z1 - .06, .045, icing, 8)
        k.ball("candy", x1 + .02, y0 + (y1 - y0) * t, z1 - .06, .045, icing, 8)
    with k.at(left_face(x0, x1, y0)):
        for s in (.3, .94):
            k.window(s, G + .32, .22, .24, frame=PINK, sill=False)
            k.ball("candy", s, -.06, G + .62, .05, MINT, 8)
    with k.at(right_face(y0, y1, x1)):
        k.door(.62, G, .3, .44, col=GINGER_D, frame=SNOW, wreath=False)
        k.ball("candy", .62, -.07, G + .5, .07, RED, 10)
    gable(k, x0, x1, y0, y1, z1, .62, lambda: J(C("#7A3E1C"), .04), GINGER, ridge="x", over=.12, rake=SNOW)
    for i in range(7):   # gumdrops along the ridge
        x = x0 - .05 + (x1 - x0 + .1) * (i + .5) / 7
        k.ball("candy", x, (y0 + y1) / 2, z1 + .62 + .26, .07, [PINK, MINT, GOLD, RED, LILAC][i % 5], 10, sz=.9)
    for (x, y) in ((.84, -.25), (.84, .38)):
        candy_cane(k, x, y, G, .42, .03)
    for (x, y, c) in ((-.82, -.84, RED), (.84, -.84, MINT)):
        k.tube("paint", (x, y, G), (x, y, G + .5), .015, .015, SNOW, 6)
        with k.at(Matrix.Translation((x, y, G + .58)) @ Matrix.Rotation(math.radians(45), 4, "Z")):
            k.lathe("candy", 0, 0, 0, [(.001, -.03), (.12, -.03), (.12, .03), (.001, .03)], c, 18,
                    m=Matrix.Rotation(math.pi / 2, 4, "X"))
            k.lathe("candy", 0, -.035, 0, [(.001, -.003), (.06, -.003), (.06, .003), (.001, .003)], SNOW, 18,
                    m=Matrix.Rotation(math.pi / 2, 4, "X"))
    chimney(k, -.3, .35, z1 + .25, z1 + .78, .2)
    slab_snow(k, 2, 2)


def chapel(k):
    x0, x1, y0, y1 = -.75, .35, -.42, .52
    z1 = G + .9
    grey = lambda: J(R.choice(STONE), .03)
    k.box("stone", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0 - .1, y1 - y0 - .1, z1 - G, STONE_D)
    k.wall((x0, y0), (x1, y0), G, z1, t=.14, col=grey)
    with k.at(left_face(x0, x1, y0)):
        for s in (.3, .8):
            k.box("glow", s, -.08, G + .3, .16, .04, .36, C("#FFC870"))
            k.lathe("glow", s, -.08, G + .66, [(.08, 0), (.001, .08)], C("#FFC870"), 10, sy=.25)
            k.box("stone", s, -.1, G + .26, .26, .06, .05, STONE_L)
    gable(k, x0, x1, y0, y1, z1, .6, SLATE, STONE_L, ridge="x", over=.1, wall_mat="stone")
    # the tower at the front right
    tx, ty, ts = .62, .05, .5
    zt = G + 1.55
    k.box("stone", tx, ty, G, ts, ts, zt - G, STONE_D)
    for (a, b) in (((tx - ts / 2, ty - ts / 2), (tx + ts / 2, ty - ts / 2)), ((tx + ts / 2, ty - ts / 2), (tx + ts / 2, ty + ts / 2))):
        k.wall(a, b, G, zt, t=.08, course=.2, length=.25, col=grey)
    with k.at(right_face(ty - ts / 2, ty + ts / 2, tx + ts / 2)):
        k.door(ts / 2, G, .22, .4, col=WOOD_D, frame=STONE_L)
        k.lathe("glow", ts / 2, -.06, G + 1.0, [(.1, -.01), (.1, .01)], C("#FF8A6A"), 16, m=Matrix.Rotation(math.pi / 2, 4, "X"))
        k.box("glow", ts / 2, -.06, G + 1.25, .1, .02, .18, IRON)
    with k.at(left_face(tx - ts / 2, tx + ts / 2, ty - ts / 2)):
        k.box("glow", ts / 2, -.06, G + 1.18, .12, .02, .24, IRON)
    k.lathe("gold", tx + .03, ty - .03, zt - .02 + .02, [(.001, .05), (.07, .1), (.09, .2), (.1, .26), (.001, .26)], GOLD, 14)
    k.box("stone", tx, ty, zt, ts + .08, ts + .08, .08, STONE_L)
    k.snow_cap(tx, ty, zt + .08, ts + .06, ts + .06, .05, True)
    k.lathe("roof", tx, ty, zt + .1, [(ts / 2 * 1.38, 0), (.001, .95)], SLATE, 4, m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.lathe("snow", tx, ty, zt + .1, [(ts / 2 * 1.38 + .02, .02), (ts / 2 * 1.1, .2), (.001, .22)], SNOW, 4,
            m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.star("gold", tx, ty, zt + 1.15, .1, .03, GOLD)
    k.fir(-.72, -.78, G, .75, .22, tiers=3)
    lamp(k, .82, -.8, G, .8, wreath=True)
    slab_snow(k, 2, 2)


def post_office(k):
    x0, x1, y0, y1 = -.62, .55, -.6, .62
    z1 = G + .95
    k.box("paint", (x0 + x1) / 2, 0, G, x1 - x0, y1 - y0, z1 - G, BLUE)
    trims(k, x0, x1, y0, y1, G, z1, SNOW)
    k.box("paint", (x0 + x1) / 2, y0 - .01, G + .5, x1 - x0, .03, .05, SNOW)
    with k.at(left_face(x0, x1, y0)):
        k.window(.33, G + .58, .2, .24)
        k.window(.84, G + .58, .2, .24)
        k.window(.58, G + .14, .4, .26, cross=True, sill=False)
    with k.at(right_face(y0, y1, x1)):
        k.door(.62, G, .32, .5, col=RED_D)
        k.box("paint", .62, -.08, G + .62, .36, .04, .24, SNOW)       # an envelope sign
        k.poly("paint", [(.45, -.105, G + .86), (.79, -.105, G + .86), (.62, -.105, G + .72)], C("#D8DCE4"))
        k.lathe("candy", .62, -.11, G + .73, [(.04, -.005), (.04, .005)], RED, 12, m=Matrix.Rotation(math.pi / 2, 4, "X"))
    gable(k, x0, x1, y0, y1, z1, .64, RED_D, BLUE, ridge="y", over=.12, lights=True)
    # the big red mailbox
    mx, my = .82, -.62
    k.box("paint", mx, my, G, .08, .08, .3, IRON)
    k.box("candy", mx, my, G + .3, .26, .2, .22, RED)
    k.tube("candy", (mx - .13, my, G + .52), (mx + .13, my, G + .52), .1, .1, RED, 14)
    k.snow_cap(mx, my, G + .6, .24, .16, .04, False)
    k.box("gold", mx + .135, my, G + .42, .01, .12, .025, GOLD)
    for i in range(3):
        k.box("paint", .8 + i * .05, .2 + i * .1, G + i * .04, .2, .14, .04, [SNOW, CREAM, C("#F4E0E0")][i], R.uniform(-.4, .4))
    k.box("cloth", .82, .64, G, .3, .26, .26, C("#B89870"))
    k.ball("cloth", .82, .64, G + .28, .1, C("#B89870"), 10)
    slab_snow(k, 2, 2)


def reindeer_stable(k):
    x0, x1, y0, y1 = -1.3, .9, -.62, .7
    z1 = G + .95
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, z1 - G, BARN)
    trims(k, x0, x1, y0, y1, G, z1, SNOW)
    with k.at(left_face(x0, x1, y0)):
        for s in (.4, 1.1, 1.8):
            k.window(s, G + .45, .26, .22, frame=SNOW, cross=True, sill=False)
            k.box("paint", s, -.04, G + .1, .34, .04, .26, SNOW)   # stall half-doors
            k.beam("paint", (s - .16, -.06, G + .12), (s + .16, -.06, G + .34), .04, .03, SNOW)
    with k.at(right_face(y0, y1, x1)):
        L = y1 - y0
        k.box("wood", L / 2, -.03, G, .62, .05, .62, BARN)
        k.box("glow", L / 2, -.015, G, .5, .03, .56, GLOW)
        for side in (-1, 1):   # the open barn door leaves
            k.box("paint", L / 2 + side * .4, -.08, G, .3, .05, .62, BARN)
            k.beam("paint", (L / 2 + side * .27, -.11, G + .03), (L / 2 + side * .53, -.11, G + .59), .04, .03, SNOW)
            k.beam("paint", (L / 2 + side * .53, -.11, G + .03), (L / 2 + side * .27, -.11, G + .59), .04, .03, SNOW)
        k.box("paint", L / 2, -.04, G + .62, .7, .05, .06, SNOW)
        k.box("wood", L / 2, -.03, z1 + .12, .26, .04, .28, WOOD_D)   # hayloft
        k.box("paint", L / 2, -.05, z1 + .12, .32, .03, .04, SNOW)
        k.wreath(L / 2, -.06, z1 - .1, .1)
    gable(k, x0, x1, y0, y1, z1, .72, lambda: J(C("#6A4E3A"), .04), BARN, ridge="x", over=.12, rake=SNOW)
    k.box("wood", (x0 + x1) / 2 - .4, (y0 + y1) / 2, z1 + .72 + .18, .18, .18, .22, SNOW)   # cupola
    k.lathe("roof", (x0 + x1) / 2 - .4, (y0 + y1) / 2, z1 + 1.12, [(.17, 0), (.001, .16)], C("#6A4E3A"), 4,
            m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.snow_cap((x0 + x1) / 2 - .4, (y0 + y1) / 2, z1 + 1.1, .26, .26, .03, False)
    for (x, y, rz) in ((1.18, -.55, .3), (1.25, .5, -.2), (-1.3, -.85, 0)):   # hay bales
        k.box("cloth", x, y, G, .26, .4, .2, HAY, rz)
        k.snow_cap(x, y, G + .2, .24, .36, .03, False)
    lamp(k, 1.3, -.05, G, .75)
    slab_snow(k, 3, 2)


def log_cabin(k):
    x0, x1, y0, y1 = -.6, .6, -.6, .6
    z1 = G + .82
    k.box("wood", 0, 0, G, 1.1, 1.1, z1 - G, WOOD_D)
    for i in range(6):
        z = G + .07 + i * .135
        k.tube("wood", (x0 - .08, y0, z), (x1 + .08, y0, z), .068, .068, J(LOG, .07), 10)
        k.tube("wood", (x1, y0 - .08, z + .065), (x1, y1 + .08, z + .065), .068, .068, J(LOG, .07), 10)
    with k.at(left_face(x0, x1, y0 - .07)):
        k.window(.6, G + .32, .3, .28, frame=WOOD_D, shutters=RED_D)
    with k.at(right_face(y0, y1, x1 + .07)):
        k.door(.62, G, .32, .55, col=WOOD_D, frame=WOOD)
    gable(k, x0, x1, y0, y1, z1, .7, lambda: J(WOOD_D, .05), LOG, ridge="y", over=.14, rake=WOOD, wall_mat="wood",
          lights=True)
    chimney(k, -.6, .25, G, z1 + .95, .3)
    for i in range(3):   # firewood
        for j in range(3 - i):
            k.tube("wood", (.72, -.86 + j * .13 + i * .065, G + .06 + i * .11), (.98, -.86 + j * .13 + i * .065, G + .06 + i * .11),
                   .055, .055, J(LOG, .1), 10)
    k.snow_cap(.85, -.73, G + .38, .3, .3, .04, False)
    k.box("wood", .84, .72, G, .06, .06, .38, WOOD_D)
    k.box("wood", .84, .72, G + .38, .08, .5, .04, WOOD)   # a sled leaning by the door
    k.fir(-.8, -.82, G, .7, .2, tiers=3)
    slab_snow(k, 2, 2)


def old_carousel(k):
    rr = 1.3
    k.lathe("paint", 0, 0, G, [(rr, 0), (rr, .14), (rr - .05, .16)], lambda h, t: RED if h < .1 else GOLD, 40)
    k.disc("paint", 0, 0, G + .12, rr - .06, .05, CREAM, 40)
    k.lathe("gold", 0, 0, G + .16, [(.24, 0), (.2, .2), (.2, 1.18), (.26, 1.3)], GOLD, 18)
    k.lathe("glossy", 0, 0, G + .38, [(.205, 0), (.205, .8)], lambda h, t: RED if int(t / (math.pi / 6)) % 2 else SNOW, 24)
    n = 8
    for i in range(n):
        a = 2 * math.pi * i / n + math.pi / 8
        x, y = .92 * math.cos(a), .92 * math.sin(a)
        k.tube("gold", (x, y, G + .16), (x, y, G + 1.42), .022, .022, GOLD, 8)
        z = G + .5 + (.12 if i % 2 else 0)
        # a little horse facing along the ring
        f = Matrix.Translation((x, y, z)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")
        body = [SNOW, C("#E9C89A"), C("#8C5A3C"), SNOW][i % 4]
        with k.at(f):
            k.ball("glossy", 0, 0, 0, .1, body, 12, sx=2.0, sy=.9, sz=.95)
            k.tube("glossy", (.14, 0, .04), (.22, 0, .2), .055, .045, body, 10)
            k.ball("glossy", .26, 0, .22, .055, body, 10, sx=1.6)
            for dx in (-.12, .12):
                k.tube("glossy", (dx, 0, -.04), (dx + .03, 0, -.2), .025, .02, body, 6)
            k.box("cloth", 0, 0, .08, .12, .2, .04, [RED, BLUE, GREEN, PINK][i % 4])
            k.tube("cloth", (.18, 0, .25), (.12, 0, .12), .02, .02, GOLD_D, 6)
    # the striped canopy
    m = 16
    zr, top = G + 1.45, G + 2.1
    for i in range(m):
        a0, a1 = 2 * math.pi * i / m, 2 * math.pi * (i + 1) / m
        col = RED if i % 2 == 0 else SNOW
        k.add("cloth", [(rr * math.cos(a0), rr * math.sin(a0), zr), (rr * math.cos(a1), rr * math.sin(a1), zr), (0, 0, top)], [(0, 1, 2)], col)
        am = (a0 + a1) / 2
        k.ball("cloth", rr * .98 * math.cos(am), rr * .98 * math.sin(am), zr - .03, .1, col, 10, sz=.9)
    k.lathe("snow", 0, 0, zr + .25, [(rr * .62, 0), (rr * .5, .14), (.001, .64)], SNOW, 32)
    k.lathe("gold", 0, 0, zr - .06, [(rr + .02, 0), (rr + .02, .06)], GOLD, 40)
    for i in range(24):
        a = 2 * math.pi * i / 24
        k.ball("bulb", (rr + .03) * math.cos(a), (rr + .03) * math.sin(a), zr - .03, .03, BULBS[i % 4 if i % 4 != 2 else 3], 8)
    k.tube("gold", (0, 0, top - .05), (0, 0, top + .25), .025, .025, GOLD, 8)
    k.star("gold", 0, 0, top + .32, .1, .03, GOLD)
    k.light((-.3, -.3, G + 1.2), 1.5)


# ------------------------------------------------------------------ decorations

def snowman_at(k, x, y, z, h, rz=math.radians(45)):
    r0, r1, r2 = h * .26, h * .19, h * .14
    z0 = z + r0 * .9
    z1 = z0 + r0 * .8 + r1 * .8
    z2 = z1 + r1 * .8 + r2 * .85
    for zz, r in ((z0, r0), (z1, r1), (z2, r2)):
        k.ball("snow", x, y, zz, r, SNOW, 16)
    with k.at(Matrix.Translation((x, y, 0)) @ Matrix.Rotation(rz, 4, "Z")):
        k.lathe("matte", 0, -r2 * .95, z2, [(r2 * .22, 0), (.001, r2 * .9)], CARROT, 10, m=Matrix.Rotation(math.pi / 2, 4, "X"))
        for dx in (-.4, .4):
            k.ball("matte", r2 * dx, -r2 * .88, z2 + r2 * .35, r2 * .1, COAL, 6)
        for t in (-.5, 0, .5):
            k.ball("matte", 0, -r1 * .97, z1 + r1 * t * .8, r1 * .09, COAL, 6)
        k.torus("cloth", Matrix.Translation((0, 0, z1 + r1 * .72)) @ Matrix.Rotation(math.pi / 2, 4, "X"), r1 * .62, r1 * .16, RED)
        k.box("cloth", r1 * .35, -r1 * .7, z1 + r1 * .05, r1 * .3, r1 * .12, r1 * .65, RED)
        k.disc("matte", 0, 0, z2 + r2 * .7, r2 * 1.1, r2 * .1, COAL, 16)
        k.disc("matte", 0, 0, z2 + r2 * .7, r2 * .72, r2 * .95, COAL, 16)
        k.disc("cloth", 0, 0, z2 + r2 * .82, r2 * .74, r2 * .18, RED, 16)
        for side in (-1, 1):
            k.tube("wood", (side * r1 * .8, 0, z1 + r1 * .2), (side * r1 * 2.0, 0, z1 + r1 * .9), .014, .01, WOOD_D, 5)


def fir_snowy(k): k.fir(0, 0, 0, 1.3, .38, tiers=4)
def fir_decorated(k): k.fir(0, 0, 0, 1.35, .4, tiers=4, deco=16, star=True, lights=True)

def pine_grove(k):
    for (x, y, h, r) in ((-.42, .4, 1.7, .45), (.45, -.4, 1.25, .36), (.5, .5, 1.05, .32), (-.45, -.48, .9, .28)):
        k.fir(x, y, 0, h, r, tiers=4)
    k.ball("snow", 0, 0, 0, .3, SNOW, 12, sz=.4)

def birch(k):
    trunk = C("#EEEAE2")
    k.tube("wood", (0, 0, 0), (.02, -.01, 1.2), .07, .04, trunk, 10)
    for i in range(7):   # bark marks
        z = .1 + i * .15
        a = R.uniform(-2.4, .6)
        k.box("matte", .07 * math.cos(a), .07 * math.sin(a), z, .05, .05, .025, COAL, a)
    for i in range(14):
        z = .4 + i * .06
        a = 2.4 * i + R.uniform(-.3, .3)
        L = .4 * (1 - i / 18)
        p = Vector((0, 0, z))
        q = p + Vector((math.cos(a) * L, math.sin(a) * L, L * .55))
        k.tube("wood", tuple(p), tuple(q), .022, .008, C("#6E5A4A"), 6)
        k.tube("snow", tuple(p + Vector((0, 0, .02))), tuple(q.lerp(p, .3) + Vector((0, 0, .02))), .02, .01, SNOW, 6)
    k.ball("snow", 0, 0, 0, .18, SNOW, 12, sz=.4)

def snowman(k): snowman_at(k, 0, 0, 0, 1.0)

def presents(k):
    for (x, y, s, h, rz) in ((-.15, .15, .34, .3, .2), (.2, -.12, .28, .22, -.3), (-.22, -.25, .22, .18, .5),
                             (.22, .28, .2, .26, 0)):
        k.present(x, y, 0, s, h, R.choice(PRESENT), R.choice(RIBBON), rz)
    k.present(-.12, .12, .3, .2, .16, PRESENT[2], RIBBON[0], .7)

def candy_canes(k):
    k.ball("snow", 0, 0, 0, .3, SNOW, 14, sz=.35)
    candy_cane(k, -.1, .1, 0, .95, .045)
    candy_cane(k, .12, -.08, 0, .7, .04, rz=math.radians(10))
    candy_cane(k, -.15, -.18, 0, .55, .035, rz=math.radians(-100))
    k.ball("cloth", -.08, .06, .55, .07, GREEN, 10, sx=1.8, sz=.8)

def lamp_post(k): lamp(k, 0, 0, 0, 1.25, wreath=True)

def snowy_bench(k):
    for x in (-.32, .32):
        k.box("iron", x, 0, 0, .06, .28, .26, IRON)
        k.box("iron", x, .14, 0, .05, .05, .56, IRON)
    for dy in (-.09, 0, .09):
        k.box("wood", 0, dy, .26, .82, .08, .04, GREEN)
    for z in (.36, .46):
        k.box("wood", 0, .15, z, .82, .04, .07, GREEN)
    k.snow_cap(0, 0, .3, .78, .26, .05, True)
    k.box("snow", 0, .15, .53, .8, .06, .04, SNOW)

def sleigh(k):
    body = RED
    for y in (-.2, .2):   # gold runners, curled at the front
        pts = [(-.75, y, .03), (.5, y, .03)]
        for i in range(1, 9):
            a = math.pi * .5 - math.pi * 1.3 * i / 8
            pts.append((.5 + .18 * math.cos(a) + 0, y, .21 + .18 * math.sin(a) - .0))
        k.path("gold", pts, .022, GOLD, 8)
        for x in (-.5, .2):
            k.tube("gold", (x, y, .03), (x, y, .18), .015, .015, GOLD, 6)
    k.prism_y("glossy", [(-.7, .18), (.42, .18), (.62, .42), (.5, .5), (.28, .36), (-.4, .36), (-.62, .7), (-.75, .66)],
              -.26, .26, body)
    k.prism_y("gold", [(-.7, .17), (.42, .17), (.44, .21), (-.72, .21)], -.27, .27, GOLD)
    k.box("cloth", -.12, 0, .36, .5, .44, .06, C("#2E7A4A"))
    k.present(-.48, .02, .36, .22, .2, PRESENT[3], RIBBON[2], .3)
    k.present(-.25, -.1, .4, .18, .16, PRESENT[2], RIBBON[0], -.2)
    k.present(-.42, .16, .56, .16, .14, PRESENT[0], RIBBON[0], .6)
    k.present(-.1, .12, .42, .16, .12, PRESENT[4], RIBBON[1], -.4)
    k.snow_cap(.15, 0, .38, .3, .4, .03, False)

def reindeer(k):
    body, belly = C("#9A6A44"), C("#E8D2B0")
    f = Matrix.Rotation(math.radians(-60), 4, "Z")
    with k.at(f):
        k.ball("matte", 0, 0, .52, .17, body, 14, sx=1.9, sy=1.0)
        k.ball("matte", 0, 0, .48, .12, belly, 12, sx=1.6, sy=.8)
        for x in (-.22, .2):
            for y in (-.08, .08):
                k.tube("matte", (x, y, .48), (x + .02, y, .04), .04, .028, body, 8)
                k.ball("matte", x + .02, y, .04, .035, WOOD_D, 6)
        k.tube("matte", (.24, 0, .55), (.36, 0, .8), .09, .07, body, 10)
        k.ball("matte", .4, 0, .85, .09, body, 12, sx=1.4)
        k.ball("matte", .52, 0, .82, .05, belly, 10, sx=1.2)
        k.ball("glossy", .57, 0, .82, .035, RED, 8)
        for y in (-1, 1):
            k.ball("matte", .44, y * .055, .9, .018, COAL, 6)
            k.ball("matte", .34, y * .1, .93, .03, body, 6, sx=1.6)
            p = Vector((.37, y * .04, .93))
            pts = [p, p + Vector((-.05, y * .1, .16)), p + Vector((-.12, y * .16, .3))]
            k.path("wood", [tuple(q) for q in pts], .016, CREAM, 6)
            k.tube("wood", tuple(pts[1]), tuple(pts[1] + Vector((.08, y * .02, .1))), .013, .01, CREAM, 6)
            k.tube("wood", tuple(pts[2]), tuple(pts[2] + Vector((.06, y * .05, .08))), .012, .008, CREAM, 6)
        k.torus("cloth", Matrix.Translation((.3, 0, .62)) @ Matrix.Rotation(math.radians(60), 4, "Y") @ Matrix.Rotation(math.pi / 2, 4, "X"),
                .1, .025, RED)
        k.ball("gold", .38, 0, .55, .04, GOLD, 8)
        k.ball("snow", -.33, 0, .58, .05, CREAM, 8)

def wreath_arch(k):
    for x in (-.78, .78):
        k.box("wood", x, 0, 0, .12, .12, .9, WOOD)
        k.snow_cap(x, 0, .9, .14, .14, .04, False)
    for i in range(23):
        a = math.pi * i / 22
        x, z = .78 * math.cos(a), .9 + .62 * math.sin(a)
        k.ball("leaf", x, 0, z, .13, J(GREEN_L, .1), 10)
        if i % 3 == 1:
            k.ball("glossy", x, -.1, z + .03, .04, R.choice((RED, GOLD)), 8)
        if i % 2 == 0:
            k.ball("bulb", x, -.12, z - .08, .025, BULBS[(i // 2) % 4], 6)
        k.ball("snow", x, .02, z + .1, .07, SNOW, 8, sz=.5)
    k.ball("cloth", 0, -.14, 1.46, .1, RED, 10, sx=2.0, sz=.8)
    for x in (-.78, .78):
        k.ball("cloth", x, -.12, .88, .07, RED, 8, sx=1.6, sz=.8)

def igloo(k):
    rr = .82
    rows = 6
    for i in range(rows):
        a0 = (math.pi / 2) * i / rows
        a1 = (math.pi / 2) * (i + 1) / rows
        r = rr * math.cos((a0 + a1) / 2)
        z = rr * math.sin(a0)
        hh = rr * (math.sin(a1) - math.sin(a0))
        n = max(4, int(2 * math.pi * r / .3))
        for j in range(n):
            a = 2 * math.pi * (j + (.5 if i % 2 else 0)) / n
            if i < 2 and abs(math.atan2(math.sin(a - math.radians(-20)), math.cos(a - math.radians(-20)))) < .38:
                continue   # the doorway
            k.box("snow", r * math.cos(a), r * math.sin(a), z, .16, 2 * math.pi * r / n * .94, hh * .96, J(SNOW, .015), a)
    k.ball("snow", 0, 0, rr * .82, .18, SNOW, 12, sz=.6)
    k.lathe("snow", 0, 0, 0, [(rr - .1, 0), (rr - .1, rr * .2), (.001, rr * .85)], SNOW_SH, 24)   # inner fill
    a = math.radians(-20)
    with k.at(Matrix.Translation((rr * .8 * math.cos(a), rr * .8 * math.sin(a), 0)) @ Matrix.Rotation(a, 4, "Z")):
        def fn(u, v):
            t = math.pi * u
            return (.05 + .25 * v, .22 * math.cos(t), .28 * math.sin(t))
        k.surface("snow", fn, 10, 2, SNOW)
        k.prism("glow", [(-.15, 0), (.15, 0), (.15, .14), (0, .22), (-.15, .14)], .06, .08, GLOW)
    k.light((.6, -.4, .2), .5)
    for (x, y) in ((.5, .55), (-.6, -.5)):
        k.ball("snow", x, y, 0, .14, SNOW, 10, sz=.6)

def ice_star(k):
    k.box("snow", 0, 0, 0, .46, .46, .18, SNOW)
    k.box("snow", 0, 0, .18, .34, .34, .16, SNOW_SH)
    k.star("ice", 0, 0, .78, .42, .12, ICE)
    k.star("glow", 0, -.0, .78, .14, .14, C("#D0F4FF"))
    k.light((-.2, -.2, .8), .3, (.7, .9, 1))

def nutcracker(k):
    k.box("paint", 0, 0, 0, .34, .34, .12, GOLD)
    with k.at(Matrix.Rotation(math.radians(45), 4, "Z")):
        for x in (-.06, .06):
            k.tube("glossy", (x, 0, .12), (x, 0, .22), .05, .05, COAL, 10)
            k.tube("glossy", (x, 0, .22), (x, 0, .42), .045, .045, SNOW, 10)
        k.tube("glossy", (0, 0, .42), (0, 0, .7), .12, .11, RED, 14)
        k.tube("gold", (0, 0, .42), (0, 0, .46), .125, .125, COAL, 14)
        for z in (.5, .57, .64):
            k.ball("gold", 0, -.11, z, .015, GOLD, 6)
        for x in (-1, 1):
            k.tube("glossy", (x * .12, 0, .68), (x * .17, -.03, .5), .04, .035, RED, 8)
            k.ball("matte", x * .17, -.03, .47, .035, SNOW, 8)
            k.ball("gold", x * .12, 0, .7, .04, GOLD, 8, sz=.5)
        k.tube("matte", (0, 0, .7), (0, 0, .74), .04, .04, SKIN, 8)
        k.ball("matte", 0, 0, .82, .1, SKIN, 12, sz=1.15)
        k.box("matte", 0, -.085, .72, .1, .04, .06, SNOW)   # beard
        k.ball("matte", 0, -.1, .82, .02, RED_L, 6)
        for x in (-.035, .035):
            k.ball("matte", x, -.09, .86, .012, COAL, 6)
        k.tube("matte", (0, 0, .88), (0, 0, 1.08), .105, .1, COAL, 14)
        k.box("gold", 0, -.09, .9, .07, .04, .14, GOLD)
        k.ball("cloth", 0, -.02, 1.11, .035, RED, 6)

def mailbox(k):
    with k.at(Matrix.Scale(1.3, 4)):
        mailbox_at(k)

def mailbox_at(k):
    k.box("wood", 0, 0, 0, .07, .07, .62, WOOD_D)
    with k.at(Matrix.Rotation(math.radians(45), 4, "Z")):
        k.box("candy", 0, 0, .62, .38, .2, .14, RED)
        k.tube("candy", (-.19, 0, .76), (.19, 0, .76), .1, .1, RED, 14)
        k.snow_cap(0, 0, .84, .3, .14, .04, False)
        k.box("gold", .19, 0, .66, .01, .14, .14, GOLD)
        k.box("candy", -.05, -.11, .66, .03, .02, .2, GOLD)   # the flag
        k.box("candy", -.02, -.11, .82, .07, .02, .05, GOLD)
        k.box("paint", .05, -.105, .7, .14, .01, .09, SNOW)   # a letter for the North Pole
    k.ball("snow", 0, 0, 0, .14, SNOW, 10, sz=.4)

def snow_rocks(k):
    for (x, y, r, s) in ((-.12, .12, .32, .8), (.26, -.14, .22, .85), (-.22, -.3, .16, .9)):
        k.ball("stone", x, y, r * s * .7, r, stone(), 14, sz=s)
        k.ball("snow", x - .03, y + .03, r * s * 1.38, r * .62, SNOW, 12, sz=.32)

def giant_ornament(k):
    k.box("snow", 0, 0, 0, .44, .44, .12, SNOW)
    k.disc("gold", 0, 0, .12, .16, .05, GOLD, 16)
    k.ball("glossy", 0, 0, .55, .38, RED, 24)
    k.lathe("gold", 0, 0, .52, [(.385, 0), (.385, .06)], GOLD, 32)
    for i in range(8):
        a = math.radians(-160) + i * math.radians(22)
        k.star("gold", .38 * math.cos(a), .38 * math.sin(a), .5, .05, .02, GOLD, rz=a + math.pi / 2)
    k.disc("gold", 0, 0, .92, .1, .1, GOLD_D, 12)
    k.torus("gold", Matrix.Translation((0, 0, 1.06)) @ Matrix.Rotation(math.radians(45), 4, "Z"), .05, .012, GOLD)

def penguins(k):
    for (x, y, s, sc) in ((-.15, .12, 1.0, RED), (.2, -.15, .7, GREEN)):
        with k.at(Matrix.Translation((x, y, 0)) @ Matrix.Rotation(math.radians(35), 4, "Z") @ Matrix.Scale(s, 4)):
            k.ball("glossy", 0, 0, .3, .18, COAL, 14, sz=1.6)
            k.ball("matte", .0, -.06, .26, .14, SNOW, 12, sz=1.5)
            k.ball("glossy", 0, 0, .62, .11, COAL, 12)
            k.ball("matte", 0, -.06, .6, .07, SNOW, 10)
            k.lathe("matte", 0, -.1, .6, [(.03, 0), (.001, .08)], CARROT, 8, m=Matrix.Rotation(math.pi / 2, 4, "X"))
            for xx in (-.04, .04):
                k.ball("matte", xx, -.09, .65, .014, COAL, 6)
                k.ball("matte", xx * 1.5, -.06, .02, .05, CARROT, 8, sy=1.5, sz=.4)
            for xx in (-1, 1):
                k.ball("glossy", xx * .17, 0, .34, .06, COAL, 8, sx=.4, sz=2.0)
            k.torus("cloth", Matrix.Translation((0, 0, .5)) @ Matrix.Rotation(math.pi / 2, 4, "X"), .12, .03, sc)
            k.box("cloth", .07, -.1, .3, .05, .03, .18, sc)

# ------------------------------------------------------------------ the market
# The twelve campaign buildings follow art/building-reference-sheet.png:
# snowy timber, evergreen garlands with warm bulbs, red bows, amber windows
# and lanterns, each on a snow-covered brick slab.

TIMBER, TIMBER_D, TIMBER_L = C("#A86E3C"), C("#6A3E1E"), C("#C48A50")
BRICK = [C(h) for h in ("#A0968C", "#8F857B", "#B2A89C")]
COPPER = C("#C27840")
NAVY, NAVY_D = C("#2F4E86"), C("#1F3560")
WARM = C("#FFC864")
DEEP_RED = C("#B01E22")
BAUBLES = [C(h) for h in ("#D4262A", "#F0B83A", "#D4262A", "#E8E0D0")]


def market_slab(k, w, h):
    """The direction sheet's base: grey brick under a thick snow layer."""
    k.box("slab", 0, 0, 0, w, h, G, J(BRICK[1], .02))
    for side in range(2):   # brick courses on the two visible sides
        L = w if side == 0 else h
        n = int(L / .28)
        for row in range(2):
            off = .5 if row else 0
            for j in range(n + 1):
                t0, t1 = max(0, (j - off) / n), min(1, (j + 1 - off) / n)
                if t1 <= t0:
                    continue
                c, ln = (t0 + t1) / 2 * L - L / 2, (t1 - t0) * L * .94
                z = row * G / 2
                if side == 0:
                    k.box("stone", c, -h / 2 + .006, z + .004, ln, .012, G / 2 - .008, J(R.choice(BRICK), .03))
                else:
                    k.box("stone", w / 2 - .006, c, z + .004, .012, ln, G / 2 - .008, J(R.choice(BRICK), .03))
    k.box("snow", 0, 0, G - .02, w - .02, h - .02, .07, SNOW)
    for _ in range(int((w + h) * 3)):   # soft drifts along the edges
        if R.random() < .5:
            x, y = R.uniform(-w / 2 + .1, w / 2 - .1), (h / 2 - .08) * R.choice((-1, 1))
        else:
            x, y = (w / 2 - .08) * R.choice((-1, 1)), R.uniform(-h / 2 + .1, h / 2 - .1)
        k.ball("snow", x, y, G + .03, R.uniform(.07, .12), SNOW, 10, sz=.4)


def bow(k, x, y, z, s=.1, rz=math.radians(45)):
    """A red ribbon bow; rz = 45 degrees faces the camera, 0 a wall frame's outside."""
    with k.at(Matrix.Translation((x, y, z)) @ Matrix.Rotation(rz, 4, "Z")):
        for side in (-1, 1):
            k.ball("cloth", side * s * .62, 0, s * .1, s * .55, DEEP_RED, 10, sx=1.3, sy=.55, sz=.9)
            k.beam("cloth", (side * s * .12, 0, -s * .1), (side * s * .55, -.005, -s * 1.15), s * .3, s * .12, DEEP_RED)
        k.ball("cloth", 0, -s * .05, 0, s * .26, RED, 8)


def garland(k, pts, r=.07, sag=.1, bows=(), bulbs=True, bow_size=.11, bow_rz=math.radians(45)):
    """Evergreen rope through pts, sagging between them, with warm bulbs and bows at
    the given control-point indices."""
    pts = [Vector(p) for p in pts]
    fine = []
    for a, b in zip(pts, pts[1:]):
        n = max(2, int((b - a).length / (r * 1.1)))
        for i in range(n):
            t = i / n
            fine.append(a.lerp(b, t) - Vector((0, 0, sag * 4 * t * (1 - t))))
    fine.append(pts[-1])
    for i, p in enumerate(fine):
        k.ball("leaf", p.x, p.y, p.z, r * R.uniform(.9, 1.15), J(R.choice(FIR), .08), 8)
        if bulbs and i % 3 == 1:
            k.ball("bulb", p.x + R.uniform(-.02, .02), p.y + R.uniform(-.02, .02), p.z - r * .7, r * .32, WARM, 6)
        if i % 5 == 2:
            k.ball("snow", p.x, p.y, p.z + r * .7, r * .6, SNOW, 6, sz=.5)
    for i in bows:
        p = pts[i]
        bow(k, p.x, p.y, p.z, bow_size, bow_rz)


def lantern(k, x, y, z, s=.1, light=.7):
    """A black iron lantern with a warm glow, standing at z."""
    k.box("iron", x, y, z, s * 1.1, s * 1.1, s * .2, IRON)
    k.box("glow", x, y, z + s * .2, s * .8, s * .8, s * 1.2, GLOW_L)
    for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        k.box("iron", x + dx * s * .45, y + dy * s * .45, z + s * .2, s * .12, s * .12, s * 1.2, IRON)
    k.lathe("iron", x, y, z + s * 1.4, [(s * .8, 0), (.001, s * .6)], IRON, 4, m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.ball("iron", x, y, z + s * 2.05, s * .14, IRON, 6)
    k.ball("snow", x, y, z + s * 1.6, s * .4, SNOW, 6, sz=.5)
    if light:
        k.light((x - .1, y - .1, z + s), light)


def bow_fir(k, x, y, h, r, z=G, bows=2):
    k.fir(x, y, z, h, r, tiers=3, deco=int(h * 6), palette=BAUBLES, snow=.45)
    for i in range(bows):
        a = math.radians(-45) + R.uniform(-.7, .7)
        t = .35 + .3 * i
        rr = r * (1 - t) + .02
        bow(k, x + rr * math.cos(a), y + rr * math.sin(a), z + h * (.15 + t * .75), .06 + r * .05)


def post_box(k, x, y, z0, z1, s=.16, col=TIMBER):
    k.box("wood", x, y, z0, s, s, z1 - z0, J(col, .04))


def half_timber(k, frame_len, z0, z1, n, col=TIMBER_D, cross=True):
    """Dark beams on a wall frame: posts, a rail and braces (local -y out)."""
    for i in range(n + 1):
        k.box("wood", frame_len * i / n, -.02, z0, .07, .04, z1 - z0, col)
    k.box("wood", frame_len / 2, -.02, (z0 + z1) / 2, frame_len, .04, .07, col)
    if cross:
        for i in range(n):
            a, b = frame_len * i / n, frame_len * (i + 1) / n
            k.beam("wood", (a + .05, -.025, z0 + .05), (b - .05, -.025, (z0 + z1) / 2 - .03), .05, .03, col)


def candy_post(k, x, y, z0, z1, r=.06):
    n = int((z1 - z0) / .09)
    for i in range(n):
        k.tube("candy", (x, y, z0 + i * (z1 - z0) / n), (x, y, z0 + (i + 1) * (z1 - z0) / n), r, r, RED if i % 2 else SNOW, 10)


def fence(k, a, b, z, posts, h=.32, garland_bows=True):
    """A wooden rail fence from a to b with a garland along its top rail."""
    a, b = Vector(a), Vector(b)
    for i in range(posts + 1):
        p = a.lerp(b, i / posts)
        k.box("wood", p.x, p.y, z, .09, .09, h + .05, TIMBER_D)
        k.ball("snow", p.x, p.y, z + h + .07, .05, SNOW, 6, sz=.6)
    for zz in (z + h * .45, z + h):
        k.beam("wood", (a.x, a.y, zz), (b.x, b.y, zz), .06, .05, TIMBER)
    garland(k, [(a.x, a.y, z + h + .02), (b.x, b.y, z + h + .02)], .06, .08,
            bows=(0, 1) if garland_bows else ())


def eave_garland(k, x0, x1, y, z, bows=(0, 1, 2)):
    """Along a -Y eave: control points at both ends and the middle."""
    garland(k, [(x0, y, z), ((x0 + x1) / 2, y, z), (x1, y, z)], .07, .12, bows=bows, bow_rz=0)


def side_garland(k, x, y0, y1, z, bows=(1,)):
    """Along a +X eave."""
    garland(k, [(x, y0, z), (x, (y0 + y1) / 2, z), (x, y1, z)], .065, .1, bows=bows, bow_rz=math.radians(90))


def arch(k):
    py, px = 1.0, .1
    for y in (-py, py):
        for row in range(4):   # brick pillars
            k.box("stone", px, y, G + row * .21, .56, .56, .2, J(R.choice(BRICK), .03))
        k.box("stone", px, y, G + .84, .64, .64, .08, STONE_L)
        k.snow_cap(px, y, G + .92, .6, .6, .06)
        post_box(k, px, y, G + .9, G + 1.85, .24)
        lantern(k, px + .38, y, G + 1.02, .12)
        k.box("iron", px + .2, y, G + 1.3, .3, .03, .03, IRON)
    top = G + 1.85
    k.box("wood", px, 0, top, .3, 2 * py + .5, .2, TIMBER)
    with k.at(wall_frame((px + .13, -py), (px + .13, py))):   # the curved brace under the beam, on the visible face
        n = 9
        for i in range(n):
            a0, a1 = math.pi * i / n, math.pi * (i + 1) / n
            ri, ro = .78, .92
            p = [(math.cos(a0) * ri, math.sin(a0) * ri), (math.cos(a1) * ri, math.sin(a1) * ri),
                 (math.cos(a1) * ro, math.sin(a1) * ro), (math.cos(a0) * ro, math.sin(a0) * ro)]
            v = [(py + px_, d, top - .78 + pz) for d in (-.1, .1) for px_, pz in p]
            k.add("wood", v, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], TIMBER_D)
    gable(k, px - .32, px + .32, -py - .3, py + .3, top + .2, .42, TIMBER_D, TIMBER, ridge="y", over=.08, rake=TIMBER_L, wall_mat="wood")
    garland(k, [(px + .24, -py - .2, top + .05), (px + .24, -py * .5, top - .1), (px + .24, 0, top - .02),
                (px + .24, py * .5, top - .1), (px + .24, py + .2, top + .05)], .08, .12, bows=(0, 4), bow_rz=math.radians(90))
    with k.at(right_face(-py, py, px + .3)):
        k.wreath(py, -.02, top - .3, .22)
        bow(k, py, -.08, top - .08, .12, rz=0)
    for (x, y, hh) in ((1.15, -1.15, .8), (1.15, 1.18, .7), (-1.15, -1.18, .75), (-1.1, 1.1, .9)):
        bow_fir(k, x, y, hh, .26)


def lumber(k):
    x0, x1, y0, y1 = -1.2, 1.15, -.7, 1.2
    zt = G + 1.5
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        post_box(k, x + (.08 if x < 0 else -.08), y + (.08 if y < 0 else -.08), G, zt, .18)
    for i in range(9):   # plank walls at the back and left
        t = (i + .5) / 9
        k.box("wood", x0 + (x1 - x0) * t, y1 - .08, G, (x1 - x0) / 9 * .95, .06, zt - G, J(TIMBER, .08))
        k.box("wood", x0 + .08, y0 + (y1 - y0) * t, G, .06, (y1 - y0) / 9 * .95, zt - G, J(TIMBER, .08))
    k.box("wood", (x0 + x1) / 2, y0 + .08, zt - .14, x1 - x0, .14, .14, TIMBER_D)   # lintels
    k.box("wood", x1 - .08, (y0 + y1) / 2, zt - .14, .14, y1 - y0, .14, TIMBER_D)
    gable(k, x0, x1, y0, y1, zt, .72, TIMBER_D, TIMBER, ridge="x", over=.1, rake=TIMBER_L, wall_mat="wood")
    eave_garland(k, x0, x1, y0 - .14, zt - .05)
    side_garland(k, x1 + .14, y0, y1, zt - .05)
    for row in range(3):   # the log pile along the back wall, ends towards us
        for j in range(5 - row):
            z = G + .1 + row * .17
            xx = x0 + .5 + j * .2 + row * .1
            k.tube("wood", (xx, y1 - .6, z), (xx, y1 - .18, z), .09, .09, J(LOG, .08), 10)
            k.lathe("wood", xx, y1 - .605, z, [(.001, -.004), (.08, -.004), (.08, .004), (.001, .004)], C("#D8B080"), 12,
                    m=Matrix.Rotation(math.pi / 2, 4, "X"))
    k.box("wood", -.1, -.95, G + .45, 1.2, .5, .07, TIMBER_L)   # the workbench, out in front
    for dx in (-.52, .52):
        for dy in (-.18, .18):
            k.box("wood", -.1 + dx, -.95 + dy, G, .07, .07, .45, TIMBER_D)
    k.tube("wood", (-.5, -.95, G + .61), (.1, -.95, G + .61), .08, .08, LOG, 10)
    k.box("iron", .3, -.95, G + .52, .3, .02, .09, C("#C0C4CC"))
    for i in range(3):   # shavings and a sawhorse log
        k.ball("wood", -.6 + i * .25, -1.25, G + .02, .05, C("#E0C090"), 6, sz=.4)
    k.lathe("iron", .8, -1.0, G + .55, [(.001, -.02), (.3, -.02), (.3, .02), (.001, .02)], C("#B8BCC4"), 24,
            m=Matrix.Rotation(math.pi / 2, 4, "X"))   # the saw wheel, facing us on the left
    k.lathe("wood", .8, -.97, G + .55, [(.001, -.03), (.08, -.03), (.08, .03), (.001, .03)], TIMBER_D, 12,
            m=Matrix.Rotation(math.pi / 2, 4, "X"))
    k.box("wood", .8, -.92, G, .12, .1, .5, TIMBER_D)
    k.ball("wood", -1.1, -1.2, G + .2, .17, WOOD_L, 12, sx=.9, sy=.9, sz=1.2)
    for z in (G + .1, G + .34):
        k.tube("iron", (-1.1, -1.2, z), (-1.1, -1.2, z + .02), .16, .16, IRON, 12)
    k.snow_cap(-1.1, -1.2, G + .43, .2, .2, .03, False)
    for i in range(3):   # planks leaning on the right
        k.beam("wood", (1.36, .1 + i * .14, G), (1.24, .2 + i * .14, G + .85), .12, .04, J(TIMBER_L, .06))
    lantern(k, (x0 + x1) / 2, y0 - .02, zt - .5, .09)
    bow_fir(k, 1.28, -1.28, .7, .2)
    bow_fir(k, -1.28, 1.28, .8, .2)


def bakery(k):
    x0, x1, y0, y1 = -1.15, .95, -.75, 1.2
    z1 = G + 1.15
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, z1 - G, PLASTER)
    k.box("stone", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0 + .04, y1 - y0 + .04, .18, STONE_D)
    with k.at(left_face(x0, x1, y0)):
        half_timber(k, x1 - x0, G + .18, z1, 4)
        k.box("glow", 1.05, -.05, G + .32, 1.5, .04, .5, GLOW_L)   # the shop window behind the counter
        k.box("wood", 1.05, -.36, G, 1.7, .34, .42, TIMBER)       # the counter
        k.box("wood", 1.05, -.36, G + .42, 1.8, .4, .05, TIMBER_D)
        for i in range(7):   # gingerbread on the counter
            s_ = .3 + i * .21
            k.ball("matte", s_, -.38, G + .55, .05, GINGER, 8)
            k.box("matte", s_, -.38, G + .47, .09, .03, .06, GINGER)
        n = 9   # the striped awning
        for i in range(n):
            x = .15 + (i + .5) * (1.8 / n)
            col = RED if i % 2 == 0 else SNOW
            k.beam("cloth", (x, -.62, G + .92), (x, -.02, G + 1.08), 1.8 / n * 1.01, .04, col)
            k.box("cloth", x, -.63, G + .82, 1.8 / n * .98, .04, .11, col)
        k.snow_cap(1.05, -.32, G + 1.05, 1.7, .5, .04, False)
    with k.at(right_face(y0, y1, x1)):
        half_timber(k, y1 - y0, G + .18, z1, 4)
        k.window(1.2, G + .45, .4, .42, frame=TIMBER_D, glow=GLOW_L)
        k.wreath(.45, -.06, G + .75, .14)
    gable(k, x0, x1, y0, y1, z1, .95, lambda: J(TIMBER_D, .04), PLASTER, ridge="y", over=.14, rake=TIMBER_D)
    with k.at(left_face(x0, x1, y0 - .05)):   # the pretzel sign on the front gable
        pts = []
        cx, cz = (x1 - x0) / 2, z1 + .38
        for i in range(33):
            t = 2 * math.pi * i / 32
            pts.append((cx + .22 * math.sin(2 * t), -.05, cz + .16 * math.cos(t) + .05 * math.cos(2 * t)))
        k.path("matte", pts, .05, C("#B8742E"), 8)
    garland(k, [(x0 - .1, y0 - .17, z1 - .05), ((x0 + x1) / 2, y0 - .17, z1 + .92), (x1 + .1, y0 - .17, z1 - .05)], .07, .05, bows=(0, 1, 2), bow_rz=0)
    side_garland(k, x1 + .17, y0, y1, z1 - .05, bows=(0, 2))
    chimney(k, -.6, .7, z1 + .45, z1 + 1.1, .3)
    bow_fir(k, 1.25, -1.28, .7, .2)
    bow_fir(k, 1.3, 1.25, .8, .22)
    bow_fir(k, -1.3, -1.25, .65, .2)


def cocoa(k):
    x0, x1, y0, y1 = -1.05, 1.0, -.7, 1.1
    zc, zt = G + .6, G + 1.3
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, zc - G, RED_D)
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2 + .3, zc, x1 - x0 - .1, y1 - y0 - .6, zt - zc, GREEN_D)
    k.box("glow", (x0 + x1) / 2, y0 + .32, zc, x1 - x0 - .3, .04, zt - zc - .05, GLOW)
    with k.at(left_face(x0, x1, y0)):
        for s_ in (.15, 1.9):
            k.box("paint", s_, -.02, G + .05, .1, .04, zc - G - .1, GREEN)
        for s_ in (.55, 1.5):   # wreaths on the front panel
            k.wreath(s_, -.03, G + .33, .13)
            bow(k, s_, -.07, G + .2, .06, rz=0)
        k.box("paint", 1.02, -.02, zc - .05, 2.05, .06, .05, GOLD_D)
    k.box("wood", (x0 + x1) / 2, y0 + .05, zc, x1 - x0 + .1, .5, .05, TIMBER_L)   # the counter top
    k.lathe("gold", -.15, y0 + .12, zc + .05, [(.001, 0), (.13, 0), (.16, .1), (.15, .32), (.1, .36), (.04, .42), (.001, .44)], COPPER, 16)
    k.box("gold", .02, y0 + .02, zc + .14, .1, .03, .03, COPPER)
    for i, c in enumerate((RED, SNOW, RED, GREEN, SNOW)):   # mugs
        k.lathe("candy", .25 + i * .14, y0 + .05 + (i % 2) * .1, zc + .05, [(.045, 0), (.05, .1)], c, 10)
    candy_cane(k, -.75, y0 + .12, zc + .05, .3, .025)
    for x in (x0 + .06, x1 - .06):
        candy_post(k, x, y0 + .06, zc, zt)
    candy_post(k, x1 - .06, y1 - .06, zc, zt)
    gable(k, x0, x1, y0, y1, zt, .7, lambda: J(RED_D, .04), GREEN_D, ridge="x", over=.12, rake=GOLD_D)
    eave_garland(k, x0 - .05, x1 + .05, y0 - .14, zt - .04)
    side_garland(k, x1 + .14, y0, y1, zt - .04)
    with k.at(right_face(y0, y1, x1)):
        k.wreath(.9, -.04, G + .32, .14)
    chimney(k, .55, .55, zt + .35, zt + .95, .26)
    k.ball("wood", -1.25, .3, G + .2, .17, WOOD_L, 12, sx=.9, sy=.9, sz=1.2)
    k.snow_cap(-1.25, .3, G + .4, .2, .2, .03, False)
    bow_fir(k, 1.28, -1.25, .75, .22)
    bow_fir(k, -1.25, -1.25, .7, .2)


def toys(k):
    x0, x1, y0, y1 = -1.2, .95, -.55, 1.2
    z1 = G + 1.2
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, z1 - G, PLASTER)
    k.box("stone", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0 + .04, y1 - y0 + .04, .2, STONE_D)
    with k.at(left_face(x0, x1, y0)):
        half_timber(k, x1 - x0, G + .2, z1, 4, cross=False)
        k.box("wood", .55, -.04, G + .2, .5, .05, .62, TIMBER)   # the arched door
        k.lathe("wood", .55, -.04, G + .82, [(.001, -.025), (.25, -.025), (.25, .025), (.001, .025)], TIMBER, 16,
                m=Matrix.Rotation(math.pi / 2, 4, "X"))
        k.wreath(.55, -.08, G + .62, .13)
        k.window(1.45, G + .5, .36, .36, frame=TIMBER_D, glow=GLOW_L)
        k.window(1.9, G + .5, .22, .36, frame=TIMBER_D, glow=GLOW_L, cross=False)
        for s_ in (.15, .95):
            lantern(k, s_, -.12, G + .7, .08, .4)
    with k.at(right_face(y0, y1, x1)):
        half_timber(k, y1 - y0, G + .2, z1, 3, cross=False)
        k.window(1.2, G + .55, .4, .38, frame=TIMBER_D, glow=GLOW_L)
    k.box("wood", x1 + .24, .3, G, .36, .9, .42, TIMBER)   # the toy counter on the right
    k.box("wood", x1 + .24, .3, G + .42, .42, .96, .05, TIMBER_D)
    for i in range(4):
        k.present(x1 + .22, -.03 + i * .22, G + .47, .14, .12 + .04 * (i % 2), [RED, GREEN, GOLD, BLUE][i], RIBBON[i % 2], .3)
    gable(k, x0, x1, y0, y1, z1, .9, lambda: J(TIMBER_D, .04), PLASTER, ridge="x", over=.12, rake=TIMBER_D)
    dx, dz = -.15, z1 + .3   # a dormer on the front slope
    k.box("paint", dx, y0 + .42, dz - .14, .52, .4, .46, PLASTER)
    with k.at(left_face(dx - .26, dx + .26, y0 + .22)):
        k.window(.26, dz + .02, .2, .2, frame=TIMBER_D, glow=GLOW_L, sill=False)
    gable(k, dx - .27, dx + .27, y0 + .2, y0 + .64, dz + .32, .3, lambda: J(TIMBER_D, .04), PLASTER, ridge="y", over=.06,
          rake=TIMBER_D, drip=False)
    eave_garland(k, x0, x1, y0 - .14, z1 - .04)
    chimney(k, -.75, .75, z1 + .45, z1 + 1.15, .28)
    with k.at(Matrix.Translation((.6, -1.05, G)) @ Matrix.Scale(1.3, 4)):
        nutcracker_figure(k)
    bow_fir(k, -1.28, -1.25, .75, .22)
    bow_fir(k, 1.3, 1.3, .65, .2)


def gifts(k):
    hw = 1.05
    zt = G + 1.2
    for x, y in ((-hw, -hw), (hw, -hw), (hw, hw), (-hw, hw)):
        post_box(k, x, y, G, zt, .14)
    for a, b in (((-hw, -hw), (hw, -hw)), ((hw, -hw), (hw, hw))):   # red drapes tied back at the posts
        a, b = Vector((*a, 0)), Vector((*b, 0))
        d = (b - a).normalized()
        for t, sgn in ((.0, 1), (1., -1)):
            p = a.lerp(b, t) + d * .14 * sgn
            k.beam("cloth", (p.x, p.y, zt - .05), (p.x + d.x * .1 * sgn, p.y + d.y * .1 * sgn, G + .1), .2, .05, DEEP_RED)
    k.box("cloth", 0, 0, zt - .05, 2 * hw + .1, 2 * hw + .1, .08, DEEP_RED)
    for side in range(4):   # the scalloped valance
        for i in range(8):
            t = (i + .5) / 8
            if side == 0:
                x, y = -hw + 2 * hw * t, -hw - .06
            elif side == 1:
                x, y = hw + .06, -hw + 2 * hw * t
            elif side == 2:
                x, y = hw - 2 * hw * t, hw + .06
            else:
                x, y = -hw - .06, hw - 2 * hw * t
            k.ball("cloth", x, y, zt - .08, .1, DEEP_RED if i % 2 else SNOW, 8, sz=.8)
    k.lathe("cloth", 0, 0, zt + .02, [(hw * 1.42, 0), (.001, .95)], DEEP_RED, 4, m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.lathe("snow", 0, 0, zt + .05, [(hw * .78, .43), (hw * .6, .54), (hw * .3, .7), (.001, .72)], SNOW, 4,
            m=Matrix.Rotation(math.pi / 4, 4, "Z"))
    k.tube("gold", (0, 0, zt + .85), (0, 0, zt + 1.15), .03, .01, GOLD, 8)
    k.ball("gold", 0, 0, zt + .92, .06, GOLD, 10)
    eave_garland(k, -hw, hw, -hw - .13, zt - .02)
    side_garland(k, hw + .13, -hw, hw, zt - .02, bows=(1, 2))
    k.box("wood", 0, -.45, G, 1.6, .45, .45, TIMBER)   # the wrapping counter
    k.box("cloth", 0, -.45, G + .45, 1.7, .5, .04, RED)
    for i, c in enumerate((RED, SNOW, GREEN, GOLD)):   # rolls of paper
        k.tube("cloth", (-.65 + i * .1, -.38, G + .49), (-.65 + i * .1, -.38, G + .95), .045, .045, c, 10)
    for i in range(5):
        k.present(-.15 + i * .2, -.5 + (i % 2) * .08, G + .49, .15, .1 + .03 * (i % 3), R.choice(PRESENT[:5]), RIBBON[i % 2], R.uniform(-.4, .4))
    for row in range(3):   # shelves of gifts at the back
        z = G + .1 + row * .35
        k.box("wood", 0, .8, z, 1.8, .3, .04, TIMBER_D)
        for j in range(6):
            k.present(-.75 + j * .3, .8, z + .04, .18, .16, R.choice(PRESENT), R.choice(RIBBON[:2]), 0)
    for x, y in ((-hw, -hw), (hw, -hw), (hw, hw)):
        lantern(k, x, y, zt - .42, .08, .35)
    bow_fir(k, -1.3, -1.28, .7, .2)
    bow_fir(k, 1.3, -1.3, .65, .2)
    bow_fir(k, 1.3, 1.3, .75, .2)


def candles(k):
    x0, x1, y0, y1 = -1.15, .95, -.7, 1.2
    z1 = G + 1.15
    k.box("paint", (x0 + x1) / 2, (y0 + y1) / 2, G, x1 - x0, y1 - y0, z1 - G, NAVY)
    with k.at(left_face(x0, x1, y0)):
        L = x1 - x0
        for i in range(5):
            k.box("wood", L * i / 4, -.03, G, .08, .05, z1 - G, CREAM)
        k.box("wood", L / 2, -.03, z1 - .06, L, .05, .07, CREAM)
        k.box("glow", 1.05, -.03, G + .3, 1.5, .04, .72, C("#FFB060"))
        for row in range(3):   # shelves of candles
            z = G + .3 + row * .25
            k.box("wood", 1.05, -.12, z, 1.5, .18, .03, TIMBER_D)
            for j in range(9):
                hh = R.uniform(.08, .16)
                xx = .38 + j * .16
                k.tube("candy", (xx, -.12, z + .03), (xx, -.12, z + .03 + hh), .028, .028, J(CREAM, .03), 8)
                k.ball("bulb", xx, -.12, z + .06 + hh, .016, WARM, 5, sz=1.6)
        k.box("wood", 1.05, -.3, G, 1.7, .26, .3, NAVY_D)   # the counter
        k.box("wood", 1.05, -.3, G + .3, 1.8, .32, .05, CREAM)
        for j in range(5):
            k.tube("candy", (.4 + j * .3, -.3, G + .35), (.4 + j * .3, -.3, G + .5), .05, .05, [RED, CREAM, GREEN][j % 3], 10)
            k.ball("bulb", .4 + j * .3, -.3, G + .53, .025, WARM, 6, sz=1.6)
        k.box("iron", .05, -.2, G + 1.0, .03, .3, .03, IRON)
        lantern(k, .05, -.36, G + .78, .09, .5)
    with k.at(right_face(y0, y1, x1)):
        L = y1 - y0
        for i in range(4):
            k.box("wood", L * i / 3, -.03, G, .08, .05, z1 - G, CREAM)
        k.window(L * .55, G + .45, .5, .42, frame=CREAM, glow=GLOW_L)
    gable(k, x0, x1, y0, y1, z1, .95, lambda: J(TIMBER_D, .04), NAVY, ridge="y", over=.14, rake=CREAM)
    with k.at(left_face(x0, x1, y0 - .06)):
        k.wreath((x1 - x0) / 2, -.04, z1 + .38, .2)
        bow(k, (x1 - x0) / 2, -.1, z1 + .56, .11, rz=0)
    garland(k, [(x0 - .1, y0 - .17, z1 - .05), ((x0 + x1) / 2, y0 - .17, z1 + .92), (x1 + .1, y0 - .17, z1 - .05)], .065, .04, bows=(0, 2), bow_rz=0)
    side_garland(k, x1 + .17, y0, y1, z1 - .05)
    chimney(k, -.6, .7, z1 + .45, z1 + 1.1, .3)
    bow_fir(k, 1.25, -1.28, .7, .2)
    bow_fir(k, -1.32, -1.2, .75, .2)


def carousel(k):
    rr = 1.28
    k.lathe("paint", 0, 0, G, [(rr, 0), (rr, .16), (rr - .04, .18)], DEEP_RED, 40)
    k.lathe("gold", 0, 0, G + .14, [(rr + .02, 0), (rr + .02, .04)], GOLD, 40)
    k.disc("paint", 0, 0, G + .15, rr - .06, .04, C("#E8D2A0"), 40)
    k.lathe("gold", 0, 0, G + .19, [(.24, 0), (.2, .2), (.2, 1.18), (.26, 1.3)], GOLD, 18)
    k.lathe("glow", 0, 0, G + .4, [(.205, 0), (.205, .78)], WARM, 24)
    n = 8
    for i in range(n):
        a = 2 * math.pi * i / n + math.pi / 8
        x, y = .92 * math.cos(a), .92 * math.sin(a)
        k.tube("gold", (x, y, G + .19), (x, y, G + 1.42), .022, .022, GOLD, 8)
        z = G + .5 + (.12 if i % 2 else 0)
        f = Matrix.Translation((x, y, z)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")
        with k.at(f):   # a reindeer on each pole
            body, belly = C("#C8925C"), C("#F0E0C0")
            k.ball("glossy", 0, 0, 0, .1, body, 12, sx=2.0, sy=.9, sz=.95)
            k.ball("glossy", 0, 0, -.03, .07, belly, 10, sx=1.7, sy=.8)
            k.tube("glossy", (.14, 0, .04), (.22, 0, .2), .055, .045, body, 10)
            k.ball("glossy", .26, 0, .22, .055, body, 10, sx=1.6)
            k.ball("glossy", .34, 0, .21, .02, RED, 6)
            for dy in (-.03, .03):
                k.path("wood", [(.24, dy, .26), (.2, dy * 3, .36), (.15, dy * 5, .44)], .012, CREAM, 5)
            for dx in (-.12, .12):
                k.tube("glossy", (dx, 0, -.04), (dx + .03, 0, -.2), .025, .02, body, 6)
            k.box("cloth", 0, 0, .08, .12, .2, .04, [RED, GREEN, RED, GOLD][i % 4])
            k.ball("gold", .14, 0, .09, .025, GOLD, 6)
    m = 16
    zr, top = G + 1.45, G + 2.15
    for i in range(m):   # the striped canopy, one band per stripe
        a0, a1 = 2 * math.pi * i / m, 2 * math.pi * (i + 1) / m
        col = DEEP_RED if i % 2 == 0 else SNOW
        k.add("cloth", [(rr * math.cos(a0), rr * math.sin(a0), zr), (rr * math.cos(a1), rr * math.sin(a1), zr), (0, 0, top)], [(0, 1, 2)], col)
    k.lathe("snow", 0, 0, zr + .3, [(rr * .55, 0), (rr * .45, .14), (.001, .6)], SNOW, 32)
    k.lathe("gold", 0, 0, zr - .1, [(rr + .03, 0), (rr + .03, .1)], GOLD, 40)
    ring = [(rr * 1.02 * math.cos(2 * math.pi * i / 24), rr * 1.02 * math.sin(2 * math.pi * i / 24), zr - .1) for i in range(25)]
    garland(k, ring, .07, .1, bows=tuple(range(0, 24, 3)))
    k.tube("gold", (0, 0, top - .05), (0, 0, top + .25), .025, .025, GOLD, 8)
    k.ball("gold", 0, 0, top + .3, .07, GOLD, 10)
    k.light((-.3, -.3, G + 1.2), 1.5)
    bow_fir(k, 1.3, -1.3, .7, .2)
    bow_fir(k, -1.3, -1.3, .65, .2)
    bow_fir(k, 1.3, 1.3, .75, .2)


def rink(k):
    W = 1.3
    k.box("matte", 0, 0, G + .045, 2 * W, 2 * W, .03, RINK_ICE)   # above the slab's snow
    for i in range(4):   # skate marks
        a = R.uniform(0, 3)
        pts = [(.55 * math.cos(a + t) * (1 + .18 * i), .45 * math.sin(a + t) * (1 + .18 * i), G + .078) for t in [j * .2 for j in range(14)]]
        for p, q in zip(pts, pts[1:]):
            k.beam("snow", p, q, .012, .005, SNOW_BLUE)
    c = [(-W, -W), (W, -W), (W, W), (-W, W)]
    for i in range(4):
        fence(k, (*c[i], G), (*c[(i + 1) % 4], G), G + .05, 5)
    for x, y in c:
        k.box("wood", x, y, G, .14, .14, .7, TIMBER_D)
        lantern(k, x, y, G + .7, .1, .5)
    bow_fir(k, 1.32, -1.32, .55, .16, bows=1)
    bow_fir(k, -1.32, 1.32, .6, .16, bows=1)
    bow_fir(k, -1.34, -1.0, .5, .14, bows=1)


def tree(k):
    k.fir(0, 0, G, 3.1, 1.0, tiers=5, deco=90, star=False, lights=True, palette=BAUBLES, snow=.55)
    k.star("gold", 0, 0, G + 3.25, .2, .07, GOLD)
    k.light((-.3, -.3, G + 3.1), 1.0, (1, .82, .4))
    for i in range(10):
        a = math.radians(-160) + i * math.radians(30)
        rr = R.uniform(.4, .75)
        bow(k, rr * math.cos(a), rr * math.sin(a), G + R.uniform(.6, 2.2) * (1 - rr * .3), .07)
    W = 1.3
    c = [(-W, -W), (W, -W), (W, W), (-W, W)]
    for i in range(4):
        fence(k, (*c[i], G), (*c[(i + 1) % 4], G), G, 4, h=.26)
    for (x, y, s, hh) in ((.95, -.3, .26, .22), (.75, -.8, .24, .18), (.25, -1.0, .22, .26), (1.0, .4, .2, .18),
                          (-.45, -.95, .22, .16), (.6, -.45, .18, .28), (-.9, -.6, .2, .2)):
        k.present(x, y, G, s, hh, R.choice(PRESENT[:4]), R.choice(RIBBON[:2]), R.uniform(-.4, .4))
    for x, y in ((W, -W), (-W, -W), (W, W)):
        k.box("wood", x, y, G, .12, .12, .5, TIMBER_D)
        lantern(k, x, y, G + .5, .1, .45)


def firs(k):
    bow_fir(k, -.45, .4, 1.55, .42, bows=3)
    bow_fir(k, .5, .45, 1.15, .34, bows=2)
    k.disc("iron", .2, -.35, G, .08, .06, IRON, 12)
    k.tube("iron", (.2, -.35, G), (.2, -.35, G + 1.2), .035, .025, IRON, 8)
    lantern(k, .2, -.35, G + 1.2, .13, .8)
    with k.at(Matrix.Translation((.2, -.35, 0)) @ Matrix.Rotation(math.radians(45), 4, "Z")):
        k.wreath(0, -.05, G + .78, .1)
        bow(k, 0, -.09, G + .9, .07, rz=0)
    for (x, y, r) in ((-.55, -.5, .16), (-.3, -.7, .11), (.65, -.6, .12)):
        k.ball("stone", x, y, G + r * .5, r, stone(), 10, sz=.8)
        k.ball("snow", x - .01, y + .01, G + r * 1.05, r * .7, SNOW, 10, sz=.4)


def bench(k):
    with k.at(Matrix.Translation((-.2, .25, G)) @ Matrix.Scale(1.25, 4)):
        snowy_bench(k)
        garland(k, [(-.42, .17, .58), (0, .17, .58), (.42, .17, .58)], .05, .06, bows=(0, 2), bow_rz=0)
    snowman_at(k, .52, -.25, G, .95)
    bow_fir(k, -.55, .7, .95, .26, bows=2)
    lantern(k, .72, .6, G, .1, .5)
    lantern(k, -.75, -.65, G, .09, .4)


def nutcracker_figure(k):
    nutcracker(k)


BUILDERS = {"tree": tree, "bench": bench, "bakery": bakery, "carousel": carousel}


# ------------------------------------------------------------------ assembly

with open(os.path.join(HERE, "catalogue.json")) as f:
    CATALOGUE = [dict(zip(("key", "title", "cat", "w", "h", "gold", "stars", "about"), row)) for row in json.load(f)]
BASED = ("wonder", "cottage")      # these stand on a slab; decorations stand on the snow
SLABBED = ("firs", "bench")        # the two original decorations have one too, as on the direction sheet


def to_object(name, bucket, mat, materials, coll, parent):
    me = bpy.data.meshes.new(PREFIX + name)
    me.from_pydata(bucket["v"], [], bucket["f"])
    me.update()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    attr = me.color_attributes.new("col", "FLOAT_COLOR", "POINT")
    flat = []
    for c in bucket["c"]:
        flat.extend((c[0], c[1], c[2], 1))
    attr.data.foreach_set("color", flat)
    me.polygons.foreach_set("use_smooth", [True] * len(bucket["s"]) if mat in BEVELS else bucket["s"])
    me.materials.append(materials[mat])
    me.update()
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    ob.parent = parent
    if mat in BEVELS:
        wid, seg = BEVELS[mat]
        mod = ob.modifiers.new("bevel", "BEVEL")
        mod.width = wid
        mod.segments = seg
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(40)
        mod.harden_normals = True
    return ob


def clean_previous():
    old = bpy.data.scenes.get(SCENE_NAME)
    if old:
        bpy.data.scenes.remove(old)
    for ob in list(bpy.data.objects):
        if ob.get("cm_iso"):
            bpy.data.objects.remove(ob)
    for coll in list(bpy.data.collections):
        if coll.name.startswith(PREFIX):
            bpy.data.collections.remove(coll)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras, bpy.data.worlds):
        for item in list(block):
            if item.name.startswith(PREFIX) and item.users == 0:
                block.remove(item)


def model(it, i):
    R.seed(1000 + i)
    k = Kit(it["w"], it["h"])
    if it["cat"] in BASED or it["key"] in SLABBED:
        if it["cat"] == "cottage":
            k.box("slab", 0, 0, 0, it["w"], it["h"], G, COBBLE)     # the base: exactly the footprint
            k.box("snow", 0, 0, G - .03, it["w"] - .06, it["h"] - .06, .04, SNOW)
        else:
            market_slab(k, it["w"], it["h"])
    BUILDERS.get(it["key"], globals().get(it["key"]))(k)
    hw, hh = it["w"] / 2, it["h"] / 2
    for b in k.buckets.values():   # nothing hangs over the footprint into a neighbour's
        b["v"] = [(max(-hw, min(hw, v[0])), max(-hh, min(hh, v[1])), v[2]) for v in b["v"]]
    return k


def setup_render(scn, transparent=True):
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 96
    scn.cycles.use_adaptive_sampling = True
    scn.cycles.adaptive_threshold = .02
    scn.cycles.use_denoising = True
    scn.cycles.max_bounces = 6
    scn.cycles.caustics_reflective = False
    scn.cycles.caustics_refractive = False
    scn.render.film_transparent = transparent
    scn.render.resolution_percentage = 100
    scn.render.image_settings.file_format = "PNG"
    scn.render.image_settings.color_mode = "RGBA"
    scn.view_settings.view_transform = "Standard"
    scn.view_settings.look = "None"
    scn.view_settings.exposure = -.15


def add_lights(scn):
    # A low winter sun from the camera's left throws shadows back, onto the object's own tiles.
    sun = bpy.data.lights.new(PREFIX + "sun", "SUN")
    sun.energy = 3.0
    sun.angle = math.radians(6)
    sun.color = (1, .9, .78)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_mode = "QUATERNION"
    so.rotation_quaternion = Vector((-.55, 1.0, -1.25)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(so)
    fill = bpy.data.lights.new(PREFIX + "fill", "SUN")
    fill.energy = .55
    fill.angle = math.radians(40)
    fill.color = (.75, .85, 1)
    fo = bpy.data.objects.new("fill", fill)
    fo.rotation_mode = "QUATERNION"
    fo.rotation_quaternion = Vector((-1.0, .2, -.6)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(fo)
    w = bpy.data.worlds.new(PREFIX + "world")
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (.62, .74, 1.0, 1)
    bg.inputs[1].default_value = .7
    scn.world = w


def iso_camera(scn):
    cam = bpy.data.cameras.new(PREFIX + "iso_cam")
    cam.type = "ORTHO"
    cam.clip_start, cam.clip_end = .1, 400
    co = bpy.data.objects.new("iso_camera", cam)
    co.rotation_euler = city_camera.ROTATION
    scn.collection.objects.link(co)
    scn.camera = co
    rot = co.rotation_euler.to_matrix()
    return co, rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0)), rot @ Vector((0, 0, 1))


def build():
    """Every object in its own collection, laid out in rows on the ground for inspection."""
    clean_previous()
    scn = bpy.data.scenes.new(SCENE_NAME)
    materials = make_materials()
    kit_materials = building_kit.make_materials()
    root = bpy.data.collections.new("buildings")
    scn.collection.children.link(root)
    u = v = 0
    row_h = 0
    for i, it in enumerate(CATALOGUE):
        wish = it["key"] in market_wishes.KEYS   # these use the shared kit and its materials
        k = market_wishes.model(it, i) if wish else model(it, i)
        if u + it["w"] > 24:
            u, v = 0, v + row_h + 2
            row_h = 0
        coll = bpy.data.collections.new(it["key"])
        root.children.link(coll)
        pivot = bpy.data.objects.new(it["key"] + ".pivot", None)
        pivot.location = (u + it["w"] / 2, -(v + it["h"] / 2), 0)
        pivot.empty_display_size = .25
        pivot["title"], pivot["w"], pivot["h"] = it["title"], it["w"], it["h"]
        coll.objects.link(pivot)
        for mat, bucket in k.buckets.items():
            if wish:
                building_kit.to_object(it["key"] + "." + mat, bucket, mat, kit_materials, coll, pivot)
            else:
                to_object(it["key"] + "." + mat, bucket, mat, materials, coll, pivot)
        for n, light in enumerate(k.lights):
            p, watts, colour = light if len(light) == 3 else (*light, (1, .62, .28))
            li = bpy.data.lights.new(PREFIX + it["key"] + "_light", "POINT")
            li.energy = watts
            li.color = colour
            li.shadow_soft_size = .08
            lo = bpy.data.objects.new(it["key"] + ".light%d" % n, li)
            lo.location = p
            lo.parent = pivot
            coll.objects.link(lo)
        u += it["w"] + 2
        row_h = max(row_h, it["h"])
    add_lights(scn)
    setup_render(scn)
    co, right, up, back = iso_camera(scn)
    co.location = Vector((10, -6, 0)) + back * 120
    co.data.ortho_scale = 34
    for ob in scn.objects:
        ob["cm_iso"] = True
    for win in getattr(bpy.context.window_manager, "windows", []):
        win.scene = scn
    return scn


if __name__ == "__main__" or "__file__" in globals():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build()
    for other in list(bpy.data.scenes):
        if "buildings" not in other.collection.children:
            bpy.data.scenes.remove(other)
    bpy.context.preferences.filepaths.save_version = 0   # no .blend1 beside the master
    blend = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(HERE, "christmas_market_buildings.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
