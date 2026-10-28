"""Asset-contract checks only; does not launch Godot or edit runtime files."""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageOps
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build as b

BASE=b.BASE
data=json.loads((BASE/'manifest.json').read_text())
assert len(data['assets'])==65
counts={}
def read(path):return Image.open(path).copy()
for record in data['assets']:
    path=b.ROOT/record['path']
    assert record['path'].startswith('assets/art/fixtures/fixture_v2_') or record['path']=='assets/art/icons/coat_spent.png'
    im=read(path)
    assert im.mode=='P' and im.getpalette()==b.TABLE,record['path']
    assert set(im.convert('RGBA').getchannel('A').getdata()) <= {0,255}
    assert max(im.getdata())<=31
    assert list(im.size)==record['size']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    old=record['replaces']
    if old.startswith('assets/'):
        assert read(b.ROOT/old).size==im.size,record['path']
    if record['kind']=='plate':assert record['anchor']==[im.width//2,im.height]
    if record['kind']=='lever':
        assert record['anchor']==[im.width//2-int(record['projection']=='right'),[22,14,8][record['depth']-1]]
    if record['kind']=='cord_grate' and 'projection' in record:
        assert record['anchor']==[im.width//2-int(record['projection']=='right'),im.height//2]
    counts[record['kind']]=counts.get(record['kind'],0)+1
for path,digest in data['sources'].items():
    assert hashlib.sha256((b.ROOT/path).read_bytes()).hexdigest()==digest,path

def new(name):return read(b.OUT/f'fixture_v2_{name}.png')
for floor in [1,2]:
    reference=read(b.ROOT/'assets/art/env/calm_v3_floor_dry_a.png')
    wall=read(b.ROOT/f'assets/art/env/painted_f{floor}_plain_0.png')
    for kind in ['lift_dead','lift_working','stairs_down']:
        im=new(f'f{floor}_floor_{kind}_64')
        assert 0 not in set(im.getdata())
        for box in [(0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64)]:
            assert im.crop(box).tobytes()==reference.crop(box).tobytes()
    face=new(f'f{floor}_cache_open_64');overlay=new(f'f{floor}_cache_open_overlay_64')
    assert 0 not in set(face.getdata())
    a=np.array(face);w=np.array(wall);o=np.array(overlay)
    mask=np.zeros((64,64),dtype=bool);x0,y0,x1,y1=b.CACHE_PATCH;mask[y0:y1,x0:x1]=True
    assert np.array_equal(a[~mask],w[~mask]) and not np.any(o[~mask])
    assert np.array_equal(a[mask],o[mask]) and np.all(o[mask]>0)

for d,size in enumerate(b.LEVER_SIZES,1):
    for state in ['up','down']:
        left=new(f'lever_left_{state}_d{d}');right=new(f'lever_right_{state}_d{d}')
        assert ImageOps.mirror(left).tobytes()==right.tobytes()
        assert left.size==size
    for state in ['intact','cut']:
        left=new(f'cord_grate_left_{state}_d{d}');right=new(f'cord_grate_right_{state}_d{d}')
        assert ImageOps.mirror(left).tobytes()==right.tobytes()
for d,h in enumerate(b.SIZES,1):
    intact=np.array(new(f'web_intact_d{d}'))
    assert .10<np.mean(intact==0)<.85,('web gaps',d)
    burnt=new(f'web_burnt_d{d}')
    assert np.mean(np.array(burnt)==0)>.70,('burnt clearance',d)
    cut=new(f'cord_grate_cut_d{d}')
    original=new('cord_grate_cut_d1')
    assert original.resize((h,h),b.NEAREST).tobytes()==cut.tobytes()
    assert np.mean(np.array(cut)==0)>.35,('cord passage',d)
    for state in ['intact','cut']:
        grate=np.array(new(f'cord_grate_{state}_d{d}'))
        assert np.any(grate==0) and np.any(grate>0)

mask=Image.new('L',(64,64),0)
ImageDraw.Draw(mask).polygon([(9,39),(14,19),(29,10),(51,19),(57,39),(47,59),(17,60)],fill=255)
outside=np.array(mask)==0
a=np.array(new('web_burning_0_d1'));c=np.array(new('web_burning_1_d1'))
assert np.array_equal(a[outside],c[outside]) and np.any(a!=c)
assert not np.any(np.array(new('web_burnt_d1'))[8:64,10:54])
assert not np.any(np.array(new('cord_grate_cut_d1'))[25:59,11:53])

# Direction transforms agree with an actual rotation of the physical tile.
tile=new('f1_floor_stairs_down_64')
for direction,rotation in [('N',None),('E',Image.Transpose.ROTATE_270),('S',Image.Transpose.ROTATE_180),('W',Image.Transpose.ROTATE_90)]:
    expected=tile if rotation is None else tile.transpose(rotation)
    expected=expected.copy()
    b.border(expected,tile)  # The world-fixed seam ring is never rotated.
    for v in range(64):
        for u in range(64):
            assert tile.getpixel(b.sample_uv(direction,u,v))==expected.getpixel((u,v))

reviews=sorted(BASE.glob('*_4x.png'))
assert len(reviews)==10
for path in reviews:
    im=read(path);native=read(path.with_name(path.name.replace('_4x','_native')))
    assert im.size==(native.width*4,native.height*4)
    assert native.resize(im.size,b.NEAREST).tobytes()==im.tobytes()
    assert im.mode=='P' and im.getpalette()==b.TABLE

result={'runtime_pngs':len(data['assets']),'review_pairs':len(reviews),'kinds':counts,
        'passed':['palette and binary alpha','old canvas dimensions','source/output hashes',
                  'shared two-pixel floor border','opaque floor planes','cache outside patch unchanged',
                  'mirrored side projections','transparent web/grate passages',
                  'static web outside fire','world-fixed four floor orientations','exact 4x nearest reviews'],
        'engine_run':False,'phone_playtest':False}
(BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
