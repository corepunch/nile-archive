"""Register painted slab textures to the 3D model's ground-contact polygon."""
import json
import math

from PIL import Image

import city_camera


def slab_keys(root, config):
    foundation = config.get('foundations')
    if not foundation:
        return set()
    catalogue = json.loads((root / 'art/building-catalogue/catalogue.json').read_text())
    return {key for key, _, category, *_ in catalogue
            if category in foundation['categories'] or key in foundation['keys']}


def check(image, pivot, size, ppt):
    """Check footprint coverage and the visible contact edge at 50% alpha."""
    left, front, right, back = city_camera.corners(*pivot, *size, ppt)
    if 'A' not in image.getbands():
        return 'painted slab needs an alpha channel'
    channel = image.getchannel('A')
    alpha = channel.load()
    if left[0] < 0 or right[0] > image.width or front[1] >= image.height:
        return 'projected slab is clipped by the sprite canvas'
    worst = 0
    for x in range(math.ceil(left[0]), math.floor(right[0])):
        p, q = (left, front) if x + .5 < front[0] else (front, right)
        expected = p[1] + (x + .5 - p[0]) * (q[1] - p[1]) / (q[0] - p[0])
        y = next((y for y in range(image.height - 1, -1, -1) if alpha[x, y] >= 128), None)
        if y is None or y + 1 == image.height:
            return f'no complete slab edge at column {x}'
        above, below = alpha[x, y], alpha[x, y + 1]
        actual = y + .5 + (above - 127.5) / (above - below)
        worst = max(worst, abs(actual - expected))
        p, q = (left, back) if x + .5 < back[0] else (back, right)
        rear = p[1] + (x + .5 - p[0]) * (q[1] - p[1]) / (q[0] - p[0])
        if any(alpha[x, j] < 128 for j in range(math.ceil(rear + .5), math.floor(expected - .5))):
            return f'painted slab leaves uncovered ground at column {x}'
    if worst > 1:
        return f'painted slab deviates from the projected ground edge by {worst:.1f} px (limit 1 px)'
    # The left/right corners bound the whole model in screen x.
    box = channel.point(lambda a: 255 if a >= 128 else 0).getbbox()
    if box[0] < left[0] - 1 or box[2] > right[0] + 1:
        return 'painted sprite extends past the projected side corners'
    return None


def register(image, pivot, size, ppt):
    """Remap the lower band of the painting onto the exact z=0 slab edges."""
    import numpy as np
    from scipy.ndimage import map_coordinates

    left, front, right, _ = city_camera.corners(*pivot, *size, ppt)
    # Allow transparent space for raster filtering even if the paint crop was tight.
    x0 = min(0, math.floor(left[0]) - 2)
    x1 = max(image.width, math.ceil(right[0]) + 2)
    height = max(image.height, math.ceil(front[1]) + 2)
    x = np.arange(x0, x1) + .5
    y = np.arange(height)[:, None] + .5
    ground = np.interp(x, (left[0], front[0], right[0]), (left[1], front[1], right[1]))

    source = np.asarray(image.convert('RGBa'))
    solid = source[:, :, 3] >= 128
    columns = np.flatnonzero(solid.any(axis=0))
    bottom = image.height - 1 - solid[::-1].argmax(axis=0)
    if len(columns) < .85 * (right[0] - left[0]):
        raise ValueError('painted slab is too narrow to register')
    # Use the centre of the painted front tip, excluding the rounded side pixels.
    tips = columns[bottom[columns] >= bottom[columns].max() - 1]
    first, last = columns[0] + 2.5, columns[-1] - 1.5
    tip = tips.mean() + .5
    if not first < tip < last:
        raise ValueError('could not locate the painted front corner')
    clamped_x = np.clip(x, left[0], right[0])
    slab_x = np.interp(clamped_x, (left[0], front[0], right[0]), (first, tip, last))
    slab_x += x - clamped_x

    # Keep the building above the slab as painted. The base band tapers into it.
    band = np.clip((y - ground + .45 * ppt) / (.30 * ppt), 0, 1)
    band = band * band * (3 - 2 * band)
    texture_x = x + band * (slab_x - x)
    source_edge = np.interp(texture_x, columns + .5, bottom[columns] + 1.)
    texture_y = y + band * (source_edge - ground)

    # The front face takes its colour from the paint. The projected geometry
    # sets the antialiased contact edge, including the left and right corners.
    edge_band = np.clip((y - ground + 4) / 2, 0, 1)
    texture_y = np.minimum(texture_y, source_edge - 1.5 * edge_band)
    coords = (texture_y - .5, texture_x - .5)
    sampled = np.stack([map_coordinates(channel, coords, order=1, mode='grid-constant')
                        for channel in source.transpose(2, 0, 1)], axis=-1)
    paint = Image.frombytes(
        'RGBa', (x1 - x0, height), sampled.tobytes()).convert('RGBA')

    # Integrate coverage across the pixel's width, including fractional corner x.
    coverage = np.zeros((height, len(x)))
    for offset in (-.375, -.125, .125, .375):
        sub_x = x + offset
        sub_y = np.interp(sub_x, (left[0], front[0], right[0]), (left[1], front[1], right[1]))
        coverage += np.clip(sub_y - y + .5, 0, 1) * ((sub_x >= left[0]) & (sub_x < right[0]))
    alpha = (1 - edge_band) * sampled[:, :, 3] + edge_band * (coverage * (255 / 4))
    # The 3D assembly clips every vertex to the same horizontal footprint span.
    alpha = np.minimum(alpha, 255 * np.clip(np.minimum(x + .5, right[0]) - np.maximum(x - .5, left[0]), 0, 1))
    paint.putalpha(Image.fromarray(np.rint(alpha).astype(np.uint8)))
    return paint, [pivot[0] - x0, pivot[1]]
