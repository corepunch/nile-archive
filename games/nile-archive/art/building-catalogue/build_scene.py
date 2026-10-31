# Nile Archive buildings and decorations as procedural Blender geometry on the game's grid.
#
# The mesh kit, materials, camera and lighting follow Relic Rush's master
# (games/relic-rush/art/building-catalogue/build_scene.py) so both games render
# the same way; the palette and the 96 objects are Nile Archive's own.
#
# Convention (docs/BUILDINGS.md, engine/city.c):
#   1 Blender unit = 1 tile side. World X = tile u (down-right on screen, the
#   front-left side, size.w). World Y = -tile v (up-right, the front-right side,
#   size.h). Pivot = footprint centre at z = 0. Footprints sit on whole tiles.
#   The visible faces point to +X (front right) and -Y (front left).
#
# The camera is orthographic at 30 degrees elevation, which projects ground
# slopes to exactly +-0.5: the game's 2:1 grid, not 35.26 degree true isometric.
#
# Run: blender -b --python build_scene.py   (or python with the bpy module)
import json
import math
import os
import random

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(globals().get("__file__", "."))) if "__file__" in globals() else "."
SCENE_NAME = "NileArchiveIso"
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
    m = bpy.data.materials.new("na_" + name)
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
G = .1                # top of the base slab

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


# The catalogue is the list of what exists: name, category, footprint, price, unlock.
with open(os.path.join(HERE, "catalogue.json")) as f:
    CATALOGUE = [dict(zip(("key", "title", "cat", "w", "h", "gold", "stars", "like"), row)) for row in json.load(f)]
BASED = ("wonder", "building")   # these stand on a slab; decorations stand on the grass
# One-tile decorations are modelled at 1x and then scaled about their ground
# pivot, bevels and lights included, so they read beside the island painting.
# At 2x a 1 x 1 object fills its tile plus Nile Archive's clearance ring
# (city.clearance = size2(1, 1): half a tile of reserved ground on each side),
# so it reaches the ring's edge but never a neighbour's base. Its footprint,
# base_width and price stay those of one tile.
DECOR_SCALE = 2.0

def model_scale(it):
    return DECOR_SCALE if it["cat"] not in BASED and it["w"] == it["h"] == 1 else 1.0
ROW_PX = 3840                    # image width the rows wrap at
SECTION_PAD = 2                  # image margin around everything, in tiles


# ------------------------------------------------------------------ assembly

def layout(items):
    """Whole-tile footprints in rows across the screen, a tile of open ground between neighbours.
    A row moves down far enough that the tallest thing in it clears the row behind, label included."""
    rows, row, width = [], [], 0
    for it in items:
        step = (it["w"] + it["h"] + 2) * TILE_W / 2
        starts_section = row and (it["cat"] in BASED) != (row[-1]["cat"] in BASED)
        if row and (width + step > ROW_PX or starts_section or it["cat"] != row[-1]["cat"] and it["cat"] in BASED):
            rows.append(row)
            row, width = [], 0
        row.append(it)
        width += step
    rows.append(row)
    base, front_prev = 0, None
    for row in rows:
        top = max(it["top"] * Z_PX for it in row)
        if front_prev is not None:
            need = front_prev + top + 44
            base += math.ceil(need / TILE_H)
        u0, starts = 0, []
        for it in row:
            starts.append(u0)
            u0 += it["w"] + 1
        mid = (starts[0] + starts[-1] + row[-1]["w"]) // 2
        for u0, it in zip(starts, row):
            u0 -= mid
            it["u0"] = u0 + base
            it["v0"] = math.floor(-(u0 + it["w"] / 2) - it["h"] / 2 + .5) + base
            it["cu"], it["cv"] = it["u0"] + it["w"] / 2, it["v0"] + it["h"] / 2
        front_prev = max((it["w"] + it["h"]) * TILE_H / 2 for it in row)
    for a in items:
        for b in items:
            if a is b:
                continue
            gap_u = max(b["u0"] - (a["u0"] + a["w"]), a["u0"] - (b["u0"] + b["w"]))
            gap_v = max(b["v0"] - (a["v0"] + a["h"]), a["v0"] - (b["v0"] + b["h"]))
            assert max(gap_u, gap_v) >= 1, (a["key"], b["key"])
    return items


def to_object(name, kit_bucket, mat, materials, coll, parent):
    me = bpy.data.meshes.new("na_" + name)
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
        if ob.get("na_iso"):
            bpy.data.objects.remove(ob)
    for coll in list(bpy.data.collections):
        if coll.name.startswith("na_"):
            bpy.data.collections.remove(coll)
    for me in list(bpy.data.meshes):
        if me.name.startswith("na_") and me.users == 0:
            bpy.data.meshes.remove(me)
    for ma in list(bpy.data.materials):
        if ma.name.startswith("na_") and ma.users == 0:
            bpy.data.materials.remove(ma)


def build(tile_w=TILE_W):
    clean_previous()
    R.seed(7)
    scn = bpy.data.scenes.new(SCENE_NAME)
    materials = make_materials()
    root = bpy.data.collections.new("na_buildings")
    scn.collection.children.link(root)
    env = bpy.data.collections.new("na_ground")
    scn.collection.children.link(env)

    items = [dict(it) for it in CATALOGUE]
    for i, it in enumerate(items):
        R.seed(7 + i)
        k = Kit(it["w"], it["h"])
        if it["cat"] in BASED:
            k.box("slab", 0, 0, 0, it["w"], it["h"], G, SLAB)   # the base: exactly the footprint
        (BUILDERS.get(it["key"]) or globals()[it["key"]])(k)
        for b in k.buckets.values():
            b["v"] = [(max(-it["w"] / 2, min(it["w"] / 2, v[0])), max(-it["h"] / 2, min(it["h"] / 2, v[1])), v[2]) for v in b["v"]]
        it["kit"] = k
        it["scale"] = model_scale(it)
        it["top"] = max(v[2] for b in k.buckets.values() for v in b["v"]) * it["scale"]
    layout(items)

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
        coll = bpy.data.collections.new("na_" + it["key"])
        root.children.link(coll)
        pivot = bpy.data.objects.new(it["key"] + ".pivot", None)
        pivot.location = loc
        pivot.scale = (it["scale"],) * 3   # children (meshes, lights) inherit it
        pivot.empty_display_size = .25
        coll.objects.link(pivot)
        over = {"solid": 0., "plants": 0.}
        for mat, bucket in k.buckets.items():
            to_object(it["key"] + "." + mat, bucket, mat, materials, coll, pivot)
            kind = "plants" if mat == "leaf" else "solid"
            for v in bucket["v"]:
                over[kind] = max(over[kind], abs(v[0]) - it["w"] / 2, abs(v[1]) - it["h"] / 2)
        for p, watts in k.lights:
            li = bpy.data.lights.new("na_" + it["key"] + "_light", "POINT")
            li.energy = watts * it["scale"] ** 2   # the same light on the surfaces at the scaled distance
            li.color = (1, .62, .28)
            li.shadow_soft_size = .06
            lo = bpy.data.objects.new(it["key"] + ".light", li)
            lo.location = p
            lo.parent = pivot
            coll.objects.link(lo)
        report["buildings"].append(dict(key=it["key"], title=it["title"], cat=it["cat"], w=it["w"], h=it["h"],
                                        u0=it["u0"], v0=it["v0"], scale=it["scale"], overhang=over, top=round(it["top"], 3),
                                        verts=sum(len(b["v"]) for b in k.buckets.values())))

    # camera: orthographic, 30 degrees above the ground, so tiles land on exact 2:1 diamonds
    cam = bpy.data.cameras.new("na_iso_cam")
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
    sun = bpy.data.lights.new("na_sun", "SUN")
    sun.energy = 2.7
    sun.angle = math.radians(7)
    sun.color = (1, .93, .8)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_mode = "QUATERNION"
    so.rotation_quaternion = Vector((.34, 1.0, -1.3)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(so)
    fill = bpy.data.lights.new("na_fill", "SUN")
    fill.energy = .7
    fill.angle = math.radians(40)
    fill.color = (1, .88, .72)
    fo = bpy.data.objects.new("fill", fill)
    fo.rotation_mode = "QUATERNION"
    fo.rotation_quaternion = Vector((-1.0, .35, -.7)).to_track_quat("-Z", "Y")
    scn.collection.objects.link(fo)
    w = bpy.data.worlds.new("na_world")
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
    scn.cycles.device = "CPU"
    scn.cycles.samples = 32
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
        ob["na_iso"] = True
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
    OUT = os.environ.get("NA_ISO_OUT") or globals().get("OUT_DIR") or HERE
    for ob in list(bpy.data.objects):   # the factory cube, light and camera
        if not ob.get("na_iso"):
            bpy.data.objects.remove(ob)
    SCN, REPORT = build()
    activate(SCN)
    for other in list(bpy.data.scenes):
        if other is not SCN:
            bpy.data.scenes.remove(other)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "scene_layout.json"), "w") as f:
        json.dump(REPORT, f, indent=1)
    bpy.context.preferences.filepaths.save_version = 0   # no .blend1 backup beside the master
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "nile_archive_buildings.blend"), compress=True)
