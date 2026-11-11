#!/usr/bin/env python3
"""Generate the serialized Tropicats campaign index and check task coverage."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'reference/tropicats-analysis'
OUT = ROOT / 'docs/tropicats-reference/story'

def read(path):
    return json.loads((BASE / path).read_text())

def safe(s):
    return str(s).replace('|', '\\|').replace('\n', ' ').strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    chapters = read('config/chapterconfig.json')['chapters']
    quests = read('bundled/157_questconfig')['quests']
    english = read('bundled/english.json')
    scenes = read('config/storydialogueconfig.json')['dialogue_setup']
    narratives = json.loads((OUT / 'narratives.json').read_text())
    assert set(narratives) == {str(c['chapter']) for c in chapters}
    ids = set()
    tasks = 0
    for chapter in chapters:
        n = chapter['chapter']
        selected = [q for q in quests if re.fullmatch(r'chp%d_q\d+' % n, q['id'])]
        name = safe(english[f'quest.chapter.name_{n}'])
        end = chapters[n]['first_level'] - 1 if n < len(chapters) else max(int(v) for q in selected for token in q['task_levels'] for v in re.findall(r'\d+', token))
        nav = ['[Story index](../STORY.md)']
        if n > 1:
            nav.append(f'[Previous](chapter-{n-1:02}.md)')
        if n < len(chapters):
            nav.append(f'[Next](chapter-{n+1:02}.md)')
        lines = [f'# Chapter {n}: {name}', '', ' · '.join(nav), '',
                 f"Campaign levels **{chapter['first_level']}–{end}**; starts with `{chapter['started_by_quest']}`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.", '', narratives[str(n)], '']
        for q in selected:
            qid = q['id']
            assert qid not in ids
            ids.add(qid)
            arrays = ['task_type', 'task_item', 'task_levels', 'task_count', 'task_action_target']
            count = len(q['task_type'])
            assert all(len(q[k]) == count for k in arrays), qid
            title = safe(english.get('quest.title.' + qid, '[title absent]'))
            lines += [f'## {qid}: {title}', '', f"Configured quest `level` **{q['level']}**; assigned character **{q['character']}**."]
            # Journal entries are short localized evidence, not a claim that scenes were observed.
            for key, label in [('description', 'Setup'), ('roundup', 'Journal outcome')]:
                value = english.get(f'quest.{key}.{qid}')
                if value:
                    lines += ['', f'{label} (localized quest text): “{safe(value)}”']
            related = [s for s in scenes if str(s.get('trigger_value', '')).split('.')[0] == qid]
            if related:
                lines += ['', 'Configured scenes: ' + '; '.join(f"`{s['dialogue_id']}` ({s.get('trigger_condition', 'unspecified')}: {s.get('trigger_value', 'unspecified')})" for s in related) + '.']
            named_only = [s for s in scenes if re.search(r'(?<!\d)' + re.escape(qid) + r'(?!\d)', s['dialogue_id']) and s not in related]
            if named_only:
                lines += ['', 'Additional scene IDs name this quest but use another or no trigger value (association inferred from ID): ' + '; '.join(f"`{s['dialogue_id']}` ({s.get('trigger_condition', 'unspecified')}: {s.get('trigger_value', 'unspecified')})" for s in named_only) + '.']
            if q.get('visual_order'):
                lines += ['', f"Display order override: `{q['visual_order']}` (serialized values; task numbering below stays source-array order; runtime display semantics unverified)."]
            if q.get('loca_override'):
                lines += ['', f"Localization override: `{q['loca_override']}`; action labels below use matching overridden keys when present."]
            lines += ['', '| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |', '| --- | --- | --- | --- | --- |']
            for i in range(count):
                key = f'quest.task{i+1}.action.{qid}'
                override = key + '.' + q.get('loca_override', '')
                action = english.get(override, english.get(key, '[missing]'))
                lines.append(f"| `{qid}.{i+1}` | {safe(action)} | `{q['task_type'][i]}`; `{q['task_item'][i]}` × {q['task_count'][i]} | `{q['task_levels'][i]}` | `{q['task_action_target'][i]}` |")
                tasks += 1
            lines += ['']
        path = OUT / f'chapter-{n:02}.md'
        generated = '\n'.join(lines) + '\n'
        if args.check:
            assert path.read_text() == generated, f'stale: {path}'
        else:
            path.write_text(generated)
    assert len(ids) == len(quests), (len(ids), len(quests))
    assert len(list(OUT.glob('chapter-*.md'))) == len(chapters)
    print(f"{'Checked' if args.check else 'Generated'} {len(chapters)} chapters, {len(ids)} quests, {tasks} tasks.")

if __name__ == '__main__':
    main()
