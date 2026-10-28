"""Validate the head-on lever and carved-mark asset batch without Godot."""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT,TABLE,NEAREST
from build_architecture import side_projection,side_anchor
from build_wall_controls import PATCH

BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/fixtures'


def main():
    data=json.loads((BASE/'lever_front/manifest.json').read_text())
    for relative,digest in data['sources'].items():
        assert hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()==digest,relative
    seen=set()
    for record in data['assets']:
        path=ROOT/record['path']
        assert path.parent==OUT and path.name.startswith(('lever_front_','lever_wall_','architecture_v3_')),path
        assert str(path) not in seen,path
        seen.add(str(path))
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256'],path
        with Image.open(path) as im:
            assert im.mode=='P' and im.getpalette()==TABLE,path
            assert list(im.size)==record['size'] and im.info.get('transparency')==0,path
            assert max(im.getdata())<32 and im.getbbox(),path
            assert set(im.convert('RGBA').getchannel('A').getdata())<={0,255},path
            assert len(set(im.getdata())-{0})==record['opaque_colors'],path
            if record['kind']=='lever_hardware':
                expected_size=[(32,40),(20,26),(12,16)][record['depth']-1]
                assert im.size==expected_size
                assert record['anchor']==[[16,22],[10,14],[6,8]][record['depth']-1]
                master=Image.open(OUT/f'lever_front_{record["state"]}_d1.png')
                assert im.tobytes()==master.resize(im.size,NEAREST).tobytes(),path
                continue
            canonical=Image.open(OUT/(f'lever_wall_f{record["floor"]}_{record["state"]}_64.png' if record['kind']=='lever_wall'
                                      else f'architecture_v3_f{record["floor"]}_{record["kind"]}_64.png'))
            if 'projection' in record:
                right=record['projection']=='right'
                assert im.tobytes()==side_projection(canonical,im.size,right).tobytes(),path
                assert record['anchor']==list(side_anchor(im.size,right)),path
            else:
                assert record['anchor']==[0,0],path
                assert set(im.convert('RGBA').getchannel('A').getdata())=={255},path
                assert im.tobytes()==canonical.resize(im.size,NEAREST).tobytes(),path
    assert len(seen)==54
    for floor in [1,2]:
        for kind in ['stairs_down','stairs_up']:
            old=Image.open(OUT/f'architecture_v2_f{floor}_{kind}_64.png')
            new=Image.open(OUT/f'architecture_v3_f{floor}_{kind}_64.png')
            for y in range(64):
                for x in range(64):
                    if not (PATCH[0]<=x<PATCH[2] and PATCH[1]<=y<PATCH[3]):
                        assert old.getpixel((x,y))==new.getpixel((x,y)),(floor,kind,x,y)
            # New incision uses stone ink, never the old flat ivory/cream sign.
            assert not (set(new.crop((28,8,37,14)).getdata()) & {9,10,25,26})
    up=Image.open(OUT/'lever_front_up_d1.png')
    down=Image.open(OUT/'lever_front_down_d1.png')
    for box in [(0,0,8,40),(24,0,32,40),(11,18,21,26),
                (6,11,11,16),(21,11,26,16),(6,27,11,32),(21,27,26,32)]:
        assert up.crop(box).tobytes()==down.crop(box).tobytes(),'Shared rim/bolts/hinge'
    assert down.crop((8,0,24,7)).getbbox() is None,'No floating remnant of raised knob'
    contacts=0
    for folder in ['lever_front','keystone_carved']:
        for path in (BASE/folder).glob('*_4x.png'):
            with Image.open(path) as scaled,Image.open(path.with_name(path.name.replace('_4x','_native'))) as native:
                assert scaled.size==(native.width*4,native.height*4),path
                assert scaled.getpalette()==TABLE and native.getpalette()==TABLE,path
                assert scaled.tobytes()==native.resize(scaled.size,NEAREST).tobytes(),path
            contacts+=1
    assert 'prompt' in json.loads((BASE/'lever_front/prompt.json').read_text())
    print(f'Wall controls verified: {len(seen)} runtime PNGs, {contacts} exact 4x reviews; hashes, palette, alpha, anchors, sampling, fixed lever hinge and isolated keystone changes')


if __name__=='__main__':main()
