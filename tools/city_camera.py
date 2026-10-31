"""The city camera, read from engine/engine.h so art and engine cannot disagree.

Orthographic. World X is tile u (down-right on screen), world Y is -v (up-right),
Z is up. Use it from Blender and from plain Python: it imports neither.
"""
import math
import re
from pathlib import Path

ENGINE_H = Path(__file__).resolve().parents[1] / 'engine/engine.h'
_header = ENGINE_H.read_text()
YAW = float(re.search(r'#define CITY_CAMERA_YAW ([\d.]+)f', _header).group(1))
ELEVATION = float(re.search(r'#define CITY_CAMERA_ELEVATION ([\d.]+)f', _header).group(1))
_yaw, _elev = math.radians(YAW), math.radians(ELEVATION)

# Blender's camera rotation, XYZ Euler in radians.
ROTATION = (math.pi / 2 - _elev, 0., _yaw)
# Screen pixels, y down, for one world unit along u and v.
U = (math.cos(_yaw), math.sin(_yaw) * math.sin(_elev))
V = (-math.sin(_yaw), math.cos(_yaw) * math.sin(_elev))
Z = math.cos(_elev)   # screen pixels per world unit of height


def base_span(w, h):
    """A w x h base's width on screen, left corner to right, per world unit."""
    return w * U[0] - h * V[0]


def corners(cx, cy, w, h, scale):
    """Screen corners of a w x h base centred on (cx, cy): left, front, right, back."""
    ux, uy, vx, vy = U[0] * scale * w / 2, U[1] * scale * w / 2, V[0] * scale * h / 2, V[1] * scale * h / 2
    return [(cx - ux + vx, cy - uy + vy), (cx + ux + vx, cy + uy + vy), (cx + ux - vx, cy + uy - vy), (cx - ux - vx, cy - uy - vy)]
