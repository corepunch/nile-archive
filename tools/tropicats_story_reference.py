#!/usr/bin/env python3
"""Generate the Tropicats campaign reference or look up a level or scene."""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'reference/tropicats-analysis'
OUT = ROOT / 'docs/tropicats-reference/story'

def read(path):
    source = BASE / path
    try:
        return json.loads(source.read_text(encoding='utf-8'))
    except FileNotFoundError:
        raise SystemExit(f'Missing local extraction: {source}\n'
                         'See docs/tropicats-reference/README.md for the source inventory.') from None

def safe(s):
    return str(s).replace('|', '\\|').replace('\n', ' ').strip()

def task_action(english, quest, index):
    key = f"quest.task{index+1}.action.{quest['id']}"
    override = quest.get('loca_override')
    if override and f'{key}.{override}' in english:
        return english[f'{key}.{override}']
    return english.get(key, '[missing]')

def find_level(quests, english, level):
    for quest in quests:
        for index, group in enumerate(quest['task_levels']):
            tokens = group.split(',')
            for token in tokens:
                if token == 'none' or int(token[:-1]) != level:
                    continue
                quest_id = quest['id']
                chapter = int(quest_id.split('_')[0][3:])
                return {
                    'level_tier': token,
                    'board_file': str((BASE / 'levels' / f'{level:04d}{token[-1]}').relative_to(ROOT)),
                    'chapter_page': str((OUT / f'chapter-{chapter:02}.md').relative_to(ROOT)),
                    'quest': quest_id,
                    'quest_title': english.get(f'quest.title.{quest_id}'),
                    'task': f'{quest_id}.{index+1}',
                    'action': task_action(english, quest, index),
                    'type': quest['task_type'][index],
                    'item': quest['task_item'][index],
                    'count': quest['task_count'][index],
                    'task_level_tiers': tokens,
                    'target': quest['task_action_target'][index],
                }
    return None

def find_scene(story, english, scene_id):
    setup = [row for row in story['dialogue_setup'] if row['dialogue_id'] == scene_id]
    details = []
    for row in story['dialogue_details']:
        if row['dialogue_id'] != scene_id:
            continue
        # Staging may carry stale draft text. Expose only the localized line.
        detail = {key: value for key, value in row.items() if key not in ('text', 'dialogue_id')}
        if 'sentence' in row:
            key = f"dialogue.story.{scene_id}.{row['sentence']}"
            detail.update(localization_key=key, localized_text=english.get(key))
        details.append(detail)
    if setup or details:
        return {'scene': scene_id, 'setup': setup, 'details': details}
    return None

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true', help='check the generated chapter pages')
    mode.add_argument('--level', type=int, help='look up a campaign number and its quest task')
    mode.add_argument('--scene', help='show a scene’s triggers, staging and localized lines')
    args = parser.parse_args()
    english = read('bundled/english.json')
    if args.scene is not None:
        scene = find_scene(read('config/storydialogueconfig.json'), english, args.scene)
        if scene is None:
            parser.error(f'unknown configured scene {args.scene!r}')
        print(json.dumps(scene, ensure_ascii=False, indent=2))
        return
    quests = read('bundled/157_questconfig')['quests']
    if args.level is not None:
        level = find_level(quests, english, args.level)
        if level is None:
            parser.error(f'no campaign quest task for level {args.level}')
        print(json.dumps(level, ensure_ascii=False, indent=2))
        return
    chapters = read('config/chapterconfig.json')['chapters']
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
                action = task_action(english, q, i)
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
