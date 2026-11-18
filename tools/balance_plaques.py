#!/usr/bin/env python3
"""Find the plaques that make a board long, and trim boards to a move target.

The reference bot (tests/lua/tune_moves.lua) reports the move on which it
cleared each plaque. A plaque that goes last in most games, or never goes, is
what a long board waits for. This tool lists those plaques and, with `--trim`,
removes them in symmetric pairs until the bot's median game is at most
`--high` times the level's Homescapes move budget
(docs/homescapes-reference/first-100-levels.md). A chain or ice left on a
plain cell goes with its plaque unless it still gates a plaque below it.

    make build/test/relic-rush
    python3 tools/balance_plaques.py relic-rush --levels 31-40          # report
    python3 tools/balance_plaques.py relic-rush --trim                  # rewrite level files
    python3 tools/hex_levels.py relic-rush --lua && python3 tools/tune_moves.py relic-rush

The bot plays private copies of the boards; level files change only at the end.
"""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import tempfile

import hex_levels as H

ROOT = Path(__file__).resolve().parents[1]
CAP = 250            # tests/lua/tune_moves.lua
MIN_PLAQUES = 8      # cells; a board keeps a field worth playing
S = H.SYMBOLS
SLOT = {cell: H.slot(*cell) for cell in H.CELLS}
AT = {slot: cell for cell, slot in SLOT.items()}
ID = {number: cell for cell, number in H.CELLS.items()}


def targets():
    table = (ROOT / 'docs/homescapes-reference/first-100-levels.md').read_text()
    return {int(m.group(1)): int(m.group(2)) for m in re.finditer(r'^\| (\d+) \| (\d+) \|', table, re.M)}


def read(game, number):
    path = ROOT / f'games/{game}/levels/level_{number:03d}.txt'
    head, rows = H.parse(path)
    problems = []
    layout = H.board(rows, problems)
    return {'number': number, 'path': path, 'head': head, 'layout': layout, 'symmetry': H.symmetry(rows, layout, problems)}


def partner(cell, symmetry):
    if symmetry == 'half turn':
        return -cell[0], -cell[1]
    line, column = SLOT[cell]
    return AT[line, H.COLUMNS - 1 - column]


def honeycomb(layout):
    lines = []
    for line in range(H.LINES):
        row = [' '] * H.COLUMNS
        for cell, (at, column) in SLOT.items():
            if at == line:
                row[column] = layout.get(cell, H.HOLE)
        lines.append(''.join(row).rstrip())
    return lines


def play(game, boards, numbers, seeds):
    """The bot's games on `boards` (all of the campaign): {level: (median, [per-game {cell: move}])}."""
    tree = Path(tempfile.mkdtemp())
    try:
        for name in ('engine', 'tests', 'art', 'docs', 'tools'):
            (tree / name).symlink_to(ROOT / name)
        (tree / 'games').mkdir()
        for other in (ROOT / 'games').iterdir():
            if other.name != game:
                (tree / 'games' / other.name).symlink_to(other)
        (tree / 'games' / game).mkdir()
        for entry in (ROOT / 'games' / game).iterdir():
            if entry.name != 'lua':
                (tree / 'games' / game / entry.name).symlink_to(entry)
        shutil.copytree(ROOT / 'games' / game / 'lua', tree / 'games' / game / 'lua')
        (tree / 'games' / game / 'lua/boards.lua').write_text(
            H.lua(game, [(b['number'], b['head'], b['layout']) for b in boards]))

        def one(number):
            with tempfile.TemporaryDirectory() as run:
                run = Path(run)
                for name in ('engine', 'games', 'tests', 'art', 'docs', 'tools'):
                    (run / name).symlink_to(tree / name)
                (run / 'build/test').mkdir(parents=True)
                env = {**os.environ, 'TUNE_LEVELS': f'{number}-{number}', 'BALANCE_RUNS': str(seeds),
                       'SPRITE_SAVE_DIR': str(run / 'save')}
                subprocess.run([str(ROOT / f'build/test/{game}'), '--headless', '--mute', 'rules tune_moves'],
                               cwd=run, env=env, capture_output=True, text=True)
                log = (run / f'build/test/{game}.log').read_text()
            games = [{ID[cell]: move for cell, move in json.loads(line.split('CELLS_JSON ', 1)[1])['cleared']}
                     for line in log.splitlines() if 'CELLS_JSON ' in line]
            moves = [json.loads(line.split('MOVES_JSON ', 1)[1]) for line in log.splitlines() if 'MOVES_JSON ' in line]
            assert moves and len(games) == seeds, log[-2000:]
            return number, (moves[0]['median'] if moves[0]['median'] > 0 else CAP, games)

        with concurrent.futures.ThreadPoolExecutor(os.cpu_count() or 4) as pool:
            return dict(pool.map(one, numbers))
    finally:
        shutil.rmtree(tree)


def lateness(layout, games):
    """Mean move on which each plaque went; a plaque the bot never cleared counts as the ceiling."""
    plaques = [cell for cell, symbol in layout.items() if S[symbol][0]]
    return {cell: statistics.mean(game.get(cell, CAP) for game in games) for cell in plaques}


def projected(plaques, games):
    """The median game if only `plaques` had to be cleared."""
    return statistics.median(max(game.get(cell, CAP) for cell in plaques) for game in games)


def strip(layout, cells):
    for cell in cells:
        _, chain, ice, _ = S[layout[cell]]
        layout[cell] = {(0, 0): '.', (1, 0): 'c', (2, 0): 'C', (0, 1): 'i', (0, 2): 'I'}[chain, ice]
    while True:   # a blocker on a plain cell stays only as a gate
        fed = H.fed(layout)
        idle = [cell for cell, symbol in layout.items() if symbol in 'cCiI'
                and not H.fed({**layout, cell: '.'}) - fed - {cell}]
        if not idle:
            break
        for cell in idle:
            layout[cell] = '.'
    # Gates that hold back no plaque: nobody needs to open them.
    gates = [cell for cell, symbol in layout.items() if symbol in 'cCiI']
    held = H.fed({**layout, **{cell: '.' for cell in gates}}) - H.fed(layout)
    if not any(S[layout[cell]][0] for cell in held):
        for cell in gates:
            layout[cell] = '.'


def trim(board, games, goal):
    """Remove the latest plaques, a symmetric pair at a time, until the projected median reaches `goal`."""
    layout = board['layout']
    late = lateness(layout, games)
    left = set(late)
    removed = []
    for cell in sorted(late, key=late.get, reverse=True):
        if projected(left, games) <= goal or len(left) <= MIN_PLAQUES:
            break
        pair = {cell, partner(cell, board['symmetry'])} & left
        left -= pair
        removed += pair
    strip(layout, removed)
    return removed


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels', help='A-B, one-based and inclusive (default: all)')
    parser.add_argument('--seeds', type=int, default=40)
    parser.add_argument('--high', type=float, default=2.0, help='most the median may be, in Homescapes budgets')
    parser.add_argument('--aim', type=float, default=1.8, help='what a trim aims for, in Homescapes budgets')
    parser.add_argument('--rounds', type=int, default=10)
    parser.add_argument('--trim', action='store_true', help='remove the latest plaques and rewrite the level files')
    args = parser.parse_args()
    budget = targets()
    count = len(list((ROOT / f'games/{args.game}/levels').glob('level_*.txt')))
    boards = [read(args.game, number) for number in range(1, count + 1)]
    numbers = [n for n in H.span(args.levels, count)]
    match_min = 4 if args.game == 'relic-rush' else 3
    todo, changed, medians = numbers, set(), {}
    for round_ in range(args.rounds if args.trim else 1):
        results = play(args.game, boards, todo, args.seeds)
        again = []
        for number in todo:
            board = boards[number - 1]
            median, games = results[number]
            medians[number] = median
            high = args.high * budget[number]
            late = lateness(board['layout'], games)
            worst = sorted(late, key=late.get, reverse=True)[:6]
            where = ', '.join(f'line {SLOT[c][0] + 1} col {SLOT[c][1] + 1} ({late[c]:.0f})' for c in worst)
            if not args.trim:
                print(f"{number:3d} median {median:3d} target {budget[number] * 1.5:.0f}-{high:.0f} plaques {len(late):2d}  latest: {where}")
            elif median > high and len(late) > MIN_PLAQUES and number > 4:   # tutorials stay as authored
                # Halfway each round: with fewer plaques to chase the bot plays faster than projected.
                removed = trim(board, games, max(args.aim * budget[number], .6 * median))
                if removed:
                    changed.add(number)
                    again.append(number)
        if args.trim:
            print(f'round {round_ + 1}: {len(todo)} boards played, {len(again)} trimmed', flush=True)
        todo = again
        if not todo:
            break
    if not args.trim:
        return
    for number in sorted(changed):
        board = boards[number - 1]
        problems = []
        H.summarize(number, board['head'], board['layout'], problems, match_min, game=args.game)
        lines = board['path'].read_text().splitlines()
        head = lines[:lines.index('')]
        board['path'].write_text('\n'.join(head + [''] + honeycomb(board['layout'])) + '\n')
        plaques = sum(1 for s in board['layout'].values() if S[s][0])
        print(f"{number:3d} median {medians[number]:3d} target <= {args.high * budget[number]:.0f} plaques {plaques}"
              + ''.join(f'\n      - {p}' for p in problems))
    print(f'{len(changed)} boards rewritten; still over: '
          + (', '.join(str(n) for n in numbers if medians[n] > args.high * budget[n] and n > 4) or 'none'))


if __name__ == '__main__':
    main()
