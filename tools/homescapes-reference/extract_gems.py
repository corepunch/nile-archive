#!/usr/bin/env python3
"""Extract directly readable gem UI art and unwrap the five board atlases."""
import hashlib
import html
import json
from pathlib import Path
import re
import zipfile

from story_index import SOURCE, decode

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'reference/homescapes-analysis/gems'
TARGET = 'base_mm/Match3/vso/textures/UI/Match3TargetsBase/'
HINT = 'base_mm/Match3/vso/textures/UI/LoadingHint/'
TARGET_RE = re.compile(r'(?:chip_[0-5]|bonus_(?:any|bomb|lightning|line|plane))(?:_facelift)?\.webp')
HINT_RE = re.compile(r'.*_(?:chip\d*|result)\.webp')


def selected(name):
    if name.startswith(TARGET) and TARGET_RE.fullmatch(name[len(TARGET):]):
        return 'goal-icons'
    if name.startswith(HINT) and HINT_RE.fullmatch(name[len(HINT):]):
        return 'tutorial-art'
    return None


def main():
    if DEST.exists():
        raise SystemExit(f'Destination exists: {DEST}; preserve or move it before extraction')
    items = []
    with zipfile.ZipFile(SOURCE) as archive:
        names = sorted(name for name in archive.namelist() if selected(name))
        if len(names) != 35:
            raise SystemExit(f'Expected 35 readable images in this bundle, found {len(names)}')
        for name in names:
            group = selected(name)
            data = archive.read(name)
            if data[:4] != b'RIFF' or data[8:12] != b'WEBP':
                raise ValueError(f'Not WebP: {name}')
            rel = Path(group) / Path(name).name
            path = DEST / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            items.append({'source': name, 'output': rel.as_posix(), 'kind': group,
                          'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)})
        for i in range(5):
            base = f'base_mm/atlases/Match3_0{i}'
            for ext in ('.dds', '.xml'):
                name = base + ext
                data = archive.read(name)
                original_hash = hashlib.sha256(data).hexdigest()
                if ext == '.dds':
                    data = decode(data)
                    if not data.startswith(b'DDS '):
                        raise ValueError(f'Expected DDS header: {name}')
                rel = Path('board-atlases') / (Path(base).name + ext)
                path = DEST / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                items.append({'source': name, 'output': rel.as_posix(),
                              'kind': 'unwrapped-dds' if ext == '.dds' else 'encoded-metadata',
                              'source_sha256': original_hash,
                              'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)})
    (DEST / 'manifest.json').write_text(json.dumps(items, indent=2) + '\n', encoding='utf-8')
    groups = []
    for kind, title in [('goal-icons', 'Goal icons'), ('tutorial-art', 'Tutorial images')]:
        cards = []
        for item in items:
            if item['kind'] == kind:
                src = html.escape(item['output'], quote=True)
                label = html.escape(Path(item['output']).name)
                cards.append(f'<figure><img src="{src}" alt="{label}"><figcaption>{label}</figcaption></figure>')
        groups.append('<h2>' + title + '</h2><div class="grid">' + ''.join(cards) + '</div>')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Homescapes gem sources</title><style>body{font:16px system-ui,sans-serif;background:#f7f4ee;color:#292432;max-width:1100px;margin:auto;padding:2rem}p{line-height:1.5}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:1rem}figure{margin:0;background:white;border:1px solid #ddd;border-radius:.6rem;padding:1rem;text-align:center;overflow-wrap:anywhere}img{width:100%;height:120px;object-fit:contain}figcaption{font-size:.8rem}</style><h1>Homescapes gem sources</h1><p>Original goal-panel and tutorial artwork from the installed app. These are not a complete inventory of runtime board sprites; the five unwrapped board atlas textures have not yet been decoded. Filenames are preserved.</p>''' + ''.join(groups) + '</html>'
    (DEST / 'index.html').write_text(page, encoding='utf-8')
    print(f'{len(names)} WebP images and five DDS/XML atlas pairs: {DEST}')


if __name__ == '__main__':
    main()
