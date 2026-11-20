# Designing a match-3 campaign: flow, balance and citizens

How Relic Rush and Christmas Market are put together, on Cradle of Rome 2 as the backbone. Read it before changing a campaign's levels, purchases, prices, citizens or story schedule. The story's own rules are in [STORY_WRITING.md](STORY_WRITING.md); board layout is in [LEVEL_DESIGN.md](LEVEL_DESIGN.md).

## The backbone: Cradle of Rome 2

Cradle of Rome 2 (GameTop Windows edition, data in `reference/cradle-of-rome-2/resources`, summary in [the reference](cradle-of-rome-reference/README.md)) runs on three nested loops. We keep all three.

| Loop | Rome 2 | Our games |
| --- | --- | --- |
| **The board** | Clear every marble tablet before the time runs out. Matched coins, food and materials go to the wallet. | Clear every plaque or pane within a move budget. Matched pieces pay Coins/Tokens, Food/Treats and Supplies/Materials. |
| **The purchase** | Twenty buildings in five epochs of four. Each pays off on the board: a richer piece or one of eight tools. | The same twenty rewards in the same order, one purchase every five levels, four per epoch (Relic Rush) or Advent (Christmas Market). |
| **The citizen** | Sixteen buildings each arm one optional feat. Meeting it brings a citizen, upgrades the building and adds income every level or makes its tool come more often. | Sixteen named citizens, one per building, on the same feats (see [Citizens](#citizens)). |

What we add on top is the story: one short scene after every level, and a scene when each story building is placed. What we take away is the timer: our boards count moves.

## Game flow

The player's minute-to-minute loop:

1. **Play a level.** The board shows the current pieces and, from its building on, one tool piece. Thirty matched tool pieces charge the tool's slot once.
2. **Collect.** The results card banks the matched resources. A first clear also plays that level's scene.
3. **Build.** In town, the Build button shows the next purchase with its price or shortfall. A particle trail circles the button when it is affordable. The player places the building and confirms; a story building plays its scene.
4. **See the change.** The next board shows the new piece or tool. A citizen may arrive when the player meets a feat.

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
- **Fit to the bot's income without citizens.** A citizen is a reward for skill. Prices assume none has arrived, so a player who earns citizens builds sooner and has spare resources for decorations, as in Rome.
- **No replay should be needed.** `balance.py` walks the expected campaign; any replay it reports is a bug in the boards or prices, not a design choice. The extended `campaign_play` test plays the whole campaign with the bot on fixed seeds and allows at most five replays for income, since one below-average board can leave a purchase short.
- **Prices rise.** A later purchase never costs less in total than the one before it. Income grows with each richer piece, so a price that drops tells the player nothing about progress.
- **Refit after any change** to boards, piece yields, unlock order or citizen perks, and commit the regenerated catalogue.

**What one board pays.** Measured with the current boards (bot, mean per won board, Coins/Tokens · Food/Treats · Supplies/Materials):

| Levels | Relic Rush | Christmas Market |
| --- | --- | --- |
| 1–10 | 206 · 75 · 0 | 204 · 72 · 0 |
| 21–30 | 126 · 162 · 146 | 234 · 121 · 181 |
| 41–50 | 156 · 352 · 219 | 257 · 187 · 218 |
| 61–70 | 181 · 307 · 177 | 446 · 281 · 281 |
| 81–90 | 388 · 501 · 289 | 438 · 257 · 217 |

## Citizens

Rome 2's sixteen citizens (`settings/user_events.xml`, events `man_01` to `man_16`) are optional skill feats tied to buildings. When the building stands, its feat is armed. Meeting it once brings the citizen for good: a figure at the building, a trophy, and one lasting perk. The perk is one of two kinds: **income every level** in one currency, or **a tool that comes more often** (its piece's weight on the board). Collecting all sixteen is an award of its own.

We keep the system and give every citizen a name, a job and a two- or three-line arrival scene.

- **A citizen is a new character.** Each has a name and a trade that matches the building, and speaks in the arrival scene with one main character. The scene is speech like any other: the name comes up because someone greets or asks, never as a badge ("Dita. I clear rock for a living."), and the perk is felt in the world ("the tower will chime before the tide turns"), never named as a game rule ("your Shield will be ready sooner"). Give each scene its own shape: a complaint, a bargain, a challenge, a joke. Citizens may come back later in the scenes of their own building's tap line, never in a required story scene, because a player may not have them.
- **Perks are scaled to our income.** The feat "earn X in one level" asks for about twice the mean board income in that currency in the ten levels after the building. Income per level is Rome's ratio of perk to threshold, capped at 20% of the threshold and rounded to fives. A tool citizen makes its tool's piece charge one point more per match.
- **Rome feats we cannot measure get the nearest equivalent.** Rome's "collect three lives" becomes three wins in a row without a failed level; feats that use seconds keep Rome's time.
- **The perk is shown.** The building's card names the citizen and shows the feat or the perk as resource indicators; the arrival scene plays on the next return to town (a toast if the script has none), and the income is part of every win's total. Two citizens on one tool slot add up: a Hammer and a Bomb citizen make that slot's pieces worth 5.
- **Shared runtime.** Both games run Rome's If/Then events on `engine/lua/match3/user_events.lua`; each game supplies its data in `lua/user_events.lua` and its scenes in `docs/story.md` under `## Citizens` ([engine notes](MATCH3_ENGINE.md)).

| # | Rome 2 | Feat | Perk | Relic Rush citizen | Christmas Market citizen |
| --- | --- | --- | --- | --- | --- |
| 1 | Well (`man_03`) | 150 Food in one level | +10 Food every win | Lupe the water-carrier, Spring well | Clem the lamplighter, Welcome arch |
| 2 | Hunter's hut (`man_04`) | A match of five | Hammer charges faster | Old Bastian the trapper, Trapper's cabin | Ned the farrier, Reindeer stable |
| 3 | Sawmill (`man_02`) | 300 Supplies in one level | +60 Supplies every win | Joaquín the carpenter, Carpenter's workshop | Big Ivar the woodcutter, Lumber workshop |
| 4 | Village (`man_01`) | 10 moves in a row that each clear a target | Bomb charges faster | Dita the blaster, Expedition camp | Dot the firework maker, Firework stall |
| 5 | Farm (`man_05`) | 325 Food (RR) / 240 Treats (CM) in one level | +55 / +40 every win | Auntie Marisol the trader, Jungle market | Hettie the icer, Gingerbread bakery |
| 6 | Mine (`man_06`) | 300 Supplies / 360 Materials in one level | +60 / +70 every win | Basile the stonecutter, Stone trading post | Old Mags the stonemason, Snowy chapel |
| 7 | Mill (`man_07`) | 430 Food / 325 Treats in one level | +85 / +65 every win | Hana the miller, Water mill | Mrs Alder, Hot cocoa kiosk |
| 8 | Thermae (`man_08`) | Five matches of five in one level | Shield charges faster | Ferro the clockmender, Tide clock tower | Olaf the ice cutter, Ice house |
| 9 | Port (`man_09`) | 700 Food / 375 Treats in one level | +140 / +75 every win | Nilo the fisher, Harbour plaza | Mr Finch the fisherman, Lakeside smokehouse |
| 10 | Coliseum (`man_10`) | 330 Coins / 700 Tokens in one level | +65 / +140 every win | Zaza the drummer, Stone amphitheatre | Lotte the toymaker's apprentice, Toymaker's workshop |
| 11 | House of the Vestals (`man_11`) | Two matches of five in a row | Lightning charges faster | Ruth the cartographer, Cartographer's house | Lucia the candle girl, Candlelight shop |
| 12 | Lighthouse (`man_12`) | 15 matches within 20 seconds | Plus charges faster | Captain Ulla, Lighthouse | Mr Penny the postmaster, North Pole post office |
| 13 | Nero's Golden House (`man_13`) | 575 Coins / 760 Tokens in one level | +115 / +150 every win | Pike the shipwright, Beached schooner | Gianna the glassblower, Glassblower's stall |
| 14 | Mausoleum (`man_14`) | Three wins in a row without a failed level | Mixer charges faster | Dr Amani the astronomer, Star observatory | Sid the organ-grinder, Reindeer carousel |
| 15 | Theatre (`man_15`) | 775 Coins / 875 Tokens in one level | +155 / +175 every win | Mr Sato the curator, Relic museum | Rolf the woodcarver, Woodcarvers' hall |
| 16 | Forum (`man_16`) | 15 moves in a row that each clear a target | Star charges faster | Ixchel the storyteller, Temple of the Sun | Mr Bellamy the Fenwick choirmaster, Christmas tree |

Rome gives no citizen to the Curia Octavia, Aqueduct, Pantheon and the city centre: the Harbour lodge, Keeper's archive, Great aviary and Jade fountain in Relic Rush, and the Station kiosk, Gift wrapping pavilion, Winter skating rink and Santa's sleigh in Christmas Market.

## Story cadence

The full rules are in [STORY_WRITING.md](STORY_WRITING.md). In short:

- **One scene after every level's first clear**, two or three lines, and one when each story building is placed. Replays are silent.
- **Speech only.** Every line is said by someone to someone, wanting something. No narration, no captions, no reports of what the screen shows. [Why](STORY_WRITING.md#speech-only-no-narration).
- **Each epoch is a chapter** with one question. Its four purchases set it up, move it on and pay it off; its boss level turns it.
- **Citizens add optional scenes** on arrival; the required story never depends on them.
- **The cast grows.** Each epoch introduces or deepens at least one character with a want of their own, besides the leads. A new speaker without a painted bust is shown with a name plate until one is painted (track it in an issue).
