#!/usr/bin/env python3
"""Hex level sources for the match-3 campaigns: parse, validate and report.

Each level is a text file, games/<game>/levels/level_NNN.txt, in the format
docs/LEVEL_DESIGN.md describes: a few `key: value` header lines, then the
9 x 12 board as a 24-line honeycomb.

    python3 tools/hex_levels.py relic-rush                 # validate and summarize every level
    python3 tools/hex_levels.py relic-rush --levels 1-20   # a range
    python3 tools/hex_levels.py christmas-market --show 12 # print one level with its gated cells
    python3 tools/hex_levels.py relic-rush --lua           # also write lua/boards.lua
    python3 tools/hex_levels.py relic-rush --sheet out.png # every board on one review image

Exit status 1 when any level breaks a rule; every problem is listed.
"""
import argparse
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
BOARD_COLUMNS, BOARD_ROWS = 9, 12   # the engine's envelope: rules.lua `columns`, `rows`
HALF = (BOARD_COLUMNS - 1) // 2
LINES, COLUMNS = 2 * BOARD_ROWS, BOARD_COLUMNS   # 24 half-row lines, 9 columns
MIN_CELLS = 60         # of the 81-108 a 9-12 row board offers
MIN_ROWS = 9           # boards are 9 to 12 rows tall
TIERS = ('tutorial', 'easy', 'normal', 'hard', 'boss')
# Tablet layers (a double tablet is two) a tier may hold. Levels count moves,
# not Cradle of Rome's time, so boards carry a fraction of its plaques.
MAX_LAYERS = {'tutorial': 16, 'easy': 24, 'normal': 30, 'hard': 34, 'boss': 40}
MIN_LAYERS = 6
# Symbol -> (tablet layers, chain hits, ice layers, stone). 'x' is a hole;
# every in-hexagon slot has a symbol.
SYMBOLS = {'.': (0, 0, 0, 0), 'p': (1, 0, 0, 0), 'P': (2, 0, 0, 0),
           'c': (0, 1, 0, 0), 'C': (0, 2, 0, 0), 'k': (1, 1, 0, 0), 'K': (1, 2, 0, 0),
           'g': (2, 1, 0, 0), 'G': (2, 2, 0, 0),
           'i': (0, 0, 1, 0), 'I': (0, 0, 2, 0), 'j': (1, 0, 1, 0), 'J': (1, 0, 2, 0),
           'f': (2, 0, 1, 0),
           's': (0, 0, 0, 1)}
HOLE = 'x'
# The first level each feature may appear on: Cradle of Rome's Adventure order
# (docs/cradle-of-rome-reference/LEVELS.md), with our stones and ice slotted
# into its gaps (docs/LEVEL_DESIGN.md).
FIRST = {'chain': 5, 'chain_on_tablet': 6, 'gate': 5, 'ice': 7, 'double_tablet': 10,
         'ice_on_tablet': 11, 'stone': 15, 'double_ice': 25, 'double_chain': 51}
# Both campaigns follow the Windows sequel's feature order. Relic Rush also
# follows its plaque coverage; Christmas Market sizes each plaque field so the
# bot's median game matches a Homescapes move budget (docs/LEVEL_DESIGN.md).
SEQUEL_GAMES = ('relic-rush', 'christmas-market')
RELIC_INTRO_CAPS = {'tutorial': 24, 'easy': 40, 'normal': 45}
RELIC_FIRST = {**FIRST, 'chain': 4, 'chain_on_tablet': 4, 'ice': 12, 'ice_on_tablet': 12,
               'stone': 12, 'double_chain': 62}


def blocker(symbol):
    """Chains, ice and stones hold their cell and gate the fall below it."""
    _, chain, ice, stone = SYMBOLS[symbol]
    return chain or ice or stone


def cells():
    """Engine cell ids, in the engine's order: q ascending, then r ascending.
    Odd columns sit half a cell lower (engine/lua/match3.lua, `columns`/`rows`)."""
    out, n = {}, 0
    for q in range(-HALF, HALF + 1):
        for row in range(BOARD_ROWS):
            out[q, row - q // 2 - BOARD_ROWS // 2] = n
            n += 1
    return out


CELLS = cells()


def slot(q, r):
    """Line and column of an axial cell in the honeycomb."""
    return 2 * (r + q // 2 + BOARD_ROWS // 2) + q % 2, q + HALF


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
    return not any((q, k) in layout for k in range(-BOARD_ROWS - HALF, r))


def fed(layout):
    """The engine's rule: a cell refills from an inlet (open to the sky), or
    from a fed, unchained cell straight above or on an upper diagonal."""
    result = set()
    for (q, r) in sorted(layout, key=lambda c: (2 * c[1] + c[0], c)):
        if blocker(layout[q, r]):
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


def summarize(number, head, layout, problems, match_min, *, game=None):
    relic_rush = game == 'relic-rush'
    sequel = game in SEQUEL_GAMES
    tablets = [c for c, s in layout.items() if SYMBOLS[s][0] >= 1]
    doubles = [c for c, s in layout.items() if SYMBOLS[s][0] == 2]
    chains = [c for c, s in layout.items() if SYMBOLS[s][1] >= 1]
    double_chains = [c for c, s in layout.items() if SYMBOLS[s][1] == 2]
    on_tablets = [c for c in chains if SYMBOLS[layout[c]][0]]
    ice = [c for c, s in layout.items() if SYMBOLS[s][2] >= 1]
    double_ice = [c for c, s in layout.items() if SYMBOLS[s][2] == 2]
    ice_on_tablets = [c for c in ice if SYMBOLS[layout[c]][0]]
    stones = [c for c, s in layout.items() if SYMBOLS[s][3]]
    reach = fed(layout)
    gated = [c for c in layout if c not in reach and not blocker(layout[c])]
    groups = areas(layout)
    info = {'cells': len(layout), 'tablets': len(tablets), 'double_tablets': len(doubles), 'chains': len(chains),
            'double_chains': len(double_chains), 'chains_on_tablets': len(on_tablets), 'gated': len(gated),
            'ice': len(ice), 'double_ice': len(double_ice), 'stones': len(stones),
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
    layers = len(tablets) + len(doubles)
    if sequel:
        if layers < MIN_LAYERS:
            problems.append(f'{layers} tablet layers (a double counts two); a board holds at least {MIN_LAYERS}')
        if number % 10 == 0 and len(doubles) != len(tablets):
            problems.append('every boss plaque must be a double plaque')
    else:
        caps = RELIC_INTRO_CAPS if relic_rush else MAX_LAYERS
        cap = caps.get(head.get('tier'), 40)
        if not MIN_LAYERS <= layers <= cap:
            problems.append(f'{layers} tablet layers (a double counts two); a {head.get("tier")} board holds {MIN_LAYERS} to {cap}')
    # A tablet needs two possible match axes. Other cells need one, even
    # when a removable stone initially interrupts the line.
    spans = [range(-offset, match_min - offset) for offset in range(match_min)]
    def possible_axes(cell, area):
        q, r = cell
        return sum(any(all((q + k * dq, r + k * dr) in area for k in span) for span in spans)
                   for dq, dr in NEIGHBORS[:3])
    play = {c for c, s in layout.items() if not SYMBOLS[s][3]}
    lonely = [c for c in play if not possible_axes(c, layout)]
    if lonely:
        problems.append(f'{len(lonely)} cells sit on no straight run of {match_min} board cells: '
                        + ', '.join('line %d col %d' % tuple(n + 1 for n in slot(*c)) for c in sorted(lonely, key=lambda c: slot(*c))))
    stuck = [c for c in tablets if possible_axes(c, play) < 2]
    if stuck:
        problems.append(f'{len(stuck)} tablets sit on runs of {match_min} along fewer than two axes: '
                        + ', '.join('line %d col %d' % tuple(n + 1 for n in slot(*c)) for c in sorted(stuck, key=lambda c: slot(*c))))
    # One board: every part joins the rest through at least one cell (two is better).
    if len(groups) > 1:
        problems.append(f'the board falls apart into {len(groups)} separate parts of '
                        + ', '.join(str(len(g)) for g in sorted(groups, key=len, reverse=True))
                        + ' cells; join them with at least one cell, better two')
    rows = {slot(q, r)[0] // 2 for q, r in layout}
    if rows and max(rows) - min(rows) + 1 < MIN_ROWS:
        problems.append(f'the board is {max(rows) - min(rows) + 1} rows tall; use {MIN_ROWS} to {BOARD_ROWS}')
    # As in Cradle of Rome (869 of its 871 chains sit on plaques), a chain or
    # ice must cover a tablet, or gate cells below it: otherwise nothing makes
    # the player break it.
    now_fed = fed(layout)
    idle = []
    for c, sym in layout.items():
        tablet, chain, ice, _ = SYMBOLS[sym]
        if (chain or ice) and not tablet:
            opened = dict(layout)
            opened[c] = '.'
            if not (fed(opened) - now_fed - {c}):
                idle.append(c)
    if idle:
        problems.append(f'{len(idle)} chains or ice sit on plain cells and gate nothing; put them on tablets: '
                        + ', '.join('line %d col %d' % tuple(n + 1 for n in slot(*c)) for c in sorted(idle, key=lambda c: slot(*c))))
    # Every chain and ice must break at some point. Simulate: a blocker breaks
    # once it sits on a match-length line whose other cells refill (fed, so a
    # swap or a fall can bring the matching colour; another blocker's piece is
    # stuck in its colour). A broken blocker opens the fall below it, and
    # gates behind it may break next. A blocker left at the end waits for pieces
    # only it can let in, so the board deadlocks.
    work = dict(layout)
    def breaks(c, filled):
        for dq, dr in NEIGHBORS[:3]:
            for ks in spans:
                cells = [(c[0] + k * dq, c[1] + k * dr) for k in ks]
                others = [x for x in cells if x != c]
                # A swap must be able to bring the colour in: one of the other
                # cells needs a filled neighbour off the line.
                partner = any((x[0] + a, x[1] + b) in filled and (x[0] + a, x[1] + b) not in cells
                              for x in others for a, b in NEIGHBORS)
                if all(x in filled for x in others) and partner:
                    return True
        return False
    while True:
        filled = fed(work)
        opened = [c for c, sym in work.items() if (SYMBOLS[sym][1] or SYMBOLS[sym][2]) and breaks(c, filled)]
        if not opened:
            break
        for c in opened:
            work[c] = 'p' if SYMBOLS[work[c]][0] else '.'
    locked = [c for c, sym in work.items() if SYMBOLS[sym][1] or SYMBOLS[sym][2]]
    if locked:
        problems.append(f'{len(locked)} chains or ice can never break (no line of {match_min} fills while they hold): '
                        + ', '.join('line %d col %d' % tuple(n + 1 for n in slot(*c)) for c in sorted(locked, key=lambda c: slot(*c))))
    # Every gated cell must open once its chains break.
    open_board = {c: ('.' if blocker(s) else s) for c, s in layout.items()}
    never = [c for c in layout if c not in fed(open_board)]
    if never:
        problems.append(f'{len(never)} cells can never be fed, even with every chain broken')
    used = {'chain': chains, 'chain_on_tablet': on_tablets, 'gate': gated, 'double_tablet': doubles,
            'double_chain': double_chains, 'stone': stones, 'ice': ice,
            'ice_on_tablet': ice_on_tablets, 'double_ice': double_ice}
    introductions = RELIC_FIRST if sequel else FIRST
    for feature, first in introductions.items():
        if used[feature] and number < first:
            problems.append(f'{feature.replace("_", " ")} appears on level {number}; the campaign introduces it on {first}')
    return info


def symmetry(rows, layout, problems):
    """A board is a left-right mirror or a half turn (an S or a Z): turned 180
    degrees about the middle cell it shows the same cells and symbols."""
    lines = [row.ljust(COLUMNS) for row in rows]
    if all(row == row[::-1] for row in lines):
        return 'mirror'
    if layout and all(layout.get((-q, -r)) == s for (q, r), s in layout.items()):
        return 'half turn'
    bad = next(line for line, row in enumerate(lines) if row != row[::-1])
    problems.append(f'neither a left-right mirror (line {bad + 1}: {lines[bad]!r}) nor the same after a half turn')


def lua(game, levels):
    out = ['-- Generated by python3 tools/hex_levels.py ' + game + ' --lua from games/' + game + '/levels.',
           '-- Do not edit; change the level sources.', 'return {']
    for number, head, layout in levels:
        mask = ''.join('1' if (q, r) in layout else '0' for (q, r) in CELLS)
        tablets = sorted(CELLS[c] for c, s in layout.items() if SYMBOLS[s][0] >= 1)
        doubles = sorted(CELLS[c] for c, s in layout.items() if SYMBOLS[s][0] == 2)
        chains = sorted((CELLS[c], SYMBOLS[s][1]) for c, s in layout.items() if SYMBOLS[s][1])
        ice = sorted((CELLS[c], SYMBOLS[s][2]) for c, s in layout.items() if SYMBOLS[s][2])
        stones = sorted(CELLS[c] for c, s in layout.items() if SYMBOLS[s][3])
        out.append(f'    {{number={number}, name={lua_string(head["name"])}, tier="{head["tier"]}",')
        out.append(f'     mask="{mask}",')
        out.append(f'     oil={{{", ".join(map(str, tablets))}}}, oil_double={{{", ".join(map(str, doubles))}}},')
        out.append(f'     chain_cells={{{", ".join(f"{{cell={c}, hits={h}}}" for c, h in chains)}}},')
        out.append(f'     ice_cells={{{", ".join(f"{{cell={c}, layers={n}}}" for c, n in ice)}}},')
        out.append(f'     stones={{{", ".join(f"{{cell={c}}}" for c in stones)}}}}},')
    out.append('}')
    return '\n'.join(out) + '\n'


SHEET_HEX_RADIUS = 11
SHEET_THEME = {
    'background': (30, 34, 40),
    'hole': (55, 60, 68),
    'tiles': ((205, 190, 150), (40, 110, 200), (60, 160, 80)),
    'chain': (250, 200, 40),
    'ice': (200, 245, 255),
    'stone': (120, 120, 120),
    'gated': (250, 80, 80),
}


def sheet_grid(boards, path, title, draw_board):
    """Use the same numbered panels for hex campaigns and square references."""
    from PIL import Image, ImageDraw
    import math
    size, columns = SHEET_HEX_RADIUS, 10
    panel_w = int(size * 1.5 * BOARD_COLUMNS + size * 2)
    board_height = size * math.sqrt(3) * (BOARD_ROWS + .5)
    panel_h = int(board_height + 46)
    rows = (len(boards) + columns - 1) // columns
    image = Image.new('RGB', (columns * panel_w + 20, rows * panel_h + 50), SHEET_THEME['background'])
    draw = ImageDraw.Draw(image)
    draw.text((10, 12), title, fill=(240, 240, 240))
    for n, (label, layout) in enumerate(boards):
        ox = 10 + (n % columns) * panel_w + panel_w // 2
        oy = 40 + (n // columns) * panel_h + 26 + board_height / 2
        draw.text((ox - panel_w // 2 + 4, oy - board_height / 2 - 24), label, fill=(220, 220, 220))
        draw_board(draw, ox, oy, layout)
    image.save(path)


def draw_hex_board(draw, ox, oy, layout):
    import math
    size = SHEET_HEX_RADIUS
    theme = SHEET_THEME
    reachable = fed(layout)
    gated = {c for c in layout if c not in reachable and not blocker(layout[c])}
    for (q, r) in CELLS:
        x, y = ox + size * 1.5 * q, oy + size * math.sqrt(3) * (r + q / 2 + .25)
        hexagon = [(x + size * math.cos(math.pi / 3 * k), y + size * math.sin(math.pi / 3 * k)) for k in range(6)]
        if (q, r) not in layout:
            draw.polygon(hexagon, outline=theme['hole'])
            continue
        tablet, chain, ice, stone = SYMBOLS[layout[q, r]]
        fill = theme['stone'] if stone else theme['tiles'][tablet]
        draw.polygon(hexagon, fill=fill, outline=theme['background'])
        if ice:
            inner = [(x + size * .7 * math.cos(math.pi / 3 * k), y + size * .7 * math.sin(math.pi / 3 * k)) for k in range(6)]
            draw.polygon(inner, outline=theme['ice'], width=3 if ice == 2 else 2)
        if chain:
            draw.ellipse((x - size * .45, y - size * .45, x + size * .45, y + size * .45), outline=theme['chain'], width=3 if chain == 2 else 2)
        if (q, r) in gated:
            draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=theme['gated'])


def sheet(levels, path, title):
    boards = [(f"{number} {head.get('tier', '')[:4]} {head.get('name', '')[:18]}", layout)
              for number, head, layout in levels]
    sheet_grid(boards, path, title, draw_hex_board)


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
    parser.add_argument('--sheet', help='write every listed board to one review image')
    args = parser.parse_args()
    folder = ROOT / 'games' / args.game / 'levels'
    files = {int(m.group(1)): p for p in folder.glob('level_*.txt') if (m := re.match(r'level_(\d+)\.txt$', p.name))}
    numbers = [n for n in span(args.levels, max(files, default=0)) if n in files]
    failed, levels = 0, []
    for number in numbers:
        head, rows = parse(files[number])
        problems = []
        layout = board(rows, problems)
        symmetry(rows, layout, problems)
        info = summarize(number, head, layout, problems, 4 if args.game == "relic-rush" else 3, game=args.game) if layout else {}
        levels.append((number, head, layout))
        status = 'ok ' if not problems else 'BAD'
        failed += bool(problems)
        if info:
            print(f"{status} {number:3d} {head.get('tier', '?'):8s} cells {info['cells']:2d} tablets {info['tablets']:2d}"
                  f" (double {info['double_tablets']:2d}) chains {info['chains']:2d} (double {info['double_chains']})"
                  f" on tablets {info['chains_on_tablets']:2d} ice {info['ice']:2d} (double {info['double_ice']})"
                  f" stones {info['stones']:2d} gated {info['gated']:2d} areas {info['areas']}  {head.get('name', '')}")
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
    if args.sheet:
        sheet(levels, args.sheet, f'{args.game}: blue tablet, green double, gold ring chain (thick = double), '
              'pale ring ice, grey stone, red dot gated')
        print(f'wrote {args.sheet}')
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
