# Asset origins and replacement catalog

All runtime artwork is local to this game. Nothing is resolved from an installed
Rescue Team game or from the source project. Input files and SHA-256 hashes are
recorded in [asset-catalog.json](asset-catalog.json). The catalog also records
the exact shipped files and their hashes; `make test` verifies these stay in sync.

| Runtime asset | Origin | Replacement status |
|---|---|---|
| Five `emergency-*.png` backgrounds | Emergency's own painted episode maps | Original substitute already present |
| `sprites.png`: episode props and damaged/repaired stations | Emergency's authored `assets/volcano-episode` atlas | Original substitute already present |
| `sprites.png`: headquarters and broken paving | Emergency's authored `assets/hd-static` sheets | Original substitute used instead of retail art |
| `sprites.png`: workers and civilians | Kenney Survivors (CC0), Emergency's uniforms and work animations | Substitute already present; see `kenney-License.txt` |
| `pets-to-replace.png`: `cat0`, `dog0`, `dog1` | Rescue Team 5 / Rionix | **Replace** |
| `fonts/LilitaOne-Regular.ttf` | Existing shared repository game font, SIL OFL | No Rescue Team dependency |
| Interface, dialogue, effects and feedback sounds | Shared engine | No Rescue Team dependency |
| Native iOS/macOS `Assets.xcassets/AppIcon.appiconset` | Option 12, an authored emergency-worker team from one built-in ImageGen 4×4 sheet | Original artwork; full sheet, prompt and crop registration preserved in `art/app-icon/` |

The native app icon uses the user-selected three-person rescue team. Its full
source sheet is [preserved here](../art/app-icon/concepts-4x4-v1.png), and
[selection.json](../art/app-icon/selection.json) records the exact crop and
Lanczos export. The opaque 1024-pixel master is
[app-icon-1024.png](../art/app-icon/app-icon-1024.png); no generated states,
retouching or procedural overlays are used. It has one authored state, with OS
corner masking and launch feedback. These native assets live outside `data/`;
their hashes are recorded separately as `app_icon` in the JSON catalog.
Reproduce with `python3 games/emergency/tools/prepare_app_icon.py`, then regenerate
the Emergency Xcode project. Check with `python3 games/emergency/tools/check_assets.py`.
Review the master at full size and the native app icon after deployment; game
screens are unchanged by this asset.

The **only retained Rescue Team artwork** is the separate pet atlas: idle and
eight running directions for the three variants actually used by the campaign.
Its exact native animation keys and original declaration/image hashes are in
the JSON catalog. No unused source pet variants, retail shadows, icons,
backgrounds, buildings, fonts, menus, sounds or level files are shipped.

Replace the pet atlas with original or appropriately licensed cats/dogs in the
same camera perspective. Supply idle plus eight running directions per variant,
authored timing and ground pivots. Update `emergency_art.lua` and the catalog,
then run the regression and render the pet-containing maps. No legacy format
or game-rule change is necessary.

Packing copies existing source pixels and retains frame order, repetition and
pivots. It does not synthesize selected/pressed/damaged states. Original prompts
for the episode maps and prop sheet are retained beside this document.
