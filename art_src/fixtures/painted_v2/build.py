"""Offline painted fixture replacements. Sources/accepted art are read-only.

Run: python -B art_src/fixtures/painted_v2/build.py
Pillow + numpy; NEAREST, the shared 31 opaque inks, binary transparency.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageOps
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'anim'))
from pipeline import ROOT, RGB, TABLE, NEAREST, canvas, contact, label, manifest, paste, reduce, save

BASE = Path(__file__).resolve().parent
SOURCE = BASE / 'sources'
OUT = ROOT / 'assets/art/fixtures'
SIZES = [64, 40, 24]
PLATE_SIZES = [(64, 20), (40, 12), (24, 8)]
LEVER_SIZES = [(32, 40), (20, 26), (12, 16)]
CORD_SIZES = [(32, 48), (20, 30), (12, 18)]
ASSETS, INPUTS = [], set()
FRAMES = {}
CACHE_PATCH = (14, 22, 51, 52)  # old cavity x14..50, y22..51, exclusive right/bottom
DEEP = {1:1, 2:2, 3:3, 4:3, 5:4, 6:5, 7:6, 8:7, 9:8, 10:9,
        11:11, 12:11, 13:12, 14:13, 15:14, 16:15, 17:16,
        18:18, 19:18, 20:19, 21:20, 22:21, 23:22, 24:23, 25:24,
        26:25, 27:18, 28:27, 29:28, 30:2, 31:30}


def read(path):
    path = Path(path)
    INPUTS.add(path)
    return Image.open(path).copy()


def cell(name, index=0, count=1):
    im = read(SOURCE / f'{name}.png').convert('RGBA')
    return im.crop((round(im.width*index/count), 0, round(im.width*(index+1)/count), im.height))


def inked(im):
    return im if im.mode == 'P' and im.getpalette() == TABLE else reduce(im)


def fit(im, size, margin=0):
    alpha = im.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    box = alpha.getbbox()
    assert box, 'Empty painting'
    return reduce(im.crop(box).resize((size[0]-2*margin, size[1]-2*margin), NEAREST))


def deep(im, warm=False):
    out = im.copy()
    out.putdata([i if warm and i in [10, 24, 25, 26] else DEEP.get(i, i) for i in im.getdata()])
    return out


def border(im, reference):
    for box in [(0,0,64,2), (0,62,64,64), (0,0,2,64), (62,0,64,64)]:
        im.paste(reference.crop(box), box[:2])


def output(im, name, anchor, **meta):
    record = save(im, OUT/f'fixture_v2_{name}.png')
    record.update(anchor=list(anchor), opaque_bounds=list(im.getbbox()), **meta)
    ASSETS.append(record)
    FRAMES[name] = im
    return im


def projection(source, size, right=False):
    """Match old side canvases; keep the fixture's physical attachment anchor."""
    w, h = size
    out = canvas(size)
    for x in range(w):
        u = x/(w-1)
        top, bottom = h*.16*u, h-1-h*.16*u
        for y in range(h):
            if top <= y <= bottom:
                sy = min(source.height-1, max(0, round((y-top)/(bottom-top)*(source.height-1))))
                out.putpixel((x,y), source.getpixel((round(u*(source.width-1)),sy)))
    return ImageOps.mirror(out) if right else out


def plates():
    sources = [cell('plate', i, 2) for i in range(2)]
    master = [fit(im, PLATE_SIZES[0]) for im in sources]
    # Keep the mounting stones registered. Only the inset slab drops inside it.
    pressed = master[0].copy()
    pressed.paste(master[1].crop((12, 3, 52, 16)), (12, 3))
    # Native seam cleanup: the pressed slab drops one row and loses the bright
    # upper lip while the surrounding mounting flags remain immobile.
    inset=pressed.crop((13,3,51,15))
    inset.putdata([{8:7,9:8,10:9,7:6}.get(i,i) for i in inset.getdata()])
    pressed.paste(inset,(13,4))
    ImageDraw.Draw(pressed).line((13,3,50,3),fill=1)
    master[1] = pressed
    for floor in [1, 2]:
        for state, frame in zip(['up', 'down'], master):
            frame = frame if floor == 1 else deep(frame)
            for d, size in enumerate(PLATE_SIZES, 1):
                out = frame.resize(size, NEAREST)
                output(out, f'f{floor}_plate_{state}_d{d}', (size[0]//2,size[1]),
                       kind='plate', floor=floor, depth=d, state=state, frame_ms=0,
                       shadow='none; sunk slab seam is painted, no floating ellipse',
                       replaces=f'assets/art/fx/plate_{state}_d{d}.png')


def levers():
    for state in ['up', 'down']:
        front = inked(read(OUT/f'lever_front_{state}_d1.png'))
        for d, size in enumerate(LEVER_SIZES, 1):
            for side in ['left', 'right']:
                right = side == 'right'
                anchor = [size[0]//2-int(right), [22,14,8][d-1]]
                output(projection(front, size, right), f'lever_{side}_{state}_d{d}', anchor,
                       kind='lever', floor='both; normal scene lighting', depth=d, state=state,
                       projection=side, anchor_kind='wall hinge', frame_ms=0,
                       replaces=f'assets/art/fx/lever_{side}_{state}_d{d}.png')


def web():
    intact = reduce(cell('web').resize((64,64), NEAREST))
    burning = [reduce(cell('web_burning', i, 2).resize((64,64), NEAREST)) for i in range(2)]
    # Keep the same non-burning web outside the central ignition region.
    # The source pair supplies actual painted flame shapes/material, not code flames.
    fire_mask = Image.new('L', (64,64), 0)
    ImageDraw.Draw(fire_mask).polygon([(9,39),(14,19),(29,10),(51,19),(57,39),(47,59),(17,60)], fill=255)
    for i in range(2):
        stable = intact.copy()
        stable.paste(burning[i], (0,0), fire_mask)
        burning[i] = stable
    burnt = reduce(cell('web_burnt').resize((64,64), NEAREST))
    ImageDraw.Draw(burnt).rectangle((10,8,53,63), fill=0)
    for state, frame in [('intact',intact), ('burning_0',burning[0]), ('burning_1',burning[1]), ('burnt',burnt)]:
        for d, h in enumerate(SIZES, 1):
            output(frame.resize((h,h),NEAREST), f'web_{state}_d{d}', (h//2,h),
                   kind='web', floor='both; normal scene lighting', depth=d, state=state,
                   wall_uv=True, wall_uv_origin=[0,0], frame_ms=120 if state.startswith('burning') else 0,
                   replaces=f'assets/art/fixtures/web_{state}_d{d}.png',
                   alpha='true gaps; no opaque backdrop')


def cord():
    for state, index in [('intact',0), ('cut',1)]:
        frame = fit(cell('cord', index, 2), (64,64))
        if state == 'cut':
            # Guarantees a clear passage below the lifted grate, not black iron.
            ImageDraw.Draw(frame).rectangle((11,25,52,58), fill=0)
        for d, h in enumerate(SIZES, 1):
            output(frame.resize((h,h),NEAREST), f'cord_grate_{state}_d{d}', (h//2,h),
                   kind='cord_grate', floor='both; normal scene lighting', depth=d, state=state,
                   frame_ms=0, wall_uv=True, wall_uv_origin=[0,0],
                   replaces=f'assets/art/fixtures/cord_grate_{state}_d{d}.png')
            size = CORD_SIZES[d-1]
            for side in ['left','right']:
                right = side == 'right'
                output(projection(frame,size,right), f'cord_grate_{side}_{state}_d{d}',
                       (size[0]//2-int(right),size[1]//2), kind='cord_grate',
                       floor='both; normal scene lighting', depth=d, state=state, projection=side,
                       frame_ms=0, anchor_kind='wall centre',
                       replaces=f'assets/art/fixtures/cord_grate_{side}_{state}_d{d}.png')


def ground():
    reference = inked(read(ROOT/'assets/art/env/calm_v3_floor_dry_a.png'))
    sources = {'lift_dead':cell('lift_floor',0,2), 'lift_working':cell('lift_floor',1,2),
               'stairs_down':cell('stairs_floor')}
    for kind, source in sources.items():
        master = reduce(source.resize((64,64),NEAREST))
        for floor in [1,2]:
            frame = master.copy() if floor == 1 else deep(master, kind == 'lift_working')
            border(frame, reference)
            output(frame, f'f{floor}_floor_{kind}_64', (0,0), kind='underfoot_floor',
                   fixture=kind, floor=floor, frame_ms=0, wall_uv=False,
                   projection='horizontal world floor UV; one tile per movement cell',
                   canonical_direction='north / negative world V', border_ring_px=2,
                   replaces='fixture-cell floor override before PlaneMaterials.path(); no sprite')


def cache():
    # Register the entire painted chipped lip/cavity/shelf to the original UV
    # opening. A direct wall-coordinate crop would cut away its side bevels.
    source = reduce(cell('cache').resize((64,64),NEAREST)).crop((6,20,58,50)).resize((37,30),NEAREST)
    for floor in [1,2]:
        wall = inked(read(ROOT/f'assets/art/env/painted_f{floor}_plain_0.png'))
        patch = source if floor == 1 else deep(source)
        face, overlay = wall.copy(), canvas((64,64))
        face.paste(patch,CACHE_PATCH[:2])
        overlay.paste(patch,CACHE_PATCH[:2])
        for variant, frame in [('open',face), ('open_overlay',overlay)]:
            output(frame, f'f{floor}_cache_{variant}_64', (0,0), kind='cache', floor=floor,
                   state='open', frame_ms=0, wall_uv=True, patch=list(CACHE_PATCH),
                   replaces='open panel runtime rectangle; use full face OR overlay, once')


def coat_icon():
    original = inked(read(ROOT/'assets/art/icons/coat.png'))
    icon = original.copy()
    # Keep C's 16px garment silhouette, ochre opening and dark outline. The old
    # painted spent garment supplies mottled cloth material inside that glyph.
    source = read(ROOT/'art_src/items/sources/coat.png').convert('RGBA')
    source = source.crop((source.width//2,0,source.width,source.height))
    source = source.crop(source.getbbox())
    fabric = reduce(source.resize((16,16),NEAREST))
    for y in range(16):
        for x in range(16):
            ink = original.getpixel((x,y))
            if ink in [12,13,14,15,16]:
                material = fabric.getpixel((x,y))
                icon.putpixel((x,y),material if material in [11,12,13,14,15,16,17] else 13)
    d = ImageDraw.Draw(icon)
    # Crisp, deliberately large tears and pale stuffing: distinct at 1x.
    d.line((4,6,7,9),fill=1)
    d.line((10,9,12,7),fill=1)
    for x,y,ink in [(4,5,8),(5,6,10),(6,7,9),(11,8,9),(12,8,8),
                    (4,13,8),(5,13,10),(10,13,9),(11,12,8)]:
        d.point((x,y),fill=ink)
    for xy in [(3,12),(4,14),(6,14),(10,14),(12,13)]:d.point(xy,fill=0)
    record = save(icon, ROOT/'assets/art/icons/coat_spent.png')
    record.update(kind='inventory_icon', state='spent', anchor=[8,8], frame_ms=0,
                  replaces='coat inventory lookup when item.spent is true; keep ordinary coat icon')
    ASSETS.append(record)
    FRAMES['coat_spent_icon'] = icon


SHADE = {}
def shade(ink, amount):
    key = ink,round(amount,3)
    if key not in SHADE:
        r,g,b = [v*amount for v in RGB[ink]]
        SHADE[key] = min(range(1,32),key=lambda i:2*(r-RGB[i][0])**2+4*(g-RGB[i][1])**2+(b-RGB[i][2])**2)
    return SHADE[key]


def sample_uv(direction, u, v):
    """World-locked orientation; facing affects rays, NEVER this binding."""
    if u<2 or u>=62 or v<2 or v>=62:return u,v
    return {'N':(u,v), 'E':(v,63-u), 'S':(63-u,63-v), 'W':(63-v,u)}[direction]


def oriented(tile,direction):
    out=tile.copy()
    for v in range(64):
        for u in range(64):out.putpixel((u,v),tile.getpixel(sample_uv(direction,u,v)))
    return out


def room(floor, face=None, floor_tile=None, origin=(.5,2.65), direction='N', portal=None, floor_cell=None):
    """Offline 148x150 review ray cast; actual calm_v3 plane family/lamp math."""
    wall = inked(read(ROOT/f'assets/art/env/painted_f{floor}_plain_0.png'))
    ground = inked(read(ROOT/'assets/art/env/calm_v3_floor_dry_a.png'))
    roof = inked(read(ROOT/'assets/art/env/calm_v3_ceiling_plain.png'))
    out = canvas((148,150),1)
    # North-facing corridor x[-1,2], north wall y=0, player at x=.5.
    for y in range(150):
        depth = 37/(abs(y-71)+.5)
        if depth >= 3.6:continue
        for x in range(148):
            px = origin[0]+(x+.5-74)/74*depth
            py = origin[1]-depth
            u,v = math.floor(px*64)%64,math.floor(py*64)%64
            tile = ground
            if y <= 71:tile=roof
            elif floor_tile is not None and (math.floor(px),math.floor(py)) == (floor_cell if floor_cell is not None else (math.floor(origin[0]),math.floor(origin[1]))):
                tile = floor_tile
                u,v = sample_uv(direction,u,v)
            out.putpixel((x,y),shade(tile.getpixel((u,v)),max(0,min(1,(3.6-depth)/2.7))*(.86 if y>71 else .64)))
    for x in range(148):
        ray = (x+.5-74)/74
        side = (1.5/abs(ray)) if ray else 10000
        depth = min(side,origin[1])
        h = max(1,round(74/depth));top=71-h//2
        u = math.floor(((origin[1]-depth)%1 if side<origin[1] else origin[0]+ray*depth)*64)%64
        target = face if face is not None and side>=origin[1] and 0<=origin[0]+ray*depth<1 else wall
        for y in range(max(0,top),min(150,top+h)):
            v = min(63,int((y-top)*64/h))
            out.putpixel((x,y),shade(target.getpixel((u,v)),max(0,min(1,(3.6-depth)/2.7))*(.78 if side<origin[1] else 1)))
    if portal is not None:
        # Portal texture sampled on a world-space wall plane with real gaps.
        depth=1.6;h=round(74/depth);w=h;top=71-h//2;left=74-w//2
        tex=portal.resize((w,h),NEAREST)
        tex.putdata([shade(i,max(0,min(1,(3.6-depth)/2.7))) if i else 0 for i in tex.getdata()])
        paste(out,tex,(left,top))
    return out


def place(out, frame, depth, lateral=0):
    y=71+round(37/depth)
    sprite=frame.copy()
    sprite.putdata([shade(i,max(.18,min(1,(3.6-depth)/2.7))) if i else 0 for i in frame.getdata()])
    paste(out,sprite,(round(74+74*lateral/depth)-sprite.width//2,y-sprite.height))


def review(name, im):
    save(im,BASE/f'{name}_native.png')
    save(im.resize((im.width*4,im.height*4),NEAREST),BASE/f'{name}_4x.png')


def panels(name, title, views, cols=3):
    out=canvas((8+156*cols,28+178*math.ceil(len(views)/cols)),1)
    label(out,(8,4),title,25)
    for index,(caption,view) in enumerate(views):
        x,y=8+(index%cols)*156,28+(index//cols)*178
        paste(out,view,(x,y));label(out,(x,y+151),caption)
    review(name,out)


def reviews():
    contact(BASE/'plates_contact_4x.png','PAINTED / SUNK PRESSURE PLATE',[
        (f'Floor {f} / depth {d}',[(s,FRAMES[f'f{f}_plate_{s}_d{d}']) for s in ['up','down']])
        for f in [1,2] for d in [1,2,3]])
    contact(BASE/'levers_contact_4x.png','PAINTED / SAME HINGE AND PLATE',[
        (f'{s} / depth {d}', [('front',inked(read(OUT/f'lever_front_{s}_d{d}.png')))]+
         [(side,FRAMES[f'lever_{side}_{s}_d{d}']) for side in ['left','right']])
        for s in ['up','down'] for d in [1,2,3]])
    contact(BASE/'web_contact_4x.png','PAINTED / SILK AND FIRE',[
        (f'Depth {d} / 120ms fire',[(s.replace('burning','fire'),FRAMES[f'web_{s}_d{d}']) for s in ['intact','burning_0','burning_1','burnt']]) for d in [1,2,3]])
    contact(BASE/'cord_contact_4x.png','PAINTED / EDGE CORD GRATE',[
        (f'{s} / depth {d}', [('front',FRAMES[f'cord_grate_{s}_d{d}'])]+
         [(side,FRAMES[f'cord_grate_{side}_{s}_d{d}']) for side in ['left','right']])
        for s in ['intact','cut'] for d in [1,2,3]])
    contact(BASE/'ground_contact_4x.png','PAINTED / WORLD FLOOR UV',[
        (f'Floor {f} / north at top',[(k.replace('lift_',''),FRAMES[f'f{f}_floor_{k}_64']) for k in ['lift_dead','lift_working','stairs_down']]) for f in [1,2]])
    contact(BASE/'cache_contact_4x.png','PAINTED / OPEN SECRET CACHE',[
        (f'Floor {f}',[('wall',FRAMES[f'f{f}_cache_open_64']),('patch',FRAMES[f'f{f}_cache_open_overlay_64'])]) for f in [1,2]])
    contact(BASE/'coat_spent_contact_4x.png','COAT / SPENT ICON AND WORLD',[
        ('Inventory / keep C silhouette',[('padded',inked(read(ROOT/'assets/art/icons/coat.png'))),('spent',FRAMES['coat_spent_icon'])]),
        ('World identity',[('padded',inked(read(ROOT/'assets/art/items/item_coat_d1.png'))),('spent',inked(read(ROOT/'assets/art/items/item_coat_spent_d1.png')))])])
    views=[]
    for floor in [1,2]:
        for state in ['up','down']:
            view=room(floor)
            for d,depth,lateral in [(3,2.6,-.30),(2,1.9,.35),(1,.95,-.15)]:
                place(view,FRAMES[f'f{floor}_plate_{state}_d{d}'],depth,lateral)
            # Painted side lever on the left, using its existing fixed hinge.
            side=FRAMES[f'lever_left_{state}_d1'];paste(view,side,(8,53))
            views.append((f'F{floor} plates {state}',view))
        for state in ['intact','cut']:
            views.append((f'F{floor} cord {state}',room(floor,portal=FRAMES[f'cord_grate_{state}_d1'])))
        views.append((f'F{floor} open cache',room(floor,FRAMES[f'f{floor}_cache_open_64'],origin=(.5,1.15))))
        views.append((f'F{floor} dusty web',room(floor,portal=FRAMES['web_intact_d1'])))
    panels('corridor_fixtures','Fixture corridor / real lamp falloff',views)
    views=[]
    for floor in [1,2]:
        for kind in ['lift_dead','lift_working','stairs_down']:
            face_name = f'architecture_v2_f{floor}_lift_dead_64.png' if kind=='lift_dead' else f'architecture_f{floor}_lift_working_64.png' if kind=='lift_working' else f'architecture_v3_f{floor}_stairs_down_64.png'
            face=inked(read(OUT/face_name))
            views.append((f'F{floor} approach {kind[5:] if kind.startswith("lift_") else "stair"}',room(floor,face,FRAMES[f'f{floor}_floor_{kind}_64'],origin=(.5,2.5),floor_cell=(0,1))))
        for kind in ['lift_dead','lift_working','stairs_down']:
            face_name = f'architecture_v2_f{floor}_lift_dead_64.png' if kind=='lift_dead' else f'architecture_f{floor}_lift_working_64.png' if kind=='lift_working' else f'architecture_v3_f{floor}_stairs_down_64.png'
            face=inked(read(OUT/face_name))
            views.append((f'F{floor} inside {kind[5:] if kind.startswith("lift_") else "stair"}',room(floor,face,FRAMES[f'f{floor}_floor_{kind}_64'],origin=(.5,1.5),floor_cell=(0,1))))
    panels('underfoot_corridor','Lift / stair ground: approach then underfoot',views)
    contact(BASE/'ground_orientations_4x.png','FLOOR / FIXED PHYSICAL TRAVEL',[
        (kind,[(direction,oriented(FRAMES[f'f1_floor_{kind}_64'],direction)) for direction in ['N','E','S','W']])
        for kind in ['lift_dead','lift_working','stairs_down']])


def main():
    plates();levers();web();cord();ground();cache();coat_icon();reviews()
    manifest(BASE/'manifest.json',{'assets':ASSETS,
        'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(INPUTS)},
        'palette':'art_src/spike/palette.gpl', 'alpha':'index0 transparent, indices1..31 opaque',
        'cache_patch':list(CACHE_PATCH), 'floor_uv':'64px/cell; U=east,V=south; physical travel north in source',
        'notes':'No Godot or gameplay files changed. Existing sources/assets kept. See ART.md for exact swaps.'})
    print(f'Painted fixtures v2: {len(ASSETS)} runtime PNGs, ten exact 4x review sheets')


if __name__ == '__main__':main()
