# Chapter 37: Night Of The Living Cat

[Story index](../STORY.md) · [Previous](chapter-36.md) · [Next](chapter-38.md)

Campaign levels **1371–1410**; starts with `chp37_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

McYowler reappears and admits staging his death to test the Duchess's love. He apologizes, earns another chance and prepares a proposal.

## chp37_q1: Trail Of The Highland Cat

Configured quest `level` **1371**; assigned character **Elsie**.

Setup (localized quest text): “Woodshavings insists that he didn't kill McYowler, and that we'll have our answers when we find the body. We have to try to find McYowler, Chief!”

Journal outcome (localized quest text): “Woodshavings insisted that he didn't kill his master, and that we'd find answers with McYowler's body. Well... McYowler showed up. He said he faked his death to see if the Duchess loved him, but she wasn't so sure she did after that stunt.”

Configured scenes: `chp37_q1` (quest_start: chp37_q1); `t1chp37_q1` (quest_task_completed: chp37_q1.1); `t2chp37_q1` (quest_task_completed: chp37_q1.2); `t3chp37_q1` (quest_task_completed: chp37_q1.3); `t4chp37_q1` (quest_task_completed: chp37_q1.4); `ftchp37_q1` (claim_button_tapped: chp37_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp37_q1.1` | Interrogate Woodshavings | `collect_and_interact`; `elsie_makeup` × 3 | `1371a,1372b,1373c` | `none` |
| `chp37_q1.2` | Examine the Abbey grounds | `collect_and_interact`; `magn_glass` × 3 | `1374b,1375a,1376c` | `none` |
| `chp37_q1.3` | Inspect McYowler's clubs | `collect_and_interact`; `golfclubs` × 2 | `1377b,1378c` | `none` |
| `chp37_q1.4` | Find a high spot | `collect_and_interact`; `spyglass` × 2 | `1379a,1380c` | `none` |

## chp37_q2: A Second Chance

Configured quest `level` **1381**; assigned character **Elsie**.

Setup (localized quest text): “McYowler really messed up, and now the Duchess wants nothing to do with him. Maybe we can patch things up?”

Journal outcome (localized quest text): “I know what it's like to have someone you love do something thoughtless. But we helped McYowler apologize for his stupid scheme, and the Duchess forgave him. She's really an amazing cat.”

Configured scenes: `chp37_q2` (quest_start: chp37_q2); `t1chp37_q2` (quest_task_completed: chp37_q2.1); `t2chp37_q2` (quest_task_completed: chp37_q2.2); `t3chp37_q2` (quest_task_completed: chp37_q2.3); `t4chp37_q2` (quest_task_completed: chp37_q2.4); `ftchp37_q2` (claim_button_tapped: chp37_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp37_q2.1` | Apologize to Blacktail | `collect_and_interact`; `ClamBrew` × 4 | `1381c,1382a,1383c,1384b` | `none` |
| `chp37_q2.2` | Get Ava's help | `collect_and_interact`; `log` × 3 | `1385c,1386b,1387c` | `none` |
| `chp37_q2.3` | Plan a surprise for the Duchess | `collect_and_interact`; `page` × 1 | `1388a` | `none` |
| `chp37_q2.4` | Talk to the Duchess | `collect_and_interact`; `bouquet` × 2 | `1389c,1390a` | `none` |
| `chp37_q2.5` | Reach Village Rank 70 | `reach_rank`; `harmony` × 70 | `none` | `none` |

## chp37_q3: Getting To Know Mew

Configured quest `level` **1391**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess decided to let McYowler stay at Catton Abbey, but he's got to get to know everyone. Let's have some fun!”

Journal outcome (localized quest text): “The Duchess wasn't going to be with a cat who didn't get along with her friends. We actually had a great day with McYowler! I understood why the Duchess would want to marry him, but she wasn't ready for that... yet.”

Configured scenes: `chp37_q3` (quest_start: chp37_q3); `t1chp37_q3` (quest_task_completed: chp37_q3.1); `t2chp37_q3` (quest_task_completed: chp37_q3.2); `t3chp37_q3` (quest_task_completed: chp37_q3.3); `t4chp37_q3` (quest_task_completed: chp37_q3.4); `ftchp37_q3` (claim_button_tapped: chp37_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp37_q3.1` | Go sailing with Blacktail | `collect_and_interact`; `anchor` × 1 | `1391a` | `none` |
| `chp37_q3.2` | Go golfing with McYowler | `collect_and_repair`; `golfclubs` × 4 | `1392b,1393c,1394b,1395c` | `none` |
| `chp37_q3.3` | Deal with Woodshavings | `collect_and_interact`; `fancyscroll` × 1 | `1396a` | `none` |
| `chp37_q3.4` | Talk to Elsie about... something | `collect_and_interact`; `fish` × 4 | `1397c,1398b,1399c,1400b` | `none` |

## chp37_q4: McYowler's Wish

Configured quest `level` **1401**; assigned character **Elsie**.

Setup (localized quest text): “McYowler doesn't just want to be the Duchess's catfriend. He wants something more, and he needs help to make it happen!”

Journal outcome (localized quest text): “We helped McYowler build the perfect place to propose to the Duchess, and watched as he crushed a piece of coal into a diamond. It certainly seemed like nothing in the world could possibly scare him!”

Configured scenes: `chp37_q4` (quest_start: chp37_q4); `t1chp37_q4` (quest_task_completed: chp37_q4.1); `t2chp37_q4` (quest_task_completed: chp37_q4.2); `t3chp37_q4` (quest_task_completed: chp37_q4.3); `t4chp37_q4` (quest_task_completed: chp37_q4.4); `ftchp37_q4` (claim_button_tapped: chp37_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp37_q4.1` | Build a proposal site | `collect_and_repair`; `log` × 2 | `1401a,1402c` | `ch37_catton_wedding` |
| `chp37_q4.2` | Find a piece of coal | `collect_and_interact`; `coal` × 3 | `1403a,1404b,1405c` | `none` |
| `chp37_q4.3` | Look for McYowler's ring | `collect_and_interact`; `golden_ring` × 2 | `1406a,1407b` | `none` |
| `chp37_q4.4` | Look for flowers | `collect_and_interact`; `bouquet` × 3 | `1408c,1409b,1410c` | `none` |
| `chp37_q4.5` | Reach Village Rank 71 | `reach_rank`; `harmony` × 71 | `none` | `none` |

