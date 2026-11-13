# City streets

The city's curved building connectors are replaced by paved streets on the tile
grid ([Roads](../../BUILDINGS.md#roads)). Before: main `b18bbf3a`. All captures
use the native game renderer.

| Game | Before | After |
| --- | --- | --- |
| Christmas Market, 480×900 | ![Before](before-christmas-market.jpg) | ![After](after-christmas-market.jpg) |
| Relic Rush, 480×900 | ![Before](before-relic-rush.jpg) | ![After](after-relic-rush.jpg) |
| Nile Archive, 1200×900 | ![Before](before-nile-archive.jpg) | ![After](after-nile-archive.jpg) |

Alternate sizes and states, after only (no before capture was taken at 390×844):

| Christmas Market, 390×844 | Relic Rush, 390×844 (`--city 3`) | Christmas Market, `--roads sandstone` | Christmas Market, `--footprints` |
| --- | --- | --- | --- |
| ![Phone](after-christmas-market-390.jpg) | ![Phone](after-relic-rush-390.jpg) | ![Sandstone](after-christmas-market-sandstone.jpg) | ![Footprints](after-christmas-market-footprints.jpg) |

```sh
./build/christmas-market --headless --mute --fresh --size 480x900 --showcase --shot market.png
./build/relic-rush --headless --mute --fresh --size 480x900 --showcase --shot island.png
./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --shot island.png
```
