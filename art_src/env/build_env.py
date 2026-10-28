"""Quiet painted masonry + integer-pixel dressing. Sources remain untouched.

Run from anywhere: python art_src/env/build_env.py
All wall variants share a two-pixel boundary ring. No runtime randomness.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw
from pipeline import ROOT, NEAREST, RGB, indexed, reduce, save, contact, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/env'

def masonry(floor, variant=0):
    paint = reduce(Image.open(BASE / 'sources' / ('abbey.png' if floor == 1 else 'deep.png')), (64,64))
    im = indexed((64,64), 3 if floor == 1 else 2)
    d = ImageDraw.Draw(im)
    # Torus coordinates: mirrored endpoint samples make mixed tile edges exact.
    for y in range(64):
        v = y if y < 63 else 0
        row = v//16
        for x in range(64):
            u = x if x < 63 else 0
            bx = (u + (16 if row%2 else 0))%32
            by = v%16
            sample = paint.getpixel(((u//3)*3, (v//3)*3))
            # Painted clusters supply surface variation, compressed to quiet shades.
            r,g,b = RGB[sample]
            luminance = (r*2+g*4+b)//7
            ink = (4 if luminance<100 else (5 if luminance<155 else 6)) if floor == 1 else (2 if luminance<40 else (3 if luminance<75 else 4))
            if by in (0,15) or bx in (0,31): ink = 3 if floor == 1 else 2
            elif by == 1: ink = 6 if floor == 1 else 4
            im.putpixel((x,y), ink)
    # Deliberately small variations, entirely inside the shared boundary ring.
    if variant:
        rng = random.Random(5900+floor*90+variant)
        for _ in range(8):
            x,y = rng.randrange(4,54),rng.randrange(4,58)
            if y%16 in (0,1,15): continue
            d.line((x,y,x+rng.randrange(2,6),y), fill=6 if floor==1 else 4)
    return im

def preserve_edges(im, base):
    for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
        im.paste(base.crop(box),box[:2])
    return im

def dressing(base, name, floor):
    im=base.copy(); d=ImageDraw.Draw(im)
    if name.startswith('sconce'):
        # Local restrained halo; stone at the boundary stays unlit.
        d.ellipse((23,12,42,37), fill=27 if floor==1 else 18)
        d.rectangle((29,28,36,48), fill=1); d.rectangle((30,29,35,47),fill=4)
        d.point((31,31),fill=7); d.point((34,44),fill=7)
        d.line([(33,43),(42,37),(41,33)],fill=1,width=4)
        d.line([(33,42),(41,36),(40,33)],fill=28,width=2)
        d.polygon([(33,27),(43,27),(41,33),(35,33)],fill=1)
        d.line((34,28,42,28),fill=29)
        frame=int(name[-1])
        pts=[(36,27),(34,21),(38,15),(39,9),(43,19),(42,25)] if frame==0 else [(36,27),(35,23),(40,17),(41,11),(44,22),(41,27)]
        d.polygon(pts,fill=22); d.polygon([(37,26),(37,21),(40,17+frame*2),(41,23),(40,27)],fill=25)
        d.line((39,23,39,26),fill=10)
    elif name=='crack':
        path=[(26,6),(29,14),(27,21),(33,29),(30,38),(35,46),(33,57)]
        d.line([(x+1,y) for x,y in path], fill=6 if floor==1 else 4)
        d.line(path,fill=1); d.line([(28,20),(21,24),(19,29)],fill=2)
        d.line([(32,30),(40,32),(43,39)],fill=2)
    elif name=='damp':
        d.polygon([(12,3),(30,3),(35,10),(30,21),(26,37),(22,44),(20,26),(16,21)],fill=11)
        d.polygon([(17,4),(28,4),(29,12),(25,21),(22,31),(20,17)],fill=12)
        for x,y in [(18,12),(23,16),(21,24),(26,8),(27,12),(18,19)]:
            d.line((x,y,x+2,y),fill=13 if floor==2 else 27)
        d.line((22,35,22,43),fill=4); d.point((22,44),fill=15)
        d.polygon([(5,57),(15,52),(24,55),(35,51),(49,55),(58,58),(58,61),(5,61)],fill=11)
        d.line([(7,57),(15,54),(23,57),(34,54)],fill=12)
    elif name=='chains':
        for x,start,end in [(22,8,47),(42,6,57)]:
            d.ellipse((x-3,start-3,x+3,start+3),fill=1,outline=5)
            for y in range(start+2,end,6):
                d.ellipse((x-2,y,x+2,y+7),outline=1,width=2)
                d.line((x-1,y+1,x-1,y+4),fill=6 if floor==1 else 5)
                d.point((x+1,y+5),fill=28)
    elif name=='tapestry':
        d.line((13,10,50,10),fill=1,width=3); d.line((13,9,50,9),fill=28)
        d.polygon([(16,12),(47,12),(47,50),(42,48),(37,53),(32,50),(28,54),(23,51),(17,53)],fill=18)
        d.polygon([(18,13),(45,13),(44,48),(38,49),(32,47),(27,50),(20,48)],fill=12 if floor==1 else 11)
        d.line((20,15,43,15),fill=27); d.line((20,16,20,46),fill=27)
        # Faded dawn over a bell: invented abbey imagery, no readable writing.
        d.arc((25,21,39,35),180,360,fill=29,width=2)
        d.line((23,29,41,29),fill=28)
        d.polygon([(29,33),(35,33),(37,40),(39,42),(25,42),(28,39)],fill=27)
        d.line((26,43,38,43),fill=28)
        for x,y in [(24,17),(34,23),(29,39),(40,44),(25,47)]: d.line((x,y,x+2,y+1),fill=18)
    elif name=='drain':
        d.rectangle((13,37,51,59),fill=1,outline=3)
        d.rectangle((14,38,50,58),outline=6 if floor==1 else 4)
        d.rectangle((17,40,47,56),fill=1)
        for x in range(19,48,5):
            d.line((x,41,x,55),fill=4,width=2); d.line((x,41,x,54),fill=5)
        d.line((17,48,47,48),fill=3)
        for x,y in [(15,39),(49,39),(15,57),(49,57)]: d.point((x,y),fill=28)
        if floor==2: d.line([(12,60),(24,59),(32,61),(46,60),(53,61)],fill=12)
    elif name in ('arch','door'):
        d.rounded_rectangle((9,5,54,70),radius=22,fill=2,outline=3,width=2)
        d.rounded_rectangle((13,9,50,71),radius=18,fill=6 if floor==1 else 4)
        d.rounded_rectangle((18,15,45,72),radius=13,fill=1)
        # Voussoir joints; no stone frame extends outside the seam-safe ring.
        for a in range(205,340,23):
            r=math.radians(a)
            d.line((32+int(15*math.cos(r)),29+int(15*math.sin(r)),32+int(20*math.cos(r)),29+int(20*math.sin(r))),fill=3)
        for y in (33,45,56):
            d.line((13,y,17,y),fill=3);d.line((46,y,50,y),fill=3)
        if name=='door':
            d.rounded_rectangle((19,16,44,71),radius=12,fill=18)
            for x in range(21,44,5):
                d.line((x,29,x,60),fill=19); d.line((x+1,28,x+1,60),fill=27)
            for y in (31,50):
                d.rectangle((19,y,44,y+4),fill=2);d.line((20,y,43,y),fill=5)
                for x in (21,29,36,42):d.point((x,y+2),fill=7)
            d.ellipse((36,38,41,44),outline=28);d.point((38,38),fill=9)
            d.rectangle((38,44,39,46),fill=1)
    return preserve_edges(im,base)

def surface(floor, ceiling=False):
    im=indexed((64,64),3 if floor==1 else 2);d=ImageDraw.Draw(im)
    if ceiling:
        d.rectangle((3,3,60,60),fill=4 if floor==1 else 3)
        for x in (0,1,62,63):d.line((x,0,x,63),fill=2)
        for y in (0,1,62,63):d.line((0,y,63,y),fill=2)
        for x in (5,58):d.line((x,4,x,59),fill=5 if floor==1 else 4)
        d.line((5,5,58,5),fill=5 if floor==1 else 4)
        if floor==2:d.polygon([(18,6),(27,6),(31,21),(26,27),(22,18)],fill=11)
    else:
        for y in range(64):
            for x in range(64):
                u=x if x<63 else 0;v=y if y<63 else 0
                # Two unequal flagstones; joins wrap exactly.
                seam=u in (0,1) or v in (0,1) or (v in (31,32)) or (u in (39,40) if v<31 else u in (23,24))
                ink=(3 if floor==1 else 2) if seam else (5 if floor==1 else 3)
                if not seam and (v in (3,34) or u==3):ink=6 if floor==1 else 4
                im.putpixel((x,y),ink)
        d.line([(43,15),(47,19),(45,23),(49,27)],fill=3 if floor==1 else 2)
        if floor==2:
            d.polygon([(29,41),(38,38),(53,42),(57,49),(46,55),(31,52),(26,47)],fill=11)
            d.line([(31,42),(38,40),(49,43)],fill=13)
            d.line((35,49,47,49),fill=12)
    return im

def main():
    all_assets={}
    for floor in (1,2):
        base=masonry(floor)
        assets={f'plain_{i}':preserve_edges(masonry(floor,i),base) for i in range(3)}
        for name in ('sconce_0','sconce_1','crack','damp','chains','tapestry','drain','arch','door'):
            assets[name]=dressing(base,name,floor)
        for name,im in assets.items():
            for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
                assert im.crop(box).tobytes()==base.crop(box).tobytes(), name
        assets['floor']=surface(floor);assets['ceiling']=surface(floor,True)
        for name,im in assets.items():save(im,OUT/f'f{floor}_{name}.png')
        contact(assets,BASE/f'floor{floor}',columns=4,cell=(140,96),title=f'UNDERCROFT / FLOOR {floor}')
        # An actual mixed tile repeat sheet, for seam inspection.
        repeat=indexed((64*4,64*3),1)
        for i,name in enumerate(['plain_0','plain_1','plain_2','plain_0','damp','chains','sconce_0','tapestry','crack','drain','arch','door']):
            repeat.paste(assets[name],((i%4)*64,(i//4)*64))
        save(repeat,BASE/f'floor{floor}/repeat_native.png')
        save(repeat.resize((1024,768),NEAREST),BASE/f'floor{floor}/repeat_4x.png')
        all_assets.update({f'F{floor} {k}':v for k,v in assets.items()})
    contact(all_assets,BASE,columns=7,cell=(140,96),title='UNDERCROFT / WALLS AND SURFACES')
    manifest(list(OUT.glob('*.png'))+list(BASE.rglob('*native.png'))+list(BASE.rglob('*4x.png')), BASE/'manifest.json',
        {'edge_contract':'All wall variants within a floor share the outer 2px ring. End rows and columns match.',
         'sconce_fps':4,'wall_size':[64,64]})
    print('28 palette textures; mixed-edge checks passed; environment sheets built.')

if __name__=='__main__':main()
