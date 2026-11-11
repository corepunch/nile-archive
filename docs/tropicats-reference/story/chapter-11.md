# Chapter 11: I Do, I Mew

[Story index](../STORY.md) · [Previous](chapter-10.md) · [Next](chapter-12.md)

Campaign levels **331–370**; starts with `chp11_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Olivia withdraws and calls off the wedding, but Cubby demonstrates his commitment with a proposal setting and her favorite flamingo. They marry at the restored pagoda and sail on Ragnaruff's ship.

## chp11_q1: The House Cat

Configured quest `level` **331**; assigned character **Elsie**.

Setup (localized quest text): “After her disastrous marriage proposal, Olivia is refusing to leave her hut! We gotta convince her to return to the village and get this wedding back on track.”

Journal outcome (localized quest text): “Chief and Cubby convinced Olivia to leave her hut, but they couldn't cure her insecurity. Despite Cubby's protests, Olivia called off the wedding.”

Configured scenes: `chp11_q1` (quest_start: chp11_q1); `t1chp11_q1` (quest_task_completed: chp11_q1.1); `t3chp11_q1` (quest_task_completed: chp11_q1.3); `t2chp11_q1` (quest_task_completed: chp11_q1.2); `t4chp11_q1` (quest_task_completed: chp11_q1.4); `ftchp11_q1` (claim_button_tapped: chp11_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp11_q1.1` | Clear the rubble near the pagoda | `collect_and_repair`; `shovel` × 2 | `331a,332c` | `ch11_rubble` |
| `chp11_q1.2` | Help Cubby apologize to Olivia | `collect_and_interact`; `bouquet` × 3 | `333a,334c,335a` | `none` |
| `chp11_q1.3` | Write down romantic lines for Cubby | `collect_and_interact`; `page` × 3 | `336c,337b,338a` | `none` |
| `chp11_q1.4` | Cook lunch for Cubby and Ava | `collect_and_interact`; `watermelon` × 2 | `339b,340c` | `none` |

## chp11_q2: Love Birds

Configured quest `level` **341**; assigned character **Elsie**.

Setup (localized quest text): “Olivia is afraid Cubby might break her heart! Help Cubby prove his love is for real. Build a beautiful proposal spot and track down Olivia's favorite bird: the flamingo.”

Journal outcome (localized quest text): “Cubby and Chief built an amazing proposal spot and convinced Olivia's favorite animal, the pink flamingo, to come stay in the village. Olivia was bowled over. The wedding is back on!”

Configured scenes: `chp11_q2` (quest_start: chp11_q2); `t1chp11_q2` (quest_task_completed: chp11_q2.1); `t2chp11_q2` (quest_task_completed: chp11_q2.2); `t3chp11_q2` (quest_task_completed: chp11_q2.3); `t4chp11_q2` (quest_task_completed: chp11_q2.4); `ftchp11_q2` (claim_button_tapped: chp11_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp11_q2.1` | Build Cubby's proposal spot | `collect_and_repair`; `bamboo` × 3 | `341a,342a,343c` | `ch11_platform_main` |
| `chp11_q2.2` | Convince a pink flamingo to visit the village | `collect_and_repair`; `shrimp` × 3 | `344a,345b,346c` | `ch11_platform_flamingo` |
| `chp11_q2.3` | Plant Olivia's favorite flowers | `collect_and_repair`; `red_seed` × 3 | `347b,348a,349c` | `ch11_platform_flowers` |
| `chp11_q2.4` | Find Cubby's mother's wedding ring | `collect_and_interact`; `golden_ring` × 1 | `350c` | `none` |
| `chp11_q2.5` | Reach Village Rank 18 | `reach_rank`; `harmony` × 18 | `none` | `none` |

## chp11_q3: Pagoda Of Purrs

Configured quest `level` **351**; assigned character **Cubby**.

Setup (localized quest text): “Cubby and Olivia's wedding is back on track! Let's rebuild the Pagoda of Passionate Purrs, where the ceremony will take place.”

Journal outcome (localized quest text): “We restored the Pagoda of Passionate Purrs, baked a wonderful wedding cake, and made Olivia a purrfect wedding dress. Olivia and Cubby finally tied the knot.”

Configured scenes: `chp11_q3` (quest_start: chp11_q3); `t1chp11_q3` (quest_task_completed: chp11_q3.1); `t2chp11_q3` (quest_task_completed: chp11_q3.2); `t3chp11_q3` (quest_task_completed: chp11_q3.3); `t4chp11_q3` (quest_task_completed: chp11_q3.4); `ftchp11_q3` (claim_button_tapped: chp11_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp11_q3.1` | Rebuild the Pagoda of Passionate Purrs | `collect_and_repair`; `log` × 3 | `351a,352b,353b` | `ch11_padoga_main` |
| `chp11_q3.2` | Bake a wedding cake | `collect_and_repair`; `honey` × 2 | `354a,355c` | `ch11_padoga_cake` |
| `chp11_q3.3` | Make Olivia's wedding dress | `collect_and_interact`; `cotton` × 3 | `356c,357a,358b` | `none` |
| `chp11_q3.4` | Help Ragnaruff prepare a 'best dog' speech | `collect_and_interact`; `page` × 2 | `359b,360b` | `none` |

## chp11_q4: Cat Cruise

Configured quest `level` **361**; assigned character **Cubby**.

Setup (localized quest text): “Ragnaruff wants to take Olivia and Cubby on a honeymoon cruise on his ship. Help him get his boat back on the sea.”

Journal outcome (localized quest text): “Cubby had forgotten to plan a honeymoon, so Chief patched up Ragnaruff's ship and the doggy took our newlyweds on a honeymoon sail around the island.”

Configured scenes: `chp11_q4` (quest_start: chp11_q4); `t1chp11_q4` (quest_task_completed: chp11_q4.1); `t2chp11_q4` (quest_task_completed: chp11_q4.2); `t3chp11_q4` (quest_task_completed: chp11_q4.3); `t4chp11_q4` (quest_task_completed: chp11_q4.4); `ftchp11_q4` (claim_button_tapped: chp11_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp11_q4.1` | Plug the ship's holes | `collect_and_interact`; `bamboo` × 3 | `361a,362c,363b` | `none` |
| `chp11_q4.2` | Help Ragnaruff map the cruise route | `collect_and_interact`; `blueprints` × 3 | `364c,365a,366c` | `none` |
| `chp11_q4.3` | Prepare a picnic for the trip | `collect_and_interact`; `grilled_banana` × 3 | `367a,368a,369b` | `none` |
| `chp11_q4.4` | Find a ukulele for Ragnaruff | `collect_and_interact`; `ukulele` × 1 | `370c` | `none` |
| `chp11_q4.5` | Reach Village Rank 19 | `reach_rank`; `harmony` × 19 | `none` | `none` |

