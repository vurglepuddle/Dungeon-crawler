"""Validate new architecture art contracts offline, without launching Godot."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT, TABLE, NEAREST
from build_architecture import arch_mask, side_projection, side_anchor

BASE = Path(__file__).resolve().parent/'readability'
OUT = ROOT/'assets/art/fixtures'


def main():
    data=json.loads((BASE/'manifest.json').read_text())
    for path,digest in data['sources'].items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
    seen=set()
    for record in data['assets']:
        path=ROOT/record['path']
        assert path.name.startswith('architecture_v2_') and path.parent==OUT,path
        assert str(path) not in seen,path
        seen.add(str(path))
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256'],path
        with Image.open(path) as im:
            assert list(im.size)==record['size'],path
            assert im.mode=='P' and im.getpalette()==TABLE,path
            assert max(im.getdata())<32 and im.info['transparency']==0,path
            assert set(im.convert('RGBA').getchannel('A').getdata())<={0,255},path
            assert len(set(im.getdata())-{0})==record['opaque_colors'],path
            canonical=Image.open(OUT/f'architecture_v2_f{record["floor"]}_{record["kind"]}_64.png')
            if 'projection' in record:
                right=record['projection']=='right'
                assert im.tobytes()==side_projection(canonical,im.size,right).tobytes(),path
                assert record['anchor']==list(side_anchor(im.size,right)),path
            else:
                assert im.tobytes()==canonical.resize(im.size,NEAREST).tobytes(),path
                assert set(im.convert('RGBA').getchannel('A').getdata())=={255},path
                assert record['anchor']==[0,0],path
    assert len(seen)==54,len(seen)
    outer=arch_mask()
    for floor in [1,2]:
        wall=Image.open(ROOT/f'art_src/fixtures/architecture/sources/painted_f{floor}_base.png')
        for kind in ['stairs_down','stairs_up','lift_dead']:
            im=Image.open(OUT/f'architecture_v2_f{floor}_{kind}_64.png')
            for y in range(64):
                for x in range(64):
                    if not outer.getpixel((x,y)):
                        assert im.getpixel((x,y))==wall.getpixel((x,y)),(floor,kind,x,y)
            assert im.tobytes()!=Image.open(OUT/f'architecture_f{floor}_{kind}_64.png').tobytes(),kind
    contacts=0
    for path in BASE.glob('*_4x.png'):
        with Image.open(path) as scaled,Image.open(path.with_name(path.name.replace('_4x','_native'))) as native:
            assert scaled.getpalette()==TABLE and native.getpalette()==TABLE,path
            assert scaled.size==(native.width*4,native.height*4),path
            assert scaled.tobytes()==native.resize(scaled.size,NEAREST).tobytes(),path
        contacts+=1
    assert len(json.loads((BASE/'prompts.json').read_text()))==3
    assert 'prompt' in json.loads((BASE/'up_matching_owner_prompt.json').read_text())
    print(f'Readability art: {len(seen)} PNGs; {contacts} exact 4x sheets; palette, alpha, hashes, native sampling, anchors and wall seams verified')


if __name__=='__main__':
    main()
