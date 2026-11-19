#!/usr/bin/env python3
"""Verify shipped inventory, authored state coverage and native icon exports."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'art/manifest.json'
STATES = ['normal', 'selected', 'pressed', 'hover', 'disabled']

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def png(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    return struct.unpack('>II', data[16:24]), data[25]

def main():
    inventory = {str(p.relative_to(ROOT)): digest(p) for p in sorted((ROOT/'data').rglob('*')) if p.is_file()}
    manifest = json.loads(MANIFEST.read_text())
    if '--update' in sys.argv:
        manifest['runtime'] = inventory
        MANIFEST.write_text(json.dumps(manifest, indent=2) + '\n')
    assert manifest['runtime'] == inventory, 'Runtime changed: update the asset catalogue and manifest'
    assert manifest['states'] == STATES
    for path in manifest['prompts']:
        assert (ROOT/path).is_file(), path
    registration = json.loads((ROOT/'art/registration.json').read_text())
    assert 'buildings' not in registration and len(registration['icons']) == 19
    atlas = json.loads((ROOT/'art/match3-atlas.json').read_text())
    pieces = manifest['festive_pieces']
    assert png(ROOT/pieces['source']) == ((1536,1024),6)
    assert png(ROOT/pieces['layout']) == ((1536,1024),6)
    assert set(pieces['frames']) == {f'festive-{i}' for i in range(6)}
    for name in pieces['frames']:
        sprite = atlas['board_theme'][name]
        assert sprite['source'] == pieces['source'] and sprite['prompt'] == pieces['prompt'], name
        assert sprite['reference'] == pieces['layout'] and atlas['frames'][name]['box'][2:] == [128,128], name
        assert atlas['frames'][name]['atlas'] == 'pieces' and pieces['runtime'] == 'data/board/pieces.png', name
    for entry in registration['icons']:
        assert png(ROOT/'art/registered'/entry['path']) == ((128,128),6), entry['path']
    subprocess.run([sys.executable, str(ROOT/'tools/prepare_hud.py'), '--check'], check=True)
    tiles = manifest['tiles']
    spec = json.loads((ROOT.parents[1]/tiles['spec']).read_text())
    assert list(spec['tiles']) == tiles['frames'] and 'games/christmas-market/art/registered/board-tiles' in spec['outputs']
    for name in spec['tiles']:
        assert png(ROOT/'art/registered/board-tiles'/f'{name}.png') == ((128, 128), 6), name
    subprocess.run([sys.executable, str(ROOT.parents[1]/tiles['generator']), '--check'], check=True)
    frame = manifest['board_frame']
    art = (ROOT/'lua/art.lua').read_text()
    for review in ('review', 'decoration_review', 'reference', 'decorations'):
        assert (ROOT.parents[1]/frame[review]).is_file()
    assert frame['stone'] in inventory and (ROOT/frame['layout']).is_file()
    assert 'require("board_frame_atlas")' in art
    subprocess.run([sys.executable, str(ROOT.parents[1]/frame['generator']),
                    '--game', ROOT.name, '--check', str(ROOT/frame['stone'])], check=True)
    subprocess.run([sys.executable, str(ROOT/'tools/prepare_story_pieces.py'), '--check'], check=True)
    goods = manifest['market_goods']
    for name in ('source', 'prompt', 'edit_target', 'edit_target_prompt', 'transforms', 'review'):
        assert (ROOT/goods[name]).is_file(), name
    assert png(ROOT/goods['runtime']) == ((512, 512), 6) and len(set(goods['frames'])) == 16
    for kind in range(len(goods['frames'])):
        frame = atlas['frames'][f'market-{kind}']
        assert frame['atlas'] == 'pieces' and frame['box'][2:] == [128, 128]
    subprocess.run([sys.executable, str(ROOT/goods['registration']), '--check'], check=True)
    assert (ROOT/manifest['campaign_buttons']).is_file()
    buttons = manifest['bonus_buttons']
    economy = (ROOT/'lua/economy.lua').read_text()
    for key, frame in buttons['icons'].items():
        assert f'icon="{key}", frame="{frame}"' in economy and frame in atlas['frames'], key
        assert all(f'{key}-{state}' not in atlas['frames'] for state in STATES)
    nav = json.loads((ROOT/'art/navigation/manifest.json').read_text())
    assert set(nav['icons']) == {f'{kind}-{state}' for kind in ('build','play','levels') for state in STATES}
    for kind in ('build', 'play', 'levels'):
        assert len({digest(ROOT/nav['icons'][f'{kind}-{state}']['runtime']) for state in STATES}) == 5
    buildings = json.loads((ROOT/'art/building-catalogue/manifest.json').read_text())['items']
    for entry in buildings:
        assert png(ROOT/entry['runtime']) == (tuple(entry['image']),6), entry['key']
        assert all(x > 0 and x % 1 == 0 for x in entry['size'])
        assert entry['base_width'] > 0 and len(entry['pivot']) == 2
    assert {p.name for p in (ROOT/'data/city/buildings').iterdir()} == {e['key'] + '.png' for e in buildings}
    for i in range(6):
        assert png(ROOT/'art/registered/tile-sets/festive'/f'{i}.png') == ((128,128),6)
    cast = manifest['story_cast']
    assert png(ROOT/cast['source']) == ((1536,1024),6)
    assert set(cast['runtime']) == {str(p.relative_to(ROOT)) for p in (ROOT/'data/story/characters').glob('*.png')}
    for portrait in cast['runtime']:
        assert png(ROOT/portrait) == ((320,480),6), portrait
    catalogue = ROOT/'Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((catalogue/'Contents.json').read_text())['images']
    assert len(entries) == 11
    for entry in entries:
        pixels = int(entry['size'].split('x')[0]) * int(entry.get('scale','1x')[:-1])
        assert png(catalogue/entry['filename']) == ((pixels,pixels),2), entry
    particles = manifest['particle_sprites']   # retained CC0 Kenney sources, fresh atlas, documented frames
    assert (ROOT/particles['license']).is_file()
    doc = (ROOT/'docs/asset-catalogue.md').read_text()
    for name, source in particles['frames'].items():
        path = (Path(particles['source']) / f'{source}.png').as_posix()
        assert (ROOT/path).is_file(), source
        assert atlas['effects'][f'fx-{name}'] == path
        assert '`' + name + '`' in doc, f'Undocumented particle sprite: {name}'
    print(f'Christmas Market: {len(inventory)} runtime files, 19 atlas crops, {len(buildings)} Blender buildings, 11 native icon slots verified')

if __name__ == '__main__':
    main()
