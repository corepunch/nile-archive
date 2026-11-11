# Tropicats design reference

A reference for designing **Relic Rush** and **Christmas Market**, based on the
locally supplied Tropicats **2.5.11 / build 87469365** and its extracted content.
It covers **2,730 campaign levels × three variants**, **70 chapters**, **274 quests**
and **1,217 story tasks**. Story spoilers throughout.

| Read | What it answers |
| --- | --- |
| [Mechanics dictionary](MECHANICS.md) | What every encoded piece, blocker, field, goal and tool does; what is confirmed by tutorials/assets, and what remains unknown |
| [Board design](BOARD_DESIGN.md) | How shape, placement, supply, objectives and constraints make different decisions; concrete level examples and easy/medium/hard comparisons |
| [Complete story](STORY.md) | Every chapter and quest, its setup/outcome, each task, exact level/tier gates, world targets and associated scenes |
| [Applying it to our games](ADAPTATION.md) | Current capabilities and campaign overlap, proposed mechanic translations, board authoring briefs and story/reward pacing |
| [Local level viewer](../../tools/tropicats-viewer/README.md) | Browse the extracted boards and inspect all three variants with original game artwork |
| [Artwork catalogue and limitations](../../tools/tropicats-viewer/ART.md) | Which sprites, shaders and skeletons supply the viewer; disclosed reconstruction limits |
| [Initial technical analysis](../TROPICATS_ANALYSIS.md) | Asset delivery, progression implementation, content counts and source inventory |

Start with the mechanics dictionary, then open the board examples in the viewer.
Use the story index to follow a chapter's causal sequence from a character's need
through its puzzle rewards and world action. The adaptation guide translates those
patterns to our current hex-board engine; its proposals are not implemented rules
or new story canon.

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

## Reproduce the reference

The original application and decoded third-party content remain in ignored
`reference/`. The repository tracks the research, extraction tools and reviewed
captures. See the viewer's extraction instructions for local prerequisites.

```sh
python3 tools/tropicats_board_analysis.py
python3 tools/tropicats_story_reference.py --check
python3 tools/tropicats-viewer/serve.py
```

Open <http://127.0.0.1:8765>. The story generator reads the extracted configuration
and English localization; running it without `--check` regenerates the chapter
reference. The adaptation guide includes a small Lua command for recounting the
two current campaigns' overlap. These are reference tools; they do not modify
either playable game.
