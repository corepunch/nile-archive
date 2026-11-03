# Design and story: three chapters to "Продолжение следует"

**Status: design and script for review, not implemented.** The game still plays the seven lines in `lua/archive_content.lua`. The owner has decided that Nile Archive is our clone of June's Journey and Relic Rush takes the Tropicats-style role separately. The goal here is a game playable through several chapters to a "to be continued" ending.

**How to read the labels.** Reference facts carry the labels from [the research report](../../../reports/Прогрессия%20June%20Journey%20и%20Tropicats.md): `official` (Wooga help centre, App Store), `wiki*` and `player*` (Fandom and AppGamer, seen only through search excerpts, so recheck before tuning against them), `player` (reviews, fan transcripts, third-party guides), `analysis` (Naavik), `estimate` (arithmetic). Nobody on the research side played the game. **Everything of ours is a proposal** unless it cites our code. The report's own proposal section is for Relic Rush and none of its numbers are used.

**Paths** are relative to `games/nile-archive`, except `engine/`, `tests/` and `docs/ECONOMY_RESEARCH.md`, which are from the repo root.

**Code wins over docs.** I checked the brief's inventory against the code and it holds: 3 scenes of 8 items (`lua/archive_content.lua:10-30`, `lua/archive_state.lua:9`), 3 hard-coded at `lua/archive_economy.lua:14-25`, 101 building types (5 + 96), no loss state, no lives, 7 story lines. The catalogue totals 15,555 coins.

## Summary of the proposal

| | Proposal |
| --- | --- |
| Chapters | **3**, then the end screen |
| Each chapter | 5 hidden-object scenes + 1 Тайник (our cheap Adventure Scene) |
| Scene slots | 15 scenes + 3 Тайники |
| Paintings | 9 in all: the existing 3 + **6 new**; 6 scene slots are existing paintings with a new item list |
| Hit data | 97 new ellipses (section 2.6) |
| New portraits | **None**. The script uses Нефра, Хорем and Мерит only |
| Dialogue | See the counts table in section 3 |
| Energy | **Owner's decision**. Recommendation: none for now (section 1.2) |

## 1. What to clone, adapt or skip

### 1.1 Mechanics

| Mechanic | Reference fact | Proposal | Why |
| --- | --- | --- | --- |
| Hidden-object list, no loss | List at the bottom of the screen (`official`); no time limit or loss (`analysis`) | **Clone**, already built | `lua/archive_scene.lua:124-160` matches |
| Free hint on a recharge | Free, recharges (`official`); every 30 s (`analysis`) | **Keep ours**, 20 s | `lua/archive_state.lua:18`. Shorter suits a scene we replay far less often |
| Combo and miss scoring | Faster finds score higher, wrong taps lose points (`official`) | **Keep ours** | Already built |
| Chapter of 5 scenes + 1 Adventure Scene | `official` | **Clone the shape** | It is the unit the whole story is written against |
| Two clues per scene | First on the first play, second on a play after the third Star (`official`) | **Clone** | It gives replays a story reward, and replays never repeat dialogue |
| Opening scene with one clue | Chapter 1 has 9 clues; its first level has a single clue (`wiki*`; `player` transcript) | **Clone** | First session reaches the library after one clear, as today. Our chapter 1 has 9 clues |
| 5 accumulating Stars | Up to 5, points accumulate across plays (`official`) | **Adapt**: keep 3 Stars, add a guaranteed floor | See 2.3. 3 Stars was a deliberate decision, and a skill-only third Star would be a soft loss state |
| Next scene gate | Both clues plus a Flower level, nothing spent (`official`) | **Clone** | Our gate today is one clue plus Influence, so only the clue rule changes |
| Adventure Scene gate | 20 of 25 chapter Stars (`official`); plus all chapter clues (`official`); wiki also says "all 20 clues", which does not fit 10 (`wiki*`, conflict) | **Adapt**: all clues, no Star count | Clue B needs 3 Stars in every scene, so 15 of 15 Stars is already implied |
| Adventure Scene form | Interactive puzzle, no time limit, one solution, key on a drawer (`official`) | **Adapt** as Тайник: an ordered chain of taps | A true puzzle engine is a new system. A chain reuses `sc.at` and `sc.radius` hit data |
| Flowers | Thresholds, never spent, come from decorating and building (`official`) | **Adapt**: Influence plays the role | Influence already grows only and is never spent (`lua/archive_state.lua:5-7`) |
| Decorating gates story | Coin decorations give Flowers at a linear rate, 30 coins each (`wiki*`, `player*`, confirmed by `estimate` on three samples) | **Clone the idea**, at our own rate | Today the 96 decorations affect nothing. This is the largest economy change |
| Pay per play | floor(score / 10,000) + 10 for Perfect, ceiling 76-80 (`wiki*`, `estimate`) | **Keep ours**, 80 flat plus bonuses | Our floor already equals their ceiling, and it is tested |
| Star Boxes, suitcases | Random rewards with published odds (`official`) | **Skip** | Random reward layer with no store behind it. `docs/ECONOMY_RESEARCH.md:63` rules out random chests |
| Materials, build timers, passive income, compasses | `official`, `wiki*` | **Skip** | Extra currencies and waits with nothing to sell. `docs/ECONOMY_RESEARCH.md:227` warns against exactly this |
| More items at higher Stars | 8, then 10, then 12 (`wiki*`) | **Skip** | Multiplies hit data, our main production cost, and `G.ITEMS` is fixed at 8 |
| Land gate | Total Stars plus Compasses (`player*`) | **Keep ours**, coins plus scenes | No Compass currency. Requirements are re-spaced in 2.5 |
| Story delivery | 3-10 labelled lines per clue, 49-70 per chapter (`player` transcripts) | **Clone** | Direct fit for `story.play` |
| Journal | Chapter summary and clue list (`official`) | **Adapt, small**: a list of the notes written here | Cheap, and it lets a skipped reader catch up. Replay of clue dialogue is unconfirmed in the reference |
| Landmark dialogue | A caretaker talks on landmark upgrades (`wiki*`, `analysis`) | **Adapt**: Мерит speaks once on each restoration | Keeps the island in the story without tying plot to layout |
| Home estate is the first location | `wiki*` | **Clone**, already true | Двор хранителя |
| Weekly chapters, content edge | One a week; players wait (`official` listing, `player*`) | **Skip**, end screen instead | No release schedule |
| Volume-end reward | A decoration for finishing a volume (`player`, one report) | **Adapt**, optional | See section 4 |
| Diamonds, IAP, ads, clubs, events, Travels, Memoirs, Vault | `official` | **Skip** | No store or backend (`docs/PROJECT.md:195`) |
| Murder-mystery plot, its cast and names | `wiki*`, `player` | **Skip entirely** | Owner's instruction. See section 3 |

### 1.2 Energy: the owner's decision

**Reference (`official`):** 15 energy per scene, 1 energy per 2 minutes, bar of 110 (150 after a purchase), 10 per scene with an ad discount. Refilling a bar costs 59 diamonds by `wiki*` only.

**What it would do here (`estimate`):** a full run is 29-57 plays (section 2.3), so 435-855 energy. Minus a starting bar of 110, that is 325-745 energy, or about 11-25 hours of regeneration.

| Option | What changes | For | Against |
| --- | --- | --- | --- |
| **A. None (recommended for now)** | Nothing | The run is finishable in one sitting, which is what proves the loop. No store exists, so a limit sells nothing | No session pacing, and the run ends in about two hours (`estimate`) |
| B. Full clone | 15 per scene, 1 per 2 min, bar 110 | Closest to the reference, stretches the run to days | Delay with nothing to buy. Needs a new purse slot, HUD and an empty-bar screen |
| C. Replays only | First clear free, replays cost energy | Story's first beat is never blocked | Clue B is behind replays, so the story still stalls |

**Recommendation:** A. Revisit it once a store is on the table. `lua/archive_scene.lua:81` (`M.open`) and `lua/archive_economy.lua:27` (`can_play`) are a single choke point, so adding it later is contained. B or C would reverse `docs/ECONOMY_RESEARCH.md:62-63` and `:227`, `docs/PROJECT.md:58` and `:81`, and `README.md:104`.

### 1.3 Standing repo decisions this would reverse

| Decision | Where | What the proposal does |
| --- | --- | --- |
| Copying the full commercial mechanic set is out of scope | `docs/REFERENCES.md:28` | **Reversed by the owner's decision.** Rewrite it. Keep the rest of that line: own world and plot, no Wooga assets. Monetisation stays out |
| Influence comes only from the five restorations; decorations grant nothing | `lua/archive_content.lua:53-54`, `README.md:102-103`, `docs/PROJECT.md:78`, `lua/archive_smoke.lua:158` | Decorations grant Influence |
| New chapters need no mandatory replays | `docs/PROJECT.md:80-81`, `README.md:103`, `tests/lua/archive_rewards.lua:29` | Clue B makes 1-3 replays of each scene mandatory |
| 3 performance Stars, from time alone | `docs/ECONOMY_RESEARCH.md:55-58` | Keeps 3 Stars, but adds the play-count floor |
| Restorations are repeatable | `docs/PROJECT.md:95-96` | Each once per save (2.4) |
| Мерит is outside the clue chain | `docs/PROJECT.md:26` | She becomes central |
| No antagonist | `docs/PROJECT.md:26` | Ликон exists, offstage |
| Father's biography undefined, fate open | `docs/PROJECT.md:24`, `:34` | Defined here. His fate stays open at the end screen, as intended |
| Three chapters | `README.md:50`, `:184`; "глава" means a scene everywhere in the UI | "Глава" now means five scenes. Every UI string changes |

## 2. Structure and starting numbers

### 2.1 Chapter count: recommend 3

| Option | Scenes | New paintings | Lines | Verdict |
| --- | --- | --- | --- | --- |
| 1 chapter | 5 + 1 | 0 | about 60 | Cheapest and shippable, but not "several" |
| **3 chapters** | **15 + 3** | **6** | **about 200** | **Recommended.** Meets the goal, one shore per chapter, plot closes on a reversal |
| 5 chapters | 25 + 5 | 10-12 | about 320 | Possible later. Better spent as "Том II" after the loop is proven |

Three also suits the island: it has 3 shores to open (`lua/archive_state.lua:10`). Chapter 1 ships with **no new painting**, so it can be built and played first while art is made.

### 2.2 Scene slots

Existing scenes keep slots 1-3 and their order. Slots are append-only, like the building catalogue, so `wins` and `stars` indices in old saves stay valid and need no remapping.

| Slot | Ch. | Scene | Painting | Item list | Gate |
| ---: | ---: | --- | --- | --- | ---: |
| 1 | 1 | Двор хранителя | `scene0.png` | existing | 0 |
| 2 | 1 | Библиотека писца | `scene1.png` | existing | 20 |
| 3 | 1 | Храм на закате | `scene2.png` | existing | 50 |
| 4 | 1 | Двор, второй круг | `scene0.png` | **new** | 75 |
| 5 | 1 | Библиотека, второй круг | `scene1.png` | **new** | 90 |
| T1 | 1 | Тайник: Дверь под крылатым солнцем | `scene2.png` | existing targets | clues |
| 6 | 2 | Хранилище под храмом | **new** A | new | 130 |
| 7 | 2 | Ниломер | **new** B | new | 140 |
| 8 | 2 | Хранилище, второй круг | A | new | 165 |
| 9 | 2 | Перерезанная дамба | **new** C | new | 195 |
| 10 | 2 | Ниломер, второй круг | B | new | 220 |
| T2 | 2 | Тайник: След киля | C | C's targets + 1 | clues |
| 11 | 3 | Затопленные амбары | **new** D | new | 255 |
| 12 | 3 | Дом надзирателя | **new** E | new | 265 |
| 13 | 3 | Амбары, второй круг | D | new | 295 |
| 14 | 3 | Дом надзирателя, второй круг | E | new | 320 |
| 15 | 3 | Мастерская печатей | **new** F | new | 350 |
| T3 | 3 | Тайник: Последняя вещь | F | F's targets | clues |

### 2.3 Clue and Star rules

- **Clue A** plays on a scene's first clear. Slot 1 has clue A only (reference: `wiki*`). This keeps the first session as it is today.
- **Clue B** plays on a clear made after the scene's third Star has been earned (`official`), so a Star earned this play does not count.
- **Next scene needs** clue B of the previous scene (A for slot 1) plus the Influence gate. **Next chapter needs** the Тайник too.
- **Stars stay at 3.** Today they come only from time: 75 s and 150 s (`lua/archive_state.lua:20`). Clue B behind a time alone would be a hard block for a slower player in a game with no loss state. **Floor:** effective Stars are `max(time rating, min(3, completions))`, so the third completion always reaches the third Star. This is the small version of the reference's accumulation (`official`).

| Player | Plays | Coins from the scene, from `lua/archive_economy.lua:33-40` |
| --- | ---: | --- |
| Fast and clean | 2 | (80+40+60+20) + (80+20) = **300** |
| Fast, not clean: the minimum | 2 | (80+40+60) + 80 = **260** |
| Slow, one Star at a time | 4 | (80+40+20) + (80+20) + (80+20) + 80 = **420** |

**Run length (`estimate`):** slot 1 is 1 play, and 14 slots at 2-4 plays give **29-57 plays in all**, or 9-20 per chapter. The reference needs 60-85 per chapter (`estimate`, from a 2024 guide). That is deliberate: we have no weekly chapter to wait for, and hit data is too costly to grind against. At 1-2.5 minutes a play, plus about 10 minutes of reading (about 2,000 words at an assumed 200-250 a minute), that is about **40-155 minutes**. Human session length has not been measured.

**Тайник pays 150 coins** once. That is the rounded minimum first clear (140), since the reference's Adventure pay is unknown (gap in the research). It has no Stars, no replay, no timer, no miss penalty and hints as usual. The bar shows one name at a time, in order.

### 2.4 Influence as Flowers

**The mapping.** Reference: Flowers come from decorating (`official`), level gates scenes (`official`), never spent (`official`). Ours: Influence, already unspent. In the fiction it is how far people trust the keeper's house again: people come back as the island does.

**Rate.** Restorations cost 450 coins for 80 Influence on top of the house's 10 (`lua/archive_economy.lua:5-11`), or 5.6 coins each. Decorations should be worse than story buildings, so the proposal is **`floor(coins / 10)` Influence per decoration**.

| Rate | Coins for the last gate through decorations (260 Influence) | Share of 3,820 coins available by then |
| ---: | ---: | ---: |
| **10 (proposal)** | 2,600 | 68%, 80% with restorations |
| 30 (reference, `wiki*`/`player*`) | 7,800 | 204%, so about 50 extra replays |

The reference's rate works because it has other Flower sources (`official`) and a far longer run. All 96 decorations at rate 10 give 1,547 Influence, far beyond the last gate, so most of the catalogue stays optional and buying is never exhausted.

**Restorations once per save.** Today they repeat, so at 6 coins per Influence, repeat fountains would beat every decoration. The starting house is restoration type 0, so **four remain to buy**: fountain, workshop, archive, temple. Together with the house's 10 they make **90 Influence for 450 coins**.

**Player level is not the gate.** The official example gates by Flower level, about one per scene. `lua/archive_progress.lua:76-80` is quadratic: slot 15 would need level 15, or 1,960 Influence, about 19,000 coins. It stays a display and gates stay plain numbers, as `lua/archive_dialogs.lua:104` already shows them.

**Decoration Star unlocks scale by 5.** Today's thresholds are 0-9. With 3 Stars per scene, every decoration would unlock by slot 3. Multiplying by 5 at `lua/archive_content.lua:63-64` (the catalogue itself is generated, do not edit) spreads them over the 45 Stars available.

### 2.5 Gates, checked against minimum income

Minimum coins before a slot is `140 + 260 × (slot − 2) + 150 × Тайники done`. Cost is the cheapest purchase set: restorations first, then 10 coins per Influence.

| Slot | Gate | Step | Min. coins earned | Coins needed | Share | Left over |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 20 | +10 | 140 | 60 | 43% | 80 |
| 3 | 50 | +30 | 400 | 220 | 55% | 180 |
| 4 | 75 | +25 | 660 | 350 | 53% | 310 |
| 5 | 90 | +15 | 920 | 450 | 49% | 470 |
| 6 | 130 | +40 | 1,330 | 850 | 64% | 480 |
| 7 | 140 | +10 | 1,590 | 950 | 60% | 640 |
| 8 | 165 | +25 | 1,850 | 1,200 | 65% | 650 |
| 9 | 195 | +30 | 2,110 | 1,500 | 71% | 610 |
| 10 | 220 | +25 | 2,370 | 1,750 | 74% | 620 |
| 11 | 255 | +35 | 2,780 | 2,100 | 76% | 680 |
| 12 | 265 | +10 | 3,040 | 2,200 | 72% | 840 |
| 13 | 295 | +30 | 3,300 | 2,500 | 76% | 800 |
| 14 | 320 | +25 | 3,560 | 2,750 | 77% | 810 |
| 15 | 350 | +30 | 3,820 | 3,050 | 80% | 770 |

- **Slots 2 and 3 keep today's gates** of 20 and 50 (`lua/archive_economy.lua:4`), so existing saves are not re-locked.
- **Shape from the reference (`player*`):** the 2nd scene of a chapter is cheapest and a chapter's opener costs about what its 5th does. So slots 7 and 12 are +10 and openers are +35-40. Absolute values are not comparable: 1,300-1,970 Flowers per chapter there, 80-130 Influence here.
- **Early-chapter generosity (`player*`, 170 against 1,420):** slot 5's gate needs only the restorations, so chapter 1 asks for no decoration at all.
- **Nothing can strand the player.** Every leftover covers the optional shores (540 in all) by slot 15, and a replay always pays at least 80. Total minimum income for the run is **4,230 coins**, and the catalogue costs 15,555. At least 76% of it stays unbought at the end (3,780 coins at most go to decorations), which is the post-game.
- **Shores keep their prices** of 120/180/240 (`lua/archive_economy.lua:12`). Requirements move from 1/2/3 completed scenes to **3/6/11**, one per chapter (`lua/archive_island.lua:38`). All three would otherwise open in the first ten minutes.
- All of this is starting data. It has not been simulated in the game or played.

### 2.6 The production cost: paintings and hit data

A scene needs a 1200×800 painting with its targets painted in, plus a measured ellipse per target (`docs/REFERENCES.md:12`). There is no generator.

**Can scenes be reused with new item lists? Yes.** I looked at all three paintings and they are dense. `G.ITEMS` is per-scene data, so a re-list needs no code beyond the slot table.

| Painting | Unused objects I can identify by eye (approximate; to be measured) |
| --- | --- |
| `scene0.png` | Watering can, pitchfork, gold ewer, basket, figs, fountain, grapes, sailboat, cat statue, chest |
| `scene1.png` | Scales, lamp, bust, ibis, beaded casket, beads, reed pens, large amphora, wall scroll |
| `scene2.png` | Lyre, incense burner, lion statue, gazelle, teapot, grapes. Not needed in this plan |

Each re-list only works if the story has a reason to return, so each is written as a second look at a place. It also costs replay freshness, since the room is already familiar.

| Plan | New paintings | Re-lists | New ellipses | Reading |
| --- | ---: | ---: | ---: | --- |
| Reuse hard | 3 | 9 | 96 | Ch. 3 would have to go back to ch. 1 rooms. Weak |
| **Recommended** | **6** | **6** | **48 + 48 + 1 = 97** | Each chapter has 3 places, two of them visited twice (2.2) |
| No reuse | 12 | 0 | 96 | 15 unique places. Twice the painting cost for a modest gain |

**Effort (`estimate`, low confidence; the repo has no timing data):** 2-4 hours per painting including a generation pass and a review, about 1 hour for 8 ellipses and a smoke check. The recommended plan is about 25-35 hours of art work, against 35-60 for no reuse. Measure the first painting and correct this.

Item lists are in section 3 at each scene. The list for a new painting is its art brief, as `docs/REFERENCES.md:12` asks: "сразу задать набор целей".

## 3. The story

**Writing rules.** Plot, characters and names are original. Nothing comes from June's Journey, and this is not a murder mystery: nobody is killed, and the central question is what a good man chose to do. Nothing comes from Relic Rush's script either.

| Beat group | Clue beats | Тайник beats | Lines |
| --- | ---: | ---: | ---: |
| Chapter 1 (with the prologue) | 9 | 2 | 70 |
| Chapter 2 | 10 | 2 | 68 |
| Chapter 3 | 10 | 2 | 68 |
| **Total** | **29** | **6** | **206** |

Reference: 49-70 labelled lines per chapter (`player`), 3-10 per clue (`player`). The prologue is counted in chapter 1. Side lines (shores and so on) are counted separately in "Small lines".

### Play fantasy

I am bringing my family's island back to life, one room and one roof at a time, by playing the game my father taught me, and each thing I find tells me he was not the man I thought.

### What is broken in this world

Everything below the courtyard is silt. The library's shelves hold only household accounts. The fountain and its channel are dry, and the people have gone. The river's official numbers are false. A daughter's picture of her father is the last thing to break.

### The question

**How did Хорем know to hide the books before a flood nobody expected?** The very first clue says "Отец успел спрятать архив до наводнения", and Мерит asks the obvious question in the same scene. Chapter 1 answers where, chapter 2 gives a wrong but satisfying how, and chapter 3 gives the real one: he chose the hour himself. Then it asks a bigger question: where is he now, and what will he have to cut next?

### What really happened

The player learns this in pieces. Writers need it whole.

1. **Two centuries.** Нефра's family keeps the island's archive and its nilometer. The great book, **Книга разливов**, holds the river's height for every year. Since the size of the flood sets the harvest and the tax, those numbers are power. Хорем brought up his daughter on **Игра восьми**: he hid eight things around the house, the last always leading to the next room, and a swapped thing was always a hint.
2. **Twenty years of theft.** **Ликон**, the royal grain overseer, cuts false marks into the nilometer two cubits low. He reports poor floods to the crown, collects as for good ones from the farmers, and keeps the difference in unrecorded barns on the low northern branch. Only the Book can prove it. He comes to dinner, smiles, and asks for it "for the royal census". Хорем refuses and writes the smile down.
3. **The sum.** Хорем's tables say the coming flood will top every mark. If the dyke on the northern branch holds, the water takes seven villages on the right bank. If it is cut, the water goes down the northern branch instead, across the lower island and Ликон's barns. He warns the grain office. Ликон's office answers: "Разлив ожидается слабый".
4. **The week before.** Хорем moves 239 chests to a vault under the old temple, works it with a water-balance door tied to the fountain, leaves household accounts on the library shelves as a decoy, and sets the Игра восьми through the estate for the one person who could read it.
5. **The night.** He sends the whole island and the people of the northern branch to a feast across the river, in the seven villages he is saving. In a hood, silent, he hires Мерит's boat for the night, with six men from the seven villages. They say they were told to dig or drown. He pays her with his family's gold **seal-token**, deliberately: to him that is a signature, the mark he uses only for what he answers for. She thinks they are mending the dyke, and sees only dark hands. Later he writes the night down on a nilometer tablet, truthfully, without saying who ordered it or where he stood. Nobody drowns. By morning Мерит's house, on the same branch, is silt.
6. **The months since.** He goes upriver with no word. Ликон, ruined, catches one of the six, hears about the token, works it out and goes hunting. Хорем comes back in secret by a crawlway from the nilometer, takes the Book, feeds the cat, ties a new knot in her collar, watches the fountain start again and leaves. His sums go further than he can check: **the next flood will be higher still**.
7. **Now, nine months on.** Нефра was copying a royal decree in Мемфис when the water came, and has waited there for a letter. She comes home and Мерит, whose map's top fold shows the branch where her house stood, who carries a coin in her ear and a guilt she will not name, rows her over.

### Cast arcs

| Character | Starts as | Ends as | Voice |
| --- | --- | --- | --- |
| **Нефра** | A daughter sure of her father, playing his game | A scribe who has counted what he did and is going to ask him to his face | Warm and exact. Counts things when upset. "Запишем" |
| **Мерит** | A teasing boatwoman who calls Нефра "писарша" | The other person he used, and now a partner | River sayings, jokes first. Short lines when she is hiding something |
| **Хорем** | A beloved missing father leaving games | A man who drowned his own home on purpose, and is not sorry | Notes only, in thought bubbles. Short, dated, kind, and never a false statement |
| **Миу** (no lines) | The archive's black cat | The last clue | She is in all three existing paintings, in a jewelled collar. Her being fed is a question from scene 1 |
| **Ликон** (offstage) | A signature on false reports | A ruined thief also heading upriver | Letters read out by Нефра. No portrait needed |

### Things to plant and pay off

| Planted | Paid off |
| --- | --- |
| "Успел? Вода пришла за один час" (`c1s1a`) | He set the hour (`c3t2`) |
| Миу is fed, by whom? (`c1s1a`) | He fed her (`c3t2`) |
| Everyone was sent to a feast (`c1s3b`) | Proof of planning (`c2s5a`, `c3s2b`) |
| The list says "Гранат", the plate holds an apple, twice (art of slots 1-2) | Slot 3's list says "Яблоко" (`c1s3b`) |
| Мерит's gold earring, "плата" (`c1s2b`) | It is the seal-token (`c2t2`, `c3s5a`) |
| "Мой узел, кроме меня, никто не развяжет" (`c1s3a`) | The knot on the dyke stake (`c2s4b`, `c2s5b`) |
| Her map's top fold stays closed (`c1s2b`) | She opens it, last line of the game (`c3t2`) |
| "Тростник и вода" (`c1s1a`) | The token in Ликон's interrogation (`c3s4a`), then the earring in clay (`c3s5a`) |
| Семь Селений as a feast (`c1s3b`) | The water would have gone there (`c3s3a`) |
| Dark hands, "будто в смоле" (`c2t2`) | Ink (`c3s5b`) |
| The nilometer tablet (`c2s5a`) | Every word true, but he was in the boat (`c3s5b`) |
| Wet clay in a sealed vault (`c1t2`) | The crawlway (`c2s1b`), then him (`c3t2`) |
| Full shelves in an "empty" library (`c1s2a`) | Thieves were meant to see them (`c2s3a`) |
| "Злись и считай" (`c1s5b`) | Нефра cannot yet (`c3s2b`), then does (`c3s3a`) |

### Clue chain

| Clue | Leads to |
| --- | --- |
| Eight familiar things, "Карта" in the list | It's the childhood game, and a boat is needed |
| "Яблоко" in the list | Gardener's apple tree, the jar, the dry channel |
| Scales marked in cubits + channel | The slab is a water balance |
| Empty slot in the inventory + wet clay | Someone came after the flood, by another way |
| Two scales on the nilometer + Мемфис reports | Ликон's fraud, and what the Book proves |
| Clean cut edges + spade marks | The dyke was cut (wrong theory: by Ликон) |
| Knot on the stake + keel track | Мерит's boat |
| Ликон's own barns on that branch | It wasn't Ликон |
| Feast in the villages + where the water would go | Who gained, and how it was planned |
| "Тростник и вода" + interrogation + empty hiding place + earring in clay | Хорем |
| Tablet + dark hands | He was in the boat |
| Fresh knot on the collar + note in the bead | He is alive, and where |

### Knowledge ledger

| After | Player and Нефра know | Мерит also knows | Still believed, wrongly |
| --- | --- | --- | --- |
| Chapter 1 | Books are safe, one is gone, someone came back | She carried men with spades, and the token | Хорем is a victim who planned well |
| Chapter 2 | The fraud, the cut dyke, Мерит's night | Nothing more | Ликон ordered it |
| Slot 12 | Ликон accuses Хорем | Nothing more | Нефра: "Ликон лжёт" |
| Slot 13 | The villages were the choice | Her kin were saved | Нефра still refuses the sum |
| Chapter 3 | All of it, and the next flood | The same | Nothing: the open questions are where he is and what he will do |

### Crossing the story with the systems

| Case | Handling |
| --- | --- |
| Replays | Beats are keyed and play once. Clue B fires only once, on its qualifying clear |
| Queued beats | A placement can fire a restoration line and a milestone line together. Queue restoration first and milestones on the next return to the island. `c3t2` must clear before `MODAL_END` |
| Skip | Each beat's Запись restates its fact in the win dialog and Journal, so a skipped line costs nothing |
| Old saves | See Saves in section 5 |
| Waiting | No real-time deadline. "В прошлом месяце" is story time |
| Placement order | Restoration lines never say where the building stands. `c1s5a` and `c3s5a` assume people have returned, which the gates guarantee |
| Fountain before `c1s5b` | "Фонтан бьёт" assumes it is built, but a decoration route can reach 90 Influence without one. **Require the fountain for the Тайник** |
| Workshop before slot 15 | Slot 15 assumes it, and a decoration route can skip it. **Require it for slot 15** |
| Unavailable characters | Хорем only ever appears as notes. Ликон only in documents |

### Conflicts with existing text and art

Existing lines are kept word for word, in their existing order and scene. These are the points to review.

| Existing | Issue | Handling |
| --- | --- | --- |
| "Последняя записка отца раскрыта." (`lua/archive_content.lua:24`) | Not the last note any more | Kept. She believes it. Slot 4 finds another |
| Teaser "Соберите последнюю цепочку улик. Нужно 50 влияния." (`:23`) | Says "last"; also hard-codes the gate | Replaced below |
| Teasers hard-code gates (`:17`, `:23`) | Would drift | Moved to computed UI text |
| "библиотека опустела" (`:78`), but `scene1.png` has full shelves | Art contradicts text | **Made into plot:** the scrolls are decoys |
| Flood damage, but `scene0.png` is a lush undamaged courtyard | Art contradicts premise | New line in the prologue: the courtyard is high, the lower terraces took the water |
| "Гранат" in slots 1-2 is **painted as a red apple** with a stem; I cropped all three fruit to check | Looks like a label bug | **Made into a clue** in `c1s3b`. If you would rather fix the label, that clue needs a rewrite |
| "АРХИВ СОБРАН" (`lua/archive_island.lua:88`) | Ends the game early | Replaced by slot goals and the end screen |
| Мерит's shore line says "Открыт новый берег" every time (`:82`) | Repeats | Kept for shore 1, two new ones below |
| `README.md:44` "последняя записка обещает открыть путь" | Consistent | No change; "Восстанови остров" becomes literal |
| "На обороте печати проступил план", "Последняя записка отца раскрыта" (`:18`, `:24`) | The cold reader found both stilted: a seal has no back for a map | Kept word for word as instructed. Reword if you are willing to change shipped text |

### Staging rules

Lines are speech unless marked `(thought)` or `(shout)`, which map to `story.THOUGHT` and `story.SHOUT`. **Хорем is always a thought bubble**, as today: he is a note being read. **Хорем and Мерит never speak back to back.** Both stand on the right, and `engine/story.c:581` only shows a listener on the opposite side, so Нефра would leave the stage. The validation script enforces this.

**Order after a clear:** clue dialogue, then reward dialog (already so: `lua/archive_scene.lua:147-149`, `lua/main.lua:52`). Each beat plays once per save. Replays that earn nothing show nothing.

**"Запись"** is a one-line note under each beat: it fills the win dialog's note box (`lua/archive_dialogs.lua:36`, `:60`) and the Journal. It is not a spoken line and isn't counted.

## Chapter 1: Игра восьми

**Beat `intro` · first launch** · *Lines 1-2 are existing.*

- **Нефра:** Отец исчез после наводнения, а библиотека опустела.
- **Нефра:** Но он успел спрятать книги и оставил подсказки. Я восстановлю наше поместье — и найду архив.
- **Мерит:** Причалили, писарша. Двор вода не тронула. Всё, что ниже, теперь ил: дома, мастерская, фонтан.
- **Нефра:** Девять месяцев я ждала в Мемфисе письма. А столы так и накрыты.
- **Мерит:** Вот и сходи посмотри. А я постерегу лодку. Лодка у меня одна, как у тебя отец.

### Slot 1 · Двор хранителя

*Teaser: «На столах двора остались вещи отца. Начните с них.» (existing). Items: existing.*

**Beat `c1s1a` · first clear, the only clue here** · *Запись: Печать семейной мастерской. Отец спрятал архив заранее и начал нашу старую игру.*

- **Нефра:** На свитке — печать семейной мастерской. Отец успел спрятать архив до наводнения.
- **Мерит:** Успел? Вода пришла ночью, за один час. Никто на реке её не ждал. Что за печать?
- **Нефра:** Тростник и вода. Такую режут только у нас.
- **Нефра:** Анх, веер, ключ, перо, кошка... Мерит, это игра. Наша игра.
- **Нефра:** В детстве он прятал по дому восемь вещей. Последняя всегда вела в следующую комнату.
- **Мерит:** Кошка тоже вещь? Она на меня смотрит.
- **Нефра:** Это Миу, кошка архива. Сытая, блестит. А кто кормит её с самого наводнения?
- **Мерит:** Не я. На острове с той ночи никто не живёт.

### Slot 2 · Библиотека писца

*Teaser: «В библиотеке спрятан второй след.» (existing, gate removed). Items: existing.*

**Beat `c1s2a` · first clear** · *Запись: План острова указывает на старый храм. Свитки на полках — приманка.*

- **Нефра:** На обороте печати проступил план острова. След ведёт к старому храму у восточного берега.
- **Мерит:** Зачем нам храм? Полки же ломятся. Вот твоя пропажа, бери да читай.
- **Нефра:** Разверни любой свиток. Счета за масло, за зерно, за верёвку. Настоящих книг здесь нет.
- **Мерит:** Кто же прячет библиотеку за библиотекой?
- **Нефра:** Тот, кто ждал гостей. Вор увидит полные полки и не станет искать дальше.

**Beat `c1s2b` · clear after the third Star** · *Запись: В списке вместо свитка — карта. Дальше нужна лодка Мерит.*

- **Нефра:** Видишь? В списке вместо свитка стоит карта. В игре замена — это всегда подсказка.
- **Нефра:** Карта значит: пешком не дойдёшь. Покажи свою.
- **Мерит:** Низ смотри сколько хочешь. Верх не для тебя, писарша.
- **Нефра:** А серьга у тебя откуда? Золото, и работа тонкая. Странная вещь для лодочницы.
- **Мерит:** Плата. Раз в жизни мне заплатили золотом. Больше не спрашивай.

### Slot 3 · Храм на закате

*Teaser, replacing «Соберите последнюю цепочку улик. Нужно 50 влияния.»: «План привёл к старому храму. Посмотрим, что отец оставил на террасе.» Items: existing.*

**Beat `c1s3a` · first clear** · *Запись: Записка отца: книги под храмом. Плита под крылатым солнцем не поднимается.*

- **Мерит:** Держи конец. Мой узел, кроме меня, никто не развяжет. Мать так вязала.
- **Нефра:** Последняя записка отца раскрыта.
- **Хорем (thought):** Книги спрятаны под храмом. Восстанови остров — и библиотека снова откроется.
- **Нефра:** Крылатое солнце на этом ларе стоит криво. Под ним плита, и она не поднимается.
- **Нефра:** Он пишет: «восстанови остров». Я думала, это красивые слова.

**Beat `c1s3b` · clear after the third Star** · *Запись: В списке яблоко. Яблони растут только у дома садовника. В ночь воды остров был пуст.*

- **Нефра:** Дважды он писал в списке «гранат», а клал яблоко. Я решила, что он стареет.
- **Нефра:** А здесь написал честно: яблоко. В игре это значит: смотри сюда.
- **Мерит:** Яблоко и яблоко. Съешь, и поехали.
- **Нефра:** Яблони на острове только у дома садовника. Садовник что-нибудь видел в ту ночь?
- **Мерит:** Никто ничего не видел. Хранитель ещё днём отпустил всех на праздник за реку, в Семь Селений.
- **Нефра:** Всех? В ту самую ночь?
- **Мерит:** Повезло людям.
- **Нефра (thought):** Отец не верил в везение. Он верил в записи.

### Slot 4 · Двор, второй круг

*Teaser: «Яблоко указало на сад. Посмотрите на двор глазами садовника.» Items (new, `scene0.png`): Лейка, Вилы, Кувшин, Корзина, Инжир, Фонтан, Виноград, Ладья.*

**Beat `c1s4a` · first clear** · *Запись: Под фонтаном сухой канал. Он идёт к храму.*

- **Нефра:** Лейка, вилы, корзина. Садовые вещи собраны у воды, а не у сарая.
- **Мерит:** Смотри, под фонтаном канал. Старый, сухой и идёт прямо на восток.
- **Нефра:** К храму. Значит, плиту держит не камень. Плите нужна вода.
- **Мерит:** Твой отец сделал замок размером с остров? Кто так живёт?
- **Нефра:** Человек, у которого двести лет записей и один ключ.

**Beat `c1s4b` · clear after the third Star** · *Запись: Новая записка в корнях яблони: сначала дом, потом люди, потом река.*

- **Мерит:** Вот он. В корнях яблони кувшин, запечатан. Твоей печатью, писарша.
- **Нефра:** Дай сюда. Внутри его рука.
- **Хорем (thought):** Вода поднимет то, что не поднимут руки. Сначала верни дом, потом людей, потом реку.
- **Нефра:** Выходит, та записка не последняя. И он пишет так, будто знал, что люди уйдут.
- **Мерит:** Люди вернутся, когда будет куда. Сама их перевезу, если найдётся за что.
- **Нефра:** Тогда строим. Фонтан, мастерская, архив, храм. Запишем.

### Slot 5 · Библиотека, второй круг

*Teaser: «Весы отца что-то взвешивали. Вернитесь в библиотеку.» Items (new, `scene1.png`): Весы, Светильник, Бюст, Ибис, Ларец, Бусы, Каламы, Амфора.*

**Beat `c1s5a` · first clear** · *Запись: Плита на террасе работает как весы: камень против воды.*

- **Мерит:** Люди и правда едут. Сегодня пекарь спросил, правда ли, что у хранителя снова горит свет.
- **Нефра:** Посмотри на весы. На чашах не гири, а отметки локтей. Как на ниломере.
- **Нефра:** Плита на террасе и есть весы. С одной стороны камень, с другой вода.
- **Мерит:** И сколько ей надо? Реку сюда на верёвке не приведёшь.
- **Нефра:** Сколько поднимается в хороший год. Он всё на свете мерил разливом.

**Beat `c1s5b` · clear after the third Star** · *Запись: Порядок открытия: ключ, скарабей, анх, перо.*

- **Хорем (thought):** Порядок ты знаешь: ключ, скарабей, анх, перо. Как в тот год, когда тебе было шесть.
- **Нефра:** Он пишет мне. Не писцу, не наследнику. Мне.
- **Хорем (thought):** Если ты читаешь это, то злишься. Правильно. Злись и считай.
- **Хорем (thought):** Чужой обыщет всё, но в нашу игру играть не умеет. Поэтому игра.
- **Нефра:** Злюсь. Считаю. Мерит, фонтан бьёт, канал полон.
- **Мерит:** Нравится мне твой отец. Жаль, не достать его веслом.

### Тайник 1 · Дверь под крылатым солнцем

*Chain on `scene2.png`, existing targets (`lua/archive_content.lua:27-29`): Ключ, Скарабей, Анх, Перо.*

**Beat `c1t1` · on entering**

- **Нефра:** Ключ, скарабей, анх, перо. Вода уже шумит под плитой.
- **Мерит:** Если нас утопит, я выплыву первой. Предупреждаю честно.

**Beat `c1t2` · chain solved · hook** · *Запись: Архив цел, 239 сундуков из 240. Нет Книги разливов. На ступенях свежая глина.*

- **Нефра:** Пошла! Плита пошла. Ступени сухие. Отец, ты и это рассчитал.
- **Мерит:** Сундуки. Сколько же их тут... Целы?
- **Нефра:** Целы, и печати целы. Вся библиотека острова стоит под землёй, сухая.
- **Мерит:** Вот и всё, писарша. Нашла. Плясать будем?
- **Нефра:** Подожди. В описи двести сорок сундуков. Я насчитала двести тридцать девять.
- **Нефра:** Нет Книги разливов. Главной книги нашего дома.
- **Мерит:** Отец твой и унёс, когда прятал. Делов-то.
- **Нефра:** Мерит, посмотри на ступени. Тут глина, и она ещё сырая.
- **Мерит:** Плиту только что подняли мы. Больше сюда никому не попасть.
- **Нефра:** Значит, попали иначе. Кто-то был здесь совсем недавно. И взял только одну книгу.

## Chapter 2: Книга разливов

### Slot 6 · Хранилище под храмом

*New painting A, a dry vault of sealed chests under lamplight, with Миу. Teaser: «Архив найден, но одной книги нет. Пересчитайте всё.» Items: Опись, Кошка, Светильник, Печать, Мешочек, Ключ, Амфора, Тростинка.*

**Beat `c2s1a` · first clear** · *Запись: Книга разливов — высота воды за двести лет. Она решает налог.*

- **Нефра:** Считаю в третий раз. Двести тридцать девять. Книги разливов нет.
- **Мерит:** Да кому она нужна? Цифры про воду. Вода и так приходит каждый год.
- **Нефра:** Разлив решает всё. Вода высокая — поле родит, и царь берёт больше.
- **Нефра:** Двести лет наш дом записывал высоту реки. Каждый локоть, каждый год.
- **Мерит:** Значит, там записано, кто сколько должен был отдать. Тут у любого зачешутся руки.

**Beat `c2s1b` · clear after the third Star** · *Запись: За сундуками лаз. Он ведёт наверх, к ниломеру. На ошейнике Миу свежий узел.*

- **Нефра:** Следы идут не к двери, а к стене. Из-за сундуков тянет рекой.
- **Мерит:** Лаз. Узкий, еле плечи пройдут. И кошка твоя сидит возле него, как сторож.
- **Нефра:** Миу, иди сюда. Ошейник у тебя тот же, а узел свежий. Странно.
- **Мерит:** Кошки сами узлов не вяжут. Лаз идёт вверх, на север. Там только ниломер.
- **Нефра:** Значит, следующий вопрос задаст ниломер.

### Slot 7 · Ниломер

*New painting B, a stone stair going down into green water, cubit marks on the wall. Teaser: «Лаз выводит к ниломеру. Здесь отец встречал каждое утро.» Items: Рейка, Кошка, Резец, Молоток, Ведро, Лягушка, Лотос, Фонарь.*

**Beat `c2s2a` · first clear** · *Запись: На стене две шкалы. Вторая, свежая, занижает воду на два локтя.*

- **Нефра:** Здесь отец стоял каждое утро с рейкой. Вот его метки.
- **Мерит:** А вот метка той воды. Выше всех. Такой ни я не видела, ни мать.
- **Нефра:** Подожди. Рядом вторые метки, резец другой, и работа новее.
- **Мерит:** Кто-то подправлял реку? Смелый человек.
- **Нефра:** Они ниже настоящих на два локтя. По ним выходит, что разливы были плохие.

**Beat `c2s2b` · clear after the third Star** · *Запись: Надзиратель зерна Ликон занижал разливы двадцать лет. Книга могла это доказать.*

- **Нефра:** В столицу пишут: воды мало, зерна мало. А с крестьян берут как за большую воду.
- **Мерит:** Брали. Брат мой платил, пока поле не отдал.
- **Нефра:** Эти цифры я видела в Мемфисе, в отчётах зерновой палаты. Подпись: надзиратель Ликон.
- **Мерит:** Ликон! Он в вашем доме вино пил. Лодку мою нанимать брезговал.
- **Нефра:** Отец видел эти метки каждое утро и вёл свой счёт. Двести лет настоящих чисел против поддельных.
- **Мерит:** И вот зачем нужна вода. Утопить архив, и нет больше чисел. Так?

### Slot 8 · Хранилище, второй круг

*Painting A. Teaser: «В податных сундуках могут быть письма. Вернитесь в хранилище.» Items (new): Письмо, Счётные камни, Сандалия, Кувшин, Ларец, Чернильница, Лесенка, Весы.*

**Beat `c2s3a` · first clear** · *Запись: Ликон просил Книгу «для царской переписи». Полки наверху были приманкой для него.*

- **Нефра:** Вот письмо в податном сундуке. Рука Ликона: просит Книгу «для царской переписи».
- **Хорем (thought):** Ответил: книга не покидает острова. Он улыбнулся. Такие улыбки я записываю.
- **Нефра:** Записывает. Вот его день, вот вино, вот улыбка. Всё с датой.
- **Мерит:** Так вот для кого твои полки с маслом и верёвками.
- **Нефра:** Для него. Чтобы искал счета за верёвку, пока вода не спадёт.

**Beat `c2s3b` · clear after the third Star** · *Запись: Отец рассчитал небывалую воду и предупредил палату. Ответ: «Разлив ожидается слабый».*

- **Нефра:** Запись за месяц до воды. Он считал следующий разлив.
- **Хорем (thought):** Вода придёт выше всех отметок. Удержит её дамба или нет, я не знаю, что хуже.
- **Нефра:** Выше всех отметок. За месяц, Мерит. Он знал.
- **Мерит:** Вот как он успел! Тоже мне тайна.
- **Нефра:** Знал и написал в палату. А вот ответ: «Разлив ожидается слабый».
- **Мерит:** Подпись можешь не читать.
- **Нефра:** Ликон. Он прочёл это предупреждение и промолчал. Запишем.

### Slot 9 · Перерезанная дамба

*New painting C, a broken earth dyke on the northern branch, reeds and a mooring stake. Teaser: «Отец боялся за дамбу. Надо увидеть её своими глазами.» Items: Лопата, Кошка, Кол, Канат, Весло, Мотыга, Сандалия, Кувшин.*

**Beat `c2s4a` · first clear** · *Запись: Края пролома ровные. Дамбу перерезали лопатами. Это не разлив.*

- **Мерит:** Вот она, дамба. Где размыло, там сейчас уже тростник. Что тут смотреть?
- **Нефра:** Размыло? Посмотри на края. Ровные, будто хлеб резали.
- **Нефра:** И следы вдоль края, от лопат. Много лопат.
- **Нефра:** Мерит, дамбу перерезали. Вода сама сюда не приходила. Её привели.
- **Мерит:** Поехали отсюда. Комары.

**Beat `c2s4b` · clear after the third Star** · *Запись: На колу обрывок каната с речным узлом. Мерит не хочет на него смотреть.*

- **Нефра:** На колу обрывок каната. Кто-то швартовался прямо здесь в ту ночь.
- **Мерит:** Мало ли канатов на реке.
- **Нефра:** Помоги снять. Не развязывается, сколько ни тяни.
- **Мерит:** Брось, говорю. Режь, если так нужен.
- **Нефра (thought):** Она ни разу не взглянула на этот кол. А ведь она смотрит на всё.
- **Нефра:** Возьму с собой. Последняя вещь всегда ведёт дальше.

### Slot 10 · Ниломер, второй круг

*Painting B. Teaser: «С верхней ступени ниломера видно весь рукав.» Items (new): Верёвка, Корзина, Табличка, Посох, Цапля, Сеть, Кувшин, Светильник.*

**Beat `c2s5a` · first clear** · *Запись: Отец видел лодку и шесть лопат и записал это. А людей с острова он отослал ещё днём.*

- **Нефра:** С верхней ступени дамба как на ладони. И его табличка за той ночь, вот.
- **Хорем (thought):** На северном рукаве одна лодка и шесть лопат. На кормовом конце речной узел. Записано.
- **Нефра:** Он видел. Стоял тут и видел, и записал.
- **Мерит:** А что он мог один, против шестерых?
- **Нефра:** Людей он отослал ещё днём. Значит, знал, что Ликон пришлёт лопаты. Откуда?

**Beat `c2s5b` · clear after the third Star** · *Запись: На дамбе узел Мерит. Она обещает всё сказать на месте.*

- **Нефра:** Речной узел. Я весь вечер его тянула. Кто на реке так вяжет?
- **Мерит:** Многие.
- **Нефра:** На террасе ты сказала: твой узел, кроме тебя, никто не развяжет.
- **Мерит:** Мало ли что я говорю.
- **Нефра:** Мерит, развяжи его.
- **Мерит:** Не здесь. Поехали на дамбу. Там скажу.

### Тайник 2 · След киля

*Chain on painting C: Кол, Канат, Весло, then one extra target, След киля (cache only, +1 ellipse).*

**Beat `c2t1` · on entering**

- **Нефра:** Кол, канат, весло. Покажи, как стояла лодка.
- **Мерит:** Ищи сама. Ты же у нас считаешь.

**Beat `c2t2` · chain solved · hook** · *Запись: Лодка в ту ночь была лодкой Мерит. Её нанял человек в капюшоне. Плата — золото в её ухе.*

- **Нефра:** След киля узкий. Такая лодка на этом рукаве одна. Твоя.
- **Мерит:** Моя.
- **Нефра:** Ты возила меня по острову. Ты смеялась. И всё это время ты знала?
- **Мерит:** Человек в капюшоне нанял меня на ночь. Шестеро парней с лопатами. Они сказали: чинить дамбу.
- **Мерит:** Заплатил золотом. Я такой платы в жизни не видела и вопросов не задавала.
- **Нефра:** А потом?
- **Мерит:** А потом пришла вода. Мой дом стоял на этом рукаве, писарша. Там теперь ил.
- **Мерит:** Вот оно, золото, в ухе. Ношу, чтобы помнить, сколько я стою.
- **Нефра:** Кто он был?
- **Мерит:** Лица не видела. Руки только, тёмные, будто в смоле. А на том берегу амбары Ликона. У него и спроси.
- **Нефра:** Вези. Разговаривать не обязательно.

## Chapter 3: Печать

### Slot 11 · Затопленные амбары

*New painting D, huge drowned barns on the low bank, silt to the beams, a grain measure on a hook. Teaser: «Амбары Ликона стоят на том же рукаве. Что там осталось?» Items: Кошка, Мерка, Серп, Мешок, Весы, Табличка, Совок, Крыса.*

**Beat `c3s1a` · first clear** · *Запись: Здесь лежало краденое зерно Ликона. Всё сгнило.*

- **Мерит:** Амбары Ликона. Гребла молча, как ты просила.
- **Нефра:** Ил по самые балки. Здесь лежало зерно, которого в отчётах никогда не было.
- **Нефра:** Всё, что он не успел продать. Чужие урожаи. И всё сгнило.
- **Мерит:** Брат бы порадовался. Поделом ему, надзирателю.
- **Нефра:** Я не просила тебя радоваться. Я просила грести.

**Beat `c3s1b` · clear after the third Star** · *Запись: Амбары затопило той же водой. Ликон не стал бы топить своё зерно. Дамбу резал не он.*

- **Нефра:** Постой. Амбары стоят на северном рукаве. Куда и пустили воду.
- **Мерит:** И что? Амбары как амбары.
- **Нефра:** Ликон велел утопить собственное зерно? Весь свой запас?
- **Мерит:** Нет. Такой за горсть ячменя удавится.
- **Нефра:** Значит, дамбу резал не он. Кто-то одной водой накрыл и архив, и амбары Ликона.
- **Мерит:** Кто же меня тогда нанял?

### Slot 12 · Дом надзирателя

*New painting E, a rich Greek-Egyptian office left in a hurry, ledgers and a dropped signet. Teaser: «Дом Ликона брошен. Он уехал быстро.» Items: Кошка, Отчёт, Перстень, Кубок, Печать, Лампа, Сандалии, Ларец.*

**Beat `c3s2a` · first clear** · *Запись: Ликон пишет в Мемфис: амбары утопил хранитель Хорем, и он жив.*

- **Нефра:** Поддельные отчёты, двадцать лет. Он их даже не сжёг. Заберём: в Мемфисе их прочтут.
- **Мерит:** Вот черновик письма, свежий. Читай, я таких слов не знаю.
- **Нефра:** «Мои амбары утопил хранитель Хорем. Его видели живым выше по реке. Иду за ним».
- **Мерит (shout):** Жив?!
- **Нефра:** Ликон лжёт. Ему нужно, на кого свалить.

**Beat `c3s2b` · clear after the third Star** · *Запись: Отец спрятал книги и отослал людей заранее. Нефра пока не хочет это считать.*

- **Нефра:** «Хранитель утопил». Удобная ложь для вора. Отец никогда бы не тронул свой дом.
- **Мерит:** Конечно, не тронул бы. Свой дом, свои книги.
- **Нефра:** Книги он спрятал заранее.
- **Мерит:** И людей отослал на праздник.
- **Нефра:** Замолчи.
- **Нефра (thought):** Злись и считай, писал он. Считать я пока не хочу.

### Slot 13 · Амбары, второй круг

*Painting D. Teaser: «Куда ушла бы вода, если бы дамба устояла?» Items (new): Зерно, Корзина, Цепь, Лодочка, Кувшин, Лестница, Ключ, Сеть.*

**Beat `c3s3a` · first clear** · *Запись: Если бы дамба устояла, вода смыла бы семь селений на правом берегу.*

- **Нефра:** Всё-таки считаю. Куда ушла бы вода, если бы дамба устояла?
- **Мерит:** На правый берег. Там семь селений, и стоят они ниже реки. Тётка моя там.
- **Нефра:** При такой воде от них остался бы один ил.
- **Мерит:** А они целы. Тётка говорит, в ту ночь у них даже зерно не намокло. Весь остров там плясал.
- **Нефра:** Семь селений за ночь не увезёшь. А один остров можно отпустить на праздник.

**Beat `c3s3b` · clear after the third Star** · *Запись: Шестеро с лопатами были из тех селений. Их звал «старый писец».*

- **Мерит:** Я спросила родню. Те шестеро с лопатами были оттуда, из селений.
- **Мерит:** Кто их позвал, молчат. Говорят только: «Велели копать или тонуть».
- **Нефра:** На рукаве тоже всех позвали на праздник?
- **Мерит:** Всех. Никто не утонул. Только я работала. За золото.
- **Нефра:** Кто-то очень хорошо знал этот берег. Запишем.

### Slot 14 · Дом надзирателя, второй круг

*Painting E. Teaser: «Что Ликон успел узнать раньше нас?» Items (new): Допрос, Письмо, Монеты, Плащ, Виноград, Зеркало, Гребень, Светильник.*

**Beat `c3s4a` · first clear** · *Запись: Лодочнице заплатили золотым знаком с тростником и водой.*

- **Нефра:** Ликон поймал одного из шестерых. Вот его допрос, слово в слово.
- **Мерит:** И что сказал парень?
- **Нефра:** «Лодочнице заплатили золотым знаком. На знаке тростник и вода».
- **Мерит:** Тростника на реке хватает.
- **Нефра (thought):** Она закрыла ухо платком. Вряд ли заметила, что закрыла.

**Beat `c3s4b` · clear after the third Star** · *Запись: Это знак семейной мастерской, с первого свитка. Он хранился в тайнике дома.*

- **Нефра:** Вот почему он написал «хранитель». Тростник и вода — печать нашей мастерской.
- **Мерит:** Мало ли кто мог её украсть.
- **Нефра:** Золотой знак один. Им отец скреплял только то, за что отвечал сам.
- **Мерит:** И где он лежит, этот знак?
- **Нефра:** В мастерской, в тайнике под верстаком. Едем домой.

### Slot 15 · Мастерская печатей

*New painting F, the family workshop on the island: stone seals, clay, gravers, Миу on the bench. Teaser: «Там, где началась первая печать, закончится игра.» Items: Резец, Глина, Кошка, Печать, Молоток, Кисть, Ступка, Лампа.*

**Beat `c3s5a` · first clear** · *Запись: Тайник пуст. Серьга Мерит — золотой знак мастерской.*

- **Мерит:** Гляди, сколько народу вернулось. При твоём отце так не шумели.
- **Нефра:** Вот тайник под верстаком. Пусто. Мерит, дай мне свою серьгу.
- **Мерит:** Зачем? Ну, на.
- **Нефра:** Прижимаю к глине. Это не монета. Тростник и вода.
- **Мерит:** Это та плата. Он заплатил мне печатью вашего дома?
- **Нефра:** Он не заплатил. Он подписался. За всё, что сделал той ночью.

**Beat `c3s5b` · clear after the third Star** · *Запись: Человек в капюшоне — сам Хорем. Он нанял Мерит и перерезал дамбу.*

- **Мерит:** Он всю ночь молчал. Руки тёмные, я думала, смола. А это чернила.
- **Нефра:** Это был он. Сам нанял тебя, сам привёл лопаты. Сам назначил воде час.
- **Нефра:** И та табличка: лодка, лопаты, узел. Ни слова лжи. Только стоял он не на ниломере.
- **Мерит:** Твой отец утопил твой дом. И мой. Мой, писарша!
- **Нефра:** И спас семь селений. Знаю. И то и другое записано.
- **Мерит:** Меня-то почему не спросил?
- **Нефра:** Меня тоже. Садись. Будем злиться вдвоём.

### Тайник 3 · Последняя вещь

*Chain on painting F, its own targets: Резец, Глина, Печать, Кошка.*

**Beat `c3t1` · on entering**

- **Нефра:** Игра не кончена. Последняя вещь всегда ведёт дальше. Где тут последняя?
- **Мерит:** Вон твоя кошка опять сидит, как сторож. Что у неё на шее?

**Beat `c3t2` · chain solved · hook · last beat of the game** · *Запись: Хорем жив. Он ушёл к первому порогу с Книгой. Следующая вода будет выше.*

- **Нефра:** Ошейник. Узел писца, и в бусине свиток. Мерит, он написан в прошлом месяце!
- **Хорем (thought):** Нефра. Раз ты здесь, ты всё сосчитала. Дамбу велел резать я. Записано моей рукой.
- **Хорем (thought):** Семь селений или наш остров. Я выбрал и выбрал бы снова. Прощения не прошу.
- **Хорем (thought):** Я вернулся за Книгой, пока ты строила. Увидел, как забил фонтан. Дальше смотреть не смог.
- **Нефра:** Он был здесь. Стоял на тех ступенях, в двух шагах от меня. И ушёл.
- **Хорем (thought):** По Книге следующая вода будет выше. Иду сверять к первому порогу.
- **Хорем (thought):** И на этот раз я не знаю, что резать.
- **Нефра:** Ты слышала. Ликон тоже идёт вверх по реке.
- **Мерит:** Слышала. И что будешь делать, писарша?
- **Нефра:** Мерит. Покажи верх своей карты.
- **Мерит:** Думала, больше не спросишь.

## Small lines

Side channel, one line each and once per save, not in the chapter counts. **Beat keys** are in backticks.

**Мерит, when a shore opens** (replaces the single repeated line at `lua/archive_content.lua:82`; the first keeps it, including the drag hint).

- `shore-1`, **Мерит (shout):** Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.
- `shore-2`, **Мерит (shout):** Ещё берег! С него видно северный рукав. Я туда без нужды не хожу.
- `shore-3`, **Мерит (shout):** Последний берег! Дальше только река и всё, что вверх по ней.

**Мерит, on first placing each restoration** (reference: landmark dialogue, `wiki*`, `analysis`).

- `restore-fountain`, **Мерит:** Забил! Вот теперь твой канал услышит воду.
- `restore-workshop`, **Мерит:** Мастерская. Твой отец тут просиживал ночи, глину мял.
- `restore-archive`, **Мерит:** Архив без книг. Смешно. Но люди любят, когда у дома есть крыша.
- `restore-temple`, **Мерит:** Храм Исиды. Теперь хотя бы есть кому пожаловаться на реку.

**Мерит, when Influence crosses a milestone.** These give decorating a reason in the fiction without tying the plot to any one item. They replace nothing.

- `influence-100`, **Мерит:** Пекарь вернулся и привёл двоих. Говорит, тут снова пахнет хлебом. Врёт, но приятно.
- `influence-200`, **Мерит:** На причале очередь. Я подняла плату. Никто не спорит, значит, мало подняла.
- `influence-300`, **Мерит:** Сегодня твой остров спрашивали по имени с того берега. Запиши, писарша.

## 4. The end screen

Neither reference shows evidence of a "to be continued" screen. At June's Journey's content edge the player waits for the next weekly chapter, and the screen is not described (`player*`). Tropicats' FAQ congratulates and promises more with no date (`official`). **This is our design.**

Shown once, right after `c3t2`, as a new `MODAL_END` popup over the island, using `K.frame` and `K.ribbon`. Beat key `tbc`.

> **Ribbon: ПРОДОЛЖЕНИЕ СЛЕДУЕТ**
>
> *И на этот раз я не знаю, что резать.*
>
> Хорем жив. Ликон идёт за ним. Вода вернётся выше.
>
> **Дальше: Первый порог**
>
> Главы 3 · Сцены 15 · Звёзды N из 45 · Влияние N · Построек N
>
> **[ На остров ]**

- **No date,** since we have no release schedule. "Дальше" names a direction, not a promise of when.
- **The player keeps the island:** decorations, replays and shores stay open. At least 76% of the catalogue is still unbought at minimum income (2.5).
- **Goal card afterwards** (`lua/archive_island.lua:88`): eyebrow «ПРОДОЛЖЕНИЕ СЛЕДУЕТ», title «Обустраивайте остров. Мерит готовит лодку». Replaces «АРХИВ СОБРАН». Tapping it reopens the popup.
- **Optional reward (`player`, one report of a volume-end decoration):** one free «Причал с фелюкой» (`felucca_dock`, already in the catalogue), so Мерит's boat is on the island. No new art.
- **Natural next step:** a new map up the river to the first cataract, with the same cast.

## 5. Implementation notes

Line numbers are at `c3b507b`. Nothing here has been built or run. Per `AGENTS.md`, this PR needs screenshots, and the changes are game-local unless the engine gets a list or modal feature.

### Code

| File | Change |
| --- | --- |
| `lua/archive_economy.lua:3` | Add `CACHE_COINS=150`, `DECOR_COINS_PER_INFLUENCE=10` |
| `lua/archive_economy.lua:4` | 15 gates from 2.5. **Keep 0, 20, 50** |
| `lua/archive_economy.lua:5-11` | Restorations once per save; data flag, enforced in the tray |
| `lua/archive_economy.lua:12` | Shore requirements 3/6/11 next to prices |
| `lua/archive_economy.lua:14-18`, `:21-25` | `for i=1,3` becomes the scene count. This is the hard-coded 3 |
| `lua/archive_economy.lua:27-31` | `can_play` needs the previous scene's final clue and the previous Тайник for openers. **Keep** the legacy `wins[i]>0` line |
| `lua/archive_economy.lua:33-40`, `:42-52` | Effective Stars floor in `claim`. Clue A or B decided here, on the **pre-claim** best, so a Star earned this play does not count |
| `lua/archive_state.lua:24-25` | `wins`, `stars` sized by scene count. Add `clues` (0/1/2) and `caches` |
| `lua/archive_progress.lua:13-14` | Same in `new_game` |
| `lua/archive_progress.lua:21-25` | Version 3 to 4, serialise `clues` and `caches` |
| `lua/archive_progress.lua:67-72` | `chapter_goal` to walk clues and Тайники, not just wins |
| `lua/archive_content.lua:10-30` | 15 scenes in chapters, `clue_a`, `clue_b`, `note_a`, `note_b`; computed gate text in place of `:17` and `:23`; 3 `caches` |
| `lua/archive_content.lua:53-54`, `:63-64` | Decorations: `reward = purse(0, floor(coins/10))`, Star unlock × 5 |
| `lua/archive_content.lua:77-82` | Prologue, shore lines, restoration and milestone lines |
| `lua/archive_scene.lua:147` | Play clue key by state, not `chapter-%d` |
| `lua/archive_scene.lua:124-146` | Тайник mode: one target at a time, no combo, no miss penalty, no stars |
| `lua/archive_scene.lua:119-122` | `stars_for` stays. Floor lives in the economy |
| `lua/archive_dialogs.lua:36`, `:60` | Win dialog uses the note, not `sc.clue[1..2]`, which breaks on 3-12 line beats |
| `lua/archive_dialogs.lua:60`, `:93`, `:99`, `:104` | "ГЛАВА %d" and the "80 монет" line become scene text; add "Нужны улики" locked state |
| `lua/archive_dialogs.lua:73-108`, `:131-140` | The browser draws `SCENES` columns (`:133`, `:139`), unreadable at 15. Make it chapter pages of 5 + Тайник (reference hub, `official`). Prefer the engine `list` with `form:set_items` (`engine/ui_forms.lua:92`), as `AGENTS.md` asks |
| `lua/archive_dialogs.lua:161` | Add `MODAL_END`; small Journal |
| `lua/archive_island.lua:38` | Shore needs |
| `lua/archive_island.lua:86-92`, `:349-350` | Goal card and red dot: replay for clue, Тайник ready, end |
| `lua/archive_island.lua:172-175` | Locked text and "+N влияния" also for decorations |
| `lua/archive_island.lua:236`, `:274` | Fire restoration and milestone lines at the existing confirm point |
| `lua/archive_island.lua:328` | `story.add` per shore |
| `lua/main.lua:71`, `:93`, `:96`, `:101`, `:113`, `:119` | Debug `wins`/`stars` literals of length 3 |
| `lua/main.lua:125-128` | `chapter-2` debug beat |
| `lua/main.lua:176` | Load textures per **path**: paintings are shared. I did not verify whether `texture.load` caches |
| `lua/main.lua:65` | New `--screen end`, `cache0..2` entries |
| `lua/archive_smoke.lua:94`, `:124`, `:134`, `:158`, `:163` | Smoke path and "grant no Influence" assertion change. Must reach clue B in the path |
| `tests/lua/archive_rewards.lua:6`, `:28-29`, `:33-38`, `:40-41` | State shape, two-clear path, replay coin totals, can_play signature |

**Engine:** nothing required. `story.c` holds 48 queued lines at 512 bytes (`engine/story.c:19`, `:37`) and 256 seen beats (`:20`). The script needs under 60 beats and at most 12 lines in one, so it fits. `tests/test_story.c` and the shipped game have only played short beats, so check long beats in the game.

**Docs to update when implementing:** `README.md` (rules, table, status), `docs/PROJECT.md`, `docs/REFERENCES.md:28`, `docs/ECONOMY_RESEARCH.md` Nile section, `docs/UI_CATALOGUE.md`.

### Saves

- **Format holds.** `s:ints` reads only as many ints as the Lua table has and leaves the rest at their default (`engine/save.c:105-116`), so a 3-element `wins` loads into a 15-element table. Size the tables **before** `progress.read`, as `init` already does through `new_game` (`lua/main.lua:180-182`).
- **Slots are append-only,** so old `wins` and `stars` indices stay valid.
- **Beats by new key.** Old saves hold `chapter-0..2`. The new keys are unseen, so an old player sees the new clue A on their next clear of that scene. That is harmless, and worth it to read the new lines. `intro` stays seen, so they miss the prologue's three new lines.
- **`clues` migration at version < 4:** `clues[i] = 1` where `wins[i] > 0`, and `2` where `stars[i] == 3`, except that their clue B beat is still unseen and will play on the next clear. Nobody is re-locked: `can_play`'s `wins[i]>0` covers visited scenes.
- **Influence migration at version < 4:** add `floor(coins/10)` once per placed decoration, so decorators are not penalised. Walk `G.island.items`. The version read at `:21` is currently discarded, so it has to be kept.
- **Decoration × 5:** a player with 9 Stars keeps placed items but can't buy further ones until they earn more. Acceptable.
- **Legacy HTML import** (`lua/archive_progress.lua:52-64`) writes only coins, influence, wins and city, so the above covers it.

### Art needed

| Item | Count | Notes |
| --- | ---: | --- |
| New hidden-object paintings A-F | **6** | 1200×800, palette PNG, about 700 KB each (`docs/PROJECT.md:176`), style of the existing three, targets painted in. Item lists above are the briefs |
| Hit ellipses | **97** | 48 on new paintings, 48 on re-lists (16 of them on existing paintings), 1 for След киля |
| Portraits | **0** | Optional and not required: Ликон. The script never needs him on stage |
| Panels, cutscenes | **0** | The audit's grep found no cutscene system, and the script doesn't rely on one |
| Buildings | **0** | Existing catalogue covers all of it |
| UI | small | Chapter page, end popup, Тайник bar: drawn by `K.frame`, `K.ribbon` in `lua/archive_kit.lua`. Add to `docs/UI_CATALOGUE.md` |

Add a catalogue row per painting and list as `AGENTS.md` requires for a visual addition. Review each painting in-game with its hit data before posting.

### Suggested order

1. Economy, slots, clues, saves, chapter 1 with no new art. It is playable to `c1t2` with the end screen stubbed.
2. First painting (A). Measure the real cost and correct 2.6.
3. Remaining paintings, chapters 2-3, end screen.

## Decisions the owner must make

1. **Energy:** none, full clone or replays only (1.2). Recommendation: none.
2. **Chapter count and art budget:** 3 chapters and 6 paintings (2.1, 2.6).
3. **Decorations grant Influence** at 10 coins each, reversing the current rule (2.4).
4. **Second clue behind the third Star**, with the play-count floor, reversing "no mandatory replays" (2.3).
5. **Restorations once per save** (2.4).
6. **The final twist:** the father deliberately drowns his own home. It's the most consequential story choice, and everything is built around it.
7. **"Гранат" label** in slots 1-2: keep it as a clue or fix it as a bug.
8. **Tone of the historical anchor:** Мемфис, royal grain office, nilometer tax. See below.

## Changelog

**2026-11-02.** First draft, written to `docs/STORY_WRITING.md`, which appeared in the repo during the work. One cold read by a separate agent, chapter by chapter, with no notes. It reached the final reveal at about 55-60% by the end of chapter 2 and found it mostly fair. **Fixed from the read:** the island contradicted "drowned"; Хорем was in two places on the night; the villages and the seal motif had no plant; inky hands had no plant; a broken seal on a jar made no sense and is gone; the token's use is now motivated (a signature); no clock (now nine months); why a game at all; "никогда не спросишь" contradicted an earlier ask; "матрица" and other stiff Russian; several confirmations of the reveal trimmed. **The fixed version has not had a second cold read.**

**Still owed:** the father never appears, so the climax is a note; that is deliberate for "to be continued" but it is the read's main complaint. The reveal is guessable early, by design under the guide's small-cast rule, since the surprise is why and what it cost. Why Ликон was not exposed earlier by the record, the keel track surviving a flood, and a Russian-language pass by a native editor all remain open. Мерит still sometimes acts as a prompter for Нефра.

## Not verified

- **The cold read** covered the first draft, not this version.
- **Nothing was built or run.** No line has been seen in a bubble. The longest new line is 99 characters, against 92 in the shipped text. Check long lines at 1200×900 and 1368×1026.
- **June's Journey numbers** are as weak as their labels. `wiki*` and `player*` come from search excerpts.
- **Play time and art hours** are estimates. Human session length is not measured anywhere in the repo.
- **Extra targets on existing paintings** were identified by eye, with no measurement.
- **Land capacity** for about 25-30 buildings across the opened zones is not checked.
- **`texture.load` caching** when several scenes share a painting.
- **History.** Nilometers, flood-based tax, the first cataract and a royal decree copied at Memphis around 196 BC are from general knowledge, not checked. `docs/PROJECT.md:44` already says the setting has had no expert review. Likon and his office are invented.
