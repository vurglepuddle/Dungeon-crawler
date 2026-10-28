"""One painted leaf with real binary alpha; current 144x324 map panel size."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
import json
import hashlib
from collections import deque
from PIL import Image
from pipeline import ROOT,NEAREST,indexed,reduce,save,contact,manifest

BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/ui_offer/map_parchment_torn_v2.png'


def map_mockup(paper):
    source=Image.open(BASE/'sources/m3d_map.png').convert('RGBA').resize((154,342),NEAREST)
    world=Image.open(BASE/'sources/m3d_world.png').convert('RGBA').resize((154,342),NEAREST)
    screen=world.copy()
    screen.alpha_composite(paper.convert('RGBA'),(5,16))
    screen.paste(source.crop((0,0,154,16)),(0,0))
    # Copy existing ink glyphs, not the old page's flat backing or fold lines.
    inks={(77,43,29),(128,100,60),(15,40,45)}
    ink_positions=[]
    for y in range(28,283):
        for x in range(17 if y<45 else 26,137 if y<45 else 128):
            value=source.getpixel((x,y))
            if value[:3] in inks:
                screen.putpixel((x,y),value)
                ink_positions.append([x,y])
    button=(13,288,141,313)
    screen.paste(source.crop(button),button[:2])
    native=BASE/'mockup_map_native.png';large=BASE/'mockup_map_4x.png'
    screen.save(native)
    screen.resize((616,1368),NEAREST).save(large)
    (BASE/'mockup_registration.json').write_text(json.dumps({'ink_positions':ink_positions,
        'button_box':button,'source':'art_src/ui_offer/torn_v2/sources/m3d_map.png',
        'status':'Offline composite; original map ink, heading, CLOSE and header preserved; no map geometry invented.'},indent=2)+'\n')
    return [native,large]


def main():
    paper=reduce(Image.open(BASE/'sources/parchment.png'),(144,324))
    # Remove detached alpha flecks from the painted source, retaining the leaf.
    unseen={(x,y) for y in range(324) for x in range(144) if paper.getpixel((x,y))!=0}
    components=[]
    while unseen:
        first=unseen.pop();component={first};pending=deque([first])
        while pending:
            x,y=pending.popleft()
            for point in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if point in unseen:
                    unseen.remove(point);component.add(point);pending.append(point)
        components.append(component)
    keep=max(components,key=len)
    for y in range(324):
        for x in range(144):
            if (x,y) not in keep:paper.putpixel((x,y),0)
    # Keep every ink/control pixel inside the current panel's eight-pixel
    # side margins on opaque paper. Compress deep side bites into that band;
    # nearest sample the painting so no straight inner backing is introduced.
    original=paper.copy()
    for y in range(12,312):
        xs=[x for x in range(144) if original.getpixel((x,y))!=0]
        assert xs
        left,right=min(xs),max(xs)
        target_left=min(left,7);target_right=max(right,136)
        for x in range(144):
            if x<target_left or x>target_right:
                paper.putpixel((x,y),0)
            else:
                source_x=left+round((x-target_left)*(right-left)/(target_right-target_left))
                ink=original.getpixel((source_x,y))
                paper.putpixel((x,y),ink or 9)
    save(paper,OUT)
    silhouette=indexed(paper.size)
    silhouette.putdata([10 if i else 0 for i in paper.getdata()])
    contact({'torn parchment':paper,'opaque silhouette':silhouette},BASE,columns=2,
        cell=(164,352),title='MAP / ONE LEAF, REAL ALPHA')
    (BASE/'rects.json').write_text(json.dumps({'asset':OUT.relative_to(ROOT).as_posix(),
        'size':[144,324],'rect':[5,16,144,324],'anchor':[0,0],
        'nine_slice_ltrb':[8,12,8,12],'content_padding_ltrb':[8,12,8,12],
        'opaque_safe_rect':[8,12,128,300],'alpha':'binary; transparent outside torn leaf',
        'draw':'STRETCH at native size; no TILE, flat backing, outline or rectangular shadow',
        'preferred':'Native 144x324; existing StyleBoxTexture margins fit. Preserve edge alpha.'},indent=2)+'\n')
    previews=map_mockup(paper)
    manifest([OUT,*BASE.glob('contact_sheet*.png')],BASE/'manifest.json',
        {'rects':'art_src/ui_offer/torn_v2/rects.json','native_size_preferred':True,
         'preview_files':[{'path':p.relative_to(ROOT).as_posix(),
             'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in previews]})
    print('Built torn map parchment, 144x324; binary alpha; current margins preserved.')


if __name__=='__main__':main()
