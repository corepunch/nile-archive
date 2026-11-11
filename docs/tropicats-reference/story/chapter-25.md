# Chapter 25

[Story index](../STORY.md) · [Previous](chapter-24.md) · [Next](chapter-26.md)

Configured chapter start: campaign level **891**; starts with `chp25_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Ragnaruff wins a trial for the right to seek the Nordog crown, and Meowser pledges allegiance to him. Olivia and the Chief discover that poison caused Gruffgar's apparent voices.

## chp25_q1: Hero Or Zero?

Configured quest `level` **891**; assigned character **Elsie**.

Setup (localized quest text): “Chief! It's me, Redd! We gotta find a way to stop Gruffgar and help Ragnaruff find his inner hero again!”

Journal outcome (localized quest text): “I was ready to give up being a hero, but Chief and Cubby changed my mind and persuaded me to challenge Gruffgar to the Trial of Guts. If I win this sausage eating duel, I get to seek Fenrir's approval to become king. But if I lose... I die!”

Configured scenes: `chp25_q1` (quest_start: chp25_q1); `t1chp25_q1` (quest_task_completed: chp25_q1.1); `t2chp25_q1` (quest_task_completed: chp25_q1.2); `t3chp25_q1` (quest_task_completed: chp25_q1.3); `t4chp25_q1` (quest_task_completed: chp25_q1.4); `ftchp25_q1` (claim_button_tapped: chp25_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp25_q1.1` | Find a way to challenge King Gruffgar | `collect_and_interact`; `BookNordog` × 3 | `891a,892c,893b` | `none` |
| `chp25_q1.2` | Find a gift to calm King Gruffgar | `collect_and_interact`; `bouquet` × 3 | `894c,895a,896c` | `none` |
| `chp25_q1.3` | Write a heroic ballad for Ragnaruff | `collect_and_interact`; `ukulele` × 2 | `897b,898c` | `none` |
| `chp25_q1.4` | Help Cubby pack for Nordog Island | `collect_and_interact`; `lockbox` × 2 | `899a,900b` | `none` |

## chp25_q2: The Trial Of Guts

Configured quest `level` **901**; assigned character **Elsie**.

Setup (localized quest text): “Help me prepare for the Trial of Guts! If I win this eating duel, I can seek Fenrir's approval to become king myself!”

Journal outcome (localized quest text): “I defeated King Gruffgar at the Trial of Guts, thanks to rigorous training from Cubby, allowing me to seek Fenrir's approval for the throne. Meanwhile, Lt. Meowser received news he'd been dishonorably discharged from the Impurrial Army...”

Configured scenes: `chp25_q2` (quest_start: chp25_q2); `t1chp25_q2` (quest_task_completed: chp25_q2.1); `t2chp25_q2` (quest_task_completed: chp25_q2.2); `t3chp25_q2` (quest_task_completed: chp25_q2.3); `t4chp25_q2` (quest_task_completed: chp25_q2.4); `ftchp25_q2` (claim_button_tapped: chp25_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp25_q2.1` | Teach Ragnaruff how to really eat | `collect_and_interact`; `BurntSausage` × 4 | `901c,902a,903b,904c` | `none` |
| `chp25_q2.2` | Find something to soothe Ragnaruff’s tummy | `collect_and_interact`; `cream` × 3 | `905b,906c,907b` | `none` |
| `chp25_q2.3` | Deliver a letter to Lt. Meowser | `collect_and_interact`; `RedLetter` × 1 | `908a` | `none` |
| `chp25_q2.4` | Learn the rules of the Trial of Guts | `collect_and_interact`; `scroll` × 2 | `909c,910a` | `none` |
| `chp25_q2.5` | Reach Village Rank 46 | `reach_rank`; `harmony` × 46 | `none` | `none` |

## chp25_q3: Fenrir’s Favor

Configured quest `level` **911**; assigned character **Elsie**.

Setup (localized quest text): “I can’t be king without Fenrir’s blessing, Chief! How can I prove I'm a worthy leader?”

Journal outcome (localized quest text): “I needed to prove to Fenrir that I was worthy to lead the Nordog tribe. Luckily, Chief and Lt. Meowser knew exactly what to do. Meowser offered his sword to Fenrir and pledged loyalty to me! He's the first cat to swear allegiance a dog! Fenrir's statue now heels to my call.”

Configured scenes: `chp25_q3` (quest_start: chp25_q3); `t1chp25_q3` (quest_task_completed: chp25_q3.1); `t2chp25_q3` (quest_task_completed: chp25_q3.2); `t3chp25_q3` (quest_task_completed: chp25_q3.3); `t4chp25_q3` (quest_task_completed: chp25_q3.4); `ftchp25_q3` (claim_button_tapped: chp25_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp25_q3.1` | Prove that King Ragnaruff is a leader | `collect_and_repair`; `sword` × 1 | `911b` | `ch25_wolf_dog` |
| `chp25_q3.2` | Replant the trees around Fenrir | `collect_and_repair`; `seed` × 4 | `912a,913c,914b,915a` | `ch25_pine_forest` |
| `chp25_q3.3` | Recruit a smartypants | `collect_and_interact`; `BlueLetter` × 1 | `916c` | `none` |
| `chp25_q3.4` | Bring Gruffgar tea | `collect_and_interact`; `DogTea` × 4 | `917b,918c,919b,920c` | `none` |

## chp25_q4: One Sick Doggy

Configured quest `level` **921**; assigned character **Elsie**.

Setup (localized quest text): “Chief, we've gotta figure out why Gruffgar is hearing voices. Help Olivia diagnose his illness.”

Journal outcome (localized quest text): “Chief and Olivia discovered that Gruffgar’s food was poisoned all along! That’s why he was hearing voices. Did the poisoner intend to start a war? Now that we know what happened, we’ve got to figure out who is responsible.”

Configured scenes: `chp25_q4` (quest_start: chp25_q4); `t1chp25_q4` (quest_task_completed: chp25_q4.1); `t2chp25_q4` (quest_task_completed: chp25_q4.2); `t3chp25_q4` (quest_task_completed: chp25_q4.3); `t4chp25_q4` (quest_task_completed: chp25_q4.4); `ftchp25_q4` (claim_button_tapped: chp25_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp25_q4.1` | Examine the King’s royal sausages | `collect_and_interact`; `BurntSausage` × 2 | `921b,922c` | `none` |
| `chp25_q4.2` | Inspect the King’s tea | `collect_and_interact`; `DogTea` × 3 | `923b,924a,925c` | `none` |
| `chp25_q4.3` | Follow the suspicious paw prints | `collect_and_interact`; `SnowPrint` × 2 | `926a,927c` | `none` |
| `chp25_q4.4` | Take a break with Olivia and Cubby | `collect_and_interact`; `grilled_banana` × 3 | `928b,929c,930b` | `none` |
| `chp25_q4.5` | Reach Village Rank 47 | `reach_rank`; `harmony` × 47 | `none` | `none` |

