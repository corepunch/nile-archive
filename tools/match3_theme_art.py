"""Register the authored board-theme sheets for each portrait game."""

import os
from contextlib import ExitStack
from math import sqrt
from pathlib import Path
from statistics import median
from PIL import Image, ImageChops, ImageFilter

from homescapes_atlas import SOURCE as HOMESCAPES
from match3_specials import SPRITES as RENDERED

ART = Path(__file__).resolve().parents[1] / 'art'
POWER_UP_PAINT = ART / 'match3-power-up-paint'
PAINTED_SPECIALS = RENDERED  # The paint sheet follows the Scener render order, one row per game.
CHAIN_PAINT = ART / 'match3-chain-paint'
PAINTED_CHAINS = ('chain', 'chain-1-mirror', 'chain-2')
# Square viewports within each bay, measured at the outside edges of the mounting plates.
CHAIN_CROPS = (
    ((38, -6, 576, 532), (3, -10, 548, 535), (-6, 2, 517, 525)),
    ((38, -58, 576, 480), (2, -60, 547, 485), (-6, -50, 517, 473)),
)
FLOOR_PAINT = ART / 'match3-terrain'
PAINTED_FLOORS = ('carpet-swatch', 'oil-material', 'goal-carpet', 'goal-oil')
FLOOR_COLUMNS = (0, 444, 887, 1331, 1774)
FLOOR_ROWS = (0, 485, 887)  # Transparent gap between the swatches and goal icons.
BLOCKER_PAINT = ART / 'match3-blockers'
MATERIALS = {'carpet-swatch', 'oil-material'}

SLOTS = (
    'chip-0', 'chip-1', 'chip-2', 'chip-3', 'chip-4',
    'chip-5', 'ray-row', 'ray-column', 'ray-diagonal', 'bomb',
    'prism', 'plane', 'delivery',
) + PAINTED_FLOORS + ('stone-1',)
# Longest side in px. The plane is a thin shape: at its Homescapes area it would span the whole cell.
OBJECT_SIZE = {'plane': 84}
SIZE = 128
# Relic Rush flies Christmas Market's painted plane, its blues remapped by luminance to these parchment
# shades (shadow, midtone, highlight). The drawing, shading and alpha are unchanged.
PLANE_FROM = 'christmas-market'
PLANE_SHADES = ((150, 98, 44), (234, 201, 133), (255, 240, 200))


def silhouette(image):
    return image.getchannel('A').point(lambda alpha: 255 if alpha >= 128 else 0)


def reference_areas():
    """Use native masks so the three rocket axes start with the same target."""
    groups = {
        'chip': tuple(f'chip-{i}' for i in range(6)),
        'rocket': ('rocket-horizontal', 'rocket-vertical'),
        'bomb': ('bomb',), 'prism': ('rainbow-ball',), 'plane': ('plane',),
        'delivery': ('donut',),
    }
    result = {}
    for family, names in groups.items():
        areas = []
        for name in names:
            with Image.open(HOMESCAPES / f'{name}.png') as original:
                areas.append(silhouette(original).histogram()[255])
        # Chips and deliveries already draw on a smaller quad than specials.
        scale = .86 if family in ('chip', 'delivery') else .80
        if family == 'rocket':
            scale *= .80  # Reduce the painted rockets' width and height by 20%.
        result[family] = round(median(areas) * scale ** 2)
    return result


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


def repaint(sprite, shades):
    """Remap a one-hue sprite's luminance onto three shades: its 5th, 50th and 95th percentiles."""
    grey, alpha = sprite.convert('L'), sprite.getchannel('A')
    levels = sorted(g for g, a in zip(grey.getdata(), alpha.getdata()) if a >= 128)
    low, mid, high = (levels[len(levels) * k // 100] for k in (5, 50, 95))
    def ramp(channel):
        dark, base, light = (shade[channel] for shade in shades)
        def at(g):
            if g <= mid:
                return round(base + (dark - base) * min(1.3, (mid - g) / max(1, mid - low)))
            return round(base + (light - base) * min(1., (g - mid) / max(1, high - mid)))
        return grey.point([max(0, min(255, at(g))) for g in range(256)])
    return Image.merge('RGBA', (ramp(0), ramp(1), ramp(2), alpha))


def borrowed_plane(root):
    theme = root.parent / PLANE_FROM / 'art/board-theme'
    return [theme / 'source.png', theme / 'prompt.txt']


def painted(root):
    return [root / 'art/board-theme' / name for name in (
        'source.png', 'prompt.txt', 'accent-revision.png', 'accent-prompt.txt')]


def rendered(root):
    specials = root / 'art/board-theme/specials'
    return [specials / 'specials.blks'] + [specials / f'{name}.png' for name in RENDERED]


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
    borrowed = borrowed_plane(root) if root.name != PLANE_FROM else []
    sun_coin = [root / 'art/board-theme/sun-coin' / name for name in (
        'source.png', 'prompt.txt', 'concept.png')] if root.name == 'relic-rush' else []
    paint = [folder / name for folder, target in ((POWER_UP_PAINT, 'scener-strip.png'),
            (BLOCKER_PAINT, 'reference.png'))
             for name in ('source.png', 'prompt.txt', target)]
    paint += [FLOOR_PAINT / name for name in ('source.png', 'prompt.txt', 'relic-rush-concepts.png', 'christmas-market-concepts.png')]
    return painted(root) + borrowed + sun_coin + rendered(root) + paint + chain_inputs() + [Path(__file__).with_name('match3_specials.py')]


def registered(root, mask):
    path, prompt, accent_path, accent_prompt = painted(root)
    pack = 'relics' if root.name == 'relic-rush' else 'festive'
    areas = reference_areas()
    hex_silhouette = mask.point(lambda alpha: 255 if alpha >= 128 else 0)
    inset = hex_silhouette.filter(ImageFilter.MinFilter(5))
    with ExitStack() as stack:
        source, accent = [stack.enter_context(Image.open(p)) for p in (path, accent_path)]
        power_ups, floors, blockers = [stack.enter_context(Image.open(folder / 'source.png'))
                 for folder in (POWER_UP_PAINT, FLOOR_PAINT, BLOCKER_PAINT)]
        for sheet in (power_ups, floors, blockers):
            assert sheet.mode == 'RGBA', sheet.filename
        for sheet in (source, accent):
            assert sheet.mode == 'RGBA' and sheet.size == (1254, 1254), sheet.filename
        frames, records = registered_chains(root.name, root)
        for i, slot in enumerate(SLOTS):
            name = f'{pack}-{i}' if i < 6 else slot
            row, col = divmod(i, 5)
            is_power_up_paint = name in PAINTED_SPECIALS
            is_floor_paint = name in PAINTED_FLOORS
            is_blocker_paint = name == 'stone-1'
            if name == 'relics-0':
                folder = root / 'art/board-theme/sun-coin'
                sheet = stack.enter_context(Image.open(folder / 'source.png'))
                assert sheet.mode == 'RGBA', sheet.filename
                sprite_prompt = folder / 'prompt.txt'
                crop = (0, 0, *sheet.size)
            elif is_power_up_paint:
                sheet, sprite_prompt = power_ups, POWER_UP_PAINT / 'prompt.txt'
                row = int(root.name == 'christmas-market')
                col = PAINTED_SPECIALS.index(name)
                w, h = sheet.size
                cols = len(PAINTED_SPECIALS)
                crop = (col * w // cols, row * h // 2, (col + 1) * w // cols, (row + 1) * h // 2)
            elif is_blocker_paint:
                sheet, sprite_prompt = blockers, BLOCKER_PAINT / 'prompt.txt'
                col = int(root.name == 'christmas-market')
                crop = (col * sheet.width // 2, 0, (col + 1) * sheet.width // 2, sheet.height)
            elif is_floor_paint:
                row, col = divmod(PAINTED_FLOORS.index(name), 2)
                if root.name == 'christmas-market':
                    col += 2
                sheet, sprite_prompt = floors, FLOOR_PAINT / 'prompt.txt'
                assert sheet.size == (FLOOR_COLUMNS[-1], FLOOR_ROWS[-1]), sheet.filename
                crop = (FLOOR_COLUMNS[col], FLOOR_ROWS[row], FLOOR_COLUMNS[col + 1], FLOOR_ROWS[row + 1])
                if name in MATERIALS:
                    # Register the interior of the square, keeping paint clear of its edges.
                    left, top, right, bottom = silhouette(sheet.crop(crop)).getbbox()
                    side = min(right - left, bottom - top) - 20
                    x = crop[0] + (left + right - side) // 2
                    y = crop[1] + (top + bottom - side) // 2
                    crop = (x, y, x + side, y + side)
            else:
                # Delivery occupies the third cell of the base sheet's last row.
                if name == 'delivery':
                    row, col = 4, 2
                crop = (
                    round(col * source.width / 5), 265 if row == 1 else round(row * source.height / 5),
                    round((col + 1) * source.width / 5), 270 if row == 0 else round((row + 1) * source.height / 5),
                )
                sheet, sprite_prompt = (accent, accent_prompt) if pack == 'festive' and i == 1 else (source, prompt)
                if name == 'plane' and root.name != PLANE_FROM:
                    plane_path, sprite_prompt = borrowed_plane(root)
                    sheet = stack.enter_context(Image.open(plane_path))
                    assert sheet.mode == 'RGBA' and sheet.size == source.size, plane_path
            sprite = sheet.crop(crop)
            if name == 'plane' and root.name != PLANE_FROM:
                sprite = repaint(sprite, PLANE_SHADES)
            family = 'chip' if i < 6 else 'rocket' if name.startswith('ray-') else name
            target = areas.get(family)
            if name in MATERIALS:
                # The live board SDF supplies the alpha at the patch boundary.
                assert sprite.getchannel('A').getextrema()[0] >= 240, name
                frame = sprite.convert('RGB').resize((SIZE, SIZE), Image.Resampling.LANCZOS).convert('RGBA')
                fit = 'tiled material'
                fitted_size = [SIZE, SIZE]
            elif is_blocker_paint:
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
                    frame, fitted_size, offset = fit_object(sprite, inset, OBJECT_SIZE.get(name, SIZE), target)
                else:
                    frame, fitted_size, offset = fit_object(sprite, mask, OBJECT_SIZE.get(name, 120), None)
            frames[name] = frame
            records[name] = {'source': os.path.relpath(sheet.filename, root),
                             'prompt': os.path.relpath(sprite_prompt, root),
                             'crop': list(crop), 'rotation': 0, 'fit': fit,
                             'fitted_size': fitted_size}
            if name == 'relics-0':
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['reference'] = os.path.relpath(sprite_prompt.with_name('concept.png'), root)
            if is_power_up_paint:
                records[name]['generator'] = 'built-in ImageGen'
                records[name]['edit_target'] = os.path.relpath(POWER_UP_PAINT / 'scener-strip.png', root)
                records[name]['geometry'] = f'art/board-theme/specials/{name}.png'
            if is_floor_paint or is_blocker_paint:
                records[name]['generator'] = 'built-in ImageGen'
                if is_blocker_paint:
                    records[name]['reference'] = os.path.relpath(BLOCKER_PAINT / 'reference.png', root)
                else:
                    records[name]['reference'] = os.path.relpath(FLOOR_PAINT / f'{root.name}-concepts.png', root)
                if name not in MATERIALS:
                    records[name]['offset'] = offset
            if name == 'plane' and root.name != PLANE_FROM:
                records[name]['recolor'] = {'luminance_percentiles': [5, 50, 95], 'shades': [list(c) for c in PLANE_SHADES]}
            if target:
                records[name]['offset'] = offset
                records[name]['homescapes_target_area_px'] = target
                records[name]['silhouette_area_px'] = silhouette(frame).histogram()[255]
    return frames, records
