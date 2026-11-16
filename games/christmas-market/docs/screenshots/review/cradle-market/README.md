# Christmas Market · the resource prototype in game

Wish 4 shows the firewood earned after building the arch and the expanded
pane pattern. The first tool arrives after Theo’s workshop, so there is no
tool row on this wish.

| Size | Previous campaign | Resource prototype |
| --- | --- | --- |
| 480×900 | ![Wish 4 before](board-before-480.jpg) | ![Wish 4 after](board-after-480.jpg) |
| 390×844 | ![Wish 4 before on a smaller phone](board-before-390.jpg) | ![Wish 4 after on a smaller phone](board-after-390.jpg) |

| Wish 20 · green double panes and Lightning | Bakery · price and new piece | Wish 19 · letter and earnings |
| --- | --- | --- |
| ![A Letter Forty Years Late](double-panes-and-lightning.jpg) | ![Bakery building card](bakery-price.jpg) | ![Undelivered letter on the results card](letter-result-390.jpg) |

The results screenshot uses the standard victory fixture. The actual
campaign payouts are in the [20-wish record](../../../resource-prototype.md).

| Registered pieces and tool states | Guide |
| --- | --- |
| ![Twelve market pieces](atlas.jpg) | ![Rules on a 390×844 phone](guide-390.jpg) |

Capture the current screens from the repository root using one test process.

```sh
build/test/christmas-market "shot main-character-board" "shot phone-board" \
  "shot story-level-20" "shot building-card" "shot find-letter-reward" \
  "shot art-states" "shot phone-guide"
```
