# Chapter 8: Who's A Good Boy?

[Story index](../STORY.md) · [Previous](chapter-07.md) · [Next](chapter-09.md)

Campaign levels **211–250**; starts with `chp8_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Ragnaruff saves the kittens and earns a place in the tribe. The cats make a home for him and introduce him to their customs; at the rebuilt observatory Olivia sees a sign she associates with the ancestors' return.

## chp8_q1: Kitten Rescue

Configured quest `level` **211**; assigned character **Taka**.

Setup (localized quest text): “Ragnaruff is gonna free the kittens from the swamp crocs. Help him prepare for his heroic rescue mission.”

Journal outcome (localized quest text): “With the help of {userName}, Ragnaruff rescued the kittens from the crocodiles. This doggy really is a hero! Maybe he's telling the truth about the message in a bottle?”

Configured scenes: `chp8_q1` (quest_start: chp8_q1); `t1chp8_q1` (quest_task_completed: chp8_q1.1); `t2chp8_q1` (quest_task_completed: chp8_q1.2); `t3chp8_q1` (quest_task_completed: chp8_q1.3); `t4chp8_q1` (quest_task_completed: chp8_q1.4); `ftchp8_q1` (claim_button_tapped: chp8_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp8_q1.1` | Catch fish to bait the crocodiles | `collect_and_interact`; `fish` × 3 | `211a,212b,213c` | `none` |
| `chp8_q1.2` | Collect sleeping berries to dose the bait | `collect_and_interact`; `berries` × 3 | `214b,215c,216b` | `none` |
| `chp8_q1.3` | Collect vines to tie up the crocs | `collect_and_interact`; `vine` × 2 | `217b,218c` | `none` |
| `chp8_q1.4` | Gather swamp leaves for camouflage | `collect_and_interact`; `leaves` × 2 | `219b,220c` | `none` |

## chp8_q2: In The Dog House

Configured quest `level` **221**; assigned character **Taka**.

Setup (localized quest text): “We've decided Ragnaruff can stay on the island. Help Ava convert our old warehouse into a doggy hut.”

Journal outcome (localized quest text): “We converted the old warehouse into a doggy hut and told Ragnaruff he could stay on the island. It could be useful having a hero around!”

Configured scenes: `chp8_q2` (quest_start: chp8_q2); `t1chp8_q2` (quest_task_completed: chp8_q2.1); `t2chp8_q2` (quest_task_completed: chp8_q2.2); `t3chp8_q2` (quest_task_completed: chp8_q2.3); `ftchp8_q2` (claim_button_tapped: chp8_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp8_q2.1` | Convert the warehouse into a dog house | `collect_and_repair`; `log` × 4 | `221a,222b,223a,224c` | `ch8_ragnaruff_doghouse` |
| `chp8_q2.2` | Replant the berry bush | `collect_and_repair`; `red_seed` × 3 | `225b,226c,227a` | `ch8_ragnaruff_bushes` |
| `chp8_q2.3` | Sharpen the wood chopping axe | `collect_and_repair`; `stone` × 3 | `228b,229b,230c` | `ch8_ragnaruff_axe` |
| `chp8_q2.4` | Reach Village Rank 12 | `reach_rank`; `harmony` × 12 | `none` | `none` |

## chp8_q3: The Tropidogs?

Configured quest `level` **231**; assigned character **Ava**.

Setup (localized quest text): “We're gonna make Ragnaruff a member of the Tropicat tribe! Let's teach him how to integrate into cat culture.”

Journal outcome (localized quest text): “Chief helped Ragnaruff learn all about cat culture and we officially welcomed the first dog ever into the Tropicat tribe!”

Configured scenes: `chp8_q3` (quest_start: chp8_q3); `t1chp8_q3` (quest_task_completed: chp8_q3.1); `t2chp8_q3` (quest_task_completed: chp8_q3.2); `t3chp8_q3` (quest_task_completed: chp8_q3.3); `t4chp8_q3` (quest_task_completed: chp8_q3.4); `ftchp8_q3` (claim_button_tapped: chp8_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp8_q3.1` | Teach Ragnaruff how to groom like a cat | `collect_and_interact`; `grooming_brush` × 2 | `231a,232c` | `none` |
| `chp8_q3.2` | Find instructions on how to purr | `collect_and_interact`; `page` × 3 | `233a,234c,235c` | `none` |
| `chp8_q3.3` | Help Ragnaruff make an offering to the ancestors | `collect_and_interact`; `incense` × 3 | `236c,237a,238c` | `none` |
| `chp8_q3.4` | Find instructions on how to meow | `collect_and_interact`; `scroll` × 2 | `239b,240c` | `none` |

## chp8_q4: Shooting Stars

Configured quest `level` **241**; assigned character **Elsie**.

Setup (localized quest text): “A star map might help Ragnaruff navigate his way home. Let's rebuild the observatory.”

Journal outcome (localized quest text): “Olivia looked through the observatory telescope and saw something shocking: A pair of red and blue shooting stars. It's a sign! Our ancestors are returning to the island!”

Configured scenes: `chp8_q4` (quest_start: chp8_q4); `t1chp8_q4` (quest_task_completed: chp8_q4.1); `t2chp8_q4` (quest_task_completed: chp8_q4.2); `t3chp8_q4` (quest_task_completed: chp8_q4.3); `ftchp8_q4` (claim_button_tapped: chp8_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp8_q4.1` | Repair the star observatory | `collect_and_repair`; `log` × 4 | `241a,242b,243c,244b` | `ch8_observatory_main` |
| `chp8_q4.2` | Fix the sun dial | `collect_and_repair`; `bamboo` × 3 | `245c,246b,247c` | `ch8_observatory_sundial` |
| `chp8_q4.3` | Restore the ancestor statue | `collect_and_repair`; `stone` × 3 | `248a,249b,250c` | `ch8_observatory_statue` |
| `chp8_q4.4` | Reach Village Rank 13 | `reach_rank`; `harmony` × 13 | `none` | `none` |

