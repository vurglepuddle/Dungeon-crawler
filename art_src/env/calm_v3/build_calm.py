"""Painted quiet stone + editable native wear/water; new filenames throughout."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'room_faces'))
import hashlib
import json
from PIL import Image,ImageDraw
from pipeline import ROOT,RGB,NEAREST,indexed,reduce,save,contact,manifest
from build_faces import decorate
from selection import FLOOR_WEIGHTS,CEILING_WEIGHTS,pick,mix_hash

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/env'
RING = ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64))
PUDDLES = {
    'wet_small': [[(11,40),(15,38),(20,39),(23,42),(20,45),(14,45),(10,43)]],
    'wet_hook': [[(8,17),(14,14),(20,16),(23,21),(20,25),(15,26),(15,31),(23,32),(27,36),
        (22,40),(13,39),(8,34),(7,27),(10,24)]],
    'wet_corner': [[(35,41),(42,37),(49,40),(52,45),(58,47),(58,53),(53,57),(45,59),
        (37,56),(32,52),(31,46)]],
    'wet_split': [[(10,10),(17,8),(23,12),(21,17),(15,19),(9,16)],
        [(36,29),(43,27),(49,31),(51,37),(46,42),(38,40),(34,35)]],
    'wet_wide': [[(19,24),(26,20),(32,22),(37,19),(45,22),(50,28),(55,31),(53,36),
        (47,37),(44,43),(36,45),(29,40),(22,42),(17,38),(13,36),(15,29)]],
}


def quiet_pixels(im,passes=2):
    # Remove isolated grey flecks while retaining painted mortar/stone outlines.
    greys = {4,5,6,7,8}
    for _ in range(passes):
        old = im.copy()
        for y in range(3,61):
            for x in range(3,61):
                ink = old.getpixel((x,y))
                if ink not in greys:
                    continue
                neighbours = [old.getpixel((x+dx,y+dy)) for dy in (-1,0,1) for dx in (-1,0,1)]
                values = sorted(v for v in neighbours if v in greys)
                if len(values)>=7:
                    im.putpixel((x,y),values[len(values)//2])
    return im


def edges(im,floor=False):
    if floor:
        for y in range(64):
            for x in range(64):
                if min(x,y,63-x,63-y)<2:
                    im.putpixel((x,y),2 if (x*3+y*5)%13 else 3)
    for y in range(64):
        ink = im.getpixel((0,y))
        im.putpixel((63,y),ink)
    for x in range(64):
        ink = im.getpixel((x,0))
        im.putpixel((x,63),ink)
    im.putpixel((63,63),im.getpixel((0,0)))
    return im


def shared_floor():
    im = quiet_pixels(reduce(Image.open(BASE/'sources/floor.png'),(64,64)),2)
    compress = {4:5,8:7,9:7,10:8,24:28,25:29}
    im.putdata([compress.get(i,i) for i in im.getdata()])
    return edges(im,True)


def keep_ring(im,base):
    for box in RING:
        im.paste(base.crop(box),box[:2])
    return im


def floor_variant(base,kind):
    im = base.copy()
    if kind in ('dry_b','dry_c'):
        im = base.transpose(Image.Transpose.FLIP_LEFT_RIGHT if kind=='dry_b' else Image.Transpose.ROTATE_180)
    d = ImageDraw.Draw(im)
    if kind=='stain':
        mask = Image.new('1',(64,64));md = ImageDraw.Draw(mask)
        md.polygon([(35,10),(43,9),(48,15),(46,21),(38,23),(31,18)],fill=1)
        for y in range(9,24):
            for x in range(30,49):
                if mask.getpixel((x,y)) and im.getpixel((x,y)) in (5,6,7):
                    im.putpixel((x,y),{5:27,6:28,7:29}[im.getpixel((x,y))])
    elif kind=='chip':
        d.polygon([(45,34),(51,32),(54,36),(50,39),(46,38)],fill=4)
        d.line([(46,34),(50,33),(52,35)],fill=7)
    elif kind=='crack':
        d.line([(13,13),(18,18),(19,23),(24,27),(24,32)],fill=3)
        d.line([(19,23),(14,25),(11,29)],fill=4)
    elif kind in PUDDLES:
        mask = Image.new('1',(64,64));md = ImageDraw.Draw(mask)
        for polygon in PUDDLES[kind]:
            md.polygon(polygon,fill=1)
        wet = {1:1,2:2,3:11,4:12,5:12,6:13,7:14,8:14,11:11,12:12,13:13,14:14,
            18:11,19:11,20:12,21:12,22:13,23:13,24:14,25:14,26:14,27:12,28:13,29:14,30:11,31:12}
        for y in range(4,60):
            for x in range(4,60):
                if mask.getpixel((x,y)):
                    im.putpixel((x,y),wet.get(base.getpixel((x,y)),13))
        # Broken, restrained reflections move with each distinct basin shape.
        marks = {'wet_small':[(15,41,18,41)],'wet_hook':[(11,20,16,20),(16,35,20,35)],
            'wet_corner':[(40,46,45,46),(47,52,51,52)],
            'wet_split':[(13,13,16,13),(40,33,44,33)],
            'wet_wide':[(25,28,31,28),(39,35,43,35),(34,39,36,39)]}
        for mark in marks[kind]:
            d.line(mark,fill=14)
    return keep_ring(im,base)


def ceiling_variants():
    base = quiet_pixels(reduce(Image.open(BASE/'sources/ceiling.png'),(64,64)),1)
    # The edited painting establishes the subdued values; no extra runtime veil.
    edges(base)
    root = base.copy();d = ImageDraw.Draw(root)
    for path in ([(50,8),(48,13),(42,16),(40,22)],[(47,14),(54,19),(55,25)]):
        d.line(path,fill=1,width=2)
        d.line([(x-1,y) for x,y in path],fill=18)
    drip = base.copy()
    for x,y in ((15,40),(16,41),(16,42),(17,43),(17,44),(17,45),(18,46),(18,47),(19,48)):
        ink = drip.getpixel((x,y))
        drip.putpixel((x,y),{3:11,4:12,5:13,6:13,7:14}.get(ink,ink))
    return {'plain':base,'root':keep_ring(root,base),'drip':keep_ring(drip,base)}


def main():
    base = shared_floor()
    floors = {kind:floor_variant(base,kind) for kind in
        ('dry_a','dry_b','dry_c','stain','chip','crack','wet_small','wet_hook','wet_corner','wet_split','wet_wide')}
    ceilings = ceiling_variants()
    materials = {f'calm_v3_floor_{kind}':im for kind,im in floors.items()}
    materials.update({f'calm_v3_ceiling_{kind}':im for kind,im in ceilings.items()})
    # Matching landmark alternatives keep A's earlier room-face options usable.
    for plane,kinds,substrate in [('floor',('drain','cracked','compass'),base),
            ('ceiling',('roots','chain','boss'),ceilings['plain'])]:
        for kind in kinds:
            image = floor_variant(base,'crack') if kind=='cracked' else (
                ceilings['root'].copy() if kind=='roots' else decorate(substrate,f'{plane}_{kind}',1))
            if plane=='ceiling':
                dark = {8:5,7:5,6:4,5:3,4:3}
                for y in range(3,61):
                    for x in range(3,61):
                        if image.getpixel((x,y))!=substrate.getpixel((x,y)):
                            image.putpixel((x,y),dark.get(image.getpixel((x,y)),image.getpixel((x,y))))
            materials[f'calm_v3_room_{plane}_{kind}'] = keep_ring(image,substrate)
    for name,image in materials.items():
        save(image,OUT/f'{name}.png')
    contact({name.removeprefix('calm_v3_'):im for name,im in materials.items()},BASE,
        columns=4,cell=(164,100),title='UNDERCROFT / QUIETER STONE, SAME FAMILY')
    for group,images in [('floors',floors),('ceilings',ceilings)]:
        folder = BASE/group;folder.mkdir(exist_ok=True)
        contact(images,folder,columns=4 if group=='floors' else 3,cell=(128,98),title=group.upper()+' / SHARED BETWEEN FLOORS')
    for floor in (1,2):
        repeat = indexed((320,256),1)
        for y in range(4):
            for x in range(5):
                kind = pick('BELL42',floor,'floor',x+8,y+8)
                repeat.paste(floors[kind],(x*64,y*64))
        save(repeat,BASE/f'floor{floor}_mixed_native.png')
        save(repeat.resize((1280,1024),NEAREST),BASE/f'floor{floor}_mixed_4x.png')
    samples = [{'seed':'BELL42','floor':floor,'plane':plane,'x':x,'y':y,
        'hash':mix_hash(f'BELL42/{floor}/{plane}/{x}/{y}'),'kind':pick('BELL42',floor,plane,x,y)}
        for floor in (1,2) for plane in ('floor','ceiling') for x,y in ((10,10),(10,9),(-1,5))]
    (BASE/'selection.json').write_text(json.dumps({'schema_version':1,'hash':'PresentationArt.mix_hash',
        'key':'{seed}/{floor}/{plane}/{cell_x}/{cell_y}','roll':'hash % 100',
        'floor_weights':FLOOR_WEIGHTS,'ceiling_weights':CEILING_WEIGHTS,'reference_samples':samples},indent=2)+'\n')
    manifest([OUT/f'{name}.png' for name in materials]+[p for p in BASE.rglob('*.png')
        if 'sources' not in p.parts and not p.name.startswith('mockup_')],BASE/'manifest.json',
        {'shared_between_floors':True,'floor_names':list(floors),'ceiling_names':list(ceilings),
         'selection':'art_src/env/calm_v3/selection.json','cell_world_size':1,
         'originals':'art_src/env/calm_v3/preserved_hashes.json'})
    print('Built 11 shared floor variants, 3 subdued vaults and 6 matching landmarks.')


if __name__=='__main__':
    main()
