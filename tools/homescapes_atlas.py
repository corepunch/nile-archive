"""Register original decoded Homescapes sprites for the shared hex atlas.
No recoloring or derived damage states: only uniform sizing/rotation and the
canonical ground mask. Each power-up is a standalone, color-independent piece.
"""
import json
from pathlib import Path
from PIL import Image, ImageChops
import homescapes_composites

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engine/art/homescapes/sprites'
# Engine-made art for Homescapes mechanics, from their generator tools.
ENGINE_MADE = {'goal-carpet': 'python3 tools/carpet_goal_icon.py', 'goal-oil': 'python3 tools/oil_art.py',
               'oil-material': 'python3 tools/oil_art.py', 'oil-bubbles': 'python3 tools/oil_art.py'}
def engine_made(name): return ROOT / 'engine/art/match3' / f'{name}.png'
ALIASES = {**{f'kind-{i}': f'chip-{i}' for i in range(6)},
           'ray-row': 'rocket-horizontal', 'ray-column': 'rocket-vertical',
           'ray-diagonal': 'rocket-horizontal', 'prism': 'rainbow-ball', 'chain': 'chain-1', 'delivery': 'donut',
           'tunnel-in': 'portal-entrance-source', 'tunnel-out': 'portal-output-source'}


def registered():
    images, registrations = {}, {}
    mask = Image.open(ROOT / 'engine/art/hex-tile/hex-mask-128.png').getchannel('A')
    for path in sorted(SOURCE.glob('*.png')):
        source = Image.open(path).convert('RGBA')
        for name in [path.stem] + [alias for alias, original in ALIASES.items() if original == path.stem]:
            crop = [13,0,115,128] if name == 'blind-body' else None
            original = source.crop(crop) if crop else source
            angle = {'ray-row': -30, 'ray-diagonal': -150}.get(name, 0)
            sprite = original.rotate(angle, Image.Resampling.BICUBIC, expand=True) if angle else original.copy()
            # Keep freestanding authored alpha entirely inside the canonical hex.
            side = 112
            while True:
                candidate = sprite.copy()
                candidate.thumbnail((side, side), Image.Resampling.LANCZOS)
                canvas = Image.new('RGBA', (128,128))
                canvas.paste(candidate, ((128-candidate.width)//2,(128-candidate.height)//2))
                outside = ImageChops.subtract(canvas.getchannel('A'), mask).point(lambda v: 255 if v >= 128 else 0)
                if not outside.getbbox(): break
                side -= 2
            if name == 'carpet-swatch':
                # A tiling material: the board repeats it under an SDF patch mask.
                canvas = original.resize((128,128), Image.Resampling.LANCZOS)
            if name in ('carpet', 'honey-material', 'membrane-fill-1', 'membrane-fill-2', 'blind-body'):
                # Register source materials to the hex without manufacturing opaque pixels.
                canvas = original.resize((128,128), Image.Resampling.LANCZOS)
                canvas.putalpha(ImageChops.multiply(canvas.getchannel('A'),mask))
            images[name] = canvas
            registrations[name] = {'source': str(path.relative_to(ROOT)), 'rotation': angle,
                                   'crop': crop, 'registered_size': [128,128] if name in ('carpet','carpet-swatch','honey-material','membrane-fill-1','membrane-fill-2','blind-body') else list(candidate.size), 'canvas': [128,128],
                                   'mask': name in ('carpet','honey-material','membrane-fill-1','membrane-fill-2', 'blind-body')}
            if name == 'ice-1': fragment = candidate
    # One-layer ice is the bottom of the cracked shell, not a centred band: rest
    # it on the full shell's bottom edge, as Homescapes does.
    shell_bottom = images['ice-2'].getchannel('A').getbbox()[3]
    images['ice-1'] = Image.new('RGBA', (128,128))
    images['ice-1'].paste(fragment, ((128-fragment.width)//2, shell_bottom-fragment.height))
    registrations['ice-1']['placement'] = 'bottom-aligned to ice-2'
    for name, generator in ENGINE_MADE.items():   # 128px canvases, copied unchanged
        images[name] = Image.open(engine_made(name)).convert('RGBA')
        registrations[name] = {'source': str(engine_made(name).relative_to(ROOT)), 'canvas': [128,128], 'generator': generator}
    composite_images, composite_records = homescapes_composites.registered()
    for name, original in composite_images.items():
        images[name] = original.resize((128,128), Image.Resampling.LANCZOS)
        registrations[name] = {'placement':'shared four-cell footprint',
                               **composite_records[name], 'registered_size':[128,128]}
    return images, registrations


def inputs():
    return [Path(__file__), ROOT/'engine/art/hex-tile/hex-mask-128.png'] + [engine_made(n) for n in ENGINE_MADE] + sorted(SOURCE.glob('*.png')) + homescapes_composites.inputs()


if __name__ == '__main__':
    _, records = registered()
    print(json.dumps(records,indent=2,sort_keys=True))
