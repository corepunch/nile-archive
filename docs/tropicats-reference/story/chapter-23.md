# Chapter 23: A Hero's Welcome

[Story index](../STORY.md) · [Previous](chapter-22.md) · [Next](chapter-24.md)

Campaign levels **811–850**; starts with `chp23_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Nordog Island is burned and abandoned; the Impurrial spy Meowser admits accidentally causing the fire. A restored horn recalls King Gruffgar's fleet, but the king still plans war and Meowser's execution.

## chp23_q1: Ashes To Ashes

Configured quest `level` **811**; assigned character **Elsie**.

Setup (localized quest text): “Ragnaruff here. I can't believe it... Nordog Village is a pile of ashes! Let’s clean up the debris and figure out who did this.”

Journal outcome (localized quest text): “Chief and I finally found my long-lost home, Nordog Island. But the entire village had been burned to the ground and no one was around. Chief found cat tracks leading to a hideout in the forest. Inside was an Impurrial soldier called Lt. Meowser. Did the Impurrials destroy my village?”

Configured scenes: `chp23_q1` (quest_start: chp23_q1); `t1chp23_q1` (quest_task_completed: chp23_q1.1); `t2chp23_q1` (quest_task_completed: chp23_q1.2); `t3chp23_q1` (quest_task_completed: chp23_q1.3); `t4chp23_q1` (quest_task_completed: chp23_q1.4); `ftchp23_q1` (claim_button_tapped: chp23_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp23_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 3 | `811b,812c,813a` | `ch23_rubble` |
| `chp23_q1.2` | Look for suspicious tracks | `collect_and_interact`; `SnowPrint` × 3 | `814c,815a,816c` | `none` |
| `chp23_q1.3` | Search the remains of Ragnaruff's hut | `collect_and_interact`; `scroll` × 3 | `817b,818c,819a` | `none` |
| `chp23_q1.4` | Open Redd's luggage | `collect_and_interact`; `lockbox` × 1 | `820b` | `none` |

## chp23_q2: Tea For Talk

Configured quest `level` **821**; assigned character **Elsie**.

Setup (localized quest text): “Lt. Meowser refuses to talk. This Impurrial soldier must have something to do with the village burning down. Let’s find a way to loosen his lips.”

Journal outcome (localized quest text): “Lt. Meowser came to Nordog Island because he'd heard rumors our king wanted to attack Impurrial City. While spying, he accidentally burned down the village. Now the King and his army have set sail for Impurrial waters. Meowser thinks the Impurrial Queen will blame him for starting a war. Is there a way to call back the King?”

Configured scenes: `chp23_q2` (quest_start: chp23_q2); `t1chp23_q2` (quest_task_completed: chp23_q2.1); `t2chp23_q2` (quest_task_completed: chp23_q2.2); `t3chp23_q2` (quest_task_completed: chp23_q2.3); `t4chp23_q2` (quest_task_completed: chp23_q2.4); `ftchp23_q2` (claim_button_tapped: chp23_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp23_q2.1` | Tempt Meowser with tea | `collect_and_interact`; `DogTea` × 3 | `821c,822a,823b` | `none` |
| `chp23_q2.2` | Find Meowser's medication | `collect_and_interact`; `medicine` × 2 | `824c,825b` | `none` |
| `chp23_q2.3` | Ask Lily to talk to Meowser | `collect_and_interact`; `cake` × 2 | `826c,827b` | `none` |
| `chp23_q2.4` | Insult the Impurrial Queen | `collect_and_interact`; `queen` × 3 | `828c,829b,830a` | `none` |
| `chp23_q2.5` | Reach Village Rank 42 | `reach_rank`; `harmony` × 42 | `none` | `none` |

## chp23_q3: Ain't Nothing But A Howldog

Configured quest `level` **831**; assigned character **Elsie**.

Setup (localized quest text): “The Nordog army has set sail for Impurrial City. Repair the Howling Horn and call back the fleet, before the isles are plunged into war.”

Journal outcome (localized quest text): “Chief repaired the Howling Horn and I blew it, which turned the fleet around. Meowser said the King has lost his mind and believes angels want him to destroy Impurrial City. Has the King really gone mad? And how can we change his mind about the war?”

Configured scenes: `chp23_q3` (quest_start: chp23_q3); `t1chp23_q3` (quest_task_completed: chp23_q3.1); `t2chp23_q3` (quest_task_completed: chp23_q3.2); `t3chp23_q3` (quest_task_completed: chp23_q3.3); `t4chp23_q3` (quest_task_completed: chp23_q3.4); `ftchp23_q3` (claim_button_tapped: chp23_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp23_q3.1` | Repair the Howling Horn | `collect_and_repair`; `stone` × 2 | `831c,832a` | `ch23_horn_dog` |
| `chp23_q3.2` | Find the origin of the fire | `collect_and_interact`; `BurntSausage` × 3 | `833c,834b,835a` | `none` |
| `chp23_q3.3` | Return Meowser's lost medals | `collect_and_interact`; `medal` × 3 | `836b,837c,838b` | `none` |
| `chp23_q3.4` | Get more medicine for Meowser | `collect_and_interact`; `medicine` × 2 | `839c,840b` | `none` |

## chp23_q4: Return Of The King

Configured quest `level` **841**; assigned character **Elsie**.

Setup (localized quest text): “King Gruffgar’s ship approaches! How can we change his mind about waging war? The Code of Canines might give us a solution. The King lives his life by those codes...”

Journal outcome (localized quest text): “"Never bite unless bitten." We thought this law in the Code of Canines would stop the King from waging war. But King Gruffgar was not convinced. He thanked us for "capturing" Meowser and is going to execute him, before setting sail for Impurrial City.”

Configured scenes: `chp23_q4` (quest_start: chp23_q4); `t1chp23_q4` (quest_task_completed: chp23_q4.1); `t2chp23_q4` (quest_task_completed: chp23_q4.2); `t3chp23_q4` (quest_task_completed: chp23_q4.3); `t4chp23_q4` (quest_task_completed: chp23_q4.4); `ftchp23_q4` (claim_button_tapped: chp23_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp23_q4.1` | Read the Code of Canines | `collect_and_interact`; `BookNordog` × 2 | `841b,842c,843b` | `none` |
| `chp23_q4.2` | Fix the lantern | `collect_and_repair`; `log` × 3 | `844a,845c,846b` | `ch23_lantern` |
| `chp23_q4.3` | Find Fenrir statues | `collect_and_interact`; `fenrir` × 2 | `847c,848a,849c` | `none` |
| `chp23_q4.4` | Deliver a letter to Ava | `collect_and_interact`; `RedLetter` × 3 | `850b` | `none` |
| `chp23_q4.5` | Reach Village Rank 43 | `reach_rank`; `harmony` × 43 | `none` | `none` |

