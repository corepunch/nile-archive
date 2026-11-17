// Enum values checked against field defaults in this app's IL2CPP v31 metadata.
export const COLORS = ['Undefined', 'Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange',
  'Droppable', 'Random', 'Coins', 'Cannonball', 'Rainbow', 'Climber', 'Treasure', 'Dirt', 'Colorless'];
export const TYPES = ['Undefined', 'LineHorizontal', 'LineVertical', 'Bomb', 'ActivatedBomb',
  'ActivatedSuperBomb', 'ClimberGem', 'StackedGemSmall', 'StackedGemMedium', 'StackedGemBig',
  'Cannon', 'Chameleon', 'ChameleonReduced', 'DiagonalDownRight', 'DiagonalDownLeft',
  'DiagonalUpLeft', 'DiagonalUpRight', 'DiagonalRandom'];
export const DIRECTIONS = ['Undefined','Left','Up','Right','Down'];
export const MODIFIERS = ['Undefined', 'IceHp1', 'IceHp2', 'IceHp3', 'DirtHp1', 'DirtHp2',
  'DirtHp3', 'PreChargedMuch', 'PreChargedMedium', 'PreChargedLittle'];
export const GOALS = {climber:'Rescue climbers', droppable:'Turtles', hiddenitem:'Hidden statues',
  recipe:'Recipe', treasure:'Treasure', water:'Water', resistant_blocker:'Resistant blockers', chameleon:'Chameleons'};
export const LAYERS = {fields:'Field mask', gemColors:'Piece colors', gemTypes:'Special pieces',
  gemModifier:'Piece modifiers', gemDirection:'Piece direction', tiles:'Tiles / water', stones:'Stones / blockers',
  chains:'Chains', crates:'Crates', hiddenItems:'Hidden objects', spawning:'Spawners',
  dropItems:'Drop routes', climbers:'Climber routes', portals:'Portals'};
export const valueAt = (level, layer, index) => level.layout[layer]?.[index] ?? 0;
export const occupied = (level, layer) => (level.layout[layer] ?? []).filter(v => v !== 0).length;
export const distinct = (level, layer) => new Set((level.layout[layer] ?? []).filter(v => v !== 0)).size;
export function changedAt(a, b, index, layer = 'combined') {
  const layers = layer === 'combined' ? new Set([...Object.keys(a.layout), ...Object.keys(b.layout)]) : [layer];
  return [...layers].some(key => valueAt(a, key, index) !== valueAt(b, key, index));
}
export function sourceIndex(displayIndex, flip) {
  return flip ? (8 - Math.floor(displayIndex / 9)) * 9 + displayIndex % 9 : displayIndex;
}
export function describeValue(layer, value) {
  if (layer === 'portals' && value) return `${value} · ${value % 2 ? 'Entrance' : 'Exit'} · pair ${Math.ceil(value / 2)}`;
  if (layer === 'crates' && value) return `${value} · ${value < 4 ? 'Wood' : COLORS[Math.floor(value / 4)] || 'Unknown'} · ${value % 4} HP`;
  const names = {gemColors:COLORS, gemTypes:TYPES, gemModifier:MODIFIERS, gemDirection:DIRECTIONS,
    spawning:['None','Normal spawn','Defined gem','Chameleon spawn']};
  return names[layer]?.[value] ? `${value} · ${names[layer][value]}` : String(value);
}
export function goalLines(level, family) {
  const explicit = (level.data.objectives ?? []).map(o => `${GOALS[o.type] ?? o.type} × ${o.amount}`);
  if (family === 'hiddenitem') explicit.push(`${distinct(level, 'hiddenItems')} hidden object IDs in layout`);
  if (family === 'treasure') explicit.push(`${(level.layout.gemColors ?? []).filter(v => v === 13).length} initial treasure cells`);
  return explicit.length ? explicit : ['Target is defined by board layers; inspect the layer values below.'];
}
export function filterLevels(levels, query, chapter, family) {
  const q = query.trim().toLowerCase();
  return levels.filter(l => (!chapter || String(l.chapter) === chapter) && (!family || l.objective === family) &&
    (!q || `${l.number} ${GOALS[l.objective]} ${l.quest?.title ?? ''} ${l.quest?.quest ?? ''}`.toLowerCase().includes(q)));
}
