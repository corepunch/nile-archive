# Chapter 9

[Story index](../STORY.md) · [Previous](chapter-08.md) · [Next](chapter-10.md)

Configured chapter start: campaign level **251**; starts with `chp9_q1`. Task gates below are level/tier tokens, not guaranteed play order.

The elder predicts Kikuna's return as the cats restore places connected to Kikuna and his brother Tika. When the prophecy fails, the elder's hideout reveals his role in destroying the totem and his plan involving Tika's spirit.

## chp9_q1: The Elder's Prophecy

Configured quest `level` **251**; assigned character **Taka**.

Setup (localized quest text): “Our tribe elder foretold of the ancestors' return. He's living his 9th life in the jungle. Let's find him and ask him for guidance.”

Journal outcome (localized quest text): “We found the elder, who told us ancestor Kikuna, the founder of our village, is returning to the island! When Kikuna appears, he'll reveal who was really behind the destruction of the Great Totem!”

Configured scenes: `chp9_q1` (quest_start: chp9_q1); `t2chp9_q1` (quest_task_completed: chp9_q1.2); `t1chp9_q1` (quest_task_completed: chp9_q1.1); `t3chp9_q1` (quest_task_completed: chp9_q1.3); `t4chp9_q1` (quest_task_completed: chp9_q1.4); `ftchp9_q1` (claim_button_tapped: chp9_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp9_q1.1` | Clear the rubble | `collect_and_repair`; `shovel` × 3 | `251a,252b,253c` | `ch9_rubble` |
| `chp9_q1.2` | Track down the tribe elder | `collect_and_interact`; `tracks_3` × 3 | `254a,255c,256b` | `none` |
| `chp9_q1.3` | Examine the creepy tree | `collect_and_interact`; `magn_glass` × 2 | `257b,258c` | `none` |
| `chp9_q1.4` | Pray to the ancestors | `collect_and_interact`; `incense` × 2 | `259c,260a` | `none` |

## chp9_q2: The Birth Of A Village

Configured quest `level` **261**; assigned character **Taka**.

Setup (localized quest text): “We must restore the island's ancient sites before the Great Kikuna returns. First is the Firepit of a Million Mews, where Kikuna convinced the tribe to build a village!”

Journal outcome (localized quest text): “We restored the firepit where ancestor Kikuna convinced the tribe to build a village. But we discovered Kikuna had a brother, Tika, who believed the tribe should stay WILD!”

Configured scenes: `chp9_q2` (quest_start: chp9_q2); `t1chp9_q2` (quest_task_completed: chp9_q2.1); `t2chp9_q2` (quest_task_completed: chp9_q2.2); `t3chp9_q2` (quest_task_completed: chp9_q2.3); `t4chp9_q2` (quest_task_completed: chp9_q2.4); `ftchp9_q2` (claim_button_tapped: chp9_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp9_q2.1` | Restore the Firepit of a Million Mews | `collect_and_repair`; `log` × 3 | `261a,262b,263a` | `ch9_firepit_pit` |
| `chp9_q2.2` | Raise the flag of Kikuna | `collect_and_repair`; `bamboo` × 2 | `264c,265b` | `ch9_firepit_surrounding` |
| `chp9_q2.3` | Help Kip feed 'Mr. Tree' | `collect_and_interact`; `grilled_banana` × 3 | `266b,267b,268c` | `none` |
| `chp9_q2.4` | Introduce the elder to Ragnaruff | `collect_and_interact`; `herb` × 2 | `269b,270c` | `none` |
| `chp9_q2.5` | Reach Village Rank 14 | `reach_rank`; `harmony` × 14 | `none` | `none` |

## chp9_q3: Village Life Or Wild Life?

Configured quest `level` **271**; assigned character **Ava**.

Setup (localized quest text): “We must restore the Rock of Eternal Hissing, where ancestor Kikuna battled his brother Tika, over whether to stay wild or build a village!”

Journal outcome (localized quest text): “We restored the Rock of Eternal Hissing, where Kikuna fought Tika and stopped him from burning down the village. We then waited for Kikuna's spirit to return, like the elder had promised, but nothing happened. The elder himself had vanished.”

Configured scenes: `chp9_q3` (quest_start: chp9_q3); `t1chp9_q3` (quest_task_completed: chp9_q3.1); `t2chp9_q3` (quest_task_completed: chp9_q3.2); `t3chp9_q3` (quest_task_completed: chp9_q3.3); `t4chp9_q3` (quest_task_completed: chp9_q3.4); `ftchp9_q3` (claim_button_tapped: chp9_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp9_q3.1` | Restore the Rock of Eternal Hissing | `collect_and_repair`; `shovel` × 4 | `271a,272c,273a,274c` | `ch9_rock_hissing` |
| `chp9_q3.2` | Restore the rock's fence | `collect_and_repair`; `stone` × 2 | `275c,276a` | `ch9_rock_surrounding` |
| `chp9_q3.3` | Collect Tika's diary | `collect_and_interact`; `page` × 3 | `277a,278c,279b` | `none` |
| `chp9_q3.4` | Find the Village Scrapbook for Kip | `collect_and_interact`; `scrapbook` × 1 | `280c` | `none` |

## chp9_q4: The Revelation

Configured quest `level` **281**; assigned character **Elsie**.

Setup (localized quest text): “Ancestor Kikuna didn't appear, and the elder has vanished. It's time to get some answers... let's search the elder's hideout and see what he's been up to.”

Journal outcome (localized quest text): “We discovered that the elder was behind the destruction of the Great Totem! He tricked us! The elder is trying to resurrect Tika's spirit, which will destroy the village for good, forcing the tribe to live in the jungle.”

Configured scenes: `chp9_q4` (quest_start: chp9_q4); `t1chp9_q4` (quest_task_completed: chp9_q4.1); `t2chp9_q4` (quest_task_completed: chp9_q4.2); `t3chp9_q4` (quest_task_completed: chp9_q4.3); `t4chp9_q4` (quest_task_completed: chp9_q4.4); `ftchp9_q4` (claim_button_tapped: chp9_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp9_q4.1` | Search the elder's hideout | `collect_and_interact`; `ceramic_bottle` × 3 | `281a,282b,283c` | `none` |
| `chp9_q4.2` | Assemble the elder's diary | `collect_and_interact`; `page` × 2 | `284b,285b` | `none` |
| `chp9_q4.3` | Help Taka examine 'Mr. Tree' | `collect_and_interact`; `magn_glass` × 2 | `286b,287b` | `none` |
| `chp9_q4.4` | Find the Great Totem's blueprints | `collect_and_interact`; `blueprints` × 3 | `288c,289b,290a` | `none` |
| `chp9_q4.5` | Reach Village Rank 15 | `reach_rank`; `harmony` × 15 | `none` | `none` |

