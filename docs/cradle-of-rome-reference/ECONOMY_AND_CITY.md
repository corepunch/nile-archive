# Resource economy and city progression

## How a board pays

Plaques are the finish condition. Coins and other pieces pay for
construction as the player clears them, including in cascades in the
published desktop rules. Remaining time can also pay out on a win. This
creates a choice while there are still plaques on the board. A player
can take a match that earns the scarce resource, take the shortest route
to the final plaque, or find a match that does both.
[GameHouse walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/)

The Android piece table has five initially available regular types.
Silver and gold coins pay into the same purse at different rates.
Types 1, 2 and 17 have a base score of 5 and a resource credit of 0.
The other regular resource pieces have base score 5 and the following
credits. The English help and internal sprite labels use different names
for some pieces. Type 5, for example, is described as Meat in
the tutorial and named Water Bucket in the field art table. Its credit
is Food either way.

| Currency | Resource type → base credit |
| --- | --- |
| Gold (1) | Silver coin 3 → **3**; gold coin 4 → **5**; ring 12 → **6**; pearl 13 → **7**; diamond 16 → **8**; goblet 15 → **9**; brooch 14 → **10** |
| Supplies (2) | Lumber 6 → **5**; stone 8 → **7** |
| Food (3) | Meat / Bucket 5 → **3**; flour 7 → **4**; barrel 9 → **5**; watermelon 10 → **6**; fish 11 → **7** |

The Android Adventure `Score/Match` table sets multipliers 1, 2 and 4
for lengths 3, 4 and 5, with 6 for lengths 6 and 7. The desktop walkthrough
explains the corresponding short-line resource totals as 3, 8 and 20 times
base yield. At a gold coin's base of 5, that is 15, 40 and 100 Gold. The
Android `Score/Combo` table separately lists multipliers 2, 4 and 6 for
counts 2–4. Its `LevelComplete` sets `time_multiplier="7"` and
`level_multiplier="2"`, and the results UI labels a time bonus. The static
tables do not establish the Android payout order, how the time bonus is
allocated across purses, or what a failed attempt banks.
[Android source inventory](README.md#source-inventory) · [GameHouse walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/)

The Adventure settings also have a separate `BuyExtraTime` table specifying
a 60-second extension with rising prices, and a score threshold of 50,000
per extra life. Those settings give a reason to distinguish score, the
construction wallet and the timer when reading rewards.

Tools are another use for the matching loop. The eight `BonusBall` types
600–607 each credit 3 into a dedicated tool counter (types 10–17), whose
configured range is 0–200. The guide describes filling the corresponding
meter by matching its pieces and charging it again after use. Effect
details can differ by build. For example, Android `bonuses.xml` has
Lightning `total_kills="15"` and `puzzle_kills="1"`, while the desktop
guide describes a 20-tile tool. The type ID and its purpose are stronger
design evidence than either number for porting.

## The construction ladder

The shop data has five epochs with four purchases each, plus the
`city_olympus` completion entry with no listed price or piece unlock.
The rows below follow XML order. That order records a catalogue and a
sequence of economic roles. Exact within-epoch purchase freedom and the
level of any purchase are runtime questions. `city_view.xml` supplies
prepared positions and layered appearances for the built city.

Amounts below are **Gold / Supplies / Food**, in Rome's units. The last
column identifies the configured piece a purchase makes available.
The tool labels use the English names where the internal art or code uses
a different label.

| Epoch | Building | Price | Piece or tool |
| --- | --- | ---: | --- |
| Seven Hills | Sawmill | 500 / 0 / 0 | 6, Lumber |
| | Forge | 1,000 / 1,000 / 0 | 600, Hammer |
| | Quarry | 3,000 / 2,000 / 0 | 8, Stone |
| | Mill | 4,000 / 5,000 / 0 | 7, Flour |
| New City | Village | 3,000 / 3,000 / 2,000 | 5, Food piece |
| | Field | 5,000 / 4,000 / 4,000 | 10, Watermelon |
| | Fountain | 5,000 / 6,000 / 5,000 | 604, Lightning |
| | Tavern | 7,000 / 7,000 / 6,000 | 9, Barrel |
| Birth of Empire | Rostra | 9,000 / 8,000 / 9,000 | 601, Bomb |
| | Arch of Titus | 12,000 / 11,000 / 11,000 | 12, Ring |
| | Pantheon | 15,000 / 14,000 / 14,000 | 603, Time |
| | Tabularium | 18,000 / 18,000 / 17,000 | 605, Plus |
| Gladiators' Arena | Port | 20,000 / 23,000 / 21,000 | 11, Fish |
| | Ship | 26,000 / 25,000 / 24,000 | 13, Pearl |
| | Lighthouse | 28,000 / 30,000 / 29,000 | 607, Star |
| | Colosseum | 34,000 / 35,000 / 33,000 | 602, Shield |
| Age of Glory | Statue of Trajan | 36,000 / 36,000 / 37,000 | 16, Diamond |
| | Temple of Venus and Roma | 40,000 / 42,000 / 42,000 | 606, Mixer |
| | Temple of Saturn | 45,000 / 45,000 / 47,000 | 15, Goblet |
| | Forum | 50,000 / 50,000 / 50,000 | 14, Brooch |

The early ladder makes the supply chain visible. The first purchase uses
only Gold, the two coins fund it, and the Sawmill introduces Lumber.
The next purchase needs Supplies and introduces a tool. The Quarry
introduces a higher-yield Supplies piece. The Mill introduces Food
before the first price that requires it, the Village. From the Village
onward, all 16 purchases use all three currencies. The first epoch's
combined cost is 8,500 / 8,000 / 0 and the last is 171,000 / 173,000 /
176,000. These are price totals. They do not tell us the time, attempts,
or average earnings needed to afford a building.

Each of the 20 purchases has a `PlanAccess` resource threshold equal to
its `Price` in the data. The plan records also include jigsaws, card
games, sliders, circles and searches, with scores. This establishes
authored plan content and two matching sets of thresholds. Whether a
plan puzzle is mandatory, skipped or charges separately in this beta
is unverified. The shop config defines an epoch celebration, and the
locale shows the successive ranks Peasant, Merchant, Priest, Senator
and Emperor. The full-release ending copy distinguishes completing the
levels from completing the city and qualifying for Olympus.
[Android source inventory](README.md#source-inventory) · [Full release description](https://store.steampowered.com/app/38170/Cradle_of_Rome/)

## Citizen upgrades

City purchases can arm an optional skill challenge. The Sawmill's
`Upgrade id="0"` enables event `man_01`. The event watches for a five-piece
match, upgrades that building, and adds 100 Supplies per level. The
Quarry's `man_03` asks for 2,000 Supplies in one board and adds 200 Supplies
per level. The Field's `man_05` asks for 3,000 Food on one board and adds
200 Food per level. The Tavern's `man_06` asks for a two-combo event and
adds 300 Food per level. In a different branch the Forum's `man_011`
checks for 3,000 Gold earned in one board and changes tool weights.
These are event predicates and actions. The exact activation window and
meaning of weight changes in the spawn algorithm are unverified.

The city-to-board link has two distinct payoffs. Building something
changes the options the player sees on the board. Playing well can add
a visible citizen at that building and improve future income or tools.
For Relic Rush, the first payoff can work on its own. A citizen-style
challenge would add a new optional progression layer and can start with
a one-time reward before testing any repeatable income.
[Relic Rush adaptation](ADAPTATION.md#priorities)
