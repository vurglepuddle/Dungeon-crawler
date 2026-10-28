"""Original painted room clutter; depth registration matches B's fixture art.

No existing art or game code is written. All sources remain intact. Wet
variants repaint the same registered silhouettes rather than inventing poses.
"""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'env'))
from PIL import Image,ImageDraw
from pipeline import ROOT,NEAREST,indexed,reduce,save,label,contact,manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/props'
DEPTHS={1:(64,64),2:(40,40),3:(24,24)}
FIT={'rubble':(60,30),'bone_heap':(58,28),'skeleton':(54,54),'pots':(56,34),
     'pillar':(40,64),'statue':(60,34),'candles':(46,28),'crate':(50,44)}

def cutout(name):
    im=Image.open(BASE/'sources'/f'{name}.png').convert('RGBA')
    bounds=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    assert bounds,name
    return im.crop(bounds),bounds

def fitted(name,size,maximum):
    source,crop=cutout(name)
    scale=min(maximum[0]/source.width,maximum[1]/source.height)
    dims=(max(1,round(source.width*scale)),max(1,round(source.height*scale)))
    sprite=reduce(source,dims)
    im=indexed(size)
    im.paste(sprite,((size[0]-sprite.width)//2,size[1]-sprite.height))
    return im,crop

def wet_repaint(im):
    result=im.copy()
    neutral={1:1,2:1,3:2,4:3,5:4,6:5,7:6,8:8,9:9,10:10,
             11:11,12:11,13:12,14:13,15:14,16:15,17:16,
             18:18,19:18,20:19,21:20,22:21,23:22,24:23,25:24,26:25,
             27:18,28:27,29:28,30:2,31:30}
    damp={2:11,3:11,4:12,5:13,6:14,7:15,18:11,19:11,20:12,27:12,28:13}
    for y in range(im.height):
        for x in range(im.width):
            ink=im.getpixel((x,y))
            if ink==0:continue
            trail=(y>im.height*0.65 and (x*5+y*2)%29<11) or (x<im.width*.25 and y>im.height*.4)
            result.putpixel((x,y),damp.get(ink,neutral.get(ink,ink)) if trail else neutral.get(ink,ink))
    assert result.convert('RGBA').getchannel('A').tobytes()==im.convert('RGBA').getchannel('A').tobytes()
    return result

def depth_sheet(name,rows):
    canvas=indexed((344,42+len(rows)*88),1)
    label(canvas,(8,4),'ROOM PROP / '+name.upper(),25)
    for r,(title,frames) in enumerate(rows):
        y=35+r*88
        label(canvas,(8,y+23),title,8)
        for i,im in enumerate(frames):
            x=112+i*76+(64-im.width)//2
            alpha=im.convert('RGBA').getchannel('A')
            canvas.paste(im,(x,y+64-im.height),alpha)
            label(canvas,(112+i*76,y+65),f'D{i+1}',7)
    save(canvas,BASE/name/'contact_sheet_native.png')
    save(canvas.resize((canvas.width*4,canvas.height*4),NEAREST),BASE/name/'contact_sheet_4x.png')

def main():
    registrations=[];near={};all_frames={};source_crops={}
    for kind,maximum in FIT.items():
        dry,crop=fitted(kind,(64,64),maximum);source_crops[kind]=list(crop)
        rows=[]
        for floor,native in ((1,dry),(2,wet_repaint(dry))):
            frames=[]
            for depth,size in DEPTHS.items():
                # Resize the entire registered canvas; never re-fit opaque bounds.
                im=native if depth==1 else native.resize(size,NEAREST)
                name=f'f{floor}_{kind}_d{depth}'
                save(im,OUT/f'{name}.png');frames.append(im);all_frames[name]=im
                registrations.append({'path':f'assets/art/props/{name}.png','kind':kind,'floor':floor,'depth':depth,
                    'canvas':list(size),'anchor':[size[0]//2,size[1]],'interactive':False,
                    'needs_solid_cell_if_blocking':kind=='pillar','state':'spent/unlit' if kind=='candles' else 'static'})
            near[f'F{floor} {kind}']=native
            rows.append((f'F{floor} '+('dust' if floor==1 else 'damp'),frames))
        depth_sheet(kind,rows)
    puddle,crop=fitted('puddle',(64,20),(60,14));source_crops['puddle']=list(crop)
    frames=[]
    for depth,size in ((1,(64,20)),(2,(40,12)),(3,(24,8))):
        im=puddle if depth==1 else puddle.resize(size,NEAREST)
        name=f'f2_puddle_d{depth}';save(im,OUT/f'{name}.png');frames.append(im);all_frames[name]=im
        registrations.append({'path':f'assets/art/props/{name}.png','kind':'puddle','floor':2,'depth':depth,
            'canvas':list(size),'anchor':[size[0]//2,size[1]],'interactive':False,'plane':'floor decal; shallow aspect'})
    near['F2 puddle']=puddle;depth_sheet('puddle',[('F2 water',frames)])
    contact(near,BASE,columns=5,cell=(120,96),title='UNDERCROFT / LIVED-IN ROOMS')
    manifest(list(OUT.glob('*.png'))+list(BASE.rglob('*native.png'))+list(BASE.rglob('*4x.png')),BASE/'manifest.json',
        {'registrations':registrations,'source_crop_bounds':source_crops,'depth_bands':['<1.5','<2.5','otherwise <3.6'],
         'wet_method':'Palette repaint, same silhouettes, shared full-canvas reduction.',
         'placement':'Art only. No interactable cells, loot, stairs, gates, puzzle lanes or item-hiding placements.',
         'candles':'Spent/unlit decoration; not a LIGHT source or animated flame.'})
    assert len(registrations)==51
    print('51 prop PNGs: 8 dry/wet families at 3 depths, plus 3 shallow floor-two puddles.')

if __name__=='__main__':main()
