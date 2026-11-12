# June's Journey scene explorer

Explore the bundled first scene and chapter-one clue artwork from the local
June's Journey 4.17.7 extraction. Python 3 is the only runtime dependency.

From the repository root, run:

```sh
python3 tools/junes-viewer/serve.py
```

Open <http://127.0.0.1:8766>. Pass `--port 8767` to choose another port or
`--data /path/to/junes-journey-analysis` to use another extraction. The server
binds to loopback and reads only its UI and extracted scene images and data.
The existing extraction is in `reference/junes-journey-analysis/`. To recreate
the scene files from the local app, follow [the extraction notes](../../docs/JUNES_JOURNEY_ANALYSIS.md).
The viewer also needs the extracted `story/` files described there.

Select a region in the scene or a card in the object list to inspect an object.
Search by source name, filter by serialized difficulty, and toggle region
outlines. Open a clue card to see its artwork and the available chapter staging
association. The opening dialogue is expandable below the clue gallery.

Positions and polygon regions are reconstructed from the serialized Unity
transforms, background dimensions, sprite sizes, sorting orders and colliders.
The viewer shows the authored object layers together. The placeholder clue
character is hidden from the composite but remains available to inspect. Actual
runtime object selection and clue appearance are unverified. Difficulty values
are shown as serialized values without assuming their gameplay meaning. The
scene-one clue artwork cannot be assigned to numbered clues from the extracted
staging. The gallery includes clue art from later scenes for context; those
scenes themselves were not recovered.
