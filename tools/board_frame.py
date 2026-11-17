#!/usr/bin/env python3
"""Bake a paintable flat-top hex border atlas and its registration guide.

    python3 tools/board_frame.py --output build/board-frame
    python3 tools/board_frame.py --winter --output build/winter-frame
    python3 tools/board_frame.py --check games/relic-rush/data/board/frame/stone.png
"""
import argparse
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

import board_frame_decor
import board_grain

RADIUS = 32
PPU = 2
SLOT = 80
INTRO = 168
COLUMNS = 6
ROWS = ("edge", "outside", "inside")
SIZE = (COLUMNS * SLOT, len(ROWS) * SLOT + INTRO)
NORTH_EDGE = 4
WINTER_SLOT = (3 * SLOT, len(ROWS) * SLOT)
REACH = 5.95
UNDERLAP = 1.5
JOIN = RADIUS / 4
OVERLAP = 1.25

# Inner dark stone, rusty band, light lip and outside edge of the original rim.
BANDS = (
    (1.7, "47240c", "3a1c08"),
    (2.8, "5e3e20", "4e3218"),
    (3.35, "733a12", "5a2a0c"),
    (5.45, "c09a66", "9a7446"),
    (REACH, "5e4428", "4a3018"),
)


def unit(angle):
    return math.cos(angle), math.sin(angle)


VERTICES = [unit(k * math.tau / 6) for k in range(6)]
NORMALS = [unit((k + .5) * math.tau / 6) for k in range(6)]


def stone_strip():
    """The original rim's neutral mottling, speckles and hand-sized cracks."""
    w, h = 512, 24
    grain = board_grain.render(size=w, seed=19, stain=.35, rings=.25, mottle=.5,
                               fibre=.05, speck=.4, strength=.8)
    out = grain.resize((w, h), Image.Resampling.BICUBIC)
    out.putalpha(out.getchannel("A").point(lambda a: round(a * .7)))
    draw = ImageDraw.Draw(out)
    rng = random.Random(3)
    x = rng.uniform(0, 44)
    while x < w:
        px, py = x, rng.choice((0, h))
        heading = math.pi / 2 if py == 0 else -math.pi / 2
        for _ in range(rng.randint(3, 6)):
            heading += rng.uniform(-.7, .7)
            step = h * rng.uniform(.18, .35)
            nx, ny = px + step * math.cos(heading), py + step * math.sin(heading)
            draw.line((px + 1, py + 1, nx + 1, ny + 1), fill=(255, 255, 255, 70))
            draw.line((px, py, nx, ny), fill=(0, 0, 0, 190))
            px, py = nx, ny
        x += rng.uniform(.5, 1.2) * 44
    return out


def straight(k):
    nx, ny = NORMALS[k]
    half = RADIUS / 2 - JOIN

    def sample(x, y):
        along = -ny * x + nx * y
        if abs(along) > half + OVERLAP:
            return None
        return nx * x + ny * y, ny, along, half - abs(along)

    return sample


def corner(k, inside):
    vx, vy = VERTICES[k]
    # Two rays run from the corner towards its neighbours on a full hex.
    def arm(index, edge):
        x, y = VERTICES[index % 6]
        nx, ny = NORMALS[edge % 6]
        return x - vx, y - vy, nx, ny

    ax, ay, an, am = arm(k - 1, k - 1)
    bx, by, bn, bm = arm(k + 1, k)
    side = -1 if inside else 1

    def sample(x, y):
        a, b = ax * x + ay * y, bx * x + by * y
        if max(a, b) > JOIN + OVERLAP:
            return None
        da, db = an * x + am * y, bn * x + bm * y
        # Behind a ray's origin its nearest point is the vertex. This rounds
        # exposed tips and lets the rims meet at the bottom of an inside corner.
        tip = math.hypot(x, y)
        ra, rb = (abs(da) if a >= 0 else tip), (abs(db) if b >= 0 else tip)
        d = min(ra, rb)
        if max(da, db) * side < 0:
            d = -d
        # Ease across the vertex while matching each straight run at its join.
        mix = max(0, min(1, .5 + (ra - rb) / 6))
        along = a if ra < rb else b
        return d, (am + (bm - am) * mix) * side, along, JOIN - along

    return sample


def bake(slot, sample, strip, seed):
    # Supersample the band profile, silhouette and cut planes together.
    supersample = 2
    size = slot * supersample
    scale = PPU * supersample
    palette = [(end, bytes.fromhex(top), bytes.fromhex(bottom)) for end, top, bottom in BANDS]
    ink = strip.load()
    pixels = []
    for py in range(size):
        y = (py + .5 - size / 2) / scale
        for px in range(size):
            x = (px + .5 - size / 2) / scale
            hit = sample(x, y)
            if hit is None or not -UNDERLAP <= hit[0] < REACH:
                pixels.append((0, 0, 0, 0))
                continue
            depth, normal_y, along, from_join = hit
            _, lit, shaded = next(band for band in palette if depth < band[0])
            shade = .5 + normal_y * math.sqrt(3) / 4
            u = (round((along + RADIUS) * 2) + seed * 131) % strip.width
            v = round(max(0, depth) * (strip.height - 1) / REACH)
            gr, gg, gb, opacity = ink[u, v]
            # All pieces share the same finish where they overlap. Texture
            # fades into it just before the two registration lines.
            grain = opacity / 255 * max(0, min(1, (from_join - OVERLAP) / 3))
            colour = [round((a + (b - a) * shade) * (1 - grain) + g * grain)
                      for a, b, g in zip(lit, shaded, (gr, gg, gb))]
            pixels.append((*colour, 255))
    image = Image.new("RGBA", (size, size))
    image.putdata(pixels)
    return image.resize((slot, slot), Image.Resampling.BOX)


def intro_rim():
    # The fly-in used concentric hexagons underneath each animated cell. Bake
    # their original vertical lighting and pointed outline into a single slot.
    scale = PPU * 4
    image = Image.new("RGBA", (INTRO * 4, INTRO * 4))
    centre = image.width / 2
    draw = ImageDraw.Draw(image)
    for depth, top, bottom in reversed(BANDS):
        r = RADIUS + depth * 2 / math.sqrt(3)
        points = [(centre + r * scale * vx, centre + r * scale * vy) for vx, vy in VERTICES]
        mask = Image.new("L", image.size)
        ImageDraw.Draw(mask).polygon(points, fill=255)
        top, bottom = bytes.fromhex(top), bytes.fromhex(bottom)
        column = Image.new("RGBA", (1, image.height))
        half = r * math.sqrt(3) / 2 * scale
        for y in range(image.height):
            shade = max(0, min(1, .5 + (y - centre) / (2 * half)))
            column.putpixel((0, y), (*[round(a + (b - a) * shade) for a, b in zip(top, bottom)], 255))
        image.paste(column.resize(image.size), mask=mask)
    r = (RADIUS - UNDERLAP) * scale
    draw.polygon([(centre + r * x, centre + r * y) for x, y in VERTICES], fill=(0, 0, 0, 0))
    return image.resize((INTRO, INTRO), Image.Resampling.BOX)


def snowy_north_edge(atlas):
    spec = json.loads(board_frame_decor.SPEC.read_text())
    with Image.open(board_frame_decor.ROOT / spec["source"]) as source:
        snow = board_frame_decor.register(source, spec["north_snow"], spec["size"])
    size = round(RADIUS * PPU * 1.12)
    snow = snow.resize((size, size), Image.Resampling.LANCZOS)
    edge = atlas.crop((NORTH_EDGE * SLOT, 0, (NORTH_EDGE + 1) * SLOT, SLOT))
    centre = (SLOT - size) // 2
    edge.alpha_composite(snow, (centre, centre - round(RADIUS * PPU * .145)))
    return edge


def generate(winter=False):
    atlas = Image.new("RGBA", SIZE)
    strip = stone_strip()
    for k in range(COLUMNS):
        for row, shape in enumerate((straight(k), corner(k, False), corner(k, True))):
            atlas.paste(bake(SLOT, shape, strip, row * COLUMNS + k), (k * SLOT, row * SLOT))
    atlas.paste(intro_rim(), (0, len(ROWS) * SLOT))
    if winter:
        atlas.paste(snowy_north_edge(atlas), WINTER_SLOT)
    return atlas


def joins(row, k):
    """Unit direction to each join and the outward normal at that join."""
    if row == 0:
        nx, ny = NORMALS[k]
        return [(-ny, nx, nx, ny), (ny, -nx, nx, ny)]
    vx, vy = VERTICES[k]
    side = -1 if row == 2 else 1
    ends = []
    for index, edge in ((k - 1, k - 1), (k + 1, k)):
        x, y = VERTICES[index % 6]
        nx, ny = NORMALS[edge % 6]
        ends.append((x - vx, y - vy, nx * side, ny * side))
    return ends


def guide(atlas, winter=False):
    image = Image.new("RGB", SIZE, "#273239")
    image.paste(atlas, mask=atlas.getchannel("A"))
    draw = ImageDraw.Draw(image)
    for row, name in enumerate(ROWS):
        for k in range(COLUMNS):
            left, top = k * SLOT, row * SLOT
            x, y = left + SLOT / 2, top + SLOT / 2
            draw.rectangle((left, top, left + SLOT, top + SLOT), outline="#52636b")
            draw.text((left + 4, top + 3), f"{name} {k}", fill="#fbecd6")
            draw.ellipse((x - 2, y - 2, x + 2, y + 2), outline="#aee1f0")
            for dx, dy, nx, ny in joins(row, k):
                jx, jy = x + dx * JOIN * PPU, y + dy * JOIN * PPU
                draw.line((jx - 16 * nx, jy - 16 * ny, jx + 16 * nx, jy + 16 * ny), fill="#aee1f0")
    y = len(ROWS) * SLOT
    draw.rectangle((0, y, INTRO, y + INTRO - 1), outline="#52636b")
    legend_y = y + 14
    if winter:
        x, top = WINTER_SLOT
        draw.rectangle((x, top, x + SLOT, top + SLOT), outline="#52636b")
        draw.text((x + 4, top + 3), "Snowy north", fill="#fbecd6")
        legend_y = y + SLOT + 14
    draw.text((INTRO + 16, legend_y), "Entrance rim\n\nBlue dot = anchor\nBlue lines = joins", fill="#fbecd6", spacing=4)
    return image


def check(atlas, winter=False):
    assert atlas.size == SIZE and atlas.mode == "RGBA", f"Expected {SIZE[0]}x{SIZE[1]} RGBA atlas"
    alpha = atlas.getchannel("A")
    for row, name in enumerate(ROWS):
        for k in range(COLUMNS):
            for dx, dy, nx, ny in joins(row, k):
                # The stone must reach each join at both sides of the lip.
                for depth in (1, 4.5):
                    x = math.floor((k + .5) * SLOT + (dx * JOIN + nx * depth) * PPU)
                    y = math.floor((row + .5) * SLOT + (dy * JOIN + ny * depth) * PPU)
                    assert alpha.getpixel((x, y)) >= 230, f"Open seam in {name} {k} at {(x, y)}"
    slots = [(k * SLOT, row * SLOT, SLOT) for row in range(len(ROWS)) for k in range(COLUMNS)]
    slots.append((0, len(ROWS) * SLOT, INTRO))
    if winter:
        x, y = WINTER_SLOT
        snowy = alpha.crop((x, y, x + SLOT, y + SLOT))
        stone = alpha.crop((NORTH_EDGE * SLOT, 0, (NORTH_EDGE + 1) * SLOT, SLOT))
        assert not ImageChops.subtract(stone, snowy).getbbox(), "Winter slot must cover the north rim"
        assert ImageChops.subtract(snowy, stone).getbbox(), "Winter slot must show its snow beyond the rim"
        slots.append((x, y, SLOT))
    for x, y, side in slots:
        bounds = alpha.crop((x, y, x + side, y + side)).getbbox()
        assert bounds and min(*bounds[:2], side - bounds[2], side - bounds[3]) >= 2, (x, y, bounds)
        alpha.paste(0, (x, y, x + side, y + side))
    assert not alpha.getbbox(), "Unexpected pixels outside the atlas slots"


def ornament_join(atlas, art, group, direction, recipe):
    """Paint a variant over the plain join while preserving its connectors."""
    centre = 128
    image = Image.new("RGBA", (centre * 2, centre * 2))
    row = 2 if group == "inner" else 1
    x, y = direction * SLOT, row * SLOT
    stone = atlas.crop((x, y, x + SLOT, y + SLOT))
    image.paste(stone, (centre - SLOT // 2, centre - SLOT // 2))

    if group == "inner":
        dx, dy = (offset * PPU for offset in recipe["mount"])
        assert image.getpixel((round(centre + dx), round(centre + dy)))[3] >= 230, "Ornament hub must meet the rim"
        assert art.getpixel((art.width // 2, art.height // 2))[3] >= 230, "Ornament anchor must be painted"
    else:
        vx, vy = VERTICES[direction]
        offset = RADIUS * PPU * .16 if group == "walls" else 0
        dx, dy = vx * offset, vy * offset
    size = round(recipe.get("width", 2) * RADIUS * PPU)
    sprite = art.resize((size, size), Image.Resampling.LANCZOS)
    if recipe.get("outward"):
        sprite = sprite.rotate(-(direction * 60 + 90), Image.Resampling.BICUBIC, expand=True)
    foliage = Image.new("RGBA", image.size)
    foliage.paste(sprite, (round(centre + dx - sprite.width / 2), round(centre + dy - sprite.height / 2)))

    # The board paint-over places a small contact shadow where stems cross
    # the lip. Confine it to the stone and preserve the base join's alpha.
    shade = Image.new("L", image.size)
    shade.paste(foliage.getchannel("A"), (1, 2))
    shade = shade.filter(ImageFilter.GaussianBlur(2)).point(lambda a: round(a * .38))
    alpha = image.getchannel("A")
    image = Image.composite(Image.new("RGBA", image.size), image, shade)
    image.putalpha(alpha)
    image.alpha_composite(foliage)
    bounds = image.getchannel("A").getbbox()
    return image.crop(bounds), (bounds[0] - centre, bounds[1] - centre)


def decorate_atlas(base, game, spec):
    art = board_frame_decor.ornaments(game, spec)
    theme = spec["frames"][game]
    parts, entries = [], {}
    x, y, height = 2, SIZE[1] + 2, 0
    for group in ("corners", "inner", "walls"):
        entries[group] = []
        for recipe in theme.get(group, []):
            variants = []
            directions = range(COLUMNS) if group == "corners" else (recipe["direction"],)
            for direction in directions:
                part, (dx, dy) = ornament_join(base, art[recipe["art"]], group, direction, recipe)
                if x + part.width + 2 > SIZE[0]:
                    x, y, height = 2, y + height + 4, 0
                parts.append((part, (x, y)))
                coords = ", ".join(map(str, (x, y, part.width, part.height, dx, dy)))
                variants.append(f"{{{coords}}}")
                height = max(height, part.height)
                x += part.width + 4
            if group == "corners":
                row = "{[0] = " + ", ".join(variants) + "}"
            elif group == "inner":
                row = "{direction = " + str(recipe["direction"]) + ", part = " + variants[0] + "}"
            else:
                row = variants[0]
            entries[group].append(row)

    atlas = Image.new("RGBA", (SIZE[0], y + height + 2))
    atlas.paste(base)
    for part, pos in parts:
        atlas.paste(part, pos)
    lua = ['-- Generated by tools/board_frame.py. Edit the decoration source and recipe.',
           'return {', '    stone = "board/frame/stone.png",']
    if theme.get("winter"):
        lua.append('    north_edge = true,')
    for group, rows in entries.items():
        if rows:
            lua.extend([f"    {group} = {{", *(f"        {row}," for row in rows), "    },"])
    lua.extend(["}", ""])
    return atlas, "\n".join(lua)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--output", type=Path, default=Path("build/board-frame"))
    group.add_argument("--check", type=Path, metavar="ATLAS")
    parser.add_argument("--winter", action="store_true", help="include the snowy north rim")
    spec = json.loads(board_frame_decor.SPEC.read_text())
    parser.add_argument("--game", choices=tuple(spec["frames"]), help="include the game's painted join variants")
    args = parser.parse_args()
    winter = args.winter or args.game and spec["frames"][args.game].get("winter", False)
    if args.check:
        with Image.open(args.check) as atlas:
            if args.game:
                base = atlas.crop((0, 0, *SIZE))
                check(base, winter)
                expected, lua = decorate_atlas(base, args.game, spec)
                assert atlas.mode == "RGBA" and atlas.size == expected.size and atlas.tobytes() == expected.tobytes(), args.check
                lua_path = Path(__file__).resolve().parents[1] / "games" / args.game / "lua/board_frame_atlas.lua"
                assert lua_path.read_text() == lua, lua_path
                print(f"{args.check}: base frame and painted join variants verified")
                return
            check(atlas, winter)
        extra = " and snowy north edge" if winter else ""
        print(f"{args.check}: 18 perimeter slots, entrance rim{extra} verified")
        return
    base = generate(winter)
    check(base, winter)
    args.output.mkdir(parents=True, exist_ok=True)
    atlas = base
    review = guide(base, winter)
    if args.game:
        atlas, lua = decorate_atlas(base, args.game, spec)
        (args.output / "board_frame_atlas.lua").write_text(lua)
        full_review = Image.new("RGB", atlas.size, "#273239")
        full_review.paste(atlas, mask=atlas.getchannel("A"))
        full_review.paste(review)
        review = full_review
    atlas.save(args.output / "stone.png", optimize=True)
    review.save(args.output / "guide.png", optimize=True)


if __name__ == "__main__":
    main()
