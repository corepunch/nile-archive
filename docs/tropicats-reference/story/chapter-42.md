# Chapter 42: The Worst Show On Earth

[Story index](../STORY.md) · [Previous](chapter-41.md) · [Next](chapter-43.md)

Campaign levels **1571–1610**; starts with `chp42_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The troupe publicizes the opera and prepares Ava for the stage, then deliberately makes the performance dreadful. Purrcini loses the audience's respect and Elsie gets her mother back.

## chp42_q1: An Actor's Life For Me

Configured quest `level` **1571**; assigned character **Elsie**.

Setup (localized quest text): “We've got a truly pawful cast, but now Ava's got stage fright! You can help, right, Chief?”

Journal outcome (localized quest text): “Ava seems so brave all the time, but it turns out she gets terrible stage fright. We had to make sure she gave her most pawful performance, so we taught her a few tricks. She was ready to face the audience!”

Configured scenes: `chp42_q1` (quest_start: chp42_q1); `t1chp42_q1` (quest_task_completed: chp42_q1.1); `t2chp42_q1` (quest_task_completed: chp42_q1.2); `t3chp42_q1` (quest_task_completed: chp42_q1.3); `t4chp42_q1` (quest_task_completed: chp42_q1.4); `ftchp42_q1` (claim_button_tapped: chp42_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp42_q1.1` | Teach Ava a trick | `collect_and_interact`; `diaper` × 2 | `1571a,1572b` | `none` |
| `chp42_q1.2` | Prepare for an unruly audience | `collect_and_interact`; `tomato` × 4 | `1573c,1574a,1575b,1576c` | `none` |
| `chp42_q1.3` | Help Ava get into character | `collect_and_interact`; `page` × 2 | `1577b,1578b` | `none` |
| `chp42_q1.4` | Help Ava practice | `collect_and_interact`; `magn_glass` × 2 | `1579c,1580b` | `none` |

## chp42_q2: Public Relations

Configured quest `level` **1581**; assigned character **Elsie**.

Setup (localized quest text): “We've got to spread the word if everyone is going to see Purrcini's pawful opurra. Let's do it!”

Journal outcome (localized quest text): “Even though she'd been living in the jungle, Tammy was pretty good at public relations! She even got an interview with the local newspaper. It looked as though we were going to have a packed house for the opurra's debut!”

Configured scenes: `chp42_q2` (quest_start: chp42_q2); `t1chp42_q2` (quest_task_completed: chp42_q2.1); `t2chp42_q2` (quest_task_completed: chp42_q2.2); `t3chp42_q2` (quest_task_completed: chp42_q2.3); `t4chp42_q2` (quest_task_completed: chp42_q2.4); `ftchp42_q2` (claim_button_tapped: chp42_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp42_q2.1` | Design some flyers | `collect_and_interact`; `page` × 3 | `1581a,1582b,1583c` | `none` |
| `chp42_q2.2` | Talk to the local newspaper | `collect_and_interact`; `newspaper` × 2 | `1584b,1585c` | `none` |
| `chp42_q2.3` | Meet the public | `collect_and_interact`; `fancyscroll` × 4 | `1586a,1587c,1588a,1589c` | `none` |
| `chp42_q2.4` | Build concession stands | `collect_and_repair`; `log` × 1 | `1590b` | `ch42_furrenze_concessions` |
| `chp42_q2.5` | Reach Village Rank 80 | `reach_rank`; `harmony` × 80 | `none` | `none` |

## chp42_q3: Getting Worse All The Time

Configured quest `level` **1591**; assigned character **Elsie**.

Setup (localized quest text): “Uh oh, Chief. Ava doesn't sound that bad any more. We can make her sound worse, right?”

Journal outcome (localized quest text): “Once Ava got her confidence, she was starting to sing pretty well... but that would ruin the opurra. Luckily, we all were able to find ways to make Ava sound just as bad as before, if not worse. The opurra was going to be the disaster we needed!”

Configured scenes: `chp42_q3` (quest_start: chp42_q3); `t1chp42_q3` (quest_task_completed: chp42_q3.1); `t2chp42_q3` (quest_task_completed: chp42_q3.2); `t3chp42_q3` (quest_task_completed: chp42_q3.3); `t4chp42_q3` (quest_task_completed: chp42_q3.4); `ftchp42_q3` (claim_button_tapped: chp42_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp42_q3.1` | Drink clam brew | `collect_and_interact`; `ClamBrew` × 3 | `1591a,1592b,1593c` | `none` |
| `chp42_q3.2` | Have a karaoke night | `collect_and_interact`; `musicstand` × 3 | `1594b,1595c,1596b` | `none` |
| `chp42_q3.3` | Imitate Blacktail | `collect_and_interact`; `jesterstick` × 2 | `1597c,1598a` | `none` |
| `chp42_q3.4` | Enjoy some catnip | `collect_and_interact`; `herb` × 2 | `1599b,1600c` | `none` |

## chp42_q4: Le Due Farfalle

Configured quest `level` **1601**; assigned character **Elsie**.

Setup (localized quest text): “It's time for the big show, Chief! Do your worst, and that jerk Purrcini is sure to show up. Break a leg!”

Journal outcome (localized quest text): “We did it! We put on maybe the worst show of all time, and the audience HATED it, losing all respect for Purrcini. But I didn't care about him. I finally had my mom back!”

Configured scenes: `chp42_q4` (quest_start: chp42_q4); `t1chp42_q4` (quest_task_completed: chp42_q4.1); `t2chp42_q4` (quest_task_completed: chp42_q4.2); `t3chp42_q4` (quest_task_completed: chp42_q4.3); `t4chp42_q4` (quest_task_completed: chp42_q4.4); `ftchp42_q4` (claim_button_tapped: chp42_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp42_q4.1` | Sing a song with pawful lyrics | `collect_and_interact`; `musicstand` × 2 | `1601a,1602c` | `none` |
| `chp42_q4.2` | Forget your lines | `collect_and_interact`; `jesterstick` × 3 | `1603b,1604c,1605b` | `none` |
| `chp42_q4.3` | Get sick | `collect_and_interact`; `magn_glass` × 4 | `1606a,1607b,1608c,1609b` | `none` |
| `chp42_q4.4` | Sing the great aria | `collect_and_interact`; `concertina` × 1 | `1610c` | `none` |
| `chp42_q4.5` | Reach Village Rank 81 | `reach_rank`; `harmony` × 81 | `none` | `none` |

