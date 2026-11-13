"""Register the authored board-theme sheets for each portrait game."""

from contextlib import ExitStack
from pathlib import Path
from PIL import Image, ImageChops

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
POWER_UPS = ('ray-row', 'ray-column', 'ray-diagonal', 'bomb', 'plane')
# Align the line through the two painted tip centers to the board's axes.
ROCKET_ROTATION = {'relic-rush': (10.5, .3, -14.4), 'christmas-market': (2.8, .2, -4.5)}
OBJECT_SIZE = {'stone-mark-1': 86, 'stone-mark-2': 65, 'stone-mark-3': 38}
SIZE = 128


def inputs(root):
    return [root / 'art/board-theme' / name for name in (
        'source.png', 'prompt.txt', 'accent-revision.png', 'accent-prompt.txt',
        'power-ups.png', 'power-ups-prompt.txt')]


def registered(root, mask):
    path, prompt, accent_path, accent_prompt, power_path, power_prompt = inputs(root)
    pack = 'relics' if root.name == 'relic-rush' else 'festive'
    with ExitStack() as stack:
        source, accent, power = [stack.enter_context(Image.open(p)) for p in (path, accent_path, power_path)]
        for sheet in (source, accent, power):
            assert sheet.mode == 'RGBA' and sheet.size == (1254, 1254), sheet.filename
        frames, records = {}, {}
        for i, slot in enumerate(SLOTS):
            name = f'{pack}-{i}' if i < 6 else slot
            row, col = divmod(i, 5)
            angle = 0
            if name in POWER_UPS and (name != 'plane' or pack == 'relics'):
                index = POWER_UPS.index(name)
                power_row, power_col = divmod(index, 3)
                width, height = power.width // 3, power.height // 2
                crop = (power_col * width, power_row * height, (power_col + 1) * width, (power_row + 1) * height)
                sheet, sprite_prompt = power, power_prompt
                if index < 3:
                    angle = ROCKET_ROTATION[root.name][index]
            else:
                crop = MATERIALS.get(name, (
                    round(col * source.width / 5), 265 if row == 1 else round(row * source.height / 5),
                    round((col + 1) * source.width / 5), 270 if row == 0 else round((row + 1) * source.height / 5),
                ))
                sheet, sprite_prompt = (accent, accent_prompt) if pack == 'festive' and i == 1 else (source, prompt)
            sprite = sheet.crop(crop)
            if name in MATERIALS or name == 'oil-bubbles':
                if name in MATERIALS:
                    # The authored swatches are solid surfaces. ImageGen's
                    # near-opaque alpha is replaced by the live board SDF.
                    assert sprite.getchannel('A').getextrema()[0] >= 240, name
                    sprite = sprite.convert('RGB').convert('RGBA')
                frame = sprite.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
                fit = 'tiled material' if name in MATERIALS else 'tiled authored alpha'
            else:
                ink = sprite.getchannel('A').point(lambda alpha: 255 if alpha >= 128 else 0).getbbox()
                assert ink, name
                left, top, right, bottom = ink
                sprite = sprite.crop((max(0, left - 5), max(0, top - 5),
                                      min(sprite.width, right + 5), min(sprite.height, bottom + 5)))
                if angle:
                    sprite = sprite.rotate(angle, Image.Resampling.BICUBIC, expand=True)
                side = 110 if i < 6 else OBJECT_SIZE.get(name, 120)
                while side > 0:
                    fitted = sprite.copy()
                    fitted.thumbnail((side, side), Image.Resampling.LANCZOS)
                    frame = Image.new('RGBA', (SIZE, SIZE))
                    frame.paste(fitted, ((SIZE - fitted.width) // 2, (SIZE - fitted.height) // 2))
                    spill = ImageChops.subtract(frame.getchannel('A'), mask)
                    if not spill.point(lambda alpha: 255 if alpha >= 128 else 0).getbbox():
                        break
                    side -= 2
                assert side > 0, name
                fit = 'centered inside canonical hex with authored alpha'
            frames[name] = frame
            records[name] = {'source': str(Path(sheet.filename).relative_to(root)),
                             'prompt': str(sprite_prompt.relative_to(root)),
                             'crop': list(crop), 'rotation': angle, 'fit': fit,
                             'fitted_size': list(fitted.size) if fit.startswith('centered') else [SIZE, SIZE]}
    return frames, records
