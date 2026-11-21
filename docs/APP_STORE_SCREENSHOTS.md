# App Store screenshots

| Listing | iPhone, 1320 × 2868 |
| --- | --- |
| Christmas at Bellmere | [Five screenshots](../games/christmas-market/docs/screenshots/app-store/iphone/) |
| Relic Rush - Uncover Mysteries | [Five screenshots](../games/relic-rush/docs/screenshots/app-store/iphone/) |

These match-3 games target iPhone. The [Bellmere iPad gallery](../games/christmas-market/docs/screenshots/app-store/ipad/)
records the earlier universal build.

Both galleries open on a decorated town and show two line gems clearing a row and column. Bellmere features the Christmas tree square, the winter fair and the letter puzzle. Relic Rush features the coastal harbor, the temple gardens and the jewel pack. Both end with a rainbow gem lighting up the matching pieces before they break.

## Capture and export

From the repository root on a Mac with a 2× display, run the opt-in capture jobs. They render the game at the App Store pixel sizes and use the target device's safe-area proportions.

```sh
make build/test/all
APP_STORE_SHOTS=1 build/test/all --suite=christmas-market --suite=relic-rush 'shot app-store-iphone-'
```

The layouts in [the town capture fixture](../tests/fixtures/app-store-town/) use each game's buildings, plants, props and normal placement rules. Convert the named captures to RGB JPEGs. The numbered filenames set the gallery order.

```sh
python3 - <<'PY'
from pathlib import Path
import os
import subprocess

from PIL import Image

jobs = subprocess.check_output(
    ["build/test/all", "--suite=christmas-market", "--suite=relic-rush",
     "--list", "shot app-store-iphone-"],
    env={**os.environ, "APP_STORE_SHOTS": "1"}, text=True,
)
size = (1320, 2868)
for line in jobs.splitlines():
    if line.endswith(":"):
        game = line[:-1]
        continue
    _, shot = line.split()
    _, _, device, name = shot.split("-", 3)
    path = Path("build/shots", game, f"{shot}.png")
    destination = Path("games", game, "docs/screenshots/app-store", device)
    destination.mkdir(parents=True, exist_ok=True)
    with Image.open(path) as capture:
        if capture.size != size:
            raise ValueError(f"{path} is {capture.size}, expected {size}")
        capture.convert("RGB").save(destination / f"{name}.jpg",
                                    quality=95, subsampling=0, optimize=True)
PY
```

Inspect the exported images, then use `asc screenshots validate --path <gallery> --device-type <type>` with `IPHONE_69` or `IPAD_PRO_3GEN_129`. Check the editable version and its existing sets before uploading to the `en-US` localization. Use `asc screenshots list` to verify the order and delivery status after upload.
