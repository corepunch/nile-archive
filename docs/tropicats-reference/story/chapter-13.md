# Chapter 13: The Beacon

[Story index](../STORY.md) · [Previous](chapter-12.md) · [Next](chapter-14.md)

Campaign levels **411–450**; starts with `chp13_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The twins Layla and Milo meet the tribe. A lighthouse and harbor are built to invite visitors, and the first arriving ship raises the possibility of pirates.

## chp13_q1: Tropikittens!

Configured quest `level` **411**; assigned character **Elsie**.

Setup (localized quest text): “Cubby is one proud dad! Olivia has asked him to grab some supplies. It’s the perfect chance to show off the kittens to the rest of the tribe.”

Journal outcome (localized quest text): “Cubby and Olivia have had two gorgeous kittens named Layla and Milo. They are soooo cute! Cubby thinks it’s time to open up the island to visitors from around the world.”

Configured scenes: `chp13_q1` (quest_start: chp13_q1); `t1chp13_q1` (quest_task_completed: chp13_q1.1); `t2chp13_q1` (quest_task_completed: chp13_q1.2); `t3chp13_q1` (quest_task_completed: chp13_q1.3); `t4chp13_q1` (quest_task_completed: chp13_q1.4); `ftchp13_q1` (claim_button_tapped: chp13_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp13_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 2 | `411a,412c` | `ch13_rubble` |
| `chp13_q1.2` | Fetch diapers from Elsie | `collect_and_interact`; `diaper` × 3 | `413a,414c,415a` | `none` |
| `chp13_q1.3` | Visit Taka for cotton buds | `collect_and_interact`; `cotton` × 3 | `416c,417b,418a` | `none` |
| `chp13_q1.4` | Get brushes from Ragnaruff | `collect_and_interact`; `grooming_brush` × 2 | `419b,420c` | `none` |

## chp13_q2: Attracting Attention

Configured quest `level` **421**; assigned character **Elsie**.

Setup (localized quest text): “We’ve decided to open up the island to visitors, but now we need to find a way to tell the world that we are here! Everyone has an idea to share.”

Journal outcome (localized quest text): “It’s been decided. We’re going to build a lighty hut thing - a tower with a big light on the top to signal passing ships. How exciting!”

Configured scenes: `chp13_q2` (quest_start: chp13_q2); `t1chp13_q2` (quest_task_completed: chp13_q2.1); `t2chp13_q2` (quest_task_completed: chp13_q2.2); `t3chp13_q2` (quest_task_completed: chp13_q2.3); `t4chp13_q2` (quest_task_completed: chp13_q2.4); `ftchp13_q2` (claim_button_tapped: chp13_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp13_q2.1` | Detonate fireworks | `collect_and_interact`; `fireworks` × 3 | `421b,422a,423c` | `none` |
| `chp13_q2.2` | Send messages in bottles | `collect_and_interact`; `ceramic_bottle` × 2 | `424b,425c` | `none` |
| `chp13_q2.3` | Play some loud music | `collect_and_interact`; `ukulele` × 2 | `426a,427c` | `none` |
| `chp13_q2.4` | Reflect the sunlight | `collect_and_interact`; `magn_glass` × 3 | `428b,429c,430b` | `none` |
| `chp13_q2.5` | Reach Village Rank 22 | `reach_rank`; `harmony` × 22 | `none` | `none` |

## chp13_q3: Let There Be Light

Configured quest `level` **431**; assigned character **Elsie**.

Setup (localized quest text): “We’re going to build a tall lighty hut to attract passing ships. When they see the bright light, they’ll come to visit the island!”

Journal outcome (localized quest text): “The lighthouse is ready, and the glowing lantern can be seen for miles! Any passing ships are sure to see it, which means we now need a harbor!”

Configured scenes: `chp13_q3` (quest_start: chp13_q3); `t1chp13_q3` (quest_task_completed: chp13_q3.1); `t2chp13_q3` (quest_task_completed: chp13_q3.2); `t3chp13_q3` (quest_task_completed: chp13_q3.3); `t4chp13_q3` (quest_task_completed: chp13_q3.4); `ftchp13_q3` (claim_button_tapped: chp13_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp13_q3.1` | Collect fireflies | `collect_and_interact`; `firefly` × 3 | `431b,432b,433b` | `none` |
| `chp13_q3.2` | Find spinning mirrored objects | `collect_and_interact`; `discoball` × 2 | `434b,435c` | `none` |
| `chp13_q3.3` | Build the lighthouse | `collect_and_repair`; `log` × 3 | `436b,437a,438c` | `ch13_lighthouse` |
| `chp13_q3.4` | Construct a bench | `collect_and_repair`; `bamboo` × 2 | `439a,440c` | `ch13_lighthouse_bench` |

## chp13_q4: Safe Harbor

Configured quest `level` **441**; assigned character **Elsie**.

Setup (localized quest text): “If ships are going to visit, they’ll need a place to dock. We need to build a welcoming harbor for the island!”

Journal outcome (localized quest text): “The lighthouse and harbor are ready, and we’ve already attracted the first ship. What is that strange black flag the ship is flying though? Could it be... pirates?”

Configured scenes: `chp13_q4` (quest_start: chp13_q4); `t1chp13_q4` (quest_task_completed: chp13_q4.1); `t2chp13_q4` (quest_task_completed: chp13_q4.2); `t3chp13_q4` (quest_task_completed: chp13_q4.3); `ftchp13_q4` (claim_button_tapped: chp13_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp13_q4.1` | Construct jetties for the harbor | `collect_and_repair`; `log` × 3 | `441b,442b,443b` | `ch13_jetty` |
| `chp13_q4.2` | Paint and varnish the area | `collect_and_interact`; `paintbrush` × 2 | `444c,445b` | `none` |
| `chp13_q4.3` | Decorate the harbor with anchors | `collect_and_repair`; `anchor` × 5 | `446a,447c,448a,449c,450b` | `ch13_jetty_stuff` |
| `chp13_q4.4` | Reach Village Rank 23 | `reach_rank`; `harmony` × 23 | `none` | `none` |

