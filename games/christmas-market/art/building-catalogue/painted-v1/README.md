# Current-camera painted buildings

ImageGen category paint-overs of christmas-market's registered Blender sprites.

- `*-input.png`: geometry guides, assembled by crop/translation and optional
  uniform `display_scale` recorded in the layout. Original RGBA retained.
- `*-output.png`: untouched generated RGBA, version 1 unless otherwise noted.
- `*-prompt.txt`: the generation/edit prompt. Style references are listed in the
  game's building catalogue.
- `*-layout.json`: canvas, grid and each source object's display rectangle.
- `render-registration.json`: original Blender registration at `aefd544`.
- `imports.json`: each accepted runtime key's raw atlas, cell, crop, uniform scale,
  resulting pixel pivot and dimensions. Later category overrides are explicit.

Reproduction: `python3 tools/import_painted_buildings.py christmas-market`.
This changes normal sprites only; interaction feedback remains in the engine.
Review: `../../../docs/review/painted-buildings/current-camera/README.md`.

## Style, references and exact prompts

The [shared style guide](../../../../../docs/BUILDING_STYLE.md) explains the
accepted finish, palette and detail density. [references.json](references.json)
records every literal prompt, ordered image inputs and hashes, retained versions
and accepted runtime keys. Image generation requires a fresh visual review; the
import command above reproduces sprites from the saved accepted PNGs.
