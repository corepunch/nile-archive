#!/usr/bin/env python3
"""Report the inner block streams of the five extracted Match3 DDS files."""
from decode_board_atlases import PAGES, read_streams
from extract_gems import DEST


def main():
    for page in PAGES:
        path = DEST / 'board-atlases' / f'{page}.dds'
        width, height, streams = read_streams(path.read_bytes())
        print(f'{path.name}: {width}x{height}')
        for offset, commands, dictionary, literals in streams:
            print(f'  @{offset}: {len(commands)} command bytes, {len(dictionary) // 8} 8-byte entries, '
                  f'{len(literals)} literal bytes')


if __name__ == '__main__':
    main()
