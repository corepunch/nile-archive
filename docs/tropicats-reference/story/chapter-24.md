# Chapter 24: Dogs Of War

[Story index](../STORY.md) · [Previous](chapter-23.md) · [Next](chapter-25.md)

Campaign levels **851–890**; starts with `chp24_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Restoring a hall honoring Gruffgar's grandfather brings hope of peace and spares Meowser. A summit collapses after the Duchess arranges Blacktail's political marriage and Blacktail clashes with Gruffgar.

## chp24_q1: Wolf Food

Configured quest `level` **851**; assigned character **Elsie**.

Setup (localized quest text): “King Gruffgar is going to execute Lt. Meowser and then continue the war. We've gotta save Meowser and figure out what's wrong with the King.”

Journal outcome (localized quest text): “We struck a deal with King Gruffgar. He’ll spare Meowser’s life if we restore his grandfather’s Hall of Honor. Meanwhile, the King said the "angels of Valhowlla" want him to unite the dog tribes and take over the isles. Meowser was right... the King thinks he's talking to angels!”

Configured scenes: `chp24_q1` (quest_start: chp24_q1); `t1chp24_q1` (quest_task_completed: chp24_q1.1); `t2chp24_q1` (quest_task_completed: chp24_q1.4); `t3chp24_q1` (quest_task_completed: chp24_q1.2); `t4chp24_q1` (quest_task_completed: chp24_q1.3); `ftchp24_q1` (claim_button_tapped: chp24_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp24_q1.1` | Help Ragnaruff stop the execution | `collect_and_interact`; `cake` × 3 | `851c,852a,853c` | `none` |
| `chp24_q1.2` | Help Meowser write his will | `collect_and_interact`; `scroll` × 2 | `854a,855b` | `none` |
| `chp24_q1.3` | Prepare Meowser's last meal | `collect_and_interact`; `fish` × 2 | `856c,857b` | `none` |
| `chp24_q1.4` | Drink tea with King Gruffgar | `collect_and_interact`; `DogTea` × 3 | `858a,859b,860c` | `none` |

## chp24_q2: The Hall of Honor

Configured quest `level` **861**; assigned character **Elsie**.

Setup (localized quest text): “The King will spare Lt. Meowser’s life if we restore the Hall of Honor and build a statue of his grandfather. Ava’s here, so let’s get to work!”

Journal outcome (localized quest text): “We rebuilt the Hall of Honor and crafted a beautiful statue of the King’s grandfather, who wrote the Code of Canines. Seeing his grandfather again had a profound effect on Gruffgar. He admitted the "angel voices" may be an illness... and agreed to talk peace with the Impurrials.”

Configured scenes: `chp24_q2` (quest_start: chp24_q2); `t1chp24_q2` (quest_task_completed: chp24_q2.1); `t2chp24_q2` (quest_task_completed: chp24_q2.2); `t3chp24_q2` (quest_task_completed: chp24_q2.3); `t4chp24_q2` (quest_task_completed: chp24_q2.4); `ftchp24_q2` (claim_button_tapped: chp24_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp24_q2.1` | Repair the Hall of Honor | `collect_and_repair`; `log` × 1 | `861c,862a` | `ch24_hall_dog` |
| `chp24_q2.2` | Carve a statue of the King's grandfather | `collect_and_repair`; `scroll_nordogs` × 3 | `863c,864b,865c` | `ch24_statue_dog` |
| `chp24_q2.3` | Ask the King about the "angels" | `collect_and_interact`; `DogTea` × 3 | `866b,867c` | `none` |
| `chp24_q2.4` | Help Meowser babysit Lily and Redd | `collect_and_interact`; `rattle` × 3 | `868b,869c,870a` | `none` |
| `chp24_q2.5` | Reach Village Rank 44 | `reach_rank`; `harmony` × 44 | `none` | `none` |

## chp24_q3: Give Peace A Chance?

Configured quest `level` **871**; assigned character **Elsie**.

Setup (localized quest text): “The King is willing to stop the war with the Impurrials. Let’s organize a peace summit on Felicity’s Farm, where the two sides can talk.”

Journal outcome (localized quest text): “Chief organized a peace summit on Felicity’s farm. Now the Nordogs and Impurrials can come together, reach a settlement and stop the war. Meanwhile, Chief wanted to test the King’s fur to figure out if he has an illness or not. But the King’s honor guard confiscated the fur.”

Configured scenes: `chp24_q3` (quest_start: chp24_q3); `t1chp24_q3` (quest_task_completed: chp24_q3.1); `t2chp24_q3` (quest_task_completed: chp24_q3.2); `t3chp24_q3` (quest_task_completed: chp24_q3.3); `t4chp24_q3` (quest_task_completed: chp24_q3.4); `ftchp24_q3` (claim_button_tapped: chp24_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp24_q3.1` | Ask Felicity to host the peace summit | `collect_and_interact`; `RedLetter` × 1 | `871a` | `none` |
| `chp24_q3.2` | Invite the Impurrials to the peace summit | `collect_and_interact`; `BlueLetter` × 3 | `872c` | `none` |
| `chp24_q3.3` | Find samples of the King's fur | `collect_and_interact`; `furr_white` × 3 | `873b,874c,875b,876c` | `none` |
| `chp24_q3.4` | Eat lunch with King Gruffgar | `collect_and_interact`; `BurntSausage` × 3 | `877a,878c,879b,880c` | `none` |

## chp24_q4: The Summit

Configured quest `level` **881**; assigned character **Elsie**.

Setup (localized quest text): “The peace summit has started. Chief, help me ease tensions between the two sides until a deal is reached.”

Journal outcome (localized quest text): “The peace summit collapsed! Due to the rising threat of dogs, the Duchess arranged a political marriage for her son. Blacktail became enraged that he couldn't marry Elsie, blamed the Nordogs, and started a fight with King Gruffgar. Now the war is back on... and the King is madder than ever!”

Configured scenes: `chp24_q4` (quest_start: chp24_q4); `t1chp24_q4` (quest_task_completed: chp24_q4.1); `t2chp24_q4` (quest_task_completed: chp24_q4.2); `t3chp24_q4` (quest_task_completed: chp24_q4.3); `t4chp24_q4` (quest_task_completed: chp24_q4.4); `ftchp24_q4` (claim_button_tapped: chp24_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp24_q4.1` | Negotiate the peace treaty | `collect_and_interact`; `scroll` × 3 | `881b` | `none` |
| `chp24_q4.2` | Calm down fights with cake | `collect_and_interact`; `cake` × 2 | `882a,883c,884b` | `none` |
| `chp24_q4.3` | Help Mee Li entertain guests | `collect_and_interact`; `cocktail` × 3 | `885c,886a,887b` | `none` |
| `chp24_q4.4` | Celebrate Blacktail's engagement to Elsie | `collect_and_interact`; `ClamBrew` × 2 | `888c,889b,890c` | `none` |
| `chp24_q4.5` | Reach Village Rank 45 | `reach_rank`; `harmony` × 45 | `none` | `none` |

