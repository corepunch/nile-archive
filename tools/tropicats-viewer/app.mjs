import {cellArt, boardObjects} from './art.mjs';
import {GOALS, LAYERS, valueAt, occupied, distinct, changedAt,
  sourceIndex, describeValue, goalLines, filterLevels} from './model.mjs';

const $ = id => document.getElementById(id);
const escape = value => String(value).replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const tiers = [['a','Easy'],['b','Medium'],['c','Hard']];
const colors = ['#52646b','#ce5655','#3e9376','#497eb8','#d8b84c','#8c68ae','#d48b43',
  '#639d97','#54716f','#b89946','#536172','#ab7b9a','#449a9a','#c09749','#927453','#99a9ac'];
const shortColors = ['','R','G','B','Y','P','O','T','?','$','CB','RB','CL','TR','D','–'];
const special = ['','LH','LV','B','AB','SB','CG','S1','S2','S3','CN','CH','CR','DR','DL','UL','UR','D?'];
let artwork = {}, index, filtered = [], current, variants, page = 0, cell = null, request = 0;
const PAGE_SIZE = 50;

function fillSelect(id, entries) {
  for (const [value, text] of entries) $(id).add(new Option(text, value));
}
function updateList(resetPage = true) {
  filtered = filterLevels(index.levels, $('search').value, $('chapter').value, $('family').value);
  if (resetPage) page = 0;
  page = Math.max(0, Math.min(page, Math.ceil(filtered.length / PAGE_SIZE) - 1));
  $('result-count').textContent = `${filtered.length.toLocaleString()} levels`;
  $('level-list').innerHTML = filtered.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE).map(l =>
    `<button class="level-row ${l.number === current?.number ? 'active' : ''}" data-number="${l.number}" ${l.number === current?.number ? 'aria-current="true"' : ''}><strong>${l.number}</strong><span>${escape(GOALS[l.objective] ?? l.objective)}<small>Chapter ${l.chapter}</small></span><span class="tier-tag">${escape(l.quest?.tier.toUpperCase() ?? '')}</span></button>`).join('') || '<p class="empty">No matching levels. Try another search or reset the filters.</p>';
  $('page-info').textContent = filtered.length ? `${page + 1} / ${Math.ceil(filtered.length / PAGE_SIZE)}` : '0 / 0';
  $('page-prev').disabled = page === 0;
  $('page-next').disabled = (page + 1) * PAGE_SIZE >= filtered.length;
  const at = filtered.findIndex(l => l.number === current?.number);
  $('previous').disabled = at <= 0;
  $('next').disabled = at < 0 || at >= filtered.length - 1;
}
function choose(number) {
  if (number === current?.number) return;
  location.hash = `level=${number}`;
}
async function read(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not load data (${response.status}). Check the local server and extracted files.`);
  return response.json();
}
async function loadLevel() {
  const token = ++request;
  const params = new URLSearchParams(location.hash.slice(1));
  const number = Number(params.get('level') || 1);
  const row = index.levels.find(l => l.number === number);
  $('status').hidden = false;
  $('content').hidden = true;
  $('status').textContent = row ? `Loading level ${number}…` : 'Unknown level. Choose a campaign level from the browser.';
  if (!row) { current = null; updateList(false); return; }
  try {
    const data = await read(`/api/level/${number}`);
    if (token !== request) return;
    current = row; variants = data; cell = null;
    const at = filtered.findIndex(l => l.number === number);
    if (at >= 0) page = Math.floor(at / PAGE_SIZE);
    updateList(false);
    const chapter = index.chapters.find(c => c.chapter === row.chapter);
    $('chapter-title').textContent = `Chapter ${row.chapter} / ${chapter.title}`;
    $('level-number').textContent = number;
    $('quest-line').textContent = row.quest ? `${row.quest.title} · story requires ${row.quest.tier.toUpperCase()} · item: ${row.quest.item}` : 'Campaign puzzle';
    render();
    $('status').hidden = true; $('content').hidden = false;
  } catch (error) { if (token === request) $('status').textContent = error.message; }
}
function spriteMode() { return $('sprites').checked && $('layer').value === 'combined'; }
function spriteImage(name, attributes = '') {
  return artwork[name] ? `<img src="${escape(artwork[name].url)}" alt="" draggable="false" ${attributes}>` : '';
}
function objectMarkup(level) {
  return boardObjects(level, $('flip').checked).map(o => spriteImage(o.name,
    `class="board-object" style="left:${o.left / 9 * 100}%;top:${o.top / 9 * 100}%;width:${o.width / 9 * 100}%;height:${o.height / 9 * 100}%;z-index:${o.z}"`)).join('');
}
function tileMarkup(level, tier, displayIndex) {
  const i = sourceIndex(displayIndex, $('flip').checked), layer = $('layer').value;
  const v = key => valueAt(level, key, i);
  const diff = $('differences').checked && tier !== 'a' && changedAt(variants.a, level, i, layer);
  let label = '', badges = '', style = '', classes = '', art = '';
  if (spriteMode()) {
    classes += ' sprite-cell';
    const result = cellArt(level, i, {preview:$('preview').checked, seed:current.number});
    const missing = result.images.filter(s => !artwork[s.name]);
    art = result.images.map(s => spriteImage(s.name, `class="sprite ${s.role}" style="z-index:${s.z}"`)).join('');
    badges = [...result.badges, ...missing.map(() => '?')].map(b => `<small class="art-badge">${escape(b)}</small>`).join('');
  } else if (layer === 'combined') {
    label = shortColors[v('gemColors')] ?? `G${v('gemColors')}`;
    style = `--piece:${colors[v('gemColors')] ?? '#52646b'}`;
    if (v('stones')) { label = `S${v('stones')}`; classes += ' stone'; }
    if (!label && v('fields') === 2) label = 'F2';
    const tags = [];
    if (v('gemTypes')) tags.push(special[v('gemTypes')] ?? `G${v('gemTypes')}`);
    if (v('chains')) tags.push(`C${v('chains')}`);
    if (v('hiddenItems')) tags.push(`H${v('hiddenItems')}`);
    if (v('portals')) tags.push(`P${v('portals')}`);
    badges = `<small>${escape(tags.slice(0, 2).join(' '))}${tags.length > 2 ? '+' : ''}</small>`;
    if (v('chains')) classes += ' chained';
    if (v('tiles') === 3) classes += ' watered';
    if (v('gemModifier')) classes += ' modified';
  } else {
    const value = v(layer);
    label = String(value);
    style = `--piece:${layer === 'gemColors' ? colors[value] ?? '#52646b' : '#3c7473'}`;
    if (!value) classes += ' zero';
  }
  if (!v('fields')) classes += ' void';
  const detail = Object.keys(level.layout).filter(k => v(k)).map(k => `${k}: ${describeValue(k, v(k))}`).join('; ');
  return `<button class="cell${classes}${diff ? ' changed' : ''}${cell === i ? ' selected' : ''}" style="${style}" data-cell="${i}" data-display="${displayIndex}" data-tier="${tier}" tabindex="${cell === i || (cell === null && displayIndex === 0) ? '0' : '-1'}" aria-label="${escape(`${tier.toUpperCase()}, row ${Math.floor(i / 9) + 1}, column ${i % 9 + 1}. ${detail || 'Empty'}`)}" aria-pressed="${cell === i}" title="${escape(detail || 'Empty cell')}">${art}${label ? `<span>${escape(label)}</span>` : ''}${badges}</button>`;
}
function render() {
  if (!variants) return;
  const sprites = spriteMode();
  $('preview').disabled = !sprites;
  $('view-note').textContent = sprites
    ? `Original game artwork, composed as a static board. ${$('preview').checked ? 'Random slots show illustrative fruit from the level palette, not the game’s starting RNG.' : 'Striped pieces are the game’s authored random-color markers.'} Click any cell for exact values. Rows follow source order.`
    : 'Schematic of the extracted starting board. Select a cell to inspect all layers across three tiers. Rows follow serialized order.';
  $('legend').innerHTML = sprites
    ? '<strong>Source sprites</strong><span>Animated characters use original static illustrations</span><span>Badges retain shader, charge, color-crate and portal data</span><span class="amber">Amber outline = changed source cell</span>'
    : '<strong>Schematic</strong><span>Letters = color · ? = random · S = blocker · C = chain · H = hidden object · P = portal</span><span class="amber">Amber outline = changed cell</span>';
  $('boards').innerHTML = tiers.map(([tier, title]) => {
    const level = variants[tier];
    const delta = level.data.moves - variants.a.data.moves;
    return `<article class="board-card"><div class="card-heading"><div><span class="tier-label">${tier.toUpperCase()} / ${title}</span><h2>${level.data.moves}<small> moves</small></h2></div>${tier === 'a' ? '<span class="pill">Baseline</span>' : `<span class="pill">${delta > 0 ? '+' : ''}${delta} moves</span>`}</div><div class="board${sprites ? ' source-board' : ''}" role="group" aria-label="${title} board">${sprites ? objectMarkup(level) : ''}${Array.from({length:81}, (_, i) => tileMarkup(level, tier, i)).join('')}</div><div class="objectives">${sprites ? spriteImage(`ui_icon_objective_${current.objective === 'hiddenitem' ? 'hiddenitem_monkey' : current.objective}`, 'class="goal-icon"') : ''}<strong>${escape(GOALS[current.objective] ?? current.objective)}</strong>${goalLines(level, current.objective).map(text => `<p>${escape(text)}</p>`).join('')}</div></article>`;
  }).join('');
  const rows = [['Move budget', l => l.data.moves], ['Nonzero field cells', l => occupied(l, 'fields')],
    ['Stone / blocker cells', l => occupied(l, 'stones')], ['Chain cells', l => occupied(l, 'chains')],
    ['Crate cells', l => occupied(l, 'crates')], ['Hidden object IDs', l => distinct(l, 'hiddenItems')],
    ['Special piece cells', l => occupied(l, 'gemTypes')], ['Modified piece cells', l => occupied(l, 'gemModifier')],
    ['Portal cells', l => occupied(l, 'portals')], ['Spawn cells', l => occupied(l, 'spawning')],
    ['Changed cells · selected view', l => Array.from({length:81}, (_, i) => changedAt(variants.a, l, i, $('layer').value)).filter(Boolean).length]];
  $('comparison-table').innerHTML = '<thead><tr><th>Measure</th><th>Easy</th><th>Medium</th><th>Hard</th></tr></thead><tbody>' + rows.map(([name, fn]) => {
    const base = fn(variants.a);
    return `<tr><th>${name}</th>${tiers.map(([tier]) => `<td class="${fn(variants[tier]) !== base ? 'different' : ''}">${fn(variants[tier])}</td>`).join('')}</tr>`;
  }).join('') + '</tbody>';
  $('raw').innerHTML = tiers.map(([tier,title]) => `<div><h3>${title}</h3><p class="palette">${variants[tier].data.gems.map(g => `${escape(g.type)}: ${g.amount}`).join(' · ')}</p><details><summary>Show complete ${tier.toUpperCase()} JSON</summary><pre>${escape(JSON.stringify(variants[tier], null, 2))}</pre></details></div>`).join('');
  renderInspector();
}
function renderInspector() {
  $('cell-title').textContent = cell === null ? 'Cell inspector' : `Row ${Math.floor(cell / 9) + 1} · column ${cell % 9 + 1}`;
  $('cell-hint').textContent = cell === null ? 'Select any board cell' : `Serialized index ${cell} · same coordinate across tiers`;
  if (cell === null) { $('cell-detail').innerHTML = '<p class="muted">Click a cell to compare its piece, obstacles, routes and hidden-object values. Use arrow keys to move between cells.</p>'; return; }
  const artNotes = [...new Set(tiers.flatMap(([tier]) => cellArt(variants[tier], cell).notes))];
  const layers = new Set(tiers.flatMap(([tier]) => Object.keys(variants[tier].layout)));
  $('cell-detail').innerHTML = `<div class="table-scroll"><table><thead><tr><th>Layer</th><th>Easy</th><th>Medium</th><th>Hard</th></tr></thead><tbody>${[...layers].map(layer => `<tr><th>${escape(LAYERS[layer] ?? layer)}</th>${tiers.map(([tier]) => `<td class="${changedAt(variants.a, variants[tier], cell, layer) ? 'different' : ''}">${escape(describeValue(layer, valueAt(variants[tier], layer, cell)))}</td>`).join('')}</tr>`).join('')}</tbody></table></div>${artNotes.length ? `<p class="muted">${artNotes.map(escape).join(' ')}</p>` : ''}`;
}
function selectCell(button) {
  cell = Number(button.dataset.cell);
  document.querySelectorAll('.cell').forEach(el => {
    const selected = Number(el.dataset.cell) === cell;
    el.classList.toggle('selected', selected); el.setAttribute('aria-pressed', selected); el.tabIndex = selected ? 0 : -1;
  });
  renderInspector();
}
for (const id of ['search','chapter','family']) $(id).addEventListener(id === 'search' ? 'input' : 'change', () => updateList());
$('reset').onclick = () => { for (const id of ['search','chapter','family']) $(id).value = ''; updateList(); };
$('page-prev').onclick = () => { page--; updateList(false); $('level-list').scrollTop = 0; };
$('page-next').onclick = () => { page++; updateList(false); $('level-list').scrollTop = 0; };
$('level-list').onclick = e => { const button = e.target.closest('[data-number]'); if (button) choose(Number(button.dataset.number)); };
for (const [id, offset] of [['previous',-1],['next',1]]) $(id).onclick = () => {
  const at = filtered.findIndex(l => l.number === current?.number); if (filtered[at + offset]) choose(filtered[at + offset].number);
};
for (const id of ['layer','differences','flip','sprites','preview']) $(id).onchange = render;
$('boards').onclick = e => { const button = e.target.closest('[data-cell]'); if (button) selectCell(button); };
$('boards').onkeydown = e => {
  const button = e.target.closest('[data-cell]');
  if (!button || !['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)) return;
  e.preventDefault();
  const next = Math.max(0, Math.min(80, Number(button.dataset.display) + {ArrowLeft:-1,ArrowRight:1,ArrowUp:-9,ArrowDown:9}[e.key]));
  const target = $('boards').querySelector(`[data-tier="${button.dataset.tier}"][data-display="${next}"]`);
  selectCell(target); target.focus();
};
window.addEventListener('hashchange', () => { if (index) loadLevel(); });
try {
  [index, artwork] = await Promise.all([read('/api/index'), read('/api/art')]);
  if (!artwork.dot_red || !artwork.board_recipe) {
    $('sprites').checked = false; $('sprites').disabled = true;
    $('sprites').parentElement.title = 'Run extract_art.py to enable original sprites. See the viewer README.';
  }
  $('total').textContent = index.levels.length.toLocaleString();
  fillSelect('chapter', index.chapters.map(c => [c.chapter, `${c.chapter}. ${c.title}`]));
  fillSelect('family', Object.entries(GOALS).map(([key,label]) => [key,label]));
  fillSelect('layer', Object.entries(LAYERS));
  updateList(); await loadLevel();
} catch (error) { $('status').textContent = error.message; }
