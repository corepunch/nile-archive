# Christmas Market resources and story finds

The town and puzzle share the wallet. Shop cards and first-clear rewards use
the same Gold, Treats and Supplies icons. Cocoa Corner shows the regular
palette with a chain over a blue pane.

| Screen | Before | After |
| --- | --- | --- |
| Puzzle, 480×900 | ![Gold and Stars wallet](board-before-480.jpg) | ![Shared resource wallet](board-480.jpg) |
| Puzzle, 390×844 | ![Prior narrow wallet](board-before-390.jpg) | ![Resources on the narrow puzzle](board-390.jpg) |
| Shop, 480×900 | ![Gold prices](shop-before-480.jpg) | ![Mixed costs](shop-480.jpg) |
| Shop, 390×844 | ![Prior narrow shop](shop-before-390.jpg) | ![Mixed costs on the narrow shop](shop-390.jpg) |
| Result | ![Fixed Gold payout](reward-before.jpg) | ![Matched resources to bank](reward.jpg) |
| Town, 480×900 | ![Prior town wallet](market-before.jpg) | ![Resource wallet in town](market.jpg) |

[The town wallet at 390×844](market-390.jpg) and [the revised Market Guide](guide.jpg).

| Cocoa mug | Blue practice scarf | Undelivered letter |
| --- | --- | --- |
| ![Mug replaces candy cane](cocoa.jpg) | ![Scarf replaces blue mitten](scarf.jpg) | ![Letter replaces gingerbread](letter-480.jpg) |

| Wish ribbon | Station telegram | Borrowed lantern |
| --- | --- | --- |
| ![Ribbon replaces candy cane](ribbon.jpg) | ![Telegram replaces blue mitten](telegram.jpg) | ![Lantern replaces bell](lantern.jpg) |

[Letter board at 390×844](letter-390.jpg) and [first-clear reward with the letter](letter-reward.jpg).

Capture the actual game in one test run.

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market "shot main-character-board" "shot phone-board" "shot shop" "shot phone-shop" \
  "shot market" "shot phone-market" "shot reward" "shot guide" "shot find-"
```
