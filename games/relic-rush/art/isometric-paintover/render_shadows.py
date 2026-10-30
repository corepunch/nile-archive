"""Render separate, registered Cycles ground shadows from the source master.

Run with the existing Blender installation, no model edits or dependencies:
  Blender --background --python games/relic-rush/art/isometric-paintover/render_shadows.py

Each building casts onto a transparent shadow catcher in isolation, so a crop
never contains its neighbour's shadow. All outputs share the source camera.
"""
import json
import math
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / 'isometric-blender'
OUT = HERE / 'shadows'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'relic_rush_buildings.blend'))
scene = bpy.data.scenes['RelicRushIso']
layout = json.loads((SOURCE / 'scene_layout.json').read_text())
ground = bpy.data.objects['ground']
ground.is_shadow_catcher = True
mat = bpy.data.materials.new('shadow_catcher_white')
mat.use_nodes = True
p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
p.inputs['Base Color'].default_value = (1, 1, 1, 1)
p.inputs['Roughness'].default_value = 1
ground.data.materials.clear()
ground.data.materials.append(mat)
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.image_settings.color_depth = '8'
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 2
scene.render.use_border = True
scene.render.use_crop_to_border = False
prefs = bpy.context.preferences.addons['cycles'].preferences
try:
    prefs.compute_device_type = 'METAL'
    prefs.get_devices()
    for device in prefs.devices:
        device.use = device.type == 'METAL'
    scene.cycles.device = 'GPU' if any(d.type == 'METAL' for d in prefs.devices) else 'CPU'
except Exception:
    scene.cycles.device = 'CPU'

for ob in scene.objects:
    if ob.type == 'MESH' and ob != ground:
        ob.visible_camera = False
    if ob.type == 'LIGHT' and ob.data.type == 'POINT':
        ob.hide_render = True

for i, b in enumerate(layout['buildings']):
    key = b['key']
    for ob in scene.objects:
        if ob.type == 'MESH' and ob != ground:
            ob.hide_render = not ob.name.startswith(key + '.')
    u, v, w, h = b['u0'], b['v0'], b['w'], b['h']
    pts = [(layout['origin_px'][0] + (a - c) * 60,
            layout['origin_px'][1] + (a + c) * 30)
           for a, c in ((u, v), (u + w, v), (u + w, v + h), (u, v + h))]
    x0, x1 = min(p[0] for p in pts) - 50, max(p[0] for p in pts) + 280
    y0, y1 = min(p[1] for p in pts) - 160, max(p[1] for p in pts) + 100
    rw, rh = layout['resolution']
    scene.render.border_min_x = max(0, x0 / rw)
    scene.render.border_max_x = min(1, x1 / rw)
    scene.render.border_min_y = max(0, 1 - y1 / rh)
    scene.render.border_max_y = min(1, 1 - y0 / rh)
    scene.render.filepath = str(OUT / f'{i}.png')
    bpy.ops.render.render(write_still=True, scene=scene.name)
    print('SHADOW', i, key, scene.render.filepath, flush=True)
print('All shadows use the original orthographic camera; source master unchanged.', flush=True)
