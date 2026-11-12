#!/usr/bin/env python3
"""Copy bundled match-3 resources unchanged and index their source locations."""
import argparse
from collections import Counter
from contextlib import ExitStack
import hashlib
import html
import json
from pathlib import Path, PurePosixPath
import tempfile
from urllib.parse import quote
import zipfile

from story_index import SOURCE


DEST = SOURCE.parents[1] / 'homescapes-analysis/match3-export'
WHOLE_PACKS = {'Match3_Settings.zip', 'local_DoubleRainbow.zip'}
HAPTICS = 'base_mm/assets/common/hapticpatterns/unique/mx/'
MAX_EXPORT = 100_000_000


def encoding(data):
    if data.startswith(b'BLK\x1a'):
        return 'BLK'
    if data.startswith(b'PLXE'):
        return 'PLXE'
    if data.startswith(b'pzsd'):
        return 'pzsd'
    if data.startswith(b'RIFF') and data[8:12] == b'WEBP':
        return 'WebP'
    if data.startswith(b'\x89PNG\r\n\x1a\n'):
        return 'PNG'
    return 'as bundled'


def catalogue(rows):
    images, resources = [], []
    for row in sorted(rows, key=lambda item: item['file'].casefold()):
        path = html.escape(row['file'])
        name = html.escape(PurePosixPath(row['file']).name)
        link = html.escape(quote(row['file']), quote=True)
        kind = html.escape(row['encoding'])
        if kind in {'WebP', 'PNG'}:
            images.append(f'<figure><a href="{link}" title="{path}"><img loading="lazy" src="{link}" alt=""></a>'
                          f'<figcaption>{name}</figcaption></figure>')
        resources.append(f'<tr><td><a href="{link}">{path}</a></td><td>{kind}</td><td>{row["bytes"]:,}</td></tr>')
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Homescapes match-3 export</title>
<style>
body{{font:16px system-ui,sans-serif;background:#f7f4ee;color:#292432;max-width:1200px;margin:auto;padding:1.5rem}}
input{{font:inherit;margin:.5rem 0;width:min(32rem,95%);padding:.5rem}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(145px,1fr));gap:.75rem}}
figure{{margin:0;padding:.6rem;border-radius:.5rem;background:white;text-align:center;overflow-wrap:anywhere}}
figure img{{width:100%;height:96px;object-fit:contain}}figcaption,table{{font-size:.85rem}}
table{{width:100%;border-collapse:collapse}}th,td{{padding:.35rem;text-align:left;border-bottom:1px solid #ddd}}
td:first-child{{overflow-wrap:anywhere}}td:last-child{{text-align:right}}
</style></head>
<body><h1>Homescapes match-3 export</h1>
<p>{len(rows)} original files, including {len(images)} readable images.
Board atlas pixels and region metadata are still packed. Images below include UI and tutorial art.
The <a href="manifest.json">manifest</a> records sources and SHA-256 checksums.</p>
<label for="filter">Filter by path or encoding</label><br><input id="filter" type="search">
<h2>Readable images</h2><div class="grid">{''.join(images)}</div>
<h2>All exported files</h2>
<table><thead><tr><th scope="col">Bundle path</th><th scope="col">Encoding</th><th scope="col">Bytes</th></tr></thead>
<tbody>{''.join(resources)}</tbody></table>
<script>
const filter = document.querySelector('#filter');
const items = [...document.querySelectorAll('figure, tbody tr')].map(
  node => [node, (node.textContent + ' ' + node.querySelector('a').getAttribute('href')).toLowerCase()]);
filter.addEventListener('input', () => {{
  const query = filter.value.toLowerCase().trim();
  for (const [node, key] of items) node.hidden = !key.includes(query);
}});
</script></body></html>
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=DEST, help='new destination directory')
    dest = parser.parse_args().output
    if dest.exists() or dest.is_symlink():
        raise SystemExit(f'Destination already exists: {dest}')
    archive_root = SOURCE.parent
    paths = [SOURCE, *sorted((archive_root / 'packs').glob('*.zip'))]
    with ExitStack() as stack:
        selected = []
        destinations = set()
        for path in paths:
            archive = stack.enter_context(zipfile.ZipFile(path))
            for item in archive.infolist():
                name = item.filename.lower()
                if item.is_dir() or not (path.name in WHOLE_PACKS or 'match3' in name or name.startswith(HAPTICS)):
                    continue
                member = PurePosixPath(item.filename)
                if member.is_absolute() or '..' in member.parts:
                    raise ValueError(f'Unsafe bundle path: {item.filename}')
                origin = path.relative_to(archive_root).as_posix()
                relative = (PurePosixPath(origin) / member).as_posix()
                if relative.casefold() in destinations:
                    raise ValueError(f'Duplicate export path: {relative}')
                destinations.add(relative.casefold())
                selected.append((archive, item, origin, relative))
        size = sum(item.file_size for _, item, _, _ in selected)
        if not selected or size > MAX_EXPORT:
            raise ValueError(f'Unexpected resource selection: {len(selected)} files, {size} bytes')

        dest.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='.match3-export-', dir=dest.parent) as work:
            out = Path(work) / 'resources'
            out.mkdir()
            rows = []
            for archive, item, origin, relative in selected:
                data = archive.read(item)
                target = out / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                rows.append({'archive': origin, 'member': item.filename, 'file': relative,
                             'bytes': len(data), 'encoding': encoding(data),
                             'sha256': hashlib.sha256(data).hexdigest()})
            (out / 'manifest.json').write_text(json.dumps(rows, indent=2) + '\n', encoding='utf-8')
            (out / 'index.html').write_text(catalogue(rows), encoding='utf-8')
            out.rename(dest)
    print(f'Exported {len(rows)} files ({size:,} bytes) to {dest}')
    print(dict(Counter(row['encoding'] for row in rows)))


if __name__ == '__main__':
    main()
