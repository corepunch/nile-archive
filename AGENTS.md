# Instructions for coding agents

## Pull requests: always show screenshots

Every pull request that can change what a player sees must include screenshots in its description. That covers UI, layout, art, text, dialogue, effects and engine drawing code. Add them whenever it is possible at all. When it isn't, for example a pure build or test change, say so in one line.

- **Show the changed screens.** Include every screen the change touches, with before and after shots side by side when something existing changed.
- **Cover the sizes the change affects.** Nile Archive and Volcano are iPad landscape (1200×900, 1368×1026). Relic Rush is a 480×900 phone portrait. Add a 16:9 or a 390×844 shot when the layout adapts to it.
- **Capture the game itself.** Every game renders headlessly with the software renderer:

  ```sh
  make
  Xvfb :99 -screen 0 2000x1400x24 &            # or prefix each command with xvfb-run -a
  export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1
  ./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --shot out.png
  make shots                                   # re-renders every documentation screenshot
  ```

  Each game has entry points for its screens: Nile Archive takes `--screen …`, Relic Rush `--level`, `--city`, `--dialog …` and others, and Volcano `--level`, `--pause` and `--preview`. Pass `--frames N` for a later frame, for example once dialogue has finished typing.
- **Embed images, don't just link them.** Commit the screenshots under `games/<game>/docs/screenshots/`, or another tracked path when they are only for review. Reference them in the description with URLs pinned to the pushed commit, so they keep showing what was reviewed:

  ```markdown
  ![Island](https://github.com/corepunch/nile-archive/blob/<commit-sha>/games/nile-archive/docs/screenshots/island.jpg?raw=true)
  ```

  A table puts before and after next to each other.
- **Check them first.** Look at every screenshot before posting it. A half-typed line, an empty frame or a missing texture is a bug to fix, not a picture to post.

## Repository conventions

- **Build and test before pushing.** Run `make CFLAGS="-O2 -g -Werror"`, `make test`, and each affected game's `--smoke` run under Xvfb. CI runs the same checks.
- **Regenerate generated code.** After editing `engine/api.xml`, run `make gen`, and commit the generated files.
- **Keep the docs in step.** Update a game's README and `docs/` when its interface or rules change.
