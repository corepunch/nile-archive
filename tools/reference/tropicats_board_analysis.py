#!/usr/bin/env python3
"""Summarize retained Tropicats campaign tiers without simulating play."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re

LAYERS = ('fields', 'tiles', 'stones', 'chains', 'crates', 'hiddenItems',
          'spawning', 'dropItems', 'climbers', 'portals', 'gemColors',
          'gemTypes', 'gemModifier', 'gemDirection')


def analyze(root):
    files = sorted(p for p in root.iterdir() if re.fullmatch(r'\d{4}[abc]', p.name))
    if len(files) != 8190:
        raise ValueError(f'Expected 8190 campaign tiers, found {len(files)}')
    presence = Counter()
    first = {}
    values = defaultdict(Counter)
    moves = defaultdict(list)
    tiers = defaultdict(dict)
    for p in files:
        level = json.loads(p.read_text())
        layout = level['layout']
        assert len(layout['fields']) == 81, p.name
        tier = p.name[-1]
        moves[tier].append(level['data']['moves'])
        tiers[p.name[:4]][tier] = level['data']['moves']
        for name in LAYERS:
            for v in set(layout.get(name, [])) - {0}:
                key = f'{name}:{v}'
                values[name][str(v)] += 1
                first.setdefault(key, p.name)
            if any(layout.get(name, [])):
                presence[name] += 1
    comparison = Counter('increase' if t['c'] > t['a'] else 'decrease' if t['c'] < t['a'] else 'equal' for t in tiers.values())
    return {'campaign_tiers': len(files), 'numbered_levels': len(tiers),
            'tier_move_ranges': {k: {'min': min(v), 'max': max(v), 'mean': round(sum(v)/len(v), 2)} for k, v in sorted(moves.items())},
            'c_vs_a_moves': dict(comparison), 'variants_with_nonzero_layer': dict(presence),
            'variant_counts_by_layer_value': {k: dict(v) for k,v in values.items()},
            'first_campaign_variant_by_layer_value': first}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--levels', type=Path, default=Path('reference/tropicats-analysis/levels'))
    args = parser.parse_args()
    print(json.dumps(analyze(args.levels), indent=2, sort_keys=True))


if __name__ == '__main__':
    main()
