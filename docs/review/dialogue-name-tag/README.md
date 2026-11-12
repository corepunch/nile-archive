# Dialogue name tag on the top border

The shared dialogue bar centers the speaker’s name tag on its top border.
The text stays vertically centered and Skip sits below the bar. Each
comparison shows the previous placement on the left and the new one on the right.

| Game | 480×900 | 390×844 with safe areas |
| --- | --- | --- |
| Relic Rush | ![Relic Rush at 480×900](relic-rush-480.jpg) | ![Relic Rush at 390×844](relic-rush-390.jpg) |
| Christmas Market | ![Christmas Market at 480×900](christmas-market-480.jpg) | ![Christmas Market at 390×844](christmas-market-390.jpg) |

```sh
build/test/relic-rush 'shot quest-handoff'
build/test/christmas-market 'shot dialogue-bar-'
```
