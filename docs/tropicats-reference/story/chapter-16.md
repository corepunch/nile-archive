# Chapter 16: Bad Romance

[Story index](../STORY.md) · [Previous](chapter-15.md) · [Next](chapter-17.md)

Campaign levels **531–570**; starts with `chp16_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Elsie breaks off a disappointing date with Furbert; a garden and serenade do not solve the problem. He rediscovers his pirate identity and stands up to his mother, then he and Nibblesby settle on the island before a ship appears in distress.

## chp16_q1: Split Purrsonality

Configured quest `level` **531**; assigned character **Elsie**.

Setup (localized quest text): “Furbert wants to go on a date. It doesn’t feel the same as when he was the dashing Captain Blacktail, but let’s give it a go and see what happens.”

Journal outcome (localized quest text): “I went on a date with Furbert, but it was a complete disaster. Whatever happened to my dashing and brave pirate captain? I’ve dumped Furbert. Surely there must be some way to get Blacktail back?”

Configured scenes: `chp16_q1` (quest_start: chp16_q1); `t1chp16_q1` (quest_task_completed: chp16_q1.1); `t2chp16_q1` (quest_task_completed: chp16_q1.2); `t3chp16_q1` (quest_task_completed: chp16_q1.3); `t4chp16_q1` (quest_task_completed: chp16_q1.4); `ftchp16_q1` (claim_button_tapped: chp16_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp16_q1.1` | Groom for the date | `collect_and_interact`; `grooming_brush` × 2 | `531a,532c` | `none` |
| `chp16_q1.2` | Apply some irresistible perfume | `collect_and_interact`; `perfume` × 3 | `533c,534b,535c` | `none` |
| `chp16_q1.3` | Prepare some date night music | `collect_and_interact`; `ukulele` × 2 | `536c,537a` | `none` |
| `chp16_q1.4` | Find Nibblesby’s etiquette guide | `collect_and_interact`; `page` × 3 | `538b,539c,540b` | `none` |

## chp16_q2: Garden Of Love

Configured quest `level` **541**; assigned character **Nibblesby**.

Setup (localized quest text): “Good day, Chief! Nibblesby here! I hope you don’t mind me writing in your diary? Let’s build an Impurrial garden... and compose a spiffing love song to help Master Furbert win Elsie’s heart!”

Journal outcome (localized quest text): “Nibblesby suggested that Furbert build a fancy garden to serenade me from! The garden is actually really nice, but the song was awful! Furbert is just not my type! He needs to step out of his mother’s shadow and live his own life!”

Configured scenes: `chp16_q2` (quest_start: chp16_q2); `t1chp16_q2` (quest_task_completed: chp16_q2.1); `t2chp16_q2` (quest_task_completed: chp16_q2.2); `t3chp16_q2` (quest_task_completed: chp16_q2.3); `t4chp16_q2` (quest_task_completed: chp16_q2.4); `ftchp16_q2` (claim_button_tapped: chp16_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp16_q2.1` | Build the Garden of Love | `collect_and_repair`; `leaves` × 3 | `541a,542c,543b` | `ch16_rondel_serenade` |
| `chp16_q2.2` | Place some romantic parasols | `collect_and_repair`; `fabric` × 2 | `544b,545c` | `ch16_parasol_lace` |
| `chp16_q2.3` | Add a monument to true love | `collect_and_repair`; `bouquet` × 3 | `546a,547b,548c` | `ch16_pedestal_bouquet_B` |
| `chp16_q2.4` | Help Nibblesby compose a serenade | `collect_and_interact`; `scroll` × 2 | `549a,550c` | `none` |
| `chp16_q2.5` | Reach Village Rank 28 | `reach_rank`; `harmony` × 28 | `none` | `none` |

## chp16_q3: The Blacktail Agenda

Configured quest `level` **551**; assigned character **Elsie**.

Setup (localized quest text): “Furbert needs to step out of his mother’s shadow and rediscover his inner pirate! Chief, let’s help Blacktail become a pirate again!”

Journal outcome (localized quest text): “My dashing Captain Blacktail is back! After rediscovering his inner pirate and standing up to his mother, the part of him that was Furbert has been banished for good. Now I can fall in love with him all over again!”

Configured scenes: `chp16_q3` (quest_start: chp16_q3); `t1chp16_q3` (quest_task_completed: chp16_q3.1); `t2chp16_q3` (quest_task_completed: chp16_q3.2); `t3chp16_q3` (quest_task_completed: chp16_q3.3); `t4chp16_q3` (quest_task_completed: chp16_q3.4); `ftchp16_q3` (claim_button_tapped: chp16_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp16_q3.1` | Drink clam brew with Furbert | `collect_and_interact`; `shell` × 3 | `551c,552a,553c` | `none` |
| `chp16_q3.2` | Take Furbert sailing with Ragnaruff | `collect_and_interact`; `anchor` × 2 | `554c,555b` | `none` |
| `chp16_q3.3` | Bury some booty with Kip | `collect_and_interact`; `lockbox` × 3 | `556b,557a,558c` | `none` |
| `chp16_q3.4` | Remind Furbert how to talk like a pirate | `collect_and_interact`; `page` × 2 | `559b,560c` | `none` |

## chp16_q4: Setting Up Home

Configured quest `level` **561**; assigned character **Elsie**.

Setup (localized quest text): “Now that Blacktail and Nibblesby are going to be staying on Tropicat Island, we need to find homes for them!”

Journal outcome (localized quest text): “The Duchess has finally left, hopefully never to return! Blacktail has moved into the mansion, and we built a cute little hut for Nibblesby. We gazed out to sea and saw a ship in trouble. Someone needs saving!”

Configured scenes: `chp16_q4` (quest_start: chp16_q4); `t1chp16_q4` (quest_task_completed: chp16_q4.1); `t2chp16_q4` (quest_task_completed: chp16_q4.2); `t3chp16_q4` (quest_task_completed: chp16_q4.3); `t4chp16_q4` (quest_task_completed: chp16_q4.4); `ftchp16_q4` (claim_button_tapped: chp16_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp16_q4.1` | Help Blacktail move into the mansion | `collect_and_interact`; `lockbox` × 2 | `561b,562b` | `none` |
| `chp16_q4.2` | Build a cute little hut for Nibblesby | `collect_and_repair`; `log` × 3 | `563c,564a,565b` | `ch16_hut_nibblesby` |
| `chp16_q4.3` | Find a way to keep Nibblesby busy | `collect_and_repair`; `bamboo` × 3 | `566c,567a,568b` | `ch16_treadmill_hamster` |
| `chp16_q4.4` | Celebrate Blacktail’s return at the tavern | `collect_and_interact`; `cocktail` × 2 | `569b,570c` | `none` |
| `chp16_q4.5` | Reach Village Rank 29 | `reach_rank`; `harmony` × 29 | `none` | `none` |

