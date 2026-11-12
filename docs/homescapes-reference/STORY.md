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
