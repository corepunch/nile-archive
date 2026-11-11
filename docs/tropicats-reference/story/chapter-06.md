# Chapter 6

[Story index](../STORY.md) · [Previous](chapter-05.md) · [Next](chapter-07.md)

Configured chapter start: campaign level **131**; starts with `chp6_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Taka prepares a sun ritual at the repaired shrine to draw the dog out for water. The dog falls into the well during the attempted capture and is rescued injured.

## chp6_q1: The Sun Ritual

Configured quest `level` **131**; assigned character **Taka**.

Setup (localized quest text): “Taka is gonna perform a Sun Ritual to sweat the doggy out of hiding! He needs to collect HOT stuff for the ritual to work.”

Journal outcome (localized quest text): “Taka concocted a Sun Ritual to heat-up the island and force the thirsty dog into the village for water. Chief gathered ingredients needed for the ritual.”

Configured scenes: `chp6_q1` (quest_start: chp6_q1); `t1chp6_q1` (quest_task_completed: chp6_q1.1); `t2chp6_q1` (quest_task_completed: chp6_q1.2); `t3chp6_q1` (quest_task_completed: chp6_q1.3); `ftchp6_q1` (claim_button_tapped: chp6_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp6_q1.1` | Extract fire ant venom | `collect_and_interact`; `fire_ant` × 3 | `131a,132a,133c` | `none` |
| `chp6_q1.2` | Eat chili peppers | `collect_and_interact`; `chili` × 3 | `134a,135b,136b` | `none` |
| `chp6_q1.3` | Study fireflies | `collect_and_interact`; `firefly` × 4 | `137a,138c,139a,140c` | `none` |

## chp6_q2: No Shrine? No Ritual!

Configured quest `level` **141**; assigned character **Taka**.

Setup (localized quest text): “Taka will perform the Sun Ritual at the village shrine. We better get it repaired!”

Journal outcome (localized quest text): “Chief repaired the village shrine and Taka performed the Sun Ritual. With the island heating-up, the thirsty doggy would surely come out of hiding soon...”

Configured scenes: `chp6_q2` (quest_start: chp6_q2); `t1chp6_q2` (quest_task_completed: chp6_q2.1); `t2chp6_q2` (quest_task_completed: chp6_q2.2); `t3chp6_q2` (quest_task_completed: chp6_q2.3); `ftchp6_q2` (claim_button_tapped: chp6_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp6_q2.1` | Replant the shrine copse | `collect_and_repair`; `seed` × 2 | `141a,142b` | `ch6_shrine_trees` |
| `chp6_q2.2` | Arrange the shrine flower basket | `collect_and_repair`; `bamboo` × 3 | `143a,144a,145c` | `ch6_shrine_basket` |
| `chp6_q2.3` | Rebuild the shaman shrine | `collect_and_repair`; `log` × 5 | `146a,147c,148a,149b,150c` | `ch6_shrine` |
| `chp6_q2.4` | Reach Village Rank 8 | `reach_rank`; `harmony` × 8 | `none` | `none` |

## chp6_q3: Ancestor Apology

Configured quest `level` **151**; assigned character **Ava**.

Setup (localized quest text): “Taka wants to make an offering to the ancestors, while we wait for the dog to show up. Find him some incense!”

Journal outcome (localized quest text): “Taka made an offering to the ancestors, apologizing for allowing the Great Totem to fall. Then Cubby told us the news... he'd spotted the dog! It's here, in the village!”

Configured scenes: `chp6_q3` (quest_start: chp6_q3); `t1chp6_q3` (quest_task_completed: chp6_q3.1); `t2chp6_q3` (quest_task_completed: chp6_q3.2); `t3chp6_q3` (quest_task_completed: chp6_q3.3); `t4chp6_q3` (quest_task_completed: chp6_q3.4); `ftchp6_q3` (claim_button_tapped: chp6_q3).

Localization override: `v1`; action labels below use matching overridden keys when present.

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp6_q3.1` | Assemble Taka's lost spell book | `collect_and_interact`; `page` × 3 | `151a,152b,153c` | `none` |
| `chp6_q3.2` | Help Lily woo Kip | `collect_and_interact`; `bouquet` × 2 | `154a,155b` | `none` |
| `chp6_q3.3` | Sacrifice ants to the ancestors | `collect_and_interact`; `fire_ant` × 2 | `156a,157c` | `none` |
| `chp6_q3.4` | Burn incense at the Great Totem | `collect_and_interact`; `incense` × 3 | `158a,159b,160c` | `none` |

## chp6_q4: Well, Well, Well...

Configured quest `level` **161**; assigned character **Elsie**.

Setup (localized quest text): “The thirsty doggy fell right into the water well. Fix the well so we can pull him out!”

Journal outcome (localized quest text): “The dog fell down the well when we tried to catch it! We fixed the well and pulled out the doggy. The totem-cutter was caught... but badly hurt.”

Configured scenes: `chp6_q4` (quest_start: chp6_q4); `t1chp6_q4` (quest_task_completed: chp6_q4.1); `t2chp6_q4` (quest_task_completed: chp6_q4.2); `t3chp6_q4` (quest_task_completed: chp6_q4.3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp6_q4.1` | Find vines and make a leash | `collect_and_interact`; `vine` × 2 | `161a,162b` | `none` |
| `chp6_q4.2` | Sharpen Cubby's spear | `collect_and_interact`; `stone` × 3 | `163a,164a,165c` | `none` |
| `chp6_q4.3` | Repair the village well | `collect_and_repair`; `clay` × 5 | `166a,167c,168a,169b,170c` | `ch6_fountain` |
| `chp6_q4.4` | Reach Village Rank 9 | `reach_rank`; `harmony` × 9 | `none` | `none` |

