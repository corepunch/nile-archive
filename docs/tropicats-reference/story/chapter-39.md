# Chapter 39: Artistic Differences

[Story index](../STORY.md) · [Previous](chapter-38.md) · [Next](chapter-40.md)

Campaign levels **1451–1490**; starts with `chp39_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

On Furrenze, Elsie finds her mother, who does not remember her. Repairing the opera house and auditioning bring them together, but Elsie wins the lead and upsets her mother.

## chp39_q1: De-Composition

Configured quest `level` **1451**; assigned character **Elsie**.

Setup (localized quest text): “Furrenze is a mess! We'd better get things cleaned up and figure out what's been going on.”

Journal outcome (localized quest text): “We arrived on Furrenze Island, and things didn't look too good there! The opurra house was ruined, and the director was acting all coconuts. But I knew my mother was around here somewhere.  We just had to find her.”

Configured scenes: `chp39_q1` (quest_start: chp39_q1); `t1chp39_q1` (quest_task_completed: chp39_q1.1); `t2chp39_q1` (quest_task_completed: chp39_q1.2); `t3chp39_q1` (quest_task_completed: chp39_q1.3); `t4chp39_q1` (quest_task_completed: chp39_q1.4); `ftchp39_q1` (claim_button_tapped: chp39_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp39_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 4 | `1451a,1452b,1453c,1454b` | `ch39_rubble` |
| `chp39_q1.2` | Calm down Purrcini | `collect_and_interact`; `magn_glass` × 4 | `1455b,1456c,1457b,1458c` | `none` |
| `chp39_q1.3` | Search for Elsie's mother | `collect_and_interact`; `elsie_bell` × 1 | `1459a` | `none` |
| `chp39_q1.4` | Spy on Purrcini | `collect_and_interact`; `spyglass` × 1 | `1460b` | `none` |

## chp39_q2: La Gatta Bianca

Configured quest `level` **1461**; assigned character **Elsie**.

Setup (localized quest text): “Purrcini won't calm down until his opurra house is repaired. Maybe then he'll tell us who "La Gatta Bianca" is!”

Journal outcome (localized quest text): “I couldn't believe it, but after all this time, I found my mom! She was so beautiful and so elegant... but she didn't remember me at all. We had to get her back to the opurra that the Chief and Ava fixed.”

Configured scenes: `chp39_q2` (quest_start: chp39_q2); `t1chp39_q2` (quest_task_completed: chp39_q2.1); `t2chp39_q2` (quest_task_completed: chp39_q2.2); `t3chp39_q2` (quest_task_completed: chp39_q2.3); `t4chp39_q2` (quest_task_completed: chp39_q2.4); `ftchp39_q2` (claim_button_tapped: chp39_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp39_q2.1` | Fix the opurra house | `collect_and_repair`; `log` × 3 | `1461a,1462c,1463b` | `ch39_furrenze_opera` |
| `chp39_q2.2` | Ask Purrcini about La Gatta Bianca | `collect_and_interact`; `elsie_bell` × 3 | `1464c,1465b,1466c` | `none` |
| `chp39_q2.3` | Search the area | `collect_and_interact`; `musicstand` × 2 | `1467a,1468b` | `none` |
| `chp39_q2.4` | Practice singing | `collect_and_interact`; `jesterstick` × 2 | `1469a,1470c` | `none` |
| `chp39_q2.5` | Reach Village Rank 74 | `reach_rank`; `harmony` × 74 | `none` | `none` |

## chp39_q3: The Prima Donna

Configured quest `level` **1471**; assigned character **Elsie**.

Setup (localized quest text): “Bianca isn't too happy with Purrcini. She's going to need some persuading to return to the opurra.”

Journal outcome (localized quest text): “I have to admit that my mom was a little demanding. She refused to come back to the opurra until she had a nicer dressing room and an apawlogy from Purrcini. But she deserved to be treated well!”

Configured scenes: `chp39_q3` (quest_start: chp39_q3); `t1chp39_q3` (quest_task_completed: chp39_q3.1); `t2chp39_q3` (quest_task_completed: chp39_q3.2); `t3chp39_q3` (quest_task_completed: chp39_q3.3); `t4chp39_q3` (quest_task_completed: chp39_q3.4); `ftchp39_q3` (claim_button_tapped: chp39_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp39_q3.1` | Extract an apawlogy from Purrcini | `collect_and_interact`; `tissue` × 2 | `1471a,1472b` | `none` |
| `chp39_q3.2` | Comfort Bianca | `collect_and_interact`; `herb` × 3 | `1473c,1474a,1475c` | `none` |
| `chp39_q3.3` | Ask Purrcini where Bianca is from | `collect_and_interact`; `musicstand` × 2 | `1476b,1477c` | `none` |
| `chp39_q3.4` | Replace Bianca's litter | `collect_and_interact`; `litterbox` × 3 | `1478a,1479c,1480b` | `none` |

## chp39_q4: The Play's The Thing

Configured quest `level` **1481**; assigned character **Elsie**.

Setup (localized quest text): “Now that Bianca is back, it's time to start casting the opurra! We can all go home after this.”

Journal outcome (localized quest text): “We all auditioned for the opurra, and something incredible happened. I was cast as the star! I knew I could sing, but I wasn't as good as my mom. She wasn't happy about it at all...”

Configured scenes: `chp39_q4` (quest_start: chp39_q4); `t1chp39_q4` (quest_task_completed: chp39_q4.1); `t2chp39_q4` (quest_task_completed: chp39_q4.2); `t3chp39_q4` (quest_task_completed: chp39_q4.3); `t4chp39_q4` (quest_task_completed: chp39_q4.4); `ftchp39_q4` (claim_button_tapped: chp39_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp39_q4.1` | Have Blacktail audition for the opurra | `collect_and_interact`; `jesterstick` × 3 | `1481a,1482b,1483c` | `none` |
| `chp39_q4.2` | Watch Ava's audition | `collect_and_interact`; `ukulele` × 2 | `1484a,1485b` | `none` |
| `chp39_q4.3` | You have to audition too, {userName}! | `collect_and_interact`; `page` × 3 | `1486c,1487b,1488c` | `none` |
| `chp39_q4.4` | Watch Elsie's audition | `collect_and_interact`; `musicstand` × 2 | `1489b,1490c` | `none` |
| `chp39_q4.5` | Reach Village Rank 75 | `reach_rank`; `harmony` × 75 | `none` | `none` |

