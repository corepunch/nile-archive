# Chapter 19

[Story index](../STORY.md) · [Previous](chapter-18.md) · [Next](chapter-20.md)

Configured chapter start: campaign level **651**; starts with `chp19_q1`. Task gates below are level/tier tokens, not guaranteed play order.

At Felicity's farm the group builds a farmhouse and finds water while clues about former owner Montclaw suggest something unsettling in the woods. His diary refers to a storm and a shaman as the farm takes shape.

## chp19_q1: Lay Of The Land

Configured quest `level` **651**; assigned character **Elsie**.

Setup (localized quest text): “Ava here! I'll be updating your diary from now on. It's time to get started on Felicity's farm. Let’s clear away the rocks and survey the old buildings.”

Journal outcome (localized quest text): “I gotta write a summary of events here!? Sheesh. Well, we arrived at the island and met Felicity. She's starting a farm with Mee Li, who bought the land supurr cheap. Mee Li seems reluctant to talk about the previous owner of the farm. I wonder why?”

Configured scenes: `chp19_q1` (quest_start: chp19_q1); `t1chp19_q1` (quest_task_completed: chp19_q1.1); `t2chp19_q1` (quest_task_completed: chp19_q1.2); `t3chp19_q1` (quest_task_completed: chp19_q1.3); `t4chp19_q1` (quest_task_completed: chp19_q1.4); `ftchp19_q1` (claim_button_tapped: chp19_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp19_q1.1` | Dig the rocks out of the ground | `collect_and_repair`; `shovel` × 4 | `651a,652b,653c,654b` | `ch19_rubble` |
| `chp19_q1.2` | Survey the land and buildings | `collect_and_interact`; `magn_glass` × 4 | `655c,656a,657c,658a` | `none` |
| `chp19_q1.3` | Find honey for Felicity's cupcakes | `collect_and_interact`; `honey` × 1 | `659b` | `none` |
| `chp19_q1.4` | Collect firewood from the woods | `collect_and_interact`; `log` × 1 | `660c` | `none` |

## chp19_q2: Farmhouse Warming

Configured quest `level` **661**; assigned character **Elsie**.

Setup (localized quest text): “Mornin' Chief, it’s time to build Felicity a farmhouse. Oh and Ragnaruff’s gonna sail a cat over from Tropicat Village. Who’s it gonna be?”

Journal outcome (localized quest text): “We built Felicity a cozy farmhouse and Ragnaruff sailed Elsie here for the housewarming. But both Elsie and Ragnaruff think something’s lurking in the woods. What could it be... is it related to the old farmer, Montclaw?”

Configured scenes: `chp19_q2` (quest_start: chp19_q2); `t1chp19_q2` (quest_task_completed: chp19_q2.1); `t2chp19_q2` (quest_task_completed: chp19_q2.2); `t3chp19_q2` (quest_task_completed: chp19_q2.3); `t4chp19_q2` (quest_task_completed: chp19_q2.4); `ftchp19_q2` (claim_button_tapped: chp19_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp19_q2.1` | Build Felicity's farmhouse | `collect_and_repair`; `log` × 3 | `661a,662c,663b` | `ch19_farmhouse` |
| `chp19_q2.2` | Look for Montclaw's diary | `collect_and_interact`; `book` × 1 | `664a` | `none` |
| `chp19_q2.3` | Plant some daisies | `collect_and_repair`; `seed` × 3 | `665c,666b,667c` | `ch19_flower_daisy` |
| `chp19_q2.4` | Prepare cupcakes for the housewarming | `collect_and_interact`; `honey` × 3 | `668c,669b,670a` | `none` |
| `chp19_q2.5` | Reach Village Rank 34 | `reach_rank`; `harmony` × 34 | `none` | `none` |

## chp19_q3: Running Water

Configured quest `level` **671**; assigned character **Elsie**.

Setup (localized quest text): “Farms need water, Chief. Let's find a water source and make a storage barrel. Oh... and can you keep Kip outta my fur?”

Journal outcome (localized quest text): “We needed a water source for the farm, so Chief and Kip located a stream. But they also discovered bones nearby. Meanwhile, Montclaw's diary mentioned a "rain storm" and that something "evil" was watching the chicken coop.”

Configured scenes: `chp19_q3` (quest_start: chp19_q3); `t1chp19_q3` (quest_task_completed: chp19_q3.1); `t2chp19_q3` (quest_task_completed: chp19_q3.2); `t3chp19_q3` (quest_task_completed: chp19_q3.3); `t4chp19_q3` (quest_task_completed: chp19_q3.4); `ftchp19_q3` (claim_button_tapped: chp19_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp19_q3.1` | Follow the old tracks to the stream | `collect_and_interact`; `tracks_2` × 2 | `671b,672c` | `none` |
| `chp19_q3.2` | Build a water barrel | `collect_and_repair`; `bamboo` × 3 | `673a,674c,675b` | `ch19_barrel_farm` |
| `chp19_q3.3` | Help Kip find the purrfect poop spot | `collect_and_interact`; `magn_glass` × 2 | `676c,677b` | `none` |
| `chp19_q3.4` | Look for pages of Montclaw's diary | `collect_and_interact`; `page` × 3 | `678b,679a,680c` | `none` |

## chp19_q4: Soil 'N Trouble

Configured quest `level` **681**; assigned character **Elsie**.

Setup (localized quest text): “Let’s collect some seeds to test out the soil. Also, Elsie’s looking for holiday gifts for the tribe, can you help her find some?”

Journal outcome (localized quest text): “We planted some marrow seeds around the farm and wished Elsie and Kip a safe trip back to Tropicat Island. Meanwhile, Montclaw's diary suggested he was talking to a shaman. Did the shaman cause the storm?”

Configured scenes: `chp19_q4` (quest_start: chp19_q4); `t1chp19_q4` (quest_task_completed: chp19_q4.1); `t2chp19_q4` (quest_task_completed: chp19_q4.2); `t3chp19_q4` (quest_task_completed: chp19_q4.3); `t4chp19_q4` (quest_task_completed: chp19_q4.4); `ftchp19_q4` (claim_button_tapped: chp19_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp19_q4.1` | Find and plant vegetable seeds | `collect_and_interact`; `seed` × 3 | `681a,682c,683a` | `none` |
| `chp19_q4.2` | Help Elsie find gifts for the tribe | `collect_and_interact`; `default` × 2 | `684c,685b` | `none` |
| `chp19_q4.3` | Investigate the strange sounds in the woods | `collect_and_interact`; `magn_glass` × 3 | `686a,687c,688b` | `none` |
| `chp19_q4.4` | Collect pages of Montclaw's diary | `collect_and_interact`; `page` × 2 | `689a,690c` | `none` |
| `chp19_q4.5` | Reach Village Rank 35 | `reach_rank`; `harmony` × 35 | `none` | `none` |

