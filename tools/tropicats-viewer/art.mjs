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

// Native BoardFactory.STANDARD_GEM_AMOUNT=25. Reduced palette membership is
// inferred from GetColorsFromConfig(skipLowAmountColors), not native execution.
export function mechanicPalette(level, reduced = false) {
  return [...new Set((level.data.gems ?? []).filter(g => g.amount >= (reduced ? 25 : 1))
    .map(g => COLORS.findIndex(c => c.toLowerCase() === g.type.toLowerCase()))
    .filter(c => [1,2,3,4,5,6,9].includes(c)))];
}
export const cannonCharge = modifier => ({7:30,8:15,9:0}[modifier] ?? 0);
export function wheelState(level, stone) {
  const colors = mechanicPalette(level, stone >= 11);
  return {colors, note:`Color wheel: ${colors.length} palette segments (${colors.map(c => COLORS[c]).join(', ')}). ` +
    `${stone >= 11 ? 'Reduced palette inferred by excluding weights below the native standard of 25. ' : ''}` +
    'Original wedges, frame and wheel LUT; clockwise color order is illustrative, not saved in the level.'};
}

export function cellArt(level, index, {preview = false, seed = 0} = {}) {
  const v = key => valueAt(level, key, index);
  const images = [], notes = [], badges = [];
  const add = (name, z, role = '', mask = null) => images.push({name, z, role, mask});
  if (!v('fields')) return {images, notes, badges};
  const color = v('gemColors') === 8 && preview ? previewColor(level, index, seed) : v('gemColors');
  const type = v('gemTypes'), modifier = v('gemModifier'), stone = v('stones');
  if (v('tiles') === 3) add('water_field', 4, 'tile');
  else if (v('tiles')) add(`tile_${v('tiles')}hp`, 4, 'tile');
  if (color || type === 10) {
    let name = color === 12 ? 'ui_icon_climber' : color === 14 ? null : `dot_${COLORS[color]?.toLowerCase()}`;
    if (type >= 6 && type <= 9) {
      if ([1,2,3,4,5,6,8,9].includes(color)) name = `dot_${COLORS[color].toLowerCase()}_${TYPES[type]}`;
      else { badges.push(`T${type}`); notes.push(`${TYPES[type]} on ${COLORS[color]}: original base illustration with exact type retained as a badge.`); }
    }
    if (type === 10) {
      name = `material_cannon_${color}_${cannonCharge(modifier)}`;
      notes.push(`Cannon: ${COLORS[color]}, charge ${cannonCharge(modifier)}/45. Original tint, face and stencil cover; gauge travel fitted to the source mask. ` +
        (v('gemDirection') ? 'Direction is preserved as source data; cannon rotation is not established.' : 'No cannon direction is encoded; the authored facing pose is preserved.'));
    }
    if (type === 11 || type === 12) {
      const palette = mechanicPalette(level, type === 12);
      const next = palette.find(c => c !== color) ?? color;
      name = `material_chameleon_${color}_${next}`;
      notes.push(`Chameleon: encoded ${COLORS[color]} body; ${COLORS[next]} next-color preview from ${type === 12 ? 'the reduced' : 'the full'} palette. ` +
        'Original skeleton and two-color LUT shader, authored Blink pose at time zero. Next-color order is illustrative. ' +
        (type === 12 ? 'Reduced palette excludes weights below 25 (inferred). ' : '') +
        'Left/right facing uses the original pose mirrored; up/down movement keeps that pose because the native view exposes only left/right scales.');
    }
    if (type >= 13 && type <= 16) name = `diagonal_gems_${TYPES[type]}`;
    if (type === 17) name = 'diagonal_gems_random';
    if (name) {
      add(name, 6, 'fruit');
      if ([11,12].includes(type) && v('gemDirection') === 1) images.at(-1).mirror = true;
    }
    if (type >= 1 && type <= 5) {
      add(`material_${type === 1 ? 'line_horizontal' : type === 2 ? 'line_vertical' : 'bomb'}`, 7, 'material-overlay', name);
      notes.push(`${TYPES[type]}: original mesh and packed shader rendered at time zero.`);
    }
    if (color === 12) notes.push('Climber: original objective illustration, static pose.');
  }
  if (modifier >= 1 && modifier <= 3) add(`iceHp${modifier}`, 10, 'cover');
  if (modifier >= 4 && modifier <= 6) add(`DirtHp${modifier - 3}`, 10, 'cover');
  if (modifier >= 7 && type !== 10) { badges.push(`Q${modifier}`); notes.push('Precharge on a non-cannon is retained as source data.'); }
  if (stone >= 1 && stone <= 5) add(`stone_${stone}hp`, 8, 'cover');
  if (stone >= 6 && stone <= 8) { add(`resistantBlocker_tutorial_${stone - 5}hp`, 8, 'cover'); notes.push('Resistant blocker: original tutorial pose at the encoded strength.'); }
  if (stone >= 9) notes.push(wheelState(level, stone).note);
  if (v('crates')) {
    const crate = v('crates'), hp = crate % 4, crateColor = Math.floor(crate / 4);
    add(crateColor ? `material_crate_${crateColor}_${hp}` : `crate_${hp}hp`, 12, 'cover');
  }
  if (v('chains')) add(`chain_${v('chains')}hp`, 11, 'cover');
  if (v('fields') === 2) add('window', 13, 'cover');
  if (v('fields') === 3) add('growing_window', 13, 'cover');
  // Odd endpoints drain from a field's bottom; even endpoints feed its top.
  // Verified against boundary placement in every campaign variant (see ART.md).
  if (v('portals')) add(v('portals') % 2 ? 'portal_entrance' : 'portal_exit', 14, 'portal');
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
      const state = wheelState(level, valueAt(level, 'stones', i)), count = state.colors.length;
      const supported = count >= 3 && count <= 6;
      const name = supported ? `material_wheel_frame_${count}` : 'ui_icon_objective_colorwheel';
      const images = supported ? [
        {name:'material_wheel_background'},
        ...state.colors.map((color, n) => ({name:`material_wheel_piece_${count}_${color}`, rotation:n*360/count})),
        {name}, {name:'material_wheel_face'},
      ] : [{name}];
      result.push({name, images, left, top, width:2, height:2, z:8,
        note: supported ? state.note : 'Unsupported segment count; original objective illustration retained.'});
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
