#!/usr/bin/env python3
"""Fill square boards with targets and shorten the ones that run long.

    make build/test/relic-rush
    python3 tools/square_trim.py relic-rush --levels 3-100 --fill
    python3 tools/square_trim.py christmas-market --levels 38 --report

The greedy bot (tests/lua/tune_moves.lua) plays each board in
games/<game>/lua/campaign.lua. With --fill, every plain cell a piece can fall
onto first becomes a target (a double one on a board whose targets are all
double), as Cradle of Rome covers its boards. While the bot's median clear
then exceeds the board's ceiling, the targets it clears last on average become
plain cells together with their mirror images, and the board is played again:
the cells that are hard to reach are the ones left plain. Chained and double
targets on a mixed board go only when they run a fifth later than a plain one,
and each authored blocker type stays represented. Rerun tools/tune_moves.py
afterwards to fit the budgets.

The ceiling is the median clear a tier may take. The base budget is 1.25 times the
median, up to 40 moves before the Relic Rush multiplier. The first eleven boards climb
to it two moves at a time.
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
CEILING = {'tutorial': 24, 'easy': 24, 'normal': 28, 'hard': 30, 'boss': 32}
BLOCKER_GRACE = .8  # a chained or double target counts as this much earlier than a plain one
GATHER = .08  # and a target counts this much later for each plain cell beside it


def ceiling(level, tier):
    return min(CEILING[tier], 8 + 2 * level)


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


def symmetries(rows):
    """The flips and the half turn that leave the whole layout unchanged."""
    w, h = len(rows[0]), len(rows)
    maps = (lambda x, y: (w - 1 - x, y), lambda x, y: (x, h - 1 - y), lambda x, y: (w - 1 - x, h - 1 - y))
    return [m for m in maps if all(rows[m(x, y)[1]][m(x, y)[0]] == rows[y][x] for y in range(h) for x in range(w))]


def fed(rows):
    """Cells a piece can fall onto: open to the sky, or below a fed cell (tools/square_boards.py)."""
    cells = {(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch != '-'}
    out = set()
    for y, r in enumerate(rows):
        for x in range(len(r)):
            if (x, y) in cells and (all((x, k) not in cells for k in range(y))
                                    or any((x + dx, y - 1) in out for dx in (-1, 0, 1))):
                out.add((x, y))
    return out


def put(rows, cells, mark):
    for x, y in cells:
        rows[y] = rows[y][:x] + mark + rows[y][x + 1:]


def replace_rows(text, name, rows):
    board = next(match for match in BOARD.finditer(text) if match.group(1) == name)
    cells = iter(rows)
    fields, count = re.subn(r'"[.*+cC-]+"', lambda _: f'"{next(cells)}"', board.group(2))
    assert count == len(rows), f'{name}: could not replace every row'
    return text[:board.start(2)] + fields + text[board.end(2):]


def trim(game, level, board, text, seeds, report, fill):
    rows, tier = list(board['rows']), board['tier']
    targets = ''.join(rows).replace('.', '').replace('-', '')
    plain = '+' if targets and set(targets) == {'+'} else '*'
    before = len(targets)
    if fill and not report:
        put(rows, [p for p in fed(rows) if rows[p[1]][p[0]] == '.'], plain)
        text = replace_rows(text, board['name'], rows)
    same = symmetries(rows)
    w, h = len(rows[0]), len(rows)
    left, top = (9 - w) // 2, (12 - h) // 2
    limit = ceiling(level, tier)
    cells = sum(ch != '-' for r in rows for ch in r)
    taken = []
    while True:
        median, budget, games = play(game, level, seeds, text)
        marks = {(x, y): ch for y, r in enumerate(rows) for x, ch in enumerate(r) if ch not in '.-'}
        if report or median <= limit:
            break
        late = {}
        for x, y in marks:
            cell = (left + x) * 12 + top + y
            late[(x, y)] = (sum(dict(map(tuple, g)).get(cell, 999) for g in games) / max(1, len(games))
                            * (1 if marks[(x, y)] == plain else BLOCKER_GRACE))
        protected = set(marks.values()) - {plain}
        layers = {p: 2 if mark == '+' else 1 for p, mark in marks.items()}
        # Far over the ceiling, drop several groups a round; near it, one.
        want, dropped = sum(layers.values()) * (1 - limit / median) / 2, 0
        # A plain neighbor makes a target go a little sooner, so plain cells gather instead of speckling.
        def lateness(p):
            near = sum(0 <= y < h and 0 <= x < w and rows[y][x] == '.'
                       for x, y in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)))
            return late[p] * (1 + GATHER * near)
        refused = set()
        while dropped < want and marks.keys() - refused:
            p = max(marks.keys() - refused, key=lateness)
            group = {m(*p) for m in same} | {p}
            kept = marks.keys() - group
            if sum(layers[q] for q in kept) < 6 or not protected <= {marks[q] for q in kept}:
                refused |= group
                continue
            taken.append({q: marks[q] for q in group})
            put(rows, group, '.')
            dropped += sum(layers.pop(q) for q in group)
            for q in group:
                del marks[q]
        if not dropped:
            # No target is left to take: the shape itself is slow. Leave the board as authored for a redesign.
            rows = list(board['rows'])
            median, budget, _ = play(game, level, seeds, replace_rows(text, board['name'], rows))
            return level, board['name'], tier, median, budget, 0, before / cells, rows, 'needs a redesign: no trim reaches %d' % limit
        text = replace_rows(text, board['name'], rows)
    # A round may take more than it needed: return the groups taken last
    # (the earliest of those cleared late) while the board still fits.
    misses = 0
    for group in reversed(taken):
        trial = list(rows)
        for q, mark in group.items():
            put(trial, [q], mark)
        again = play(game, level, seeds, replace_rows(text, board['name'], trial))
        if again[0] <= limit:
            rows, (median, budget, _) = trial, again
            text = replace_rows(text, board['name'], rows)
        else:
            misses += 1
            if misses == 3:
                break
    covered = sum(ch not in '.-' for r in rows for ch in r)
    return level, board['name'], tier, median, budget, covered - before, covered / cells, rows, ''


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels', required=True, help='A-B or a comma list, one-based')
    parser.add_argument('--seeds', type=int, default=40)
    parser.add_argument('--workers', type=int, default=os.cpu_count() or 4)
    parser.add_argument('--fill', action='store_true', help='first turn every plain cell pieces can reach into a target')
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
        results = pool.map(lambda n: trim(args.game, n, boards[n - 1], original, args.seeds, args.report, args.fill), levels)
        for level, name, tier, median, budget, added, share, rows, note in results:
            changed = replace_rows(changed, name, rows)
            print(f'{level:3d} {name:<24} {tier:<7} median {median:3d}  budget {budget:3d}  targets {added:+3d}  {share:4.0%} covered  {note}', flush=True)
    if changed != original:
        path.write_text(changed)


if __name__ == '__main__':
    main()
