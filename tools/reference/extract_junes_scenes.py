#!/usr/bin/env python3
"""Extract sprites and scene metadata from the bundled June's Journey chapter 1."""
import argparse
import json
from pathlib import Path

import UnityPy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('app', type=Path, help='Path to junesjourney.app')
    parser.add_argument('output', type=Path, help='Output directory')
    args = parser.parse_args()
    root = args.app / 'Data/Raw/iOS/chapters/001'
    args.output.mkdir(parents=True, exist_ok=True)
    summary = {}
    for path in sorted(root.glob('*.hd')):
        kind = 'scene-001-01' if path.name.startswith('scene-') else (
            'thumbnails' if 'thumbnails' in path.name else 'clues')
        directory = args.output / kind
        directory.mkdir(exist_ok=True)
        env = UnityPy.load(str(path))
        sprites, text_assets, failures, scene_objects = [], [], [], []
        for obj in env.objects:
            try:
                if obj.type.name == 'Sprite':
                    data = obj.read()
                    image = data.image
                    image.save(directory / (data.m_Name + '.png'))
                    sprites.append({'name': data.m_Name, 'width': image.width,
                                    'height': image.height, 'path_id': obj.path_id,
                                    'asset_file': obj.assets_file.name})
                elif obj.type.name == 'TextAsset':
                    data = obj.read()
                    payload = data.m_Script
                    if isinstance(payload, str):
                        payload = payload.encode('utf-8', 'surrogateescape')
                    (directory / (data.m_Name + '.txt')).write_bytes(payload)
                    text_assets.append(data.m_Name)
                elif kind == 'scene-001-01' and obj.type.name in (
                        'GameObject', 'Transform', 'SpriteRenderer',
                        'MonoBehaviour', 'PolygonCollider2D'):
                    scene_objects.append({'type': obj.type.name, 'path_id': obj.path_id,
                                          'asset_file': obj.assets_file.name,
                                          'data': obj.read_typetree()})
            except Exception as exc:
                failures.append({'type': obj.type.name, 'id': obj.path_id, 'error': str(exc)})
        if scene_objects:
            (directory / 'objects.json').write_text(json.dumps(scene_objects, indent=2) + '\n')
        summary[kind] = {'source': str(path), 'sprites': sprites,
                         'text_assets': text_assets, 'failed': failures}
        print(f'{kind}: {len(sprites)} sprites, {len(scene_objects)} scene objects, '
              f'{len(failures)} failures')
    (args.output / 'index.json').write_text(json.dumps(summary, indent=2) + '\n')
    if any(item['failed'] for item in summary.values()):
        raise SystemExit('Some objects failed to extract; see index.json')


if __name__ == '__main__':
    main()
