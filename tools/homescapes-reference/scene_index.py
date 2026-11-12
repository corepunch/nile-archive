#!/usr/bin/env python3
"""Build a local index of screenplay actors and localization keys."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/homescapes-analysis/decoded/screenplays/Screenplays/compiled'
DESTINATION = ROOT / 'reference/homescapes-analysis/screenplay-index.html'
CALL = re.compile(r'ShowText\("([^"]+)"\s*,\s*\{([^\n]*)')
KEY = re.compile(r'Text\s*=\s*"([^"]+)"')


def main():
    if not SOURCE.is_dir():
        raise SystemExit('Run extract_archives.py first')
    scenes = []
    for path in sorted(SOURCE.glob('*.lua')):
        events = []
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            match = CALL.search(line)
            key = KEY.search(match.group(2)) if match else None
            if key:
                events.append([number, match.group(1), key.group(1)])
        scenes.append({'name': path.name, 'events': events})
    encoded = json.dumps(scenes, ensure_ascii=True).replace('<', '\\u003c')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Homescapes screenplay index</title>
<style>body{font:16px system-ui,sans-serif;background:#f6f3ee;color:#262030;max-width:1000px;margin:auto;padding:2rem}p{line-height:1.5}input,select{font:inherit;padding:.6rem;border:1px solid #aaa;border-radius:.4rem;max-width:100%}label{display:block;margin:1rem 0}li{background:white;padding:.7rem;margin:.4rem 0;overflow-wrap:anywhere}small{color:#555}</style>
<h1>Homescapes screenplay references</h1><p>Compiled screenplay files contain actor calls and localization keys. The dialogue wording remains encoded. Calls below follow source-file order; actors execute in separate branches, so this is not a verified conversation order.</p>
<label>Filter scripts or keys <input id="search" type="search" placeholder="e.g. chHall_FeedCat"></label><label>Script <select id="scene"></select></label><p id="count"></p><ol id="events"></ol>
<script>const data=DATA,search=document.querySelector('#search'),scene=document.querySelector('#scene'),count=document.querySelector('#count'),events=document.querySelector('#events');function choose(){let q=search.value.toLowerCase(),old=scene.value,list=data.filter(x=>(x.name+' '+x.events.map(e=>e[2]).join(' ')).toLowerCase().includes(q));scene.replaceChildren();for(let x of list){let o=document.createElement('option');o.value=x.name;o.textContent=x.name+' ('+x.events.length+' text calls)';scene.append(o)}if(list.some(x=>x.name===old))scene.value=old;count.textContent=list.length+' matching scripts';draw()}function draw(){events.replaceChildren();let x=data.find(x=>x.name===scene.value);if(!x)return;if(!x.events.length){let li=document.createElement('li');li.textContent='No directly recognized ShowText calls in this script.';events.append(li)}for(let [line,actor,key] of x.events){let li=document.createElement('li'),small=document.createElement('small');li.textContent=actor+' - '+key;small.textContent=' - source line '+line;li.append(small);events.append(li)}}search.addEventListener('input',choose);scene.addEventListener('change',draw);choose()</script></html>'''.replace('DATA', encoded, 1)
    DESTINATION.write_text(page, encoding='utf-8')
    print(f'{len(scenes)} scripts, {sum(len(x["events"]) for x in scenes)} ShowText references: {DESTINATION}')


if __name__ == '__main__':
    main()
