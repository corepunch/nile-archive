# Nile Archive progression and building economy

This is a balance handoff for the hidden-object investigation and the island.
Chapter 1 values below are implemented in `lua/archive_economy.lua` as of this
revision. Chapters 2 and 3 are a proposed, unimplemented balance model for the
existing three-chapter story plan. The values are Nile's own tuning choices.
[June's Journey research](../../../docs/junes-journey-reference/README.md) is the
reference for the relationship between clues, replay, decorations and narrative
access. The original [story](story.md) supplies Nile's characters and clue beats.

## State and transaction meanings

- **Coins** are spendable. A successful search pays once per completion and
  pays again on replay. Confirmed island purchases deduct their quoted price.
- **Influence** is a non-spendable lifetime progression total. New buildings
  and decorations add it after confirmed placement. Moving a building does not
  add it again. It does not decrease in the current game.
- **Stars** are the best score recorded for each search, with three available
  per search. Cumulative best Stars unlock decorations. They are requirements,
  not deducted balances.
- **Clues** are persistent, ordered story progress. The first search has one;
  searches 2–5 each have two. The first successful clear grants the first clue.
  The second clue requires a subsequent successful clear whose prior best was
  already three Stars. Replaying must not award an existing clue twice.
- **Restorations** are one-time placements. Decorations can be bought again.
  Coast purchases open land and deduct coins. No current energy, construction
  timer, material expense or passive coin income is included in this budget.

Story beats play when their clue is awarded, before the win modal. Journal
entries derive from the clues already held, and skipped dialogue must not remove
the clue. Already visited searches remain accessible if a gate is later unmet.
See `lua/archive_progress.lua`, `lua/archive_scene.lua`, and
`lua/archive_content.lua` for the current implementation.

## Implemented chapter 1

### Search economy

Every successful clear pays 80 coins. The first clear pays another 40. Each new
best Star pays 20, and a clear with neither misses nor hints pays another 20.
A search awards at least one Star on its first clear, two by its second and
three by its third, even if its time score is lower. A fast first clear may
already award three Stars. Clues remain tied to the prior best Star state, so a
first clear at three Stars still needs one more clear to obtain its second clue.

| Search | Prior clue requirement | Influence | Other requirement | Clues |
| --- | --- | ---: | --- | ---: |
| 1 · Keeper's courtyard | — | 0 | — | 1 |
| 2 · Scribe's library | Search 1 complete | 20 | — | 2 |
| 3 · Temple | Both search 2 clues | 50 | — | 2 |
| 4 · Courtyard revisit | Both search 3 clues | 75 | — | 2 |
| 5 · Library revisit | Both search 4 clues | 90 | Fountain restored | 2 |
| Cache | All nine clues | — | Fountain restored | — |

The cache pays 150 coins once. A new game begins with 0 coins, 10 Influence and
the gardener's house already restored. The gardener's listed 70-coin price is
not charged at the start of a new game.

### Island purchase table

| Restoration | Coin cost | Influence gained | Distinct searches needed | Repeat |
| --- | ---: | ---: | ---: | --- |
| Gardener's house | 70 | 10 | 1 | No, starts restored |
| Fountain | 60 | 10 | 1 | No |
| Workshop | 100 | 15 | 1 | No |
| Archive | 130 | 25 | 2 | No |
| Temple of Isis | 160 | 30 | 2 | No |

The catalogue contains 96 repeatable decorations. Each costs its listed coins
and grants `floor(coins / 10)` Influence. Examples include a blue lotus at
15 coins for 1 Influence, a date palm at 30 for 3, a mud house at 200 for 20,
and a small pyramid at 240 for 24. Decoration Star gates and source prices are
in `lua/archive_catalogue.lua`; footprint and placement data are registered in
`lua/building_sprites.lua` and the shared city code. The three shores cost 120,
180 and 240 coins and become eligible after 1, 2 and 3 distinct searches.
Placement confirmation and land availability still apply.

### Worked chapter 1 route

This is an arithmetic path through the current rules. It assumes each listed
restoration has a valid placement and no optional shore or decoration spending.
The slower column assumes every search initially scores one Star, with the
minimum guaranteed Stars on the next clears and no perfect bonus. For each
search with two clues that is four clears, paying 140 + 100 + 100 + 80 = 420.
The quicker column assumes three Stars on each first clear, also with no
perfect bonus. A two-clue search then takes two clears, paying 180 + 80 = 260.
Search 1 needs one clear, paying 140 or 180 respectively.

| After operation | Influence | Coins, slower | Coins, quicker |
| --- | ---: | ---: | ---: |
| Search 1 | 10 | 140 | 180 |
| Restore fountain | 20 | 80 | 120 |
| Complete both search 2 clues | 20 | 500 | 380 |
| Restore temple | 50 | 340 | 220 |
| Complete both search 3 clues | 50 | 760 | 480 |
| Restore archive | 75 | 630 | 350 |
| Complete both search 4 clues | 75 | 1,050 | 610 |
| Restore workshop | 90 | 950 | 510 |
| Complete both search 5 clues | 90 | 1,370 | 770 |
| Open cache | 90 | 1,520 | 920 |

The slower path takes 17 search clears and the quicker path takes 9. Neither
count includes the cache. Both have the same 450-coin restoration spend; a
perfect bonus, optional purchase or different Star outcome changes the balance.
Total future player savings vary, so chapter 2 cannot assume everyone arrives
with either exact wallet. Players can already use alternate decorations to meet
Influence gates. They can also buy shores or other decorations before the cache.

## Proposed chapters 2 and 3

The following is a concrete tuning candidate, not current game behaviour.
Each chapter has five searches with two clues each and a final cache or
Adventure Scene. Keep the current three-Star and prior-best clue rules, base
and first-clear payouts, and no energy or timers for this candidate. Starting
chapter 2 requires the chapter-1 cache. Starting chapter 3 requires the
chapter-2 finale. The preceding search's two clues and the stated Influence
are required to start each subsequent search. Chapter 3 search 5, scene 15,
also requires the workshop restoration because its story enters the workshop.
The finale requires all ten clues. Previously opened searches stay replayable.

These totals are candidate gates for testing story pacing. They do not assert
that June's Journey uses these thresholds. The restore projects below are
independent one-time narrative improvements to be designed against the actual
chapter scripts and island art. They must be accessible even when the player
used decorations instead of optional chapter-1 restorations. The numbers below
are project effects, not existing catalogue purchases or current building
upgrade prices. They are not mandatory if another legal purchase meets a gate.

### Proposed gate and project schedule

| Chapter | Search (scene) | Gate, total Influence | Candidate project before search | Price | Influence gained |
| --- | ---: | ---: | --- | ---: | ---: |
| 2 | 1 (6) | 100 | Archive survey | 100 | 15 |
| 2 | 2 (7) | 120 | Fountain channel survey | 150 | 20 |
| 2 | 3 (8) | 145 | Workshop records | 200 | 25 |
| 2 | 4 (9) | 170 | Temple records | 250 | 25 |
| 2 | 5 (10) | 200 | Gardener's grounds | 300 | 30 |
| 3 | 1 (11) | 230 | Archive work | 300 | 30 |
| 3 | 2 (12) | 260 | Fountain channel work | 320 | 30 |
| 3 | 3 (13) | 295 | Workshop work | 360 | 35 |
| 3 | 4 (14) | 330 | Temple work | 400 | 35 |
| 3 | 5 (15) | 370 | Gardener's grounds work | 450 | 40 |

The chapter 2 candidate projects cost 1,000 coins and add 115 Influence.
Starting at exactly 90, they leave 205. Chapter 3 projects cost 1,830 and add
170, leaving 375. The proposed one-time finale payouts are 150 coins for
chapter 2 and 200 for chapter 3. No mandatory Star gate beyond the clue rules
is included in this candidate, so the existing best-Star behaviour does not
need to be replaced with five-Star mastery.

Scene 15 checks the existing workshop restoration, which costs 100 coins and
adds 15 Influence if it has not already been bought. The two modeled routes
below purchased it in chapter 1, so they incur no second charge. A player who
reached chapter 3 using decorations still has access to that restoration after
one distinct search. The proposed workshop project is a separate one-time
improvement and does not satisfy the scene 15 restoration gate by itself.

The project titles describe tuning slots. Their presentation, location and
artwork are unresolved and require implementation. A project must have a stable
ID, price, Influence gain, unlock condition and persisted claimed flag. Buying
one consumes coins only after confirmation and credits Influence exactly once.
It must not depend on a previous optional one-time building purchase. Cancellation
or insufficient funds leave the wallet and progress unchanged. Repeatable
catalogue decorations may satisfy a gate instead, and already visited searches
remain playable after an economy change or save migration.

### Projected route budgets

The two routes continue from the matching chapter-1 examples, with no optional
purchases or land costs. Every later search has two clues. The slower route pays
420 per search over four clears; the quicker route pays 260 over two. Projects
are bought immediately before their matching search. All prices are affordable
at the point of purchase in these modeled paths. These are calculations from the
candidate rules and the listed assumptions, not measured playthroughs.

| Milestone | Influence | Slower coins | Quicker coins |
| --- | ---: | ---: | ---: |
| Start chapter 2 | 90 | 1,520 | 920 |
| Chapter 2 search 1 complete | 105 | 1,840 | 1,080 |
| Chapter 2 search 2 complete | 125 | 2,110 | 1,190 |
| Chapter 2 search 3 complete | 150 | 2,330 | 1,250 |
| Chapter 2 search 4 complete | 175 | 2,500 | 1,260 |
| Chapter 2 search 5 complete | 205 | 2,620 | 1,220 |
| Chapter 2 finale | 205 | 2,770 | 1,370 |
| Chapter 3 search 1 complete | 235 | 2,890 | 1,330 |
| Chapter 3 search 2 complete | 265 | 2,990 | 1,270 |
| Chapter 3 search 3 complete | 300 | 3,050 | 1,170 |
| Chapter 3 search 4 complete | 335 | 3,070 | 1,030 |
| Chapter 3 search 5 complete | 375 | 3,040 | 840 |
| Chapter 3 finale | 375 | 3,240 | 1,040 |

These trajectories use 20 or 10 search clears per future chapter. Replays
without new Stars still give 80 base coins per successful clear. Actual wallets
will vary. In particular, optional spending, site capacity and any additional
shore costs may require extra replays. A player must always have an accessible
search and an affordable path to Influence. Do not silently award a restoration
or reduce a prior purchase to force this route.

## Before implementation

1. Bind each project slot and chapter gate to the final story beats and source
   IDs. Specify which project dialogues are one-shot and which journal entries
   appear after clues. Finish and review the story before claiming its triggers
   are implemented.
2. Determine how projects are presented without requiring an optional earlier
   restoration or a new asset. Check whole-tile footprints, city clearance and
   available land. If a project changes a building's art or footprint, follow
   `docs/BUILDINGS.md` and inspect the in-game footprint overlay.
3. Extend save data with stable chapter/search/clue/project IDs. Migrate old
   saves without re-paying completed scenes, replaying collected dialogue,
   reducing Influence, moving buildings or revoking access to visited searches.
4. Exercise actual input and persistence around purchase confirmation,
   cancellation, failed affordability, leaving and re-entering a scene,
   repeated claims, clue skips and final rewards. Check zero and surplus wallets,
   a fast three-Star opening, slow clears, alternate decoration gates and
   players who spent on all three shores.
5. Measure the time and number of searches in a playtest, then revise prices and
   gates together. Do not describe the table as June's live balance or as
   implemented until the game, tests and documentation agree.
