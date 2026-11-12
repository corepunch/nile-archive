# Homescapes lab coverage — 2026-11-12

All **6,184** local 9.2.601 level files parse. **1,005** boards initialize (previously 753; 232 before the first blocker pass). **996** played at least one legal move in the 12-turn exercise, totalling **11,717 moves**. Goals advanced on **897** boards. Nine boards start stalled. No attempted construction or hint execution failed.

Of the other 5,179 boards, 5,178 retain unsupported model/goal vocabulary. One additional board (`packs/contest/contest_179_15.xml`) has accepted model/goal IDs but an unsupported `[a]` queue token. Generator configuration gaps occur in 291 files, usually alongside other unsupported mechanics.

The corpus has 130 model IDs and 82 goal types. The lab rejects **102 model IDs and 69 goal types**. Accepted identifiers do not establish complete scripting, routing, art or original-runtime equivalence. See the [complete feature reference](FEATURES.md), [blocker implementation record](BLOCKERS.md) and [generator/tile/blind record](GENERATORS.md).

The exercise emitted **2,851 queued pieces across 99 boards** and **938 palette-controlled pieces across 20 boards**, including initial-fill emissions. These counters verify that the new code executes, not just that identifiers are accepted. 112 accepted boards contain artifact sources, 57 contain tiles and 75 contain blinds; these groups overlap.

Run `HomescapesLab --root "$PWD" --audit --exercise` to regenerate the machine report; local results are retained in `reference/homescapes-analysis/lab-audit.json`. Every entry records unsupported models/goals/configurations, initialization, turns, progress, emissions, stalled state and actual errors. `originalRuntimeVerified` remains false.

## Stalled at startup

- `base/st/st0049.xml`
- `packs/contest/contest_004_15.xml`
- `packs/contest/contest_021_13.xml`
- `packs/contest/contest_030_03.xml`
- `packs/contest/contest_047_08.xml`
- `packs/contest/contest_064_07.xml`
- `packs/contest/contest_107_03.xml`
- `packs/contest/contest_136_15.xml`
- `packs/contest/contest_139_12.xml`

## Remaining model vocabulary

Counts are files containing each identifier.

| Identifier | Files | Example |
| --- | ---: | --- |
| `ARCADE` | 20 | `packs/contest/contest_401_08.xml` |
| `ARMOR` | 84 | `packs/contest/contest_403_01.xml` |
| `BALLOON` | 85 | `packs/contest/contest_035_03.xml` |
| `BALLOON_ROPE` | 85 | `packs/contest/contest_035_03.xml` |
| `BATTERY` | 2 | `base/beta/beta001.xml` |
| `BIG_PENCIL_BOX` | 74 | `packs/contest/contest_406_08.xml` |
| `BILLIARD` | 73 | `packs/contest/contest_033_15.xml` |
| `BOOKSHELF` | 79 | `packs/contest/contest_401_09.xml` |
| `BOOMBOX` | 3 | `base/beta/beta001.xml` |
| `BOOST_APEAR_CELLS` | 194 | `base/st/st0034.xml` |
| `BOX_ST` | 346 | `base/st/st0191.xml` |
| `BRICK_WALL` | 117 | `base/beta/beta003.xml` |
| `BROOCH` | 132 | `packs/contest/contest_098_02.xml` |
| `BUCKET` | 188 | `base/View/ply-water.xml` |
| `BUCKET_WATER` | 188 | `base/View/ply-water.xml` |
| `CAKE` | 91 | `packs/contest/contest_181_14.xml` |
| `CATS_HOUSE` | 169 | `packs/contest/contest_088_04.xml` |
| `CAT_ON_RUG` | 66 | `packs/contest/contest_401_05.xml` |
| `CHAIN_BOX` | 394 | `base/beta/beta006.xml` |
| `CHEESE` | 92 | `packs/contest/contest_043_06.xml` |
| `CHESS` | 62 | `packs/contest/contest_402_03.xml` |
| `CHEST` | 45 | `packs/contest/contest_169_09.xml` |
| `CHEST_KEY` | 42 | `packs/contest/contest_169_09.xml` |
| `CHOCO_B` | 346 | `base/st/st0091.xml` |
| `CHOCO_GEN` | 61 | `packs/contest/contest_005_10.xml` |
| `CHOCO_W` | 219 | `base/st/st0476.xml` |
| `CORN_POT` | 113 | `packs/contest/contest_402_04.xml` |
| `CUPCAKES` | 66 | `packs/contest/contest_402_09.xml` |
| `CURTAIN` | 127 | `packs/contest/contest_401_03.xml` |
| `CYLINDER_HAT` | 95 | `packs/contest/contest_089_01.xml` |
| `DESSERT` | 88 | `base/beta/beta001.xml` |
| `DONUT_MAKER` | 70 | `packs/contest/contest_401_02.xml` |
| `DUCK` | 79 | `packs/contest/contest_401_02.xml` |
| `EGG` | 378 | `base/beta/beta008.xml` |
| `EGG_TOY` | 377 | `base/beta/beta008.xml` |
| `ELECTRIC_GLOBE` | 56 | `packs/contest/contest_401_04.xml` |
| `EXPLOSIVE_BARREL` | 60 | `packs/contest/contest_404_07.xml` |
| `FAN` | 131 | `packs/contest/contest_023_02.xml` |
| `FEATHER` | 100 | `packs/contest/contest_036_06.xml` |
| `FLOWER_BOX` | 129 | `packs/contest/contest_081_10.xml` |
| `FOAM` | 61 | `packs/contest/contest_402_09.xml` |
| `FRIDGE` | 228 | `packs/contest/contest_063_12.xml` |
| `GARBAGE_PLATE` | 115 | `base/beta/beta004.xml` |
| `GARBAGE_VASE` | 128 | `base/beta/beta003.xml` |
| `GONG` | 128 | `packs/contest/contest_016_01.xml` |
| `HONEY_GENERATOR` | 77 | `packs/contest/contest_035_03.xml` |
| `ICE_BOMB` | 142 | `packs/contest/contest_001_13.xml` |
| `IVY` | 89 | `packs/contest/contest_019_08.xml` |
| `IVY_PART` | 82 | `packs/contest/contest_019_08.xml` |
| `JAR` | 170 | `packs/contest/contest_019_08.xml` |
| `KEYS` | 112 | `base/beta/beta002.xml` |
| `LAMP` | 87 | `packs/contest/contest_090_15.xml` |
| `LANTERN` | 142 | `packs/contest/contest_038_06.xml` |
| `LEMONADE` | 94 | `packs/contest/contest_117_06.xml` |
| `LIGHTBULB` | 77 | `packs/contest/contest_403_05.xml` |
| `MAGIC_HAT` | 320 | `packs/contest/contest_029_09.xml` |
| `MATCHABLE_CELLS` | 140 | `base/st/st0007.xml` |
| `MEMBRANE_GEN` | 31 | `base/beta/beta007.xml` |
| `MICE_IN_CHEESE` | 63 | `packs/contest/contest_402_08.xml` |
| `MIXER` | 166 | `packs/contest/contest_074_03.xml` |
| `NEW_VACUUM` | 77 | `packs/contest/contest_402_06.xml` |
| `NOTE_GEN` | 253 | `packs/contest/contest_002_01.xml` |
| `NOT_CHEESE_APPEAR_CELLS` | 14 | `packs/contest/contest_405_09.xml` |
| `OIL` | 257 | `base/st/st0161.xml` |
| `OIL_CAN` | 214 | `packs/contest/contest_016_15.xml` |
| `ORIGAMI` | 61 | `packs/contest/contest_169_06.xml` |
| `PAINT` | 133 | `packs/contest/contest_401_03.xml` |
| `PAINT_BOTTLE` | 27 | `packs/contest/contest_401_09.xml` |
| `PAINT_TUBE` | 80 | `packs/contest/contest_058_09.xml` |
| `PARROT` | 124 | `packs/contest/contest_148_14.xml` |
| `PASSABLE_FOR_CHIP` | 266 | `base/beta/beta001.xml` |
| `PENCIL_BOX` | 159 | `packs/contest/contest_097_08.xml` |
| `PHONE` | 155 | `packs/contest/contest_061_12.xml` |
| `PHOTO_CAMERA` | 135 | `packs/contest/contest_169_04.xml` |
| `PLAID` | 100 | `packs/contest/contest_035_03.xml` |
| `PUZZLE_PACKAGE` | 245 | `packs/contest/contest_005_11.xml` |
| `PUZZLE_PICTURE` | 260 | `packs/contest/contest_005_11.xml` |
| `RESHUFF_CELLS` | 20 | `base/st/st0091.xml` |
| `ROLL_CARPET` | 133 | `packs/contest/contest_003_04.xml` |
| `RUG` | 101 | `base/beta/beta002.xml` |
| `SAFE` | 80 | `packs/contest/contest_403_08.xml` |
| `SEASHELL` | 85 | `base/beta/beta005.xml` |
| `SOAP` | 77 | `packs/contest/contest_080_06.xml` |
| `STAINED_GLASS` | 34 | `packs/contest/contest_072_09.xml` |
| `STEAM` | 178 | `packs/contest/contest_015_02.xml` |
| `STEAM_GEN` | 78 | `packs/contest/contest_137_05.xml` |
| `STONE_TAPE_MEASURE` | 138 | `packs/contest/contest_058_15.xml` |
| `SUGAR_BORDER` | 40 | `packs/contest/contest_401_08.xml` |
| `SUITCASE` | 102 | `packs/contest/contest_016_15.xml` |
| `SUITCASE_HAT_UNWANTED_CELLS` | 2 | `packs/contest/contest_144_01.xml` |
| `TABLETS` | 1 | `base/View/ply-water.xml` |
| `TAPE_MEASURE` | 216 | `base/beta/beta003.xml` |
| `TIMER` | 63 | `packs/contest/contest_074_10.xml` |
| `TIN_CAN` | 306 | `packs/contest/contest_020_06.xml` |
| `TIN_CAN_APPEAR_CELLS` | 179 | `packs/contest/contest_023_11.xml` |
| `TOY_BOX` | 169 | `packs/contest/contest_023_03.xml` |
| `VACUUM` | 86 | `packs/contest/contest_102_13.xml` |
| `VACUUM_WAYPOINT` | 163 | `packs/contest/contest_102_13.xml` |
| `WATCH` | 80 | `packs/contest/contest_170_05.xml` |
| `WEB` | 164 | `packs/contest/contest_007_04.xml` |
| `YARN_BALL` | 201 | `packs/contest/contest_070_06.xml` |
| `YARN_BASKET` | 201 | `packs/contest/contest_070_06.xml` |

## Remaining goal vocabulary

Counts are files containing each identifier.

| Identifier | Files | Example |
| --- | ---: | --- |
| `ARCADE` | 20 | `packs/contest/contest_401_08.xml` |
| `ARMOR` | 84 | `packs/contest/contest_403_01.xml` |
| `BALLOON` | 85 | `packs/contest/contest_035_03.xml` |
| `BIG_PENCIL` | 74 | `packs/contest/contest_406_08.xml` |
| `BILLIARD_BALL` | 73 | `packs/contest/contest_033_15.xml` |
| `BONUS` | 98 | `packs/contest/contest_002_08.xml` |
| `BOOKSHELF_BOOK` | 79 | `packs/contest/contest_401_09.xml` |
| `BOOMBOX` | 3 | `base/beta/beta001.xml` |
| `BRICK_WALL` | 77 | `base/beta/beta003.xml` |
| `BROOCH` | 132 | `packs/contest/contest_098_02.xml` |
| `BUCKET` | 188 | `base/View/ply-water.xml` |
| `CAKE` | 83 | `packs/contest/contest_401_03.xml` |
| `CAT` | 169 | `packs/contest/contest_088_04.xml` |
| `CAT_ON_RUG` | 66 | `packs/contest/contest_401_05.xml` |
| `CELL_FOAM` | 142 | `packs/contest/contest_401_02.xml` |
| `CELL_OIL` | 468 | `base/st/st0161.xml` |
| `CELL_PAINT` | 160 | `packs/contest/contest_401_03.xml` |
| `CHAIN_BOX` | 102 | `base/beta/beta006.xml` |
| `CHEESE` | 113 | `packs/contest/contest_043_06.xml` |
| `CHESS` | 62 | `packs/contest/contest_402_03.xml` |
| `CHOCOLATE` | 428 | `base/st/st0091.xml` |
| `CORN_FROM_POT` | 113 | `packs/contest/contest_402_04.xml` |
| `CUPCAKES` | 66 | `packs/contest/contest_402_09.xml` |
| `DESSERT` | 101 | `base/beta/beta001.xml` |
| `DONUT_MAKER` | 70 | `packs/contest/contest_401_02.xml` |
| `DUCK` | 81 | `packs/contest/contest_401_02.xml` |
| `EGG_TOY` | 387 | `base/beta/beta008.xml` |
| `EXPLOSIVE_BARREL` | 63 | `packs/contest/contest_404_07.xml` |
| `FAN` | 134 | `packs/contest/contest_023_02.xml` |
| `FEATHER` | 81 | `packs/contest/contest_169_08.xml` |
| `FLOWER` | 129 | `packs/contest/contest_081_10.xml` |
| `FRIDGE_CAN` | 228 | `packs/contest/contest_063_12.xml` |
| `GARBAGE_PLATE` | 136 | `base/beta/beta004.xml` |
| `GARBAGE_VASE` | 148 | `base/beta/beta003.xml` |
| `GOLD_BAR` | 80 | `packs/contest/contest_403_08.xml` |
| `HONEY_GENERATOR` | 57 | `packs/contest/contest_401_04.xml` |
| `JAR` | 170 | `packs/contest/contest_019_08.xml` |
| `KEYS` | 112 | `base/beta/beta002.xml` |
| `LANTERN` | 141 | `packs/contest/contest_038_06.xml` |
| `LEMONADE` | 94 | `packs/contest/contest_117_06.xml` |
| `LIGHTBULB` | 77 | `packs/contest/contest_403_05.xml` |
| `MAGIC_HAT` | 320 | `packs/contest/contest_029_09.xml` |
| `MEMBRANE_GEN` | 3 | `base/beta/beta007.xml` |
| `MICE_IN_CHEESE` | 63 | `packs/contest/contest_402_08.xml` |
| `MIXER` | 166 | `packs/contest/contest_074_03.xml` |
| `NOTE` | 253 | `packs/contest/contest_002_01.xml` |
| `OIL_CAN` | 109 | `packs/contest/contest_401_06.xml` |
| `ORIGAMI` | 61 | `packs/contest/contest_169_06.xml` |
| `PAINT_BOTTLE` | 27 | `packs/contest/contest_401_09.xml` |
| `PAINT_TUBE` | 64 | `packs/contest/contest_407_02.xml` |
| `PARROT` | 124 | `packs/contest/contest_148_14.xml` |
| `PENCIL` | 147 | `packs/contest/contest_097_08.xml` |
| `PHONE` | 136 | `packs/contest/contest_061_12.xml` |
| `PHOTO` | 135 | `packs/contest/contest_169_04.xml` |
| `RUG` | 167 | `base/beta/beta002.xml` |
| `SEASHELL` | 91 | `base/beta/beta005.xml` |
| `STEAM` | 13 | `packs/contest/contest_401_06.xml` |
| `STEAM_GEN` | 78 | `packs/contest/contest_137_05.xml` |
| `STONE_TAPE_MEASURE` | 124 | `packs/contest/contest_173_09.xml` |
| `SUGAR_BORDER` | 40 | `packs/contest/contest_401_08.xml` |
| `SUITCASE_HAT` | 102 | `packs/contest/contest_016_15.xml` |
| `SUPER_BONUS` | 42 | `packs/contest/contest_016_03.xml` |
| `TABLETS` | 1 | `base/View/ply-water.xml` |
| `TAPE_MEASURE` | 153 | `base/beta/beta003.xml` |
| `TIMER` | 63 | `packs/contest/contest_074_10.xml` |
| `TIN_CAN` | 306 | `packs/contest/contest_020_06.xml` |
| `TOY_BOX` | 175 | `packs/contest/contest_023_03.xml` |
| `WATCH` | 80 | `packs/contest/contest_170_05.xml` |
| `YARN_BALL` | 201 | `packs/contest/contest_070_06.xml` |

## Configuration sections

Cells, basic goals, chip weights and random-chip color lists are interpreted. Refill sections now have partial support documented in BLOCKERS.md. Other sections remain evidence to decode rather than implemented behavior.

| Section | Files |
| --- | ---: |
| `Battery` | 1 |
| `Bears` | 17 |
| `BornPatterns` | 743 |
| `CarryChips` | 851 |
| `Cheese` | 35 |
| `ChestKeys` | 33 |
| `ColorChipsPattern` | 321 |
| `Dessert` | 22 |
| `Ducks` | 3 |
| `EggToys` | 61 |
| `Eggs` | 59 |
| `ElectricGlobe` | 7 |
| `ExplosiveBarrel` | 6 |
| `Fans` | 74 |
| `Feather` | 7 |
| `Garbage1Chips` | 43 |
| `Garbage2Chips` | 36 |
| `HoneyGenerator` | 83 |
| `IceBombs` | 121 |
| `Lantern` | 19 |
| `OilCans` | 14 |
| `PaintTube` | 88 |
| `Phones` | 155 |
| `PuzzleSettings` | 232 |
| `Seashell` | 13 |
| `SoapChips` | 13 |
| `TemplateElements` | 3 |
| `Timer` | 63 |
| `TrashChips` | 351 |
| `TrashStoneChips` | 110 |
| `colorSets` | 8 |
| `curtain_manager` | 127 |

## Generator configuration gaps

Counts are files with each reported first failure per referenced pattern; files can appear in several rows. The [original inventory](generator-evidence.json) records **all** token spellings and properties, including those after the first unsupported token. Configuration gaps are inspected even when a different model/goal already prevents the level from running.

| Reason | Files |
| --- | ---: |
| `BornPatterns token [g1]` | 36 |
| `BornPatterns token [g2]` | 34 |
| `BornPatterns token [p]` | 25 |
| `BornPatterns token [e2]` | 25 |
| `BornPatterns token [Chs]` | 21 |
| `BornPatterns token [d2]` | 17 |
| `BornPatterns token [Tb]` | 15 |
| `BornPatterns token [a]` | 15 |
| `BornPatterns token [l1]` | 13 |
| `BornPatterns token [sh]` | 12 |
| `BornPatterns token [Y]` | 11 |
| `BornPatterns token [e3]` | 11 |
| `BornPatterns token [O]` | 10 |
| `BornPatterns token [PT5]` | 10 |
| `BornPatterns token [HG3]` | 6 |
| `BornPatterns token [Eb]` | 6 |
| `BornPatterns token [e23]` | 5 |
| `BornPatterns token [t12]` | 4 |
| `BornPatterns token [S12]` | 4 |
| `BornPatterns token [EG]` | 4 |
| `BornPatterns missing/conflicting reference id=2` | 3 |
| `BornPatterns token [F2]` | 3 |
| `BornPatterns token [F1]` | 3 |
| `BornPatterns token [Tmr]` | 3 |
| `BornPatterns token [S1]` | 2 |
| `BornPatterns token [F12]` | 2 |
| `BornPatterns token [MB]` | 1 |
| `BornPatterns missing/conflicting reference id=1` | 1 |
| `BornPatterns token [HG]` | 1 |
| `BornPatterns token [D]` | 1 |

## Verification

44 Swift tests pass, including the full 6,184-file source-retention test. The latest test build took 2.77 s and execution took 5.92 s. The corpus exercise took 20.79 s. Six original-resource inventory tests took 2.13 s; the byte-for-byte original archive check took 1.76 s. Lint took 1.54 s with no warnings/errors. UI-only rebuilds and native visual checks are recorded in [GENERATORS.md](GENERATORS.md). No large dependencies or datasets were downloaded.
