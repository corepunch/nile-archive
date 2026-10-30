#!/usr/bin/env python3
"""Draws each footprint from the grid formula over the render, independently of Blender,
and measures where the rendered footprint lines sit relative to that formula. The line is
drawn just outside the base, so a small positive offset below the edge (under 1 px) is expected."""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "preview", "scene.png")
DST = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "preview", "scene-grid-check.png")
layout = json.load(open(os.path.join(HERE, "scene_layout.json")))
ox, oy = layout["origin_px"]
half_w, half_h = layout["tile_px"][0] / 2, layout["tile_px"][1] / 2


def screen(u, v):
    return ox + (u - v) * half_w, oy + (u + v) * half_h


im = Image.open(SRC).convert("RGB")
px = im.load()
out = im.copy()
draw = ImageDraw.Draw(out)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 17)
except OSError:
    font = ImageFont.load_default()

results = []
for b in layout["buildings"]:
    u0, v0, w, h = b["u0"], b["v0"], b["w"], b["h"]
    left, front, right, back = screen(u0, v0 + h), screen(u0 + w, v0 + h), screen(u0 + w, v0), screen(u0, v0)
    # find the rendered cream line near each front edge: its centre, relative to the formula's edge
    offsets = []
    for a, c in ((left, front), (front, right)):
        steps = int(abs(c[0] - a[0]))
        for i in range(6, steps - 6, 2):
            x, y = a[0] + (c[0] - a[0]) * i / steps, a[1] + (c[1] - a[1]) * i / steps
            col = [(dy, px[int(x), int(y) + dy]) for dy in range(-3, 7)]
            bright = [dy for dy, (r, g, bl) in col if r > 150 and g > 150 and bl > 90 and bl < r]
            if bright:
                offsets.append(sum(bright) / len(bright))
    offsets.sort()
    results.append((b["key"], f"{w}x{h}", u0, v0, len(offsets), f"median {offsets[len(offsets) // 2]:+.1f}px" if offsets else "no line"))
    draw.line([left, front, right, back, left], fill=(255, 0, 180), width=2)
    cx, cy = screen(u0 + w / 2, v0 + h / 2)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 0, 180), outline=(255, 255, 255))
    label = f"{b['title']}  {w}×{h}"
    tw = draw.textlength(label, font=font)
    draw.text((front[0] - tw / 2, front[1] + 7), label, font=font, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 40, 15))
out.save(DST)
for row in results:
    print(*row)
