"""Static evaluation of the original Unity meshes, packed textures and LUT shader.

No painted replacement assets: these are time-zero renders of bundled materials.
See ART.md for shader equations, source object IDs and limits.
"""
import math
from PIL import Image


def sample(image, u, v, repeat=False):
    """Unity bilinear sampling, bottom-left UV origin, linear channel values."""
    width, height = image.size
    x, y = u * width - .5, (1 - v) * height - .5
    x0, y0 = math.floor(x), math.floor(y)
    dx, dy = x - x0, y - y0
    def pixel(px, py):
        if repeat:
            return image.getpixel((px % width, py % height))
        return image.getpixel((min(width - 1, max(0, px)), min(height - 1, max(0, py))))
    a, b, c, d = pixel(x0, y0), pixel(x0 + 1, y0), pixel(x0, y0 + 1), pixel(x0 + 1, y0 + 1)
    return tuple(((1-dy)*((1-dx)*a[k]+dx*b[k])+dy*((1-dx)*c[k]+dx*d[k]))/255 for k in range(4))


def overlay_fragment(base, highlight, tint):
    """Both recovered fragments: RGB = tint*(.8+.2*B); alpha = R*B*A*(1+G)."""
    red, _, blue, _ = base
    return tuple(tint[k] * (.8 + .2 * blue) for k in range(3)) + (min(1, red * blue * tint[3] * (1 + highlight[1])),)


def render_overlay(mesh, texture, material, bomb=False, size=256):
    from UnityPy.helpers.MeshHelper import MeshHandler
    handler = MeshHandler(mesh)
    handler.process()
    tex = texture.image.convert('RGBA')
    props = material.m_SavedProperties
    floats = dict(props.m_Floats)
    tint = dict(props.m_Colors)['_Tint']
    tint = (tint.r, tint.g, tint.b, tint.a)
    scale = dict(props.m_TexEnvs)['_MainTex'].m_Scale
    offset = dict(props.m_TexEnvs)['_MainTex'].m_Offset
    vertices = []
    for i, pos in enumerate(handler.m_Vertices):
        x, y = pos[:2]
        uv = handler.m_UV0[i][:2]
        if bomb:
            # At t=0, the vertex shader still displaces the authored star mesh slightly.
            color = handler.m_Colors[i]
            phase = color[2] / 255 * floats['_ScrollOffset'] * floats['_ScrollSpeed']
            amount = ((math.sin(phase) + 1) * .5)**5 * floats['_ScrollSize']
            x += amount * (color[0] / 255 * 2 - 1)
            y += amount * (color[1] / 255 * 2 - 1)
        secondary = (max(0, min(1, uv[0] - (0 if bomb else .5))),
                     max(0, min(1, uv[1] - (.5 if bomb else 0))))
        uv = (uv[0] * scale.x + offset.x, uv[1] * scale.y + offset.y)
        secondary = (secondary[0] * scale.x + offset.x, secondary[1] * scale.y + offset.y)
        vertices.append((x, y, uv, secondary))
    # Two samples per output pixel axis preserve the authored mesh silhouette.
    side = size * 2
    image = Image.new('RGBA', (side, side))
    pixels = image.load()
    repeat = texture.m_TextureSettings.m_WrapU == 0
    for group in handler.get_triangles():
        for triangle in group:
            points = [vertices[i] for i in triangle]
            a, b, c = points
            denominator = (b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
            if abs(denominator) < 1e-12:
                continue
            left = max(0, math.floor((min(p[0] for p in points)+.5)*side))
            right = min(side, math.ceil((max(p[0] for p in points)+.5)*side))
            top = max(0, math.floor((.5-max(p[1] for p in points))*side))
            bottom = min(side, math.ceil((.5-min(p[1] for p in points))*side))
            for py in range(top, bottom):
                y = .5-(py+.5)/side
                for px in range(left, right):
                    x = (px+.5)/side-.5
                    wa = ((b[1]-c[1])*(x-c[0])+(c[0]-b[0])*(y-c[1]))/denominator
                    wb = ((c[1]-a[1])*(x-c[0])+(a[0]-c[0])*(y-c[1]))/denominator
                    wc = 1-wa-wb
                    if min(wa, wb, wc) < -1e-8:
                        continue
                    # Secondary UVs are clamped at vertices, then interpolated (as in Metal).
                    uv, hi = [tuple(sum(w*p[j][k] for w,p in zip((wa,wb,wc), points)) for k in range(2)) for j in (2,3)]
                    rgba = overlay_fragment(sample(tex, *uv, repeat), sample(tex, *hi, repeat), tint)
                    pixels[px, py] = tuple(round(max(0, min(1, v))*255) for v in rgba)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def render_crate(sprite, lut, color):
    """Sprites/Default-LUT: U=color/10+.05, V=source red; retain source alpha.

    Unity emits premultiplied RGB. PNG stores the equivalent straight RGB.
    """
    source = sprite.convert('RGBA')
    lookup = lut.convert('RGBA')
    palette = [tuple(round(c*255) for c in sample(lookup, color/10+.05, value/255, True)[:3]) for value in range(256)]
    result = Image.new('RGBA', source.size)
    result.putdata([palette[red] + (alpha,) for red, _, _, alpha in source.getdata()])
    return result
