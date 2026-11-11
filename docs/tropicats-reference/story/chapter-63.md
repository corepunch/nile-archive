# Chapter 63: Yarn Theory

[Story index](../STORY.md) · [Previous](chapter-62.md) · [Next](chapter-64.md)

Campaign levels **2411–2450**; starts with `chp63_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Another Taka explains the existence of other worlds. The group opens a portal, welcomes alternate versions of familiar cats and builds them a totem; Other Lily teaches Taka to use a crystal, and he sends a message to Elsie.

## chp63_q1: Into The Takaverse

Configured quest `level` **2411**; assigned character **Elsie**.

Setup (localized quest text): “Just where did this other Taka come from? We'd better figure it out, Chief!”

Journal outcome (localized quest text): “Hey, Chief, it's me, Taka, here to update the diary for a while! I met the coolest tom. His name is Taka, too! He taught me that there are endless worlds with endless Takas in them. How cool is that?”

Configured scenes: `chp63_q1` (quest_start: chp63_q1); `t1chp63_q1` (quest_task_completed: chp63_q1.1); `t2chp63_q1` (quest_task_completed: chp63_q1.2); `t3chp63_q1` (quest_task_completed: chp63_q1.3); `t4chp63_q1` (quest_task_completed: chp63_q1.4); `ftchp63_q1` (claim_button_tapped: chp63_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp63_q1.1` | Explain the universe(!) | `collect_and_interact`; `yarn` × 4 | `2411a,2412b,2413c,2414b` | `none` |
| `chp63_q1.2` | Show where Other Taka came from | `collect_and_interact`; `spyglass` × 4 | `2415a,2416c,2417a,2418c` | `none` |
| `chp63_q1.3` | Talk about other Tropicats | `collect_and_interact`; `chalkboard` × 1 | `2419a` | `none` |
| `chp63_q1.4` | Admire the island | `collect_and_interact`; `magn_glass` × 1 | `2420c` | `none` |

## chp63_q2: The New Tropicats

Configured quest `level` **2421**; assigned character **Elsie**.

Setup (localized quest text): “It's time to invite some more Tropicats onto the island! We just need to perform a little ritual.”

Journal outcome (localized quest text): “Performing rituals is so much easier with two Takas! We got the portal open again, and I was overjoyed to see Cubby, Lily, and Kip walk through it. Well, not the ones I know, but they looked just the same!”

Configured scenes: `chp63_q2` (quest_start: chp63_q2); `t1chp63_q2` (quest_task_completed: chp63_q2.1); `t2chp63_q2` (quest_task_completed: chp63_q2.2); `t3chp63_q2` (quest_task_completed: chp63_q2.3); `t4chp63_q2` (quest_task_completed: chp63_q2.4); `ftchp63_q2` (claim_button_tapped: chp63_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp63_q2.1` | Make an offering of water | `collect_and_interact`; `bucket` × 3 | `2421b,2422a,2423c` | `none` |
| `chp63_q2.2` | Make an offering of earth | `collect_and_interact`; `seed` × 1 | `2424b` | `none` |
| `chp63_q2.3` | Make an offering of fire | `collect_and_interact`; `chili` × 3 | `2425c,2426a,2427c` | `none` |
| `chp63_q2.4` | Make an offering of wind | `collect_and_interact`; `cake` × 3 | `2428a,2429b,2430c` | `none` |
| `chp63_q2.5` | Reach Village Rank 122 | `reach_rank`; `harmony` × 122 | `none` | `none` |

## chp63_q3: A New Totem

Configured quest `level` **2431**; assigned character **Elsie**.

Setup (localized quest text): “If our new friends are going to stay, they're going to need a totem of their own. We can count on you, Chief!”

Journal outcome (localized quest text): “We did everything we could to make our world a welcoming place for our new Tropicat friends, and there's nothing more welcoming than a totem! Theirs looked a little different from ours, but at least it helped them to stay with us.”

Configured scenes: `chp63_q3` (quest_start: chp63_q3); `t1chp63_q3` (quest_task_completed: chp63_q3.1); `t2chp63_q3` (quest_task_completed: chp63_q3.2); `t3chp63_q3` (quest_task_completed: chp63_q3.3); `t4chp63_q3` (quest_task_completed: chp63_q3.4); `ftchp63_q3` (claim_button_tapped: chp63_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp63_q3.1` | Collect some mushrooms | `collect_and_interact`; `backpack` × 2 | `2431b,2432c` | `none` |
| `chp63_q3.2` | Gather some wood | `collect_and_interact`; `log` × 3 | `2433a,2434b,2435c` | `none` |
| `chp63_q3.3` | Ask about the ancestors | `collect_and_interact`; `magn_glass` × 2 | `2436b,2437a` | `none` |
| `chp63_q3.4` | Build the totem | `collect_and_repair`; `stone` × 3 | `2438c,2439b,2440c` | `ch63_darktotem` |

## chp63_q4: A Message From Beyond

Configured quest `level` **2441**; assigned character **Elsie**.

Setup (localized quest text): “We need to bring our friends to the Island of the Ancients, and this new Lily has a new way of sending messages. Let's try it!”

Journal outcome (localized quest text): “Other Lily is just as smart as our Lily! She taught me a cool trick using the meowgick crystals that sends a message to anyone, anywhere. With any luck, Elsie will arrive on the island and then we can get to work rescuing Blacktail.”

Configured scenes: `chp63_q4` (quest_start: chp63_q4); `t1chp63_q4` (quest_task_completed: chp63_q4.1); `t2chp63_q4` (quest_task_completed: chp63_q4.2); `t3chp63_q4` (quest_task_completed: chp63_q4.3); `t4chp63_q4` (quest_task_completed: chp63_q4.4); `ftchp63_q4` (claim_button_tapped: chp63_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp63_q4.1` | Think about Elsie | `collect_and_repair`; `magn_glass` × 3 | `2441a,2442b,2443c` | `none` |
| `chp63_q4.2` | Write Elsie's name | `collect_and_interact`; `wand` × 1 | `2444b` | `none` |
| `chp63_q4.3` | Gather some Elsie fur | `collect_and_interact`; `furr_white` × 4 | `2445c,2446a,2447b,2448c` | `none` |
| `chp63_q4.4` | Hold a meowgick crystal | `collect_and_interact`; `meowgiccrystal` × 2 | `2449b,2450c` | `none` |
| `chp63_q4.5` | Reach Village Rank 123 | `reach_rank`; `harmony` × 123 | `none` | `none` |

