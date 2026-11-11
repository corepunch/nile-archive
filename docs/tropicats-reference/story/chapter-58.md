# Chapter 58: To Furgive Is Divine

[Story index](../STORY.md) · [Previous](chapter-57.md) · [Next](chapter-59.md)

Campaign levels **2211–2250**; starts with `chp58_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Lily forgives Kip and uses magic to clean up the vines, though Sylvia rejects his apology. Ragnaruff observes the school, and Sylvia and Gruffgar's dispute over cats and dogs escalates toward a contest.

## chp58_q1: Hiss And Make Up

Configured quest `level` **2211**; assigned character **Elsie**.

Setup (localized quest text): “Kip really wants to make up with Lily. You can help, Chief!”

Journal outcome (localized quest text): “I am one lucky kitten, Chief. Lily forgave me and she used some really cool meowgic to clean up the mess I made! I'm really sorry I was ever mean to Lily, Chief.”

Configured scenes: `chp58_q1` (quest_start: chp58_q1); `t1chp58_q1` (quest_task_completed: chp58_q1.1); `t2chp58_q1` (quest_task_completed: chp58_q1.2); `t3chp58_q1` (quest_task_completed: chp58_q1.3); `t4chp58_q1` (quest_task_completed: chp58_q1.4); `ftchp58_q1` (claim_button_tapped: chp58_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp58_q1.1` | Clean the classroom | `collect_and_interact`; `textbooks` × 3 | `2211a,2212b,2213c` | `none` |
| `chp58_q1.2` | Find new stones | `collect_and_repair`; `stone` × 2 | `2214a,2215b` | `ch58_library_extras` |
| `chp58_q1.3` | Get rid of the vines | `collect_and_interact`; `pruningshears` × 2 | `2216b,2217c` | `none` |
| `chp58_q1.4` | Pay for the damages | `collect_and_interact`; `garbage` × 3 | `2218a,2219b,2220c` | `none` |

## chp58_q2: Cat For Teacher

Configured quest `level` **2221**; assigned character **Elsie**.

Setup (localized quest text): “Kip still has to apawlogize to Ms. Sylvia. You can help him, right?”

Journal outcome (localized quest text): “I really tried to apawlogize to Ms. Sylvia, Chief, but since she's the meanest cat in the world, she didn't accept my apawlogy. I don't know what else I was supposed to do, Chief!”

Configured scenes: `chp58_q2` (quest_start: chp58_q2); `t1chp58_q2` (quest_task_completed: chp58_q2.1); `t2chp58_q2` (quest_task_completed: chp58_q2.2); `t3chp58_q2` (quest_task_completed: chp58_q2.3); `t4chp58_q2` (quest_task_completed: chp58_q2.4); `ftchp58_q2` (claim_button_tapped: chp58_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp58_q2.1` | Write Ms. Sylvia a letter | `collect_and_interact`; `BlueLetter` × 2 | `2221b,2222c` | `none` |
| `chp58_q2.2` | Find a present for Ms. Sylvia | `collect_and_interact`; `coal` × 3 | `2223a,2224c,2225a` | `none` |
| `chp58_q2.3` | Clean Ms. Sylvia's desk | `collect_and_interact`; `furr_white` × 2 | `2226b,2227c` | `none` |
| `chp58_q2.4` | Practice apawlogizing | `collect_and_interact`; `scroll` × 3 | `2228a,2229b,2230c` | `none` |
| `chp58_q2.5` | Reach Village Rank 112 | `reach_rank`; `harmony` × 112 | `none` | `none` |

## chp58_q3: Catwatching

Configured quest `level` **2231**; assigned character **Elsie**.

Setup (localized quest text): “Ragnaruff needs to observe the school, but you can help him out.”

Journal outcome (localized quest text): “King Ragnaruff came to our school today! He was checking out all of our classes, and he seemed pretty happy. I love King Raggy, because he could tell that Ms. Sylvia was being really mean!”

Configured scenes: `chp58_q3` (quest_start: chp58_q3); `t1chp58_q3` (quest_task_completed: chp58_q3.1); `t2chp58_q3` (quest_task_completed: chp58_q3.2); `t3chp58_q3` (quest_task_completed: chp58_q3.3); `t4chp58_q3` (quest_task_completed: chp58_q3.4); `ftchp58_q3` (claim_button_tapped: chp58_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp58_q3.1` | Watch Lt. Meowser teach | `collect_and_interact`; `magn_glass` × 1 | `2231a` | `none` |
| `chp58_q3.2` | Observe Cubby's class | `collect_and_interact`; `dumbbells` × 1 | `2232b` | `none` |
| `chp58_q3.3` | Observe Dean Gruffgar | `collect_and_interact`; `spyglass` × 4 | `2233c,2234b,2235c,2236b` | `none` |
| `chp58_q3.4` | Observe Sylvia | `collect_and_interact`; `chalkboard` × 4 | `2237a,2238c,2239b,2240c` | `none` |

## chp58_q4: Of Canines And Codes

Configured quest `level` **2241**; assigned character **Elsie**.

Setup (localized quest text): “Dean Gruffgar needs your help to defend the Code of Canines, Chief!”

Journal outcome (localized quest text): “I don't get why grown-ups argue all the time over stupid stuff, Chief. Ms. Sylvia was trying to say that cats are better than dogs, but Dean Gruffgar stumped her. Now they're going to have a real battle!”

Configured scenes: `chp58_q4` (quest_start: chp58_q4); `t1chp58_q4` (quest_task_completed: chp58_q4.1); `t2chp58_q4` (quest_task_completed: chp58_q4.2); `t3chp58_q4` (quest_task_completed: chp58_q4.3); `t4chp58_q4` (quest_task_completed: chp58_q4.4); `ftchp58_q4` (claim_button_tapped: chp58_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp58_q4.1` | Debate hygiene | `collect_and_interact`; `furr_white` × 1 | `2241c` | `none` |
| `chp58_q4.2` | Debate cuteness | `collect_and_interact`; `yarn` × 3 | `2242a,2243c,2244b` | `none` |
| `chp58_q4.3` | Debate intelligence | `collect_and_interact`; `textbooks` × 3 | `2245c,2246a,2247b` | `none` |
| `chp58_q4.4` | Debate athleticism | `collect_and_interact`; `dumbbells` × 3 | `2248c,2249b,2250c` | `none` |
| `chp58_q4.5` | Reach Village Rank 113 | `reach_rank`; `harmony` × 113 | `none` | `none` |

