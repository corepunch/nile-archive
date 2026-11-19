#!/usr/bin/env python3
"""Shorten square boards that run long: remove the targets the bot clears last.

    make build/test/relic-rush
    python3 tools/square_trim.py relic-rush --levels 21-100
    python3 tools/square_trim.py christmas-market --levels 38 --report

The greedy bot (tests/lua/tune_moves.lua) plays each board in
games/<game>/lua/campaign.lua. While its median game is longer than the
tier's ceiling (easy 30, normal 45, hard 60, boss 70 moves), the target it
clears last on average becomes a plain cell together with its mirror images,
and the board is played again. Chains go with their target. Rerun
tools/tune_moves.py afterwards to fit the budgets.
"""
import argparse
import concurrent.futures
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path

from square_boards import parse

ROOT = Path(__file__).resolve().parents[1]
CEILING = {'tutorial': 30, 'easy': 30, 'normal': 45, 'hard': 60, 'boss': 70}
SEEDS = 20


def play(game, level):
    """(median, {(x, y): mean clear move}) for one board; 999 for never."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for name in ('engine', 'games', 'tests', 'art', 'docs', 'tools'):
            (tmp / name).symlink_to(ROOT / name)
        (tmp / 'build/test').mkdir(parents=True)
        env = {**os.environ, 'TUNE_LEVELS': f'{level}-{level}', 'BALANCE_RUNS': str(SEEDS),
               'SPRITE_SAVE_DIR': str(tmp / 'save')}
        subprocess.run([str(ROOT / f'build/test/{game}'), '--headless', '--mute', 'rules tune_moves'],
                       cwd=tmp, env=env, capture_output=True)
        log = (tmp / f'build/test/{game}.log').read_text()
    moves = next(json.loads(l.split('MOVES_JSON ', 1)[1]) for l in log.splitlines() if 'MOVES_JSON ' in l)
    games = [json.loads(l.split('CELLS_JSON ', 1)[1])['cleared'] for l in log.splitlines() if 'CELLS_JSON ' in l]
    return moves['median'] if moves['median'] >= 0 else 999, games


def mirrors(rows, x, y):
    w, h = len(rows[0]), len(rows)
    out = {(x, y), (w - 1 - x, y)}
    if [r[::-1] for r in reversed(rows)] == rows:
        out |= {(w - 1 - x, h - 1 - y), (x, h - 1 - y)}
    return out


def trim(game, level, report):
    path = ROOT / 'games' / game / 'lua/campaign.lua'
    board = parse(path.read_text())[level - 1]
    rows, tier = list(board['rows']), board['tier']
    ceiling, removed = CEILING[tier], 0
    while True:
        median, games = play(game, level)
        if median <= ceiling or report:
            return level, board['name'], tier, median, removed
        w, h = len(rows[0]), len(rows)
        left, top = (9 - w) // 2, (12 - h) // 2
        late = {}
        for x, y in [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch not in '.-']:
            cell = (left + x) * 12 + top + y
            late[(x, y)] = sum(dict(map(tuple, g)).get(cell, 999) for g in games) / max(1, len(games))
        layers = sum(2 if rows[y][x] in '+C' else 1 for x, y in late)
        if layers <= 8:
            return level, board['name'], tier, median, removed
        x, y = max(late, key=late.get)
        for mx, my in mirrors(rows, x, y):
            if rows[my][mx] not in '.-':
                rows[my] = rows[my][:mx] + '.' + rows[my][mx + 1:]
                removed += 1
        # The board's rows are unique to its table; rewrite them in place.
        text = path.read_text()
        m = re.search(r'(\{name="%s", tier="\w+"(?:, moves=\d+)?,)((?:\s*"[^"]*",?)+)\s*\}' % re.escape(board['name']), text)
        body = '\n' + ',\n'.join('        "%s"' % r for r in rows) + '}'
        path.write_text(text[:m.start()] + m.group(1) + body + text[m.end():])


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels', required=True, help='A-B or a comma list, one-based')
    parser.add_argument('--report', action='store_true', help='only print each median')
    args = parser.parse_args()
    levels = []
    for part in args.levels.split(','):
        a, _, b = part.partition('-')
        levels += range(int(a), int(b or a) + 1)
    # Boards are rewritten in place, so trim one at a time per file but play in parallel.
    with concurrent.futures.ThreadPoolExecutor(1 if not args.report else os.cpu_count() or 4) as pool:
        for level, name, tier, median, removed in pool.map(lambda n: trim(args.game, n, args.report), levels):
            print(f'{level:3d} {name:<24} {tier:<7} median {median:4d}  removed {removed}')


if __name__ == '__main__':
    main()
