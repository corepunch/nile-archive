#!/usr/bin/env python3
"""Build an offline schematic explorer of the extracted Homescapes levels."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/homescapes-analysis/decoded/match3levels/Match3/Levels'
OUTPUT = ROOT / 'reference/homescapes-analysis/board-explorer'


def load_level(path):
    root = ET.parse(path).getroot()
    level = root.find('Level')
    if level is None:
        raise ValueError(f'No Level element: {path}')
    cells = []
    for cell in level.findall('.//Cell'):
        attrs = dict(cell.attrib)
        x, y = int(attrs.pop('x')), int(attrs.pop('y'))
        models = []
        for item in cell.findall('Model'):
            model = dict(item.attrib)
            if len(item):
                model['_children_xml'] = [ET.tostring(child, encoding='unicode').strip() for child in item]
            models.append(model)
        cells.append([x, y, attrs, models])
    if len({(c[0], c[1]) for c in cells}) != len(cells):
        raise ValueError(f'Duplicate cell coordinate: {path}')
    targets = [dict(x.attrib) for x in level.findall('./Targets/target')]
    chips = [dict(x.attrib) for x in level.findall('./ChipSet/chip')]
    return {'path': path.relative_to(SOURCE).as_posix(), 'level': dict(level.attrib),
            'targets': targets, 'chips': chips, 'cells': cells}



PAGE = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Homescapes board explorer</title><style>
body{font:15px system-ui,sans-serif;background:#f6f3ee;color:#262030;max-width:1400px;margin:auto;padding:1.5rem}p{line-height:1.5}h1{margin-bottom:.3rem}
.controls{display:flex;flex-wrap:wrap;gap:.8rem;align-items:end}label{display:grid;gap:.3rem}input,select,button{font:inherit;padding:.5rem;border:1px solid #aaa;border-radius:.4rem;background:white}select{max-width:min(500px,85vw)}
.layout{display:grid;grid-template-columns:minmax(280px,1fr) minmax(250px,340px);gap:1rem;margin-top:1rem}#board{display:grid;gap:3px;align-content:start;overflow:auto;background:#ddd2c7;padding:.6rem;border-radius:.6rem}
.cell,.hole{aspect-ratio:1;min-width:25px}.cell{background:#eee6db;border:1px solid #bcae9f;border-radius:.3rem;padding:1px;overflow:hidden;font:10px system-ui;cursor:pointer}.cell:hover,.cell.selected{outline:3px solid #7955bd;z-index:1}.hole{background:transparent}.dot{display:block;width:40%;height:40%;border-radius:50%;margin:2px auto;background:#bbb}.id{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.detail{background:#fff;border-radius:.6rem;padding:1rem;overflow:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px}#meta{font-size:.9rem}@media(max-width:760px){.layout{grid-template-columns:1fr}}
</style><h1>Homescapes board explorer</h1><p>Bundled XML shown as a <strong>schematic</strong>, not a gameplay simulation. Paths are source file names; their relation to campaign level numbers is unverified. Layer abbreviations and colored dots are placeholders, not original board art. Y decreases down the screen by default; flip it if needed.</p>
<div class="controls"><label>Filter paths<input type="search" id="filter" placeholder="e.g. st0001 or contest"></label><label>Level file<select id="level"></select></label><button id="flip" type="button">Flip Y</button></div><p id="meta"></p><div class="layout"><div id="board" aria-label="Schematic board"></div><aside class="detail"><h2>Cell details</h2><p>Choose a cell to see its coordinates and all serialized model layers.</p><pre id="detail">No cell selected</pre><h3>Level attributes</h3><pre id="levelinfo"></pre></aside></div>
<script>
let levels=[];const filter=document.querySelector('#filter'), select=document.querySelector('#level'),board=document.querySelector('#board'),meta=document.querySelector('#meta'),detail=document.querySelector('#detail'),info=document.querySelector('#levelinfo');let flipped=false,current=null;const colors=['#e74d53','#f4c53c','#61b964','#4c98da','#d55fb1','#4bc1d2'];
function options(){let old=select.value,q=filter.value.toLowerCase(),list=levels.filter(x=>x.path.toLowerCase().includes(q));select.replaceChildren();for(const x of list){let o=document.createElement('option');o.value=x.path;o.textContent=x.path;select.append(o)}if(list.some(x=>x.path===old))select.value=old;else if(list.some(x=>x.path==='base/st/st0001.xml'))select.value='base/st/st0001.xml';meta.textContent=list.length+' matching files';draw()}
async function draw(){let path=select.value;board.replaceChildren();detail.textContent='No cell selected';if(!path){info.textContent='';return}let response=await fetch('/api/level?path='+encodeURIComponent(path));if(!response.ok){info.textContent='Unable to read level';return}let value=await response.json();if(select.value!==path)return;current=value;let cells=current.cells;info.textContent=JSON.stringify({level:current.level,targets:current.targets,chipSet:current.chips},null,2);meta.textContent=current.path+' · '+cells.length+' cells · '+levels.length+' files available';if(!cells.length)return;let xs=cells.map(c=>c[0]),ys=cells.map(c=>c[1]),xmin=Math.min(...xs),xmax=Math.max(...xs),ymin=Math.min(...ys),ymax=Math.max(...ys),w=xmax-xmin+1,lookup=new Map(cells.map(c=>[c[0]+','+c[1],c]));board.style.gridTemplateColumns='repeat('+w+', minmax(25px,1fr))';for(let row=0;row<=ymax-ymin;row++){let y=flipped?ymin+row:ymax-row;for(let x=xmin;x<=xmax;x++){let c=lookup.get(x+','+y);if(!c){let hole=document.createElement('div');hole.className='hole';board.append(hole);continue}let b=document.createElement('button');b.className='cell';b.type='button';b.title='('+x+', '+y+') '+c[3].map(m=>m.modelId||'?').join(', ');let first=c[3].find(m=>m.modelId==='NORMAL'),dot=document.createElement('span');dot.className='dot';if(first&&first.color in colors)dot.style.background=colors[Number(first.color)];b.append(dot);let ids=document.createElement('span');ids.className='id';ids.textContent=c[3].map(m=>m.modelId||'?').join('/');b.append(ids);b.addEventListener('click',()=>{board.querySelectorAll('.selected').forEach(el=>el.classList.remove('selected'));b.classList.add('selected');detail.textContent=JSON.stringify({x:c[0],y:c[1],attributes:c[2],models:c[3]},null,2)});board.append(b)}}}
filter.addEventListener('input',options);select.addEventListener('change',draw);document.querySelector('#flip').addEventListener('click',()=>{flipped=!flipped;draw()});fetch('/api/list').then(r=>r.json()).then(data=>{levels=data.map(path=>({path}));options()}).catch(()=>{meta.textContent='Unable to load level list'});
</script></html>'''

