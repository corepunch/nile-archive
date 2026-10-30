#!/usr/bin/env python3
"""One-time source migration; normal builds only use committed Lua + PNG assets.
Usage: python3 games/volcano/tools/import_episode.py [source-folder]
Defaults to games/volcano/source, preserved locally with the authored levels.
Requires Pillow. Repackages existing artwork without inventing visual states.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET
from PIL import Image

DEST = Path(__file__).resolve().parents[1]

def lua(v):
    if isinstance(v, dict): return '{' + ','.join('['+json.dumps(str(k))+']='+lua(x) for k,x in v.items()) + '}'
    if isinstance(v, (list, tuple)): return '{'+','.join(map(lua,v))+'}'
    if isinstance(v, str): return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool): return str(v).lower()
    if v is None: return 'nil'
    return str(round(v, 6) if isinstance(v,float) else v)

def main():
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('source',type=Path,nargs='?',default=DEST/'source'); args=parser.parse_args()
    src=args.source.resolve(); data=DEST/'data'; code=DEST/'lua'
    entries={}; originals={}; catalog=[]
    def record(path, purpose, origin='volcano-original'):
        rel=str(path.relative_to(src))
        if rel not in originals:
            originals[rel]=dict(source=rel,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),origin=origin,purpose=purpose)
    def anim(name, frames, fps, scale, origin, sources):
        entries[name]=dict(frames=frames,fps=fps,scale=scale,origin=origin)
        for p in sources: record(p,name,origin)
    # Episode-specific props, including independently authored damaged/repaired states.
    decl=src/'assets/volcano-episode/sprites.xml'; root=ET.parse(decl).getroot(); image=src/'assets/volcano-episode'/root.get('image'); sheet=Image.open(image).convert('RGBA')
    for n in root:
        x,y,w,h=map(int,n.get('rect').split(',')); px,py=map(float,n.get('pivot').split(','))
        anim(n.get('name'),[(sheet.crop((x,y,x+w,y+h)),[px,py])],0,float(n.get('scale')), 'volcano-original',[decl,image])
    # Existing HD substitutes replace the retail headquarters and broken road.
    manifest=src/'assets/hd-static/atlas.json'; static=json.loads(manifest.read_text())
    for source_name,name,width in [('base0','hq',123),('broken_road0','road',49)]:
        e=next(x for x in static['frames'] if x['animation']==source_name and x['frame']==0)
        path=manifest.parent/e['sheet']; crop=Image.open(path).convert('RGBA').crop(e['region']); l,t,r,b=e['region']
        pivot=e.get('pivot',[(l+r)/2,(t+b)/2]); pivot=[(pivot[0]-l)/(r-l),(pivot[1]-t)/(b-t)]
        anim(name,[(crop,pivot)],0,width/crop.width,'volcano-original',[manifest,path])
    # Trimmed 8-direction Kenney animations. Repeat records preserve source timing.
    decl=src/'assets/kenney-characters/sprites/kenney.sprites.xml'; root=ET.parse(decl).getroot(); cache={}
    wanted={'worker_wait0','man_idle0','wman_idle0'}
    for d in range(8):
        wanted.update(f'worker_{a}{d}' for a in ['run','wood','pick','repair','srepair','pet'])
        wanted.update([f'man_run{d}',f'wman_run{d}'])
    for e in root:
        if e.get('name') not in wanted: continue
        path=decl.parent/e.get('image')
        if path not in cache: cache[path]=Image.open(path).convert('RGBA')
        frames=[]
        for f in e:
            x,y,w,h=map(int,f.get('rect').split(',')); pivot=list(map(float,f.get('pivot').split(',')))
            frames.extend([(cache[path].crop((x,y,x+w,y+h)),pivot)]*int(f.get('repeat','1')))
        anim(e.get('name'),frames,float(e.get('fps','0')),.5,'kenney-cc0-and-volcano',[decl,path])
    if not wanted <= entries.keys(): raise ValueError('missing character animations: '+str(wanted-entries.keys()))
    # Only the pets still need retail art. Extract exact authored frames into a
    # separate replaceable atlas; no original declarations ship with the game.
    for species in ['cat','dog']:
        decl=src/f'reference/rescue-team/texture/lazy/{species}s.lua'; text=decl.read_text()
        blocks=re.split(r"texinfo\s*=\s*createTextureInfoEx\('([^']+)'\)",text)
        needed={f'{species}{v}_idle0' for v in ([0] if species=='cat' else [0,1])}
        needed.update(f'{species}{v}_run{d}' for v in ([0] if species=='cat' else [0,1]) for d in range(8))
        for i in range(1,len(blocks),2):
            name,block=blocks[i:i+2]
            if name not in needed: continue
            m=re.search(r"addTextureInfoExNodes\(texinfo, '([^']+)', frames, ([\d.]+)\)",block)
            path=decl.parent/(m[1]+'.png'); sheet=Image.open(path).convert('RGBA'); frames=[]
            for raw in re.findall(r'\{([^{}]+)\}',block.split('addTexture')[0]):
                fields={k:float(v) for k,v in re.findall(r'\b(dx|dy|u|v|cu|cv|w|h)\s*=\s*([\d.eE+-]+)',raw)}
                if 'u' not in fields: continue
                f=fields; x=round(f['u']*sheet.width); y=round((1-f['v']-f['cv'])*sheet.height); w=round(f['cu']*sheet.width); h=round(f['cv']*sheet.height)
                crop=sheet.crop((x,y,x+w,y+h))
                if crop.getbbox() is None: raise ValueError('empty source frame: '+name)
                frames.append((crop,[f['dx']/f['w'],1-f['dy']/f['h']]))
            anim(name,frames,float(m[2]),1,'rescue-team-temporary',[decl,path])
    # Shelf packing copies pixels only. Deduplicate repeated timing frames.
    native={}
    for borrowed,file in [(False,'sprites.png'),(True,'pets-to-replace.png')]:
        x=y=row=0; placements=[]; seen={}
        for name,e in entries.items():
            if (e['origin']=='rescue-team-temporary') != borrowed: continue
            out=[]
            for image,pivot in e['frames']:
                key=(image.size,hashlib.sha256(image.tobytes()).digest())
                if key in seen: box=seen[key]
                else:
                    w,h=image.size
                    if x+w+2>2048: x=0; y+=row+2; row=0
                    box=[x,y,w,h]; placements.append((image,x,y)); seen[key]=box; x+=w+2; row=max(row,h)
                out.append(dict(source=dict(zip(['x','y','w','h'],box)),pivot=dict(zip(['x','y'],pivot))))
            native[name]=dict(image=file,fps=e['fps'],scale=e['scale'],frames=out)
        atlas=Image.new('RGBA',(2048,y+row+2))
        for image,x,y in placements: atlas.paste(image,(x,y))
        atlas.save(data/file)
        if borrowed:
            catalog.append(dict(asset=file,origin='Rescue Team 5 / Rionix',status='replace',reason='No original or CC0 cat/dog substitute exists in either repository.',uses=['cat0','dog0','dog1'],animations=[n for n,e in entries.items() if e['origin']=='rescue-team-temporary'],replacement='An original pet atlas with idle and eight running directions; keep native animation keys and pivots.'))
    (code/'volcano_art.lua').write_text('-- Migrated atlas metadata; frames retain their authored pivots and timing.\nreturn '+lua(native)+'\n')
    levels=[]
    for folder in sorted((src/'missions').glob('volcano-*')):
        path=folder/'mission.xml'; root=ET.parse(path).getroot(); settings=root.find('settings')
        level=dict(id=folder.name,title=root.get('title').split(': ',1)[-1],briefing=root.get('briefing'),width=int(root.get('width')),height=int(root.get('height')),food=int(settings.get('food')),wood=int(settings.get('wood')),people=int(settings.get('people')),animals=int(settings.get('animals','0')),nodes=[],objects=[])
        for lane in root.findall('traffic'): level['nodes'].extend([dict(zip(['x','y'],map(float,p.split(',')))) for p in lane.text.split()])
        for e in root.findall('object'):
            level['objects'].append(dict(id=int(e.get('id')),type=e.get('type'),x=float(e.get('x')),y=float(e.get('y')),variant=int(e.get('variant','0'))))
        level['animals']=sum(o['type'] in ('cat','dog') for o in level['objects'])
        level['background']=folder.name+'.png'; shutil.copyfile(folder/'background.png',data/level['background']); levels.append(level)
        record(path,'Native Lua campaign layout'); record(folder/'background.png','Painted campaign backdrop')
        for p in folder.glob('*.prompt.txt'): shutil.copyfile(p,DEST/'docs'/(folder.name+'.prompt.txt'))
    (code/'volcano_levels.lua').write_text('-- Native Lua campaign: no XML or retail level loader at runtime.\nreturn '+lua(levels)+'\n')
    record(src/'assets/kenney-characters/README.md','Kenney provenance and authored animation details','kenney-cc0-and-volcano')
    runtime=[dict(asset=str(p.relative_to(data)),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size) for p in sorted(data.rglob('*')) if p.is_file()]
    preservation=DEST/'docs/source-preservation.json'
    if src==(DEST/'source').resolve() and preservation.is_file():
        source_commit=json.loads(preservation.read_text())['source_commit']
    else:
        source_commit=subprocess.check_output(['git','-C',str(src),'rev-parse','HEAD'],text=True).strip()
    (DEST/'docs/asset-catalog.json').write_text(json.dumps(dict(runtime=runtime,format='volcano-asset-catalog-1',source_root='games/volcano/source',source_commit=source_commit,borrowed=catalog,sources=list(originals.values())),indent=2)+'\n')
    licenses=list((src/'assets/kenney-characters/source').rglob('*[Ll]icense*'))
    for p in licenses:
        if p.is_file(): shutil.copyfile(p,DEST/'docs'/('kenney-'+p.name))
    for p in (src/'assets/volcano-episode').glob('*.prompt.txt'): shutil.copyfile(p,DEST/'docs'/p.name)
    print(f'Migrated {len(levels)} maps, {len(native)} animations; borrowed art isolated in pets-to-replace.png')

if __name__=='__main__': main()
