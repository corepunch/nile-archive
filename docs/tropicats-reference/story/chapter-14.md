# Chapter 14

[Story index](../STORY.md) · [Previous](chapter-13.md) · [Next](chapter-15.md)

Configured chapter start: campaign level **451**; starts with `chp14_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Captain Blacktail arrives seeking somewhere to hide treasure, rather than to steal it. His account of the Duchess leads to the discovery of her spy Nibblesby and the revelation that she is his mother.

## chp14_q1: Black Sails

Configured quest `level` **451**; assigned character **Elsie**.

Setup (localized quest text): “There’s a pirate ship heading straight for the island. They must be coming to steal our treasure! Quick, hide everything!”

Journal outcome (localized quest text): “Black sails have been spotted on the horizon. That can only mean that pirates are coming! We hid our valuables, but it turned out that Captain Blacktail was here to hide treasure, not steal it!”

Configured scenes: `chp14_q1` (quest_start: chp14_q1); `t1chp14_q1` (quest_task_completed: chp14_q1.1); `t2chp14_q1` (quest_task_completed: chp14_q1.2); `t3chp14_q1` (quest_task_completed: chp14_q1.3); `t4chp14_q1` (quest_task_completed: chp14_q1.4); `ftchp14_q1` (claim_button_tapped: chp14_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp14_q1.1` | Hide the tribe’s valuables | `collect_and_interact`; `lockbox` × 2 | `451a,452c` | `none` |
| `chp14_q1.2` | Find some weapons | `collect_and_interact`; `wooden_club` × 2 | `453b,454c` | `none` |
| `chp14_q1.3` | Practice fighting with Ragnaruff | `collect_and_interact`; `shield` × 3 | `455a,456b,457c` | `none` |
| `chp14_q1.4` | Help Kip hide Mr Crabby's kids | `collect_and_interact`; `crab` × 3 | `458c,459b,460c` | `none` |

## chp14_q2: Shiver Me Timbers!

Configured quest `level` **461**; assigned character **Elsie**.

Setup (localized quest text): “It turns out that Captain Blacktail isn’t here to steal treasure. He wants to hide it! Let’s build a cove for burying treasure!”

Journal outcome (localized quest text): “It turned out that Blacktail the pirate is really nice, and he’s so dreamy as well! He just wanted somewhere to hide his treasure away from a scary cat who has been chasing him!”

Configured scenes: `chp14_q2` (quest_start: chp14_q2); `t1chp14_q2` (quest_task_completed: chp14_q2.1); `t2chp14_q2` (quest_task_completed: chp14_q2.2); `t3chp14_q2` (quest_task_completed: chp14_q2.3); `ftchp14_q2` (claim_button_tapped: chp14_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp14_q2.1` | Dig a hole for the treasure | `collect_and_interact`; `shovel` × 3 | `461a,462b,463c` | `none` |
| `chp14_q2.2` | Pile up rocks to make a cove | `collect_and_repair`; `stone` × 3 | `464c,465b,466c` | `ch14_piratecave` |
| `chp14_q2.3` | Camouflage the cove entrance | `collect_and_repair`; `leaves` × 4 | `467a,468c,469b,470c` | `ch14_piratecave_stuff` |
| `chp14_q2.4` | Reach Village Rank 24 | `reach_rank`; `harmony` × 24 | `none` | `none` |

## chp14_q3: Tavern Fever

Configured quest `level` **471**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail is being chased by a villain called the Duchess! He wants to tell his tail over a drink. So let’s build a tavern on the island where we can party like pirates!”

Journal outcome (localized quest text): “We built a tavern and Blacktail told his story. He says the Duchess is a powerful cat from Impurrial Island. But before Blacktail could say any more, Kip spotted one of the Duchess's spies on the island!”

Configured scenes: `chp14_q3` (quest_start: chp14_q3); `t1chp14_q3` (quest_task_completed: chp14_q3.1); `t2chp14_q3` (quest_task_completed: chp14_q3.2); `t3chp14_q3` (quest_task_completed: chp14_q3.3); `t4chp14_q3` (quest_task_completed: chp14_q3.4); `ftchp14_q3` (claim_button_tapped: chp14_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp14_q3.1` | Build the pirate tavern! | `collect_and_repair`; `bamboo` × 3 | `471b,472a,473b` | `ch14_piratebar` |
| `chp14_q3.2` | Make clam brew for the tavern | `collect_and_repair`; `shell` × 2 | `474c,475b` | `ch14_piratebar_barrel` |
| `chp14_q3.3` | Grill bananas for tavern snacks | `collect_and_interact`; `grilled_banana` × 3 | `476b,477b,478c` | `none` |
| `chp14_q3.4` | Help Elsie groom for the tavern's opening night | `collect_and_interact`; `grooming_brush` × 3 | `479a,480c` | `none` |

## chp14_q4: Watchers In The Night

Configured quest `level` **481**; assigned character **Elsie**.

Setup (localized quest text): “Somebody is spying on us! Could the Duchess have found Blacktail already? We need to find the intruder!”

Journal outcome (localized quest text): “We found the spy - a hamster named Nibblesby. He's the Duchess’s butler and he revealed that the Duchess is Blacktail's mother! She'll arrive any day now!”

Configured scenes: `chp14_q4` (quest_start: chp14_q4); `t1chp14_q4` (quest_task_completed: chp14_q4.1); `t2chp14_q4` (quest_task_completed: chp14_q4.2); `t3chp14_q4` (quest_task_completed: chp14_q4.3); `t4chp14_q4` (quest_task_completed: chp14_q4.4); `ftchp14_q4` (claim_button_tapped: chp14_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp14_q4.1` | Search the beach | `collect_and_interact`; `shell` × 2 | `481a,482c` | `none` |
| `chp14_q4.2` | Search the gardens | `collect_and_interact`; `herb` × 3 | `483c,484a,485b` | `none` |
| `chp14_q4.3` | Search the jungle | `collect_and_interact`; `axe` × 3 | `486a,487c,488b` | `none` |
| `chp14_q4.4` | Search the huts | `collect_and_interact`; `magn_glass` × 2 | `489a,490c` | `none` |
| `chp14_q4.5` | Reach Village Rank 25 | `reach_rank`; `harmony` × 25 | `none` | `none` |

