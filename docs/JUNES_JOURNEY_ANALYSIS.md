# June's Journey bundled content

For the development handoff on story, progression and building prices, see the
[June’s Journey reference for Nile Archive](junes-journey-reference/README.md).

This inspection covers the iPhone app version 4.17.7, build 120. The source
app was supplied locally at `/Users/igor/Developer/nile-archive/reference/junesjourney.app`.
The extracted game content is in the ignored `reference/junes-journey-analysis/`
directory in this checkout. The investigation used static Unity asset and JSON
inspection. It did not establish what the live service delivers or overrides.

## Hidden-object scenes

`Data/Raw/iOS/chapters/001/` contains the scene 001-01 Unity bundle and
separate chapter 001 clue and thumbnail bundles. The extracted `scenes/` directory
contains 173 scene sprites including the 2048×1170 background, 10 clue sprites,
six thumbnails, and `scene-001-01/objects.json` with 1,319 serialized objects.
These include renderers, transforms, polygon colliders and behaviour fields.
`scenes/index.json` records source paths, sprite names, dimensions, object IDs
and extraction failures. The six thumbnails do not establish that six complete
scenes are included. The extracted pieces have not been assembled into a playable
scene.

To reproduce the scene extraction with UnityPy 1.25.4 installed:

```sh
/tmp/tropicats-inspect-venv/bin/python tools/extract_junes_scenes.py \
  /Users/igor/Developer/nile-archive/reference/junesjourney.app \
  reference/junes-journey-analysis/scenes
```

## Story

The app's `Data/Raw/iOS/chapters/001/` chapter dialogue JSON contains 84
staging rows across six scenes, including speakers, timing, positions and moods.
The bundled locale files contain the opening funnel text and generic startup
text. `story/` preserves the chapter and opening staging files, 72 locale JSON
files in 18 languages, and `funnel-dialogue-en-US.json`, which joins the four
opening dialogue identifiers with English text. The chapter staging refers to
identifiers whose full translated chapter dialogue was not found in the bundled
locale files, manifests or `resources.assets` TextAssets. Later campaign story
was not located in the inspected files.

The source files can be copied from `Data/Raw/iOS/locale/`,
`Data/Raw/iOS/dialogues/`, and the chapter 001 dialogue JSON. The joined opening
text uses identifiers from the opening dialogue staging JSON and the English
`jj-funnel-001` locale JSON.

## Progression and delivery

`progression/manifests/` contains the 33 bundled manifest JSON files and
`progression/manifest-inventory.json` lists 128 references and their local
presence. The bundled funnel manifest identifies chapter 001 and its chapter
manifest identifies the first scene, clues, thumbnails and dialogue. Complete
campaign progression tables and a later-chapter master manifest were not found.
The IL2CPP metadata names chapter and scene configuration services and contains
CDN base URLs. Those names do not establish the contents of the missing tables.
A guessed CDN manifest URL returned HTTP 403, leaving the correct remote path and
availability unverified.

To recopy the manifests, use:

```sh
cp -R /Users/igor/Developer/nile-archive/reference/junesjourney.app/Data/Raw/iOS/manifests \
  reference/junes-journey-analysis/progression/
```

## Follow-up phone and asset inspection

A follow-up inspection loaded all 784 bundled `Data/level*` and
`Data/*.assets` files. The 12 TextAssets found are listed in
`progression/unity-textassets-inventory.json`; none identifies the requested
campaign tables. Other serialized object types were not exhaustively decoded.
Additional guessed CDN paths returned HTTP 403, so the actual content path and
remote access requirements remain unknown.

The connected iPhone's app-container file listing failed with CoreDevice
ActionError 3. A selective backup attempt used a separate temporary directory
and retained only the June's Journey app domain, but the phone rejected the
backup before transfer, reporting that 164.7 GB of space was required and
the Mac had 3.5 GB available. A backup also excludes `Library/Caches`, so its contents
would depend on where the game stores downloaded data. No additional scene,
story or progression content was recovered from the phone in this attempt.
