#!/usr/bin/env python3
"""Build and check the engine's and each game's match-3 atlases.

Every registered sprite is packed into one atlas per kind of art, so a reskin
redraws one family at a time in one style: pieces, blockers, cells, boosters,
hud and fx (see docs/ASSET_LAYOUT.md). Backgrounds are separate files, never
packed. Match-3 ice uses a canonical mask and baked opacity. Control sprites
are packed with their authored colors and alpha. --check never writes runtime
assets.
"""
import argparse
import importlib.util
import hashlib
import io
import json
import math
from os.path import relpath
from pathlib import Path

from PIL import Image, ImageChops
from match3_elements_art import NAMES as ELEMENT_NAMES
import match3_buttons
import match3_theme_art
import pack_particles

ROOT = Path(__file__).resolve().parents[1]
ICE_DIR = ROOT / 'art/match3-ice'
ICE_CROPS = {'ice-1': (129, 66, 819, 756), 'ice-2': (1060, 66, 1750, 756)}
ICE_OPACITY_RAMPS = {
    'ice-1': {'luma': [140, 230], 'alpha': [62, 224]},
    # The two-hit pane's painted highlights are dimmer than the broken rim.
    'ice-2': {'luma': [155, 199], 'alpha': [78, 250]},
}
HEX_MASK = ROOT / 'engine/art/hex-tile/hex-mask-128.png'
ICE_INPUTS = [ICE_DIR / name for name in ('source.png', 'open-hex.png', 'concept.png', 'clear-shell.png',
                                         'prompt.txt', 'transparency-prompt.txt', 'hexagon-prompt.txt',
                                         'filled-pane-prompt.txt')]
ICE_INPUTS += [HEX_MASK, ROOT / 'engine/art/hex-tile/hex-mask-preview.png']
SQUARE_DIR = ROOT / 'art/match3-square'
SIGNBOARD_DIR = ROOT / 'art/match3-signboards'
SIGNBOARD_CROPS = {
    # Centre each crop on the painted face so live counters share its axis.
    'relic-rush': (18, 93, 1752, 449),
    'christmas-market': (18, 496, 1752, 786),
}
STATES = ['normal', 'selected', 'pressed', 'hover', 'disabled']
NAMES = ([f'kind-{i}' for i in range(8)] +
         ['ray-row', 'ray-column', 'ray-diagonal', 'bomb', 'prism', 'sand', 'chain', 'ice-2',
          'ice-1', 'selected', 'hint', 'guide', 'cell-mask', 'score', 'complete', 'moves'] +
         [f'{tool}-{state}' for tool in ['pickaxe', 'dynamite', 'sunburst', 'pause'] for state in STATES] +
         ['hud-panel', 'tool-tray', 'board-frame', 'background'] +
         [f'spark-{i}' for i in range(8)] + [f'ice-puff-{i}' for i in range(4)] + [f'impact-{i}' for i in range(4)])
# Cells of the authored source in grid order. The excavation tile ('sand') and
# the power-ups served mechanics the engine no longer has; their cells stay,
# unregistered.
UNREGISTERED = {'sand', 'ray-row', 'ray-column', 'ray-diagonal', 'bomb', 'prism'}
HEX = {'chain', 'ice-2', 'ice-1', 'selected', 'hint', 'cell-mask', 'board-frame'}


# One atlas per kind of art, in the order the generated tables list them.
GROUPS = ['pieces', 'blockers', 'cells', 'hud', 'fx']
HUD_NAMES = {'score', 'complete', 'moves', 'life', 'signboard', 'hud-panel', 'tool-tray', 'discovery-star', 'next-clue'}
BOARD_GROUPS = ['pieces', 'blockers', 'cells', 'fx']   # the board skin
HUD_GROUPS = ['hud']                                   # the board HUD
RELIC_HUD_ICONS = {'score', 'complete', 'life', 'discovery-star', 'next-clue', 'shop-built', 'shop-locked'}


def group_of(name):
    """The atlas a frame belongs to, by its name."""
    if name.startswith(('fx-', 'spark-', 'ice-puff-', 'impact-')) or name == 'glow':
        return 'fx'
    if name.startswith(('chain', 'ice-', 'stone-', 'crate-')):
        return 'blockers'
    if name.startswith(('tile-', 'square-')) or name in ('selected', 'hint', 'guide', 'cell-mask', 'board-frame'):
        return 'cells'
    if name in HUD_NAMES or name.startswith(('pause-', 'board-pause-', 'shop-')):
        return 'hud'
    return 'pieces'


CELL = 128   # pieces, blockers, cells, boosters and HUD icons are all 128x128


def grid_layout(sprites, columns):
    """128x128 frames on an even grid in name order, then other sizes shelved below."""
    cells = sorted(name for name, sprite in sprites.items() if sprite.size == (CELL, CELL))
    frames = {name: [i % columns * CELL, i // columns * CELL, CELL, CELL] for i, name in enumerate(cells)}
    top = (len(cells) + columns - 1) // columns * CELL
    rest = {name: sprite for name, sprite in sprites.items() if name not in frames}
    bottom = top
    if rest:
        shelved, bottom = frame_layout(rest, columns * CELL, top + 2)
        frames |= shelved
    return frames, bottom


ACTION_STRIP = ROOT / 'art/match3-buttons/actions.png'


def pack_groups(sprites, piece_icons=()):
    """{group: (image, frames)}: each group in the smallest power-of-two sheet."""
    actions = grid_sprites(ACTION_STRIP, ['action-build', 'action-play', 'action-levels', 'action-pause'], 4)
    sprites = sprites | actions
    groups = {}
    for name, sprite in sprites.items():
        group = 'pieces' if name in piece_icons else group_of(name)
        groups.setdefault(group, {})[name] = sprite
    packed = {}
    for group in GROUPS:
        members = groups.get(group)
        if not members:
            continue
        best = None
        for width in (256, 512, 1024, 2048, 4096):
            if any(sprite.width + 4 > width for sprite in members.values()):
                continue
            frames, bottom = grid_layout(members, width // CELL)
            height = 1 << (bottom - 1).bit_length()
            key = (width * height, max(width, height))
            if height <= 4096 and (best is None or key < best[0]):
                best = key, width, height, frames
        _, width, height, frames = best
        image = Image.new('RGBA', (width, height))
        paste_frames(image, members, frames)
        packed[group] = image, dict(sorted(frames.items()))
    return packed


def lua_frames(frames, indent):
    return ''.join(f'{indent}["{name}"]={{' + ','.join(map(str, box)) + '},\n' for name, box in frames.items())


def lua_sheet(path, frames, indent='    '):
    return f'{indent}{{path="{path}", frames={{\n' + lua_frames(frames, indent + '    ') + f'{indent}}}}}'


def lua_strings(table, indent='    '):
    return ''.join(f'{indent}    ["{k}"]="{v}",\n' for k, v in sorted(table.items()))


def frame_index(packed):
    """{frame: {'atlas': group, 'box': [x, y, w, h]}} across every packed atlas."""
    return {name: {'atlas': group, 'box': box} for group, (_, frames) in packed.items() for name, box in frames.items()}


def crop_frames(image, frames):
    return {name: image.crop((x, y, x + w, y + h)) for name, (x, y, w, h) in frames.items()}


def write_asset(path, value):
    if isinstance(value, str):
        value = value.encode()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(value)


def png(image):
    result = io.BytesIO()
    image.save(result, format='PNG', optimize=True)
    return result.getvalue()


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def provenance(inputs, outputs):
    # Registration and JPEG decoding are authoring steps. Verify the exact
    # recipe, inputs AND registered deliverables without reauthoring artwork
    # through a different platform's resampling/decoder implementation.
    inputs = [*inputs, ACTION_STRIP]
    return {'recipe': fingerprint(Path(__file__)),
            'inputs': {str(p.relative_to(ROOT)): fingerprint(p) for p in sorted(set(inputs))},
            'outputs': {str(p.relative_to(ROOT)): fingerprint(p) for p in sorted(set(outputs))}}


def verify_provenance(manifest_path):
    manifest = json.loads(manifest_path.read_text())
    recorded = manifest['provenance']
    assert recorded['recipe'] == fingerprint(Path(__file__)), 'Atlas recipe changed: run python3 tools/match3_atlas.py'
    for group in ['inputs', 'outputs']:
        for name, digest in recorded[group].items():
            assert fingerprint(ROOT / name) == digest, f'Stale {name}: run python3 tools/match3_atlas.py'
    print(f'{manifest_path.relative_to(ROOT)}: recipe, {len(recorded["inputs"])} inputs and {len(recorded["outputs"])} outputs verified')
    return manifest


def registered_ice():
    sprites, records = {}, {}
    with Image.open(HEX_MASK) as reference:
        mask = reference.getchannel('A')
    with Image.open(ICE_DIR / 'source.png') as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (1886, 834)
        for name, box in ICE_CROPS.items():
            ramp = ICE_OPACITY_RAMPS[name]
            dark, light = ramp['luma']
            transparent, opaque = ramp['alpha']
            opacity_curve = [round(transparent + (opaque - transparent) * min(1, max(0, (value - dark) / (light - dark))))
                             for value in range(256)]
            sprite = sheet.crop(box).resize(mask.size, Image.Resampling.LANCZOS)
            paint = sprite.getchannel('A')
            if name == 'ice-2':
                # The painted pane must have material under the entire mask.
                coverage = paint.point(lambda alpha: 255 if alpha >= 240 else 0)
                assert ImageChops.subtract(mask, coverage).getbbox() is None, 'Incomplete full ice painting'
                alpha = mask
            else:
                # Keep the painted fracture while fitting the lower three sides.
                alpha = ImageChops.multiply(paint, mask)
            opacity = sprite.convert('L').point(opacity_curve)
            sprite.putalpha(ImageChops.multiply(alpha, opacity))
            sprites[name] = sprite
            records[name] = {'source': 'art/match3-ice/source.png', 'prompt': 'art/match3-ice/filled-pane-prompt.txt',
                             'crop': list(box), 'canvas': list(mask.size), 'opacity_ramp': ramp,
                             'mask': str(HEX_MASK.relative_to(ROOT))}
    return sprites, records


def build_default(check):
    manifest_path = ROOT / 'engine/art/match3/manifest.json'
    if check:
        verify_provenance(manifest_path)
        return
    source = Image.open(ROOT / 'engine/art/match3/source.png').convert('RGBA')
    brick = Image.open(ROOT / 'engine/art/match3/source-brick.png').convert('RGBA')
    rows = [0, 167, 338, 499, 644, 795, 947, 1103, 1254]
    assert source.size == (1254, 1254)
    image = Image.new('RGBA', (1024, 2048))
    frames, registration = {}, {}
    for i, name in enumerate(NAMES):
        if name in UNREGISTERED: continue
        row, col = divmod(i, 8)
        box = [round(col * source.width / 8), rows[row], round((col + 1) * source.width / 8), rows[row + 1]]
        sprite = source.crop(box)
        if name == 'kind-1':
            box = [156, 36, 315, 163]
            sprite = brick.crop(box)
        angle = 30 if name in HEX else 0
        if angle:
            sprite = sprite.rotate(angle, Image.Resampling.BICUBIC, expand=True)
        sprite.thumbnail((124, 124), Image.Resampling.LANCZOS)
        x, y = col * 128, row * 128
        image.paste(sprite, (x + (128 - sprite.width) // 2, y + (128 - sprite.height) // 2))
        frames[name] = [x, y, 128, 128]
        registration[name] = {'crop': box, 'rotation': angle, 'size': list(sprite.size), 'runtime': frames[name]}
        if name == 'kind-1':
            registration[name]['source'] = 'engine/art/match3/source-brick.png'
            registration[name]['prompt'] = 'engine/art/match3/brick.prompt.txt'
    element_sources = []
    for i, name in enumerate(ELEMENT_NAMES):
        path = ROOT / 'engine/art/registered/board-states' / f'{name}.png'
        element_sources.append(path)
        sprite = Image.open(path).convert('RGBA')
        assert sprite.size == (128, 128)
        row, col = divmod(i, 8)
        x, y = col * 128, 1024 + row * 128
        image.paste(sprite, (x, y))
        frames[name] = [x, y, 128, 128]
        registration[name] = {'source': str(path.relative_to(ROOT)), 'runtime': frames[name],
                              'transform': 'RGBA canvas copied without change'}
    originals, registration_h = registered_ice()
    chains, chain_records = match3_theme_art.registered_chains('relic-rush', ROOT)
    originals.update(chains)
    registration_h.update(chain_records)
    start = 11 * 8
    end = start + sum(name not in frames for name in originals)
    required_height = ((end + 7) // 8) * 128
    if required_height > image.height:
        expanded = Image.new('RGBA', (image.width, 1 << (required_height - 1).bit_length()))
        expanded.paste(image, (0, 0))
        image = expanded
    for name, sprite in sorted(originals.items()):
        if name in frames:
            x,y,_,_ = frames[name]
        else:
            row,col = divmod(start,8);start += 1
            x,y = col*128,row*128
        image.paste(sprite,(x,y))
        frames[name] = [x,y,128,128]
        registration[name] = registration_h[name]
    frames["glow"] = frames["spark-0"]
    effects, effect_sources = pack_particles.registered(ROOT / 'games/relic-rush')
    effect_top = max(y + h for _, y, _, h in frames.values()) + 2
    effect_frames, bottom = frame_layout(effects, image.width, effect_top)
    assert bottom <= image.height
    paste_frames(image, effects, effect_frames)
    for name, box in effect_frames.items():
        assert name not in frames
        frames[name] = box
        registration[name] = {'source': str(effect_sources[name].relative_to(ROOT)), 'runtime': box}
    # Split the registered grid into one atlas per kind; the background tile
    # becomes its own image, and glow stays the first spark.
    sprites = crop_frames(image, frames)
    background = sprites.pop('background')
    del sprites['glow']
    packed = pack_groups(sprites)
    outputs = [ROOT / 'engine/data/board/backs/background.png', ROOT / 'engine/lua/match3/frames.lua']
    write_asset(outputs[0], png(background))
    sheets = []
    for group, (sheet, sheet_frames) in packed.items():
        path = f'data/board/{group}.png'
        write_asset(ROOT / 'engine' / path, png(sheet))
        outputs.append(ROOT / 'engine' / path)
        sheets.append(lua_sheet(path, sheet_frames, '        '))
    write_asset(outputs[1], '-- Generated by python3 tools/match3_atlas.py; do not edit.\n'
                '-- The engine\'s default skin: one atlas per kind of art, read from the\n'
                '-- engine\'s resource directory, and a separate background.\n'
                'return {\n    engine=true,\n    sheets={\n' + ',\n'.join(sheets) + ',\n    },\n'
                '    images={\n        ["background"]="data/board/backs/background.png",\n    },\n'
                '    aliases={\n        ["glow"]="spark-0",\n    },\n}\n')
    manifest = {'generator': 'built-in image_gen; one source sheet, all icon/control states together',
                'source': 'engine/art/match3/source.png', 'prompt': 'engine/art/match3/prompt.txt',
                'kinds': ['gold', 'brick', 'timber', 'grain', 'stone', 'water', 'apple', 'fish'],
                'reference': 'https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/',
                'atlases': {group: {'runtime': f'engine/data/board/{group}.png', 'size': list(sheet.size)}
                            for group, (sheet, _) in packed.items()},
                'images': {'background': 'engine/data/board/backs/background.png'},
                'aliases': {'glow': 'spark-0'},
                'frames': frame_index(packed), 'registration': registration,
                'reproduction': 'python3 tools/match3_atlas.py', 'review': 'docs/review/match3/README.md'}
    manifest['provenance'] = provenance(
        [ROOT / 'engine/art/match3' / name for name in ['source.png', 'source-brick.png', 'prompt.txt', 'brick.prompt.txt']]
        + element_sources + ICE_INPUTS + match3_theme_art.chain_inputs()
        + list(effect_sources.values()) + [Path(pack_particles.__file__), Path(match3_theme_art.__file__)],
        outputs)
    write_asset(manifest_path, json.dumps(manifest, indent=2) + '\n')


def frame_layout(sprites, width, y=2):
    x, row_h, frames = 2, 0, {}
    for name in sorted(sprites, key=lambda name: (-sprites[name].height, name)):
        sprite = sprites[name]
        assert sprite.width + 4 <= width, name
        if x + sprite.width + 2 > width:
            x, y, row_h = 2, y + row_h + 4, 0
        frames[name] = [x, y, sprite.width, sprite.height]
        x, row_h = x + sprite.width + 4, max(row_h, sprite.height)
    return frames, y + row_h + 2


def paste_frames(image, sprites, frames):
    for name, sprite in sprites.items():
        x, y, w, h = frames[name]
        assert y + h <= image.height, name
        image.paste(sprite, (x, y))
        assert image.crop((x, y, x + w, y + h)).tobytes() == sprite.tobytes(), name


def grid_sprites(path, names, columns, side=128):
    """Named cells of a registered grid sheet, read row by row."""
    with Image.open(path) as sheet:
        sheet = sheet.convert('RGBA')
        return {name: sheet.crop((i % columns * side, i // columns * side, (i % columns + 1) * side, (i // columns + 1) * side))
                for i, name in enumerate(names) if name}


def folder_sprites(folder, prefix):
    return {prefix + path.stem: path for path in sorted(folder.glob('*.png'))}


# (destination, source) axis stops for the painted Relic Rush frame. Each
# port spans 44:68, or 60:84 on the opposite side of a diagonal join. The
# 128 px square maps to one board step. The inset corner adds 48 px of
# padding on each side, so its ports move by 48 and the pivot stays centred.
SQUARE_INNER_PAD = 48
SQUARE_FRAME_STOPS = {
    'square-frame-edge': (
        [(0, 30), (128, 598)],
        [(42, 210), (44, 219), (68, 332), (70, 341)],
    ),
    'square-frame-outer': (
        [(42, 806), (44, 816), (68, 933), (128, 1221)],
        [(42, 210), (44, 219), (68, 332), (128, 595)],
    ),
    'square-frame-inner': (
        [(0, 28), (48, 206), (92, 360), (116, 452), (118, 460)],
        [(0, 633), (48, 806), (92, 961), (116, 1056), (118, 1064)],
    ),
    'square-frame-diagonal': (
        [(0, 650), (44, 839), (60, 917), (68, 953), (84, 1031), (128, 1223)],
        [(0, 652), (44, 848), (60, 921), (68, 960), (84, 1035), (128, 1222)],
    ),
}


def square_frame_sprites(root):
    source = root / 'art/square-frame/source.png'
    foliage = source.with_name('large-foliage.png')
    inputs = [source, foliage, *[source.with_name(name) for name in (
        'layout.png', 'prompt.txt', 'foliage.png', 'retouch-prompt.txt',
        'large-foliage-layout.png', 'large-foliage-prompt.txt',
    )]]
    sprites, registration = {}, {}
    for name, (x_stops, y_stops) in SQUARE_FRAME_STOPS.items():
        inner = name == 'square-frame-inner'
        path = foliage if inner else source
        padding = SQUARE_INNER_PAD if inner else 0
        side = CELL + 2 * padding
        rail = 44 + padding
        mesh = []
        for (dx0, sx0), (dx1, sx1) in zip(x_stops, x_stops[1:]):
            for (dy0, sy0), (dy1, sy1) in zip(y_stops, y_stops[1:]):
                # Extend the foliage into the notch while trimming the two
                # stone ends at the same midpoint as their straight neighbours.
                if inner and ((dx1 <= padding and dy0 >= rail) or (dy1 <= padding and dx0 >= rail)):
                    continue
                mesh.append(((dx0, dy0, dx1, dy1), (sx0, sy0, sx0, sy1, sx1, sy1, sx1, sy0)))
        with Image.open(path) as sheet:
            sprite = sheet.convert('RGBA').transform((side, side), Image.Transform.MESH, mesh, Image.Resampling.BICUBIC)
        registered = root / 'art/registered/square-cells' / f'{name}.png'
        write_asset(registered, png(sprite))
        sprites[name] = sprite
        registration[name] = {
            'source': relpath(path, root), 'size': list(sprite.size),
            'x_stops': x_stops, 'y_stops': y_stops, 'registered': relpath(registered, root),
        }
        if inner:
            registration[name]['join_padding'] = padding
        inputs.append(registered)
    return sprites, inputs, registration


def square_cells(game, root):
    source = SQUARE_DIR / 'source.png'
    ornaments = SQUARE_DIR / 'ornaments.png'
    row = 0 if game == 'relic-rush' else 512
    materials = {
        'square-plain': (0, 0, 256, 256),
        'square-target': (256, 0, 512, 256),
        'square-selected': (512, 0, 768, 256),
        'square-double': (768, 0, 1024, 256),
        'square-trim': (1024, 0, 1280, 76),
        'square-grout': (1312, 32, 1504, 224),
    }
    sprites, registration = {}, {}
    inputs = [source, SQUARE_DIR / 'prompt.txt', SQUARE_DIR / 'lighting-prompt.txt']
    decorations = {}
    sheets = [(source, materials)]
    if game == 'relic-rush':
        del materials['square-trim']
    else:
        decorations = {
            'square-foliage': (0, 0, 512, 512),
            'square-joint': (512, 0, 1024, 512),
            'square-medallion': (1024, 0, 1536, 512),
        }
        sheets.append((ornaments, decorations))
        inputs += [ornaments, SQUARE_DIR / 'ornaments-prompt.txt']
    for path, crops in sheets:
        with Image.open(path) as sheet:
            for name, (x0, y0, x1, y1) in crops.items():
                box = (x0, y0 + row, x1, y1 + row)
                image = sheet.crop(box).convert('RGBA')
                if name in decorations:
                    # Ignore stray low-alpha pixels when measuring the crop, then retain the authored alpha.
                    left, top, right, bottom = image.getchannel('A').point(lambda a: 255 if a >= 16 else 0).getbbox()
                    left, top, right, bottom = left - 4, top - 4, right + 4, bottom + 4
                    assert 0 <= left < right <= image.width and 0 <= top < bottom <= image.height, name
                    image = image.crop((left, top, right, bottom))
                    box = (box[0] + left, box[1] + top, box[0] + right, box[1] + bottom)
                size = (128, 38) if name == 'square-trim' else (128, 128)
                if name in decorations:
                    image.thumbnail(size, Image.Resampling.LANCZOS)
                    sprite = Image.new('RGBA', size)
                    sprite.paste(image, ((128 - image.width) // 2, (128 - image.height) // 2))
                else:
                    sprite = image.resize(size, Image.Resampling.LANCZOS)
                # Isolate the painted rim so the active target remains visible through it.
                if name == 'square-selected':
                    sprite.paste((0, 0, 0, 0), (11, 11, 117, 117))
                registered = root / 'art/registered/square-cells' / f'{name}.png'
                write_asset(registered, png(sprite))
                sprites[name] = sprite
                registration[name] = {'source': relpath(path, root), 'crop': list(box), 'size': list(size),
                                      'registered': relpath(registered, root)}
                if name == 'square-selected':
                    registration[name]['transparent_center'] = [11, 11, 117, 117]
                inputs.append(registered)
    if game == 'relic-rush':
        frame_sprites, frame_inputs, frame_registration = square_frame_sprites(root)
        sprites.update(frame_sprites)
        registration.update(frame_registration)
        inputs.extend(frame_inputs)
    return sprites, inputs, registration


def game_sprites(game, root):
    """The game's other registered sprite sets, under the keys its art.lua uses."""
    registered = root / 'art/registered'
    files = folder_sprites(registered / 'board-tiles', 'tile-')
    files |= folder_sprites(registered / 'story-pieces', 'story-')
    sprites, inputs = {}, []
    if game == 'relic-rush':
        manifest = json.loads((root / 'art/board-states/manifest.json').read_text())
        files |= folder_sprites(registered / 'resource-pieces', 'resource-')
        campaign = [f'campaign-{key}' for row in manifest['campaign_pieces']['rows'] for key in row]
        sprites |= grid_sprites(registered / 'campaign-pieces.png', campaign, 5)
        sprites |= grid_sprites(registered / 'result-icons.png', list(manifest['result_icons']['icons']), 2)
        gems = manifest['bonus_gems']
        bonus_frames = [f'bonus-{key}' for key in gems['columns']]
        sprites |= grid_sprites(registered / 'bonus-gems.png', bonus_frames, len(bonus_frames))
        inputs += [registered / name for name in ('campaign-pieces.png', 'result-icons.png', 'bonus-gems.png')]
    else:
        manifest = json.loads((root / 'art/manifest.json').read_text())
        bonus_frames = manifest['bonus_buttons']['icons'].values()
        goods = manifest['market_goods']['frames']
        sprites |= grid_sprites(registered / 'market-goods.png', [f'market-{i}' for i in range(len(goods))], 4)
        inputs.append(registered / 'market-goods.png')
    for name, path in files.items():
        sprites[name] = Image.open(path).convert('RGBA')
    return sprites, inputs + list(files.values()), bonus_frames


def build_game(game, check):
    root = ROOT / 'games' / game
    if check:
        verify_provenance(root / 'art/match3-atlas.json')
        return
    registered = root / 'art/registered'
    if game == 'relic-rush':
        spec = importlib.util.spec_from_file_location('relic_assets', root / 'tools/prepare_assets.py')
        assets = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(assets)
        # Keep Relic Rush's original flame, independently of the engine default.
        write_asset(registered / 'tile-sets/relics/1.png', png(assets.original_tile(0, 1)))
        for (pack, kind), image in assets.hex_replacements().items():
            write_asset(registered / f'tile-sets/{pack}/{kind}.png', png(image))
    sources = {}
    packs = ['relics', 'jewels', 'resources'] if game == 'relic-rush' else ['festive']
    for pack in packs:
        for i in range(6):
            sources[f'{pack}-{i}'] = registered / f'tile-sets/{pack}/{i}.png'
    for source in sorted((registered / 'board-states').glob('*.png')):
        if source.stem in ('stone-2', 'stone-3'):
            continue  # Archived campaign sprites from before one-hit stones.
        sources[source.stem] = source
    sources.update((source.stem, source) for source in sorted((registered / 'expedition-hud').glob('*.png'))
                   if not source.stem.startswith('pause-'))
    # Backgrounds stay separate JPEGs; the atlases hold sprites only.
    images = {'background': 'board/backs/background.jpg'}
    aliases = {f'kind-{i}': f'{packs[0]}-{i}' for i in range(6)}
    hud_images, hud_aliases = {}, {}
    if game == 'relic-rush':
        images |= {'scene-1': 'board/backs/scene-1.jpg', 'scene-2': 'board/backs/scene-2.jpg'}
    else:
        aliases['market-16'] = 'festive-1'
        aliases |= {'scene-1': 'background', 'scene-2': 'background'}
        hud_images['character'] = 'story/characters/noelle.png'
        hud_aliases['score'] = 'complete'
    loaded = {name: Image.open(path).convert('RGBA') for name, path in sources.items()}
    signboard_source = SIGNBOARD_DIR / 'source.png'
    signboard_crop = SIGNBOARD_CROPS[game]
    with Image.open(signboard_source) as sheet:
        signboard = sheet.crop(signboard_crop).convert('RGBA')
        signboard.thumbnail((960, 200), Image.Resampling.LANCZOS)
    loaded['signboard'] = signboard
    effects, effect_sources = pack_particles.registered(root)
    loaded.update(effects)
    with Image.open(HEX_MASK) as mask:
        theme, theme_registration = match3_theme_art.registered(root, mask.getchannel('A'))
    ice, ice_records = registered_ice()
    theme.update(ice)
    theme_registration.update(ice_records)
    loaded.update(theme)
    for name in theme:
        sources.pop(name, None)
    glow = Image.new("RGBA", (64, 64))
    glow.putdata([(255, 255, 255, math.floor(255 * max(0, 1 - math.hypot(x - 31.5, y - 31.5) / 32) ** 3))
                  for y in range(64) for x in range(64)])
    loaded["glow"] = glow
    extra, extra_inputs, bonus_frames = game_sprites(game, root)
    assert not set(extra) & set(loaded), set(extra) & set(loaded)
    loaded.update(extra)
    squares, square_inputs, square_registration = square_cells(game, root)
    loaded.update(squares)
    button_centers = {}
    for name in sorted(set(bonus_frames)):
        image = loaded[name]
        x, y = match3_buttons.alpha_center(image)
        button_centers[name] = (f'{x / image.width:.7f}', f'{y / image.height:.7f}')
    piece_icons = RELIC_HUD_ICONS if game == 'relic-rush' else ()
    hud_groups = ['pieces', *HUD_GROUPS] if piece_icons else HUD_GROUPS
    packed = pack_groups(loaded, piece_icons)
    outputs = []
    for group, (sheet, _) in packed.items():
        write_asset(root / f'data/board/{group}.png', png(sheet))
        outputs.append(root / f'data/board/{group}.png')
    header = '-- Generated by python3 tools/match3_atlas.py; do not edit.\n'
    tables = {
        'lua/match3_atlases.lua': header + '-- One atlas per kind of art, each drawn together in one style.\nreturn {\n' +
            ''.join(f'    {group}=' + lua_sheet(f'board/{group}.png', frames).lstrip() + ',\n' for group, (_, frames) in packed.items()) + '}\n',
        'lua/match3_skin.lua': header + 'local atlases = require("match3_atlases")\nreturn {\n    sheets={' +
            ', '.join(f'atlases.{group}' for group in BOARD_GROUPS if group in packed) + '},\n' +
            '    button_centers={\n' + lua_frames(button_centers, '        ') + '    },\n' +
            '    images={\n' + lua_strings(images) + '    },\n    aliases={\n' + lua_strings(aliases) + '    },\n}\n',
        'lua/match3_hud.lua': header + 'local atlases = require("match3_atlases")\nreturn {\n    sheets={' +
            ', '.join(f'atlases.{group}' for group in hud_groups if group in packed) + '},\n' +
            '    images={\n' + lua_strings(hud_images) + '    },\n    aliases={\n' + lua_strings(hud_aliases) + '    },\n}\n',
    }
    for name, text in tables.items():
        write_asset(root / name, text)
        outputs.append(root / name)
    if game == 'relic-rush':
        square_frame_sources = {'frame_source': 'art/square-frame/source.png',
                                'frame_layout': 'art/square-frame/layout.png',
                                'frame_prompt': 'art/square-frame/prompt.txt',
                                'foliage_source': 'art/square-frame/large-foliage.png',
                                'foliage_layout': 'art/square-frame/large-foliage-layout.png',
                                'foliage_prompt': 'art/square-frame/large-foliage-prompt.txt'}
    else:
        square_frame_sources = {'ornaments': '../../art/match3-square/ornaments.png',
                                'ornaments_prompt': '../../art/match3-square/ornaments-prompt.txt'}
    manifest = {'atlases': {group: {'runtime': f'data/board/{group}.png', 'size': list(sheet.size)}
                            for group, (sheet, _) in packed.items()},
                'board': BOARD_GROUPS, 'hud': hud_groups,
                'images': {name: 'data/' + path for name, path in (images | hud_images).items()},
                'aliases': aliases | hud_aliases,
                'frames': frame_index(packed),
                'sources': {name: relpath(path, root) for name, path in sources.items()},
                'effects': {name: relpath(path, root) for name, path in effect_sources.items()},
                'signboard': {'source': '../../art/match3-signboards/source.png',
                              'prompt': '../../art/match3-signboards/prompt.txt',
                              'reference': '../../art/match3-signboards/concept.jpg',
                              'crop': list(signboard_crop), 'size': list(signboard.size),
                              'state': 'static backplate', 'frame': 'signboard'},
                'board_theme': theme_registration,
                'square_cells': {'source': '../../art/match3-square/source.png',
                                 'prompt': '../../art/match3-square/prompt.txt',
                                 'lighting_prompt': '../../art/match3-square/lighting-prompt.txt',
                                 **square_frame_sources,
                                 'frames': square_registration,
                                 'review': 'docs/square-match3.md'},
                'procedural_glow': 'Original 64px white cubic radial alpha; transient light, packed alongside sprites',
                'transform': 'RGBA canvases packed without resizing, recoloring or alpha changes; 2px transparent gutters',
                'reproduction': 'python3 tools/match3_atlas.py', 'review': 'docs/review/trickling/README.md'}
    inputs = list(sources.values()) + list(effect_sources.values()) + extra_inputs + [Path(match3_buttons.__file__)] + square_inputs
    inputs += [signboard_source, SIGNBOARD_DIR / 'prompt.txt', SIGNBOARD_DIR / 'concept.jpg']
    inputs += ICE_INPUTS + match3_theme_art.inputs(root) + [Path(match3_theme_art.__file__), Path(pack_particles.__file__)]
    inputs += [root / 'data' / path for path in (images | hud_images).values()]
    if game == 'relic-rush':
        inputs += [root / name for name in ['tools/prepare_assets.py', 'art/tile-sets/source.png', 'art/tile-sets/source-flat-hex.png']]
        outputs += [registered / 'tile-sets' / pack / f'{kind}.png' for pack, kind in [('relics', 0), ('relics', 1), ('jewels', 0)]]
    manifest['provenance'] = provenance(inputs, outputs)
    write_asset(root / 'art/match3-atlas.json', json.dumps(manifest, indent=2) + '\n')
    print(f'{game}: ' + ', '.join(f'{group} {len(frames)} in {sheet.width}x{sheet.height}' for group, (sheet, frames) in packed.items()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    build_default(args.check)
    for game in ['relic-rush', 'christmas-market']:
        build_game(game, args.check)


if __name__ == '__main__':
    main()
