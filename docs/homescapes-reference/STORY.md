# Homescapes story: opening and evidence

This is a short, sourced account of the opening premise, not the complete story
or a transcript of the installed build. Different versions can have different
openings. We have not played through this version or decoded its dialogue.

Austin the butler returns to his parents' deteriorating home. His parents plan
to sell it, while Austin wants to save it by repairing and furnishing it. The
renovation is therefore both a practical sequence of visible changes and an
attempt to persuade his family to keep a place tied to their memories. The
player helps make those changes, with some choice over their appearance. This
summary follows contemporary third-party accounts, rather than recovered game
text: [Gamezebo review](https://www.gamezebo.com/reviews/homescapes-review-homeward-bound/),
[Gamepressure overview](https://www.gamepressure.com/games/homescapes/z05aa9).

Playrix's current guide describes areas opened in sequence and subdivided into
in-game days and star-costing tasks. [Area guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1101-unlocking-new-areas-in-the-mansion/)
That gives the story a useful hierarchy: a large emotional aim (save the home),
a place with visible progress (an area), a short session boundary (a day), and
a small action with a consequence (a task). This is a design interpretation of
the sources, not a claim that each day forms a complete dramatic arc.

## What the installed bundle reveals

The `base_mm/cluster1/CH_Hall/Quest.xml.au` container decompresses to structured
binary containing the labels `Ostin room: Day 1` and `Hall: Day 1` through
`Hall: Day 4`, alongside identifiers for a bed, furniture and other objects.
The pointer arrays now identify five day groups and 46 records in this file;
their serialized order does not establish actual display order, costs, dialogue,
or which opening the player sees.

For comparison, the Tropicats handoff can join chapter, quest, task, board and
scene IDs to decoded English. We cannot yet make that join for Homescapes:
`Storyline.lua`, tutorials and many text resources begin with `PLXE`, while the quest parser currently covers day arrays, record IDs and title keys only. Next research requires a validated reader for
those formats, then a check against actual play. Until then, this page should
not be treated as a full story reference.

## Explore the bundled identifiers

[Open the local quest string explorer](../../reference/homescapes-analysis/quest-strings.html).
It offers a file selector and text filter over **113,932 printable string
occurrences** in all **48** bundled `/Quest.xml.au` files. Offsets locate each
string in its decompressed binary. Run `python3 tools/homescapes-reference/story_index.py`
to regenerate it; this requires the `zstd` command and the local app bundle.
The generator checks the `BLK` signature, frame signature, expected output size
and the prefix repeated in the container header. Some inputs have trailing
bytes after the frame; the decoder accepts the CLI's trailing-header error only
if the complete output passes those checks.

For example, choose `cluster1/CH_Hall/Quest.xml.au` and filter `_Title` to see
identifiers such as `CH_OstinsRoom_ReplaceCarpet_Title`,
`CH_OstinsRoom_CleanRoom_Title` and `CH_OstinsRoom_SetBed_Title`. These provide
leads to authored actions, not the localized task descriptions or an established
sequence. Searching `Scene` exposes scene-like identifiers but not their dialogue.
The explorer intentionally retains duplicate occurrences and binary order for
inspection; neither is a count of unique tasks or proof of progression.

A previously published [PLXE version 4 unpacking approach](https://www.zenhax.com/viewtopic.php%40t%3D16964.html)
expects a Zstandard frame following the header. The version 5 resources in this
bundle do not have that frame at the expected offset, and the old approach does
not decode them. No conclusion about their exact encoding follows from that test.

## Structured outline

[Open the local quest outline](../../reference/homescapes-analysis/story-outline.html)
to browse **48 area files, 285 serialized day groups and 6,078 records**. The
viewer starts with the Hall and uses readable labels mechanically split from
the identifiers. Select another area or filter by an action. Each row retains
its exact ID, title key and decompressed offset. Run
`python3 tools/homescapes-reference/story_outline.py` to regenerate it.

This reader follows the binary's relative-pointer arrays rather than inferring
grouping from nearby strings. In the first Hall group, for example, it returns
Homecoming, ReplaceCarpet, CleanRoom, SetChair, SetBed, CageParrot and
OpenExpansion in array order. The corresponding title keys are separate fields;
119 records use title keys that do not start with their record ID, so matching
localization by string concatenation would be incorrect. These arrays alone do
not establish visible text, dependencies, alternate branches, which records are
shown, or the actual order of a playthrough.

Verification: the focused parser tests inspect all 48 supplied files, check the
opening Hall array and its title key, and reject truncated inputs. Counts are
for this bundled data, not the full live game or a claim about played tasks.
