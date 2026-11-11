# Chapter 43

[Story index](../STORY.md) · [Previous](chapter-42.md) · [Next](chapter-44.md)

Configured chapter start: campaign level **1611**; starts with `chp43_q1`. Task gates below are level/tier tokens, not guaranteed play order.

Elsie's mother receives the antidote, but a storm destroys Blacktail's ship. The group meets inventor Meownardo, who paints Elsie; Ava's attraction to him becomes awkward when she learns he is gay.

## chp43_q1: The Gathering Storm

Configured quest `level` **1611**; assigned character **Elsie**.

Setup (localized quest text): “There's a storm brewing overhead. We'd better get packed up and ready to head back to Tropicat Island, Chief!”

Journal outcome (localized quest text): “We gave my mother the potion to cure her amnesia, and started to get ready to set sail for Tropicat Island. I was sure everything was going to get back to normal, but those storm clouds up above looked nasty!”

Configured scenes: `chp43_q1` (quest_start: chp43_q1); `t1chp43_q1` (quest_task_completed: chp43_q1.1); `t2chp43_q1` (quest_task_completed: chp43_q1.2); `t3chp43_q1` (quest_task_completed: chp43_q1.3); `t4chp43_q1` (quest_task_completed: chp43_q1.4); `ftchp43_q1` (claim_button_tapped: chp43_q1).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp43_q1.1` | Gather everyone's belongings | `collect_and_interact`; `suitcase` × 1 | `1611a` | `none` |
| `chp43_q1.2` | Acquire leave authorization | `collect_and_interact`; `fancyscroll` × 3 | `1612c,1613b,1614c` | `none` |
| `chp43_q1.3` | Secure the rigging | `collect_and_interact`; `tracks_1` × 3 | `1615a,1616c,1617b` | `none` |
| `chp43_q1.4` | Plot a course | `collect_and_interact`; `map` × 3 | `1618c,1619a,1620b` | `none` |

## chp43_q2: Oh Ship!

Configured quest `level` **1621**; assigned character **Elsie**.

Setup (localized quest text): “Blacktail's ship sunk! We've got to find Bianca's friend Meownardo. He can help us off the island!”

Journal outcome (localized quest text): “Poor Blacktail lost his ship in the storm. It looked like we weren't going anywhere, but then we met Meownardo da Vinci. My mom said that if anyone could help us, he could!”

Configured scenes: `chp43_q2` (quest_start: chp43_q2); `t1chp43_q2` (quest_task_completed: chp43_q2.1); `t2chp43_q2` (quest_task_completed: chp43_q2.2); `t3chp43_q2` (quest_task_completed: chp43_q2.3); `t4chp43_q2` (quest_task_completed: chp43_q2.4); `ftchp43_q2` (claim_button_tapped: chp43_q2).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp43_q2.1` | Attend a wake for Blacktail's ship | `collect_and_interact`; `scroll` × 3 | `1621c,1622a,1623b` | `none` |
| `chp43_q2.2` | Survey the harbor damage | `collect_and_interact`; `herb` × 2 | `1624c,1625b` | `none` |
| `chp43_q2.3` | Read the latest newspaper | `collect_and_interact`; `newspaper` × 2 | `1626c,1627b` | `none` |
| `chp43_q2.4` | Track down Meownardo | `collect_and_interact`; `tracks_2` × 3 | `1628c,1629b,1630a` | `none` |
| `chp43_q2.5` | Reach Village Rank 82 | `reach_rank`; `harmony` × 82 | `none` | `none` |

## chp43_q3: Renaissance Cat

Configured quest `level` **1631**; assigned character **Elsie**.

Setup (localized quest text): “Meownardo is willing to help us, but we've got to help him satisfy his patron first. We've got to get his studio running!”

Journal outcome (localized quest text): “Ava helped get Meownardo's studio up and running, and he decided what painting would make his patron happy. You'd never believe his subject: me! I was going to be the subject of a painting!”

Configured scenes: `chp43_q3` (quest_start: chp43_q3); `t1chp43_q3` (quest_task_completed: chp43_q3.1); `t2chp43_q3` (quest_task_completed: chp43_q3.2); `t3chp43_q3` (quest_task_completed: chp43_q3.3); `t4chp43_q3` (quest_task_completed: chp43_q3.4); `ftchp43_q3` (claim_button_tapped: chp43_q3).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp43_q3.1` | Build Meownardo's studio | `collect_and_repair`; `log` × 2 | `1631b,1632a` | `ch43_meownardo_lab` |
| `chp43_q3.2` | Brainstorm painting ideas | `collect_and_interact`; `chalkboard` × 3 | `1633c,1634b,1635c` | `none` |
| `chp43_q3.3` | Chat with Ava | `collect_and_interact`; `magn_glass` × 3 | `1636a,1637b,1638c` | `none` |
| `chp43_q3.4` | Look at Meownardo's inventions | `collect_and_interact`; `jesterstick` × 2 | `1639b,1640b` | `none` |

## chp43_q4: Ava's Wish

Configured quest `level` **1641**; assigned character **Elsie**.

Setup (localized quest text): “Ava has a little crush on Meownardo. Surely you can help her catch his attention, Chief!”

Journal outcome (localized quest text): “Ava had a pretty big crush on Meownardo. I mean, I get it. He's pretty cute. But poor Ava... she had no idea that Meownardo was gay. Both Ava and Meownardo were feeling pretty awkward about the whole thing.”

Configured scenes: `chp43_q4` (quest_start: chp43_q4); `t1chp43_q4` (quest_task_completed: chp43_q4.1); `t2chp43_q4` (quest_task_completed: chp43_q4.2); `t3chp43_q4` (quest_task_completed: chp43_q4.3); `t4chp43_q4` (quest_task_completed: chp43_q4.4); `ftchp43_q4` (claim_button_tapped: chp43_q4).

| Task | Localized action | Type; item × count | Level/tier tokens | Encoded target |
| --- | --- | --- | --- | --- |
| `chp43_q4.1` | Make blueprints for Meownardo | `collect_and_interact`; `blueprints` × 2 | `1641b,1642c` | `none` |
| `chp43_q4.2` | Interrogate Meownardo | `collect_and_repair`; `lantern` × 3 | `1643a,1644c,1645b` | `none` |
| `chp43_q4.3` | Brew some coffee | `collect_and_interact`; `porcelain_cup` × 2 | `1646c,1647b` | `none` |
| `chp43_q4.4` | Plan studio improvements | `collect_and_interact`; `bouquet` × 3 | `1648c,1649b,1650b` | `none` |
| `chp43_q4.5` | Reach Village Rank 83 | `reach_rank`; `harmony` × 83 | `none` | `none` |

