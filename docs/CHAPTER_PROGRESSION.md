# Chapters of four landmarks

Status: **proposal**, from a design discussion on 2026-11-17. Nothing here is implemented yet. It covers Relic Rush and Christmas Market; Nile Archive keeps its June's Journey structure.

## The idea

The island advances one landmark at a time. Every four landmarks close a chapter, called an **epoch** in Relic Rush and an **Advent** in Christmas Market. The chapter is a story unit, not a new gate. Decorations come to the player as rewards and dress the island on their own, so there is no happiness or decoration score.

## What exists today

- **The build order is already strictly linear.** The engine's campaign ladder (`G.campaign_ladder` in [engine/match3_game.lua](../engine/match3_game.lua)) puts every building in purchase order. `next_step` returns a single building. `ladder_blocked` reports every other one as `earlier` (another comes first), `later` (waits for a clear) or `built`.
- **The shop shows the whole catalogue anyway.** It lists the ladder in purchase order and then everything else, with lock labels. Most rows say "not yet".
- **Levels are never replayed.** The player only plays the next level, so every level clear is also the next step of funding. Relic Rush's results screen still has a leftover "REPLAY TO EARN THE REST" heading ([lua/screens.lua](../games/relic-rush/lua/screens.lua)) that should say the next level brings the rest.
- **Both games have ten story buildings over thirty levels**, after clears 1, 4, 7, 9/10, 13, 16, 19, 23, 26 and 29 (`wonder_levels` in each game's `lua/campaign.lua`).
- **Relic Rush has three chapters** of 4, 3 and 3 restorations ([story](../games/relic-rush/docs/story.md#campaign-milestones)). The catalogue has about 20 wonders plus Star-gated buildings (`apothecary`, `mess_hall`, `stilt_house`, `greenhouse`, `treehouse`, `hanging_gardens`) and trees ([catalogue](../games/relic-rush/docs/building-catalogue.md)).
- **Christmas Market has three episodes** ([story](../games/christmas-market/docs/story.md)) and about 14 wonders, some of them 1 × 1 (`presents`, `giant_ornament`) ([catalogue](../games/christmas-market/docs/building-catalogue.md)).
- **Relic Rush already has a small happiness stat.** `island.decoration_bonus` ([lua/island.lua](../games/relic-rush/lua/island.lua)) adds +1 Coin per decoration to every level reward, up to +10. The results screen shows it as "Decorations +N Coins".

## Why not a happiness stat

June's Journey gates progress on decorating. It is a hack, but it works for two reasons: it soaks up coins, and players enjoy owning and dressing their island. We keep the second reason and drop the gate. Decorating is something players do because they want to, and progress never depends on it.

## Decisions

### One landmark at a time

The player sees only the next landmark. The four in a chapter still arrive one after another. Choosing freely among them is out, because every story is written around plants and payoffs in a fixed order. Building in any order would mean writing every beat for every sequence, which costs a lot of writing and gains little in this genre.

### A chapter is a story beat, not a mechanic

Because the ladder already sets the pace, chapters add no gate of their own. In data, a chapter is a number on each ladder step. Its value comes from what happens when the fourth landmark is placed:

- **Climax scene.** The chapter's question is answered: the lamp is lit, the keeper returns. The last build and the story pay off together.
- **The island changes.** New land opens, the weather or light changes (deeper snow, the market lights coming on, dusk), or a new character moves in. Progress is visible, not counted.
- **Decoration reward.** A themed box: a lantern set or snow sculptures in Christmas Market, jungle plants in Relic Rush. This is the main source of decorations.
- **A natural pause.** A "To be continued" card, a short recap and a silhouette of the next landmark. It is also a clean end for a free part or an update.

The chapter budgets beats around exactly four builds, which is simpler to plan in the story's working sheets than an open count. Follow [STORY_WRITING.md](STORY_WRITING.md).

### Decorations

1. **Landmarks bring their own dressing.** When a landmark is confirmed, a few matching small pieces appear in its clearance ring: lamp posts and snowy rocks by the bakery, palms and a banana plant by the well. A player who never decorates still gets a full island, and the art stays tied to its chapter.
2. **Rewards go into a box.** Level stars, story finds and chapter ends put decorations into a keepsake box. The player can place, move or put them away at any time. Nothing locks.
3. **Coins can buy extra decorations.** This is the optional coin sink that replaces the gate. Nothing in the campaign requires it.

`decoration_bonus` goes away, or becomes a one-off reward for the first decoration placed.

### UI

The [mockup](#mockup) shows these screens for Christmas Market.

1. **One build card** for the next landmark: its picture, name and the story line about why it matters now. It extends the "next restoration" slot on the results screen ([lua/screens.lua](../games/relic-rush/lua/screens.lua)). It has two states:
   - **Ready:** a Build button with the price. Pressing it starts placement with the shared mover. Confirming plants the landmark's own decorations.
   - **Funding:** a progress bar and "wish 9 brings the rest". There is no replay prompt, because the play button is always the way forward. The finite economy (`reserved_cost`) guarantees that the chapter's levels pay for its four landmarks. Coins left over go to decorations.
2. **A chapter strip** with four slots: built, current, and locked as a silhouette. In Christmas Market the slots are the four candles of the Advent wreath. The player always knows how close the chapter's climax is.
3. **Later chapters stay hidden.** At most, show the next chapter's first silhouette once the strip is full.
4. **The shop holds decorations only.** It covers the keepsake box and what Coins can buy, with no lock labels. In Christmas Market the hammer button becomes a gift button with a badge counting unplaced rewards.
5. **The chapter end is a card after the climax scene.** It shows the candle (or the epoch's emblem), the island change in one line, the decoration reward with Place now and Later, and the next chapter's locked silhouette.

### Mockup

Wireframes for Christmas Market at phone portrait. Icons stand in for the painted art.

![Christmas Market Advent UI wireframes](mockups/chapter-progression.svg)

- **1 · Town:** the HUD, the Advent strip (two built, the current one outlined, one locked, then the candle), the build card, and the gift, Play and story buttons.
- **1b · Funding:** the build card's second state, with a progress bar and the next wish.
- **2 · Place:** the existing Confirm and Cancel, plus dots for the dressing that will appear around the landmark.
- **3 · Advent end:** the second candle lights, Lantern set ×4 goes into the box, and the next Advent is teased.
- **4 · Decorations:** rewards in the box first, then anything Bells can buy. Nothing is locked.

## Per game

### Christmas Market: four Advents

- Four Advent Sundays with four landmarks each is 16 landmarks. Today there are 10 story buildings and about 14 wonders, so the ladder needs six more story steps and probably two new wonders.
- The story has three episodes and needs a fourth. Another option is to end at the third candle and keep the fourth for a Christmas Eve finale.
- Lighting a candle is the Advent's end moment, and the strip is the wreath.
- The joyful tone still applies: chapter climaxes are warm, never tragic.

### Relic Rush: epochs

- With about 20 wonders, four per epoch gives five epochs. With the current three chapters there are two options:
  - Make each chapter one epoch of four, 12 story landmarks in all. Chapter 1 already has four. Chapters 2 and 3 have three each and need one more.
  - Keep three chapters, each spanning about two epochs.
- The Star-gated buildings don't fit four per epoch. Make them epoch rewards or decorations.

## Implementation sketch

- **Engine:** add a `chapter` to each ladder step (`economy.unlocks`), and add helpers for the current chapter, its four steps and their states (`built`, `current`, `locked`). Fire a chapter-complete event after the fourth landmark is confirmed. Keep save compatibility: waived ladder positions stay waived.
- **Games:** a build card and a chapter strip in each skin (`ui.skin`, see [UI_ENGINE.md](UI_ENGINE.md#skins)), with the layout in the engine forms. The shop list filters to decorations. Dressing sets go in each catalogue row, and chapter-end scenes go in `story_content.lua`. Remove `decoration_bonus`.
- **Story:** update each game's `docs/story.md`: milestones per chapter, plant-and-payoff sheet, changelog. A separate reader gives it a cold read.
- **Art:** new wonders and dressing sets follow [BUILDING_ART.md](BUILDING_ART.md) and [BUILDINGS.md](BUILDINGS.md). The wreath and the strip states go in the asset catalogue.
- **Tests:** ladder chapter helpers in the engine suite, plus the build card, strip and chapter end in each game's named screens, at 480 × 900 and 390 × 844.

## Open questions

- Should Relic Rush's chapters map one to one onto epochs, or should each chapter span about two?
- Should Christmas Market add a fourth episode, or end on a Christmas Eve finale?
- Can the player move or remove auto-placed dressing, or does it stay fixed with its landmark?
- What else do Coins buy once decorations are optional?
