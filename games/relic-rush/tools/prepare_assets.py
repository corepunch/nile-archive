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
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TILE_SETS = ('relics', 'jewels', 'resources')   # relics is the default, the others are optional art packs
ART, DATA = ROOT / 'art', ROOT / 'data'
REGISTERED = ART / 'registered'   # registered sprites the atlas packer reads


def save_jpg(im, name, size):
    im.convert('RGB').resize(size, Image.Resampling.LANCZOS).save(DATA / name, quality=90, subsampling=0, optimize=True)


def isolate_sprite(im, with_box=False):
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
    result = im.crop(box) if box else im
    return (result, box or (0,0,w,h)) if with_box else result


def tile(im, size=128, inner=116):
    box = im.getchannel('A').point(lambda a: 255 if a > 70 else 0).getbbox()
    if box:
        im = im.crop(box)
    im.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (size, size))
    out.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    return out


SQUARE_JEWEL_CROP = (34, 207, 345, 518)


def original_tile(row, col):
    sheet = Image.open(ART / 'tile-sets/source.png').convert('RGBA')
    bounds = (round(col * sheet.width / 6), round(row * sheet.height / 3),
              round((col + 1) * sheet.width / 6), round((row + 1) * sheet.height / 3))
    return tile(isolate_sprite(sheet.crop(bounds)), inner=112)


def square_jewel():
    with Image.open(ART / 'tile-sets/source-square-jewel.png') as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (2170, 725)
        return tile(isolate_sprite(sheet.crop(SQUARE_JEWEL_CROP)), inner=112)


def prepare_portraits():
    folder = DATA / 'story/characters'
    folder.mkdir(parents=True, exist_ok=True)
    # These gutters separate each entire silhouette, including the cup and wheat.
    with Image.open(ART / 'art-direction/harbour-family.png') as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (2172, 724)
        for name, left, right in [('sela', 40, 680), ('oren', 680, 1468), ('tavi', 1480, 2172)]:
            bust = sheet.crop((left, 0, right, sheet.height))
            if name == 'tavi':
                # The renderer mirrors the right-hand slot. Store a right-facing source.
                bust = bust.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            bust.thumbnail((320, 364), Image.Resampling.LANCZOS)
            bust.save(folder / (name + '.png'), optimize=True)
    with Image.open(ART / 'art-direction/ina-first-crossing.png') as painting:
        painting = painting.convert('RGB')
        painting.thumbnail((768, 512), Image.Resampling.LANCZOS)
        painting.save(DATA / 'story/scenes/ina-first-crossing.jpg', quality=92, optimize=True)


def main():
    if sys.argv[1:] == ['--portraits-only']:
        prepare_portraits()
        return
    # Match pieces: three original six-piece packs in one 6 x 3 sheet. Row order
    # is the pieces' meaning (idol, flame, leaf, scarab, crystal, amphora...).
    sheet = Image.open(ART / 'tile-sets' / 'source.png').convert('RGBA')
    for row, pack in enumerate(TILE_SETS):
        (REGISTERED / 'tile-sets' / pack).mkdir(parents=True, exist_ok=True)
        for col in range(6):
            im = sheet.crop((round(col * sheet.width / 6), round(row * sheet.height / 3),
                             round((col + 1) * sheet.width / 6), round((row + 1) * sheet.height / 3)))
            tile(isolate_sprite(im), inner=112).save(REGISTERED / 'tile-sets' / pack / f'{col}.png', optimize=True)

    square_jewel().save(REGISTERED / 'tile-sets/jewels/0.png', optimize=True)

    prepare_portraits()
    print('relic-rush data ready')
    subprocess.run([sys.executable, str(ROOT / 'tools/board_assets.py')], check=True)
    subprocess.run([sys.executable, str(ROOT / 'tools/prepare_hud.py')], check=True)


if __name__ == '__main__':
    main()
