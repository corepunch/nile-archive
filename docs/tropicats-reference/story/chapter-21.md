# Chapter 21: A Way Home?

[Story index](../STORY.md) · [Previous](chapter-20.md) · [Next](chapter-22.md)

Campaign levels **731–770**; starts with `chp21_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Tracks reveal a puppy, Redd, who recounts evacuation from Nordog Island and separation from his mother in Montclaw's storm. Meanwhile Taka and the Chief help Felicity recover the confidence to enter a vegetable contest.

## chp21_q1: It's Alive!

Configured quest `level` **731**; assigned character **Elsie**.

Setup (localized quest text): “Chief, there are no spirits on this island. Whatever's harassing us is a living creature. Help Ragnaruff track it down and find out what it wants.”

Journal outcome (localized quest text): “Chief and Ragnaruff searched the forest and found dog tracks and toy rattles. Ragnaruff concluded that our troublemaker is a puppy! But where are the puppy's parents, what's it doing in Impurrial territory, and most importantly, is it from Nordog Island?”

Configured scenes: `chp21_q1` (quest_start: chp21_q1); `t1chp21_q1` (quest_task_completed: chp21_q1.1); `t2chp21_q1` (quest_task_completed: chp21_q1.2); `t3chp21_q1` (quest_task_completed: chp21_q1.4); `t4chp21_q1` (quest_task_completed: chp21_q1.3); `ftchp21_q1` (claim_button_tapped: chp21_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp21_q1.1` | Search for tracks in the woods | `collect_and_interact`; `tracks` × 3 | `731b,732c,733a` | `none` |
| `chp21_q1.2` | Look for the source of the rattling | `collect_and_interact`; `rattle` × 3 | `734b,735b,736c` | `none` |
| `chp21_q1.3` | Repair the olive grove | `collect_and_repair`; `shovel` × 3 | `737b,738c,739a` | `ch21_olivegrove` |
| `chp21_q1.4` | Find flyers for the veggie contest | `collect_and_interact`; `page` × 1 | `740b` | `none` |

## chp21_q2: The Allure Of Lures

Configured quest `level` **741**; assigned character **Elsie**.

Setup (localized quest text): “Our ghost problem just got a whole lot cuter. There’s a puppy on the island! Help Ragnaruff lure it out of hiding.”

Journal outcome (localized quest text): “Chief lured the puppy out of hiding. His name is Redd and, like Ragnaruff, he’s from Nordog Island. This puppy could help Ragnaruff finally find his way home. But what’s his story? How did he get here?”

Configured scenes: `chp21_q2` (quest_start: chp21_q2); `t1chp21_q2` (quest_task_completed: chp21_q2.1); `t2chp21_q2` (quest_task_completed: chp21_q2.2); `t3chp21_q2` (quest_task_completed: chp21_q2.3); `t4chp21_q2` (quest_task_completed: chp21_q2.4); `ftchp21_q2` (claim_button_tapped: chp21_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp21_q2.1` | Grill fish for the puppy | `collect_and_interact`; `fish` × 3 | `741c,742a,743b` | `none` |
| `chp21_q2.2` | Cook eggs for the puppy | `collect_and_interact`; `eggs` × 2 | `744c,745b` | `none` |
| `chp21_q2.3` | Teach the cats how to howl | `collect_and_interact`; `scroll` × 2 | `746c,747b` | `none` |
| `chp21_q2.4` | Sketch Felicity's paw prints | `collect_and_interact`; `tracks` × 3 | `748c,749b,750a` | `none` |
| `chp21_q2.5` | Reach Village Rank 38 | `reach_rank`; `harmony` × 38 | `none` | `none` |

## chp21_q3: Seeing Redd

Configured quest `level` **751**; assigned character **Elsie**.

Setup (localized quest text): “Redd is too nervous to tell us his story. Let’s feed and groom him. Maybe then the little pup will come outta his shell.”

Journal outcome (localized quest text): “Redd explained that the Nordog King ordered everyone to leave his island. Redd sailed with his mom, but a storm struck... the same storm caused by Montclaw. The pup fell overboard and washed up here. Why did the King order everyone to leave? No one seems to know...”

Configured scenes: `chp21_q3` (quest_start: chp21_q3); `t1chp21_q3` (quest_task_completed: chp21_q3.1); `t2chp21_q3` (quest_task_completed: chp21_q3.2); `t3chp21_q3` (quest_task_completed: chp21_q3.4); `t4chp21_q3` (quest_task_completed: chp21_q3.3); `ftchp21_q3` (claim_button_tapped: chp21_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp21_q3.1` | Help Ragnaruff groom Redd | `collect_and_interact`; `grooming_brush` × 2 | `751b,752c` | `none` |
| `chp21_q3.2` | Build a windmill | `collect_and_repair`; `log` × 3 | `753c,754b,755a` | `ch21_windmill` |
| `chp21_q3.3` | Eat lunch with Ragnaruff and Redd | `collect_and_interact`; `fish` × 3 | `756b,757c,758c` | `none` |
| `chp21_q3.4` | Play with Redd and Lily | `collect_and_interact`; `rattle` × 2 | `759a,760b` | `none` |

## chp21_q4: Self Belief

Configured quest `level` **761**; assigned character **Elsie**.

Setup (localized quest text): “Taka entered Felicity into the vegetable contest without her knowing. Felicity's a bag of nerves. A little therapy may help her believe in herself again.”

Journal outcome (localized quest text): “Taka entered Felicity into the Impurrial Vegetable Contest, but Felicity's lack of self belief meant she refused to take part. With a bit of therapy, Chief and Taka helped Felicity confront her past and regain her confidence. Finally, she's ready to achieve her dream of becoming a successful farmer.”

Configured scenes: `chp21_q4` (quest_start: chp21_q4); `t1chp21_q4` (quest_task_completed: chp21_q4.1); `t2chp21_q4` (quest_task_completed: chp21_q4.2); `t3chp21_q4` (quest_task_completed: chp21_q4.3); `t4chp21_q4` (quest_task_completed: chp21_q4.4); `ftchp21_q4` (claim_button_tapped: chp21_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp21_q4.1` | Help Felicity vent her anger | `collect_and_interact`; `shrimp` × 2 | `761b,762c` | `none` |
| `chp21_q4.2` | Help Felicity stay pawsitive | `collect_and_interact`; `cake` × 3 | `763b,764a,765c` | `none` |
| `chp21_q4.3` | Write down Felicity's talents | `collect_and_interact`; `scroll` × 2 | `766c,767b` | `none` |
| `chp21_q4.4` | Bless the soil with meowgic | `collect_and_interact`; `incense` × 3 | `768a,769c,770b` | `none` |
| `chp21_q4.5` | Reach Village Rank 39 | `reach_rank`; `harmony` × 39 | `none` | `none` |

