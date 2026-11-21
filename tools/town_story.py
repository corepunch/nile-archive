"""Read confirmed purchases and conditional dialogue from a campaign's story script."""
import json
import re


def compile_town(source, beats, speakers):
    def quote(value):
        return json.dumps(value, ensure_ascii=False)

    def speech(body):
        lines = []
        for row in body.strip().splitlines():
            match = re.fullmatch(r'- \*\*(.+?):\*\* (.+)', row)
            assert match and len(match[2]) <= 100, row
            lines.append('{%s, %s}' % (quote(speakers[match[1]]), quote(match[2])))
        return lines

    by_key = {beat['key']: beat for beat in beats}
    purchases, variants, residents = {}, {}, {}
    visits = {}
    for block in re.split(r'^\*\*(?=Placed |With |Visit )', source, flags=re.M)[1:]:
        heading, body = block.split('**\n', 1)
        action, building, *target = heading.split()
        assert re.fullmatch(r'[a-z_]+', building), heading
        if action == 'With':
            lines = speech(body)
            key, number = target
            index = int(number)
            assert key not in variants and len(lines) == 1 and 1 <= index <= len(by_key[key]['lines']), heading
            variants[key] = ', variant={building=%s, index=%d, line=%s}' % (quote(building), index, lines[0])
        elif action == 'Visit':
            checkpoint, = target
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
                assert '- **' + resident + ':**' in answer, label
                lines = speech(answer)
                assert 0 < len(lines) <= 48, label
                options.append((topic, label, lines))
            stages.append((checkpoint, level, options))
        else:
            lines = speech(body)
            if target:
                verb, name, invitation = target
                assert verb == 'introduces' and invitation in by_key and name in speakers, heading
                residents[building] = (name, invitation)
            assert building not in purchases and 0 < len(lines) <= 48, heading
            purchases[building] = lines

    output = []
    for building, lines in purchases.items():
        fields = ''
        if building in residents:
            name, invitation = residents[building]
            fields = ', resident=%s, invitation=%s' % (quote(speakers[name]), quote(invitation))
        output.append('    {key=%s, phase="placed", building=%s%s, lines={' %
                      (quote('placed-' + building), quote(building), fields))
        output.extend('        ' + line + ',' for line in lines)
        output.append('    }},')
    for site, stages in visits.items():
        for checkpoint, level, options in stages:
            key = 'visit-' + site + '-' + checkpoint
            output.append('    {key=%s, phase="visit", building=%s, checkpoint=%s, level=%d, prompt=%s, choices={' %
                          (quote(key), quote(site), quote(checkpoint), level, quote('Ask ' + residents[site][0])))
            for topic, label, lines in options:
                # The story answer is the original visit. Keep its save key for returning players.
                answer_key = key if topic == 'story' else key + '.' + topic
                output.append('        {key=%s, topic=%s, label=%s, lines={' %
                              (quote(answer_key), quote(topic), quote(label)))
                output.extend('            ' + line + ',' for line in lines)
                output.append('        }},')
            output.append('    }},')
    return variants, output
