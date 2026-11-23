"""Compile town dialogue and link conditional replies against the campaign's story keys."""
import json
import re
from dataclasses import dataclass


def quote(value):
    return json.dumps(value, ensure_ascii=False)


@dataclass(frozen=True)
class Line:
    speaker: str
    text: str

def speech(body, speakers):
    lines = []
    for row in body.strip().splitlines():
        match = re.fullmatch(r'- \*\*(.+?):\*\* (.+)', row)
        assert match and match[1] in speakers and len(match[2]) <= 100, row
        lines.append(Line(speakers[match[1]], match[2]))
    assert 0 < len(lines) <= 48, body
    return lines


def single_line(body, speakers):
    lines = speech(body, speakers)
    assert len(lines) == 1, 'A conditional reply replaces one line: ' + body
    return lines[0]


def compile_town(source, beats, speakers, *, render_line):
    by_key = {beat['key']: beat for beat in beats}
    purchases, callbacks, residents = {}, {}, {}
    for block in re.split(r'^\*\*(?=Placed |With )', source, flags=re.M)[1:]:
        heading, body = block.split('**\n', 1)
        action, building, *target = heading.split()
        assert re.fullmatch(r'[a-z_]+', building), heading
        if action == 'With':
            key, number = target
            index = int(number)
            assert key in by_key and 1 <= index <= len(by_key[key]['lines']), heading
            assert (key, index) not in callbacks, 'Duplicate target line: ' + heading
            callbacks[key, index] = (building, single_line(body, speakers))
        else:
            if target:
                verb, name, invitation = target
                assert verb == 'introduces' and invitation in by_key and name in speakers, heading
                residents[building] = (name, invitation)
            assert building not in purchases, heading
            purchases[building] = speech(body, speakers)

    output, introductions = [], {}
    for building, lines in purchases.items():
        key = 'placed-' + building
        fields = ''
        if building in residents:
            name, invitation = residents[building]
            speaker = speakers[name]
            assert speaker not in introductions, 'Duplicate resident: ' + name
            introductions[speaker] = key
            fields = ', resident=%s, invitation=%s' % (quote(speaker), quote(invitation))
        output.append('    {key=%s, phase="placed", building=%s%s, lines={' %
                      (quote(key), quote(building), fields))
        output.extend('        ' + render_line(line) + ',' for line in lines)
        output.append('    }},')

    replies = {}
    for (beat, index), (building, line) in callbacks.items():
        fields = f'index={index}, building={quote(building)}'
        if line.speaker in introductions:
            fields += ', introduction=' + quote(introductions[line.speaker])
        replies.setdefault(beat, []).append('        {%s, line=%s},' % (fields, render_line(line)))
    return {beat: ', replies={\n' + '\n'.join(rules) + '\n    }' for beat, rules in replies.items()}, output
