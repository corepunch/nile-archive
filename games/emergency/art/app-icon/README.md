# Emergency AppIcon concepts

`concepts-4x4-v1.png` contains sixteen alternatives in a single numbered 4×4
sheet, generated together with the built-in ImageGen tool on 2026-11-01.
The exact prompt is `concepts-4x4-v1.prompt.txt`; reproduce by submitting it as
one opaque image generation. Rows read left to right, numbered 1 through 16.
The original prompt names the game Volcano; it is preserved verbatim as the
generation record for the Emergency icon.

The user selected **12** (row 3, column 4): three emergency workers, with the
woman in the yellow hard hat in front. The original sheet remains unchanged.
`selection.json` records the artwork bounds and exact square crop, excluding
the gutters and number. `selected.png` preserves those 264×264 source pixels;
`app-icon-1024.png` is the opaque RGB master, enlarged with Lanczos resampling.
No artwork was regenerated or recoloured; iOS supplies corner masking.

Reproduce all native sizes and their provenance hashes with:

```sh
python3 games/emergency/tools/prepare_app_icon.py
python3 tools/xcode/generate.py emergency --unsigned
python3 games/emergency/tools/check_assets.py
```

`Assets.xcassets/AppIcon.appiconset` provides the 1024-pixel iOS icon and every
macOS 1×/2× slot. App icons have one authored state; the operating system owns
home-screen/Dock masking and interaction treatments. The catalog is separate
from game `data/`, and the existing game screens use unchanged artwork.
