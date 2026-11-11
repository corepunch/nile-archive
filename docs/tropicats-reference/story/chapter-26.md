# Chapter 26

[Story index](../STORY.md) · [Previous](chapter-25.md) · [Next](chapter-27.md)

Configured chapter start: campaign level **931**; starts with `chp26_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Barker is identified as the poisoner, acting for the mysterious Mother. Ragnaruff becomes king; the Mother invites the Chief to the Island of the Ancients, and Taka recognizes his mother's poison recipe.

## chp26_q1: Who Poisoned The King?

Configured quest `level` **931**; assigned character **Elsie**.

Setup (localized quest text): “King Gruffgar was poisoned! We must find out who did it... once we cure him, that is.”

Journal outcome (localized quest text): “Chief and Lt. Meowser cracked the case! Cpt. Barker poisoned Gruffgar. But we discovered Barker was working for a shady character called the Mother. Who is this mother? And why would she want to start a war between dogs and Impurrials?”

Configured scenes: `chp26_q1` (quest_start: chp26_q1); `t1chp26_q1` (quest_task_completed: chp26_q1.1); `t2chp26_q1` (quest_task_completed: chp26_q1.2); `t3chp26_q1` (quest_task_completed: chp26_q1.3); `t4chp26_q1` (quest_task_completed: chp26_q1.4); `ftchp26_q1` (claim_button_tapped: chp26_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp26_q1.1` | Find out what Captain Barker knows | `collect_and_interact`; `magn_glass` × 3 | `931a,932c,933b` | `none` |
| `chp26_q1.2` | Search Barker’s room for evidence | `collect_and_interact`; `scroll` × 2 | `934c,935a` | `none` |
| `chp26_q1.3` | Investigate the dog tracks | `collect_and_interact`; `SnowPrint` × 2 | `936c,937b` | `none` |
| `chp26_q1.4` | Make a cure for King Gruffgar | `collect_and_interact`; `herb` × 3 | `938c,939a,940c` | `none` |

## chp26_q2: Repair The Nordog Throne

Configured quest `level` **941**; assigned character **Elsie**.

Setup (localized quest text): “Chief, I’m gonna be King of the Nordogs! Well, I will if we can fix the throne. You can’t be a king without a giant chair!”

Journal outcome (localized quest text): “We repaired the Nordog throne and I was crowned King of the Nordogs. I never thought THAT would happen. Meanwhile, Meowser questioned Barker about the Mother. Apparently she'll only ever appear near the village runestone.”

Configured scenes: `chp26_q2` (quest_start: chp26_q2); `t1chp26_q2` (quest_task_completed: chp26_q2.1); `t2chp26_q2` (quest_task_completed: chp26_q2.2); `t3chp26_q2` (quest_task_completed: chp26_q2.3); `t4chp26_q2` (quest_task_completed: chp26_q2.4); `ftchp26_q2` (claim_button_tapped: chp26_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp26_q2.1` | Repair the Nordog throne | `collect_and_repair`; `log` × 1 | `941c` | `ch26_throne_dog` |
| `chp26_q2.2` | Send out invitations to the coronation | `collect_and_interact`; `RedLetter` × 3 | `942a,943c,944b` | `none` |
| `chp26_q2.3` | Prepare the coronation feast | `collect_and_interact`; `fish` × 5 | `945c,946b,947a,948b,949c` | `none` |
| `chp26_q2.4` | Find the royal shield | `collect_and_interact`; `shield` × 1 | `950b` | `none` |
| `chp26_q2.5` | Reach Village Rank 48 | `reach_rank`; `harmony` × 48 | `none` | `none` |

## chp26_q3: Mother Knows Best

Configured quest `level` **951**; assigned character **Elsie**.

Setup (localized quest text): “A mysterious figure called "the Mother" seems to have orchestrated the whole war. If we repair the old runestone, she may appear on the island.”

Journal outcome (localized quest text): “We finally met The Mother. She admitted to starting the war, but said it was for good reasons. She also seemed to know Olivia and Taka! The Mother promised to explain all if Chief meets her on the Island of the Ancients, which is somewhere west of Tropicat Island...”

Configured scenes: `chp26_q3` (quest_start: chp26_q3); `t1chp26_q3` (quest_task_completed: chp26_q3.1); `t2chp26_q3` (quest_task_completed: chp26_q3.2); `t3chp26_q3` (quest_task_completed: chp26_q3.3); `t4chp26_q3` (quest_task_completed: chp26_q3.4); `ftchp26_q3` (claim_button_tapped: chp26_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp26_q3.1` | Repair the runestone | `collect_and_repair`; `stone` × 1 | `951a` | `ch26_runestone_dog` |
| `chp26_q3.2` | Interrogate Captain Barker about the Mother | `collect_and_interact`; `magn_glass` × 3 | `952c,953b,954c` | `none` |
| `chp26_q3.3` | Say goodbye to Gruffgar | `collect_and_interact`; `bouquet` × 3 | `955b,956c,957a` | `none` |
| `chp26_q3.4` | Make some bandages for Lt. Meowser | `collect_and_interact`; `cotton` × 3 | `958c,959a,960c` | `none` |

## chp26_q4: An Ancient Truth

Configured quest `level` **961**; assigned character **Elsie**.

Setup (localized quest text): “Olivia here! We must find out how to reach the Island of the Ancients. The Mother told us we'll find "the truth" when we get there...”

Journal outcome (localized quest text): “Olivia here! I’ll be updating the diary for a while! We found a map and set sail to the Island of the Ancients. Meanwhile, Taka discovered that the recipe for the Mother’s poison was exactly the same as one written by... his own mom! Is the Mother TAKA’s mother?? But she’s dead... all our parents are dead...”

Configured scenes: `chp26_q4` (quest_start: chp26_q4); `t1chp26_q4` (quest_task_completed: chp26_q4.1); `t2chp26_q4` (quest_task_completed: chp26_q4.2); `t3chp26_q4` (quest_task_completed: chp26_q4.3); `t4chp26_q4` (quest_task_completed: chp26_q4.4); `ftchp26_q4` (claim_button_tapped: chp26_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp26_q4.1` | Research the Mother's poison | `collect_and_interact`; `scroll` × 3 | `961b,962a,963c` | `none` |
| `chp26_q4.2` | Ask Alapa about the Island of the Ancients | `collect_and_interact`; `magn_glass` × 2 | `964b,965c` | `none` |
| `chp26_q4.3` | Collect supplies for the journey | `collect_and_interact`; `lockbox` × 3 | `966a,967b,968c` | `none` |
| `chp26_q4.4` | Find a map to the Island of the Ancients | `collect_and_interact`; `map` × 2 | `969b,970c` | `none` |
| `chp26_q4.5` | Reach Village Rank 49 | `reach_rank`; `harmony` × 49 | `none` | `none` |

