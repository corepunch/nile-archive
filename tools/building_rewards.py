#!/usr/bin/env python3
"""Export the live building rewards and the GameTop Windows reference as two HTML tables."""

import argparse
from html import escape
import json
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs/cradle-of-rome-reference'
GAMES = {'relic-rush': 'Relic Rush', 'christmas-market': 'Christmas Market'}
ROME_TOOLS = dict(enumerate(('hammer', 'bomb', 'shield', 'hourglass', 'lightning', 'plus', 'mixer', 'star'), 600))
ROME_SLOT = {1: 1, 2: 3, 3: 2}  # Original credit ID to our wallet order.

# Only the economy module is needed. It uses ordinary Lua and the shared bonus descriptors.
LUA_REWARDS = '''
local game = assert(os.getenv("REWARD_REVIEW_GAME"))
package.path = "games/" .. game .. "/lua/?.lua;engine/lua/?.lua;" .. package.path
local economy = require("economy")
for _, unlock in ipairs(economy.unlocks) do
    local bonus = unlock.bonus
    local piece = economy.FOOD and economy.pieces[unlock.kind] or unlock
    local frame = bonus and bonus.frame or economy.FOOD and "market-" .. unlock.kind or "campaign-" .. piece.key
    local name = bonus and bonus.name or piece.name
    local effect = bonus and bonus.effect or economy.currencies[piece.slot].name
    local slot = bonus and 0 or piece.slot
    local amount = bonus and bonus.amount or piece.amount
    print(table.concat({unlock.building, unlock.after, unlock.rome or "", unlock.tile or "",
        frame, name, effect, slot, amount, bonus and bonus.key or ""}, "\\t"))
end
'''

STYLE = '''
:root { color-scheme: light; font: 16px/1.4 system-ui, sans-serif; color: #28241e; background: #f8f5ee; }
body { max-width: 1230px; margin: 2.5rem auto; padding: 0 1.25rem; }
h1 { font: 700 clamp(1.8rem, 4vw, 2.8rem)/1.1 Georgia, serif; margin: 0 0 .8rem; }
p { max-width: 78ch; }
a { color: #255d56; }
.scroll { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; background: #fffefb; }
th, td { text-align: left; padding: .65rem .85rem; border-bottom: 1px solid #e6ded1; }
thead th { background: #244840; color: #fff; min-width: 200px; }
thead th:first-child { min-width: 55px; }
thead small { color: #e2ece6; }
tbody tr:nth-child(even) { background: #f5f1e9; }
tbody tr:nth-child(4n+1) { border-top: 2px solid #9b886a; }
tbody th { vertical-align: top; }
td > div { display: flex; gap: .65rem; align-items: center; min-height: 3rem; }
td > div + div { padding-top: .1rem; }
.item { flex: 0 0 52px; width: 52px; height: 52px; background-repeat: no-repeat; object-fit: contain; }
small { display: block; color: #62574b; }
.cost { font-variant-numeric: tabular-nums; white-space: nowrap; }
'''


def game_rows(game):
    root = ROOT / 'games' / game
    catalogue = json.loads((root / 'art/building-catalogue/manifest.json').read_text())
    buildings = {item['key']: item for item in catalogue['items']}
    atlas = json.loads((root / 'art/match3-atlas.json').read_text())
    output = subprocess.check_output(['lua', '-'], input=LUA_REWARDS, cwd=ROOT, text=True,
                                     env={**os.environ, 'REWARD_REVIEW_GAME': game})
    rows = []
    for line in output.splitlines():
        key, after, rome, tile, frame, name, effect, slot, amount, tool = line.split('\t')
        item = buildings[key]
        sprite = atlas['frames'][frame]
        sheet = atlas['atlases'][sprite['atlas']]
        x, y, w, h = sprite['box']
        assert w == h == 128, frame
        factor = 52 / w
        path = f'../../games/{game}/{sheet["runtime"]}'
        width, height = [axis * factor for axis in sheet['size']]
        icon = (f'<span class="item" aria-hidden="true" style="background-image:url({escape(path)});'
                f'background-size:{width:g}px {height:g}px;background-position:{-x*factor:g}px {-y*factor:g}px"></span>')
        picture = f'<img class="item" src="../../games/{game}/{escape(item["runtime"])}" alt="" loading="lazy">'
        rows.append(dict(key=key, after=int(after), rome=rome, tile=tile, price=item['cost'], name=item['name'],
                         reward=name, effect=effect, slot=int(slot), amount=int(amount), tool=tool,
                         picture=picture, icon=icon))
    return rows


def rome_rows():
    source = json.loads((DOCS / 'rome-2-economy.json').read_text())
    rows = []
    for epoch in source['epochs']:
        for building in epoch['buildings']:
            code = building['unlocks_tile']
            tile = source['tiles'][str(code)]
            credit = tile['credit']
            tool = ROME_TOOLS.get(code, '')
            assert bool(tool) == (tile['kind'] == 'BonusBall'), code
            gold, supplies, food = building['price']
            rows.append(dict(key=building['id'], name=building['name'], reward=building['reward'], tool=tool,
                             tile=code, sprite=tile['sprite'], price=[gold, food, supplies],
                             effect=source['resource_ids'].get(str(credit['type']), '').title(),
                             slot=0 if tool else ROME_SLOT[credit['type']], amount=credit['amount']))
    return rows


def details(row):
    if not row['tool']:
        return f'+{row["amount"]} {escape(row["effect"])} per piece'
    if 'sprite' in row:
        return f'+{row["amount"]} charge per piece'
    return escape(row['effect'])


def cell(row):
    price = ' / '.join(f'{amount:,}' for amount in row['price'])
    picture, icon = row.get('picture', ''), row.get('icon', '')
    source = ''
    if 'sprite' in row:
        source = f'<small>Tile {row["tile"]} · {escape(row["sprite"])}</small>'
    return (f'<td><div>{picture}<span><strong>{escape(row["name"])}</strong>'
            f'<small class="cost">{price}</small></span></div><div>{icon}<span>{escape(row["reward"])}'
            f'<small>{details(row)}</small>{source}</span></div></td>')


def report(title, intro, headers, rows, gates=()):
    page = ['<!doctype html>', '<html lang="en"><meta charset="utf-8">',
            '<meta name="viewport" content="width=device-width, initial-scale=1">',
            f'<title>{escape(title)}</title><style>{STYLE}</style><body>',
            f'<h1>{escape(title)}</h1>', *intro, '<div class="scroll"><table><thead><tr>',
            '<th scope="col">Purchase</th>']
    for heading, currency in headers:
        page.append(f'<th scope="col">{escape(heading)}<small>{escape(currency)}</small></th>')
    page.append('</tr></thead><tbody>')
    for index, row in enumerate(rows, 1):
        gate = f'<small>Clear {gates[index-1]}</small>' if gates else ''
        page.append(f'<tr><th scope="row">{index}{gate}</th>' + ''.join(map(cell, row)) + '</tr>')
    page.append('</tbody></table></div></body></html>\n')
    return '\n'.join(page)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='verify the exports are current')
    args = parser.parse_args()
    rome = rome_rows()
    relics, market = map(game_rows, GAMES)
    assert len(rome) == len(relics) == len(market) == 20
    for purchase, (original, relic, winter) in enumerate(zip(rome, relics, market), 1):
        assert relic['rome'] == original['key'] and int(relic['tile']) == original['tile'], relic['key']
        for game in (relic, winter):
            assert game['after'] == 1 + (purchase - 1) * 5, game['key']
            for field in ('slot', 'amount', 'tool'):
                assert game[field] == original[field], (game['key'], field)
            assert list(map(bool, game['price'])) == list(map(bool, original['price'])), game['key']

    source_header = ('Cradle of Rome 2', 'Gold / Food / Supplies')
    result = {
        'building-rewards.html': report('Campaign building rewards', [
            '<p>Every row is one purchase. Its reward is the piece that appears on later boards. '
            'A resource piece earns the amount shown. Matching 30 tool pieces charges the tool once before optional upgrades.</p>',
            '<p>The order, resource values and price currencies match the Windows reference. '
            'The games use their own prices, themes and four permanent tool slots. '
            '<a href="rome-2-building-rewards.html">Open the standalone Cradle of Rome 2 export.</a></p>',
        ], [source_header, (GAMES['relic-rush'], 'Coins / Food / Supplies'),
            (GAMES['christmas-market'], 'Tokens / Treats / Materials')],
            zip(rome, relics, market), [row['after'] for row in relics]),
        'rome-2-building-rewards.html': report('Cradle of Rome 2 building rewards', [
            '<p>GameTop Windows edition. The purchase order and prices come from <code>epochs.xml</code>, '
            'the credits from <code>game_balls.xml</code>, the sprite IDs from <code>field_balls.xml</code> '
            'and the display names from the English locale. <a href="rome-2-economy.json">Source data export</a>.</p>',
            '<p><a href="building-rewards.html">Compare with Relic Rush and Christmas Market.</a></p>',
        ], [source_header], zip(rome)),
    }
    for name, content in result.items():
        path = DOCS / name
        if args.check:
            assert path.read_text() == content, f'Regenerate {name} with tools/building_rewards.py'
        else:
            path.write_text(content)


if __name__ == '__main__':
    main()
