# Relic Rush buildings rebuilt as procedural Blender geometry on the game's grid.
#
# Convention (docs/BUILDINGS.md, engine/city.c):
#   1 Blender unit = 1 tile side. World X = tile u (down-right on screen, the
#   front-left side, size.w). World Y = -tile v (up-right, the front-right side,
#   size.h). Pivot = footprint centre at z = 0. Footprints sit on whole tiles.
#
# The camera is orthographic at 30 degrees elevation, which projects ground
# slopes to exactly +-0.5: the game's 2:1 grid, not 35.26 degree true isometric.
#
# Run inside Blender: runpy.run_path(this_file) (REPORT holds the checks).
import json
import math
import os
import random

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(globals().get("__file__", "."))) if "__file__" in globals() else "."
SCENE_NAME = "RelicRushIso"
TILE_W, TILE_H = 120, 60                       # one tile on screen, in pixels
PPU = TILE_W / math.sqrt(2)                    # pixels per Blender unit
Z_PX = PPU * math.cos(math.radians(30))        # pixels per unit of height
R = random.Random(7)


# ------------------------------------------------------------------ palette

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
GRASS_A, GRASS_B, GRID = C("#5B8A3E"), C("#527F39"), C("#3F6A2C")
LINE = C("#FFF3C4")

def sand():
    return J(R.choice(SANDS), .025)


# ------------------------------------------------------------------ materials

# Bevels do the soft, toy-like edges; they are wide on purpose.
BEVELS = {"stone": (.04, 3), "wood": (.03, 2), "clay": (.03, 2), "glaze": (.028, 2),
          "gold": (.022, 2), "slab": (.04, 3), "cloth": (.025, 2)}

def make_material(name, rough=.7, metal=0., spec=.4, emit=0., bump=0., scale=20., mottle=0.):
    m = bpy.data.materials.new("rr_" + name)
    m.use_nodes = True
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    a = nt.nodes.new("ShaderNodeAttribute")
    a.attribute_name = "col"
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    p.inputs["Specular IOR Level"].default_value = spec
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


# ------------------------------------------------------------------ buildings
#
# Casual style: few, big, soft shapes. A building reads at a glance from its
# silhouette and two or three colours; nothing smaller than about a tenth of a tile.

G = .1   # top of the base slab

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
    Y, zc, r = .56, G, .68
    def top(x):
        return G + .22 + .86 * math.cos(math.pi * min(abs(x), 1.5) / 3.)
    # solid core between the arch and the deck
    for i in range(30):
        x = -1.55 + 3.1 * (i + .5) / 30
        lo = zc + math.sqrt(max(r * r - x * x, 0)) + .02
        if top(x) - .06 > lo:
            k.box("stone", x, 0, lo, 3.1 / 30 * 1.02, 2 * Y - .1, top(x) - .06 - lo, SAND_DK)
    # big blocks on both faces
    for y in (-Y, Y):
        for i in range(4):
            z = G + i * .32
            zm = z + .16
            x = -1.58 + (.3 if i % 2 else 0)
            while x < 1.58:
                l = .6 * R.uniform(.9, 1.1)
                xm = x + l / 2
                if zm < top(xm) - .05 and math.hypot(xm, zm - zc) > r + .2:
                    k.box("stone", xm, y, z, l, .2, .32, sand())
                x += l
        with k.at(Matrix.Translation((0, y, 0))):
            k.arch(0, zc, r, .24, .28, n=7, col=SAND_PALE)
    # deck: three rows of big slabs
    n = 9
    for i in range(n):
        x0, x1 = -1.6 + 3.2 * i / n, -1.6 + 3.2 * (i + 1) / n
        z0, z1 = top(x0), top(x1)
        ang, L = math.atan2(z1 - z0, x1 - x0), math.hypot(x1 - x0, z1 - z0) * 1.03
        for ry, wy, kerb in ((-.46, .26, True), (0, .68, False), (.46, .26, True)):
            with k.at(Matrix.Translation(((x0 + x1) / 2, ry, (z0 + z1) / 2)) @ Matrix.Rotation(-ang, 4, "Y")):
                if not kerb and i == n // 2:
                    k.box("glaze", 0, 0, -.14, L, wy, .17, TEAL)
                else:
                    k.box("stone", 0, 0, -.16, L, wy, .2 + (.09 if kerb else 0), J(SAND_PALE, .03) if kerb else sand())
    for s in (-1, 1):
        k.box("stone", s * 1.58, 0, G, .26, 2 * Y - .06, .2, sand())
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.pillar(sx * 1.7, sy * .72, G, .86)
    k.puff(0, .84, G, .22)
    k.puff(1.08, -.86, G, .13)
    k.puff(-1.1, -.86, G, .13)


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


BUILDINGS = [
    # key, title, w, h, game size, builder  (rows as in art/buildings.png)
    ("camp", "Expedition camp", 2, 2, "2x2", camp),
    ("well", "Spring well", 2, 2, "2x2", well),
    ("workshop", "Artisan workshop", 3, 2, "3x2", workshop),
    ("market", "Jungle market", 3, 2, "3x2", market),
    ("gateway", "Sunstone gateway", 4, 2, "3x2", gateway),
    ("lodge", "Explorer's lodge", 3, 3, "3x2", lodge),
    ("archive", "Lost-world archive", 3, 3, "2x2", archive),
    ("observatory", "Star observatory", 2, 2, "2x2", observatory),
    ("fountain", "Jade fountain", 3, 3, "2x2", fountain),
    ("temple", "Temple of the sun", 4, 4, "3x3", temple),
]
ROW_COUNT = 5     # buildings per row
ROW_STEP = 6      # tiles along both u and v between rows: straight down on screen
SECTION_PAD = 2   # image margin around the buildings, in tiles


# ------------------------------------------------------------------ assembly

def layout():
    """Whole-tile footprints with a tile of open ground between neighbours."""
    out = []
    rows = [BUILDINGS[i:i + ROW_COUNT] for i in range(0, len(BUILDINGS), ROW_COUNT)]
    for r, row in enumerate(rows):
        # walk right on screen: +u, -v; each step clears the previous footprint by a tile
        u0, starts = 0, []
        for key, title, w, h, game, fn in row:
            starts.append(u0)
            u0 += w + 1
        mid = (starts[0] + starts[-1] + row[-1][2]) // 2   # centres the row on the origin
        for u0, (key, title, w, h, game, fn) in zip(starts, row):
            u0 -= mid
            v0 = math.floor(-(u0 + w / 2) - h / 2 + .5)
            u0 += r * ROW_STEP
            v0 += r * ROW_STEP
            out.append(dict(key=key, title=title, w=w, h=h, game=game, fn=fn, u0=u0, v0=v0, cu=u0 + w / 2, cv=v0 + h / 2))
    for a in out:
        for b in out:
            if a is b:
                continue
            gap_u = max(b["u0"] - (a["u0"] + a["w"]), a["u0"] - (b["u0"] + b["w"]))
            gap_v = max(b["v0"] - (a["v0"] + a["h"]), a["v0"] - (b["v0"] + b["h"]))
            assert max(gap_u, gap_v) >= 1, (a["key"], b["key"])
    return out


def to_object(name, kit_bucket, mat, materials, coll, parent):
    me = bpy.data.meshes.new("rr_" + name)
    me.from_pydata(kit_bucket["v"], [], kit_bucket["f"])
    me.update()
    attr = me.color_attributes.new("col", "FLOAT_COLOR", "POINT")
    flat = []
    for c in kit_bucket["c"]:
        flat.extend((c[0], c[1], c[2], 1))
    attr.data.foreach_set("color", flat)
    me.polygons.foreach_set("use_smooth", [True] * len(kit_bucket["s"]) if mat in BEVELS else kit_bucket["s"])
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


def ground(coll, materials, umin, umax, vmin, vmax):
    b = {"v": [], "f": [], "c": [], "s": []}
    def quad(x0, y0, x1, y1, z, col):
        i = len(b["v"])
        b["v"] += [(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)]
        b["f"].append((i, i + 1, i + 2, i + 3))
        b["c"] += [col] * 4
        b["s"].append(False)
    for u in range(umin, umax):
        for v in range(vmin, vmax):
            col = GRASS_A if (u + v) % 2 else GRASS_B
            quad(u, -v - 1, u + 1, -v, 0, tuple(c * R.uniform(.97, 1.03) for c in col))
    lw = .007
    for u in range(umin, umax + 1):
        quad(u - lw, -vmax, u + lw, -vmin, .0015, GRID)
    for v in range(vmin, vmax + 1):
        quad(umin, -v - lw, umax, -v + lw, .0015, GRID)
    return to_object("ground", b, "ground", materials, coll, None)


def footprint_lines(coll, materials, items):
    b = {"v": [], "f": [], "c": [], "s": []}
    def quad(x0, y0, x1, y1):
        i = len(b["v"])
        b["v"] += [(x0, y0, .003), (x1, y0, .003), (x1, y1, .003), (x0, y1, .003)]
        b["f"].append((i, i + 1, i + 2, i + 3))
        b["c"] += [LINE] * 4
        b["s"].append(False)
    t = .03
    for it in items:
        x0, x1, y0, y1 = it["u0"], it["u0"] + it["w"], -(it["v0"] + it["h"]), -it["v0"]
        quad(x0 - t, y0 - t, x1 + t, y0)
        quad(x0 - t, y1, x1 + t, y1 + t)
        quad(x0 - t, y0, x0, y1)
        quad(x1, y0, x1 + t, y1)
    return to_object("footprints", b, "matte", materials, coll, None)


def clean_previous():
    old = bpy.data.scenes.get(SCENE_NAME)
    if old:
        bpy.data.scenes.remove(old)
    for ob in list(bpy.data.objects):
        if ob.get("rr_iso"):
            bpy.data.objects.remove(ob)
    for coll in list(bpy.data.collections):
        if coll.name.startswith("rr_"):
            bpy.data.collections.remove(coll)
    for me in list(bpy.data.meshes):
        if me.name.startswith("rr_") and me.users == 0:
            bpy.data.meshes.remove(me)
    for ma in list(bpy.data.materials):
        if ma.name.startswith("rr_") and ma.users == 0:
            bpy.data.materials.remove(ma)


def build(tile_w=TILE_W):
    clean_previous()
    R.seed(7)
    scn = bpy.data.scenes.new(SCENE_NAME)
    materials = make_materials()
    root = bpy.data.collections.new("rr_buildings")
    scn.collection.children.link(root)
    env = bpy.data.collections.new("rr_ground")
    scn.collection.children.link(env)

    items = layout()
    for it in items:
        k = Kit(it["w"], it["h"])
        k.box("slab", 0, 0, 0, it["w"], it["h"], G, SLAB)   # the base: exactly the footprint
        it["fn"](k)
        for b in k.buckets.values():
            b["v"] = [(max(-it["w"] / 2, min(it["w"] / 2, v[0])), max(-it["h"] / 2, min(it["h"] / 2, v[1])), v[2]) for v in b["v"]]
        it["kit"] = k
        it["top"] = max(v[2] for b in k.buckets.values() for v in b["v"])

    # image bounds from the real geometry, on whole half tiles from the grid origin
    xs, ys = [], []
    for it in items:
        for u, v in ((it["u0"], it["v0"]), (it["u0"] + it["w"], it["v0"]), (it["u0"], it["v0"] + it["h"]), (it["u0"] + it["w"], it["v0"] + it["h"])):
            xs.append((u - v) * TILE_W / 2)
            ys.append((u + v) * TILE_H / 2)
            ys.append((u + v) * TILE_H / 2 - it["top"] * Z_PX)
    pad = SECTION_PAD * TILE_W / 2
    px0 = math.floor((min(xs) - pad) / (TILE_W / 2)) * TILE_W / 2
    px1 = math.ceil((max(xs) + pad) / (TILE_W / 2)) * TILE_W / 2
    py0 = math.floor((min(ys) - pad * .6) / (TILE_H / 2)) * TILE_H / 2
    py1 = math.ceil((max(ys) + pad * .6) / (TILE_H / 2)) * TILE_H / 2
    res_x, res_y = int(px1 - px0), int(py1 - py0)

    corners = [(px0, py0), (px1, py0), (px0, py1), (px1, py1)]
    us = [(x / (TILE_W / 2) + y / (TILE_H / 2)) / 2 for x, y in corners]
    vs = [(y / (TILE_H / 2) - x / (TILE_W / 2)) / 2 for x, y in corners]
    umin, umax = math.floor(min(us)) - 1, math.ceil(max(us)) + 1
    vmin, vmax = math.floor(min(vs)) - 1, math.ceil(max(vs)) + 1
    ground(env, materials, umin, umax, vmin, vmax)
    footprint_lines(env, materials, items)

    report = {"buildings": [], "resolution": [res_x, res_y]}
    for it in items:
        k = it["kit"]
        loc = (it["cu"], -it["cv"], 0)
        coll = bpy.data.collections.new("rr_" + it["key"])
        root.children.link(coll)
        pivot = bpy.data.objects.new(it["key"] + ".pivot", None)
        pivot.location = loc
        pivot.empty_display_size = .25
        coll.objects.link(pivot)
        over = {"solid": 0., "plants": 0.}
        for mat, bucket in k.buckets.items():
            to_object(it["key"] + "." + mat, bucket, mat, materials, coll, pivot)
            kind = "plants" if mat == "leaf" else "solid"
            for v in bucket["v"]:
                over[kind] = max(over[kind], abs(v[0]) - it["w"] / 2, abs(v[1]) - it["h"] / 2)
        for p, watts in k.lights:
            li = bpy.data.lights.new("rr_" + it["key"] + "_light", "POINT")
            li.energy = watts
            li.color = (1, .62, .28)
            li.shadow_soft_size = .06
            lo = bpy.data.objects.new(it["key"] + ".light", li)
            lo.location = p
            lo.parent = pivot
            coll.objects.link(lo)
        report["buildings"].append(dict(key=it["key"], title=it["title"], w=it["w"], h=it["h"], game=it["game"],
                                        u0=it["u0"], v0=it["v0"], overhang=over, top=round(it["top"], 3),
                                        verts=sum(len(b["v"]) for b in k.buckets.values())))

    # camera: orthographic, 30 degrees above the ground, so tiles land on exact 2:1 diamonds
    cam = bpy.data.cameras.new("rr_iso_cam")
    cam.type = "ORTHO"
    cam.ortho_scale = max(res_x, res_y) / PPU
    cam.clip_start, cam.clip_end = .1, 400
    co = bpy.data.objects.new("iso_camera", cam)
    co.rotation_euler = (math.radians(60), 0, math.radians(45))
    scn.collection.objects.link(co)
    rot = co.rotation_euler.to_matrix()
    right, up, back = rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0)), rot @ Vector((0, 0, 1))
    cx, cy = (px0 + px1) / 2, (py0 + py1) / 2
    # the world point at the image centre, in the ground plane
    centre = right * (cx / PPU) + up * (-cy / PPU)
    co.location = centre + back * 120
    scn.camera = co

    # light
    sun = bpy.data.lights.new("rr_sun", "SUN")
    sun.energy = 2.7
    sun.angle = math.radians(7)
    sun.color = (1, .93, .8)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_mode = "QUATERNION"
    so.rotation_quaternion = Vector((.34, 1.0, -1.3)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(so)
    fill = bpy.data.lights.new("rr_fill", "SUN")
    fill.energy = .7
    fill.angle = math.radians(40)
    fill.color = (1, .88, .72)
    fo = bpy.data.objects.new("fill", fill)
    fo.rotation_mode = "QUATERNION"
    fo.rotation_quaternion = Vector((-1.0, .35, -.7)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(fo)
    w = bpy.data.worlds.new("rr_world")
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (.62, .72, .95, 1)
    bg.inputs[1].default_value = .62
    scn.world = w

    # render
    scn.render.engine = "CYCLES"
    scn.render.resolution_x, scn.render.resolution_y = res_x, res_y
    scn.render.resolution_percentage = 100
    scn.render.film_transparent = False
    scn.cycles.device = "GPU"
    scn.cycles.samples = 64
    scn.cycles.use_adaptive_sampling = True
    scn.cycles.adaptive_threshold = .02
    scn.cycles.use_denoising = True
    scn.cycles.filter_width = 1.0
    scn.cycles.max_bounces = 5
    scn.cycles.caustics_reflective = False
    scn.cycles.caustics_refractive = False
    scn.view_settings.view_transform = "Standard"
    scn.view_settings.look = "None"

    # checks: the projection of every grid corner against the analytic 2:1 formula
    scn.view_layers[0].update()
    for ob in scn.objects:
        ob["rr_iso"] = True
    errs = []
    for u, v in [(umin + 3, vmin + 3), (0, 0), (umax - 3, vmax - 3), (umin + 3, vmax - 3), (umax - 3, vmin + 3), (7, -2)]:
        p = world_to_camera_view(scn, co, Vector((u, -v, 0)))
        px, py = p.x * res_x, (1 - p.y) * res_y
        ax = (u - v) * TILE_W / 2 - px0
        ay = (u + v) * TILE_H / 2 - py0
        errs.append(max(abs(px - ax), abs(py - ay)))
    report["grid_max_error_px"] = round(max(errs), 5)
    p0 = world_to_camera_view(scn, co, Vector((0, 0, 0)))
    p1 = world_to_camera_view(scn, co, Vector((1, 0, 0)))
    dx, dy = (p1.x - p0.x) * res_x, (p1.y - p0.y) * res_y
    report["tile_edge_px"] = [round(dx, 4), round(dy, 4)]
    report["slope"] = round(abs(dy / dx), 5)
    report["origin_px"] = [-px0, -py0]
    report["tile_px"] = [TILE_W, TILE_H]
    report["z_px"] = round(Z_PX, 3)
    report["items"] = [{k_: v_ for k_, v_ in it.items() if k_ not in ("fn", "kit")} for it in items]
    return scn, report


def activate(scn):
    for win in bpy.context.window_manager.windows:
        win.scene = scn


if True:
    OUT = os.environ.get("RR_ISO_OUT") or globals().get("OUT_DIR") or HERE
    SCN, REPORT = build()
    activate(SCN)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "scene_layout.json"), "w") as f:
        json.dump(REPORT, f, indent=1)
