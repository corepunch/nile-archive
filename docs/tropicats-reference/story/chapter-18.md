# Chapter 18: Age Of Purrgress

[Story index](../STORY.md) · [Previous](chapter-17.md) · [Next](chapter-19.md)

Campaign levels **611–650**; starts with `chp18_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

A pigeon post office helps Mee Li seek an antidote; Kip loses his unusual hair. Given a second chance as a merchant, she asks for help with Felicity's new farm, and the Chief and Ava depart.

## chp18_q1: Pigeon Post

Configured quest `level` **611**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li says she can fix Kip’s coconutty condition - she just needs a way to send mail. In the meantime, I’m giving Kip a haircut. Or is that a leafcut?”

Journal outcome (localized quest text): “Mee Li said she can cure Kip’s coconutty condition, but she needed advice from a scientist on her home island. She instructed us to build a Pigeon Post Office so she could send a letter. Tropicat Island has entered the age of communication!”

Configured scenes: `chp18_q1` (quest_start: chp18_q1); `t1chp18_q1` (quest_task_completed: chp18_q1.1); `t2chp18_q1` (quest_task_completed: chp18_q1.2); `t3chp18_q1` (quest_task_completed: chp18_q1.3); `t4chp18_q1` (quest_task_completed: chp18_q1.4); `ftchp18_q1` (claim_button_tapped: chp18_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp18_q1.1` | Build the Pigeon Post Office | `collect_and_repair`; `log` × 3 | `611c,612b,613a` | `ch18_office_post` |
| `chp18_q1.2` | Train some pigeons | `collect_and_repair`; `seed` × 3 | `614b,615c,616b` | `ch18_pigeon_single` |
| `chp18_q1.3` | Write a letter to the medicine cat | `collect_and_interact`; `page` × 2 | `617a,618b` | `none` |
| `chp18_q1.4` | Trim Kip's leaves | `collect_and_interact`; `scissors` × 2 | `619b,620c` | `none` |

## chp18_q2: Cat Me If You Can

Configured quest `level` **621**; assigned character **Elsie**.

Setup (localized quest text): “We need to make the antidote for Kip’s leaf problem. First we need to find him to administer it. Where could he be?”

Journal outcome (localized quest text): “Kip had been hiding away with Lily, but we lured him out with some cake. After squirting him with antidote, his leafy hair fell right out. He’s not exactly pleased though. He liked his new look!”

Configured scenes: `chp18_q2` (quest_start: chp18_q2); `t1chp18_q2` (quest_task_completed: chp18_q2.1); `t2chp18_q2` (quest_task_completed: chp18_q2.2); `t3chp18_q2` (quest_task_completed: chp18_q2.3); `t4chp18_q2` (quest_task_completed: chp18_q2.4); `ftchp18_q2` (claim_button_tapped: chp18_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp18_q2.1` | Follow Kip's tracks | `collect_and_interact`; `tracks_2` × 2 | `621a,622b` | `none` |
| `chp18_q2.2` | Follow Lily's tracks | `collect_and_interact`; `tracks_1` × 2 | `623c,624b` | `none` |
| `chp18_q2.3` | Set bait for Kip | `collect_and_interact`; `grilled_banana` × 3 | `625c,626a,627b` | `none` |
| `chp18_q2.4` | Find squirty bottles | `collect_and_interact`; `perfume` × 3 | `628c,629a,630c` | `none` |
| `chp18_q2.5` | Reach Village Rank 32 | `reach_rank`; `harmony` × 32 | `none` | `none` |

## chp18_q3: Mee Li's Market

Configured quest `level` **631**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li is depurressed. She thinks she’s a total failure. Let’s build her a marketplace and persuade her to keep on inventing. Everyone deserves a second chance!”

Journal outcome (localized quest text): “After Kip's leaf fiasco, Mee Li wanted to give up inventing. But everyone deserves a second chance. We built her a marketplace and asked her to stay. Mee Li is now our resident merchant. I just hope she gets better at inventing stuff!”

Configured scenes: `chp18_q3` (quest_start: chp18_q3); `t1chp18_q3` (quest_task_completed: chp18_q3.1); `t2chp18_q3` (quest_task_completed: chp18_q3.2); `t3chp18_q3` (quest_task_completed: chp18_q3.3); `t4chp18_q3` (quest_task_completed: chp18_q3.4); `ftchp18_q3` (claim_button_tapped: chp18_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp18_q3.1` | Build the marketplace | `collect_and_repair`; `bamboo` × 3 | `631c,632a,633c` | `ch18_marketplace` |
| `chp18_q3.2` | Add a firework stall | `collect_and_repair`; `fireworks` × 3 | `634c,635b,636b` | `ch18_stand_fireworks` |
| `chp18_q3.3` | Make an improved health elixir | `collect_and_interact`; `coconut` × 2 | `637c,638a` | `none` |
| `chp18_q3.4` | Advertise the marketplace | `collect_and_interact`; `page` × 2 | `639b,640c` | `none` |

## chp18_q4: A Mew Adventure

Configured quest `level` **641**; assigned character **Elsie**.

Setup (localized quest text): “Hey, Chief. Ava here. Mee Li's friend needs our help... on a different island! Are you ready to visit somewhere new? Let's get ready for the trip.”

Journal outcome (localized quest text): “Mee Li's friend Felicity needed help building a farm on a new island. So Chief and Ava prepared for the journey and set sail. The restoration of Tropicat Village is over. Now it's time for a new adventure!”

Configured scenes: `chp18_q4` (quest_start: chp18_q4); `t1chp18_q4` (quest_task_completed: chp18_q4.1); `t2chp18_q4` (quest_task_completed: chp18_q4.2); `t3chp18_q4` (quest_task_completed: chp18_q4.3); `t4chp18_q4` (quest_task_completed: chp18_q4.4); `ftchp18_q4` (claim_button_tapped: chp18_q4); `ftchp18_q4` (claim_button_tapped: chp18_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp18_q4.1` | Help Mee Li paint a map of the region | `collect_and_interact`; `scroll` × 2 | `641b,642c` | `none` |
| `chp18_q4.2` | Tell Elsie about your plans | `collect_and_interact`; `bouquet` × 3 | `643a,644c,645b` | `none` |
| `chp18_q4.3` | Fix up Ragnaruff's ship | `collect_and_interact`; `log` × 3 | `646c,647b,648a` | `none` |
| `chp18_q4.4` | Write a letter to Felicity Belle | `collect_and_interact`; `page` × 2 | `649b,650c` | `none` |
| `chp18_q4.5` | Reach Village Rank 33 | `reach_rank`; `harmony` × 33 | `none` | `none` |

