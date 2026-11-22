"""Compile the reviewed story's spoken lines; --check detects script/runtime drift."""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from town_story import Line, compile_town, quote

text = (ROOT / 'docs/story.md').read_text()
# The upgrades' scenes live in their own section; the level beats never see it.
section = re.search(r'^## Upgrades\n.*?(?=^## |\Z)', text, re.S | re.M)
upgrade_source = section[0] if section else ''
town_source = re.search(r'^## Town dialogue\n.*?(?=^## |\Z)', text, re.S | re.M)[0]
source = text.replace(upgrade_source, '').replace(town_source, '')
source = re.sub(r'^## Citizens\n.*?(?=^## |\Z)', '', source, flags=re.S | re.M).split('## Crew requests')[0]   # also drop the superseded Citizens section
beats, beat, choice = [], None, None
speakers = {name: name.lower() for name in ('Sela', 'Oren', 'Tavi')}
# The runtime owns the keeper and title of each optional upgrade.
upgrade_data = (ROOT / 'lua/user_events.lua').read_text()
keepers = dict(re.findall(r'\{id="(man_\d+)", building="[^"]+", title="[^"]+", keeper="([^"]+)"', upgrade_data))
for line in source.splitlines():
    heading = re.match(r'\*\*(Before level|Level|After restoration) (\d+)', line)
    if heading:
        phase = {'Before level': 'before', 'Level': 'after', 'After restoration': 'restore'}[heading[1]]
        level = int(heading[2])
        key = f'{phase}-{level:02}'
        beat = {'key': key, 'phase': phase, 'level': level, 'lines': [], 'choices': []}
        if phase == 'restore':
            site = re.fullmatch(r'\*\*After restoration \d+ · ([^*]+)\*\*', line)
            assert site, 'name the purchased building in each restoration heading: ' + line
            beat['building'] = site[1]
        beats.append(beat)
        choice = None
    prompt = re.match(r'Choice prompt: (.+)', line)
    if prompt and beat:
        beat['prompt'] = prompt[1]
    option = re.match(r'### Choice: ([a-z0-9_-]+) \| (.+)', line)
    if option and beat:
        choice = {'id': option[1], 'label': option[2], 'lines': []}
        beat['choices'].append(choice)
    spoken = re.match(r'- \*\*(' + '|'.join(speakers) + r')(?: \((thought|shout)\))?:\*\* (.+)', line)
    if beat and line.startswith('- **') and ':**' in line:
        assert spoken, 'Relic Rush dialogue requires a named cast member: ' + line
    if spoken and beat:
        (choice['lines'] if choice else beat['lines']).append((speakers[spoken[1]], spoken[3], spoken[2]))
upgrades, upgrade = [], None
for line in upgrade_source.splitlines():
    heading = re.match(r'\*\*Upgrade (man_\d\d) · ([^·*]+) · ([^*]+)\*\*\s*$', line)
    if line.startswith('**Upgrade'):
        assert heading, 'write each upgrade heading as **Upgrade man_NN · <title> · <Building name>**: ' + line
        assert heading[1] in keepers, 'unknown upgrade event ' + heading[1]
        upgrade = {'key': 'upgrade-' + heading[1], 'event': heading[1], 'title': heading[2].strip(), 'building': heading[3].strip(), 'lines': []}
        upgrades.append(upgrade)
    spoken = re.match(r'- \*\*(' + '|'.join(speakers) + r')(?: \((thought|shout)\))?:\*\* (.+)', line)
    if upgrade and line.startswith('- **') and ':**' in line:
        assert spoken, 'Relic Rush dialogue requires a named cast member: ' + line
    if spoken and upgrade:
        upgrade['lines'].append((speakers[spoken[1]], spoken[3], spoken[2]))
assert len({c['event'] for c in upgrades}) == len(upgrades) == len(keepers), 'an upgrade has two scenes'
for c in upgrades:
    assert c['lines'] and len(c['lines']) <= 48, c['key'] + ' needs spoken lines'
    assert keepers[c['event']] in {who for who, _, _ in c['lines']}, \
        c['key'] + ' must have its keeper (' + keepers[c['event']] + ') speak'
    assert all(len(text) <= 100 for _, text, _ in c['lines']), c['key'] + ' has a line over 100 characters'
# Quiet boards need no beat. Bookend the campaign and cover every story restoration.
keys = [b['key'] for b in beats]
assert len(set(keys)) == len(keys), 'a level has two beats of one phase'
assert keys[0] == 'before-01' and keys[-1] == 'after-100'
assert all(1 <= b['level'] <= 100 for b in beats)
assert {b['level'] for b in beats if b['phase'] == 'restore'} == {1, 16, 21, 36, 41, 46, 61, 66, 91, 96}
assert all(b['lines'] and len(b['lines']) <= 48 for b in beats)
assert all(bool(b.get('prompt')) == bool(b['choices']) for b in beats)
assert all(len({c['id'] for c in b['choices']}) == len(b['choices']) and all(c['lines'] for c in b['choices']) for b in beats)
assert all(len(text) <= 100 for b in beats for group in [b['lines']] + [c['lines'] for c in b['choices']] for _, text, _ in group)
def emit_speech(line, listener=None, *, mode=None):
    options = []
    if mode:
        options.append('mode=story.' + mode.upper())
    if listener:
        options.append('listener=' + quote(listener))
    if options:
        return '%s(%s, {%s})' % (line.speaker, quote(line.text), ', '.join(options))
    return '%s %s' % (line.speaker, quote(line.text))


def emit_lines(items, indent):
    return [indent + emit_speech(Line(who, text), mode=kind) + ',' for who, text, kind in items]


replies, town_beats = compile_town(town_source, beats, speakers, render_line=emit_speech)
lines = ['-- Generated by tools/prepare_story.py from docs/story.md; edit the reviewed script.',
         'local cast = require("story_cast").by_id']
lines.extend(f'local {speaker} = cast.{speaker}' for speaker in speakers.values())
lines.extend(['', 'return {'])
for b in beats:
    building = ', building=' + quote(b['building']) if 'building' in b else ''
    lines.append('    {key=%s, phase=%s, level=%d%s, lines={' % (quote(b['key']), quote(b['phase']), b['level'], building + replies.get(b['key'], '')))
    lines.extend(emit_lines(b['lines'], '        '))
    if b['choices']:
        lines.append('    }, prompt=%s, choices={' % quote(b['prompt']))
        for c in b['choices']:
            lines.append('        {id=%s, label=%s, lines={' % (quote(c['id']), quote(c['label'])))
            lines.extend(emit_lines(c['lines'], '            '))
            lines.append('        }},')
        lines.append('    }},')
    else:
        lines.append('    }},')
for c in upgrades:
    lines.append('    {key=%s, phase="upgrade", event=%s, title=%s, building=%s, lines={' % (quote(c['key']), quote(c['event']), quote(c['title']), quote(c['building'])))
    lines.extend(emit_lines(c['lines'], '        '))
    lines.append('    }},')
lines.extend(town_beats)
lines.append('}')
content = '\n'.join(lines) + '\n'
path = ROOT / 'lua/story_content.lua'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
if args.check:
    assert path.read_text() == content, 'Story changed: run python3 games/relic-rush/tools/prepare_story.py'
else:
    path.write_text(content)
count = sum(len(b['lines']) + sum(len(c['lines']) for c in b['choices']) for b in beats)
print(f'Relic Rush: {len(beats)} story beats, {count} dialogue lines, {len(upgrades)} upgrade scenes')
