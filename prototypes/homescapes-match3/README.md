# Homescapes Match-3 Lab

This standalone macOS Swift package opens eight match-3 boards from the
Homescapes 9.2.601 bundle. It reads the extracted XML, including the board
shape, fixed pieces, blocker strengths, goals and move budget, and displays
the decoded art in SpriteKit. The game has no animation.

Run from the Nile Archive checkout root with Xcode's Swift toolchain:

```sh
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD"
```

The app reads the local reference assets in place. See the
[Homescapes art reference](../../docs/homescapes-reference/ART.md) for the
extraction commands. The package manifest also opens directly in Xcode.

Use the menu to choose `st0004`, `st0008`, `st0011`, `st0016`, `st0022`,
`st0031`, `st0131` or `st0136`. Swap with a drag or two clicks. Click a
special twice to activate it. Restart replays the same seed, and New seed
changes the random fill. Hint highlights a legal move. The names are source
file IDs.

The rules cover horizontal and vertical matches, 2 × 2 planes, rockets,
bombs and rainbow balls, gravity, refill, cascades, locks, ice, boxes,
cookies, carpet spread and donut exits. Sprite states use the same
[model map](../../tools/homescapes-reference/model_sprites.json) as the web
explorer. The original refill algorithm, level scripting, spawn routing,
special pair combinations and the exact hit and targeting order remain
unverified. The lab uses seeded weighted fills and straight gravity.
Unsupported models and goals are rejected when loading a playable board.

```sh
swift test --package-path prototypes/homescapes-match3
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --check
```

The first command verifies special creation and held-piece damage. The
second loads the eight local boards and plays up to 12 legal moves on each.

The loader also retains the exact source XML and a generic element tree, including
unknown configuration and nested model data, for future mechanic implementation.
Retention does not imply that those mechanics are understood or playable. The
corpus test checks every locally extracted XML file; the archive test checks the
extracted bytes against the original bundled archive.
