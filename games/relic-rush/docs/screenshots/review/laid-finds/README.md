# Timber and relay cable excavations

Comparisons show the original find on the left and the new art on the right.
The sand marks cells still to clear. An authored black silhouette shows the shape
under the pieces, and each match reveals the painted prop in the cleared cells.
The timber screenshots record the original excavation. See the
[current timber collection board](../story-collection/README.md).

| Board and state | 480×900 | 390×844 |
| --- | --- | --- |
| Camp timber, covered | [Before and after](timber-covered-480.jpg) | [Before and after](timber-covered-390.jpg) |
| Camp timber, partly uncovered | [Before and after](timber-partial-480.jpg) | [Before and after](timber-partial-390.jpg) |
| Camp timber, recovered | [Before and after](timber-recovered-480.jpg) | [Before and after](timber-recovered-390.jpg) |
| Relay cable, covered | [Before and after](cable-covered-480.jpg) | [Before and after](cable-covered-390.jpg) |
| Relay cable, partly uncovered | [Before and after](cable-partial-480.jpg) | [Before and after](cable-partial-390.jpg) |
| Relay cable, recovered | [Before and after](cable-recovered-480.jpg) | [Before and after](cable-recovered-390.jpg) |

The [recovered-item cards](cards.jpg) use the compact artwork.
Reproduce the captures from the repository root.

```sh
build/test/relic-rush "shot cable-" "shot find-half"
python3 tools/relic_quest_art.py --check --overlay-dir /tmp/relic-finds
```

See the [asset catalogue](../../../asset-catalogue.md#chapter-1-quest-objects)
for the source atlas, prompts, individual PNGs and footprint registration.
