"""Spatially assemble original Homescapes components for the hex adaptation.

Positions follow the original help illustrations, not recovered prefab geometry.
No source component is recoloured or repainted.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engine/art/homescapes/sprites'


def part(name, size):
    im = Image.open(SOURCE / (name + '.png')).convert('RGBA')
    im.thumbnail(size, Image.Resampling.LANCZOS)
    return im


def registered():
    images, records = {}, {}
    plate = part('apple-platter-base', (246, 246))
    apple = part('goal-target-generator', (70, 70))
    # Back-to-front order follows the cluster in the official eight-apple example.
    positions = [(52,42),(93,42),(134,42),(52,83),(93,83),(134,83),(52,124),(93,124),(134,124)]
    for count in range(1,10):
        canvas = Image.new('RGBA',(256,256))
        canvas.alpha_composite(plate, ((256-plate.width)//2,(256-plate.height)//2))
        for x,y in positions[:count]:
            canvas.alpha_composite(apple,(x,y))
        name=f'apple-platter-{count}'
        images[name]=canvas
        records[name]={'sources':['apple-platter-base','goal-target-generator'], 'canvas':[256,256],
                       'plate_size':list(plate.size), 'apple_size':list(apple.size),
                       'apple_positions':[list(p) for p in positions[:count]],
                       'registration':'manual spatial approximation of official illustration; ninth position is a hex adaptation'}
    base = part('donut-maker-base', (226, 226))
    for charge in range(4):
        canvas=Image.new('RGBA',(256,256))
        canvas.alpha_composite(base,((256-base.width)//2,(256-base.height)//2))
        sources=['donut-maker-base']
        if charge:
            name=f'donut-maker-dough-{charge}'
            dough=part(name,(105,105))
            canvas.alpha_composite(dough,((256-dough.width)//2,48))
            sources.append(name)
        name=f'donut-maker-{charge}'
        images[name]=canvas
        records[name]={'sources':sources,'canvas':[256,256],
                       'registration':'manual spatial approximation; charge mapping inferred, dome not recovered'}
    return images, records


def inputs():
    return [Path(__file__)] + [SOURCE / (n+'.png') for n in ['apple-platter-base','goal-target-generator',
            'donut-maker-base','donut-maker-dough-1','donut-maker-dough-2','donut-maker-dough-3']]
