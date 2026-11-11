# Chapter 22: The Dream Harvest

[Story index](../STORY.md) · [Previous](chapter-21.md) · [Next](chapter-23.md)

Campaign levels **771–810**; starts with `chp22_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Felicity prepares for and wins the regional farm contest judged by the Duchess. Redd's account and the observatory give Ragnaruff a route home, and he, Redd and the Chief sail north.

## chp22_q1: V Is For Veggies

Configured quest `level` **771**; assigned character **Elsie**.

Setup (localized quest text): “Let's build a vegetable garden and get ready for the Impurrial Vegetable Contest. The Duchess will judge the farm tomorrow.”

Journal outcome (localized quest text): “We built the vegetable garden in preparation for the Impurrial Vegetable Contest. The Duchess will be judging each farm in the western region of the Impurrial Empire. Felicity will have to impress her to win!”

Configured scenes: `chp22_q1` (quest_start: chp22_q1); `t1chp22_q1` (quest_task_completed: chp22_q1.1); `t2chp22_q1` (quest_task_completed: chp22_q1.2); `t3chp22_q1` (quest_task_completed: chp22_q1.3); `t4chp22_q1` (quest_task_completed: chp22_q1.4); `ftchp22_q1` (claim_button_tapped: chp22_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp22_q1.1` | Replant the veggie patch | `collect_and_repair`; `seed` × 3 | `771b,772c,773b` | `ch22_vegetablegarden` |
| `chp22_q1.2` | Repair the old scarecrow | `collect_and_repair`; `log` × 2 | `774a,775b` | `ch22_scarecrow` |
| `chp22_q1.3` | Eat lunch with Ragnaruff | `collect_and_interact`; `fish` × 2 | `776c,777a` | `none` |
| `chp22_q1.4` | Make perfume for Felicity's chicks | `collect_and_interact`; `perfume` × 3 | `778c,779b,780b` | `none` |

## chp22_q2: Reap What You Sow

Configured quest `level` **781**; assigned character **Elsie**.

Setup (localized quest text): “The Duchess has shown up to judge Felicity’s farm. Let’s present her with the best squash and feed her our finest produce!”

Journal outcome (localized quest text): “Felicity's farm was crowned best farm in the western Impurrial Empire and surprisingly, the Duchess took a real shine to Felicity herself. Meanwhile, Ragnaruff discovered that the Nordog King may have evacuated his island due to an impending war...”

Configured scenes: `chp22_q2` (quest_start: chp22_q2); `t1chp22_q2` (quest_task_completed: chp22_q2.1); `t2chp22_q2` (quest_task_completed: chp22_q2.2); `t3chp22_q2` (quest_task_completed: chp22_q2.3); `t4chp22_q2` (quest_task_completed: chp22_q2.4); `ftchp22_q2` (claim_button_tapped: chp22_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp22_q2.1` | Give the Duchess a farm tour | `collect_and_interact`; `magn_glass` × 1 | `781c` | `none` |
| `chp22_q2.2` | Choose the best squash | `collect_and_interact`; `marrow` × 3 | `782b,783c,784b` | `none` |
| `chp22_q2.3` | Cook the Duchess an olive omelet | `collect_and_interact`; `eggs` × 3 | `785a,786b,787c` | `none` |
| `chp22_q2.4` | Drink tea with the Duchess and Nibblesby | `collect_and_interact`; `herb` × 3 | `788b,789b,790b` | `none` |
| `chp22_q2.5` | Reach Village Rank 40 | `reach_rank`; `harmony` × 40 | `none` | `none` |

## chp22_q3: Farewell, Felicity

Configured quest `level` **791**; assigned character **Elsie**.

Setup (localized quest text): “Our work here is almost done, Chief. Let’s perform a few final tasks, say goodbye, and head back to Tropicat Village.”

Journal outcome (localized quest text): “We officially reopened the farm, said goodbye to Felicity and Mee Li, and prepared to journey back to Tropicat Village. Through Redd, Ragnaruff discovered a route back to Nordog Island and he wants to use the Tropicat Observatory to make a map.”

Configured scenes: `chp22_q3` (quest_start: chp22_q3); `t1chp22_q3` (quest_task_completed: chp22_q3.1); `t2chp22_q3` (quest_task_completed: chp22_q3.2); `t3chp22_q3` (quest_task_completed: chp22_q3.3); `t4chp22_q3` (quest_task_completed: chp22_q3.4); `ftchp22_q3` (claim_button_tapped: chp22_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp22_q3.1` | Officially open the farm | `collect_and_interact`; `scissors` × 1 | `791a` | `none` |
| `chp22_q3.2` | Plant a farewell tree | `collect_and_repair`; `seed` × 3 | `792c,793b,794a` | `ch22_tree_olive` |
| `chp22_q3.3` | Help Felicity find a gift for Taka | `collect_and_interact`; `incense` × 3 | `795c,796c,797b` | `none` |
| `chp22_q3.4` | Eat lunch with Ragnaruff and Redd | `collect_and_interact`; `fish` × 3 | `798c,799b,800c` | `none` |

## chp22_q4: Northward Bound

Configured quest `level` **801**; assigned character **Elsie**.

Setup (localized quest text): “With Redd’s knowledge, Ragnaruff can finally make a star map of the northern isles. Help ‘em out, Chief. This may lead us to Nordog Island.”

Journal outcome (localized quest text): “Using the observatory, Ragnaruff and Redd made a star map to help them navigate to Nordog Island. Along with Chief they set sail to the cold and icy northern realms. Ragnaruff is finally going home. But what will he find there?”

Configured scenes: `chp22_q4` (quest_start: chp22_q4); `t1chp22_q4` (quest_task_completed: chp22_q4.1); `t2chp22_q4` (quest_task_completed: chp22_q4.2); `t3chp22_q4` (quest_task_completed: chp22_q4.3); `t4chp22_q4` (quest_task_completed: chp22_q4.4); `ftchp22_q4` (claim_button_tapped: chp22_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp22_q4.1` | Make a map with Redd | `collect_and_interact`; `scroll` × 3 | `801b,802a,803c` | `none` |
| `chp22_q4.2` | Help Ragnaruff clean his hut | `collect_and_interact`; `grooming_brush` × 2 | `804b,805c` | `none` |
| `chp22_q4.3` | Eat lunch with Ragnaruff and Cubby | `collect_and_interact`; `melon` × 3 | `806c,807b,808b` | `none` |
| `chp22_q4.4` | Help Ragnaruff patch his sails | `collect_and_interact`; `fabric` × 2 | `809b,810c` | `none` |
| `chp22_q4.5` | Reach Village Rank 41 | `reach_rank`; `harmony` × 41 | `none` | `none` |

