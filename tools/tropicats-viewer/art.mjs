// Source-name mapping and static composition. Evidence/limitations: ART.md.
import {COLORS, TYPES, valueAt, sourceIndex} from './model.mjs';

export function previewColor(level, index, seed) {
  const palette = (level.data.gems ?? []).filter(g => g.amount > 0)
    .map(g => COLORS.findIndex(c => c.toLowerCase() === g.type.toLowerCase()))
    .filter(c => c >= 1 && c <= 6);
  if (!palette.length) return 8;
  // Same source coordinate and level seed across tiers; no gameplay/RNG claim.
  let hash = Math.imul(index + 1, 0x45d9f3b) ^ Math.imul(seed + 1, 0x27d4eb2d);
  hash = Math.imul(hash ^ (hash >>> 16), 0x45d9f3b);
  return palette[((hash ^ (hash >>> 16)) >>> 0) % palette.length];
}

export function cellArt(level, index, {preview = false, seed = 0} = {}) {
  const v = key => valueAt(level, key, index);
  const images = [], notes = [], badges = [];
  const add = (name, z, role = '') => images.push({name, z, role});
  if (!v('fields')) return {images, notes, badges};
  const color = v('gemColors') === 8 && preview ? previewColor(level, index, seed) : v('gemColors');
  const type = v('gemTypes'), modifier = v('gemModifier'), stone = v('stones');
  if (v('tiles') === 3) add('water_field', 4, 'tile');
  else if (v('tiles')) add(`tile_${v('tiles')}hp`, 4, 'tile');
  if (color) {
    let name = color === 12 ? 'ui_icon_climber' : color === 14 ? null : `dot_${COLORS[color]?.toLowerCase()}`;
    if (type >= 6 && type <= 9) {
      if ([1,2,3,4,5,6,8,9].includes(color)) name = `dot_${COLORS[color].toLowerCase()}_${TYPES[type]}`;
      else { badges.push(`T${type}`); notes.push(`${TYPES[type]} on ${COLORS[color]}: original base illustration with exact type retained as a badge.`); }
    }
    if (type === 10) { name = 'cannon_tutorial'; notes.push('Cannon: original static tutorial pose; orientation/charge are in the inspector.'); }
    if (type === 11 || type === 12) { name = 'chameleon_1_tutorial'; notes.push('Chameleon: original static illustration; reduced/color state is in the inspector.'); }
    if (type >= 13 && type <= 16) name = `diagonal_gems_${TYPES[type]}`;
    if (type === 17) name = 'diagonal_gems_random';
    if (name) add(name, 6, 'fruit');
    if (type >= 1 && type <= 5) {
      badges.push(['','↔','↕','B','AB','SB'][type]);
      notes.push(`${TYPES[type]}: shader overlay is represented by a data badge.`);
    }
    if (color === 12) notes.push('Climber: original objective illustration, static pose.');
  }
  if (modifier >= 1 && modifier <= 3) add(`iceHp${modifier}`, 10, 'cover');
  if (modifier >= 4 && modifier <= 6) add(`DirtHp${modifier - 3}`, 10, 'cover');
  if (modifier >= 7) { badges.push(`Q${modifier}`); notes.push('Precharge is a data badge; shader fill is not simulated.'); }
  if (stone >= 1 && stone <= 5) add(`stone_${stone}hp`, 8, 'cover');
  if (stone >= 6 && stone <= 8) { add(`resistantBlocker_tutorial_${stone - 5}hp`, 8, 'cover'); notes.push('Resistant blocker: original tutorial pose at the encoded strength.'); }
  if (stone >= 9) notes.push('Color wheel: original objective illustration, not its runtime segment configuration.');
  if (v('crates')) {
    const crate = v('crates'), hp = crate % 4;
    add(`crate_${crate > 3 ? 'tintable_' : ''}${hp}hp`, 12, 'cover');
    if (crate > 3) { badges.push(`C${crate}`); notes.push('Color crate: original neutral frame; encoded color/strength remains in the inspector.'); }
  }
  if (v('chains')) add(`chain_${v('chains')}hp`, 11, 'cover');
  if (v('fields') === 2) add('window', 13, 'cover');
  if (v('fields') === 3) add('growing_window', 13, 'cover');
  // Portal end numbering is left as data until entrance/exit semantics are verified.
  if (v('portals')) { badges.push(`P${v('portals')}`); notes.push('Portal endpoint ID; entrance/exit direction is not reconstructed.'); }
  return {images, notes, badges};
}

export function boardObjects(level, flip = false) {
  const result = [], hidden = new Map();
  for (let i = 0; i < 81; i++) {
    const id = valueAt(level, 'hiddenItems', i);
    if (id) { if (!hidden.has(id)) hidden.set(id, []); hidden.get(id).push(sourceIndex(i, flip)); }
    if ([9,11].includes(valueAt(level, 'stones', i))) {
      // Corner marker + three occupancy markers define a 2×2 wheel in serialized order.
      const neighbors = [i, i+1, i+9, i+10].map(n => sourceIndex(n, flip));
      const left = Math.min(...neighbors.map(n => n % 9)), top = Math.min(...neighbors.map(n => Math.floor(n / 9)));
      result.push({name:'ui_icon_objective_colorwheel', left, top, width:2, height:2, z:8,
        note:'Color wheel: original objective illustration, not its runtime segment configuration.'});
    }
  }
  for (const [id, cells] of hidden) {
    const xs = cells.map(i => i % 9), ys = cells.map(i => Math.floor(i / 9));
    const left = Math.min(...xs), top = Math.min(...ys);
    result.push({name:'hiddenItem', left, top, width:Math.max(...xs)-left+1, height:Math.max(...ys)-top+1, z:2,
      note:`Hidden statue ${id}; one sprite spans its serialized footprint.`});
  }
  return result;
}
