"""Static native-asset compositions for cannons, chameleons and wheel slices."""
import hashlib
import json
from PIL import Image, ImageChops
from materials import render_crate, sample
from skeleton import read_setup, read_atlas, render_setup

COLORS = (1, 2, 3, 4, 5, 6, 9)


def registered(sprite, bitmap=None, size=256, scale=1):
    """Restore the original trimmed sprite around its authored pivot."""
    bitmap = (bitmap if bitmap is not None else sprite.image).convert('RGBA')
    rect, offset, pivot = sprite.m_Rect, sprite.m_RD.textureRectOffset, sprite.m_Pivot
    unit = size / rect.width * scale
    left = size/2 + (offset.x-pivot.x*rect.width)*unit
    top = size/2 - (offset.y+bitmap.height-pivot.y*rect.height)*unit
    bitmap = bitmap.resize((round(bitmap.width*unit), round(bitmap.height*unit)), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size,size))
    result.alpha_composite(bitmap, (round(left),round(top)))
    return result


def cannon_image(scene, color, charge, size=256):
    """Sprite tint + stencil-clipped moving cover + original face.

    Charge is exact. The cover's travel is fitted to the native mask bounds;
    private native minYPos/chargeRange initializers are unavailable (see ART.md).
    """
    tint = scene.objects[2270].read_typetree()['colors'][color]
    sprite = scene.objects[594].read()
    source = sprite.image.convert('RGBA')
    channels = source.split()
    source = Image.merge('RGBA', tuple(channels[i].point(lambda v: round(v*tint[k]))
                                      for i,k in enumerate(('r','g','b','a'))))
    result = registered(sprite, source, size)
    mask = registered(scene.objects[604].read(), size=size, scale=1.06).getchannel('A').point(lambda a: 255 if a >= 26 else 0)
    cover = registered(scene.objects[600].read(), size=size)
    bounds = mask.getbbox()
    bottom = cover.getchannel('A').getbbox()[3]
    desired = bounds[3] - (bounds[3]-bounds[1])*charge/45
    moved = Image.new('RGBA', result.size)
    moved.alpha_composite(cover, (0, round(desired-bottom)))
    moved.putalpha(ImageChops.multiply(moved.getchannel('A'), mask))
    result.alpha_composite(moved)
    result.alpha_composite(registered(scene.objects[653].read(), size=size))
    return result


def chameleon_atlas(source, mask, lut, current, next_color):
    """Unlit/Unlit-RecolorLUT; output straight-alpha equivalent of Metal RGB*A."""
    source, mask, lut = [im.convert('RGBA') for im in (source,mask,lut)]
    mask = mask.resize(source.size, Image.Resampling.BILINEAR)
    palettes = [[sample(lut,c/10+.05,max(.02,min(.98,v/255)))[:3] for v in range(256)]
                for c in (current,next_color)]
    result = Image.new('RGBA',source.size)
    pixels = []
    for (red,green,blue,alpha),(mr,mg,_,_) in zip(source.getdata(),mask.getdata()):
        grey = max(.02,min(.98,red/255))
        base = (grey,green/255,blue/255)
        colored = [palettes[1][red][k]*(1-mr/255)+palettes[0][red][k]*mr/255 for k in range(3)]
        pixels.append(tuple(round(255*(base[k]*(1-mg/255)+colored[k]*mg/255)) for k in range(3))+(alpha,))
    result.putdata(pixels)
    return result


def extract_mechanics(scene, output, manifest, material_sources):
    import lz4.block
    evidence = output / 'shader-evidence'
    def save(name, image, **metadata):
        target = output / 'sprites' / f'{name}.png'
        image.save(target)
        manifest[name] = dict(url=f'/art/{name}.png', file=scene.name, kind='MaterialRender',
                              width=image.width, height=image.height,
                              sha256=hashlib.sha256(target.read_bytes()).hexdigest(), **metadata)
    hashes = {}
    for name, mid in [('cannon_stencil',90),('chameleon',85),('color_wheel',96)]:
        material = scene.objects[mid].read()
        shader = material.m_Shader.read()
        decoded = lz4.block.decompress(bytes(shader.compressedBlob), uncompressed_size=shader.decompressedLengths[0][0])
        (evidence / f'{name}.decoded').write_bytes(decoded)
        hashes[name] = hashlib.sha256(decoded).hexdigest()
        material_sources[name] = dict(shader=shader.m_ParsedForm.m_Name, sha256=hashes[name])
    for object_id in [2270,2279,2302,2342,2187,2283,90,91]:
        (evidence / f'mechanic-{object_id}.json').write_text(json.dumps(scene.objects[object_id].read_typetree(),indent=2)+'\n')
    for color in (0,*COLORS):
        for charge in (0,15,30,45):
            save(f'material_cannon_{color}_{charge}',cannon_image(scene,color,charge),
                 sprite_ids=[594,600,604,653], material_ids=[90,91], color_map_id=2270,
                 color=color, charge=charge, max_charge=45, shader_sha256=hashes['cannon_stencil'],
                 gauge_geometry='Cover travel fitted to mask bounds; native private travel constants unavailable')
    wheel_lut = scene.objects[285].read().image
    for n, piece, frame in [(3,651,657),(4,661,598),(5,689,677),(6,679,692)]:
        save(f'material_wheel_frame_{n}',registered(scene.objects[frame].read()), sprite_id=frame)
        for color in COLORS:
            sprite = scene.objects[piece].read()
            save(f'material_wheel_piece_{n}_{color}',registered(sprite,render_crate(sprite.image,wheel_lut,color)),
                 sprite_id=piece,material_id=96,lut_id=285,color=color,segments=n,
                 shader_sha256=hashes['color_wheel'])
    for name, sid in [('face',599),('background',623)]:
        save(f'material_wheel_{name}',registered(scene.objects[sid].read()),sprite_id=sid)
    skeleton = scene.objects[361].read().m_Script.encode('utf8','surrogateescape')
    atlas_text = scene.objects[353].read().m_Script
    layers, regions = read_setup(skeleton), read_atlas(atlas_text)
    (evidence / 'chameleon.skel').write_bytes(skeleton)
    (evidence / 'chameleon.atlas').write_text(atlas_text)
    source,mask,lut = [scene.objects[i].read().image for i in (279,273,304)]
    for current in COLORS:
        for next_color in COLORS:
            atlas = chameleon_atlas(source,mask,lut,current,next_color)
            save(f'material_chameleon_{current}_{next_color}',render_setup(layers,regions,atlas),
                 material_id=85,texture_id=279,mask_id=273,lut_id=304,skeleton_id=361,atlas_id=353,
                 skeleton_sha256=hashlib.sha256(skeleton).hexdigest(),
                 pose='Blink',time=0,pixels_per_unit=128,current_color=current,next_color=next_color,
                 shader_sha256=hashes['chameleon'])


    # The character prefabs use these exact original Spine animations at t=0.
    for name, skeleton_id, atlas_id, texture_id, animation, y in [
            ('climber',358,360,227,'Idle',-64),
            ('resistant_1',355,354,168,'IdleHp1',0),
            ('resistant_2',355,354,168,'IdleHp2',0),
            ('resistant_3',355,354,168,'IdleHp3',0)]:
        skeleton = scene.objects[skeleton_id].read().m_Script.encode('utf8','surrogateescape')
        atlas_text = scene.objects[atlas_id].read().m_Script
        regions = read_atlas(atlas_text)
        layers = read_setup(skeleton,animation,regions)
        (evidence / f'{name}.skel').write_bytes(skeleton)
        (evidence / f'{name}.atlas').write_text(atlas_text)
        save(f'material_{name}', render_setup(layers,regions,scene.objects[texture_id].read().image,offset_y=y),
             skeleton_id=skeleton_id,atlas_id=atlas_id,texture_id=texture_id,
             skeleton_sha256=hashlib.sha256(skeleton).hexdigest(), pose=animation,time=0,
             pixels_per_unit=128, offset_y_pixels=y,
             attachment_paths=[layer['path'] for layer in layers])


def review_sheet(art):
    """Contact sheet of every cannon/chameleon state and all wheel LUT columns."""
    from PIL import ImageDraw
    entries = []
    for color in (0,*COLORS):
        for charge in (0,15,30,45):
            entries.append((f'C{color} {charge}/45', Image.open(art/f'material_cannon_{color}_{charge}.png').convert('RGBA')))
    for color in COLORS:
        for next_color in COLORS:
            entries.append((f'Ch {color} / {next_color}',Image.open(art/f'material_chameleon_{color}_{next_color}.png').convert('RGBA')))
    for count in range(3,7):
        for start in range(7):
            image = Image.open(art/'material_wheel_background.png').convert('RGBA')
            for i in range(count):
                color = COLORS[(start+i)%7]
                with Image.open(art/f'material_wheel_piece_{count}_{color}.png') as piece:
                    image.alpha_composite(piece.rotate(-i*360/count,Image.Resampling.BICUBIC))
            for name in [f'frame_{count}','face']:
                with Image.open(art/f'material_wheel_{name}.png') as layer:
                    image.alpha_composite(layer)
            entries.append((f'Wheel {count} / C{COLORS[start]}',image))
    sheet = Image.new('RGB',(800,((len(entries)+7)//8)*116),'#435d63')
    draw = ImageDraw.Draw(sheet)
    for i,(label,image) in enumerate(entries):
        x,y = i%8*100,i//8*116
        draw.text((x+3,y+2),label,fill='white')
        image.thumbnail((96,96),Image.Resampling.LANCZOS)
        sheet.paste(image,(x+2,y+18),image)
    return sheet


if __name__ == '__main__':
    import argparse
    from pathlib import Path
    parser = argparse.ArgumentParser(description='Review extracted native mechanic states')
    parser.add_argument('art',type=Path,help='Extracted art/sprites directory')
    parser.add_argument('output',type=Path,help='Review PNG destination')
    args = parser.parse_args()
    review_sheet(args.art).save(args.output)
