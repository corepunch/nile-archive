# Chapter 3

[Story index](../STORY.md) · [Previous](chapter-02.md) · [Next](chapter-04.md)

Configured chapter start: campaign level **11**; starts with `chp3_q1`. Task gates below are level/tier tokens, not guaranteed play order.

The search leads to guard Cubby, whose breakfast and investigation require work on the grill. A witness recalls a strange creature; Cubby's hut must be restored before he can retrieve his spear.

## chp3_q1: Finding The Guard

Configured quest `level` **11**; assigned character **Elsie**.

Setup (localized quest text): “The Great Totem didn’t fall... someone cut it down! Clear this rubble so we can find the village guard.”

Journal outcome (localized quest text): “We cleared some rubble and found Cubby the guard! If anyone can catch this totem-cutter it's... well it's probably not Cubby, but we might as well give him a shot!”

Configured scenes: `chp3_q1` (quest_start: chp3_q1); `t1chp3_q1` (quest_task_completed: chp3_q1.1); `t2chp3_q1` (quest_task_completed: chp3_q1.2); `t3chp3_q1` (quest_task_completed: chp3_q1.3); `t4chp3_q1` (quest_task_completed: chp3_q1.4); `ftchp3_q1` (claim_button_tapped: chp3_q1).

Display order override: `0,1,3,2` (serialized values; task numbering below stays source-array order; runtime display semantics unverified).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp3_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 3 | `11a,12a,13a` | `ch3_rubble` |
| `chp3_q1.2` | Feed Mr. Crabby. | `collect_and_interact`; `fire_ant` × 3 | `14a,15a,17a` | `none` |
| `chp3_q1.3` | Recover the suspicious axe | `collect_and_interact`; `axe` × 1 | `16b` | `none` |
| `chp3_q1.4` | Find the guard's tracks | `collect_and_interact`; `tracks_1` × 3 | `18a,19a,20a` | `none` |

## chp3_q2: The Guard's Breakfast

Configured quest `level` **21**; assigned character **Elsie**.

Setup (localized quest text): “Cubby needs to eat his breakfast before he starts guard duty. Fix the fruit grill so he can cook some bananas.”

Journal outcome (localized quest text): “Cubby needed breakfast before starting guard duty... typical! Chief fixed the fruit grill and Cubby packed-in enough calories to begin his investigation.”

Configured scenes: `chp3_q2` (quest_start: chp3_q2); `t3chp3_q2` (quest_task_completed: chp3_q2.3); `t1chp3_q2` (quest_task_completed: chp3_q2.1); `t2chp3_q2` (quest_task_completed: chp3_q2.2); `t4chp3_q2` (quest_task_completed: chp3_q2.4); `ftchp3_q2` (claim_button_tapped: chp3_q2).

Display order override: `0,2,1,3` (serialized values; task numbering below stays source-array order; runtime display semantics unverified).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp3_q2.1` | Fix the grill's benches | `collect_and_repair`; `bamboo` × 2 | `21a,22a` | `ch3_grill_benches` |
| `chp3_q2.2` | Fix the grill's Tiki table | `collect_and_repair`; `log` × 3 | `26a,27a,28b` | `ch3_grill_table` |
| `chp3_q2.3` | Repair Cubby's fruit grill | `collect_and_repair`; `clay` × 3 | `23a,24a,25a` | `ch3_grill` |
| `chp3_q2.4` | Find Cubby's lost love letters | `collect_and_interact`; `page` × 2 | `29a,30b` | `none` |
| `chp3_q2.5` | Reach Village Rank 2 | `reach_rank`; `harmony` × 2 | `none` | `none` |

## chp3_q3: The Investigation!

Configured quest `level` **31**; assigned character **Cubby**.

Setup (localized quest text): “Cubby declared the beach a crime scene! Help him investigate who cut down our Great Totem.”

Journal outcome (localized quest text): “Cubby says a strange creature was on the beach the night the Great Totem fell. My bro Kip spotted it. Was this creature real, or just a kitten’s nightmare?”

Configured scenes: `chp3_q3` (quest_start: chp3_q3); `t1chp3_q3` (quest_task_completed: chp3_q3.1); `t2chp3_q3` (quest_task_completed: chp3_q3.2); `t3chp3_q3` (quest_task_completed: chp3_q3.3); `t4chp3_q3` (quest_task_completed: chp3_q3.4); `t5chp3_q3` (quest_task_completed: chp3_q3.5); `ftchp3_q3` (claim_button_tapped: chp3_q3).

Localization override: `v1`; action labels below use matching overridden keys when present.

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp3_q3.1` | Inspect the Great Totem | `collect_and_interact`; `magn_glass` × 2 | `31a,32b` | `none` |
| `chp3_q3.2` | Question suspect No.1 | `collect_and_interact`; `tracks_1` × 3 | `33a,34a,35b` | `none` |
| `chp3_q3.3` | Question suspect No.2 | `collect_and_interact`; `tracks_2` × 3 | `36a,37c,38a` | `none` |
| `chp3_q3.4` | Examine stolen grilled bananas | `collect_and_interact`; `grilled_banana` × 2 | `39a,40b` | `none` |

## chp3_q4: Get To The Point

Configured quest `level` **41**; assigned character **Cubby**.

Setup (localized quest text): “Cubby thinks the totem-cutter is some kind of monster... He needs his spear! Repair Cubby’s hut so he can get it.”

Journal outcome (localized quest text): “Cubby couldn't go monster hunting without his spear! {userName} fixed Cubby's hut so he could get the weapon... and a few extra pairs of underwear.”

Configured scenes: `chp3_q4` (quest_start: chp3_q4); `t4chp3_q4` (quest_task_completed: chp3_q4.4); `t1chp3_q4` (quest_task_completed: chp3_q4.1); `t2chp3_q4` (quest_task_completed: chp3_q4.2); `t3chp3_q4` (quest_task_completed: chp3_q4.3); `ftchp3_q4` (claim_button_tapped: chp3_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp3_q4.1` | Fix Cubby's surfboard | `collect_and_repair`; `bamboo` × 2 | `41a,42b` | `ch3_cubby_surfboard` |
| `chp3_q4.2` | Restore coral statue | `collect_and_repair`; `shell` × 2 | `43a,44c` | `ch3_cubby_coral` |
| `chp3_q4.3` | Cook second breakfast | `collect_and_interact`; `watermelon` × 2 | `45a,46b` | `none` |
| `chp3_q4.4` | Repair Cubby's hut | `collect_and_repair`; `log` × 4 | `47a,48b,49a,50c` | `ch3_cubby_hut` |
| `chp3_q4.5` | Reach Village Rank 3 | `reach_rank`; `harmony` × 3 | `none` | `none` |

