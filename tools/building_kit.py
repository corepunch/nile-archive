"""The toolbox every game's Blender buildings are made with.

A game's build_scene.py defines one function per building, each drawing into a Kit
in pivot-local, whole-tile coordinates, and hands them to assemble(). The saved
.blend follows the convention tools/buildings.py renders by name:

    collection <key>        under the collection "buildings"; <key> names the sprite
    empty <key>.pivot       the footprint's ground centre; custom properties title, w, h

Coordinates: 1 unit = 1 tile side. X = tile u, the front-left side, size.w. Y = -v,
the front-right side, size.h. The camera (tools/city_camera.py) sees faces towards
-Y best: put a building's main facade there, its second side towards +X.
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import city_camera

R = random.Random(7)


def C(h):
    h = h.lstrip("#")
    def lin(v):
        v /= 255
        return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
    return tuple(lin(int(h[i:i + 2], 16)) for i in (0, 2, 4))

def J(col, j=.08):
    m = 1 + R.uniform(-j, j)
    return tuple(max(0, c * m * (1 + R.uniform(-j, j) * .25)) for c in col)

SANDS = [C(h) for h in ("#E2C48A", "#D9B878", "#CFAB6A")]
SAND_DK, SAND_PALE = C("#94744A"), C("#E8D3A0")
SLAB = C("#A8946F")
WOOD, WOOD_L, WOOD_D = C("#8E5427"), C("#B47436"), C("#5A3216")
CLAY, CLAY_L, CLAY_D = C("#C94E2C"), C("#E06A3A"), C("#9C3B22")
TEAL, TEAL_D, TEAL_L = C("#16A296"), C("#0D6F6C"), C("#3CCDB7")
GOLD, GOLD_D = C("#E8AE2C"), C("#B67A16")
CANVAS, CANVAS_D = C("#E0CDA0"), C("#C4AB78")
RED, RED_D = C("#B83A30"), C("#872723")
LEAVES = [C(h) for h in ("#3FB23C", "#55C43F", "#6FD043")]
LEAF_CORE = C("#1E6426")
WATER, WATER_L = C("#1596C9"), C("#7FE0F5")
FLAME, FLAME_L = C("#FF7A0A"), C("#FFC02E")
GLOW = C("#FFB84A")
DARK = C("#2A1A10")
BASKET = C("#C39146")
POT = C("#B5613A")
FRUIT = [C(h) for h in ("#D9402E", "#EE8A1E", "#7DBB33", "#E9C32E", "#C2352E")]
PLASTER = C("#E2CFA3")
GREY, STRAW, BRONZE, GLASS = C("#A8A390"), C("#D3A94F"), C("#A87A2E"), C("#BDEFE6")
GRASS_A, GRASS_B, GRID = C("#5B8A3E"), C("#527F39"), C("#3F6A2C")
LINE = C("#FFF3C4")

def sand():
    return J(R.choice(SANDS), .025)


# ------------------------------------------------------------------ materials

# Bevels do the soft, toy-like edges; they are wide on purpose.
BEVELS = {"stone": (.04, 3), "wood": (.03, 2), "clay": (.03, 2), "glaze": (.028, 2),
          "gold": (.022, 2), "slab": (.04, 3), "cloth": (.025, 2), "hedge": (.07, 3)}

def make_material(name, rough=.7, metal=0., spec=.4, emit=0., bump=0., scale=20., mottle=0., alpha=1.):
    m = bpy.data.materials.new("rr_" + name)
    m.use_nodes = True
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    a = nt.nodes.new("ShaderNodeAttribute")
    a.attribute_name = "col"
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    p.inputs["Specular IOR Level"].default_value = spec
    p.inputs["Alpha"].default_value = alpha
    color = a.outputs["Color"]
    if bump or mottle:
        tc = nt.nodes.new("ShaderNodeTexCoord")
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = scale
        noise.inputs["Detail"].default_value = 5
        nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    if mottle:
        mr = nt.nodes.new("ShaderNodeMapRange")
        mr.inputs["From Min"].default_value = .32
        mr.inputs["From Max"].default_value = .68
        mr.inputs["To Min"].default_value = 1 - mottle
        mr.inputs["To Max"].default_value = 1 + mottle * .5
        nt.links.new(noise.outputs["Fac"], mr.inputs["Value"])
        mul = nt.nodes.new("ShaderNodeVectorMath")
        mul.operation = "MULTIPLY"
        nt.links.new(a.outputs["Color"], mul.inputs[0])
        nt.links.new(mr.outputs["Result"], mul.inputs[1])
        color = mul.outputs["Vector"]
    nt.links.new(color, p.inputs["Base Color"])
    if bump:
        b = nt.nodes.new("ShaderNodeBump")
        b.inputs["Strength"].default_value = bump
        b.inputs["Distance"].default_value = .03
        nt.links.new(noise.outputs["Fac"], b.inputs["Height"])
        nt.links.new(b.outputs["Normal"], p.inputs["Normal"])
    if emit:
        nt.links.new(a.outputs["Color"], p.inputs["Emission Color"])
        p.inputs["Emission Strength"].default_value = emit
    return m

def make_materials():
    return {
        "stone": make_material("stone", rough=.8),
        "slab": make_material("slab", rough=.85),
        "wood": make_material("wood", rough=.7),
        "clay": make_material("clay", rough=.6, spec=.35),
        "glaze": make_material("glaze", rough=.45, spec=.4),
        "gold": make_material("gold", rough=.42, metal=.3, spec=.5),
        "cloth": make_material("cloth", rough=.85),
        "leaf": make_material("leaf", rough=.55, spec=.3),
        "hedge": make_material("hedge", rough=.6, spec=.3),
        "glass": make_material("glass", rough=.08, spec=.8, alpha=.32),
        "matte": make_material("matte", rough=.7),
        "water": make_material("water", rough=.2, spec=.3, emit=.35),
        "flame": make_material("flame", rough=.5, emit=2.6),
        "glow": make_material("glow", rough=.5, emit=1.5),
        "ground": make_material("ground", rough=.95, mottle=.05, scale=6),
    }


# ------------------------------------------------------------------ mesh kit

class Kit:
    """Collects one building's geometry by material, in pivot-local coordinates."""

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
        for a, b in zip(pts, pts[1:]):
            self.tube(mat, a, b, r, r, col, n)

    def lathe(self, mat, x, y, z, prof, col, n=18, smooth=True, sx=1., sy=1., m=None):
        pts, cols = [], []
        for r, h in prof:
            for i in range(n):
                t = 2 * math.pi * i / n
                pts.append((r * math.cos(t) * sx, r * math.sin(t) * sy, h))
                cols.append(col(h) if callable(col) else col)
        f = []
        for j in range(len(prof) - 1):
            for i in range(n):
                f.append((j * n + i, j * n + (i + 1) % n, (j + 1) * n + (i + 1) % n, (j + 1) * n + i))
        f += [tuple(reversed(range(n))), tuple(range((len(prof) - 1) * n, len(prof) * n))]
        t = Matrix.Translation((x, y, z))
        self.add(mat, pts, f, cols, smooth, m=t @ m if m else t)

    def ball(self, mat, x, y, z, r, col, n=12, sx=1., sy=1., sz=1.):
        prof = [(max(r * math.sin(math.pi * i / 7), .001), r * sz * (1 - math.cos(math.pi * i / 7))) for i in range(8)]
        self.lathe(mat, x, y, z - r * sz, prof, col, n, True, sx, sy)

    def surface(self, mat, fn, nu, nv, col):
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
        self.add(mat, pts, f, cols, True)

    def poly(self, mat, pts, col, smooth=False):
        self.add(mat, pts, [tuple(range(len(pts)))], col, smooth)

    # ---- masonry

    def wall(self, a, b, z0, z1, t=.24, course=.34, length=.62, col=None, mat="stone"):
        """Big running-bond blocks from a to b. Walking counter-clockwise puts inside on the left."""
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
                off = R.uniform(-.012, .012)
                nx, ny = math.sin(ang), -math.cos(ang)
                self.box(mat, mid.x + nx * off, mid.y + ny * off, z0 + i * ch, s1 - s0, t, ch,
                         col() if callable(col) else (J(col, .03) if col else sand()), ang)

    def ring(self, x, y, z0, z1, r, t=.28, course=.34, stone=.66, col=None):
        n = max(1, round((z1 - z0) / course))
        ch = (z1 - z0) / n
        count = max(6, round(2 * math.pi * r / stone))
        da = 2 * math.pi / count
        w = 2 * r * math.tan(da / 2)
        for i in range(n):
            for j in range(count):
                a = (j + (.5 if i % 2 else 0)) * da
                self.box("stone", x + r * math.cos(a), y + r * math.sin(a), z0 + i * ch, t, w, ch,
                         col() if callable(col) else (J(col, .03) if col else sand()), a)

    def arch(self, cx, cz, r, thick, depth, col=None, n=7, y=0., mat="stone"):
        """Voussoirs in the frame's XZ plane; call inside k.at(wall frame)."""
        for i in range(n):
            a0, a1 = math.pi * i / n, math.pi * (i + 1) / n
            ri, ro = r, r + thick
            p = [(math.cos(a0) * ri, math.sin(a0) * ri), (math.cos(a1) * ri, math.sin(a1) * ri),
                 (math.cos(a1) * ro, math.sin(a1) * ro), (math.cos(a0) * ro, math.sin(a0) * ro)]
            v = []
            for d in (y - depth / 2, y + depth / 2):
                for px, pz in p:
                    v.append((cx + px, d, cz + pz))
            f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
            self.add(mat, v, f, col() if callable(col) else (J(col, .03) if col else sand()))

    def arch_fill(self, cx, z0, zs, r, col, y=0., mat="glow", n=14):
        p = [(cx - r, y, z0), (cx + r, y, z0)]
        for i in range(n + 1):
            a = math.pi * i / n
            p.append((cx + r * math.cos(a), y, zs + r * math.sin(a)))
        self.poly(mat, p, col)

    def window(self, s, z0, zs, r, fill=GLOW, fill_mat="glow", trim=SAND_PALE, trim_mat="stone", y=0.):
        """A chunky arched opening mounted on a wall face; the frame's -y points outside."""
        self.arch_fill(s, z0, zs, r, fill, y=y - .03, mat=fill_mat)
        self.arch(s, zs, r, .12, .1, col=trim, y=y - .04, mat=trim_mat)
        for side in (-1, 1):
            self.box(trim_mat, s + side * (r + .06), y - .04, z0, .12, .1, zs - z0, trim)
        self.box(trim_mat, s, y - .05, z0 - .08, 2 * r + .32, .14, .09, trim)

    def pane(self, mat, a, b, c, d, col, size=.38, lift=.04):
        """Big overlapping tiles on quad a-b (eave) to d-c (ridge), over a deck."""
        a, b, c, d = map(Vector, (a, b, c, d))
        nrm = (b - a).cross(d - a).normalized()
        if nrm.z < 0:
            nrm = -nrm
        self.poly(mat, [tuple(a), tuple(b), tuple(c), tuple(d)], tuple(k * .5 for k in (col() if callable(col) else col)))
        rows = max(2, round((d - a).length / (size * .8)))
        for i in range(rows):
            t0, t1 = i / rows, min(1, (i + 1.2) / rows)
            l0, r0 = a.lerp(d, t0), b.lerp(c, t0)
            l1, r1 = a.lerp(d, t1), b.lerp(c, t1)
            cols = max(1, round((r0 - l0).length / size))
            off = .5 if i % 2 else 0
            for j in range(cols + (1 if off else 0)):
                u0, u1 = max(0, (j - off) / cols), min(1, (j + 1 - off) / cols)
                if u1 <= u0:
                    continue
                p = [l0.lerp(r0, u0), l0.lerp(r0, u1), l1.lerp(r1, u1), l1.lerp(r1, u0)]
                th = lift + .02
                v = [tuple(q + nrm * .005) for q in p] + \
                    [tuple(p[0] + nrm * (th + .035)), tuple(p[1] + nrm * (th + .035)),
                     tuple(p[2] + nrm * th), tuple(p[3] + nrm * th)]
                f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
                self.add(mat, v, f, col() if callable(col) else J(col, .04))

    def hip_roof(self, cx, cy, z, sx, sy, h, mat, col, cap, size=.38):
        hx, hy = sx / 2, sy / 2
        rx, ry = max(hx - hy, .02), max(hy - hx, .02)
        e = [Vector((cx + px, cy + py, z)) for px, py in ((-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy))]
        r = [Vector((cx + px, cy + py, z + h)) for px, py in ((-rx, -ry), (rx, -ry), (rx, ry), (-rx, ry))]
        for i in range(4):
            j = (i + 1) % 4
            self.pane(mat, e[i], e[j], r[j], r[i], col, size=size)
        lift = Vector((0, 0, .06))
        for i in range(4):
            self.beam(cap[0], e[i] + lift, r[i] + lift, .13, .1, cap[1])
            if (r[i] - r[(i + 1) % 4]).length > .2:
                self.beam(cap[0], r[i] + lift, r[(i + 1) % 4] + lift, .14, .12, cap[1])
            self.beam(cap[0], e[i] - lift * .6, e[(i + 1) % 4] - lift * .6, .12, .1, cap[1])
        self.box(cap[0], cx, cy, z + h, 2 * rx + .26, 2 * ry + .26, .12, cap[1])
        return r

    def prism(self, mat, pts, x0, x1, col):
        """Extrudes a polygon, counter-clockwise in (y, z), along x."""
        n = len(pts)
        v = [(x0, y, z) for y, z in pts] + [(x1, y, z) for y, z in pts]
        f = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        f += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.add(mat, v, f, col)

    # ---- plants

    def fit(self, x, y, reach):
        """Moves a plant inward so its reach stays on the footprint."""
        p = self.xf @ Vector((x, y, 0))
        lim_x, lim_y = max(self.w / 2 - reach, 0), max(self.h / 2 - reach, 0)
        q = Vector((max(-lim_x, min(lim_x, p.x)), max(-lim_y, min(lim_y, p.y)), 0))
        q = self.xf.inverted() @ q
        return q.x, q.y

    def blob(self, x, y, z, r):
        base = J(R.choice(LEAVES), .04)
        self.ball("leaf", x, y, z, r, lambda h: tuple(c * (.6 + .6 * h / (2 * r)) for c in base), 16)

    def puff(self, x, y, z, r=.25):
        """A rounded shrub: a few big soft balls."""
        r *= 1.25
        x, y = self.fit(x, y, r * 1.17)
        for i in range(3):
            a = 2 * math.pi * i / 3 + R.uniform(0, 1)
            self.blob(x + r * .45 * math.cos(a), y + r * .45 * math.sin(a), z + r * .55, r * .72)
        self.blob(x, y, z + r * 1.05, r * .75)

    def palm(self, x, y, z, h=1., L=.5, fronds=6):
        x, y = self.fit(x, y, L * 1.02)
        top = Vector((x, y, z + h))
        self.tube("wood", (x, y, z), tuple(top), .09, .06, WOOD, 10)
        for i in range(fronds):
            a = 2 * math.pi * i / fronds + R.uniform(-.15, .15)
            out = Vector((math.cos(a), math.sin(a), 0))
            side = Vector((-out.y, out.x, 0))
            base = J(R.choice(LEAVES), .04)
            def fn(u, v, out=out, side=side):
                w = L * .24 * math.sin(math.pi * min(v * .92 + .08, 1))
                p = top + out * L * v + Vector((0, 0, L * (.32 * v - .8 * v * v)))
                q = p + side * (u - .5) * 2 * w - Vector((0, 0, abs(u - .5) * w * .6))
                return tuple(q)
            self.surface("leaf", fn, 2, 7, lambda u, v, base=base: tuple(c * (.72 + .4 * (1 - abs(u - .5) * 2)) for c in base))
        self.blob(top.x, top.y, top.z, .08)

    # ---- props

    def flame(self, x, y, z, s=.14, light=3.):
        prof = [(max(s * .7 * math.sin(math.pi * min(t * 1.5, 1) ** .7) * (1 - t) ** .55, .001), s * 2.2 * t) for t in [i / 9 for i in range(10)]]
        self.lathe("flame", x, y, z, prof, lambda h: FLAME if h < s * .7 else FLAME_L, 12)
        if light:
            self.lights.append(((x, y, z + s), light))

    def brazier(self, x, y, z, h=.3):
        self.box("stone", x, y, z, .28, .28, h, J(SAND_PALE, .03))
        self.lathe("gold", x, y, z + h, [(.08, 0), (.2, .12), (.22, .17), (.16, .17)], GOLD, 16)
        self.flame(x, y, z + h + .13)

    def crate(self, x, y, z, s, h=None, rz=0.):
        h = h or s
        self.box("wood", x, y, z, s, s, h, J(WOOD_L, .05), rz)
        self.box("wood", x, y, z + h, s + .05, s + .05, .06, WOOD, rz)

    def basket(self, x, y, z, r=.2):
        self.lathe("matte", x, y, z, [(r * .62, 0), (r, r * .55), (r * 1.05, r * .85), (r * .85, r * .8)], J(BASKET, .05), 16)
        col = R.choice(FRUIT)
        for i in range(3):
            a = 2 * math.pi * i / 3
            self.ball("matte", x + r * .42 * math.cos(a), y + r * .42 * math.sin(a), z + r * .85, r * .4, J(col, .05), 12)

    def emblem(self, s, y, z, r, col=GOLD):
        star = []
        for i in range(8):
            a = math.pi * i / 4
            d = r if i % 2 == 0 else r * .38
            star.append((s + d * math.cos(a), y, z + d * math.sin(a)))
        self.poly("gold", star, col)

    def banner(self, s, z_top, w, h, y=-.03, col=TEAL):
        """Hangs on a wall frame's outside (local -y)."""
        self.box("cloth", s, y, z_top - h, w, .04, h, col)
        self.box("cloth", s, y - .005, z_top - h, w, .05, .08, GOLD)
        self.box("wood", s, y, z_top, w + .14, .07, .07, WOOD_D)
        self.emblem(s, y - .03, z_top - h * .5, w * .3)

    def pillar(self, x, y, z, h, s=.46):
        self.box("stone", x, y, z, s * 1.2, s * 1.2, .18, sand())
        self.box("stone", x, y, z + .18, s, s, h - .18, sand())
        pz, ph = z + .3, h - .42
        self.box("glaze", x, y - s / 2 - .01, pz, s * .68, .04, ph, TEAL)
        self.box("glaze", x + s / 2 + .01, y, pz, .04, s * .68, ph, TEAL)
        self.box("gold", x, y, z + h, s * 1.12, s * 1.12, .07, GOLD)
        self.box("glaze", x, y, z + h + .07, s * .86, s * .86, .2, TEAL)
        self.box("gold", x, y, z + h + .27, s * .98, s * .98, .07, GOLD)

    def awning(self, x0, x1, y0, y1, z0, z1, cols, n=6, hang=.2):
        """Wide sloped boards from a low front edge to a high back, each ending in a tab."""
        w = (x1 - x0) / n
        for i in range(n):
            x = x0 + (i + .5) * w
            col = cols[i % len(cols)]
            self.beam("cloth", (x, y0, z0), (x, y1, z1), w * 1.01, .09, col)
            self.box("cloth", x, y0, z0 - hang, w * .98, .09, hang, col)


def wall_frame(a, b):
    """x along a->b, y to the inside when walking counter-clockwise, z up."""
    a, b = Vector(a), Vector(b)
    ang = math.atan2(b.y - a.y, b.x - a.x)
    return Matrix.Translation((a.x, a.y, 0)) @ Matrix.Rotation(ang, 4, "Z")

def radial_frame(cx, cy, r, a):
    """Faces out of a circle at angle a: local -y points outward."""
    return Matrix.Translation((cx + r * math.cos(a), cy + r * math.sin(a), 0)) @ Matrix.Rotation(a + math.pi / 2, 4, "Z")


# ------------------------------------------------------------------ assembly

G = .1   # top of the base slab


def to_object(name, bucket, mat, materials, coll, parent):
    me = bpy.data.meshes.new(name)
    me.from_pydata(bucket["v"], [], bucket["f"])
    me.update()
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


def _sun(scene, name, energy, angle, color, direction):
    light = bpy.data.lights.new(name, "SUN")
    light.energy, light.angle, light.color = energy, math.radians(angle), color
    ob = bpy.data.objects.new(name, light)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector(direction).to_track_quat("-Z", "Y")
    scene.collection.objects.link(ob)


def assemble(scene_name, items, builders, blend, slab=None, slab_color=None, model_scale=None, extra_materials=None, light_color=(1, .62, .28)):
    """Build every item (dicts with key, title, w, h) with builders[key] and save blend.

    slab(item) says which items stand on the shared base slab; the rest stand on grass.
    model_scale(item, reach) enlarges a model about its pivot, bevels and lights included,
    while its footprint and base width stay those of its size. reach is how far the
    model extends from its pivot along either ground axis, in tiles.
    The Blender file holds one scene. Everything in it is rebuilt from code."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = scene_name
    materials = make_materials()
    materials.update(extra_materials() if extra_materials else {})
    root = bpy.data.collections.new("buildings")
    scene.collection.children.link(root)

    u, v, row_h = 0, 0, 0
    for i, it in enumerate(items):
        R.seed(7 + i)
        k = Kit(it["w"], it["h"])
        if slab is None or slab(it):
            k.box("slab", 0, 0, 0, it["w"], it["h"], G, slab_color or SLAB)   # the base: exactly the footprint
        builders[it["key"]](k)
        for b in k.buckets.values():   # nothing may leave the footprint
            b["v"] = [(max(-it["w"] / 2, min(it["w"] / 2, p[0])), max(-it["h"] / 2, min(it["h"] / 2, p[1])), p[2]) for p in b["v"]]
        coll = bpy.data.collections.new(it["key"])
        root.children.link(coll)
        if u + it["w"] > 40:   # shelves of buildings, whole tiles apart, for browsing the scene
            u, v, row_h = 0, v + row_h + 2, 0
        pivot = bpy.data.objects.new(it["key"] + ".pivot", None)
        pivot.location = (u + it["w"] / 2, -(v + it["h"] / 2), 0)
        pivot.empty_display_size = .25
        reach = max((max(abs(p[0]), abs(p[1])) for b in k.buckets.values() for p in b["v"]), default=0)
        scale = model_scale(it, reach) if model_scale else 1.
        pivot.scale = (scale,) * 3   # children (meshes, lights) inherit it
        pivot["title"], pivot["w"], pivot["h"] = it["title"], it["w"], it["h"]
        coll.objects.link(pivot)
        u, row_h = u + it["w"] + 2, max(row_h, it["h"])
        for mat, bucket in k.buckets.items():
            to_object(it["key"] + "." + mat, bucket, mat, materials, coll, pivot)
        for p, watts in k.lights:
            light = bpy.data.lights.new(it["key"] + ".light", "POINT")
            # the same light on the surfaces at the scaled distance
            light.energy, light.color, light.shadow_soft_size = watts * scale ** 2, light_color, .06
            ob = bpy.data.objects.new(it["key"] + ".light", light)
            ob.location, ob.parent = p, pivot
            coll.objects.link(ob)

    cam = bpy.data.cameras.new("city_camera")
    cam.type = "ORTHO"
    cam.clip_start, cam.clip_end = .1, 500
    camera = bpy.data.objects.new("city_camera", cam)
    camera.rotation_euler = city_camera.ROTATION
    scene.collection.objects.link(camera)
    scene.camera = camera
    _sun(scene, "sun", 2.7, 7, (1, .93, .8), (.34, 1.0, -1.3))
    _sun(scene, "fill", .7, 40, (1, .88, .72), (-1.0, .35, -.7))
    world = bpy.data.worlds.new("sky")
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (.62, .72, .95, 1)
    bg.inputs[1].default_value = .62
    scene.world = world
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.engine = "CYCLES"
    Path(blend).parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0   # no .blend1 beside the master
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    print(f"Built {len(items)} buildings into {blend}")


def blend_argument(default):
    """The .blend path tools/buildings.py passes after --, or the game's own."""
    return sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else str(default)
