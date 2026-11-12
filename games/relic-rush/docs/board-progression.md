# Relic Rush board progression

Thirty original expedition boards use three cycles: teach excavation and locks (1–10), revisit them as interrupted terraces (11–20), and combine them in the approach to the temple (21–30). Levels 18 and 28 deliberately reduce the workload. Names, story order and building milestones are unchanged. These are design intentions, not evidence of human difficulty or guaranteed move sequences.

The engine generates piece colours from a seed. Soil and lock positions are deterministic: the active cells are sorted by the level’s terrain priority (usually a seam; levels 20 and 26 concentrate it toward the middle); sand occupies the first N, chains sample ranks 2, 5, 8 and so on, and ice scans from rank 5, skipping chains and the outer ring. Every third placed ice cell begins at strength two when that level enables layered ice. A locked sand cell needs a hit to remove the lock before a later hit can excavate it. All locks and the configured amount of sand must be cleared.

Coordinates below are axial `(q,r)`, as enumerated in `engine/match3.lua`; the complete starting sand, chain and ice positions are listed so the intended choices can be checked against the actual placements. Ice order also identifies which cells receive two layers: the first, fourth, seventh, and so on when layered ice is enabled. Board holes stop ordinary match runs but rays pass through them. Exposed column tops refill, pieces can trickle, and blocked-parent pockets can spawn; these shapes do not promise a starved or sealed supply.

## 1. First Light

Use the generous central field to learn straight matches; the missing left corner leaves the long axes readable.

- Active cells: 58; seam: `1q + 0r = 0`. Moves: 24.
- Sand: —.
- Chains: —.
- Ice in placement order: —.

## 2. The Jade Crescent

Build a four-piece ray beside the first sand strip; its offset keeps much of the opposite side open for setup.

- Active cells: 55; seam: `0q + 1r = -1`. Moves: 29.
- Sand: (-2,-1) (-1,-1) (0,-1) (1,-1) (2,-1) (3,-1) (4,-1).
- Chains: —.
- Ice in placement order: —.

## 3. Sunstone Spiral

Excavate across a diagonal cut: matches stop at the missing cells, but a ray can strike beyond them.

- Active cells: 52; seam: `1q + 1r = 0`. Moves: 32.
- Sand: (1,-1) (2,-2) (3,-3) (4,-4) (-4,3) (-3,4) (-2,3) (-1,2) (0,-1) (0,1) (1,-2) (1,0).
- Chains: —.
- Ice in placement order: —.

## 4. The Vine Constellation

Free chained relics along the near-side sand seam; unlocked cells can then participate in swaps.

- Active cells: 55; seam: `1q + 0r = -1`. Moves: 35.
- Sand: (-1,-3) (-1,-2) (-1,-1) (-1,0) (-1,1) (-1,2) (-1,3) (-1,4) (0,-4) (0,-3).
- Chains: (-1,-2) (-1,1) (-1,4) (0,-2).
- Ice in placement order: —.

## 5. Three Paths Meet

Pick a line on either side of the cut to make rays that can cross it and reach the sand.

- Active cells: 50; seam: `0q + 1r = 0`. Moves: 35.
- Sand: (-4,0) (-3,0) (1,0) (2,0) (3,0) (4,0) (-4,1) (-3,-1) (-3,1) (-2,-1) (-1,-1) (0,-1) (0,1).
- Chains: (-3,0) (3,0) (-3,-1) (-1,-1).
- Ice in placement order: —.

## 6. Winter Lotus

Work near the offset frozen seam while retaining the wider opposite side for ordinary matches.

- Active cells: 55; seam: `1q + 1r = 1`. Moves: 37.
- Sand: (3,-2) (2,-1) (1,0) (0,1) (-2,3) (-3,4) (4,-2) (3,-3) (3,-1) (2,-2) (2,0) (1,-1) (1,1).
- Chains: —.
- Ice in placement order: (-2,3) (3,-3) (3,-1) (2,-2) (2,0).

## 7. The Ember Ring

Look for flame matches beside the ice mixed into the sand seam; the centre hole interrupts ordinary lines.

- Active cells: 54; seam: `1q + 0r = 1`. Moves: 40.
- Sand: (1,3) (1,2) (1,1) (1,0) (1,-1) (1,-2) (1,-3) (1,-4) (0,4) (0,3) (0,2) (2,2) (0,1) (2,1) (2,0).
- Chains: (1,2) (1,-1) (1,-4) (0,2).
- Ice in placement order: (1,-2) (1,-3) (0,3) (0,1) (2,1).

## 8. Prism Hollow

Use the wide courts to set up a five-piece line; the central gap separates ordinary runs, not ray effects.

- Active cells: 49; seam: `0q + 1r = -1`. Moves: 40.
- Sand: (4,-1) (3,-1) (2,-1) (1,-1) (0,-1) (-1,-1) (-2,-1) (-3,-1) (4,-2) (4,0) (3,-2) (3,0) (2,-2) (2,0) (1,-2) (1,0) (0,-2).
- Chains: (3,-1) (0,-1) (-3,-1) (3,-2).
- Ice in placement order: (-1,-1) (-2,-1) (3,0) (2,-2) (2,0) (1,-2).

## 9. The Sixfold Seal

Attack either edge of the central band and use rays across the two cuts to reach the rest.

- Active cells: 51; seam: `1q + 1r = 0`. Moves: 43.
- Sand: (-4,4) (-3,3) (-2,2) (-1,1) (0,0) (1,-1) (2,-2) (3,-3) (4,-4) (-4,3) (-3,4) (-2,3) (-1,0) (-1,2) (0,-1) (0,1) (1,-2) (1,0) (2,-3).
- Chains: (-3,3) (0,0) (3,-3) (-3,4) (-1,2).
- Ice in placement order: (1,-1) (2,-2) (-2,3) (-1,0) (0,-1) (0,1).

## 10. Heart of the Hexagon

Choose a side of the central opening from which to clear the surrounding sand and locks.

- Active cells: 54; seam: `1q + 0r = 0`. Moves: 46.
- Sand: (0,3) (0,2) (0,1) (0,-1) (0,-2) (0,-3) (-1,4) (-1,3) (1,3) (-1,2) (1,2) (-1,1) (1,1) (-1,0) (1,0) (-1,-1) (1,-1) (-1,-2) (1,-2) (-1,-3) (1,-3) (1,-4).
- Chains: (0,2) (0,-2) (-1,3) (1,2) (-1,0) (1,-1).
- Ice in placement order: (0,-3) (-1,2) (-1,1) (1,1) (1,0) (-1,-1).

## 11. The Long Terrace

Sweep along the offset terrace; no locks interrupt this reset, but sand extends beyond one match.

- Active cells: 55; seam: `0q + 1r = 1`. Moves: 33.
- Sand: (-4,1) (-3,1) (-2,1) (-1,1) (0,1) (1,1) (2,1) (3,1) (-4,2) (-3,0) (-3,2) (-2,0) (-2,2) (-1,0).
- Chains: —.
- Ice in placement order: —.

## 12. Twelve Crates

Free the chain positions embedded in the diagonal sand strip before cleaning its ends.

- Active cells: 55; seam: `1q + 1r = -1`. Moves: 36.
- Sand: (3,-4) (2,-3) (1,-2) (0,-1) (-1,0) (-2,1) (-3,2) (-4,3) (3,-3) (2,-4) (2,-2) (1,-3) (1,-1) (0,-2) (0,0).
- Chains: (2,-3) (-1,0) (-4,3) (2,-2) (0,-2).
- Ice in placement order: —.

## 13. Names in the Stone

Build a ray along the central stone band; gaps beside it interrupt setup lines, while rays cross them.

- Active cells: 48; seam: `1q + 0r = 0`. Moves: 37.
- Sand: (0,-4) (0,-3) (0,-2) (0,-1) (0,0) (0,1) (0,2) (0,3) (0,4) (1,-4) (-1,-3) (1,-3) (1,-2) (-1,0) (1,0) (1,1).
- Chains: (0,-3) (0,0) (0,3) (-1,-3) (-1,0) (-1,2).
- Ice in placement order: —.

## 14. Static

Choose which end of the broken seam offers a useful match, then clear the locks through the band.

- Active cells: 51; seam: `0q + 1r = 1`. Moves: 38.
- Sand: (3,1) (2,1) (1,1) (0,1) (-1,1) (4,0) (2,2) (1,0) (1,2) (0,0) (0,2) (-1,0) (-1,2) (-2,2) (-3,2) (-4,0) (-4,2).
- Chains: (2,1) (-1,1) (1,0) (0,2) (-2,2) (-4,2) (0,-1).
- Ice in placement order: —.

## 15. The Frost Line

Clear the sand and mixed locks along the diagonal while working around the stepped edge.

- Active cells: 55; seam: `1q + 1r = 0`. Moves: 39.
- Sand: (-4,4) (-3,3) (-2,2) (-1,1) (0,0) (1,-1) (2,-2) (3,-3) (4,-4) (-4,3) (-3,2) (-3,4) (-2,1) (-2,3) (-1,0) (-1,2) (0,-1) (0,1).
- Chains: (-3,3) (0,0) (3,-3) (-3,2).
- Ice in placement order: (1,-1) (2,-2) (-2,1) (-2,3) (-1,0) (-1,2).

## 16. Supper for Twelve

Use adjacent flame matches on the offset ice while clearing chains in the same sand band.

- Active cells: 55; seam: `1q + 0r = -1`. Moves: 40.
- Sand: (-1,4) (-1,3) (-1,2) (-1,1) (-1,-1) (-1,-2) (-1,-3) (-2,4) (0,4) (-2,3) (0,3) (-2,2) (0,2) (-2,1) (0,1) (-2,0) (0,0) (-2,-1).
- Chains: (-1,3) (-1,-1) (-2,4) (0,3).
- Ice in placement order: (-1,-2) (-2,3) (-2,2) (0,2) (-2,1) (0,1) (-2,0).

## 17. The Torn Log

Choose a side of the notch for repeated hits on double ice; locked sand needs another hit after unlocking.

- Active cells: 49; seam: `0q + 1r = -1`. Moves: 42.
- Sand: (-3,-1) (-2,-1) (-1,-1) (0,-1) (1,-1) (2,-1) (3,-1) (4,-1) (-2,-2) (-1,-2) (0,-2) (0,0) (1,-2) (1,0) (2,-2) (2,0) (3,-2) (3,0) (4,0).
- Chains: (-2,-1) (1,-1) (4,-1) (0,-2) (1,0).
- Ice in placement order: (2,-1) (3,-1) (-1,-2) (0,0) (1,-2) (2,-2) (2,0).

## 18. Lantern Steps

Use the open terrace to finish a lighter sand and lock workload before the final approach.

- Active cells: 57; seam: `1q + 1r = 1`. Moves: 40.
- Sand: (4,-3) (3,-2) (2,-1) (1,0) (0,1) (-1,2) (-2,3) (-3,4) (4,-2) (3,-3) (3,-1) (2,-2).
- Chains: (3,-2) (0,1).
- Ice in placement order: (-1,2) (-2,3) (3,-3) (3,-1).

## 19. Under the Vines

Clear locks in the offset vertical sand band; the diagonal edge cut shortens some setup lines.

- Active cells: 50; seam: `1q + 0r = 1`. Moves: 45.
- Sand: (1,-4) (1,-3) (1,-2) (1,-1) (1,0) (0,-4) (2,-4) (0,-3) (2,-3) (0,-2) (2,-2) (0,-1) (2,-1) (0,0) (2,0) (0,1) (0,2) (3,-4) (-1,-3) (3,-3).
- Chains: (1,-3) (1,0) (0,-3) (2,-2) (0,0) (0,2).
- Ice in placement order: (2,-3) (0,-2) (0,-1) (2,-1) (2,0) (0,1) (3,-3) (-1,-2).

## 20. The Archivist's Key

Work around the central opening and clear the concentrated mixed coverings on both sides.

- Active cells: 49; terrain: `0q + 1r = 0; centre-weighted`. Moves: 46.
- Sand: (0,-1) (0,1) (1,0) (0,-2) (0,2) (-1,1) (1,-1) (1,1) (0,-3) (0,3) (2,0) (-1,-2) (-1,2) (1,-2) (1,2) (0,-4) (0,4) (2,-1) (-1,-3) (-1,3) (1,-3) (1,3).
- Chains: (0,1) (0,2) (1,1) (2,0) (1,-2) (0,4) (-1,3).
- Ice in placement order: (-1,1) (1,-1) (0,-3) (0,3) (-1,-2) (-1,2) (1,2) (2,-1) (1,-3).

## 21. Tomas's Trail

Follow the diagonal sand seam around the edge cut; this restart has no locks.

- Active cells: 55; seam: `1q + 1r = -1`. Moves: 35.
- Sand: (-4,3) (-3,2) (-2,1) (-1,0) (0,-1) (1,-2) (2,-3) (3,-4) (-4,2) (-4,4) (-3,1) (-3,3) (-2,0) (-2,2) (-1,-1).
- Chains: —.
- Ice in placement order: —.

## 22. The Frozen Stair

Thaw from the side of the stepped diagonal cut with the best flame match; two-layer ice takes repeated hits.

- Active cells: 49; seam: `1q + 0r = -1`. Moves: 40.
- Sand: (-1,-3) (-1,-2) (-1,-1) (-1,3) (-1,4) (0,-4) (0,-3) (-2,-2) (0,-2) (-2,-1) (0,-1) (-2,0) (0,0) (0,1) (0,2) (0,3).
- Chains: (-1,-2) (-1,4).
- Ice in placement order: (0,-3) (0,-2) (-2,-1) (0,-1) (-2,0) (0,0) (0,1) (0,2).

## 23. The Star Road

Use the long open side to make a prism and choose a useful colour while cleaning the offset sand band.

- Active cells: 54; seam: `0q + 1r = 1`. Moves: 40.
- Sand: (-4,1) (-3,1) (-2,1) (-1,1) (0,1) (1,1) (2,1) (3,1) (-4,2) (-3,0) (-3,2) (-2,0) (-2,2) (-1,0) (-1,2) (0,2).
- Chains: (-3,1) (0,1) (3,1) (-3,2) (-1,0).
- Ice in placement order: (1,1) (2,1) (-3,0) (-2,0) (-2,2).

## 24. Noon Shadow

Work across the upper cut to reach the diagonal sand; ice and chains can cover the same excavation area.

- Active cells: 51; seam: `1q + 1r = 1`. Moves: 41.
- Sand: (4,-3) (2,-1) (1,0) (0,1) (-2,3) (-3,4) (4,-4) (3,-3) (3,-1) (2,-2) (2,0) (1,-1) (1,1) (0,0) (0,2) (-1,3) (-2,4) (-3,3) (-4,4) (4,-1).
- Chains: (2,-1) (-2,3) (3,-3) (2,0).
- Ice in placement order: (3,-1) (2,-2) (1,-1) (1,1) (0,0).

## 25. Smoke on the Water

Choose which notched side to work from while resolving the central band of mixed locks.

- Active cells: 49; seam: `1q + 0r = 0`. Moves: 38.
- Sand: (0,4) (0,3) (0,2) (0,0) (0,-1) (0,-2) (0,-3) (0,-4) (-1,4) (-1,3) (1,3) (-1,2) (1,2) (-1,1) (1,1) (-1,0) (1,0) (1,-1).
- Chains: (0,3) (0,-1) (0,-4) (1,3) (-1,1) (1,0).
- Ice in placement order: (0,-2) (0,-3) (-1,3) (-1,2) (1,2) (1,1).

## 26. The Jade Deep

Clear the concentrated offset frozen ground; the central hole stops ordinary matches, while rays still pass across it.

- Active cells: 49; terrain: `0q + 1r = -1; centre-weighted`. Moves: 43.
- Sand: (0,-1) (0,-2) (-1,-1) (0,-3) (0,1) (-1,-2) (-1,0) (1,-2) (-2,-1) (0,-4) (0,2) (-1,-3) (-1,1) (1,-3) (1,1) (-2,-2) (-2,0).
- Chains: (0,-2) (0,1) (1,-2) (0,2).
- Ice in placement order: (-1,-2) (-1,0) (-2,-1) (-1,1) (1,-3) (1,1) (-2,0).

## 27. Six Sun Gates

Work around the clipped corners and inner notch to clear the diagonal band of locks and sand.

- Active cells: 50; seam: `1q + 1r = 0`. Moves: 45.
- Sand: (-3,3) (0,0) (1,-1) (2,-2) (3,-3) (-4,3) (-3,2) (-3,4) (-2,3) (0,-1) (0,1) (1,-2) (1,0) (2,-3) (2,-1) (3,-4) (3,-2) (4,-3) (-4,2) (-3,1).
- Chains: (0,0) (3,-3) (-3,4) (0,1) (2,-3) (3,-2) (-3,1).
- Ice in placement order: (-3,2) (-2,3) (0,-1) (1,-2) (1,0) (2,-1) (-2,0) (-1,-1).

## 28. The Last Terrace

Use the broad field and reduced workload to prepare for the last two boards.

- Active cells: 57; seam: `1q + 0r = 1`. Moves: 42.
- Sand: (1,3) (1,2) (1,1) (1,0) (1,-1) (1,-2) (1,-3) (1,-4) (0,4) (0,3) (0,2) (2,2) (0,1).
- Chains: (1,2) (1,-1).
- Ice in placement order: (1,-2) (1,-3) (0,3) (0,2).

## 29. The Silent Temple

Open a useful end of the central strip, then clear the mixed locks and soil across the interrupted floor.

- Active cells: 49; seam: `0q + 1r = 0`. Moves: 47.
- Sand: (-1,0) (1,0) (2,0) (3,0) (4,0) (-4,1) (-3,1) (-2,1) (-1,1) (0,-1) (0,1) (1,-1) (1,1) (2,-1) (2,1) (3,-1) (3,1) (4,-1) (-4,2) (-3,2) (-2,2) (-1,2) (0,-2).
- Chains: (1,0) (4,0) (-2,1) (0,1) (2,-1) (3,1) (-3,2) (0,-2).
- Ice in placement order: (-3,1) (-1,1) (0,-1) (1,-1) (1,1) (2,1) (3,-1) (-2,2) (-1,2) (0,2).

## 30. The Song Returns

Choose either side of the central opening, use long rays across the holes and finish the full mixed-lock band.

- Active cells: 49; seam: `1q + 1r = 0`. Moves: 49.
- Sand: (4,-4) (3,-3) (2,-2) (1,-1) (-2,2) (-3,3) (-4,4) (4,-3) (3,-4) (3,-2) (2,-3) (1,-2) (1,0) (0,-1) (0,1) (-1,2) (-2,3) (-3,2) (-3,4) (-4,3) (4,-2) (2,-4) (2,0) (1,-3).
- Chains: (3,-3) (-2,2) (4,-3) (2,-3) (0,-1) (-2,3) (-4,3) (2,0).
- Ice in placement order: (-3,3) (3,-2) (1,-2) (1,0) (0,1) (-1,2) (-3,2) (1,-3) (1,1) (0,-2).
