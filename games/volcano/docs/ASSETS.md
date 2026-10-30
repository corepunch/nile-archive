# Asset origins and replacement catalog

All runtime artwork is local to this game. Nothing is resolved from an installed
Rescue Team game or from the source project. Input files and SHA-256 hashes are
recorded in [asset-catalog.json](asset-catalog.json). The catalog also records
the exact shipped files and their hashes; `make test` verifies these stay in sync.

| Runtime asset | Origin | Replacement status |
|---|---|---|
| Five `volcano-*.png` backgrounds | Volcano's own painted episode maps | Original substitute already present |
| `sprites.png`: episode props and damaged/repaired stations | Volcano's authored `assets/volcano-episode` atlas | Original substitute already present |
| `sprites.png`: headquarters and broken paving | Volcano's authored `assets/hd-static` sheets | Original substitute used instead of retail art |
| `sprites.png`: workers and civilians | Kenney Survivors (CC0), Volcano's uniforms and work animations | Substitute already present; see `kenney-License.txt` |
| `pets-to-replace.png`: `cat0`, `dog0`, `dog1` | Rescue Team 5 / Rionix | **Replace** |
| `fonts/LilitaOne-Regular.ttf` | Existing shared repository game font, SIL OFL | No Rescue Team dependency |
| Interface, dialogue, effects and feedback sounds | Shared engine | No Rescue Team dependency |

The **only retained Rescue Team artwork** is the separate pet atlas: idle and
eight running directions for the three variants actually used by the campaign.
Its exact native animation keys and original declaration/image hashes are in
the JSON catalog. No unused source pet variants, retail shadows, icons,
backgrounds, buildings, fonts, menus, sounds or level files are shipped.

Replace the pet atlas with original or appropriately licensed cats/dogs in the
same camera perspective. Supply idle plus eight running directions per variant,
authored timing and ground pivots. Update `volcano_art.lua` and the catalog,
then run the regression and render the pet-containing maps. No legacy format
or game-rule change is necessary.

Packing copies existing source pixels and retains frame order, repetition and
pivots. It does not synthesize selected/pressed/damaged states. Original prompts
for the episode maps and prop sheet are retained beside this document.
