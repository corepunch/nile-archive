#!/usr/bin/env python3
"""Read PLXE resource metadata from archived Homescapes APKs and bundles."""

import argparse
import base64
from hashlib import md5, sha256
from pathlib import Path, PurePosixPath
import struct
import subprocess
import zipfile
import zlib


# x86 libgame.so layouts. The resource format is shared across platforms.
KEYS_685 = [
    (0xaef81e, 92), (0xaef87b, 92), (0xaef8d8, 92),
    (0xaef935, 92), (0xaef992, 88), (0xaef9eb, 96),
]
KEY_LAYOUTS = {
    '0db415eabf59d599e53ce52539c6cd07fabbacb5062ac1ecbc97a9e29c754459': [(0x15a9bd2, 92)],
    'a7bd9db806df2bdd9fe5cc74d980812e2e587664c68e55f82d9907719941722c': KEYS_685,
}
LEGACY = b'PLXE\x03\x00\x02\x00'
MODERN = b'PLXE\x05\x00\x05\x00'


def load_keys(binary):
    """Read the key table from a known archived native library."""
    digest = sha256(binary).hexdigest()
    if digest not in KEY_LAYOUTS:
        raise ValueError(f'Unrecognized libgame.so (SHA-256 {digest})')
    keys = {}
    for slot, (offset, length) in enumerate(KEY_LAYOUTS[digest], 1):
        data = binary[offset:offset + length + 1]
        salt = data[-1] - length * length
        encoded = bytes(value ^ ((salt + i * length) & 255) for i, value in enumerate(data[:-1]))
        keys[slot] = base64.b64decode(encoded, validate=True)
    return keys


def decipher(data, key, basename):
    # Read the filename hash least-significant bit first, in cyclic 3-bit groups.
    bits = ''.join(f'{value:08b}'[::-1] for value in md5(basename.encode()).digest()) * 2
    rotated = []
    for i, value in enumerate(key):
        start = i * 3 % 128
        shift = int(bits[start:start + 3], 2)
        rotated.append(((value << shift) | (value >> (8 - shift))) & 255)

    decoded = bytearray(len(data))
    feedback = 0
    for i, value in enumerate(data):
        position = (i * 23) & 0xffffffff
        position ^= position >> 16
        position ^= position >> 8
        clear = value ^ rotated[i % len(rotated)] ^ feedback ^ (position & 255)
        decoded[i] = clear
        feedback = (((feedback << 1) | (feedback >> 7)) & 255) ^ clear
    return decoded


def decode(data, basename, keys):
    if data.startswith(LEGACY) and len(data) > 10:
        offset, = struct.unpack_from('<b', data, 8)
        key = keys.get(data[9] ^ 0x45)
        if key is None:
            raise ValueError('Missing PLXE key slot')
        return zlib.decompress(decipher(data[10:], key, basename), offset)
    if data.startswith(MODERN) and len(data) > 13:
        size, = struct.unpack_from('<I', data, 8)
        key = keys.get(data[12] ^ 0x45)
        if key is None:
            raise ValueError('Missing PLXE key slot')
        frame = decipher(data[13:], key, basename)
        if not frame.startswith(b'\x28\xb5\x2f\xfd'):
            raise ValueError('Decoded payload lacks the Zstandard frame magic')
        decoded = subprocess.run(['zstd', '-qdc'], input=frame, check=True, stdout=subprocess.PIPE).stdout
        if len(decoded) != size:
            raise ValueError(f'Expected {size} decoded bytes, got {len(decoded)}')
        return decoded
    raise ValueError('Unsupported PLXE header')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--key-apk', type=Path, help='Homescapes 1.1.0 or 6.8.5 APK with x86 library')
    source.add_argument('--library', type=Path, help='Extracted x86 libgame.so from either APK')
    parser.add_argument('--archive', required=True, type=Path, help='APK or resource ZIP')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('members', nargs='+', help='Exact case-sensitive member paths')
    args = parser.parse_args()
    if args.key_apk:
        with zipfile.ZipFile(args.key_apk) as apk:
            keys = load_keys(apk.read('lib/x86/libgame.so'))
    else:
        keys = load_keys(args.library.read_bytes())
    with zipfile.ZipFile(args.archive) as archive:
        for member in args.members:
            path = PurePosixPath(member)
            if path.is_absolute() or '..' in path.parts:
                parser.error(f'Unsafe member path: {member}')
            decoded = decode(archive.read(member), path.name, keys)
            output = args.output.joinpath(*path.parts)
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(decoded)
            print(f'{member} ({len(decoded)} decoded bytes)')


if __name__ == '__main__':
    main()
