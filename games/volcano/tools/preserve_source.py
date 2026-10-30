#!/usr/bin/env python3
"""Preserve a Volcano checkout locally before retiring it; never deletes source.
Copies the complete working tree into owned authoring sources and ignored local
references/backups. On macOS, APFS clones avoid temporary duplicate disk usage.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

GAME=Path(__file__).resolve().parents[1]
REPO=GAME.parents[1]
MANIFEST=GAME/'docs/source-preservation.json'

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

def inventory(source):
    entries=[]
    for path in sorted(source.rglob('*')):
        rel=path.relative_to(source)
        if rel.parts[0]=='.git': continue
        if rel.parts[0]=='reference': dest=Path('reference').joinpath(*rel.parts[1:])
        elif rel.parts[0]=='resources': dest=Path('reference/volcano-resources').joinpath(*rel.parts[1:])
        elif rel.parts[0]=='build': dest=Path('reference/volcano-backup/build').joinpath(*rel.parts[1:])
        else: dest=Path('games/volcano/source')/rel
        e=dict(source=str(rel),destination=str(dest))
        if path.is_symlink(): e.update(kind='symlink',target=os.readlink(path))
        elif path.is_file(): e.update(kind='file',bytes=path.stat().st_size,sha256=digest(path))
        elif path.is_dir(): e.update(kind='directory')
        else: raise RuntimeError('Unsupported filesystem entry: '+str(path))
        entries.append(e)
    return entries

def verify(manifest,source=None):
    files=0;size=0
    for e in manifest['entries']:
        dst=REPO/e['destination']
        if e['kind']=='symlink':
            if not dst.is_symlink() or os.readlink(dst)!=e['target']: raise RuntimeError('Symlink mismatch: '+str(dst))
        elif e['kind']=='directory':
            if not dst.is_dir(): raise RuntimeError('Missing directory: '+str(dst))
        else:
            if not dst.is_file() or dst.stat().st_size!=e['bytes'] or digest(dst)!=e['sha256']:
                raise RuntimeError('File mismatch: '+str(dst))
            if source is not None and digest(source/e['source'])!=e['sha256']:
                raise RuntimeError('Source changed during migration: '+e['source'])
            files+=1;size+=e['bytes']
    bundle=REPO/manifest['git_bundle']['path']
    if digest(bundle)!=manifest['git_bundle']['sha256']: raise RuntimeError('Git bundle checksum mismatch')
    print(f'Preserved {files} files ({size:,} bytes), all {len(manifest["missions"])} missions, and complete Git history; hashes verified.',flush=True)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path,nargs='?')
    parser.add_argument('--verify',action='store_true')
    args=parser.parse_args()
    if args.verify:
        verify(json.loads(MANIFEST.read_text()));return
    if not args.source: parser.error('source checkout path is required')
    src=args.source.resolve()
    if src==REPO or REPO in src.parents or src in REPO.parents: raise RuntimeError('Source must be a separate checkout')
    destination=GAME/'source'
    if destination.exists() or MANIFEST.exists(): raise RuntimeError('Preserved source already exists; use --verify')
    status=subprocess.check_output(['git','-C',str(src),'status','--porcelain'],text=True)
    print('Inventorying all source, references and ignored build files...',flush=True)
    entries=inventory(src)
    reference=REPO/'reference';backup=reference/'volcano-backup'
    backup.mkdir(parents=True,exist_ok=True)
    bundle=backup/'volcano-history.bundle'
    subprocess.run(['git','-C',str(src),'bundle','create',str(bundle),'--all'],check=True)
    subprocess.run(['git','-C',str(src),'bundle','verify',str(bundle)],check=True,stdout=subprocess.DEVNULL)
    destination.mkdir()
    for item in sorted(src.iterdir()):
        name=item.name
        if name=='.git': continue
        if name=='reference':
            for child in sorted(item.iterdir()):
                target=reference/child.name
                if target.exists(): raise RuntimeError('Reference destination already exists: '+str(target))
                if sys.platform=='darwin': subprocess.run(['cp','-cRp',str(child),str(target)],check=True)
                elif child.is_dir(): shutil.copytree(child,target,symlinks=True)
                else: shutil.copy2(child,target)
            continue
        target=(reference/'volcano-resources') if name=='resources' else (backup/'build') if name=='build' else (destination/name)
        if target.exists(): raise RuntimeError('Destination already exists: '+str(target))
        if sys.platform=='darwin': subprocess.run(['cp','-cRp',str(item),str(target)],check=True)
        elif item.is_dir(): shutil.copytree(item,target,symlinks=True)
        else: shutil.copy2(item,target)
    # Original tools retain their own relative path conventions. These links are
    # local-only under the archived checkout's original ignore rules.
    (destination/'reference').symlink_to('../../../reference',target_is_directory=True)
    (destination/'resources').symlink_to('../../../reference/volcano-resources',target_is_directory=True)
    (destination/'build').symlink_to('../../../reference/volcano-backup/build',target_is_directory=True)
    missions=[]
    for path in sorted((src/'missions').glob('*/mission.xml')):
        root=ET.parse(path).getroot()
        missions.append(dict(id=path.parent.name,title=root.get('title'),source='games/volcano/source/'+str(path.relative_to(src))))
    manifest=dict(format='volcano-source-preservation-1',original_checkout=str(src),source_commit=subprocess.check_output(['git','-C',str(src),'rev-parse','HEAD'],text=True).strip(),source_status=status,git_bundle=dict(path=str(bundle.relative_to(REPO)),sha256=digest(bundle)),missions=missions,entries=entries)
    MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n')
    verify(manifest,src)

if __name__=='__main__': main()
