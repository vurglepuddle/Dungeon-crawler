"""Painted floor pickups: offline fixed-palette distance art and room reviews."""
import sys
sys.dont_write_bytecode=True
import hashlib
from pathlib import Path
import numpy as np
from scipy import ndimage
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT,RGB,NEAREST,canvas,contact,label,manifest,paste,reduce,save

BASE=Path(__file__).resolve().parent
SOURCE=BASE/'sources'
OUT=ROOT/'assets/art/items'
ORDER=['knife','shard','club','stone','bone','bread','tonic','coat','coat_spent','key','clapper','lamp']
SIZES=[(64,48),(40,30),(24,18)]
FITS={'knife':(50,24),'shard':(34,26),'club':(56,28),'stone':(38,25),
      'bone':(48,23),'bread':(38,25),'tonic':(28,37),'coat':(56,34),
      'coat_spent':(56,25),'key':(40,26),'clapper':(48,25),'lamp':(32,42)}
RIMS={'knife':9,'shard':17,'club':8,'stone':8,'bone':10,'bread':25,
      'tonic':9,'coat':17,'coat_spent':17,'key':26,'clapper':25,'lamp':9}
ASSETS=[]
INPUTS=set()


def read(path):
    INPUTS.add(path)
    return Image.open(path).copy()


def cutout(kind):
    name='coat' if kind=='coat_spent' else kind
    source=read(SOURCE/f'{name}.png').convert('RGBA')
    if name=='coat':
        index=1 if kind=='coat_spent' else 0
        source=source.crop((round(source.width*index/2),0,round(source.width*(index+1)/2),source.height))
    rgba=np.array(source)
    components,total=ndimage.label(rgba[:,:,3]>=128)
    counts=np.bincount(components.ravel());counts[0]=0
    assert total and counts.max()>1000,kind
    rgba[:,:,3]=np.where(components==counts.argmax(),255,0)
    source=Image.fromarray(rgba)
    return source.crop(source.getbbox())


def master(kind):
    source=cutout(kind)
    max_w,max_h=FITS[kind]
    scale=min(max_w/source.width,max_h/source.height)
    size=(round(source.width*scale),round(source.height*scale))
    if kind in ['coat','coat_spent']:
        # The same garment footprint, foreshortened on the floor; spent padding
        # collapses vertically rather than shrinking the whole coat into a toy.
        size=(max_w,max_h)
    # Floor-cast contact line: one transparent bottom row, matching fixtures.
    out=canvas(SIZES[0])
    paste(out,reduce(source.resize(size,NEAREST)),((64-size[0])//2,47-size[1]))
    if kind=='tonic':
        # The fixed palette otherwise pulls saturated red paint toward rust.
        # Keep cork and parchment untouched; correct liquid planes to brick red.
        top=out.getbbox()[1]
        red={19:30,20:30,21:31,22:31,23:31}
        for y in range(top+round(size[1]*.42),47):
            for x in range(64):
                ink=out.getpixel((x,y));out.putpixel((x,y),red.get(ink,ink))
    return out


def rim(frame,kind):
    """Material-valued upper/left pixels, retouched at each native distance."""
    out=frame.copy()
    bounds=frame.getbbox()
    target=RIMS[kind]
    brightness=lambda ink:2*RGB[ink][0]+4*RGB[ink][1]+RGB[ink][2]
    for y in range(bounds[1],bounds[3]):
        for x in range(bounds[0],bounds[2]):
            ink=frame.getpixel((x,y))
            if not ink:continue
            top=y==0 or not frame.getpixel((x,y-1))
            left=x==0 or not frame.getpixel((x-1,y))
            if (top or left) and (x<(bounds[0]+bounds[2])//2 or y<bounds[1]+(bounds[3]-bounds[1])//4):
                if brightness(ink)<brightness(target):out.putpixel((x,y),target)
    return out


def build():
    frames={}
    for kind in ORDER:
        base=master(kind)
        for depth,size in enumerate(SIZES,1):
            frame=rim(base.resize(size,NEAREST),kind)
            frames[(kind,depth)]=frame
            record=save(frame,OUT/f'item_{kind}_d{depth}.png')
            record.update(kind=kind,depth=depth,anchor=[size[0]//2,size[1]],
                          opaque_bounds=list(frame.getbbox()),shadow='renderer; no baked shadow',
                          state='spent' if kind=='coat_spent' else 'intact' if kind=='coat' else 'static')
            ASSETS.append(record)
    return frames


def sheet(path,im):
    save(im,path.with_name(path.name.replace('_4x','_native')))
    save(im.resize((im.width*4,im.height*4),NEAREST),path)


def room(floor):
    """Simple three-cell-wide, 148x150 offline room with actual game materials."""
    wall=reduce(read(ROOT/f'art_src/fixtures/architecture/sources/painted_f{floor}_base.png'))
    ground=reduce(read(ROOT/f'assets/art/env/f{floor}_floor.png'))
    roof=reduce(read(ROOT/f'assets/art/env/f{floor}_ceiling.png'))
    out=canvas((148,150),1)
    for y in range(150):
        depth=37/(abs(y-71)+.5)
        if depth>=3.6:continue
        for x in range(148):
            u=int((.5+(x+.5-74)/74*depth)*64)%64
            v=int((.5+depth)*64)%64
            ink=(ground if y>71 else roof).getpixel((u,v))
            out.putpixel((x,y),shade(ink,max(0,min(1,(3.6-depth)/2.7))*(.86 if y>71 else .64)))
    for x in range(148):
        ray=(x+.5-74)/74
        side=1.5/abs(ray) if ray else 10000
        depth=min(side,3.25)
        height=max(1,round(74/depth));top=71-height//2
        u=int(((.5+depth)%1 if side<3.25 else (.5+ray*depth)%1)*64)
        for y in range(max(0,top),min(150,top+height)):
            v=min(63,int((y-top)*64/height))
            out.putpixel((x,y),shade(wall.getpixel((u,v)),max(0,min(1,(3.6-depth)/2.7))*(.78 if side<3.25 else 1)))
    return out


SHADE={}
def shade(ink,amount):
    key=ink,round(amount,3)
    if key not in SHADE:
        r,g,b=[v*amount for v in RGB[ink]]
        SHADE[key]=min(range(1,32),key=lambda i:2*(r-RGB[i][0])**2+4*(g-RGB[i][1])**2+(b-RGB[i][2])**2)
    return SHADE[key]


def place(out,frame,depth,lateral,lit=True):
    ground=71+round(37/depth)
    x=round(74+74*lateral/depth)-frame.width//2
    y=ground-frame.height
    bounds=frame.getbbox()
    # Review-only renderer shadow follows the opaque footprint, not padding.
    d=ImageDraw.Draw(out)
    d.ellipse((x+bounds[0],ground-3,x+bounds[2],ground-1),fill=1)
    sprite=frame.copy()
    if lit:sprite.putdata([shade(ink,max(.18,min(1,(3.6-depth)/2.7))) if ink else 0 for ink in frame.getdata()])
    paste(out,sprite,(x,y))


def reviews(frames):
    rows=[]
    for kind in ORDER:
        icon=read(ROOT/f'assets/art/icons/{"coat" if kind=="coat_spent" else kind}.png')
        rows.append((kind,[('pack icon',icon)]+[(f'D{d}',frames[(kind,d)]) for d in [1,2,3]]))
    contact(BASE/'items_contact_4x.png','WORLD ITEMS / ICON + DEPTHS 1-3',rows)
    contact(BASE/'items_weapons_4x.png','WORLD ITEMS / EDGE AND HEAVY',[rows[ORDER.index(k)] for k in ['knife','shard','club','stone','bone','clapper']])
    contact(BASE/'items_supplies_4x.png','WORLD ITEMS / CLOTH AND SUPPLIES',[rows[ORDER.index(k)] for k in ['bread','tonic','coat','coat_spent','key','lamp']])
    contact(BASE/'coat_states_4x.png','COAT / PADDED TO SPENT',[(f'Depth {d}',[(k,frames[(k,d)]) for k in ['coat','coat_spent']]) for d in [1,2,3]])
    fixtures=[]
    for d in [1,2,3]:
        entries=[]
        for caption,path in [('torch cold',f'reed_torch_unlit_d{d}.png'),('torch lit',f'reed_torch_lit_0_d{d}.png'),('Seal',f'dawn_seal_pulse_0_d{d}.png')]:
            entries.append((caption,read(ROOT/'assets/art/fixtures'/path)))
        fixtures.append((f'Existing fixtures / depth {d}',entries))
    contact(BASE/'torch_seal_match_4x.png','EXISTING TORCH AND DAWN SEAL',fixtures)
    setups=[['knife','stone','bone','tonic','coat','key'],['club','bread','shard','lamp','coat_spent','clapper']]
    positions=[(.95,-.60),(1.1,.62),(1.8,-.30),(1.9,.30),(2.55,-1.20),(2.6,1.20)]
    overview=canvas((2*156+8,2*190+28),1)
    label(overview,(8,4),'Room pickups / lamp shaded',25)
    for floor in [1,2]:
        for index,kinds in enumerate(setups):
            view=room(floor)
            for kind,(depth,lateral) in reversed(list(zip(kinds,positions))):
                variant=1 if depth<1.5 else 2 if depth<2.5 else 3
                place(view,frames[(kind,variant)],depth,lateral)
            panel=canvas((156,180),1)
            label(panel,(4,2),f'Floor {floor} / set {index+1}',25)
            paste(panel,view,(4,22))
            sheet(BASE/f'room_f{floor}_set{index+1}_4x.png',panel)
            paste(overview,view,(8+index*156,28+(floor-1)*190))
            label(overview,(8+index*156,180+(floor-1)*190),f'F{floor} set {index+1}')
    sheet(BASE/'room_items_overview_4x.png',overview)
    comparison=room(1)
    place(comparison,frames[('coat',1)],.95,-.42)
    place(comparison,frames[('coat_spent',1)],.95,.42)
    panel=canvas((156,180),1)
    label(panel,(4,2),'Padded / spent',25);paste(panel,comparison,(4,22))
    sheet(BASE/'coat_room_comparison_4x.png',panel)


def main():
    frames=build()
    reviews(frames)
    manifest(BASE/'manifest.json',{'assets':ASSETS,'depth_sizes':[list(s) for s in SIZES],
        'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(INPUTS)},
        'shadow':'No baked shadow. Renderer contact ellipse should follow opaque_bounds.',
        'rim':'Native upper-left material highlight retouched at each distance.',
        'reuse':'Existing fixtures/reed_torch_* and dawn_seal_* retain current identity and palette.'})
    print(f'Items: {len(ASSETS)} new PNGs; 12 kinds/states at three depths; 11 exact 4x reviews')


if __name__=='__main__':main()
