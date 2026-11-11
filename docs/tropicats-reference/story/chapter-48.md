# Chapter 48: Captains Of Industry

[Story index](../STORY.md) · [Previous](chapter-47.md) · [Next](chapter-49.md)

Campaign levels **1811–1850**; starts with `chp48_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The inventors demonstrate a steam engine. Mee Li sells prototypes to fund a surprise for Felicity, extending the work and delaying the journey home while she plans a restaurant.

## chp48_q1: Eureka!

Configured quest `level` **1811**; assigned character **Elsie**.

Setup (localized quest text): “Now that we've got an idea of how to build a steam engine, it's time to make one, Chief!”

Journal outcome (localized quest text): “Ava and Meownardo showed off their new steam engine. It was pretty impressive and made a lot of noise. They said it would get us home to Tropicat Island really quickly, but it sure was stinky!”

Configured scenes: `chp48_q1` (quest_start: chp48_q1); `t1chp48_q1` (quest_task_completed: chp48_q1.1); `t2chp48_q1` (quest_task_completed: chp48_q1.2); `t3chp48_q1` (quest_task_completed: chp48_q1.3); `t4chp48_q1` (quest_task_completed: chp48_q1.4); `ftchp48_q1` (claim_button_tapped: chp48_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp48_q1.1` | Find some coal | `collect_and_interact`; `coal` × 3 | `1811a,1812b,1813c` | `none` |
| `chp48_q1.2` | Work on the engine | `collect_and_interact`; `log` × 2 | `1814a,1815b` | `none` |
| `chp48_q1.3` | Build a staging area | `collect_and_repair`; `anchor` × 2 | `1816c,1817b` | `ch48_shipyard_staging` |
| `chp48_q1.4` | Modify the ship design | `collect_and_repair`; `blueprints` × 3 | `1818c,1819b,1820b` | `none` |

## chp48_q2: Business Boom

Configured quest `level` **1821**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li wants to do something special for Felicity, but needs some money. Let's sell some engines, Chief!”

Journal outcome (localized quest text): “Mee Li wanted to do something special for Felicity, and she ended up selling a lot of Ava and Meownardo's prototype engines to do it. We really didn't want to be stuck on the island forever, though!”

Configured scenes: `chp48_q2` (quest_start: chp48_q2); `t1chp48_q2` (quest_task_completed: chp48_q2.1); `t2chp48_q2` (quest_task_completed: chp48_q2.2); `t3chp48_q2` (quest_task_completed: chp48_q2.3); `t4chp48_q2` (quest_task_completed: chp48_q2.4); `ftchp48_q2` (claim_button_tapped: chp48_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp48_q2.1` | Develop some flyers | `collect_and_interact`; `fancyscroll` × 1 | `1821b` | `none` |
| `chp48_q2.2` | Train Mee Li's pigeon | `collect_and_interact`; `chalkboard` × 3 | `1822c,1823a,1824c` | `none` |
| `chp48_q2.3` | Spend time with Mee Li and Felicity | `collect_and_interact`; `porcelain_cup` × 5 | `1825a,1826b,1827a,1828c,1829b` | `none` |
| `chp48_q2.4` | Check Mee Li's budget | `collect_and_interact`; `scroll` × 1 | `1830c` | `none` |
| `chp48_q2.5` | Reach Village Rank 92 | `reach_rank`; `harmony` × 92 | `none` | `none` |

## chp48_q3: Scaling Up

Configured quest `level` **1831**; assigned character **Elsie**.

Setup (localized quest text): “Now that we've got a big engine order to fill, it's time to expand!”

Journal outcome (localized quest text): “Ava and Meownardo were exhausted after working day and night to fulfill orders for their engines. But I was sure it would be worth it to see Felicity and Mee Li happy together. I wondered what Mee Li had in store!”

Configured scenes: `chp48_q3` (quest_start: chp48_q3); `t1chp48_q3` (quest_task_completed: chp48_q3.1); `t2chp48_q3` (quest_task_completed: chp48_q3.2); `t3chp48_q3` (quest_task_completed: chp48_q3.3); `t4chp48_q3` (quest_task_completed: chp48_q3.4); `ftchp48_q3` (claim_button_tapped: chp48_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp48_q3.1` | Expand the work area | `collect_and_interact`; `log` × 1 | `1831b` | `none` |
| `chp48_q3.2` | Check on Olivia | `collect_and_interact`; `porcelain_cup` × 3 | `1832c,1833a,1834c` | `none` |
| `chp48_q3.3` | Discover a way to build faster | `collect_and_interact`; `magn_glass` × 3 | `1835b,1836a,1837b` | `none` |
| `chp48_q3.4` | Make coffee for Ava and Meownardo | `collect_and_interact`; `coffee` × 3 | `1838c,1839b,1840c` | `none` |

## chp48_q4: Anything For Love

Configured quest `level` **1841**; assigned character **Elsie**.

Setup (localized quest text): “Mee Li wants to build Felicity a restaurant! Let's find out what Felicity wants, Chief.”

Journal outcome (localized quest text): “Mee Li was so cute trying to find out what Felicity's perfect restaurant would be like. We wanted to go home, but making Felicity's dreams come true seemed worth a little delay!”

Configured scenes: `chp48_q4` (quest_start: chp48_q4); `t1chp48_q4` (quest_task_completed: chp48_q4.1); `t2chp48_q4` (quest_task_completed: chp48_q4.2); `t3chp48_q4` (quest_task_completed: chp48_q4.3); `t4chp48_q4` (quest_task_completed: chp48_q4.4); `ftchp48_q4` (claim_button_tapped: chp48_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp48_q4.1` | Talk to Felicity about restaurants | `collect_and_interact`; `jesterstick` × 3 | `1841a,1842b,1843c` | `none` |
| `chp48_q4.2` | Search Felicity's farm | `collect_and_interact`; `magn_glass` × 2 | `1844b,1845b` | `none` |
| `chp48_q4.3` | Spy on Felicity | `collect_and_interact`; `spyglass` × 3 | `1846c,1847b,1848c` | `none` |
| `chp48_q4.4` | Draw up some blueprints | `collect_and_interact`; `blueprints` × 2 | `1849b,1850c` | `none` |
| `chp48_q4.5` | Reach Village Rank 93 | `reach_rank`; `harmony` × 93 | `none` | `none` |

