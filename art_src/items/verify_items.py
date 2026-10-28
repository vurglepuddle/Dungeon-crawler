"""World-pickup palette, registration, source and native-distance checks."""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
from pathlib import Path
from PIL import Image
from scipy import ndimage
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'anim'))
from pipeline import ROOT,TABLE,NEAREST
from build_items import BASE,OUT,ORDER,SIZES,master,rim


def main():
    data=json.loads((BASE/'manifest.json').read_text())
    for path,digest in data['sources'].items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
    seen=set()
    originals={kind:master(kind) for kind in ORDER}
    for record in data['assets']:
        path=ROOT/record['path']
        assert path.parent==OUT and path.name.startswith('item_'),path
        assert str(path) not in seen,path
        seen.add(str(path))
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256'],path
        with Image.open(path) as image:
            size=SIZES[record['depth']-1]
            assert image.mode=='P' and image.getpalette()==TABLE,path
            assert image.size==size and list(size)==record['size'],path
            assert image.info.get('transparency')==0 and max(image.getdata())<32,path
            assert set(image.convert('RGBA').getchannel('A').getdata())=={0,255},path
            assert list(image.getbbox())==record['opaque_bounds'],path
            assert record['anchor']==[size[0]//2,size[1]],path
            assert len(set(image.getdata())-{0})==record['opaque_colors'],path
            expected=rim(originals[record['kind']].resize(size,NEAREST),record['kind'])
            assert image.tobytes()==expected.tobytes(),path
            # No broad shadow/ground patch below a floating object.
            assert image.getbbox()[3]>=image.height-1,path
            assert record['shadow']=='renderer; no baked shadow',path
    assert len(seen)==36
    for d in [1,2,3]:
        a=Image.open(OUT/f'item_coat_d{d}.png')
        b=Image.open(OUT/f'item_coat_spent_d{d}.png')
        ab,bb=a.getbbox(),b.getbbox()
        assert bb[3]-bb[1]<ab[3]-ab[1],d
        # A frayed extreme edge can disappear on the 24px sampling grid.
        assert abs((ab[2]-ab[0])-(bb[2]-bb[0]))<=2,d
        assert a.tobytes()!=b.tobytes(),d
        key=Image.open(OUT/f'item_key_d{d}.png')
        # Keep at least one actual transparent hole in the ring at all depths.
        background=np.asarray(key)==0
        filled=ndimage.binary_fill_holes(~background)
        assert np.any(filled & background),f'Key ring at D{d}'
    contacts=0
    for path in BASE.glob('*_4x.png'):
        with Image.open(path) as scaled,Image.open(path.with_name(path.name.replace('_4x','_native'))) as native:
            assert scaled.size==(native.width*4,native.height*4),path
            assert scaled.getpalette()==TABLE and native.getpalette()==TABLE,path
            assert scaled.tobytes()==native.resize(scaled.size,NEAREST).tobytes(),path
        contacts+=1
    assert contacts==11,contacts
    prompts=sum(len(json.loads(path.read_text())['items']) for path in BASE.glob('prompts*.json'))
    assert prompts==11,prompts
    print(f'Items verified: {len(seen)} runtime PNGs; {contacts} exact 4x reviews; hashes, palette, binary alpha, native retouch, anchors, key holes and spent-coat silhouette')


if __name__=='__main__':main()
