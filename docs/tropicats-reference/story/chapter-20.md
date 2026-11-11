# Chapter 20: Fowl Play

[Story index](../STORY.md) · [Previous](chapter-19.md) · [Next](chapter-21.md)

Campaign levels **691–730**; starts with `chp20_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Chicks disappear from the repaired coop. Mee Li describes Montclaw's rain magic and an alleged spirit; Taka and Lily investigate, and a failed séance suggests the intruder is alive.

## chp20_q1: Cooped Up

Configured quest `level` **691**; assigned character **Elsie**.

Setup (localized quest text): “Let’s build a chicken coop and search for some hens. Mee Li reckons a few of Montclaw’s old chicks are roaming the woods.”

Journal outcome (localized quest text): “We built the chicken coop and tracked down Montclaw’s old chickens, but some invisible force broke into the coop and stole the chicks. Now Felicity is convinced an evil spirit haunts this island...”

Configured scenes: `chp20_q1` (quest_start: chp20_q1); `t1chp20_q1` (quest_task_completed: chp20_q1.1); `t2chp20_q1` (quest_task_completed: chp20_q1.2); `t3chp20_q1` (quest_task_completed: chp20_q1.3); `t4chp20_q1` (quest_task_completed: chp20_q1.4); `ftchp20_q1` (claim_button_tapped: chp20_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp20_q1.1` | Build the chicken coop | `collect_and_repair`; `log` × 2 | `691a,692c` | `ch20_chickencoop` |
| `chp20_q1.2` | Find some chickens | `collect_and_repair`; `chicken` × 4 | `693b,694c,695b,696a` | `ch20_hen` |
| `chp20_q1.3` | Collect chicken feed | `collect_and_interact`; `red_seed` × 2 | `697c,698a` | `none` |
| `chp20_q1.4` | Search Montclaw's lockboxes | `collect_and_interact`; `lockbox` × 2 | `699c,700b` | `none` |

## chp20_q2: Are You Chicken?

Configured quest `level` **701**; assigned character **Elsie**.

Setup (localized quest text): “We need to find the missing chickens and track down Mee Li. There's something lurking in the woods and she knows what...”

Journal outcome (localized quest text): “Mee Li finally spilled the cream on Montclaw. The farmer was using dark meowgic to summon rain and improve his crops. But he accidentally summoned an evil spirit. Mee Li thinks the story is a bunch of hairballs. We'd better investigate.”

Configured scenes: `chp20_q2` (quest_start: chp20_q2); `t1chp20_q2` (quest_task_completed: chp20_q2.1); `t2chp20_q2` (quest_task_completed: chp20_q2.2); `t3chp20_q2` (quest_task_completed: chp20_q2.3); `t4chp20_q2` (quest_task_completed: chp20_q2.4); `ftchp20_q2` (claim_button_tapped: chp20_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp20_q2.1` | Rescue the missing chickens | `collect_and_interact`; `chicken` × 3 | `701b,702a,703c` | `none` |
| `chp20_q2.2` | Build a wall around the coop | `collect_and_repair`; `stone` × 2 | `704b,705c` | `ch20_drystonewall` |
| `chp20_q2.3` | Track down Mee Li | `collect_and_interact`; `tracks_2` × 4 | `706b,707a,708b,709c` | `none` |
| `chp20_q2.4` | Send a letter to Ragnaruff | `collect_and_interact`; `scroll` × 1 | `710b` | `none` |
| `chp20_q2.5` | Reach Village Rank 36 | `reach_rank`; `harmony` × 36 | `none` | `none` |

## chp20_q3: Ghost Hunt

Configured quest `level` **711**; assigned character **Elsie**.

Setup (localized quest text): “Chief, you've gotta help Lily figure out whether this island is haunted or not. I hope that kitten knows what she’s doing...”

Journal outcome (localized quest text): “Taka and Lily arrived on the island to investigate the strange happenings. Lily couldn’t find any evidence of an evil spirit, so Taka decided to take matters into his own paws.”

Configured scenes: `chp20_q3` (quest_start: chp20_q3); `t1chp20_q3` (quest_task_completed: chp20_q3.1); `t2chp20_q3` (quest_task_completed: chp20_q3.2); `t3chp20_q3` (quest_task_completed: chp20_q3.3); `t4chp20_q3` (quest_task_completed: chp20_q3.4); `ftchp20_q3` (claim_button_tapped: chp20_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp20_q3.1` | Find Montclaw's spell scrolls | `collect_and_interact`; `scroll` × 3 | `711a,712b,713c` | `none` |
| `chp20_q3.2` | Interview Ava and Felicity | `collect_and_interact`; `cake` × 3 | `714b,715c,716b` | `none` |
| `chp20_q3.3` | Cast a Seventh Sense spell | `collect_and_interact`; `herb` × 2 | `717a,718b` | `none` |
| `chp20_q3.4` | Help Lily take Ragnaruff for a walk | `collect_and_interact`; `vine` × 2 | `719c,720b` | `none` |

## chp20_q4: Body Purrsession

Configured quest `level` **721**; assigned character **Elsie**.

Setup (localized quest text): “Taka is going to perform a Séance of Purssession, so we can communicate with the ghost via Lily. Help him prepare for the séance!”

Journal outcome (localized quest text): “Taka performed a Séance of Purssession, to try and communicate with the evil spirit. But the séance didn’t work. Lily was right. Whatever is on this island is no ghost. It’s very much alive.”

Configured scenes: `chp20_q4` (quest_start: chp20_q4); `t1chp20_q4` (quest_task_completed: chp20_q4.1); `t2chp20_q4` (quest_task_completed: chp20_q4.2); `t3chp20_q4` (quest_task_completed: chp20_q4.3); `t4chp20_q4` (quest_task_completed: chp20_q4.4); `ftchp20_q4` (claim_button_tapped: chp20_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp20_q4.1` | Purify the area for the séance | `collect_and_interact`; `incense` × 2 | `721b,722a` | `none` |
| `chp20_q4.2` | Cut some hay for the chickens | `collect_and_repair`; `scythe` × 3 | `723b,724c,725b` | `ch20_haybale` |
| `chp20_q4.3` | Eat lunch with Taka | `collect_and_interact`; `grilled_banana` × 3 | `726c,727b,728c` | `none` |
| `chp20_q4.4` | Help Taka woo Felicity | `collect_and_interact`; `bouquet` × 2 | `729a,730c` | `none` |
| `chp20_q4.5` | Reach Village Rank 37 | `reach_rank`; `harmony` × 37 | `none` | `none` |

