#!/usr/bin/env python3
"""Bake the shared match-3 board tiles into hex sprites for every game.

The eight tiles follow the slots of Cradle of Rome's board sheet: normal cell,
single and double tablet, light wave, hover, selected, ice and bonus area.
Each is lit from above: a bevel ring runs from a light upper edge to a shaded
lower one, and inside it the face runs from a lighter top colour to a darker
bottom one. A neutral stained-paper grain (tools/board_grain.py) darkens and
lightens it, optional hairline cracks and a radial glow add
ice and light, and the canonical
flat-top mask (engine/art/hex-tile) cuts the final alpha.

The spec (engine/art/board-tiles/tiles.json) holds every colour and setting
and lists the game data folders that receive identical copies:

    python3 tools/board_tiles.py
    python3 tools/board_tiles.py --check
"""
import argparse
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

import board_grain

REPO = Path(__file__).resolve().parents[1]
SPEC = REPO / "engine/art/board-tiles/tiles.json"
SS = 4   # supersampling for the bevel, gradient and glow edges


def rgb(hex_colour):
    hex_colour = hex_colour.lstrip("#")
    return tuple(int(hex_colour[i:i + 2], 16) for i in (0, 2, 4))


def hexagon(size, radius):
    """Flat-top hex, the engine's polygon at angles 0, π/3, …, as an L mask."""
    c = size / 2
    points = [(c + radius * math.cos(k * math.pi / 3), c + radius * math.sin(k * math.pi / 3)) for k in range(6)]
    mask = Image.new("L", (size, size))
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def gradient(size, radius, top, bottom):
    """Vertical gradient from the hex's top edge to its bottom edge."""
    half = radius * math.sqrt(3) / 2
    column = Image.new("RGB", (1, size))
    for y in range(size):
        t = min(1, max(0, (y - (size / 2 - half)) / (2 * half)))
        column.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return column.resize((size, size))


def glow(size, colour, opacity, reach):
    """A soft radial light, strongest at the centre, gone at reach × radius."""
    small = 64
    alpha = Image.new("L", (small, small))
    c, r = (small - 1) / 2, reach * small / 2
    alpha.putdata([round(255 * opacity * max(0.0, 1 - math.hypot(x - c, y - c) / r) ** 1.6)
                   for y in range(small) for x in range(small)])
    out = Image.new("RGBA", (size, size), rgb(colour) + (0,))
    out.putalpha(alpha.resize((size, size), Image.Resampling.BICUBIC))
    return out


def cracks(size, spec):
    """Branching hairline cracks, like frost on a pane."""
    rng = random.Random(spec.get("seed", 1))
    layer = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(layer)
    colour = rgb(spec["colour"]) + (round(255 * spec["opacity"]),)
    pending = [(rng.uniform(.2, .8) * size, rng.uniform(.2, .8) * size, rng.uniform(0, 2 * math.pi), 1.0)
               for _ in range(spec.get("count", 6))]
    while pending:
        x, y, heading, life = pending.pop()
        for _ in range(int(18 * life)):
            heading += rng.uniform(-.5, .5)
            step = size * rng.uniform(.015, .035)
            nx, ny = x + step * math.cos(heading), y + step * math.sin(heading)
            draw.line((x, y, nx, ny), fill=colour, width=max(1, round(spec.get("width", 1) * SS * life)))
            x, y = nx, ny
            if life > .3 and rng.random() < .12:
                pending.append((x, y, heading + rng.choice((-1, 1)) * rng.uniform(.6, 1.3), life * .6))
    return layer


def spread(a, b, contrast):
    """Push two colours apart (contrast > 1) or together around their midpoint."""
    mid = [(x + y) / 2 for x, y in zip(a, b)]
    return ([m + (x - m) * contrast for m, x in zip(mid, a)], [m + (y - m) * contrast for m, y in zip(mid, b)])


def lerp(a, b, t):
    return tuple(min(255, max(0, round(x + (y - x) * t))) for x, y in zip(a, b))


def lit_face(size, radius, bevel, tile, shading):
    """A face lit from `light` (a vector towards the light, e.g. [-1, -1] for the
    north-west): the face runs from `top` on the lit side to `bottom` on the far
    side, scaled by `contrast`. A "facets" bevel shades each of the six edges by
    how squarely it faces the light, like a cut stone; "ring" keeps one gradient.
    """
    lx, ly = shading.get("light", [0, -1])
    n = math.hypot(lx, ly)
    lx, ly = lx / n, ly / n
    top, bottom = spread(rgb(tile["top"]), rgb(tile["bottom"]), shading.get("contrast", 1))
    light, shade = spread(rgb(tile["light"]), rgb(tile["shade"]), shading.get("bevel_contrast", 1))
    edge_mid = lerp(light, shade, .5)
    facets = shading.get("bevel_style", "ring") == "facets"
    inner = radius - bevel
    apothem_inner = inner * math.sqrt(3) / 2
    c = (size - 1) / 2
    pixels = []
    for y in range(size):
        for x in range(size):
            dx, dy = (x - c) / radius, (y - c) / radius
            # Distance to the hex edge along the nearest edge normal (angles 30° + 60°k).
            k = round((math.degrees(math.atan2(dy, dx)) - 30) / 60) % 6
            nx, ny = math.cos(math.radians(30 + 60 * k)), math.sin(math.radians(30 + 60 * k))
            along = (dx * nx + dy * ny) * radius
            t = (1 - (dx * lx + dy * ly) / 1.0) / 2   # 0 on the lit side, 1 opposite
            if along > apothem_inner:   # in the bevel
                if facets:
                    b = nx * lx + ny * ly
                    pixels.append(lerp(edge_mid, light, b) if b > 0 else lerp(edge_mid, shade, -b))
                else:
                    pixels.append(lerp(light, shade, t))
            else:
                pixels.append(lerp(top, bottom, t))
    face = Image.new("RGB", (size, size))
    face.putdata(pixels)
    face = face.convert("RGBA")
    blob = shading.get("blob")
    if blob:   # a soft highlight, by default in the north-west
        layer = glow(size, blob.get("colour", "#FFFFFF"), blob["opacity"], blob.get("reach", .6))
        offset = (round(blob.get("x", -.35) * radius), round(blob.get("y", -.35) * radius))
        moved = Image.new("RGBA", (size, size))
        moved.paste(layer, offset, layer)
        face.alpha_composite(moved)
    return face


def bake(spec, tile, grains, index):
    size = spec["size"] * SS
    radius = size / 2
    shading = {**spec.get("shading", {}), **tile.get("shading", {})}
    bevel = shading.get("bevel", tile.get("bevel", spec["bevel"])) * SS
    if shading:
        face = lit_face(size, radius, bevel, tile, shading)
    else:
        face = gradient(size, radius, rgb(tile["light"]), rgb(tile["shade"]))
        inner = gradient(size, radius - bevel, rgb(tile["top"]), rgb(tile["bottom"]))
        face.paste(inner, (0, 0), hexagon(size, radius - bevel))
        face = face.convert("RGBA")
    if tile.get("grain", 0) > 0:
        # Each tile samples its own patch of its grain.
        grain = grains[json.dumps(tile.get("grain_params", {}), sort_keys=True)]
        sample = spec["grain_sample"]
        span = grain.width - sample
        x, y = (index * 197 + 41) % span, (index * 331 + 113) % span
        patch = grain.crop((x, y, x + sample, y + sample)).resize((size, size), Image.Resampling.BICUBIC)
        if "grain_tint" in tile:   # warm stains and flecks keep a colour from going gray
            dark, light = rgb(tile["grain_tint"]["dark"]), rgb(tile["grain_tint"]["light"])
            tone = patch.getchannel("R")
            patch = Image.merge("RGBA", [tone.point(lambda v, a=a, b=b: round(a + (b - a) * v / 255))
                                         for a, b in zip(dark, light)] + [patch.getchannel("A")])
        patch.putalpha(patch.getchannel("A").point(lambda a: round(a * tile["grain"])))
        face.alpha_composite(patch)
    if "cracks" in tile:
        face.alpha_composite(cracks(size, tile["cracks"]))
    if "glow" in tile:
        g = tile["glow"]
        face.alpha_composite(glow(size, g["colour"], g["opacity"], g.get("reach", 1)))
    out = face.resize((spec["size"], spec["size"]), Image.Resampling.LANCZOS)
    out.putalpha(Image.open(REPO / spec["mask"]).getchannel("A"))
    return out


def render_all(spec):
    grains = {}
    for tile in spec["tiles"].values():
        key = json.dumps(tile.get("grain_params", {}), sort_keys=True)
        if tile.get("grain", 0) > 0 and key not in grains:
            grains[key] = board_grain.render(**{**spec["grain"], **tile.get("grain_params", {})})
    return {name: bake(spec, tile, grains, i) for i, (name, tile) in enumerate(spec["tiles"].items())}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--spec", type=Path, default=SPEC)
    parser.add_argument("--check", action="store_true", help="fail if any tile differs from a fresh render")
    args = parser.parse_args()
    spec = json.loads(args.spec.read_text())
    tiles = render_all(spec)
    for folder in spec["outputs"]:
        for name, out in tiles.items():
            path = REPO / folder / f"{name}.png"
            if args.check:
                current = Image.open(path).convert("RGBA")
                assert current.size == out.size and current.tobytes() == out.tobytes(), f"Stale tile: {path}"
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                out.save(path, optimize=True)


if __name__ == "__main__":
    main()
