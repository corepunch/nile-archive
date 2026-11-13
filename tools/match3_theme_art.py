"""Register the single authored board-theme atlas for each portrait game."""

from PIL import Image, ImageChops

SLOTS = (
    'ray-row', 'ray-column', 'ray-diagonal', 'bomb',
    'prism', 'plane', 'carpet-swatch', 'oil-material',
    'stone-material', 'stone-mark-1', 'stone-mark-2', 'stone-mark-3',
    'goal-carpet', 'goal-oil', 'goal-stone', 'oil-bubbles',
)
MATERIALS = {
    'carpet-swatch': (647, 336, 913, 602),
    'oil-material': (963, 335, 1228, 600),
    'stone-material': (24, 650, 290, 916),
}
# Measured from the major axis of the authored rocket's alpha silhouette.
ROCKET_ROTATION = {'relic-rush': (19.3, .2, -19.1), 'christmas-market': (24.3, .3, -24.8)}
SIZE = 128


def inputs(root):
    return [root / 'art/board-theme' / name for name in ('source.png', 'prompt.txt')]


def registered(root, mask):
    path, prompt = inputs(root)
    with Image.open(path) as source:
        assert source.mode == 'RGBA' and source.size == (1254, 1254), path
        frames, records = {}, {}
        for i, name in enumerate(SLOTS):
            row, col = divmod(i, 4)
            crop = MATERIALS.get(name, (
                round(col * source.width / 4), round(row * source.height / 4),
                round((col + 1) * source.width / 4), round((row + 1) * source.height / 4),
            ))
            sprite = source.crop(crop)
            angle = ROCKET_ROTATION[root.name][i] if i < 3 else 0
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
                side = {'stone-mark-1': 86, 'stone-mark-2': 65, 'stone-mark-3': 38}.get(name, 120)
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
            records[name] = {'source': str(path.relative_to(root)), 'prompt': str(prompt.relative_to(root)),
                             'crop': list(crop), 'rotation': angle, 'fit': fit,
                             'fitted_size': list(fitted.size) if fit.startswith('centered') else [SIZE, SIZE]}
    return frames, records
