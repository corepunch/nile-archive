# Compact find silhouettes

The [opening boards](covered-boards.jpg) show every new silhouette at 480×900.
The marker artwork appears twice because boards 5 and 6 share it. The
[recovered boards](recovered-boards.jpg) show the matching painted props.
The board 4 and 9 images record the original implementation. See the
[current story collection boards](../story-collection/README.md).

The before and after pairs below show the shutter crank over tide-room silt
at both phone sizes. Already uncovered cells show the painted crank.

| State | 480×900 | 390×844 |
| --- | --- | --- |
| Covered | [Before and after](crank-covered-480.jpg) | [Before and after](crank-covered-390.jpg) |
| Partly uncovered | [Before and after](crank-partial-480.jpg) | [Before and after](crank-partial-390.jpg) |

Run the crank captures with `build/test/relic-rush "shot crank-covered" "shot crank-half"`.
The same opening and recovery views are in the scenario overview. Refresh Relic
Rush's captures with `python3 tools/scenario_overview.py --capture --games relic-rush --out build/scenarios/relic-rush.html`,
then rebuild the combined overview with `python3 tools/scenario_overview.py`.
See the [asset catalogue](../../../asset-catalogue.md#chapter-1-quest-objects)
for the exact source and crop data.
