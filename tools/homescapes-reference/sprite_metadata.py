#!/usr/bin/env python3
"""Read sprite reference strings from the bundled Match3 prefab library."""
import json
import re
import struct
import subprocess
from zipfile import ZipFile

from story_index import SOURCE

LIBRARY = 'base_mm/Match3/vso/Assets/'
ZSTD = b'\x28\xb5\x2f\xfd'
SPRITE = re.compile(rb'Match3(?:Chip_\d+[A-Za-z_]*|(?:Bomb|Line)Static[A-Za-z_]*|Target_[A-Za-z0-9_]+)')
FLAG = re.compile(rb'(?:Blocks|Hides|Hang|CanClear|CanFall|CanSwap|HasColor|IsComplex)[A-Za-z]+')


def unwrap(data):
    if len(data) < 40 or data[:4] != b'BLK\x1a':
        raise ValueError('Expected a BLK container')
    size = struct.unpack_from('<I', data, 12)[0]
    start = struct.unpack_from('<I', data, 32)[0]
    if not (40 <= start <= len(data) and start % 4 == 0 and 0 < size <= 16_000_000):
        raise ValueError('Invalid BLK frame directory')
    frames = []
    for (end,) in struct.iter_unpack('<I', data[36:start]):
        if not start + 4 < end <= len(data) or data[start:start + 4] != ZSTD:
            raise ValueError('Invalid BLK frame bounds')
        frames.append(subprocess.check_output(['zstd', '-dc'], input=data[start:end]))
        start = (end + 3) & ~3
    decoded = b''.join(frames)
    if len(decoded) != size or decoded[:8] != data[16:24] or start != len(data):
        raise ValueError('BLK output or padding does not match its directory')
    return decoded


def entries(index):
    lines = iter(index.decode('utf-8').splitlines())
    for section in lines:
        for _ in range(int(next(lines))):
            name, offset, size, *_ = next(lines).split(';')
            yield section, name, int(offset), int(size)


def references(archive, prefix=LIBRARY):
    index = list(entries(archive.read(prefix + 'Library.xml.meta')))
    result = {}
    for section in sorted({row[0] for row in index} & {'Vso.vso', 'M3Settings.vso'}):
        payload = unwrap(archive.read(prefix + section))
        for filename, name, offset, size in index:
            if filename != section:
                continue
            if not 0 <= offset <= offset + size <= len(payload):
                raise ValueError(f'Index exceeds {section}: {name}')
            record = payload[offset:offset + size]
            identifiers = sorted({match.group().decode() for match in SPRITE.finditer(record)})
            flags = sorted({match.group().decode() for match in FLAG.finditer(record)}) if name.startswith('Element') else []
            if identifiers or flags:
                result[name] = {'section': section, 'offset': offset, 'size': size}
                if identifiers:
                    result[name]['references'] = identifiers
                if flags:
                    result[name]['flag_names'] = flags
    return result


def bundled_references():
    with ZipFile(SOURCE) as archive:
        base = references(archive)
    with ZipFile(SOURCE.parent / 'packs/Match3_Settings.zip') as archive:
        settings = references(archive, 'Match3/Settings/')
    return {'base.zip': base, 'Match3_Settings.zip': settings}


if __name__ == '__main__':
    print(json.dumps(bundled_references(), indent=2))
