"""Family-registered metal hasps. Run through items/keys_r12/build_keys.py."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
import json
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
# UV positions of the dark keyhole, not sprite feet. Original door art stays.
KEYHOLES = {1:(31,41),2:(32,40),3:(32,40),4:(32,40)}


def plate(b,metal,family):
    cx,cy = KEYHOLES[family]
    # Half-size revision: the native hasp is7-9px wide,10-11px tall.
    # Author at its final scale so the round/crested outlines survive40/24px.
    local = Image.new('L',(9,11)); d = ImageDraw.Draw(local)
    if metal == 'iron':
        d.rectangle((1,1,7,10),fill=255)
    elif metal == 'bronze':
        d.ellipse((0,0,7,10),fill=255)
    else:
        d.ellipse((3,0,5,3),fill=255)
        d.ellipse((0,1,3,4),fill=255); d.ellipse((5,1,8,4),fill=255)
        d.polygon([(2,3),(6,3),(7,5),(7,8),(4,10),(1,8),(1,5)],fill=255)
    # Same paint sample and ramps as the keys, no arbitrary RGB or new texture.
    material = b.painted(local,metal)
    d = ImageDraw.Draw(material); ramp = b.RAMPS[metal]
    # Quiet fasteners and a tiny recessed keyhole, not a shield-sized symbol.
    for x,y in ((2,2),(6,2),(2,8),(6,8)):
        if local.getpixel((x,y)):
            d.point((x,y),fill=ramp[0]); d.point((x,y-1),fill=ramp[3])
    d.rectangle((3,3,4,4),fill=1)
    d.line((4,4,4,7),fill=1,width=1)
    d.point((5,6),fill=ramp[3])
    out = b.indexed((64,64))
    # Local keyhole centre4,5: original family registrations are unchanged.
    b.composite(out,material,(cx-4,cy-5))
    return out


def main(b):
    assets,paths,records = {},[],[]
    for family in range(1,5):
        for metal in b.METALS:
            im = plate(b,metal,family)
            p = b.ROOT/f'assets/art/fixtures/lock_plate_f{family}_{metal}_64.png'
            b.save(im,p); paths.append(p); assets[(family,metal)] = im
            records.append({'path':p.relative_to(b.ROOT).as_posix(),'family':family,'metal':metal,
                'size':[64,64],'anchor':[0,0],'keyhole_uv':list(KEYHOLES[family]),'opaque_bounds':im.getbbox(),
                'closed_door':f'assets/art/env/painted_f{family}_door_v2.png','state':'closed only; hide on open door',
                'sampling':'Compose on canonical64x64 door before nearest wall-column projection; no sprite/billboard pass.'})
    overview = b.indexed((392,484),1)
    b.label(overview,(8,5),'METAL HASPS / F1-F4 / REGISTERED WALL UV',25)
    depths = b.indexed((688,352),1)
    previews = []
    for row,family in enumerate(range(1,5)):
        door = b.read(b.ROOT/f'assets/art/env/painted_f{family}_door_v2.png')
        sheet = b.indexed((344,176),1)
        b.label(sheet,(8,5),f'F{family} / IRON, BRONZE, GOLD',25)
        b.label(overview,(8,34+row*108),f'F{family}',8)
        for col,metal in enumerate(b.METALS):
            face = door.copy(); b.composite(face,assets[(family,metal)],(0,0))
            x = 8+col*112
            b.label(sheet,(x,25),metal.upper(),8)
            sheet.paste(face,(x+16,46))
            sheet.paste(face.resize((40,40),b.NEAREST),(x+4,120))
            sheet.paste(face.resize((24,24),b.NEAREST),(x+56,128))
            b.label(sheet,(x+2,159),'64 / 40 / 24',6)
            overview.paste(face,(48+col*112,34+row*108))
            # Overlay-only inset makes the exact plate bounds inspectable.
            overlay = assets[(family,metal)]
            detail = overlay.crop(overlay.getbbox())
            b.composite(overview,detail,(69+col*112,101+row*108))
        previews += b.pair(sheet,BASE,f'lock_doors_f{family}')
        depths.paste(sheet,(((family-1)%2)*344,((family-1)//2)*176))
    previews += b.pair(overview,BASE,'contact_sheet')
    previews += b.pair(depths,BASE,'lock_doors_all')
    (BASE/'layout.json').write_text(json.dumps({'schema_version':1,'canvas':[64,64],'anchor':[0,0],
        'keyhole_uv':{str(k):list(v) for k,v in KEYHOLES.items()},'registrations':records,
        'offset':'Already baked per family; runtime offset always0,0.',
        'filter':'nearest','frames':1,'timing':'static','open_state':'Remove overlay when door opens; use existing open portal art.',
        'lighting':'Apply same distance/light modulation as closed door, not glint emission.',
        'door_family':'Use the family actually selected for the closed door, including per-block families; never raw floor number. Winding fallback is f4.',
        'gameplay':'Art supplies metal hint only; A owns exact key ID/door matching.'},indent=2)+'\n')
    for (family,metal),im in assets.items():
        assert im.size==(64,64) and im.getbbox()[0]>2 and im.getbbox()[2]<62
        assert im.getpixel(KEYHOLES[family])==1
        assert {a for *_,a in im.convert('RGBA').getdata()}=={0,255}
    b.manifest(paths+previews,BASE/'manifest.json',{'runtime_count':12,'layout':'layout.json',
        'dependency_files':[{'path':p.relative_to(b.ROOT).as_posix(),'sha256':b.sha(p)} for p in sorted(b.INPUTS|{Path(__file__),b.BASE/'build_keys.py'})]})
    return len(paths)


if __name__ == '__main__':
    raise SystemExit('Run python -B art_src/items/keys_r12/build_keys.py to build the registered family together.')
