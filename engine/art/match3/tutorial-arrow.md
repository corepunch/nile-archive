# Tutorial arrow

The arrow points from the source piece to the adjacent destination piece during
a guided swap. It has one painted state. The board rotates it to the swap
direction and slides it gently along that direction. Reduce Motion holds it still.

ImageGen painted the [source](tutorial-arrow-source.png) from the brief of a
straight right-pointing ivory enamel arrow with a champagne-gold bevel, a bronze
keyline and soft shadow. Crop to the bounds of alpha values of 16 or higher,
preserving the pixel alpha, then resize to 128 × 61 with Lanczos. The registered
sprite is [tutorial-arrow.png](../../data/board/hints/tutorial-arrow.png).
The game draws the cream highlight from each piece's painted silhouette.

Review in `build/test/all --suite=christmas-market "shot tutorial-line"` or
`build/test/all --suite=relic-rush "shot tutorial-match-three"`.
