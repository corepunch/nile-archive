# Chapter 56: Too Mewl For School

[Story index](../STORY.md) · [Previous](chapter-55.md) · [Next](chapter-57.md)

Campaign levels **2131–2170**; starts with `chp56_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Kip dislikes his first classes and resents Lily's success while the adults improve the school. Redd wonders whether he is a cat or a dog, and attempts to manage Kip's behavior deepen his frustration.

## chp56_q1: School Kittens

Configured quest `level` **2131**; assigned character **Elsie**.

Setup (localized quest text): “It's the first day of school. Let's make it a good one, Chief!”

Journal outcome (localized quest text): “I didn't have a great first day of school, Chief. I hated my meowgic and history classes. Lily got all the answers right. Why does she have to be such a know-it-all, Chief?”

Configured scenes: `chp56_q1` (quest_start: chp56_q1); `t1chp56_q1` (quest_task_completed: chp56_q1.1); `t2chp56_q1` (quest_task_completed: chp56_q1.2); `t3chp56_q1` (quest_task_completed: chp56_q1.3); `t4chp56_q1` (quest_task_completed: chp56_q1.4); `ftchp56_q1` (claim_button_tapped: chp56_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp56_q1.1` | Introduce a late student | `collect_and_interact`; `backpack` × 3 | `2131a,2132b,2133c` | `none` |
| `chp56_q1.2` | Begin meowgic class | `collect_and_interact`; `meowgiccrystal` × 2 | `2134b,2135c` | `none` |
| `chp56_q1.3` | Begin history class | `collect_and_interact`; `textbooks` × 2 | `2136b,2137b` | `none` |
| `chp56_q1.4` | Begin gym class | `collect_and_interact`; `dumbbells` × 3 | `2138a,2139b,2140c` | `none` |

## chp56_q2: A Place To Learn

Configured quest `level` **2141**; assigned character **Elsie**.

Setup (localized quest text): “It's not enough to have a school. We've gotta make it look good, Chief!”

Journal outcome (localized quest text): “All the grown-ups were working really hard to make the school look nice. I don't know why. Who would ever want to go to school? I admit it does look kinda nice, though...”

Configured scenes: `chp56_q2` (quest_start: chp56_q2); `t1chp56_q2` (quest_task_completed: chp56_q2.1); `t2chp56_q2` (quest_task_completed: chp56_q2.2); `t3chp56_q2` (quest_task_completed: chp56_q2.3); `t4chp56_q2` (quest_task_completed: chp56_q2.4); `ftchp56_q2` (claim_button_tapped: chp56_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp56_q2.1` | Decorate the classrooms | `collect_and_interact`; `paintbrush` × 1 | `2141a` | `none` |
| `chp56_q2.2` | Build some walkways | `collect_and_repair`; `stone` × 3 | `2142b,2143c,2144b` | `ch56_university_paths` |
| `chp56_q2.3` | Build a bench | `collect_and_repair`; `log` × 3 | `2145a,2146c,2147a` | `ch56_university_bench` |
| `chp56_q2.4` | Finish the quad | `collect_and_repair`; `SnowPrint` × 3 | `2148c,2149b,2150c` | `ch56_university_mainfences` |
| `chp56_q2.5` | Reach Village Rank 108 | `reach_rank`; `harmony` × 108 | `none` | `none` |

## chp56_q3: Neither Dog Nor Cat

Configured quest `level` **2151**; assigned character **Elsie**.

Setup (localized quest text): “Redd isn't sure whether he's a dog or a cat. Let's help him find out, Chief!”

Journal outcome (localized quest text): “Redd wasn't sure whether he was a cat or a dog, but I knew the answer! Redd looked like a dog, and he smelled like a dog, and he played like a dog... but I'm not sure I convinced him he is one.”

Configured scenes: `chp56_q3` (quest_start: chp56_q3); `t1chp56_q3` (quest_task_completed: chp56_q3.1); `t2chp56_q3` (quest_task_completed: chp56_q3.2); `t3chp56_q3` (quest_task_completed: chp56_q3.3); `t4chp56_q3` (quest_task_completed: chp56_q3.4); `ftchp56_q3` (claim_button_tapped: chp56_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp56_q3.1` | Play with Lily | `collect_and_interact`; `yarn` × 1 | `2151b` | `none` |
| `chp56_q3.2` | Play with Kip | `collect_and_interact`; `SnowPrint` × 3 | `2152c,2153a,2154b` | `none` |
| `chp56_q3.3` | Talk to the dean | `collect_and_interact`; `magn_glass` × 3 | `2155c,2156b,2157c` | `none` |
| `chp56_q3.4` | Ask Sylvia for help | `collect_and_interact`; `book` × 3 | `2158b,2159a,2160c` | `none` |

## chp56_q4: One Bad Kitty

Configured quest `level` **2161**; assigned character **Elsie**.

Setup (localized quest text): “We've got to do something about Kip's behavior, Chief!”

Journal outcome (localized quest text): “Everyone at school was giving me a hard time. Why couldn't they leave me alone? I'm just a kit! They kept trying all this stuff, but it just made me more and more frustrated.”

Configured scenes: `chp56_q4` (quest_start: chp56_q4); `t1chp56_q4` (quest_task_completed: chp56_q4.1); `t2chp56_q4` (quest_task_completed: chp56_q4.2); `t3chp56_q4` (quest_task_completed: chp56_q4.3); `t4chp56_q4` (quest_task_completed: chp56_q4.4); `ftchp56_q4` (claim_button_tapped: chp56_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp56_q4.1` | Teach Kip not to interrupt | `collect_and_interact`; `chalkboard` × 3 | `2161c,2162b,2163a` | `none` |
| `chp56_q4.2` | Post the dean's list | `collect_and_interact`; `page` × 3 | `2164a,2165b,2166c` | `none` |
| `chp56_q4.3` | Offer Kip some tutoring | `collect_and_interact`; `textbooks` × 3 | `2167b,2168c,2169b` | `none` |
| `chp56_q4.4` | Grade Kip's paper | `collect_and_interact`; `pen` × 1 | `2170c` | `none` |
| `chp56_q4.5` | Reach Village Rank 109 | `reach_rank`; `harmony` × 109 | `none` | `none` |

