"""New head-on levers and carved keystones. Original assets are read-only."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
from pathlib import Path
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT, TABLE, NEAREST, canvas, contact, label, manifest, paste, reduce, save
from build_architecture import arch_mask, side_projection, side_anchor, preserve_border
from build_architecture_readability import corridor, floor_two

BASE=Path(__file__).resolve().parent
LEVER=BASE/'lever_front'
KEY=BASE/'keystone_carved'
OLD=BASE/'architecture/sources'
OUT=ROOT/'assets/art/fixtures'
OWNER=OLD/'fe3439be-72ab-49d3-8af7-49e3b2e58160.png'
ASSETS=[]
SOURCES=set()
PATCH=(24,5,41,17)


def read(path):
    SOURCES.add(path)
    return Image.open(path).copy()


def output(im,name,**meta):
    record=save(im,OUT/f'{name}.png')
    record.update(**meta)
    ASSETS.append(record)


def review(path,im):
    save(im,path.with_name(path.name.replace('_4x','_native')))
    save(im.resize((im.width*4,im.height*4),NEAREST),path)


def hardware():
    source=read(LEVER/'sources/lever_states.png').convert('RGBA')
    cells=[]
    for index in range(2):
        cell=source.crop((round(index*source.width/2),0,round((index+1)*source.width/2),source.height))
        rgba=np.array(cell)
        components,_=ndimage.label(rgba[:,:,3]>=128)
        counts=np.bincount(components.ravel());counts[0]=0
        rgba[:,:,3]=np.where(components==counts.argmax(),255,0)
        cell=Image.fromarray(rgba)
        cells.append(cell)
    # Inspectable source pivot: both square housings centre on source y=465.
    # Preserve common source Y coordinates; independent alpha crops would make
    # the whole plate jump when the projecting knob flips up/down.
    pivot_y=465
    bounds=[cell.getbbox() for cell in cells]
    scale=min(24/max(b[2]-b[0] for b in bounds),
              22/(pivot_y-min(b[1] for b in bounds)),
              17/(max(b[3] for b in bounds)-pivot_y))
    states=[]
    for cell,box in zip(cells,bounds):
        painted=cell.crop(box)
        size=(round(painted.width*scale),round(painted.height*scale))
        cell=painted.resize(size,NEAREST)
        frame=canvas((32,40))
        paste(frame,reduce(cell),(16-size[0]//2,22+round((box[1]-pivot_y)*scale)))
        states.append(frame)
    # Preserve the same backplate rim, four bolts and hinge between states.
    up,down=states
    stable=up.copy()
    stable.paste(down.crop((8,0,24,40)),(8,0))
    stable.paste(up.crop((11,18,21,26)),(11,18))
    for box in [(6,11,11,16),(21,11,26,16),(6,27,11,32),(21,27,26,32)]:
        stable.paste(up.crop(box),box[:2])
    states=[up,stable]
    for state,frame in zip(['up','down'],states):
        for depth,size in enumerate([(32,40),(20,26),(12,16)],1):
            output(frame.resize(size,NEAREST),f'lever_front_{state}_d{depth}',
                   kind='lever_hardware',state=state,depth=depth,
                   anchor=[[16,22],[10,14],[6,8]][depth-1],anchor_kind='wall hinge')
    all_faces={}
    for floor in [1,2]:
        wall=reduce(read(OLD/f'painted_f{floor}_base.png'))
        for state,frame in zip(['up','down'],states):
            face=wall.copy()
            paste(face,frame,(16,5))
            all_faces[(floor,state)]=face
            for depth,height in enumerate([64,40,24],1):
                output(face.resize((height,height),NEAREST),f'lever_wall_f{floor}_{state}_{height}',
                       kind='lever_wall',floor=floor,state=state,depth=depth,wall_uv=True,
                       anchor=[0,0],hinge=[round(32*height/64),round(27*height/64)])
    return states,all_faces


def carve_recess(face,down,floor):
    """A small single cut entirely inside the keystone, clear of arch joints.

    Dark top/left lip, grime in the groove, stone-valued lower/right bevel.
    No cream/white ink; the bottom point of V cannot merge into the arch's M.
    """
    # Calm a few noisy source speckles on the cut stone face; the neighboring
    # voussoirs and all arch geometry remain exactly the accepted painting.
    d=ImageDraw.Draw(face)
    d.polygon([(27,7),(37,7),(36,14),(28,14)],fill=6 if floor==1 else 5)
    d.line([(27,7),(28,14),(35,14)],fill=5 if floor==1 else 4)
    d.point((36,7),fill=7 if floor==1 else 6)
    points=[(28,8),(32,12),(36,8)] if down else [(28,12),(32,8),(36,12)]
    groove=Image.new('L',(64,64),0)
    ImageDraw.Draw(groove).line(points,fill=255,width=1)
    shadow=3 if floor==1 else 2
    cavity=4 if floor==1 else 3
    bevel=7 if floor==1 else 6
    pixels={(x,y) for y in range(64) for x in range(64) if groove.getpixel((x,y))}
    for x,y in pixels:
        if (x-1,y-1) not in pixels:face.putpixel((x-1,y-1),shadow)
    for x,y in pixels:
        if (x,y+1) not in pixels:face.putpixel((x,y+1),bevel)
    for x,y in pixels:
        face.putpixel((x,y),cavity)


def stairs():
    down=reduce(read(OWNER).resize((64,64),NEAREST))
    up=reduce(read(BASE/'readability/sources/stairs_up_matching_owner.png').resize((64,64),NEAREST))
    all_faces={}
    outer,opening=arch_mask(),arch_mask(True)
    for floor in [1,2]:
        wall=reduce(read(OLD/f'painted_f{floor}_base.png'))
        for kind,source in [('stairs_down',down),('stairs_up',up)]:
            old=read(OUT/f'architecture_v2_f{floor}_{kind}_64.png')
            clean=reduce(read(OLD/'painted_f1_base.png'))
            clean.paste(down,(0,0),outer)
            clean.paste(source,(0,0),opening)
            if floor==2:
                stone=floor_two(clean,kind)
                clean=wall.copy();clean.paste(stone,(0,0),outer)
            preserve_border(clean,wall)
            face=old.copy()
            # Remove every old sign pixel, including those touching the arch,
            # from the clean pre-mark painting, then cut the new small groove.
            face.paste(clean.crop(PATCH),PATCH[:2])
            carve_recess(face,kind=='stairs_down',floor)
            all_faces[(floor,kind)]=face
            for depth,height in enumerate([64,40,24],1):
                output(face.resize((height,height),NEAREST),f'architecture_v3_f{floor}_{kind}_{height}',
                       kind=kind,floor=floor,depth=depth,anchor=[0,0],wall_uv=True,
                       threshold_anchor=[height//2,round(62*height/64)])
            for depth,size in enumerate([(32,64),(20,40),(12,24)],1):
                for side in ['left','right']:
                    output(side_projection(face,size,side=='right'),f'architecture_v3_f{floor}_{kind}_{side}_d{depth}',
                           kind=kind,floor=floor,depth=depth,projection=side,
                           anchor=list(side_anchor(size,side=='right')),anchor_kind='projected wall threshold')
    return all_faces


def side_view(face,floor,state):
    """A wall face on the left side of the same 148x150 review corridor."""
    end=reduce(read(OLD/f'painted_f{floor}_base.png'))
    view=corridor(end,floor,2.5)
    # Reuse exactly the palette and lamp math of the corridor review renderer.
    from pipeline import RGB
    from build_architecture_readability import gain
    cache={}
    for x in range(74):
        ray_x=(x+.5-74)/74
        depth=-.5/ray_x
        if depth>=2.5:continue
        h=max(1,round(74/depth));top=71-h//2
        u=int(((.5+depth)%1)*64)
        for y in range(max(0,top),min(150,top+h)):
            v=min(63,int((y-top)*64/h))
            ink=(face if .5<=depth<1.5 else end).getpixel((u,v))
            if (ink,depth) not in cache:
                r,g,b=[c*gain(depth)*.78 for c in RGB[ink]]
                cache[(ink,depth)]=min(range(1,32),key=lambda i:2*(r-RGB[i][0])**2+4*(g-RGB[i][1])**2+(b-RGB[i][2])**2)
            view.putpixel((x,y),cache[(ink,depth)])
    return view


def reviews(states,lever_faces,stair_faces):
    rows=[]
    for floor in [1,2]:
        for h in [64,40,24]:
            rows.append((f'F{floor} / {h}px / head-on wall',[(s,lever_faces[(floor,s)].resize((h,h),NEAREST)) for s in ['up','down']]))
    contact(LEVER/'lever_front_contact_4x.png','LEVER / FRONT WALL / FLIPS',rows)
    contact(LEVER/'lever_hardware_contact_4x.png','LEVER / FRONT AND EXISTING SIDE',[
        (s,[('front',states[i]),('old left',read(ROOT/f'assets/art/fx/lever_left_{s}_d1.png')),
             ('old right',read(ROOT/f'assets/art/fx/lever_right_{s}_d1.png'))]) for i,s in enumerate(['up','down'])])
    for floor in [1,2]:
        sheet=canvas((3*156+8,2*177+32),1)
        label(sheet,(8,4),f'F{floor} / lever / face and turn',25)
        for row,state in enumerate(['up','down']):
            face=lever_faces[(floor,state)]
            views=[('front near',corridor(face,floor,.5)),('front D2',corridor(face,floor,1.5)),
                   ('side wall',side_view(face,floor,state))]
            for col,(caption,im) in enumerate(views):
                x,y=8+col*156,28+row*177
                paste(sheet,im,(x,y));label(sheet,(x,y+151),f'{caption} {state}')
        review(LEVER/f'lever_corridor_f{floor}_4x.png',sheet)
    rows=[]
    for floor in [1,2]:
        for h in [64,40,24]:
            rows.append((f'F{floor} / {h}px / cut into stone',[(kind.replace('stairs_',''),stair_faces[(floor,kind)].resize((h,h),NEAREST)) for kind in ['stairs_down','stairs_up']]))
    contact(KEY/'keystone_contact_4x.png','KEYSTONE / CARVED V AND ^',rows)
    close=canvas((384,158),1)
    label(close,(8,4),'Keystone / old mark and new cut',25)
    for floor in [1,2]:
        for index,kind in enumerate(['stairs_down','stairs_up']):
            x=8+index*184;y=28+(floor-1)*64
            old=read(OUT/f'architecture_v2_f{floor}_{kind}_64.png').crop(PATCH)
            new=stair_faces[(floor,kind)].crop(PATCH)
            paste(close,old.resize((51,36),NEAREST),(x,y))
            paste(close,new.resize((51,36),NEAREST),(x+65,y))
            label(close,(x,y+37),f'F{floor} {kind[7:]} old / new')
    review(KEY/'keystone_detail_4x.png',close)


def main():
    states,lever_faces=hardware()
    stair_faces=stairs()
    reviews(states,lever_faces,stair_faces)
    from build_architecture_readability import INPUTS as corridor_inputs
    SOURCES.update(corridor_inputs)
    source_hashes={path.relative_to(ROOT).as_posix():hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(SOURCES)}
    manifest(LEVER/'manifest.json',{'assets':ASSETS,'sources':source_hashes,
        'keystone_patch':list(PATCH),'wall_hinge':[32,27],
        'front_sprite_hinge':[[16,22],[10,14],[6,8]],
        'runtime_note':'Choose wall UV faces OR correctly oriented sprites, never both. No code wiring in this batch.'})
    print(f'Wall controls: {len(ASSETS)} new runtime PNGs; front lever states and carved keystones')


if __name__=='__main__':main()
