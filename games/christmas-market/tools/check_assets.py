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
    assert 'buildings' not in registration and len(registration['icons']) == 40
    for entry in registration['icons']:
        assert png(ROOT/'data'/entry['path']) == ((128,128),6), entry['path']
    for tool, folder in [('pickaxe','board-states'),('dynamite','board-states'),('sunburst','board-states'),('pause','expedition-hud')]:
        hashes = {digest(ROOT/'data'/folder/f'{tool}-{state}.png') for state in STATES}
        assert len(hashes) == 5, f'{tool}: every state must have its own authored artwork'
    buildings = json.loads((ROOT/'art/building-catalogue/manifest.json').read_text())['items']
    for entry in buildings:
        assert png(ROOT/entry['runtime']) == (tuple(entry['image']),6), entry['key']
        assert all(x > 0 and x % 1 == 0 for x in entry['size'])
        assert entry['base_width'] > 0 and len(entry['pivot']) == 2
    assert {p.name for p in (ROOT/'data/buildings').iterdir()} == {e['key'] + '.png' for e in buildings}
    for i in range(6):
        assert png(ROOT/'data/tile-sets/festive'/f'{i}.png') == ((128,128),6)
    cast = manifest['story_cast']
    assert png(ROOT/cast['source']) == ((1536,1024),6)
    assert set(cast['runtime']) == {str(p.relative_to(ROOT)) for p in (ROOT/'data/characters').glob('*.png')}
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
        assert (ROOT/particles['source']/f'{source}.png').is_file(), source
        assert '`' + name + '`' in doc, f'Undocumented particle sprite: {name}'
    subprocess.run([sys.executable, str(ROOT.parents[1]/'tools/pack_particles.py'), 'christmas-market', '--check'], check=True)
    print(f'Christmas Market: {len(inventory)} runtime files, 40 atlas crops, {len(buildings)} Blender buildings, 11 native icon slots verified')

if __name__ == '__main__':
    main()
