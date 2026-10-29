"""Assemble documentation images from frames rendered by tools/screenshots.sh (needs Pillow)."""
import sys
from pathlib import Path

from PIL import Image

src, out = Path(sys.argv[1]), Path(sys.argv[2])


def frames(prefix, count):
    return [Image.open(src / f'{prefix}-{i}.png').convert('RGB').resize((240, 450), Image.LANCZOS) for i in range(count)]


def gif(name, images, ms):
    pal = [im.quantize(colors=160, method=Image.Quantize.MEDIANCUT) for im in images]
    pal[0].save(out / name, save_all=True, append_images=pal[1:], duration=ms, loop=0, optimize=True)


gif('effects-reel.gif', frames('fx-ray', 18) + frames('fx-bomb', 18) + frames('fx-prism', 18), 66)
gif('ui-result-reel.gif', frames('result', 36), 50)

shapes = [Image.open(src / f'shape-{i}.png').convert('RGB').crop((0, 270, 480, 720)).resize((240, 225), Image.LANCZOS) for i in range(1, 11)]
sheet = Image.new('RGB', (240 * 5 + 40, 225 * 2 + 10), (16, 47, 44))
for i, im in enumerate(shapes):
    sheet.paste(im, (i % 5 * 250, i // 5 * 235))
sheet.save(out / 'level-shapes-overview.jpg', quality=86)
print('reels ready')
