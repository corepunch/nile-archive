"""Register original decoded Homescapes sprites for the shared hex atlas.
No recoloring or derived damage states: only uniform sizing/rotation and the
canonical ground mask. Each power-up is a standalone, color-independent piece.
"""
import json
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engine/art/homescapes/sprites'
ALIASES = {**{f'kind-{i}': f'chip-{i}' for i in range(6)},
           'ray-row': 'rocket-horizontal', 'ray-column': 'rocket-vertical',
           'ray-diagonal': 'rocket-horizontal', 'prism': 'rainbow-ball', 'chain': 'chain-1', 'delivery': 'donut'}


def registered():
    images, registrations = {}, {}
    mask = Image.open(ROOT / 'engine/art/hex-tile/hex-mask-128.png').getchannel('A')
    for path in sorted(SOURCE.glob('*.png')):
        source = Image.open(path).convert('RGBA')
        for name in [path.stem] + [alias for alias, original in ALIASES.items() if original == path.stem]:
            angle = {'ray-row': -30, 'ray-diagonal': -150}.get(name, 0)
            sprite = source.rotate(angle, Image.Resampling.BICUBIC, expand=True) if angle else source.copy()
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
            if name in ('carpet', 'honey-material'):
                # These are source material previews; clip to the hex without fabricating opaque pixels.
                canvas = source.resize((128,128), Image.Resampling.LANCZOS)
                canvas.putalpha(ImageChops.multiply(canvas.getchannel('A'),mask))
            images[name] = canvas
            registrations[name] = {'source': str(path.relative_to(ROOT)), 'rotation': angle,
                                   'registered_size': list(candidate.size), 'canvas': [128,128],
                                   'mask': name in ('carpet','honey-material')}
    return images, registrations


def inputs():
    return [Path(__file__), ROOT/'engine/art/hex-tile/hex-mask-128.png'] + sorted(SOURCE.glob('*.png'))


if __name__ == '__main__':
    _, records = registered()
    print(json.dumps(records,indent=2,sort_keys=True))
