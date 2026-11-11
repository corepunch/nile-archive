# Chapter 7

[Story index](../STORY.md) · [Previous](chapter-06.md) · [Next](chapter-08.md)

Configured chapter start: campaign level **171**; starts with `chp7_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Olivia tries to treat the prisoner and the purified spring heals him. Ragnaruff claims a bottle message offered a reward for cutting the totem; the cats cannot find it and prepare to send him away, until Lily and Kip stray into crocodile territory.

## chp7_q1: Prisoner Pup

Configured quest `level` **171**; assigned character **Taka**.

Setup (localized quest text): “We've locked the dog in Cubby's hut. Help Olivia tend to his injuries... we'll question him when he's healed.”

Journal outcome (localized quest text): “We tried our best to heal the dog's wounds but his condition began to worsen. His only hope for survival is the healing waters of our Spring of Purrification.”

Configured scenes: `chp7_q1` (quest_start: chp7_q1); `t1chp7_q1` (quest_task_completed: chp7_q1.1); `t2chp7_q1` (quest_task_completed: chp7_q1.2); `t3chp7_q1` (quest_task_completed: chp7_q1.3); `t4chp7_q1` (quest_task_completed: chp7_q1.4); `ftchp7_q1` (claim_button_tapped: chp7_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp7_q1.1` | Clear the rubble around the spring | `collect_and_repair`; `shovel` × 3 | `171a,172b,173c` | `ch7_rubble` |
| `chp7_q1.2` | Make catnip medicine for the dog | `collect_and_interact`; `herb` × 3 | `174a,175c,176b` | `none` |
| `chp7_q1.3` | Help Olivia feed the dog | `collect_and_interact`; `grilled_banana` × 2 | `177b,178c` | `none` |
| `chp7_q1.4` | Collect vines for Ava's "special project" | `collect_and_interact`; `vine` × 2 | `179b,180c` | `none` |

## chp7_q2: Bath Time

Configured quest `level` **181**; assigned character **Taka**.

Setup (localized quest text): “Let's unblock the Spring of Purrification. It's meowgic waters will heal the dog's injuries... and then we can get some answers.”

Journal outcome (localized quest text): “We unblocked the Spring of Purrification and healed the dog. The creature is called Ragnaruff and, rather than the evildoer we expected, he says he's a hero!”

Configured scenes: `chp7_q2` (quest_start: chp7_q2); `t1chp7_q2` (quest_task_completed: chp7_q2.1); `t2chp7_q2` (quest_task_completed: chp7_q2.2); `t3chp7_q2` (quest_task_completed: chp7_q2.3); `ftchp7_q2` (claim_button_tapped: chp7_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp7_q2.1` | Unblock the Spring of Purrification | `collect_and_repair`; `shovel` × 4 | `181a,182b,183a,184c` | `ch7_healing_spa` |
| `chp7_q2.2` | Replant the fan palm tree | `collect_and_repair`; `seed` × 3 | `185b,186c,187a` | `ch7_spa_fanpalm` |
| `chp7_q2.3` | Repair Elsie's pedicure chair | `collect_and_repair`; `bamboo` × 3 | `188b,189b,190c` | `ch7_spa_aromachair` |
| `chp7_q2.4` | Reach Village Rank 10 | `reach_rank`; `harmony` × 10 | `none` | `none` |

## chp7_q3: Message In A Bottle

Configured quest `level` **191**; assigned character **Ava**.

Setup (localized quest text): “Ragnaruff claims he found a message in a bottle at sea that offered a reward to anyone who'd cut down the Great Totem. Is the dog telling the truth? Let's find that message...”

Journal outcome (localized quest text): “Ragnaruff claimed he found a message in a bottle at sea. The message offered a reward to anyone who'd cut down our Great Totem. Chief couldn't find the message, so we decided Ragnaruff must leave the island.”

Configured scenes: `chp7_q3` (quest_start: chp7_q3); `t1chp7_q3` (quest_task_completed: chp7_q3.1); `t2chp7_q3` (quest_task_completed: chp7_q3.2); `t3chp7_q3` (quest_task_completed: chp7_q3.3); `t4chp7_q3` (quest_task_completed: chp7_q3.4); `ftchp7_q3` (claim_button_tapped: chp7_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp7_q3.1` | Look for Ragnaruff's message in a bottle | `collect_and_interact`; `ceramic_bottle` × 4 | `191a,192c,193a,194c` | `none` |
| `chp7_q3.2` | Read Ragnaruff's ship's log | `collect_and_interact`; `page` × 2 | `195b,196c` | `none` |
| `chp7_q3.3` | Examine suspicious tracks | `collect_and_interact`; `tracks_2` × 2 | `197a,198c` | `none` |
| `chp7_q3.4` | Reunite Lily with Ragnaruff | `collect_and_interact`; `herb` × 2 | `199b,200c` | `none` |

## chp7_q4: Dog Gone

Configured quest `level` **201**; assigned character **Elsie**.

Setup (localized quest text): “It's time Ragnaruff left the island. We need to repair his ship, or he'll sink like a dog-shaped stone.”

Journal outcome (localized quest text): “We fixed Ragnaruff's ship so he could leave. But Cubby brought terrible mews: Lily and Kip went searching for the lost message... and they strayed into crocodile territory!”

Configured scenes: `chp7_q4` (quest_start: chp7_q4); `t1chp7_q4` (quest_task_completed: chp7_q4.1); `t2chp7_q4` (quest_task_completed: chp7_q4.2); `t3chp7_q4` (quest_task_completed: chp7_q4.3); `ftchp7_q4` (claim_button_tapped: chp7_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp7_q4.1` | Repair Ragnaruff's ship | `collect_and_repair`; `log` × 4 | `201a,202b,203c,204b` | `ch7_journey_ship` |
| `chp7_q4.2` | Find medicinal supplies for Ragnaruff | `collect_and_repair`; `herb` × 4 | `205b,206b,207c` | `ch7_journey_dryer` |
| `chp7_q4.3` | Stock food supplies for Ragnaruff | `collect_and_repair`; `grilled_banana` × 3 | `208a,209b,210c` | `ch7_journey_supplies` |
| `chp7_q4.4` | Reach Village Rank 11 | `reach_rank`; `harmony` × 11 | `none` | `none` |

