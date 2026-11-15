# Edge-mounted match-3 chains

Relic Rush uses warm burnished metal. Christmas Market uses cooler silver and
brighter gold. The engine's neutral atlas uses the Relic Rush row.

| Frame | Rule and attachment points |
| --- | --- |
| `chain` | One hit remaining. Silver chain bolted to the lower-left and upper-right sides. |
| `chain-1-mirror` | One hit remaining on a mirrored source cell. Gold chain bolted to the upper-left and lower-right sides. |
| `chain-2` | Two hits remaining. Two crossed silver chains bolted to all four sloped sides. |

The `chain-1` compatibility frame reuses `chain`. Clearing the final hit removes
both the chain and its mounting plates.

One built-in ImageGen edit authored all six sprites in [one atlas](edge-anchors.png).
The [exact prompt](edge-anchors-prompt.txt) uses the [earlier curved chain art](source.png)
as its edit target and the [canonical mask preview](../../engine/art/hex-tile/hex-mask-preview.png)
as its geometry guide. The registration crops each atlas bay, takes a measured
square around the outside of its anchors and uniformly resizes to 128×128.
This preserves the authored alpha, link holes and mounting plates. Every
mounting plate reaches within one pixel of the canonical boundary at 50% alpha.
The board draws the canvas at `2 * (HEX_R - .65)`. The guide's chain icon uses
a miniature board face behind the piece and the same chain overlay.

Rebuild the engine and game textures with `python3 tools/match3_atlas.py`.
The manifests record the source, bay and square crop for every state.

- [Relic Rush in-game review](../../games/relic-rush/docs/screenshots/review/chain-anchors/README.md)
- [Christmas Market in-game review](../../games/christmas-market/docs/screenshots/review/chain-anchors/README.md)
