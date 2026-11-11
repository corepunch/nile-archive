# Chapter 12: Purrenthood

[Story index](../STORY.md) · [Previous](chapter-11.md) · [Next](chapter-13.md)

Campaign levels **371–410**; starts with `chp12_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Pregnancy brings gifts and a new family hut, but Cubby disappears as Olivia goes into labor. Ragnaruff finds and reassures him, and the playground is completed in time for the twins' birth.

## chp12_q1: Kitten Shower

Configured quest `level` **371**; assigned character **Elsie**.

Setup (localized quest text): “Olivia is pregnant! New kittens are coming to the island! Let's help the tribe collect gifts for Olivia's kitten shower.”

Journal outcome (localized quest text): “Olivia announced she's pregnant, so Chief helped us collect gifts for a kitten shower. But not everyone was entirely happy about the news, especially the daddy-in-waiting...”

Configured scenes: `chp12_q1` (quest_start: chp12_q1); `t1chp12_q1` (quest_task_completed: chp12_q1.1); `t2chp12_q1` (quest_task_completed: chp12_q1.2); `t3chp12_q1` (quest_task_completed: chp12_q1.3); `t4chp12_q1` (quest_task_completed: chp12_q1.4); `ftchp12_q1` (claim_button_tapped: chp12_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp12_q1.1` | Find Kip's old baby toys | `collect_and_interact`; `rattle` × 3 | `371a,372c,373a` | `none` |
| `chp12_q1.2` | Help Ava make a crib for the kittens | `collect_and_interact`; `bamboo` × 2 | `374b,375a` | `none` |
| `chp12_q1.3` | Find the elder's story books | `collect_and_interact`; `scrapbook` × 2 | `376b,377b` | `none` |
| `chp12_q1.4` | Help Taka predict the kittens' future | `collect_and_interact`; `firefly` × 3 | `378a,379b,380c` | `none` |

## chp12_q2: Housewarming

Configured quest `level` **381**; assigned character **Olivia**.

Setup (localized quest text): “With kittens on the way, Cubby and Olivia are gonna need a new family hut. Help Ava build the hut... and find out what's eating Cubby!”

Journal outcome (localized quest text): “We built Cubby and Olivia a new family hut in preparation for the arrival of the kittens. But when it came time for the housewarming, Cubby didn't show up.”

Configured scenes: `chp12_q2` (quest_start: chp12_q2); `t1chp12_q2` (quest_task_completed: chp12_q2.1); `t2chp12_q2` (quest_task_completed: chp12_q2.2); `t3chp12_q2` (quest_task_completed: chp12_q2.3); `t4chp12_q2` (quest_task_completed: chp12_q2.4); `ftchp12_q2` (claim_button_tapped: chp12_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp12_q2.1` | Build Olivia and Cubby's family hut | `collect_and_repair`; `log` × 4 | `381a,382c,383b,384b` | `ch12_weddinghut_hut` |
| `chp12_q2.2` | Hang Ava's crib on the tree | `collect_and_repair`; `vine` × 2 | `385b,386a` | `ch12_weddinghut_tree_cradle` |
| `chp12_q2.3` | Repair Olivia's old rocking chair | `collect_and_repair`; `bamboo` × 2 | `387c,388c` | `ch12_weddinghut_chair` |
| `chp12_q2.4` | Eat lunch and talk with Cubby | `collect_and_interact`; `berries` × 2 | `389b,390b` | `none` |
| `chp12_q2.5` | Reach Village Rank 20 | `reach_rank`; `harmony` × 20 | `none` | `none` |

## chp12_q3: Cold Paws

Configured quest `level` **391**; assigned character **Elsie**.

Setup (localized quest text): “Olivia has gone into labor... and Cubby has disappeared from the village! Help Ragnaruff track down the daddy-in-waiting and let's make Olivia comfortable.”

Journal outcome (localized quest text): “Olivia went into labor and Cubby vanished from the village. Luckily Ragnaruff tracked him down and convinced him that he's gonna be a great dad. Olivia isn't the only one with insecurities...”

Configured scenes: `chp12_q3` (quest_start: chp12_q3); `t1chp12_q3` (quest_task_completed: chp12_q3.1); `t3chp12_q3` (quest_task_completed: chp12_q3.3); `t4chp12_q3` (quest_task_completed: chp12_q3.4); `t2chp12_q3` (quest_task_completed: chp12_q3.2); `ftchp12_q3` (claim_button_tapped: chp12_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp12_q3.1` | Help Ragnaruff search for Cubby's tracks | `collect_and_interact`; `tracks_2` × 3 | `391a,392b,393c` | `none` |
| `chp12_q3.2` | Picnic with Alapa, Kip, and Lily | `collect_and_interact`; `grilled_banana` × 2 | `394b,395b` | `none` |
| `chp12_q3.3` | Pray for the kittens' safe delivery | `collect_and_interact`; `incense` × 2 | `396a,397c` | `none` |
| `chp12_q3.4` | Make catnip tea for Olivia | `collect_and_interact`; `herb` × 3 | `398a,399b,400c` | `none` |

## chp12_q4: Welcome To Kittengarden

Configured quest `level` **401**; assigned character **Elsie**.

Setup (localized quest text): “Cubby is ready to be a daddy! He's returned to the village and wants to build his kits the best playground ever.”

Journal outcome (localized quest text): “With Cubby embracing fatherhood, him and Chief built a playground for the new kittens and it was finished just in time for their arrival... Olivia gave birth to twins!”

Configured scenes: `chp12_q4` (quest_start: chp12_q4); `t1chp12_q4` (quest_task_completed: chp12_q4.1); `t2chp12_q4` (quest_task_completed: chp12_q4.2); `t3chp12_q4` (quest_task_completed: chp12_q4.3); `t4chp12_q4` (quest_task_completed: chp12_q4.4); `ftchp12_q4` (claim_button_tapped: chp12_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp12_q4.1` | Build a playground for the kittens | `collect_and_repair`; `bamboo` × 3 | `401a,402c,403b` | `ch12_playground_main` |
| `chp12_q4.2` | Make a yarn ball toy for the playground | `collect_and_repair`; `cotton` × 2 | `404b,405a` | `ch12_playground_yarnball` |
| `chp12_q4.3` | Help Cubby apologize to Olivia | `collect_and_interact`; `bouquet` × 3 | `406c,407b,408b` | `none` |
| `chp12_q4.4` | Write down kitten names | `collect_and_interact`; `page` × 2 | `409a,410c` | `none` |
| `chp12_q4.5` | Reach Village Rank 21 | `reach_rank`; `harmony` × 21 | `none` | `none` |

