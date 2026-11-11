# Chapter 15: Mummy's Boy

[Story index](../STORY.md) · [Previous](chapter-14.md) · [Next](chapter-16.md)

Campaign levels **491–530**; starts with `chp15_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The Duchess dismisses the island's welcome and customs and wants Blacktail home. Ava builds a mansion to impress her, while Blacktail adopts his birth name Furbert and behaves differently around his mother.

## chp15_q1: The Dreaded Duchess

Configured quest `level` **491**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess is on her way! Her son Blacktail has become a quivering wreck, so it falls to the rest of us to prepare. Let’s give her a nice welcome... she could be my future mother-in-paw!”

Journal outcome (localized quest text): “The Duchess arrived. What a rude cat! She wasn’t impressed with our welcome party and Blacktail just stood by while she insulted our traditions. He seems so different around her...”

Configured scenes: `chp15_q1` (quest_start: chp15_q1); `t1chp15_q1` (quest_task_completed: chp15_q1.1); `t2chp15_q1` (quest_task_completed: chp15_q1.2); `t3chp15_q1` (quest_task_completed: chp15_q1.3); `t4chp15_q1` (quest_task_completed: chp15_q1.4); `ftchp15_q1` (claim_button_tapped: chp15_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp15_q1.1` | Tidy up the area | `collect_and_repair`; `shovel` × 3 | `491a,492b,493a` | `ch15_rubble` |
| `chp15_q1.2` | Prepare traditional Tropicat snacks | `collect_and_interact`; `watermelon` × 3 | `494c,495b,496c` | `none` |
| `chp15_q1.3` | Teach Cubby a welcome dance | `collect_and_interact`; `lance` × 2 | `497c,498a` | `none` |
| `chp15_q1.4` | Help Taka bless the Duchess | `collect_and_interact`; `incense` × 2 | `499c,500a` | `none` |

## chp15_q2: Tea For Mew

Configured quest `level` **501**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess wants afternoon tea. Let’s brew a pot and make a nice picnic. If we don’t impress this cat, she’ll drag Blacktail back to Impurrial Island!”

Journal outcome (localized quest text): “The Duchess was unimpressed with our tea party, and was horribly snooty about it! She says Tropicat Village isn’t good enough for Blacktail and she wants him back on Impurrial Island. We gotta change her mind.”

Configured scenes: `chp15_q2` (quest_start: chp15_q2); `t1chp15_q2` (quest_task_completed: chp15_q2.1); `t2chp15_q2` (quest_task_completed: chp15_q2.2); `t3chp15_q2` (quest_task_completed: chp15_q2.3); `t4chp15_q2` (quest_task_completed: chp15_q2.4); `ftchp15_q2` (claim_button_tapped: chp15_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp15_q2.1` | Set up a nice picnic | `collect_and_repair`; `fabric` × 3 | `501a,502b,503c` | `ch15_place_picnic` |
| `chp15_q2.2` | Make some nice cakes | `collect_and_repair`; `cake` × 3 | `504c,505a,506c` | `ch15_table_crumpets` |
| `chp15_q2.3` | Brew up some tea | `collect_and_repair`; `leaves` × 2 | `507b,508c` | `ch15_table_teatime` |
| `chp15_q2.4` | Prepare jam | `collect_and_interact`; `berries` × 2 | `509a,510c` | `none` |
| `chp15_q2.5` | Reach Village Rank 26 | `reach_rank`; `harmony` × 26 | `none` | `none` |

## chp15_q3: Meeting Mummy

Configured quest `level` **511**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail has one last chance to convince the Duchess to let him stay on Tropicat Island. Let’s give her a tour of our village and prove that we’re not primitive wildcats!”

Journal outcome (localized quest text): “We gave the Duchess a tour of the village. She insulted EVERYTHING, especially Ava’s buildings. And Blacktail just stood there and took it, like a brain-dead fish! What’s happened to my once brave and dashing pirate!?”

Configured scenes: `chp15_q3` (quest_start: chp15_q3); `t1chp15_q3` (quest_task_completed: chp15_q3.1); `t2chp15_q3` (quest_task_completed: chp15_q3.2); `t3chp15_q3` (quest_task_completed: chp15_q3.3); `t4chp15_q3` (quest_task_completed: chp15_q3.4); `ftchp15_q3` (claim_button_tapped: chp15_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp15_q3.1` | Attend an ancestor ceremony with Taka and Lily | `collect_and_interact`; `incense` × 2 | `511a,512c` | `none` |
| `chp15_q3.2` | Listen to the elder read a traditional tale | `collect_and_interact`; `book` × 3 | `513a,514c,515b` | `none` |
| `chp15_q3.3` | Have an adventure with Kip and Ragnaruff | `collect_and_interact`; `fire_ant` × 3 | `516c,517b,518c` | `none` |
| `chp15_q3.4` | Inspect the village architecture with Ava | `collect_and_interact`; `magn_glass` × 2 | `519a,520c` | `none` |

## chp15_q4: Impurrial Pride

Configured quest `level` **521**; assigned character **Ava**.

Setup (localized quest text): “Chief! Ava here! Elsie has gone off to hide from the Duchess, so I’m taking over this quest. The Duchess called our village "primitive." I’ll SHOW HER! Let’s build something that’ll blow the whiskers off her face!”

Journal outcome (localized quest text): “Ava built an incredible mansion, convincing the Duchess our village is good enough for her son. But Blacktail isn’t Blacktail anymore... he’s going by his birth name: Furbert! And he’s acting so lame. My heart is breaking!”

Configured scenes: `chp15_q4` (quest_start: chp15_q4); `t1chp15_q4` (quest_task_completed: chp15_q4.1); `t2chp15_q4` (quest_task_completed: chp15_q4.2); `t3chp15_q4` (quest_task_completed: chp15_q4.3); `t4chp15_q4` (quest_task_completed: chp15_q4.4); `ftchp15_q4` (claim_button_tapped: chp15_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp15_q4.1` | Build something to impress the Duchess | `collect_and_repair`; `stone` × 3 | `521b,522c,523a` | `ch15_mansion_duchess` |
| `chp15_q4.2` | Plant some topiaries around the area | `collect_and_repair`; `seed` × 3 | `524b,525b,526a` | `ch15_topiary_ball` |
| `chp15_q4.3` | Add some Impurrial flags to please the Duchess | `collect_and_repair`; `fabric` × 2 | `527c,528a` | `ch15_flag_imperial` |
| `chp15_q4.4` | Organize a date night for Elsie and Blacktail | `collect_and_interact`; `bouquet` × 2 | `529a,530c` | `none` |
| `chp15_q4.5` | Reach Village Rank 27 | `reach_rank`; `harmony` × 27 | `none` | `none` |

