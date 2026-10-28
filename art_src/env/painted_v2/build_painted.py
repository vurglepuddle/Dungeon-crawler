"""Primary wall dressing: the owner's original painted 64px wall, preserved.

Only painted_f[12]_*.png and this folder's review files are written. The old
f[12]_*.png set remains an alternate. All scale sampling uses nearest.
"""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import json
import hashlib
from PIL import Image,ImageDraw
from pipeline import ROOT,RGB,NEAREST,indexed,save,contact,manifest
from build_env import dressing,preserve_edges
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/env'

def nearest(rgb):
    return min(range(1,32),key=lambda i:2*(rgb[0]-RGB[i][0])**2+4*(rgb[1]-RGB[i][1])**2+(rgb[2]-RGB[i][2])**2)

def seam_repair(original):
    im=original.copy()
    # Change only the outermost ring. The complete 62x62 interior is exact.
    for y in range(64):
        a,b=RGB[original.getpixel((0,y))],RGB[original.getpixel((63,y))]
        ink=nearest(tuple((a[i]+b[i])//2 for i in range(3)))
        im.putpixel((0,y),ink);im.putpixel((63,y),ink)
    for x in range(64):
        a,b=RGB[im.getpixel((x,0))],RGB[im.getpixel((x,63))]
        ink=nearest(tuple((a[i]+b[i])//2 for i in range(3)))
        im.putpixel((x,0),ink);im.putpixel((x,63),ink)
    return im

def deep_repaint(source):
    # Preserve every stone, chip, crack and mortar boundary. No new brick grid.
    dark={1:1,2:1,3:2,4:3,5:4,6:5,7:6,8:7,9:8,10:9,
          11:11,12:11,13:12,14:13,15:14,16:15,17:16,
          18:18,19:18,20:19,21:20,22:21,23:22,24:23,25:24,26:25,27:18,28:27,29:28,30:2,31:30}
    wet={2:11,3:11,4:12,5:13,6:14,7:15,8:16}
    im=source.copy()
    for y in range(64):
        for x in range(64):
            ink=source.getpixel((x,y))
            # Broad damp trails follow the same painted stone grain.
            water=((x-47)**2/100+(y-35)**2/550<1) or (x<10 and y>28) or (29<x<38 and y>45)
            im.putpixel((x,y),wet.get(ink,dark.get(ink,ink)) if water else dark.get(ink,ink))
    return seam_repair(im)

def subtle_variant(base,number):
    im=base.copy()
    if number==1:
        # A shifted crop of one stone interior, not a shifted masonry course.
        for y in range(4,13):
            for x in range(4,18):
                ink=base.getpixel((x+24,y))
                if ink in range(4,9) and base.getpixel((x,y)) in range(4,9):im.putpixel((x,y),ink)
        for y in range(38,45):
            for x in range(27,41):
                ink=base.getpixel((x-8,y))
                if ink in range(4,9) and base.getpixel((x,y)) in range(4,9):im.putpixel((x,y),ink)
    elif number==2:
        stain={4:11,5:12,6:13,7:14}
        for y in range(21,54):
            for x in range(34,52):
                if abs(x-43)<max(1,7-(y-21)//6):
                    old=base.getpixel((x,y))
                    if (x+y)%3!=0:im.putpixel((x,y),stain.get(old,old))
    return preserve_edges(im,base)

def main():
    original=Image.open(BASE/'sources/stone_wall_original_64.png')
    assert original.mode=='P' and original.size==(64,64)
    assert original.convert('RGBA').tobytes()==Image.open(ROOT/'assets/art/stone_wall.png').convert('RGBA').tobytes()
    abbey=seam_repair(original)
    assert abbey.crop((1,1,63,63)).tobytes()==original.crop((1,1,63,63)).tobytes()
    same=sum(a==b for a,b in zip(original.getdata(),abbey.getdata()))
    assert same>=3844
    combined={}
    for floor,base in [(1,abbey),(2,deep_repaint(original))]:
        assets={f'plain_{n}':subtle_variant(base,n) for n in range(3)}
        for name in ('sconce_0','sconce_1','crack','damp','chains','tapestry','drain','arch','door'):
            assets[name]=dressing(base,name,floor)
        for name,im in assets.items():
            for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
                assert im.crop(box).tobytes()==base.crop(box).tobytes(),name
            assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes()
            assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes()
            save(im,OUT/f'painted_f{floor}_{name}.png')
        contact(assets,BASE/f'floor{floor}',columns=4,cell=(124,96),title=f'PAINTED WALL / FLOOR {floor}')
        repeat=indexed((256,192),1)
        for n,name in enumerate(['plain_0','plain_1','plain_2','plain_0','sconce_0','crack','damp','chains','tapestry','drain','arch','door']):repeat.paste(assets[name],((n%4)*64,(n//4)*64))
        save(repeat,BASE/f'floor{floor}/repeat_native.png')
        save(repeat.resize((1024,768),NEAREST),BASE/f'floor{floor}/repeat_4x.png')
        combined.update({f'F{floor} {k}':v for k,v in assets.items()})
    contact(combined,BASE,columns=6,cell=(124,96),title='UNDERCROFT / PRIMARY PAINTED WALLS')
    comparison={'original':original,'primary':abbey,'older wet':deep_repaint(original)}
    contact(comparison,BASE/'comparison',columns=3,cell=(124,96),title='FAVOURITE WALL / SAME STONES')
    manifest(list(OUT.glob('painted_*.png'))+list(BASE.rglob('*native.png'))+list(BASE.rglob('*4x.png')),BASE/'manifest.json',
        {'primary_prefix':'painted_fN_','alternate_prefix':'fN_','original_unchanged_pixels':same,
         'original_total_pixels':4096,'interior_contract':'The full 62x62 interior of floor-one plain_0 is pixel-exact to stone_wall.png.',
         'floor2_method':'Palette repaint and broad damp trails on original geometry; no new masonry.',
         'sconce_fps':4})
    preserved=json.loads((BASE/'preserved_hashes.json').read_text())
    assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==digest for p,digest in preserved.items())
    print(f'Primary painted walls: 24 textures; {same}/4096 original base pixels exact; original assets preserved.')

if __name__=='__main__':main()
