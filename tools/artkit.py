"""Shared helpers for the procedural art scripts (Pillow + NumPy).

Everything is drawn supersampled and downscaled with Lanczos so edges come out
anti-aliased. Used by games/*/tools/*.py.
"""
import math

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SS = 4  # supersampling factor


def canvas(size):
    w, h = (size, size) if isinstance(size, int) else size
    return Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))


def finish(im, size):
    w, h = (size, size) if isinstance(size, int) else size
    return im.resize((w, h), Image.LANCZOS)


def mask_from(draw_fn, size):
    m = Image.new('L', size, 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def solid(size, rgb, alpha=255):
    return Image.new('RGBA', size, tuple(rgb) + (alpha,))


def paste_masked(dst, src, mask):
    dst.alpha_composite(Image.composite(src, Image.new('RGBA', dst.size, (0, 0, 0, 0)), mask))


def radial_light(size, center, radius, inner, outer):
    """RGB image fading from `inner` at center to `outer` at radius."""
    w, h = size
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((x - center[0]) ** 2 + (y - center[1]) ** 2) / radius
    t = np.clip(d, 0, 1)[..., None]
    rgb = np.array(inner, np.float32) * (1 - t) + np.array(outer, np.float32) * t
    return Image.fromarray(rgb.astype(np.uint8), 'RGB').convert('RGBA')


def shade(rgb, k):
    return tuple(int(max(0, min(255, c * k))) for c in rgb)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def drop_shadow(im, offset, blur, alpha=110):
    a = im.getchannel('A').point(lambda v: v * alpha // 255)
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.alpha_composite(sh, offset)
    out.alpha_composite(im)
    return out


def outline(im, width, rgb):
    a = im.getchannel('A').filter(ImageFilter.MaxFilter(width * 2 + 1))
    ol = Image.new('RGBA', im.size, tuple(rgb) + (0,))
    ol.putalpha(a)
    ol.alpha_composite(im)
    return ol


def noise(shape, scale, octaves=4, seed=0):
    """Fractal value noise in [0,1], shape=(h, w), `scale` = size of the largest blob in px."""
    rs = np.random.RandomState(seed)
    h, w = shape
    out = np.zeros(shape, np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        s = max(1.0, scale / (2 ** o))
        gw, gh = int(w / s) + 2, int(h / s) + 2
        grid = (rs.rand(gh, gw) * 255).astype(np.uint8)
        layer = np.asarray(Image.fromarray(grid, 'L').resize((int(gw * s), int(gh * s)), Image.BICUBIC), np.float32)[:h, :w] / 255
        out += layer * amp
        total += amp
        amp *= 0.5
    return out / total


def coin(size=96):
    n = size * SS
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pad = n * .06
    d.ellipse([pad, pad + n * .03, n - pad, n - pad + n * .03], fill=(120, 78, 22, 255))
    d.ellipse([pad, pad, n - pad, n - pad], fill=(226, 176, 82, 255))
    inner = n * .17
    d.ellipse([inner, inner, n - inner, n - inner], fill=(246, 214, 132, 255), outline=(170, 118, 40, 255), width=int(n * .035))
    c, r = n / 2, n * .2
    d.polygon([(c, c - r), (c + r, c), (c, c + r), (c - r, c)], fill=(170, 118, 40, 255))
    r2 = r * .45
    d.polygon([(c, c - r2), (c + r2, c), (c, c + r2), (c - r2, c)], fill=(250, 232, 180, 255))
    return im.resize((size, size), Image.LANCZOS)


def star_points(cx, cy, r_out, r_in, points=5, rot=-math.pi / 2):
    pts = []
    for i in range(points * 2):
        a = rot + i * math.pi / points
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def star(size=96, fill=(255, 205, 70), edge=(150, 90, 20)):
    n = size * SS
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    c = n / 2
    pts = star_points(c, c * 1.04, n * .46, n * .2)
    body = radial_light((n, n), (c * .8, c * .6), n * .6, shade(fill, 1.25), shade(fill, .8))
    m = mask_from(lambda d: d.polygon(pts, fill=255), (n, n))
    paste_masked(im, body, m)
    d = ImageDraw.Draw(im)
    d.polygon(pts, outline=tuple(edge) + (255,), width=int(n * .03))
    hl = mask_from(lambda d: d.ellipse([c * .62, c * .5, c * .95, c * .78], fill=150), (n, n)).filter(ImageFilter.GaussianBlur(n * .02))
    paste_masked(im, solid((n, n), (255, 255, 255)), ImageChops.multiply(hl, m))
    return im.resize((size, size), Image.LANCZOS)
