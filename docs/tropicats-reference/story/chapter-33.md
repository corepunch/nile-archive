# Chapter 33

[Story index](../STORY.md) · [Previous](chapter-32.md) · [Next](chapter-34.md)

Configured chapter start: campaign level **1211**; starts with `chp33_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Blacktail helps Felicity prepare a dinner; his apparent theft of McYowler's clubs raises suspicion. At the dinner McYowler suddenly collapses, turning the visit into a murder mystery.

## chp33_q1: Down On The Farm

Configured quest `level` **1211**; assigned character **Elsie**.

Setup (localized quest text): “If the Duchess is going to have a great dinner party, she'll need Felicity's help. But we've got to make sure her farm is taken care of first.”

Journal outcome (localized quest text): “Blacktail sailed to Felicity's island to bring her back so she could prepare food for a big dinner party. She put Blacktail to work helping her on the farm, which isn't really pirate work, but Blacktail did just fine. I couldn't wait to see them again!”

Configured scenes: `chp33_q1` (quest_start: chp33_q1); `t1chp33_q1` (quest_task_completed: chp33_q1.1); `t2chp33_q1` (quest_task_completed: chp33_q1.2); `t3chp33_q1` (quest_task_completed: chp33_q1.3); `t4chp33_q1` (quest_task_completed: chp33_q1.4); `ftchp33_q1` (claim_button_tapped: chp33_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp33_q1.1` | Feed the chickens | `collect_and_interact`; `seed` × 1 | `1211b` | `none` |
| `chp33_q1.2` | Collect eggs | `collect_and_interact`; `eggs` × 3 | `1212c,1213a,1214c` | `none` |
| `chp33_q1.3` | Water the crops | `collect_and_interact`; `bucket` × 3 | `1215b,1216c,1217b` | `none` |
| `chp33_q1.4` | Help Felicity pack | `collect_and_interact`; `lockbox` × 3 | `1218c,1219a,1220b` | `none` |

## chp33_q2: No Party Like A Tropicat Party

Configured quest `level` **1221**; assigned character **Elsie**.

Setup (localized quest text): “Felicity's here! She's going to get right to work, but she's going to need your help, Chief. There's a lot of prep needed to make this an amazing party!”

Journal outcome (localized quest text): “I was so proud of Blacktail. He helped Felicity in the kitchen all day and learned how to cook from a master chef. And in the end, we ended up with some food that was sure to impress Lord McYowler!”

Configured scenes: `chp33_q2` (quest_start: chp33_q2); `t1chp33_q2` (quest_task_completed: chp33_q2.1); `t2chp33_q2` (quest_task_completed: chp33_q2.2); `t3chp33_q2` (quest_task_completed: chp33_q2.3); `t4chp33_q2` (quest_task_completed: chp33_q2.4); `ftchp33_q2` (claim_button_tapped: chp33_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp33_q2.1` | Help chop vegetables | `collect_and_interact`; `sword` × 3 | `1221c,1222a,1223b` | `none` |
| `chp33_q2.2` | Prepare the tea | `collect_and_repair`; `herb` × 2 | `1224c,1225b` | `none` |
| `chp33_q2.3` | Prepare the appetizers | `collect_and_interact`; `eggs` × 2 | `1226c,1227b` | `none` |
| `chp33_q2.4` | Assemble the cutlery | `collect_and_interact`; `kitchen_knife` × 3 | `1228c,1229b,1230a` | `none` |
| `chp33_q2.5` | Reach Village Rank 62 | `reach_rank`; `harmony` × 62 | `none` | `none` |

## chp33_q3: The Club Conspiracy

Configured quest `level` **1231**; assigned character **Elsie**.

Setup (localized quest text): “McYowler's clubs went missing, and it looks like Blacktail is responsible! You've got to find out where they went!”

Journal outcome (localized quest text): “It certainly seemed like Blacktail had stolen Lord McYowler's clubs. Everything pointed to him, and he had been kind of a jerk to McYowler. But I knew I had to trust my husband. We found the clubs planted in our room, but I snuck them back under McYowler's bed.”

Configured scenes: `chp33_q3` (quest_start: chp33_q3); `t1chp33_q3` (quest_task_completed: chp33_q3.1); `t2chp33_q3` (quest_task_completed: chp33_q3.2); `t3chp33_q3` (quest_task_completed: chp33_q3.3); `t4chp33_q3` (quest_task_completed: chp33_q3.4); `ftchp33_q3` (claim_button_tapped: chp33_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp33_q3.1` | Search for tracks | `collect_and_interact`; `tracks_1` × 2 | `1231b,1232c` | `none` |
| `chp33_q3.2` | Eavesdrop on McYowler and Woodshavings | `collect_and_interact`; `spyglass` × 3 | `1233c,1234b,1235a` | `none` |
| `chp33_q3.3` | Search McYowler's room | `collect_and_interact`; `golfclubs` × 3 | `1236a,1237b,1238c` | `none` |
| `chp33_q3.4` | Talk to Woodshavings | `collect_and_interact`; `magn_glass` × 2 | `1239b,1240c` | `none` |

## chp33_q4: A Tropicat Party Don't Stop

Configured quest `level` **1241**; assigned character **Elsie**.

Setup (localized quest text): “Now that McYowler has settled down, it's time for a dinner party! We've got to make sure he's impressed, Chief.”

Journal outcome (localized quest text): “We hosted a dinner party for McYowler, and everything was going great. The food and tea came out on time, and McYowler and the Duchess were really hitting it off. We were all shocked when McYowler suddenly dropped dead on the floor! How could it have happened?”

Configured scenes: `chp33_q4` (quest_start: chp33_q4); `t1chp33_q4` (quest_task_completed: chp33_q4.1); `t2chp33_q4` (quest_task_completed: chp33_q4.2); `t3chp33_q4` (quest_task_completed: chp33_q4.3); `t4chp33_q4` (quest_task_completed: chp33_q4.4); `ftchp33_q4` (claim_button_tapped: chp33_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp33_q4.1` | Listen to McYowler's crazy stories | `collect_and_interact`; `jesterstick` × 2 | `1241b,1242c` | `none` |
| `chp33_q4.2` | Serve the tea | `collect_and_repair`; `porcelain_cup` × 3 | `1243b,1244c,1245a` | `none` |
| `chp33_q4.3` | Serve hors d'oeuvres | `collect_and_repair`; `eggs` × 2 | `1246c,1247b` | `none` |
| `chp33_q4.4` | Brag about the Duchess | `collect_and_interact`; `bouquet` × 3 | `1248c,1249b,1250a` | `none` |
| `chp33_q4.5` | Reach Village Rank 63 | `reach_rank`; `harmony` × 63 | `none` | `none` |

