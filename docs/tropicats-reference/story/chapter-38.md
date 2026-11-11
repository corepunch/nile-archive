# Chapter 38: The Highlander And The Duchess

[Story index](../STORY.md) · [Previous](chapter-37.md) · [Next](chapter-39.md)

Campaign levels **1411–1450**; starts with `chp38_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The Duchess accepts McYowler's proposal and they marry. A new lead says Elsie's missing mother may be an opera singer on Furrenze Island.

## chp38_q1: The Big Question

Configured quest `level` **1411**; assigned character **Elsie**.

Setup (localized quest text): “McYowler's gotten nervous all of a sudden! If he's going to propose, we're going to have to make him comfortable.”

Journal outcome (localized quest text): “McYowler proposed to the Duchess in the most amazing way. You should have seen how he'd prepared! I don't know how the Duchess could have said no, and thankfully, she didn't. It looks as though I have a wedding to plan!”

Configured scenes: `chp38_q1` (quest_start: chp38_q1); `t1chp38_q1` (quest_task_completed: chp38_q1.1); `t2chp38_q1` (quest_task_completed: chp38_q1.2); `t3chp38_q1` (quest_task_completed: chp38_q1.3); `t4chp38_q1` (quest_task_completed: chp38_q1.4); `ftchp38_q1` (claim_button_tapped: chp38_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp38_q1.1` | Practice the proposal | `collect_and_interact`; `fancyscroll` × 3 | `1411c,1412a,1413b` | `none` |
| `chp38_q1.2` | Have a bachelor party | `collect_and_interact`; `ClamBrew` × 2 | `1414c,1415b` | `none` |
| `chp38_q1.3` | Talk to Nibblesby about marriage | `collect_and_interact`; `bouquet` × 2 | `1416c,1417b` | `none` |
| `chp38_q1.4` | Build something special for the Duchess | `collect_and_repair`; `log` × 3 | `1418c,1419a,1420b` | `ch38_mcyowler_proposal` |

## chp38_q2: The Wedding Planner

Configured quest `level` **1421**; assigned character **Elsie**.

Setup (localized quest text): “Now that the Duchess has agreed to marry McYowler, we've got a wedding to plan! Let's get everything together, Chief.”

Journal outcome (localized quest text): “I really like wedding planning! It was so much fun to make seating charts, prepare the food, and get everyone to the island. I love love... what can I say? Nothing could have gone wrong, and it was time to have an amazing wedding.”

Configured scenes: `chp38_q2` (quest_start: chp38_q2); `t1chp38_q2` (quest_task_completed: chp38_q2.1); `t2chp38_q2` (quest_task_completed: chp38_q2.2); `t3chp38_q2` (quest_task_completed: chp38_q2.3); `t4chp38_q2` (quest_task_completed: chp38_q2.4); `ftchp38_q2` (claim_button_tapped: chp38_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp38_q2.1` | Build a seating chart | `collect_and_interact`; `blueprints` × 1 | `1421b` | `none` |
| `chp38_q2.2` | Work in the kitchen | `collect_and_interact`; `kitchen_knife` × 3 | `1422a,1423b,1424c` | `none` |
| `chp38_q2.3` | Set the tables | `collect_and_interact`; `fabric` × 5 | `1425b,1426c,1427b,1428c,1429a` | `none` |
| `chp38_q2.4` | Pick up the Tropicats | `collect_and_interact`; `anchor` × 1 | `1430c` | `none` |
| `chp38_q2.5` | Reach Village Rank 72 | `reach_rank`; `harmony` × 72 | `none` | `none` |

## chp38_q3: Highland Love

Configured quest `level` **1431**; assigned character **Elsie**.

Setup (localized quest text): “That was a beautiful ceremony. It's time to party now, Chief! You'll help manage, right?”

Journal outcome (localized quest text): “The Duchess and McYowler had a really beautiful wedding. It was so nice to see everyone getting along after such an awful experience. But we had another adventure waiting just around the corner!”

Configured scenes: `chp38_q3` (quest_start: chp38_q3); `t1chp38_q3` (quest_task_completed: chp38_q3.1); `t2chp38_q3` (quest_task_completed: chp38_q3.2); `t3chp38_q3` (quest_task_completed: chp38_q3.3); `t4chp38_q3` (quest_task_completed: chp38_q3.4); `ftchp38_q3` (claim_button_tapped: chp38_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp38_q3.1` | Chat with the guests | `collect_and_interact`; `ClamBrew` × 1 | `1431a` | `none` |
| `chp38_q3.2` | Serve tea | `collect_and_interact`; `porcelain_cup` × 3 | `1432c,1433b,1434a` | `none` |
| `chp38_q3.3` | Finish making dessert | `collect_and_interact`; `kitchen_knife` × 3 | `1435c,1436b,1437c` | `none` |
| `chp38_q3.4` | Make a speech | `collect_and_interact`; `fancyscroll` × 3 | `1438b,1439c,1440a` | `none` |

## chp38_q4: Elsie Of The Bells

Configured quest `level` **1441**; assigned character **Elsie**.

Setup (localized quest text): “Elsie's mother left a bell behind on the Island of the Ancients. We can figure out where it came from, right, Chief?”

Journal outcome (localized quest text): “After thinking she was gone for years, I suddenly learned that not only was my mom alive, but she was probably on Furrenze Island, living as an opera singer! She sounded amazing and I couldn't wait to meet her again.”

Configured scenes: `chp38_q4` (quest_start: chp38_q4); `t1chp38_q4` (quest_task_completed: chp38_q4.1); `t2chp38_q4` (quest_task_completed: chp38_q4.2); `t3chp38_q4` (quest_task_completed: chp38_q4.3); `t4chp38_q4` (quest_task_completed: chp38_q4.4); `ftchp38_q4` (claim_button_tapped: chp38_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp38_q4.1` | Fix Sherlock's sad tummy | `collect_and_interact`; `herb` × 3 | `1441a,1442c,1443b` | `none` |
| `chp38_q4.2` | Interrogate Sylvia | `collect_and_interact`; `SnowPrint` × 2 | `1444c,1445b` | `none` |
| `chp38_q4.3` | Analyze the bell's composition | `collect_and_interact`; `elsie_bell` × 3 | `1446c,1447b,1448c` | `none` |
| `chp38_q4.4` | Ask Woodshavings about Furrenze | `collect_and_interact`; `magn_glass` × 2 | `1449a,1450b` | `none` |
| `chp38_q4.5` | Reach Village Rank 73 | `reach_rank`; `harmony` × 73 | `none` | `none` |

