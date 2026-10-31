"""Render every catalogue object of the Blender master to its own runtime sprite.

    blender -b games/christmas-market/art/building-catalogue/christmas_market_buildings.blend \\
        --python games/christmas-market/tools/render_buildings.py [-- key ...]

The master is not modified. The camera is the master's orthographic 30-degree
camera (exact 2:1 ground projection, as in Relic Rush), moved over each object
in turn at one fixed scale: a tile is TILE_PX pixels wide in every sprite. Each sprite's pivot (the footprint's ground centre) and base width are
projected analytically and written to registration.json; prepare_catalogue.py
crops the sprites and generates the game's Lua table from it.
"""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/building-catalogue'
OUT = ROOT / 'data/buildings'
TILE_PX = 128                      # tile width in sprite pixels
PPU = TILE_PX / math.sqrt(2)       # pixels per Blender unit (a tile side)
MARGIN = 4                         # transparent pixels around the projected geometry

scene = bpy.data.scenes['ChristmasMarketIso']
layout = json.loads((ART / 'scene_layout.json').read_text())
only = set(sys.argv[sys.argv.index('--') + 1:]) if '--' in sys.argv else set()

camera = scene.camera
rot = camera.rotation_euler.to_matrix()
right, up, back = [rot @ Vector(v) for v in [(1, 0, 0), (0, 1, 0), (0, 0, 1)]]
for coll in bpy.data.collections:
    if coll.name in ('cm_ground',):
        coll.hide_render = True

scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 64
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = .02
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
camera.data.sensor_fit = 'AUTO'

OUT.mkdir(parents=True, exist_ok=True)
reg_path = ART / 'registration.json'
registration = json.loads(reg_path.read_text()) if reg_path.exists() and only else {'tile_px': TILE_PX, 'items': {}}
items = layout['buildings']
for item in items:
    bpy.data.collections['cm_' + item['key']].hide_render = True
for item in items:
    key = item['key']
    if only and key not in only:
        continue
    coll = bpy.data.collections['cm_' + key]
    coll.hide_render = False
    pivot = bpy.data.objects[key + '.pivot'].matrix_world.translation.copy()
    w, h = item['w'], item['h']
    points = [ob.matrix_world @ v.co for ob in coll.objects if ob.type == 'MESH' for v in ob.data.vertices]
    points += [pivot + Vector((sx * w / 2, sy * h / 2, 0)) for sx in (-1, 1) for sy in (-1, 1)]
    xs = [(p - pivot).dot(right) * PPU for p in points]
    ys = [(p - pivot).dot(up) * PPU for p in points]
    x0, x1 = math.floor(min(xs)) - MARGIN, math.ceil(max(xs)) + MARGIN
    y0, y1 = math.floor(min(ys)) - MARGIN, math.ceil(max(ys)) + MARGIN
    width, height = x1 - x0, y1 - y0
    scene.render.resolution_x, scene.render.resolution_y = width, height
    camera.data.ortho_scale = max(width, height) / PPU
    camera.location = pivot + right * ((x0 + x1) / 2 / PPU) + up * ((y0 + y1) / 2 / PPU) + back * 120
    scene.render.filepath = str(OUT / (key + '.png'))
    bpy.ops.render.render(write_still=True, scene=scene.name)
    coll.hide_render = True
    registration['items'][key] = dict(size=[w, h], image=[width, height], pivot=[-x0, y1],
                                      base_width=(w + h) * TILE_PX / 2)
    print('rendered', key, width, height, flush=True)

registration['items'] = {it['key']: registration['items'][it['key']] for it in items if it['key'] in registration['items']}
reg_path.write_text(json.dumps(registration, indent=1) + '\n')
