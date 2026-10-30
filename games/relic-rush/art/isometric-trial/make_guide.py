"""Draw a geometry reference for the complete building-atlas ImageGen trial.

This is a guide, never runtime artwork. Each slab top is exactly 280 x 140
pixels; its centre is the building's ground pivot. Requires existing Pillow.
"""
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
im = Image.new("RGBA", (2000, 1200), (246, 243, 231, 255))
draw = ImageDraw.Draw(im)
for i in range(10):
    x, y = 200 + i % 5 * 400, 490 + i // 5 * 600
    left, back, right, front = (x - 140, y), (x, y - 70), (x + 140, y), (x, y + 70)
    draw.polygon([left, front, (x, y + 82), (x - 140, y + 12)], fill=(153, 129, 94), outline=(64, 61, 49))
    draw.polygon([front, right, (x + 140, y + 12), (x, y + 82)], fill=(123, 109, 82), outline=(64, 61, 49))
    draw.polygon([left, back, right, front], fill=(221, 204, 163), outline=(64, 61, 49), width=2)
    # All ground lines obey dy/dx = +/- 0.5. No perspective convergence.
    for t in (-0.5, 0, 0.5):
        draw.line([(x - 70 + 140 * t, y - 35 - 70 * t), (x + 70 + 140 * t, y + 35 - 70 * t)], fill=(181, 166, 130), width=1)
        draw.line([(x - 70 + 140 * t, y + 35 + 70 * t), (x + 70 + 140 * t, y - 35 + 70 * t)], fill=(181, 166, 130), width=1)
im.save(HERE / "geometry-guide.png")

# A second guide constrains walls as well as the ground plane.
for i in range(10):
    x, y = 200 + i % 5 * 400, 490 + i // 5 * 600
    h = (240, 160, 220, 220, 200, 300, 300, 330, 290, 330)[i]
    left, back, right, front = (x - 110, y), (x, y - 55), (x + 110, y), (x, y + 55)
    top = lambda p: (p[0], p[1] - h)
    draw.polygon([left, front, top(front), top(left)], fill=(183, 159, 115), outline=(64, 61, 49), width=2)
    draw.polygon([front, right, top(right), top(front)], fill=(144, 125, 93), outline=(64, 61, 49), width=2)
    draw.polygon([top(left), top(back), top(right), top(front)], fill=(235, 212, 164), outline=(64, 61, 49), width=2)
im.save(HERE / "structure-guide.png")
