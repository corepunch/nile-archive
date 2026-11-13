#!/usr/bin/env python3
"""Compile representative source boards directly from the original archive.
Square source (x,y) becomes axial (x-cx,cy-y); no models/goals are discarded.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools/homescapes-reference'))
from extract_archives import Zstd, read_archive
from story_index import SOURCE

SELECTED = ['base/st/'+x+'.xml' for x in ['st0001','st0037','st0051','st0065','st0161','st0162','st0255','st0401']] + [
    'packs/contest/'+x+'.xml' for x in ['contest_005_06','contest_026_01','contest_172_04','contest_011_15']]
OUT = ROOT/'engine/match3_reference.lua'


def lua(value):
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, (int, float)): return str(value)
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list): return '{'+','.join(lua(x) for x in value)+'}'
    return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'


def convert(data, path):
    level = ET.fromstring(data).find('Level')
    cells = list(level.iter('Cell'))
    points = [(int(c.get('x')), int(c.get('y'))) for c in cells]
    cx = (min(x for x,y in points)+max(x for x,y in points))//2
    cy = (min(y for x,y in points)+max(y for x,y in points))//2
    radius = max(max(abs(x-cx), abs(cy-y), abs(x-cx+cy-y)) for x,y in points)
    assert 1 <= radius <= 16
    axial = [(q,r) for q in range(-radius,radius+1) for r in range(max(-radius,-q-radius),min(radius,-q+radius)+1)]
    ids = {p:i for i,p in enumerate(axial)}
    def cellid(x,y): return ids[(int(x)-cx,cy-int(y))]
    spec = {'cells':{},'goals':[], 'colors':{}, 'randomPatterns':[], 'bornPatterns':[], 'colorPatterns':[], 'colorSets':{}, 'refill':[]}
    for c in cells:
        models = []
        for model in c:
            attrs = dict(model.attrib)
            if 'mainX' in attrs: attrs['mainCell'] = cellid(attrs['mainX'],attrs['mainY'])
            models.append(attrs)
        spec['cells'][cellid(c.get('x'),c.get('y'))] = {'models':models}
    for c in level.findall('ChipSet/chip'):
        if int(c.get('probability'))>0: spec['colors'][int(c.get('number'))] = int(c.get('probability'))
    if not spec['colors']: spec['colors'] = dict.fromkeys(range(5),100)
    for t in level.findall('Targets/target'):
        spec['goals'].append({'type':t.get('type'),'subtype':t.get('subtype',''),'current':int(t.get('current','0')),'max':int(t.get('max'))})
    spec['randomPatterns'] = [[int(c.get('id')) for c in p] for p in level.findall('RandomChips/pattern')]
    for p in level.findall('BornPatterns/pattern'):
        record = dict(p.attrib)
        record['settings'] = [[dict(prop.attrib) for prop in unit] for unit in p.findall('settings/*')]
        spec['bornPatterns'].append(record)
    spec['colorPatterns'] = [p.get('str') for p in level.findall('ColorChipsPattern/pattern')]
    for c in level.findall('colorSets/colorSet'):
        spec['colorSets'][c.get('name')] = [dict(enumerate(map(int,s.get('val').split(',')))) for s in c]
    for section,goal,element in [('CarryChips','CARRY',None),('TrashChips','TRASH','cookie'),('TrashStoneChips','TRASHSTONE','hazelnut')]:
        node = level.find(section)
        if node is None: continue
        a = dict(node.attrib)
        for p in level.findall('Targets/target'):
            if p.get('type')==goal:
                for param in p:
                    key = {'chance_born':'chance','max_on_field':'max'}.get(param.get('name'))
                    if key: a[key] = param.get('value')
        initial = sum(m.get('modelId')=='CARRY' for c in cells for m in c)
        rule = {'goal':goal,'chance':int(a.get('chance',100 if goal=='CARRY' else 0)),
                'max':int(a.get('max',max(1,initial) if goal=='CARRY' else 0)),
                'hp':int(a.get('level','1')),'limited':a.get('gen_limitation')=='true'}
        if element: rule['element'] = element
        if len(node): rule['sources'] = {cellid(p.get('x'),p.get('y')):True for p in node if p.tag=='b'}
        spec['refill'].append(rule)
    return {'radius':radius,'source':path,'sha256':hashlib.sha256(data).hexdigest(),
            'seed':int(level.get('LevelLocalSeed','0')),
            'level':{'name':Path(path).stem,'lesson':'Homescapes source board on hexes','moves':int(level.get('movesLimitLocal')),
                     'score':0,'relics':0,'soil':0,'chains':0,'ice':0,
                     'mask':''.join('1' if i in spec['cells'] else '0' for i in range(len(axial))), 'homescapes':spec}}


def generate():
    with ZipFile(SOURCE) as bundle: packed = bundle.read('base_mm/fs_archives/match3levels.zstd')
    codec = Zstd()
    try:
        dictionary,entries = read_archive(packed,codec)
        records = {}
        for path,blob,size in entries:
            name = str(path).split('Match3/Levels/')[-1]
            if name in SELECTED: records[Path(name).stem] = convert(codec.unpack(blob,size,dictionary),name)
    finally: codec.close()
    assert len(records)==len(SELECTED), sorted(records)
    return '-- Generated by tools/homescapes_hex.py from original base.zip; do not edit.\nreturn '+lua(dict(sorted(records.items())))+'\n'

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    content=generate()
    if args.check:
        assert OUT.read_text()==content, 'source reference pack is stale'
    else: OUT.write_text(content)
    print(('Verified %d source boards against original archive' if args.check else 'Compiled %d source boards') % len(SELECTED))
