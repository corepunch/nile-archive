# Designing a match-3 campaign: flow, balance, upgrades and cast

How Relic Rush and Christmas Market are put together, on Cradle of Rome 2 as the backbone. Read it before changing a campaign's levels, purchases, prices or upgrades. Board layout is in [LEVEL_DESIGN.md](LEVEL_DESIGN.md).

## The backbone: Cradle of Rome 2

Cradle of Rome 2 (GameTop Windows edition, data in `reference/cradle-of-rome-2/resources`, summary in [the reference](cradle-of-rome-reference/README.md)) runs on three nested loops. We keep all three.

| Loop | Rome 2 | Our games |
| --- | --- | --- |
| **The board** | Clear every marble tablet before the time runs out. Matched coins, food and materials go to the wallet. | Clear every plaque or pane within a move budget. Matched pieces pay Coins/Tokens, Food/Treats and Supplies/Materials. |
| **The purchase** | Twenty buildings in five epochs of four. Players can choose any affordable project in the current epoch. Each adds a richer piece or one of eight tools. | Four projects per epoch or Advent. Relic Rush offers any affordable project in the active epoch. Christmas Market opens projects at their scheduled clears. |
| **The citizen** | Sixteen buildings each arm one optional feat. Meeting it brings a citizen, upgrades the building and adds income every level or makes its tool come more often. | The same sixteen feats upgrade the building through the character who runs it (see [Upgrades](#upgrades-romes-citizens-kept-by-the-cast-we-know)). |

Both games count moves. The campaign advances through board clears and construction, with short instructions on the board and project card.

## Game flow

The first launch starts on level 1. After collecting the opening reward, the
player visits the town with resources to spend. Later launches open the
[main menu](PORTRAIT_GAMES.md#first-launch-and-main-menu).

The player's minute-to-minute loop:

1. **Play a level.** The board shows the current pieces and, from its building on, one tool piece. Thirty matched tool pieces charge the tool's slot once.
2. **Collect.** The results card banks the matched resources. Ordinary wins lead to the next board. The results action returns to town when a project opens or is affordable.
3. **Build.** The bottom row shows the current phase's four projects, in order, and Play. Select any project to see its cost, board reward and requirements. A trail marks a project you can buy. Choose a site and confirm.
4. **See the change.** The next board shows the new piece or tool. Meeting a building's feat upgrades it, with a brief upgrade notice.

The campaign's shape:

| | Levels | Balance targets | Construction milestones | Last level |
| --- | --- | --- | --- | --- |
| Epoch I / First Advent | 1–20 | after 1, 6, 11, 16 | two | 20 |
| Epoch II / Second Advent | 21–40 | after 21, 26, 31, 36 | two | 40 |
| Epoch III / Third Advent | 41–60 | after 41, 46, 51, 56 | two | 60 |
| Epoch IV / Fourth Advent | 61–80 | after 61, 66, 71, 76 | two | 80 |
| Epoch V / Christmas | 81–100 | after 81, 86, 91, 96 | two | 100 |

- **Construction begins after level 1.** The five-level cadence (`after` in `economy.unlocks`) sets the price targets and reward milestones. Relic Rush makes all four projects in the current epoch available at once, with separate price checks.
- **Complete the phase to advance.** The town row advances after the last level and all four purchases in the phase are complete. Earlier purchases waived by a migrated save do not hold the row back. Players can keep clearing boards while raising funds. Confirming a purchase enables its reward on eligible boards.
- **Each campaign purchase adds exactly one board item.** The bakery brings gingerbread, the stable brings a farrier's hammer, and the candle shop brings a lantern. Resource pieces replace a line of the palette. Charging pieces use four permanent slots (Hammer → Bomb, Shield → Plus, Hourglass → Mixer, Lightning → Star). [All 20 pairs beside the Windows reference](cradle-of-rome-reference/building-rewards.html).
- **Boards follow a ten-level rhythm.** Tiers run `easy, easy, normal, normal, hard, easy, normal, normal, hard, boss` after four tutorials. A boss is dense and the board after it is a breather.
- **Regions open with the phase.** After 20, 40, 60 and 80 clears and the four projects in each phase, fog lifts as the next phase opens. Completing the final phase opens the last district. Older saves keep land they already opened.
- **The phase medals** appear after Continue on the main menu and when a phase opens a new district. Past phases have muted medals, the current phase has a full-color medal, and future phases carry a lock. Play resumes the current campaign.

## Balance

The [greedy bot](../engine/lua/match3/bot.lua) plays every board many times so the tools can fit the budgets and prices.

| What | Target | Tool |
| --- | --- | --- |
| Board validity | Fits 9 × 12; pieces can fall onto every target; at least 6 target layers and 45 cells | `python3 tools/square_boards.py <game>` |
| Plaque coverage | Every cell a piece can fall onto is a plaque, as on Rome's boards. A cell stays plain only where the bot reaches it last and the board would otherwise run long. Both campaigns average 95% covered from level 5 on, and 55 boards are covered completely | `python3 tools/square_trim.py <game> --levels 3-100 --fill` |
| Board length | Median clear at most 24 moves on easy boards, 28 on normal, 30 on hard and 32 on bosses, before the move allowance. Boards 3 to 11 climb to it two moves at a time (8 + 2 × level); boards 1 and 2 stay as authored | the same run; `--report` only measures |
| Move budget | Median clear × 1.25, rounded up, for every tier. Relic Rush multiplies that result by 1.5 and rounds up again. Trim late targets when a board runs long. | `python3 tools/tune_moves.py <game>` |
| Prices | Budget from the average of the mean and lower-quartile winning income. Each purchase uses 65% of the projected wallet in its currencies, with 50% for the first purchase. | `python3 tools/balance.py <game>` |

The move fit uses 40 starts per board with the pieces and tools earned by that level. The bot plays by swapping pieces and saves its tools. It prioritizes target layers and blocker damage, then weighs first-wave score, holes that can feed pieces onto remaining targets, and newly created gems. A line gem adds the value of two ordinary clears and a rainbow gem adds five. The bot tries both destinations for a line-gem cross and evaluates the visible first wave without random refills.

Line gems and rainbow gems are why the boards can be covered: a line gem sweeps a whole row or column of plaques, so a fully covered board takes the bot 20 to 34 moves where it took about 110 before the gems. When the rules change what a move clears, fill and trim again before fitting budgets and prices.

A 12-move median gets 23 moves in Relic Rush and 15 in Christmas Market. Slow runs remain visible in the within-budget count. The price fit uses 40 different starts per board and counts income from wins. [Relic Rush move budgets](../games/relic-rush/docs/level-moves.md) · [Christmas Market move budgets](../games/christmas-market/docs/level-moves.md)

**Rules for prices.**

- **Keep Rome's currency mix.** Each purchase uses the currency mix of its counterpart in the GameTop Windows `epochs.xml`. Only the price amounts are fitted.
- **Fit to the bot's income without optional upgrades.** Players who earn upgrades build sooner and have more resources for decorations.
- **Fund each purchase by its target clear.** The income forecast and the fixed-seed `campaign_play` test both require all twenty purchases by their scheduled levels with zero replays for income. Failed board attempts can be retried.
- **Keep total prices nondecreasing.** The fitter caps any early price spike at the next purchase's total while retaining every currency it uses.
- **Refit after any change** to boards, piece yields, unlock order or upgrade perks, and commit the regenerated catalogue.

**What one board pays.** Measured with the current boards (bot, mean per won board, Coins/Tokens · Food/Treats · Supplies/Materials):

| Levels | Relic Rush | Christmas Market |
| --- | --- | --- |
| 1–20 | 360 · 135 · 121 | 311 · 114 · 91 |
| 21–40 | 202 · 287 · 252 | 315 · 174 · 256 |
| 41–60 | 214 · 419 · 269 | 431 · 298 · 358 |
| 61–80 | 294 · 432 · 272 | 555 · 322 · 375 |
| 81–100 | 511 · 564 · 361 | 580 · 269 · 315 |

## Upgrades: Rome's citizens, kept by the cast we know

Rome 2's sixteen citizens (`settings/user_events.xml`, events `man_01` to `man_16`) are optional skill feats tied to buildings. When the building stands, its feat is armed. Meeting it once upgrades the building for good and gives one lasting perk: **income every level** in one currency, or **a tool that comes more often**. In Rome the citizen is an anonymous figure that appears at the building and never speaks.

We keep the feats, the upgrades and the perks, and give each upgrade to **the character who already runs that building**. Agnes gets a second oven; Oren sharpens his father's adze. No new person arrives: the player sees someone they know get better at what they do.

- **Optional upgrades.** An upgrade takes effect when the player completes its feat. The building card shows the feat and the earned perk.
- **Perks are scaled to our income.** The feat "earn X in one level" asks for about twice the mean board income in that currency in the ten levels after the building. Income per level is Rome's ratio of perk to threshold, capped at 20% of the threshold and rounded to fives. A tool upgrade makes its tool's piece charge one point more per match; two on one slot add up.
- **Rome feats we cannot measure get the nearest equivalent.** "Collect three lives" becomes three wins in a row without a failed level; feats in seconds keep Rome's time.
- **The perk is shown.** The building's card shows the feat while it is armed and the upgrade with its perk once met, as resource indicators; the income is part of every win's total.
- **Shared runtime.** Both games run Rome's If/Then events on `engine/lua/match3/user_events.lua`; each game supplies its data in `lua/user_events.lua` ([engine notes](MATCH3_ENGINE.md)).

| # | Rome 2 | Feat | Perk | Relic Rush upgrade (keeper) | Christmas Market upgrade (keeper) |
| --- | --- | --- | --- | --- | --- |
| 1 | Well (`man_03`) | 245 Food / 240 Treats in one level | +15 every win | Spring well: a second rope and pulley (Oren) | Welcome arch: a mulled-wine hatch in the arch (Noelle) |
| 2 | Hunter's hut (`man_04`) | A match of five | The single-cell tool charges faster | Trapper's cabin: his father's tools sharpened (Oren) | Reindeer stable: a new harness and bells for the reindeer (Pip) |
| 3 | Sawmill (`man_02`) | 520 Supplies / 395 Materials in one level | +105 / +75 every win | Carpenter's workshop: a second saw bench (Sela) | Lumber workshop: a drying shed for the pine (Theo) |
| 4 | Village (`man_01`) | 10 moves in a row that each clear a target | Bomb charges faster | Expedition camp: a dry tool store (Sela) | Firework stall: a rocket rack, ready in threes (Pip) |
| 5 | Farm (`man_05`) | 560 Food / 315 Treats in one level | +95 / +50 every win | Jungle market: the hill farms send their carts (Tavi) | Gingerbread bakery: a second oven (Agnes) |
| 6 | Mine (`man_06`) | 550 Supplies / 585 Materials in one level | +110 / +115 every win | Stone trading post: a cart road to the quarry (Sela) | Snowy chapel: the masons' yard behind the chapel (Mr Wren) |
| 7 | Mill (`man_07`) | 625 Food / 400 Treats in one level | +125 / +80 every win | Water mill: a second millstone (Oren) | Hot cocoa kiosk: Mrs Alder's ladle and second pot (Mrs Alder) |
| 8 | Thermae (`man_08`) | Five matches of five in one level | Shield charges faster | Tide clock tower: a warning chime (Tavi) | Ice house: a second ice saw on the lake (Theo) |
| 9 | Port (`man_09`) | 850 Food / 575 Treats in one level | +170 / +115 every win | Harbour plaza: a fish market every morning (Tavi) | Lakeside smokehouse: a second smoking rack (Mr Finch) |
| 10 | Coliseum (`man_10`) | 460 Coins / 985 Tokens in one level | +90 / +195 every win | Stone amphitheatre: market-day shows (Oren) | Toymaker's workshop: a second bench and a shop bell (Henrik) |
| 11 | House of the Vestals (`man_11`) | Two matches of five in a row | Lightning charges faster | Cartographer's house: storm charts on the wall (Tavi) | Candlelight shop: Mr Wren trims every wick (Mr Wren) |
| 12 | Lighthouse (`man_12`) | 15 matches within 20 seconds | Plus charges faster | Lighthouse: a bronze reflector (Tavi) | North Pole post office: a second sorting rack (Pip) |
| 13 | Nero's Golden House (`man_13`) | 690 Coins / 1070 Tokens in one level | +140 / +210 every win | Beached schooner: a ferry to the hill villages (Tavi) | Glassblower's stall: a second furnace (Ada) |
| 14 | Mausoleum (`man_14`) | Three wins in a row without a failed level | Mixer charges faster | Star observatory: the sighting stones aligned (Sela) | Reindeer carousel: a band organ (Pip) |
| 15 | Theatre (`man_15`) | 990 Coins / 1170 Tokens in one level | +200 / +235 every win | Relic museum: a reading room open to all (Sela) | Woodcarvers' hall: Henrik's old apprentices come back (Henrik) |
| 16 | Forum (`man_16`) | 15 moves in a row that each clear a target | Star charges faster | Temple of the Sun: the keepers' watch roster (Oren) | Christmas tree: a star for the top (Theo) |

Rome gives no feat to the Curia Octavia, Aqueduct, Pantheon and the city centre: the Harbour lodge, Keeper's archive, Great aviary and Jade fountain in Relic Rush, and the Station kiosk, Gift wrapping pavilion, Winter skating rink and Santa's sleigh in Christmas Market.

## Project copy

Describe what each building does in ordinary language. Show a separate name and icon for its board reward. In Christmas Market, the same portrait can appear on related projects. Dialogue scripts remain available for development previews.
