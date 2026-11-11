# Chapter 28

[Story index](../STORY.md) · [Previous](chapter-27.md) · [Next](chapter-29.md)

Configured chapter start: campaign level **1011**; starts with `chp28_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Sylvia's amnesia poison affects the Duchess; an antidote restores hope and Sylvia faces trial. Ragnaruff gives her a chance to make amends, and the Duchess permits Blacktail and Elsie to marry despite the Queen's wishes.

## chp28_q1: A Mixed Up Mind

Configured quest `level` **1011**; assigned character **Elsie**.

Setup (localized quest text): “We've got to find an antidote to Sylvia's poison and help the Duchess get her memories back, Chief!”

Journal outcome (localized quest text): “We thought Sylvia was helping us find our parents, but she gave the Duchess a poison that caused amnesia instead! We had no idea how to help her until a strange black jungle cat came down from the trees to help us. Who is she, I wonder?”

Configured scenes: `chp28_q1` (quest_start: chp28_q1); `t1chp28_q1` (quest_task_completed: chp28_q1.1); `t2chp28_q1` (quest_task_completed: chp28_q1.2); `t3chp28_q1` (quest_task_completed: chp28_q1.3); `t4chp28_q1` (quest_task_completed: chp28_q1.4); `ftchp28_q1` (claim_button_tapped: chp28_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp28_q1.1` | Make an antidote for the Duchess | `collect_and_interact`; `ceramic_bottle` × 3 | `1011a,1012c,1013b` | `none` |
| `chp28_q1.2` | Look for the other parents with Alapa | `collect_and_interact`; `magn_glass` × 2 | `1014c,1015b` | `none` |
| `chp28_q1.3` | Help Elsie groom the Duchess | `collect_and_interact`; `grooming_brush` × 2 | `1016c` | `none` |
| `chp28_q1.4` | Recruit the Nordog Navy | `collect_and_interact`; `anchor` × 3 | `1017a,1018b,1019a,1020c` | `none` |

## chp28_q2: Toil And Trouble

Configured quest `level` **1021**; assigned character **Elsie**.

Setup (localized quest text): “The jungle cat is Olivia's mother! It's time to make that antidote, Chief.”

Journal outcome (localized quest text): “With Chief's help, we managed to cure my mother and the Duchess of Sylvia's amnesia poison, and we waited for them to regain their memories. Lt. Meowser arrived to tell us Sylvia had been captured... the trial was about to begin!”

Configured scenes: `chp28_q2` (quest_start: chp28_q2); `t1chp28_q2` (quest_task_completed: chp28_q2.1); `t2chp28_q2` (quest_task_completed: chp28_q2.2); `t3chp28_q2` (quest_task_completed: chp28_q2.3); `t4chp28_q2` (quest_task_completed: chp28_q2.4); `ftchp28_q2` (claim_button_tapped: chp28_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp28_q2.1` | Repair the cauldron | `collect_and_repair`; `log` × 1 | `1021c,1022b,1023c,1024a` | `ch28_cauldron_meowgic` |
| `chp28_q2.2` | Collect the antidote ingredients | `collect_and_interact`; `herb` × 3 | `1025a,1026b,1027c` | `none` |
| `chp28_q2.3` | Study the amnesia poison | `collect_and_interact`; `DogTea` × 5 | `1028c,1029a` | `none` |
| `chp28_q2.4` | Talk to the Duchess about Elsie | `collect_and_interact`; `magn_glass` × 1 | `1030b` | `none` |
| `chp28_q2.5` | Reach Village Rank 52 | `reach_rank`; `harmony` × 52 | `none` | `none` |

## chp28_q3: The Trial Of The Century

Configured quest `level` **1031**; assigned character **Elsie**.

Setup (localized quest text): “Sylvia's trial is about to begin on Nordog Island. Taka was only just reunited with her... can we get Ragnaruff to be lenient with her?”

Journal outcome (localized quest text): “Chief helped Taka defend his mother on Nordog Island. We proved that Sylvia was simply mad with grief, and Ragnaruff wisely understood that she deserved a chance to make amends for her crimes.”

Configured scenes: `chp28_q3` (quest_start: chp28_q3); `t1chp28_q3` (quest_task_completed: chp28_q3.1); `t2chp28_q3` (quest_task_completed: chp28_q3.2); `t3chp28_q3` (quest_task_completed: chp28_q3.3); `t4chp28_q3` (quest_task_completed: chp28_q3.4); `ftchp28_q3` (claim_button_tapped: chp28_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp28_q3.1` | Cross-examine Gruffgar | `collect_and_interact`; `magn_glass` × 1 | `1031a` | `none` |
| `chp28_q3.2` | Prove Sylvia is mentally unwell | `collect_and_interact`; `fish` × 3 | `1032b,1033c,1034b` | `none` |
| `chp28_q3.3` | Ask Sylvia where the other parents went | `collect_and_interact`; `tracks_1` × 3 | `1035a,1036b,1037c` | `none` |
| `chp28_q3.4` | Study Nordog law | `collect_and_interact`; `BookNordog` × 3 | `1038c,1039b,1040c` | `none` |

## chp28_q4: The Doomed Groom

Configured quest `level` **1041**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail has to marry the Hong Kitty princess. It's a sad day, but Blacktail needs Chief's help to make his last day with Elsie special.”

Journal outcome (localized quest text): “Thanks to the amnesia, the Duchess and Elsie were getting along, but she couldn't afford to upset the Queen by letting Blacktail marry Elsie. But with Chief's help, Blacktail proved his love, and the Duchess defied the Queen by letting her son marry Elsie.”

Configured scenes: `chp28_q4` (quest_start: chp28_q4); `t1chp28_q4` (quest_task_completed: chp28_q4.1); `t2chp28_q4` (quest_task_completed: chp28_q4.2); `t3chp28_q4` (quest_task_completed: chp28_q4.3); `t4chp28_q4` (quest_task_completed: chp28_q4.4); `ftchp28_q4` (claim_button_tapped: chp28_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp28_q4.1` | Help Blacktail make Elsie a necklace | `collect_and_interact`; `pearls` × 3 | `1041b,1042a,1043c` | `none` |
| `chp28_q4.2` | Cook a romantic dinner | `collect_and_interact`; `strawberry_bowl` × 2 | `1044b,1045c` | `none` |
| `chp28_q4.3` | Ask the Duchess to reconsider | `collect_and_interact`; `magn_glass` × 3 | `1046a,1047b,1048c` | `none` |
| `chp28_q4.4` | Ask Tammy what happened to the parents | `collect_and_interact`; `tracks_1` × 2 | `1049b,1050c` | `none` |
| `chp28_q4.5` | Reach Village Rank 53 | `reach_rank`; `harmony` × 53 | `none` | `none` |

