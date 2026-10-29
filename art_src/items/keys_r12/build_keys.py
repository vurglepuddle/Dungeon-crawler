"""R12 keys: offline painted material, editable native shapes, fixed palette.

The accepted key painting supplies metal texture. Shapes are intentionally
authored, not a colour swap, and the 16px silhouettes are drawn at 16px first.
Only r12-owned output files are written; no old item/hand/Fall builder runs.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
import hashlib
import importlib.util
import json
import math
from PIL import Image, ImageDraw
from scipy import ndimage
import numpy as np
from pipeline import ROOT, RGB, TABLE, NEAREST, indexed, reduce, save, label, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/items'
METALS = ('iron','bronze','gold')
SIZES = ((64,48),(40,30),(24,18))
RAMPS = {'iron':(2,3,4,5,7),'bronze':(19,21,28,29,24),'gold':(20,23,25,26,10)}
INPUTS = set()


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    path = Path(path); INPUTS.add(path)
    return Image.open(path).copy()


def material_patch():
    path = BASE/'sources/accepted_key_metal_patch.png'
    if not path.exists():
        original = read(ROOT/'art_src/items/sources/key.png').convert('RGBA')
        w,h = original.size
        patch = original.crop((round(w*.23),round(h*.10),round(w*.36),round(h*.21)))
        # The top of the accepted bow: pitted gold paint, no new generation.
        patch.save(path)
    return read(path)


def painted(mask,metal,ui=False):
    """Remap accepted paint to a quiet ramp and shade native silhouette edges."""
    patch = material_patch().convert('RGBA')
    patch = patch.resize(mask.size,NEAREST)
    ramp = RAMPS[metal]; result = indexed(mask.size)
    a = np.array(mask)>0
    for y in range(mask.height):
        for x in range(mask.width):
            if not a[y,x]: continue
            r,g,b,alpha = patch.getpixel((x,y))
            lum = (2*r+4*g+b)/7 if alpha>=128 else 160
            # Broad material clusters: two interior tones for UI, three in world.
            tone = (2 if lum<180 else 3) if ui else (1 if lum<120 else 2 if lum<190 else 3)
            ink = ramp[tone]
            top = y==0 or not a[y-1,x]
            left = x==0 or not a[y,x-1]
            bottom = y==mask.height-1 or not a[y+1,x]
            right = x==mask.width-1 or not a[y,x+1]
            if bottom or right: ink = ramp[0]
            if top or left: ink = ramp[3 if ui else 4]
            result.putpixel((x,y),ink)
    return result


def icon(metal):
    m = Image.new('L',(16,16)); d = ImageDraw.Draw(m)
    if metal == 'iron':
        d.polygon([(1,1),(6,1),(8,3),(8,7),(6,9),(1,8),(0,6),(0,3)],fill=255)
        d.rectangle((3,3,5,6),fill=0)
        d.polygon([(6,6),(8,6),(14,12),(12,14),(6,8)],fill=255)
        d.polygon([(11,10),(15,12),(13,15),(10,13)],fill=255)
        d.point((11,14),fill=0)
    elif metal == 'bronze':
        d.ellipse((0,1,8,9),fill=255); d.ellipse((3,4,5,6),fill=0)
        d.polygon([(6,6),(8,6),(14,12),(12,14),(6,8)],fill=255)
        d.polygon([(12,9),(15,11),(14,12),(13,11),(12,12),(13,13),(12,14),(11,13),(10,14),(9,13)],fill=255)
        d.point((14,12),fill=0); d.point((12,14),fill=0)
        d.line((13,14,13,15),fill=255)
    else:
        # Three solid lobes around one open bow, distinct even in monochrome.
        d.ellipse((2,0,6,4),fill=255)
        d.ellipse((0,3,4,7),fill=255); d.ellipse((4,3,8,7),fill=255)
        d.rectangle((3,3,5,8),fill=255); d.rectangle((3,4,5,5),fill=0)
        d.polygon([(6,6),(8,6),(14,12),(12,14),(6,8)],fill=255)
        d.line([(8,7),(7,9)],fill=255,width=2)
        d.polygon([(12,9),(15,11),(15,13),(13,13),(13,15),(10,13),(11,11)],fill=255)
        d.point((14,12),fill=0)
    result = painted(m,metal,ui=True)
    # One broad lit shaft edge; subordinate texture never cuts the silhouette.
    d = ImageDraw.Draw(result)
    d.line([(7,7),(11,11)],fill=RAMPS[metal][3],width=1)
    # Keep this authored highlight inside the mask.
    for y in range(16):
        for x in range(16):
            if not m.getpixel((x,y)): result.putpixel((x,y),0)
    return result


def world_mask(metal):
    # Draw in local key coordinates at 4x, then give it the accepted diagonal
    # floor pose. Bow/bit geometry is shared conceptually with the native icon.
    s = 4; m = Image.new('L',(76*s,40*s)); d = ImageDraw.Draw(m)
    def poly(points,ink=255): d.polygon([(x*s,y*s) for x,y in points],fill=ink)
    def rect(box,ink=255): d.rectangle(tuple(v*s for v in box),fill=ink)
    def oval(box,ink=255): d.ellipse(tuple(v*s for v in box),fill=ink)
    if metal == 'iron':
        poly([(5,4),(22,4),(25,7),(25,22),(22,25),(5,25),(2,22),(2,7)])
        rect((9,10,18,19),0)
    elif metal == 'bronze':
        oval((1,2,27,28)); oval((8,9,20,21),0)
    else:
        oval((8,0,21,13)); oval((0,9,14,23)); oval((15,9,29,23))
        poly([(6,14),(23,14),(26,25),(18,29),(8,26)])
        oval((10,12,19,21),0)
    rect((24,12,68,18))
    if metal == 'iron':
        rect((58,15,70,27)); rect((57,22,64,27),0)
    elif metal == 'bronze':
        for x,height in ((55,25),(61,24),(67,27)): rect((x,15,x+3,height))
    else:
        rect((46,9,50,21))
        poly([(58,10),(71,10),(73,14),(71,18),(71,28),(66,28),(66,23),(61,23),(61,27),(57,27)])
        rect((68,19,72,21),0)
    m = m.rotate(-35,resample=NEAREST,expand=True)
    return m.crop(m.getbbox())


def world(metal):
    shape = world_mask(metal)
    scale = min(40/shape.width,26/shape.height)
    native = shape.resize((round(shape.width*scale),round(shape.height*scale)),NEAREST)
    master = Image.new('L',SIZES[0]); master.paste(native,((64-native.width)//2,47-native.height))
    frames = []
    for size in SIZES:
        mask = master.resize(size,NEAREST)
        box = mask.getbbox(); body = mask.crop(box)
        mask = Image.new('L',size)
        mask.paste(body,(box[0],size[1]-1-body.height))
        im = painted(mask,metal)
        frames.append(im)
    return frames


def pair(im,base,stem):
    base.mkdir(parents=True,exist_ok=True); paths = []
    for suffix,frame in [('native',im),('4x',im.resize((im.width*4,im.height*4),NEAREST))]:
        p = base/f'{stem}_{suffix}.png'
        if frame.mode == 'P': save(frame,p)
        else: frame.save(p)
        paths.append(p)
    return paths


def composite(canvas,im,at):
    canvas.paste(im,at,im.convert('RGBA').getchannel('A'))


def reviews(icons,worlds):
    leather = reduce(read(ROOT/'assets/art/ui_offer/pack_leather.png'),(152,22))
    belt = read(ROOT/'assets/art/ui_offer/belt_loops.png')
    belt = reduce(belt,belt.size)
    slate = read(ROOT/'assets/art/ui_offer/message_slate.png')
    slate = reduce(slate,slate.size)
    sheet = indexed((550,352),1)
    label(sheet,(8,5),'THREE METALS / SAME KEY IN PACK, BELT AND WORLD',25)
    label(sheet,(8,31),'METAL    PACK  BELT  SLATE  SHAPE       D1       D2     D3',8)
    for row,metal in enumerate(METALS):
        y = 58+row*82; im = icons[metal]
        label(sheet,(8,y+16),metal.upper(),8)
        sheet.paste(leather.crop((19,0,41,22)),(85,y+12)); composite(sheet,im,(88,y+15))
        sheet.paste(belt.crop((2,0,24,22)),(120,y+12)); composite(sheet,im,(123,y+15))
        sheet.paste(slate.crop((12,4,34,26)),(155,y+12)); composite(sheet,im,(158,y+15))
        mono = im.copy(); mono.putdata([8 if v else 0 for v in im.getdata()]); composite(sheet,mono,(200,y+15))
        for depth,x in enumerate((255,348,420)):
            frame = worlds[(metal,depth+1)]
            composite(sheet,frame,(x,y+54-frame.height))
        label(sheet,(480,y+24),'STATIC',6)
    # Real tray alongside accepted icons; the old key is read-only reference.
    sheet.paste(leather,(8,313))
    accepted = [('stone',None),('bone',None),('key','iron'),('key','bronze'),('key','gold'),('lamp',None),('key',None)]
    for i,(kind,metal) in enumerate(accepted):
        im = icons[metal] if metal else reduce(read(OUT/f'icon_{kind}_16.png'),(16,16))
        composite(sheet,im,(10+i*19,316))
    label(sheet,(177,313),'REAL TRAY / LAST KEY = ACCEPTED OLD',8)
    return pair(sheet,BASE,'contact_sheet')


def protect():
    snapshot = BASE/'preserved_hashes.json'
    if not snapshot.exists():
        prefixes = ('icon_key_iron_','icon_key_bronze_','icon_key_gold_','item_key_iron_','item_key_bronze_','item_key_gold_')
        paths = list(OUT.glob('*.png'))+list((ROOT/'assets/art/icons').glob('*.png'))
        paths += list((ROOT/'assets/art/hands').glob('*.png'))
        paths += list((ROOT/'assets/art/fx').glob('fall_crumble_*.png'))
        paths += list((ROOT/'assets/art/env').glob('*.png'))
        paths = [p for p in paths if not p.name.startswith(prefixes)]
        snapshot.write_text(json.dumps({p.relative_to(ROOT).as_posix():sha(p) for p in sorted(paths)},indent=2)+'\n')
    return json.loads(snapshot.read_text())


def verify(icons,worlds):
    silhouettes = []
    for metal in METALS:
        im = icons[metal]; a = np.array(im)!=0
        assert im.size == (16,16)
        count = ndimage.label(a,structure=np.ones((3,3)))[1]
        assert count == 1,(metal,'disconnected icon')
        assert (ndimage.binary_fill_holes(a)&~a).any(),(metal,'closed bow')
        silhouettes.append(a.tobytes())
        for depth,size in enumerate(SIZES,1):
            im = worlds[(metal,depth)]; assert im.size == size
            assert im.getbbox()[3] <= size[1]-1,'One transparent bottom row'
            a = np.array(im)!=0
            assert ndimage.label(a,structure=np.ones((3,3)))[1] == 1,(metal,depth,'disconnected world')
            assert (ndimage.binary_fill_holes(a)&~a).any(),(metal,depth,'closed world bow')
    assert len(set(silhouettes)) == 3,'Silhouette must distinguish all metals'


def main():
    (BASE/'sources').mkdir(parents=True,exist_ok=True)
    preserved = protect()
    icons = {m:icon(m) for m in METALS}; worlds = {}
    for metal in METALS:
        for depth,im in enumerate(world(metal),1): worlds[(metal,depth)] = im
    verify(icons,worlds)
    paths,records = [],[]
    for metal,im in icons.items():
        p = OUT/f'icon_key_{metal}_16.png'; save(im,p); paths.append(p)
        records.append({'path':p.relative_to(ROOT).as_posix(),'kind':f'key_{metal}','use':'pack, belt, card','size':[16,16],'anchor':[8,8],'metal':metal})
    for (metal,depth),im in worlds.items():
        p = OUT/f'item_key_{metal}_d{depth}.png'; save(im,p); paths.append(p)
        records.append({'path':p.relative_to(ROOT).as_posix(),'kind':f'key_{metal}','metal':metal,'depth':depth,'size':list(im.size),'anchor':[im.width//2,im.height],
            'shadow':'renderer; no baked shadow','bottom_margin_px':1,'use':'floor pickup; static'})
    previews = reviews(icons,worlds)
    (BASE/'layout.json').write_text(json.dumps({'schema_version':1,'metal_order':list(METALS),'registrations':records,
        'belt':'Same native16x16 icon as pack/card; no separate belt art or baked count/selection badge.',
        'key_identity':'A owns key/door IDs and consumption. Metal selects art only; same metal does not imply same key ID.',
        'source':'Accepted art_src/items/sources/key.png metal patch; original key icons/world files are preserved.',
        'filter':'nearest','ramp':RAMPS,'animation':'none'},indent=2)+'\n')
    # The lock builder shares these paints, not another image/model dependency.
    lock_path = ROOT/'art_src/fixtures/locks_r12/build_locks.py'
    spec = importlib.util.spec_from_file_location('r12_locks',lock_path)
    locks = importlib.util.module_from_spec(spec); spec.loader.exec_module(locks)
    lock_count = locks.main(sys.modules[__name__])
    assert all(sha(ROOT/p)==expected for p,expected in preserved.items()),'Protected old art changed'
    deps = sorted(INPUTS|{ROOT/'art_src/items/sources/key.png',BASE/'build_keys.py',lock_path,BASE.parents[1]/'env/pipeline.py'})
    manifest(paths+previews,BASE/'manifest.json',{'runtime_count':12,'layout':'layout.json','generation':'None; offline editable silhouettes with accepted painted metal.',
        'dependency_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in deps],
        'preserved_existing_pngs':len(preserved),'lock_runtime_count':lock_count})
    print(f'R12: 3 UI icons shared by pack/belt +9 world frames +{lock_count} family lock overlays; {len(preserved)} protected PNGs unchanged.')


if __name__ == '__main__': main()
