#!/usr/bin/env python3
"""Build one self-contained HTML overview of every game's scenario.

For each story game it shows the cast with their portraits, then the campaign
in play order: each level (match-3) or search scene (Nile Archive) with its
picture, what it awards or funds, and every story beat around it as dialogue.

    python3 tools/scenario_overview.py              # reuse captures already in build/shots/frames
    python3 tools/scenario_overview.py --capture    # first capture every match-3 board (one start per game)
    python3 tools/scenario_overview.py --games relic-rush --out /tmp/rr.html

The data is read from each game's own Lua tables by tools/scenario_dump.lua under
the host's `lua` (5.4+), so nothing here repeats the story. Images are embedded,
so the page can be opened anywhere or published as is. Needs Pillow.
"""
import argparse
import base64
import html
import io
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FRAMES = ROOT / 'build/shots/frames'
GAMES = ['relic-rush', 'christmas-market', 'nile-archive']
MATCH3 = {'relic-rush', 'christmas-market'}
PHASES = {'before': 'Before the level', 'after': 'After the first clear', 'restore': 'After the building is restored'}
PHASE_ORDER = {'before': 0, 'after': 1, 'restore': 2}
STORY_PIECE_NAMES = {
    'timber': 'timber pieces', 'lens': 'lenses', 'cable': 'cable coils',
    'chart': 'map pieces', 'marker': 'marker pieces', 'tools': 'tool rolls',
    'supplies': 'supply packs', 'gear': 'gears', 'note': 'folded notes',
    'pliers': 'relay pliers',
}


def capture(game):
    """Every board of a match-3 game, from one start of its test binary."""
    subprocess.run(['make', f'build/test/{game}'], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    env = dict(os.environ, SPRITE_SCENARIO='1')
    if sys.platform.startswith('linux'):
        env.setdefault('LIBGL_ALWAYS_SOFTWARE', '1')
    subprocess.run([f'build/test/{game}', 'frame scenario-'], cwd=ROOT, env=env, check=True)


def dump(game):
    out = subprocess.run(['lua', 'tools/scenario_dump.lua', game], cwd=ROOT, check=True, capture_output=True, text=True)
    return json.loads(out.stdout)


def embed(image, width, fmt='JPEG'):
    """A data: URI of `image` scaled to `width` pixels across."""
    if image.width > width:
        image = image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    if fmt == 'JPEG':
        image.convert('RGB').save(buf, 'JPEG', quality=80)
    else:
        image.save(buf, 'PNG', optimize=True)
    return f'data:image/{fmt.lower()};base64,' + base64.b64encode(buf.getvalue()).decode()


def picture(path, width, fmt='JPEG'):
    path = Path(path)
    return embed(Image.open(path), width, fmt) if path.is_file() else None


def quest_icons(game):
    """Relic Rush's recovered-object icons for the scenario cards."""
    art = (ROOT / f'games/{game}/lua/art.lua').read_text()
    m = re.search(r'A\.quest_objects = \{([^}]*)\}', art)
    atlas = ROOT / f'games/{game}/data/quest-objects.png'
    if not m or not atlas.is_file():
        return {}
    sheet = Image.open(atlas)
    icons = {}
    for i, key in enumerate(re.findall(r'"([^"]+)"', m.group(1))):
        box = (i % 4 * 128, i // 4 * 128, i % 4 * 128 + 128, i // 4 * 128 + 128)
        icons.setdefault(key, embed(sheet.crop(box), 96, 'PNG'))
    return icons


def esc(s):
    return html.escape(s or '')


class Page:
    def __init__(self, data):
        self.d = data
        self.game = data['game']
        self.data_dir = ROOT / f'games/{self.game}/data'
        self.cast = {c['id']: c for c in data['cast']}
        self.portraits = {c['id']: picture(self.data_dir / c['portrait'], 160, 'PNG') if c.get('portrait') else None
                          for c in data['cast']}

    def avatar(self, speaker, cls='avatar'):
        if self.portraits.get(speaker):   # one CSS rule per portrait, however many lines they speak
            return f'<span class="{cls} face-{self.game}-{speaker}" role="img" aria-label=""></span>'
        name = self.cast.get(speaker, {}).get('name', speaker or '?')
        return f'<span class="{cls} initial">{esc(name[:1])}</span>'

    def lines(self, lines):
        rows = []
        for line in lines:
            who = self.cast.get(line['speaker'], {}).get('name', line['speaker'])
            mode = line.get('mode')
            tag = f' <span class="mode">{esc(mode)}</span>' if mode else ''
            rows.append(f'<div class="line {esc(mode or "")}">{self.avatar(line["speaker"])}'
                        f'<div><div class="who">{esc(who)}{tag}</div><div class="said">{esc(line["text"])}</div></div></div>')
        return '\n'.join(rows)

    def beat(self, b, label):
        body = self.lines(b.get('lines', []))
        if b.get('note'):
            body = f'<p class="note">Journal: {esc(b["note"])}</p>' + body
        if b.get('choices'):
            opts = ''.join(f'<div class="choice"><div class="pick">Choice: {esc(c["label"])}</div>{self.lines(c["lines"])}</div>'
                           for c in b['choices'])
            body += f'<div class="prompt">{esc(b.get("prompt") or "The player chooses")}</div><div class="choices">{opts}</div>'
        return (f'<details class="beat" open><summary><span class="phase">{esc(label)}</span>'
                f'<code>{esc(b["key"])}</code><span class="count">{len(b.get("lines", []))} lines</span></summary>{body}</details>')

    def styles(self):
        return ''.join(f'.face-{self.game}-{who}{{background-image:url({src})}}' for who, src in self.portraits.items() if src)

    def cast_strip(self):
        spoken = {}
        for b in self.d['beats']:
            for line in b.get('lines', []) + [l for c in b.get('choices') or [] for l in c['lines']]:
                spoken[line['speaker']] = spoken.get(line['speaker'], 0) + 1
        cards = ''.join(f'<figure class="person">{self.avatar(c["id"], "portrait")}<figcaption><b>{esc(c["name"])}</b>'
                        f'<span>{esc(c.get("role"))}</span><small>{spoken.get(c["id"], 0)} lines</small></figcaption></figure>'
                        for c in self.d['cast'])
        return f'<style>{self.styles()}</style><section class="cast">{cards}</section>'


def match3_section(data, title):
    page = Page(data)
    game = data['game']
    icons = quest_icons(game)
    resources = {}
    by_level = {}
    for b in data['beats']:
        by_level.setdefault(b['level'], []).append(b)
    cards = []
    for lv in data['levels']:
        n = lv['n']
        frame = FRAMES / f'scenario-{game}-board-{n:02d}.png'
        board = picture(frame, 200)
        shot = f'<img class="board" src="{board}" alt="Board {n}">' if board else '<div class="board missing">run with --capture</div>'
        chips = []
        palette = ''
        if lv.get('plaques'):
            chips.append(f'<span class="chip">Clear <b>{lv["plaques"]} blue plaques</b></span>')
        if collection := lv.get('collection'):
            key = collection['key']
            folder = 'resource-pieces' if collection['resource'] else 'story-pieces'
            icon = picture(page.data_dir / f'{folder}/{key}.png', 96, 'PNG')
            img = f'<img src="{icon}" alt="">' if icon else ''
            chips.append(f'<span class="chip">{img}Collect <b>{collection["count"]} {STORY_PIECE_NAMES[key]}</b></span>')
            palette = f' · {collection["regular"]} regular types'
            if not collection['resource']:
                palette += ' + 1 story type'
        if lv.get('quest'):
            key = lv['quest']['key']
            icon = icons.get(key) or picture(page.data_dir / f'finds/{key}.png', 96, 'PNG')
            img = f'<img src="{icon}" alt="">' if icon else ''
            chips.append(f'<span class="chip award">{img}Recovers <b>{esc(lv["quest"]["name"])}</b></span>')
        if lv.get('wonder'):
            w = lv['wonder']
            sprite = picture(page.data_dir / w['sprite'], 120, 'PNG') if w.get('sprite') else None
            img = f'<img src="{sprite}" alt="">' if sprite else ''
            price = w.get('price')
            label = 'Opens' if price else 'Funds'
            chips.append(f'<span class="chip fund" title="{esc(w.get("about"))}">{img}{label} <b>{esc(w["name"])}</b></span>')
            if price:
                amounts = ' + '.join(f'{p["amount"]} {esc(p["name"])}' for p in price)
                chips.append(f'<span class="chip">Restoration price <b>{amounts}</b></span>')
        reveal = ''
        if lv.get('resources'):
            palette = ' · ' + str(len(lv['resources'])) + ' resource types'
            if lv.get('collection') and not lv['collection']['resource']:
                palette += ' + 1 story type'
            for item in lv['resources']:
                key = item['key']
                if key not in resources:
                    path = 'tile-sets/resources/4.png' if key == 'cut-blocks' else f'resource-pieces/{key}.png'
                    resources[key] = picture(page.data_dir / path, 44, 'PNG')
                img = f'<img src="{resources[key]}" alt="">' if resources[key] else ''
                chips.append(f'<span class="chip">{img}{esc(item["name"])} <b>+{item["yield"]} {esc(item["currency"])}</b></span>')
        if lv.get('resource_unlock') == 'water':
            reveal += '<p class="meta">After the Spring Well is placed, water buckets take the blue timber slot and earn Provisions.</p>'
            timber = picture(FRAMES / f'scenario-{game}-before-well-{n:02d}.png', 220)
            if timber:
                reveal += (f'<figure class="reveal"><img src="{timber}" alt="Blue timber before the well">'
                           '<figcaption>Palette before the Spring Well is restored.</figcaption></figure>')
        if lv.get('resource_unlock') == 'cut-blocks':
            reveal += '<p class="meta">After the Artisan Workshop is placed, cut blocks take the purple stone slot and earn Supplies.</p>'
        if game == 'relic-rush' and n == 9 and (result := picture(FRAMES / 'scenario-relic-rush-resources.png', 300)):
            reveal += (f'<figure class="reveal"><img src="{result}" alt="Resources and three-currency market price">'
                       '<figcaption>The resources banked on clear and the market restoration price.</figcaption></figure>')
        reveal_spec = lv.get('reveal') or {}
        if reveal_spec.get('covered_picture'):
            src = picture(FRAMES / f'scenario-{game}-find-{n:02d}.png', 300)
            if not src:
                name = reveal_spec['picture'].removeprefix('find-')
                src = picture(page.data_dir / f'finds/{name}.png', 300, 'PNG')
            if src:
                name = esc(lv['quest']['name'])
                reveal = (f'<figure class="reveal"><img src="{src}" alt="{name} uncovered">'
                          f'<figcaption>{name} uncovered across {reveal_spec["cells"]} cells.</figcaption></figure>')
        elif reveal_spec.get('picture'):
            # Each game keeps its story pictures in its own folder under data/.
            found = sorted(page.data_dir.rglob(f'{lv["reveal"]["picture"]}.jpg'))
            src = picture(found[0], 360) if found else None
            if src:
                floor = f' ({esc(lv["reveal"]["floor"])} floor)' if lv['reveal'].get('floor') else ''
                reveal = f'<figure class="reveal"><img src="{src}" alt=""><figcaption>Story picture revealed on the board{floor}</figcaption></figure>'
        if lv.get('quest') and (award := picture(FRAMES / f'scenario-{game}-award-{n:02d}.png', 300)):
            name = esc(lv['quest']['name'])
            reveal += (f'<figure class="reveal"><img src="{award}" alt="{name} recovery card">'
                       f'<figcaption>{name} on the first-clear item card.</figcaption></figure>')
        if lv.get('signal') == 'cliff':
            reveal += '<p class="meta">First clear: the light under the cliff waits, then flashes three times.</p>'
        elif lv.get('signal') == 'landing':
            scene = picture(FRAMES / 'scenario-relic-rush-landing.png', 360)
            if not scene:
                scene = picture(page.data_dir / 'safe-landing.jpg', 360)
            if scene:
                reveal += (f'<figure class="reveal"><img src="{scene}" alt="Ines lifting her lantern on the safe landing">'
                           '<figcaption>First clear: Ines waits and answers from the landing with the same three flashes.</figcaption></figure>')
        beats = sorted(by_level.get(n, []), key=lambda b: PHASE_ORDER.get(b['phase'], 9))
        beat_html = ''.join(page.beat(b, PHASES.get(b['phase'], b['phase'])) for b in beats)
        materials = ', '.join(name.replace('-', ' ') for name in lv.get('materials', []))
        materials_html = f'<p class="meta">Board materials · {esc(materials.capitalize())}</p>' if materials else ''
        cards.append(f'''<article class="step" id="{game}-{n}">
  <div class="media">{shot}</div>
  <div class="body">
    <h3><span class="num">{n}</span>{esc(lv["name"])}</h3>
    <p class="meta">{esc(lv.get("lesson"))} · {lv.get("moves")} moves · {lv.get("score")} points{palette}</p>
    {materials_html}<div class="chips">{"".join(chips)}</div>{reveal}
    {beat_html or '<p class="quiet">No story beat.</p>'}
  </div>
</article>''')
    total = sum(len(b.get('lines', [])) for b in data['beats'])
    return (f'<section class="game" id="{game}"><h2>{esc(title)}</h2>'
            f'<p class="sum">{len(data["levels"])} levels · {len(data["beats"])} story beats · {total} lines</p>'
            f'{page.cast_strip()}{"".join(cards)}</section>')


def nile_section(data, title):
    page = Page(data)
    beats = {b['key']: b for b in data['beats']}
    used = set()
    cards = []
    intro = beats.get('intro')
    if intro:
        used.add('intro')
        cards.append(f'<article class="step wide"><div class="body"><h3>Opening</h3>{page.beat(intro, "Intro")}</div></article>')
    for s in data['scenes']:
        bg = picture(page.data_dir / s['background'], 520) if s.get('background') else None
        shot = f'<img class="scene" src="{bg}" alt="">' if bg else ''
        label = f'Cache {s["cache"]}' if s.get('cache') else f'Search {s["n"]}'
        clue_html = ''
        for i, key in enumerate(s.get('clues') or []):
            if key in beats:
                used.add(key)
                clue_html += page.beat(beats[key], f'Clue {i + 1} (win {i + 1})')
        items = ', '.join(s.get('names') or [])
        cards.append(f'''<article class="step scene-step">
  <div class="media">{shot}</div>
  <div class="body">
    <h3><span class="num">{esc(label)}</span>{esc(s["title"])}</h3>
    <p class="meta">{esc(s.get("teaser"))}</p>
    <p class="items">Find: {esc(items)}</p>
    {clue_html or '<p class="quiet">No clue dialogue.</p>'}
  </div>
</article>''')
    rest = [b for k, b in sorted(beats.items()) if k not in used]
    if rest:
        cards.append('<article class="step wide"><div class="body"><h3>Island scenes</h3>'
                     + ''.join(page.beat(b, 'Island') for b in rest) + '</div></article>')
    total = sum(len(b.get('lines', [])) for b in data['beats'])
    return (f'<section class="game" id="{data["game"]}"><h2>{esc(title)}</h2>'
            f'<p class="sum">{len(data["scenes"])} scenes · {len(data["beats"])} story entries · {total} lines</p>'
            f'{page.cast_strip()}{"".join(cards)}</section>')


CSS = '''
:root{--bg:#f6f3ec;--card:#fffdf8;--ink:#2a2620;--muted:#6f675b;--line:#e3dccd;--accent:#2c6c54;--chip:#efe8d8;--bubble:#f3eee2}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#15181a;--card:#1d2124;--ink:#ece6da;--muted:#a59d8e;--line:#30363a;--accent:#7cc4a3;--chip:#2a2f33;--bubble:#252a2e}}
:root[data-theme="dark"]{--bg:#15181a;--card:#1d2124;--ink:#ece6da;--muted:#a59d8e;--line:#30363a;--accent:#7cc4a3;--chip:#2a2f33;--bubble:#252a2e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,sans-serif}
header{position:sticky;top:0;z-index:2;background:var(--bg);border-bottom:1px solid var(--line);padding:10px 16px;display:flex;gap:16px;align-items:center;flex-wrap:wrap}
header h1{font-size:17px;margin:0}header nav{display:flex;gap:12px;flex-wrap:wrap}header a{color:var(--accent);text-decoration:none;font-weight:600}
main{max-width:1100px;margin:0 auto;padding:16px}
h2{font-size:26px;margin:32px 0 2px}.sum{color:var(--muted);margin:0 0 16px}
.cast{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px;margin-bottom:24px}
.person{margin:0;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:10px;text-align:center}
.person .portrait{width:110px;height:110px;background-size:cover;background-position:top center;border-radius:50%;background-color:var(--chip);display:inline-flex;align-items:center;justify-content:center;font-size:40px;font-weight:700}
.person figcaption{display:flex;flex-direction:column;gap:2px;margin-top:6px}.person span,.person small{color:var(--muted);font-size:13px}
.step{display:grid;grid-template-columns:200px 1fr;gap:18px;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px;margin-bottom:14px}
.step.wide,.step.scene-step{grid-template-columns:1fr}.scene-step .media{max-width:520px}
.board{width:200px;border-radius:10px;display:block}.board.missing{height:120px;display:flex;align-items:center;justify-content:center;background:var(--chip);color:var(--muted);font-size:13px}
.scene{width:100%;border-radius:10px;display:block}
h3{margin:0 0 4px;font-size:19px;display:flex;gap:10px;align-items:baseline}.num{color:var(--accent);font-weight:800}
.meta,.items{margin:0 0 8px;color:var(--muted)}.quiet{color:var(--muted);font-style:italic}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:8px}.chip{display:inline-flex;align-items:center;gap:8px;background:var(--chip);border-radius:999px;padding:4px 12px 4px 4px;font-size:14px}
.chip img{width:40px;height:40px;object-fit:contain}
.reveal{margin:0 0 10px}.reveal img{width:100%;max-width:360px;border-radius:10px;display:block}.reveal figcaption{color:var(--muted);font-size:13px}
.beat{border-top:1px solid var(--line);padding-top:8px;margin-top:8px}.beat summary{cursor:pointer;display:flex;gap:10px;align-items:baseline;flex-wrap:wrap}
.phase{font-weight:700}.beat code{color:var(--muted);font-size:12px}.count{color:var(--muted);font-size:13px}
.line{display:flex;gap:10px;align-items:flex-start;margin:8px 0}.avatar{width:38px;height:38px;border-radius:50%;background-size:cover;background-position:top center;flex:none;background-color:var(--chip);display:inline-flex;align-items:center;justify-content:center;font-weight:700}
.who{font-weight:700;font-size:13px}.mode{font-weight:400;color:var(--muted)}.said{background:var(--bubble);border-radius:4px 12px 12px 12px;padding:6px 10px}
.thought .said{font-style:italic}.shout .said{font-weight:700}
.note{background:var(--chip);border-left:3px solid var(--accent);padding:6px 10px;border-radius:6px}
.prompt{font-weight:700;margin-top:10px}.choices{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:10px}
.choice{border:1px dashed var(--line);border-radius:10px;padding:6px 10px}.pick{color:var(--accent);font-weight:700}
@media (max-width:640px){.step{grid-template-columns:1fr}.board{width:160px}}
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--capture', action='store_true', help='capture every match-3 board first')
    ap.add_argument('--games', nargs='+', default=GAMES, choices=GAMES)
    ap.add_argument('--out', default=str(ROOT / 'build/scenarios/index.html'))
    args = ap.parse_args()
    sections, links = [], []
    for game in args.games:
        if args.capture and game in MATCH3:
            capture(game)
        data = dump(game)
        title = json.loads((ROOT / f'games/{game}/data/game.json').read_text()).get('app', {}).get('title') \
            if (ROOT / f'games/{game}/data/game.json').is_file() else 'Nile Archive'
        sections.append(match3_section(data, title) if data['kind'] == 'match3' else nile_section(data, title))
        links.append(f'<a href="#{game}">{esc(title)}</a>')
    page = (f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1"><title>Game Scenarios</title>'
            f'<style>{CSS}</style></head><body><header><h1>Game scenarios</h1><nav>{"".join(links)}</nav></header>'
            f'<main>{"".join(sections)}</main></body></html>\n')
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page)
    print(f'{out} ({len(page) / 1e6:.1f} MB)')


if __name__ == '__main__':
    main()
