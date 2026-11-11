# Chapter 67: Tropicruel Cats

[Story index](../STORY.md) · [Previous](chapter-66.md) · [Next](chapter-68.md)

Campaign levels **2571–2610**; starts with `chp67_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Elsie trains to confront Purrcini, with Sylvia urging her on. Nibblesby builds an information network among hamster butlers, and Sherlock Bones discovers a secret about the Queen's claim to rule.

## chp67_q1: Karate Cat

Configured quest `level` **2571**; assigned character **Elsie**.

Setup (localized quest text): “We need a place for Elsie to train to beat Purrcini! Help us out, Chief.”

Journal outcome (localized quest text): “Hey, Chief, it's me, Elsie. I'm going to take over the diary for now. I was having a really hard time missing Blacktail, but Sylvia built a really cool training ground for me. When I see Purrcini, he's going to regret stealing my husband!”

Configured scenes: `chp67_q1` (quest_start: chp67_q1); `t1chp67_q1` (quest_task_completed: chp67_q1.1); `t2chp67_q1` (quest_task_completed: chp67_q1.2); `t3chp67_q1` (quest_task_completed: chp67_q1.3); `t4chp67_q1` (quest_task_completed: chp67_q1.4); `ftchp67_q1` (claim_button_tapped: chp67_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp67_q1.1` | Remove Olivia's cone | `collect_and_interact`; `tracks_1` × 3 | `2571a,2572b,2573c` | `none` |
| `chp67_q1.2` | Receive a letter | `collect_and_interact`; `BlueLetter` × 3 | `2574b,2575a,2576b` | `none` |
| `chp67_q1.3` | Talk to Other Blacktail | `collect_and_interact`; `magn_glass` × 3 | `2577c,2578b,2579c` | `none` |
| `chp67_q1.4` | Build a training ground | `collect_and_repair`; `log` × 1 | `2580b` | `ch67_training` |

## chp67_q2: Claws Out

Configured quest `level` **2581**; assigned character **Elsie**.

Setup (localized quest text): “Elsie is training hard and we have to band together to support her!”

Journal outcome (localized quest text): “I am working really hard to make sure I am in top shape when I face Purrcini. My friends are all being really helpful, but they are concerned I am working too hard. Sylvia is keeping me motivated, though!”

Configured scenes: `chp67_q2` (quest_start: chp67_q2); `t1chp67_q2` (quest_task_completed: chp67_q2.1); `t2chp67_q2` (quest_task_completed: chp67_q2.2); `t3chp67_q2` (quest_task_completed: chp67_q2.3); `t4chp67_q2` (quest_task_completed: chp67_q2.4); `ftchp67_q2` (claim_button_tapped: chp67_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp67_q2.1` | Improve Elsie's nutrition | `collect_and_interact`; `herb` × 3 | `2581b,2582c,2583a` | `none` |
| `chp67_q2.2` | Confide in Bianca | `collect_and_interact`; `elsie_bell` × 2 | `2584c,2585b` | `none` |
| `chp67_q2.3` | Catch up with Lily and Kip | `collect_and_interact`; `magn_glass` × 2 | `2586a,2587b` | `none` |
| `chp67_q2.4` | Gather more crystals | `collect_and_interact`; `meowgiccrystal` × 3 | `2588c,2589a,2590c` | `none` |
| `chp67_q2.5` | Reach Village Rank 130 | `reach_rank`; `harmony` × 130 | `none` | `none` |

## chp67_q3: Nibblesby's Task

Configured quest `level` **2591**; assigned character **Elsie**.

Setup (localized quest text): “The hamsters are ready to revolt! Let's build them an information network.”

Journal outcome (localized quest text): “Greetings, Chief! It's me, Agent Nibblesby. With the Duchess's blessing, we set to work on an information network where all hamster butlers can share secrets. It certainly smells like a revolution!”

Configured scenes: `chp67_q3` (quest_start: chp67_q3); `t1chp67_q3` (quest_task_completed: chp67_q3.1); `t2chp67_q3` (quest_task_completed: chp67_q3.2); `t3chp67_q3` (quest_task_completed: chp67_q3.3); `t4chp67_q3` (quest_task_completed: chp67_q3.4); `ftchp67_q3` (claim_button_tapped: chp67_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp67_q3.1` | Devise some plans | `collect_and_interact`; `blueprints` × 2 | `2591a,2592c` | `none` |
| `chp67_q3.2` | Gather some glass | `collect_and_interact`; `magn_glass` × 3 | `2593a,2594c,2595a` | `none` |
| `chp67_q3.3` | Create a vacuum | `collect_and_interact`; `musicstand` × 3 | `2596c,2597b,2598c` | `none` |
| `chp67_q3.4` | Begin construction | `collect_and_interact`; `log` × 2 | `2599a,2600c` | `none` |

## chp67_q4: The Royal Lie

Configured quest `level` **2601**; assigned character **Elsie**.

Setup (localized quest text): “Sherlock Bones believes he's discovered something about our Queen. Let's reveal the secret!”

Journal outcome (localized quest text): “When I discovered the Queen had been lying to us all, why, I was as mad as a hamster could be! If she wasn't the true ruler of the isles, then who was? We have to set sail for the Island of the Ancients to tell the Tropicats!”

Configured scenes: `chp67_q4` (quest_start: chp67_q4); `t1chp67_q4` (quest_task_completed: chp67_q4.1); `t2chp67_q4` (quest_task_completed: chp67_q4.2); `t3chp67_q4` (quest_task_completed: chp67_q4.3); `t4chp67_q4` (quest_task_completed: chp67_q4.4); `ftchp67_q4` (claim_button_tapped: chp67_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp67_q4.1` | Search Nibblesby's information | `collect_and_interact`; `page` × 3 | `2601c,2602a,2603c` | `none` |
| `chp67_q4.2` | Consult with McYowler | `collect_and_interact`; `magn_glass` × 3 | `2604b,2605a,2606c` | `none` |
| `chp67_q4.3` | Examine the Book of Impurrial Peerage | `collect_and_interact`; `BookNordog` × 1 | `2607c` | `none` |
| `chp67_q4.4` | Keep Woodshavings quiet | `collect_and_interact`; `sword` × 3 | `2608b,2609a,2610c` | `none` |
| `chp67_q4.5` | Reach Village Rank 131 | `reach_rank`; `harmony` × 131 | `none` | `none` |

