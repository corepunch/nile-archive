"""Generate every Relic Rush sprite procedurally (Pillow + NumPy).

    python3 games/relic-rush/tools/make_art.py

Writes games/relic-rush/data/: six gem pieces, the relic orb, camp buildings,
the camp map, the dig-site backdrop and UI icons. The map constants (river,
oasis, zones) must match `camp_buildable` in main.c.
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools'))
from artkit import (SS, canvas, coin, drop_shadow, finish, mask_from, mix, noise, outline, paste_masked,  # noqa: E402
                    radial_light, shade, solid, star)

OUT = Path(__file__).resolve().parent.parent / 'data'

# ------------------------------------------------------------------ gems

GEMS = [
    ('ruby', (222, 40, 64), 'octagon'),
    ('emerald', (34, 176, 92), 'step'),
    ('sapphire', (44, 110, 232), 'trillion'),
    ('topaz', (246, 178, 34), 'kite'),
    ('amethyst', (150, 70, 210), 'hexagon'),
    ('moonstone', (210, 236, 240), 'cabochon'),
]


def regular(n, cx, cy, r, rot=0.0, sx=1.0, sy=1.0):
    return [(cx + math.cos(rot + i * 2 * math.pi / n) * r * sx, cy + math.sin(rot + i * 2 * math.pi / n) * r * sy) for i in range(n)]


def gem_outline(kind, n):
    c = n / 2
    r = n * .42
    if kind == 'octagon':
        return regular(8, c, c, r, math.pi / 8)
    if kind == 'step':
        w, h, k = r * .82, r * .98, r * .3
        return [(c - w + k, c - h), (c + w - k, c - h), (c + w, c - h + k), (c + w, c + h - k), (c + w - k, c + h),
                (c - w + k, c + h), (c - w, c + h - k), (c - w, c - h + k)]
    if kind == 'trillion':
        return regular(3, c, c * 1.1, r * 1.12, -math.pi / 2)
    if kind == 'kite':
        return [(c, c - r * 1.02), (c + r * .8, c - r * .1), (c, c + r * 1.02), (c - r * .8, c - r * .1)]
    if kind == 'hexagon':
        return regular(6, c, c, r, 0, 1, .95)
    return None


def facet_gem(name, base, kind, size=128):
    n = size * SS
    im = canvas(size)
    c = n / 2
    light = np.array([-.55, -.75])
    if kind == 'cabochon':
        body = radial_light((n, n), (c * .75, c * .62), n * .55, (255, 255, 255), shade(base, .72))
        m = mask_from(lambda d: d.ellipse([c - n * .4, c - n * .36, c + n * .4, c + n * .4], fill=255), (n, n))
        paste_masked(im, body, m)
        # a milky inner glow and a rainbow-ish sheen typical of moonstone
        glow = mask_from(lambda d: d.ellipse([c - n * .22, c - n * .05, c + n * .26, c + n * .3], fill=110), (n, n))
        paste_masked(im, solid((n, n), (120, 200, 255)), glow.filter(ImageFilter.GaussianBlur(n * .05)))
        pink = mask_from(lambda d: d.ellipse([c - n * .3, c - n * .2, c + n * .02, c + n * .12], fill=70), (n, n))
        paste_masked(im, solid((n, n), (255, 160, 220)), pink.filter(ImageFilter.GaussianBlur(n * .05)))
        pts = None
    else:
        pts = gem_outline(kind, n)
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        table = [(cx + (x - cx) * .52, cy + (y - cy) * .52) for x, y in pts]
        d = ImageDraw.Draw(im)
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            ta, tb = table[i], table[(i + 1) % len(pts)]
            nx, ny = (a[1] + b[1]) / 2 - cy, -((a[0] + b[0]) / 2 - cx)
            nrm = np.array([-(ny), nx])
            nrm = nrm / (np.linalg.norm(nrm) + 1e-6)
            lit = float(np.dot(nrm, -light) * -1)
            k = .62 + .55 * max(-.6, min(1, lit))
            d.polygon([a, b, tb, ta], fill=shade(base, k) + (255,))
            d.line([a, ta], fill=shade(base, 1.35) + (160,), width=int(n * .006))
        tbody = radial_light((n, n), (cx - n * .08, cy - n * .1), n * .35, mix(base, (255, 255, 255), .45), shade(base, .95))
        paste_masked(im, tbody, mask_from(lambda dd: dd.polygon(table, fill=255), (n, n)))
        d.polygon(table, outline=shade(base, 1.5) + (200,), width=int(n * .008))
        m = mask_from(lambda dd: dd.polygon(pts, fill=255), (n, n))
    # specular highlight and sparkle
    hl = mask_from(lambda d: d.ellipse([c - n * .25, c - n * .3, c - n * .02, c - n * .14], fill=200), (n, n))
    hl = ImageChops.multiply(hl.filter(ImageFilter.GaussianBlur(n * .02)), m)
    paste_masked(im, solid((n, n), (255, 255, 255)), hl)
    sp = Image.new('L', (n, n), 0)
    sd = ImageDraw.Draw(sp)
    sx, sy, sr = c + n * .14, c - n * .2, n * .07
    sd.polygon([(sx, sy - sr), (sx + sr * .2, sy - sr * .2), (sx + sr, sy), (sx + sr * .2, sy + sr * .2), (sx, sy + sr),
                (sx - sr * .2, sy + sr * .2), (sx - sr, sy), (sx - sr * .2, sy - sr * .2)], fill=230)
    paste_masked(im, solid((n, n), (255, 255, 255)), ImageChops.multiply(sp, m))
    im = outline(im, int(n * .018), shade(base, .3))
    im = drop_shadow(im, (0, int(n * .03)), n * .02, 120)
    return finish(im, size)


def orb(size=128):
    n = size * SS
    im = canvas(size)
    c = n / 2
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    ang = np.arctan2(y - c, x - c)
    dist = np.sqrt((x - c) ** 2 + (y - c) ** 2) / (n * .4)
    hue = (ang / (2 * np.pi) + dist * .6) % 1.0
    hsv = np.stack([hue * 255, np.full_like(hue, 170), np.clip(255 - dist * 90, 0, 255)], -1).astype(np.uint8)
    body = Image.fromarray(hsv, 'HSV').convert('RGBA')
    m = mask_from(lambda d: d.ellipse([c - n * .4, c - n * .4, c + n * .4, c + n * .4], fill=255), (n, n))
    paste_masked(im, body, m)
    core = mask_from(lambda d: d.ellipse([c - n * .17, c - n * .17, c + n * .17, c + n * .17], fill=255), (n, n))
    paste_masked(im, solid((n, n), (255, 250, 225)), core.filter(ImageFilter.GaussianBlur(n * .06)))
    hl = mask_from(lambda d: d.ellipse([c - n * .28, c - n * .33, c - n * .02, c - n * .17], fill=210), (n, n))
    paste_masked(im, solid((n, n), (255, 255, 255)), hl.filter(ImageFilter.GaussianBlur(n * .02)))
    d = ImageDraw.Draw(im)
    d.ellipse([c - n * .4, c - n * .4, c + n * .4, c + n * .4], outline=(255, 220, 120, 255), width=int(n * .03))
    im = outline(im, int(n * .014), (90, 50, 20))
    return finish(drop_shadow(im, (0, int(n * .03)), n * .02, 120), size)

# ------------------------------------------------------------- buildings

ISO = (math.cos(math.radians(30)), .5)


def iso(origin, x, y, z, s):
    return (origin[0] + (x - y) * ISO[0] * s, origin[1] + (x + y) * ISO[1] * s - z * s)


def box(d, o, s, x0, y0, z0, w, l, h, top, left, right, edge=None):
    P = lambda x, y, z: iso(o, x, y, z, s)
    x1, y1, z1 = x0 + w, y0 + l, z0 + h
    d.polygon([P(x0, y1, z0), P(x1, y1, z0), P(x1, y1, z1), P(x0, y1, z1)], fill=left)
    d.polygon([P(x1, y0, z0), P(x1, y1, z0), P(x1, y1, z1), P(x1, y0, z1)], fill=right)
    d.polygon([P(x0, y0, z1), P(x1, y0, z1), P(x1, y1, z1), P(x0, y1, z1)], fill=top)
    if edge:
        w_ = max(1, int(s * .03))
        d.line([P(x0, y1, z1), P(x1, y1, z1), P(x1, y0, z1)], fill=edge, width=w_)
        d.line([P(x1, y1, z0), P(x1, y1, z1)], fill=edge, width=w_)


def gable(d, o, s, x0, y0, z0, w, l, h, roof_l, roof_r, gable_c):
    """Roof ridge along y over a w x l footprint."""
    P = lambda x, y, z: iso(o, x, y, z, s)
    xm = x0 + w / 2
    d.polygon([P(x0, y0, z0), P(x0, y0 + l, z0), P(xm, y0 + l, z0 + h), P(xm, y0, z0 + h)], fill=roof_l)
    d.polygon([P(x0, y0 + l, z0), P(x0 + w, y0 + l, z0), P(xm, y0 + l, z0 + h)], fill=gable_c)
    d.polygon([P(x0 + w, y0, z0), P(x0 + w, y0 + l, z0), P(xm, y0 + l, z0 + h), P(xm, y0, z0 + h)], fill=roof_r)


def pyramid(d, o, s, x0, y0, z0, w, l, h, left, right):
    P = lambda x, y, z: iso(o, x, y, z, s)
    apex = P(x0 + w / 2, y0 + l / 2, z0 + h)
    d.polygon([P(x0, y0 + l, z0), P(x0 + w, y0 + l, z0), apex], fill=left)
    d.polygon([P(x0 + w, y0, z0), P(x0 + w, y0 + l, z0), apex], fill=right)


SAND = (222, 190, 132)
STONE = (214, 186, 140)


def ground_shadow(d, o, s, w, l):
    P = lambda x, y: iso(o, x, y, 0, s)
    pts = [P(-.15, -.15), P(w + .25, -.15), P(w + .25, l + .25), P(-.15, l + .25)]
    d.polygon(pts, fill=(60, 40, 20, 70))


def building(name, fn, size=256):
    n = size * SS
    im = canvas((size, int(size * 1.5)))
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    o = (n / 2, n * .95)
    s = n * .2
    fn(ImageDraw.Draw(im), ImageDraw.Draw(sh), o, s)
    sh = sh.filter(ImageFilter.GaussianBlur(n * .012))
    sh.alpha_composite(im)
    bbox = sh.getbbox()
    out = sh.crop(bbox)
    out = out.resize((max(1, out.width // SS), max(1, out.height // SS)), Image.LANCZOS)
    return out


def b_tent(d, sh, o, s):
    ground_shadow(sh, o, s, 2, 2.2)
    canvas_c = (238, 224, 190)
    gable(d, o, s, 0, 0, 0, 2, 2.2, 1.5, shade(canvas_c, .85), shade(canvas_c, 1.0), shade(canvas_c, .72))
    P = lambda x, y, z: iso(o, x, y, z, s)
    d.polygon([P(.75, 2.2, 0), P(1.25, 2.2, 0), P(1, 2.2, .9)], fill=(70, 50, 35))
    d.line([P(1, 1.1, 1.5), P(1, 1.1, 2.3)], fill=(90, 60, 40), width=int(s * .05))
    d.polygon([P(1, 1.1, 2.3), P(1, 1.65, 2.15), P(1, 1.1, 2.0)], fill=(214, 64, 52))
    box(d, o, s, 2.15, 1.5, 0, .45, .45, .4, (176, 128, 74), (140, 98, 56), (120, 84, 48))
    box(d, o, s, 2.2, .9, 0, .35, .35, .3, (186, 138, 84), (150, 108, 66), (130, 92, 56))


def b_dig(d, sh, o, s):
    ground_shadow(sh, o, s, 2.6, 2.6)
    P = lambda x, y, z: iso(o, x, y, z, s)
    box(d, o, s, 0, 0, 0, 2.6, 2.6, .12, (196, 160, 104), (160, 124, 78), (150, 116, 72))
    d.polygon([P(.35, .35, .12), P(2.25, .35, .12), P(2.25, 2.25, .12), P(.35, 2.25, .12)], fill=(92, 64, 40))
    d.polygon([P(.35, .35, .12), P(2.25, .35, .12), P(2.25, .55, -.1), P(.55, .55, -.1)], fill=(70, 48, 30))
    for i in range(3):
        y = .55 + i * .55
        d.line([P(.5, y, .12), P(2.1, y, .12)], fill=(200, 170, 120), width=int(s * .03))
    beam = (150, 104, 60)
    for x, y in [(.1, .1), (2.4, .1), (.1, 2.4), (2.4, 2.4)]:
        box(d, o, s, x, y, 0, .12, .12, 1.4, shade(beam, 1.1), beam, shade(beam, .8))
    box(d, o, s, .1, .1, 1.4, 2.42, .12, .12, shade(beam, 1.15), beam, shade(beam, .8))
    box(d, o, s, .1, 2.4, 1.4, 2.42, .12, .12, shade(beam, 1.15), beam, shade(beam, .8))
    d.line([P(1.3, 2.45, 1.4), P(1.3, 1.3, .3)], fill=(60, 50, 40), width=int(s * .02))
    box(d, o, s, 1.15, 1.15, .12, .3, .3, .25, (130, 130, 140), (100, 100, 110), (80, 80, 90))
    d.ellipse([*P(2.6, .4, 0), *(lambda p: (p[0] + s * .6, p[1] + s * .3))(P(2.6, .4, 0))], fill=(230, 200, 140))


def b_workshop(d, sh, o, s):
    ground_shadow(sh, o, s, 2.2, 2)
    wall = (206, 160, 112)
    box(d, o, s, 0, 0, 0, 2.2, 2, 1.25, shade(wall, 1.15), shade(wall, .95), shade(wall, .78), shade(wall, .6))
    box(d, o, s, -.05, -.05, 1.25, 2.3, 2.1, .12, shade(wall, 1.25), shade(wall, 1.0), shade(wall, .82))
    P = lambda x, y, z: iso(o, x, y, z, s)
    d.polygon([P(.7, 2, 0), P(1.3, 2, 0), P(1.3, 2, .85), P(.7, 2, .85)], fill=(80, 54, 36))
    stripes = [(210, 70, 60), (245, 230, 200)]
    for i in range(5):
        x = .3 + i * .32
        d.polygon([P(x, 2, 1.05), P(x + .32, 2, 1.05), P(x + .32, 2.55, .75), P(x, 2.55, .75)], fill=stripes[i % 2])
    d.polygon([P(2.2, .5, .5), P(2.2, 1.2, .5), P(2.2, 1.2, .95), P(2.2, .5, .95)], fill=(60, 44, 32))
    box(d, o, s, 2.35, 1.6, 0, .4, .4, .35, (176, 128, 74), (140, 98, 56), (120, 84, 48))
    box(d, o, s, 2.4, 1.65, .35, .3, .3, .28, (186, 138, 84), (150, 108, 66), (130, 92, 56))
    box(d, o, s, 1.4, .4, 1.37, .3, .3, .6, (180, 150, 130), (150, 120, 100), (120, 96, 80))


def b_market(d, sh, o, s):
    ground_shadow(sh, o, s, 2.4, 2.4)
    wood = (150, 104, 60)
    box(d, o, s, .2, .2, 0, 2, 2, .6, (196, 150, 96), (170, 124, 76), (140, 100, 60))
    for x, y in [(.2, .2), (2.1, .2), (.2, 2.1), (2.1, 2.1)]:
        box(d, o, s, x, y, .6, .1, .1, .9, shade(wood, 1.1), wood, shade(wood, .8))
    cols = [(46, 140, 196), (250, 236, 206)]
    P = lambda x, y, z: iso(o, x, y, z, s)
    apex = P(1.2, 1.2, 2.4)
    corners = [(0, 0), (2.4, 0), (2.4, 2.4), (0, 2.4)]
    for f in range(2):
        a, b = corners[f + 1], corners[(f + 2) % 4]
        for i in range(4):
            t0, t1 = i / 4, (i + 1) / 4
            p0 = (a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0)
            p1 = (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)
            c = shade(cols[i % 2], 1.0 if f == 1 else .82)
            d.polygon([P(p0[0], p0[1], 1.5), P(p1[0], p1[1], 1.5), apex], fill=c)
    for i, c in enumerate([(220, 120, 40), (190, 60, 50), (240, 200, 70)]):
        p = P(.6 + i * .5, 2.25, .6)
        d.ellipse([p[0] - s * .18, p[1] - s * .3, p[0] + s * .18, p[1] + s * .05], fill=c)
    p = P(2.6, 1.6, 0)
    d.ellipse([p[0] - s * .25, p[1] - s * .55, p[0] + s * .25, p[1]], fill=(170, 90, 50))
    d.ellipse([p[0] - s * .12, p[1] - s * .62, p[0] + s * .12, p[1] - s * .48], fill=(120, 60, 34))


def b_museum(d, sh, o, s):
    ground_shadow(sh, o, s, 3, 2.4)
    st = STONE
    box(d, o, s, -.1, -.1, 0, 3.2, 2.6, .25, shade(st, 1.15), shade(st, .95), shade(st, .8))
    box(d, o, s, .2, .2, .25, 2.6, 1.6, 1.45, shade(st, 1.1), shade(st, .9), shade(st, .75), shade(st, .6))
    P = lambda x, y, z: iso(o, x, y, z, s)
    for i in range(5):
        x = .25 + i * .6
        box(d, o, s, x, 2.0, .25, .18, .18, 1.45, shade(st, 1.2), shade(st, 1.0), shade(st, .8))
    box(d, o, s, .1, .1, 1.7, 2.8, 2.2, .18, shade(st, 1.2), shade(st, 1.0), shade(st, .8), shade(st, .6))
    gable(d, o, s, .1, .1, 1.88, 2.8, 2.2, .7, shade((180, 80, 60), .9), (180, 80, 60), shade(st, 1.05))
    d.polygon([P(1.2, 1.8, .25), P(1.8, 1.8, .25), P(1.8, 1.8, 1.0), P(1.2, 1.8, 1.0)], fill=(70, 50, 36))
    p = P(1.5, 2.3, 2.2)
    d.ellipse([p[0] - s * .12, p[1] - s * .12, p[0] + s * .12, p[1] + s * .12], fill=(240, 200, 90))


def b_obelisk(d, sh, o, s):
    ground_shadow(sh, o, s, 1.6, 1.6)
    st = (226, 196, 140)
    box(d, o, s, 0, 0, 0, 1.6, 1.6, .3, shade(st, 1.15), shade(st, .95), shade(st, .8), shade(st, .6))
    box(d, o, s, .2, .2, .3, 1.2, 1.2, .2, shade(st, 1.2), shade(st, 1.0), shade(st, .82))
    P = lambda x, y, z: iso(o, x, y, z, s)
    b0, b1, top = .45, 1.15, 3.6
    t0, t1 = .55, 1.05
    d.polygon([P(b0, b1, .5), P(b1, b1, .5), P(t1, t1, top), P(t0, t1, top)], fill=shade(st, .92))
    d.polygon([P(b1, b0, .5), P(b1, b1, .5), P(t1, t1, top), P(t1, t0, top)], fill=shade(st, .75))
    apex = P(.8, .8, top + .45)
    d.polygon([P(t0, t1, top), P(t1, t1, top), apex], fill=(250, 210, 90))
    d.polygon([P(t1, t0, top), P(t1, t1, top), apex], fill=(205, 160, 50))
    for i in range(6):
        z = .9 + i * .42
        p = P(.8, 1.12, z)
        d.rectangle([p[0] - s * .07, p[1] - s * .07, p[0] + s * .07, p[1] + s * .03], fill=shade(st, .6))


BUILDINGS = [('tent', b_tent), ('dig', b_dig), ('workshop', b_workshop), ('market', b_market), ('museum', b_museum), ('obelisk', b_obelisk)]

# ------------------------------------------------------------------ maps

W, H = 2400, 1600
RIVER_X, RIVER_AMP, RIVER_W = 250, 90, 170          # river centre x = RIVER_X + RIVER_AMP*sin(y/260)
OASIS_C, OASIS_R = (1650, 1180), (190, 110)


def camp_map():
    rs = np.random.RandomState(7)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    n1 = noise((H, W), 420, 5, 1)
    n2 = noise((H, W), 60, 3, 2)
    dunes = np.sin((x * .6 + y) / 70 + n1 * 9) * .5 + .5
    sand = np.array([226, 192, 132], np.float32)
    col = sand[None, None, :] * (0.86 + n1[..., None] * .22 + dunes[..., None] * .06 + n2[..., None] * .05)

    river_x = RIVER_X + RIVER_AMP * np.sin(y / 260)
    dr = np.abs(x - river_x) - RIVER_W / 2
    do = np.sqrt(((x - OASIS_C[0]) / OASIS_R[0]) ** 2 + ((y - OASIS_C[1]) / OASIS_R[1]) ** 2) - 1
    do_px = do * min(OASIS_R)
    water_d = np.minimum(dr, do_px)
    green = np.clip(1 - (water_d - n2 * 60) / 160, 0, 1) ** 1.4
    grass = np.array([118, 150, 64], np.float32) * (0.8 + n2[..., None] * .4)
    col = col * (1 - green[..., None]) + grass * green[..., None]
    wet = np.clip(1 - water_d / 18, 0, 1)
    col = col * (1 - wet[..., None] * .35)
    water = np.clip(-water_d / 6, 0, 1)
    deep = np.clip(-water_d / 70, 0, 1)
    wc = np.array([64, 170, 190], np.float32) * (1 - deep[..., None]) + np.array([24, 96, 140], np.float32) * deep[..., None]
    wc = wc * (0.92 + n2[..., None] * .16)
    col = col * (1 - water[..., None]) + wc * water[..., None]
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')

    over = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    # a stone road through the camp
    pts = [(560, 820 + 60 * math.sin(i / 3)) for i in range(0)]
    for i in range(60):
        t = i / 59
        px = 520 + t * 1800
        py = 820 + math.sin(t * 5) * 90
        pts.append((px, py))
    d.line(pts, fill=(200, 172, 124, 255), width=70, joint='curve')
    d.line(pts, fill=(214, 188, 140, 255), width=52, joint='curve')
    for px, py in pts[::2]:
        for _ in range(3):
            ox, oy = rs.uniform(-22, 22), rs.uniform(-18, 18)
            d.ellipse([px + ox - 7, py + oy - 5, px + ox + 7, py + oy + 5], fill=(186, 160, 116, 255))
    # ruins: broken columns and blocks, rocks
    def column(cx, cy, h):
        d.ellipse([cx - 22, cy - 9, cx + 22, cy + 9], fill=(120, 96, 70, 120))
        d.rectangle([cx - 14, cy - h, cx + 14, cy], fill=(214, 190, 150, 255))
        d.rectangle([cx + 4, cy - h, cx + 14, cy], fill=(180, 156, 118, 255))
        d.ellipse([cx - 14, cy - h - 6, cx + 14, cy - h + 6], fill=(232, 214, 176, 255))
    for cx, cy, h in [(700, 330, 60), (760, 300, 90), (2150, 360, 70), (2240, 420, 40), (1300, 1420, 55), (1980, 1380, 80)]:
        column(cx, cy, h)
    for _ in range(60):
        cx, cy = rs.uniform(450, 2380), rs.uniform(120, 1560)
        if abs(cx - (RIVER_X + RIVER_AMP * math.sin(cy / 260))) < 200:
            continue
        r = rs.uniform(6, 16)
        d.ellipse([cx - r * 1.4, cy - r * .3, cx + r * 1.4, cy + r * .9], fill=(110, 86, 60, 90))
        d.ellipse([cx - r, cy - r * .8, cx + r, cy + r * .6], fill=(170, 140, 100, 255))
        d.ellipse([cx - r * .6, cy - r * .7, cx + r * .3, cy - r * .1], fill=(200, 172, 128, 255))

    def palm(cx, cy, h):
        d.ellipse([cx - 46, cy - 10, cx + 46, cy + 12], fill=(40, 60, 20, 70))
        lean = rs.uniform(-.35, .35)
        segs = 12
        pts_l, pts_r = [], []
        for i in range(segs + 1):
            t = i / segs
            px = cx + math.sin(t * 1.6) * 40 * lean
            py = cy - t * h
            w = 8 - t * 3.5
            pts_l.append((px - w, py))
            pts_r.append((px + w, py))
        d.polygon(pts_l + pts_r[::-1], fill=(122, 86, 48, 255))
        for i in range(1, segs):
            a, b = pts_l[i], pts_r[i]
            d.line([a, b], fill=(96, 66, 36, 255), width=2)
        tx, ty = (pts_l[-1][0] + pts_r[-1][0]) / 2, pts_l[-1][1]
        for k in range(9):
            a = math.pi + k * math.pi / 8 + rs.uniform(-.12, .12)
            length = rs.uniform(52, 70)
            droop = 30 + abs(math.cos(a)) * 10
            tip = (tx + math.cos(a) * length, ty + math.sin(a) * length * .45 + droop)
            mid = (tx + math.cos(a) * length * .55, ty + math.sin(a) * length * .3 - 6)
            nx, ny = -math.sin(a) * 9, math.cos(a) * 5
            shade_k = .75 + .25 * (k / 8)
            leaf = (int(70 * shade_k), int(138 * shade_k), int(52 * shade_k), 255)
            d.polygon([(tx, ty), (mid[0] + nx, mid[1] + ny), tip, (mid[0] - nx, mid[1] - ny)], fill=leaf)
            d.line([(tx, ty), mid, tip], fill=(46, 96, 36, 255), width=2)
        d.ellipse([tx - 7, ty - 5, tx + 7, ty + 7], fill=(92, 64, 34, 255))

    def bush(cx, cy, r):
        d.ellipse([cx - r * 1.3, cy - r * .2, cx + r * 1.3, cy + r * .6], fill=(60, 70, 20, 70))
        for k in range(5):
            ox, oy = rs.uniform(-r * .7, r * .7), rs.uniform(-r * .5, r * .1)
            rr = r * rs.uniform(.45, .7)
            c = (int(rs.uniform(90, 120)), int(rs.uniform(120, 150)), 56, 255)
            d.ellipse([cx + ox - rr, cy + oy - rr * .8, cx + ox + rr, cy + oy + rr * .6], fill=c)

    for _ in range(90):
        cx, cy = rs.uniform(420, 2380), rs.uniform(60, 1580)
        rx = RIVER_X + RIVER_AMP * math.sin(cy / 260)
        if abs(cx - rx) < 240:
            continue
        if ((cx - OASIS_C[0]) / OASIS_R[0]) ** 2 + ((cy - OASIS_C[1]) / OASIS_R[1]) ** 2 < 1.4:
            continue
        bush(cx, cy, rs.uniform(10, 20))

    trees = []
    for i in range(70):
        yy = rs.uniform(30, H - 20)
        rx = RIVER_X + RIVER_AMP * math.sin(yy / 260)
        side = 1 if i % 2 else -1
        trees.append((rx + side * rs.uniform(RIVER_W / 2 + 25, RIVER_W / 2 + 110), yy, rs.uniform(70, 120)))
    for i in range(14):
        a = rs.uniform(0, 2 * math.pi)
        trees.append((OASIS_C[0] + math.cos(a) * (OASIS_R[0] + 40), OASIS_C[1] + math.sin(a) * (OASIS_R[1] + 30), rs.uniform(70, 110)))
    for cx, cy, h in sorted(trees, key=lambda t: t[1]):
        palm(cx, cy, h)
    img.alpha_composite(over)
    vign = radial_light((W, H), (W / 2, H / 2), W * .75, (255, 255, 255), (170, 150, 120))
    img = ImageChops.multiply(img, vign)
    return img.convert('RGB')


def dig_backdrop(w=1600, h=1000):
    n1 = noise((h, w), 300, 5, 11)
    n2 = noise((h, w), 30, 3, 12)
    base = np.array([176, 128, 82], np.float32)
    col = base * (0.7 + n1[..., None] * .45 + n2[..., None] * .1)
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    rows = (y // 90).astype(int)
    off = (rows % 2) * 110
    mortar = ((y % 90) < 5) | (((x + off) % 220) < 5)
    col[mortar] *= .62
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')
    d = ImageDraw.Draw(img)
    rs = np.random.RandomState(3)
    carve = (110, 76, 46, 255)
    for i in range(26):
        cx, cy = rs.uniform(60, w - 60), rs.uniform(60, h - 60)
        k = rs.randint(5)
        if k == 0:
            d.ellipse([cx - 24, cy - 14, cx + 24, cy + 14], outline=carve, width=5)
            d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=carve)
        elif k == 1:
            d.line([cx, cy - 30, cx, cy + 30], fill=carve, width=6)
            d.ellipse([cx - 14, cy - 52, cx + 14, cy - 26], outline=carve, width=6)
            d.line([cx - 20, cy - 18, cx + 20, cy - 18], fill=carve, width=6)
        elif k == 2:
            d.polygon([(cx - 30, cy + 20), (cx, cy - 26), (cx + 30, cy + 20)], outline=carve)
            d.line([(cx - 30, cy + 20), (cx, cy - 26), (cx + 30, cy + 20), (cx - 30, cy + 20)], fill=carve, width=5)
        elif k == 3:
            for j in range(3):
                d.arc([cx - 30 + j * 20, cy - 10, cx - 10 + j * 20, cy + 10], 0, 180, fill=carve, width=5)
        else:
            d.line([cx - 26, cy, cx + 26, cy], fill=carve, width=5)
            d.line([cx - 26, cy, cx - 10, cy - 18], fill=carve, width=5)
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for cx in (140, w - 140):
        gd.ellipse([cx - 260, 100, cx + 260, 620], fill=(255, 170, 60, 90))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))
    vign = radial_light((w, h), (w / 2, h / 2), w * .62, (255, 255, 255), (80, 56, 40))
    return ImageChops.multiply(img, vign).convert('RGB')


def moves_icon(size=96):
    n = size * SS
    im = canvas(size)
    d = ImageDraw.Draw(im)
    c = n / 2
    sand = (240, 200, 120, 255)
    glass = (220, 240, 250, 200)
    d.polygon([(c - n * .26, n * .14), (c + n * .26, n * .14), (c + n * .04, c), (c + n * .26, n * .86), (c - n * .26, n * .86),
               (c - n * .04, c)], fill=glass)
    d.polygon([(c - n * .16, n * .26), (c + n * .16, n * .26), (c, c - n * .06)], fill=sand)
    d.polygon([(c - n * .2, n * .82), (c + n * .2, n * .82), (c, n * .6)], fill=sand)
    d.rectangle([c - n * .32, n * .08, c + n * .32, n * .15], fill=(150, 96, 50, 255))
    d.rectangle([c - n * .32, n * .85, c + n * .32, n * .92], fill=(150, 96, 50, 255))
    return finish(outline(im, int(n * .02), (70, 40, 20)), size)


def main():
    (OUT / 'pieces').mkdir(parents=True, exist_ok=True)
    (OUT / 'buildings').mkdir(parents=True, exist_ok=True)
    (OUT / 'icons').mkdir(parents=True, exist_ok=True)
    for i, (name, base, kind) in enumerate(GEMS):
        facet_gem(name, base, kind).save(OUT / 'pieces' / f'{i}.png', optimize=True)
    orb().save(OUT / 'pieces' / 'orb.png', optimize=True)
    for i, (name, fn) in enumerate(BUILDINGS):
        building(name, fn).save(OUT / 'buildings' / f'{i}.png', optimize=True)
    coin().save(OUT / 'icons' / 'coin.png', optimize=True)
    star().save(OUT / 'icons' / 'star.png', optimize=True)
    moves_icon().save(OUT / 'icons' / 'moves.png', optimize=True)
    camp_map().save(OUT / 'camp.jpg', quality=88)
    dig_backdrop().save(OUT / 'backdrop.jpg', quality=86)


if __name__ == '__main__':
    main()
