"""16px pack illustrations derived from accepted item/fixture paintings.

No source painting, world sprite, C icon or UI material is written. Original
paintings -> alpha crop -> nearest reduction -> documented native cue cleanup.
"""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
import math
from pathlib import Path
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT,RGB,TABLE,NEAREST,canvas,contact,label,manifest,paste,reduce,save

BASE=Path(__file__).resolve().parent
REVIEW=BASE/'pack_icons'
OUT=ROOT/'assets/art/items'
ORDER=['knife','shard','club','stone','bone','bread','tonic','coat','coat_spent',
       'key','clapper','lamp','torch_unlit','torch_lit','seal']
NAMES={'knife':'Rust knife','shard':'Glass shard','club':'Iron club','stone':'Round stone',
       'bone':'Ham bone','bread':'Dry bread','tonic':'Red tonic','coat':'Padded coat',
       'coat_spent':'Spent coat','key':'Abbey key','clapper':'Clapper','lamp':'Hooded lamp',
       'torch_unlit':'Cold reeds','torch_lit':'Lit reeds','seal':'Dawn Seal'}
FITS={'knife':(14,14),'shard':(12,14),'club':(14,14),'stone':(13,11),'bone':(14,13),
      'bread':(14,11),'tonic':(11,14),'coat':(14,11),'coat_spent':(14,9),
      'key':(14,14),'clapper':(14,12),'lamp':(10,14),'seal':(14,14)}
RIMS={'knife':9,'shard':17,'club':8,'stone':8,'bone':10,'bread':25,'tonic':9,
      'coat':16,'coat_spent':16,'key':25,'clapper':25,'lamp':25,'seal':26}
INPUTS=set()
ASSETS=[]


def read(path):
    path=Path(path);INPUTS.add(path)
    return Image.open(path).copy()


def indexed(im):return im if im.mode=='P' and im.getpalette()==TABLE else reduce(im)


def component(source):
    rgba=np.array(source.convert('RGBA'))
    parts,count=ndimage.label(rgba[:,:,3]>=128)
    areas=np.bincount(parts.ravel());areas[0]=0
    assert count and areas.max()>10
    rgba[:,:,3]=np.where(parts==areas.argmax(),255,0)
    im=Image.fromarray(rgba)
    return im.crop(im.getbbox())


def source(kind):
    if kind=='seal':
        im=read(ROOT/'art_src/fixtures/sources/dawn_seal_pedestal.png').convert('RGBA')
        # Take the actual painted sun disc, never the stone pedestal or glove.
        mask=Image.new('L',im.size,0);d=ImageDraw.Draw(mask)
        box=tuple(round(f*s) for f,s in zip((.17,.025,.835,.725),(im.width,im.height,im.width,im.height)))
        d.ellipse(box,fill=255)
        rgba=np.array(im);rgba[:,:,3]=np.minimum(rgba[:,:,3],np.array(mask))
        return component(Image.fromarray(rgba))
    if kind.startswith('torch'):
        return component(read(ROOT/'art_src/fixtures/sources/reed_torch_unlit.png'))
    name='coat' if kind=='coat_spent' else kind
    im=read(BASE/f'sources/{name}.png').convert('RGBA')
    if name=='coat':
        i=int(kind=='coat_spent')
        im=im.crop((round(im.width*i/2),0,round(im.width*(i+1)/2),im.height))
    return component(im)


def fit(kind):
    im=source(kind)
    if kind.startswith('torch'):
        # Separate the painted fan and grip before reduction. Their natural
        # proportions lose the reed ends entirely at 16px. Keep a broader fan
        # and a slightly leaning three-pixel grip, reusing actual paint in both.
        head=reduce(im.crop((0,0,im.width,round(im.height*.34))).resize((7,5),NEAREST))
        handle=reduce(im.crop((round(im.width*.30),round(im.height*.32),round(im.width*.68),im.height)).resize((3,6),NEAREST))
        frame=canvas((16,16));paste(frame,head,(6,5))
        d=ImageDraw.Draw(frame)
        for y in range(9,15):
            x=5+round((14-y)*.4)
            for dx in range(3):
                ink=handle.getpixel((dx,y-9))
                d.point((x+dx,y),fill=ink if ink else [24,23,20][dx])
        d.line((8,9,10,9),fill=18)
        for xy in [(7,5),(9,4),(11,5)]:d.point(xy,fill=9)
        return frame
    w,h=FITS[kind]
    scale=min(w/im.width,h/im.height)
    size=(max(1,round(im.width*scale)),max(1,round(im.height*scale)))
    if kind in ['coat','coat_spent']:size=FITS[kind]
    out=canvas((16,16));paste(out,reduce(im.resize(size,NEAREST)),((16-size[0])//2,(16-size[1])//2))
    return out


def rim(im,kind):
    out=im.copy();bounds=im.getbbox();target=RIMS[kind]
    bright=lambda ink:2*RGB[ink][0]+4*RGB[ink][1]+RGB[ink][2]
    for y in range(bounds[1],bounds[3]):
        for x in range(bounds[0],bounds[2]):
            ink=im.getpixel((x,y))
            if not ink:continue
            exposed=(y==0 or not im.getpixel((x,y-1))) or (x==0 or not im.getpixel((x-1,y)))
            if exposed and x<8 and y<(bounds[1]+bounds[3])//2 and bright(ink)<bright(target):out.putpixel((x,y),target)
    return out


def cues(im,kind):
    out=im.copy();d=ImageDraw.Draw(out)
    if kind=='knife':
        d.line([(7,7),(11,4),(14,3)],fill=9)
        for xy in [(2,10),(3,9),(5,8)]:d.point(xy,fill=23)
    if kind=='key':
        # Keep the painted bow/shank, restoring the small closed gold loop
        # which dark source shadows make read as a C at native pack scale.
        for xy in [(2,3),(3,2),(4,2),(5,3),(5,4),(5,5),(4,6),(3,6),(2,5),(2,4)]:d.point(xy,fill=25 if sum(xy)%2 else 24)
        d.rectangle((3,4,4,5),fill=0)
    if kind=='tonic':
        # Keep cork/label; red liquid must not quantize entirely into brown rust.
        for y in range(7,14):
            for x in range(16):
                ink=out.getpixel((x,y))
                if ink in [19,20,21,22,23]:out.putpixel((x,y),30 if ink in [19,20] else 31)
    if kind=='coat_spent':
        # The same spent garment as the accepted icon: pale exposed stuffing,
        # dark slit, collapsed lower edge. Positions are local to the 16px icon.
        d.line((3,7,5,8),fill=1)
        for x,y,ink in [(3,6,9),(4,7,10),(5,7,8),(11,6,9),(12,7,8),(5,10,9),(10,10,8)]:d.point((x,y),fill=ink)
        for xy in [(3,10),(6,11),(10,11),(12,9)]:d.point(xy,fill=0)
    if kind=='stone':
        # Keep one chipped corner and a geological face; no level rim/brim.
        box=out.getbbox()
        d.point((box[2]-2,box[3]-1),fill=0)
    return out


def painted_fire():
    im=read(ROOT/'art_src/fixtures/painted_v2/sources/web_burning.png').convert('RGBA')
    w=im.width//2
    im=im.crop((round(w*.34),round(im.height*.20),round(w*.62),round(im.height*.49)))
    rgba=np.array(im)
    r,g,b=rgba[:,:,0].astype(float),rgba[:,:,1].astype(float),rgba[:,:,2].astype(float)
    keep=(r>b*1.35)&(g>b*1.12)&(r>100)&(rgba[:,:,3]>=128)
    rgba[:,:,3]=np.where(keep,255,0)
    return component(Image.fromarray(rgba))


def old(kind):
    if kind.startswith('torch'):
        return indexed(read(ROOT/f'assets/art/fixtures/reed_torch_icon_{kind[6:]}_16.png'))
    if kind=='seal':return indexed(read(ROOT/'assets/art/fixtures/dawn_seal_icon_16.png'))
    return indexed(read(ROOT/f'assets/art/icons/{kind}.png'))


def build():
    icons={}
    for kind in ORDER:
        if kind=='torch_lit':
            im=icons['torch_unlit'].copy()
            fire=reduce(painted_fire().resize((7,8),NEAREST))
            paste(im,fire,(6,0))
            # Two warm edge pixels connect the painted tongue to the reed head.
            ImageDraw.Draw(im).line((8,6,10,7),fill=25)
        else:
            im=fit(kind)
            if not kind.startswith('torch'):im=cues(rim(im,kind),kind)
        record=save(im,OUT/f'icon_{kind}_16.png')
        record.update(kind=kind,anchor=[8,8],opaque_bounds=list(im.getbbox()),frame_ms=0,
                      material='accepted painting reduced and native cue cleanup',
                      shadow='none; HUD illustration, no dungeon lamp modulation')
        ASSETS.append(record);icons[kind]=im
    return icons


def sheet(name,im):
    save(im,REVIEW/f'{name}_native.png')
    save(im.resize((im.width*4,im.height*4),NEAREST),REVIEW/f'{name}_4x.png')


def nine(source,size,margin=4):
    # Match Chrome.surface(card): source once-stretched, fixed 4px corners.
    out=canvas(size)
    xs=[0,margin,source.width-margin,source.width]
    ys=[0,margin,source.height-margin,source.height]
    tx=[0,margin,size[0]-margin,size[0]];ty=[0,margin,size[1]-margin,size[1]]
    for y in range(3):
        for x in range(3):
            box=(xs[x],ys[y],xs[x+1],ys[y+1]);target=(tx[x+1]-tx[x],ty[y+1]-ty[y])
            paste(out,source.crop(box).resize(target,NEAREST),(tx[x],ty[y]))
    return out


def selected(slot):
    out=slot.copy();d=ImageDraw.Draw(out)
    for x,y,dx,dy in [(1,1,1,1),(17,1,-1,1),(1,20,1,-1),(17,20,-1,-1)]:
        d.line((x,y,x+dx*3,y),fill=25);d.line((x,y,x,y+dy*3),fill=25)
    return out


def reviews(icons):
    pack=indexed(read(ROOT/'assets/art/ui_offer/pack_leather.png'))
    slate=indexed(read(ROOT/'assets/art/ui/slate.png'))
    context=canvas((384,40+5*66),1)
    label(context,(8,2),'16px / PACK OLD-NEW / SLATE OLD-NEW',25)
    label(context,(8,19),'Accepted paintings / no icon enlargement',8)
    for i,kind in enumerate(ORDER):
        x=(i%3)*128;y=40+(i//3)*66
        label(context,(x+4,y),kind.replace('torch_','reed '),9)
        slot=pack.crop(((i%8)*19,0,(i%8+1)*19,22))
        backgrounds=[slot,slot,nine(slate,(24,22)),nine(slate,(24,22))]
        for j,(bg,icon) in enumerate(zip(backgrounds,[old(kind),icons[kind],old(kind),icons[kind]])):
            bg=bg.copy();paste(bg,icon,((bg.width-16)//2,3))
            paste(context,bg,(x+4+j*30,y+20))
    sheet('icons_context',context)
    rows=[]
    for n in range(2):
        kinds=ORDER[n*8:(n+1)*8];strips=[]
        for version in ['old','painted']:
            strip=pack.copy()
            for i,kind in enumerate(kinds):
                paste(strip,old(kind) if version=='old' else icons[kind],(i*19+1,3))
            if n==0:
                piece=selected(strip.crop((3*19,0,4*19,22)));paste(strip,piece,(3*19,0))
            strips.append((version,strip))
        rows.append((f'Actual 8 x 19px slots / set {n+1}',strips))
    contact(REVIEW/'icons_pack_strip_4x.png','PACK / OLD AND PAINTED / NATIVE 16px',rows)
    rows=[]
    for n in range(3):
        kinds=ORDER[n*5:(n+1)*5];cards=[]
        for version in ['old','painted']:
            card=nine(slate,(146,132));label(card,(6,2),version.upper(),25)
            for i,kind in enumerate(kinds):
                y=23+i*21
                paste(card,old(kind) if version=='old' else icons[kind],(6,y))
                label(card,(27,y),NAMES[kind],9)
            cards.append((version,card))
        rows.append((f'Actual slate card material / set {n+1}',cards))
    contact(REVIEW/'icons_card_4x.png','SLATE CARD / 16px READABILITY',rows)
    rows=[]
    for kind in ORDER[:12]:
        rows.append((NAMES[kind],[('world',indexed(read(OUT/f'item_{kind}_d1.png'))),('old',old(kind)),('painted',icons[kind])]))
    contact(REVIEW/'icons_world_match_4x.png','PAINTING / WORLD TO PACK',rows)
    contact(REVIEW/'icons_torch_seal_4x.png','REEDS AND SEAL / PAINTED MATCH',[
        (NAMES[k],[('old',old(k)),('painted',icons[k])]) for k in ['torch_unlit','torch_lit','seal']])


def main():
    # Default rebuild follows the owner's current r10 direction. The original
    # r9 code/PNGs/receipt are preserved under pack_icons/r9 for comparison.
    import runpy
    runpy.run_path(str(REVIEW/'r10/build.py'),run_name='__main__')


if __name__=='__main__':main()
