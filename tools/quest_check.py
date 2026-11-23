#!/usr/bin/env python3
"""Render the dark green check that marks a finished quest on the town tracker.

One 128 px sprite, drawn at 8x and reduced for clean edges: a dark green
check with round caps and a round joint in the green coin's dark rim colour
(as the numbers use the gold coin's brown), its outline centred in the cell. It is
written into both portrait games' registered HUD art; repack the atlases
with `python3 tools/match3_atlas.py` afterwards.

    python3 tools/quest_check.py           # write the sprite
    python3 tools/quest_check.py --check   # compare with the registered files
"""
import io
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TARGETS = [ROOT / f'games/{game}/art/registered/expedition-hud/quest-check.png'
           for game in ('relic-rush', 'christmas-market')]
CELL, SCALE = 128, 8
INK = (31, 74, 38, 255)          # #1F4A26, the done coin's rim
POINTS = [(.17, .53), (.40, .76), (.84, .26)]
STROKE = .22                     # of the cell


def stroke(draw, points, width, fill):
    """A polyline with round caps and joints."""
    for a, b in zip(points, points[1:]):
        draw.line([a, b], fill=fill, width=round(width))
    for x, y in points:
        r = width / 2
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def render():
    side = CELL * SCALE
    image = Image.new('RGBA', (side, side))
    draw = ImageDraw.Draw(image)
    points = [(x * side, y * side) for x, y in POINTS]
    width = STROKE * side
    stroke(draw, points, width, INK)
    image = image.resize((CELL, CELL), Image.Resampling.LANCZOS)
    # Centre the outline in the cell.
    left, top, right, bottom = image.getchannel('A').getbbox()
    dx, dy = round((CELL - (left + right)) / 2), round((CELL - (top + bottom)) / 2)
    centred = Image.new('RGBA', (CELL, CELL))
    centred.paste(image, (dx, dy))
    return centred


def png(image):
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=True)
    return out.getvalue()


def main():
    data = png(render())
    if '--check' in sys.argv:
        stale = [str(t.relative_to(ROOT)) for t in TARGETS if not t.exists() or t.read_bytes() != data]
        if stale:
            sys.exit('quest check is stale: ' + ', '.join(stale) + ' (run python3 tools/quest_check.py)')
        print('quest check: 2 registered copies match')
        return
    for target in TARGETS:
        target.write_bytes(data)
        print('wrote', target.relative_to(ROOT))


if __name__ == '__main__':
    main()
