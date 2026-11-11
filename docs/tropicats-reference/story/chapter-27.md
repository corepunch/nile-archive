# Chapter 27: The Mother's Truth

[Story index](../STORY.md) · [Previous](chapter-26.md) · [Next](chapter-28.md)

Campaign levels **971–1010**; starts with `chp27_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The Mother is Sylvia, Taka's mother, who offers an account of the missing parents. A mysterious cat and Elder Alapa give competing information about Sylvia and the parents, leaving their fate uncertain.

## chp27_q1: The Mother's Truth

Configured quest `level` **971**; assigned character **Elsie**.

Setup (localized quest text): “We landed on the Island of the Ancients, but there's no sign of the Mother. If we rebuild her runestone, maybe she'll show up!”

Journal outcome (localized quest text): “We found out the Mother of the Isles is really Sylvia, Taka's mom! But does that mean all of our parents are alive? The elder told us they died in a flood long ago.”

Configured scenes: `chp27_q1` (quest_start: chp27_q1); `t1chp27_q1` (quest_task_completed: chp27_q1.1); `t2chp27_q1` (quest_task_completed: chp27_q1.2); `t3chp27_q1` (quest_task_completed: chp27_q1.3); `t4chp27_q1` (quest_task_completed: chp27_q1.4); `ftchp27_q1` (claim_button_tapped: chp27_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp27_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 3 | `971b,972a,973b` | `ch27_rubble` |
| `chp27_q1.2` | Examine the broken statue | `collect_and_interact`; `magn_glass` × 3 | `974c,975a,976c` | `none` |
| `chp27_q1.3` | Read the Mother's diary fragment | `collect_and_interact`; `book` × 1 | `977b` | `none` |
| `chp27_q1.4` | Repair the runestone | `collect_and_repair`; `stone` × 2 | `978c,979a,980c` | `ch27_magical_stone_meowgic` |

## chp27_q2: The Return Of Kata

Configured quest `level` **981**; assigned character **Elsie**.

Setup (localized quest text): “Sylvia says she'll tell us why she started the war between the Nordogs and Impurrials. But first, she wants us to repair her husband's statue in time for her wedding anniversary.”

Journal outcome (localized quest text): “Sylvia told us the truth about our parents: An Impurrial ship kitnapped them for refusing to trade. They’re still alive but imprisoned in Impurrial City! Blacktail has traveled with Sylvia to meet his mother, the Duchess. Hopefully with the Duchess's help, he can free our parents.”

Configured scenes: `chp27_q2` (quest_start: chp27_q2); `t1chp27_q2` (quest_task_completed: chp27_q2.1); `t2chp27_q2` (quest_task_completed: chp27_q2.2); `t3chp27_q2` (quest_task_completed: chp27_q2.3); `t4chp27_q2` (quest_task_completed: chp27_q2.4); `ftchp27_q2` (claim_button_tapped: chp27_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp27_q2.1` | Repair the statue of Taka's dad | `collect_and_repair`; `log` × 4 | `981a,982c,983b,984c` | `ch27_taka_temple_meowgic` |
| `chp27_q2.2` | Help Sylvia make dinner | `collect_and_interact`; `coconut` × 3 | `985b,986c,987b` | `none` |
| `chp27_q2.3` | Find Blacktail a gift for Elsie | `collect_and_interact`; `default` × 1 | `988b` | `none` |
| `chp27_q2.4` | Speak to Taka about his dad | `collect_and_interact`; `magn_glass` × 2 | `989c,990a` | `none` |
| `chp27_q2.5` | Reach Village Rank 50 | `reach_rank`; `harmony` × 50 | `none` | `none` |

## chp27_q3: The Family Reunion

Configured quest `level` **991**; assigned character **Elsie**.

Setup (localized quest text): “Our parents are finally coming home! We've got to prepare a real Tropicat welcome.”

Journal outcome (localized quest text): “Blacktail and Sylvia sailed to the Duchess's ship to try to negotiate our parents' release. Meanwhile, Chief was approached by a mysterious jungle cat who said Sylvia can't be trusted. The cat advised us to talk to Elder Alapa. Who is telling the truth? We'd better head to Tropicat Island!”

Configured scenes: `chp27_q3` (quest_start: chp27_q3); `t1chp27_q3` (quest_task_completed: chp27_q3.1); `t2chp27_q3` (quest_task_completed: chp27_q3.2); `t3chp27_q3` (quest_task_completed: chp27_q3.3); `t4chp27_q3` (quest_task_completed: chp27_q3.4); `ftchp27_q3` (claim_button_tapped: chp27_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp27_q3.1` | Fix Blacktail's sails | `collect_and_interact`; `fabric` × 1 | `991b` | `none` |
| `chp27_q3.2` | Hide Cubby's snacks | `collect_and_interact`; `grilled_banana` × 4 | `992a,993c,994a,995b` | `none` |
| `chp27_q3.3` | Help Elsie practice her singing | `collect_and_interact`; `ukulele` × 1 | `996c` | `none` |
| `chp27_q3.4` | Follow the mysterious tracks | `collect_and_interact`; `tracks_2` × 4 | `997b,998c,999b,1000c` | `none` |

## chp27_q4: Secrets Of The Elder

Configured quest `level` **1001**; assigned character **Elsie**.

Setup (localized quest text): “We arrived on Tropicat Island to ask Elder Alapa about Sylvia. Here's hoping he gives us straight answers!”

Journal outcome (localized quest text): “According to the elder, Taka’s dad drowned trying to rescue a sinking Impurrial ship. Sylvia became mad with grief and fled to the Island of the Ancients. Our parents went after her... but they never returned. Sylvia is just out for revenge against the Impurrials. And who knows where our parents really are...”

Configured scenes: `chp27_q4` (quest_start: chp27_q4); `t1chp27_q4` (quest_task_completed: chp27_q4.1); `t2chp27_q4` (quest_task_completed: chp27_q4.2); `t3chp27_q4` (quest_task_completed: chp27_q4.3); `t4chp27_q4` (quest_task_completed: chp27_q4.4); `ftchp27_q4` (claim_button_tapped: chp27_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp27_q4.1` | Search the sunken ship | `collect_and_interact`; `magn_glass` × 2 | `1001b,1002c,1003b` | `none` |
| `chp27_q4.2` | Search Alapa's lockbox | `collect_and_interact`; `lockbox` × 3 | `1004a` | `none` |
| `chp27_q4.3` | Spy on Alapa | `collect_and_interact`; `spyglass` × 2 | `1005c,1006b,1007c` | `none` |
| `chp27_q4.4` | Give Alapa catnip | `collect_and_interact`; `herb` × 3 | `1008a,1009c,1010b` | `none` |
| `chp27_q4.5` | Reach Village Rank 51 | `reach_rank`; `harmony` × 51 | `none` | `none` |

