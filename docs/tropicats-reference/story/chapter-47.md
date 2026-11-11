# Chapter 47: Unhappy Landings

[Story index](../STORY.md) · [Previous](chapter-46.md) · [Next](chapter-48.md)

Campaign levels **1771–1810**; starts with `chp47_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

Wind damages the wings and the group crashes at Felicity's farm, where Olivia is hurt. A shipyard is built; Felicity and Mee Li's relationship is revealed, and the inventors propose wind-independent propulsion.

## chp47_q1: Crash Course

Configured quest `level` **1771**; assigned character **Elsie**.

Setup (localized quest text): “Olivia hurt her neck in the crash! We've got to help her, Chief.”

Journal outcome (localized quest text): “We didn't make it to Tropicat Island. The wind tore into our wings, and we fell from the sky. Fortunately, we landed on Felicity's farm safely. Well, most of us did. Olivia hurt her neck, but the Chief made sure she'd be back to normal soon.”

Configured scenes: `chp47_q1` (quest_start: chp47_q1); `t1chp47_q1` (quest_task_completed: chp47_q1.1); `t2chp47_q1` (quest_task_completed: chp47_q1.2); `t3chp47_q1` (quest_task_completed: chp47_q1.3); `t4chp47_q1` (quest_task_completed: chp47_q1.4); `ftchp47_q1` (claim_button_tapped: chp47_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp47_q1.1` | Examine Olivia's injury | `collect_and_interact`; `magn_glass` × 3 | `1771a,1772b,1773a` | `none` |
| `chp47_q1.2` | Make something to help Olivia | `collect_and_interact`; `log` × 3 | `1774b,1775c,1776b` | `none` |
| `chp47_q1.3` | Check on everyone else | `collect_and_interact`; `spyglass` × 2 | `1777b,1778c` | `none` |
| `chp47_q1.4` | Ask Mee Li for pain relief | `collect_and_interact`; `medicine` × 2 | `1779b,1780c` | `none` |

## chp47_q2: The Two Meowsters

Configured quest `level` **1781**; assigned character **Elsie**.

Setup (localized quest text): “Now that everyone's okay, it's time to find a way off the island. C'mon, Chief!”

Journal outcome (localized quest text): “Ava and Meownardo were kind of unstoppable! While the rest of us were recovering from the crash, they built a shipyard. We'd be on our way to Tropicat Island before long!”

Configured scenes: `chp47_q2` (quest_start: chp47_q2); `t1chp47_q2` (quest_task_completed: chp47_q2.1); `t2chp47_q2` (quest_task_completed: chp47_q2.2); `t3chp47_q2` (quest_task_completed: chp47_q2.3); `t4chp47_q2` (quest_task_completed: chp47_q2.4); `ftchp47_q2` (claim_button_tapped: chp47_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp47_q2.1` | Go over the shipyard blueprints | `collect_and_interact`; `blueprints` × 4 | `1781a,1782c,1783b,1784c` | `none` |
| `chp47_q2.2` | Chat with Bianca | `collect_and_interact`; `magn_glass` × 3 | `1785c,1786b,1787a` | `none` |
| `chp47_q2.3` | Visit Felicity | `collect_and_interact`; `chicken` × 1 | `1788c` | `none` |
| `chp47_q2.4` | Build a shipyard | `collect_and_repair`; `anchor` × 2 | `1789a,1790b` | `ch47_shipyard_main` |
| `chp47_q2.5` | Reach Village Rank 90 | `reach_rank`; `harmony` × 90 | `none` | `none` |

## chp47_q3: Felicity's Secret

Configured quest `level` **1791**; assigned character **Elsie**.

Setup (localized quest text): “Felicity is hiding something... we'd better make sure she's okay, Chief.”

Journal outcome (localized quest text): “I was overjoyed when I found out that Felicity and Mee Li were dating! I always thought they were cute together, and it was so cool to know I was right. But you know I love this stuff, Chief!”

Configured scenes: `chp47_q3` (quest_start: chp47_q3); `t1chp47_q3` (quest_task_completed: chp47_q3.1); `t2chp47_q3` (quest_task_completed: chp47_q3.2); `t3chp47_q3` (quest_task_completed: chp47_q3.3); `t4chp47_q3` (quest_task_completed: chp47_q3.4); `ftchp47_q3` (claim_button_tapped: chp47_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp47_q3.1` | Poke around Felicity's farm | `collect_and_interact`; `chicken` × 1 | `1791c` | `none` |
| `chp47_q3.2` | Share tea with Mee Li | `collect_and_repair`; `porcelain_cup` × 4 | `1792b,1793c,1794a,1795b` | `none` |
| `chp47_q3.3` | Spy on Mee Li | `collect_and_interact`; `spyglass` × 1 | `1796c` | `none` |
| `chp47_q3.4` | Gossip with Olivia | `collect_and_interact`; `tracks_1` × 4 | `1797b,1798a,1799b,1800c` | `none` |

## chp47_q4: The Dreams Of Cats

Configured quest `level` **1801**; assigned character **Elsie**.

Setup (localized quest text): “It's time to build a ship! But how are we going to do it, Chief?”

Journal outcome (localized quest text): “Something got Ava, Meownardo, and Mee Li really excited. They said they'd make a new invention that could make ships sail without wind. I didn't really understand, but I knew my friends would get us home!”

Configured scenes: `chp47_q4` (quest_start: chp47_q4); `t1chp47_q4` (quest_task_completed: chp47_q4.1); `t2chp47_q4` (quest_task_completed: chp47_q4.2); `t3chp47_q4` (quest_task_completed: chp47_q4.3); `t4chp47_q4` (quest_task_completed: chp47_q4.4); `ftchp47_q4` (claim_button_tapped: chp47_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp47_q4.1` | Review ship designs | `collect_and_repair`; `blueprints` × 2 | `1801a,1802b` | `none` |
| `chp47_q4.2` | Learn about Hong Kitty ships | `collect_and_interact`; `magn_glass` × 3 | `1803c,1804b,1805c` | `none` |
| `chp47_q4.3` | Work on a flag design | `collect_and_interact`; `fabric` × 2 | `1806b,1807c` | `none` |
| `chp47_q4.4` | Have tea together | `collect_and_interact`; `DogTea` × 3 | `1808a,1809b,1810c` | `none` |
| `chp47_q4.5` | Reach Village Rank 91 | `reach_rank`; `harmony` × 91 | `none` | `none` |

