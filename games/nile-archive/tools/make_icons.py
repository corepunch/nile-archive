"""Draw the coin and influence icons used by the SDL interface (needs Pillow)."""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools'))
from artkit import coin  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / 'data' / 'icons'
S = 4  # supersampling


def influence(size=96):
    n = size * S
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    glow = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([n * .2, n * .2, n * .8, n * .8], fill=(160, 220, 255, 120))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(n * .08)))
    d = ImageDraw.Draw(im)
    c = n / 2
    pts = []
    for i in range(8):
        a = -math.pi / 2 + i * math.pi / 4
        r = n * (.46 if i % 2 == 0 else .13)
        pts.append((c + math.cos(a) * r, c + math.sin(a) * r))
    d.polygon(pts, fill=(205, 236, 255, 255), outline=(70, 130, 170, 255), width=int(n * .025))
    d.ellipse([c - n * .07, c - n * .07, c + n * .07, c + n * .07], fill=(255, 255, 255, 255))
    return im.resize((size, size), Image.LANCZOS)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    coin().save(OUT / 'coin.png', optimize=True)
    influence().save(OUT / 'influence.png', optimize=True)
