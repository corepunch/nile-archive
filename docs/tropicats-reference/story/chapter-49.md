# Chapter 49: Felicity's Feast

[Story index](../STORY.md) · [Previous](chapter-48.md) · [Next](chapter-50.md)

Campaign levels **1851–1890**; starts with `chp49_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Felicity's new bistro draws more customers than expected. Its success strains the group and exhausts the helpers as supplies run low.

## chp49_q1: Cookin' Up Somethin' Good

Configured quest `level` **1851**; assigned character **Elsie**.

Setup (localized quest text): “It's time to build Felicity's restaurant, Chief! Let's get to work.”

Journal outcome (localized quest text): “The look on Felicity's face when she saw her brand new restaurant was the most heartwarming thing ever! I love love, and this was just about the loveliest thing I'd ever seen.”

Configured scenes: `chp49_q1` (quest_start: chp49_q1); `t1chp49_q1` (quest_task_completed: chp49_q1.1); `t2chp49_q1` (quest_task_completed: chp49_q1.2); `t3chp49_q1` (quest_task_completed: chp49_q1.3); `t4chp49_q1` (quest_task_completed: chp49_q1.4); `ftchp49_q1` (claim_button_tapped: chp49_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp49_q1.1` | Distract Felicity | `collect_and_interact`; `jesterstick` × 3 | `1851a,1852b,1853c` | `none` |
| `chp49_q1.2` | Check Felicity's inventory | `collect_and_interact`; `fancyscroll` × 3 | `1854a,1855c,1856b` | `none` |
| `chp49_q1.3` | Plan a budget | `collect_and_interact`; `scroll` × 1 | `1857c` | `none` |
| `chp49_q1.4` | Build Felicity's Bistro | `collect_and_repair`; `log` × 3 | `1858a,1859b,1860c` | `ch49_restaurant_main` |

## chp49_q2: Supply And Demand

Configured quest `level` **1861**; assigned character **Elsie**.

Setup (localized quest text): “There's a lot of work to do to maintain a restaurant. Let's get it running smoothly, Chief!”

Journal outcome (localized quest text): “Felicity's Bistro ended up being way more popular than any of us ever expected. Cats from all over the Pawcific came to visit to try Felicity's cooking, and we barely managed it, but seeing Felicity happy made it all worth it.”

Configured scenes: `chp49_q2` (quest_start: chp49_q2); `t1chp49_q2` (quest_task_completed: chp49_q2.1); `t2chp49_q2` (quest_task_completed: chp49_q2.2); `t3chp49_q2` (quest_task_completed: chp49_q2.3); `t4chp49_q2` (quest_task_completed: chp49_q2.4); `ftchp49_q2` (claim_button_tapped: chp49_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp49_q2.1` | Clean the tables | `collect_and_interact`; `cotton` × 4 | `1861a,1862c,1863b,1864c` | `none` |
| `chp49_q2.2` | Try a new recipe | `collect_and_interact`; `page` × 3 | `1865a,1866b,1867c` | `none` |
| `chp49_q2.3` | Take care of the guests | `collect_and_interact`; `magn_glass` × 1 | `1868c` | `none` |
| `chp49_q2.4` | Check on the kitchen | `collect_and_interact`; `grilled_banana` × 2 | `1869a,1870b` | `none` |
| `chp49_q2.5` | Reach Village Rank 94 | `reach_rank`; `harmony` × 94 | `none` | `none` |

## chp49_q3: Yes, Chef!

Configured quest `level` **1871**; assigned character **Elsie**.

Setup (localized quest text): “Felicity's Bistro has got to run even more smoothly today. Think we can do it, Chief?”

Journal outcome (localized quest text): “We were all really tired after running the restaurant for two days. The only one of us who wasn't was Mee Li, it seemed. We were running out of supplies fast, but Mee Li had a solution.”

Configured scenes: `chp49_q3` (quest_start: chp49_q3); `t1chp49_q3` (quest_task_completed: chp49_q3.1); `t2chp49_q3` (quest_task_completed: chp49_q3.2); `t3chp49_q3` (quest_task_completed: chp49_q3.3); `t4chp49_q3` (quest_task_completed: chp49_q3.4); `ftchp49_q3` (claim_button_tapped: chp49_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp49_q3.1` | Prep vegetables | `collect_and_interact`; `tomato` × 1 | `1871b` | `none` |
| `chp49_q3.2` | Stock the kitchen | `collect_and_interact`; `marrow` × 4 | `1872c,1873b,1874a,1875b` | `none` |
| `chp49_q3.3` | Deal with customers | `collect_and_interact`; `magn_glass` × 1 | `1876c` | `none` |
| `chp49_q3.4` | Take out the trash | `collect_and_interact`; `garbage` × 4 | `1877a,1878c,1879b,1880c` | `none` |

## chp49_q4: Purrnout

Configured quest `level` **1881**; assigned character **Elsie**.

Setup (localized quest text): “Now we've got to make more engine prototypes AND run the restaurant?! Good thing we've got you!”

Journal outcome (localized quest text): “We were all really happy for Felicity's Bistro to be so successful, but we were all getting more exhausted by the day... except for Mee Li. We weren't sure how much more Ava and Meownardo could take!”

Configured scenes: `chp49_q4` (quest_start: chp49_q4); `t1chp49_q4` (quest_task_completed: chp49_q4.1); `t2chp49_q4` (quest_task_completed: chp49_q4.2); `t3chp49_q4` (quest_task_completed: chp49_q4.3); `t4chp49_q4` (quest_task_completed: chp49_q4.4); `ftchp49_q4` (claim_button_tapped: chp49_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp49_q4.1` | Plan a production schedule | `collect_and_interact`; `calendar` × 3 | `1881b,1882a,1883c` | `none` |
| `chp49_q4.2` | Take a break | `collect_and_interact`; `porcelain_cup` × 1 | `1884a` | `none` |
| `chp49_q4.3` | Brew some coffee | `collect_and_interact`; `coffee` × 3 | `1885b,1886c,1887b` | `none` |
| `chp49_q4.4` | Check in with Mee Li | `collect_and_interact`; `magn_glass` × 3 | `1888c,1889b,1890c` | `none` |
| `chp49_q4.5` | Reach Village Rank 95 | `reach_rank`; `harmony` × 95 | `none` | `none` |

