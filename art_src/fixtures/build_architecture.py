"""Painted architectural wall faces, shared exact masonry and arch registration.

Read preserved sources only. Never writes C's walls, original art or scenes.
Python + Pillow; fixed palette; NEAREST only; no generation/network at rebuild.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, NEAREST, canvas, contact, label, manifest, paste, reduce, save, strip

BASE=Path(__file__).resolve().parent
SOURCE=BASE/'architecture/sources'
OUT=ROOT/'assets/art/fixtures'
KINDS=['exit','stairs_down','stairs_up','gate_closed','gate_open','lift_dead','lift_working']
SHORT=['exit','down','up','shut','open','dead','live']
ASSETS=[]
DEEP={1:1,2:1,3:2,4:3,5:4,6:5,7:6,8:7,9:8,10:9,
      11:11,12:11,13:12,14:13,15:14,16:15,17:16,
      18:18,19:18,20:19,21:20,22:21,23:22,24:23,25:24,26:25,27:18,28:27,29:28,30:2,31:30}


def export(im,name,floor,kind,anchor=(0,0),**metadata):
    record=save(im,OUT/f'{name}.png')
    record.update(floor=floor,kind=kind,anchor=list(anchor),**metadata)
    ASSETS.append(record)
    return record


def painted(name,cell=0,count=1):
    with Image.open(SOURCE/name) as source:
        source=source.convert('RGBA')
        box=(round(source.width*cell/count),0,round(source.width*(cell+1)/count),source.height)
        return reduce(source.crop(box).resize((64,64),NEAREST))


def arch_mask(inner=False):
    mask=Image.new('L',(64,64),0);d=ImageDraw.Draw(mask)
    # Match C's centred round-arch geometry; preserve the full outer 2px ring.
    d.rounded_rectangle((18,15,45,80) if inner else (9,5,54,80),radius=13 if inner else 22,fill=255)
    d.rectangle((0,62,63,63),fill=0)
    return mask


def deep_repaint(im,keep_warm=False):
    result=im.copy()
    result.putdata([ink if keep_warm and ink in [10,24,25,26] else DEEP.get(ink,ink) for ink in im.getdata()])
    return result


def preserve_border(im,wall):
    for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:im.paste(wall.crop(box),box[:2])


def gate_overlay(face,kind,opening):
    result=face.copy()
    # Define solid iron independently of its shade. Darkening floor-two iron
    # must never turn the same physical bar into a transparent patch.
    metal=Image.new('L',(64,64),0);d=ImageDraw.Draw(metal)
    if kind=='gate_closed':
        for x in [24,32,40]:
            d.rectangle((x-1,16,x+1,56),fill=255)
            d.polygon([(x-2,55),(x+2,55),(x,60)],fill=255)
        d.rectangle((19,27,44,30),fill=255)
        d.rectangle((19,47,44,50),fill=255)
    else:
        d.rectangle((20,17,43,20),fill=255)
        for x in [24,32,40]:
            d.rectangle((x-1,15,x+1,23),fill=255)
            d.polygon([(x-2,22),(x+2,22),(x,27)],fill=255)
    for y in range(64):
        for x in range(64):
            if opening.getpixel((x,y)):
                if not metal.getpixel((x,y)):result.putpixel((x,y),0)
    return result


def side_projection(source,size,right=False):
    out=canvas(size)
    w,h=size
    for x in range(w):
        u=x/(w-1)
        top=h*.16*u
        bottom=h-1-h*.16*u
        for y in range(h):
            if top<=y<=bottom:
                sy=min(63,max(0,round((y-top)/(bottom-top)*63)))
                out.putpixel((x,y),source.getpixel((round(u*63),sy)))
    if right:out=ImageOps.mirror(out)
    return out


def side_anchor(size,right=False):
    w,h=size
    x=w//2
    y=round(h-1-h*.16*x/(w-1))
    return (w-1-x if right else x,y)


def checker_gate(im):
    background=canvas((64,64),3)
    draw=ImageDraw.Draw(background)
    for y in range(0,64,8):
        for x in range(0,64,8):
            if (x//8+y//8)%2==0:draw.rectangle((x,y,x+7,y+7),fill=5)
    paste(background,im,(0,0))
    return background


def groups(faces,height):
    def scaled(key):return faces[key] if height==64 else faces[key].resize((height,height),NEAREST)
    return [(f'{height}px / exit and stairs',[(kind.replace('stairs_',''),scaled(kind)) for kind in KINDS[:3]]),
            (f'{height}px / portcullis',[(kind.replace('gate_',''),scaled(kind)) for kind in KINDS[3:5]]),
            (f'{height}px / recessed lift',[(kind.replace('lift_',''),scaled(kind)) for kind in KINDS[5:]])]


def main():
    paintings={
        'exit':painted('exit.png'),
        'stairs_down':painted('stairs_down.png'),
        'stairs_up':painted('stairs_up.png'),
        'gate_closed':painted('gate_sheet.png',0,2),
        'gate_open':painted('gate_sheet.png',1,2),
        'lift_dead':painted('lift_sheet.png',0,2),
        'lift_working':painted('lift_sheet.png',1,2),
    }
    # Source cobwebs are finer than a 64px sampling grid. Preserve their story
    # cue with a few native grey threads, entirely inside the dead alcove.
    dust=ImageDraw.Draw(paintings['lift_dead'])
    for mirror in [False,True]:
        def points(path):return [(63-x if mirror else x,y) for x,y in path]
        for path in [[(29,18),(19,34)],[(22,22),(25,24),(28,23)],
                     [(21,25),(24,27),(27,26)],[(20,29),(23,30),(26,29)]]:
            dust.line(points(path),fill=5)
    outer,opening=arch_mask(),arch_mask(True)
    # ONE shared painted arch for every fixture/state. Generated source-wall
    # layouts are never allowed to replace the accepted surrounding masonry.
    arch_paint=paintings['exit']
    all_faces={};all_sides={};gate_reviews=[];seam_reviews=[]
    for floor in [1,2]:
        wall=reduce(Image.open(SOURCE/f'painted_f{floor}_base.png'))
        frame=wall.copy()
        frame.paste(arch_paint if floor==1 else deep_repaint(arch_paint),(0,0),outer)
        faces={}
        for kind in KINDS:
            face=frame.copy()
            inset=paintings[kind] if floor==1 else deep_repaint(paintings[kind],kind in ['exit','stairs_up','lift_working'])
            face.paste(inset,(0,0),opening)
            if kind=='exit':
                # Keep the one-pixel daylight tell at distance after sampling.
                d=ImageDraw.Draw(face)
                d.line((19,59,44,59),fill=25)
                d.line((19,60,44,60),fill=10)
            preserve_border(face,wall)
            name=f'architecture_f{floor}_{kind}'
            export(face,f'{name}_64',floor,kind,wall_uv=True,threshold_anchor=[32,62])
            faces[kind]=face
            for depth,size in enumerate([(32,64),(20,40),(12,24)],1):
                for side in ['left','right']:
                    side_im=side_projection(face,size,side=='right')
                    export(side_im,f'{name}_{side}_d{depth}',floor,kind,side_anchor(size,side=='right'),
                           depth=depth,projection=side,anchor_kind='centre of projected wall threshold')
                    all_sides[(floor,side,depth,kind)]=side_im
            if kind.startswith('gate_'):
                overlay=gate_overlay(face,kind,opening)
                export(overlay,f'{name}_overlay_64',floor,kind,wall_uv=True,purpose='transparent aperture; draw real corridor first')
                for depth,size in enumerate([(32,64),(20,40),(12,24)],1):
                    for side in ['left','right']:
                        export(side_projection(overlay,size,side=='right'),f'{name}_overlay_{side}_d{depth}',floor,kind,
                               side_anchor(size,side=='right'),depth=depth,projection=side,
                               purpose='transparent aperture; no opaque black rectangle behind open gate')
                gate_reviews.append((f'Floor {floor} / {kind} / alpha',[(kind,checker_gate(overlay))]))
            # Validate exact material compatibility and a single stable frame.
            for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
                assert face.crop(box).tobytes()==wall.crop(box).tobytes(),kind
            assert set(face.convert('RGBA').getchannel('A').getdata())=={255},kind
        for family,states in [('gate',['closed','open']),('lift',['dead','working'])]:
            image=strip([faces[f'{family}_{state}'] for state in states])
            export(image,f'architecture_f{floor}_{family}_strip_64',floor,family,
                   frame_count=2,frame_size=[64,64],frame_order=states,wall_uv=True)
        for kind in KINDS:
            for x in range(64):
                for y in range(64):
                    if not opening.getpixel((x,y)):
                        assert faces[kind].getpixel((x,y))==faces['exit'].getpixel((x,y)),kind
        all_faces[floor]=faces
        rows=[]
        for height in [64,40,24]:rows.extend(groups(faces,height))
        contact(BASE/f'architecture_f{floor}_contact_4x.png',f'ARCHITECTURE / FLOOR {floor}',rows)
        seam_reviews.append((f'Floor {floor} / same stone', [('wall',wall),('exit',faces['exit']),('wall',wall)]))
    side_rows=[]
    for floor,side,depth in [(1,'left',1),(1,'right',1),(2,'left',1),(2,'right',1),
                             (1,'left',2),(1,'left',3),(2,'right',2),(2,'right',3)]:
        side_rows.append((f'F{floor} / {side} / depth {depth}',[(label,all_sides[(floor,side,depth,kind)]) for label,kind in zip(SHORT,KINDS)]))
    contact(BASE/'architecture_sides_contact_4x.png','ARCHITECTURE / SIDE WALLS',side_rows)
    contact(BASE/'architecture_gate_overlay_contact_4x.png','GATE APERTURE / CHECKER BEHIND',gate_reviews)
    contact(BASE/'architecture_seams_contact_4x.png','ARCH / AGED MASONRY MATCH',seam_reviews)
    source_hashes={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SOURCE.glob('*.png'))}
    manifest(BASE/'architecture_manifest.json',{'assets':ASSETS,'sources':source_hashes,
        'wall_size':[64,64],'arch_outer':[9,5,54,80],'aperture':[18,15,45,80],
        'source_masonry':'Frozen C painted_v2 floor-one and darker floor-two faces',
        'uv_anchor':[0,0],'threshold_anchor':[32,62],
        'shared_contract':'outer 2px ring matches frozen masonry; same painted arch across every state'})
    print(f'Architecture: {len(ASSETS)} indexed wall/state/side/overlay PNGs; shared arch and masonry borders verified')


if __name__=='__main__':main()
