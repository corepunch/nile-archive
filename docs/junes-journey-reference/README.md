# June’s Journey reference for Nile Archive

Research checked 12 November 2026. This is a development reference for Nile
Archive's story, hidden-object scenes, island and economy. It combines three
kinds of evidence:

- **Bundled** means the supplied iPhone app 4.17.7 / build 120, inspected
  statically. Its opening scene, chapter-one staging, clue art and limited
  English text are retained under ignored `reference/junes-journey-analysis/`.
- **Official** means Wooga's help pages, which describe the general live game.
  Feature availability and balance can change.
- **Community** means a player-maintained catalogue or transcript. These are
  useful examples, not verified current account prices or proof of what this
  app build actually displays.

The complete campaign configuration and full chapter dialogue were not
recovered. Do not fill those gaps with assumptions. The opening artwork and
object layout can be explored in the [local scene viewer](../../tools/junes-viewer/README.md).
See [opening analysis](../JUNES_JOURNEY_OPENING.md), [extraction notes](../JUNES_JOURNEY_ANALYSIS.md),
and the earlier [story](../../research_notes/Прогрессия%20June%20Journey%20и%20Tropicats/junes_journey_story.md)
and [economy](../../research_notes/Прогрессия%20June%20Journey%20и%20Tropicats/junes_journey_economy.md)
research. Where earlier research differs from the extracted app or Wooga's
current help, use the evidence and qualifications below.

## The playable loop

1. **Choose a scene.** A chapter contains five hidden-object scenes and an
   Adventure Scene. General scene access requires both previous-scene clues
   and the required Flower level. Wooga gives an early example in which scene 3
   needs level 3 and both scene-2 clues. [Scene locks](https://wooga.theymes.com/hc/en/junes-journey/articles/why-is-a-hidden-object-scene-locked-315)
2. **Find objects.** Tap the listed objects in the illustration. Faster finds
   increase score, wrong taps lose points, and a free hint recharges. Some
   finds give suitcase rewards revealed with the score. [Scene rules](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-hidden-object-scene-439)
3. **Collect a clue and progress.** Wooga says the first clue comes on the
   first play, and the second on a play after the scene's third Mastery Star.
   Score accumulates over plays toward five Stars, with increasingly demanding
   thresholds. A new Star awards a Star Box, with a 5-Star Box for the fifth.
   The opening tutorial may have exceptions. [Scene rules](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-hidden-object-scene-439), [Star Boxes](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-star-box-485)
4. **Improve the island.** Earn coins from scene play, some buildings and
   boxes. Buy decorations and buildings, upgrade buildings or restore
   landmarks to add Flowers and raise level. [Coins](https://wooga.theymes.com/hc/en/junes-journey/articles/what-do-i-need-coins-for-and-how-do-i-get-them-336), [levels](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-june-s-journey-levels-396)
5. **Finish the chapter.** The Adventure Scene needs all chapter clues and
   the Star count shown on its card. Wooga's level guide gives a minimum of 20
   chapter Stars. Complete the Adventure Scene and meet the next chapter's
   Flower-level requirement to advance. [Adventure Scene](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-an-adventure-scene-483), [levels](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-june-s-journey-levels-396)

The files do not establish the order of clue dialogue, score and reward screens
in June's opening. Treat each step above as a dependency, not a recording of
precise screen transitions.

## Story and clue structure

### Premise from the bundled app

June Parker's sister Clare and Clare's husband Harry have been shot. Police
believe Harry killed Clare and then himself. June doubts that account, travels
to New York to care for her niece Virginia, and intends to investigate. In a
separate opening exchange Mrs Talbot says Virginia is inconsolable and directs
June to the parlor. Two bundled intro versions disagree on the elapsed time
since the deaths, and their playback order is unverified.

The chapter 001 dialogue file contains **84 staging rows**, with before/after
blocks for two numbered clues in scenes 1–5 and one block in scene 6. Rows carry
speaker, character positions, moods and sometimes clue-image placement. The
corresponding full chapter-one localized dialogue is missing. For example, the
scene-2 clue-1 after block places the family picture between June and Virginia.
[Bundled source details](../JUNES_JOURNEY_OPENING.md#how-clues-carry-the-story)

| Scene | First staged clue image | Second staged clue image |
| --- | --- | --- |
| 1, estate exterior | No numbered image binding established | No numbered image binding established |
| 2 | Family picture | Crime photo |
| 3 | Whiskey glasses | Footprint |
| 4 | Broken lock | Carafe |
| 5 | Bloody handkerchief | Window |
| 6 | Adventure dialogue block | — |

### Chapter-one sequence from a community transcript

The following account is a separate, older fan transcription, so it may differ
from build 4.17.7. It offers a useful example of how evidence changes a working
theory. Its first scene has one clue, whereas the bundled staging has two
numbered groups. The runtime opening rule for the inspected build remains
unverified. [Chapter-one transcript](https://vocal.media/fiction/june-s-journey-full-story)

| Beat | What the clue contributes | Next question or action |
| --- | --- | --- |
| Return to estate | Mrs Talbot welcomes June and Virginia is grieving | Care for Virginia and learn what happened |
| Parlor | A family portrait leads to a crime-scene photo | Virginia questions the police account |
| Photo | Three glasses and an unfamiliar footprint suggest another person | Search the garden route |
| Garden gate | Forced lock and a broken whiskey carafe suggest a way out | Follow the route beyond the gate |
| Lane | A bloody handkerchief and a light in the gatehouse raise the stakes | Approach the gatehouse |

Wooga's own chapter-one Adventure walkthrough describes moving a plant, taking
a key, opening a drawer, finding a combination, moving a painting and opening a
safe. The transcript above ends at the gatehouse. It does not establish the
exact timing or contents of the extracted scene-6 dialogue. [Adventure walkthrough](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-an-adventure-scene-483)

The player-maintained scene index places the first six chapters at the estate,
a speakeasy investigation, Eddie Daggett, Clare's secret, Havana and the search
for Virginia. Its chapter-two cellar account says June finds Virginia unharmed,
and that a whiskey crate and diary point toward Harry's smuggling and a meeting
by boat. These later events are community-reported and were not recovered from
the supplied app. [Scene index](https://junes-journey.fandom.com/wiki/Hidden_Object_Scenes_of_Volume_1),
[Hidden Cellar](https://junes-journey.fandom.com/wiki/Hidden_Cellar_-_Level_6%2C_Vol._1)

**Design inference.** A clue has a visible identity, prompts a character's
interpretation and motivates a next location. A later clue may strengthen or
revise the theory. For Nile, write these as separate evidence, inference and
next-action fields so dialogue does not silently turn a suspicion into fact.
The current June files do not establish a universal chapter-writing formula.

## Currency, gates and rewards

| Resource | June's Journey evidence | Function |
| --- | --- | --- |
| Coins | Official | Earned from scenes, some buildings and Star Boxes. Spent on buildings, decorations and obstacle removal. |
| Flowers | Official | Island decorations, building upgrades and landmarks contribute to level. Storing or selling a decoration removes its Flower contribution and can lower level. Flowers are a balance used for thresholds, not a purchase payment. |
| Stars | Official | Scene score accumulates toward five Mastery Stars. Stars are used for scene/chapter requirements and some shop unlocks. |
| Energy | Official | A hidden-object play costs 15 energy. It regenerates 1 every 2 minutes up to a normal 110 or extended 150 capacity. |
| Materials | Official | Earned in Star Boxes and sometimes scenes, used with time to upgrade buildings. |
| Diamonds | Official | Shop currency for some items and for missing materials or instant upgrade completion. |
| Compasses | Official | Used to clear new island areas, with sources including Star Boxes and scene bonuses. |

Sources: [coins](https://wooga.theymes.com/hc/en/junes-journey/articles/what-do-i-need-coins-for-and-how-do-i-get-them-336),
[levels and Flower removal](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-june-s-journey-levels-396),
[energy](https://wooga.theymes.com/hc/en/junes-journey/articles/what-do-i-need-energy-for-and-how-do-i-get-it-492),
[building upgrades](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-upgrade-my-buildings-323),
[compasses](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-the-compasses-for-and-how-do-i-find-them-332),
[decorations](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-get-new-decorations-326).
The general help gives no exact scene-score payout formula, complete level curve,
or chapter-by-chapter Flower requirements.

### Early scene thresholds reported by players

The community level list records the following totals. Blank values are
missing in that source. These are historical reference values, not values
extracted from the app or confirmed for the current account. Flower totals are
thresholds, not amounts consumed. [Community level list](https://junes-journey.fandom.com/wiki/Levels)

| Scene | Reported total Flowers | Change from preceding listed scene |
| --- | ---: | ---: |
| 1 · Orchid Island Estate | 10 | — |
| 2 · Estate Parlor | Not listed | — |
| 3 · Crime Scene Photo | Not listed | — |
| 4 · Old Garden Gate | 67 | +32, as listed |
| 5 · Wooded Lane | 170 | +103 |
| 6 · Hidden Cellar | 235 | +65 |
| 7 · Harry's Yacht | 260 | +25 |
| 8 · New York Café | 310 | +50 |
| 9 · Garment District | 380 | +70 |
| 10 · The Blind Tiger | 490 | +110 |

## Building prices and upgrades

These examples come from the community wiki, read 12 November 2026. They were
not extracted from the supplied app or checked in a live account. The Flower
column is the **total at building level 5**, not the immediate reward for the
initial coin price. The parent building list's unlock column is ambiguously
labelled, so only individual Fountain and Stables pages are used for their
Star requirements. [Buildings list](https://junes-journey.fandom.com/wiki/Buildings),
[Fountain](https://junes-journey.fandom.com/wiki/Fountain),
[Stables](https://junes-journey.fandom.com/wiki/Stables)

| Building | Footprint | Initial coin price | Reported unlock | Flowers at level 5 | Rare upgrade material |
| --- | --- | ---: | --- | ---: | --- |
| Estate | 4×4 | Starter | — | 165 | Copper |
| Fountain | 3×3 | 750 | 7 Stars | 360 | Porcelain |
| Stables | 3×3 | 1,200 | 40 Stars | 535 | Terracotta |
| Orangerie | 3×3 | 1,650 | Not verified here | 760 | Glass |
| Windmill | 3×3 | 1,950 | Not verified here | 960 | Marble |
| Vineyard | 3×3 | 2,400 | Not verified here | 1,135 | Terracotta |

The wiki reports the Fountain and Stables each accumulate one coin every
40 minutes up to 15 coins. Its Fountain table gives this upgrade example.
Each row's Flower gain adds to the cumulative total. Materials and construction
time are additional to the initial 750-coin purchase. [Fountain](https://junes-journey.fandom.com/wiki/Fountain)

| Level | Added Flowers | Brick / hammer / wood | Paint | Porcelain | Time | Total Flowers |
| ---: | ---: | --- | ---: | ---: | --- | ---: |
| 1 | 25 | 2 / 2 / 2 | 0 | 0 | 3 h | 25 |
| 2 | 65 | 7 / 7 / 7 | 3 | 2 | 7 h | 90 |
| 3 | 75 | 9 / 9 / 9 | 5 | 3 | 14 h | 165 |
| 4 | 90 | 10 / 10 / 10 | 5 | 5 | 20 h | 255 |
| 5 | 105 | 12 / 12 / 12 | 6 | 6 | 31 h | 360 |

The player wiki lists these **2019 seasonal decorations**. Their 30 coins per
Flower ratio is an observation for these examples, not an established universal
pricing rule or a current availability claim. [Forest Festivities set](https://junes-journey.fandom.com/wiki/Forest_Festivities_Set)

| Decoration | Footprint | Price | Flowers | Construction |
| --- | --- | ---: | ---: | --- |
| Holly Bush | 1×1 | 450 coins | 15 | 3 h |
| Holiday Lantern | 1×1 | 600 coins | 20 | 4 h |
| Snowy Pine | 1×1 | 1,200 coins | 40 | 10 h |
| Christmas Tree | 2×2 | 18,600 coins | 620 | 3 d 2 h |

## Nile Archive today

The implemented chapter is the original Egyptian mystery in
[story.md](../../games/nile-archive/docs/story.md). Nefra returns after a flood
to find her father Horem missing and his archive emptied. Merit helps follow
his trail. Chapter 1 is implemented; chapters 2 and 3 in the script are planned.
The existing script identifies unresolved continuity work, including the chest
count and the survival of dyke evidence. Its truth timeline and the writing
guide remain the authority for future story work. [Writing guide](../STORY_WRITING.md)

| Nile search | Implemented clue beats | Gate |
| --- | --- | --- |
| 1 · Keeper's courtyard | Horem's seal and the Game of Eight | Available at start |
| 2 · Scribe's library | Seal's island plan; a replacement map and Merit's boat | Previous clue, 20 Influence |
| 3 · Temple | Horem's vault note; an apple leads back to the garden | Both library clues, 50 Influence |
| 4 · Courtyard revisit | Dry fountain channel; Horem's instruction | Both temple clues, 75 Influence |
| 5 · Library revisit | Counterweight; key, scarab, ankh and feather | Both courtyard clues, 90 Influence, restored fountain |
| Cache | Open the archive and expose the missing-book question | All nine clues and restored fountain |

The two revisits reuse earlier scene paintings. The cache uses a four-target
sequence. Clue dialogue is invoked before the win modal in the current code.
[Content](../../games/nile-archive/lua/archive_content.lua),
[story beats](../../games/nile-archive/lua/archive_story.lua),
[scene result](../../games/nile-archive/lua/archive_scene.lua),
[economy rules](../../games/nile-archive/lua/archive_economy.lua).

### Current Nile values

| Item | Implemented rule |
| --- | --- |
| Start | 0 coins, 10 Influence, gardener's house already restored |
| Search payout | 80 base + 40 first clear + 20 per newly improved Star + 20 perfect |
| Stars | Three best Stars per search. Clear count guarantees at least two on the second clear and three on the third. |
| Clues | One in search 1. Searches 2–5 give the first on a first clear and the second on a subsequent clear after the best was already three Stars. |
| Restorations | Gardener 70 coins / 10 Influence, already owned; temple 160 / 30; archive 130 / 25; fountain 60 / 10; workshop 100 / 15. |
| Decorations | Catalogue price in coins; Influence is `floor(price / 10)`. Best Stars unlock items. A 30-coin date palm gives 3 Influence. |
| Shores | 120, 180, 240 coins, unlocked after one, two and three distinct searches. |
| Cache reward | 150 coins once |
| Timing | No energy or construction timers in the current implementation. |

Restorations are one-time purchases. Temple and archive require two distinct
searches; fountain and workshop require one. Current catalogue prices include
15-coin blue lotus, 30-coin date palm, 200-coin mud house and 240-coin small
pyramid. These are Nile's own economy units and rules. The complete 96-item
catalogue is in [archive_catalogue.lua](../../games/nile-archive/lua/archive_catalogue.lua).

A reproducible early example starts at 0 coins and 10 Influence. A first clear
with one new Star and no perfect bonus pays 80 + 40 + 20 = 140 coins. Restoring
the fountain costs 60 and adds 10 Influence, leaving 80 coins and 20 Influence.
Once the first clue has been awarded, search 2 meets its stated Influence and
previous-clue requirements. This is an arithmetic example, not a measured
playthrough or a claim about June's prices.

The runtime economy code is authoritative for current behaviour. An older
passage in the building catalogue says a date palm gives no Influence; the
current implementation and game README give 3.

## Development handoff

For each future Nile scene, record a stable scene ID, background and object
layout, two explicit clue IDs where applicable, first and repeat discovery
conditions, before/after dialogue IDs, journal text, score and payout rules,
prior-clue and Influence gates, and the next location. Keep one-shot dialogue
and awarded clues in saved state. The first Nile search currently has one clue;
do not change existing saves or this exception merely to match the general
June guide.

For each building or decoration, record category, whole-tile footprint, coin
cost, unlock condition, Influence contribution and whether it can repeat.
If the design later adds production, upgrades, timers, storage or removal,
write their costs, rewards, collection caps, persistence and effect on
Influence explicitly. June's live Flower removal behaviour and Nile's current
monotonic Influence are separate choices.

Before tuning later chapters, measure the number of required clears, coin
income and available Influence along both a typical and a low-reward route.
State each assumed Star result and purchase. Keep June's community prices as
reference examples until verified against a current account. The extracted
files do not supply June's full building catalogue, Star thresholds, scene
selection algorithm, current live prices or later campaign story.
