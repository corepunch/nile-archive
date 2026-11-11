# Chapter 31: The Shabby Abbey

[Story index](../STORY.md) · [Previous](chapter-30.md) · [Next](chapter-32.md)

Campaign levels **1131–1170**; starts with `chp31_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The honeymoon party restores the dilapidated abbey, and the Duchess knights Ava. The group discovers Angus McYowler in a peerage book and invites him to visit the Duchess.

## chp31_q1: Homecoming

Configured quest `level` **1131**; assigned character **Elsie**.

Setup (localized quest text): “Catton Abbey is in terrible shape. We've got to start cleaning things up, Chief!”

Journal outcome (localized quest text): “Elsie here! Blacktail and I arrived at Catton Abbey for our honeymoon, but the place was a shambles. Poor Duchess! We cleaned things up pretty well, but we needed Ava's help to repair the Abbey.”

Configured scenes: `chp31_q1` (quest_start: chp31_q1); `t1chp31_q1` (quest_task_completed: chp31_q1.1); `t2chp31_q1` (quest_task_completed: chp31_q1.2); `t3chp31_q1` (quest_task_completed: chp31_q1.3); `t4chp31_q1` (quest_task_completed: chp31_q1.4); `ftchp31_q1` (claim_button_tapped: chp31_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp31_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 4 | `1131a,1132b,1133c,1134b` | `ch31_rubble` |
| `chp31_q1.2` | Drink tea with the Duchess | `collect_and_interact`; `porcelain_cup` × 4 | `1135c,1136a,1137c,1138a` | `none` |
| `chp31_q1.3` | Examine the Abbey | `collect_and_interact`; `magn_glass` × 1 | `1139b` | `none` |
| `chp31_q1.4` | Prepare the master suite | `collect_and_interact`; `log` × 1 | `1140c` | `none` |

## chp31_q2: Catton Abbey Reborn

Configured quest `level` **1141**; assigned character **Elsie**.

Setup (localized quest text): “Now that Ava's here, we can really get the Abbey back into shape, Chief!”

Journal outcome (localized quest text): “Ava and the Chief pulled out all the stops. Catton Abbey looked greater than ever before, and the Duchess couldn't have been happier. She was feeling pretty overwhelmed at her first taste of what it means to be a Tropicat!”

Configured scenes: `chp31_q2` (quest_start: chp31_q2); `t1chp31_q2` (quest_task_completed: chp31_q2.1); `t2chp31_q2` (quest_task_completed: chp31_q2.2); `t3chp31_q2` (quest_task_completed: chp31_q2.3); `t4chp31_q2` (quest_task_completed: chp31_q2.4); `ftchp31_q2` (claim_button_tapped: chp31_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp31_q2.1` | Renovate Catton Abbey | `collect_and_repair`; `log` × 3 | `1141a,1142c,1143b` | `ch31_catton_abbey` |
| `chp31_q2.2` | Let Ava show off a little | `collect_and_repair`; `tracks_1` × 3 | `1144a` | `none` |
| `chp31_q2.3` | Find Catton Abbey's ledgers | `collect_and_interact`; `scrapbook` × 2 | `1145c,1146b,1147c` | `none` |
| `chp31_q2.4` | Visit Blacktail's old room | `collect_and_interact`; `magn_glass` × 2 | `1148c,1149b,1150a` | `none` |
| `chp31_q2.5` | Reach Village Rank 58 | `reach_rank`; `harmony` × 58 | `none` | `none` |

## chp31_q3: The Legend Of Ava

Configured quest `level` **1151**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess has a big surprise for Ava. She's going to be knighted! But first, we need to prepare the ceremony.”

Journal outcome (localized quest text): “Chief found the Rite of Knighthood, and with Blacktail's sword, Ava was knighted by the Duchess for her services to the realm! She was pretty surprised, let me tell you. But "Dame Ava" suits her pretty well, I think.”

Configured scenes: `chp31_q3` (quest_start: chp31_q3); `t1chp31_q3` (quest_task_completed: chp31_q3.1); `t2chp31_q3` (quest_task_completed: chp31_q3.2); `t3chp31_q3` (quest_task_completed: chp31_q3.3); `t4chp31_q3` (quest_task_completed: chp31_q3.4); `ftchp31_q3` (claim_button_tapped: chp31_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp31_q3.1` | Find the Rite of Knighthood | `collect_and_interact`; `page` × 2 | `1151b,1152c` | `none` |
| `chp31_q3.2` | Find medals of the Impurrial Order | `collect_and_interact`; `medal` × 3 | `1153a,1154c,1155b` | `none` |
| `chp31_q3.3` | Get a dubbing sword | `collect_and_interact`; `sword` × 1 | `1156c` | `none` |
| `chp31_q3.4` | Find a character witness for Ava | `collect_and_interact`; `spyglass` × 3 | `1157b,1158b,1159a,1160c` | `none` |

## chp31_q4: Of Duchesses And Toms

Configured quest `level` **1161**; assigned character **Elsie**.

Setup (localized quest text): “There's only one way to make sure Catton Abbey is taken care of, Chief. The Duchess can't do it alone - she needs a rich suitor!”

Journal outcome (localized quest text): “The Duchess, Ava, and me had a lot of fun looking through the Book of Impurrial Peerage. Only one cat caught the Duchess's eye, though. Angus McYowler. It was a long shot, but we invited him to Catton Abbey to meet the Duchess again.”

Configured scenes: `chp31_q4` (quest_start: chp31_q4); `t1chp31_q4` (quest_task_completed: chp31_q4.1); `t2chp31_q4` (quest_task_completed: chp31_q4.2); `t3chp31_q4` (quest_task_completed: chp31_q4.3); `t4chp31_q4` (quest_task_completed: chp31_q4.4); `ftchp31_q4` (claim_button_tapped: chp31_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp31_q4.1` | Search the Book of Impurrial Peerage | `collect_and_interact`; `BookNordog` × 3 | `1161a,1162c,1163a` | `none` |
| `chp31_q4.2` | Reward Elsie | `collect_and_repair`; `elsie_makeup` × 2 | `1164c,1165b` | `none` |
| `chp31_q4.3` | Break the news to Blacktail | `collect_and_repair`; `RedLetter` × 3 | `1166a,1167c,1168b` | `none` |
| `chp31_q4.4` | Advise the Duchess on love | `collect_and_interact`; `bouquet` × 2 | `1169a,1170c` | `none` |
| `chp31_q4.5` | Reach Village Rank 59 | `reach_rank`; `harmony` × 59 | `none` | `none` |

