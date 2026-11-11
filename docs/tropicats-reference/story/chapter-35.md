# Chapter 35: Whodunit?!

[Story index](../STORY.md) · [Previous](chapter-34.md) · [Next](chapter-36.md)

Campaign levels **1291–1330**; starts with `chp35_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Sherlock Bones investigates an invitation nobody admits sending and rules out Blacktail. Poison and a will implicate Woodshavings, but the detective ultimately rules him out as the killer too.

## chp35_q1: The Unsent Letter

Configured quest `level` **1291**; assigned character **Elsie**.

Setup (localized quest text): “Sherlock Bones was summoned by a letter, but we never sent one! Who sent it, Chief?”

Journal outcome (localized quest text): “A detective (dogtective?) named Sherlock Bones showed up, saying that we'd sent him a letter asking for help, but we never sent one! When he looked at the evidence, he couldn't match up the handwriting. Someone was playing a cruel game!”

Configured scenes: `chp35_q1` (quest_start: chp35_q1); `t1chp35_q1` (quest_task_completed: chp35_q1.1); `t2chp35_q1` (quest_task_completed: chp35_q1.2); `t3chp35_q1` (quest_task_completed: chp35_q1.3); `t4chp35_q1` (quest_task_completed: chp35_q1.4); `ftchp35_q1` (claim_button_tapped: chp35_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp35_q1.1` | Analyze Blacktail's handwriting | `collect_and_interact`; `page` × 3 | `1291a,1292c,1293b` | `none` |
| `chp35_q1.2` | Acquire Woodshavings's signature | `collect_and_interact`; `pen` × 3 | `1294c,1295a,1296b` | `none` |
| `chp35_q1.3` | Study the Duchess's letters | `collect_and_interact`; `blueLetter` × 3 | `1297c,1298b,1299c` | `none` |
| `chp35_q1.4` | Look at Felicity's cookbook | `collect_and_interact`; `scrapbook` × 1 | `1300b` | `none` |

## chp35_q2: What's Up With Blacktail?

Configured quest `level` **1301**; assigned character **Elsie**.

Setup (localized quest text): “Woodshavings is sure that Blacktail committed the murder. He couldn't have! But we have to rule out every possibility.”

Journal outcome (localized quest text): “That mean butler Woodshavings accused my husband of the murder! Sherlock Bones investigated every possibility, and understood that my husband couldn't have done it. He DID find poison in McYowler's teacup, though...”

Configured scenes: `chp35_q2` (quest_start: chp35_q2); `t1chp35_q2` (quest_task_completed: chp35_q2.1); `t2chp35_q2` (quest_task_completed: chp35_q2.2); `t3chp35_q2` (quest_task_completed: chp35_q2.3); `t4chp35_q2` (quest_task_completed: chp35_q2.4); `ftchp35_q2` (claim_button_tapped: chp35_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp35_q2.1` | Ask Elsie about the golf clubs | `collect_and_interact`; `magn_glass` × 3 | `1301a,1302c,1303b` | `none` |
| `chp35_q2.2` | Recruit Ava | `collect_and_interact`; `jesterstick` × 2 | `1304c,1305a` | `none` |
| `chp35_q2.3` | Talk to Blacktail about piracy | `collect_and_interact`; `sword` × 2 | `1306c,1307b` | `none` |
| `chp35_q2.4` | Examine the teacups | `collect_and_interact`; `porcelain_cup` × 3 | `1308c,1309a,1310c` | `none` |
| `chp35_q2.5` | Reach Village Rank 66 | `reach_rank`; `harmony` × 66 | `none` | `none` |

## chp35_q3: A Meowtive To Kill

Configured quest `level` **1311**; assigned character **Elsie**.

Setup (localized quest text): “With no obvious suspects, it's time to find out WHY someone would have McYowler killed. Come on, Chief!”

Journal outcome (localized quest text): “The Chief and Sherlock Bones learned something from McYowler's will. If he couldn't find an heir, everything he owned would go to Woodshavings! We had a new suspect, and a really mean one, too. We just needed evidence!”

Configured scenes: `chp35_q3` (quest_start: chp35_q3); `t1chp35_q3` (quest_task_completed: chp35_q3.1); `t2chp35_q3` (quest_task_completed: chp35_q3.2); `t3chp35_q3` (quest_task_completed: chp35_q3.3); `t4chp35_q3` (quest_task_completed: chp35_q3.4); `ftchp35_q3` (claim_button_tapped: chp35_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp35_q3.1` | Learn about Catton Abbey's history | `collect_and_interact`; `map` × 2 | `1311c,1312a` | `none` |
| `chp35_q3.2` | Learn about McYowler | `collect_and_interact`; `magn_glass` × 3 | `1313c,1314b,1315a` | `none` |
| `chp35_q3.3` | Study McYowler's will | `collect_and_interact`; `scroll` × 3 | `1316c,1317b,1318c` | `none` |
| `chp35_q3.4` | Find out what intrigued McYowler | `collect_and_interact`; `RedLetter` × 2 | `1319b,1320a` | `none` |

## chp35_q4: The Butler Did It?

Configured quest `level` **1321**; assigned character **Elsie**.

Setup (localized quest text): “Woodshavings stands to gain a lot if this mystery isn't solved! Let's see what we can find out about him.”

Journal outcome (localized quest text): “Sherlock Bones determined that Woodshavings couldn't have been McYowler's killer. We were completely out of suspects, but Sherlock Bones had another deduction we could have never imagined.”

Configured scenes: `chp35_q4` (quest_start: chp35_q4); `t1chp35_q4` (quest_task_completed: chp35_q4.1); `t2chp35_q4` (quest_task_completed: chp35_q4.2); `t3chp35_q4` (quest_task_completed: chp35_q4.3); `t4chp35_q4` (quest_task_completed: chp35_q4.4); `ftchp35_q4` (claim_button_tapped: chp35_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp35_q4.1` | Recruit Nibblesby as a spy | `collect_and_interact`; `spyglass` × 3 | `1321b,1322c,1323a` | `none` |
| `chp35_q4.2` | Snatch Woodshavings's diary | `collect_and_interact`; `scrapbook` × 3 | `1324b,1325c,1326b` | `none` |
| `chp35_q4.3` | Eavesdrop on Woodshavings | `collect_and_interact`; `magn_glass` × 3 | `1327c,1328b,1329c` | `none` |
| `chp35_q4.4` | Sneak into Woodshavings's quarters | `collect_and_interact`; `tracks_1` × 1 | `1330a` | `none` |
| `chp35_q4.5` | Reach Village Rank 67 | `reach_rank`; `harmony` × 67 | `none` | `none` |

