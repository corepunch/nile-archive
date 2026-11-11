# Chapter 34: Ode To A Highland Cat

[Story index](../STORY.md) · [Previous](chapter-33.md) · [Next](chapter-35.md)

Campaign levels **1251–1290**; starts with `chp34_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Woodshavings accuses the guests, the Duchess grieves, and McYowler's body vanishes. The group tries to summon help despite a missing carrier pigeon; an unexpected visitor arrives.

## chp34_q1: Dial "M" For Meowrder

Configured quest `level` **1251**; assigned character **Elsie**.

Setup (localized quest text): “Lord McYowler is dead, and it looks like it wasn't an accident! We've got to get to the bottom of this, Chief!”

Journal outcome (localized quest text): “With McYowler dead, his servant, Woodshavings, started accusing everyone. It definitely seemed that McYowler was poisoned, but he didn't eat our food or drink the tea. There was a lot more to this mystery, somehow.”

Configured scenes: `chp34_q1` (quest_start: chp34_q1); `t1chp34_q1` (quest_task_completed: chp34_q1.1); `t2chp34_q1` (quest_task_completed: chp34_q1.2); `t3chp34_q1` (quest_task_completed: chp34_q1.3); `t4chp34_q1` (quest_task_completed: chp34_q1.4); `ftchp34_q1` (claim_button_tapped: chp34_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp34_q1.1` | Interrogate Felicity | `collect_and_interact`; `lantern` × 3 | `1251c,1252b,1253c` | `none` |
| `chp34_q1.2` | Interrogate Blacktail | `collect_and_repair`; `lantern` × 2 | `1254c,1255b` | `none` |
| `chp34_q1.3` | Interrogate Nibblesby | `collect_and_interact`; `lantern` × 2 | `1256c,1257a` | `none` |
| `chp34_q1.4` | Establish a motive | `collect_and_interact`; `page` × 3 | `1258a,1259b,1260c` | `none` |

## chp34_q2: Ode To A Highland Cat

Configured quest `level` **1261**; assigned character **Elsie**.

Setup (localized quest text): “Blaming each other is getting us nowhere, Chief. We have to do the right thing and make sure McYowler is honored. You'll help, right?”

Journal outcome (localized quest text): “The Duchess was so distraught, we had to make sure we took the time to remember Lord Angus McYowler properly. We only knew him for a short time, but he made an impression on everyone. The Duchess was heartbroken, but the Chief helped her get through her grief.”

Configured scenes: `chp34_q2` (quest_start: chp34_q2); `t1chp34_q2` (quest_task_completed: chp34_q2.1); `t2chp34_q2` (quest_task_completed: chp34_q2.2); `t3chp34_q2` (quest_task_completed: chp34_q2.3); `t4chp34_q2` (quest_task_completed: chp34_q2.4); `ftchp34_q2` (claim_button_tapped: chp34_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp34_q2.1` | Build a memorial to McYowler | `collect_and_repair`; `stone` × 1 | `1261a` | `ch33_mcyowler_memorial` |
| `chp34_q2.2` | Recite some Highland poetry | `collect_and_interact`; `page` × 3 | `1262c,1263b,1264c` | `none` |
| `chp34_q2.3` | Prepare a Highland dish | `collect_and_interact`; `kitchen_knife` × 3 | `1265a,1266b,1267c` | `none` |
| `chp34_q2.4` | Share memories of McYowler | `collect_and_interact`; `scrapbook` × 3 | `1268b,1269a,1270c` | `none` |
| `chp34_q2.5` | Reach Village Rank 64 | `reach_rank`; `harmony` × 64 | `none` | `none` |

## chp34_q3: McYowler Is Missing

Configured quest `level` **1271**; assigned character **Elsie**.

Setup (localized quest text): “Chief! Just when we thought things were settling down, McYowler's body disappeared! If we find it, maybe we'll find the culprit!”

Journal outcome (localized quest text): “We didn't know how it happened, but Lord McYowler's body just... disappeared! We looked all over, and figured out that none of us were strong enough to lift him. We had no clues and no suspects. What we needed more than anything was help.”

Configured scenes: `chp34_q3` (quest_start: chp34_q3); `t1chp34_q3` (quest_task_completed: chp34_q3.1); `t2chp34_q3` (quest_task_completed: chp34_q3.2); `t3chp34_q3` (quest_task_completed: chp34_q3.3); `t4chp34_q3` (quest_task_completed: chp34_q3.4); `ftchp34_q3` (claim_button_tapped: chp34_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp34_q3.1` | Search McYowler's room | `collect_and_interact`; `magn_glass` × 1 | `1271a` | `none` |
| `chp34_q3.2` | Search for tracks | `collect_and_interact`; `tracks_2` × 3 | `1272c,1273b,1274a` | `none` |
| `chp34_q3.3` | Conduct an experiment | `collect_and_interact`; `stone` × 3 | `1275c,1276a,1277b` | `none` |
| `chp34_q3.4` | Calm the Duchess | `collect_and_repair`; `grooming_brush` × 3 | `1278c,1279b,1280c` | `ch33_memorial_sitting` |

## chp34_q4: Pigeon Practice

Configured quest `level` **1281**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess's carrier pigeon went missing, on top of everything else, but we need help, Chief. We'll have to train a new one!”

Journal outcome (localized quest text): “We knew we had to send a pigeon for help, but the Duchess's carrier pigeon was missing. We tried to train one ourselves, but couldn't catch one, and the chickens weren't too helpful. Imagine our surprise when someone got a letter from us anyway and showed up at the front door!”

Configured scenes: `chp34_q4` (quest_start: chp34_q4); `t1chp34_q4` (quest_task_completed: chp34_q4.1); `t2chp34_q4` (quest_task_completed: chp34_q4.2); `t3chp34_q4` (quest_task_completed: chp34_q4.3); `t4chp34_q4` (quest_task_completed: chp34_q4.4); `ftchp34_q4` (claim_button_tapped: chp34_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp34_q4.1` | Find a book on pigeon training | `collect_and_interact`; `book` × 3 | `1281b,1282a,1283c` | `none` |
| `chp34_q4.2` | Prepare some bird food | `collect_and_interact`; `seed` × 3 | `1284a,1285b,1286c` | `none` |
| `chp34_q4.3` | Catch a pigeon | `collect_and_interact`; `vine` × 3 | `1287a,1288c,1289b` | `none` |
| `chp34_q4.4` | Train a chicken to fly | `collect_and_interact`; `chicken` × 1 | `1290c` | `none` |
| `chp34_q4.5` | Reach Village Rank 65 | `reach_rank`; `harmony` × 65 | `none` | `none` |

