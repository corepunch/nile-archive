#!/usr/bin/env python3
"""Render a game's city buildings, by name, with Scener (or Blender), from the game's build_scene.py.

    python3 tools/buildings.py relic-rush                 every building
    python3 tools/buildings.py relic-rush lodge well      just these two
    python3 tools/buildings.py relic-rush --rebuild       rebuild the .blend from build_scene.py first
    python3 tools/buildings.py --list relic-rush          what the registry holds
    python3 tools/buildings.py --check                    every game's art matches the engine's camera
    python3 tools/buildings.py relic-rush --blender       render with Blender/Cycles from the .blend instead

Scener (apps/scener in github.com/corepunch/orion-ui) renders by default: tools/scener_buildings.py
runs the game's build_scene.py without Blender and writes the buildings as Scener scenes, one
orthographic camera per building. Set SCENER to the binary, or keep an orion-ui checkout beside
this one and run `make scener` there. Without a display, the renders run under xvfb-run.

A building's Blender collection name is its key and its file name: collection
`lodge` becomes data/buildings/lodge.png and data/building-shadows/lodge.png. Each
game's art/buildings.json says where its master is. Generated beside the sprites:
the registry (registration of every sprite), lua/building_sprites.lua, which games
merge into their city defs, and docs/screenshots/buildings.jpg, the review sheet.
See docs/BUILDINGS.md.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import city_camera

GAMES = ['relic-rush', 'nile-archive', 'christmas-market']
SHADOW_PPT = 28.284   # shadows stay low-resolution: the engine blurs them up
SHADOW_STRENGTH = .42


SUPERSAMPLE = 3      # Scener renders 3x3 samples per pixel
SHADOW_SOFTEN = 1.2  # px of blur on a Scener shadow: Blender's sun has a 1.5 degree disc, Scener's stencil none


def find_scener():
    """The scener binary and the environment it runs in (a build tree's libraries, a virtual display)."""
    sibling = ROOT.parent / 'orion-ui/build/bin/scener'
    for candidate in (os.environ.get('SCENER'), shutil.which('scener'), str(sibling)):
        if candidate and Path(candidate).exists():
            env = dict(os.environ)
            lib = Path(candidate).resolve().parents[1] / 'lib'
            if lib.is_dir():
                env['LD_LIBRARY_PATH'] = f'{lib}:{env["LD_LIBRARY_PATH"]}' if env.get('LD_LIBRARY_PATH') else str(lib)
                env['DYLD_LIBRARY_PATH'] = env['LD_LIBRARY_PATH']
            cmd = [candidate]
            if sys.platform.startswith('linux') and not env.get('DISPLAY') and shutil.which('xvfb-run'):
                cmd = ['xvfb-run', '-a', '-s', '-screen 0 1280x1024x24'] + cmd
            return cmd, env
    sys.exit('Scener not found: set SCENER, or build ../orion-ui with `make scener` (or pass --blender)')


def run_scener(args, log):
    cmd, env = find_scener()
    with open(log, 'w') as f:
        code = subprocess.call(cmd + args, stdout=f, stderr=subprocess.STDOUT, env=env)
    if code:
        sys.exit(f'Scener failed, see {log}:\n' + '\n'.join(Path(log).read_text().splitlines()[-12:]))


def render_scener(game, cfg, keys, out, ppt, look, shadows_only):
    """Sprites and shadow layers for tools/buildings.py's render(), drawn by Scener; returns the report."""
    import time
    import scener_buildings
    t0 = time.time()
    report = scener_buildings.write_scenes(game, out, ppt, look, keys)
    t1 = time.time()
    if not shadows_only:
        run_scener(['--render', str(out / 'sprites.blks'), '--transparent', '--format', 'png',
                    '--supersample', str(SUPERSAMPLE), '--output-dir', str(out / 'sprites')], out / 'sprites.log')
    t2 = time.time()
    run_scener(['--render', str(out / 'shadows.blks'), '--format', 'png', '--supersample', str(SUPERSAMPLE),
                '--output-dir', str(out / 'shadow-catcher')], out / 'shadows.log')
    from PIL import ImageFilter
    for key in report['items']:
        # The catcher is white where the sun reaches it: its darkening is the shadow, black at full occlusion,
        # as Blender's shadow catcher writes it.
        lum = Image.open(out / 'shadow-catcher' / f'{key}.png').convert('L')
        lit = max(1, lum.getextrema()[1])
        alpha = lum.point(lambda v: max(0, min(255, round(255 * (1 - v / lit)))))
        alpha = alpha.filter(ImageFilter.GaussianBlur(SHADOW_SOFTEN))
        layer = Image.new('RGBA', lum.size, (0, 0, 0, 0))
        layer.putalpha(alpha)
        layer.save(out / 'shadows' / f'{key}.png')
    t3 = time.time()
    print(f'{game}: scenes {t1 - t0:.1f} s, sprites {t2 - t1:.1f} s, shadows {t3 - t2:.1f} s')
    return report


def find_blender():
    for candidate in (os.environ.get('BLENDER_PATH'), shutil.which('blender'),
                      '/Applications/Blender.app/Contents/MacOS/Blender'):
        if candidate and Path(candidate).exists():
            return candidate
    sys.exit('Blender not found: set BLENDER_PATH')


def config(game):
    root = ROOT / 'games' / game
    cfg = json.loads((root / 'art/buildings.json').read_text())
    return root, cfg


def run_blender(args, log):
    with open(log, 'w') as f:
        code = subprocess.call([find_blender(), '-b', *args], stdout=f, stderr=subprocess.STDOUT)
    text = Path(log).read_text()
    # Blender exits 0 after a Python error in --python.
    if code or 'Traceback' in text or 'Error: Python' in text:
        sys.exit(f'Blender failed, see {log}:\n' + '\n'.join(text.splitlines()[-12:]))


def bleed(im, passes=2):
    """Give fully transparent edge pixels their neighbours' RGB, so filtering a
    straight-alpha sprite cannot pull in black. Retained pixels stay as rendered."""
    w, h = im.size
    px = im.load()
    for _ in range(passes):
        changes = []
        for y in range(h):
            for x in range(w):
                if px[x, y][3]:
                    continue
                total, n = [0, 0, 0], 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < w and 0 <= y + dy < h:
                        q = px[x + dx, y + dy]
                        if q[3] or q[:3] != (0, 0, 0):
                            total = [a + b for a, b in zip(total, q[:3])]
                            n += 1
                if n:
                    changes.append((x, y, tuple(a // n for a in total) + (0,)))
        for x, y, value in changes:
            px[x, y] = value
    return im


def trim(path, threshold=0, margin=2):
    """Crop transparent margins; return the image and the crop's top-left."""
    im = Image.open(path).convert('RGBA')
    box = im.getchannel('A').point(lambda a: 255 if a > threshold else 0).getbbox()
    if not box:
        return None, (0, 0)
    box = (max(0, box[0] - margin), max(0, box[1] - margin), min(im.width, box[2] + margin), min(im.height, box[3] + margin))
    return im.crop(box), box[:2]


def rounded(values):
    return [round(v, 3) for v in values]


def registry_path(root, cfg):
    return root / cfg['registry']


def write_lua(root, registry):
    lines = ['-- Generated by tools/buildings.py from the Blender master; do not edit.', 'return {']
    for key in registry['order']:
        b = registry['items'].get(key)
        if not b:
            continue
        lines.append('    %s={sprite_path="%s", size=size2(%d,%d), pivot=vec2(%g,%g), base_width=%g, '
                     'shadow_path="%s", shadow_pivot=vec2(%g,%g), shadow_base_width=%g},' % (
                         key if key.isidentifier() else f'["{key}"]', b['sprite'].removeprefix('data/'), *b['size'], *b['pivot'], b['base_width'],
                         b['shadow'].removeprefix('data/'), *b['shadow_pivot'], b['shadow_base_width']))
    lines.append('}')
    (root / 'lua/building_sprites.lua').write_text('\n'.join(lines) + '\n')


def contact_sheet(root, registry, path, ppt):
    """Every building on one tile grid, with its footprint and name, for review."""
    tile = 42
    keys = [k for k in registry['order'] if k in registry['items']]
    cols = 8 if len(keys) > 16 else max(4, min(6, len(keys)))
    scale = tile / ppt
    font_path = next((p for p in ('/System/Library/Fonts/Helvetica.ttc',
                                 '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf') if Path(p).exists()), None)
    font = ImageFont.truetype(font_path, 15) if font_path else ImageFont.load_default()
    cells = []
    for key in keys:
        b = registry['items'][key]
        sprite = Image.open(root / b['sprite']).convert('RGBA')
        size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
        cells.append((key, b, sprite.resize(size, Image.Resampling.LANCZOS)))
    cell_w = max(c[2].width for c in cells) + 24
    rows = [cells[i:i + cols] for i in range(0, len(cells), cols)]
    heights = [max(round(c[1]['pivot'][1] * scale) for c in row) + max(c[2].height - round(c[1]['pivot'][1] * scale) for c in row) + 44 for row in rows]
    sheet = Image.new('RGB', (cell_w * cols, sum(heights)), (86, 134, 66))
    d = ImageDraw.Draw(sheet, 'RGBA')
    # the tile grid, in the camera's projection
    ux, uy, vx, vy = [v * tile for v in (*city_camera.U, *city_camera.V)]
    reach = (sheet.width + sheet.height) // tile + 4
    for i in range(-reach, reach):
        d.line([(i * vx - reach * ux, i * vy - reach * uy), (i * vx + reach * ux, i * vy + reach * uy)], fill=(0, 0, 0, 26))
        d.line([(i * ux - reach * vx, i * uy - reach * vy), (i * ux + reach * vx, i * uy + reach * vy)], fill=(0, 0, 0, 26))
    y = 0
    for row, height in zip(rows, heights):
        top = max(round(c[1]['pivot'][1] * scale) for c in row)
        for i, (key, b, sprite) in enumerate(row):
            px = i * cell_w + cell_w // 2 - sprite.width // 2
            py = y + top - round(b['pivot'][1] * scale)
            shadow = Image.open(root / b['shadow']).convert('RGBA')
            k = city_camera.base_span(*b['size']) * tile / b['shadow_base_width']
            shadow = shadow.resize((max(1, round(shadow.width * k)), max(1, round(shadow.height * k))), Image.Resampling.BILINEAR)
            cx, cy = px + b['pivot'][0] * scale, py + b['pivot'][1] * scale
            sheet.paste(shadow, (round(cx - b['shadow_pivot'][0] * k), round(cy - b['shadow_pivot'][1] * k)), shadow)
            sheet.paste(sprite, (px, py), sprite)
            corners = city_camera.corners(cx, cy, b['size'][0], b['size'][1], tile)
            d = ImageDraw.Draw(sheet, 'RGBA')
            d.polygon(corners, outline=(255, 40, 200, 220))
            d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=(255, 40, 200, 255))
            label = f"{b['title']}  {b['size'][0]}×{b['size'][1]}"
            label_font = font
            if font_path:
                while d.textlength(label, font=label_font) > cell_w - 12 and label_font.size > 8:
                    label_font = ImageFont.truetype(font_path, label_font.size - 1)
            d.text((i * cell_w + cell_w / 2, y + height - 26), label, font=label_font,
                   fill='white', anchor='ma', stroke_width=2, stroke_fill=(20, 50, 20))
        y += height
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, quality=88)


def render(game, keys, rebuild, samples, workdir, shadows_only=False, blender=False):
    root, cfg = config(game)
    blend = root / cfg['blend']
    out = Path(workdir) / game
    (out / 'sprites').mkdir(parents=True, exist_ok=True)
    (out / 'shadows').mkdir(parents=True, exist_ok=True)
    ppt = cfg.get('ppt', 85)
    look = cfg.get('shadow', {})   # per game: resolution, strength, and the shadow pass's own sun direction
    shadow_ppt, strength = look.get('ppt', SHADOW_PPT), look.get('strength', SHADOW_STRENGTH)
    if not blender:
        print(f'{game}: rendering {len(keys) if keys else "all"} buildings with Scener at {ppt} px per tile')
        report = render_scener(game, cfg, keys, out, ppt, look, shadows_only)
    else:
        report = render_blender(game, cfg, keys, rebuild, samples, out, ppt, look, shadows_only)
    store(game, root, cfg, keys, out, report, ppt, strength, look, shadows_only, 'Scener' if not blender else 'Blender')


def render_blender(game, cfg, keys, rebuild, samples, out, ppt, look, shadows_only):
    root = ROOT / 'games' / game
    blend = root / cfg['blend']
    if rebuild or not blend.exists():
        print(f'{game}: building {blend.relative_to(ROOT)}')
        run_blender(['--factory-startup', '--python', str(root / cfg['generator']), '--', str(blend)], out / 'build.log')
    shadow_ppt = look.get('ppt', SHADOW_PPT)
    request = dict(out=str(out), keys=keys, ppt=ppt, shadow_ppt=shadow_ppt, samples=samples or cfg.get('samples', 64),
                   denoise=cfg.get('denoise', True), shadows_only=shadows_only,
                   shadow_sun=look.get('sun'), shadow_angle=look.get('angle', 3))
    (out / 'request.json').write_text(json.dumps(request))
    print(f'{game}: rendering {len(keys) if keys else "all"} buildings at {ppt} px per tile')
    run_blender([str(blend), '--python', str(ROOT / 'tools/render_buildings_blender.py'), '--', str(out / 'request.json')], out / 'render.log')
    return json.loads((out / 'report.json').read_text())


def store(game, root, cfg, keys, out, report, ppt, strength, look, shadows_only, renderer):
    """Trim the renders into data/, record their registration and regenerate what follows from it."""
    path = registry_path(root, cfg)
    registry = json.loads(path.read_text()) if path.exists() else {}
    if (not keys and not shadows_only) or 'camera' not in registry:   # a whole set, or a registry from before this tool
        registry['items'] = {}
    sprites, shadows = root / 'data/buildings', root / 'data/building-shadows'
    sprites.mkdir(parents=True, exist_ok=True)
    shadows.mkdir(parents=True, exist_ok=True)
    for key, item in report['items'].items():
        if not shadows_only:
            sprite, at = trim(out / 'sprites' / f'{key}.png')
            if sprite is None:
                sys.exit(f'{game}: {key} rendered empty')
            bleed(sprite).save(sprites / f'{key}.png', optimize=True)
        layer, shadow_at = trim(out / 'shadows' / f'{key}.png', threshold=24, margin=3)
        if layer is None:
            sys.exit(f'{game}: {key} rendered no shadow')
        # A direct-light catcher holds full occlusion; bright ambient island light keeps it translucent.
        layer.putalpha(layer.getchannel('A').point(lambda v: round(v * strength)))
        if look.get('tint'):   # shadow on snow reads blue, not grey
            layer.paste(tuple(look['tint']), mask=layer.getchannel('A'))
        layer.save(shadows / f'{key}.png', optimize=True)
        old = registry['items'].get(key, {})
        registry['items'][key] = dict(
            title=item['title'], size=item['size'], scale=item['scale'],
            sprite=f'data/buildings/{key}.png',
            image=old['image'] if shadows_only else list(sprite.size),
            pivot=old['pivot'] if shadows_only else rounded([item['pivot'][0] - at[0], item['pivot'][1] - at[1]]),
            base_width=round(item['base_width'], 3),
            shadow=f'data/building-shadows/{key}.png',
            shadow_pivot=rounded([item['shadow_pivot'][0] - shadow_at[0], item['shadow_pivot'][1] - shadow_at[1]]),
            shadow_base_width=round(item['shadow_base_width'], 3))
    registry.update(generator='tools/buildings.py', renderer=renderer, master=cfg['blend'], scene_generator=cfg['generator'],
                    camera=dict(yaw=city_camera.YAW, elevation=city_camera.ELEVATION),
                    ppt=ppt, order=report['order'])
    path.write_text(json.dumps(registry, indent=1) + '\n')
    known = {f'{k}.png' for k in registry['items']}
    if len(registry['items']) == len(report['order']):   # a complete set: drop what no longer exists
        for folder in (sprites, shadows):
            for old in folder.glob('*.png'):
                if old.name not in known:
                    old.unlink()
    finish(game)
    print(f'{game}: {len(report["items"])} buildings done; review {cfg.get("sheet", "docs/screenshots/buildings.jpg")}')


def finish(game):
    """Everything derived from the registry, without Blender."""
    root, cfg = config(game)
    registry = json.loads(registry_path(root, cfg).read_text())
    write_lua(root, registry)
    contact_sheet(root, registry, root / cfg.get('sheet', 'docs/screenshots/buildings.jpg'), registry['ppt'])
    hook = cfg.get('after')
    if hook:
        subprocess.check_call([sys.executable, str(root / hook)])


def check():
    problems = []
    for game in GAMES:
        root, cfg = config(game)
        path = registry_path(root, cfg)
        if not path.exists():
            problems.append(f'{game}: no registry at {cfg["registry"]}')
            continue
        registry = json.loads(path.read_text())
        camera = registry['camera']
        if (camera['yaw'], camera['elevation']) != (city_camera.YAW, city_camera.ELEVATION):
            problems.append(f'{game}: rendered at yaw {camera["yaw"]}, elevation {camera["elevation"]}; the engine says '
                            f'{city_camera.YAW}, {city_camera.ELEVATION}. Re-render: python3 tools/buildings.py {game}')
        if not (root / cfg['blend']).exists():
            problems.append(f'{game}: missing master {cfg["blend"]}')
        missing = [k for k in registry['order'] if k not in registry['items']]
        if missing:
            problems.append(f'{game}: never rendered: {missing}')
        for key, b in registry['items'].items():
            for field in ('sprite', 'shadow'):
                if not (root / b[field]).is_file():
                    problems.append(f'{game}: {key} lost {b[field]}')
            if (root / b['sprite']).is_file() and list(Image.open(root / b['sprite']).size) != b['image']:
                problems.append(f'{game}: {b["sprite"]} changed size without a render')
            if Path(b['sprite']).stem != key:
                problems.append(f'{game}: {b["sprite"]} is not named after {key}')
            if abs(b['base_width'] - city_camera.base_span(*b['size']) * registry['ppt']) > .01:
                problems.append(f'{game}: {key} base_width disagrees with the camera')
        for folder, field in (('buildings', 'sprite'), ('building-shadows', 'shadow')):
            known = {Path(b[field]).name for b in registry['items'].values()}
            stray = [p.name for p in (root / 'data' / folder).glob('*.png') if p.name not in known]
            if stray:
                problems.append(f'{game}: stray files in data/{folder}: {stray[:5]}')
        lua = (root / 'lua/building_sprites.lua')
        if not lua.exists() or any(f'buildings/{k}.png' not in lua.read_text() for k in registry['items']):
            problems.append(f'{game}: lua/building_sprites.lua is stale: python3 tools/buildings.py {game} --finish')
    if problems:
        sys.exit('\n'.join(problems))
    print(f'Buildings: {", ".join(GAMES)} match the camera (yaw {city_camera.YAW:g}, elevation {city_camera.ELEVATION:g})')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('game', nargs='?', choices=GAMES)
    ap.add_argument('keys', nargs='*', help='building keys; all of them when omitted')
    ap.add_argument('--rebuild', action='store_true', help='rebuild the .blend from its build_scene.py first')
    ap.add_argument('--samples', type=int, help='Cycles samples (the game default otherwise; Blender only)')
    ap.add_argument('--blender', action='store_true', help='render with Blender/Cycles from the .blend instead of Scener')
    ap.add_argument('--shadows', action='store_true', help='re-render only the ground shadows; sprites stay as they are')
    ap.add_argument('--finish', action='store_true', help='regenerate Lua, the sheet and hooks without rendering')
    ap.add_argument('--list', action='store_true', help='print every key in the registry')
    ap.add_argument('--check', action='store_true', help='verify every game without Blender')
    a = ap.parse_intermixed_args()
    if a.check:
        return check()
    if not a.game:
        ap.error('name a game: ' + ', '.join(GAMES))
    if a.list:
        root, cfg = config(a.game)
        registry = json.loads(registry_path(root, cfg).read_text())
        for key in registry['order']:
            b = registry['items'].get(key)
            print(f'{key:20} {b["size"][0]}x{b["size"][1]}  {b["title"]}' if b else f'{key:20} (not rendered)')
        return
    if a.finish:
        return finish(a.game)
    with tempfile.TemporaryDirectory(prefix='buildings-') as workdir:
        render(a.game, a.keys, a.rebuild, a.samples, workdir, a.shadows, a.blender)


if __name__ == '__main__':
    main()
