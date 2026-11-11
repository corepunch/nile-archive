# Chapter 1: Totem Troubles

[Story index](../STORY.md) · [Next](chapter-02.md)

Campaign levels **1–5**; starts with `chp1_q1`. The range ends before the next configured chapter, or at the final referenced level for the last chapter. Task gates below are level/tier tokens, not guaranteed play order.

The Chief clears the village and restores the fallen Great Totem, returning its protective magic after the earthquake.

## chp1_q1: The Great Totem

Configured quest `level` **1**; assigned character **Elsie**.

Setup (localized quest text): “The Great Totem has fallen! Let's repair it and restore its protective magic before there are more earthquakes.”

Journal outcome (localized quest text): “For many moons, The Great Totem quelled earthquakes. But last night it fell... and Tropicat Village fell with it! Today, the totem was restored by {userName}, our Big Chief.”

Configured scenes: `t1chp1_q1` (tutorial: chp1_q1.1); `t2chp1_q1` (tutorial: chp1_q1.2); `t3chp1_q1` (quest_task_completed: chp1_q1.3).

Additional scene IDs name this quest but use another or no trigger value (association inferred from ID): `chp1_q1` (unspecified: unspecified); `crabchp1_q1` (tutorial: tutorial).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp1_q1.1` | Clear the rubble from the beach | `collect_and_repair`; `shovel` × 1 | `1a` | `ch1_rubble` |
| `chp1_q1.2` | Restore the totem square | `collect_and_repair`; `bamboo` × 1 | `2a` | `ch1_totem_place` |
| `chp1_q1.3` | Repair the Great Totem | `collect_and_repair`; `log` × 3 | `3a,4a,5a` | `ch1_totem` |

