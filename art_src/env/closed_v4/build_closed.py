"""Solid decorative blockages; original wall/door PNGs remain unchanged."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'painted_v2'))
import hashlib
import json
from PIL import Image,ImageDraw
from pipeline import ROOT,NEAREST,indexed,reduce,save,contact,manifest
from build_painted import deep_repaint

BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/env'
PATCH=[(8,61),(8,25),(10,19),(15,13),(22,8),(29,5),(36,5),
    (43,8),(49,13),(54,19),(56,25),(56,61)]


def patch_mask():
    mask=Image.new('1',(64,64));ImageDraw.Draw(mask).polygon(PATCH,fill=1)
    return mask


def main():
    mask=patch_mask()
    assets={};registrations=[]
    for kind,suffix in [('arch','arch_blocked'),('door','door_barricaded')]:
        painting=reduce(Image.open(BASE/'sources'/f'{kind}.png'),(64,64))
        for floor in (1,2):
            base=Image.open(OUT/f'painted_f{floor}_plain_0.png').copy()
            patch=painting if floor==1 else deep_repaint(painting)
            im=base.copy();im.paste(patch,(0,0),mask)
            name=f'painted_f{floor}_{suffix}'
            save(im,OUT/f'{name}.png');assets[f'F{floor} / {"SEALED ARCH" if kind=="arch" else "BARRED DOOR"}']=im
            registrations.append({'path':f'assets/art/env/{name}.png','floor':floor,
                'kind':suffix,'canvas':[64,64],'anchor':[0,0],
                'base':f'assets/art/env/painted_f{floor}_plain_0.png',
                'interactive':False,'collision_supplied':False,'patch_polygon':PATCH})
    contact(assets,BASE,columns=2,cell=(164,100),title='UNDERCROFT / CLOSED FOR CENTURIES')
    for floor in (1,2):
        repeat=indexed((192,128),1)
        names=[f'painted_f{floor}_{suffix}' for suffix in
            ('plain_0','arch_blocked','plain_1','plain_2','door_barricaded','plain_0')]
        for index,name in enumerate(names):
            repeat.paste(Image.open(OUT/f'{name}.png'),((index%3)*64,(index//3)*64))
        save(repeat,BASE/f'floor{floor}_repeat_native.png')
        save(repeat.resize((768,512),NEAREST),BASE/f'floor{floor}_repeat_4x.png')
    from build_mockups import build_mockups
    previews=build_mockups()
    paths=[ROOT/r['path'] for r in registrations]+[p for p in BASE.glob('*.png')
        if not p.name.startswith('mockup_')]
    manifest(paths,BASE/'manifest.json',{'registrations':registrations,
        'preview_files':[{'path':p.relative_to(ROOT).as_posix(),
            'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in previews],
        'integration':'Decorative solid wall faces only. Existing painted_fN_door.png remains the live lock texture.',
        'originals':'art_src/env/closed_v4/preserved_hashes.json'})
    from verify_closed import main as verify
    verify()


if __name__=='__main__':main()
