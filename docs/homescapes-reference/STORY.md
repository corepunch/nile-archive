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
Their presence suggests authored room/day groupings; string order alone does not
establish task order, costs, dialogue, or which opening the player sees. Other
quest containers include labels for other rooms, but many cannot yet be read
using the same simple extraction. No completeness claim follows from these
filenames or strings.

For comparison, the Tropicats handoff can join chapter, quest, task, board and
scene IDs to decoded English. We cannot yet make that join for Homescapes:
`Storyline.lua`, tutorials and many text resources begin with `PLXE`, and the
quest binary has not been parsed. Next research requires a validated reader for
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
