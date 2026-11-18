# Homescapes: moves and goals for levels 1–100

These figures come from the decoded level files of the extracted Homescapes
build (Windows 9.2.601). Each file's `movesLimitLocal` is the move budget, and its
`<Targets>` are the goals. The source is
`reference/homescapes-analysis/decoded/match3levels/Match3/Levels/base/st/st0001.xml`
to `st0100.xml`, which is not tracked in git.

**The level order is assumed.** Level N here is file `stNNNN`. The file that
sets the campaign order (`Match3LevelSelector.xml`) is still encrypted, so
the live game's level N may use another board, and A/B balance packs can
change the move counts.

## Goal names

- **Gem colours:** chip IDs 0–5 are red, yellow, green, blue, pink and light
  blue. The names come from the goal icons, and red and blue are confirmed by
  the prefab names.
- **Carpet cells:** a `CELL_JELLY` goal. Carpet spreads across matches made on
  carpet. The first figure is the goal's `max`, and "pre-laid" is its
  `current`, which equals the carpet already on the board.
- **Cherries (in honey):** `COLLECT_PIGGY`.
- **Donuts brought down:** `CARRY`.
- **Boxes:** `BOX`.
- **Cookies:** `TRASH`.
- **Apples (platter):** `TARGET_GENERATOR`.
- **Chocolate:** `CHOCOLATE`.

## Move budgets

| Levels | Average | Min | Max |
|---|---|---|---|
| 1–20 | 19.9 | 10 | 33 |
| 21–40 | 20.1 | 13 | 36 |
| 41–60 | 18.2 | 12 | 25 |
| 61–80 | 17.5 | 10 | 25 |
| 81–100 | 16.7 | 12 | 24 |
| 1–100 | 18.5 | 10 | 36 |

## Levels

| Level | Moves | Goal |
|---|---|---|
| 1 | 26 | 12 yellow |
| 2 | 27 | 16 green, 16 blue |
| 3 | 20 | 20 yellow, 20 green |
| 4 | 30 | 25 pink |
| 5 | 25 | 40 green, 30 blue |
| 6 | 25 | 56 carpet cells (6 pre-laid) |
| 7 | 14 | 73 carpet cells (17 pre-laid) |
| 8 | 21 | 68 carpet cells (8 pre-laid) |
| 9 | 33 | 69 carpet cells (4 pre-laid) |
| 10 | 14 | 30 yellow, 30 blue |
| 11 | 17 | 67 carpet cells (9 pre-laid), 60 yellow |
| 12 | 10 | 19 cherries (in honey) |
| 13 | 14 | 26 cherries (in honey) |
| 14 | 25 | 56 carpet cells (14 pre-laid), 14 cherries (in honey) |
| 15 | 17 | 74 carpet cells (16 pre-laid) |
| 16 | 13 | 72 carpet cells (2 pre-laid), 25 blue |
| 17 | 17 | 18 cherries (in honey) |
| 18 | 12 | 3 donuts brought down |
| 19 | 25 | 10 cherries (in honey) |
| 20 | 14 | 1 donut brought down |
| 21 | 18 | 49 carpet cells (7 pre-laid), 32 yellow |
| 22 | 26 | 72 carpet cells (20 pre-laid), 30 boxes |
| 23 | 13 | 6 donuts brought down, 52 boxes |
| 24 | 25 | 3 donuts brought down, 37 boxes |
| 25 | 15 | 84 carpet cells (20 pre-laid) |
| 26 | 13 | 26 cherries (in honey), 55 yellow |
| 27 | 33 | 75 carpet cells (25 pre-laid), 3 donuts brought down, 30 boxes |
| 28 | 18 | 80 carpet cells (42 pre-laid), 4 donuts brought down, 26 boxes |
| 29 | 25 | 71 carpet cells (18 pre-laid), 37 boxes |
| 30 | 15 | 75 carpet cells (24 pre-laid), 28 cherries (in honey) |
| 31 | 16 | 3 donuts brought down, 43 cookies |
| 32 | 16 | 42 cookies, 12 boxes |
| 33 | 15 | 2 donuts brought down, 40 green, 6 boxes |
| 34 | 25 | 38 cookies, 31 boxes |
| 35 | 20 | 26 cherries (in honey), 26 cookies |
| 36 | 36 | 75 carpet cells (7 pre-laid), 25 cookies |
| 37 | 18 | 81 carpet cells (38 pre-laid), 3 donuts brought down, 24 boxes |
| 38 | 16 | 17 cherries (in honey) |
| 39 | 21 | 18 cookies, 23 boxes |
| 40 | 17 | 42 cookies, 66 boxes |
| 41 | 12 | 4 donuts brought down |
| 42 | 25 | 2 donuts brought down, 33 boxes |
| 43 | 18 | 69 carpet cells (5 pre-laid), 17 cookies, 24 boxes |
| 44 | 18 | 13 cherries (in honey), 60 yellow |
| 45 | 25 | 22 cherries (in honey) |
| 46 | 18 | 141 carpet cells (46 pre-laid), 27 boxes |
| 47 | 18 | 85 carpet cells (29 pre-laid), 29 cookies |
| 48 | 12 | 4 donuts brought down, 41 cookies |
| 49 | 17 | 66 carpet cells (23 pre-laid), 14 cherries (in honey), 32 boxes |
| 50 | 25 | 2 donuts brought down, 14 cherries (in honey) |
| 51 | 16 | 32 apples (platter) |
| 52 | 16 | 83 carpet cells (40 pre-laid), 21 cookies, 32 apples (platter) |
| 53 | 18 | 84 carpet cells (13 pre-laid), 33 cookies |
| 54 | 24 | 17 cherries (in honey), 16 apples (platter) |
| 55 | 18 | 27 boxes, 32 apples (platter) |
| 56 | 17 | 91 carpet cells (43 pre-laid), 4 donuts brought down, 18 boxes |
| 57 | 18 | 93 carpet cells (44 pre-laid), 14 cherries (in honey) |
| 58 | 15 | 3 donuts brought down, 33 cherries (in honey) |
| 59 | 18 | 14 cherries (in honey), 16 apples (platter) |
| 60 | 17 | 70 carpet cells (22 pre-laid), 12 boxes, 16 apples (platter) |
| 61 | 16 | 4 donuts brought down |
| 62 | 18 | 4 donuts brought down, 28 boxes |
| 63 | 17 | 77 carpet cells (15 pre-laid), 65 blue, 26 boxes |
| 64 | 18 | 74 carpet cells (34 pre-laid), 23 boxes, 32 apples (platter) |
| 65 | 18 | 88 carpet cells (22 pre-laid), 55 cookies |
| 66 | 18 | 21 cherries (in honey), 40 blue |
| 67 | 24 | 38 cherries (in honey) |
| 68 | 17 | 80 carpet cells (14 pre-laid) |
| 69 | 18 | 60 carpet cells (14 pre-laid), 14 boxes, 40 apples (platter) |
| 70 | 10 | 60 green, 16 boxes, 24 apples (platter) |
| 71 | 15 | 70 red |
| 72 | 16 | 3 donuts brought down, 31 boxes |
| 73 | 18 | 73 carpet cells (18 pre-laid), 40 blue, 29 cookies |
| 74 | 15 | 69 carpet cells (16 pre-laid), 35 green, 33 cookies |
| 75 | 17 | 15 cherries (in honey), 18 cookies, 16 apples (platter) |
| 76 | 18 | 19 cherries (in honey) |
| 77 | 17 | 3 donuts brought down, 15 cherries (in honey) |
| 78 | 25 | 150 carpet cells (48 pre-laid), 32 cookies |
| 79 | 17 | 3 donuts brought down, 34 boxes |
| 80 | 18 | 87 carpet cells (1 pre-laid) |
| 81 | 18 | 92 carpet cells (48 pre-laid), 20 cherries (in honey) |
| 82 | 24 | 31 cherries (in honey) |
| 83 | 14 | 20 cherries (in honey), 45 green |
| 84 | 16 | 18 cookies |
| 85 | 18 | 5 donuts brought down, 45 boxes |
| 86 | 17 | 5 donuts brought down, 31 boxes |
| 87 | 17 | 89 carpet cells (1 pre-laid), 60 blue, 65 boxes |
| 88 | 20 | 71 carpet cells (16 pre-laid), 4 donuts brought down |
| 89 | 15 | 14 cherries (in honey) |
| 90 | 18 | 8 cherries (in honey), 20 cookies |
| 91 | 17 | 26 chocolate, 19 boxes |
| 92 | 12 | 3 donuts brought down, 10 chocolate |
| 93 | 18 | 5 donuts brought down, 18 boxes |
| 94 | 18 | 83 carpet cells (12 pre-laid), 60 red |
| 95 | 17 | 90 carpet cells (20 pre-laid), 23 chocolate |
| 96 | 12 | 32 cherries (in honey) |
| 97 | 14 | 41 chocolate |
| 98 | 17 | 78 carpet cells (21 pre-laid), 21 cookies, 24 boxes |
| 99 | 14 | 82 carpet cells (8 pre-laid), 8 donuts brought down, 37 chocolate |
| 100 | 18 | 6 donuts brought down, 27 chocolate, 21 boxes |
