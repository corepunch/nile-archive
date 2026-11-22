# Relic Rush · Finds plan (draft)

**Status:** a proposal for review. Nothing here is in the game yet, and it has no dialogue on purpose. The lines get written only once the thread below holds up. Chapter 1 is detailed level by level as the sample; the other chapters are outlined until chapter 1 is approved.

## The split

This follows June's Journey, which tells its whole story in its scenes and none on its island ([how June's Journey does it](../../../docs/junes-journey-reference/STORY_STRUCTURE.md)).

- **Levels carry the story.** They play in the same order for everyone, so the story can't arrive out of order. Most levels have a find: something the dig turns up, a line before the board about what they're digging for, and a reaction after about what it means.
- **Buildings carry the montage.** A building changes what turns up on the boards (water buckets, timber, tools, and later rings, scarabs and harps). Placing one plays no scene. The Build button already shows the next purchase and its price.
- **The town gets tutorial lines, not story.** June's Journey teaches its island through a character's small wish: Mrs. Talbot has been meaning to get new garden chairs, and suggests picking some out in the shop. Relic Rush can do the same for the first few purchases and for moving a building: one line, a personal wish rather than a need, and nothing that the levels' story depends on.
- **Chapters are ten levels, and each is a place.** Nine levels of small finds lead up to a big find on the boss board (every tenth level), which answers the chapter's question and raises the next one. June's Journey works the same way: five scenes with clues, then an adventure scene that closes the chapter.

## The mystery

**The question, asked on level 1:** somebody lived here. Who were they, and where did they go?

**The answer, which the player can piece together before it's said:** the people of Callira didn't vanish. Over generations the land rose and the reef closed their harbour. Their boats couldn't get in or out, so they carried what they could up into the hills and became farmers. The hill people who trade with the settlers from level 21 are their grandchildren's grandchildren. They have forgotten the harbour, but they kept some of its things.

Why this answer:

- **It's warm.** Nobody died, nobody was a villain, nobody hid a secret. It suits the tone rule for Relic Rush (a warm adventure about founding a town).
- **It's fair.** The answer is planted on level 20, when smoke rises over the hills, 70 levels before anyone says it. A player can guess it.
- **It has a turn.** The strangers in the hills turn out to be the people we were looking for.
- **It's physical.** Every clue is something you can paint and bury on a board.
- **It reuses what's already there.** The cup, the harbour steps, the tide marks, the Callira stones, the wreck, the hill people, Tavi's reef and the museum all stay; they finally point at one answer. The current script leaves "why they left" open for good, and an unanswered mystery doesn't hook anyone.

A wrong guess along the way (a storm took them) gives the player something to correct.

## The chapters

| Chapter | Levels | Place | Question | Boss find | What the boss settles |
| --- | --- | --- | --- | --- | --- |
| 1 | 1–10 | The landing beach | Did people live here? | A carved stone of a ship under sail | They were sailors; this was a harbour |
| 2 | 11–20 | The old shore | Where was the harbour? | Worn harbour steps that end in dry sand; smoke over the hills at the end | The harbour was here, but the sea isn't. And we're not alone |
| 3 | 21–30 | The hill trail and the market | Who are the hill people? | A hill-people pot with the cup's wave pattern | The hill people and Callira are linked, and the hill people don't know it |
| 4 | 31–40 | The cliffs | Why do the steps end in sand? | Bronze mooring rings, high and dry | The sea was much higher. Oren's wrong guess: a storm took them |
| 5 | 41–50 | The cove | Did a storm take them? | An old boat hauled up the beach on rollers, not wrecked | No: they pulled their own boats out, carefully |
| 6 | 51–60 | The town under the jungle | What was this place? | A stone carved with the town's name | Callira, and they were proud of it |
| 7 | 61–70 | The reef | Why give up the sea? | A chart on slate showing a channel through the reef | The reef grew over their channel and closed the harbour |
| 8 | 71–80 | The path inland | Where did they go? | A wall painting of people carrying pots and boats uphill | They walked up into the hills |
| 9 | 81–90 | The hill village | Are they still there? | A hill grandmother's cup, the twin of Sela's | **The answer:** the hill people are Callira's descendants |
| 10 | 91–100 | The harbour again | What now? | Callira's founding stone: people coming ashore from boats | Callira began the way our town did; it takes the old name back |

## Chapter 1 level by level: the landing beach

The settlers clear ground along the beach to build. The finds come out of that ground, so the player is literally digging. Each find is small, ordinary and plausible on a beach, and together they lead to the boss find.

| Level | Find | What it tells them | Who notices |
| --- | --- | --- | --- |
| 1 | A clay cup with a wave pattern | Somebody lived here | Sela, who keeps it (pays off at 90 and at the fountain) |
| 2 | A broken plate with the same pattern | More than one cup: a household, not a visitor | Sela |
| 3 | A fish hook carved from bone | They fished | Oren |
| 4 | A ring of blackened hearth stones | They cooked here: a house stood here | Oren |
| 5 | A stone net weight with a hole bored through | They fished with nets, so from boats | Tavi |
| 6 | A child's toy boat carved from wood | Families lived here, and children played at boats | Sela |
| 7 | A green bronze nail, the kind used in boat planks | They built boats here, not only sailed them | Tavi |
| 8 | A rock with a groove worn smooth by rope | Boats were tied here for years | Tavi |
| 9 | A row of rotted posts in the sand | Something stood along the water: a jetty? | Tavi asks; nobody knows yet |
| 10 (boss) | A carved stone of a ship under sail | They were sailors and this was their harbour. So where is it? | Tavi, which leads into chapter 2 |

Every level speaks, but briefly: at most one line before the board (what they hope to find, or a guess from the last find) and two after (the reaction). The board's tease line plays when half the plaques are clear.

## How a find level works

The engine already has buried finds (`reveal`, [docs/MATCH3_ELEMENTS.md](../../../docs/MATCH3_ELEMENTS.md)); Christmas Market uses them and an earlier Relic Rush campaign did too:

- `reveal = {picture=…, icon=…, object=true, bark=…}` draws the find across the board's plaques. Each cleared plaque shows its part of the object.
- `bark` is one line spoken when half the plaques are clear: the tease.
- On the first clear the pieces fade, the whole object holds on screen, and then the scene plays. Replays show the picture without the hold.
- The plaques form the object's silhouette: a cup shape for the cup, a ring of stones for the hearth. The board must still pass the plaque coverage and move budgets in [board-progression.md](board-progression.md). Check with `python3 tools/balance_plaques.py relic-rush`.
- Review a find with `--level N --reveal 1`.

## What it costs

- **Art:** about 95 find pictures: 9 small ones per chapter and a large one per boss (chapter 2 ends on an event rather than a dig). Generate each chapter's nine small finds together in one atlas, so a chapter shares one style and one pass. Catalogue them in [asset-catalogue.md](asset-catalogue.md).
- **Boards:** each find level's plaques redrawn to trace its object. The difficulty tier stays the same.
- **Script:** about 300 lines: up to three per level, plus the tease lines. That's more than today's 224, but every line reacts to an object on screen. Placement scenes, request scenes and the "let's build X" lines go.
- **A cheaper version:** if 95 pictures is too many, give half the levels in each chapter a find picture and let the others speak about the last one (a guess, a question, a disagreement). The bosses keep their big finds.

## Still open

- **The families thread.** The mystery doesn't need the ship going back for the families. If it stays, it fits: the reef that closed Callira's harbour is the reef Tavi has to get across. If it goes, the finale is the hill people coming down to the harbour.
- **The museum (87).** It could display the finds so far, as June's Journey keeps its clues in a casebook. That would be the only building that shows story.
- **Board names.** Many current boards have temple and jungle names (Jaguar Gate, Serpent Throne). They should be renamed to match their chapter's place.
