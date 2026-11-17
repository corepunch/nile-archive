# Cradle of Rome (2007): game-design and systems reference

> **Purpose:** a consolidated, source-backed design reference for Nile Archive's match-3 games, especially **Christmas Market** and **Relic Rush**. This is a description of *Cradle of Rome*, not a specification for implementing a clone.
>
> **Edition boundary:** unless explicitly labelled otherwise, exact prices, building-to-piece mappings, type IDs, event predicates and board-file counts below refer to the extracted **Awem Cradle of Rome Android beta 0.9.0**. Public guides primarily describe the commercial PC game; contemporary hands-on articles cover the Nintendo DS edition. **Cradle of Rome 2** is a separate game with a different purchase ladder. Do not silently combine their data.
>
> **Research updated:** 16 November 2026. **Evidence key:** **[DATA]** extracted authored game files; **[GUIDE]** published player-facing rules; **[REVIEW]** hands-on reporting; **[INFERENCE]** an explanation consistent with evidence but not proved by execution; **[PROPOSAL]** an idea for our games.

## 1. Reference map and verification standard

There is already unusually good source material in this repository. Use this document for the overall systems picture; use the linked studies and raw exports for exact evidence.

| Existing reference | What it establishes |
| --- | --- |
| [Reference index](README.md) | Android beta provenance, archive paths, extraction and reproduction commands; sequel data; source limitations |
| [Economy and city](ECONOMY_AND_CITY.md) | Original Android piece credits, match multipliers, all 20 building prices and unlocks, citizen event examples |
| [Board design](BOARD_DESIGN.md) | Serialized board geometry, plaque/lock layers, level-by-level structural progression, counts and timer budgets |
| [Adaptation to Relic Rush](ADAPTATION.md) | Changes implemented in Relic Rush versus design proposals and validation tasks |
| [Rome 2 economy export](rome-2-economy.json) | Machine-readable Windows sequel construction costs, requirements, unlocked pieces and yields |
| [Gem correspondence](gem-correspondence.html) | Art/name correspondence between source editions and our pieces |
| [Christmas Market resource prototype](../../games/christmas-market/docs/resource-prototype.md) | Existing 30-level economy implementation and measured first-20-level results |
| [Relic Rush resource expedition](../../games/relic-rush/docs/resource-expedition.md) | Existing resources, story-restoration prices, purchased piece changes and tests |

Independent public cross-checks:

- [Steam: official Cradle of Rome listing](https://store.steampowered.com/app/38170/Cradle_of_Rome/) — Awem, five epochs, more than 100 levels, eight bonus types.
- [GameHouse walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/) — PC-era rules, resource yields, buildings, citizens, tool behaviors and persistence.
- [GameSpot hands-on (17 Oct 2008)](https://www.gamespot.com/articles/cradle-of-rome-hands-on/1100-6199594/) — firsthand Nintendo DS demonstration, one available power-up piece family per board, stored tools across boards, construction pace.
- [WIRED hands-on (21 Oct 2008)](https://www.wired.com/2008/10/hands-on-cradle/) — resource-unlock loop, blue target tiles, chains, tool charge persistence and random tool family selection in DS build.
- [Awem Tips and Tricks](https://support.awem.com/hc/en-gb/articles/200702072--Tips-and-Tricks) — bigger matches, completion bonus, building unlocks, special arrow and combos. Check the article's product context before applying every rule to a specific port.
- [Gamezebo review](https://www.gamezebo.com/reviews/cradle-of-rome-review/) — contemporary review of bonus bar, citizen tasks and risk of failure.
- [MobyGames entry](https://www.mobygames.com/game/32011/cradle-of-rome/) — overview of layered goal tiles and amphora timer.

**Method:** XML and extracted assets can confirm *configured data*, but not everything a real player experiences. A default setting, event callback, or unused board file does not prove a runtime behavior. In particular, the Android APK was **not played** in the source audit. Where public articles conflict with extracted settings, retain both observations and their editions.

## 2. The fundamental design: a board with two jobs

The game's defining feature is a tightly coupled **puzzle → resources → construction → stronger puzzle economy** cycle.

1. Enter a match-3 board with a **win condition** (clear all marked floor plaques) and a **time limit**.
2. Match ordinary icons. The matched *symbol* determines how much Gold, Supplies or Food enters the wallet.
3. Decide whether to clear remaining plaques immediately or use available time to collect a resource needed for the next building.
4. Win the board, take any applicable remaining-time reward and view the growing city.
5. Pay for a building. Its corresponding regular piece or bonus-tool family becomes available on subsequent boards.
6. Skillful play can also unlock a citizen tied to the building, altering future income or tool availability.
7. Repeat with a changed economy and increasingly complex layouts.

This is a feedback loop rather than a decorative metagame. A Mill matters because it introduces **Flour** (a more valuable Food piece); a Forge matters because it introduces **Hammer** charge pieces; a Sawmill matters because it introduces a necessary new resource family.

The choice *inside* a level is important: a resource match can be valuable even when it makes no progress toward the plaques. The same swap might accomplish both. [GUIDE, REVIEW]

### What progression is — and is not

- **Puzzle victory** is objective-based: remove marked plaques, not earn a predetermined number of arbitrary stars.
- **Money is earned by play**, and buildings consume it.
- **Buildings change later boards**, sometimes by increasing a resource's yield and sometimes by introducing a tool family.
- **Not every board requires a new building.** Sources report that players could finish construction in roughly 30 levels if highly effective, or 50–60 ordinarily, despite a 100-plus-level campaign (a producer estimate for the DS version in GameSpot).
- **Do not assert a hard building gate at each numbered level.** The research establishes the building economy and the subsequent changes to boards; it does *not* establish that the player cannot launch level N+1 without first affording a particular structure. Building purchase timing depends on earnings and edition. [REVIEW; DATA]
- The game has an authored finish, epoch ranks and an Olympus objective; these are not equivalent to spending a star after each puzzle.

This explains why the loop feels internally motivated: the objects matched in the puzzle carry a concrete economic meaning outside it.

## 3. Board rules and victory conditions

### Match and refill

- The source format is a **square**, orthogonally adjacent match-3 grid, with swaps forming horizontal or vertical lines of at least three.
- Removed pieces cause gravity/refill and may create cascades; those matches also matter for earnings.
- The underlying *plaque layer* and movable/icon layer are different concepts. Matching over a plaque damages or removes the target under the piece.
- The player wins when all marked plaques are cleared before the timer expires. [GUIDE]
- Level score, construction resources, time and tool charge are different counters. Treat them separately when designing reward screens.

### Plaques and other obstacles

| Feature | Meaning | Evidence |
| --- | --- | --- |
| Plain cell | No target on the floor | [DATA] `Tile puzzle_count=0` |
| Single plaque | One matching hit needed over it | [DATA] `puzzle_count=1`; [GUIDE] |
| Double plaque | Two matching hits over the same cell | [DATA] `puzzle_count=2`; [GUIDE] |
| One/two-stage chains | Piece cannot be freely swapped/moved until locks are broken | [DATA] `Ball lock`; [REVIEW] |
| Chain above plaque | Restrictions and targets may coexist, requiring more planning | [DATA] |
| Irregular active-cell mask | Creates corridors, separate islands and limited matching space | [DATA] |
| Refill/generator markers | Authored refill points, but not a complete runtime refill specification | [DATA; unresolved] |

The source audit conservatively avoids assuming that hitting a chain above a plaque also damages the plaque underneath. That interaction requires runtime verification. The lesson for our hex board is to visually distinguish **unlocking a piece** from **clearing a floor objective**.

### Time, failure and rewards

The original uses a **water amphora** to show remaining time. Finishing sooner can award resources corresponding to the unused time; the Awem guide says the bonus targets the most needed resource. Some builds also have lives/extra-time mechanics. [GUIDE]

The Android Adventure file sets time limits of 300 seconds for levels 1–11, 480 for level 12, 660 for 13–29, 770 for 30–36, 660 for 37, and 770 for 38–100. These are **authored limits**, not measurements of actual time pressure. The data also includes a 60-second extra-time purchase table, score-based extra-life threshold and separate score multipliers. [DATA]

The precise reward banking order, how extra-time cost is charged, whether a failed board retains any matched resources, and whether the commercial editions use identical life rules have **not** been established by the static Android audit. Do not build an exact economy simulation from those assumptions.

### Authored layout progression

The extracted APK ships **115 numbered board XML files**. Its beta flag limits soft release to **1–40**, while configuration describes Adventure **1–100** and Extras **101–115**. The numbers are not evidence that all 115 were accessible in beta.

- Active area spans roughly 62–126 cells in Adventure and averages about 104 cells.
- Level 1 starts with six single plaques and no chains.
- Level 5 first authors a single lock; level 6 places many locks over plaques.
- Level 10 switches heavily to **double plaques** (88 out of 92 active cells).
- Level 20 repeats the all-double-plaque theme on a larger board.
- Level 35 uses two substantial active groups with their own targets and generator markers.
- Level 51 introduces double locks in the authored Adventure data.
- Very late boards mix high target density, restrictions and split areas.

See [BOARD_DESIGN.md](BOARD_DESIGN.md) for the exact ranges, first appearances, per-level samples and ASCII map. **Do not copy the square-board timers or tile counts directly into a 61-cell hex board.**

## 4. Economy: three wallets, multiple icon yields

The fundamental resources are:

- **Gold** — coins, precious objects and trade valuables.
- **Supplies** — timber, stone and related building materials.
- **Food** — provisions for the settlement.

The distinction is between a **piece's appearance** and the **wallet it contributes to**. Different icons can fund the same wallet, but at different rates. This permits city progression to introduce *better* pieces without adding new currencies.

### Regular source-piece table (Android beta 0.9.0)

The following values are **base credits per removed piece** before match-length multipliers. Source type IDs are included to distinguish similarly named art.

| Wallet | Icon / ID | Base credit |
| --- | --- | ---: |
| Gold | Silver coin (3) | 3 |
| Gold | Gold coin (4) | 5 |
| Gold | Ring (12) | 6 |
| Gold | Pearl (13) | 7 |
| Gold | Diamond (16) | 8 |
| Gold | Goblet (15) | 9 |
| Gold | Brooch (14) | 10 |
| Supplies | Lumber (6) | 5 |
| Supplies | Stone (8) | 7 |
| Food | Meat / Water Bucket art (5) | 3 |
| Food | Flour (7) | 4 |
| Food | Barrel (9) | 5 |
| Food | Watermelon (10) | 6 |
| Food | Fish (11) | 7 |

The Android English string calls type 5 **Meat**, but the inspected field-art label says **Water Bucket**. It pays **Food** either way. Two initial score-only pieces (leaf and flower) have no wallet yield. A score-only skull also appears in the game's data, but its normal refill exposure is unverified.

### Match size and examples

The published desktop guide describes the following resource payouts, expressed as a multiple of the icon's base yield:

| Match | Guide total multiplier | Example: Gold coin with base 5 |
| --- | ---: | ---: |
| Three | 3× | 15 Gold |
| Four | 8× | 40 Gold |
| Five | 20× | 100 Gold |

The Android Adventure configuration has *per-piece* match multipliers 1 for length 3, 2 for length 4, 4 for length 5, and 6 for lengths 6/7. Thus 3 × 1, 4 × 2 and 5 × 4 reproduce the guide's 3×, 8× and 20× totals for simple lines. Separate combo settings have multipliers 2/4/6 for counts 2–4, but exact application order requires running the build. [DATA; GUIDE]

This matters: a strategically timed Match-5 can be **more than six times as lucrative** as a Match-3 of the same icon, while also helping to clear plaques. The economy rewards board skill, not just number of cleared levels.

### Scarcity and resource strategy

A building can require multiple wallets at once, so the **limiting resource** changes from purchase to purchase. A player can see that they need more Supplies and deliberately chase a stone match instead of farming more Gold. An early larger-yield food item can immediately make a later food-heavy building affordable.

The exact random piece frequency, variance of earnings by level, and whether late-game balances tend toward persistent surpluses are not established by reading prices alone. Measure those with a running build and seeded simulations before claiming a particular pacing curve.

## 5. Every building in the original 20-purchase ladder

**Authoritative for this table:** `settings/scenes/shop/epochs.xml` in the extracted Android beta, transcribed and cross-checked in [ECONOMY_AND_CITY.md](ECONOMY_AND_CITY.md).

Prices are **Gold / Supplies / Food**. The right column is the **new regular piece or tool-family availability** authored for the construction. A category labelled *Tool* is not an additional production resource.

| Epoch | Building | Price (G / S / F) | Unlocked piece / tool |
| --- | --- | ---: | --- |
| I — Seven Hills | Sawmill | 500 / 0 / 0 | Lumber, +5 Supplies |
| I | Forge / Foundry | 1,000 / 1,000 / 0 | **Hammer** tool pieces |
| I | Quarry | 3,000 / 2,000 / 0 | Stone, +7 Supplies |
| I | Mill | 4,000 / 5,000 / 0 | Flour, +4 Food |
| II — New City | Village | 3,000 / 3,000 / 2,000 | Food piece, +3 Food (type 5) |
| II | Field | 5,000 / 4,000 / 4,000 | Watermelon, +6 Food |
| II | Fountain | 5,000 / 6,000 / 5,000 | **Lightning** tool pieces |
| II | Tavern | 7,000 / 7,000 / 6,000 | Barrel, +5 Food |
| III — Birth of Empire | Rostra | 9,000 / 8,000 / 9,000 | **Bomb** tool pieces |
| III | Arch of Titus | 12,000 / 11,000 / 11,000 | Ring, +6 Gold |
| III | Pantheon | 15,000 / 14,000 / 14,000 | **Hourglass** tool pieces |
| III | Tabularium | 18,000 / 18,000 / 17,000 | **Plus** tool pieces |
| IV — Gladiators' Arena | Port | 20,000 / 23,000 / 21,000 | Fish, +7 Food |
| IV | Ship | 26,000 / 25,000 / 24,000 | Pearl, +7 Gold |
| IV | Lighthouse | 28,000 / 30,000 / 29,000 | **Star** tool pieces |
| IV | Colosseum | 34,000 / 35,000 / 33,000 | **Shield** tool pieces |
| V — Age of Glory | Statue of Trajan | 36,000 / 36,000 / 37,000 | Diamond, +8 Gold |
| V | Temple of Venus and Roma | 40,000 / 42,000 / 42,000 | **Mixer / Orb** tool pieces |
| V | Temple of Saturn | 45,000 / 45,000 / 47,000 | Goblet, +9 Gold |
| V | Forum | 50,000 / 50,000 / 50,000 | Brooch, +10 Gold |

**Crucial reading:** every construction above has **one authored piece or tool type** in this source. It does **not** follow that the player receives one already charged tool, or that the new piece permanently occupies an additional distinct board slot. Actual board-pool and refill selection remain runtime questions.

Each of the 20 `PlanAccess` thresholds equals its corresponding `Price` in the extracted source. Additional authored puzzle-plan content includes jigsaws, searches, sliders and other minigame structures. Whether those plans are mandatory, skipped, separately charged or used in this beta was not verified.

### Why the early progression works

The first four buildings create a particularly legible onboarding chain:

1. Starting coins generate Gold.
2. **Sawmill** costs only Gold and opens the first Supplies producer: Lumber.
3. **Forge** now requires Supplies and offers the first tool family.
4. **Quarry** upgrades Supplies yield via Stone.
5. **Mill** opens Food via Flour **before** Village introduces a price requiring Food.
6. The **Village** unlocks another Food piece, followed by the Field's stronger Food yield.

The player encounters new *needs* shortly after being given a way to meet them. This is a more meaningful story of construction than an unrelated star payment.

## 6. The eight tools: EXACT building-to-tool mapping

The bottom toolbar is an inventory of **unlocked tools and their individual charge meters**, not eight different bonus pieces simultaneously occupying the board. The Android source's eight `BonusBall` records use type IDs **600–607** and credit **3 charge** per removed matching bonus piece toward a separate tool counter (the data's tool resources are types 10–17, configured with range 0–200). [DATA]

| Building [DATA] | Tool | Bonus piece ID [DATA] | Player-facing effect [GUIDE] |
| --- | --- | ---: | --- |
| **Forge** | Hammer | 600 | Removes one selected tile, plaque or chain |
| **Fountain** | Lightning | 604 | Removes multiple scattered tiles; guide describes 20 |
| **Rostra** | Bomb | 601 | Explodes a 3×3 area |
| **Pantheon** | Hourglass | 603 | Adds time to the amphora |
| **Tabularium** | Plus / Cross | 605 | Adds to selected resource/tool charge |
| **Lighthouse** | Star | 607 | Removes every piece with a chosen icon |
| **Colosseum** | Shield | 602 | Clears a whole row |
| **Temple of Venus and Roma** | Mixer / Orb | 606 | Shuffles board pieces |

**Edition warning:** Android `bonuses.xml` specifies **15** lightning kills and `puzzle_kills=1`; the public desktop guide describes **20**. They are not interchangeable balancing constants. For a new hex game, a fixed number of affected hexes, target priority and whether tools earn resource credit must be specified explicitly.

### Why do several buttons appear below the board?

The original divides bonuses into **three separate concepts**:

1. **Unlocked tool inventory:** permanent list of tools earned by construction.
2. **On-board charge piece family:** the family of matchable symbols that produces charge during the current board.
3. **Stored charge / ready state:** a meter per tool, so previously charged tools can be used later.

According to GameHouse, the first board after purchasing a tool-granting building presents that tool's new charge pieces. Later boards pick a charge family randomly from unlocked families. GameSpot and WIRED independently describe **one tool family per board** in the DS build and **saving charged tools across boards**. The Android XML supplies tool types and meter limits but does **not** prove exact selection probability, cross-level persistence or any hard one-use-per-level constraint in that port.

It follows that eight bottom buttons do not require eight tool symbols at once on the puzzle field. One type can charge while several previously charged tools remain available to spend.

### A useful separation from Match-4 / Match-5 specials

A direct-match special (e.g. a rocket spawned by a four-in-a-row) is not the same system as a **building-granted, chargeable inventory tool**.

- **Line special:** created by a special match and ordinarily resides in a board cell until activated.
- **City tool:** unlocked by construction, charged by matching its dedicated piece, stored in the toolbar and activated when needed.
- **Citizen upgrade:** persistent improvement earned by a separate challenge at a building.

Some editions also feature a special arrow for a five-plus match; see Awem Tips and Tricks. Do not assume that a contemporary rocket implementation is an exact recreation of that rule.

## 7. Citizen challenges: buildings can have a second payoff

The construction's first reward is a new piece/tool. A **conditional citizen** supplies a second kind of reward. The public walkthrough documents the following challenges, and the Android `settings/user_events.xml` includes corresponding event predicates for several of them.

| Building | Citizen | Published challenge [GUIDE] |
| --- | --- | --- |
| Sawmill | Farmer | Make a match of five |
| Forge / Foundry | Smith / Blacksmith | Score 10,000 points within ten levels |
| Quarry | Miner | Earn 2,000 Supplies in a level |
| Mill | Miller | Make 15 successful moves in rapid succession |
| Field | Peasant | Earn 3,000 Food in a level |
| Tavern | Wine Maker | Make two successive combos |
| Tabularium | Scholar | Make three successive combos |
| Port | Fisherman | Make three consecutive five-piece matches |
| Forum | Orator | Earn 3,000 Gold in one level |
| Colosseum | Gladiator | Produce a chain reaction of 15 blows |
| Pantheon | Priest | Complete a level in under three minutes |

**Qualification:** the guide's wording about when a challenge can be met is not perfectly consistent across sections. The APK's event-enabling and activation windows should be inspected before insisting every challenge must happen on the single next level.

Some **confirmed Android event effects**, not generalized guesses:

- Sawmill `man_01`: a five-piece match can upgrade the building and provide **+100 Supplies per level**.
- Quarry `man_03`: a 2,000-Supplies achievement can provide **+200 Supplies per level**.
- Field `man_05`: a 3,000-Food achievement can provide **+200 Food per level**.
- Tavern `man_06`: two-combo event can provide **+300 Food per level**.
- Forum `man_011`: Gold-target event modifies **tool weights**, not just currency.

Thus citizen effects may change **future income** *or* **tool availability**. Neither a character portrait nor a purely cosmetic upgrade captures the entire mechanic.

**Design lesson:** there are three timescales of reward:

1. Immediate: earning resources on a match.
2. Medium: purchasing a structure, unlocking a piece/tool.
3. Long: meeting a skill challenge, improving an ongoing economy or tool system.

The last layer is optional for a small game, but it provides a natural reason to revisit a building.

## 8. Campaign and presentation

### City and epochs

Steam advertises **five historical epochs**, more than **20 architectural masterpieces** and more than **100 levels**, finishing with Olympus and Emperor status. In the inspected Android construction table there are **20 priced entries** (four per epoch) plus an Olympus completion entry. The figures are compatible as marketing counts and authored data, but should not be used as an exact universal building count across every edition. [GUIDE; DATA]

The player sees a city that gradually fills with structures. The structure list/price is presented outside the board. Returning to the city after a level gives the previous puzzle's earnings a tangible use.

Reported ranks are Peasant → Merchant → Priest → Senator → Emperor. Olympus provides a long-range aspiration beyond the next structure. The game also includes informational descriptions of Roman architecture; the setting is more than an arbitrary decoration layer. [GUIDE]

### Progression and pacing

A long campaign can support many boards between buildings. The player may occasionally have sufficient resources for multiple improvements or be short on one resource after a win. A good design makes those situations intelligible rather than silently generating a star to patch a mismatch.

Things that can be **inferred from the architecture** but **not measured from static files**:

- Early cheap buildings are suited to onboarding.
- Later expensive entries encourage repeated earning.
- More valuable pieces can increase future purchasing power.
- The economy may reward skilled play by reducing the number of puzzles before the city is complete.

Things that are **not proved**:

- A fixed purchase after each numbered level.
- A mandatory one-building-per-level story cadence.
- Exact wall-clock time or average number of attempts to purchase each building.
- The probability of a particular tool-charge piece family appearing in each level.
- Identical resource yields, tools or building order in every PC, Android, DS and iOS build.

### The player-facing UI contract

A useful adaptation keeps these facts visually explicit:

- The matchable icon has a recognizable **resource family**.
- A match's resource payout is understandable without reading a separate manual.
- The city shows **cost**, **current balance**, and **remaining shortfall**.
- A building purchase preview states **what this building unlocks**.
- The next board visibly calls attention to the newly unlocked piece/tool.
- Bonus meters are separate from Gold/Supplies/Food.
- An achievement/citizen's persistent effect is described, not hidden.

## 9. Cradle of Rome 2 is not the same purchase ladder

The repository also includes a full Windows **Cradle of Rome 2** resource export. A prominent first-epoch contrast:

| Original Android beta, Rome I | Sequel Windows, Rome II |
| --- | --- |
| Sawmill: 500 Gold → Lumber (+5 Supplies) | Well: 500 Gold → Water Bucket (+3 Food) |
| Forge: 1,000 Gold + 1,000 Supplies → Hammer | Hunter's Hut: 1,000 Gold + 1,500 Food → Hammer |
| Quarry: 3,000 Gold + 2,000 Supplies → Stone (+7 Supplies) | Sawmill: 3,000 Gold + 2,500 Food → Lumber (+5 Supplies) |
| Mill: 4,000 Gold + 5,000 Supplies → Flour (+4 Food) | Village: 2,000 Gold + 3,000 Supplies + 2,000 Food → Bomb |

This difference matters when comparing gameplay recordings or screenshots. A screenshot showing **Water Bucket** in the opening levels and a **Well** as the first purchase is useful evidence for **Rome 2**, not for the original Android beta's Sawmill-first ladder. For all Rome 2 entries, see [rome-2-economy.json](rome-2-economy.json) and the [sequel section of the source index](README.md#cradle-of-rome-2-economy-data).

Do not infer that the Forge gives a hammer in Rome 2 merely because it does so in Rome I. Some building names recur with different functions or places in the order.

## 10. What Nile Archive's games already borrow

These are **repo documentation snapshots**, not a claim that the latest running code has been inspected in this document.

### Relic Rush

[Existing adaptation](ADAPTATION.md) and [resource-expedition.md](../../games/relic-rush/docs/resource-expedition.md) already describe a strong Rome-like structure:

- Puzzle wins and repeated clears earn **Coins, Supplies and Food**.
- Twenty restorations (ten story, ten between them) are purchased with actual balances, and each unlocks one board change, as in Rome's ladder.
- Higher-yield pieces are introduced after restorations.
- Expedition Camp and Star Observatory introduce tool effects.
- A replay can recover a resource shortfall.
- Story progress and land/decorative access use separate, non-spendable Stars.
- Important intentional differences: **hex geometry**, **move limit instead of timed amphora**, **short 30-board campaign**, and our own economy values.

The key unanswered design question is whether players recognize **which purchase caused which new piece** and can explain the new piece's economic benefit. See the scripted test/seed recommendations in the adaptation study.

### Christmas Market

[Christmas Market resource prototype](../../games/christmas-market/docs/resource-prototype.md) documents a **30-wish** campaign, Gold/Supplies/Food, exact purchase costs, real board-earned payouts and story-linked market stalls.

At the time of that resource-prototype document:

- Building costs are about one tenth of the source's early Roman price ladder.
- The first purchase gives Firewood (+5 Supplies); later purchases give more valuable resource pieces.
- **Lumber workshop → Hammer**, debut board 5.
- **Candlelight shop → Lightning**, debut board 20.
- The prototype describes tools **starting uncharged on each board**, a seeded choice of one unlocked charge family when several exist, and a 200-charge threshold.
- The market also has **stars for land/decor access**; these are not spent as a universal repair currency.

The shared engine has no match-made specials: as in Rome, power comes only from the inventory tools.

### Differences we should preserve

Cradle of Rome is a design reference, not a specification that we must reproduce literally. In particular, there is no reason to import:

- PC-sized 100-plus-cell square layouts into a compact portrait hex game;
- a real-time amphora into an intentionally untimed, move-limited Christmas Market;
- the exact original prices/earning scale;
- a recurring citizen-income simulation before its use is clear;
- hard life gates, extra-time purchases or other business-model systems;
- the entire eight-tool bar onto a small iPhone display.

## 11. Suggested Christmas Market design extension [PROPOSAL]

This section is **not** an inventory of implemented mechanics. It is a possible direction inspired by the original's causal progression.

### A limited six-tool target, not eight at launch

Six tools total can be an upper design target **if** they remain readable and sufficiently distinct. Prototype **two existing ones** thoroughly before committing to four more. Suggested functions:

| Category | Example Christmas tool | Function to test |
| --- | --- | --- |
| Precise action | Hammer (existing) | Remove one chosen piece, chain or floor layer; specify target priority |
| Random sweep | Lightning (existing) | Strike a controlled number of hex cells; define preference for uncompleted objectives |
| Area clear | Firecracker | Clear a small neighborhood around a selected hex |
| Line clear | Garland | Clear one of the three hex axes in a chosen direction |
| Recovery | Santa's Parcel | Shuffle without causing unwanted automatic payouts or deadlock |
| Resource/charge | Festive Star | Collect one selected piece family or replenish an existing tool |

A **time extension** is inappropriate for a move-limited game unless intentionally replaced with a **move extension** (which changes difficulty and monetization assumptions). Do not copy the Hourglass verbatim.

### Building link must be meaningful

Possible pairings with **already existing** market-wish buildings:

- Lumber workshop → Hammer (already documented).
- Candlelight shop → Lightning (already documented).
- Toymaker's workshop → a precision or shuffle effect **only if it does not duplicate Hammer**.
- Gift wrapping pavilion → a selectable piece-family/resource effect.
- Reindeer carousel → a sweeping/line tool.
- Christmas tree → a late-game board-wide event or one-time upgrade.

Those last four are **ideas, not source-game mappings and not implemented commitments**.

### Charged tool UX for a phone

- A board normally exposes **zero or one charge-piece family**; a newly unlocked family is shown on the first eligible board after construction.
- The bottom panel displays only **unlocked** tools. Let it scale to 2–4 visible tools plus an overflow/second row if six cannot fit with legible hit targets.
- Distinguish **ready**, **charging**, **not unlocked** and **temporarily unavailable**.
- Make the charge acquisition cost visible: the player should understand why matching three themed tool icons fills a particular meter.
- Decide explicitly whether charge carries between boards. This is a **major** difference between the original desktop/DS reports and the documented Christmas prototype; persistence should not change accidentally during a refactor.
- If direct Match-4/Match-5 specials also exist, preserve distinct UI and state models for **on-board specials** versus **inventory tools**.

### Resource loop and fairness

1. A building should unlock a resource piece that pays into a purse **needed by a future purchase**, or a tool that clearly helps the next puzzle challenge.
2. The next board should make the new piece/tool **visible enough to notice** without requiring a guaranteed winning path.
3. The result screen should show **earned resources**, not just score/stars.
4. An unaffordable building should show the exact **missing resource amounts** and a playable earning route. Replays or other earning opportunities should remain available; avoid silent softlocks.
5. Paid optional decoration must not consume the reserved resources of required story construction.
6. Higher-yield pieces must be balanced against the number of spawn slots and legal swaps. A growing list of every past icon is not automatically better than a curated rotating pool.
7. Skill rewards (large matches, economical play) should matter without forcing a user to replay an already completed chapter for its required story building.

### Optional citizen-style objectives

Rather than giving every stall passive income, prototype **one** optional mastery event:

> After building the Gingerbread Bakery, make two five-piece matches on any later eligible board to earn an upgrade that improves the Food payout of its relevant piece.

Show the goal on the building card, do not expire it after one attempt, make the claim idempotent and ensure old saves are unaffected. This is a proposed test of the *second-payoff* pattern, not a request to add it immediately.

## 12. Research questions requiring a real build or instrumentation

| Question | Why it matters | How to test |
| --- | --- | --- |
| Does original Rome I allow a new level without the next construction? | Avoid false one-building-per-level gating | Run PC/Android retail/beta, finish a board while short of Supplies and try Continue |
| Does every original edition offer just one charge family per board? | Palette complexity and tool pacing | Log visible bonus piece IDs across many boards after unlocking two or more tools |
| Does cross-board tool charge persist in the Android beta? | Save structure and user strategy | Charge to a partial value, win, compare meter, restart app |
| Is a tool usable more than once per level when recharged? | Consumption and balance | Trigger/charge the same tool twice in one long board |
| Does matching a chained plaque clear both layers? | Board work-count model | Create isolated chained plaque, inspect state after each hit |
| What exactly does the Plus tool boost? | Prevent incorrect UX language | Test each resource/tool target and resulting meter/wallet |
| Does an unfinished/failed board keep any earned resources? | Economic softlocks and retry incentives | Check wallet before entry and after fail/timeout |
| What triggers a specific citizen and when? | Optional mastery design | Verify `enable_user_events`, event predicates and rewards live |
| What changes when more regular pieces unlock than the board can fit? | Match probability and palette identity | Instrument available types and actual spawn distribution |
| How is the remaining-time bonus apportioned? | Tradeoff of earning versus finishing quickly | Finish otherwise identical seeded boards at different times |
| Do tool effects collect resource credits for destroyed pieces? | Correct wallet accounting | Compare payouts with and without tool clearing of equivalent cells |

For source inspection, use the analyzer, not screenshots alone:

```sh
python3 tools/reference/cradle-of-rome/analyze.py --level 35
python3 tools/reference/cradle-of-rome/analyze.py > /tmp/cradle-of-rome.json
```

For the sequel, add `--root reference/cradle-of-rome-2/resources` **after extracting the copyrighted pack locally** according to [README.md](README.md). The unpacked original assets are research inputs and are not included in this Markdown.

## 13. Design principles worth retaining

1. **Build → mechanic:** new construction should change some *future* action, not solely decorate the city.
2. **Pieces mean something:** ordinary matched icons can be genuine economic production, not arbitrary candy.
3. **One wallet, several tiers:** higher-yield food/gold/supply icons make the settlement's growth observable inside puzzles without adding currencies.
4. **Two simultaneous goals:** the player can improve the settlement while solving the immediate board objective.
5. **Tools are separate from tool pieces:** a full toolbar and one current charge family are compatible.
6. **Progression is not a rigid star treadmill:** earnings and spending need not happen at exactly one building per level.
7. **Optional skill achievements extend buildings:** a citizen/mastery challenge can provide a second, lasting payoff.
8. **State the edition:** original Rome I, Android beta, DS and Rome II are not one interchangeable specification.
9. **Use a short measurable prototype:** a clear, tested two-tool system is worth more than six barely differentiated icons.
10. **Expose causality in the UI:** show which building unlocked the piece, which wallet it pays, and what the next purchase needs.

**Bottom line:** the most valuable reference is the *causal connection between matching, city resources, construction and future board rules*. That system gives a small town-building game a sense of economic and mechanical progression without requiring a huge renovation narrative or an abstract spendable-star layer.
