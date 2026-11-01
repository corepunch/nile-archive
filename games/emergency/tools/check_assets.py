#!/usr/bin/env python3
"""Check that every shipped asset matches the replacement/provenance catalog."""
import hashlib
import json
from pathlib import Path
import struct

GAME=Path(__file__).resolve().parents[1]
def main():
    catalog=json.loads((GAME/'docs/asset-catalog.json').read_text())
    data=GAME/'data'
    actual={str(p.relative_to(data)) for p in data.rglob('*') if p.is_file()}
    recorded={e['asset'] for e in catalog['runtime']}
    if actual!=recorded: raise SystemExit(f'Asset catalog file list differs: {actual ^ recorded}')
    for e in catalog['runtime']:
        path=data/e['asset']
        if hashlib.sha256(path.read_bytes()).hexdigest()!=e['sha256']:
            raise SystemExit('Asset changed without updating its catalog: '+e['asset'])
    for e in catalog['borrowed']:
        if e['asset'] not in actual or not e['animations'] or not e['replacement']:
            raise SystemExit('Incomplete borrowed asset entry: '+e['asset'])
    icon = catalog['app_icon']
    for rel, expected in icon['files'].items():
        if hashlib.sha256((GAME/rel).read_bytes()).hexdigest() != expected:
            raise SystemExit('AppIcon changed without updating its catalog: '+rel)
    icons = GAME/'Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((icons/'Contents.json').read_text())['images']
    assert len(entries) == 11, 'AppIcon must cover iOS and all macOS slots'
    for entry in entries:
        size = int(entry['size'].split('x')[0]) * int(entry.get('scale','1x')[:-1])
        data = (icons/entry['filename']).read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',data[16:24]) == (size,size), entry
        assert data[25] == 2, 'Native app icons must be opaque RGB'
    print('Emergency AppIcon: authored selection, source sheet and 11 native slots verified')
    print(f'Emergency asset catalog: {len(actual)} shipped files verified; {len(catalog["borrowed"])} atlas to replace')
if __name__=='__main__': main()
