# Power-ups in both games

Christmas Market is on the left and Relic Rush is on the right. On each board,
the three rockets sit above the bomb, rainbow ball and plane.

![Christmas Market and Relic Rush side by side](boards.jpg)

## Relic Rush plane flight

The parchment plane flies from the middle of the board toward the left lane.
The loop plays at roughly quarter speed.

![Relic Rush paper plane in flight](relic-rush-plane.webp)

Capture the boards and flight with the existing test runner.

```sh
./build/test/all --suite=christmas-market --suite=relic-rush 'shot specials-and-stone'
./build/test/all --suite=relic-rush 'reel fx-plane'
```
