# Designing a match-3 campaign: flow, balance, upgrades and cast

How Relic Rush and Christmas Market are put together, on Cradle of Rome 2 as the backbone. Read it before changing a campaign's levels, purchases, prices, upgrades, cast or story schedule. The story's own rules are in [STORY_WRITING.md](STORY_WRITING.md); board layout is in [LEVEL_DESIGN.md](LEVEL_DESIGN.md).

## The backbone: Cradle of Rome 2

Cradle of Rome 2 (GameTop Windows edition, data in `reference/cradle-of-rome-2/resources`, summary in [the reference](cradle-of-rome-reference/README.md)) runs on three nested loops. We keep all three.

| Loop | Rome 2 | Our games |
| --- | --- | --- |
| **The board** | Clear every marble tablet before the time runs out. Matched coins, food and materials go to the wallet. | Clear every plaque or pane within a move budget. Matched pieces pay Coins/Tokens, Food/Treats and Supplies/Materials. |
| **The purchase** | Twenty buildings in five epochs of four. Each pays off on the board: a richer piece or one of eight tools. | The same twenty rewards in the same order, one purchase every five levels, four per epoch (Relic Rush) or Advent (Christmas Market). |
| **The citizen** | Sixteen buildings each arm one optional feat. Meeting it brings a citizen, upgrades the building and adds income every level or makes its tool come more often. | The same sixteen feats upgrade the building through the character who runs it (see [Upgrades](#upgrades-romes-citizens-kept-by-the-cast-we-know)). |

What we add on top is the story: one short scene after every level, and a scene when each story building is placed. What we take away is the timer: our boards count moves.

## Game flow

The player's minute-to-minute loop:

1. **Play a level.** The board shows the current pieces and, from its building on, one tool piece. Thirty matched tool pieces charge the tool's slot once.
2. **Collect.** The results card banks the matched resources. A first clear also plays that level's scene.
3. **Build.** In town, the Build button shows the next purchase with its price or shortfall. A particle trail circles the button when it is affordable. The player places the building and confirms; a story building plays its scene.
4. **See the change.** The next board shows the new piece or tool. Meeting a building's feat upgrades it, with a short scene from its keeper.

The campaign's shape:

| | Levels | Purchases | Story buildings | Closes with |
| --- | --- | --- | --- | --- |
| Epoch / Advent 1 | 1–20 | after 1, 6, 11, 16 | two | a turning scene on the level-20 boss |
| 2 | 21–40 | after 21, 26, 31, 36 | two | 40 |
| 3 | 41–60 | after 41, 46, 51, 56 | two | 60 |
| 4 | 61–80 | after 61, 66, 71, 76 | two | 80 |
| 5 | 81–100 | after 81, 86, 91, 96 | two | the finale at 100 |

- **Purchases open every five levels** (`after` in `economy.unlocks`). The first is affordable after level 1, so the player builds within a minute.
- **Story buildings hold the next level.** The level after a story building waits until it stands, and so does every earlier purchase. Other purchases never block, so a player may run ahead of them. The scenes may speak of a non-story building as standing only from the next story building's scene on.
- **Each building pays off on the board.** A purchase gives the piece or tool its artwork shows: the bakery gingerbread, the candle shop the lantern. A piece replaces a line of the palette; a tool takes its permanent slot (Hammer → Bomb, Shield → Plus, Hourglass → Mixer, Lightning → Star).
- **Boards follow a ten-level rhythm.** Tiers run `easy, easy, normal, normal, hard, easy, normal, normal, hard, boss` after four tutorials. A boss is dense and the board after it is a breather.
- **Regions open** after 15, 30, 50, 70 and 85 levels cleared, each with a line from a main character.

## Balance

Balance is measured, never guessed. The greedy bot (`tests/lua/greedy_bot.lua`) plays every board many times, and the tools fit the numbers to what it does.

| What | Target | Tool |
| --- | --- | --- |
| Board validity | Fits 9 × 12; pieces can fall onto every target; at least 6 target layers and 45 cells | `python3 tools/square_boards.py <game>` |
| Board length | The bot's median game within the tier ceiling: easy 30, normal 45, hard 60, boss 70 moves | `python3 tools/square_trim.py <game> --levels A-B` |
| Move budget | Median × tier margin: tutorial 2.5, easy 2, normal 1.4, hard 1.2, boss 1 | `python3 tools/tune_moves.py <game>` |
| Prices | Each purchase spends 70% of what the expected wallet holds in the currencies it uses; the expected campaign needs no replays | `python3 tools/balance.py <game>` |

**Rules for prices.**

- **Keep Rome's currency mix.** A purchase uses the currencies its Rome counterpart uses (Rome's Farm costs no Food, so neither does the bakery). Only the amounts are fitted.
- **Fit to the bot's income without upgrades.** An upgrade is a reward for skill. Prices assume none, so a player who earns upgrades builds sooner and has spare resources for decorations, as in Rome.
- **No replay should be needed.** `balance.py` walks the expected campaign; any replay it reports is a bug in the boards or prices, not a design choice. The extended `campaign_play` test plays the whole campaign with the bot on fixed seeds and allows at most five replays for income, since one below-average board can leave a purchase short.
- **Prices rise.** A later purchase never costs less in total than the one before it. Income grows with each richer piece, so a price that drops tells the player nothing about progress.
- **Refit after any change** to boards, piece yields, unlock order or upgrade perks, and commit the regenerated catalogue.

**What one board pays.** Measured with the current boards (bot, mean per won board, Coins/Tokens · Food/Treats · Supplies/Materials):

| Levels | Relic Rush | Christmas Market |
| --- | --- | --- |
| 1–10 | 206 · 75 · 0 | 204 · 72 · 0 |
| 21–30 | 126 · 162 · 146 | 234 · 121 · 181 |
| 41–50 | 156 · 352 · 219 | 257 · 187 · 218 |
| 61–70 | 181 · 307 · 177 | 446 · 281 · 281 |
| 81–90 | 388 · 501 · 289 | 438 · 257 · 217 |

## Upgrades: Rome's citizens, kept by the cast we know

Rome 2's sixteen citizens (`settings/user_events.xml`, events `man_01` to `man_16`) are optional skill feats tied to buildings. When the building stands, its feat is armed. Meeting it once upgrades the building for good and gives one lasting perk: **income every level** in one currency, or **a tool that comes more often**. In Rome the citizen is an anonymous figure that appears at the building and never speaks.

We keep the feats, the upgrades and the perks, and give each upgrade to **the character who already runs that building**. Agnes gets a second oven; Tomas mends his father's traps. No new person arrives: the player sees someone they know get better at what they do.

- **The upgrade is the keeper's scene.** Its two to four lines are the keeper and one other main character, about what has improved and what it means to them. The perk is felt in the world ("I'll have a tray out before the first train"), never named as a rule ("your Treats income rises").
- **Optional and timeless.** An upgrade plays on the next return to town after its feat, at any point after its building stands, so it never refers to story events by level and never depends on them. The required story never depends on an upgrade.
- **Perks are scaled to our income.** The feat "earn X in one level" asks for about twice the mean board income in that currency in the ten levels after the building. Income per level is Rome's ratio of perk to threshold, capped at 20% of the threshold and rounded to fives. A tool upgrade makes its tool's piece charge one point more per match; two on one slot add up.
- **Rome feats we cannot measure get the nearest equivalent.** "Collect three lives" becomes three wins in a row without a failed level; feats in seconds keep Rome's time.
- **The perk is shown.** The building's card shows the feat while it is armed and the upgrade with its perk once met, as resource indicators; the income is part of every win's total.
- **Shared runtime.** Both games run Rome's If/Then events on `engine/lua/match3/user_events.lua`; each game supplies its data in `lua/user_events.lua` and its scenes in `docs/story.md` under `## Upgrades` ([engine notes](MATCH3_ENGINE.md)).

| # | Rome 2 | Feat | Perk | Relic Rush upgrade (keeper) | Christmas Market upgrade (keeper) |
| --- | --- | --- | --- | --- | --- |
| 1 | Well (`man_03`) | 150 Food / Treats in one level | +10 every win | Spring well: a second rope and pulley (Tomas) | Welcome arch: a mulled-wine hatch in the arch (Noelle) |
| 2 | Hunter's hut (`man_04`) | A match of five | Hammer charges faster | Trapper's cabin: his father's tools sharpened (Tomas) | Reindeer stable: new shoes and bells for the sleigh-horse (Pip) |
| 3 | Sawmill (`man_02`) | 300 Supplies / 230 Materials in one level | +60 / +45 every win | Carpenter's workshop: a second saw bench (Mara) | Lumber workshop: a drying shed for the pine (Theo) |
| 4 | Village (`man_01`) | 10 moves in a row that each clear a target | Bomb charges faster | Expedition camp: a proper powder store (Adrian) | Firework stall: a rocket rack, ready in threes (Pip) |
| 5 | Farm (`man_05`) | 325 Food / 240 Treats in one level | +55 / +40 every win | Jungle market: the hill farms send their carts (Marisol) | Gingerbread bakery: a second oven (Agnes) |
| 6 | Mine (`man_06`) | 300 Supplies / 360 Materials in one level | +60 / +70 every win | Stone trading post: a cart road to the quarry (Adrian) | Snowy chapel: the masons' yard behind the chapel (Mr Wren) |
| 7 | Mill (`man_07`) | 430 Food / 325 Treats in one level | +85 / +65 every win | Water mill: a second millstone (Elena) | Hot cocoa kiosk: Mrs Alder's ladle and second pot (Mrs Alder) |
| 8 | Thermae (`man_08`) | Five matches of five in one level | Shield charges faster | Tide clock tower: a warning chime (Tomas) | Ice house: a second ice saw on the lake (Theo) |
| 9 | Port (`man_09`) | 700 Food / 375 Treats in one level | +140 / +75 every win | Harbour plaza: a fish market every morning (Marisol) | Lakeside smokehouse: a second smoking rack (Mr Finch) |
| 10 | Coliseum (`man_10`) | 330 Coins / 700 Tokens in one level | +65 / +140 every win | Stone amphitheatre: market-day shows (Adrian) | Toymaker's workshop: a second bench and a shop bell (Henrik) |
| 11 | House of the Vestals (`man_11`) | Two matches of five in a row | Lightning charges faster | Cartographer's house: storm charts on the wall (Elena) | Candlelight shop: Mr Wren trims every wick (Mr Wren) |
| 12 | Lighthouse (`man_12`) | 15 matches within 20 seconds | Plus charges faster | Lighthouse: a polished lens (Mara) | North Pole post office: a second sorting rack (Pip) |
| 13 | Nero's Golden House (`man_13`) | 575 Coins / 760 Tokens in one level | +115 / +150 every win | Beached schooner: a ferry to the hill villages (Mara) | Glassblower's stall: a second furnace (Theo) |
| 14 | Mausoleum (`man_14`) | Three wins in a row without a failed level | Mixer charges faster | Star observatory: the telescope realigned (Elena) | Reindeer carousel: a band organ (Pip) |
| 15 | Theatre (`man_15`) | 775 Coins / 875 Tokens in one level | +155 / +175 every win | Relic museum: a reading room open to all (Adrian) | Woodcarvers' hall: Henrik's old apprentices come back (Henrik) |
| 16 | Forum (`man_16`) | 15 moves in a row that each clear a target | Star charges faster | Temple of the Sun: the keepers' watch roster (Tomas) | Christmas tree: a star for the top (Theo) |

Rome gives no feat to the Curia Octavia, Aqueduct, Pantheon and the city centre: the Harbour lodge, Keeper's archive, Great aviary and Jade fountain in Relic Rush, and the Station kiosk, Gift wrapping pavilion, Winter skating rink and Santa's sleigh in Christmas Market.

## Cast economy

Players remember a few people well, not many people faintly. Before adding a speaker, give the line to someone the player already knows.

- **What the references do.** Tropicats starts with one quest-giver and adds about one per chapter of forty levels: five by level 170, six in 2,800 levels, and Elsie gives 249 of its 274 quests ([story reference](tropicats-reference/STORY.md)). Its upgrades restore a known character's place, such as Cubby's grill and Lily's hut. Rome 2's citizens are anonymous figures that never speak. Life games grow the same shopkeepers' shops instead of adding new shopkeepers, and screenwriters merge minor roles into existing characters so the audience tracks fewer people.
- **At most one new speaker per epoch**, and none in the first. The exception is a long-awaited arrival the whole story has been building to, such as Pip's mum and Gran stepping off the last train.
- **Talk about a person before they speak.** A new speaker is planted in others' lines first (Mrs Alder's candles and cup, Mr Finch's goat, Pip's mum, Gran), so their first line is a payoff, not an introduction.
- **Every speaker has a want and comes back.** A character who speaks has a want of their own and appears in at least three beats. Anyone with less stays a name in someone else's mouth.
- **Growth before addition.** A building's improvement, a new job or a return visit belongs to someone the player knows. Give the keeper the change, not a newcomer.
- **Name only what recurs.** A one-off helper is "the farrier" or "Marisol's cousin", not a new name.

## Story cadence

The full rules are in [STORY_WRITING.md](STORY_WRITING.md). In short:

- **One scene after every level's first clear**, two or three lines, and one when each story building is placed. Replays are silent.
- **Speech only.** Every line is said by someone to someone, wanting something. No narration, no captions, no reports of what the screen shows. [Why](STORY_WRITING.md#speech-only-no-narration).
- **Each epoch is a chapter** with one question. Its four purchases set it up, move it on and pay it off; its boss level turns it.
- **Upgrades add optional scenes** from the building's keeper; the required story never depends on them.
- **The cast stays small and grows deeper.** See [Cast economy](#cast-economy): at most one new speaker per epoch, planted before they speak. A new speaker without a painted bust is shown with a name plate until one is painted (track it in an issue).
