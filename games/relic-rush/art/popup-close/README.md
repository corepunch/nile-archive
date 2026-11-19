# Popup close glyph

The shared round-button renderer paints the circle, rim, shadow and interaction feedback. Relic Rush supplies a red face palette and one ivory X. The disabled state uses the engine’s pewter finish. The `hud-states` game capture displays all five states in its last row.

## Artwork

ImageGen prompt: A single isolated ivory multiplication cross on transparent alpha, with two identical diagonal strokes crossing at 90 degrees, softly rounded squared ends, a delicate pale bevel and a narrow warm brown contour. Front-on and legible at 20 pixels. Keep all space between and around the arms transparent. Only the glyph belongs in the sprite.

## Registration

From `games/relic-rush`, crop the glyph and center it in its atlas cell.

```python
from PIL import Image

source = Image.open("art/popup-close/source.png").convert("RGBA")
glyph = source.crop((198, 219, 1053, 1069))
glyph.thumbnail((102, 102), Image.Resampling.LANCZOS)
frame = Image.new("RGBA", (128, 128))
frame.paste(glyph, ((128 - glyph.width) // 2, (128 - glyph.height) // 2))
frame.save("art/registered/board-states/action-close.png")
```

Run `python3 tools/match3_atlas.py` from the repository root to repack `action-close` into `data/board/pieces.png`.
