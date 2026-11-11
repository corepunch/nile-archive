# Chapter 61

[Story index](../STORY.md) · [Previous](chapter-60.md) · [Next](chapter-62.md)

Configured chapter start: campaign level **2331**; starts with `chp61_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Lily melts the ice to end the match, angering Sylvia. As Lily studies crystals, news arrives of Blacktail's capture, and the children investigate how the crystals could help rescue him.

## chp61_q1: No Winners, No Losers

Configured quest `level` **2331**; assigned character **Elsie**.

Setup (localized quest text): “Lily has an idea to finally end this match. Help her out, Chief?”

Journal outcome (localized quest text): “I didn't think that stupid hockey match would ever end, but Lily used one of Taka's spells to melt the ice. Pretty cool, huh? Ms. Sylvia was so mad I thought she was going to melt!”

Configured scenes: `chp61_q1` (quest_start: chp61_q1); `t1chp61_q1` (quest_task_completed: chp61_q1.1); `t2chp61_q1` (quest_task_completed: chp61_q1.2); `t3chp61_q1` (quest_task_completed: chp61_q1.3); `t4chp61_q1` (quest_task_completed: chp61_q1.4); `ftchp61_q1` (claim_button_tapped: chp61_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp61_q1.1` | Find some fire | `collect_and_interact`; `lantern` × 4 | `2331a,2332b,2333c,2334a` | `none` |
| `chp61_q1.2` | Find a hot pepper | `collect_and_interact`; `chili` × 4 | `2335c,2336b,2337a,2338c` | `none` |
| `chp61_q1.3` | Find a pan | `collect_and_interact`; `pan` × 1 | `2339b` | `none` |
| `chp61_q1.4` | Find one more hot ingredient | `collect_and_interact`; `jesterstick` × 1 | `2340c` | `none` |

## chp61_q2: Winter's End

Configured quest `level` **2341**; assigned character **Elsie**.

Setup (localized quest text): “Lily wants to help Ms. Sylvia with some cool new meowgic. Let's help them out!”

Journal outcome (localized quest text): “Lily started learning about these weird meowgic crystals with Ms. Sylvia... but I think she is better at using them than Ms. Sylvia. I bet that made her really mad, deep down!”

Configured scenes: `chp61_q2` (quest_start: chp61_q2); `t1chp61_q2` (quest_task_completed: chp61_q2.1); `t2chp61_q2` (quest_task_completed: chp61_q2.2); `t3chp61_q2` (quest_task_completed: chp61_q2.3); `t4chp61_q2` (quest_task_completed: chp61_q2.4); `ftchp61_q2` (claim_button_tapped: chp61_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp61_q2.1` | Show Lily how crystals work | `collect_and_interact`; `chalkboard` × 3 | `2341b,2342a,2343c` | `none` |
| `chp61_q2.2` | Learn to use a crystal | `collect_and_interact`; `meowgiccrystal` × 3 | `2344b,2345a,2346c` | `none` |
| `chp61_q2.3` | Receive a letter | `collect_and_interact`; `RedLetter` × 2 | `2347b,2348c` | `none` |
| `chp61_q2.4` | Grow something pretty | `collect_and_repair`; `bouquet` × 2 | `2349a,2350c` | `ch61_lily_flowers` |
| `chp61_q2.5` | Reach Village Rank 118 | `reach_rank`; `harmony` × 118 | `none` | `none` |

## chp61_q3: Potential Energy

Configured quest `level` **2351**; assigned character **Elsie**.

Setup (localized quest text): “Lily thinks she can do even more with the meowgic crystals. Let's help her out!”

Journal outcome (localized quest text): “While Lily was using crystals to make beautiful things in the snow, Ms. Sylvia got a letter from Elsie. Blacktail was kitnapped by the Impurrial Queen! We have to do something, Chief!”

Configured scenes: `chp61_q3` (quest_start: chp61_q3); `t1chp61_q3` (quest_task_completed: chp61_q3.1); `t2chp61_q3` (quest_task_completed: chp61_q3.2); `t3chp61_q3` (quest_task_completed: chp61_q3.3); `t4chp61_q3` (quest_task_completed: chp61_q3.4); `ftchp61_q3` (claim_button_tapped: chp61_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp61_q3.1` | Make something beautiful | `collect_and_repair`; `meowgiccrystal` × 2 | `2351c,2352a` | `ch61_greenhouse_main` |
| `chp61_q3.2` | Study the crystals | `collect_and_interact`; `magn_glass` × 3 | `2353c,2354b,2355c` | `none` |
| `chp61_q3.3` | Talk with Ragnaruff | `collect_and_interact`; `SnowPrint` × 2 | `2356b,2357b` | `none` |
| `chp61_q3.4` | Spy on Sylvia | `collect_and_interact`; `spyglass` × 3 | `2358a,2359b,2360c` | `none` |

## chp61_q4: Forming A Plan

Configured quest `level` **2361**; assigned character **Elsie**.

Setup (localized quest text): “Sylvia says we can use the meowgic crystals to save Blacktail! Let's figure them out, Chief.”

Journal outcome (localized quest text): “Redd and I helped Lily learn more about those weird meowgic crystals. If she was going to save Blacktail, we had to do all we could! Besides, maybe it meant we could leave the island...”

Configured scenes: `chp61_q4` (quest_start: chp61_q4); `t1chp61_q4` (quest_task_completed: chp61_q4.1); `t2chp61_q4` (quest_task_completed: chp61_q4.2); `t3chp61_q4` (quest_task_completed: chp61_q4.3); `t4chp61_q4` (quest_task_completed: chp61_q4.4); `ftchp61_q4` (claim_button_tapped: chp61_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp61_q4.1` | Bring beauty to Nordog Island | `collect_and_repair`; `meowgiccrystal` × 3 | `2361c,2362b,2363c` | `ch61_greenhouse_lily` |
| `chp61_q4.2` | Study crystals in the library | `collect_and_interact`; `scrapbook` × 2 | `2364a,2365b` | `none` |
| `chp61_q4.3` | Get some help | `collect_and_interact`; `SnowPrint` × 3 | `2366a,2367b,2368c` | `none` |
| `chp61_q4.4` | Recruit Ragnaruff | `collect_and_interact`; `magn_glass` × 2 | `2369b,2370c` | `none` |
| `chp61_q4.5` | Reach Village Rank 119 | `reach_rank`; `harmony` × 119 | `none` | `none` |

