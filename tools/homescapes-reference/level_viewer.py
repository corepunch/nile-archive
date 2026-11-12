#!/usr/bin/env python3
"""Render the local explorer for extracted Homescapes levels."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/homescapes-analysis/decoded/match3levels/Match3/Levels'


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
.cell,.hole{aspect-ratio:1;min-width:25px}.cell{background:#eee6db;border:1px solid #bcae9f;border-radius:.3rem;padding:1px;overflow:hidden;font:10px system-ui;cursor:pointer}.cell:hover,.cell.selected{outline:3px solid #7955bd;z-index:1}.hole{background:transparent}.visual{position:relative;width:100%;height:75%;display:grid;place-items:center}.piece{position:absolute;width:82%;height:100%;object-fit:contain}.piece.ground,.piece.overlay{width:96%}.piece.ice-fragment{object-position:center bottom}.unknown{display:grid;place-items:center;height:75%;font-weight:700;color:#62586b;font-size:16px}.id{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.detail{background:#fff;border-radius:.6rem;padding:1rem;overflow:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px}#meta,#art-status{font-size:.9rem}.examples{display:flex;gap:1rem;flex-wrap:wrap}@media(max-width:760px){.layout{grid-template-columns:1fr}}
</style><h1>Homescapes board explorer</h1>
<p id="art-status"></p>
<nav class="examples" aria-label="Example boards"><a id="atlas" href="/art/" hidden>Browse the five atlas pages</a>
<a href="/?level=base%2Fst%2Fst0001.xml">Gems</a>
<a href="/?level=base%2Fst%2Fst0136.xml">Ice</a>
<a href="/?level=base%2Fst%2Fst0038.xml">Chains</a>
<a href="/?level=base%2Fst%2Fst0120.xml">Boxes</a>
<a href="/?level=base%2Fst%2Fst0101.xml">Cookies</a>
<a href="/?level=base%2Fst%2Fst0038.xml">Honey</a>
<a href="/?level=packs%2Fcontest%2Fcontest_007_04.xml">Cobwebs</a></nav>
<div class="controls"><label>Filter paths<input type="search" id="filter" placeholder="e.g. st0001 or contest"></label><label>Level file<select id="level"></select></label><button id="flip" type="button">Flip Y</button></div><p id="meta"></p><div class="layout"><div id="board" aria-label="Board layout"></div><aside class="detail"><h2>Cell details</h2><p>Choose a cell to see its coordinates and model layers.</p><pre id="detail">No cell selected</pre><h3>Level attributes</h3><pre id="levelinfo"></pre></aside></div>
<script>
let levels = [], sprites = new Set(), modelArt = {}, flipped = false;
const requested = new URLSearchParams(location.search).get('level') || 'base/st/st0001.xml';
const filter = document.querySelector('#filter'), select = document.querySelector('#level'),
      board = document.querySelector('#board'), meta = document.querySelector('#meta'),
      detail = document.querySelector('#detail'), info = document.querySelector('#levelinfo');
const iconModels={BOX:'box',TRASH:'trash',JELLY:'jelly',LOCK:'lock',RUG:'rug',CARRY:'carry',CHERRY:'piggy',TAPE_MEASURE:'tape_measure',JAR:'jar',TARGET_GEN:'target_generator',BOMB:'bonus_bomb',LINE:'bonus_line',LIGHTNING:'bonus_lightning'};
function pickIcons(models){let ground=models.filter(m=>m.modelId==='JELLY'||m.modelId==='RUG').map(m=>iconModels[m.modelId]+'.webp');let n=models.find(m=>m.modelId==='NORMAL'&&/^[0-5]$/.test(m.color));if(n)ground.push('chip_'+n.color+'.webp');for(const m of models){if(iconModels[m.modelId]&&m.modelId!=='JELLY'&&m.modelId!=='RUG')ground.push(iconModels[m.modelId]+'.webp')}return ground}

function pickSprites(models, available, mappings) {
  const layers = {ground: [], piece: [], overlay: []};
  for (const [index, model] of models.entries()) {
    const mapping = mappings[model.modelId];
    if (!mapping) continue;
    const value = model[mapping.field];
    const mirror = model.mirror === 'true' ? mapping.variants?.[value + ':mirror'] : undefined;
    const id = mirror || mapping.variants?.[value] || mapping.sprite;
    if (!available.has(id)) continue;
    const style = id === 'ice-1' ? 'overlay ice-fragment' : mapping.layer;
    layers[mapping.layer].push({id, style, index, status: mapping.status || 'identified'});
  }
  return Object.values(layers).flat();
}

function options() {
  const old = select.value || requested;
  const query = filter.value.toLowerCase();
  const matches = levels.filter(path => path.toLowerCase().includes(query));
  select.replaceChildren(...matches.map(path => new Option(path, path)));
  if (matches.includes(old)) select.value = old;
  draw();
}

function cellButton(cell) {
  const [x, y, attributes, models] = cell;
  const names = models.map(model => model.modelId || '?');
  const button = document.createElement('button');
  button.className = 'cell';
  button.type = 'button';
  button.title = '(' + x + ', ' + y + ') ' + names.join(', ');
  const art = sprites.size
    ? pickSprites(models, sprites, modelArt).map(sprite => ({
        src: '/art/sprites/' + sprite.id + '.png', title: sprite.id, style: sprite.style,
        index: sprite.index, status: sprite.status
      }))
    : pickIcons(models).map((icon, index) => ({
        src: '/api/icon/' + icon, title: 'Goal icon ' + icon, style: index === 0 ? 'ground' : ''
      }));
  const visual = document.createElement('span');
  visual.className = art.length ? 'visual' : 'unknown';
  if (!art.length && names.length) visual.textContent = '?';
  for (const layer of art) {
    const image = document.createElement('img');
    image.className = ('piece ' + layer.style).trim();
    image.alt = '';
    image.title = layer.title;
    image.src = layer.src;
    visual.append(image);
  }
  const ids = document.createElement('span');
  ids.className = 'id';
  ids.textContent = names.join('/');
  button.append(visual, ids);
  button.addEventListener('click', () => {
    board.querySelector('.selected')?.classList.remove('selected');
    button.classList.add('selected');
    const layers = new Map(art.map(layer => [layer.index, layer]));
    const inspected = models.map((model, index) => {
      const layer = layers.get(index);
      return sprites.size
        ? {...model, art: layer ? {sprite: layer.title, status: layer.status} : {status: 'unmapped'}}
        : model;
    });
    detail.textContent = JSON.stringify({x, y, attributes, models: inspected}, null, 2);
  });
  return button;
}

let request = 0;
async function draw() {
  const version = ++request;
  const path = select.value;
  board.replaceChildren();
  detail.textContent = 'No cell selected';
  if (!path) {
    meta.textContent = 'No matching levels';
    info.textContent = '';
    return;
  }
  try {
    const response = await fetch('/api/level?path=' + encodeURIComponent(path));
    if (!response.ok) throw new Error('Level unavailable');
    const {cells, level, targets, chips} = await response.json();
    if (version !== request) return;
    info.textContent = JSON.stringify({level, targets, chipSet: chips}, null, 2);
    meta.textContent = path + ' · ' + cells.length + ' cells · ' + levels.length + ' files available';
    if (!cells.length) return;
    const xs = cells.map(cell => cell[0]), ys = cells.map(cell => cell[1]);
    const xmin = Math.min(...xs), xmax = Math.max(...xs), ymin = Math.min(...ys), ymax = Math.max(...ys);
    const lookup = new Map(cells.map(cell => [cell[0] + ',' + cell[1], cell]));
    board.style.gridTemplateColumns = 'repeat(' + (xmax - xmin + 1) + ', minmax(25px,1fr))';
    const fragment = document.createDocumentFragment();
    for (let row = 0; row <= ymax - ymin; row++) {
      const y = flipped ? ymin + row : ymax - row;
      for (let x = xmin; x <= xmax; x++) {
        const cell = lookup.get(x + ',' + y);
        if (cell) fragment.append(cellButton(cell));
        else {
          const hole = document.createElement('div');
          hole.className = 'hole';
          fragment.append(hole);
        }
      }
    }
    board.append(fragment);
  } catch (error) {
    if (version === request) info.textContent = 'Unable to read level';
  }
}

filter.addEventListener('input', options);
select.addEventListener('change', draw);
document.querySelector('#flip').addEventListener('click', () => { flipped = !flipped; draw(); });
Promise.all(['/api/list', '/api/sprites', '/api/model-art'].map(url => fetch(url).then(response => response.json())))
  .then(([paths, ids, mappings]) => {
    levels = paths;
    sprites = new Set(ids);
    modelArt = mappings;
    document.querySelector('#atlas').hidden = !sprites.size;
    document.querySelector('#art-status').textContent = sprites.size
      ? 'Original sprites on bundled layouts. Select a cell to see its model, strength, and whether its art is identified, a material preview, or unmapped.'
      : 'Board art is unavailable. These layouts use goal icons where available.';
    options();
  })
  .catch(() => { meta.textContent = 'Unable to load board data'; });
</script></html>'''

