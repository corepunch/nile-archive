"""Recreate the SDL color-key atlas from the accepted building cutouts."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent.parent
atlas=Image.new('RGB',(1280,256),(255,0,255))
for i in range(5):
    sprite=Image.open(root/'assets'/f'building-{i}.png').convert('RGBA')
    sprite.thumbnail((248,248),Image.Resampling.LANCZOS)
    alpha=sprite.getchannel('A').point(lambda x:255 if x>=180 else 0)
    atlas.paste(sprite.convert('RGB'),(i*256+(256-sprite.width)//2,252-sprite.height),alpha)
atlas.save(root/'atlas.bmp')
