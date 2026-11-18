#!/usr/bin/env python3
"""Draw the two Cradle of Rome Adventure campaigns as board overview sheets."""

import argparse
from pathlib import Path
import sys

from analyze import read_board

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from hex_levels import SHEET_THEME, sheet_grid  # noqa: E402

CAMPAIGNS = (
    ('cradle-of-rome', 'Cradle of Rome (Android beta)'),
    ('cradle-of-rome-2', 'Cradle of Rome 2 (GameTop Windows)'),
)
CELL_SIZE = 9  # Fits the widest occupied square board in the shared panel.


def adventure_boards(level_dir):
    boards = []
    for number in range(1, 101):
        path = level_dir / f'level_{number}.xml'
        _, cells = read_board(path)
        xs, ys = zip(*cells)
        left, top = min(xs), min(ys)
        width, height = max(xs) - left + 1, max(ys) - top + 1
        label = f'{number}  {width}x{height}  |  {len(cells)} cells'
        boards.append((label, (cells, left, top, width, height)))
    return boards


def draw_square_board(draw, ox, oy, layout):
    cells, left, top, width, height = layout
    x0 = round(ox - width * CELL_SIZE / 2)
    y0 = round(oy - height * CELL_SIZE / 2)
    theme = SHEET_THEME
    for row in range(height):
        for column in range(width):
            x, y = x0 + column * CELL_SIZE, y0 + row * CELL_SIZE
            right, bottom = x + CELL_SIZE - 1, y + CELL_SIZE - 1
            box = (x, y, right, bottom)
            cell = cells.get((left + column, top + row))
            if cell is None:
                draw.rectangle(box, outline=theme['hole'])
                continue
            plaque, ball = cell
            draw.rectangle(box, fill=theme['tiles'][plaque], outline=theme['background'])
            marker = (x + 1, y + 1, right - 1, bottom - 1)
            if ball.get('lock') in ('1', '2'):
                draw.ellipse(marker, outline=theme['chain'], width=int(ball['lock']))
            if ball.get('freeze') == '1':
                draw.rectangle(marker, outline=theme['ice'])
            if ball.get('disable') == '1':
                draw.line((x + 2, y + 2, right - 2, bottom - 2), fill='lightgrey')
                draw.line((right - 2, y + 2, x + 2, bottom - 2), fill='lightgrey')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'docs/review/level-sheets')
    args = parser.parse_args()
    try:
        campaigns = [(key, title, adventure_boards(ROOT / 'reference' / key / 'resources/settings/scenes/game/levels'))
                     for key, title in CAMPAIGNS]
    except FileNotFoundError as error:
        parser.exit(1, f'Missing source level {error.filename}. See docs/cradle-of-rome-reference/README.md.\n')
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for key, title, boards in campaigns:
        path = args.output_dir / f'{key}.png'
        legend = 'Blue single plaques, green double plaques, gold chains, pale outlines ice, grey crosses disabled'
        sheet_grid(boards, path, f'{title} - Adventure 1-100  |  {legend}', draw_square_board)
        print(f'wrote {path} ({len(boards)} levels)')


if __name__ == '__main__':
    main()
