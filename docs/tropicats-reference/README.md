# Tropicats design reference

A reference for designing **Relic Rush** and **Christmas Market**, based on the
locally supplied Tropicats **2.5.11 / build 87469365** and its extracted content.
It covers **2,730 campaign levels × three variants**, **70 chapters**, **274 quests**
and **1,217 story tasks**. Story spoilers throughout.

| Read | What it answers |
| --- | --- |
| [Story handoff and chapter index](STORY.md) | How chapters, quests, tasks, boards and scenes fit together, with a worked opening and a route into writing an original campaign |
| [Mechanics dictionary](MECHANICS.md) | What every encoded piece, blocker, field, goal and tool does; what is confirmed by tutorials/assets, and what remains unknown |
| [Board design](BOARD_DESIGN.md) | How shape, placement, supply, objectives and constraints make different decisions; concrete level examples and easy/medium/hard comparisons |
| [Applying it to our games](ADAPTATION.md) | Current capabilities and campaign overlap, proposed mechanic translations, board authoring briefs and story/reward pacing |
| [Implemented elements and board shapes](../MATCH3_ELEMENTS.md) | Current six-family implementation, King counterparts, original artwork, shared tile mask and campaign progressions |
| [Local level viewer](../../tools/tropicats-viewer/README.md) | Browse the extracted boards and inspect all three variants with original game artwork |
| [Artwork catalogue and limitations](../../tools/tropicats-viewer/ART.md) | Which sprites, shaders and skeletons supply the viewer; disclosed reconstruction limits |
| [Initial technical analysis](../TROPICATS_ANALYSIS.md) | Asset delivery, progression implementation, content counts and source inventory |

For a story rewrite, start at the story handoff and follow its reading order.
The 70 linked chapter pages work from a plain checkout and contain all 274 quest
setups and outcomes, 1,217 tasks, and the associated scene IDs. For puzzle design,
start with the mechanics dictionary and open the board examples in the viewer.

## Reading the evidence

Serialized levels and configuration establish authored values and task mappings.
English tutorial text establishes player-facing behavior. Prefabs, materials,
shaders and skeletons establish visual states. Metadata names help interpret
encoding, but do not prove every runtime algorithm. The installed native executable
is encrypted, so this is static resource research rather than recovered C# or a
complete playthrough. Each reference distinguishes confirmed data, inference and
design recommendations.

Random-fruit previews, runtime color permutations, bridge selection and other
visual approximations are labeled in the viewer and artwork audit. A static board
cannot establish solvability, actual player difficulty or win rate. The three
variants can differ structurally; “hard” is not simply a fixed move reduction.

The complete story reference records every configured task, not a verbatim
transcript of every dialogue line. Scene IDs retain a route back to the extracted
dialogue. Configuration order, scene triggers and journal outcomes are kept
distinct where they do not establish a single strict runtime order.

## Source inventory

The checked-in chapter pages and design notes are the portable reference. The
raw tables, board definitions and original sprites are under the ignored local
`reference/tropicats-analysis/` directory. Paths in this table are relative to
that directory. Use the original source when a summary and a raw value differ.

| What you need | Local source | How to join it |
| --- | --- | --- |
| Chapter start and opening quest | `config/chapterconfig.json` | `chapters[]` has `chapter`, `first_level` and `started_by_quest`. |
| Quest tasks, item requirements, targets and default claim reward | `bundled/157_questconfig` | Find a quest by `id`, then use the same index in its `task_*` arrays. `reward` is at the root of the file. |
| Story wording, task labels and tutorial text | `bundled/english.json` | Look up `quest.title.<id>`, `quest.description.<id>`, `quest.roundup.<id>`, or `quest.task<N>.action.<id>[.<loca_override>]`. |
| Scene trigger, cast, place, camera and staging | `config/storydialogueconfig.json` | Find the `dialogue_id` in `dialogue_setup` and `dialogue_details`. Join each numbered sentence to `dialogue.story.<dialogue_id>.<sentence>` in `english.json`. |
| Exact campaign gate and board tier | `config/areasconfig.json`, `levels/` | Find the numbered level in `areas[].levels[]` for quest and dialogue gates. A task token such as `32b` selects board file `levels/0032b`. |
| Separate puzzle sets | `config/singletierareasconfig.json`, `bundled/107_endofcontentlevelsconfig`, `level-inventory.json` | Keep alternate and post-story selection data separate from chapter counts. The inventory lists all decoded board assets. |
| Village, building and rank context | `config/buildingconfiglist.json`, `config/startbuildingconfig.json`, `config/villagerconfig.json`, `config/villagerbehaviorconfig.json`, `bundled/111_islandareaconfig`, `bundled/113_villagerankconfig` | Start from the task target or scene place and compare identifiers. Look up rank thresholds independently of the task's puzzle tiers. |
| Default rewards and other bundled systems | `bundled/116_level_rewards`, `bundled/inventory.json` | The inventory indexes the bundled text assets, including events, collection rewards and feature settings. The level rewards table and quest claim reward describe different layers of progression. |
| Board art and reconstruction | `art/sprites.json`, `art/provenance.json`, `art/sprites/` | Use the artwork catalogue and viewer for mappings and limits. [Artwork catalogue](../../tools/tropicats-viewer/ART.md) |
| Provenance and implementation clues | `audit.json`, `download-sizes.json`, `bundles/`, `metadata-symbols.txt`, `metadata-literals.json` | The audit lists bundle URLs and fingerprints. Metadata identifies classes and fields. [Technical analysis](../TROPICATS_ANALYSIS.md) |

## Reproduce the reference

The original application and decoded third-party content remain in ignored
`reference/`. The repository tracks the research, extraction tools and reviewed
captures. See the viewer's extraction instructions for local prerequisites.

```sh
python3 tools/tropicats_board_analysis.py
python3 tools/tropicats_story_reference.py --check
python3 tools/tropicats-viewer/serve.py
```

Open <http://127.0.0.1:8765>. The story tool uses the extracted tables. Run it
without arguments to regenerate the chapter pages, or use `--level` and
`--scene` for read-only lookups. The technical analysis documents the bundle
audit and input provenance. The artwork catalogue documents sprite extraction.
