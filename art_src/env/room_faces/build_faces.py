"""Lived-in floor/ceiling faces. Old surface and wall PNGs are read-only."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import math
from PIL import Image,ImageDraw
from pipeline import ROOT,NEAREST,RGB,indexed,save,contact,manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/env'

def weathered(floor,ceiling=False):
    im=Image.open(ROOT/f'assets/art/env/f{floor}_{"ceiling" if ceiling else "floor"}.png').copy()
    grain=Image.open(ROOT/'assets/art/stone_wall.png')
    # Original painted stone provides wear, not a replacement wall pattern.
    for y in range(5,59):
        for x in range(5,59):
            old=im.getpixel((x,y));sample=grain.getpixel(((x+11)%64,(y+7)%64))
            if ceiling and old in (3,4):
                ink={3:2,4:3,5:3,6:4,7:5,8:5}.get(sample,old)
                if floor==2:ink={2:2,3:3,4:3,5:4}.get(ink,ink)
                im.putpixel((x,y),ink)
            elif not ceiling and old in (3,4,5,6):
                # Preserve original flag joins and pooled water; scuff faces only.
                if x in (23,24,39,40) or y in (31,32):continue
                ink={3:3,4:4,5:5,6:6,7:6,8:7}.get(sample,old)
                if floor==2:ink={3:2,4:3,5:4,6:5,7:5}.get(ink,ink)
                im.putpixel((x,y),ink)
    return im

def decorate(base,kind,floor):
    im=base.copy();d=ImageDraw.Draw(im)
    if kind=='ceiling_roots':
        paths=[[(6,6),(15,13),(19,22),(28,31),(32,43),(43,56)],
               [(13,11),(26,12),(33,21),(47,25),(57,34)],
               [(20,23),(13,33),(16,43),(8,54)],
               [(31,20),(39,11),(50,8)],[(31,40),(44,43),(51,52)]]
        for p in paths:
            d.line(p,fill=1,width=4);d.line([(x-1,y-1) for x,y in p],fill=18 if floor==2 else 27,width=2)
            d.line([(x-1,y-1) for x,y in p],fill=28 if floor==1 else 12)
        d.line([(45,24),(51,19),(57,20)],fill=18)
        d.line([(18,40),(27,43),(29,49)],fill=18)
    elif kind=='ceiling_chain':
        for x,y in ((12,12),(50,50)):
            d.ellipse((x-4,y-4,x+4,y+4),fill=2,outline=5);d.point((x-1,y-1),fill=8)
        for i in range(7):
            x,y=14+i*5,14+i*5
            d.ellipse((x-3,y-2,x+4,y+5),outline=1,width=2)
            d.line((x-1,y-1,x+2,y-1),fill=6 if floor==1 else 5)
            d.line((x+3,y+2,x+2,y+4),fill=4)
        if floor==2:d.line([(39,43),(43,47)],fill=13,width=2)
    elif kind=='ceiling_boss':
        d.ellipse((15,15,49,49),fill=2)
        d.ellipse((16,16,47,47),fill=5 if floor==1 else 4,outline=7 if floor==1 else 5)
        d.ellipse((20,20,43,43),fill=4 if floor==1 else 3,outline=6 if floor==1 else 5)
        for a in range(0,360,45):
            r=math.radians(a)
            d.line((32+round(math.cos(r)*5),32+round(math.sin(r)*5),32+round(math.cos(r)*11),32+round(math.sin(r)*11)),fill=7 if floor==1 else 5,width=2)
        d.ellipse((27,27,36,36),fill=6 if floor==1 else 4)
        d.line([(31,16),(29,23),(34,29),(31,34),(38,40),(38,47)],fill=1,width=2)
        d.line([(32,16),(30,23),(35,29)],fill=8 if floor==1 else 6)
        if floor==2:d.arc((17,17,47,47),50,145,fill=12,width=2)
    elif kind=='floor_drain':
        d.rectangle((15,15,49,49),fill=2,outline=6 if floor==1 else 4)
        d.rectangle((18,18,46,46),fill=1,outline=4)
        for x in range(21,46,5):
            d.line((x,19,x,45),fill=5 if floor==1 else 4,width=2)
            d.line((x,19,x,44),fill=7 if floor==1 else 5)
        d.line((19,32,45,32),fill=3,width=2)
        for x,y in ((17,17),(47,17),(17,47),(47,47)):d.point((x,y),fill=28)
        if floor==2:
            d.line([(12,47),(19,51),(33,52),(47,49)],fill=12,width=2)
            d.line([(28,54),(38,54)],fill=14)
    elif kind=='floor_cracked':
        paths=[[(9,10),(18,19),(21,29),(31,36),(37,48),(52,56)],[(21,29),(34,25),(43,14)],[(36,47),(24,48),(15,55)]]
        for p in paths:
            d.line([(x+1,y-1) for x,y in p],fill=7 if floor==1 else 5)
            d.line(p,fill=2,width=2)
        d.polygon([(20,29),(25,32),(23,36),(18,34)],fill=3 if floor==1 else 11)
    elif kind=='floor_compass':
        d.ellipse((10,10,54,54),outline=27,width=2)
        d.ellipse((12,12,52,52),outline=28)
        for a in range(0,360,45):
            r=math.radians(a);tip=21 if a%90==0 else 13
            cx,cy=32,32
            p=[(cx+round(math.cos(r)*tip),cy+round(math.sin(r)*tip)),
               (cx+round(math.cos(r+math.pi/2)*4),cy+round(math.sin(r+math.pi/2)*4)),
               (cx,cy),(cx+round(math.cos(r-math.pi/2)*4),cy+round(math.sin(r-math.pi/2)*4))]
            d.polygon(p,fill=29 if a%90==0 else 27)
            d.line((cx,cy,p[0][0],p[0][1]),fill=24 if floor==1 else 28)
        d.ellipse((29,29,35,35),fill=13,outline=28)
        # One arrowhead identifies world north (negative world Y). No tiny text.
        d.polygon([(32,8),(29,13),(35,13)],fill=9)
        if floor==2:
            d.arc((10,10,54,54),10,80,fill=12,width=2)
            d.line((29,40,27,45),fill=13)
    # All variants keep the existing surface family's complete two-pixel ring.
    for box in ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)):im.paste(base.crop(box),box[:2])
    return im

def main():
    assets={}
    for floor in (1,2):
        for ceiling,kinds in ((False,('drain','cracked','compass')),(True,('roots','chain','boss'))):
            plane='ceiling' if ceiling else 'floor';base=weathered(floor,ceiling)
            for kind in kinds:
                name=f'room_f{floor}_{plane}_{kind}'
                im=decorate(base,f'{plane}_{kind}',floor)
                for box in ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)):
                    assert im.crop(box).tobytes()==base.crop(box).tobytes()
                assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes()
                assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes()
                save(im,OUT/f'{name}.png');assets[f'F{floor} {kind}']=im
    contact(assets,BASE,columns=6,cell=(120,96),title='UNDERCROFT / OVERHEAD AND UNDERFOOT')
    manifest(list(OUT.glob('room_*.png'))+list(BASE.glob('contact_sheet*.png')),BASE/'manifest.json',
        {'world_uv_origin':'top-left; U +world X, V +world Y','size':[64,64],
         'compass_north':'Negative world Y; do not randomly rotate this tile.',
         'plane_only':'Roots and chain lie on the ceiling plane. No hanging geometry or collision is supplied.'})
    print('12 lived-in floor/ceiling faces; shared surface edges intact.')

if __name__=='__main__':main()
