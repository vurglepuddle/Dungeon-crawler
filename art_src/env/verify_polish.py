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
    for group in ('env','icons','portrait','screens'):
        base=ROOT/'art_src'/group
        data=json.loads((base/'manifest.json').read_text())
        for source in data['sources']:
            assert hashlib.sha256((ROOT/source['path']).read_bytes()).hexdigest()==source['sha256'],source['path']
        for entry in data['files']:
            p=ROOT/entry['path']
            assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],p
            with Image.open(p) as im:
                assert list(im.size)==entry['size'] and im.mode=='P' and im.getpalette()==TABLE,p
                assert max(im.getdata())<32,p
                union.update(im.convert('RGBA').getdata())
        for native in base.rglob('*native.png'):
            enlarged=native.with_name(native.name.replace('native','4x'))
            with Image.open(native) as a,Image.open(enlarged) as b:
                assert b.size==(a.width*4,a.height*4)
                assert a.resize(b.size,NEAREST).tobytes()==b.tobytes(),enlarged
        for p in (ROOT/'assets/art'/group).glob('*.png'):
            with Image.open(p) as im:
                if group=='env':expected=(64,64)
                elif group=='icons':expected=(208,16) if p.stem=='items_strip' else (16,16)
                elif group=='portrait':expected=(96,32) if p.stem=='finder_strip' else (32,32)
                else:expected=(154,150) if p.stem in ('title','splash') else (128,80)
                assert im.size==expected,(p,im.size,expected)
            count+=1
    assert count==50,count
    assert len(union)<=32
    assert {rgba[3] for rgba in union}<={0,255}
    assert {rgba[:3] for rgba in union if rgba[3]}<=set(RGB[1:])
    for floor in (1,2):
        base=Image.open(ROOT/f'assets/art/env/f{floor}_plain_0.png')
        for p in (ROOT/'assets/art/env').glob(f'f{floor}_*.png'):
            with Image.open(p) as im:
                assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes(),p
                assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes(),p
                if p.stem.endswith(('_floor','_ceiling')):continue
                for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
                    assert im.crop(box).tobytes()==base.crop(box).tobytes(),p
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
