"""Register the authored board-theme sheets for each portrait game."""

import os
from contextlib import ExitStack
from math import sqrt
from pathlib import Path
from statistics import median
from PIL import Image, ImageChops, ImageFilter


ART = Path(__file__).resolve().parents[1] / 'art'
CHAIN_PAINT = ART / 'match3-chain-paint'
PAINTED_CHAINS = ('chain', 'chain-1-mirror', 'chain-2')
# Square viewports within each bay, measured at the outside edges of the mounting plates.
CHAIN_CROPS = (
    ((38, -6, 576, 532), (3, -10, 548, 535), (-6, 2, 517, 525)),
    ((38, -58, 576, 480), (2, -60, 547, 485), (-6, -50, 517, 473)),
)
BLOCKER_PAINT = ART / 'match3-blockers'
FESTIVE_ATLAS = 'art/festive-pieces'

SLOTS = (
    'chip-0', 'chip-1', 'chip-2', 'chip-3', 'chip-4', 'chip-5', 'stone-1',
)
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


def fit_object(sprite, mask, max_side, target_area):
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
        offset = ((SIZE - fitted.width) // 2, (SIZE - fitted.height) // 2)
        frame.paste(fitted, offset)
        spill = ImageChops.subtract(frame.getchannel('A'), mask).point(lambda alpha: 255 if alpha >= 128 else 0)
        if not spill.getbbox():
            return frame, list(fitted.size), list(offset)
    raise ValueError('empty registered sprite')


def register_stone(sprite, mask):
    """Align the stone face to the board's full flat-top hex."""
    bounds = silhouette(sprite).getbbox()
    assert bounds, 'missing stone'
    # Allow two pixels of face bleed on each edge before applying the exact mask.
    top, bottom = mask.getbbox()[1::2]
    bleed = 2
    face = sprite.crop(bounds).resize((SIZE + 2 * bleed, bottom - top + 2 * bleed), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE))
    offset = (-bleed, top - bleed)
    canvas.paste(face, offset)
    canvas.putalpha(mask)
    return canvas, list(face.size), list(offset)


def painted(root):
    return [root / 'art/board-theme' / name for name in (
        'source.png', 'prompt.txt', 'accent-revision.png', 'accent-prompt.txt')]


def chain_inputs():
    return [CHAIN_PAINT / name for name in ('edge-anchors.png', 'edge-anchors-prompt.txt', 'source.png')] + [
        ART.parent / 'engine/art/hex-tile/hex-mask-preview.png']


def registered_chains(game, manifest_root):
    source, prompt, edit_target, geometry = chain_inputs()
    frames, records = {}, {}
    row = int(game == 'christmas-market')
    with Image.open(source) as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (1671, 941), source
        for col, name in enumerate(PAINTED_CHAINS):
            bay = (col * sheet.width // 3, row * sheet.height // 2,
                   (col + 1) * sheet.width // 3, (row + 1) * sheet.height // 2)
            crop = CHAIN_CROPS[row][col]
            # Isolate the bay before cropping beyond it into transparent padding.
            frames[name] = sheet.crop(bay).crop(crop).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
            records[name] = {'source': os.path.relpath(source, manifest_root),
                             'prompt': os.path.relpath(prompt, manifest_root),
                             'edit_target': os.path.relpath(edit_target, manifest_root),
                             'geometry': os.path.relpath(geometry, manifest_root),
                             'generator': 'built-in ImageGen', 'bay': list(bay), 'crop': list(crop),
                             'fit': 'edge-mounted on the canonical hex with authored alpha',
                             'fitted_size': [SIZE, SIZE]}
    frames['chain-1'] = frames['chain']
    records['chain-1'] = {**records['chain'], 'alias': 'chain'}
    return frames, records


def inputs(root):
    sun_coin = [root / 'art/board-theme/sun-coin' / name for name in (
        'source.png', 'prompt.txt', 'concept.png')] if root.name == 'relic-rush' else []
    festive = [root / FESTIVE_ATLAS / name for name in (
        'source.png', 'prompt.txt', 'layout.png')] if root.name == 'christmas-market' else []
    paint = [BLOCKER_PAINT / name for name in ('source.png', 'prompt.txt', 'reference.png')]
    return painted(root) + sun_coin + festive + paint + chain_inputs()


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
        blockers = stack.enter_context(Image.open(BLOCKER_PAINT / 'source.png'))
        assert blockers.mode == 'RGBA', blockers.filename
        assert source.mode == 'RGBA' and source.size == (1254, 1254), source.filename
        frames, records = registered_chains(root.name, root)
        for i, slot in enumerate(SLOTS):
            name = f'{pack}-{i}' if i < 6 else slot
            row, col = divmod(i, 5)
            is_blocker_paint = name == 'stone-1'
            is_festive_piece = festive is not None and i < 6
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
            elif is_blocker_paint:
                sheet, sprite_prompt = blockers, BLOCKER_PAINT / 'prompt.txt'
                col = int(root.name == 'christmas-market')
                crop = (col * sheet.width // 2, 0, (col + 1) * sheet.width // 2, sheet.height)
            else:
                crop = (
                    round(col * source.width / 5), 265 if row == 1 else round(row * source.height / 5),
                    round((col + 1) * source.width / 5), 270 if row == 0 else round((row + 1) * source.height / 5),
                )
                sheet, sprite_prompt = source, prompt
            sprite = sheet.crop(crop)
            target = REFERENCE_AREAS['chip'] if i < 6 else None
            if is_blocker_paint:
                frame, fitted_size, offset = register_stone(sprite, mask)
                fit = 'full flat-top hex with the canonical face mask'
            else:
                ink = silhouette(sprite).getbbox()
                assert ink, name
                left, top, right, bottom = ink
                sprite = sprite.crop((max(0, left - 5), max(0, top - 5),
                                      min(sprite.width, right + 5), min(sprite.height, bottom + 5)))
                fit = 'centered inside canonical hex with authored alpha'
                if target:
                    frame, fitted_size, offset = fit_object(sprite, inset, SIZE, target)
                else:
                    frame, fitted_size, offset = fit_object(sprite, mask, 120, None)
            frames[name] = frame
            records[name] = {'source': os.path.relpath(sheet.filename, root),
                             'prompt': os.path.relpath(sprite_prompt, root),
                             'crop': list(crop), 'rotation': 0, 'fit': fit,
                             'fitted_size': fitted_size}
            if name == 'relics-0':
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(sprite_prompt.with_name('concept.png'), root)
            if is_festive_piece:
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(sprite_prompt.with_name('layout.png'), root)
            if is_blocker_paint:
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(BLOCKER_PAINT / 'reference.png', root)
                records[name]['offset'] = offset
            if target:
                records[name]['offset'] = offset
                records[name]['target_area_px'] = target
                records[name]['silhouette_area_px'] = silhouette(frame).histogram()[255]
    return frames, records
