#!/usr/bin/env python3
"""Read the observed quest/day/record pointer arrays, without simulating play."""
import json
from pathlib import Path
import re
import struct
import zipfile

from story_index import SOURCE, OUTPUT, decode

DESTINATION = OUTPUT.with_name('story-outline.html')


def parse(data):
    def u32(p):
        if p < 0 or p + 4 > len(data):
            raise ValueError('Pointer outside quest data')
        return struct.unpack_from('<I', data, p)[0]

    def string(p):
        if p < 0 or p + 2 > len(data):
            raise ValueError('String outside quest data')
        size = struct.unpack_from('<H', data, p)[0]
        if not 0 < size <= 512 or p + 2 + size > len(data):
            raise ValueError('Invalid string length')
        value = data[p + 2:p + 2 + size].decode('utf-8')
        if not value.isprintable():
            raise ValueError('Invalid text in string')
        return value

    def relative(p):
        offset = u32(p)
        if not offset:
            return None
        return p + offset

    root = relative(0x18)
    if root is None or u32(root) > 100:
        raise ValueError('Invalid day array')
    days = []
    for i in range(u32(root)):
        day = relative(root + 4 + i * 4)
        if day is None:
            raise ValueError('Missing day')
        label = relative(day)
        label = string(label + 4) if label is not None else ''
        records = relative(day + 4)
        if records is None or u32(records) > 1000:
            raise ValueError('Invalid record array')
        tasks = []
        for j in range(u32(records)):
            task = relative(records + 4 + j * 4)
            if task is None:
                raise ValueError('Missing record')
            task += 4
            name = relative(task)
            title = relative(task + 8)
            if name is None:
                raise ValueError('Missing record identifier')
            tasks.append({'id': string(name), 'title_key': string(title) if title else '', 'offset': task})
        days.append({'label': label, 'offset': day, 'tasks': tasks})
    return days


def main():
    areas = []
    with zipfile.ZipFile(SOURCE) as archive:
        for path in sorted(n for n in archive.namelist() if n.endswith('/Quest.xml.au')):
            days = parse(decode(archive.read(path)))
            areas.append({'name': Path(path).parts[-2], 'path': path, 'days': days})
    encoded = json.dumps(areas, ensure_ascii=True).replace('<', '\\u003c')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Homescapes quest outline</title>
<style>body{font:16px system-ui,sans-serif;background:#f6f3ee;color:#262030;max-width:1100px;margin:auto;padding:2rem}p{line-height:1.5}select,input{font:inherit;padding:.6rem;border:1px solid #aaa;border-radius:.4rem;max-width:100%}label{display:block;margin:1rem 0}article{background:white;border:1px solid #ddd;border-radius:.7rem;margin:1rem 0;padding:1rem}li{padding:.45rem 0;border-bottom:1px solid #eee}small{display:block;color:#625a67;overflow-wrap:anywhere}h2{margin-top:0}</style>
<h1>Homescapes quest outline</h1><p>Array order from the bundled quest files, not a verified playthrough. Labels are mechanically inferred from identifiers; they are not dialogue or official localized task text. Prerequisites, variants, optional actions and actual display order remain unverified.</p>
<label>Area <select id="area"></select></label><label>Filter records <input id="search" type="search" placeholder="e.g. carpet, cat, father"></label><p id="count"></p><main id="days"></main>
<script>const data=DATA,area=document.querySelector('#area'),search=document.querySelector('#search'),days=document.querySelector('#days'),count=document.querySelector('#count');for(const d of data){let o=document.createElement('option');o.value=d.path;o.textContent=d.name;area.append(o)}function label(s){let v=s.replace(/^CH_(?:OstinsRoom|\\d_\\d+)_/i,'').replace(/^ch[A-Za-z0-9]+_/,'').replaceAll('_',' ').replace(/([a-z])([A-Z])/g,'$1 $2');return v||s}function draw(){let a=data.find(x=>x.path===area.value),q=search.value.toLowerCase(),shown=0,total=0;days.replaceChildren();a.days.forEach((d,i)=>{total+=d.tasks.length;let tasks=d.tasks.filter(t=>(t.id+' '+t.title_key+' '+label(t.id)).toLowerCase().includes(q));if(!tasks.length)return;shown+=tasks.length;let section=document.createElement('article'),h=document.createElement('h2'),list=document.createElement('ol');h.textContent=d.label||'Unnamed day group '+(i+1);section.append(h,list);for(const t of tasks){let li=document.createElement('li'),title=document.createElement('span'),source=document.createElement('small');title.textContent=label(t.id);source.textContent=t.id+' · title key '+(t.title_key||'(none)')+' · offset 0x'+t.offset.toString(16);li.append(title,source);list.append(li)}days.append(section)});count.textContent=shown+' of '+total+' records · '+a.path}area.value=(data.find(x=>x.name==='CH_Hall')||data[0]).path;area.addEventListener('change',draw);search.addEventListener('input',draw);draw()</script></html>'''.replace('DATA', encoded, 1)
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    DESTINATION.write_text(page, encoding='utf-8')
    print(f'{len(areas)} areas, {sum(len(a["days"]) for a in areas)} groups, {sum(len(d["tasks"]) for a in areas for d in a["days"])} records: {DESTINATION}')


if __name__ == '__main__':
    main()
