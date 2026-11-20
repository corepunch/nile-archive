"""Compile the reviewed story's spoken lines; --check detects script/runtime drift."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'docs/story.md').read_text()
# The citizens' arrival scenes live in their own section; the level beats never see it.
section = re.search(r'^## Citizens\n.*?(?=^## |\Z)', text, re.S | re.M)
citizen_source = section[0] if section else ''
source = text.replace(citizen_source, '').split('## Crew requests')[0]
beats, beat, choice = [], None, None
speakers = {'Elena': 'elena', 'Mara': 'mara', 'Tomas': 'tomas', 'Adrian': 'adrian', 'Kessler': 'kessler', 'Ines': 'ines',
            'Ancient keeper': 'keeper',
            'Lupe': 'lupe', 'Bastian': 'bastian', 'Joaquín': 'joaquin', 'Dita': 'dita', 'Marisol': 'marisol',
            'Basile': 'basile', 'Hana': 'hana', 'Ferro': 'ferro', 'Nilo': 'nilo', 'Zaza': 'zaza', 'Ruth': 'ruth',
            'Ulla': 'ulla', 'Pike': 'pike', 'Amani': 'amani', 'Sato': 'sato', 'Ixchel': 'ixchel'}
# Rome 2's citizen events (games/relic-rush/lua/user_events.lua) and the speaker each one must have.
citizen_speakers = {'man_03': 'Lupe', 'man_04': 'Bastian', 'man_02': 'Joaquín', 'man_01': 'Dita', 'man_05': 'Marisol',
                    'man_06': 'Basile', 'man_07': 'Hana', 'man_08': 'Ferro', 'man_09': 'Nilo', 'man_10': 'Zaza',
                    'man_11': 'Ruth', 'man_12': 'Ulla', 'man_13': 'Pike', 'man_14': 'Amani', 'man_15': 'Sato',
                    'man_16': 'Ixchel'}
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
citizens, citizen = [], None
for line in citizen_source.splitlines():
    heading = re.match(r'\*\*Citizen (man_\d\d) · ([^·*]+) · ([^*]+)\*\*\s*$', line)
    if line.startswith('**Citizen'):
        assert heading, 'write each citizen heading as **Citizen man_NN · <name> · <building>**: ' + line
        assert heading[1] in citizen_speakers, 'unknown citizen event ' + heading[1]
        citizen = {'key': 'citizen-' + heading[1], 'event': heading[1], 'building': heading[3].strip(), 'lines': []}
        citizens.append(citizen)
    spoken = re.match(r'- \*\*(' + '|'.join(speakers) + r')(?: \((thought|shout)\))?:\*\* (.+)', line)
    if citizen and line.startswith('- **') and ':**' in line:
        assert spoken, 'Relic Rush dialogue requires a named cast member: ' + line
    if spoken and citizen:
        citizen['lines'].append((speakers[spoken[1]], spoken[3], spoken[2]))
assert len({c['event'] for c in citizens}) == len(citizens), 'a citizen has two scenes'
for c in citizens:
    assert c['lines'] and len(c['lines']) <= 48, c['key'] + ' needs spoken lines'
    assert speakers[citizen_speakers[c['event']]] in {who for who, _, _ in c['lines']}, \
        c['key'] + ' must have its citizen (' + citizen_speakers[c['event']] + ') speak'
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
for c in citizens:
    lines.append('    {key=%s, phase="citizen", event=%s, building=%s, lines={' % (quote(c['key']), quote(c['event']), quote(c['building'])))
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
print(f'Relic Rush: {len(beats)} story beats, {count} dialogue lines, {len(citizens)} citizen scenes')
