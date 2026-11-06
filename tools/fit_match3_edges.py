#!/usr/bin/env python3
"""Register board-only snow, excavation and ice to the tinsel hex edge."""
from math import sqrt
from pathlib import Path

from PIL import Image, ImageChops

SIZE = 128
RADIUS = 46
APOTHEM = sqrt(3) / 2
ROOT = Path(__file__).resolve().parents[1]


def hex_distance(x, y):
    return max(abs(y) / APOTHEM, abs(x) + abs(y) / sqrt(3))


def remap(source, center, radii, source_radius):
    def sample(x, y):
        dx, dy = x - SIZE / 2, y - SIZE / 2
        distance = hex_distance(dx, dy)
        stretch = source_radius(distance) / max(distance, 1)
        return (center[0] + dx * stretch * radii[0],
                center[1] + dy * stretch * radii[1] / APOTHEM)

    mesh = []
    for y in range(0, SIZE, 2):
        for x in range(0, SIZE, 2):
            corners = (sample(x, y), sample(x, y + 2), sample(x + 2, y + 2), sample(x + 2, y))
            mesh.append(((x, y, x + 2, y + 2), tuple(coord for point in corners for coord in point)))
    return source.transform((SIZE, SIZE), Image.Transform.MESH, mesh, Image.Resampling.BILINEAR)


def thin_ring(source, center, radii):
    # Double distance from the painted wire when sampling it.
    return remap(source, center, radii, lambda d: max(0, 2 * d / RADIUS - 1))


def material_edge(source, center, radii, half_width):
    # Keep an interior strip of the authored material and give it the cell's
    # exact flat-top perimeter. The sampled pixels keep their colour and alpha.
    def band(d):
        return min(.97, max(.68, .825 + (d - RADIUS) * .145 / half_width))

    edge = remap(source, center, radii, band)
    mask = Image.new('L', (SIZE, SIZE))
    mask.putdata([
        round(255 * min(1, max(0, half_width + .5 - abs(hex_distance(
            x + .5 - SIZE / 2, y + .5 - SIZE / 2) - RADIUS))))
        for y in range(SIZE) for x in range(SIZE)
    ])
    edge.putalpha(ImageChops.multiply(edge.getchannel('A'), mask))
    return edge


RECIPES = {
    'christmas-market': {
        'sand': ((66, 61.5), (50, 49), 3.8),
        'ice-1': ((64, 60), (44, 42), None),
        'ice-2': ((64, 62), (43, 39), None),
    },
    'relic-rush': {
        'sand': ((64, 64), (63, 54), 3.8),
        'ice-1': ((63, 63.5), (60, 53), 5),
        'ice-2': ((64, 63), (61, 53), 5.8),
    },
}


def build_edges(game):
    folder = ROOT / 'games' / game / 'data/board-states'
    for name, (center, radii, half_width) in RECIPES[game].items():
        with Image.open(folder / f'{name}.png') as source:
            if half_width is None:
                edge = thin_ring(source, center, radii)
            else:
                edge = material_edge(source, center, radii, half_width)
            edge.save(folder / f'{name}-edge.png')


if __name__ == '__main__':
    from match3_atlas import build_game

    for game in RECIPES:
        build_edges(game)
        build_game(game, False)
