#!/usr/bin/env python3
"""Temporary story busts: a name card per cast member who has no painted bust yet.

Each card replaces nothing authored; it is a catalogued fallback until the bust
is painted (docs/asset-catalogue.md#story-cast). --check detects stale cards.
"""
import argparse
import io
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / 'data/fonts/LilitaOne-Regular.ttf'
# id, name, role, cast colour (lua/narrative.lua)
CARDS = [
    ('theo', 'Theo Marsh', 'Tree seller', (58, 96, 62)),
    ('agnes', 'Agnes Holt', 'Baker', (150, 92, 48)),
    ('henrik', 'Henrik Strand', 'Toymaker', (96, 70, 52)),
    ('pip', 'Pip Larkin', 'Post runner', (46, 86, 128)),
    ('wren', 'Mr Wren', 'The man with the broom', (92, 92, 104)),
]
SIZE = (320, 480)   # the same canvas as Noelle's bust; the lowest third stands behind the dialogue box


def fitted(draw, text, limit, start):
    size = start
    while size > 12:
        font = ImageFont.truetype(str(FONT), size)
        if draw.textlength(text, font=font) <= limit:
            return font
        size -= 2
    return font


def card(name, role, colour):
    image = Image.new('RGBA', SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((16, 40, 304, 470), 36, fill=colour + (255,), outline=(255, 246, 222, 255), width=6)
    cream = (255, 246, 222, 255)
    initial = name.removeprefix('Mr ')[0]   # a large faint initial where the face will go
    faint = Image.new('RGBA', SIZE, (0, 0, 0, 0))
    ImageDraw.Draw(faint).text((160, 150), initial, font=ImageFont.truetype(str(FONT), 170), fill=(255, 246, 222, 70), anchor='mm')
    image.alpha_composite(faint)
    draw.text((160, 268), name, font=fitted(draw, name, 260, 44), fill=cream, anchor='mm')
    draw.text((160, 312), role, font=fitted(draw, role, 250, 24), fill=(255, 246, 222, 200), anchor='mm')
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=True)
    return out.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    for key, name, role, colour in CARDS:
        path = ROOT / 'data/characters' / f'{key}.png'
        data = card(name, role, colour)
        if args.check:
            assert path.read_bytes() == data, f'{path.name} is stale: run python3 games/christmas-market/tools/prepare_name_cards.py'
        else:
            path.write_bytes(data)
    print(f'Christmas Market: {len(CARDS)} temporary name-card busts')


if __name__ == '__main__':
    main()
