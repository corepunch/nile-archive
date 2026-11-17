"""Read selected first frames from bundled Spine 3.2.01 skeletons (not a general animation runtime).

Binary field layout checked against the official 3.1.07 / 3.4.02 format readers;
3.2 uses shear-aware bones with the older separate weighted-mesh attachment.
Only the features required by these skeletons are accepted, never silently skipped.
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


def read_setup(data, expected_animation="Blink", regions=None):
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
        inherit = (r.byte(), r.byte())
        if any(value not in (0, 1) for value in inherit):
            raise ValueError('Invalid bone inheritance')
        if extra:
            r.raw(4)
        local_bones.append((parent, values, inherit))
    if r.var() or r.var():
        raise ValueError('Constraints need an animation runtime')
    slots = []
    for _ in range(r.var()):
        name, bone, color = r.string(), r.var(), r.raw(4)
        attachment, blend = r.string(), r.var()
        if color != bytes([255]*4) or blend:
            raise ValueError(f'Unsupported slot color/blend: {name}')
        slots.append([bone, attachment, color])
    attachments = {}
    for _ in range(r.var()):
        slot = r.var()
        for _ in range(r.var()):
            key = r.string()
            name = r.string() or key
            kind = r.byte()
            path = r.string() or name
            if kind == 0:
                rotation, x, y, sx, sy, width, height = r.floats(7)
                if r.raw(4) != bytes([255]*4):
                    raise ValueError(f'Unsupported attachment color: {name}')
                if regions is None or path not in regions:
                    raise ValueError(f'Missing atlas region: {path}')
                region = regions[path]
                rw, rh = map(int, region['size'].split(','))
                ow, oh = map(int, region['orig'].split(','))
                ox, oy = map(int, region['offset'].split(','))
                x1, y1 = -width*sx/2+ox*width*sx/ow, -height*sy/2+oy*height*sy/oh
                x2, y2 = x1+rw*width*sx/ow, y1+rh*height*sy/oh
                angle = math.radians(rotation)
                cs, sn = math.cos(angle), math.sin(angle)
                vertices = [[(slots[slot][0], x+px*cs-py*sn, y+px*sn+py*cs, 1)]
                            for px,py in [(x1,y1),(x1,y2),(x2,y2),(x2,y1)]]
                uvs, triangles = [(0,1),(0,0),(1,0),(1,1)], [0,1,2,2,3,0]
            elif kind in (2, 3):
                if r.raw(4) != bytes([255]*4):
                    raise ValueError(f'Unsupported attachment color: {name}')
                count = r.var()
                uvdata, triangles = r.floats(count*2), r.shorts()
                uvs = list(zip(uvdata[::2], uvdata[1::2]))
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
            else:
                raise ValueError(f'Unsupported attachment: {name} ({kind})')
            attachments[slot,key] = dict(path=path, vertices=vertices, uvs=uvs, triangles=triangles)
    if r.var() or r.var():
        raise ValueError('Unexpected additional skins or events')
    # Walk earlier animations to reach the selected authored first frame.
    found = False
    for _ in range(r.var()):
        animation = r.string()
        selected = animation == expected_animation
        for _ in range(r.var()):
            slot = r.var()
            for _ in range(r.var()):
                kind, frames = r.byte(), r.var()
                if kind not in (4,5):
                    raise ValueError('Unsupported slot timeline')
                for frame in range(frames):
                    time = r.floats(1)[0]
                    value = r.string() if kind == 4 else r.raw(4)
                    if selected and frame == 0 and time == 0:
                        slots[slot][1 if kind == 4 else 2] = value
                    if kind == 5 and frame < frames-1:
                        read_curve(r)
        for _ in range(r.var()):
            bone = r.var()
            values = local_bones[bone][1]
            for _ in range(r.var()):
                kind, frames = r.byte(), r.var()
                if kind not in (0,1,2,3):
                    raise ValueError('Unsupported bone timeline')
                for frame in range(frames):
                    key = r.floats(2 if kind == 0 else 3)
                    if selected and frame == 0 and key[0] == 0:
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
                        read_curve(r)
        # IK and transform constraints are absent from these skeletons.
        if r.var() or r.var():
            raise ValueError('Unsupported animation constraint timeline')
        # Deformation data is skipped for earlier animations, never for the selected pose.
        for _ in range(r.var()):
            r.var()  # skin
            for _ in range(r.var()):
                r.var()  # slot
                for _ in range(r.var()):
                    r.string()  # attachment
                    frames = r.var()
                    for frame in range(frames):
                        time = r.floats(1)[0]
                        count = r.var()
                        if count:
                            r.var()  # first vertex
                            r.floats(count)
                        if selected and frame == 0 and time == 0 and count:
                            raise ValueError('Unsupported selected deformation')
                        if frame < frames-1: read_curve(r)
        draw_count = r.var()
        for frame in range(draw_count):
            time = r.floats(1)[0]
            changes = [(r.var(), r.var()) for _ in range(r.var())]
            if selected and frame == 0 and time == 0 and changes:
                raise ValueError('Unsupported selected draw order')
        event_count = r.var()
        if event_count:
            raise ValueError('Unsupported animation event timeline')
        if selected:
            found = True
            break
    if not found:
        raise ValueError(f'Animation not found: {expected_animation}')
    bones = world_bones(local_bones)
    layers = []
    for slot, (bone, key, color) in enumerate(slots):
        if key is None:
            continue
        if (slot,key) not in attachments:
            raise ValueError(f'Missing slot attachment: {slot} {key}')
        layer = attachments[slot,key]
        layer['color'] = color
        world = []
        for vertex in layer['vertices']:
            points = [(*transform(bones[bone], x,y),weight) for bone,x,y,weight in vertex]
            world.append(tuple(sum(p[k]*p[2] for p in points) for k in (0,1)))
        layer['vertices'] = world
        layers.append(layer)
    return layers


def read_curve(r):
    curve = r.byte()
    if curve == 2:
        r.floats(4)
    elif curve not in (0,1):
        raise ValueError('Unsupported curve')


def world_bones(local_bones):
    # Spine 3.4 Bone.UpdateWorldTransform, with skeleton flips disabled.
    bones = []
    for parent, values, inherit in local_bones:
        rotation, x, y, sx, sy, shx, shy, _ = values
        rx, ry = math.radians(rotation+shx), math.radians(rotation+90+shy)
        la, lb, lc, ld = math.cos(rx)*sx, math.cos(ry)*sy, math.sin(rx)*sx, math.sin(ry)*sy
        if parent is None:
            bones.append((la,lb,lc,ld,x,y))
            continue
        x,y = transform(bones[parent],x,y)
        if inherit == (1,1):
            pa,pb,pc,pd = bones[parent][:4]
        elif inherit == (0,0):
            pa,pb,pc,pd = 1,0,0,1
        else:
            pa,pb,pc,pd = 1,0,0,1
            ancestor = parent
            while ancestor is not None:
                pparent, pv, pinherit = local_bones[ancestor]
                angle = math.radians(pv[0]); cs, sn = math.cos(angle), math.sin(angle)
                if inherit[0]:
                    pa,pb,pc,pd = pa*cs+pb*sn, pb*cs-pa*sn, pc*cs+pd*sn, pd*cs-pc*sn
                    if not pinherit[0]: break
                else:
                    psx,psy = pv[3:5]
                    za,zb,zc,zd = cs*psx,sn*psy,sn*psx,cs*psy
                    pa,pb,pc,pd = pa*za+pb*zc, pb*zd-pa*zb, pc*za+pd*zc, pd*zd-pc*zb
                    if psx >= 0: sn = -sn
                    pa,pb,pc,pd = pa*cs+pb*sn, pb*cs-pa*sn, pc*cs+pd*sn, pd*cs-pc*sn
                    if not pinherit[1]: break
                ancestor = pparent
        bones.append((pa*la+pb*lc, pa*lb+pb*ld, pc*la+pd*lc, pc*lb+pd*ld,x,y))
    return bones


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


def render_setup(layers, regions, atlas, size=256, offset_y=0):
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
        points = [((x/128+.5)*side, (.5-(y+offset_y)/128)*side) for x,y in layer['vertices']]
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
        if layer.get('color', bytes([255]*4)) != bytes([255]*4):
            rendered = Image.merge('RGBA', tuple(channel.point(lambda v, c=c: round(v*c/255))
                         for channel,c in zip(rendered.split(), layer['color'])))
        image.alpha_composite(rendered)
    return image.resize((size,size), Image.Resampling.LANCZOS)
