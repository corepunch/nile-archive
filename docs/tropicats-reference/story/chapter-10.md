# Chapter 10

[Story index](../STORY.md) · [Previous](chapter-09.md) · [Next](chapter-11.md)

Configured chapter start: campaign level **291**; starts with `chp10_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Kip uses village memories to calm Tika, and Kikuna reconciles with his brother. The elder apologizes; the story shifts to Olivia's planned proposal and Ava's competing offer to Cubby.

## chp10_q1: Where Cats Belong

Configured quest `level` **291**; assigned character **Taka**.

Setup (localized quest text): “Tika's spirit wants to force us back to living wild! Assemble our scrapbook of village memories and Kip will convince Tika that this is where we belong.”

Journal outcome (localized quest text): “Kip showed Tika our village scrapbook, a collection of our most cherished memories. My brother convinced Tika that this village is where the tribe belongs now, not the jungle. Tika's fury has finally been calmed.”

Configured scenes: `chp10_q1` (quest_start: chp10_q1); `t1chp10_q1` (quest_task_completed: chp10_q1.1); `t3chp10_q1` (quest_task_completed: chp10_q1.3); `t4chp10_q1` (quest_task_completed: chp10_q1.4); `t2chp10_q1` (quest_task_completed: chp10_q1.2); `ftchp10_q1` (claim_button_tapped: chp10_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp10_q1.1` | Show Tika the Village Scrapbook | `collect_and_repair`; `page` × 4 | `291a,292b,293c,294a` | `ch10_magictree_tree` |
| `chp10_q1.2` | Place incense by the tree | `collect_and_repair`; `incense` × 2 | `295c,296b` | `ch10_magictree_surrounding` |
| `chp10_q1.3` | Examine the broken statue | `collect_and_interact`; `magn_glass` × 2 | `297b,298c` | `none` |
| `chp10_q1.4` | Help Elsie apologize to Kip | `collect_and_interact`; `grilled_banana` × 2 | `299b,300c` | `none` |

## chp10_q2: The Founder's Return

Configured quest `level` **301**; assigned character **Taka**.

Setup (localized quest text): “The spirit of ancestor Kikuna has returned! Let's help him reconcile with his brother's spirit and get to know the rest of the tribe.”

Journal outcome (localized quest text): “Ancestor Kikuna's spirit returned to the island. The prophecy came true after all! We showed Kikuna around the village he never got to see, and helped him reconcile with his brother.”

Configured scenes: `chp10_q2` (quest_start: chp10_q2); `t1chp10_q2` (quest_task_completed: chp10_q2.1); `t2chp10_q2` (quest_task_completed: chp10_q2.2); `t3chp10_q2` (quest_task_completed: chp10_q2.3); `t4chp10_q2` (quest_task_completed: chp10_q2.4); `ftchp10_q2` (claim_button_tapped: chp10_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp10_q2.1` | Help Kikuna reconcile with his brother Tika | `collect_and_interact`; `incense` × 3 | `301a,302b,303a` | `none` |
| `chp10_q2.2` | Eat lunch at the grill with Kikuna | `collect_and_interact`; `watermelon` × 2 | `304b,305c` | `none` |
| `chp10_q2.3` | Drink tea with Kikuna and Olivia | `collect_and_interact`; `herb` × 2 | `306c,307c` | `none` |
| `chp10_q2.4` | Show Kikuna Ava's blueprints | `collect_and_interact`; `blueprints` × 3 | `308c,309a,310b` | `none` |
| `chp10_q2.5` | Reach Village Rank 16 | `reach_rank`; `harmony` × 16 | `none` | `none` |

## chp10_q3: The Big Apawlogy

Configured quest `level` **311**; assigned character **Ava**.

Setup (localized quest text): “The elder seeks the tribe's forgiveness. Help him restore the Great Kikuna statue and let's hear what he has to say.”

Journal outcome (localized quest text): “The tribe elder wants to beg for forgiveness. We helped him restore a statue of ancestor Kikuna and listened to his apawology. I believe Tika's spirit had led him astray. It'll take time, but hopefully the tribe will be able to forgive him.”

Configured scenes: `chp10_q3` (quest_start: chp10_q3); `t1chp10_q3` (quest_task_completed: chp10_q3.1); `t2chp10_q3` (quest_task_completed: chp10_q3.2); `t3chp10_q3` (quest_task_completed: chp10_q3.3); `t4chp10_q3` (quest_task_completed: chp10_q3.4); `ftchp10_q3` (claim_button_tapped: chp10_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp10_q3.1` | Restore the Great Kikuna statue | `collect_and_repair`; `stone` × 3 | `311a,312c,313b` | `ch10_statue_kikuna` |
| `chp10_q3.2` | Prepare a melon juice table | `collect_and_repair`; `watermelon` × 2 | `314c,315c` | `ch10_statue_surrounding` |
| `chp10_q3.3` | Make a fruit cocktail buffet | `collect_and_repair`; `berries` × 2 | `316c,317a` | `ch10_statue_surrounding2` |
| `chp10_q3.4` | Help Olivia woo Cubby | `collect_and_interact`; `bouquet` × 3 | `318b,319b,320c` | `none` |

## chp10_q4: A Purrfect Purrposal

Configured quest `level` **321**; assigned character **Elsie**.

Setup (localized quest text): “I've convinced Olivia to propose to Cubby! Now we just have to make sure she doesn't screw it up. Let's help her prepare!”

Journal outcome (localized quest text): “Olivia was growing tired of Cubby dodging the marriage question. So I convinced her to propose to Cubby herself! But then Ava got jealous, and during the proposal she made a counter offer! Ava or Olivia? Who's Cubby gonna choose?”

Configured scenes: `chp10_q4` (quest_start: chp10_q4); `t3chp10_q4` (quest_task_completed: chp10_q4.3); `t2chp10_q4` (quest_task_completed: chp10_q4.2); `t1chp10_q4` (quest_task_completed: chp10_q4.1); `t4chp10_q4` (quest_task_completed: chp10_q4.4); `ftchp10_q4` (claim_button_tapped: chp10_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp10_q4.1` | Help Olivia groom at the spring | `collect_and_interact`; `grooming_brush` × 2 | `321a,322b` | `none` |
| `chp10_q4.2` | Ask Ava to build a romantic gazebo | `collect_and_interact`; `bouquet` × 2 | `323c,324b` | `none` |
| `chp10_q4.3` | Help Olivia practice her proposal lines | `collect_and_interact`; `page` × 3 | `325b,326c,327b` | `none` |
| `chp10_q4.4` | Grill watermelons for Cubby | `collect_and_interact`; `watermelon` × 3 | `328c,329a,330a` | `none` |
| `chp10_q4.5` | Reach Village Rank 17 | `reach_rank`; `harmony` × 17 | `none` | `none` |

