# Popup close artwork

The five red enamel buttons were drawn together in a single ImageGen strip. A large ivory X identifies dismissal. Focus uses the engine’s standard focus ring. The hover, selected, pressed and disabled faces come directly from the painting.

## Generation prompt

> One production-ready transparent horizontal sprite atlas of precisely FIVE red circular close buttons for a warm illustrated island expedition puzzle game, five equal cells in a single row, left to right: normal, selected, pressed, hover, disabled. All five share the identical front-facing circular silhouette, softly bevelled antique gold rim, lacquered vermilion face and a very large thick raised ivory X with a slender dark umber keyline, readable at 32px. Selected has lit golden rim, pressed has visibly inset darker face, hover has brighter coral lacquer, disabled has muted brick-grey finish and matte pale X. Same diameter, optical center, scale and lighting across all five. Each authored directly. Transparent clear gutters between them, no contact shadows outside each button. No labels/captions/text beyond X, no extra items. 5:1 wide strip if possible. Each button must be a perfect circle.

## Registration

Run from games/relic-rush to register the five painted cells. The rectangular crops preserve the source alpha.

```python
from PIL import Image

source = Image.open("art/popup-close/source.png").convert("RGBA")
states = ["normal", "selected", "pressed", "hover", "disabled"]
for state, center in zip(states, [232, 659, 1086, 1513, 1939]):
    cell = source.crop((center - 213, 142, center + 213, 578))
    cell.thumbnail((124, 124), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (128, 128))
    frame.paste(cell, ((128 - cell.width) // 2, (128 - cell.height) // 2))
    frame.save(f"art/registered/board-states/close-{state}.png")
```

Run `python3 tools/match3_atlas.py` at repository root to repack pieces.png and its frame index.
