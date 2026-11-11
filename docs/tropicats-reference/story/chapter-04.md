# Chapter 4

[Story index](../STORY.md) · [Previous](chapter-03.md) · [Next](chapter-05.md)

Configured chapter start: campaign level **51**; starts with `chp4_q1`. Task gates below are level/tier tokens, not guaranteed play order.

The search for tracks brings in wildlife expert Olivia. Her damaged encyclopedia identifies a dog, alarming the tribe; gathering medicine from the herb market calms her and directs them to the shaman.

## chp4_q1: To Catch A "Monster"

Configured quest `level` **51**; assigned character **Elsie**.

Setup (localized quest text): “Cubby’s got his spear. It’s time to hunt down this totem-cutting monster. Search for its tracks in the jungle.”

Journal outcome (localized quest text): “Chief and Cubby went looking for suspicious tracks in the jungle. They found paw prints belonging to a foreign animal no one could identify... purrplexing.”

Configured scenes: `chp4_q1` (quest_start: chp4_q1); `t1chp4_q1` (quest_task_completed: chp4_q1.1); `t2chp4_q1` (quest_task_completed: chp4_q1.2); `t3chp4_q1` (quest_task_completed: chp4_q1.3); `t4chp4_q1` (quest_task_completed: chp4_q1.4); `ftchp4_q1` (claim_button_tapped: chp4_q1).

Display order override: `2,0,1,3` (serialized values; task numbering below stays source-array order; runtime display semantics unverified).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp4_q1.1` | Take a brunch break | `collect_and_interact`; `honey` × 2 | `54a,55c` | `none` |
| `chp4_q1.2` | Help Cubby woo Ava | `collect_and_interact`; `bouquet` × 3 | `56a,57b,58a` | `none` |
| `chp4_q1.3` | Examine the strange animal tracks | `collect_and_interact`; `tracks_1` × 3 | `51a,52b,53c` | `none` |
| `chp4_q1.4` | Help Elsie groom Cubby | `collect_and_interact`; `grooming_brush` × 2 | `59b,60c` | `none` |

## chp4_q2: The Wildlife Expert

Configured quest `level` **61**; assigned character **Olivia**.

Setup (localized quest text): “Olivia needs her wildlife encyclopedia to identify the "monster" tracks. Repair her study so she can recover the book.”

Journal outcome (localized quest text): “To identify the tracks, Olivia - our wildlife expert - needed her encyclopedia. It was written by the ancestors long ago. Chief recovered the book... but pages were torn out...”

Configured scenes: `chp4_q2` (quest_start: chp4_q2); `t1chp4_q2` (quest_task_completed: chp4_q2.1); `t2chp4_q2` (quest_task_completed: chp4_q2.2); `t3chp4_q2` (quest_task_completed: chp4_q2.3); `ftchp4_q2` (claim_button_tapped: chp4_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp4_q2.1` | Replant Olivia's flower patch | `collect_and_repair`; `red_seed` × 2 | `61a,62c` | `ch4_olivia_place` |
| `chp4_q2.2` | Plant Olivia's favorite shady tree | `collect_and_repair`; `seed` × 3 | `63a,64a,65c` | `ch4_olivia_tree` |
| `chp4_q2.3` | Repair Olivia's wildlife study | `collect_and_repair`; `log` × 5 | `66a,67b,68a,69a,70b` | `ch4_olivia_hut` |
| `chp4_q2.4` | Reach Village Rank 4 | `reach_rank`; `harmony` × 4 | `none` | `none` |

## chp4_q3: The Book Thief!

Configured quest `level` **71**; assigned character **Elsie**.

Setup (localized quest text): “Pages are missing from the wildlife encyclopedia... whoever cut down the totem doesn’t wanna be identified! Let’s piece together that book!”

Journal outcome (localized quest text): “We found the missing pages. The animal that cut down our totem is a dog: A horrifying creature, according to our ancestors, that HATES cats!”

Configured scenes: `chp4_q3` (quest_start: chp4_q3); `t1chp4_q3` (quest_task_completed: chp4_q3.1); `t2chp4_q3` (quest_task_completed: chp4_q3.2); `t3chp4_q3` (quest_task_completed: chp4_q3.3); `t4chp4_q3` (quest_task_completed: chp4_q3.4); `ftchp4_q3` (claim_button_tapped: chp4_q3).

Localization override: `v1`; action labels below use matching overridden keys when present.

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp4_q3.1` | Feed Mr. Crabby | `collect_and_interact`; `fire_ant` × 2 | `71a,72b` | `none` |
| `chp4_q3.2` | Find herbs for Kip's runny nose | `collect_and_interact`; `herb` × 2 | `73a,74b` | `none` |
| `chp4_q3.3` | Help Olivia woo Cubby | `collect_and_interact`; `watermelon` × 3 | `75c,76a,77b` | `none` |
| `chp4_q3.4` | Assemble the wildlife encyclopedia | `collect_and_interact`; `page` × 3 | `78a,79b,80c` | `none` |

## chp4_q4: Keep Calm And Take Catnip!

Configured quest `level` **81**; assigned character **Elsie**.

Setup (localized quest text): “Olivia’s having a panic attack! Fix the herb market so she can get her catnip medicine.”

Journal outcome (localized quest text): “The discovery of the dog sent jittery Olivia into a panic. We gathered catnip from the herb market to calm her nerves... and decided to seek-out the shaman for help.”

Configured scenes: `chp4_q4` (quest_start: chp4_q4); `t1chp4_q4` (quest_task_completed: chp4_q4.1); `t2chp4_q4` (quest_task_completed: chp4_q4.2); `t3chp4_q4` (quest_task_completed: chp4_q4.3); `t4chp4_q4` (quest_task_completed: chp4_q4.4); `ftchp4_q4` (claim_button_tapped: chp4_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp4_q4.1` | Repair the herb market wheelbarrow | `collect_and_repair`; `bamboo` × 2 | `81a,82c` | `ch4_flowermarket_barrow` |
| `chp4_q4.2` | Replant flowerbed | `collect_and_repair`; `seed` × 2 | `83a,84b` | `ch4_flowermarket_place` |
| `chp4_q4.3` | Grill some lunch | `collect_and_interact`; `honey` × 1 | `85b` | `none` |
| `chp4_q4.4` | Repair the herb market | `collect_and_repair`; `log` × 5 | `86a,87b,88a,89b,90c` | `ch4_flowermarket` |
| `chp4_q4.5` | Reach Village Rank 5 | `reach_rank`; `harmony` × 5 | `none` | `none` |

