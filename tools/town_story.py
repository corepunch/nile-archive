"""Read confirmed purchases and conditional dialogue from a campaign's story script."""
import json
import re


def compile_town(source, beats, speakers):
    def quote(value):
        return json.dumps(value, ensure_ascii=False)

    by_key = {beat['key']: beat for beat in beats}
    purchases, variants, residents = {}, {}, {}
    visits = {}
    for block in re.split(r'^\*\*(?=Placed |With |Visit )', source, flags=re.M)[1:]:
        heading, body = block.split('**\n', 1)
        action, building, *target = heading.split()
        assert re.fullmatch(r'[a-z_]+', building), heading
        lines = []
        for row in body.strip().splitlines():
            match = re.fullmatch(r'- \*\*(.+?):\*\* (.+)', row)
            assert match and len(match[2]) <= 100, row
            lines.append('{%s, %s}' % (quote(speakers[match[1]]), quote(match[2])))
        if action == 'With':
            key, number = target
            index = int(number)
            assert key not in variants and len(lines) == 1 and 1 <= index <= len(by_key[key]['lines']), heading
            variants[key] = ', variant={building=%s, index=%d, line=%s}' % (quote(building), index, lines[0])
        elif action == 'Visit':
            checkpoint, = target
            assert building in residents and 0 < len(lines) <= 48, heading
            stages = visits.setdefault(building, [])
            if stages:
                assert checkpoint in by_key and by_key[checkpoint]['level'] > stages[-1][1], heading
                level = by_key[checkpoint]['level']
            else:
                assert checkpoint == 'placed-' + building, heading
                level = by_key[residents[building][1]]['level']
            stages.append((checkpoint, level, lines))
        else:
            if target:
                verb, name, invitation = target
                assert verb == 'introduces' and invitation in by_key and name in speakers, heading
                residents[building] = (speakers[name], invitation)
            assert building not in purchases and 0 < len(lines) <= 48, heading
            purchases[building] = lines

    output = []
    def emit(key, phase, building, fields, lines):
        output.append('    {key=%s, phase=%s, building=%s%s, lines={' %
                      (quote(key), quote(phase), quote(building), fields))
        output.extend('        ' + line + ',' for line in lines)
        output.append('    }},')

    for building, lines in purchases.items():
        resident = residents.get(building)
        fields = ', resident=%s, invitation=%s' % tuple(map(quote, resident)) if resident else ''
        emit('placed-' + building, 'placed', building, fields, lines)
    for site, stages in visits.items():
        for checkpoint, level, lines in stages:
            fields = ', checkpoint=%s, level=%d' % (quote(checkpoint), level)
            emit('visit-' + site + '-' + checkpoint, 'visit', site, fields, lines)
    return variants, output
