#!/usr/bin/env python3
"""Validate the square match-3 boards in a game's lua/campaign.lua (or a Lua fragment).

    python3 tools/square_boards.py christmas-market          # check the campaign
    python3 tools/square_boards.py relic-rush --show 42      # print board 42
    python3 tools/square_boards.py --file boards.lua         # check a fragment of board tables

Every board fits nine columns by twelve rows, uses the legend of
match3.shapes.square_levels (. * + c C -), is normally symmetric (asymmetric boards are listed as a note), keeps its
playable cells in one 4-connected piece, lets pieces fall onto every target (plain cells that stay empty are listed as a note), has a tier, at least six target
layers and, past the tutorials, at least 45 playable cells.
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TIERS = {'tutorial', 'easy', 'normal', 'hard', 'boss'}
BOARD = re.compile(r'\{\s*name\s*=\s*"([^"]+)"([^{}]*)\}', re.S)
FIELD = re.compile(r'\w+\s*=\s*("[^"]*"|[^,"]+)')


def parse(text):
    boards = []
    for match in BOARD.finditer(text):
        fields = match.group(2)
        tier = re.search(r'tier\s*=\s*"(\w+)"', fields)
        moves = re.search(r'moves\s*=\s*(\d+)', fields)
        rows = re.findall(r'"([^"]*)"', FIELD.sub('', fields))
        boards.append({'name': match.group(1), 'tier': tier and tier.group(1),
                       'moves': moves and int(moves.group(1)), 'rows': rows})
    return boards


def problems(n, board):
    rows, out = board['rows'], []
    width = len(rows[0]) if rows else 0
    if not rows or width > 9 or len(rows) > 12:
        out.append(f'{width}×{len(rows)} exceeds 9×12')
    if any(len(r) != width for r in rows):
        out.append('rows differ in width')
    if any(re.search(r'[^.*+cC-]', r) for r in rows):
        out.append('unknown symbol')
    images = ([r[::-1] for r in rows], [r[::-1] for r in reversed(rows)], rows[::-1],
              [''.join(r[x] for r in rows) for x in range(width)] if len(rows) == width else None)
    if rows not in images:
        print(f'{n:3d} {board["name"]}: note: asymmetric')
    if board['tier'] not in TIERS:
        out.append(f'tier {board["tier"]!r}')
    cells = {(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch != '-'}
    if cells:
        seen, todo = set(), [next(iter(cells))]
        while todo:
            x, y = todo.pop()
            if (x, y) in seen or (x, y) not in cells:
                continue
            seen.add((x, y))
            todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if len(seen) != len(cells):
            out.append('playable cells are not one connected piece')
    # Pieces fall from the sky into a cell with nothing playable above it in
    # its column, then straight or diagonally down (chains count as broken).
    fed = set()
    for y, r in enumerate(rows):
        for x in range(len(r)):
            if (x, y) in cells and (all((x, k) not in cells for k in range(y))
                                    or any((x + dx, y - 1) in fed for dx in (-1, 0, 1))):
                fed.add((x, y))
    where = lambda xy: f'column {xy[0] + 1} row {xy[1] + 1}'
    unfed = sorted(cells - fed, key=lambda xy: xy[::-1])
    stuck = [xy for xy in unfed if rows[xy[1]][xy[0]] != '.']
    if stuck:
        out.append('no piece can ever fall onto the target at ' + ', '.join(map(where, stuck)))
    elif unfed:
        print(f'{n:3d} {board["name"]}: note: always empty at ' + ', '.join(map(where, unfed)))
    text = ''.join(rows)
    layers = text.count('*') + text.count('c') + text.count('C') + 2 * text.count('+')
    if layers < 6:
        out.append(f'only {layers} target layers')
    if board['tier'] != 'tutorial' and len(cells) < 45:
        out.append(f'only {len(cells)} playable cells (at least 45)')
    return out, layers, len(cells)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game', nargs='?')
    parser.add_argument('--file')
    parser.add_argument('--show', type=int)
    args = parser.parse_args()
    path = Path(args.file) if args.file else ROOT / 'games' / args.game / 'lua/campaign.lua'
    boards = parse(path.read_text())
    if args.show:
        b = boards[args.show - 1]
        print(b['name'], b['tier'], b['moves'])
        print('\n'.join(b['rows']))
        return
    failed, names = 0, {}
    for n, board in enumerate(boards, 1):
        out, layers, cells = problems(n, board)
        if board['name'] in names:
            out.append(f'name repeats board {names[board["name"]]}')
        names.setdefault(board['name'], n)
        if out:
            failed += 1
            print(f'{n:3d} {board["name"]}: ' + '; '.join(out))
    print(f'{len(boards)} boards, {failed} with problems')
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
