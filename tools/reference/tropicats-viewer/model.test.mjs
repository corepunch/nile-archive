import test from 'node:test';
import assert from 'node:assert/strict';
import {changedAt, distinct, filterLevels, goalLines, sourceIndex} from './model.mjs';

test('comparison detects layers present in only one tier, treating missing zero as empty', () => {
  const a = {layout:{fields:[1,1], stones:[0,2]}};
  const b = {layout:{fields:[1,1], stones:[0,2], chains:[0,1]}};
  assert.equal(changedAt(a,b,0),false);
  assert.equal(changedAt(a,b,1),true);
  assert.equal(changedAt(a,b,1,'stones'),false);
  assert.equal(changedAt(b,a,1),true);
});
test('row flip preserves the serialized coordinate and is reversible', () => {
  assert.equal(sourceIndex(0,true),72);
  assert.equal(sourceIndex(8,true),80);
  for (let i=0;i<81;i++) assert.equal(sourceIndex(sourceIndex(i,true),true),i);
});
test('hidden objects are counted by nonzero ID, not covered cells', () => {
  const level = {data:{objectives:[]},layout:{hiddenItems:[0,1,1,1,2,2,7]}};
  assert.equal(distinct(level,'hiddenItems'),3);
  assert.deepEqual(goalLines(level,'hiddenitem'),['3 hidden object IDs in layout']);
  assert.match(goalLines(level,'water')[0],/defined by board layers/);
});
test('explicit targets remain visible and treasure counts are initial cells only', () => {
  const level = {data:{objectives:[{type:'red',amount:100}]},layout:{gemColors:[13,13,1]}};
  assert.deepEqual(goalLines(level,'treasure'),['red × 100','2 initial treasure cells']);
});
test('chapter, objective and case-insensitive quest search intersect', () => {
  const levels = [
    {number:1,chapter:1,objective:'climber',quest:{title:'Great Totem',quest:'chp1_q1'}},
    {number:6,chapter:2,objective:'hiddenitem',quest:{title:'Home',quest:'chp2_q1'}},
  ];
  assert.equal(filterLevels(levels,' TOTEM ','1','climber')[0].number,1);
  assert.equal(filterLevels(levels,'totem','2','').length,0);
  assert.equal(filterLevels(levels,'6','','hiddenitem')[0].number,6);
  assert.equal(filterLevels(levels,'no match','','').length,0);
});
