# Chapter 50: All Work And No Play

[Story index](../STORY.md) · [Previous](chapter-49.md) · [Next](chapter-51.md)

Campaign levels **1891–1930**; starts with `chp50_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The team works toward a critic's visit that does not happen as expected. The restaurant becomes unbearable even for Felicity, who breaks up with Mee Li and asks her to change her relationship with work.

## chp50_q1: The Customer Is King

Configured quest `level` **1891**; assigned character **Elsie**.

Setup (localized quest text): “Oh, hairballs. Now a food critic is coming to Felicity's Bistro. Help us prepare, Chief?”

Journal outcome (localized quest text): “I can't remember the last time I worked so hard. We were all covered in food stains after preparing for the food critic, but he never showed up. We had to do it all again the next day, but none of us had any energy left!”

Configured scenes: `chp50_q1` (quest_start: chp50_q1); `t1chp50_q1` (quest_task_completed: chp50_q1.1); `t2chp50_q1` (quest_task_completed: chp50_q1.2); `t3chp50_q1` (quest_task_completed: chp50_q1.3); `t4chp50_q1` (quest_task_completed: chp50_q1.4); `ftchp50_q1` (claim_button_tapped: chp50_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp50_q1.1` | Train Tammy in customer service | `collect_and_interact`; `chalkboard` × 3 | `1891a,1892b,1893c` | `none` |
| `chp50_q1.2` | Train Blacktail in presentation | `collect_and_interact`; `marrow` × 2 | `1894b,1895c` | `none` |
| `chp50_q1.3` | Reserve the best table | `collect_and_repair`; `book` × 1 | `1896b` | `ch50_restaurant_expansion` |
| `chp50_q1.4` | Prepare dessert | `collect_and_interact`; `cream_puff` × 4 | `1897a,1898b,1899c,1900b` | `none` |

## chp50_q2: Union Dues

Configured quest `level` **1901**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li is getting kind of unreasonable. Maybe you could persuade her to back down, Chief.”

Journal outcome (localized quest text): “Mee Li wouldn't stop fighting for her girlfriend's business. Normally, I'd think that's awesome, but she was really starting to break us down. Sooner or later, things were going to fall apart. We just didn't know how soon.”

Configured scenes: `chp50_q2` (quest_start: chp50_q2); `t1chp50_q2` (quest_task_completed: chp50_q2.1); `t2chp50_q2` (quest_task_completed: chp50_q2.2); `t3chp50_q2` (quest_task_completed: chp50_q2.3); `t4chp50_q2` (quest_task_completed: chp50_q2.4); `ftchp50_q2` (claim_button_tapped: chp50_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp50_q2.1` | Ask Mee Li for more time | `collect_and_interact`; `calendar` × 4 | `1901b,1902a,1903c,1904b` | `none` |
| `chp50_q2.2` | Send Bianca to talk to Mee Li | `collect_and_interact`; `bouquet` × 3 | `1905a,1906c,1907a` | `none` |
| `chp50_q2.3` | Try to get Mee Li's pity | `collect_and_interact`; `default` × 2 | `1908c,1909b` | `none` |
| `chp50_q2.4` | Find Mee Li a management book | `collect_and_interact`; `book` × 1 | `1910c` | `none` |
| `chp50_q2.5` | Reach Village Rank 96 | `reach_rank`; `harmony` × 96 | `none` | `none` |

## chp50_q3: I Quit!

Configured quest `level` **1911**; assigned character **Elsie**.

Setup (localized quest text): “We're running out of supplies and Blacktail called in sick. Can we make it through the day, Chief?”

Journal outcome (localized quest text): “The restaurant was too much work for all of us... even Felicity. Her dream had turned into something terrible, and she broke up with Mee Li. My heart broke for both of them... there had to be something we could do!”

Configured scenes: `chp50_q3` (quest_start: chp50_q3); `t1chp50_q3` (quest_task_completed: chp50_q3.1); `t2chp50_q3` (quest_task_completed: chp50_q3.2); `t3chp50_q3` (quest_task_completed: chp50_q3.3); `t4chp50_q3` (quest_task_completed: chp50_q3.4); `ftchp50_q3` (claim_button_tapped: chp50_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp50_q3.1` | Check on Blacktail | `collect_and_interact`; `magn_glass` × 1 | `1911b` | `none` |
| `chp50_q3.2` | Chop vegetables | `collect_and_interact`; `kitchen_knife` × 3 | `1912c,1913a,1914b` | `none` |
| `chp50_q3.3` | Seat some guests | `collect_and_interact`; `tracks_1` × 3 | `1915c,1916b,1917c` | `none` |
| `chp50_q3.4` | Serve food | `collect_and_interact`; `grilled_banana` × 3 | `1918a,1919c,1920b` | `none` |

## chp50_q4: Felicity's Choice

Configured quest `level` **1921**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li thinks she can patch things up with Felicity. Can you help, Chief?”

Journal outcome (localized quest text): “Poor Mee Li! Poor Felicity! And definitely poor me! I don't like it when awesome couples break up. Felicity told Mee Li she needed to work on herself, and well... I kind of agreed. There's more to life than work.”

Configured scenes: `chp50_q4` (quest_start: chp50_q4); `t1chp50_q4` (quest_task_completed: chp50_q4.1); `t2chp50_q4` (quest_task_completed: chp50_q4.2); `t3chp50_q4` (quest_task_completed: chp50_q4.3); `t4chp50_q4` (quest_task_completed: chp50_q4.4); `ftchp50_q4` (claim_button_tapped: chp50_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp50_q4.1` | Pick some flowers | `collect_and_interact`; `bouquet` × 3 | `1921a,1922b,1923c` | `none` |
| `chp50_q4.2` | Make a new cutting board | `collect_and_interact`; `kitchen_knife` × 2 | `1924b,1925c` | `none` |
| `chp50_q4.3` | Find cool new recipes | `collect_and_interact`; `page` × 3 | `1926a,1927b,1928c` | `none` |
| `chp50_q4.4` | Practice an apawlogy | `collect_and_interact`; `jesterstick` × 2 | `1929b,1930c` | `none` |
| `chp50_q4.5` | Reach Village Rank 97 | `reach_rank`; `harmony` × 97 | `none` | `none` |

