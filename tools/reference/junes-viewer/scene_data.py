#!/usr/bin/env python3
"""Map the extracted Unity scene into normalized image and polygon coordinates."""
import argparse
import json
from pathlib import Path


OBJECT_LABELS = {
    'blueflowers': 'Blue flowers', 'capricornstature': 'Capricorn stature',
    'clue_mrstalbot': 'Mrs. Talbot clue', 'clue_placeholder': 'Placeholder clue',
    'firealarm': 'Fire alarm', 'glassdome': 'Glass dome', 'golfbag': 'Golf bag',
    'greekornament': 'Greek ornament', 'hangingflower': 'Hanging flower',
    'hatbox': 'Hat box', 'jerrycan': 'Jerry can', 'letterp': 'Letter P',
    'luggagetag': 'Luggage tag', 'paperboat': 'Paper boat', 'pinecone': 'Pine cone',
    'postbox': 'Postbox', 'romantwo': 'Roman numeral II',
    'stackofbooks': 'Stack of books', 'stainedglasswindow': 'Stained glass window',
    'streetlight': 'Streetlight', 'stringlights': 'String lights',
    'uniformcaps': 'Uniform caps', 'wateringcan': 'Watering can',
    'watertower': 'Water tower', 'welcomematt': 'Welcome mat',
}

CLUE_LABELS = {
    '01_clue_mrstalbot': ('Mrs. Talbot', 1, None),
    '01_clue_placeholder': ('Placeholder', 1, None),
    '02_clue_familypicture': ('Family picture', 2, 1),
    '02_clue_crimephoto': ('Crime photo', 2, 2),
    '03_clue_glasses': ('Whiskey glasses', 3, 1),
    '03_clue_footprint': ('Footprint', 3, 2),
    '04_clue_brokenlock': ('Broken lock', 4, 1),
    '04_clue_carafe': ('Carafe', 4, 2),
    '05_clue_bloodyhandkerchief': ('Bloody handkerchief', 5, 1),
    '05_clue_windows': ('Window', 5, 2),
}


def build_scene(data_root):
    scenes = Path(data_root) / 'scenes'
    scene_dir = scenes / 'scene-001-01'
    with (scene_dir / 'objects.json').open() as file:
        raw = json.load(file)
    with (scenes / 'index.json').open() as file:
        index = json.load(file)

    by_id = {entry['path_id']: entry for entry in raw}
    game_objects = {entry['path_id']: entry['data'] for entry in raw
                    if entry['type'] == 'GameObject'}
    transforms = {entry['data']['m_GameObject']['m_PathID']: entry['data']
                  for entry in raw if entry['type'] == 'Transform'}
    sprites = {entry['path_id']: entry for entry in index['scene-001-01']['sprites']}

    def components(game_object):
        return [by_id[item['component']['m_PathID']]
                for item in game_objects[game_object]['m_Component']]

    def world_position(transform):
        x = y = 0
        while transform:
            position = transform['m_LocalPosition']
            rotation = transform['m_LocalRotation']
            scale = transform['m_LocalScale']
            if any(rotation[key] != value for key, value in
                   [('x', 0), ('y', 0), ('z', 0), ('w', 1)]) or any(
                       scale[key] != 1 for key in ('x', 'y', 'z')):
                raise ValueError('Scene uses unsupported rotation or scale')
            x += position['x']
            y += position['y']
            parent = transform['m_Father']['m_PathID']
            transform = by_id[parent]['data'] if parent else None
        return x, y

    background_id = next(key for key, value in game_objects.items()
                         if value['m_Name'] == 'background')
    background_renderer = next(item['data'] for item in components(background_id)
                               if item['type'] == 'SpriteRenderer')
    bg_x, bg_y = world_position(transforms[background_id])
    bg_w = background_renderer['m_Size']['x']
    bg_h = background_renderer['m_Size']['y']
    left, top = bg_x - bg_w / 2, bg_y + bg_h / 2

    def point(x, y):
        return [(x - left) / bg_w, (top - y) / bg_h]

    objects = []
    for entry in raw:
        data = entry['data']
        if entry['type'] != 'MonoBehaviour' or 'Collider' not in data or 'Root' not in data:
            continue
        root_id = data['Root']['m_PathID']
        name = game_objects[root_id]['m_Name']
        collider = by_id[data['Collider']['m_PathID']]['data']
        collider_game_object = collider['m_GameObject']['m_PathID']
        collider_x, collider_y = world_position(transforms[collider_game_object])
        offset = collider['m_Offset']
        polygons = [[point(collider_x + offset['x'] + p['x'],
                           collider_y + offset['y'] + p['y']) for p in path]
                    for path in collider['m_Points']['m_Paths']]
        layers = []
        for kind in ('Cast', 'Item', 'Cover'):
            game_id = data[kind]['m_PathID']
            renderer = next((item['data'] for item in components(game_id)
                             if item['type'] == 'SpriteRenderer'), None)
            if not renderer or not renderer['m_Enabled']:
                continue
            sprite_id = renderer['m_Sprite']['m_PathID']
            if not sprite_id:
                continue
            sprite = sprites[sprite_id]
            x, y = world_position(transforms[game_id])
            width = renderer['m_Size']['x']
            height = renderer['m_Size']['y']
            left_x, top_y = point(x - width / 2, y + height / 2)
            layers.append({'kind': kind.lower(), 'image': sprite['name'] + '.png',
                           'x': left_x, 'y': top_y, 'width': width / bg_w,
                           'height': height / bg_h, 'order': renderer['m_SortingOrder']})
        objects.append({'id': name, 'name': name, 'label': OBJECT_LABELS.get(name, name.replace('_', ' ').title()),
                        'difficulty': data.get('Difficulty'),
                        'polygon': polygons[0] if polygons else [], 'polygons': polygons,
                        'layers': layers, 'sortingOrder': data.get('DefaultSortingOrder'),
                        'excludeInSilhouetteMode': bool(data.get('ExcludeInSilhouetteMode', 0)),
                        'isClue': name.startswith('clue_')})

    clues = []
    for sprite in index['clues']['sprites']:
        name = sprite['name']
        label, scene, clue = CLUE_LABELS[name]
        clues.append({'name': name, 'label': label, 'image': name + '.png',
                      'scene': scene, 'clue': clue})
    clues.sort(key=lambda item: (item['scene'], item['clue'] or 0, item['name']))
    objects.sort(key=lambda item: item['name'])
    background = sprites[background_renderer['m_Sprite']['m_PathID']]
    with (Path(data_root) / 'story' / 'funnel-dialogue-en-US.json').open() as file:
        opening_dialogue = json.load(file)
    caption_file = next((Path(data_root) / 'story' / 'locale' / 'en-US').glob(
        'jj-funnel-captions-*.json'))
    with caption_file.open() as file:
        captions = json.load(file)
    opening_captions = [captions['tutorial.funnel_captions_' + key]
                        for key in ('ship1', 'picture1', 'picture2', 'ship2', 'locket')]
    return {'width': background['width'], 'height': background['height'],
            'background': background['name'] + '.png',
            'objects': objects, 'clues': clues, 'openingDialogue': opening_dialogue,
            'openingCaptions': opening_captions}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('data', type=Path, help='Path to junes-journey-analysis')
    parser.add_argument('output', type=Path, help='Output JSON path')
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(build_scene(args.data), indent=2) + '\n')


if __name__ == '__main__':
    main()
