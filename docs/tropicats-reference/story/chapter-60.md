# Chapter 60: Cats Rule, Dogs Drool

[Story index](../STORY.md) · [Previous](chapter-59.md) · [Next](chapter-61.md)

Campaign levels **2291–2330**; starts with `chp60_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Flyers attract Nordog visitors to the hockey match, and another Taka arrives. The cat–dog contest finally takes place, but neither side proves decisive.

## chp60_q1: The Big Event

Configured quest `level` **2291**; assigned character **Elsie**.

Setup (localized quest text): “Everyone wants the big hockey match to be a success! Help us get the word out, Chief.”

Journal outcome (localized quest text): “We had to tell everyone about the big match to determine whether dogs or cats were better, so we sent flyers all over the Pawcific. My school is pretty cool!”

Configured scenes: `chp60_q1` (quest_start: chp60_q1); `t1chp60_q1` (quest_task_completed: chp60_q1.1); `t2chp60_q1` (quest_task_completed: chp60_q1.2); `t3chp60_q1` (quest_task_completed: chp60_q1.3); `t4chp60_q1` (quest_task_completed: chp60_q1.4); `ftchp60_q1` (claim_button_tapped: chp60_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp60_q1.1` | Make some flyers | `collect_and_interact`; `page` × 3 | `2291b,2292c,2293b` | `none` |
| `chp60_q1.2` | Settle the messenger pigeons | `collect_and_interact`; `rattle` × 2 | `2294a,2295b` | `none` |
| `chp60_q1.3` | Send word to the Nordogs | `collect_and_interact`; `RedLetter` × 2 | `2296c,2297b` | `none` |
| `chp60_q1.4` | Try to contact the Tropicats | `collect_and_interact`; `BlueLetter` × 3 | `2298a,2299b,2300c` | `none` |

## chp60_q2: Taka Taka

Configured quest `level` **2301**; assigned character **Elsie**.

Setup (localized quest text): “It's time to get to know this other Taka. What's his deal, Chief?”

Journal outcome (localized quest text): “Hey, Chief, it's me, Taka! I met this other Taka... he is just the coolest cat I've ever met. Apparently, there are even more Tropicats to meet, and I can't wait to meet 'em!”

Configured scenes: `chp60_q2` (quest_start: chp60_q2); `t1chp60_q2` (quest_task_completed: chp60_q2.1); `t2chp60_q2` (quest_task_completed: chp60_q2.2); `t3chp60_q2` (quest_task_completed: chp60_q2.3); `t4chp60_q2` (quest_task_completed: chp60_q2.4); `ftchp60_q2` (claim_button_tapped: chp60_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp60_q2.1` | Ask Taka about the other Tropicats | `collect_and_interact`; `magn_glass` × 1 | `2301c` | `none` |
| `chp60_q2.2` | Receive a letter | `collect_and_interact`; `RedLetter` × 3 | `2302b,2303c,2304a` | `none` |
| `chp60_q2.3` | Tell Taka about our adventures | `collect_and_interact`; `fancyscroll` × 5 | `2305b,2306a,2307b,2308c,2309a` | `none` |
| `chp60_q2.4` | Introduce yourself | `collect_and_interact`; `jesterstick` × 1 | `2310c` | `none` |
| `chp60_q2.5` | Reach Village Rank 116 | `reach_rank`; `harmony` × 116 | `none` | `none` |

## chp60_q3: Tourist Season

Configured quest `level` **2311**; assigned character **Elsie**.

Setup (localized quest text): “The Nordogs have arrived... and they're pretty demanding. Let's get them settled, Chief!”

Journal outcome (localized quest text): “Hey, Chief, it's Kip again! Our school's been invaded... by Nordogs! I guess all those flyers really helped. Everyone is pretty excited for the big match, especially me. GO DEAN GRUFFGAR!”

Configured scenes: `chp60_q3` (quest_start: chp60_q3); `t1chp60_q3` (quest_task_completed: chp60_q3.1); `t2chp60_q3` (quest_task_completed: chp60_q3.2); `t3chp60_q3` (quest_task_completed: chp60_q3.3); `t4chp60_q3` (quest_task_completed: chp60_q3.4); `ftchp60_q3` (claim_button_tapped: chp60_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp60_q3.1` | Build some stands | `collect_and_repair`; `log` × 1 | `2311c` | `ch60_hockey_stands` |
| `chp60_q3.2` | Build up the hockey rink area | `collect_and_repair`; `stone` × 3 | `2312b,2313b,2314a` | `ch60_hockey_paths` |
| `chp60_q3.3` | Make some new friends | `collect_and_interact`; `jesterstick` × 3 | `2315c,2316b,2317c` | `none` |
| `chp60_q3.4` | Deal with unruly dogs | `collect_and_interact`; `newspaper` × 3 | `2318a,2319b,2320c` | `none` |

## chp60_q4: Cats Vs. Dogs

Configured quest `level` **2321**; assigned character **Elsie**.

Setup (localized quest text): “Well, Chief, it's time for the big match at last. Let's see how it all goes!”

Journal outcome (localized quest text): “I thought hockey was supposed to be fun, but both Dean Gruffgar and Ms. Sylvia weren't very good at scoring. Why isn't pooping in the snow a sport? I'd be awesome at it!”

Configured scenes: `chp60_q4` (quest_start: chp60_q4); `t1chp60_q4` (quest_task_completed: chp60_q4.1); `t2chp60_q4` (quest_task_completed: chp60_q4.2); `t3chp60_q4` (quest_task_completed: chp60_q4.3); `t4chp60_q4` (quest_task_completed: chp60_q4.4); `ftchp60_q4` (claim_button_tapped: chp60_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp60_q4.1` | Begin the game | `collect_and_interact`; `megaphone` × 3 | `2321b,2322a,2323b` | `none` |
| `chp60_q4.2` | Watch the first period | `collect_and_interact`; `skates` × 2 | `2324c,2325b` | `none` |
| `chp60_q4.3` | Watch the second period | `collect_and_interact`; `spyglass` × 3 | `2326c,2327a,2328c` | `none` |
| `chp60_q4.4` | Watch the final period | `collect_and_interact`; `megaphone` × 2 | `2329b,2330c` | `none` |
| `chp60_q4.5` | Reach Village Rank 117 | `reach_rank`; `harmony` × 117 | `none` | `none` |

