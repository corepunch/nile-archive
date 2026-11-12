const $ = (selector) => document.querySelector(selector);
const svgNS = 'http://www.w3.org/2000/svg';
const sceneBase = '/assets/scene-001-01/';
const cluesBase = '/assets/clues/';
const state = { data: null, selected: null, regions: new Map() };

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function imageUrl(base, filename) {
  return base + encodeURIComponent(filename);
}

function displayName(object) {
  return object.label || object.name.replaceAll('_', ' ');
}

function objectImage(object) {
  const layer = (object.layers || []).find((item) => item.kind === 'item');
  return layer ? layer.image : null;
}

function renderLayers() {
  const layerRoot = $('#sprite-layer');
  const layers = state.data.objects
    .filter((object) => object.name !== 'clue_placeholder')
    .flatMap((object) => object.layers || []);
  layers.sort((a, b) => a.order - b.order);
  for (const layer of layers) {
    const image = element('img', 'scene-sprite');
    image.src = imageUrl(sceneBase, layer.image);
    image.alt = '';
    image.draggable = false;
    image.style.left = `${layer.x * 100}%`;
    image.style.top = `${layer.y * 100}%`;
    image.style.width = `${layer.width * 100}%`;
    image.style.height = `${layer.height * 100}%`;
    layerRoot.append(image);
  }
}

function selectObject(object, focusScene = false) {
  state.selected = object.id;
  for (const [id, regions] of state.regions) {
    for (const region of regions) region.classList.toggle('active', id === object.id);
  }
  renderObjectList();
  renderDetail(object);
  if (focusScene) {
    $('.inspect-panel').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
}

function renderRegions() {
  const root = $('#regions');
  for (const object of state.data.objects) {
    const polygons = object.polygons || (object.polygon ? [object.polygon] : []);
    const regions = [];
    for (const points of polygons) {
      if (!points || points.length < 3) continue;
      const polygon = document.createElementNS(svgNS, 'polygon');
      polygon.setAttribute('points', points.map(([x, y]) => `${x * 1000},${y * 1000}`).join(' '));
      polygon.setAttribute('tabindex', '0');
      polygon.setAttribute('role', 'button');
      polygon.setAttribute('aria-label', `Inspect ${displayName(object)}`);
      const title = document.createElementNS(svgNS, 'title');
      title.textContent = displayName(object);
      polygon.append(title);
      polygon.addEventListener('click', () => selectObject(object));
      polygon.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          selectObject(object);
        }
      });
      root.append(polygon);
      regions.push(polygon);
    }
    state.regions.set(object.id, regions);
  }
}

function renderDetail(object) {
  $('#detail-title').textContent = displayName(object);
  const detail = $('#detail');
  detail.classList.remove('empty');
  detail.replaceChildren();
  const artwork = objectImage(object);
  if (artwork) {
    const preview = element('div', 'art-preview');
    const image = element('img');
    image.src = imageUrl(sceneBase, artwork);
    image.alt = `${displayName(object)} extracted artwork`;
    preview.append(image);
    detail.append(preview);
  }
  const fields = [
    ['Source name', object.name],
    ['Difficulty', object.difficulty === null || object.difficulty === undefined ? 'Not specified' : String(object.difficulty)],
    ['Scene regions', String((object.polygons || (object.polygon ? [object.polygon] : [])).length)],
  ];
  const list = element('dl');
  for (const [label, value] of fields) {
    const row = element('div');
    row.append(element('dt', '', label), element('dd', '', value));
    list.append(row);
  }
  detail.append(list, element('p', 'note', object.name.startsWith('clue_')
    ? 'This is a clue-prefixed scene object. The extracted data does not connect it to a numbered clue.'
    : 'This is an authored scene object. The effect of its difficulty value on gameplay is unknown.'));
}

function renderObjectList() {
  const query = $('#search').value.trim().toLocaleLowerCase();
  const difficulty = $('#difficulty').value;
  const items = state.data.objects.filter((object) => {
    const matchesQuery = displayName(object).toLocaleLowerCase().includes(query) || object.name.toLocaleLowerCase().includes(query);
    return matchesQuery && (difficulty === '' || String(object.difficulty) === difficulty);
  });
  items.sort((a, b) => displayName(a).localeCompare(displayName(b)));
  $('#object-count').textContent = `${items.length} of ${state.data.objects.length} objects`;
  $('#no-results').hidden = items.length > 0;
  const list = $('#object-list');
  list.replaceChildren();
  for (const object of items) {
    const card = element('button', 'object-card');
    card.type = 'button';
    card.classList.toggle('active', object.id === state.selected);
    card.setAttribute('aria-pressed', object.id === state.selected ? 'true' : 'false');
    const artwork = objectImage(object);
    if (artwork) {
      const image = element('img');
      image.src = imageUrl(sceneBase, artwork);
      image.alt = '';
      image.loading = 'lazy';
      card.append(image);
    }
    card.append(element('span', '', displayName(object)));
    card.addEventListener('click', () => selectObject(object, true));
    list.append(card);
  }
}

function renderClues() {
  const list = $('#clue-list');
  for (const clue of state.data.clues) {
    const card = element('button', 'clue-card');
    card.type = 'button';
    const frame = element('div', 'clue-image');
    const image = element('img');
    image.src = imageUrl(cluesBase, clue.image);
    image.alt = clue.label;
    image.loading = 'lazy';
    frame.append(image);
    const context = clue.scene === 1 ? 'SCENE 01 · BUNDLED ART' : `SCENE ${String(clue.scene).padStart(2, '0')} · BUNDLED ART`;
    card.append(frame, element('small', '', context), element('strong', '', clue.label));
    card.addEventListener('click', () => {
      $('#clue-dialog-title').textContent = clue.label;
      $('#clue-dialog-context').textContent = context;
      $('#clue-dialog-image').src = imageUrl(cluesBase, clue.image);
      $('#clue-dialog-image').alt = clue.label;
      $('#clue-dialog-note').textContent = clue.scene === 1
        ? 'The scene 1 staging does not link its numbered clues to this artwork.'
        : `Chapter dialogue staging places this artwork with scene ${clue.scene}, clue ${clue.clue}. The corresponding dialogue text is unavailable.`;
      $('#clue-dialog').showModal();
    });
    list.append(card);
  }
}

async function main() {
  const response = await fetch('/api/scene');
  if (!response.ok) throw new Error(`Unable to load the extracted scene (${response.status}).`);
  state.data = await response.json();
  if (!Array.isArray(state.data.objects) || !Array.isArray(state.data.clues)) {
    throw new Error('The scene data is missing objects or clues.');
  }
  $('#background').src = imageUrl(sceneBase, state.data.background || 'background.png');
  renderLayers();
  renderRegions();
  renderObjectList();
  renderClues();
  for (const line of state.data.openingDialogue || []) {
    const row = element('div', 'dialogue-line');
    row.append(element('strong', '', line.speaker), element('span', '', line.text));
    $('#dialogue-list').append(row);
  }
  $('#close-clue').addEventListener('click', () => $('#clue-dialog').close());
  $('#search').addEventListener('input', renderObjectList);
  $('#difficulty').addEventListener('change', renderObjectList);
  $('#show-regions').addEventListener('change', (event) => {
    $('#regions').classList.toggle('hidden-regions', !event.target.checked);
  });
  $('#status').hidden = true;
  $('#content').hidden = false;
}

main().catch((error) => {
  const status = $('#status');
  status.className = 'status error';
  status.textContent = `Could not open the scene. ${error.message}`;
});
