#!/usr/bin/env python3
"""Inventory generator syntax directly from the original archive, without extracting it."""
import collections
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from zipfile import ZipFile

from extract_archives import Zstd, read_archive
from story_index import SOURCE


def evidence():
    with ZipFile(SOURCE) as bundle:
        archive = bundle.read('base_mm/fs_archives/match3levels.zstd')
    codec = Zstd()
    try:
        dictionary, entries = read_archive(archive, codec)
        tokens, properties, palettes = collections.Counter(), collections.Counter(), collections.Counter()
        examples, conflicts, loops = {}, [], collections.Counter()
        files = collections.Counter()
        digest = hashlib.sha256()
        for path, packed, size in entries:
            data = codec.unpack(packed, size, dictionary)
            name = str(path)
            digest.update(name.encode() + b'\0' + data)
            level = ET.fromstring(data).find('Level')
            for section in ['BornPatterns', 'ColorChipsPattern']:
                node = level.find(section)
                if node is not None:
                    files[section] += 1
                    for pattern in node:
                        string = pattern.get('str', '')
                        if section == 'ColorChipsPattern':
                            palettes[string] += 1
                            continue
                        loops[str(pattern.get('isLooped'))] += 1
                        for token in re.findall(r'\[([^\]]*)\]', string):
                            tokens[token] += 1
                            examples.setdefault(token, name)
                        for prop in pattern.iter('propertyNode'):
                            properties[json.dumps(prop.attrib, sort_keys=True)] += 1
            for cell in level.iter('Cell'):
                for model in cell:
                    kind = model.get('modelId')
                    if kind not in ['ARTIFACT_GEN', 'PATTERN_COLOR_BORN']:
                        continue
                    files[kind + '_instances'] += 1
                    section = 'BornPatterns' if kind == 'ARTIFACT_GEN' else 'ColorChipsPattern'
                    patterns = level.find(section)
                    index = int(model.get('id'))
                    if patterns is None or not 0 <= index < len(patterns) or patterns[index].get('str') != model.get('pattern'):
                        conflicts.append({'file': name, 'cell': cell.attrib, 'model': model.attrib})
        return {'source': 'base.zip/base_mm/fs_archives/match3levels.zstd', 'archive_sha256': hashlib.sha256(archive).hexdigest(),
                'corpus_sha256': digest.hexdigest(), 'levels': len(entries), 'counts': dict(files),
                'tokens': dict(sorted(tokens.items())), 'token_examples': dict(sorted(examples.items())),
                'properties': [{'attributes': json.loads(key), 'occurrences': value} for key, value in sorted(properties.items())],
                'palettes': dict(sorted(palettes.items())), 'loops': dict(loops), 'reference_conflicts': conflicts,
                'original_runtime_verified': False}
    finally:
        codec.close()


if __name__ == '__main__':
    print(json.dumps(evidence(), indent=2, sort_keys=True))
