#!/usr/bin/env python3
"""Extract the bundled pzsd screenplay and match-3 level archives."""
import ctypes
import ctypes.util
import hashlib
import json
from pathlib import Path, PurePosixPath
import struct
import zipfile

from story_index import SOURCE

ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'reference/homescapes-analysis/decoded'
ARCHIVES = ('screenplays', 'match3levels')


class Zstd:
    def __init__(self):
        library = ctypes.util.find_library('zstd')
        if not library and Path('/opt/homebrew/lib/libzstd.dylib').exists():
            library = '/opt/homebrew/lib/libzstd.dylib'
        if not library:
            raise RuntimeError('libzstd not found')
        self.lib = ctypes.CDLL(library)
        self.lib.ZSTD_createDCtx.restype = ctypes.c_void_p
        self.lib.ZSTD_freeDCtx.argtypes = [ctypes.c_void_p]
        self.lib.ZSTD_decompress_usingDict.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t,
                                                      ctypes.c_void_p, ctypes.c_size_t,
                                                      ctypes.c_void_p, ctypes.c_size_t]
        self.lib.ZSTD_decompress_usingDict.restype = ctypes.c_size_t
        self.lib.ZSTD_isError.argtypes = [ctypes.c_size_t]
        self.lib.ZSTD_isError.restype = ctypes.c_uint
        self.ctx = self.lib.ZSTD_createDCtx()
        if not self.ctx:
            raise RuntimeError('Cannot allocate Zstandard context')

    def close(self):
        self.lib.ZSTD_freeDCtx(self.ctx)

    def unpack(self, data, expected, dictionary=b''):
        if expected > 32_000_000:
            raise ValueError('Unexpected decoded resource size')
        out = ctypes.create_string_buffer(expected)
        result = self.lib.ZSTD_decompress_usingDict(self.ctx, out, expected, data, len(data),
                                                    dictionary, len(dictionary))
        if self.lib.ZSTD_isError(result) or result != expected:
            raise ValueError('Zstandard decompression failed or size did not match')
        return out.raw


def read_archive(blob, zstd):
    if len(blob) < 24 or blob[:4] != b'pzsd':
        raise ValueError('Not a pzsd archive')
    _, version, index_compressed, index_size, count, dictionary_size = struct.unpack_from('<6I', blob)
    if version != 1 or count > 100_000 or dictionary_size > 2_000_000:
        raise ValueError('Unsupported archive header')
    dict_start = 24 + index_compressed
    data_start = dict_start + dictionary_size
    if data_start > len(blob):
        raise ValueError('Truncated archive')
    index = zstd.unpack(blob[24:dict_start], index_size)
    dictionary = blob[dict_start:data_start]
    entries, pos = [], 0
    for _ in range(count):
        if pos + 20 > len(index):
            raise ValueError('Truncated index')
        next_pos, offset, compressed, size, _stamp = struct.unpack_from('<5I', index, pos)
        if next_pos <= pos + 20 or next_pos > len(index) or data_start + offset + compressed > len(blob):
            raise ValueError('Invalid index offsets')
        end = index.find(b'\0', pos + 20, next_pos)
        if end < 0:
            raise ValueError('Missing name terminator')
        name = index[pos + 20:end].decode('utf-8')
        path = PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or not path.parts:
            raise ValueError('Unsafe archive path')
        entries.append((path, blob[data_start + offset:data_start + offset + compressed], size))
        pos = next_pos
    if pos != len(index) or len({str(e[0]) for e in entries}) != len(entries):
        raise ValueError('Index length or names invalid')
    return dictionary, entries


def main():
    if OUTPUT.exists():
        raise SystemExit(f'Destination exists: {OUTPUT}; preserve or move it before extraction')
    zstd = Zstd()
    manifest = []
    try:
        with zipfile.ZipFile(SOURCE) as bundle:
            for archive in ARCHIVES:
                name = f'base_mm/fs_archives/{archive}.zstd'
                blob = bundle.read(name)
                dictionary, entries = read_archive(blob, zstd)
                total = 0
                for path, packed, size in entries:
                    content = zstd.unpack(packed, size, dictionary)
                    target = OUTPUT / archive / Path(*path.parts)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(content)
                    total += len(content)
                manifest.append({'source': name, 'sha256': hashlib.sha256(blob).hexdigest(),
                                 'files': len(entries), 'decoded_bytes': total})
    finally:
        zstd.close()
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    for row in manifest:
        print(f'{row["source"]}: {row["files"]} files, {row["decoded_bytes"]:,} bytes')


if __name__ == '__main__':
    main()
