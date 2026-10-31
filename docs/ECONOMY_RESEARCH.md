# Progression and economy study

Research checked 30–31 October 2026. This document separates documented publisher
mechanics, our interpretation, implemented changes, and proposed future work.
It covers Relic Rush (the Lost Valley match-4 game) and Nile Archive (the
hidden-object estate game). All tuning numbers below are our own prototype
budgets, not claimed Playrix or Wooga reward tables.

## Decision

Use two complementary loops, with unlimited play and instant construction:

| Game | Win a round | Spend | Permanent progress | Return to play |
| --- | --- | --- | --- | --- |
| Relic Rush | First discovery funds its restoration, adds 80–120 spare Gold, 3 Discovery Stars and a scheduled Compass grant | Gold/Wood/Stone on the story wonder; spare Gold on optional catalogue items; Compasses on land | Discoveries unlock stock and regions; each restored wonder advances the island story | Next discovery after restoration, or replay any completed expedition for 60–100 Gold |
| Nile Archive | 80 Coins every completed scene; first-clear, improved-Star and clean-search bonuses | Coins on buildings or optional shores | Buildings give Influence; preceding clues plus Influence open the next chapter | Repeat an open scene for Coins or pursue the next unlocked clue |

The important distinction is between **money that circulates**, **milestones
that are earned once**, and **requirements that are checked but never spent**.
The UI must say which is which before the player commits a purchase.

## What the reference games actually do

| Reference | Documented reward and spending model | Lesson for these games |
| --- | --- | --- |
| Homescapes | Completed levels give restoration Stars and Coins for game resources/additional moves. Saved moves improve rewards. Completed levels cannot be repeated. [Official level guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1087-how-do-i-play-match-3-levels/) | Separate story entitlement from discretionary spending. Tie a bounded bonus to performance. Our repeat option is a deliberate adaptation to a ten-level campaign. |
| Gardenscapes | Regular levels award one task Star; Challenge levels award three. Coins buy puzzle assistance. [Official overview](https://playrix.helpshift.com/hc/en/5-gardenscapes/faq/15571-about-the-game-how-to-play-gardenscapes/) | A puzzle should lead to an understandable restoration action. A Star is not a universal definition shared by every game. |
| Fishdom | Coins buy fish/decorations; Diamonds buy boosters, moves and lives. They cannot be exchanged. [Currency guide](https://playrix.helpshift.com/hc/en/4-fishdom/faq/15954-coins-and-diamonds/) | Playrix also supports a play-to-decorate economy, so copying its restoration-Star system is not mandatory. |
| Fishdom progression | Decorations and fish add Beauty. Beauty Stars open aquariums and improve level income; removing items reduces the tank's Beauty. [Beauty guide](https://playrix.helpshift.com/hc/en/4-fishdom/faq/16092-aquariums-and-beauty/) | Construction can have a visible progression return rather than only being a sink. |
| June's Journey | Repeated scenes accumulate mastery toward five Stars. Estate decoration earns Flowers that open chapters. Some buildings generate Coins. [Official gameplay guide](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-play-junes-journey-394) | Scene mastery, purchasing power and island progress are separate tracks. Nile's Influence should come from the estate. |
| June's Journey shop | Coins or Diamonds buy items; some stock requires an earned Star count. Construction usually takes time. [Decoration guide](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-get-new-decorations-326) | Show purchase cost separately from the unlock requirement. Our instant build avoids importing waiting into a small offline game. |
| June's Journey land | Clearing clouded areas usually checks Stars and Compasses. [Expansion guide](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-get-more-space-on-orchid-island-331) | Give land its own budget and display its requirements. Do not let optional decoration consume the expansion supply. |
| June's Journey chapter structure | The final Adventure Scene is untimed; access requires the chapter's clues and a Star threshold. The following chapter also depends on Flowers. [Adventure-scene guide](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-an-adventure-scene-483) | Preserve narrative order as well as an estate requirement; wealth alone must not skip clues. |
| June's Journey onboarding | Island Errands offer one task at a time and explicitly connect searching, Coins, clues, Stars and decorating. [Errands guide](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-island-errands-398) | Offer a useful next action from the result screen and island goal, rather than explaining everything at once. |
| June's Journey ongoing goals | Cases invite replays, new scores, clean searches, building income and decoration purchases. Materials for upgrades come from boxes and scenes. [Help Wanted guide](https://wooga.theymes.com/hc/en/junes-journey/articles/help-wanted-cases-393) | Replays need an economic purpose. Material systems need real upgrade sinks before adding more inventories. |
| Pearl's Peril | Scenes have five increasingly difficult badges. Island decorations add Prestige to unlock scenes/areas; buildings generate daily Coins. [Official guide](https://wooga.theymes.com/hc/en/pearls-peril/articles/how-do-i-play-pearls-peril-162) | Nile's build → Influence → next scene loop fits the genre directly. |
| Township | Production feeds orders; helicopter orders return Coins/experience, trains return construction materials, and other deliveries have different returns. [Production guide](https://playrix.helpshift.com/hc/en/3-township/faq/15993-farming-production/) | Multiple materials make sense when activities and sinks differ. A large factory chain would exceed the current games' content. |
| Manor Matters | Coins, tools and lives have multiple sources, including levels, story-day milestones and events. [Resource guide](https://playrix.helpshift.com/hc/en/16-manor-matters/faq/3510-how-do-i-earn-resources-in-the-game/) | Reward beats can span a session, but each added system needs content and a clear purpose. |

These are functional observations from official support documentation, not a
claim that a particular mechanic causes retention. Public documentation does
not reveal complete difficulty curves, cohorts, experimental variants or economy
telemetry. Exact live-service payouts can change; this study avoids copying
unverified coin values from old guides.

## What we adapt and what we leave out

Our interpretation is to borrow clarity, visible estate progress, recoverable
spending and a short next-action loop. Relic Rush keeps its archaeological
Gold/Wood/Stone identity; replacing those balances with spendable Stars would
require another migration and would duplicate its existing Discovery-Star
meaning. Materials now fund a specific restoration predictably, rather than
growing as an incidental by-product of random tile colours.

Nile keeps three **performance** Stars per scene, not June's Journey's five
accumulated mastery Stars. Improving a best rating now has a one-time Coin
reward. This gives its current three-scene prototype a replay goal without
pretending it has the content volume for a long mastery grind.

The reference games also use session limits: Gardenscapes documents regenerating
lives, and June's Journey documents construction time. Those support their
live-service structure. Unlimited retries and instant construction remain the
working scope here. There is no new energy, premium currency, random chest,
daily login obligation, production timer or purchase backend.
[Gardenscapes lives](https://playrix.helpshift.com/hc/en/5-gardenscapes/faq/16021-how-to-get-lives/),
[June's Journey construction](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-get-new-decorations-326).

## Problems found in the previous implementation

| Game | Code finding | Player consequence |
| --- | --- | --- |
| Relic Rush | Ten one-time payouts funded 96 catalogue entries; another completion of an old level could not pay | The decorative shop eventually became an earning dead end |
| Relic Rush | Reward added raw Idol/Leaf/Crystal clears to each restoration cost | Wallet totals depended on random colours and surplus materials had no further sink |
| Relic Rush | Every victory displayed 3 Stars and 3 Compasses; 30 Compasses entered a map costing 20 | UI suggested generic prizes rather than a planned expansion budget |
| Relic Rush | Shop showed total Gold, including the amount reserved for earned wonders | Displayed money and available spending could disagree |
| Nile Archive | Every scene replay paid 240 Coins **and 20 Influence** | Playing alone bypassed the advertised restoration loop |
| Nile Archive | New saves started with 260 Coins; chapter cards only checked Influence | Buildings could open later scenes before earlier clues were found |
| Nile Archive | Time Stars had no economic effect; rewards never varied | Improving skill had little purpose beyond the displayed rating |
| Nile Archive | Clicking an island plot could immediately buy the selected building | Exploration or a mistaken placement could spend the wallet without review |

These findings come from the runtime rules and entry points before this change,
not from the publishers. Historical before captures are retained in each game's
economy review directory.

## Relic Rush: implemented budget

**First clear:** the next wonder's complete Gold/Wood/Stone cost, plus 80 Gold,
plus `min(40, 2 × moves remaining)` Gold. It also grants 3 permanent Discovery
Stars and the level's Compass amount. **Replay:** 60 Gold plus that same bounded
move bonus; no materials, Stars, Compasses, new wonder or story advancement.
An individual result can be claimed only once. A failed or abandoned attempt
has no payout and no financial penalty.

| Discovery | Wonder | Gold grant | Wood | Stone | Spare Gold | Compasses |
| ---: | --- | ---: | ---: | ---: | --- | ---: |
| 1 | Expedition camp | 60 | 10 | 5 | 80–120 | 1 |
| 2 | Spring well | 80 | 15 | 15 | 80–120 | 1 |
| 3 | Artisan workshop | 100 | 25 | 15 | 80–120 | 3 |
| 4 | Jungle market | 120 | 25 | 25 | 80–120 | 2 |
| 5 | Sunstone courtyard | 140 | 30 | 30 | 80–120 | 2 |
| 6 | Explorer's lodge | 160 | 35 | 35 | 80–120 | 2 |
| 7 | Lost-world archive | 180 | 35 | 45 | 80–120 | 3 |
| 8 | Star observatory | 200 | 40 | 50 | 80–120 | 3 |
| 9 | Jade fountain | 220 | 45 | 55 | 80–120 | 3 |
| 10 | Temple of the sun | 250 | 50 | 60 | 80–120 | 0 |

The whole first-clear campaign provides **800–1,200 discretionary Gold**, in
addition to the entire restoration bill. Twenty Compasses cover all five
expansions by discovery nine, when its Star requirement becomes reachable.
Stars and the existing stock/region thresholds remain cumulative and unspent.

Gold already committed to earned, unbuilt wonders stays protected. The shop
now distinguishes spendable and reserved amounts. With zero move bonuses, a
player can spend every discretionary coin after every win and still restore
all ten wonders and open the whole map. Optional stock never consumes Wood or
Stone. All old balances and ownership are retained.

Indicative saving goals at the minimum replay payout:

| Purchase | Gold | Replays from an empty spare purse |
| --- | ---: | ---: |
| Shrub | 15 | 1 |
| Young palm | 30 | 1 |
| Trapper's cabin | 200 | 4 |
| Relic museum | 500 | 9 |
| Hanging gardens | 550 | 10 |

These are optional goals, not a requirement to buy the entire catalogue. Early
first-clear surplus covers several small decorative choices immediately. The
expedition browser exposes completed, current and future stages; the current
discovery waits for the earned restoration, while completed stages remain
available for earning. The finale now has a useful play-for-Gold route.
Pause resumes the same board and moves, restarts it after a confirmation (a
free retry, like a failure), or quits to the island keeping the unfinished board
for the next LEVEL / Expeditions visit; neither pays anything. An unfinished board still restarts after closing the
application, as in the existing save contract; board persistence is separate work.

## Nile Archive: implemented budget

| Resource or record | Source | Use |
| --- | --- | --- |
| Coins | 80 per completed scene; +40 on its first clear; +20 per newly improved best Star; +20 for a completion with no misses or hints | Repeatable buildings and optional shores |
| Influence | Starting house supplies the initial 10; purchased buildings add their listed amount once | Non-spendable chapter/estate progress; scenes award none |
| Scene Stars | Best time rating, 1–3, with existing 75/150-second thresholds | Visible performance record; only improvements pay the Star bonus |
| Completed chapters | Unique discovered clues, rebuilt from saved wins | Story order and building/shore unlocks; replays do not inflate it |

New saves start with **0 Coins, the existing house and 10 Influence**. A slow
first clear earns 140 Coins; a three-Star clean first clear earns 200. Repeating
a mastered scene pays 80–100, with an additional milestone bonus only when its
best Star count improves. Hints remain free and always available after their
existing recharge. A player using hints still earns the full 80-Coin base and
any first-clear/improvement rewards.

The first clear unlocks houses, fountains and workshops. The second unlocks the
archive and temple. Their prices and Influence yields remain 70/+10, 60/+10,
100/+15, 130/+25 and 160/+30 respectively. The building list uses these same
tested data records for price, payoff and requirements. All purchases preview
the cost and Influence return, and debit/add them only on Confirm. Cancel and
movement are free.

Minimum-reward example, using one-Star wins and no clean-search bonus:

| Step | Coins after action | Influence | Result |
| --- | ---: | ---: | --- |
| Start | 0 | 10 | First chapter available |
| Clear courtyard | 140 | 10 | First restoration funded |
| Build fountain, pay 60 | 80 | 20 | Library opens |
| Clear library | 220 | 20 | Temple becomes purchasable |
| Build temple, pay 160 | 60 | 50 | Final chapter opens |
| Clear temple scene | 200 | 50 | Three clues complete; replay/decorate remains available |

Players can choose a different eligible building mix. Chapter two requires the
first clue and 20 Influence; chapter three requires the second clue and 50.
Replay farming cannot satisfy the Influence requirement by itself. Optional
shore costs are now 120/180/240 Coins, gated by one/two/three unique chapters.
Each shore costs at most three minimum-reward replays; spending on one cannot
permanently strand the player. No shore purchase is required to read a clue.

The result screen explains the actual paid components and offers construction
when Influence is the next requirement. The island goal shows the remaining
Influence gap and opens the building list directly. Chapter cards explain the
preceding-clue requirement and the repeatable Coin source.

## Save and transaction rules

- Existing wallets, buildings, best Stars, wins, opened land and once-only story
  beats are preserved. No old currency is confiscated to force the new curve.
- Already visited Nile scenes remain replayable in legacy out-of-order saves.
  New scenes follow the corrected clue order. Building requirements are derived
  from unique saved clears rather than replay count.
- An attempt's result pays once. Closing/reopening UI cannot duplicate it.
  Replaying is a fresh won attempt with a fresh payout, not another claim of the
  old result.
- Construction pays and grants its progress atomically at confirmation. Preview,
  cancellation, blocked placement and moving do not alter the economy.
- Opening a shared modal consumes its opening-frame input; the same release
  cannot immediately activate a new modal button under it. This fixed an actual
  smaller-phone replay-browser failure found during input testing.

## Evidence and remaining tuning

The [machine-readable audit](economy-audit.json) runs the actual puzzle rules
with 20 deterministic seeds per level, a greedy legal-swap policy and no tools.
It won **199 of 200** attempts. Old mean spare Gold per won level ranged from
about 31 to 64; the new policy gave about 117–120 for this strong automated
player. Guaranteed floors, rather than that bot's performance, define the
progression budgets. Zero-bonus tests separately prove campaign affordability.

This bot is not a novice, and these are not measured human win rates. Puzzle
move counts, objectives and tool allowances have not been tightened based on
automated play. Both games are still small prototypes: ten puzzle stages and
three hidden-object scenes. They do not yet have the content breadth of their
references, building upgrades, a player-tested mastery curve or live telemetry.

Before extending the campaign, playtest the first 15–20 minutes with new players.
Record time to first win/build/expansion, result-to-building conversion, repeated
failure count, unspent materials, discretionary Coin balance, and whether the
next action is understood without explanation. Check slow/hint users separately.
The initial targets are one visible restoration per Relic discovery, no forced
replay on Nile's shortest story path, and optional expensive decorations that
remain reachable by a visible repeatable activity.

Future work, not included in this implementation: more scenes/levels before
larger grind targets; estate projects with meaningful upgrade stages before new
material types; optional mastery challenges with original art/content; and a
reviewed storage/selling design before enabling removal that could lower estate
progress. Do not add timers, energy or extra currencies merely because a
reference game has them.

## Reproduce

```sh
make CFLAGS="-O2 -g -Werror"
make test
python3 tools/economy_audit.py
./build/relic-rush --headless --fresh --mute --size 480x900 --smoke
./build/relic-rush --headless --fresh --mute --size 390x844 --safe-area 0,47,0,34 --smoke
./build/nile-archive --headless --fresh --mute --size 1200x900 --smoke
./build/nile-archive --headless --fresh --mute --size 1600x900 --smoke
```

On Linux run renderer commands under Xvfb with `LIBGL_ALWAYS_SOFTWARE=1`.
The audit uses existing dependencies and isolated test saves. All additional
local work is small source, JSON and review captures; no model, environment or
large dependency installation is needed.

Review galleries:
[Relic Rush](../games/relic-rush/docs/review/economy/README.md),
[Nile Archive](../games/nile-archive/docs/review/economy/README.md).
