# Chapter 5

[Story index](../STORY.md) · [Previous](chapter-04.md) · [Next](chapter-06.md)

Configured chapter start: campaign level **91**; starts with `chp5_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Lily, the shaman's apprentice, regards the dog as a friend. Ava turns Lily's planned tea party into a trap, and the group must regain Lily's cooperation before Taka agrees to make a nonviolent spell.

## chp5_q1: Meowgic Matters

Configured quest `level` **91**; assigned character **Elsie**.

Setup (localized quest text): “We need the shaman's meowgic powers to catch the dog. Clear the rubble so we can search for Taka and his apprentice, Lily.”

Journal outcome (localized quest text): “We found the shaman’s kooky kitten apprentice, Lily, who insisted the dog isn’t evil. In fact, she said they’re best friends... This can’t end well.”

Configured scenes: `chp5_q1` (quest_start: chp5_q1); `t1chp5_q1` (quest_task_completed: chp5_q1.1); `t2chp5_q1` (quest_task_completed: chp5_q1.2); `t3chp5_q1` (quest_task_completed: chp5_q1.3); `t4chp5_q1` (quest_task_completed: chp5_q1.4); `ftchp5_q1` (claim_button_tapped: chp5_q1).

Display order override: `2,0,1,3` (serialized values; task numbering below stays source-array order; runtime display semantics unverified).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp5_q1.1` | Take a lunch break | `collect_and_interact`; `honey` × 2 | `95a,96c` | `none` |
| `chp5_q1.2` | Help Cubby woo Olivia | `collect_and_interact`; `bouquet` × 2 | `97a,98b` | `none` |
| `chp5_q1.3` | Clear the rubble near the river | `collect_and_repair`; `shovel` × 4 | `91a,92c,93a,94c` | `ch5_rubble` |
| `chp5_q1.4` | Help Elsie groom Kip | `collect_and_interact`; `grooming_brush` × 2 | `99b,100c` | `none` |

## chp5_q2: Partying With The Enemy

Configured quest `level` **101**; assigned character **Elsie**.

Setup (localized quest text): “Lily has befriended the dog and wants to throw it a tea party. Let's fix her hut for the event... and maybe this doggy will show up.”

Journal outcome (localized quest text): “We helped Lily set-up a party for 'Mr. Doggy', to introduce him to the tribe. But Ava tried to turn the event into a trap! The wily dog didn't show-up and Lily flew into a rage.”

Configured scenes: `chp5_q2` (quest_start: chp5_q2); `t1chp5_q2` (quest_task_completed: chp5_q2.1); `t2chp5_q2` (quest_task_completed: chp5_q2.2); `t3chp5_q2` (quest_task_completed: chp5_q2.3); `ftchp5_q2` (claim_button_tapped: chp5_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp5_q2.1` | Prepare catnip tea for the party | `collect_and_interact`; `herb` × 2 | `101a,102b` | `none` |
| `chp5_q2.2` | Replant Lily's prize-winning flower patch | `collect_and_repair`; `seed` × 3 | `103a,104b,105c` | `ch5_lily_flowers` |
| `chp5_q2.3` | Repair Lily's hut | `collect_and_repair`; `log` × 5 | `106a,107a,108b,109a,110c` | `ch5_lily_hut` |
| `chp5_q2.4` | Reach Village Rank 6 | `reach_rank`; `harmony` × 6 | `none` | `none` |

## chp5_q3: Where's The Shaman?

Configured quest `level` **111**; assigned character **Taka**.

Setup (localized quest text): “Lily is furious over her ruined tea party. She won't tell us where the shaman is! Try anything you can to cheer her up.”

Journal outcome (localized quest text): “Due to Ava's scheming, Lily refused to grant us an audience with the shaman. But after Chief and Cubby cheered her up, the kitten agreed to fetch her master.”

Configured scenes: `chp5_q3` (quest_start: chp5_q3); `t1chp5_q3` (quest_task_completed: chp5_q3.1); `t2chp5_q3` (quest_task_completed: chp5_q3.2); `t3chp5_q3` (quest_task_completed: chp5_q3.3); `t4chp5_q3` (quest_task_completed: chp5_q3.4); `t5chp5_q3` (quest_task_completed: chp5_q3.5); `ftchp5_q3` (claim_button_tapped: chp5_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp5_q3.1` | Make a hula hoop for Lily | `collect_and_interact`; `bamboo` × 2 | `111a,112b` | `none` |
| `chp5_q3.2` | Grill sweet bananas for Lily | `collect_and_interact`; `honey` × 3 | `113a,114b,115c` | `none` |
| `chp5_q3.3` | Help Kip cheer up Lily | `collect_and_interact`; `bouquet` × 2 | `116a,117b` | `none` |
| `chp5_q3.4` | Make Lily's favorite tea | `collect_and_interact`; `herb` × 3 | `118a,119b,120c` | `none` |

## chp5_q4: Spell Crafting

Configured quest `level` **121**; assigned character **Taka**.

Setup (localized quest text): “The shaman needs to dream up a 100% violence-free spell to catch the dog. Fix up his shack so he can work on it.”

Journal outcome (localized quest text): “At Lily's insistence Taka, the shaman, agreed to craft a 'violence-free' meowgic spell to trap the dog. Chief repaired the shaman shack, so Taka could get to work.”

Configured scenes: `chp5_q4` (quest_start: chp5_q4); `t1chp5_q4` (quest_task_completed: chp5_q4.1); `t2chp5_q4` (quest_task_completed: chp5_q4.2); `t3chp5_q4` (quest_task_completed: chp5_q4.3); `ftchp5_q4` (claim_button_tapped: chp5_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp5_q4.1` | Replant the shack's flowers | `collect_and_repair`; `seed` × 3 | `121a,122b,123c` | `ch5_taka_flowers` |
| `chp5_q4.2` | Rebuild Taka's meowgic firepit | `collect_and_repair`; `clay` × 2 | `124a,125c` | `ch5_taka_firepit` |
| `chp5_q4.3` | Repair the shaman shack | `collect_and_repair`; `log` × 5 | `126a,127b,128c,129b,130b` | `ch5_taka_hut` |
| `chp5_q4.4` | Reach Village Rank 7 | `reach_rank`; `harmony` × 7 | `none` | `none` |

