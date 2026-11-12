#!/usr/bin/env python3
"""Print a reproducible Markdown index of bundled board model and target IDs."""
from collections import Counter
import xml.etree.ElementTree as ET

from level_viewer import SOURCE


def main():
    files = sorted(SOURCE.rglob('*.xml'))
    if not files:
        raise SystemExit('No board XML files found; run extract_archives.py first.')
    specs = [('Model IDs', 'Model', 'modelId'), ('Target types', 'target', 'type')]
    counts = {tag: Counter() for _, tag, _ in specs}
    examples = {tag: {} for _, tag, _ in specs}
    for path in files:
        level = ET.parse(path).getroot().find('Level')
        if level is None:
            raise ValueError(f'No Level element in {path}')
        relative = path.relative_to(SOURCE).as_posix()
        for _, tag, attribute in specs:
            ids = {element.attrib[attribute] for element in level.iter(tag)}
            counts[tag].update(ids)
            for identifier in ids:
                examples[tag].setdefault(identifier, relative)

    print('# Homescapes bundled board IDs\n')
    print(f'Computed from {len(files):,} level XML files in Homescapes 9.2.601. '
          'Counts are files containing the ID, and example paths are relative '
          'to `Match3/Levels/`. IDs can represent the board structure, '
          'art variants or goals as well as player-facing mechanics. '
          'See [the comparison](MECHANICS.md) for verified rules.\n')
    print('Regenerate with `python3 tools/homescapes-reference/board_ids.py`.')
    for title, tag, _ in specs:
        print(f'\n## {title} ({len(counts[tag])})\n')
        print('| ID | Files | Example |\n| --- | ---: | --- |')
        for identifier, count in sorted(counts[tag].items()):
            print(f'| `{identifier}` | {count:,} | `{examples[tag][identifier]}` |')


if __name__ == '__main__':
    main()
