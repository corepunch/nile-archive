# Chapter 52: Furgive And Furget

[Story index](../STORY.md) · [Previous](chapter-51.md) · [Next](chapter-53.md)

Campaign levels **1971–2010**; starts with `chp52_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Felicity sees Mee Li's change and the pair reconcile. Meanwhile Cubby struggles to care for the kittens without Olivia, and the steamship is completed to take her home.

## chp52_q1: A Second Chance

Configured quest `level` **1971**; assigned character **Elsie**.

Setup (localized quest text): “We've got to prove to Felicity that Mee Li's changed, Chief!”

Journal outcome (localized quest text): “Felicity saw a brand new Mee Li, and just as I'd planned all along, she couldn't resist! Well... you helped, of course. That's why I love ya, Chief!”

Configured scenes: `chp52_q1` (quest_start: chp52_q1); `t1chp52_q1` (quest_task_completed: chp52_q1.1); `t2chp52_q1` (quest_task_completed: chp52_q1.2); `t3chp52_q1` (quest_task_completed: chp52_q1.3); `t4chp52_q1` (quest_task_completed: chp52_q1.4); `ftchp52_q1` (claim_button_tapped: chp52_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp52_q1.1` | Show Felicity the Kit Inn | `collect_and_interact`; `magn_glass` × 3 | `1971a,1972b,1973c` | `none` |
| `chp52_q1.2` | Talk to Felicity about Mee Li | `collect_and_repair`; `elsie_bell` × 3 | `1974a,1975c,1976b` | `none` |
| `chp52_q1.3` | Make the inn more relaxing | `collect_and_repair`; `log` × 2 | `1977c,1978a` | `ch52_bnb_expansion` |
| `chp52_q1.4` | Spy on Mee Li | `collect_and_interact`; `spyglass` × 2 | `1979b,1980c` | `none` |

## chp52_q2: The Second First Date

Configured quest `level` **1981**; assigned character **Elsie**.

Setup (localized quest text): “Elsie won't leave Mee Li and Felicity alone! Let's distract her.”

Journal outcome (localized quest text): “I didn't like being kept away from Mee Li and Felicity. I get it, though. I get a little... excited about love. Besides, Mee Li and Felicity had a great time!”

Configured scenes: `chp52_q2` (quest_start: chp52_q2); `t1chp52_q2` (quest_task_completed: chp52_q2.1); `t2chp52_q2` (quest_task_completed: chp52_q2.2); `t3chp52_q2` (quest_task_completed: chp52_q2.3); `t4chp52_q2` (quest_task_completed: chp52_q2.4); `ftchp52_q2` (claim_button_tapped: chp52_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp52_q2.1` | Perform a makeover | `collect_and_interact`; `elsie_makeup` × 2 | `1981b,1982a` | `none` |
| `chp52_q2.2` | Cook with Blacktail | `collect_and_interact`; `kitchen_knife` × 3 | `1983c,1984b,1985a` | `none` |
| `chp52_q2.3` | Keep a lookout for Elsie | `collect_and_interact`; `spyglass` × 1 | `1986c` | `none` |
| `chp52_q2.4` | Lock the doors to the Kit Inn | `collect_and_interact`; `key` × 4 | `1987a,1988c,1989b,1990c` | `none` |
| `chp52_q2.5` | Reach Village Rank 100 | `reach_rank`; `harmony` × 100 | `none` | `none` |

## chp52_q3: Mo' Kittens, Mo' Problems

Configured quest `level` **1991**; assigned character **Elsie**.

Setup (localized quest text): “Kip and Lily are getting a little rambunctious. We've gotta do something about it, Chief!”

Journal outcome (localized quest text): “Hey, Chief. Cubby here taking over for Elsie. I didn't know where Olivia was, but one thing was sure... I couldn't take care of Lily and Kip AND the kittens on my own. Thank goodness Ragnaruff came to help!”

Configured scenes: `chp52_q3` (quest_start: chp52_q3); `t1chp52_q3` (quest_task_completed: chp52_q3.1); `t2chp52_q3` (quest_task_completed: chp52_q3.2); `t3chp52_q3` (quest_task_completed: chp52_q3.3); `t4chp52_q3` (quest_task_completed: chp52_q3.4); `ftchp52_q3` (claim_button_tapped: chp52_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp52_q3.1` | Entertain the kittens | `collect_and_interact`; `kitchen_knife` × 3 | `1991c,1992b,1993c` | `none` |
| `chp52_q3.2` | Recruit Alapa | `collect_and_interact`; `jesterstick` × 3 | `1994a,1995b,1996c` | `none` |
| `chp52_q3.3` | Put Layla and Milo to sleep | `collect_and_interact`; `rattle` × 2 | `1997a,1998b` | `none` |
| `chp52_q3.4` | Write Ragnaruff a letter | `collect_and_interact`; `RedLetter` × 2 | `1999c,2000b` | `none` |

## chp52_q4: Anchors Aweigh

Configured quest `level` **2001**; assigned character **Elsie**.

Setup (localized quest text): “It's time to set sail for Tropicat Island, Chief! Let's get ready.”

Journal outcome (localized quest text): “It's me, Elsie, taking the diary back, Chief. We did it. Ava and Meownardo built the steam ship, and finally we were going to get Olivia back to her kittens. We were all relieved!”

Configured scenes: `chp52_q4` (quest_start: chp52_q4); `t1chp52_q4` (quest_task_completed: chp52_q4.1); `t2chp52_q4` (quest_task_completed: chp52_q4.2); `t3chp52_q4` (quest_task_completed: chp52_q4.3); `t4chp52_q4` (quest_task_completed: chp52_q4.4); `ftchp52_q4` (claim_button_tapped: chp52_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp52_q4.1` | Collect some coal | `collect_and_interact`; `coal` × 1 | `2001a` | `none` |
| `chp52_q4.2` | Test the engine | `collect_and_interact`; `magn_glass` × 3 | `2002c,2003b,2004c` | `none` |
| `chp52_q4.3` | Install the steering wheel | `collect_and_interact`; `shipwheel` × 4 | `2005a,2006c,2007a,2008c` | `none` |
| `chp52_q4.4` | Move the ship into the sea | `collect_and_interact`; `tracks_3` × 2 | `2009b,2010c` | `none` |
| `chp52_q4.5` | Reach Village Rank 101 | `reach_rank`; `harmony` × 101 | `none` | `none` |

