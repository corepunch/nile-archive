#!/usr/bin/env python3
"""Recover named settings evidence for the lab; this is not a full VSO decoder."""
import hashlib
import json
import re
from zipfile import ZipFile

from sprite_metadata import SOURCE, entries, unwrap

RECORDS = {
    'base.zip': ('base_mm/Match3/vso/Assets/', {
        'ElementHoneySettings', 'ElementTargetGeneratorSettings', 'ElementBonusFishSettings',
        'ElementCarrySettings', 'ElementTrashSettings', 'ElementBornPointSettings', 'TargetGenerator'}),
    'packs/Match3_Settings.zip': ('Match3/Settings/', {
        'ElementColorBoxSettings', 'ElementTrashStoneSettings', 'ElementStatueSettings',
        'ElementCarryGeneratorSettings', 'ElementCookieBoxSettings'}),
}


def evidence():
    result = {}
    for archive, (prefix, names) in RECORDS.items():
        with ZipFile(SOURCE.parent / archive) as bundle:
            records = list(entries(bundle.read(prefix + 'Library.xml.meta')))
            payloads = {}
            for section, name, offset, size in records:
                if name not in names:
                    continue
                if section not in payloads:
                    payloads[section] = unwrap(bundle.read(prefix + section))
                payload = payloads[section][offset:offset + size]
                if len(payload) != size:
                    raise ValueError('Truncated settings record')
                words = sorted({m.decode() for m in re.findall(rb'[A-Za-z][A-Za-z0-9_:.-]{3,}', payload)})
                result[name] = {'archive': archive, 'section': section, 'offset': offset, 'bytes': size,
                                'sha256': hashlib.sha256(payload).hexdigest(), 'identifiers': words}
            missing = names - result.keys()
            if missing:
                raise ValueError(f'Missing original settings: {sorted(missing)}')
    return result


if __name__ == '__main__':
    print(json.dumps(evidence(), indent=2, sort_keys=True))
