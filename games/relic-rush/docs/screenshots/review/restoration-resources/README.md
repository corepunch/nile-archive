# Restoration resources

The Spring Well gives the marker expeditions water buckets worth one
Provisions each. The Artisan Workshop gives the supply run cut blocks worth
one Supplies each. The blocks are the darker outlined sprite from the
original Resources sheet. The blue supply packs still fill the crate goal.

| View | Before | After |
| --- | --- | --- |
| Shore Marker briefing, 480 × 900 | ![Original briefing](well-briefing-before.jpg) | ![Water earns Provisions](well-briefing-after.jpg) |
| Shore Marker briefing, 390 × 844 | ![Original phone briefing](well-briefing-phone-before.jpg) | ![Water earns Provisions on phone](well-briefing-phone-after.jpg) |
| Supply Crate board, 480 × 900 | ![Pale dressed stone](workshop-board-before.jpg) | ![Dark cut blocks](workshop-board-after.jpg) |
| Supply Crate board, 390 × 844 | ![Pale dressed stone on phone](workshop-board-phone-before.jpg) | ![Dark cut blocks on phone](workshop-board-phone-after.jpg) |

| Workshop briefing | Explorer’s guide | Supply crate handoff |
| --- | --- | --- |
| ![Cut blocks earn Supplies](workshop-lesson-phone.jpg) | ![Well and Workshop rewards](phone-guide.jpg) | ![Mara explains the plan for the steps](workshop-story-phone.jpg) |

Reproduce the captures using the named Relic Rush tests.

```sh
build/test/relic-rush "shot dressing-lesson" "shot floating-hud" "shot phone-floating-hud" "shot workshop-lesson" "shot workshop-story" "shot phone-guide"
```

Use `--level 9 --before-workshop` in the game to preview the pale stone
palette before restoration. Ownership and earnings are exercised by
`"rules relic_wallet"`; `"smoke campaign"` follows the live story, claim
and placement sequence.
