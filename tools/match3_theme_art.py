"""Register the authored board-theme sheets for each portrait game."""

from contextlib import ExitStack
from math import sqrt
from pathlib import Path
from statistics import median
from PIL import Image, ImageChops, ImageFilter

from homescapes_atlas import SOURCE as HOMESCAPES
from match3_specials import SPRITES as RENDERED

SLOTS = (
    'chip-0', 'chip-1', 'chip-2', 'chip-3', 'chip-4',
    'chip-5', 'ray-row', 'ray-column', 'ray-diagonal', 'bomb',
    'prism', 'plane', 'carpet-swatch', 'oil-material', 'stone-material',
    'stone-mark-1', 'stone-mark-2', 'stone-mark-3', 'goal-carpet', 'goal-oil',
    'goal-stone', 'oil-bubbles', 'delivery', 'chain', 'chain-2',
)
MATERIALS = {
    'carpet-swatch': (540, 550, 714, 724),
    'oil-material': (782, 550, 956, 724),
    'stone-material': (1026, 550, 1200, 724),
}
# RENDERED sprites are modelled on the board's axes by tools/match3_specials.py.
PLANE_CROP = (418, 627, 836, 1254)   # Relic Rush's painted plane in power-ups.png
OBJECT_SIZE = {'stone-mark-1': 86, 'stone-mark-2': 65, 'stone-mark-3': 38}
SIZE = 128


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


def painted(root):
    return [root / 'art/board-theme' / name for name in (
        'source.png', 'prompt.txt', 'accent-revision.png', 'accent-prompt.txt',
        'power-ups.png', 'power-ups-prompt.txt')]


def rendered(root):
    specials = root / 'art/board-theme/specials'
    return [specials / 'specials.blks'] + [specials / f'{name}.png' for name in RENDERED]


def inputs(root):
    return painted(root) + rendered(root) + [Path(__file__).with_name('match3_specials.py')]


def registered(root, mask):
    path, prompt, accent_path, accent_prompt, power_path, power_prompt = painted(root)
    scene = rendered(root)[0]
    pack = 'relics' if root.name == 'relic-rush' else 'festive'
    areas = reference_areas()
    hex_silhouette = mask.point(lambda alpha: 255 if alpha >= 128 else 0)
    inset = hex_silhouette.filter(ImageFilter.MinFilter(5))
    with ExitStack() as stack:
        source, accent, power = [stack.enter_context(Image.open(p)) for p in (path, accent_path, power_path)]
        for sheet in (source, accent, power):
            assert sheet.mode == 'RGBA' and sheet.size == (1254, 1254), sheet.filename
        frames, records = {}, {}
        for i, slot in enumerate(SLOTS):
            name = f'{pack}-{i}' if i < 6 else slot
            row, col = divmod(i, 5)
            if name in RENDERED:
                sheet = stack.enter_context(Image.open(scene.with_name(f'{name}.png')))
                assert sheet.mode == 'RGBA', sheet.filename
                crop, sprite_prompt = (0, 0) + sheet.size, scene
            elif name == 'plane' and pack == 'relics':
                crop, sheet, sprite_prompt = PLANE_CROP, power, power_prompt
            else:
                crop = MATERIALS.get(name, (
                    round(col * source.width / 5), 265 if row == 1 else round(row * source.height / 5),
                    round((col + 1) * source.width / 5), 270 if row == 0 else round((row + 1) * source.height / 5),
                ))
                sheet, sprite_prompt = (accent, accent_prompt) if pack == 'festive' and i == 1 else (source, prompt)
            sprite = sheet.crop(crop)
            family = 'chip' if i < 6 else 'rocket' if name.startswith('ray-') else name
            target = areas.get(family)
            if name in MATERIALS or name == 'oil-bubbles':
                if name in MATERIALS:
                    # The authored swatches are solid surfaces. ImageGen's
                    # near-opaque alpha is replaced by the live board SDF.
                    assert sprite.getchannel('A').getextrema()[0] >= 240, name
                    sprite = sprite.convert('RGB').convert('RGBA')
                frame = sprite.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
                fit = 'tiled material' if name in MATERIALS else 'tiled authored alpha'
                fitted_size = [SIZE, SIZE]
            else:
                ink = silhouette(sprite).getbbox()
                assert ink, name
                left, top, right, bottom = ink
                sprite = sprite.crop((max(0, left - 5), max(0, top - 5),
                                      min(sprite.width, right + 5), min(sprite.height, bottom + 5)))
                if target:
                    frame, fitted_size, offset = fit_object(sprite, inset, SIZE, target)
                else:
                    frame, fitted_size, offset = fit_object(sprite, mask, OBJECT_SIZE.get(name, 120), None)
                fit = 'centered inside canonical hex with authored alpha'
            frames[name] = frame
            # A painted sprite records its prompt, a rendered one its Scener scene.
            recipe = 'scene' if name in RENDERED else 'prompt'
            records[name] = {'source': str(Path(sheet.filename).relative_to(root)),
                             recipe: str(sprite_prompt.relative_to(root)),
                             'crop': list(crop), 'rotation': 0, 'fit': fit,
                             'fitted_size': fitted_size}
            if name in RENDERED:
                records[name]['generator'] = 'tools/match3_specials.py'
            if target:
                records[name]['offset'] = offset
                records[name]['homescapes_target_area_px'] = target
                records[name]['silhouette_area_px'] = silhouette(frame).histogram()[255]
    return frames, records
