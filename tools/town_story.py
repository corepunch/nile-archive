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

    def lua(self, listener=None):
        addressed = ', listener=' + quote(listener) if listener else ''
        return '{%s, %s%s}' % (quote(self.speaker), quote(self.text), addressed)


def paired_lines(lines, cast, indent, render_line):
    """Show the new pair together on their first line, even in the middle of a level."""
    listener, = cast - {lines[0].speaker}
    return [indent + render_line(line, listener if i == 0 else None) + ',' for i, line in enumerate(lines)]


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


def meeting_questions(blocks, sites, key, visits, residents, speakers, render_line):
    """Link the two accounts after reading both, so either can be written first."""
    questions = {}
    for site, source, label, body in zip(blocks[1::4], blocks[2::4], blocks[3::4], blocks[4::4]):
        assert site in sites and site in visits and (site, source) not in questions, f'{key}: invalid question at {site}'
        assert not source or (source in sites and source != site), f'{key}: invalid source {source} at {site}'
        lines = speech(body, speakers)
        assert any(line.speaker == speakers[residents[site][0]] for line in lines), label
        answer_key = key + '.' + site + ('.reply' if source else '')
        questions[site, source] = (answer_key, label, lines)

    output = []
    for (site, source), (answer_key, label, lines) in questions.items():
        fields = ''
        if source:
            assert (source, None) in questions and (site, None) in questions, f'{key}: both residents need a first account'
            heard = [quote(answer[0]) for (home, _), answer in questions.items() if home == source]
            fields = ', source=%s, heard_any={%s}' % (quote(residents[source][0]), ', '.join(heard))
        output.append('        {key=%s, building=%s, when=%s, topic="meeting"%s, label=%s, lines={' %
                      (quote(answer_key), quote(site), quote(key), fields, quote(label)))
        output.extend('            ' + render_line(line) + ',' for line in lines)
        output.append('        }},')
    return output


def recall_questions(blocks, sites, checkpoint, residents, speakers, render_line):
    homes = blocks[1::3]
    assert sorted(homes) == sorted(sites), f'{checkpoint}: write one final question at each home'
    output = []
    for site, label, body in zip(homes, blocks[2::3], blocks[3::3]):
        parts = re.split(r'^\*\*If heard ([a-z_]+)\*\*$', body, flags=re.M)
        lines = speech(parts[0], speakers)
        assert any(line.speaker == speakers[residents[site][0]] for line in lines), label
        output.append('        {key=%s, building=%s, when=%s, topic="recall", label=%s, lines={' %
                      (quote(checkpoint + '.' + site), quote(site), quote(checkpoint), quote(label)))
        output.extend('            ' + render_line(line) + ',' for line in lines)
        if len(parts) > 1:
            other, reply = parts[1:]
            alternate = speech(reply, speakers)
            assert other in sites and other != site, label
            assert [line.speaker for line in alternate] == [line.speaker for line in lines], label
            output.append('        }, replies={')
            for index, line in enumerate(alternate, 1):
                output.append('            {index=%d, building=%s, when=%s, line=%s},' %
                              (index, quote(other), quote(checkpoint + '.' + other), render_line(line)))
        output.append('        }},')
    return output


def compile_recall(body, sites, meeting, cast, speakers, level_beat, residents, render_line):
    body, *catchup = re.split(r'^\*\*Catch up in town\*\*$', body, flags=re.M)
    parts = re.split(r'^\*\*Heard ([a-z_]+)\*\*$', body, flags=re.M)
    histories = parts[1::2]
    assert not parts[0].strip() and sorted(histories) == sorted([*sites, 'neither', 'both']), \
        f'{meeting}: write one exchange for each listening history'
    checkpoint = meeting + '.' + level_beat['key']
    output = [', recall={key=%s, meeting=%s, exchanges={' % (quote(checkpoint), quote(meeting))]
    for history, exchange in zip(histories, parts[2::2]):
        lines = speech(exchange, speakers)
        assert {line.speaker for line in lines} == cast, f'{meeting}: both residents must speak in {history}'
        assert len(level_beat['lines']) + len(lines) <= 48, f'{meeting}: {history} exceeds the dialogue queue'
        output.append('        [%s]={' % quote(history))
        output.extend(paired_lines(lines, cast, '            ', render_line))
        output.append('        },')
    if catchup:
        town, = catchup
        blocks = re.split(r'^\*\*Ask at ([a-z_]+) \| ([^\n]+\?)\*\*$', town, flags=re.M)
        lines = speech(blocks[0], speakers)
        assert {line.speaker for line in lines} == cast, checkpoint
        output.append('    }, lines={')
        output.extend(paired_lines(lines, cast, '        ', render_line))
        output.append('    }, followups={')
        output.extend(recall_questions(blocks, sites, checkpoint, residents, speakers, render_line))
    output.append('    }}')
    return '\n'.join(output)


def compile_town(source, beats, speakers, *, render_line=Line.lua):
    by_key = {beat['key']: beat for beat in beats}
    purchases, callbacks, residents, visits = {}, {}, {}, {}
    meetings = {}
    for block in re.split(r'^\*\*(?=Placed |With |Visit |Meeting )', source, flags=re.M)[1:]:
        heading, body = block.split('**\n', 1)
        action, building, *target = heading.split()
        assert re.fullmatch(r'[a-z_]+', building), heading
        if action == 'Meeting':
            other, = target
            assert other != building and re.fullmatch(r'[a-z_]+', other), heading
            assert (building, other) not in meetings and (other, building) not in meetings, heading
            meetings[building, other] = body
        elif action == 'With':
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
        output.extend('        ' + render_line(line) + ',' for line in lines)
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
                output.extend('            ' + render_line(line) + ',' for line in lines)
                output.append('        }},')
            output.append('    }},')

    recalls = {}
    for sites, body in meetings.items():
        assert all(site in residents for site in sites), f'Unknown resident site in {sites}'
        key = 'meeting-' + '-'.join(sites)
        recall = re.split(r'^\*\*Recall ([\w-]+)\*\*$', body, flags=re.M)
        body = recall[0]
        followups = re.split(r'^\*\*Ask at ([a-z_]+)(?: after ([a-z_]+))? \| ([^\n]+\?)\*\*$', body, flags=re.M)
        parts = re.split(r'^\*\*If asked ([a-z_]+) ([\w-]+) (personal|story) (\d+)\*\*$', followups[0], flags=re.M)
        lines = speech(parts[0], speakers)
        cast = {speakers[residents[site][0]] for site in sites}
        assert {line.speaker for line in lines} == cast, f'{key}: both residents must speak'
        level = max(by_key[residents[site][1]]['level'] for site in sites)
        if len(recall) > 1:
            target, exchange = recall[1:]
            assert target in by_key and by_key[target]['phase'] == 'after' and by_key[target]['level'] > level, \
                f'{key}: recall needs a later level clear'
            assert target not in recalls, f'{target}: two meetings share a recall'
            assert {site for site, source in zip(followups[1::4], followups[2::4]) if not source} == set(sites), \
                f'{key}: both residents need a first account'
            recalls[target] = compile_recall(exchange, sites, key, cast, speakers, by_key[target], residents, render_line)
        output.append('    {key=%s, phase="meeting", sites={%s}, level=%d, lines={' %
                      (quote(key), ', '.join(map(quote, sites)), level))
        output.extend('        ' + render_line(line) + ',' for line in lines)
        if len(parts) > 1:
            output.append('    }, replies={')
            targets = set()
            for start in range(1, len(parts), 5):
                site, checkpoint, topic, number, body_line = parts[start:start + 5]
                index = int(number)
                question = (site, checkpoint, topic)
                assert site in sites and question in answers, f'{key}: unknown question {question}'
                answer, _ = answers[question]
                line = single_line(body_line, speakers)
                assert 1 <= index <= len(lines) and line.speaker == lines[index - 1].speaker, key
                assert (index, answer) not in targets, f'{key}: duplicate conditional line'
                targets.add((index, answer))
                output.append('        {index=%d, building=%s, when=%s, line=%s},' %
                              (index, quote(site), quote(answer), render_line(line)))
        if len(followups) > 1:
            output.append('    }, followups={')
            output.extend(meeting_questions(followups, sites, key, visits, residents, speakers, render_line))
        output.append('    }},')

    fields = compile_replies(callbacks, by_key, introductions, answers, render_line)
    for target, recall in recalls.items():
        fields[target] = fields.get(target, '') + recall
    return fields, output


def compile_replies(callbacks, beats, introductions, answers, render_line):
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
            rules.append('        {%s, when=%s, line=%s},' % (fields, quote(key), render_line(line)))
        rules.append('        {%s, line=%s},' % (fields, render_line(default)))
    return {beat: ', replies={\n' + '\n'.join(rules) + '\n    }' for beat, rules in replies.items()}
