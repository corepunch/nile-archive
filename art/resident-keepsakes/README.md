# Resident keepsake paintings

[sheet.png](sheet.png) is the original 1774 × 887 ImageGen sheet. Each half is one finished illustration. Each game ships its own square picture at 512 × 512.

The portrait references were Relic Rush’s [Lio](../../games/relic-rush/data/story/characters/lio.png) and [Nera](../../games/relic-rush/data/story/characters/nera.png). The final art direction was to paint two pinned pencil drawings facing each other, with the parrot beside Lio’s ear and a pencil tucked behind Nera’s. In the second panel, show one four-hole cobalt glass coat button in the palm of Pip’s red knitted mitten over Otis’s checked tin lid. The mitten has one thumb and a single round pouch. Keep both subjects legible at visit size, with no lettering.

Reproduce both runtime pictures from the repository root with Pillow.

```sh
python3 - <<'PY'
from pathlib import Path
from PIL import Image

sheet = Image.open('art/resident-keepsakes/sheet.png').convert('RGB')
panels = [('relic-rush', 'facing-sketches'), ('christmas-market', 'pips-blue-button')]
for i, (game, name) in enumerate(panels):
    panel = sheet.crop((i * 887, 0, (i + 1) * 887, 887))
    path = Path('games') / game / 'data/story/scenes' / (name + '.jpg')
    panel.resize((512, 512), Image.Resampling.LANCZOS).save(path, quality=91, optimize=True)
PY
```
