"""Register the authored board-theme sheets for each portrait game."""

import os
from contextlib import ExitStack
from math import sqrt
from statistics import median
from PIL import Image, ImageChops, ImageFilter


FESTIVE_ATLAS = 'art/festive-pieces'

SIZE = 128


def silhouette(image):
    return image.getchannel('A').point(lambda alpha: 255 if alpha >= 128 else 0)


# Target silhouette area in px, measured from the original chip and scaled.
REFERENCE_AREAS = {'chip': 6273}


def object_offset(sprite, mask):
    """Find the nearest centered placement that leaves clearance on every row."""
    ink = silhouette(sprite)
    left, top, right, bottom = ink.getbbox()
    x = (SIZE - left - right) // 2
    y = (SIZE - top - bottom) // 2
    rows = [(row, bounds[0], bounds[2]) for row in range(top, bottom)
            if (bounds := ink.crop((left, row, right, row + 1)).getbbox())]
    mask_rows = [mask.crop((0, row, SIZE, row + 1)).getbbox() for row in range(SIZE)]
    best = None
    for dy in range(-8, 9):
        yy = y + dy
        lo, hi = x - 8, x + 8
        for row, start, end in rows:
            at = yy + row
            available = mask_rows[at] if 0 <= at < SIZE else None
            if not available:
                break
            lo = max(lo, available[0] - left - start)
            hi = min(hi, available[2] - left - end)
            if lo > hi:
                break
        else:
            xx = min(max(x, lo), hi)
            choice = ((xx - x) ** 2 + dy ** 2, xx, yy)
            if best is None or choice < best:
                best = choice
    return best[1:] if best else None


def fit_object(sprite, mask, max_side, target_area, *, anchor=None):
    if target_area:
        scale = sqrt(target_area / silhouette(sprite).histogram()[255])
        max_side = min(max_side, round(max(sprite.size) * scale))
    for side in range(max_side, 0, -1 if target_area else -2):
        fitted = sprite.copy()
        fitted.thumbnail((side, side), Image.Resampling.LANCZOS)
        frame = Image.new('RGBA', (SIZE, SIZE))
        if target_area:
            offset = object_offset(fitted, mask)
            if offset is not None:
                frame.paste(fitted, offset)
                return frame, list(fitted.size), list(offset)
            continue
        if anchor:
            cx, cy = anchor(fitted)
            offset = (round(SIZE / 2 - cx), round(SIZE / 2 - cy))
            if not (0 <= offset[0] <= SIZE - fitted.width and 0 <= offset[1] <= SIZE - fitted.height):
                continue
        else:
            offset = ((SIZE - fitted.width) // 2, (SIZE - fitted.height) // 2)
        frame.paste(fitted, offset)
        spill = ImageChops.subtract(frame.getchannel('A'), mask).point(lambda alpha: 255 if alpha >= 128 else 0)
        if not spill.getbbox():
            return frame, list(fitted.size), list(offset)
    raise ValueError('empty registered sprite')


def painted(root):
    return [root / 'art/board-theme' / name for name in (
        'source.png', 'prompt.txt', 'accent-revision.png', 'accent-prompt.txt')]


def inputs(root):
    sun_coin = [root / 'art/board-theme/sun-coin' / name for name in (
        'source.png', 'prompt.txt', 'concept.png')] if root.name == 'relic-rush' else []
    festive = [root / FESTIVE_ATLAS / name for name in (
        'source.png', 'prompt.txt', 'layout.png')] if root.name == 'christmas-market' else []
    return painted(root) + sun_coin + festive


def registered(root, mask):
    path, prompt, *_ = painted(root)
    pack = 'relics' if root.name == 'relic-rush' else 'festive'
    hex_silhouette = mask.point(lambda alpha: 255 if alpha >= 128 else 0)
    inset = hex_silhouette.filter(ImageFilter.MinFilter(5))
    with ExitStack() as stack:
        source = stack.enter_context(Image.open(path))
        festive = stack.enter_context(Image.open(root / FESTIVE_ATLAS / 'source.png')) if pack == 'festive' else None
        if festive:
            assert festive.mode == 'RGBA' and festive.size == (1536, 1024), festive.filename
        assert source.mode == 'RGBA' and source.size == (1254, 1254), source.filename
        frames, records = {}, {}
        for i in range(6):
            name = f'{pack}-{i}'
            row, col = divmod(i, 5)
            is_festive_piece = festive is not None
            if is_festive_piece:
                sheet, sprite_prompt = festive, root / FESTIVE_ATLAS / 'prompt.txt'
                row, col = divmod(i, 3)
                crop = (col * 512, row * 512, (col + 1) * 512, (row + 1) * 512)
            elif name == 'relics-0':
                folder = root / 'art/board-theme/sun-coin'
                sheet = stack.enter_context(Image.open(folder / 'source.png'))
                assert sheet.mode == 'RGBA', sheet.filename
                sprite_prompt = folder / 'prompt.txt'
                crop = (0, 0, *sheet.size)
            else:
                crop = (
                    round(col * source.width / 5), 265 if row == 1 else round(row * source.height / 5),
                    round((col + 1) * source.width / 5), 270 if row == 0 else round((row + 1) * source.height / 5),
                )
                sheet, sprite_prompt = source, prompt
            sprite = sheet.crop(crop)
            target = REFERENCE_AREAS['chip']
            ink = silhouette(sprite).getbbox()
            assert ink, name
            left, top, right, bottom = ink
            sprite = sprite.crop((max(0, left - 5), max(0, top - 5),
                                  min(sprite.width, right + 5), min(sprite.height, bottom + 5)))
            frame, fitted_size, offset = fit_object(sprite, inset, SIZE, target)
            frames[name] = frame
            records[name] = {'source': os.path.relpath(sheet.filename, root),
                             'prompt': os.path.relpath(sprite_prompt, root),
                             'crop': list(crop), 'rotation': 0, 'fit': 'authored alpha on a centered 128px canvas',
                             'fitted_size': fitted_size}
            if name == 'relics-0':
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(sprite_prompt.with_name('concept.png'), root)
            if is_festive_piece:
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(sprite_prompt.with_name('layout.png'), root)
            records[name]['offset'] = offset
            records[name]['target_area_px'] = target
            records[name]['silhouette_area_px'] = silhouette(frame).histogram()[255]
    return frames, records
