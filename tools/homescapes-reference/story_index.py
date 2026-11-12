#!/usr/bin/env python3
"""Index printable strings in decompressed Homescapes quest containers.

This is a raw evidence browser, not a parser of tasks or dialogue.
Requires the zstd command. The app bundle and output remain local and ignored.
"""
import html
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/Homescapes.app/base.zip'
OUTPUT = ROOT / 'reference/homescapes-analysis/quest-strings.html'


def decode(data):
    if data[:4] != b'BLK\x1a' or data[40:44] != b'\x28\xb5\x2f\xfd':
        raise ValueError('Unsupported quest container')
    size = struct.unpack_from('<I', data, 12)[0]
    if size > 16_000_000:
        raise ValueError('Unexpected uncompressed size')
    proc = subprocess.run(['zstd', '-dc'], input=data[40:], capture_output=True)
    # Some containers append non-frame bytes, which the zstd CLI reports as an
    # unknown header after successfully emitting the complete first frame.
    if len(proc.stdout) != size or (proc.returncode and b'unknown header' not in proc.stderr):
        raise ValueError('Zstandard output incomplete or corrupt')
    if proc.stdout[:8] != data[16:24]:
        raise ValueError('Decompressed prefix does not match container header')
    return proc.stdout


def main():
    entries = []
    with zipfile.ZipFile(SOURCE) as archive:
        names = sorted(n for n in archive.namelist() if n.endswith('/Quest.xml.au'))
        for name in names:
            data = decode(archive.read(name))
            found = [(m.start(), m.group().decode('ascii')) for m in re.finditer(rb'[\x20-\x7e]{5,}', data)]
            entries.append({'path': name, 'bytes': len(data), 'strings': found})
    encoded = json.dumps(entries, ensure_ascii=True).replace('<', '\\u003c')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Homescapes quest string explorer</title><style>body{font:16px system-ui,sans-serif;background:#f6f3ee;color:#262030;max-width:1100px;margin:auto;padding:2rem}p{line-height:1.5}input,select{font:inherit;padding:.6rem;border:1px solid #aaa;border-radius:.4rem;max-width:100%}label{display:block;margin:1rem 0}table{border-collapse:collapse;width:100%;background:white}td,th{border-bottom:1px solid #ddd;padding:.5rem;text-align:left;overflow-wrap:anywhere}td:first-child{white-space:nowrap;font-family:monospace;color:#655}td:last-child{font-family:monospace}</style>
<h1>Homescapes quest strings</h1><p>Raw printable strings from decompressed bundled quest data. This is <strong>not</strong> a story transcript or a parsed task list. Sequence in the binary does not establish player-facing order, and identifiers may name unused or alternate content. Offsets are in the decompressed container.</p>
<label>Quest file <select id="file"></select></label><label>Filter strings <input id="search" type="search" placeholder="e.g. title, scene, room"></label><p id="count"></p><table><thead><tr><th>Offset</th><th>Raw string</th></tr></thead><tbody id="rows"></tbody></table>
<script>const data=DATA,sel=document.querySelector('#file'),search=document.querySelector('#search'),rows=document.querySelector('#rows'),count=document.querySelector('#count');for(const d of data){let o=document.createElement('option');o.value=d.path;o.textContent=d.path;sel.append(o)}function draw(){const d=data.find(x=>x.path===sel.value),q=search.value.toLowerCase();rows.replaceChildren();let visible=d.strings.filter(x=>x[1].toLowerCase().includes(q));for(const [offset,s] of visible){let tr=document.createElement('tr'),a=document.createElement('td'),b=document.createElement('td');a.textContent='0x'+offset.toString(16);b.textContent=s;tr.append(a,b);rows.append(tr)}count.textContent=visible.length+' of '+d.strings.length+' strings · '+d.bytes+' decompressed bytes'}sel.addEventListener('change',draw);search.addEventListener('input',draw);draw()</script></html>'''.replace('DATA', encoded, 1)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(page, encoding='utf-8')
    print(f'{len(entries)} files, {sum(len(e["strings"]) for e in entries)} strings: {OUTPUT}')


if __name__ == '__main__':
    main()
