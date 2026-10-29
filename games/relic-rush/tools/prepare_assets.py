"""Build Relic Rush's runtime data/ from the source paintings in art/ (needs Pillow).

    python3 games/relic-rush/tools/prepare_assets.py

Backgrounds are downscaled to what the 480 x 900 screen needs, sprites are cut
out of their sheets (largest opaque component only, so a neighbour that crosses
a sheet cell never leaks in) and centred in square tiles. The engine loads the
resulting PNG/JPG files directly.
"""
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
TILE_SETS = ('relics', 'jewels', 'resources')   # relics is the default, the others are optional art packs
ART, DATA = ROOT / 'art', ROOT / 'data'


def save_jpg(im, name, size):
    im.convert('RGB').resize(size, Image.Resampling.LANCZOS).save(DATA / name, quality=90, subsampling=0, optimize=True)


def isolate_sprite(im):
    im = im.convert('RGBA')
    w, h = im.size
    alpha = im.getchannel('A')
    data = alpha.tobytes()
    seen = bytearray(w * h)
    largest = []
    for start, a in enumerate(data):
        if a <= 45 or seen[start]:
            continue
        seen[start] = 1
        queue, component = deque([start]), []
        while queue:
            at = queue.popleft()
            component.append(at)
            x, y = at % w, at // w
            for nxt in ([at - 1] if x else []) + ([at + 1] if x + 1 < w else []) + ([at - w] if y else []) + ([at + w] if y + 1 < h else []):
                if not seen[nxt] and data[nxt] > 45:
                    seen[nxt] = 1
                    queue.append(nxt)
        if len(component) > len(largest):
            largest = component
    keep = bytearray(w * h)
    for at in largest:
        keep[at] = 255
    mask = Image.frombytes('L', (w, h), bytes(keep)).filter(ImageFilter.MaxFilter(7))
    im.putalpha(ImageChops.multiply(alpha, mask))
    box = im.getchannel('A').getbbox()
    return im.crop(box) if box else im


def tile(im, size=128, inner=116):
    box = im.getchannel('A').point(lambda a: 255 if a > 70 else 0).getbbox()
    if box:
        im = im.crop(box)
    im.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (size, size))
    out.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out


def main():
    # Match pieces: three original six-piece packs in one 6 x 3 sheet. Row order
    # is the pieces' meaning (idol, flame, leaf, scarab, crystal, amphora...).
    sheet = Image.open(ART / 'tile-sets' / 'source.png').convert('RGBA')
    for row, pack in enumerate(TILE_SETS):
        (DATA / 'tile-sets' / pack).mkdir(parents=True, exist_ok=True)
        for col in range(6):
            im = sheet.crop((round(col * sheet.width / 6), round(row * sheet.height / 3),
                             round((col + 1) * sheet.width / 6), round((row + 1) * sheet.height / 3)))
            tile(im, inner=112).save(DATA / 'tile-sets' / pack / f'{col}.png', optimize=True)

    sheet = Image.open(ART / 'buildings.png').convert('RGBA')
    for i in range(10):
        box = (round(i % 5 * sheet.width / 5), round(i // 5 * sheet.height / 2),
               round((i % 5 + 1) * sheet.width / 5), round((i // 5 + 1) * sheet.height / 2))
        im = isolate_sprite(sheet.crop(box))
        im.thumbnail((300, 320), Image.Resampling.LANCZOS)
        im.save(DATA / 'buildings' / f'{i}.png', optimize=True)
    # Busts of the expedition cast for the dialogue, cut from the concept lineup.
    (DATA / 'characters').mkdir(parents=True, exist_ok=True)
    cast = Image.open(ART / 'art-direction' / 'expedition-cast.png').convert('RGBA')
    busts = {'elena': (40, 100, 370, 505), 'mara': (430, 95, 760, 500), 'tomas': (790, 100, 1120, 505), 'adrian': (1160, 85, 1490, 490)}
    for name, box in busts.items():
        im = cast.crop(box)
        im.thumbnail((264, 324), Image.Resampling.LANCZOS)
        im.save(DATA / 'characters' / f'{name}.png', optimize=True)
    print('relic-rush data ready')


if __name__ == '__main__':
    main()
