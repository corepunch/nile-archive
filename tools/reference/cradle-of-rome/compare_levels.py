#!/usr/bin/env python3
"""Compare a hex campaign's boards with Cradle of Rome 2's, level by level.

For every level it prints the share of the envelope in use, the share of the
board under blue and green plaques, chained and frozen, and the share that a
blocker cuts off: Cradle of Rome 2's cells below an ice tablet (`disable`),
our cells that stay empty until a gate breaks. Totals follow per ten levels.

    python3 tools/reference/cradle-of-rome/compare_levels.py relic-rush
    python3 tools/reference/cradle-of-rome/compare_levels.py christmas-market --levels 41-50

Reads the local reference/cradle-of-rome-2 extraction (see
docs/cradle-of-rome-reference/README.md).
"""
import argparse
from pathlib import Path
import sys

from analyze import read_board

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
import hex_levels  # noqa: E402

KEYS = ('blue', 'green', 'chain', 'double_chain', 'ice', 'held')


def reference(number):
    info, cells = read_board(ROOT / f'reference/cradle-of-rome-2/resources/settings/scenes/game/levels/level_{number}.xml')
    width, height = info['envelope']
    balls = [ball for _, ball in cells.values()]
    return {'envelope': width * height, 'cells': len(cells),
            'blue': sum(plaque == 1 for plaque, _ in cells.values()),
            'green': sum(plaque == 2 for plaque, _ in cells.values()),
            'chain': sum(ball.get('lock') in ('1', '2') for ball in balls),
            'double_chain': sum(ball.get('lock') == '2' for ball in balls),
            'ice': sum(ball.get('freeze') == '1' for ball in balls),
            'held': sum(ball.get('disable') == '1' for ball in balls)}


def campaign(game, number):
    head, rows = hex_levels.parse(ROOT / f'games/{game}/levels/level_{number:03d}.txt')
    layout = hex_levels.board(rows, [])
    layers = [hex_levels.SYMBOLS[symbol] for symbol in layout.values()]
    reach = hex_levels.fed(layout)
    return {'envelope': hex_levels.BOARD_COLUMNS * hex_levels.BOARD_ROWS, 'cells': len(layout),
            'blue': sum(tablet == 1 for tablet, *_ in layers),
            'green': sum(tablet == 2 for tablet, *_ in layers),
            'chain': sum(chain > 0 for _, chain, _, _ in layers),
            'double_chain': sum(chain == 2 for _, chain, _, _ in layers),
            'ice': sum(ice > 0 for _, _, ice, _ in layers),
            'held': sum(cell not in reach and not hex_levels.blocker(symbol) for cell, symbol in layout.items()),
            'tier': head.get('tier', '')}


def shares(boards):
    cells = sum(board['cells'] for board in boards)
    fill = 100 * cells / sum(board['envelope'] for board in boards)
    return f'{fill:4.0f} ' + ' '.join(f"{100 * sum(board[key] for board in boards) / cells:5.1f}" for key in KEYS)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels', help='A-B, one-based and inclusive (default: 1-100)')
    args = parser.parse_args()
    numbers = hex_levels.span(args.levels, 100)
    try:
        pairs = [(number, reference(number), campaign(args.game, number)) for number in numbers]
    except FileNotFoundError as error:
        parser.exit(1, f'Missing {error.filename}. See docs/cradle-of-rome-reference/README.md.\n')
    header = 'fill  blue green chain  dbl.   ice  held'
    print(f'Percent of the envelope in use, then percent of the board. Left: Cradle of Rome 2. Right: {args.game}.')
    print(f'  #  cells {header} | cells {header}')
    for number, rome, ours in pairs:
        print(f"{number:3d}  {rome['cells']:5d} {shares([rome])} | {ours['cells']:5d} {shares([ours])}  {ours['tier']}")
    print('\nPer ten levels; boards = how many carry chains / ice.')
    for first in range(numbers[0], numbers[-1] + 1, 10):
        group = [pair for pair in pairs if first <= pair[0] < first + 10]
        for label, boards in (('Rome 2', [g[1] for g in group]), (args.game, [g[2] for g in group])):
            counts = f"{sum(b['chain'] > 0 for b in boards)} / {sum(b['ice'] > 0 for b in boards)}"
            print(f'{first:3d}-{group[-1][0]:3d} {label:17s} {shares(boards)}  boards {counts}')


if __name__ == '__main__':
    main()
