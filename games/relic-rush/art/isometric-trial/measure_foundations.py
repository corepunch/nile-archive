"""Measure sampled lower-left slab edges; diagnostic, not an asset acceptance test.

Fits the bottom opaque silhouette in a clear span of each slab. It does not
validate the opposite edge, masonry, roof, or actual building ground pivot.
"""
import json
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
result = {"target_slope": 0.5, "alpha_threshold": 200,
          "sample_x": "requested equal-width cell left +30 through +124 pixels",
          "method": "least-squares fit of bottom opaque silhouette; sampled lower-left slab edge only",
          "versions": {}}
for version in ('v1', 'v2'):
    im = Image.open(HERE / f'buildings-2to1-{version}.png')
    alpha = im.getchannel('A')
    slopes = []
    for i in range(10):
        x0 = round(i % 5 * im.width / 5)
        y0 = round(i // 5 * im.height / 2)
        y1 = round((i // 5 + 1) * im.height / 2)
        pts = []
        for x in range(x0 + 30, x0 + 125):
            ys = [y for y in range(y0, y1) if alpha.getpixel((x, y)) > 200]
            if ys:
                pts.append((x, max(ys)))
        n = len(pts)
        sx, sy = sum(x for x, y in pts), sum(y for x, y in pts)
        slope = (n * sum(x * y for x, y in pts) - sx * sy) / (n * sum(x * x for x, y in pts) - sx * sx)
        slopes.append(round(slope, 4))
    result['versions'][version] = slopes
(HERE / 'measurements.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
