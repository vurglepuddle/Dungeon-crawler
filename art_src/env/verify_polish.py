"""Validate art/text integration contracts without importing or launching Godot."""
import hashlib
import json
import sys
sys.dont_write_bytecode=True
from pathlib import Path
from PIL import Image
from pipeline import ROOT, RGB, TABLE, NEAREST

def lines(value):
    assert isinstance(value,list) and 1<=len(value)<=2,value
    assert all(isinstance(s,str) and 0<len(s)<=21 and '\n' not in s for s in value),value

def main():
    union=set();count=0
    runtime_paths=set();declared_runtime=set()
    for group in ('env','icons','portrait','screens','ui_offer','props'):
        base=ROOT/'art_src'/group
        if not base.exists():continue
        for manifest_path in base.rglob('manifest.json'):
            data=json.loads(manifest_path.read_text())
            for source in data['sources']:
                assert hashlib.sha256((ROOT/source['path']).read_bytes()).hexdigest()==source['sha256'],source['path']
            for entry in data['files']:
                p=ROOT/entry['path']
                if entry['path'].startswith('assets/art/'):declared_runtime.add(p)
                assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],p
                with Image.open(p) as im:
                    assert list(im.size)==entry['size'] and im.mode=='P' and im.getpalette()==TABLE,p
                    assert max(im.getdata())<32,p
                    union.update(im.convert('RGBA').getdata())
            for entry in data.get('preview_files',[]):
                p=ROOT/entry['path']
                assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],p
        for native in base.rglob('*native.png'):
            enlarged=native.with_name(native.name.replace('native','4x'))
            with Image.open(native) as a,Image.open(enlarged) as b:
                assert b.size==(a.width*4,a.height*4)
                assert a.resize(b.size,NEAREST).tobytes()==b.tobytes(),enlarged
        for p in (ROOT/'assets/art'/group).glob('*.png'):
            runtime_paths.add(p)
            with Image.open(p) as im:
                if group=='env':expected=(64,64)
                elif group=='icons':expected=(208,16) if p.stem=='items_strip' else (16,16)
                elif group=='portrait':expected=(96,32) if 'strip' in p.stem else (32,32)
                elif group=='screens':
                    screen_sizes={'title':(154,150),'splash':(154,150),'win':(128,80),'death':(128,80),
                        'logotype_140':(140,40),'subtitle_plate_140':(140,20),'icon_offer_192':(192,192),
                        'icon_offer_foreground_432':(432,432),'icon_offer_background_432':(432,432)}
                    for family,suffix,frames in [('splash','flutter',2),('title','flicker',3),('win','dawn',3),('death','gutter',3)]:
                        for frame in range(frames):
                            screen_sizes[f'{family}_{suffix}_{frame}']=screen_sizes[family]
                    expected=screen_sizes[p.stem]
                elif group=='props':
                    depth=int(p.stem[-1])
                    expected={1:(64,20),2:(40,12),3:(24,8)}[depth] if 'puddle' in p.stem else {1:(64,64),2:(40,40),3:(24,24)}[depth]
                else:expected=im.size # Exact UI rects are checked below.
                assert im.size==expected,(p,im.size,expected)
            count+=1
    assert runtime_paths==declared_runtime,('Undeclared/missing runtime files',runtime_paths^declared_runtime)
    assert len(union)<=32
    assert {rgba[3] for rgba in union}<={0,255}
    assert {rgba[:3] for rgba in union if rgba[3]}<=set(RGB[1:])
    for prefix in ('f1_','f2_','painted_f1_','painted_f2_'):
        base_path=ROOT/f'assets/art/env/{prefix}plain_0.png'
        if not base_path.exists():continue
        base=Image.open(base_path)
        for p in (ROOT/'assets/art/env').glob(f'{prefix}*.png'):
            with Image.open(p) as im:
                assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes(),p
                assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes(),p
                if p.stem.endswith(('_floor','_ceiling')):continue
                for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
                    assert im.crop(box).tobytes()==base.crop(box).tobytes(),p
    receipt=ROOT/'art_src/env/painted_v2/preserved_hashes.json'
    if receipt.exists():
        for p,digest in json.loads(receipt.read_text()).items():
            assert hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==digest,('Changed preserved PNG',p)
    room_receipt=ROOT/'art_src/props/preserved_hashes.json'
    if room_receipt.exists():
        for p,digest in json.loads(room_receipt.read_text()).items():
            # Launcher art belongs to Claude; its accepted replacement is not
            # part of C's promise to preserve old C assets. Keep the receipt.
            if p.startswith('assets/icon/'):continue
            assert hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==digest,('Changed pre-room PNG',p)
    for floor in (1,2):
        for plane in ('floor','ceiling'):
            base=Image.open(ROOT/f'assets/art/env/f{floor}_{plane}.png')
            for p in (ROOT/'assets/art/env').glob(f'room_f{floor}_{plane}_*.png'):
                im=Image.open(p)
                for box in ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)):
                    assert im.crop(box).tobytes()==base.crop(box).tobytes(),p
    prop_manifest=ROOT/'art_src/props/manifest.json'
    if prop_manifest.exists():
        for entry in json.loads(prop_manifest.read_text())['registrations']:
            p=ROOT/entry['path'];w,h=entry['canvas']
            assert entry['anchor']==[w//2,h] and entry['interactive'] is False,entry
            im=Image.open(p)
            base=Image.open(p.with_name(p.name[:-5]+'1.png'))
            assert im.tobytes()==base.resize(im.size,NEAREST).tobytes(),p
            if entry['floor']==2 and entry['kind']!='puddle':
                dry=Image.open(p.with_name('f1_'+p.name[3:]))
                assert im.convert('RGBA').getchannel('A').tobytes()==dry.convert('RGBA').getchannel('A').tobytes(),p
    foreground=ROOT/'assets/art/screens/icon_offer_foreground_432.png'
    if foreground.exists():
        im=Image.open(foreground)
        assert all((x+0.5-216)**2+(y+0.5-216)**2<=132**2 for y in range(432) for x in range(432) if im.getpixel((x,y))!=0)
        bg=Image.open(ROOT/'assets/art/screens/icon_offer_background_432.png')
        assert 0 not in set(bg.getdata())
    assert Image.open(ROOT/'assets/art/finder.png').convert('RGBA').tobytes()==Image.open(ROOT/'assets/art/portrait/finder_fine.png').convert('RGBA').tobytes()
    ui_layout=ROOT/'art_src/ui_offer/rects.json'
    if ui_layout.exists():
        for name,entry in json.loads(ui_layout.read_text())['assets'].items():
            with Image.open(ROOT/f'assets/art/ui_offer/{name}.png') as im:
                assert list(im.size)==entry.get('size',entry.get('rect',[])[2:]),name
                l,t,r,b=entry['nine_slice_ltrb']
                assert 0<=l+r<im.width and 0<=t+b<im.height,name
        with Image.open(ROOT/'assets/art/ui_offer/hp_vial_full.png') as im:
            assert im.convert('RGBA').getchannel('A').getbbox()==(2,6,4,24)
    provenance=json.loads((ROOT/'data/text/provenance.json').read_text())
    kinds={'knife','lamp','stone','bone','bread','torch','clapper','shard','tonic','club','coat','key','seal'}
    assert set(provenance['items'])==kinds
    for entry in provenance['items'].values():lines(entry)
    flavour=json.loads((ROOT/'data/text/flavour.json').read_text())
    for entry in flavour['floor_names'].values():lines(entry)
    for entry in flavour['death_epitaphs']:lines(entry)
    assert len({entry['id'] for entry in flavour['hint_notes']})==len(flavour['hint_notes'])
    for entry in flavour['hint_notes']:lines(entry['lines'])
    print(f'Polish verified: {count} runtime PNGs; {len(union)-int((0,0,0,0) in union)} opaque inks; binary alpha; exact 4x sheets; mixed wall edges; text <=21 chars x2.')

if __name__=='__main__':main()
