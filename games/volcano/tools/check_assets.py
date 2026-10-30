#!/usr/bin/env python3
"""Check that every shipped asset matches the replacement/provenance catalog."""
import hashlib
import json
from pathlib import Path

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
    print(f'Volcano asset catalog: {len(actual)} shipped files verified; {len(catalog["borrowed"])} atlas to replace')
if __name__=='__main__': main()
