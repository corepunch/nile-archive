"""Run with Blender -b <master.blend> --python this.py; no master is modified.

Export one transparent, registered 12 x 8 paint-over guide for all 96 objects.
"""
import bpy
import json
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/building-catalogue'
scene = bpy.data.scenes['RelicRushIso']
layout = json.loads((OUT / 'scene_layout.json').read_text())
group = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'all'
first,last,cell,cols,rows = (10,26,384,4,4) if group=='buildings' else (0,96,288,12,8)
ppu = 100
width, height = cols * cell, rows * cell
camera = scene.camera
rot = camera.rotation_euler.to_matrix()
right, up, back = [rot @ Vector(v) for v in [(1,0,0),(0,1,0),(0,0,1)]]
camera.location = back * 120
camera.data.ortho_scale = width / ppu
for coll in bpy.data.collections:
    if coll.name == 'rr_ground':
        coll.hide_render = True
report = []
for j, item in enumerate(layout['buildings']):
    coll = bpy.data.collections['rr_' + item['key']]
    if not first<=j<last:
        coll.hide_render=True
        continue
    i=j-first
    pivot = bpy.data.objects[item['key'] + '.pivot']
    points = [ob.matrix_world @ v.co for ob in coll.objects if ob.type == 'MESH' for v in ob.data.vertices]
    xs, ys = [[p.dot(axis)*ppu for p in points] for axis in [right, up]]
    scale = min((cell-36)/(max(xs)-min(xs)), (cell-36)/(max(ys)-min(ys)))
    cx, cy = (max(xs)+min(xs))/2, (max(ys)+min(ys))/2
    tx, ty = (i % cols + .5)*cell-width/2, height/2-(i//cols+.5)*cell
    # Scale around the old ground pivot; translate to the cell's centre.
    px, py = pivot.location.dot(right)*ppu, pivot.location.dot(up)*ppu
    pivot.scale *= scale
    nx, ny = tx-(cx-px)*scale, ty-(cy-py)*scale
    pivot.location += right*((nx-px)/ppu)+up*((ny-py)/ppu)
    report.append(dict(key=item['key'], size=[item['w'],item['h']],
        box=[i%cols*cell,i//cols*cell,(i%cols+1)*cell,(i//cols+1)*cell],
        pivot=[nx+width/2,height/2-ny], base_width=(item['w']+item['h'])*2**-.5*ppu*scale,
        scale=scale))
scene.render.resolution_x, scene.render.resolution_y = width, height
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
suffix='-buildings' if group=='buildings' else ''
scene.render.filepath = str(OUT/('geometry-atlas'+suffix+'.png'))
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 24
scene.cycles.use_denoising = False  # OIDN can stall on the installed macOS build.
(OUT/('registration'+suffix+'.json')).write_text(json.dumps(dict(size=[width,height],columns=cols,rows=rows,items=report),indent=2)+'\n')
bpy.ops.render.render(write_still=True, scene=scene.name)
