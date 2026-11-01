#!/usr/bin/env python3
"""Import reviewed category paint-overs; crop/scale/translate only, retaining alpha.

python3 tools/import_painted_buildings.py relic-rush [wonder building ...]
Inputs, outputs, prompts and original Blender registration live in painted-v1/.
The Blender master remains the geometry source. No colour or mask processing.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import buildings
from city_camera import U, V


def support_box(im):
    # Locate a crop around substantial authored components, excluding distant
    # generation flecks. This never changes any pixel or alpha inside the crop.
    labels, count = ndimage.label(np.asarray(im.getchannel('A')) > 160)
    if not count:
        raise ValueError('Empty painted cell')
    areas = np.bincount(labels.ravel())
    minimum = max(32, areas[1:].max() * .005)
    regions = [region for i, region in enumerate(ndimage.find_objects(labels), 1)
               if region is not None and areas[i] >= minimum]
    box = (min(s[1].start for s in regions), min(s[0].start for s in regions),
           max(s[1].stop for s in regions), max(s[0].stop for s in regions))
    return (max(0, box[0] - 3), max(0, box[1] - 3),
            min(im.width, box[2] + 3), min(im.height, box[3] + 3))


def ground(im, footprint):
    """Same lower-V fit as footprint.py, using a histogram instead of y loops."""
    a = np.asarray(im.getchannel('A')) > 160
    h, w = a.shape
    valid = a.any(axis=0)
    x = np.arange(w)[valid]
    low = (h - 1 - a[::-1].argmax(axis=0))[valid]
    best = None
    fraction = footprint[0] * U[0] / (footprint[0] * U[0] - footprint[1] * V[0])
    for xb in range(round(w * (fraction - .05)), min(w, round(w * (fraction + .05)))):
        drop = np.where(x < xb, (xb - x) * U[1] / U[0], (x - xb) * V[1] / -V[0])
        votes = np.rint(low + drop).astype(int)
        hist = np.bincount(votes, minlength=h + w * 2)
        scores = np.convolve(hist, np.ones(7, dtype=int), mode='same')
        scores[:int(h * .6)] = 0
        scores[h:] = 0
        yb = int(scores.argmax())
        if best is None or scores[yb] > best[0]:
            on = x[np.abs(low + drop - yb) <= 4]
            best = (scores[yb], xb, yb, int(on.min()), int(on.max()))
    _, xb, yb, xl, xr = best
    # Painted bevels and foliage can interrupt an otherwise matching slab edge.
    # Never let a partial edge fit turn a whole foundation into half a tile.
    xl, xr = min(xl, round(w * .035)), max(xr, round(w * .965))
    yl = yb - (xb - xl) * U[1] / U[0]
    yr = yb - (xr - xb) * V[1] / -V[0]
    return np.array([(xl + xr) / 2, (yl + yr) / 2]), xr - xl


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('game', choices=buildings.GAMES)
    ap.add_argument('categories', nargs='*')
    args = ap.parse_args()
    root, cfg = buildings.config(args.game)
    source = root / 'art/building-catalogue/painted-v1'
    original = json.loads((source / 'render-registration.json').read_text())
    registry_path = buildings.registry_path(root, cfg)
    registry = json.loads(registry_path.read_text())
    imports = {}
    for layout_path in sorted(source.glob('*-layout.json')):
        category = layout_path.name.removesuffix('-layout.json')
        if args.categories and category not in args.categories:
            continue
        output = source / f'{category}-output.png'
        if not output.exists():
            continue
        layout = json.loads(layout_path.read_text())
        atlas = Image.open(output).convert('RGBA')
        guide = Image.open(source / f'{category}-input.png').convert('RGBA')
        cols, rows = layout['cols'], layout['rows']
        for i, entry in enumerate(layout['entries']):
            key = entry['key']
            old = original['items'][key]
            cell = (round(i % cols * atlas.width / cols), round(i // cols * atlas.height / rows),
                    round((i % cols + 1) * atlas.width / cols), round((i // cols + 1) * atlas.height / rows))
            painted = atlas.crop(cell)
            crop = support_box(painted)
            painted = painted.crop(crop)
            base = guide.crop(entry['box'])
            display_scale = entry.get('display_scale', 1)
            pivot = np.array(old['pivot']) * display_scale
            if category in ('wonder', 'restoration', 'cottage') or (category == 'building' and args.game != 'christmas-market'):
                source_pivot, source_span = ground(base, old['size'])
                painted_pivot, painted_span = ground(painted, old['size'])
                scale = source_span / painted_span / display_scale
                new_pivot = painted_pivot * scale + (pivot - source_pivot) / display_scale
            else:
                scale = max(base.size) / max(painted.size) / display_scale
                new_pivot = np.array([painted.width / 2, painted.height]) * scale
                new_pivot += (pivot - np.array([base.width / 2, base.height])) / display_scale
            size = [max(1, round(v * scale)) for v in painted.size]
            painted.resize(size, Image.Resampling.LANCZOS).save(root / old['sprite'])
            item = registry['items'][key]
            item['image'] = size
            item['pivot'] = buildings.rounded(new_pivot.tolist())
            imports[key] = dict(atlas=str(output.relative_to(root)), cell=cell, crop=crop,
                                scale=round(scale, 8), pivot=item['pivot'], image=size)
    if not imports:
        raise SystemExit('No painted outputs to import')
    registry['paintover'] = dict(version='painted-v1', importer='tools/import_painted_buildings.py',
                                sources='art/building-catalogue/painted-v1')
    registry_path.write_text(json.dumps(registry, indent=1) + '\n')
    report = source / 'imports.json'
    previous = json.loads(report.read_text()) if report.exists() else {}
    previous.update(imports)
    report.write_text(json.dumps(previous, indent=2) + '\n')
    buildings.finish(args.game)
    print(f'{args.game}: imported {len(imports)} painted sprites')


if __name__ == '__main__':
    main()
