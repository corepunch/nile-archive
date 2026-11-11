# Chapter 53: Purrcini's Cannon March

[Story index](../STORY.md) · [Previous](chapter-52.md) · [Next](chapter-54.md)

Campaign levels **2011–2050**; starts with `chp53_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Purrcini arrives with the Queen's navy and prevents departure; Tammy is captured and then freed through Elsie's mother. Blacktail surrenders so Olivia can return to her kittens, leaving Elsie determined to rescue him.

## chp53_q1: Purrcini's Revenge

Configured quest `level` **2011**; assigned character **Elsie**.

Setup (localized quest text): “Oh no, Chief! Purrcini trapped us! We've got to get out.”

Journal outcome (localized quest text): “Just when we were about to leave, my dad showed up with the Queen's navy. He trapped us and wouldn't let us leave. How is he my dad, Chief?!”

Configured scenes: `chp53_q1` (quest_start: chp53_q1); `t1chp53_q1` (quest_task_completed: chp53_q1.1); `t2chp53_q1` (quest_task_completed: chp53_q1.2); `t3chp53_q1` (quest_task_completed: chp53_q1.3); `t4chp53_q1` (quest_task_completed: chp53_q1.4); `ftchp53_q1` (claim_button_tapped: chp53_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp53_q1.1` | Plead with Purrcini | `collect_and_repair`; `magn_glass` × 4 | `2011a,2012b,2013c,2014b` | `none` |
| `chp53_q1.2` | Pickpocket Purrcini | `collect_and_interact`; `RedLetter` × 4 | `2015c,2016a,2017c,2018a` | `none` |
| `chp53_q1.3` | Scour the coastline | `collect_and_interact`; `tracks_1` × 1 | `2019b` | `none` |
| `chp53_q1.4` | Try to sail through the blockade | `collect_and_interact`; `shipwheel` × 1 | `2020c` | `none` |

## chp53_q2: Meows In The Time Of War

Configured quest `level` **2021**; assigned character **Elsie**.

Setup (localized quest text): “Olivia isn't letting Purrcini stop her. Let's help her out, Chief.”

Journal outcome (localized quest text): “Things went from bad to worse! Olivia's mother tried to play superspy, but she managed to get captured by Purrcini. Things didn't look good at all, but we had to rescue her!”

Configured scenes: `chp53_q2` (quest_start: chp53_q2); `t1chp53_q2` (quest_task_completed: chp53_q2.1); `t2chp53_q2` (quest_task_completed: chp53_q2.2); `t3chp53_q2` (quest_task_completed: chp53_q2.3); `t4chp53_q2` (quest_task_completed: chp53_q2.4); `ftchp53_q2` (claim_button_tapped: chp53_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp53_q2.1` | Spy on Purrcini | `collect_and_repair`; `spyglass` × 3 | `2021a,2022b,2023c` | `none` |
| `chp53_q2.2` | Research Impurrial warships | `collect_and_interact`; `book` × 1 | `2024a` | `none` |
| `chp53_q2.3` | Distract Olivia | `collect_and_interact`; `spyglass` × 3 | `2025c,2026b,2027c` | `none` |
| `chp53_q2.4` | Practice holding your breath | `collect_and_interact`; `jesterstick` × 3 | `2028a,2029c,2030b` | `none` |
| `chp53_q2.5` | Reach Village Rank 102 | `reach_rank`; `harmony` × 102 | `none` | `none` |

## chp53_q3: The Rescue

Configured quest `level` **2031**; assigned character **Elsie**.

Setup (localized quest text): “Tammy was captured by Purrcini! Whatever we do, we've got to get her back first.”

Journal outcome (localized quest text): “My mom was able to persuade Purrcini to let Tammy go, but she couldn't convince him to let the rest of us go. We needed a new plan, and fast, or we'd be stuck on Felicity's island furever.”

Configured scenes: `chp53_q3` (quest_start: chp53_q3); `t1chp53_q3` (quest_task_completed: chp53_q3.1); `t2chp53_q3` (quest_task_completed: chp53_q3.2); `t3chp53_q3` (quest_task_completed: chp53_q3.3); `t4chp53_q3` (quest_task_completed: chp53_q3.4); `ftchp53_q3` (claim_button_tapped: chp53_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp53_q3.1` | Fly, fly again | `collect_and_interact`; `herb` × 2 | `2031c,2032b` | `none` |
| `chp53_q3.2` | Plead with Purrcini | `collect_and_interact`; `magn_glass` × 3 | `2033c,2034a,2035b` | `none` |
| `chp53_q3.3` | Sharpen Blacktail's cutlass | `collect_and_interact`; `sword` × 1 | `2036c` | `none` |
| `chp53_q3.4` | Bribe Purrcini with food | `collect_and_interact`; `cake` × 4 | `2037a,2038b,2039c,2040b` | `none` |

## chp53_q4: The Last Option

Configured quest `level` **2041**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail volunteered to surrender himself. We'd better prepare to rescue him!”

Journal outcome (localized quest text): “When Blacktail surrendered to Purrcini to reunite Olivia with her kits, I felt my heart breaking. I knew I couldn't just let things happen any more. I had to be a brave pirate, just like my husband.”

Configured scenes: `chp53_q4` (quest_start: chp53_q4); `t1chp53_q4` (quest_task_completed: chp53_q4.1); `t2chp53_q4` (quest_task_completed: chp53_q4.2); `t3chp53_q4` (quest_task_completed: chp53_q4.3); `t4chp53_q4` (quest_task_completed: chp53_q4.4); `ftchp53_q4` (claim_button_tapped: chp53_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp53_q4.1` | Build a communications headquarters | `collect_and_repair`; `log` × 3 | `2041a,2042b,2043c` | `ch53_pigeonpost_main` |
| `chp53_q4.2` | Give Blacktail a present | `collect_and_interact`; `medicine` × 2 | `2044a,2045b` | `none` |
| `chp53_q4.3` | Lecture Blacktail | `collect_and_interact`; `sword` × 3 | `2046c,2047b,2048c` | `none` |
| `chp53_q4.4` | Have a farewell dinner with Elsie | `collect_and_interact`; `strawberry_bowl` × 2 | `2049b,2050c` | `none` |
| `chp53_q4.5` | Reach Village Rank 103 | `reach_rank`; `harmony` × 103 | `none` | `none` |

