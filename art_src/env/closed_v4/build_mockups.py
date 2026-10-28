"""Corridor material proofs: oblique blockage beside a genuine open gate,
plus front-on wall faces. Offline authoring only; no game state is changed.
"""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'calm_v3'))
import math
from PIL import Image
from pipeline import ROOT,RGB,NEAREST,indexed,label
from selection import texture_name

BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/env'
WIDTH,HEIGHT,FOCAL,HORIZON,FAR=148,150,74.0,71,3.6


def lamp(depth):
    return min(1.0,max(0.0,(FAR-depth)/2.7))


def tint(ink,gain):
    return tuple(max(0,min(255,int(c*gain))) for c in RGB[ink])+(255,)


def render_view(floor,suffix,side_test):
    textures={p.stem:Image.open(p) for p in
        list(OUT.glob('painted_*.png'))+list(OUT.glob('calm_v3_*.png'))}
    view=Image.new('RGBA',(WIDTH,HEIGHT),(5,6,9,255))
    for y in range(HEIGHT):
        plane='floor' if y>HORIZON else 'ceiling'
        depth=FOCAL*0.5/(abs(y-HORIZON)+0.5)
        if depth>=FAR:continue
        gain=lamp(depth)*(0.86 if plane=='floor' else 0.64)
        for x in range(WIDTH):
            lateral=(x+0.5-WIDTH/2)/FOCAL
            wx,wy=10.5+lateral*depth,10.5-depth
            cell=(math.floor(wx),math.floor(wy))
            name=texture_name('BELL42',floor,plane,*cell)
            u,v=math.floor(wx*64)%64,math.floor(wy*64)%64
            view.putpixel((x,y),tint(textures[name].getpixel((u,v)),gain))
    back=3.5 if side_test else 1.0
    for x in range(WIDTH):
        lateral=(x+0.5-WIDTH/2)/FOCAL
        side_depth=0.5/abs(lateral) if lateral else 1e9
        depth=min(side_depth,back);side=side_depth<back
        along=10.5-depth if side else 10.5+lateral*depth
        u=along-math.floor(along)
        if (side and lateral>0) or not side:u=1-u
        tx=min(63,max(0,int(u*64)))
        salt=(math.floor(along)+(1 if lateral>0 else 0))%3
        name=f'painted_f{floor}_plain_{salt}'
        if (side_test and side and lateral>0 and math.floor(along)==9) or (not side_test and not side):
            name=f'painted_f{floor}_{suffix}'
        wall=textures[name]
        h=max(1,math.floor(FOCAL/depth+0.5));top=HORIZON-h//2
        gain=lamp(depth)*(0.78 if side else 1.0)
        for y in range(max(0,top),min(HEIGHT,top+h)):
            ty=min(63,max(0,int((y-top)*64/h)))
            view.putpixel((x,y),tint(wall.getpixel((tx,ty)),gain))
    if side_test:
        # B's existing transparent gate provides a real open-route comparison.
        # It is read-only and drawn at a proxy plane 1.5 cells in front.
        portal=Image.open(ROOT/f'assets/art/fixtures/architecture_f{floor}_gate_open_overlay_64.png').convert('RGBA')
        depth=1.5;h=max(1,math.floor(FOCAL/depth+0.5));top=HORIZON-h//2
        for x in range(WIDTH):
            lateral=(x+0.5-WIDTH/2)/FOCAL
            wx=10.5+lateral*depth
            if not 10<=wx<11:continue
            tx=min(63,max(0,int((1-(wx-10))*64)))
            for y in range(max(0,top),min(HEIGHT,top+h)):
                ty=min(63,max(0,int((y-top)*64/h)))
                r,g,b,a=portal.getpixel((tx,ty))
                if a>=128:
                    view.putpixel((x,y),(int(r*lamp(depth)),int(g*lamp(depth)),int(b*lamp(depth)),255))
    return view


def pair(name,image):
    native=BASE/f'{name}_native.png';large=BASE/f'{name}_4x.png'
    image.save(native)
    image.resize((image.width*4,image.height*4),NEAREST).save(large)
    return [native,large]


def build_mockups():
    previews=[]
    for side_test in (True,False):
        group='side' if side_test else 'front'
        sheet=indexed((344,390),1).convert('RGBA')
        text=indexed(sheet.size)
        label(text,(8,5),'OBLIQUE / REAL GATE AHEAD' if side_test else 'FRONT / SOLID END WALL',25)
        sheet.alpha_composite(text.convert('RGBA'))
        for floor in (1,2):
            for column,suffix in enumerate(('arch_blocked','door_barricaded')):
                image=render_view(floor,suffix,side_test)
                previews+=pair(f'mockup_f{floor}_{suffix}_{group}',image)
                x,y=8+column*164,34+(floor-1)*174
                sheet.paste(image,(x,y))
                text=indexed(sheet.size)
                label(text,(x,y+152),f'F{floor} / '+('SEALED ARCH' if column==0 else 'BARRED DOOR'),8)
                sheet.alpha_composite(text.convert('RGBA'))
        previews+=pair(f'mockup_{group}',sheet)
    return previews


if __name__=='__main__':build_mockups()
