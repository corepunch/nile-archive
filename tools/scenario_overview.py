#!/usr/bin/env python3
"""Build one self-contained HTML overview of every game's scenario.

For each story game it shows the cast with their portraits, then the campaign
in play order: each level (match-3) or search scene (Nile Archive) with its
picture, what it awards or funds, and every story beat around it as dialogue.

    python3 tools/scenario_overview.py              # reuse captures already in build/shots/frames
    python3 tools/scenario_overview.py --capture    # first capture every match-3 board (one start per game)
    python3 tools/scenario_overview.py --games relic-rush --out /tmp/rr.html
    python3 tools/scenario_overview.py --epoch 1 --capture    # build/scenarios/epoch-1.html, see below

With --epoch N the page covers one epoch of each match-3 game instead: the four
ladder purchases N stands for (docs/CHAPTER_PROGRESSION.md), each with its
build-card text, price and what it changes on later boards, the levels played up
to the fourth purchase, the scene each building or clear brings, and the town
once the epoch is bought.

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
    'lens': 'Lamp lens', 'cable': 'Relay cable', 'chart': 'Tide chart',
    'marker': 'Trail marker', 'tools': 'Tool roll', 'supplies': 'Supply pack',
    'gear': 'Shutter gear', 'note': 'Folded note', 'pliers': 'Relay pliers',
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
        self.steps = {s['key']: s for s in data.get('ladder', [])}
        self.residents = {b['resident'] for b in data['beats'] if b.get('resident')}
        self.questions = {c['key']: c['label'] for b in data['beats'] if b.get('visit_site') for c in b['choices']}
        self.frames = data.get('frames', {})   # atlas frames the dump named
        self.atlases, self.icons = {}, {}

    def avatar(self, speaker, cls='avatar'):
        if self.portraits.get(speaker):   # one CSS rule per portrait, however many lines they speak
            return f'<span class="{cls} face-{self.game}-{speaker}" role="img" aria-label=""></span>'
        name = self.cast.get(speaker, {}).get('name', speaker or '?')
        return f'<span class="{cls} initial">{esc(name[:1])}</span>'

    def icon(self, name):
        """A piece or bonus from the game's atlases; one CSS rule per frame."""
        if name not in self.frames:
            return ''
        if name not in self.icons:
            frame = self.frames[name]
            if frame['path'] not in self.atlases:
                self.atlases[frame['path']] = Image.open(self.data_dir / frame['path'])
            atlas = self.atlases[frame['path']]
            if frame.get('grid'):
                w = h = frame['grid']
                row, col = divmod(frame['frame'], atlas.width // w)
                x, y = col * w, row * h
            else:
                x, y, w, h = frame['frame']
            self.icons[name] = embed(atlas.crop((x, y, x + w, y + h)), 80, 'PNG')
        return f'<span class="ico ico-{self.game}-{name}" role="img" aria-label=""></span>'

    def lines(self, lines):
        rows = []
        for line in lines:
            speaker = line.get('speaker')
            if not speaker:   # narration between the spoken lines
                rows.append(f'<p class="narration">{esc(line["text"])}</p>')
                continue
            who = self.cast.get(speaker, {}).get('name', speaker)
            mode = line.get('mode')
            tag = f' <span class="mode">{esc(mode)}</span>' if mode else ''
            rows.append(f'<div class="line {esc(mode or "")}">{self.avatar(speaker)}'
                        f'<div><div class="who">{esc(who)}{tag}</div><div class="said">{esc(line["text"])}</div></div></div>')
        return '\n'.join(rows)

    def beat(self, b, label=None):
        if not label:   # a scene after a story building's level waits until that building stands
            step = self.steps.get(b.get('waits_for'))
            label = f'After the {step["name"]} is placed' if step else PHASES.get(b['phase'], b['phase'])
        if b.get('visit_site'):
            label = f"Tap the {self.steps[b['visit_site']]['name']} after {b['checkpoint']}"
        if b.get('phase') == 'upgrade':
            label = 'When the building upgrade is earned'
        body = self.lines(b.get('lines', []))
        if v := b.get('variant'):
            name = self.steps[v['building']]['name']
            speaker = v['lines'][0]['speaker']
            condition = (f"After meeting {self.cast[speaker]['name']} at the {name}"
                         if speaker in self.residents else f'If {name} stands')
            body += f'<p class="pick">{esc(condition)}, line {v["index"]} becomes</p>{self.lines(v["lines"])}'
            if memory := v.get('memory'):
                question = self.questions[memory['answer']]
                body += f'<p class="pick">If you asked “{esc(question)}”, the reply is</p>{self.lines(memory["lines"])}'
        if b.get('note'):
            body = f'<p class="note">Journal: {esc(b["note"])}</p>' + body
        if b.get('choices'):
            opts = ''.join(f'<div class="choice"><div class="pick">Choice: {esc(c["label"])}</div>{self.lines(c["lines"])}</div>'
                           for c in b['choices'])
            body += f'<div class="prompt">{esc(b.get("prompt") or "The player chooses")}</div><div class="choices">{opts}</div>'
        return (f'<details class="beat" open><summary><span class="phase">{esc(label)}</span>'
                f'<code>{esc(b["key"])}</code><span class="count">{len(b.get("lines", []))} lines</span></summary>{body}</details>')

    def styles(self):
        return (''.join(f'.face-{self.game}-{who}{{background-image:url({src})}}' for who, src in self.portraits.items() if src)
                + ''.join(f'.ico-{self.game}-{name}{{background-image:url({src})}}' for name, src in self.icons.items()))

    def cast_strip(self, speaking_only=False):
        spoken = {}
        for b in self.d['beats']:
            for line in b.get('lines', []) + [l for c in b.get('choices') or [] for l in c['lines']]:
                spoken[line.get('speaker')] = spoken.get(line.get('speaker'), 0) + 1
        cards = ''.join(f'<figure class="person">{self.avatar(c["id"], "portrait")}<figcaption><b>{esc(c["name"])}</b>'
                        f'<span>{esc(c.get("role"))}</span><small>{spoken.get(c["id"], 0)} lines</small></figcaption></figure>'
                        for c in self.d['cast'] if spoken.get(c['id']) or not speaking_only)
        return f'<style>{self.styles()}</style><section class="cast">{cards}</section>'


def price_text(parts):
    return ' + '.join(f'{p["amount"]} {esc(p["name"])}' for p in parts)


def gets_html(page, step):
    """What a ladder purchase changes on later boards, one row per change."""
    rows = []
    for g in step['gets']:
        kind = g['type']
        if kind == 'bonus':
            text = (f'Upgrade <b>{esc(g["name"])}</b> replaces {esc(g["upgrades"])}' if g.get('upgrades')
                    else f'New bonus <b>{esc(g["name"])}</b>') + f' <span class="fx">{esc(g["effect"])}</span>'
        elif kind == 'piece':
            text = f'New piece <b>{esc(g["name"])}</b> <span class="fx">+{g["amount"]} {esc(g["currency"])} each</span>'
        elif kind == 'charge':
            text = f'New piece <b>{esc(g["name"])}</b> <span class="fx">Match it to charge a booster. {esc(g["effect"])}</span>'
        elif kind == 'opening':
            text = f'<b>+1 {esc(g["name"])}</b> on every board <span class="fx">{esc(g["effect"])}</span>'
        elif kind == 'moves':
            text = f'<b>+{g["amount"]} moves</b> on every board'
        elif kind == 'faster':
            text = f'Boosters charge <b>×{g["amount"]}</b> as fast'
        else:
            text = f'<b>+{g["amount"]} {esc(g["currency"])}</b> on every win'
        rows.append(f'<li>{page.icon(g.get("icon"))}<span>{text}</span></li>')
    return f'<ul class="gets">{"".join(rows)}</ul>' if rows else ''


def level_card(page, lv, beats, opens=()):
    """One board: its capture, goal, the pieces that pay on it and its scenes."""
    game, n = page.game, lv['n']
    board = picture(FRAMES / f'scenario-{game}-board-{n:02d}.png', 200)
    shot = f'<img class="board" src="{board}" alt="Board {n}">' if board else '<div class="board missing">run with --capture</div>'
    chips = []
    if lv.get('plaques'):
        chips.append(f'<span class="chip">Clear <b>{lv["plaques"]} blue plaques</b></span>')
    story_piece = lv.get('story_piece')
    if isinstance(story_piece, str):
        chips.append(f'<span class="chip">Story piece <b>{esc(STORY_PIECE_NAMES[story_piece])}</b></span>')
    elif story_piece:
        chips.append(f'<span class="chip">Story find <b>{esc(story_piece["name"])}</b></span>')
    for step in opens:
        sprite = picture(page.data_dir / step['sprite'], 120, 'PNG') if step.get('sprite') else None
        img = f'<img src="{sprite}" alt="">' if sprite else ''
        chips.append(f'<span class="chip fund" title="{esc(step.get("about"))}">{img}Opens <b>{esc(step["name"])}</b>'
                     f'&nbsp;· {price_text(step["price"])}</span>')
    for item in lv.get('resources') or []:
        pays = f'charges a {item["charges"]}' if item.get('charges') else f'+{item["yield"]} {esc(item["currency"])}'
        chips.append(f'<span class="chip">{page.icon(item.get("icon"))}{esc(item["name"])} <b>{pays}</b></span>')
    reveal = ''
    if game == 'relic-rush' and n == 9 and (result := picture(FRAMES / 'scenario-relic-rush-resources.png', 300)):
        reveal += (f'<figure class="reveal"><img src="{result}" alt="Resources and the next building on the results card">'
                   '<figcaption>The results card: the resources banked on the clear and the next building.</figcaption></figure>')
    reveal_spec = lv.get('reveal') or {}
    if reveal_spec.get('picture'):
        # Each game keeps its story pictures in its own folder under data/.
        found = sorted(page.data_dir.rglob(f'{lv["reveal"]["picture"]}.jpg'))
        src = picture(found[0], 360) if found else None
        if src:
            floor = f' ({esc(lv["reveal"]["floor"])} floor)' if lv['reveal'].get('floor') else ''
            reveal = f'<figure class="reveal"><img src="{src}" alt=""><figcaption>Story picture revealed on the board{floor}</figcaption></figure>'
    if lv.get('signal') == 'cliff':
        reveal += '<p class="meta">First clear: the light under the cliff waits, then flashes three times.</p>'
    elif lv.get('signal') == 'landing':
        scene = picture(FRAMES / 'scenario-relic-rush-landing.png', 360)
        if not scene:
            scene = picture(page.data_dir / 'story/finale/safe-landing.jpg', 360)
        if scene:
            reveal += (f'<figure class="reveal"><img src="{scene}" alt="Ines lifting her lantern on the safe landing">'
                       '<figcaption>First clear: Ines waits and answers from the landing with the same three flashes.</figcaption></figure>')
    beat_html = ''.join(page.beat(b) for b in sorted(beats, key=lambda b: PHASE_ORDER.get(b['phase'], 9)))
    materials = ', '.join(name.replace('-', ' ') for name in lv.get('materials') or [])
    materials_html = f'<p class="meta">Board materials · {esc(materials.capitalize())}</p>' if materials else ''
    return f'''<article class="step" id="{game}-{n}">
  <div class="media">{shot}</div>
  <div class="body">
    <h3><span class="num">{n}</span>{esc(lv["name"])}</h3>
    <p class="meta">{esc(lv.get("lesson"))} · {lv.get("moves")} moves</p>
    {materials_html}<div class="chips">{"".join(chips)}</div>{reveal}
    {beat_html or '<p class="quiet">No story beat.</p>'}
  </div>
</article>'''


def match3_section(data, title):
    page = Page(data)
    game = data['game']
    by_level = {}
    for b in data['beats']:
        by_level.setdefault(b['level'], []).append(b)
    cards = [level_card(page, lv, by_level.get(lv['n'], []), [s for s in data['ladder'] if s['after'] == lv['n']])
             for lv in data['levels']]
    total = sum(len(b.get('lines', [])) for b in data['beats'])
    return (f'<section class="game" id="{game}"><h2>{esc(title)}</h2>'
            f'<p class="sum">{len(data["levels"])} levels · {len(data["beats"])} story beats · {total} lines</p>'
            f'{page.cast_strip()}{"".join(cards)}</section>')


def purchase_card(page, step, beats):
    """One ladder purchase: who needs it, its price, what it changes and the scene that waits for it."""
    sprite = picture(page.data_dir / step['sprite'], 200, 'PNG') if step.get('sprite') else None
    img = f'<img class="sprite" src="{sprite}" alt="">' if sprite else ''
    quest = step.get('quest')
    quest_html = (f'<div class="quest"><b>{esc(quest["title"])}</b><p>{esc(quest["request"])}</p></div>' if quest
                  else '<p class="quiet">No quest card text: the build card shows the shop line below.</p>')
    kind = 'Story building' if step['story'] else 'Ladder building'
    beat_html = ''.join(page.beat(b) for b in beats)
    return f'''<article class="step buy" id="{page.game}-buy-{step["position"]}">
  <div class="media">{img}</div>
  <div class="body">
    <h3><span class="num">Purchase {step["position"]}</span>{esc(step["name"])}</h3>
    <p class="meta">{kind} · opens after level {step["after"]} · changes boards from level {step["from"]}</p>
    {quest_html}
    <div class="chips"><span class="chip price">Price <b>{price_text(step["price"])}</b></span></div>
    <p class="meta">Shop line · {esc(step.get("about"))}</p>
    {gets_html(page, step)}
    {beat_html or '<p class="quiet">No scene waits for this building.</p>'}
  </div>
</article>'''


def epoch_section(data, title, number):
    """One epoch: four ladder purchases, the levels up to the last of them and their scenes."""
    game, ladder = data['game'], data['ladder']
    steps = ladder[4 * (number - 1):4 * number]
    if not steps:
        sys.exit(f'{game} has no epoch {number}: its ladder has {len(ladder)} purchases')
    first = ladder[4 * (number - 1) - 1]['after'] + 1 if number > 1 else 1
    last = max(first, steps[-1]['after'])
    keys = {s['key'] for s in steps}
    beats = [b for b in data['beats']
             if b.get('waits_for') in keys or not b.get('waits_for') and first <= b['level'] <= last]
    page = Page(dict(data, beats=beats))
    waiting = {key: [b for b in beats if b.get('waits_for') == key] for key in keys}

    cards = [purchase_card(page, s, waiting[s['key']]) for s in steps if s['after'] < first]   # open since the last epoch
    for lv in data['levels'][first - 1:last]:
        cards.append(level_card(page, lv, [b for b in beats if b['level'] == lv['n'] and not b.get('waits_for')]))
        cards += [purchase_card(page, s, waiting[s['key']]) for s in steps if s['after'] == lv['n']]

    slots = []
    for s in steps:
        sprite = picture(page.data_dir / s['sprite'], 120, 'PNG') if s.get('sprite') else None
        img = f'<img src="{sprite}" alt="">' if sprite else ''
        quest = f'<span class="task">{esc(s["quest"]["title"])}</span>' if s.get('quest') else ''
        slots.append(f'<li class="slot"><a href="#{game}-buy-{s["position"]}">{img}<span><small>Purchase {s["position"]} · after level {s["after"]}</small>'
                     f'<b>{esc(s["name"])}</b>{quest}<span class="cost">{price_text(s["price"])}</span></span></a></li>')
    town = picture(FRAMES / f'scenario-{game}-town-epoch-{number}.png', 320)
    town_html = (f'<figure class="town"><img src="{town}" alt="The town with the epoch\'s buildings">'
                 f'<figcaption>The town once purchase {steps[-1]["position"]} is confirmed.</figcaption></figure>' if town
                 else '<div class="town missing">run with --capture</div>')
    totals = {}
    for s in steps:
        for part in s['price']:
            totals[part['name']] = totals.get(part['name'], 0) + part['amount']
    cost = price_text([{'name': name, 'amount': totals[name]} for name in data['currencies'] if name in totals])
    lines = sum(len(b.get('lines', [])) for b in beats)
    return (f'<section class="game" id="{game}"><h2>{esc(title)} · Epoch {number}</h2>'
            f'<p class="sum">Purchases {steps[0]["position"]}–{steps[-1]["position"]} · levels {first}–{last} · '
            f'{len(beats)} scenes · {lines} lines · {cost} in all</p>'
            f'<div class="epoch">{town_html}<ol class="slots">{"".join(slots)}</ol></div>'
            f'{page.cast_strip(speaking_only=True)}{"".join(cards)}</section>')


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
.ico{width:40px;height:40px;flex:none;display:inline-block;background:center/contain no-repeat}
.narration{color:var(--muted);font-style:italic;margin:8px 0 8px 48px}
.epoch{display:grid;grid-template-columns:320px 1fr;gap:18px;align-items:start;margin-bottom:24px}
.town{margin:0}.town img{width:100%;border-radius:14px;display:block}.town figcaption{color:var(--muted);font-size:13px;margin-top:4px}
.town.missing{height:160px;display:flex;align-items:center;justify-content:center;background:var(--chip);color:var(--muted);font-size:13px;border-radius:14px}
.slots{list-style:none;margin:0;padding:0;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.slot{background:var(--card);border:1px solid var(--line);border-radius:12px}
.slot a{display:grid;grid-template-columns:96px 1fr;gap:12px;align-items:center;padding:10px;color:inherit;text-decoration:none}
.slot img{width:96px;height:96px;object-fit:contain}.slot a>span{display:flex;flex-direction:column;gap:2px;min-width:0}
.slot small,.slot .cost{color:var(--muted);font-size:13px}.slot .task{color:var(--accent);font-weight:600}
.step,.game{scroll-margin-top:110px}.step.buy{border-left:4px solid var(--accent)}.sprite{width:200px;height:200px;object-fit:contain;display:block}
.quest{background:var(--chip);border-left:3px solid var(--accent);border-radius:6px;padding:6px 10px;margin:0 0 8px}.quest p{margin:2px 0 0}
.chip.price{padding-left:12px}
.gets{list-style:none;margin:0 0 8px;padding:0;display:grid;gap:4px}.gets li{display:flex;gap:10px;align-items:center}.fx{color:var(--muted)}
@media (max-width:760px){.epoch{grid-template-columns:1fr}.town{max-width:320px}.slots{grid-template-columns:1fr}}
@media (max-width:640px){.step{grid-template-columns:1fr}.board{width:160px}.sprite{width:140px;height:140px}}
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--capture', action='store_true', help='capture every match-3 board first')
    ap.add_argument('--games', nargs='+', choices=GAMES, help='default: every game, or the match-3 games with --epoch')
    ap.add_argument('--epoch', type=int, metavar='N', help='only epoch N of the match-3 games: purchases 4N-3 to 4N')
    ap.add_argument('--out', help='default: build/scenarios/index.html, or epoch-N.html with --epoch')
    args = ap.parse_args()
    games = args.games or [g for g in GAMES if g in MATCH3 or not args.epoch]
    if args.epoch is not None and (args.epoch < 1 or set(games) - MATCH3):
        ap.error('--epoch takes a number from 1 and covers the match-3 games only')
    heading = f'Epoch {args.epoch} overview' if args.epoch else 'Game scenarios'
    sections, links = [], []
    for game in games:
        if args.capture and game in MATCH3:
            capture(game)
        data = dump(game)
        config = ROOT / f'games/{game}/lua/game_config.lua'   # app = {title = "...", ...}
        title = re.search(r'\bapp = \{title = "([^"]*)"', config.read_text()).group(1) if game in MATCH3 else 'Nile Archive'
        if args.epoch:
            sections.append(epoch_section(data, title, args.epoch))
        else:
            sections.append(match3_section(data, title) if data['kind'] == 'match3' else nile_section(data, title))
        links.append(f'<a href="#{game}">{esc(title)}</a>')
    page = (f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1"><title>{heading.title()}</title>'
            f'<style>{CSS}</style></head><body><header><h1>{heading}</h1><nav>{"".join(links)}</nav></header>'
            f'<main>{"".join(sections)}</main></body></html>\n')
    out = Path(args.out or ROOT / 'build/scenarios' / (f'epoch-{args.epoch}.html' if args.epoch else 'index.html'))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page)
    print(f'{out} ({len(page) / 1e6:.1f} MB)')


if __name__ == '__main__':
    main()
