#!/usr/bin/env python3
"""Verify shipped inventory, authored state coverage and native icon exports."""
import hashlib
import json
from pathlib import Path
import struct
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
    if '--update' in sys.argv:
        MANIFEST.write_text(json.dumps({'status': 'directional buildings pending Blender render/repaint',
            'generator': 'built-in image_gen', 'prompts': ['art/prompts.json', 'art/character-and-icon-prompts.json', 'art/reference-sheet-prompt.txt'],
            'states': STATES, 'runtime': inventory}, indent=2) + '\n')
    manifest = json.loads(MANIFEST.read_text())
    assert manifest['runtime'] == inventory, 'Runtime changed: update the asset catalogue and manifest'
    assert manifest['states'] == STATES
    for path in manifest['prompts']:
        assert (ROOT/path).is_file(), path
    registration = json.loads((ROOT/'art/registration.json').read_text())
    assert len(registration['buildings']) == 12 and len(registration['icons']) == 40
    for entry in registration['icons']:
        assert png(ROOT/'data'/entry['path']) == ((128,128),6), entry['path']
    for tool, folder in [('pickaxe','board-states'),('dynamite','board-states'),('sunburst','board-states'),('pause','expedition-hud')]:
        hashes = {digest(ROOT/'data'/folder/f'{tool}-{state}.png') for state in STATES}
        assert len(hashes) == 5, f'{tool}: every state must have its own authored artwork'
    for i, entry in enumerate(registration['buildings']):
        assert png(ROOT/'data/buildings'/f'{i}.png') == (tuple(entry['size']),6)
        assert all(x > 0 and x % 1 == 0 for x in entry['tiles'])
        assert entry['base_width'] > 0 and len(entry['pivot']) == 2
    for i in range(6):
        assert png(ROOT/'data/tile-sets/festive'/f'{i}.png') == ((128,128),6)
    assert png(ROOT/'data/characters/noelle.png') == ((320,480),6)
    catalogue = ROOT/'Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((catalogue/'Contents.json').read_text())['images']
    assert len(entries) == 11
    for entry in entries:
        pixels = int(entry['size'].split('x')[0]) * int(entry.get('scale','1x')[:-1])
        assert png(catalogue/entry['filename']) == ((pixels,pixels),2), entry
    print(f'Christmas Market: {len(inventory)} runtime files, 40 atlas crops, 12 buildings, 11 native icon slots verified')

if __name__ == '__main__':
    main()
