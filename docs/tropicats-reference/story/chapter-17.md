# Chapter 17

[Story index](../STORY.md) · [Previous](chapter-16.md) · [Next](chapter-18.md)

Configured chapter start: campaign level **571**; starts with `chp17_q1`. Task gates below are level/tier tokens, not guaranteed play order.

The tribe rescues inventor Mee Li and builds her a workshop. Her cure for Kip's cold appears successful, but mass-producing it exposes a side effect: leaves grow on his head.

## chp17_q1: Shipwrecked

Configured quest `level` **571**; assigned character **Elsie**.

Setup (localized quest text): “Someone is in trouble! A ship is sinking near the island. Let’s help Blacktail and Ragnaruff go to the rescue!”

Journal outcome (localized quest text): “We rescued the survivor from the sinking ship. She’s an inventor and merchant called Mee Li and she comes from a distant land. She seems ever so purrculiar.”

Configured scenes: `chp17_q1` (quest_start: chp17_q1); `t1chp17_q1` (quest_task_completed: chp17_q1.1); `t2chp17_q1` (quest_task_completed: chp17_q1.2); `t3chp17_q1` (quest_task_completed: chp17_q1.3); `t4chp17_q1` (quest_task_completed: chp17_q1.4); `ftchp17_q1` (claim_button_tapped: chp17_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp17_q1.1` | Clear away the rubble | `collect_and_repair`; `shovel` × 4 | `571c,572b,573a,574c` | `ch17_rubble` |
| `chp17_q1.2` | Help Blacktail find rope | `collect_and_interact`; `vine` × 4 | `575a,576b,577c,578b` | `none` |
| `chp17_q1.3` | Help Ragnaruff launch the dinghy | `collect_and_interact`; `anchor` × 1 | `579a` | `none` |
| `chp17_q1.4` | Alert the survivor, rescue is on the way! | `collect_and_interact`; `rattle` × 1 | `580c` | `none` |

## chp17_q2: Age Of Purrgress

Configured quest `level` **581**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li wants to sell us her amazing inventions. But she lost everything in the shipwreck. Let’s build her a workshop so she can craft new products!”

Journal outcome (localized quest text): “Mee Li sailed from Hong Kitty Island to sell her inventions, but she lost everything in the shipwreck. We built her a workshop so she can craft new stock. Meanwhile, Kip started to develop a bad cold.”

Configured scenes: `chp17_q2` (quest_start: chp17_q2); `t1chp17_q2` (quest_task_completed: chp17_q2.1); `t2chp17_q2` (quest_task_completed: chp17_q2.2); `t3chp17_q2` (quest_task_completed: chp17_q2.3); `t4chp17_q2` (quest_task_completed: chp17_q2.4); `ftchp17_q2` (claim_button_tapped: chp17_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp17_q2.1` | Build Mee Li's workshop | `collect_and_repair`; `stone` × 3 | `581c,582a,583b` | `ch17_workshop` |
| `chp17_q2.2` | Find some tools for the workshop | `collect_and_repair`; `axe` × 3 | `584c,585a,586b` | `ch17_anvil` |
| `chp17_q2.3` | Make a cold remedy for Kip | `collect_and_interact`; `herb` × 2 | `587c,588b` | `none` |
| `chp17_q2.4` | Gather tissues for Kip | `collect_and_interact`; `tissue` × 2 | `589a,590c` | `none` |
| `chp17_q2.5` | Reach Village Rank 30 | `reach_rank`; `harmony` × 30 | `none` | `none` |

## chp17_q3: A Miracle Cure

Configured quest `level` **591**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li here! I’m going to invent the most FANTABULOUS cold remedy the world has ever seen! 100% SCIENCE! Want to help?”

Journal outcome (localized quest text): “Kip’s cold continued to worsen, so Mee Li invented him a health elixir. Meanwhile, Nibblesby discovered schematics of Mee Li's past inventions, which were too crazy to ever work. Nevertheless, the elixir cured Kip's cold.”

Configured scenes: `chp17_q3` (quest_start: chp17_q3); `t1chp17_q3` (quest_task_completed: chp17_q3.1); `t2chp17_q3` (quest_task_completed: chp17_q3.2); `t3chp17_q3` (quest_task_completed: chp17_q3.3); `t4chp17_q3` (quest_task_completed: chp17_q3.4); `ftchp17_q3` (claim_button_tapped: chp17_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp17_q3.1` | Extract coconut oil | `collect_and_interact`; `coconut` × 2 | `591a,592c` | `none` |
| `chp17_q3.2` | Collect fresh honey | `collect_and_interact`; `honey` × 3 | `593b,594c,595a` | `none` |
| `chp17_q3.3` | Find a bottle for the elixir | `collect_and_interact`; `ceramic_bottle` × 2 | `596c,597b` | `none` |
| `chp17_q3.4` | Read Mee Li's old schematics | `collect_and_interact`; `blueprints` × 3 | `598c,599a,600b` | `none` |

## chp17_q4: Mass Purrduction

Configured quest `level` **601**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li wants to build a coconut press to mass produce her health elixir. Let’s do it! Oh... and can you see what’s up with Nibblesby? He looks worried...”

Journal outcome (localized quest text): “We built Mee Li a coconut press, so she could mass produce her health elixir. But Nibblesby's suspicions were confirmed. The elixir has terrible side effects. It caused leaves to grow out of Kip’s head! My brother’s turning into a coconut tree!”

Configured scenes: `chp17_q4` (quest_start: chp17_q4); `t1chp17_q4` (quest_task_completed: chp17_q4.1); `t2chp17_q4` (quest_task_completed: chp17_q4.2); `t3chp17_q4` (quest_task_completed: chp17_q4.3); `t4chp17_q4` (quest_task_completed: chp17_q4.4); `ftchp17_q4` (claim_button_tapped: chp17_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp17_q4.1` | Build a coconut oil press | `collect_and_repair`; `log` × 3 | `601a,602c,603b` | `ch17_farm_coconut` |
| `chp17_q4.2` | Lay a road around the press | `collect_and_repair`; `stone` × 2 | `604b,605a` | `ch17_road_rustic` |
| `chp17_q4.3` | Plant some bamboo | `collect_and_repair`; `bamboo` × 3 | `606c,607b,608c` | `ch17_forest_bamboo` |
| `chp17_q4.4` | Ask Mee Li about her dodgy inventions | `collect_and_interact`; `blueprints` × 2 | `609a,610b` | `none` |
| `chp17_q4.5` | Reach Village Rank 31 | `reach_rank`; `harmony` × 31 | `none` | `none` |

