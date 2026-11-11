# Chapter 2

[Story index](../STORY.md) · [Previous](chapter-01.md) · [Next](chapter-03.md)

Configured chapter start: campaign level **6**; starts with `chp2_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Elsie's hut is repaired and her brother's crab recovered. Ava then reveals that the totem was deliberately cut down, changing the restoration into an investigation.

## chp2_q1: Home Is Where The Hut Is

Configured quest `level` **6**; assigned character **Elsie**.

Setup (localized quest text): “My hut didn’t survive the quake. Let’s fix it up and find my brother’s missing pet crab.”

Journal outcome (localized quest text): “{userName} repaired my hut! But Ava, our builder, made a shocking discovery: the Great Totem didn't fall... it was CUT DOWN! Who in the tribe would want to cause an earthquake?”

Configured scenes: `chp2_q1` (quest_start: chp2_q1); `t1chp2_q1` (tutorial: chp2_q1.1); `t2chp2_q1` (quest_task_completed: chp2_q1.2); `ftchp2_q1` (claim_button_tapped: chp2_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp2_q1.1` | Repair Elsie and Kip's hut | `collect_and_repair`; `log` × 4 | `6a,7a,8a,9a` | `ch2_elsie_hut` |
| `chp2_q1.2` | Bring Mr. Crabby home | `collect_and_repair`; `crab` × 1 | `10a` | `ch2_crab` |

