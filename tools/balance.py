#!/usr/bin/env python3
"""Balance a match-3 campaign in one run: the bots play, and every fitted value is written.

    python3 tools/balance.py relic-rush            # or: make balance GAME=relic-rush
    python3 tools/balance.py christmas-market
    python3 tools/balance.py relic-rush --trim     # first trim boards that run long
    python3 tools/balance.py relic-rush --fill     # first cover every board with targets, then trim
    python3 tools/balance.py relic-rush --report   # prices and expected campaign only; writes nothing

Steps, each from the square boards in games/<game>/lua/campaign.lua:

1. Build the test binary.
2. With --trim, remove the targets that make a board run long (tools/square_trim.py);
   with --fill, first turn every cell pieces can reach into a target.
3. Fit every move budget to the bot's median game (tools/tune_moves.py).
4. Play every board with those budgets, fit the purchase prices to the income
   (tests/lua/relic_balance.lua) and write them: Relic Rush to
   art/building-catalogue/story.json (and the purchase table in its README),
   Christmas Market to art/building-catalogue/catalogue.json; then regenerate
   lua/buildings.lua and the manifest.
5. Fit the citizens' "bank N in one level" feats to the same income and write
   them to lua/user_events.lua and docs/CAMPAIGN_DESIGN.md.
6. Run the game's rule tests.

The bots run the rules alone: no window, renderer or audio is opened. Boards
are spread over one process per processor.
"""
import argparse
import concurrent.futures
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

from square_boards import parse

ROOT = Path(__file__).resolve().parents[1]
PRICED = {'relic-rush': ('rules relic_balance', 'art/building-catalogue/story.json', 'tools/prepare_buildings.py'),
          'christmas-market': ('rules relic_balance', 'art/building-catalogue/catalogue.json', 'tools/prepare_catalogue.py')}


def step(title, command):
    started = time.time()
    proc = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    last = (proc.stdout.strip().splitlines() or [''])[-1]
    print(f'{title}: {last}  ({time.time() - started:.0f} s)', flush=True)
    if proc.returncode:
        sys.exit(proc.stdout[-4000:] + proc.stderr[-4000:])


def rules_run(game, test, env, modules=None):
    """One rules-only run of the test binary in a scratch tree; returns its log."""
    with tempfile.TemporaryDirectory() as tree:
        tree = Path(tree)
        for name in ('engine', 'tests', 'art', 'docs', 'tools'):
            (tree / name).symlink_to(ROOT / name)
        (tree / 'games').mkdir()
        for other in (ROOT / 'games').iterdir():
            if other.name != game or not modules:
                (tree / 'games' / other.name).symlink_to(other)
        if modules:   # extra Lua modules beside the game's own
            (tree / 'games' / game).mkdir()
            for entry in (ROOT / 'games' / game).iterdir():
                if entry.name != 'lua':
                    (tree / 'games' / game / entry.name).symlink_to(entry)
            shutil.copytree(ROOT / 'games' / game / 'lua', tree / 'games' / game / 'lua')
            for name, text in modules.items():
                (tree / 'games' / game / 'lua' / name).write_text(text)
        (tree / 'build/test').mkdir(parents=True)
        proc = subprocess.run([str(ROOT / f'build/test/{game}'), '--headless', '--mute', '--extended', test], cwd=tree,
                              env={**os.environ, 'SPRITE_SAVE_DIR': str(tree / 'save'), **env}, capture_output=True, text=True)
        log = (tree / f'build/test/{game}.log').read_text()
        if proc.returncode:
            sys.exit(f'{test} failed:\n{log[-4000:]}')
        return log


def tagged(log, tag):
    return [json.loads(line.split(tag + ' ', 1)[1]) for line in log.splitlines() if tag + ' ' in line]


def fit_prices(game, seeds, write=True):
    test, source, generator = PRICED[game]
    started = time.time()
    count = len(parse((ROOT / f'games/{game}/lua/campaign.lua').read_text()))
    workers = os.cpu_count() or 4
    chunk = (count + workers - 1) // workers
    with concurrent.futures.ThreadPoolExecutor(workers) as pool:
        logs = pool.map(lambda n: rules_run(game, test, {
            'TUNE_LEVELS': f'{n}-{min(count, n + chunk - 1)}', 'BALANCE_RUNS': str(seeds)}),
            range(1, count + 1, chunk))
        incomes = sorted((row for log in logs for row in tagged(log, 'INCOME_JSON')), key=lambda row: row['level'])
    assert len(incomes) == count
    for start in range(0, count, 20):
        rows = incomes[start:start + 20]
        mean = [round(sum(row['income'][slot] for row in rows) / len(rows)) for slot in range(3)]
        print(f'{game} levels {start + 1}–{start + len(rows)}: mean income {"/".join(map(str, mean))}', flush=True)
    module = 'return {\n' + ''.join(
        f"    {{income={{{', '.join(map(str, row['income']))}}}, planning={{{', '.join(map(str, row['planning']))}}}}},\n"
        for row in incomes) + '}\n'
    log = rules_run(game, test, {'BALANCE_RUNS': str(seeds)}, {'balance_incomes.lua': module})
    prices = tagged(log, 'PRICE_JSON')
    if not write:   # the runner's own report: fitted prices and both expected campaigns
        print(log[log.index('fitted prices'):].split('PASS')[0].rstrip())
        print(f'income and price report in {time.time() - started:.0f} s')
        return
    path = ROOT / 'games' / game / source
    text, changed = path.read_text(), 0
    for price in prices:   # edit the cost in place: the file keeps its hand formatting
        if source.endswith('catalogue.json'):   # a row: [key, name, category, w, h, [cost], ...]
            pattern = re.compile(r'(\["%s", "[^"]*", "\w+", \d+, \d+, )\[[^\]]*\]' % re.escape(price['key']))
        else:
            pattern = re.compile(r'("%s": \{.*?"cost": )\[[^\]]*\]' % re.escape(price['key']), re.S)
        cost = '[' + ', '.join(map(str, price['cost'])) + ']'
        new, found = pattern.subn(lambda m: m.group(1) + cost, text, count=1)
        assert found, f"{source} has no cost for {price['key']}"
        changed += new != text
        text = new
    path.write_text(text)
    summary = next((line for line in reversed(log.splitlines()) if 'expected campaign (fitted)' in line), '').strip()
    print(f'prices: {changed} of {len(prices)} changed; {summary}  ({time.time() - started:.0f} s)', flush=True)
    step('catalogue', [sys.executable, f'games/{game}/{generator}'])
    write_price_tables(game)
    fit_feats(game, incomes)


# A feat's currency by its id, in income (cost) order, and its name in each game.
FEAT_SLOTS = {'coins': 0, 'food': 1, 'supplies': 2}
FEAT_WORDS = {'relic-rush': ('Coins', 'Food', 'Supplies'), 'christmas-market': ('Tokens', 'Treats', 'Materials')}
FEAT_ROW = re.compile(r'(\{id="(man_\d+)", building="(\w+)"[^\n]*\n\s*If=\{"IF_PLAYER_GET_RESOURCE_IN_LEVEL", '
                      r'id="(\w+)", amount=)(\d+)(\}, perk=income\("\w+", )(\d+)')


def round5(value):
    return max(5, int(5 * round(value / 5)))


def first_levels(game):
    """The first board each ladder building is available after, from lua/economy.lua."""
    text = (ROOT / 'games' / game / 'lua/economy.lua').read_text()
    levels = {key: int(n) for key, n in re.findall(r'building="(\w+)"[^}\n]*?first_level=(\d+)', text)}
    levels.update({key: int(n) + 1 for key, n in re.findall(r'building="(\w+)"[^}\n]*?after=(\d+)', text)})
    return levels


def feat_rows(game):
    return FEAT_ROW.finditer((ROOT / 'games' / game / 'lua/user_events.lua').read_text())


def fit_feats(game, incomes):
    """A "bank N in one level" feat asks for twice the mean income in its currency over the
    ten boards after its building, in fives. Its perk keeps Rome's share of the threshold."""
    path = ROOT / 'games' / game / 'lua/user_events.lua'
    levels, by_level = first_levels(game), {row['level']: row['income'] for row in incomes}

    def fitted(match):
        building, currency, amount, perk = match.group(3), match.group(4), int(match.group(5)), int(match.group(7))
        first = levels[building]
        window = [by_level[n][FEAT_SLOTS[currency]] for n in range(first, first + 10) if n in by_level]
        threshold = round5(2 * sum(window) / len(window))
        cap = max(5, 5 * int(threshold * .2 // 5))   # a perk is at most a fifth of its feat
        return f'{match.group(1)}{threshold}{match.group(6)}{min(cap, round5(threshold * perk / amount))}'
    text, count = FEAT_ROW.subn(fitted, path.read_text())
    path.write_text(text)
    write_feat_table()
    print(f'feats: {count} income feats fitted', flush=True)


def write_feat_table():
    """Copy both games' fitted feats into the upgrade table of docs/CAMPAIGN_DESIGN.md."""
    feats = {game: {m.group(2): (FEAT_SLOTS[m.group(4)], int(m.group(5)), int(m.group(7))) for m in feat_rows(game)}
             for game in FEAT_WORDS}
    path = ROOT / 'docs/CAMPAIGN_DESIGN.md'
    lines = path.read_text().split('\n')
    for n, line in enumerate(lines):
        key = re.search(r'\(`(man_\d+)`\)', line)
        if not key or key.group(1) not in feats['relic-rush']:
            continue
        (rr_slot, rr_amount, rr_perk), (cm_slot, cm_amount, cm_perk) = (feats[g][key.group(1)] for g in FEAT_WORDS)
        cells = line.split('|')
        cells[3] = (f' {rr_amount} {FEAT_WORDS["relic-rush"][rr_slot]} / '
                    f'{cm_amount} {FEAT_WORDS["christmas-market"][cm_slot]} in one level ')
        cells[4] = f' +{rr_perk} every win ' if rr_perk == cm_perk else f' +{rr_perk} / +{cm_perk} every win '
        lines[n] = '|'.join(cells)
    path.write_text('\n'.join(lines))


# Currency names in cost order, as the docs spell a price out in words.
CURRENCIES = {'relic-rush': ('Coins', 'Food', 'Supplies'), 'christmas-market': ('Tokens', 'Treats', 'Materials')}
PRICE_DOCS = {'relic-rush': ('README.md', 'docs/building-catalogue.md'),
              'christmas-market': ('docs/market-pieces.md', 'docs/building-catalogue.md')}


def write_price_tables(game):
    """Copy every fitted price into the tables that quote it.

    A row names its building by `key` in its first cell (the building
    catalogues) or by name in its second (the purchase ladders, where a
    Rome name may follow in brackets). Its price is a cell of "a / b / c" in
    cost order, or of "N Coins + N Food" in any order."""
    items = json.loads((ROOT / 'games' / game / 'art/building-catalogue/manifest.json').read_text())['items']
    by_key = {item['key']: item['cost'] for item in items}
    by_name = {item['name'].replace('’', "'"): item['cost'] for item in items}
    names = CURRENCIES[game]
    worded = re.compile(r'^\d+ (%s)( \+ \d+ (%s))*$' % ('|'.join(names), '|'.join(names)))
    rows = 0
    for doc in PRICE_DOCS[game]:
        path = ROOT / 'games' / game / doc
        lines = path.read_text().split('\n')
        for n, line in enumerate(lines):
            cells = line.split('|')
            if len(cells) < 5 or not line.startswith('|'):
                continue
            key = re.search(r'`(\w+)`', cells[1])
            name = re.sub(r'\*\*|\s*\([^)]*\)', '', cells[2]).strip().replace('’', "'")
            cost = by_key.get(key.group(1)) if key else by_name.get(name)
            if not cost:
                continue
            for i, cell in enumerate(cells):
                text = cell.strip()
                if re.fullmatch(r'\d+ / \d+ / \d+', text):
                    cells[i] = ' %s ' % ' / '.join(map(str, cost))
                elif worded.match(text):
                    quoted = re.findall(r'\d+ (\w+)', text)
                    assert set(quoted) == {names[s] for s in range(3) if cost[s]}, f'{doc}: {line}'
                    cells[i] = ' %s ' % ' + '.join(f'{cost[names.index(c)]} {c}' for c in quoted)
                else:
                    continue
                rows += 1
                break
            lines[n] = '|'.join(cells)
        path.write_text('\n'.join(lines))
    assert rows >= len([i for i in items if any(i['cost'])]), f'{game}: only {rows} price rows found in the docs'
    print(f'docs: {rows} price rows', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--seeds', type=int, default=40, help='games the bot plays per board')
    parser.add_argument('--trim', action='store_true', help='first trim boards whose median game runs long')
    parser.add_argument('--fill', action='store_true', help='first cover every board from the third on with targets, then trim')
    parser.add_argument('--report', action='store_true',
                        help='only print the income-fitted prices and the expected campaign; write nothing')
    args = parser.parse_args()
    started = time.time()
    step('build', ['make', f'build/test/{args.game}'])
    if args.report:
        return fit_prices(args.game, args.seeds, write=False)
    if args.trim or args.fill:
        count = len(parse((ROOT / f'games/{args.game}/lua/campaign.lua').read_text()))
        step('trim', [sys.executable, 'tools/square_trim.py', args.game, '--seeds', str(args.seeds), '--levels',
                      *([f'3-{count}', '--fill'] if args.fill else [f'1-{count}'])])
    step('budgets', [sys.executable, 'tools/tune_moves.py', args.game, '--seeds', str(args.seeds)])
    if args.game in PRICED:
        fit_prices(args.game, args.seeds)
    step('tests', [f'build/test/{args.game}', '--headless', '--mute'])
    print(f'{args.game} balanced in {time.time() - started:.0f} s')


if __name__ == '__main__':
    main()
