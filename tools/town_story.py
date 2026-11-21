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

    def lua(self):
        return '{%s, %s}' % (quote(self.speaker), quote(self.text))


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


def compile_town(source, beats, speakers):
    by_key = {beat['key']: beat for beat in beats}
    purchases, callbacks, residents, visits = {}, {}, {}, {}
    for block in re.split(r'^\*\*(?=Placed |With |Visit )', source, flags=re.M)[1:]:
        heading, body = block.split('**\n', 1)
        action, building, *target = heading.split()
        assert re.fullmatch(r'[a-z_]+', building), heading
        if action == 'With':
            key, number = target
            index = int(number)
            assert key in by_key and 1 <= index <= len(by_key[key]['lines']), heading
            assert (key, index) not in callbacks, 'Duplicate target line: ' + heading
            parts = re.split(r'^\*\*If (.+?)\*\*$', body, flags=re.M)
            default = single_line(parts[0], speakers)
            branches = [(condition, single_line(reply, speakers)) for condition, reply in zip(parts[1::2], parts[2::2])]
            callbacks[key, index] = (building, default, branches)
        elif action == 'Visit':
            checkpoint, = target
            assert building in residents, 'Declare the resident before ' + heading
            resident, invitation = residents[building]
            stages = visits.setdefault(building, [])
            if stages:
                assert checkpoint in by_key and by_key[checkpoint]['level'] > stages[-1][1], heading
                level = by_key[checkpoint]['level']
            else:
                assert checkpoint == 'placed-' + building, heading
                level = by_key[invitation]['level']
            parts = re.split(r'^\*\*Ask (personal|story) \| ([^\n]+\?)\*\*$', body, flags=re.M)
            assert not parts[0].strip() and sorted(parts[1::3]) == ['personal', 'story'], heading
            options = []
            for topic, label, answer in zip(parts[1::3], parts[2::3], parts[3::3]):
                lines = speech(answer, speakers)
                assert any(line.speaker == speakers[resident] for line in lines), label
                options.append((topic, label, lines))
            stages.append((checkpoint, level, options))
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
        output.extend('        ' + line.lua() + ',' for line in lines)
        output.append('    }},')

    answers = {}
    for site, stages in visits.items():
        for checkpoint, level, options in stages:
            key = 'visit-' + site + '-' + checkpoint
            output.append('    {key=%s, phase="visit", building=%s, checkpoint=%s, level=%d, prompt=%s, choices={' %
                          (quote(key), quote(site), quote(checkpoint), level, quote('Ask ' + residents[site][0])))
            for topic, label, lines in options:
                # The story answer is the original visit. Keep its save key for returning players.
                answer_key = key if topic == 'story' else key + '.' + topic
                answers[site, checkpoint, topic] = (answer_key, level)
                output.append('        {key=%s, topic=%s, label=%s, lines={' %
                              (quote(answer_key), quote(topic), quote(label)))
                output.extend('            ' + line.lua() + ',' for line in lines)
                output.append('        }},')
            output.append('    }},')

    return compile_replies(callbacks, by_key, introductions, answers), output


def compile_replies(callbacks, beats, introductions, answers):
    """Resolve author-facing references once. First eligible reply wins for each line."""
    replies = {}
    for (beat, index), (site, default, branches) in callbacks.items():
        fields = f'index={index}, building={quote(site)}'
        if default.speaker in introductions:
            fields += ', introduction=' + quote(introductions[default.speaker])
        rules = replies.setdefault(beat, [])
        conditions = set()
        for condition, line in branches:
            words = condition.split()
            if len(words) == 3 and words[0] == 'asked':
                answer = (site, words[1], words[2])
                assert answer in answers, f'{beat}: unknown question {condition!r} at {site}'
                key, level = answers[answer]
            else:
                assert len(words) == 2 and words[0] == 'seen' and words[1] in beats, f'{beat}: unknown condition {condition!r}'
                key = words[1]
                level = beats[key]['level']
            assert level < beats[beat]['level'], f'{beat}: {condition!r} must precede the reply'
            assert key not in conditions and line.speaker == default.speaker, f'{beat}: conflicting reply for {condition!r}'
            conditions.add(key)
            rules.append('        {%s, when=%s, line=%s},' % (fields, quote(key), line.lua()))
        rules.append('        {%s, line=%s},' % (fields, default.lua()))
    return {beat: ', replies={\n' + '\n'.join(rules) + '\n    }' for beat, rules in replies.items()}
