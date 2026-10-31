# Primal Rage arcade runtime and asset catalogue

Clayfight now uses the supplied **Primal Rage arcade 2.3 December 1994**
(`primrageo`) chips in `data/primrage/`. The entire game framebuffer is
**672×480**, exactly twice the arcade's native **336×240**. Fighting sprites
retain their original pixels, RGB555 colours and pivots. The DOS installation,
DOS executable and converted retail creature definitions are unused and removed
from active data. Custom clay photographs remain in `data/creatures/`.

## Runtime contract

| Asset / behaviour | Original source | Runtime / registration |
|---|---|---|
| Seven fighter bodies and effects | 12,000-slot Atari RLE motion-object table; 11,206 nonempty objects | `w_gra.c`, lazy decoding; source signed x/y pivots; index 0 transparent |
| Fighter colours | CPU palette pointer table `0x6e38c` | Seven characters × four original 64-colour palettes; no recolouring |
| Animations and moves | CPU script table `0x6d964`, 65 rows × 10 slots | `p_script.c` executes big-endian ROM bytecode; native units, 30-frame breathing and 20-frame crouch cycles |
| Damage, stun, hit class and attack boxes | `0xfbba0`, `0x6fca4`, `0x72ea4`, `0x7d328`, `0x49f7c` | `PS_Move`; native sprite anchors; no DOS art scale |
| Eight arena skies and floors | Three tile-plane chips; map tables `0x1e58c4`, `0x1e5904`; palette pointers `0x5fea2` | `W_DrawArcadeStage`; original tile planes and source colours, camera scroll and floor-strip projection |
| Title and menu panel | Motion objects 446, 460, 480; palettes `0x68d7a`, `0x652c2` | Native title layers; original stone art resized to the menu panel |
| Character-selection temple | Objects 784/785; palettes `0x6717a`/`0x671fa` | Complete 336×240 background at 2×, sky plus temple |
| Podiums | Objects 786/787; palette `0x6727a` | Both source podiums; inward-facing animated previews above their surfaces |
| Original selection states | Reliefs 788–794 and original body palettes | Unselected stone reliefs in background; coloured source heads under P1/P2 cursors; procedural red/yellow focus outlines retained |
| Original close-up portraits | Objects 852–886, five frames per fighter; palette pointers at `0x676fa` | Source palettes; clay pages retain authored photo portraits, selected/unselected tile backgrounds and shared cursors |
| Conquest globe | Object 491 with `0x65cfa`; continents 503/516/529 with `0x65d7a` | Shared source hotspots retained; uniformly scaled to fit campaign list |
| Character glyphs | `136102-1045b.23p`, packed 4-bit 8×8 glyphs | Original character shapes, trimmed transparent right columns; existing text colour API |
| Effects and seven voice tables | CAGE boot chip 1078a and sound chips 0075/0077 | Standalone BSD-licensed TMS320C3x interpreter, native ROM driver, four DAC channels mixed into cached 11025 Hz mono PCM; shared stereo panning |

The sound adapter reads victory, attack and pain command tables at `0x6b0b0`,
`0x6e3e8` and `0x69c64`. Generic impact commands 8064–806A, block 806B,
swish 8049, thud 806F, crowd 80E3 and select 806C feed the existing events.
Samples decode once during sound-enabled startup, then play without emulation
in the combat loop. `-nosound` skips decoding. See
[`source/sound/LICENSE`](../source/sound/LICENSE) for interpreter attribution.
There is no runtime SDL or MAME executable dependency.

The port retains its existing campaign, training, tug, endurance and photo
capture rules. This migration does not implement the original machine's full
special-move, projectile, fatality, follower or cinematic systems; those were
already outside the port's supported rules. It does not claim hardware-exact
arcade emulation. See [menus and capture](menu-and-capture.md).

## Reproduction and review

From the repository root:

```sh
python3 games/clayfight/tools/import_resources.py /path/to/primrage
make CFLAGS="-O2 -g -Werror" clayfight build/clayfight-arcade
make test-clayfight-retail
python3 games/clayfight/tools/screenshots.py
make lint
```

The combined retail suite starts the game once, checks all seven voice tables
and effect decoding, 280 standard animations/move slots, game flow, selection,
palettes and 1,629 airborne pose/box registrations, and captures title, menus,
original/clay selection, all eight arenas, conquest, continue, ending and a
short fight reel. Screens are under `docs/review/arcade/after/`; representative
DOS baselines are under `before/`. Normal project screenshots are updated by
the screenshot tool. The renderer is fixed at 672×480 and larger host windows
letterbox it without changing the native coordinate system.

| Screen | DOS baseline | Arcade runtime |
|---|---|---|
| Selection | ![DOS selection](review/arcade/before/select.png) | ![Arcade selection](review/arcade/after/select.png) |
| Menu | ![DOS menu](review/arcade/before/menu.png) | ![Arcade menu](review/arcade/after/menu.png) |
| Campaign | ![DOS map](review/arcade/before/campaign.png) | ![Arcade map](review/arcade/after/campaign.png) |

## Historical sprite comparison, corrected mapping

Both versions show the same recognisable models and poses, but their sprites
are **not identical**. Arcade retains more pixels, colours and intermediate
poses. The comparison now selects poses from the arcade's actual standing
scripts for **all seven fighters**. Early comparisons inferred object IDs
through DOS aliases; that mapping was unreliable and its 53-frame cycle counts
were incorrect. All seven native arcade breathing cycles contain 30 frames.

Historical comparison requires an external DOS copy and externally generated
DOS definitions; they are not installed inside runtime data:

```sh
python3 games/clayfight/tools/pr2creature.py /path/to/DOS /tmp/dos-creatures
python3 games/clayfight/tools/compare_arcade.py --dos /path/to/DOS --creatures /tmp/dos-creatures
```

Outputs stay Git-ignored under `art/reference/arcade-comparison/`, outside
bundled data: native/detail comparison PNGs, a SHA-256 input/report manifest,
`arcade-raw-indexed.zip` (11,206 objects) and
`arcade-standing-coloured.zip` (210 native standing objects, all seven
palettes). Raw indexed exports have a diagnostic greyscale palette; coloured
exports use the original CPU palettes and transparency. No generated artwork,
smoothing or manufactured intermediate frames are used.

| Fighter | DOS pixels | Arcade object | Arcade pixels | DOS / arcade colours |
|---|---|---:|---|---:|
| Sauron | 153×86 | 3818 | 190×122 | 31 / 59 |
| Blizzard | 70×87 | 4747 | 87×122 | 31 / 60 |
| Talon | 139×64 | 3004 | 173×90 | 30 / 47 |
| Vertigo | 173×83 | 5789 | 215×118 | 28 / 59 |
| Armadon | 131×76 | 8070 | 163×107 | 31 / 60 |
| Diablo | 137×75 | 3788 | 194×122 | 31 / 60 |
| Chaos | 56×71 | 4776 | 80×114 | 29 / 60 |

Measurements include transparent margins and use visually closest standing poses;
they do not claim pixel-exact pose equivalence.

ROM layout and RLE provenance: [MAME Atari GT driver](https://github.com/mamedev/mame/blob/master/src/mame/atari/atarigt.cpp), [Atari RLE decoder](https://github.com/mamedev/mame/blob/master/src/mame/atari/atarirle.cpp), [CAGE board](https://github.com/mamedev/mame/blob/master/src/mame/shared/cage.cpp).
