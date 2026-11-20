"""Compile the reviewed story's spoken lines; --check detects script/runtime drift."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'docs/story.md').read_text()
# The upgrades' scenes live in their own section; the level beats never see it.
section = re.search(r'^## Upgrades\n.*?(?=^## |\Z)', text, re.S | re.M)
upgrade_source = section[0] if section else ''
source = text.replace(upgrade_source, '')
source = re.sub(r'^## Citizens\n.*?(?=^## |\Z)', '', source, flags=re.S | re.M).split('## Crew requests')[0]   # also drop the superseded Citizens section
beats, beat, choice = [], None, None
speakers = {'Elena': 'elena', 'Mara': 'mara', 'Tomas': 'tomas', 'Adrian': 'adrian', 'Kessler': 'kessler', 'Ines': 'ines',
            'Ancient keeper': 'keeper', 'Marisol': 'marisol'}
# Rome 2's upgrade events (games/relic-rush/lua/user_events.lua) and the keeper who must speak in each.
keeper_speakers = {'man_03': 'Tomas', 'man_04': 'Tomas', 'man_02': 'Mara', 'man_01': 'Adrian', 'man_05': 'Marisol', 'man_06': 'Adrian', 'man_07': 'Elena', 'man_08': 'Tomas', 'man_09': 'Marisol', 'man_10': 'Adrian', 'man_11': 'Elena', 'man_12': 'Mara', 'man_13': 'Mara', 'man_14': 'Elena', 'man_15': 'Adrian', 'man_16': 'Tomas'}
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
        assert heading[1] in keeper_speakers, 'unknown upgrade event ' + heading[1]
        upgrade = {'key': 'upgrade-' + heading[1], 'event': heading[1], 'title': heading[2].strip(), 'building': heading[3].strip(), 'lines': []}
        upgrades.append(upgrade)
    spoken = re.match(r'- \*\*(' + '|'.join(speakers) + r')(?: \((thought|shout)\))?:\*\* (.+)', line)
    if upgrade and line.startswith('- **') and ':**' in line:
        assert spoken, 'Relic Rush dialogue requires a named cast member: ' + line
    if spoken and upgrade:
        upgrade['lines'].append((speakers[spoken[1]], spoken[3], spoken[2]))
assert len({c['event'] for c in upgrades}) == len(upgrades), 'an upgrade has two scenes'
for c in upgrades:
    assert c['lines'] and len(c['lines']) <= 48, c['key'] + ' needs spoken lines'
    assert speakers[keeper_speakers[c['event']]] in {who for who, _, _ in c['lines']}, \
        c['key'] + ' must have its keeper (' + keeper_speakers[c['event']] + ') speak'
    assert all(len(text) <= 100 for _, text, _ in c['lines']), c['key'] + ' has a line over 100 characters'
# One beat after every expedition's first clear and one scene per story restoration.
keys = [b['key'] for b in beats]
assert len(set(keys)) == len(keys), 'a level has two beats of one phase'
assert {b['level'] for b in beats if b['phase'] == 'after'} == set(range(1, 101))
assert {b['level'] for b in beats if b['phase'] == 'restore'} == {1, 16, 21, 36, 41, 46, 61, 66, 91, 96}
assert all(b['lines'] and len(b['lines']) <= 48 for b in beats)
assert all(bool(b.get('prompt')) == bool(b['choices']) for b in beats)
assert all(len({c['id'] for c in b['choices']}) == len(b['choices']) and all(c['lines'] for c in b['choices']) for b in beats)
assert all(len(text) <= 100 for b in beats for group in [b['lines']] + [c['lines'] for c in b['choices']] for _, text, _ in group)
quote = lambda s: json.dumps(s, ensure_ascii=False)
def emit_lines(items, indent):
    return [indent + '{%s, %s%s},' % (quote(who), quote(text), ', story.' + kind.upper() if kind else '')
            for who, text, kind in items]
lines = ['-- Generated by tools/prepare_story.py from docs/story.md; edit the reviewed script.', 'return {']
for b in beats:
    building = ', building=' + quote(b['building']) if 'building' in b else ''
    lines.append('    {key=%s, phase=%s, level=%d%s, lines={' % (quote(b['key']), quote(b['phase']), b['level'], building))
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
