"""The building kits, drawing Scener primitives and modifiers instead of Blender meshes.

make_kit(Base, ...) subclasses a game's kit (tools/building_kit.Kit, or Christmas Market's own) so that the
game's builders run unchanged and every kit call writes one readable element through Scener's writer kit
(orion-ui apps/scener/tools/building_kit.py):

    box                  soft-box / slab utility call, rounded by the material's bevel
    beam, tube           a slab or a circle, extruded, bevelled and tapered
    lathe (ball, disc)   <lathe> of the profile; a sphere is a revolved half circle
    surface              <surface> of its grid points
    at(matrix)           <group pos rot scale>
    a solid the kit builds from vertices (wall courses, voussoirs, roof tiles, prisms, gables, panels)
                         <shape> of its polygon -> <extrude> along the sweep (-> <taper> to an apex)

Colour belongs to the piece. A Gradient becomes its gizmo, <gradient type="uv"> or type="box"; there is no
per-vertex colour. The base kit still collects its meshes (quietly), and they give the frame each building
is rendered in, exactly as Blender frames it.
"""
import math

TOL = 1e-4   # tiles


# ---------------------------------------------------------------- small vector algebra (tiles, Blender axes)

def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def mul(a, k): return (a[0] * k, a[1] * k, a[2] * k)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def length(a): return math.sqrt(dot(a, a))
def unit(a):
    n = length(a)
    return mul(a, 1 / n) if n > 1e-12 else (0., 0., 0.)
def mean(ps): return mul((sum(p[0] for p in ps), sum(p[1] for p in ps), sum(p[2] for p in ps)), 1 / len(ps))


def newell(ps):
    n = [0., 0., 0.]
    for i in range(len(ps)):
        a, b = ps[i], ps[(i + 1) % len(ps)]
        n[0] += (a[1] - b[1]) * (a[2] + b[2])
        n[1] += (a[2] - b[2]) * (a[0] + b[0])
        n[2] += (a[0] - b[0]) * (a[1] + b[1])
    return tuple(n)


def scener_rot(x, y, z, frame=True):
    """Scener's rot (degrees, applied Rz * Ry * Rx) putting an element's local axes along x, y, z (Blender
    coordinates). frame: the element is a kit frame, whose own axes follow Blender's convention too (its
    children are written as Blender (x, y, z) -> Scener (x, z, -y)); otherwise they are Scener's own, as a
    <shape>'s profile plane (x, y) and extrusion (z)."""
    r = [[x[i], y[i], z[i]] for i in range(3)]               # columns are the axes
    b = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]                  # Blender (x, y, z) -> Scener (x, z, -y)
    mm = lambda p, q: [[sum(p[i][k] * q[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    r = mm(mm(b, r), [list(c) for c in zip(*b)]) if frame else mm(b, r)
    ry = -math.asin(max(-1., min(1., r[2][0])))
    if abs(math.cos(ry)) > 1e-6:
        rx, rz = math.atan2(r[2][1], r[2][2]), math.atan2(r[1][0], r[0][0])
    else:
        rx, rz = math.atan2(-r[1][2], r[1][1]), 0.
    return tuple(math.degrees(a) for a in (rx, ry, rz))


def matrix_frame(m):
    """(translation, x, y, z axes, uniform scale) of a kit Matrix (rotation, uniform scale, translation)."""
    cols = [(m.m[0][j], m.m[1][j], m.m[2][j]) for j in range(3)]
    s = length(cols[0]) or 1.
    return (m.m[0][3], m.m[1][3], m.m[2][3]), [mul(c, 1 / s) for c in cols], s


# ---------------------------------------------------------------- recognising swept solids

def _rings(faces, n):
    """The two faces of a prism's ends, if the mesh is one: bottom range(h), top range(h, n), in either winding."""
    h = n // 2
    keys = {frozenset(f) for f in faces}
    return h if n % 2 == 0 and frozenset(range(h)) in keys and frozenset(range(h, n)) in keys else 0


def opposite_pairs(faces):
    """For a hexahedron, its three pairs of opposite quads, each with the vertex correspondence along the edges
    joining them: [(a_loop, b_loop)] where a_loop[i] is joined to b_loop[i]."""
    quads = [list(f) for f in faces if len(f) == 4]
    if len(quads) != 6:
        return []
    edges = set()
    for f in quads:
        for a, b in zip(f, f[1:] + f[:1]):
            edges.add(frozenset((a, b)))
    pairs = []
    for i in range(6):
        for j in range(i + 1, 6):
            A, B = quads[i], quads[j]
            if set(A) & set(B):
                continue
            match = []
            for a in A:
                bs = [b for b in B if frozenset((a, b)) in edges]
                if len(bs) != 1:
                    break
                match.append(bs[0])
            else:
                pairs.append((A, match))
    return pairs


def outline(V, faces, side, fan=False):
    """The boundary loop of the faces lying wholly in `side` (vertex indices), or with fan, the rim of the
    triangles around an apex."""
    edges = {}
    for fc in faces:
        pts = [i for i in fc if i in side]
        loop = list(fc) if all(i in side for i in fc) else (pts if fan and len(pts) == 2 else None)
        if not loop:
            continue
        for a, b in (zip(loop, loop[1:] + loop[:1]) if len(loop) > 2 else [tuple(loop)]):
            e = frozenset((a, b))
            edges[e] = edges.get(e, 0) + 1
    boundary = [tuple(e) for e, c in edges.items() if c == 1]
    if not boundary:
        return None
    nxt = {}
    for a, b in boundary:
        nxt.setdefault(a, []).append(b)
        nxt.setdefault(b, []).append(a)
    if any(len(v) != 2 for v in nxt.values()):
        return None
    start = boundary[0][0]
    loop, prev = [start], None
    while True:
        cur = loop[-1]
        nb = [x for x in nxt[cur] if x != prev]
        if not nb or nb[0] == start:
            break
        prev = cur
        loop.append(nb[0])
    return loop if len(loop) == len(nxt) else None


def local_frame(bottom, z):
    """Axes for a polygon swept along z: x along its first edge, y = z x x, origin its centroid."""
    e = sub(bottom[1], bottom[0])
    x = unit(sub(e, mul(z, dot(e, z))))
    return mean(bottom), x, cross(z, x)


def swept(V, faces):
    """A solid the kit made from vertices, as a polygon swept through space, or None:

      dict(bottom, d)                       a prism: every top vertex is its bottom one plus d (wall blocks,
                                            voussoirs, kit prisms, gables)
      dict(bottom, d, kx, ky)               a frustum or pyramid: the top is the bottom scaled about the
                                            sweep axis by kx, ky along the polygon's own axes (0 for an apex)
      dict(bottom, d, wedge=(axis, ratio))  a roof tile: swept along the polygon's normal, its thickness
                                            changing linearly along one of the polygon's axes"""
    n = len(V)
    h = _rings(faces, n)
    candidates = []
    if h:
        candidates.append((list(range(h)), list(range(h, n))))
    if n == 8:
        candidates += opposite_pairs(faces)
    for A, B in candidates:
        bottom, top = [V[i] for i in A], [V[i] for i in B]
        d = sub(top[0], bottom[0])
        if all(length(sub(sub(t, b), d)) < TOL for b, t in zip(bottom, top)):
            return dict(bottom=bottom, d=d)
    for A, B in candidates:
        bottom, top = [V[i] for i in A], [V[i] for i in B]
        nrm = unit(newell(bottom))
        # a frustum: the top is the bottom scaled about the axis through both centroids
        cb, ct = mean(bottom), mean(top)
        d = sub(ct, cb)
        if length(d) > TOL:
            o, x, y = local_frame(bottom, unit(d))
            ks = []
            for axis in (x, y):
                pairs = [(dot(sub(b, cb), axis), dot(sub(t, ct), axis)) for b, t in zip(bottom, top)]
                big = [(p, q) for p, q in pairs if abs(p) > 1e-6]
                k = big[0][1] / big[0][0] if big else 1.
                ks.append(k if all(abs(q - k * p) < TOL for p, q in pairs) else None)
            if None not in ks and all(abs(dot(sub(t, ct), unit(d))) < TOL for t in top):
                return dict(bottom=bottom, d=d, kx=ks[0], ky=ks[1])

        # a wedge: every top vertex is its bottom one moved along the normal, by a thickness linear across it
        offs = [sub(t, b) for b, t in zip(bottom, top)]
        th = [dot(o_, nrm) for o_ in offs]
        if min(th) > TOL and all(length(sub(o_, mul(nrm, t))) < TOL for o_, t in zip(offs, th)):
            o, x, y = local_frame(bottom, nrm)
            for name, axis in (("x", x), ("y", y)):
                c = [dot(sub(b, o), axis) for b in bottom]
                lo, hi = min(c), max(c)
                if hi - lo < TOL:
                    continue
                t0 = next(t for t, ci in zip(th, c) if abs(ci - lo) < TOL)
                t1 = next(t for t, ci in zip(th, c) if abs(ci - hi) < TOL)
                if all(abs(t - (t0 + (t1 - t0) * (ci - lo) / (hi - lo))) < TOL for t, ci in zip(th, c)):
                    return dict(bottom=bottom, d=mul(nrm, t0), wedge=(name, t1 / t0 - 1, lo))
    # strips: two copies of an outline, d apart, whose ends are built from strips instead of one face
    for i in range(1, n):
        d = sub(V[i], V[0])
        if length(d) < TOL:
            continue
        key = lambda p: tuple(round(c / TOL / 10) for c in p)
        where = {key(p): j for j, p in enumerate(V)}
        side = [j for j, p in enumerate(V) if key(add(p, d)) in where]
        if len(side) * 2 != n or any(key(sub(V[j], d)) in where for j in side):
            continue
        ring = outline(V, faces, set(side))
        if ring and abs(dot(unit(newell([V[j] for j in ring])), unit(d))) > .999:
            return dict(bottom=[V[j] for j in ring], d=d)
        break
    # a star or lens: a ring and an apex either side, as far out each way
    for a in range(n):
        for b in range(a + 1, n):
            ring = [j for j in range(n) if j not in (a, b)]
            if len(ring) < 3 or not all(len(fc) == 3 for fc in faces):
                continue
            c = mean([V[j] for j in ring])
            if length(add(sub(V[a], c), sub(V[b], c))) < TOL and abs(dot(unit(sub(V[a], c)), unit(newell([V[j] for j in ring])))) > .999:
                loop = outline(V, [fc for fc in faces if a in fc], set(ring), fan=True)
                if loop:
                    half = sub(V[a], c)
                    return dict(bottom=[sub(V[j], half) for j in loop], d=mul(half, 2), kx=0., ky=0., both=True)
    for A, B in candidates:   # last: ends a few degrees off square to the axis (a dome's blocks, scaled to its centre)
        bottom, top = [V[i] for i in A], [V[i] for i in B]
        cb, ct = mean(bottom), mean(top)
        d = sub(ct, cb)
        if length(d) < TOL or abs(dot(unit(newell(bottom)), unit(d))) < .97:
            continue
        o, x, y = local_frame(bottom, unit(d))
        ks = []
        for axis in (x, y):
            pairs = [(dot(sub(b, cb), axis), dot(sub(t, ct), axis)) for b, t in zip(bottom, top)]
            big = [(p, q) for p, q in pairs if abs(p) > 1e-6]
            k = big[0][1] / big[0][0] if big else 1.
            ks.append(k if all(abs(q - k * p) < 1e-3 for p, q in pairs) else None)
        if None not in ks:
            return dict(bottom=bottom, d=d, kx=ks[0], ky=ks[1], approx=True)
    if n >= 4:   # a pyramid: a polygon and an apex
        for f in faces:
            if len(f) == n - 1 and all(len(g) == 3 for g in faces if g is not f):
                apex = V[next(i for i in range(n) if i not in f)]
                bottom = [V[i] for i in f]
                return dict(bottom=bottom, d=sub(apex, mean(bottom)), kx=0., ky=0.)
    return None


# ---------------------------------------------------------------- the kit

def make_kit(Base, writer, linear_to_scene, gradient_cls, stats):
    """A subclass of the kit class Base whose primitives write Scener elements through writer (Scener's kit
    module). linear_to_scene turns a kit colour (linear) into a scene colour; stats counts what was written."""
    TILE, f, f4, v3, attrs = writer.TILE, writer.f, writer.f4, writer.v3, writer.attrs

    def P(p):
        return v3(p[0] * TILE, p[2] * TILE, -p[1] * TILE)

    class SKit(Base):
        shapes, materials, emission = {}, {}, {}   # set by the caller: shared lathe profiles, material table, emit

        def __init__(self, w, h):
            Base.__init__(self, w, h)
            self.sk = writer.Kit(w, h, SKit.shapes)
            self.quiet = 0

        # ---- the base kit's own meshes, for framing only

        def _base(self, name, *a, **k):
            self.quiet += 1
            try:
                return getattr(Base, name)(self, *a, **k)
            finally:
                self.quiet -= 1

        # ---- colour

        def _colour(self, mat, col):
            """(scene colour, gradient element or "") for a piece."""
            if isinstance(col, gradient_cls):
                return (1., 1., 1.), self._gradient(mat, col)
            if callable(col):
                raise SystemExit(f'a {mat} piece is coloured per vertex by {col}: write it as a Gradient')
            if isinstance(col, list):
                raise SystemExit(f'a {mat} piece has per-vertex colours: give it one colour or a Gradient')
            k = SKit.emission.get(mat, 1.)
            return tuple(linear_to_scene(c * k) for c in col[:3]), ""

        def _gradient(self, mat, g):
            ends = lambda c: v3(*(linear_to_scene(x * SKit.emission.get(mat, 1.)) for x in c[:3]))
            a = [("from", ends(g.a)), ("to", ends(g.b))]
            if g.axis is None:
                a = [("type", "uv"), ("tile", "%s %s" % (f(g.tile[0]), f(g.tile[1])))] + a
            else:
                if g.axis == "y":
                    raise SystemExit('a box Gradient along y: use x or z (Scener runs its z the other way)')
                a = [("type", "box"), ("axis", {"x": "x", "z": "y"}[g.axis])] + a
            a += [("offset", f4(g.offset) if g.offset else None), ("repeat", 1 if g.repeat else None),
                  ("mirror", 1 if getattr(g, "mirror", False) else None),
                  ("edge", f4(g.edge) if g.edge else None), ("power", f4(g.power) if g.power != 1 else None)]
            return "<gradient%s/>" % attrs(a)

        def _look(self, mat, col):
            c, grad = self._colour(mat, col)
            return self.sk.look(mat, c), grad

        def _emit(self, kind, fn, grad):
            """Runs a writer call; a gradient goes inside the first element it writes."""
            first = len(self.sk.lines)
            fn()
            stats[kind] += 1
            if not grad:
                return
            for i in range(first, len(self.sk.lines)):
                line = self.sk.lines[i]
                if line.lstrip().startswith("<group"):
                    continue
                if line.endswith("/>") and line.count("<") == 1:
                    tag = line.lstrip()[1:].split()[0]
                    self.sk.lines[i] = line[:-2] + ">" + grad + "</%s>" % tag
                else:
                    j = line.index(">") + 1
                    self.sk.lines[i] = line[:j] + grad + line[j:]
                return

        # ---- frames

        class _Frame:
            def __init__(self, kit, m): self.kit, self.m = kit, m
            def __enter__(self):
                k = self.kit
                self.base = Base.at(k, self.m)
                self.base.__enter__()
                if not k.quiet:
                    t, (x, y, z), s = matrix_frame(self.m)
                    rot = scener_rot(x, y, z)
                    k.sk.open("group", [("pos", P(t)), ("rot", v3(*rot)) if any(abs(r) > 1e-6 for r in rot) else ("rot", None),
                                        ("scale", " ".join([f4(s)] * 3)) if abs(s - 1) > 1e-6 else ("scale", None)])
            def __exit__(self, *a):
                if not self.kit.quiet:
                    self.kit.sk.close("group")
                self.base.__exit__(*a)

        def at(self, m):
            return SKit._Frame(self, m)

        # ---- primitives

        def box(self, mat, x, y, z, sx, sy, sz, col, rz=0.):
            if self.quiet: return Base.box(self, mat, x, y, z, sx, sy, sz, col, rz)
            self._base("box", mat, x, y, z, sx, sy, sz, col, rz)
            c, grad = self._colour(mat, col)
            self._emit("box", lambda: self.sk.box(mat, x, y, z, sx, sy, sz, c, rz), grad)

        def beam(self, mat, a, b, w, d, col):
            if self.quiet: return Base.beam(self, mat, a, b, w, d, col)
            self._base("beam", mat, a, b, w, d, col)
            c, grad = self._colour(mat, col)
            self._emit("beam", lambda: self.sk.beam(mat, tuple(a), tuple(b), w, d, c), grad)

        def tube(self, mat, a, b, r0, r1, col, n=10, smooth=True):
            if self.quiet: return Base.tube(self, mat, a, b, r0, r1, col, n, smooth)
            self._base("tube", mat, a, b, r0, r1, col, n, smooth)
            c, grad = self._colour(mat, col)
            self._emit("tube", lambda: self.sk.tube(mat, tuple(a), tuple(b), max(r0, 1e-3), max(r1, 1e-3), c, n), grad)

        def lathe(self, mat, x, y, z, prof, col, n=18, smooth=True, sx=1., sy=1., m=None):
            if self.quiet: return Base.lathe(self, mat, x, y, z, prof, col, n, smooth, sx, sy, m)
            self._base("lathe", mat, x, y, z, prof, col, n, smooth, sx, sy, m)
            look, grad = self._look(mat, col)
            cm = [(r * TILE, h * TILE) for r, h in prof]
            scale = v3(sx, 1, sy) if (sx, sy) != (1., 1.) else None
            if m is None:
                self._emit("lathe", lambda: self.sk.revolve(cm, P((x, y, z)), scale, n, look), grad)
                return
            t, (ax, ay, az), s = matrix_frame(m)   # a turned lathe: a group at its origin
            self.sk.open("group", [("pos", P((x, y, z))), ("rot", v3(*scener_rot(ax, ay, az)))])
            self._emit("lathe", lambda: self.sk.revolve(cm, "0 0 0", scale, n, look), grad)
            self.sk.close("group")

        def surface(self, mat, fn, nu, nv, col, *rest):
            if self.quiet: return Base.surface(self, mat, fn, nu, nv, col, *rest)
            self._base("surface", mat, fn, nu, nv, col, *rest)
            look, grad = self._look(mat, col)
            pts = [fn(i / nu, j / nv) for j in range(nv + 1) for i in range(nu + 1)]
            line = '<surface segments="%d %d" twoSided="1"%s points="%s"' % (nu, nv, attrs(look), " ".join(P(p) for p in pts))
            self._emit("surface", lambda: self.sk.emit(line + ("><%s</surface>" % grad[1:] if grad else "/>")), "")

        def poly(self, mat, pts, col, smooth=False):
            if self.quiet: return Base.poly(self, mat, pts, col, smooth)
            self.add(mat, [tuple(p) for p in pts], [tuple(range(len(pts)))], col, smooth)

        def torus(self, mat, frame, R_, r, col, nu=20, nv=8):   # Christmas Market's kit
            if self.quiet: return Base.torus(self, mat, frame, R_, r, col, nu, nv)
            self._base("torus", mat, frame, R_, r, col, nu, nv)
            look, grad = self._look(mat, col)
            t, (ax, ay, az), s = matrix_frame(frame)
            self.sk.open("group", [("pos", P(t)), ("rot", v3(*scener_rot(ax, ay, az)))])
            # the kit's ring lies in the frame's XY plane, which is Scener's XZ plane, where a <torus> lies
            el = '<torus majorRadius="%s" minorRadius="%s" majorSegments="%d" minorSegments="%d"%s/>' % (
                f(R_ * s * TILE), f(r * s * TILE), nu, nv, attrs(look))
            self._emit("torus", lambda: self.sk.emit(el), grad)
            self.sk.close("group")

        # ---- anything else the kit builds from vertices

        def add(self, mat, verts, faces, col, smooth=False, m=None):
            if self.quiet: return Base.add(self, mat, verts, faces, col, smooth, m)
            Base.add(self, mat, verts, faces, col, smooth, m)
            V = [tuple(m @ v) if m is not None else tuple(v) for v in verts]
            F = [tuple(fc) for fc in faces]
            look, grad = self._look(mat, col)
            if len(F) == 1:
                return self._plate(mat, [V[i] for i in F[0]], look, grad)
            sw = swept(V, F)
            if sw:
                return self._sweep(mat, look, grad, **sw)
            self._mesh(mat, V, F, look, grad, smooth)

        def _plate(self, mat, pts, look, grad):
            """A single polygon: a thin sheet, drawn from both sides as Blender draws a face."""
            nrm = unit(newell(pts))
            off = mul(nrm, -writer.THIN / TILE / 2)
            self._sweep(mat, look, grad, [add(p, off) for p in pts], mul(nrm, writer.THIN / TILE), kind="plate")

        def _sweep(self, mat, look, grad, bottom, d, kx=1., ky=1., wedge=None, kind=None, approx=False, both=False):
            """<shape> of the polygon, extruded along d (Scener centres the extrusion on the shape's plane), then
            tapered: a frustum's top by kx, ky (Max's Taper, from the base), a wedge's thickness along one axis."""
            z = unit(d)
            nrm = unit(newell(bottom))
            if abs(dot(nrm, z)) < (.97 if approx else .999):   # an oblique sweep: Scener extrudes along the polygon's normal
                return self._mesh_from_sweep(mat, bottom, d, kx, ky, look, grad)
            depth = length(d) * TILE
            o, x, y = local_frame(bottom, z)
            pts2 = [(dot(sub(p, o), x) * TILE, dot(sub(p, o), y) * TILE) for p in bottom]
            if dot(nrm, z) < 0:
                pts2 = pts2[::-1]
            mods, ext = "", '<extrude amount="%s"/>' % f(depth)
            shortest = min(math.dist(pts2[i], pts2[(i + 1) % len(pts2)]) for i in range(len(pts2)))
            bevel = writer.MATERIALS.get(mat, (0, 0, 0))[1] * TILE
            if (kx, ky) == (1., 1.) and not wedge and bevel and depth > 2.5 and shortest > 2.5:
                rad = min(bevel, .3 * shortest)   # the bevel modifier's soft edges: rounded corners, rounded rims
                bev = min(.85 * rad, .4 * depth)
                if rad >= .8:
                    mods = '<fillet radius="%s"/>' % f(rad)
                if bev >= .6:
                    ext += '<bevel amount="%s" bevelSegments="2"/>' % f(bev)
            taper = ""
            if both:   # a star or lens: to a point on either side of its plane
                taper = '<taper axis="z" amount="-2" center="0 0 0" symmetry="1"/>'
            elif kx == ky != 1.:
                taper = '<taper axis="z" amount="%s"/>' % f4(kx - 1)
            else:
                for eff, k in (("x", kx), ("y", ky)):
                    if k != 1.:
                        taper += '<taper axis="z" effect="%s" amount="%s"/>' % (eff, f4(k - 1))
            if wedge:   # thickness from the low side of the axis, the base face staying put
                axis, amount, lo = wedge
                c = (lo * TILE, 0) if axis == "x" else (0, lo * TILE)
                taper += '<taper axis="%s" effect="z" amount="%s" center="%s %s %s"/>' % (axis, f4(amount), f(c[0]), f(c[1]), f(-depth / 2))
            el = '<shape closed="1" pos="%s" rot="%s" v="%s"%s>%s%s%s%s</shape>' % (
                P(add(o, mul(d, .5))), v3(*scener_rot(x, y, z, frame=False)), " ".join("%s %s" % (f(a), f(b)) for a, b in pts2),
                attrs(look), grad, mods, ext, taper)
            self._emit(kind or ("approx" if approx else "wedge" if wedge else "taper" if taper else "sweep"), lambda: self.sk.emit(el), "")

        def _mesh_from_sweep(self, mat, bottom, d, kx, ky, look, grad):
            n = len(bottom)
            c = mean(bottom)
            o, x, y = local_frame(bottom, unit(d))
            top = [add(add(add(c, mul(x, dot(sub(p, c), x) * kx)), mul(y, dot(sub(p, c), y) * ky)), d) for p in bottom]
            F = [tuple(reversed(range(n))), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
            self._mesh(mat, bottom + top, F, look, grad, False)

        def _mesh(self, mat, V, F, look, grad, smooth):
            """The last resort, counted: free-form faces with the piece's one colour."""
            el = '<mesh%s v="%s" f="%s"%s>%s</mesh>' % (' smooth="1"' if smooth else "", " ".join(P(p) for p in V),
                                                     ", ".join(" ".join(map(str, fc)) for fc in F), attrs(look), grad)
            self._emit("mesh", lambda: self.sk.emit(el), "")

    return SKit

