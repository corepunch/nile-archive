# Chapter 36: The Ham Of The Whiskervilles

[Story index](../STORY.md) · [Previous](chapter-35.md) · [Next](chapter-37.md)

Campaign levels **1331–1370**; starts with `chp36_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

A supposed supernatural hamster leads the group to the old clan ruins. Blacktail confronts the creature, and a trap reveals Woodshavings in disguise.

## chp36_q1: The Hamster From Hell

Configured quest `level` **1331**; assigned character **Elsie**.

Setup (localized quest text): “Sherlock Bones now thinks that a demon might have stolen McYowler's body, but that couldn't be true. Could it?”

Journal outcome (localized quest text): “Sherlock Bones suggested that a demon hamster might have been responsible for everything! We thought it was crazy, of course. Who ever heard of a demon hamster? We were so scared when we heard the real thing barking across the moors!”

Configured scenes: `chp36_q1` (quest_start: chp36_q1); `t1chp36_q1` (quest_task_completed: chp36_q1.1); `t2chp36_q1` (quest_task_completed: chp36_q1.2); `t3chp36_q1` (quest_task_completed: chp36_q1.3); `t4chp36_q1` (quest_task_completed: chp36_q1.4); `ftchp36_q1` (claim_button_tapped: chp36_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp36_q1.1` | Look for books on the occult | `collect_and_interact`; `book` × 3 | `1331c,1332a,1333c` | `none` |
| `chp36_q1.2` | Learn about the hamster afterlife | `collect_and_interact`; `scroll` × 2 | `1334a,1335c` | `none` |
| `chp36_q1.3` | Search for Elsie's makeup kit | `collect_and_interact`; `elsie_makeup` × 2 | `1336b,1337c` | `none` |
| `chp36_q1.4` | Ask Woodshavings about the afterlife | `collect_and_interact`; `magn_glass` × 3 | `1338a,1339b,1340c` | `none` |

## chp36_q2: Lair Of The Hamster

Configured quest `level` **1341**; assigned character **Elsie**.

Setup (localized quest text): “We're here at the beast's lair! Let's be careful, Chief... we have to catch that demon!”

Journal outcome (localized quest text): “We arrived at the Hell-ham's lair: the old McYowler Clan ruins. We were careful, making sure we covered the exits, and drew out the demon with our insults. He was so scary, Chief! We ran for our lives. We just weren't ready to face the beast yet.”

Configured scenes: `chp36_q2` (quest_start: chp36_q2); `t1chp36_q2` (quest_task_completed: chp36_q2.1); `t2chp36_q2` (quest_task_completed: chp36_q2.2); `t3chp36_q2` (quest_task_completed: chp36_q2.3); `t4chp36_q2` (quest_task_completed: chp36_q2.4); `ftchp36_q2` (claim_button_tapped: chp36_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp36_q2.1` | Cut through the overgrowth | `collect_and_repair`; `pruningshears` × 2 | `1341b,1342c` | `ch36_mcyowler_ruins` |
| `chp36_q2.2` | Examine the demon hamster droppings | `collect_and_interact`; `clothespin` × 3 | `1343b,1344c,1345a` | `none` |
| `chp36_q2.3` | Secure the exits | `collect_and_interact`; `magn_glass` × 2 | `1346b,1347c` | `none` |
| `chp36_q2.4` | Insult the demon | `collect_and_interact`; `jesterstick` × 3 | `1348b,1349c,1350a` | `none` |
| `chp36_q2.5` | Reach Village Rank 68 | `reach_rank`; `harmony` × 68 | `none` | `none` |

## chp36_q3: Pirate Training

Configured quest `level` **1351**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail needs to learn to fight if we're going to face this demon hamster. Let's get to it!”

Journal outcome (localized quest text): “Chief! My husband is amazing. We taught him to fight, and he walked right up to that Ham of the Whiskervilles and showed him what happens when you mess with the Tropicats! We just had to capture it.”

Configured scenes: `chp36_q3` (quest_start: chp36_q3); `t1chp36_q3` (quest_task_completed: chp36_q3.1); `t2chp36_q3` (quest_task_completed: chp36_q3.2); `t3chp36_q3` (quest_task_completed: chp36_q3.3); `t4chp36_q3` (quest_task_completed: chp36_q3.4); `ftchp36_q3` (claim_button_tapped: chp36_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp36_q3.1` | Teach Blacktail how to be strong | `collect_and_interact`; `lance` × 1 | `1351a` | `none` |
| `chp36_q3.2` | Teach Blacktail how to sword fight | `collect_and_interact`; `sword` × 1 | `1352b` | `none` |
| `chp36_q3.3` | Teach Blacktail how to be brave | `collect_and_interact`; `diaper` × 4 | `1353c,1354b,1355c,1356a` | `none` |
| `chp36_q3.4` | Teach Blacktail how to calm down | `collect_and_interact`; `herb` × 4 | `1357b,1358c,1359b,1360c` | `none` |

## chp36_q4: Ham's End

Configured quest `level` **1361**; assigned character **Elsie**.

Setup (localized quest text): “The creature is on the defensive! We need to trap it and bring it to justice. Are you ready, Chief?”

Journal outcome (localized quest text): “When we caught the evil Ham of the Whiskervilles in my trap, we found out it was that mean butler, Woodshavings! He'd stolen my makeup and turned himself into a monster. Frame my husband AND steal my makeup? What a jerk!”

Configured scenes: `chp36_q4` (quest_start: chp36_q4); `t1chp36_q4` (quest_task_completed: chp36_q4.1); `t2chp36_q4` (quest_task_completed: chp36_q4.2); `t3chp36_q4` (quest_task_completed: chp36_q4.3); `t4chp36_q4` (quest_task_completed: chp36_q4.4); `ftchp36_q4` (claim_button_tapped: chp36_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp36_q4.1` | Build a hedge maze | `collect_and_repair`; `pruningshears` × 1 | `1361a` | `ch36_hamster_maze` |
| `chp36_q4.2` | Find some bait | `collect_and_interact`; `cake` × 3 | `1362b,1363c,1364b` | `none` |
| `chp36_q4.3` | Sew a net | `collect_and_interact`; `vine` × 3 | `1365c,1366b,1367a` | `none` |
| `chp36_q4.4` | Plant motion detectors | `collect_and_interact`; `log` × 3 | `1368c,1369b,1370c` | `none` |
| `chp36_q4.5` | Reach Village Rank 69 | `reach_rank`; `harmony` × 69 | `none` | `none` |

