"""Read confirmed purchases and conditional dialogue from a campaign's story script."""
import json
import re


def compile_town(source, beats, speakers):
    def quote(value):
        return json.dumps(value, ensure_ascii=False)

    by_key = {beat['key']: beat for beat in beats}
    purchases, variants = {}, {}
    for block in re.split(r'^\*\*(?=Placed |With )', source, flags=re.M)[1:]:
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
        else:
            assert not target and building not in purchases and 0 < len(lines) <= 48, heading
            purchases[building] = lines

    output = []
    for building, lines in purchases.items():
        output.append('    {key=%s, phase="placed", building=%s, lines={' %
                      (quote('placed-' + building), quote(building)))
        output.extend('        ' + line + ',' for line in lines)
        output.append('    }},')
    return variants, output
