"""Read the bundled Spine 3.2.01 setup meshes (not a general animation runtime).

Binary field layout checked against the official 3.1.07 / 3.4.02 format readers;
3.2 uses shear-aware bones with the older separate weighted-mesh attachment.
Only the features present in this skeleton are accepted, never silently skipped.
"""
import math
import struct
from PIL import Image, ImageDraw


class Reader:
    def __init__(self, data):
        self.data, self.position = data, 0

    def raw(self, count):
        end = self.position + count
        if end > len(self.data):
            raise ValueError('Truncated skeleton')
        result = self.data[self.position:end]
        self.position = end
        return result

    def byte(self):
        return self.raw(1)[0]

    def var(self):
        value = 0
        for shift in range(0, 35, 7):
            byte = self.byte()
            value |= (byte & 127) << shift
            if byte < 128:
                return value
        raise ValueError('Invalid skeleton varint')

    def string(self):
        count = self.var()
        return self.raw(count - 1).decode('utf8') if count else None

    def floats(self, count):
        return struct.unpack(f'>{count}f', self.raw(count * 4))

    def shorts(self):
        count = self.var()
        return struct.unpack(f'>{count}H', self.raw(count * 2))


def transform(matrix, x, y):
    a, b, c, d, tx, ty = matrix
    return a*x+b*y+tx, c*x+d*y+ty


def read_setup(data):
    r = Reader(data)
    r.string()  # content hash
    version = r.string()
    if version != '3.2.01':
        raise ValueError(f'Unsupported skeleton version {version}')
    r.floats(2)  # authoring bounds, not the origin
    extra = r.byte()
    if extra:
        r.string()
    local_bones = []
    for i in range(r.var()):
        r.string()
        parent = r.var() if i else None
        values = list(r.floats(8))
        if (r.byte(), r.byte()) != (1, 1):
            raise ValueError('Unsupported bone inheritance')
        if extra:
            r.raw(4)
        local_bones.append((parent, values))
    if r.var() or r.var():
        raise ValueError('Constraints need an animation runtime')
    slots = []
    for _ in range(r.var()):
        name, bone, color = r.string(), r.var(), r.raw(4)
        attachment, blend = r.string(), r.var()
        if color != bytes([255]*4) or blend:
            raise ValueError(f'Unsupported slot color/blend: {name}')
        slots.append((bone, attachment))
    layers = {}
    for _ in range(r.var()):
        slot = r.var()
        for _ in range(r.var()):
            key = r.string()
            name = r.string() or key
            kind = r.byte()
            path = r.string() or name
            if kind not in (2, 3) or r.raw(4) != bytes([255]*4):
                raise ValueError(f'Unsupported attachment: {name}')
            count = r.var()
            uvs, triangles = r.floats(count*2), r.shorts()
            vertices = []
            for _ in range(count):
                if kind == 2:
                    vertices.append([(slots[slot][0], *r.floats(2), 1)])
                else:
                    vertices.append([(int(r.floats(1)[0]), *r.floats(3))
                                     for _ in range(int(r.floats(1)[0]))])
            r.var()  # hull length
            if extra:
                r.shorts()
                r.floats(2)
            if key == slots[slot][1]:
                layers[slot] = dict(path=path, vertices=vertices, uvs=list(zip(uvs[::2], uvs[1::2])), triangles=triangles)
    if r.var() or r.var():
        raise ValueError('Unexpected additional skins or events')
    # Blink's authored first frame is the open-eyed resting pose. Its other
    # timeline groups are empty; reject changes instead of inventing a pose.
    if not r.var() or r.string() != 'Blink' or r.var():
        raise ValueError('Expected Blink with no slot timelines')
    for _ in range(r.var()):
        bone = r.var()
        values = local_bones[bone][1]
        for _ in range(r.var()):
            kind, frames = r.byte(), r.var()
            if kind not in (0, 1, 2, 3):
                raise ValueError('Unsupported bone timeline')
            for frame in range(frames):
                key = r.floats(2 if kind == 0 else 3)
                if frame == 0:
                    if key[0] != 0:
                        raise ValueError('Expected an authored time-zero key')
                    if kind == 0:
                        values[0] += key[1]
                    else:
                        offset = {1:1, 2:3, 3:5}[kind]
                        for j in (0,1):
                            if kind == 2:
                                values[offset+j] *= key[j+1]
                            else:
                                values[offset+j] += key[j+1]
                if frame < frames-1:
                    curve = r.byte()
                    if curve == 2:
                        r.floats(4)
                    elif curve not in (0,1):
                        raise ValueError('Unsupported curve')
    if any(r.var() for _ in range(5)):
        raise ValueError('Unexpected Blink constraint/deform/draw/event timelines')
    bones = []
    for parent, values in local_bones:
        rotation, x, y, sx, sy, shx, shy, _ = values
        rx, ry = math.radians(rotation+shx), math.radians(rotation+90+shy)
        a, b, c, d = math.cos(rx)*sx, math.cos(ry)*sy, math.sin(rx)*sx, math.sin(ry)*sy
        if parent is not None:
            pa, pb, pc, pd, _, _ = bones[parent]
            x, y = transform(bones[parent], x, y)
            a, b, c, d = pa*a+pb*c, pa*b+pb*d, pc*a+pd*c, pc*b+pd*d
        bones.append((a,b,c,d,x,y))
    for layer in layers.values():
        world = []
        for vertex in layer['vertices']:
            points = [(*transform(bones[bone], x,y),weight) for bone,x,y,weight in vertex]
            world.append(tuple(sum(p[k]*p[2] for p in points) for k in (0,1)))
        layer['vertices'] = world
    return [layers[i] for i in sorted(layers)]


def read_atlas(text):
    regions = {}
    region = None
    for line in text.splitlines():
        if not line.strip():
            continue
        if line.startswith('  '):
            key, value = line.strip().split(': ', 1)
            if region is not None:
                region[key] = value
        elif ':' not in line and not line.endswith('.png'):
            region = regions[line] = {}
    return regions


def render_setup(layers, regions, atlas, size=256):
    """Rasterize original triangles in setup draw order, at 128 pixels per unit."""
    side = size * 2
    image = Image.new('RGBA', (side, side))
    for layer in layers:
        region = regions[layer['path']]
        x, y = map(int, region['xy'].split(','))
        w, h = map(int, region['size'].split(','))
        rotated = region['rotate'] == 'true'
        texture = atlas.crop((x, y, x+(h if rotated else w), y+(w if rotated else h)))
        if rotated:
            texture = texture.transpose(Image.Transpose.ROTATE_270)
        points = [((x/128+.5)*side, (.5-y/128)*side) for x,y in layer['vertices']]
        uv = [(u*w, v*h) for u,v in layer['uvs']]
        rendered = Image.new('RGBA', image.size)
        for i in range(0, len(layer['triangles']), 3):
            ids = layer['triangles'][i:i+3]
            p = [points[j] for j in ids]
            (ax,ay),(bx,by),(cx,cy) = p
            det = (bx-ax)*(cy-ay)-(cx-ax)*(by-ay)
            if abs(det) < 1e-8:
                continue
            coefficients = []
            for k in (0,1):
                av,bv,cv = [uv[j][k] for j in ids]
                a = ((bv-av)*(cy-ay)-(cv-av)*(by-ay))/det
                b = ((bx-ax)*(cv-av)-(cx-ax)*(bv-av))/det
                coefficients.extend((a,b,av-a*ax-b*ay))
            patch = texture.transform(image.size, Image.Transform.AFFINE, coefficients, Image.Resampling.BILINEAR)
            mask = Image.new('1', image.size)
            ImageDraw.Draw(mask).polygon(p, fill=1)
            rendered.paste(patch, (0,0), mask)
        image.alpha_composite(rendered)
    return image.resize((size,size), Image.Resampling.LANCZOS)
