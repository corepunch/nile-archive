#!/usr/bin/env python3
"""Audit sprite coverage against every bundled board model and strength."""
from collections import Counter, defaultdict
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from level_viewer import SOURCE

MAPPINGS = Path(__file__).with_name('model_sprites.json')


def resolve(model, mapping):
    field = mapping.get('field')
    key = model.get(field, '') if field else ''
    variants = mapping.get('variants', {})
    if model.get('mirror') == 'true' and key + ':mirror' in variants:
        return variants[key + ':mirror']
    return variants.get(key, mapping.get('sprite'))


def report(paths, mappings):
    rows = defaultdict(Counter)
    examples = {}
    strengths = defaultdict(set)
    for path in paths:
        for item in ET.parse(path).iter('Model'):
            model = item.attrib
            name = model['modelId']
            mapping = mappings.get(name, {})
            image = resolve(model, mapping)
            status = mapping.get('status', 'identified') if image else 'unmapped'
            rows[name][status] += 1
            if 'level' in model:
                strengths[name].add(model['level'])
            if status != 'identified':
                examples.setdefault(name, path)
    return rows, examples, strengths


def main():
    paths = sorted(SOURCE.rglob('*.xml'))
    if not paths:
        raise SystemExit('No extracted levels. Run extract_archives.py first.')
    mappings = json.loads(MAPPINGS.read_text())
    rows, examples, strengths = report(paths, mappings)
    print('# Homescapes board sprite coverage\n')
    print(f'Counts are serialized model occurrences across {len(paths):,} board XML files. '
          'Identified counts use mapped original images. Material counts use a named texture or '
          'representative crop while the per-strength art remains unresolved. The table includes '
          'spawn and layout markers alongside visible objects.\n')
    print('Generate with `python3 tools/homescapes-reference/sprite_coverage.py`.\n')
    print('| Model | Serialized levels | Identified | Material | Unmapped | Example to verify |')
    print('| --- | --- | ---: | ---: | ---: | --- |')
    for name, counts in sorted(rows.items()):
        levels = ', '.join(sorted(strengths[name], key=int))
        path = examples.get(name)
        example = f'`{path.relative_to(SOURCE).as_posix()}`' if path else ''
        print(f'| `{name}` | {levels} | {counts["identified"]:,} | {counts["material"]:,} | '
              f'{counts["unmapped"]:,} | {example} |')


if __name__ == '__main__':
    main()
