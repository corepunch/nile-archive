# Chapter 30

[Story index](../STORY.md) · [Previous](chapter-29.md) · [Next](chapter-31.md)

Configured chapter start: campaign level **1091**; starts with `chp30_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Evidence places the parents on the Island of the Ancients, and Sylvia's library contains a doll resembling the Chief. A shrine shows a vision of the Chief's homeland; a letter sends Ava and the Chief to Catton Abbey.

## chp30_q1: The Tropicat Parents

Configured quest `level` **1091**; assigned character **Elsie**.

Setup (localized quest text): “We know Sylvia has clues to where our parents went on this island, Chief! Let's find them.”

Journal outcome (localized quest text): “We searched all over the island, and found plenty of evidence showing that our parents DID come to the Island of the Ancients! Thanks to Olivia and Cubby's kittens, we knew there HAD to be evidence in Sylvia's library.”

Configured scenes: `chp30_q1` (quest_start: chp30_q1); `t1chp30_q1` (quest_task_completed: chp30_q1.1); `t2chp30_q1` (quest_task_completed: chp30_q1.2); `t3chp30_q1` (quest_task_completed: chp30_q1.3); `t4chp30_q1` (quest_task_completed: chp30_q1.4); `ftchp30_q1` (claim_button_tapped: chp30_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp30_q1.1` | Search the beach | `collect_and_interact`; `page` × 3 | `1091c,1092b,1093a` | `none` |
| `chp30_q1.2` | Search Sylvia's jungle lab | `collect_and_repair`; `golden_ring` × 3 | `1094b,1095c,1096b` | `none` |
| `chp30_q1.3` | Search the ancient caves | `collect_and_interact`; `lockbox` × 2 | `1097a,1098c` | `none` |
| `chp30_q1.4` | Search the jungle | `collect_and_interact`; `elsie_bell` × 2 | `1099b,1100c` | `none` |

## chp30_q2: Family Secrets

Configured quest `level` **1101**; assigned character **Elsie**.

Setup (localized quest text): “Now that we know our parents were here, we've got to figure out where they went. Can you help us, Chief?”

Journal outcome (localized quest text): “We rebuilt Sylvia's library and found some really strange things, including a doll that looked kind of like the Chief. Did the Chief have something to do with our parents' disappearance?”

Configured scenes: `chp30_q2` (quest_start: chp30_q2); `t1chp30_q2` (quest_task_completed: chp30_q2.1); `t2chp30_q2` (quest_task_completed: chp30_q2.2); `t3chp30_q2` (quest_task_completed: chp30_q2.3); `t4chp30_q2` (quest_task_completed: chp30_q2.4); `ftchp30_q2` (claim_button_tapped: chp30_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp30_q2.1` | Rebuild Sylvia's library | `collect_and_repair`; `log` × 2 | `1101a,1102b` | `ch30_library_meowgic` |
| `chp30_q2.2` | Search for books | `collect_and_interact`; `scrapbook` × 2 | `1103c,1104b,1105c` | `none` |
| `chp30_q2.3` | Examine a strange doll | `collect_and_interact`; `human_doll` × 3 | `1106b` | `none` |
| `chp30_q2.4` | Hypnotize Tammy | `collect_and_interact`; `stone` × 3 | `1107a,1108c,1109b,1110c` | `none` |
| `chp30_q2.5` | Reach Village Rank 56 | `reach_rank`; `harmony` × 56 | `none` | `none` |

## chp30_q3: The Ceremony

Configured quest `level` **1111**; assigned character **Elsie**.

Setup (localized quest text): “Taka discovered something special about the shrine where Elsie and Blacktail got married. We just have to activate it somehow to find out what it does.”

Journal outcome (localized quest text): “We offered elemental gifts to the ceremonial shrine, and it rewarded us with a vision of the Chief's homeland! It looked so strange and different from our own world, but no matter where you came from, Chief, you are a Tropicat to us!”

Configured scenes: `chp30_q3` (quest_start: chp30_q3); `t1chp30_q3` (quest_task_completed: chp30_q3.1); `t2chp30_q3` (quest_task_completed: chp30_q3.2); `t3chp30_q3` (quest_task_completed: chp30_q3.3); `t4chp30_q3` (quest_task_completed: chp30_q3.4); `ftchp30_q3` (claim_button_tapped: chp30_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp30_q3.1` | Make an offering of fire | `collect_and_interact`; `firefly` × 3 | `1111c,1112a,1113c` | `none` |
| `chp30_q3.2` | Deliver a letter to Ava | `collect_and_repair`; `BlueLetter` × 3 | `1114c,1115b,1116c` | `none` |
| `chp30_q3.3` | Make an offering of earth | `collect_and_interact`; `seed` × 2 | `1117b,1118a` | `none` |
| `chp30_q3.4` | Make an offering of water | `collect_and_interact`; `bucket` × 2 | `1119c,1120b` | `none` |

## chp30_q4: Journey To Catton Abbey

Configured quest `level` **1121**; assigned character **Elsie**.

Setup (localized quest text): “Elsie and Blacktail need help at Catton Abbey, Chief. We'd better help Ava get ready to set sail!”

Journal outcome (localized quest text): “We got a letter from Elsie saying that she needed help from Ava and Chief at Catton Abbey - and a special wedding gift. A hint of where Elsie's mother went! Ava and the Chief set sail to save Elsie and Blacktail's honeymoon, while the rest of the Tropicats went home... except for Taka, who wanted to study the shrine on the Island of the Ancients.”

Configured scenes: `chp30_q4` (quest_start: chp30_q4); `t1chp30_q4` (quest_task_completed: chp30_q4.1); `t2chp30_q4` (quest_task_completed: chp30_q4.2); `t3chp30_q4` (quest_task_completed: chp30_q4.3); `t4chp30_q4` (quest_task_completed: chp30_q4.4); `ftchp30_q4` (claim_button_tapped: chp30_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp30_q4.1` | Search the hidden compartment | `collect_and_interact`; `magn_glass` × 2 | `1121b` | `none` |
| `chp30_q4.2` | Help the Tropicats home | `collect_and_interact`; `grilled_banana` × 3 | `1122c,1123a,1124c` | `none` |
| `chp30_q4.3` | Say goodbye to Taka | `collect_and_interact`; `spyglass` × 3 | `1125b,1126c,1127a,1128c` | `none` |
| `chp30_q4.4` | Teach the kittens to talk | `collect_and_interact`; `rattle` × 2 | `1129b,1130c` | `none` |
| `chp30_q4.5` | Reach Village Rank 57 | `reach_rank`; `harmony` × 57 | `none` | `none` |

