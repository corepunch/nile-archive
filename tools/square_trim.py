#!/usr/bin/env python3
"""Shorten square boards that run long: remove the targets the bot clears last.

    make build/test/relic-rush
    python3 tools/square_trim.py relic-rush --levels 21-100
    python3 tools/square_trim.py christmas-market --levels 38 --report

The greedy bot (tests/lua/tune_moves.lua) plays each board in
games/<game>/lua/campaign.lua. While its median or fitted move budget exceeds
the tier's ceiling, the target it
clears last on average becomes a plain cell together with its mirror images,
and the board is played again. Keep each authored blocker type represented. Rerun
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

from square_boards import BOARD, parse

ROOT = Path(__file__).resolve().parents[1]
CEILING = {'tutorial': 30, 'easy': 30, 'normal': 45, 'hard': 60, 'boss': 70}
BUDGET = {'tutorial': 55, 'easy': 80, 'normal': 90, 'hard': 100, 'boss': 105}


def play(game, level, seeds, campaign):
    """Measure a candidate in scratch space so workers can refine boards independently."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for name in ('engine', 'tests', 'art', 'docs', 'tools'):
            (tmp / name).symlink_to(ROOT / name)
        game_path = tmp / 'games' / game
        (game_path / 'lua').mkdir(parents=True)
        (game_path / 'data').symlink_to(ROOT / 'games' / game / 'data')
        for path in (ROOT / 'games' / game / 'lua').iterdir():
            local = game_path / 'lua' / path.name
            if path.name == 'campaign.lua':
                local.write_text(campaign)
            else:
                local.symlink_to(path)
        (tmp / 'build/test').mkdir(parents=True)
        env = {**os.environ, 'TUNE_LEVELS': f'{level}-{level}', 'BALANCE_RUNS': str(seeds),
               'SPRITE_SAVE_DIR': str(tmp / 'save')}
        subprocess.run([str(ROOT / f'build/test/{game}'), '--headless', '--mute', 'rules tune_moves'],
                       cwd=tmp, env=env, capture_output=True)
        log = (tmp / f'build/test/{game}.log').read_text()
    moves = next(json.loads(l.split('MOVES_JSON ', 1)[1]) for l in log.splitlines() if 'MOVES_JSON ' in l)
    games = [json.loads(l.split('CELLS_JSON ', 1)[1])['cleared'] for l in log.splitlines() if 'CELLS_JSON ' in l]
    return moves['median'] if moves['median'] >= 0 else 999, moves['moves'], games


def mirrors(rows, x, y):
    w, h = len(rows[0]), len(rows)
    out = {(x, y), (w - 1 - x, y)}
    if [r[::-1] for r in reversed(rows)] == rows:
        out |= {(w - 1 - x, h - 1 - y), (x, h - 1 - y)}
    return out


def replace_rows(text, name, rows):
    board = next(match for match in BOARD.finditer(text) if match.group(1) == name)
    cells = iter(rows)
    fields, count = re.subn(r'"[.*+cC-]+"', lambda _: f'"{next(cells)}"', board.group(2))
    assert count == len(rows), f'{name}: could not replace every row'
    return text[:board.start(2)] + fields + text[board.end(2):]


def trim(game, level, board, text, seeds, report):
    rows, tier = list(board['rows']), board['tier']
    removed = 0
    while True:
        median, budget, games = play(game, level, seeds, text)
        if report or (median <= CEILING[tier] and budget <= BUDGET[tier]):
            return level, board['name'], tier, median, budget, removed, rows
        w, h = len(rows[0]), len(rows)
        left, top = (9 - w) // 2, (12 - h) // 2
        late = {}
        for x, y in [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch not in '.-']:
            cell = (left + x) * 12 + top + y
            late[(x, y)] = sum(dict(map(tuple, g)).get(cell, 999) for g in games) / max(1, len(games))
        marks = {p: rows[p[1]][p[0]] for p in late}
        protected = set(marks.values()) - {'*'}
        layers = {p: 2 if mark == '+' else 1 for p, mark in marks.items()}
        for x, y in sorted(late, key=late.get, reverse=True):
            group = mirrors(rows, x, y) & late.keys()
            kept = late.keys() - group
            if sum(layers[p] for p in kept) >= 6 and protected <= {marks[p] for p in kept}:
                break
        else:
            raise ValueError(f"{game} board {level} still needs {budget} moves with {sum(layers.values())} target layers")
        for mx, my in group:
            rows[my] = rows[my][:mx] + '.' + rows[my][mx + 1:]
        removed += len(group)
        text = replace_rows(text, board['name'], rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels', required=True, help='A-B or a comma list, one-based')
    parser.add_argument('--seeds', type=int, default=20)
    parser.add_argument('--workers', type=int, default=os.cpu_count() or 4)
    parser.add_argument('--report', action='store_true', help='only print each median and fitted budget')
    args = parser.parse_args()
    levels = []
    for part in args.levels.split(','):
        a, _, b = part.partition('-')
        levels += range(int(a), int(b or a) + 1)
    path = ROOT / 'games' / args.game / 'lua/campaign.lua'
    original = path.read_text()
    boards = parse(original)
    changed = original
    with concurrent.futures.ThreadPoolExecutor(args.workers) as pool:
        results = pool.map(lambda n: trim(args.game, n, boards[n - 1], original, args.seeds, args.report), levels)
        for level, name, tier, median, budget, removed, rows in results:
            if removed:
                changed = replace_rows(changed, name, rows)
            print(f'{level:3d} {name:<24} {tier:<7} median {median:3d}  budget {budget:3d}  removed {removed}', flush=True)
    if changed != original:
        path.write_text(changed)


if __name__ == '__main__':
    main()
