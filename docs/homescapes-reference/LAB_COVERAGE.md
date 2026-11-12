# Homescapes lab coverage — 2026-11-12

The full local 9.2.601 corpus audit loaded 6,184 files without parse or construction errors on the attempted boards. Only 232 boards initialize; the remaining 5,952 contain unsupported vocabulary. Initialization does not establish original-game behavior. There are 130 model IDs and 82 goal types in the corpus; 115 model IDs and 75 goal types are not accepted by the lab.

Run the `--audit` command in the [lab README](../../prototypes/homescapes-match3/README.md#full-corpus-audit) for the current machine-readable report, including every path. Counts below are files containing an identifier, not individual instances.

## Implemented in this batch

- Double bomb, double plane, plane carrying bomb/rocket, rainbow conversion to bomb/rocket/plane, and double rainbow combination dispatch.
- Ice and chains protect a covered cookie; removal credits the restraint goal.
- Donut stacks settle through marked exits before random refill.
- Full corpus reporting retains every unsupported model and goal rather than just the first error.

The [lab README](../../prototypes/homescapes-match3/README.md#additional-rules-and-verification) links publisher evidence and documents unverified geometry, targeting, conversion and hit scheduling. The original iPhoneOS executable was not run. No original-game equivalence is claimed. Existing assets and mappings are unchanged.

## Verification

Swift build: 3.94 s. All 18 Swift tests: 5.77 s, including loading and preserving every local level. Complete corpus audit: 6.57 s. Eight sample boards, 12 moves each: 0.70 s. Archive reader tests (5), including byte-for-byte comparison of all extracted levels: 1.48 s. Repository lint: 1.14 s, no warnings or errors.

## Remaining model vocabulary

| Identifier | Files | Example |
| --- | ---: | --- |
| `ARCADE` | 20 | `packs/contest/contest_401_08.xml` |
| `ARMOR` | 84 | `packs/contest/contest_403_01.xml` |
| `ARTIFACT_GEN` | 743 | `base/beta/beta003.xml` |
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
| `BUBBLE_MEMBRANE` | 280 | `packs/contest/contest_011_12.xml` |
| `BUCKET` | 188 | `base/View/ply-water.xml` |
| `BUCKET_WATER` | 188 | `base/View/ply-water.xml` |
| `CAKE` | 91 | `packs/contest/contest_181_14.xml` |
| `CARRY_GEN` | 166 | `base/st/st0251.xml` |
| `CARRY_GEN_CELLS` | 196 | `base/st/st0251.xml` |
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
| `COLOR_BOX` | 161 | `packs/contest/contest_020_08.xml` |
| `COOKIE_BOX` | 112 | `packs/contest/contest_026_01.xml` |
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
| `FISH` | 289 | `base/View/ply-water.xml` |
| `FLOWER_BOX` | 129 | `packs/contest/contest_081_10.xml` |
| `FOAM` | 61 | `packs/contest/contest_402_09.xml` |
| `FRIDGE` | 228 | `packs/contest/contest_063_12.xml` |
| `GARBAGE_PLATE` | 115 | `base/beta/beta004.xml` |
| `GARBAGE_VASE` | 128 | `base/beta/beta003.xml` |
| `GONG` | 128 | `packs/contest/contest_016_01.xml` |
| `HONEY` | 832 | `base/View/st0101.xml` |
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
| `PATTERN_COLOR_BORN` | 321 | `base/st/st0037.xml` |
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
| `SHUTTERS` | 341 | `base/st/st0401.xml` |
| `SOAP` | 77 | `packs/contest/contest_080_06.xml` |
| `STAINED_GLASS` | 34 | `packs/contest/contest_072_09.xml` |
| `STATUE` | 477 | `base/st/st0221.xml` |
| `STEAM` | 178 | `packs/contest/contest_015_02.xml` |
| `STEAM_GEN` | 78 | `packs/contest/contest_137_05.xml` |
| `STONE_TAPE_MEASURE` | 138 | `packs/contest/contest_058_15.xml` |
| `SUGAR_BORDER` | 40 | `packs/contest/contest_401_08.xml` |
| `SUITCASE` | 102 | `packs/contest/contest_016_15.xml` |
| `SUITCASE_HAT_UNWANTED_CELLS` | 2 | `packs/contest/contest_144_01.xml` |
| `TABLETS` | 1 | `base/View/ply-water.xml` |
| `TAPE_MEASURE` | 216 | `base/beta/beta003.xml` |
| `TARGET_GEN` | 379 | `base/st/st0051.xml` |
| `TIMER` | 63 | `packs/contest/contest_074_10.xml` |
| `TIN_CAN` | 306 | `packs/contest/contest_020_06.xml` |
| `TIN_CAN_APPEAR_CELLS` | 179 | `packs/contest/contest_023_11.xml` |
| `TOY_BOX` | 169 | `packs/contest/contest_023_03.xml` |
| `TRASH_STONE` | 456 | `base/st/st0351.xml` |
| `VACUUM` | 86 | `packs/contest/contest_102_13.xml` |
| `VACUUM_WAYPOINT` | 163 | `packs/contest/contest_102_13.xml` |
| `WATCH` | 80 | `packs/contest/contest_170_05.xml` |
| `WEB` | 164 | `packs/contest/contest_007_04.xml` |
| `YARN_BALL` | 201 | `packs/contest/contest_070_06.xml` |
| `YARN_BASKET` | 201 | `packs/contest/contest_070_06.xml` |

## Remaining goal vocabulary

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
| `BUBBLE_MEMBRANE` | 311 | `base/beta/beta007.xml` |
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
| `COLOR_BOX` | 133 | `packs/contest/contest_020_08.xml` |
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
| `SHUTTERS` | 19 | `base/st/st0401.xml` |
| `STATUE` | 477 | `base/st/st0221.xml` |
| `STEAM` | 13 | `packs/contest/contest_401_06.xml` |
| `STEAM_GEN` | 78 | `packs/contest/contest_137_05.xml` |
| `STONE_TAPE_MEASURE` | 124 | `packs/contest/contest_173_09.xml` |
| `SUGAR_BORDER` | 40 | `packs/contest/contest_401_08.xml` |
| `SUITCASE_HAT` | 102 | `packs/contest/contest_016_15.xml` |
| `SUPER_BONUS` | 42 | `packs/contest/contest_016_03.xml` |
| `TABLETS` | 1 | `base/View/ply-water.xml` |
| `TAPE_MEASURE` | 153 | `base/beta/beta003.xml` |
| `TARGET_GENERATOR` | 379 | `base/st/st0051.xml` |
| `TIMER` | 63 | `packs/contest/contest_074_10.xml` |
| `TIN_CAN` | 306 | `packs/contest/contest_020_06.xml` |
| `TOY_BOX` | 175 | `packs/contest/contest_023_03.xml` |
| `TRASHSTONE` | 355 | `base/st/st0351.xml` |
| `WATCH` | 80 | `packs/contest/contest_170_05.xml` |
| `YARN_BALL` | 201 | `packs/contest/contest_070_06.xml` |

## Configuration sections requiring further interpretation

Even an accepted model list does not imply complete configuration support. The loader preserves all sections; the simulator currently interprets cells, basic targets, chip weights and random-chip color lists. Other sections below remain evidence to decode and implement.

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
