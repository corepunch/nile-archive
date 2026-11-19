#!/usr/bin/env python3
"""Balance a match-3 campaign in one run: the bots play, and every fitted value is written.

    python3 tools/balance.py relic-rush            # or: make balance GAME=relic-rush
    python3 tools/balance.py christmas-market
    python3 tools/balance.py relic-rush --trim     # first trim boards that run long
    python3 tools/balance.py relic-rush --report   # prices and expected campaign only; writes nothing

Steps, each from the level files in games/<game>/levels:

1. Build the test binary and compile the boards (tools/hex_levels.py --lua).
2. With --trim, remove the plaques that make a board run long (tools/balance_plaques.py).
3. Fit every move budget to the bot's median game (tools/tune_moves.py).
4. Relic Rush: play every board with those budgets, fit the restoration prices to
   the income (tests/lua/relic_balance.lua), write them to
   art/building-catalogue/story.json, regenerate lua/buildings.lua and the
   manifest, and update the purchase table in the game's README.
5. Run the game's rule tests.

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

ROOT = Path(__file__).resolve().parents[1]
PRICED = {'relic-rush': ('rules relic_balance', 'art/building-catalogue/story.json', 'tools/prepare_buildings.py')}


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
    count = len(list((ROOT / f'games/{game}/levels').glob('level_*.txt')))
    with concurrent.futures.ThreadPoolExecutor(os.cpu_count() or 4) as pool:
        logs = pool.map(lambda n: rules_run(game, test, {'TUNE_LEVELS': f'{n}-{n}', 'BALANCE_RUNS': str(seeds)}),
                        range(1, count + 1))
        incomes = sorted((row for log in logs for row in tagged(log, 'INCOME_JSON')), key=lambda row: row['level'])
    assert len(incomes) == count
    module = 'return {\n' + ''.join(
        f"    {{wins={row['wins']}, moves={row['moves']}, income={{{', '.join(map(str, row['income']))}}}}},\n"
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
    # The README's purchase table quotes every price.
    readme = ROOT / 'games' / game / 'README.md'
    text = readme.read_text()
    for item in json.loads((ROOT / 'games' / game / 'art/building-catalogue/manifest.json').read_text())['items']:
        row = re.compile(r'(\| \d+ \| %s \| \d+ \| )[^|]*(\|)' % re.escape(item['name']))
        text = row.sub(lambda m: m.group(1) + ' / '.join(map(str, item['cost'])) + ' ' + m.group(2), text)
    readme.write_text(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('game')
    parser.add_argument('--seeds', type=int, default=40, help='games the bot plays per board')
    parser.add_argument('--trim', action='store_true', help='first trim boards whose median game runs long')
    parser.add_argument('--report', action='store_true',
                        help='only print the income-fitted prices and the expected campaign; write nothing')
    args = parser.parse_args()
    started = time.time()
    step('build', ['make', f'build/test/{args.game}'])
    if args.report:
        return fit_prices(args.game, args.seeds, write=False)
    if args.trim:
        step('trim', [sys.executable, 'tools/balance_plaques.py', args.game, '--trim', '--seeds', str(args.seeds)])
    step('boards', [sys.executable, 'tools/hex_levels.py', args.game, '--lua'])
    step('budgets', [sys.executable, 'tools/tune_moves.py', args.game, '--seeds', str(args.seeds)])
    if args.game in PRICED:
        fit_prices(args.game, args.seeds)
    step('tests', [f'build/test/{args.game}', '--headless', '--mute'])
    print(f'{args.game} balanced in {time.time() - started:.0f} s')


if __name__ == '__main__':
    main()
