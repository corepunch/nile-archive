"""Spatially assemble original Homescapes components for the hex adaptation."""
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'engine/art/homescapes/sprites'
MAKER_SOURCE = SOURCE.parent / 'maker-source'
MAKER_REGIONS = ROOT / 'tools/homescapes-reference/maker-named-regions.json'
MAKER_SHELL = ('Match3CarryGeneratorBase', 'Match3CarryGeneratorGlassBack', 'Match3CarryGeneratorGlassFront')
MAKER_DOUGH = {2: 'textures/particles/Match3/CarryGenerator/_0033_02',
               3: 'textures/particles/Match3/CarryGenerator/_0034_01'}
JELLY_FLOWERS = (
    None,
    'jelly-flower-frame-source',
    'jelly-flower-fill-source',
    'jelly-flower-three-pale-source',
    'jelly-flower-five-pale-source',
    'jelly-flower-dark-source',
)


def part(name, size):
    im = Image.open(SOURCE / (name + '.png')).convert('RGBA')
    im.thumbnail(size, Image.Resampling.LANCZOS)
    return im


def maker(charge, regions):
    shell = []
    for name in MAKER_SHELL:
        region = regions[name]
        attrs = region['attributes']
        with Image.open(MAKER_SOURCE / region['output']) as raw:
            sprite = raw.convert('RGBA').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        frame = int(attrs['frameWidth']), int(attrs['frameHeight'])
        at = int(attrs['innerX']), frame[1] - int(attrs['innerY']) - sprite.height
        shell.append((region['output'], sprite, at, frame))
    base, back, front = shell
    stack = Image.new('RGBA', base[3])
    sources = [item[0] for item in shell]
    layers = {item[0]: list(item[2]) for item in shell}
    stack.alpha_composite(base[1], base[2])
    stack.alpha_composite(back[1], back[2])
    if charge:
        source = regions[MAKER_DOUGH[charge]]['output'] if charge in MAKER_DOUGH else None
        path = MAKER_SOURCE / source if source else SOURCE / 'donut-maker-dough-1.png'
        # The dough crops are stored in the same bottom-origin atlas as the shell.
        with Image.open(path) as raw:
            dough = raw.convert('RGBA').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        # The raw and heated rings sit above the heating surface in the
        # official tutorial. Their placement is measured against that view.
        top = 148 if source else base[2][1] + 11
        at = (base[2][0] + (base[1].width - dough.width) // 2, top)
        stack.alpha_composite(dough, at)
        layers['dough'] = list(at)
        sources.append(str(path.relative_to(ROOT)))
    stack.alpha_composite(front[1], front[2])
    crop = stack.getchannel('A').getbbox()
    stack = stack.crop(crop)
    stack.thumbnail((244, 244), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (256, 256))
    canvas.alpha_composite(stack, ((256 - stack.width) // 2, (256 - stack.height) // 2))
    return canvas, {'sources': sources, 'canvas': [256, 256], 'native_layer_offsets': layers,
                    'source_canvas': list(base[3]), 'source_crop': list(crop),
                    'registration': 'native base and glass offsets; shell and dough crops flipped vertically from the bottom-origin atlas; charge preview alignment inferred'}


def jelly(flower, cherry=None):
    base_name = 'jelly-square-source'
    base = Image.open(SOURCE / (base_name + '.png')).convert('RGBA')
    sources = [base_name]
    overlay = part(flower, (94, 94)) if flower else None
    if cherry:
        fruit = ImageOps.mirror(part(cherry, (86, 86)))
        sources.append(cherry)
        if overlay:
            # Use the authored transparent hole to clip the source soft
            # cherry. The outer transparent region is disconnected from it.
            alpha = overlay.getchannel('A')
            hole = alpha.point(lambda value: 255 if value >= 24 else 0)
            ImageDraw.floodfill(hole, (hole.width // 2, hole.height // 2), 128)
            assert hole.getpixel((0, 0)) != 128, 'jelly flower hole opens onto the exterior'
            hole = hole.point(lambda value: 255 if value == 128 else 0)
            contents = Image.new('RGBA', overlay.size)
            contents.alpha_composite(fruit, ((overlay.width - fruit.width) // 2, (overlay.height - fruit.height) // 2))
            contents.putalpha(ImageChops.multiply(contents.getchannel('A'), hole))
            fruit = contents
        base.alpha_composite(fruit, ((base.width - fruit.width) // 2, (base.height - fruit.height) // 2))
    if overlay:
        base.alpha_composite(overlay, ((base.width - overlay.width) // 2, (base.height - overlay.height) // 2))
        sources.append(flower)
    canvas = Image.new('RGBA', (256, 256))
    canvas.alpha_composite(base.resize((200, 200), Image.Resampling.LANCZOS), (28, 28))
    return canvas, {'sources': sources, 'canvas': [256, 256], 'placement': 'single-cell object',
                    'base_size': [200, 200],
                    'flower_size_limit': [94, 94], 'cherry_size_limit': [86, 86] if cherry else None,
                    'cherry_transform': 'horizontal mirror; clip soft cherry to authored flower hole' if overlay and cherry
                    else 'horizontal mirror' if cherry else None,
                    'registration': 'original square and centered source layers, matched to Playrix illustration'}


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
    regions = {record['id']: record for record in json.loads(MAKER_REGIONS.read_text())['records']}
    for charge in range(4):
        name = f'donut-maker-{charge}'
        images[name], records[name] = maker(charge, regions)
    for strength, flower in enumerate(JELLY_FLOWERS, 1):
        name = f'jelly-{strength}'
        images[name], records[name] = jelly(flower)
    for strength, variant in enumerate(('clear', 'soft'), 1):
        name = f'jelly-{strength}-cherry'
        images[name], records[name] = jelly(JELLY_FLOWERS[strength - 1], f'jelly-cherry-{variant}-source')
    return images, records


def inputs():
    regions = json.loads(MAKER_REGIONS.read_text())['records']
    maker_layers = [MAKER_SOURCE / record['output'] for record in regions
                    if record['id'] in MAKER_SHELL or record['id'] in MAKER_DOUGH.values()]
    return [Path(__file__), MAKER_REGIONS, *maker_layers] + [SOURCE / (n+'.png') for n in ['apple-platter-base','goal-target-generator',
            'donut-maker-dough-1',
            'jelly-square-source', 'jelly-cherry-clear-source', 'jelly-cherry-soft-source', *JELLY_FLOWERS[1:]]]
