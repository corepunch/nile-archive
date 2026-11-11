import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {cellArt, previewColor, boardObjects} from './art.mjs';
import {changedAt} from './model.mjs';
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
    for(const o of boardObjects(l)) {
      assert.ok(art[o.name]); assert.ok(o.left>=0 && o.top>=0 && o.left+o.width<=9 && o.top+o.height<=9,file);
    }
  }
});
