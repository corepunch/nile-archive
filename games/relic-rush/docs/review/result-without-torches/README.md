# Result card without torches

Before: main at `8d30149b9550b02fb971a3e3080e5494b1a28f35`. After: this PR.

Both decorative sconces and the unused flame renderer are removed. The result card retains its existing stars, score, resource rewards, progression, next restoration, reveal sequence and claim behavior. No artwork or interaction state is added.

Capture the real game with `--headless --fresh --mute --victory --frames 90 --shot <file>.png`, at `--size 480x900` and `--size 390x844 --safe-area 0,47,0,34`. Review JPEGs are capped at 480×900; canonical screenshots retain native capture resolution. The result reel uses 36 frames at `--frames (3*i+1) --victory --reel`, reduced to 240×450 for the documentation GIF. `make shots` reproduces the result screenshots and reel.

Build, unit tests, authored atlas checks, and the normal/tall-phone injected-input smoke runs verify the change and reward collection.
