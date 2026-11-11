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
window growing_window portal_entrance portal_exit drop_item_exit climber_exit
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
    (output / 'sprites.json').write_text(json.dumps(manifest, indent=2) + '\n')
    provenance = {'bundle': str(bundle.relative_to(app)),
                  'sha256': hashlib.sha256(bundle.read_bytes()).hexdigest(),
                  'decoder': f'UnityPy {UnityPy.__version__}', 'sprites': len(manifest),
                  'transform': 'Original Sprite.image / Texture2D.image; no repainting, tinting or synthesized states.'}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    print(f'Extracted {len(manifest)} original images to {output}')
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
