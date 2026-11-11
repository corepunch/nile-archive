"""Scener scenes of a game's city buildings, made from the same build_scene.py Blender uses.

tools/buildings.py renders sprites and ground shadows with Scener (github.com/corepunch/orion-ui,
apps/scener) through this module:

    scenes = write_scenes(game, workdir, ppt, shadow)   # sprites.blks, shadows.blks, frames
    scener --render sprites.blks --transparent ...       # one orthographic camera per building

Nothing is translated by hand. The game's builders run unchanged against a subclass of the real
building kit (tools/scener_kit.py, over tools/building_kit.py or Christmas Market's own), with stand-in
bpy and mathutils modules, and every kit call is written as a Scener primitive with its modifiers:
soft-boxes, lathes, tubes, surfaces, shapes extruded and tapered, in groups for the kit's frames. A
piece has one colour; a Gradient is its gizmo. So a building reads as its source does, looks the same
in both renderers, and editing build_scene.py changes both.

What Blender adds on top, and how it comes across:
  - a material: roughness becomes shininess (Scener's shader takes roughness = exp(-shininess / 18)),
    Specular IOR Level and metallic go across as Scener's specular and metallic, emission becomes
    an unlit piece. Bump, mottle, subsurface, coat and glass transparency have no counterpart.
  - the bevel modifier: the material's bevel width rounds every soft-box and every extruded shape
    (a fillet on its corners, a bevel on its rims).
  - Cycles' global illumination: Scener lights with the sun, the fill, the sky as an ambient term
    and the building's own lamps.

Scene layout: Blender's X (tile u) and Y (-v) are Scener's X and -Z; Blender's Z is Scener's Y;
one tile is TILE cm. Buildings stand SPACING tiles apart along the camera's right vector, so no
camera's frame or shadow reaches a neighbour, and each camera is named after its building's key.
"""
import importlib.util
import json
import shutil
import math
import sys
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import city_camera

TILE = 160.          # cm per tile, as Scener's building kit
SPACING = 48         # tiles between buildings along the camera's right vector
CAMERA_BACK = 120.   # tiles from a building to its camera, as Blender's frame()
LIGHT_SCALE = .35    # Blender point-light watts -> Scener intensity (Scener's building kit)
GI_GAIN = 1.55       # Cycles' bounced light: Blender's renders are this much brighter (linear) than direct + ambient


# ---------------------------------------------------------------- mathutils and bpy stand-ins

class Vector:
    def __init__(self, v=(0, 0, 0)):
        self.v = [float(c) for c in v]
    x = property(lambda s: s.v[0], lambda s, a: s.v.__setitem__(0, float(a)))
    y = property(lambda s: s.v[1], lambda s, a: s.v.__setitem__(1, float(a)))
    z = property(lambda s: s.v[2], lambda s, a: s.v.__setitem__(2, float(a)))
    def __iter__(self): return iter(self.v)
    def __getitem__(self, i): return self.v[i]
    def __len__(self): return len(self.v)
    def __repr__(self): return 'Vector(%r)' % (tuple(self.v),)
    def __add__(self, o): return Vector(a + b for a, b in zip(self.v, o))
    __radd__ = __add__
    def __sub__(self, o): return Vector(a - b for a, b in zip(self.v, o))
    def __rsub__(self, o): return Vector(b - a for a, b in zip(self.v, o))
    def __neg__(self): return Vector(-a for a in self.v)
    def __mul__(self, k):
        if isinstance(k, Vector): return Vector(a * b for a, b in zip(self.v, k))
        return Vector(a * k for a in self.v)
    __rmul__ = __mul__
    def __truediv__(self, k): return Vector(a / k for a in self.v)
    @property
    def length(self): return math.sqrt(sum(a * a for a in self.v))
    def normalized(self):
        n = self.length or 1
        return Vector(a / n for a in self.v)
    def normalize(self):
        n = self.length or 1
        self.v = [a / n for a in self.v]
    def dot(self, o): return sum(a * b for a, b in zip(self.v, o))
    def cross(self, o):
        a, b = self.v, list(o)
        return Vector((a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]))
    def lerp(self, o, t): return self * (1 - t) + Vector(o) * t
    def copy(self): return Vector(self.v)
    def to_tuple(self, *a): return tuple(self.v)


class Matrix:
    def __init__(self, rows=None):
        self.m = [list(map(float, r)) for r in rows] if rows else [[1. if i == j else 0. for j in range(4)] for i in range(4)]
    @staticmethod
    def Identity(n=4): return Matrix()
    @staticmethod
    def Translation(v):
        m = Matrix()
        m.m[0][3], m.m[1][3], m.m[2][3] = v[0], v[1], v[2]
        return m
    @staticmethod
    def Scale(s, n=4, axis=None):
        m = Matrix()
        if axis is None:
            for i in range(3): m.m[i][i] = s
        else:   # scale s along a direction
            a = Vector(axis).normalized()
            for i in range(3):
                for j in range(3): m.m[i][j] += (s - 1) * a[i] * a[j]
        return m
    @staticmethod
    def Rotation(a, n, axis):
        c, s, m = math.cos(a), math.sin(a), Matrix()
        if isinstance(axis, str):
            i, j = {'X': (1, 2), 'Y': (2, 0), 'Z': (0, 1)}[axis.upper()]
            m.m[i][i], m.m[i][j], m.m[j][i], m.m[j][j] = c, -s, s, c
        else:   # about an arbitrary axis (Rodrigues)
            x, y, z = Vector(axis).normalized()
            t = 1 - c
            r = [[t * x * x + c, t * x * y - s * z, t * x * z + s * y],
                 [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
                 [t * x * z - s * y, t * y * z + s * x, t * z * z + c]]
            for i in range(3): m.m[i][:3] = r[i]
        return m
    def __matmul__(self, o):
        if isinstance(o, Matrix):
            return Matrix([[sum(self.m[i][k] * o.m[k][j] for k in range(4)) for j in range(4)] for i in range(4)])
        v = list(o) + [1.]
        return Vector(sum(self.m[i][k] * v[k] for k in range(4)) for i in range(3))
    @property
    def translation(self): return Vector((self.m[0][3], self.m[1][3], self.m[2][3]))
    def to_3x3(self):
        m = Matrix([r[:3] + [0.] for r in self.m[:3]] + [[0, 0, 0, 1]])
        return m
    def inverted(self):
        # a general 4x4 inverse (Gauss-Jordan); kit frames are affine
        n = 4
        a = [r[:] + [1. if i == j else 0. for j in range(n)] for i, r in enumerate(self.m)]
        for c in range(n):
            p = max(range(c, n), key=lambda r: abs(a[r][c]))
            a[c], a[p] = a[p], a[c]
            d = a[c][c] or 1e-12
            a[c] = [x / d for x in a[c]]
            for r in range(n):
                if r != c and a[r][c]:
                    f = a[r][c]
                    a[r] = [x - f * y for x, y in zip(a[r], a[c])]
        return Matrix([r[n:] for r in a])


class _Anything:
    """bpy: any attribute, call or item is another stand-in, so module-level Blender calls do nothing."""
    def __getattr__(self, name): return _Anything()
    def __call__(self, *a, **k): return _Anything()
    def __getitem__(self, k): return _Anything()
    def __setitem__(self, k, v): pass
    def __iter__(self): return iter(())
    def __bool__(self): return False


def install_stubs():
    sys.modules['mathutils'] = types.SimpleNamespace(Vector=Vector, Matrix=Matrix)
    sys.modules['bpy'] = _Anything()
    sys.modules['bmesh'] = _Anything()


def load(name, path, globs=None, stop=None):
    """Execute a script as module `name`; stop: run only the source before this line."""
    path = Path(path)
    mod = types.ModuleType(name)
    mod.__file__ = str(path)
    sys.modules[name] = mod
    src = path.read_text()
    if stop and stop in src:
        src = src[:src.index(stop)]
    if globs: mod.__dict__.update(globs)
    exec(compile(src, str(path), 'exec'), mod.__dict__)
    return mod


# ---------------------------------------------------------------- capture

def find_writer():
    """Scener's writer kit (orion-ui apps/scener/tools/building_kit.py) and its utilities.xml."""
    import os
    roots = [os.environ.get('ORION_UI'), str(ROOT.parent / 'orion-ui')]
    scener = os.environ.get('SCENER')
    if scener:   # .../orion-ui/build/bin/scener
        roots.insert(0, str(Path(scener).resolve().parents[2]))
    for r in roots:
        if r and (Path(r) / 'apps/scener/tools/building_kit.py').exists():
            tools = Path(r) / 'apps/scener'
            spec = importlib.util.spec_from_file_location('scener_writer', tools / 'tools/building_kit.py')
            writer = importlib.util.module_from_spec(spec)
            sys.modules['scener_writer'] = writer
            spec.loader.exec_module(writer)
            return writer, tools / 'scenes/utilities.xml'
    raise SystemExit('Scener\'s building kit not found: set ORION_UI to an orion-ui checkout')


class Captured:
    """One building: its Scener elements, the base kit's meshes (to frame it), lights and pivot scale."""
    def __init__(self, it, kit, scale, light_color):
        self.key, self.title, self.w, self.h = it['key'], it['title'], it['w'], it['h']
        self.scale = scale
        self.buckets = kit.buckets
        self.lines = kit.sk.lines
        self.lights = []
        for light in kit.lights:
            p, watts, colour = light if len(light) == 3 else (*light, light_color)
            self.lights.append((tuple(p), watts, tuple(colour)))


def _materials(module):
    """name -> make_material keyword arguments, from the module's own make_materials()."""
    seen = {}
    orig = module.make_material
    module.make_material = lambda name, **kw: seen.setdefault(name, kw)
    try:
        module.make_materials()
    finally:
        module.make_material = orig
    return seen


def g22(v):
    """A linear value as Scener reads scene colours (it raises them to 2.2); values above 1 stay."""
    return max(0., v) ** (1 / 2.2)


def palette(writer, kwargs, bevels):
    """Point Scener's writer at one kit's materials: Blender's roughness as shininess (Scener's shader takes
    roughness = exp(-shininess / 18)), its bevel width and segments, specular and metallic, emission as unlit.
    Returns material -> emission strength, by which an unlit piece's colour is raised as Blender's is."""
    writer.MATERIALS.clear(); writer.SURFACE.clear(); writer.SEGMENTS.clear(); writer.GRADIENTS.clear()
    emission = {}
    for name, kw in kwargs.items():
        rough = max(kw.get('rough', .7), .05)
        wid, seg = bevels.get(name, (0, 2))
        writer.MATERIALS[name] = (round(-18 * math.log(rough), 1), wid, kw.get('emit', 0) > 0)
        writer.SEGMENTS[name] = seg
        writer.SURFACE[name] = (kw.get('spec', .4), kw.get('metal', 0.))
        if kw.get('emit', 0) > 0:
            emission[name] = kw['emit']
    return emission


def capture(game, stats=None):
    """Run the game's builders without Blender, drawing Scener elements. Returns (buildings, shapes, lighting)."""
    import collections
    import scener_kit
    install_stubs()
    for name in ('building_kit', 'city_camera', 'market_wishes'):
        sys.modules.pop(name, None)
    here = ROOT / 'games' / game / 'art/building-catalogue'
    sys.path.insert(0, str(ROOT / 'tools'))
    sys.path.insert(0, str(here))
    import building_kit as kit
    writer, _ = find_writer()
    stats = stats if stats is not None else collections.Counter()
    shapes = {}
    KitS = scener_kit.make_kit(kit.Kit, writer, g22, kit.Gradient, stats)
    KitS.shapes = shapes
    looks = {'kit': (_materials(kit), kit.BEVELS)}
    out = []

    if game == 'christmas-market':
        scene = load('cm_build_scene', here / 'build_scene.py', stop='\nif __name__ == "__main__"')
        OwnS = scener_kit.make_kit(scene.Kit, writer, g22, kit.Gradient, stats)
        OwnS.shapes = shapes
        looks['own'] = (_materials(scene), scene.BEVELS)
        import market_wishes
        market_wishes.Kit, scene.Kit = KitS, OwnS
        for i, it in enumerate(scene.CATALOGUE):
            wish = it['key'] in market_wishes.KEYS
            (KitS if wish else OwnS).emission = palette(writer, *looks['kit' if wish else 'own'])
            k = market_wishes.model(it, i) if wish else scene.model(it, i)
            out.append(Captured(it, k, kit.TREE_GROWTH if it['key'] in scene.TREES else 1., (1, .62, .28)))
        lighting = dict(sun=(3.0, 6, (1, .9, .78), (-.55, 1.0, -1.25)), fill=(.55, 40, (.75, .85, 1), (-1.0, .2, -.6)),
                        world=((.62, .74, 1.0), .7), exposure=-.15)
        return out, shapes, lighting

    calls = []
    kit.assemble = lambda *a, **k: calls.append((a, k))
    load(game.replace('-', '_') + '_build_scene', here / 'build_scene.py')
    (_, items, builders, _), opts = calls[0][0][:4], calls[0][1]
    slab, slab_color, model_scale = opts.get('slab'), opts.get('slab_color'), opts.get('model_scale')
    light_color = opts.get('light_color', (1, .62, .28))
    KitS.emission = palette(writer, *looks['kit'])
    for i, it in enumerate(items):   # kit.assemble, without bpy
        kit.R.seed(7 + i)
        k = KitS(it['w'], it['h'])
        if slab is None or slab(it):
            k.box('slab', 0, 0, 0, it['w'], it['h'], kit.G, slab_color or kit.SLAB)
        builders[it['key']](k)
        for b in k.buckets.values():   # nothing may leave the footprint
            b['v'] = [(max(-it['w'] / 2, min(it['w'] / 2, p[0])), max(-it['h'] / 2, min(it['h'] / 2, p[1])), p[2]) for p in b['v']]
        reach = max((max(abs(p[0]), abs(p[1])) for b in k.buckets.values() for p in b['v']), default=0)
        out.append(Captured(it, k, model_scale(it, reach) if model_scale else 1., light_color))
    lighting = dict(sun=(2.7, 7, (1, .93, .8), (.34, 1.0, -1.3)), fill=(.7, 40, (1, .88, .72), (-1.0, .35, -.7)),
                    world=((.62, .72, .95), .62), exposure=0.)
    return out, shapes, lighting


# ---------------------------------------------------------------- writing

def _dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def f(v, digits=2):
    s = '%.*f' % (digits, v)
    if '.' in s: s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def to_scener(p):
    """Blender tiles (x = u, y = -v, z up) -> Scener cm (y up)."""
    return (p[0] * TILE, p[2] * TILE, -p[1] * TILE)


def frame_of(points, scale, margin):
    """Blender's frame(): the camera's view of points, in whole pixels. Returns the frame and the camera basis."""
    yaw, elev = math.radians(city_camera.YAW), math.radians(city_camera.ELEVATION)
    a = math.pi / 2 - elev
    right = (math.cos(yaw), math.sin(yaw), 0.)
    up = (-math.sin(yaw) * math.cos(a), math.cos(yaw) * math.cos(a), math.sin(a))
    back = (math.sin(yaw) * math.sin(a), -math.cos(yaw) * math.sin(a), math.cos(a))
    xs, ys = [_dot(p, right) for p in points], [_dot(p, up) for p in points]
    pad = margin / scale
    x0, x1, y0, y1 = min(xs) - pad, max(xs) + pad, min(ys) - pad, max(ys) + pad
    width, height = math.ceil((x1 - x0) * scale - 1e-6), math.ceil((y1 - y0) * scale - 1e-6)
    x1, y0 = x0 + width / scale, y1 - height / scale
    return dict(x0=x0, x1=x1, y0=y0, y1=y1, width=width, height=height, right=right, up=up, back=back)


def camera_xml(name, fr, scale):
    cx, cy = (fr['x0'] + fr['x1']) / 2, (fr['y0'] + fr['y1']) / 2
    target = tuple(fr['right'][i] * cx + fr['up'][i] * cy for i in range(3))
    eye = tuple(target[i] + fr['back'][i] * CAMERA_BACK for i in range(3))
    return '  <camera name="%s" pos="%s" look="%s" ortho="%s" size="%d %d"/>' % (
        name, ' '.join(f(c) for c in to_scener(eye)), ' '.join(f(c) for c in to_scener(target)),
        f(fr['height'] / scale * TILE, 4), fr['width'], fr['height'])


def pixel_of(p, fr, scale):
    return [(_dot(p, fr['right']) - fr['x0']) * scale, (fr['y1'] - _dot(p, fr['up'])) * scale]


def sun_xml(strength, colour, direction, shadows, scale=1.):
    d = to_scener(direction)
    l = math.sqrt(_dot(d, d))
    return '  <sun dir="%s" color="%s" intensity="%s" castShadows="%d"/>' % (
        ' '.join(f(c / l, 4) for c in d), ' '.join(f(g22(c), 3) for c in colour), f(strength / math.pi * scale, 3), shadows)


def write_scenes(game, out, ppt, shadow_cfg, keys=None, log=print):
    """Write sprites.blks and shadows.blks for the game's buildings (or just keys) into out.

    Returns {key: dict(title, size, scale, pivot, base_width, shadow_pivot, shadow_base_width)} with
    every pixel position in its camera's image, as render_buildings_blender.py reports them."""
    import collections
    stats = collections.Counter()
    buildings, shapes, lighting = capture(game, stats)
    order = [b.key for b in buildings]
    if keys:
        missing = [k for k in keys if k not in order]
        if missing: raise SystemExit(f'No such buildings in {game}: {missing}')
        buildings = [b for b in buildings if b.key in keys]
    shadow_ppt = shadow_cfg.get('ppt', 28.284)
    sun_dir = shadow_cfg.get('sun') or lighting['sun'][3]
    yaw = math.radians(city_camera.YAW)
    exposure = 2 ** lighting['exposure'] * GI_GAIN
    world, world_strength = lighting['world']
    ambient = [g22(c * world_strength * exposure) for c in world]

    sprite, shadow, report = [], [], {}
    sl = math.sqrt(sum(c * c for c in sun_dir))
    sun = [c / sl for c in sun_dir]
    slope = (sun[0] / max(-sun[2], .05), sun[1] / max(-sun[2], .05))
    for n, b in enumerate(buildings):
        origin = (n * SPACING * math.cos(yaw), n * SPACING * math.sin(yaw), 0.)
        s = b.scale
        pts = [(origin[0] + v[0] * s, origin[1] + v[1] * s, v[2] * s) for bk in b.buckets.values() for v in bk['v']]
        fr = frame_of(pts, ppt, 6)
        sfr_pts = list(pts)
        top = max(p[2] for p in pts)
        sfr_pts += [(p[0] + slope[0] * p[2], p[1] + slope[1] * p[2], 0.) for p in pts if p[2] > top * .3]
        sfr = frame_of(sfr_pts + [origin], shadow_ppt, 8)
        span = city_camera.base_span(b.w, b.h)
        report[b.key] = dict(title=b.title, size=[b.w, b.h], scale=s, pivot=pixel_of(origin, fr, ppt),
                             base_width=span * ppt, shadow_pivot=pixel_of(origin, sfr, shadow_ppt),
                             shadow_base_width=span * shadow_ppt)
        sprite.append(camera_xml(b.key, fr, ppt))
        shadow.append(camera_xml(b.key, sfr, shadow_ppt))

        body = ['  ' + l for l in b.lines]
        lamps = ['    <light pos="%s" color="%s" intensity="%s" radius="%s" castShadows="1"/>' % (
            ' '.join(f(c) for c in to_scener(p)), ' '.join(f(g22(c), 3) for c in colour),
            f(LIGHT_SCALE * watts * exposure, 3), f(TILE * 1.4)) for p, watts, colour in b.lights]
        head = '  <group pos="%s"%s' % (' '.join(f(c) for c in to_scener(origin)), ' scale="%s %s %s"' % ((f(s, 4),) * 3) if s != 1 else '')
        sprite += ['%s name="%s">' % (head, b.key)] + body + lamps + ['  </group>']
        shadow += ['%s name="%s" renderable="0">' % (head, b.key)] + body + ['  </group>']

    sun_strength, _, sun_colour, sun_direction = lighting['sun']
    fill_strength, _, fill_colour, fill_direction = lighting['fill']
    profiles = ['  <shape id="%s" closed="0" v="%s"/>' % (sid, ' '.join(' '.join(p.split(',')) for p in key.split(' ')))
                for key, sid in shapes.items()]
    head = ['<?xml version="1.0" encoding="UTF-8"?>',
            f'<!-- {game} buildings for the city camera, written by nile-archive tools/scener_buildings.py from the',
            '     game\'s build_scene.py: one group per building, each kit call one primitive with its modifiers.',
            '     Generated: edit build_scene.py, not this file. -->']
    lib = ['  <include src="utilities.xml"/>'] + profiles
    sprites = head + ['<scene ambient="%s" background="0 0 0">' % ' '.join(f(c, 3) for c in ambient),
                      sun_xml(sun_strength, sun_colour, sun_direction, 1, exposure),
                      sun_xml(fill_strength, fill_colour, fill_direction, 0, exposure)] + lib + sprite + ['</scene>', '']
    # the shadow pass: the buildings cast but are not drawn; a white catcher lit by the shadow sun alone
    lo = (-SPACING, -SPACING)
    hi = (len(buildings) * SPACING * math.cos(yaw) + SPACING, len(buildings) * SPACING * math.sin(yaw) + SPACING)
    catcher = [(lo[0], lo[1], -.006), (hi[0], lo[1], -.006), (hi[0], hi[1], -.006), (lo[0], hi[1], -.006)]
    shadows = head + ['<scene ambient="0 0 0" background="0 0 0">',
                      sun_xml(math.pi, (1, 1, 1), sun, 1)] + lib + [
                      '  <mesh name="shadow_catcher" castShadow="0" specular="0" v="%s" f="0 1 2 3"/>' % ' '.join(
                          f(c) for p in catcher for c in to_scener(p))] + shadow + ['</scene>', '']
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    (out / 'sprites.blks').write_text('\n'.join(sprites))
    (out / 'shadows.blks').write_text('\n'.join(shadows))
    shutil.copy(find_writer()[1], out / 'utilities.xml')
    log(f'{game}: wrote {len(buildings)} buildings to {out}/sprites.blks ({(out / "sprites.blks").stat().st_size // 1024} KB): '
        + ', '.join(f'{n} {k}' for k, n in stats.most_common()))
    return dict(order=order, items=report)


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('game')
    ap.add_argument('out')
    ap.add_argument('keys', nargs='*')
    a = ap.parse_args()
    cfg = json.loads((ROOT / 'games' / a.game / 'art/buildings.json').read_text())
    rep = write_scenes(a.game, a.out, cfg.get('ppt', 85), cfg.get('shadow', {}), a.keys)
    (Path(a.out) / 'report.json').write_text(json.dumps(rep, indent=1))
