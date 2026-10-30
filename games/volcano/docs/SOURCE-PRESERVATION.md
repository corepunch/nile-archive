# Volcano source preservation

The former `/Users/igor/Developer/volcano-sdl2` checkout has been retired after
copying and verifying all its files into this repository. The original GitHub
repository is not removed by this local migration.

## Authored content kept with the project

[../source/](../source/) preserves the complete original working tree, including
its C implementation, tools, content definitions, editable models, source art,
documentation and all eleven missions:

| Mission | Current status |
|---|---|
| First Rescue | Original editable mission and art preserved |
| Emerald Falls | Original editable mission and art preserved |
| Forest Mayday | Original editable mission and art preserved |
| Ancient Echoes | Original editable mission and art preserved |
| Library Rescue | Original editable mission and art preserved |
| Twisted Tracks | Original editable mission and art preserved |
| After the Eruption: Outskirts | Preserved source and native Lua port |
| After the Eruption: Suburbs | Preserved source and native Lua port |
| After the Eruption: Town Square | Preserved source and native Lua port |
| After the Eruption: Cut-off District | Preserved source and native Lua port |
| After the Eruption: City Centre | Preserved source and native Lua port |

The source folder is a historical preservation copy. Its old engine, original
workflow instructions and formats are retained as source material; the current
game still uses the shared engine and Lua. Native/web/iPad packaging includes
only the game's `lua/` and `data/` directories.

## Local references and recovery material

The root `.gitignore` excludes `/reference/`. These files are kept locally:

| Local location from repository root | Preserved material |
|---|---|
| `reference/rescue-team/` | Complete original Rescue Team reference assets and levels |
| `reference/my-kingdom-for-the-princess/` | Other reference game's original files |
| `reference/volcano-resources/` | Original checkout's separate resource tree |
| `reference/volcano-backup/build/` | Complete previous build folder, including renders, temporary authoring scripts and virtual environment |
| `reference/volcano-backup/volcano-history.bundle` | Self-contained bundle of every original Git ref and its history |

The preserved source's ignored `reference`, `resources` and `build` links point
to these local directories, so its relative asset paths remain available. A
fresh Git clone alone does not contain the ignored reference/recovery files;
back up this local folder separately if moving machines.

[The manifest](source-preservation.json) records the original commit, every
source-to-destination mapping, byte size and SHA-256 checksum. It also preserves
all empty directories and symlink targets. The old `.git` directory is replaced
by the verified Git bundle, rather than creating a nested repository.

Recheck the preserved content from this repository root:

```sh
python3 games/volcano/tools/preserve_source.py --verify
```

Repack native campaign assets using the preserved source and local reference
art, with no dependency on the deleted checkout:

```sh
python3 games/volcano/tools/import_episode.py
python3 games/volcano/tools/check_assets.py
```

To recover the historical repository independently, clone
`reference/volcano-backup/volcano-history.bundle` into another directory.
