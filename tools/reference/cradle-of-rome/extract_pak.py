#!/usr/bin/env python3
"""Unpack the AWEM v1 resources.pak from Cradle of Rome Beta or Cradle of Rome 2."""

import argparse
import struct
import zlib
from pathlib import Path
from zipfile import _ZipDecrypter


MAX_BYTES = 192 * 1024 * 1024
ENTRY_FLAGS = {0, 1, 9}


def read_payload(data, name):
    # AWEM uses the ZipCrypto byte cipher but supplies its own 16-byte header.
    key = bytes(
        ((byte + (i if i % 2 else i // 2 + 17)) & 255) or 33
        for i, byte in enumerate(name)
    )
    decrypt = _ZipDecrypter(key)
    prefix = struct.unpack_from("<I", decrypt(data[:16]), 12)[0]
    if prefix > len(data) - 16:
        raise ValueError(f"invalid encrypted length for {name!r}")
    return decrypt(data[16:16 + prefix]) + data[16 + prefix:]


def inflate(data, size):
    stream = zlib.decompressobj()
    output = stream.decompress(data, size + 1)
    if len(output) != size or not stream.eof or stream.unused_data:
        raise ValueError("invalid compressed payload")
    return output


def unpack(path):
    if path.stat().st_size > MAX_BYTES:
        raise ValueError("pack is too large")
    data = path.read_bytes()
    magic, version, index_start = struct.unpack_from("<4sII", data)
    if (magic, version) != (b"AWEM", 1) or not 12 <= index_start <= len(data) - 28:
        raise ValueError("expected an AWEM v1 pack")
    reserved, index_size, packed_size = struct.unpack_from("<III", data, index_start)
    if reserved or index_size > MAX_BYTES or index_start + 28 + packed_size != len(data):
        raise ValueError("invalid pack index header")
    # The game derives the index key from the original basename.
    index = inflate(read_payload(data[index_start + 12:], b"resources.pak"), index_size)
    count, = struct.unpack_from("<I", index)
    pos = 4
    entries = []
    names = set()
    total = 0
    for _ in range(count):
        flags, offset, size, length = struct.unpack_from("<4I", index, pos)
        end = index.index(0, pos + 16)
        name = index[pos + 16:end]
        pos = end + 1
        pathname = name.decode("ascii")
        key = pathname.casefold()
        if (
            any(part in {"", ".", ".."} for part in pathname.split("/"))
            or "\\" in pathname
            or ":" in pathname
            or key in names
        ):
            raise ValueError(f"invalid or duplicate filename: {name!r}")
        names.add(key)
        total += size
        if flags not in ENTRY_FLAGS or length < 16 or total > MAX_BYTES:
            raise ValueError(f"invalid file record: {name!r}")
        entries.append((offset, length, flags, size, name, pathname))
    if pos != len(index):
        raise ValueError("unexpected data after the pack index")

    files = {}
    next_offset = 12
    for offset, length, flags, size, name, pathname in sorted(entries):
        next_end = offset + length
        if offset != next_offset or next_end > index_start:
            raise ValueError(f"invalid file offset: {name!r}")
        payload = read_payload(data[offset:next_end], name)
        content = inflate(payload, size) if flags & 1 else payload
        if len(content) != size:
            raise ValueError(f"invalid file size: {name!r}")
        files[pathname] = content
        next_offset = next_end
    if next_offset != index_start:
        raise ValueError("unexpected data before the pack index")
    return files, total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pack", type=Path, help="path to the game's resources.pak")
    parser.add_argument("output", type=Path, help="new directory for extracted files")
    args = parser.parse_args()
    try:
        files, total = unpack(args.pack)
        args.output.mkdir()
        for pathname, content in files.items():
            target = args.output / pathname
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
    except (ValueError, OSError, struct.error, zlib.error) as error:
        parser.exit(1, f"Extraction failed: {error}\n")
    print(f"Extracted {len(files)} files ({total:,} bytes) to {args.output}")


if __name__ == "__main__":
    main()
