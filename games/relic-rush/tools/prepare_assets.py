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
    (DATA / 'relics').mkdir(parents=True, exist_ok=True)
    (DATA / 'buildings').mkdir(parents=True, exist_ok=True)
    for name in ('jungle', 'scene-lagoon', 'scene-temple'):
        save_jpg(Image.open(ART / f'{name}.png'), f'{name}.jpg', (768, 1152))
    save_jpg(Image.open(ART / 'island-organic.jpg'), 'island.jpg', (1024, 1536))
    Image.open(ART / 'title.png').save(DATA / 'title.png', optimize=True)

    sheet = Image.open(ART / 'relics.png').convert('RGBA')
    for i in range(6):
        im = sheet.crop((i % 3 * 512, i // 3 * 512, (i % 3 + 1) * 512, (i // 3 + 1) * 512))
        if i == 0:   # the six-sided idol replaces the sheet's square one
            im = Image.open(ART / 'idol-hex.png').convert('RGBA')
        tile(im).save(DATA / 'relics' / f'{i}.png', optimize=True)

    sheet = Image.open(ART / 'buildings.png').convert('RGBA')
    for i in range(10):
        box = (round(i % 5 * sheet.width / 5), round(i // 5 * sheet.height / 2),
               round((i % 5 + 1) * sheet.width / 5), round((i // 5 + 1) * sheet.height / 2))
        im = isolate_sprite(sheet.crop(box))
        im.thumbnail((300, 320), Image.Resampling.LANCZOS)
        im.save(DATA / 'buildings' / f'{i}.png', optimize=True)
    print('relic-rush data ready')


if __name__ == '__main__':
    main()
