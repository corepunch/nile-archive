#!/usr/bin/env python3
"""Draw the completed-goal checkmark badge (data/expedition-hud/goal-check.png).

A met goal shows this badge in place of its count, as Relic Rush's authored
check medallion and Candy Crush's goal ticks do. The market's star wreath stays
the Stars/score icon, so a finished goal never reads as a star objective.
Rendered at 4x and downsampled for smooth edges; deterministic.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "expedition-hud", "goal-check.png")
SIZE, K = 128, 4
S = SIZE * K
C = S / 2


def radial(r_outer, inner, outer, center=(C, C - 6 * K)):
    """A disc whose colour runs from `inner` at `center` to `outer` at its rim."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 64
    for i in range(steps, 0, -1):
        t = i / steps
        col = tuple(int(inner[k] + (outer[k] - inner[k]) * t) for k in range(3)) + (255,)
        r = r_outer * t
        cx = C + (center[0] - C) * (1 - t)
        cy = C + (center[1] - C) * (1 - t)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((C - r_outer, C - r_outer, C + r_outer, C + r_outer), fill=255)
    layer.putalpha(mask)
    return layer


def linear(r_outer, top, bottom):
    """A disc lit from above: `top` colour at its top edge, `bottom` at its foot."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for y in range(int(C - r_outer), int(C + r_outer) + 1):
        t = (y - (C - r_outer)) / (2 * r_outer)
        d.line((0, y, S, y), fill=tuple(int(top[k] + (bottom[k] - top[k]) * t) for k in range(3)) + (255,))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((C - r_outer, C - r_outer, C + r_outer, C + r_outer), fill=255)
    layer.putalpha(mask)
    return layer


def main():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # soft drop shadow
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((C - 56 * K, C - 52 * K, C + 56 * K, C + 60 * K), fill=(10, 30, 27, 140))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4 * K)))
    d = ImageDraw.Draw(img)
    # wooden rim, then the gold ring
    d.ellipse((C - 57 * K, C - 57 * K, C + 57 * K, C + 57 * K), fill=(102, 68, 39, 255))
    img.alpha_composite(linear(54 * K, (255, 244, 186), (214, 138, 38)))
    # four gold studs, as on the market's medallions
    d = ImageDraw.Draw(img)
    for a in range(4):
        ang = a * math.pi / 2 - math.pi / 2
        x, y = C + math.cos(ang) * 50 * K, C + math.sin(ang) * 50 * K
        d.ellipse((x - 6 * K, y - 6 * K, x + 6 * K, y + 6 * K), fill=(138, 90, 36, 255))
        d.ellipse((x - 4.5 * K, y - 5 * K, x + 4.5 * K, y + 4 * K), fill=(255, 231, 163, 255))
    # inner rim and evergreen face
    img.alpha_composite(linear(43 * K, (150, 92, 32), (255, 226, 140)))   # bevel: dark above, lit below
    img.alpha_composite(radial(41 * K, (78, 170, 102), (18, 72, 46)))
    # gloss over the top of the face
    gloss = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse((C - 30 * K, C - 38 * K, C + 30 * K, C - 6 * K), fill=(255, 255, 255, 52))
    img.alpha_composite(gloss.filter(ImageFilter.GaussianBlur(3 * K)))
    # the tick: shadow, dark outline, cream stroke
    pts = [(C - 22 * K, C + 1 * K), (C - 6 * K, C + 17 * K), (C + 24 * K, C - 17 * K)]
    d = ImageDraw.Draw(img)

    def stroke(points, width, fill, offset=(0, 0)):
        p = [(x + offset[0], y + offset[1]) for x, y in points]
        d.line(p, fill=fill, width=int(width), joint="curve")
        for x, y in (p[0], p[-1]):
            d.ellipse((x - width / 2, y - width / 2, x + width / 2, y + width / 2), fill=fill)

    stroke(pts, 19 * K, (8, 40, 26, 150), (0, 3 * K))
    stroke(pts, 19 * K, (13, 54, 43, 255))
    stroke(pts, 12 * K, (255, 249, 226, 255))
    stroke([(x, y - 1.5 * K) for x, y in pts], 4 * K, (255, 255, 255, 120))
    img.resize((SIZE, SIZE), Image.LANCZOS).save(OUT)
    print("wrote", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
