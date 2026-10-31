"""Runs inside Blender for tools/buildings.py: one transparent sprite and one ground
shadow per building, named after its collection. The master is never saved.

    Blender -b master.blend --python this.py -- <request.json>
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import city_camera

request = json.loads(Path(sys.argv[sys.argv.index('--') + 1]).read_text())
out, ppt, shadow_ppt = Path(request['out']), request['ppt'], request['shadow_ppt']
scene = next(s for s in bpy.data.scenes if 'buildings' in s.collection.children)
bpy.context.window.scene = scene
camera = scene.camera
root = bpy.data.collections['buildings']
buildings = {coll.name: coll for coll in root.children}
keys = request['keys'] or list(buildings)
missing = [k for k in keys if k not in buildings]
if missing:
    raise SystemExit(f'No such buildings in the scene: {missing}')

camera.rotation_euler = city_camera.ROTATION
bpy.context.view_layer.update()
rot = camera.rotation_euler.to_matrix()
right, up, back = [rot @ Vector(v) for v in [(1, 0, 0), (0, 1, 0), (0, 0, 1)]]


def show_only(key):
    for name, coll in buildings.items():
        coll.hide_render = name != key
    bpy.context.view_layer.update()


def mesh_points(coll):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    points = []
    for ob in coll.objects:
        if ob.type == 'MESH':
            evaluated = ob.evaluated_get(depsgraph)
            points += [evaluated.matrix_world @ v.co for v in evaluated.data.vertices]
    return points


def frame(points, pivot, scale, name, margin=6):
    """Fit the camera to points; return the pivot's pixel."""
    xs, ys = [p.dot(right) for p in points], [p.dot(up) for p in points]
    pad = margin / scale
    x0, x1, y0, y1 = min(xs) - pad, max(xs) + pad, min(ys) - pad, max(ys) + pad
    # Whole pixels, so the sprite's grid and the camera's agree exactly.
    width, height = math.ceil((x1 - x0) * scale), math.ceil((y1 - y0) * scale)
    x1, y0 = x0 + width / scale, y1 - height / scale
    camera.location = right * ((x0 + x1) / 2) + up * ((y0 + y1) / 2) + back * 150
    camera.data.ortho_scale = max(width, height) / scale
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(name)
    return [(pivot.dot(right) - x0) * scale, (y1 - pivot.dot(up)) * scale]


scene.render.engine = 'CYCLES'
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.image_settings.color_depth = '8'
scene.render.image_settings.compression = 100
scene.cycles.device = 'CPU'
scene.cycles.samples = request['samples']
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = .02
scene.cycles.use_denoising = request['denoise']
scene.cycles.filter_width = 1.0
scene.cycles.max_bounces = 5
scene.cycles.caustics_reflective = scene.cycles.caustics_refractive = False

report = {}
for key in keys:
    coll = buildings[key]
    pivot_ob = bpy.data.objects[key + '.pivot']
    show_only(key)
    pixel = frame(mesh_points(coll), pivot_ob.matrix_world.translation, ppt, out / 'sprites' / f'{key}.png')
    bpy.ops.render.render(write_still=True, scene=scene.name)
    w, h = pivot_ob['w'], pivot_ob['h']
    report[key] = dict(title=pivot_ob['title'], size=[w, h], scale=pivot_ob.scale.x, pivot=pixel,
                       base_width=city_camera.base_span(w, h) * ppt)

# Ground shadows: direct sun and fill only, on a catcher, from invisible clay casters.
# Painted emissive windows must not become hundreds of mesh lights here.
clay = bpy.data.materials.new('shadow_caster_clay')
clay.diffuse_color = (.4, .4, .4, 1)
for coll in buildings.values():
    for ob in coll.objects:
        if ob.type == 'MESH':
            ob.visible_camera = False
            ob.data.materials.clear()
            ob.data.materials.append(clay)
        elif ob.type == 'LIGHT':
            ob.hide_render = True
mesh = bpy.data.meshes.new('shadow_catcher')
mesh.from_pydata([(-1000, -1000, -.006), (1000, -1000, -.006), (1000, 1000, -.006), (-1000, 1000, -.006)], [], [(0, 1, 2, 3)])
catcher = bpy.data.objects.new('shadow_catcher', mesh)
scene.collection.objects.link(catcher)
catcher.is_shadow_catcher = True
scene.cycles.samples = 32
scene.cycles.use_adaptive_sampling = False
scene.cycles.use_denoising = False
scene.cycles.max_bounces = 0
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0
suns = [ob.matrix_world.to_3x3() @ Vector((0, 0, -1)) for ob in scene.objects if ob.type == 'LIGHT' and ob.data.type == 'SUN']

for key in keys:
    coll = buildings[key]
    pivot_ob = bpy.data.objects[key + '.pivot']
    show_only(key)
    points = mesh_points(coll)
    origin = pivot_ob.matrix_world.translation
    # Include where every point's shadow lands, so no layer is clipped by its frame.
    reach = list(points)
    top = max(p.z for p in points)
    for sun in suns:
        slope = Vector((sun.x, sun.y, 0)) / max(-sun.z, .05)
        reach += [p + slope * p.z - Vector((0, 0, p.z)) for p in points if p.z > top * .3]
    pixel = frame(reach + [origin], origin, shadow_ppt, out / 'shadows' / f'{key}.png', margin=8)
    bpy.ops.render.render(write_still=True, scene=scene.name)
    report[key]['shadow_pivot'] = pixel
    report[key]['shadow_base_width'] = city_camera.base_span(pivot_ob['w'], pivot_ob['h']) * shadow_ppt

(out / 'report.json').write_text(json.dumps(dict(order=[c for c in buildings], items=report), indent=1))
