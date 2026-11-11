#!/usr/bin/env python3
"""Extract original Tropicats artwork locally. Requires UnityPy 1.25.4."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
# Static illustrations are deliberate: animated meshes are not single sprites.
NAMES = set('''board_recipe ui_icon_climber hiddenItem water_field
window window_bridge growing_window growing_window_bridge_01 growing_window_bridge_02 portal_entrance portal_exit drop_item_exit climber_exit
ice_background cannon_tutorial chameleon_1_tutorial diagonal_gems_random
ui_icon_objective_colorwheel'''.split())
PATTERN = re.compile(r"(?:dot_[A-Za-z_]+|ui_icon_objective_[a-z_]+|stone_[1-5]hp|chain_[1-3]hp|crate_(?:tintable_)?[1-3]hp|tile_[12]hp|iceHp[1-3]|DirtHp[1-3]|resistantBlocker_tutorial_[1-3]hp|diagonal_gems_Diagonal[A-Za-z]+)")


def extract(app, output):
    import UnityPy
    bundles = sorted((app / 'Data/Raw/AssetBundles').glob('allscenes_*'))
    if len(bundles) != 1:
        raise ValueError(f'Expected one allscenes bundle, found {len(bundles)}')
    bundle = bundles[0]
    environment = UnityPy.load(str(bundle))
    candidates = {}
    for obj in environment.objects:
        if obj.type.name not in ('Sprite', 'Texture2D'):
            continue
        data = obj.read()
        name = data.m_Name
        if not (name in NAMES or PATTERN.fullmatch(name)):
            continue
        if obj.type.name == 'Texture2D' and name != 'board_recipe':
            continue
        # Prefer the level prefab's own sprite to duplicate scene references.
        rank = (obj.assets_file.name != 'BuildPlayer-M3_Level.sharedAssets', obj.assets_file.name, obj.path_id)
        if name not in candidates or rank < candidates[name][0]:
            candidates[name] = (rank, obj, data)
    required = {'dot_red', 'dot_random', 'board_recipe', 'stone_1hp', 'iceHp3'}
    if required - candidates.keys():
        raise ValueError(f'Missing expected artwork: {required - candidates.keys()}')
    scene = next(o.assets_file for o in environment.objects if o.assets_file.name == "BuildPlayer-M3_Level.sharedAssets")
    sprites = output / 'sprites'
    sprites.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name, (_, obj, data) in sorted(candidates.items()):
        bitmap = data.image  # UnityPy decodes texture compression, atlas crop, rotation and alpha.
        target = sprites / f'{name}.png'
        bitmap.save(target)
        manifest[name] = {'url': f'/art/{name}.png', 'file': obj.assets_file.name,
                          'path_id': obj.path_id, 'kind': obj.type.name,
                          'width': bitmap.width, 'height': bitmap.height,
                          'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
    # Cached theme bundle is optional: it is downloaded separately from the app.
    # Read the explicit LevelTheme references, never guess a texture by appearance.
    theme_path = output.parent / 'bundles/m3_themes'
    theme_source = None
    if theme_path.is_file():
        theme_env = UnityPy.load(str(theme_path))
        objects = {o.path_id: o for o in theme_env.objects}
        references = {}
        for obj in theme_env.objects:
            if obj.type.name != 'MonoBehaviour':
                continue
            tree = obj.read_typetree()
            board_id = tree.get('board', {}).get('m_PathID', 0)
            if not board_id:
                continue
            texture = objects[board_id].read()
            name = texture.m_Name
            target = sprites / f'{name}.png'
            bitmap = texture.image
            bitmap.save(target)
            manifest[name] = {'url': f'/art/{name}.png', 'file': theme_path.name,
                              'path_id': board_id, 'kind': 'Texture2D',
                              'width': bitmap.width, 'height': bitmap.height,
                              'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
            references[tree['m_Name']] = {'texture': name, 'theme_id': obj.path_id}
        theme_source = {'bundle': 'bundles/m3_themes',
                        'sha256': hashlib.sha256(theme_path.read_bytes()).hexdigest(),
                        'references': references}
    # Evaluate native materials with their authored inputs, rather than inventing variants.
    from materials import render_overlay, render_crate
    import lz4.block
    evidence = output / 'shader-evidence'
    evidence.mkdir(exist_ok=True)
    material_sources = {}
    for name, material_id, mesh_id, texture_id in [('bomb', 5, 314, 124),
            ('line_horizontal', 59, 317, 289), ('line_vertical', 59, 321, 289)]:
        material = scene.objects[material_id].read()
        shader = material.m_Shader.read()
        # Keep recovered source local and fingerprint it in the review catalogue.
        decoded = lz4.block.decompress(bytes(shader.compressedBlob), uncompressed_size=shader.decompressedLengths[0][0])
        (evidence / f'{name}.decoded').write_bytes(decoded)
        image = render_overlay(scene.objects[mesh_id].read(), scene.objects[texture_id].read(), material, bomb=name == 'bomb')
        key = f'material_{name}'
        target = sprites / f'{key}.png'
        image.save(target)
        manifest[key] = {'url': f'/art/{key}.png', 'kind': 'MaterialRender', 'width': image.width, 'height': image.height,
            'file': scene.name, 'material_id': material_id, 'mesh_id': mesh_id, 'texture_id': texture_id,
            'shader_sha256': hashlib.sha256(decoded).hexdigest(), 'time': 0,
            'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
        material_sources[name] = {'shader': shader.m_ParsedForm.m_Name, 'sha256': hashlib.sha256(decoded).hexdigest()}
    crate_material = scene.objects[95].read()
    shader = crate_material.m_Shader.read()
    decoded = lz4.block.decompress(bytes(shader.compressedBlob), uncompressed_size=shader.decompressedLengths[0][0])
    (evidence / 'crate.decoded').write_bytes(decoded)
    material_sources['crate'] = {'shader': shader.m_ParsedForm.m_Name, 'sha256': hashlib.sha256(decoded).hexdigest(),
        'columns': 10, 'column_center_offset': .05, 'crate_hp_stride': 4}
    lut = scene.objects[304].read().image
    for color in [1,2,3,4,5,6,9]:
        for hp in [1,2,3]:
            source_name = f'crate_tintable_{hp}hp'
            image = render_crate(candidates[source_name][2].image, lut, color)
            key = f'material_crate_{color}_{hp}'
            target = sprites / f'{key}.png'
            image.save(target)
            manifest[key] = {'url': f'/art/{key}.png', 'kind': 'MaterialRender', 'width': image.width, 'height': image.height,
                'file': scene.name, 'material_id': 95, 'lut_id': 304, 'sprite_id': candidates[source_name][1].path_id,
                'shader_sha256': material_sources['crate']['sha256'], 'color': color, 'hp': hp,
                'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
    for name, sprite_id, transform_id in [('portal_entrance',597,1273), ('portal_exit',669,1216)]:
        sprite = scene.objects[sprite_id].read()
        position = scene.objects[transform_id].read().m_LocalPosition
        rect, offset, pivot, ppu = sprite.m_Rect, sprite.m_RD.textureRectOffset, sprite.m_Pivot, sprite.m_PixelsToUnits
        width, height = manifest[name]['width']/ppu, manifest[name]['height']/ppu
        manifest[name]['placement'] = {'left': .5 + position.x + (offset.x-pivot.x*rect.width)/ppu,
            'top': .5-position.y-(offset.y+manifest[name]['height']-pivot.y*rect.height)/ppu,
            'width': width, 'height': height, 'transform_id': transform_id}
    from mechanics import extract_mechanics
    extract_mechanics(scene, output, manifest, material_sources)
    (output / 'sprites.json').write_text(json.dumps(manifest, indent=2) + '\n')
    provenance = {'bundle': str(bundle.relative_to(app)),
                  'sha256': hashlib.sha256(bundle.read_bytes()).hexdigest(),
                  'decoder': f'UnityPy {UnityPy.__version__}', 'sprites': len(manifest),
                  'decoded_images': len(candidates) + sum(item['kind'] == 'Texture2D' and item['file'] == 'm3_themes' for item in manifest.values()),
                  'material_renders': sum(item['kind'] == 'MaterialRender' for item in manifest.values()),
                  'transform': 'Original decoded sprites plus time-zero evaluation of bundled meshes, packed overlay shaders, stencil gauge, skeletal characters and color LUTs; no painted replacements.',
                  'materials': material_sources, 'theme_source': theme_source}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    print(f"Prepared {provenance['decoded_images']} original images and {provenance['material_renders']} material renders in {output}")
    return {'source': provenance, 'sprites': manifest}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, default=ROOT / 'reference/Tropicats.app')
    parser.add_argument('--output', type=Path, default=ROOT / 'reference/tropicats-analysis/art')
    parser.add_argument('--catalogue', type=Path, help='Also write source metadata (no image pixels) for review')
    args = parser.parse_args()
    catalogue = extract(args.app, args.output)
    if args.catalogue:
        args.catalogue.write_text(json.dumps(catalogue, indent=2) + '\n')
