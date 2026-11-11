# Chapter 69: Impurrial Interference

[Story index](../STORY.md) · [Previous](chapter-68.md) · [Next](chapter-70.md)

Campaign levels **2651–2690**; starts with `chp69_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The Queen and Purrcini arrive with Blacktail; Sylvia tries to undo the harm and Gruffgar attempts to reason with the Queen. When her claim is challenged, she attacks Elsie and Gruffgar intervenes.

## chp69_q1: Rulers And Mewlers

Configured quest `level` **2651**; assigned character **Elsie**.

Setup (localized quest text): “The Queen is here, and so is Blacktail! We have to help him, Chief.”

Journal outcome (localized quest text): “The Queen herself arrived with Purrcini on the Island of the Ancients, saying it belongs to her... along with Blacktail. I don't like her, Chief. I really don't like her. I don't care what it takes... I have to get my husband back!”

Configured scenes: `chp69_q1` (quest_start: chp69_q1); `t1chp69_q1` (quest_task_completed: chp69_q1.1); `t2chp69_q1` (quest_task_completed: chp69_q1.2); `t3chp69_q1` (quest_task_completed: chp69_q1.3); `t4chp69_q1` (quest_task_completed: chp69_q1.4); `ftchp69_q1` (claim_button_tapped: chp69_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp69_q1.1` | Ask about Blacktail | `collect_and_interact`; `magn_glass` × 3 | `2651a,2652b,2653c` | `none` |
| `chp69_q1.2` | Spy on the Queen | `collect_and_interact`; `spyglass` × 3 | `2654b,2655a,2656b` | `none` |
| `chp69_q1.3` | Threaten the Queen | `collect_and_interact`; `sword` × 2 | `2657c,2658b` | `none` |
| `chp69_q1.4` | Plead with Purrcini | `collect_and_interact`; `page` × 2 | `2659c,2660b` | `none` |

## chp69_q2: Sylvia's Second Chance

Configured quest `level` **2661**; assigned character **Elsie**.

Setup (localized quest text): “Sylvia thinks she can undo the work of Evil Sylvia. Let's help her out!”

Journal outcome (localized quest text): “The Queen is pretty pawful. She really does think that everything on the islands belongs to her, and I really can't stand cats like that. Poor Sylvia feels so guilty about what happened, but it wasn't her fault.”

Configured scenes: `chp69_q2` (quest_start: chp69_q2); `t1chp69_q2` (quest_task_completed: chp69_q2.1); `t2chp69_q2` (quest_task_completed: chp69_q2.2); `t3chp69_q2` (quest_task_completed: chp69_q2.3); `t4chp69_q2` (quest_task_completed: chp69_q2.4); `ftchp69_q2` (claim_button_tapped: chp69_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp69_q2.1` | Visit the fort | `collect_and_interact`; `tracks_1` × 4 | `2661b,2662c,2663b,2664a` | `none` |
| `chp69_q2.2` | Introduce Ragnaruff | `collect_and_interact`; `axe` × 3 | `2665b,2666c,2667b` | `none` |
| `chp69_q2.3` | Tell a story | `collect_and_interact`; `BookNordog` × 1 | `2668c` | `none` |
| `chp69_q2.4` | Meet Gruffgar | `collect_and_repair`; `DogTea` × 2 | `2669b,2670b` | `none` |
| `chp69_q2.5` | Reach Village Rank 134 | `reach_rank`; `harmony` × 134 | `none` | `none` |

## chp69_q3: A Dog's Life

Configured quest `level` **2671**; assigned character **Elsie**.

Setup (localized quest text): “Dean Gruffgar thinks the Queen might listen to some dog wisdom. Worth a try, right?”

Journal outcome (localized quest text): “I think that Dean Gruffgar is trying to get through to the Queen, but she is so set in her ways, I don't think she'll ever change. She would need for something big to happen, or for a big secret to come out...”

Configured scenes: `chp69_q3` (quest_start: chp69_q3); `t1chp69_q3` (quest_task_completed: chp69_q3.1); `t2chp69_q3` (quest_task_completed: chp69_q3.2); `t3chp69_q3` (quest_task_completed: chp69_q3.3); `t4chp69_q3` (quest_task_completed: chp69_q3.4); `ftchp69_q3` (claim_button_tapped: chp69_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp69_q3.1` | Tell the Queen something nice | `collect_and_interact`; `bouquet` × 1 | `2671c` | `none` |
| `chp69_q3.2` | Introduce yourself to the Queen | `collect_and_interact`; `magn_glass` × 4 | `2672b,2673c,2674a,2675b` | `none` |
| `chp69_q3.3` | Give the Queen a gift | `collect_and_interact`; `grilled_banana` × 1 | `2676c` | `none` |
| `chp69_q3.4` | Teach the Queen something new | `collect_and_interact`; `chalkboard` × 4 | `2677b,2678a,2679b,2680c` | `none` |

## chp69_q4: Hairball To The Throne

Configured quest `level` **2681**; assigned character **Elsie**.

Setup (localized quest text): “The Queen isn't the Queen! We're a little scared to tell her. Maybe you can help?”

Journal outcome (localized quest text): “No one has ever tried to kill me before. It's not a good feeling, Chief. I was so lucky to have Dean Gruffgar bravely jump in front of her blade, but I was so scared when I watched him fall to the ground in front of me...”

Configured scenes: `chp69_q4` (quest_start: chp69_q4); `t1chp69_q4` (quest_task_completed: chp69_q4.1); `t2chp69_q4` (quest_task_completed: chp69_q4.2); `t3chp69_q4` (quest_task_completed: chp69_q4.3); `t4chp69_q4` (quest_task_completed: chp69_q4.4); `ftchp69_q4` (claim_button_tapped: chp69_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp69_q4.1` | Practice confronting the Queen | `collect_and_interact`; `dumbbells` × 2 | `2681b,2682c` | `none` |
| `chp69_q4.2` | Explain the facts | `collect_and_interact`; `chalkboard` × 3 | `2683a,2684b,2685c` | `none` |
| `chp69_q4.3` | Speak with the Duchess | `collect_and_interact`; `magn_glass` × 2 | `2686b,2687b` | `none` |
| `chp69_q4.4` | Pluck up Elsie's courage | `collect_and_interact`; `elsie_bell` × 3 | `2688c,2689b,2690c` | `none` |
| `chp69_q4.5` | Reach Village Rank 135 | `reach_rank`; `harmony` × 135 | `none` | `none` |

