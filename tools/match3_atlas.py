#!/usr/bin/env python3
"""Build and check the engine's and each game's match-3 atlases.

Every registered sprite is packed into one atlas per kind of art, so a reskin
redraws one family at a time in one style: pieces, blockers, cells, boosters,
hud and fx (see docs/ASSET_LAYOUT.md). Backgrounds are separate files, never
packed. Match-3 ice uses geometry-specific registration and baked opacity. Control sprites
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
import match3_buttons
import match3_theme_art
import pack_particles
import square_board_frame

ROOT = Path(__file__).resolve().parents[1]
HEX_MASK = ROOT / 'engine/art/hex-tile/hex-mask-128.png'
SQUARE_DIR = ROOT / 'art/match3-square'
SQUARE_BLOCKER_CROPS = {
    'chain-square-1': (48, 36, 592, 580),
    'chain-square-2': (662, 36, 1210, 584),
    'ice-square-1': (53, 662, 596, 1199),
    'ice-square-2': (658, 665, 1202, 1199),
}
SQUARE_BLOCKER_INPUTS = [SQUARE_DIR / name for name in (
    'blockers.png', 'blockers-prompt.txt', 'blockers-edit-target.png', 'blockers-ice-reference.png')]
SQUARE_STONE_SOURCE = SQUARE_DIR / 'stones.png'
SQUARE_STONE_PROMPT = SQUARE_DIR / 'stones-prompt.txt'
SQUARE_STONE_REFERENCE = ROOT / 'art/match3-blockers/source.png'
SQUARE_STONE_CROPS = {
    'relic-rush': (181, 90, 828, 737),
    'christmas-market': (1079, 90, 1726, 737),
}
SQUARE_ICE_OPACITY = {'luma': [170, 235], 'opacity': [.55, .95]}
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
# Retired cells remain in the master sheet's grid but do not ship.
UNREGISTERED = {
    'sand', 'ray-row', 'ray-column', 'ray-diagonal', 'bomb', 'prism',
    'chain', 'ice-2', 'ice-1', 'selected', 'hint', 'guide', 'cell-mask', 'board-frame', 'moves',
}


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
    if name.startswith('square-'):
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


def lua_sheet(path, frames, indent='    ', grid_width=None):
    grid = ''
    if grid_width is None:
        entries = lua_frames(frames, indent + '    ')
    else:
        grid = f' grid={CELL},'
        columns = grid_width // CELL
        indices = {}
        for name, (x, y, w, h) in frames.items():
            assert w == h == CELL and x % CELL == y % CELL == 0, name
            indices[name] = (y // CELL) * columns + x // CELL
        entries = ''.join(f'{indent}    ["{name}"]={slot},\n' for name, slot in indices.items())
    return f'{indent}{{path="{path}",{grid} frames={{\n' + entries + f'{indent}}}}}'


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


def registered_square_blockers(game, root):
    source, prompt, edit_target, ice_reference = SQUARE_BLOCKER_INPUTS
    with Image.open(source) as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (1254, 1254)
        sprites = {name: sheet.crop(box).resize((CELL, CELL), Image.Resampling.LANCZOS)
                   for name, box in SQUARE_BLOCKER_CROPS.items()}
    low, high = SQUARE_ICE_OPACITY['luma']
    clear, bright = SQUARE_ICE_OPACITY['opacity']
    curve = [round(255 * (clear + (bright - clear) * min(1, max(0, (value - low) / (high - low)))))
             for value in range(256)]
    for name, sprite in sprites.items():
        if name.startswith('ice-'):
            opacity = sprite.convert('L').point(curve)
            sprite.putalpha(ImageChops.multiply(sprite.getchannel('A'), opacity))
    stone_crop = SQUARE_STONE_CROPS[game]
    with Image.open(SQUARE_STONE_SOURCE) as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (1905, 825)
        stone = sheet.crop(stone_crop).resize((CELL, CELL), Image.Resampling.LANCZOS)
    # The artwork fills the cell to its four lightly rounded corners.
    for x in (8, CELL - 9):
        for y in (8, CELL - 9):
            assert stone.getpixel((x, y))[3] >= 240, f'{game}: stone must fill a square cell'
    sprites['stone-1'] = stone
    return sprites, {
        'source': relpath(source, root),
        'prompt': relpath(prompt, root),
        'edit_target': relpath(edit_target, root),
        'ice_reference': relpath(ice_reference, root),
        'crops': SQUARE_BLOCKER_CROPS,
        'canvas': [CELL, CELL],
        'transform': 'Crop and resize with Lanczos, then multiply ice alpha by the luminance ramp',
        'ice_opacity_ramp': SQUARE_ICE_OPACITY,
        'stone': {
            'source': relpath(SQUARE_STONE_SOURCE, root),
            'prompt': relpath(SQUARE_STONE_PROMPT, root),
            'reference': relpath(SQUARE_STONE_REFERENCE, root),
            'crop': stone_crop,
            'frame': 'stone-1',
            'state': 'one hit',
            'transform': 'Square crop resized to 128px with Lanczos; authored alpha preserved',
        },
        'review': 'docs/square-match3.md#blockers-and-target-hints',
    }


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
        sprite.thumbnail((124, 124), Image.Resampling.LANCZOS)
        x, y = col * 128, row * 128
        image.paste(sprite, (x + (128 - sprite.width) // 2, y + (128 - sprite.height) // 2))
        frames[name] = [x, y, 128, 128]
        registration[name] = {'crop': box, 'rotation': 0, 'size': list(sprite.size), 'runtime': frames[name]}
        if name == 'kind-1':
            registration[name]['source'] = 'engine/art/match3/source-brick.png'
            registration[name]['prompt'] = 'engine/art/match3/brick.prompt.txt'
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
        sheets.append(lua_sheet(path, sheet_frames, '        ', sheet.width if group == 'pieces' else None))
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
        + list(effect_sources.values()) + [Path(pack_particles.__file__)],
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


PAPYRUS_FLOORS = {
    'square-plain': (40, 38, 379, 379),
    'square-target': (457, 39, 797, 379),
    'square-double': (875, 39, 1215, 379),
}


def square_frame_sprites(game, root):
    rail = None
    if game == 'christmas-market':
        sprites, leaf_spec, rail, inputs = square_board_frame.generate_christmas(root / 'art/square-frame')
    else:
        sprites, leaf_spec, inputs = square_board_frame.generate(root / 'art/papyrus-board/stone-cracks.png')
    recipe = relpath(square_board_frame.__file__, root)
    registration = {}
    for name, sprite in sprites.items():
        registered = root / 'art/registered/square-cells' / f'{name}.png'
        write_asset(registered, png(sprite))
        registration[name] = {
            'generator': recipe, 'size': list(sprite.size),
            'pivot': [sprite.width // 2, sprite.height // 2],
            'registered': relpath(registered, root),
        }
        inputs.append(registered)
        if rail:
            registration[name]['rail'] = rail
        if name.endswith('-leaf'):
            registration[name]['foliage'] = leaf_spec
    return sprites, inputs, registration


def square_cells(game, root):
    source = SQUARE_DIR / 'source.png'
    papyrus = root / 'art/papyrus-board/contact.png'
    materials = {
        'square-plain': (0, 0, 256, 256),
        'square-target': (256, 0, 512, 256),
        'square-selected': (512, 0, 768, 256),
        'square-double': (768, 0, 1024, 256),
        'square-grout': (1312, 32, 1504, 224),
    }
    sprites, registration = {}, {}
    inputs = [source, SQUARE_DIR / 'prompt.txt', SQUARE_DIR / 'lighting-prompt.txt']
    if game == 'relic-rush':
        sheets = [(papyrus, PAPYRUS_FLOORS, 0),
                  (source, {name: materials[name] for name in ('square-selected', 'square-grout')}, 0)]
        inputs += [papyrus, papyrus.with_name('contact-layout.png'), papyrus.with_name('contact-prompt.txt')]
    else:
        materials.pop('square-plain')
        plain = root / 'art/square-cells/plain.png'
        sheets = [(source, materials, 512), (plain, {'square-plain': (0, 0, 128, 128)}, 0)]
        inputs.append(plain)
    for path, crops, row in sheets:
        with Image.open(path) as sheet:
            for name, (x0, y0, x1, y1) in crops.items():
                box = (x0, y0 + row, x1, y1 + row)
                size = (128, 128)
                sprite = sheet.crop(box).convert('RGBA').resize(size, Image.Resampling.LANCZOS)
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
    frame_sprites, frame_inputs, frame_registration = square_frame_sprites(game, root)
    sprites.update(frame_sprites)
    registration.update(frame_registration)
    inputs.extend(frame_inputs)
    return sprites, inputs, registration


def game_sprites(game, root):
    """The game's other registered sprite sets, under the keys its art.lua uses."""
    registered = root / 'art/registered'
    files = folder_sprites(registered / 'story-pieces', 'story-')
    sprites, inputs, aliases, outline_centered = {}, [], {}, set()
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
        files.update((name, (root / path).resolve()) for name, path in manifest['wallet_icons'].items())
        buttons = manifest['bonus_buttons']
        bonus_frames = list(buttons['icons'].values())
        outline_centered = set(buttons.get('outline_centered', ()))
        goods = manifest['market_goods']
        aliases = goods['aliases']
        names = [None if name in aliases else name for name in goods['frames']]
        sprites |= grid_sprites(registered / 'market-goods.png', names, 4)
        inputs.append(registered / 'market-goods.png')
    for name, path in files.items():
        sprites[name] = Image.open(path).convert('RGBA')
    return sprites, inputs + list(files.values()), bonus_frames, aliases, outline_centered


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
        write_asset(registered / 'tile-sets/jewels/0.png', png(assets.square_jewel()))
    sources = {}
    packs = ['relics', 'jewels', 'resources'] if game == 'relic-rush' else ['festive']
    for pack in packs:
        for i in range(6):
            sources[f'{pack}-{i}'] = registered / f'tile-sets/{pack}/{i}.png'
    if game == 'relic-rush':
        sources['action-close'] = registered / 'board-states/action-close.png'
    sources.update((source.stem, source) for source in sorted((registered / 'expedition-hud').glob('*.png'))
                   if not source.stem.startswith('pause-'))
    # Backgrounds stay separate JPEGs; the atlases hold sprites only.
    images = {'background': 'board/backs/background.jpg'}
    aliases = {f'kind-{i}': f'{packs[0]}-{i}' for i in range(6)}
    hud_images, hud_aliases = {}, {}
    if game == 'relic-rush':
        images |= {'scene-1': 'board/backs/scene-1.jpg', 'scene-2': 'board/backs/scene-2.jpg'}
    else:
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
    loaded.update(theme)
    for name in theme:
        sources.pop(name, None)
    glow = Image.new("RGBA", (64, 64))
    glow.putdata([(255, 255, 255, math.floor(255 * max(0, 1 - math.hypot(x - 31.5, y - 31.5) / 32) ** 3))
                  for y in range(64) for x in range(64)])
    loaded["glow"] = glow
    extra, extra_inputs, bonus_frames, piece_aliases, outline_centered = game_sprites(game, root)
    assert not set(extra) & set(loaded), set(extra) & set(loaded)
    loaded.update(extra)
    aliases.update(piece_aliases)
    squares, square_inputs, square_registration = square_cells(game, root)
    loaded.update(squares)
    square_blockers, square_blocker_registration = registered_square_blockers(game, root)
    loaded.update(square_blockers)
    button_centers = {}
    for name in sorted(bonus_frames):
        image = loaded[name]
        # A lopsided icon (the hammer's heavy head) centres by its outline.
        centre = match3_buttons.outline_center if name in outline_centered else match3_buttons.alpha_center
        x, y = centre(image)
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
            ''.join(f'    {group}=' + lua_sheet(f'board/{group}.png', frames, grid_width=sheet.width if group == 'pieces' else None).lstrip()
                    + ',\n' for group, (sheet, frames) in packed.items()) + '}\n',
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
        square_sources = {'source': 'art/papyrus-board/contact.png',
                          'layout': 'art/papyrus-board/contact-layout.png',
                          'prompt': 'art/papyrus-board/contact-prompt.txt',
                          'frame_recipe': '../../tools/square_board_frame.py',
                          'frame_texture': 'art/papyrus-board/stone-cracks.png',
                          'frame_texture_prompt': 'art/papyrus-board/stone-cracks-prompt.txt',
                          'frame_texture_blend': 'multiply',
                          'selection_and_grout': '../../art/match3-square/source.png'}
    else:
        square_sources = {'source': '../../art/match3-square/source.png',
                          'prompt': '../../art/match3-square/prompt.txt',
                          'lighting_prompt': '../../art/match3-square/lighting-prompt.txt',
                          'frame_recipe': '../../tools/square_board_frame.py',
                          'frame_styles': 'art/square-frame/styles.json',
                          'frame_source': 'art/square-frame/variants.png',
                          'frame_prompt': 'art/square-frame/prompt.txt'}
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
                'square_cells': {**square_sources,
                                 'frames': square_registration,
                                 'review': 'docs/square-match3.md'},
                'square_blockers': square_blocker_registration,
                'procedural_glow': 'Original 64px white cubic radial alpha; transient light, packed alongside sprites',
                'transform': 'RGBA canvases packed without resizing, recoloring or alpha changes; 2px transparent gutters',
                'reproduction': 'python3 tools/match3_atlas.py', 'review': 'docs/review/trickling/README.md'}
    inputs = list(sources.values()) + list(effect_sources.values()) + extra_inputs + [Path(match3_buttons.__file__)] + square_inputs
    inputs += [signboard_source, SIGNBOARD_DIR / 'prompt.txt', SIGNBOARD_DIR / 'concept.jpg']
    inputs += match3_theme_art.inputs(root) + [HEX_MASK, Path(match3_theme_art.__file__), Path(pack_particles.__file__)]
    inputs += SQUARE_BLOCKER_INPUTS + [SQUARE_STONE_SOURCE, SQUARE_STONE_PROMPT, SQUARE_STONE_REFERENCE]
    inputs += [root / 'data' / path for path in (images | hud_images).values()]
    if game == 'relic-rush':
        inputs += [root / name for name in ['tools/prepare_assets.py', 'art/tile-sets/source.png',
            'art/tile-sets/source-square-jewel.png', 'art/tile-sets/square-jewel-prompt.txt',
            'art/tile-sets/square-jewel-edit-target.png']]
        outputs += [registered / 'tile-sets/relics/1.png', registered / 'tile-sets/jewels/0.png']
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
