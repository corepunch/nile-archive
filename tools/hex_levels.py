#!/usr/bin/env python3
"""Hex level sources for the match-3 campaigns: parse, validate and report.

Each level is a text file, games/<game>/levels/level_NNN.txt, in the format
docs/LEVEL_DESIGN.md describes: a few `key: value` header lines, then the
radius-4 board as a 17-line honeycomb.

    python3 tools/hex_levels.py relic-rush                 # validate and summarize every level
    python3 tools/hex_levels.py relic-rush --levels 1-20   # a range
    python3 tools/hex_levels.py christmas-market --show 12 # print one level with its gated cells
    python3 tools/hex_levels.py relic-rush --lua           # also write lua/boards.lua

Exit status 1 when any level breaks a rule; every problem is listed.
"""
import argparse
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
RADIUS = 4
LINES, COLUMNS = 4 * RADIUS + 1, 2 * RADIUS + 1   # 17 doubled-y rows, 9 columns
MIN_CELLS = 49
TIERS = ('tutorial', 'easy', 'normal', 'hard', 'boss')
# Symbol -> (tablet layers, chain hits). 'x' is a hole; every in-hexagon slot has a symbol.
SYMBOLS = {'.': (0, 0), 'p': (1, 0), 'P': (2, 0), 'c': (0, 1), 'C': (0, 2),
           'k': (1, 1), 'K': (1, 2), 'g': (2, 1), 'G': (2, 2)}
HOLE = 'x'
# The first level each feature may appear on: Cradle of Rome's Adventure order
# (docs/cradle-of-rome-reference/LEVELS.md).
FIRST = {'chain': 5, 'chain_on_tablet': 6, 'gate': 5, 'areas': 9, 'double_tablet': 10, 'double_chain': 51}


def cells():
    """Engine cell ids, in the engine's order: q ascending, then r ascending."""
    out, n = {}, 0
    for q in range(-RADIUS, RADIUS + 1):
        for r in range(max(-RADIUS, -q - RADIUS), min(RADIUS, -q + RADIUS) + 1):
            out[q, r] = n
            n += 1
    return out


CELLS = cells()


def slot(q, r):
    """Line and column of an axial cell in the honeycomb."""
    return 2 * r + q + 2 * RADIUS, q + RADIUS


def parse(path):
    text = path.read_text()
    head, rows = {}, []
    for line in text.splitlines():
        m = re.match(r'^([a-z_]+):\s*(.*)$', line)
        if m and not rows:
            head[m.group(1)] = m.group(2).strip()
        elif line.strip() or rows:
            rows.append(line.rstrip())
    while rows and not rows[-1].strip():
        rows.pop()
    return head, rows


def board(rows, problems):
    grid = [row.ljust(COLUMNS) for row in rows]
    if len(grid) != LINES:
        problems.append(f'board has {len(grid)} lines, needs {LINES}')
        return {}
    layout = {}
    expected = {slot(q, r): (q, r) for (q, r) in CELLS}
    for line, row in enumerate(grid):
        if len(row) > COLUMNS:
            problems.append(f'line {line + 1} is wider than {COLUMNS} columns')
        for column, ch in enumerate(row[:COLUMNS]):
            at = expected.get((line, column))
            if at is None:
                if ch != ' ':
                    problems.append(f'line {line + 1} column {column + 1}: {ch!r} is outside the honeycomb')
            elif ch == ' ':
                problems.append(f'line {line + 1} column {column + 1}: board slot left blank (use {HOLE!r} for a hole)')
            elif ch != HOLE and ch not in SYMBOLS:
                problems.append(f'line {line + 1} column {column + 1}: unknown symbol {ch!r}')
            elif ch != HOLE:
                layout[at] = ch
    return layout


NEIGHBORS = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]   # engine directions 0..5; 1 is down, 4 up


def is_inlet(layout, q, r):
    """Open to the sky: nothing on the board above it in its column."""
    return not any((q, k) in layout for k in range(-RADIUS - 4, r))


def fed(layout):
    """The engine's rule: a cell refills from an inlet (open to the sky), or
    from a fed, unchained cell straight above or on an upper diagonal."""
    result = set()
    for (q, r) in sorted(layout, key=lambda c: (2 * c[1] + c[0], c)):
        if SYMBOLS[layout[q, r]][1]:
            continue
        above = (q, r - 1)
        diagonals = [(q - 1, r), (q + 1, r - 1)]
        if is_inlet(layout, q, r) or above in result or any(d in result for d in diagonals):
            result.add((q, r))
    return result


def areas(layout):
    seen, groups = set(), []
    for start in layout:
        if start in seen:
            continue
        group, todo = [], [start]
        seen.add(start)
        while todo:
            q, r = todo.pop()
            group.append((q, r))
            for dq, dr in NEIGHBORS:
                n = (q + dq, r + dr)
                if n in layout and n not in seen:
                    seen.add(n)
                    todo.append(n)
        groups.append(group)
    return groups


def summarize(number, head, layout, problems):
    tablets = [c for c, s in layout.items() if SYMBOLS[s][0] >= 1]
    doubles = [c for c, s in layout.items() if SYMBOLS[s][0] == 2]
    chains = [c for c, s in layout.items() if SYMBOLS[s][1] >= 1]
    double_chains = [c for c, s in layout.items() if SYMBOLS[s][1] == 2]
    on_tablets = [c for c in chains if SYMBOLS[layout[c]][0]]
    reach = fed(layout)
    gated = [c for c in layout if c not in reach and not SYMBOLS[layout[c]][1]]
    groups = areas(layout)
    info = {'cells': len(layout), 'tablets': len(tablets), 'double_tablets': len(doubles), 'chains': len(chains),
            'double_chains': len(double_chains), 'chains_on_tablets': len(on_tablets), 'gated': len(gated),
            'areas': len(groups), 'gated_cells': gated}
    if head.get('tier') not in TIERS:
        problems.append(f"tier must be one of {', '.join(TIERS)}")
    for key in ('name', 'teaches'):
        if not head.get(key):
            problems.append(f'missing `{key}:` header')
    if len(layout) < MIN_CELLS:
        problems.append(f'{len(layout)} cells, needs at least {MIN_CELLS}')
    if not tablets:
        problems.append('no tablets: every board is won by clearing its tablets')
    for group in groups:
        if not any(is_inlet(layout, q, r) for q, r in group):
            problems.append(f'an area of {len(group)} cells has no inlet (a cell open to the sky)')
    # Every gated cell must open once its chains break.
    open_board = {c: ('.' if SYMBOLS[s][1] else s) for c, s in layout.items()}
    never = [c for c in layout if c not in fed(open_board)]
    if never:
        problems.append(f'{len(never)} cells can never be fed, even with every chain broken')
    used = {'chain': chains, 'chain_on_tablet': on_tablets, 'gate': gated, 'double_tablet': doubles,
            'double_chain': double_chains, 'areas': groups[1:]}
    for feature, first in FIRST.items():
        if used[feature] and number < first:
            problems.append(f'{feature.replace("_", " ")} appears on level {number}; Cradle of Rome introduces it on {first}')
    return info


def mirror(rows, problems):
    for line, row in enumerate(row.ljust(COLUMNS) for row in rows):
        if row != row[::-1]:
            problems.append(f'line {line + 1} is not a left-right mirror: {row!r}')


def lua(game, levels):
    out = ['-- Generated by python3 tools/hex_levels.py ' + game + ' --lua from games/' + game + '/levels.',
           '-- Do not edit; change the level sources.', 'return {']
    for number, head, layout in levels:
        mask = ''.join('1' if (q, r) in layout else '0' for (q, r) in CELLS)
        tablets = sorted(CELLS[c] for c, s in layout.items() if SYMBOLS[s][0] >= 1)
        doubles = sorted(CELLS[c] for c, s in layout.items() if SYMBOLS[s][0] == 2)
        chains = sorted((CELLS[c], SYMBOLS[s][1]) for c, s in layout.items() if SYMBOLS[s][1])
        out.append(f'    {{number={number}, name={lua_string(head["name"])}, tier="{head["tier"]}",')
        out.append(f'     mask="{mask}",')
        out.append(f'     oil={{{", ".join(map(str, tablets))}}}, oil_double={{{", ".join(map(str, doubles))}}},')
        out.append(f'     chain_cells={{{", ".join(f"{{cell={c}, hits={h}}}" for c, h in chains)}}}}},')
    out.append('}')
    return '\n'.join(out) + '\n'


def lua_string(text):
    return '"' + text.replace('\\', '\\\\').replace('"', '\\"') + '"'


def span(text, last):
    if not text:
        return range(1, last + 1)
    picked = []
    for part in text.split(','):
        a, _, b = part.partition('-')
        picked += range(int(a), int(b or a) + 1)
    return picked


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--levels')
    parser.add_argument('--show', type=int)
    parser.add_argument('--lua', action='store_true')
    args = parser.parse_args()
    folder = ROOT / 'games' / args.game / 'levels'
    files = {int(m.group(1)): p for p in folder.glob('level_*.txt') if (m := re.match(r'level_(\d+)\.txt$', p.name))}
    numbers = [n for n in span(args.levels, max(files, default=0)) if n in files]
    failed, levels = 0, []
    for number in numbers:
        head, rows = parse(files[number])
        problems = []
        layout = board(rows, problems)
        mirror(rows, problems)
        info = summarize(number, head, layout, problems) if layout else {}
        levels.append((number, head, layout))
        status = 'ok ' if not problems else 'BAD'
        failed += bool(problems)
        if info:
            print(f"{status} {number:3d} {head.get('tier', '?'):8s} cells {info['cells']:2d} tablets {info['tablets']:2d}"
                  f" (double {info['double_tablets']:2d}) chains {info['chains']:2d} (double {info['double_chains']})"
                  f" on tablets {info['chains_on_tablets']:2d} gated {info['gated']:2d} areas {info['areas']}  {head.get('name', '')}")
        else:
            print(f'{status} {number:3d}')
        for problem in problems:
            print(f'      - {problem}')
        if args.show == number:
            gated = set(info.get('gated_cells', []))
            for line in range(LINES):
                row = [' '] * COLUMNS
                for (q, r), s in layout.items():
                    ln, col = slot(q, r)
                    if ln == line:
                        row[col] = '~' if (q, r) in gated else s
                for (q, r) in CELLS:
                    ln, col = slot(q, r)
                    if ln == line and (q, r) not in layout:
                        row[col] = HOLE
                print('      ' + ''.join(row))
            print("      (~ marks a gated cell: it starts empty until a chain above it breaks)")
    missing = [n for n in span(args.levels, max(files, default=0)) if n not in files]
    if missing:
        print(f'missing levels: {", ".join(map(str, missing))}')
    if args.lua:
        if failed or missing:
            print('not writing lua/boards.lua while levels are missing or broken')
        else:
            (ROOT / 'games' / args.game / 'lua/boards.lua').write_text(lua(args.game, levels))
            print(f'wrote games/{args.game}/lua/boards.lua')
    print(f'{len(numbers) - failed} of {len(numbers)} levels valid')
    sys.exit(1 if failed or missing else 0)


if __name__ == '__main__':
    main()
