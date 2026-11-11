import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {cellArt, previewColor, boardObjects, mechanicPalette, cannonCharge, boardTexture} from './art.mjs';
import {changedAt, describeValue} from './model.mjs';
const level = overrides => ({data:{gems:[{type:'red',amount:10},{type:'blue',amount:10},{type:'green',amount:0}]},
  layout:{fields:[1],gemColors:[8],...overrides}});

test('preview uses allowed palette, stays deterministic and does not change source comparisons', () => {
  const l = level({}), before = structuredClone(l);
  const colors = new Set(Array.from({length:81},(_,i) => previewColor(l,i,8)));
  assert.deepEqual(colors, new Set([1,3]));
  assert.deepEqual(cellArt(l,0,{preview:true,seed:8}),cellArt(before,0,{preview:true,seed:8}));
  assert.equal(cellArt(l,0).images[0].name,'dot_random');
  assert.deepEqual(l,before); assert.equal(changedAt(l,before,0),false);
  assert.equal(previewColor({data:{gems:[]}},0,8),8);
});

test('layer order keeps leaves behind fruit and chains above ice; void fields stay empty', () => {
  const l=level({gemColors:[1],tiles:[2],gemModifier:[3],chains:[2]});
  const names=cellArt(l,0).images.sort((a,b)=>a.z-b.z).map(a=>a.name);
  assert.deepEqual(names,['tile_2hp','dot_red','iceHp3','chain_2hp']);
  l.layout.fields[0]=0; assert.equal(cellArt(l,0).images.length,0);
});

test('one sprite per hidden object or wheel, including row flipping', () => {
  const l=level({hiddenItems:[5,5,0,0,0,0,0,0,0,5,5],stones:[0,0,9,10,0,0,0,0,0,0,0,10,10]});
  const objects=boardObjects(l); assert.equal(objects.length,2);
  for(const o of objects) {assert.equal(o.width,2);assert.equal(o.height,2);assert.equal(o.top,0);}
  for(const o of boardObjects(l,true)) assert.equal(o.top,7);
});

test('non-fruit stacked pieces retain the original base image and disclose unmatched state', () => {
  const result=cellArt(level({gemColors:[7],gemTypes:[7]}),0);
  assert.equal(result.images[0].name,'dot_droppable');
  assert.deepEqual(result.badges,['T7']); assert.ok(result.notes.length);
});

test('bomb and both line axes use original material overlays, under ice and crates', () => {
  for (const [type, name] of [[1,'line_horizontal'],[2,'line_vertical'],[3,'bomb']]) {
    const result=cellArt(level({gemColors:[1],gemTypes:[type],gemModifier:[2],crates:[7]}),0);
    const overlay=result.images.find(i=>i.role==='material-overlay');
    assert.equal(overlay.name,`material_${name}`); assert.equal(overlay.mask,'dot_red');
    assert.ok(overlay.z<result.images.find(i=>i.name==='iceHp2').z);
    assert.ok(overlay.z<result.images.find(i=>i.name==='material_crate_1_3').z);
    assert.deepEqual(result.badges,[]);
  }
});

test('crate encoding keeps color and strength; portal pairs retain exact IDs in inspection', () => {
  for(const color of [1,2,3,4,5,6,9]) for(const hp of [1,2,3]) {
    const result=cellArt(level({crates:[color*4+hp]}),0);
    assert.ok(result.images.some(i=>i.name===`material_crate_${color}_${hp}`));
    assert.deepEqual(result.badges,[]);
  }
  for(const [id,name] of [[1,'entrance'],[2,'exit'],[17,'entrance'],[18,'exit']]) {
    const result=cellArt(level({portals:[id]}),0);
    assert.ok(result.images.some(i=>i.name===`portal_${name}`)); assert.deepEqual(result.badges,[]);
  }
  assert.equal(describeValue('portals',18),'18 · Exit · pair 9');
  assert.equal(describeValue('crates',39),'39 · Coins · 3 HP');
});

test('native cannon charges replace badges, including undefined-color cannons', () => {
  for (const [modifier,charge] of [[7,30],[8,15],[9,0]]) {
    assert.equal(cannonCharge(modifier),charge);
    const result=cellArt(level({gemTypes:[10],gemColors:[5],gemModifier:[modifier]}),0);
    assert.equal(result.images[0].name,`material_cannon_5_${charge}`);
    assert.deepEqual(result.badges,[]);
    assert.ok(result.notes[0].includes(`${charge}/45`));
    assert.ok(result.notes[0].includes('No cannon direction'));
  }
  assert.equal(cellArt(level({gemTypes:[10],gemColors:[0],gemModifier:[9]}),0).images[0].name,'material_cannon_0_0');
});

test('chameleon keeps encoded body color, previews next palette color and mirrors left facing', () => {
  const l=level({gemTypes:[12],gemColors:[1],gemDirection:[1]});
  l.data.gems=[{type:'red',amount:25},{type:'green',amount:8},{type:'coins',amount:25}];
  const before=structuredClone(l), reduced=cellArt(l,0);
  assert.equal(reduced.images[0].name,'material_chameleon_1_9');
  assert.equal(reduced.images[0].mirror,true);
  assert.ok(reduced.notes[0].includes('illustrative'));
  assert.deepEqual(l,before);
  l.layout.gemTypes[0]=11;l.layout.gemDirection[0]=3;
  assert.equal(cellArt(l,0).images[0].name,'material_chameleon_1_2');
  assert.ok(!cellArt(l,0).images[0].mirror);
  for(const [value,name] of [[1,'Left'],[2,'Up'],[3,'Right'],[4,'Down']])
    assert.equal(describeValue('gemDirection',value),`${value} · ${name}`);
});

test('wheel uses native wedges for the tier palette, including coins and reduced colors', () => {
  const l=level({stones:[11,12,0,0,0,0,0,0,0,12,12]});
  l.data.gems=[{type:'red',amount:25},{type:'green',amount:8},{type:'coins',amount:25},{type:'blue',amount:25},{type:'yellow',amount:25}];
  assert.deepEqual(mechanicPalette(l,true),[1,9,3,4]);
  const wheel=boardObjects(l)[0];
  assert.equal(wheel.name,'material_wheel_frame_4');
  assert.deepEqual(wheel.images.filter(i=>i.rotation!==undefined).map(i=>i.rotation),[0,90,180,270]);
  assert.ok(wheel.images.some(i=>i.name==='material_wheel_piece_4_9'));
  assert.equal(boardObjects(l,true)[0].top,7);
  l.layout.stones[0]=9;
  assert.equal(boardObjects(l)[0].name,'material_wheel_frame_5');
});

const root=new URL('../../reference/tropicats-analysis/',import.meta.url);
const available=fs.existsSync(new URL('art/sprites.json',root));
test('all 8,190 campaign variants resolve artwork and keep wheels inside the board', {skip:!available}, () => {
  const art=JSON.parse(fs.readFileSync(new URL('art/sprites.json',root)));
  const files=fs.readdirSync(new URL('levels/',root)).filter(n=>/^\d{4}[abc]$/.test(n));
  assert.equal(files.length,8190);
  for(const file of files) {
    const l=JSON.parse(fs.readFileSync(new URL('levels/'+file,root)));
    for(let i=0;i<81;i++) for(const preview of [false,true]) {
      for(const item of cellArt(l,i,{preview,seed:parseInt(file)}).images)
        assert.ok(art[item.name],`${file}:${i} missing ${item.name}`);
    }
    // Parity is grounded in every serialized endpoint's open boundary.
    for(let i=0;i<81;i++) {
      const id=l.layout.portals?.[i];
      if(!id) continue;
      const neighbor=i+(id%2 ? 9 : -9);
      assert.ok(neighbor<0 || neighbor>=81 || !l.layout.fields[neighbor], `${file}:${i} portal edge`);
      assert.ok(l.layout.portals.includes(id%2 ? id+1 : id-1), `${file}:${i} portal pair`);
    }
    for(const o of boardObjects(l)) {
      assert.ok(art[o.name]);
      for(const image of o.images ?? []) assert.ok(art[image.name],`${file} missing ${image.name}`);
      if ([9,11].some(stone=>l.layout.stones.includes(stone))) assert.ok(!o.name.includes('objective_colorwheel'),`${file} unsupported wheel`);
      assert.ok(o.left>=0 && o.top>=0 && o.left+o.width<=9 && o.top+o.height<=9,file);
    }
  }
});


test('vertical same-type windows connect once and follow row flips', () => {
  const l=level({fields:[2,3,0,0,0,0,0,0,0,2,3]});
  const bridges=boardObjects(l).filter(o=>o.name.includes('bridge'));
  assert.deepEqual(bridges.map(o=>[o.name,o.left,o.top]),[['window_bridge',0,.5],['growing_window_bridge_01',1,.5]]);
  assert.deepEqual(boardObjects(l,true).filter(o=>o.name.includes('bridge')).map(o=>o.top),[7.5,7.5]);
  l.layout.fields[9]=3;
  assert.equal(boardObjects(l).filter(o=>o.name==='window_bridge').length,0);
});


test('objective board textures use original theme references with an explicit fallback', () => {
  for (const [goal,texture] of Object.entries({treasure:'board_DirtAndTreasure',water:'board_water',
    hiddenitem:'board_hiddenitem',droppable:'board_drop',chameleon:'board_water',resistant_blocker:'board_water',
    climber:'board_recipe',recipe:'board_recipe'})) assert.equal(boardTexture(goal),texture);
});


test('climber and resistant strength use original native idle poses', () => {
  const climber=cellArt(level({gemColors:[12]}),0);
  assert.equal(climber.images[0].name,'material_climber');
  for (const stone of [6,7,8]) {
    const result=cellArt(level({stones:[stone]}),0);
    assert.ok(result.images.some(i=>i.name===`material_resistant_${stone-5}`));
    assert.ok(result.notes.some(note=>note.includes('time zero')));
  }
});
