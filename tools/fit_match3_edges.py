#!/usr/bin/env python3
"""Hex-edge remapping shared by the board art tools (Christmas tinsel ring)."""
from math import sqrt

from PIL import Image

SIZE = 128
RADIUS = 46
APOTHEM = sqrt(3) / 2


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
