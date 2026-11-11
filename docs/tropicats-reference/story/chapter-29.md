# Chapter 29: Trouble In Paradise

[Story index](../STORY.md) · [Previous](chapter-28.md) · [Next](chapter-30.md)

Campaign levels **1051–1090**; starts with `chp29_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Wedding preparations are interrupted by Blacktail's suspicious absence and a search. Elsie and Blacktail marry and leave for Catton Abbey, asking the others to keep looking for their parents.

## chp29_q1: The Big Wedding

Configured quest `level` **1051**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess finally gave Elsie and Blacktail her blessing! We'd better get everything prepared, starting with Elsie's wedding dress!”

Journal outcome (localized quest text): “We started getting ready for Elsie's big day, thanks to the Duchess's blessing. Wedding planning was in full swing, and we started ordering the things we needed to make Elsie's day extra special. But her wedding dress didn't look so good...”

Configured scenes: `chp29_q1` (quest_start: chp29_q1); `t1chp29_q1` (quest_task_completed: chp29_q1.1); `t2chp29_q1` (quest_task_completed: chp29_q1.2); `t3chp29_q1` (quest_task_completed: chp29_q1.3); `t4chp29_q1` (quest_task_completed: chp29_q1.4); `ftchp29_q1` (claim_button_tapped: chp29_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp29_q1.1` | Order a dress | `collect_and_interact`; `BlueLetter` × 4 | `1051c,1052b,1053a,1054c` | `none` |
| `chp29_q1.2` | Order a wedding cake | `collect_and_interact`; `cake` × 4 | `1055a,1056c,1057b` | `none` |
| `chp29_q1.3` | Send out invitations | `collect_and_interact`; `RedLetter` × 1 | `1058c` | `none` |
| `chp29_q1.4` | Find a wedding spot | `collect_and_interact`; `magn_glass` × 1 | `1059a,1060c` | `none` |

## chp29_q2: The Wedding Site

Configured quest `level` **1061**; assigned character **Elsie**.

Setup (localized quest text): “Elsie and Blacktail can't get married without a place that means something. Taka found one - let's get it rebuilt and get this wedding going!”

Journal outcome (localized quest text): “We rebuilt the ceremonial shrine in preparation for Elsie and Blacktail's wedding. But Blacktail was acting suspiciously, spending a lot of time with Mee Li, and then he disappeared. What was wrong with that cat?”

Configured scenes: `chp29_q2` (quest_start: chp29_q2); `t1chp29_q2` (quest_task_completed: chp29_q2.1); `t2chp29_q2` (quest_task_completed: chp29_q2.2); `t3chp29_q2` (quest_task_completed: chp29_q2.3); `t4chp29_q2` (quest_task_completed: chp29_q2.4); `ftchp29_q2` (claim_button_tapped: chp29_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp29_q2.1` | Rebuild the ceremonial site | `collect_and_repair`; `log` × 3 | `1061c,1062a,1063b` | `ch29_totem_site_meowgic` |
| `chp29_q2.2` | Plant some flowers | `collect_and_repair`; `bouquet` × 3 | `1064c,1065a,1066c` | `ch29_totemsite_flowers` |
| `chp29_q2.3` | Party with Blacktail and Mee Li | `collect_and_interact`; `spyglass` × 2 | `1067b,1068a` | `none` |
| `chp29_q2.4` | Get ready for rehearsal | `collect_and_interact`; `golden_ring` × 2 | `1069c,1070b` | `none` |
| `chp29_q2.5` | Reach Village Rank 54 | `reach_rank`; `harmony` × 54 | `none` | `none` |

## chp29_q3: The Missing Groom

Configured quest `level` **1071**; assigned character **Elsie**.

Setup (localized quest text): “We got this whole wedding prepared, but now Blacktail is missing! You gotta help Kip find Blacktail, Chief.”

Journal outcome (localized quest text): “Kip and the Chief led the search for Blacktail. We couldn't let him hurt poor Elsie! We found out that he'd sailed off, and Kip thought he'd run off to Felicity's island. What was that scurvy cat up to?”

Configured scenes: `chp29_q3` (quest_start: chp29_q3); `t1chp29_q3` (quest_task_completed: chp29_q3.1); `t2chp29_q3` (quest_task_completed: chp29_q3.2); `t3chp29_q3` (quest_task_completed: chp29_q3.3); `t4chp29_q3` (quest_task_completed: chp29_q3.4); `ftchp29_q3` (claim_button_tapped: chp29_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp29_q3.1` | Search the jungle | `collect_and_interact`; `magn_glass` × 2 | `1071a,1072c` | `none` |
| `chp29_q3.2` | Search the beaches | `collect_and_interact`; `tracks_1` × 3 | `1073b,1074c,1075a` | `none` |
| `chp29_q3.3` | Comfort Elsie | `collect_and_interact`; `tissue` × 2 | `1076c,1077b` | `none` |
| `chp29_q3.4` | Send a letter to the Queen | `collect_and_interact`; `RedLetter` × 3 | `1078c,1079a,1080c` | `none` |

## chp29_q4: The Long-Delayed Wedding

Configured quest `level` **1081**; assigned character **Elsie**.

Setup (localized quest text): “We found Blacktail and dragged him back to the Island of the Ancients for his wedding. Now let's host the best reception ever!”

Journal outcome (localized quest text): “Elsie and Blacktail finally got married! We had an amazing reception, thanks to the Chief, and the newlyweds set off to Catton Abbey for their honeymoon. Before she left, she asked us to look for clues about our parents. Of course the Tropicats are up to the job!”

Configured scenes: `chp29_q4` (quest_start: chp29_q4); `t1chp29_q4` (quest_task_completed: chp29_q4.1); `t2chp29_q4` (quest_task_completed: chp29_q4.2); `t3chp29_q4` (quest_task_completed: chp29_q4.3); `t4chp29_q4` (quest_task_completed: chp29_q4.4); `ftchp29_q4` (claim_button_tapped: chp29_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp29_q4.1` | Party with the guests | `collect_and_interact`; `BurntSausage` × 3 | `1081a,1082b,1083c` | `none` |
| `chp29_q4.2` | Help Felicity with the catering | `collect_and_repair`; `cream_puff` × 2 | `1084b,1085c` | `none` |
| `chp29_q4.3` | Dine with the Duchess | `collect_and_repair`; `cake` × 3 | `1086b,1087c,1088b` | `none` |
| `chp29_q4.4` | Help Elsie learn Impurrial etiquette | `collect_and_interact`; `magn_glass` × 2 | `1089a,1090c` | `none` |
| `chp29_q4.5` | Reach Village Rank 55 | `reach_rank`; `harmony` × 55 | `none` | `none` |

