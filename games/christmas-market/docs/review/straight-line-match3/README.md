# Straight-line hex match-3 review

Before and after screenshots of the board at 480×900 and 390×844, and the
480×900 Market keeper's guide. All six images were inspected before posting.
The changes use existing artwork and interaction states.

The before images come from CI run 41451740623 at
`c3b507b8f3b3e092b1fc201459b7e55da667baa7`; its tree matches the main-branch
baseline. The after images come from CI run 41597879292 at
`f6e223f49ee7d20b9d48ad185e6e31f4fe2b14bf`. Both runs use the repository's
existing Linux/Xvfb capture and documentation-image pipeline.

To reproduce just the affected screens in one game process:

```sh
make CFLAGS="-O2 -g -Werror" christmas-market build/test/christmas-market
xvfb-run -a ./build/test/christmas-market "shot main-character-board" "shot phone-board" "shot guide"
```

The raw captures are `build/shots/christmas-market/*.png`. CI's existing
`tools/screenshots.py` export produces the JPGs preserved here.
