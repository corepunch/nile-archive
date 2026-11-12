#!/usr/bin/env python3
"""Report the inner block streams of the five extracted Match3 DDS files."""
import struct

from extract_gems import DEST


def inspect(data):
    if len(data) < 128 or data[:4] != b'DDS ' or data[84:88] != b'etc2':
        raise ValueError('Expected an ETC2-tagged DDS')
    height, width, _, count = struct.unpack_from('<4I', data, 12)
    offset = 128
    streams = []
    for _ in range(count):
        if len(data) - offset < 16:
            raise ValueError(f'Truncated stream header at {offset}')
        words, commands, entries, literals = struct.unpack_from('<4I', data, offset)
        end = offset + 4 + 4 * words
        if words != 3 + commands + 2 * entries + literals or end > len(data):
            raise ValueError(f'Invalid board stream layout at {offset}')
        streams.append((offset, commands * 4, entries, literals * 4))
        offset = end
    if offset != len(data):
        raise ValueError('Streams do not span the DDS payload')
    return width, height, streams


def main():
    for i in range(5):
        path = DEST / 'board-atlases' / f'Match3_0{i}.dds'
        width, height, streams = inspect(path.read_bytes())
        print(f'{path.name}: {width}x{height}')
        for offset, commands, entries, literals in streams:
            print(f'  @{offset}: {commands} command bytes, {entries} 8-byte entries, {literals} literal bytes')


if __name__ == '__main__':
    main()
