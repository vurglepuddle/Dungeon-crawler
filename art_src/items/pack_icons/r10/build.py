"""Native 16px silhouette revision; accepted r9 icons are read-only.

Owner art direction: mass/outline first, painted material in a few clusters.
No new image generation; all shapes are editable integer-pixel geometry.
"""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
import hashlib
import json
import math
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
import build_pack_icons as b

ROOT=b.ROOT
BASE=Path(__file__).resolve().parent
R9=BASE.parent/'r9'
OUT=b.OUT
REWORK=['knife','shard','coat','coat_spent','torch_unlit','torch_lit','seal']
ACCEPTED=['stone','bone','bread','clapper','lamp','key','tonic','club']
ASSETS=[]


def read(path):return b.indexed(b.read(path))


def knife():
    im=b.canvas((16,16));d=ImageDraw.Draw(im)
    # Continuous broad steel blade, one pale edge, one quiet rust patch.
    d.polygon([(6,7),(8,4),(14,1),(14,6),(10,10)],fill=2)
    d.polygon([(7,7),(9,5),(13,2),(13,6),(10,9)],fill=6)
    d.polygon([(8,6),(10,4),(13,2),(11,6),(8,8)],fill=8)
    d.line([(7,7),(10,4),(13,2)],fill=9)
    d.line([(11,6),(10,7)],fill=28)
    # A substantial leather grip and separate brass crossguard.
    d.polygon([(2,11),(4,9),(8,12),(5,14),(2,14),(1,13)],fill=2)
    d.polygon([(2,12),(4,10),(6,12),(4,13),(2,13)],fill=22)
    d.line([(2,12),(4,10),(5,11)],fill=24)
    d.polygon([(4,8),(5,7),(10,11),(9,12)],fill=2)
    d.line([(5,8),(9,11)],fill=29)
    # Join the guard/blade/grip corners into solid material, with no accidental
    # one-pixel transparent pinholes between the diagonal polygons.
    occupied=np.array(im)!=0
    holes=ndimage.binary_fill_holes(occupied)&~occupied
    for y,x in np.argwhere(holes):im.putpixel((int(x),int(y)),2)
    return im


def shard():
    im=b.canvas((16,16));d=ImageDraw.Draw(im)
    d.polygon([(2,9),(4,3),(11,1),(14,6),(12,8),(13,12),(7,14),(5,11),(2,12)],fill=2)
    d.polygon([(3,9),(5,4),(11,2),(13,6),(11,8),(12,11),(7,13),(6,10),(3,11)],fill=13)
    d.polygon([(5,4),(11,2),(10,7),(5,10),(3,10)],fill=15)
    d.polygon([(5,4),(10,2),(7,8),(4,10)],fill=17)
    return im


def coat():
    old=read(ROOT/'assets/art/icons/coat.png')
    # EXACT old garment coverage: shoulders, sleeves and a full upright hem.
    a=np.array(old)!=0
    im=b.canvas((16,16))
    for y in range(16):
        for x in range(16):
            if not a[y,x]:continue
            edge=any(xx<0 or xx>=16 or yy<0 or yy>=16 or not a[yy,xx]
                     for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)])
            im.putpixel((x,y),2 if edge else 14 if x<8 else 13)
    d=ImageDraw.Draw(im)
    # Broad lamp-lit shoulder/left panel: no random quilting speckles.
    d.line([(4,3),(6,2)],fill=16)
    d.line((2,4,3,6),fill=16)
    d.rectangle((4,5,6,11),fill=14)
    d.line([(4,7),(6,9)],fill=13)
    d.line([(4,10),(6,12)],fill=13)
    d.line([(10,6),(11,7)],fill=14)
    d.line((8,3,8,12),fill=2)
    d.line((9,4,9,12),fill=28)
    # All native edits stay within the old silhouette, including sleeve ends.
    for y in range(16):
        for x in range(16):
            if not a[y,x]:im.putpixel((x,y),0)
    return im


def spent_coat(fresh):
    im=fresh.copy();d=ImageDraw.Draw(im)
    # Two grouped tears. Preserve the WHOLE garment outline and cloth mass.
    d.line([(3,5),(4,6),(5,7),(6,7)],fill=1)
    d.line([(3,5),(3,6),(4,6)],fill=9)
    d.point((4,7),fill=8)
    d.line([(10,9),(11,10),(10,11),(11,12)],fill=1)
    d.line([(10,10),(10,11),(9,11)],fill=9)
    return im


def torch():
    im=b.canvas((16,16));d=ImageDraw.Draw(im)
    d.polygon([(5,9),(10,9),(10,14),(5,14)],fill=2)
    d.rectangle((6,9,9,13),fill=20)
    d.line((6,10,6,13),fill=24)
    # The bound fan has mass; three long reed highlights replace texture.
    d.polygon([(3,4),(4,2),(6,3),(7,2),(9,3),(11,2),(12,4),(11,9),(10,10),(5,10),(3,8)],fill=2)
    d.polygon([(4,4),(5,3),(7,4),(8,3),(10,4),(11,3),(11,7),(10,9),(5,9),(4,7)],fill=29)
    d.line((5,4,5,7),fill=9)
    d.line((7,3,7,7),fill=9)
    d.line((10,4,9,7),fill=8)
    d.line((4,6,11,8),fill=18)
    d.line((5,7,10,9),fill=28)
    d.rectangle((9,7,10,8),fill=18)
    d.point((9,7),fill=29)
    return im


def lit_torch(cold):
    im=cold.copy();d=ImageDraw.Draw(im)
    d.polygon([(4,5),(5,2),(7,0),(9,1),(11,4),(10,6),(5,6)],fill=2)
    d.polygon([(5,5),(6,2),(7,1),(8,2),(10,4),(9,5)],fill=23)
    d.polygon([(6,5),(6,3),(7,2),(9,4),(8,5)],fill=25)
    d.line((7,3,7,5),fill=10)
    return im


def seal():
    source=read(ROOT/'art_src/icon/dawn_seal_disc_46.png')
    # Classify the accepted disc's actual material regions BEFORE area-majority
    # reduction; preserve ring/rays/core and suppress isolated bright flecks.
    classes={i:(2 if i in [1,2,3,4,5,6] else 28 if i in [18,19,20,21,30,31] else
                13 if 11<=i<=17 else 10 if i in [9,10,26] else 24)
             for i in range(1,32)}
    pixels=np.array(source)
    im=b.canvas((16,16))
    for v in range(14):
        for u in range(14):
            x0,x1=round(u*46/14),round((u+1)*46/14)
            y0,y1=round(v*46/14),round((v+1)*46/14)
            region=pixels[y0:y1,x0:x1].ravel()
            opaque=region[region!=0]
            if len(opaque)<len(region)*.34:continue
            values=[classes[int(i)] for i in opaque]
            counts={ink:values.count(ink) for ink in set(values)}
            ink=max(counts,key=lambda c:(counts[c],c in [24,10]))
            # The source's cream core stays bright; outside it the launcher
            # highlights belong to calm gold rays, not many white sparkles.
            radius=math.hypot(u-6.5,v-6.5)
            if ink==10 and radius>2.65:ink=24
            if ink==28 and radius>5.2 and u+v<13:ink=24
            im.putpixel((u+1,v+1),ink)
    # Restore the source's simple gold arch inside the bright core, which a
    # three-source-pixel area vote otherwise averages into the cream field.
    ImageDraw.Draw(im).line([(6,8),(7,7),(8,7),(9,8)],fill=24)
    silhouette=np.array(im)!=0
    # One clean outline outside the sampled disc, without eating its gold ring.
    out=im.copy()
    for y in range(16):
        for x in range(16):
            if not silhouette[y,x] and any(0<=xx<16 and 0<=yy<16 and silhouette[yy,xx]
                    for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):out.putpixel((x,y),2)
    return out


def club_alt():
    im=b.canvas((16,16));d=ImageDraw.Draw(im)
    d.line((3,13,9,6),fill=2,width=5)
    d.line((3,13,9,6),fill=22,width=3)
    d.line((2,12,7,7),fill=24)
    d.polygon([(8,1),(12,1),(14,3),(14,7),(11,9),(7,7),(6,4)],fill=2)
    d.polygon([(8,2),(12,2),(13,4),(13,6),(11,8),(8,6),(7,4)],fill=5)
    d.polygon([(8,2),(11,2),(12,4),(9,5),(7,4)],fill=8)
    d.polygon([(10,5),(13,4),(13,6),(11,8),(10,7)],fill=4)
    return im


def output(im,kind,alt=False):
    path=OUT/f'icon_{kind}_16{"_alt" if alt else ""}.png'
    record=b.save(im,path)
    record.update(kind=kind,revision='r10',anchor=[8,8],frame_ms=0,
                  opaque_bounds=list(im.getbbox()),optional=alt,
                  r9_reference=f'art_src/items/pack_icons/r9/icon_{kind}_16.png')
    ASSETS.append(record)


def all_icons():return {kind:read(OUT/f'icon_{kind}_16.png') for kind in b.ORDER}


def sheet(name,im):
    b.save(im,BASE/f'{name}_native.png')
    b.save(im.resize((im.width*4,im.height*4),b.NEAREST),BASE/f'{name}_4x.png')


def reviews(icons,alt):
    pack=read(ROOT/'assets/art/ui_offer/pack_leather.png')
    slate=read(ROOT/'assets/art/ui/slate.png')
    kinds=REWORK+['club']
    grid=b.canvas((384,42+4*79),1)
    b.label(grid,(8,2),'R10 / PACK r9-r10 / SLATE r9-r10',25)
    b.label(grid,(8,19),'Club: optional alt / accepted stays',8)
    for i,kind in enumerate(kinds):
        x=(i%2)*192;y=42+(i//2)*79
        b.label(grid,(x+8,y),kind.replace('torch_','reed '),9)
        before=read(R9/f'icon_{kind}_16.png');after=alt if kind=='club' else icons[kind]
        old_slot=pack.crop(((i%8)*19,0,(i%8+1)*19,22))
        for j,(bg,icon) in enumerate([(old_slot,before),(old_slot,after),
                     (b.nine(slate,(26,22)),before),(b.nine(slate,(26,22)),after)]):
            tile=bg.copy();b.paste(tile,icon,((tile.width-16)//2,3))
            b.paste(grid,tile,(x+10+j*43,y+21))
        b.label(grid,(x+8,y+45),'r9   r10   r9   r10',8)
    sheet('icons_r9_r10_context',grid)
    rows=[]
    for group in range(2):
        entries=[]
        for rev in ['r9','r10']:
            tray=pack.copy()
            for i,kind in enumerate(b.ORDER[group*8:(group+1)*8]):
                icon=read(R9/f'icon_{kind}_16.png') if rev=='r9' else icons[kind]
                b.paste(tray,icon,(i*19+1,3))
            entries.append((rev,tray))
        rows.append((f'Whole family / set {group+1}',entries))
    rows.append(('Accepted family / untouched',[(k,icons[k]) for k in ['stone','bone','bread','clapper','lamp','key','tonic','club']]))
    b.contact(BASE/'icons_r9_r10_pack_4x.png','NATIVE PACK / r9-r10 / ACCEPTED NEIGHBOURS',rows)
    rows=[]
    for n in range(3):
        entries=[]
        for rev in ['r9','r10']:
            card=b.nine(slate,(146,132));b.label(card,(6,2),rev.upper(),25)
            for i,kind in enumerate(b.ORDER[n*5:(n+1)*5]):
                y=23+i*21
                icon=read(R9/f'icon_{kind}_16.png') if rev=='r9' else icons[kind]
                b.paste(card,icon,(6,y));b.label(card,(27,y),b.NAMES[kind],9)
            entries.append((rev,card))
        rows.append((f'Family on slate / set {n+1}',entries))
    b.contact(BASE/'icons_r9_r10_card_4x.png','R10 / SLATE / r9-r10 AND ACCEPTED',rows)
    b.contact(BASE/'icons_r10_silhouettes_4x.png','R10 / SHAPE FIRST / 16px',[
        (kind.replace('torch_','reed '),[('r9',read(R9/f'icon_{kind}_16.png')),
             ('r10',alt if kind=='club' else icons[kind]),
             ('silhouette',silhouette(alt if kind=='club' else icons[kind]))]) for kind in kinds])
    disc=read(ROOT/'art_src/icon/dawn_seal_disc_46.png')
    b.contact(BASE/'seal_launcher_match_4x.png','SEAL / EXACT LAUNCHER DISC SOURCE',[
        ('Source and pack revisions',[('disc 46',disc),('r9',read(R9/'icon_seal_16.png')),('r10',icons['seal'])])])


def silhouette(im):
    out=im.copy();out.putdata([9 if i else 0 for i in im.getdata()]);return out


def main():
    fresh=coat();cold=torch()
    images={'knife':knife(),'shard':shard(),'coat':fresh,'coat_spent':spent_coat(fresh),
            'torch_unlit':cold,'torch_lit':lit_torch(cold),'seal':seal()}
    accepted_before={k:hashlib.sha256((OUT/f'icon_{k}_16.png').read_bytes()).hexdigest() for k in ACCEPTED}
    for kind,im in images.items():output(im,kind)
    alt=club_alt();output(alt,'club',True)
    icons=all_icons();reviews(icons,alt)
    assert all(hashlib.sha256((OUT/f'icon_{k}_16.png').read_bytes()).hexdigest()==digest for k,digest in accepted_before.items())
    b.manifest(BASE/'manifest.json',{'revision':'r10','assets':ASSETS,
        'accepted_unchanged':accepted_before,
        'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(b.INPUTS)},
        'method':'Editable integer silhouettes and broad painted-material palette clusters; source-disc area-majority reduction for Seal.',
        'state_contract':'Coats share exact old-code coverage. Reeds identical below flame. All static 16px, centre (8,8).',
        'runtime_files_written':len(ASSETS),'accepted_runtime_files_written':0})
    # The top-level receipt follows the CURRENT 15-kind set. Its r9 copy is
    # frozen, so future verification never mistakes an obsolete hash for r10.
    original=json.loads((R9/'manifest.json').read_text())
    revised={a['kind']:a for a in ASSETS if not a['optional']}
    original['assets']=[revised.get(a['kind'],a) for a in original['assets']]
    original.update(revision='r10',r9_archive='art_src/items/pack_icons/r9/',
                    optional_assets=[a for a in ASSETS if a['optional']],
                    revision_manifest='art_src/items/pack_icons/r10/manifest.json',
                    current_reviews='art_src/items/pack_icons/r10/*_4x.png',
                    method='r9 accepted paintings plus r10 silhouette/cluster revisions; launcher disc source for Seal',
                    state_contract='Coats share the old garment silhouette; reed body registered below flame; static 16px.')
    original['sources'].update({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in sorted(b.INPUTS) if p.parent!=OUT})
    b.manifest(BASE.parent/'manifest.json',original)
    print('r10: seven revised state PNGs + optional club; eight accepted runtime icons preserved')


if __name__=='__main__':main()
