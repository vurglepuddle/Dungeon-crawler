"""r10 scope, archive and native sprite contracts; no Godot invocation."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build as r

receipt=json.loads((r.BASE/'manifest.json').read_text())
archive=json.loads((r.R9/'manifest.json').read_text())
assert len(receipt['assets'])==8
assert receipt['runtime_files_written']==8 and receipt['accepted_runtime_files_written']==0
for a in archive['assets']:
    path=r.R9/Path(a['path']).name
    assert hashlib.sha256(path.read_bytes()).hexdigest()==a['sha256'],('r9 copy',path)
for kind in r.ACCEPTED:
    before=(r.R9/f'icon_{kind}_16.png').read_bytes()
    assert (r.OUT/f'icon_{kind}_16.png').read_bytes()==before,('accepted changed',kind)
for a in receipt['assets']:
    path=r.ROOT/a['path'];im=Image.open(path)
    assert im.mode=='P' and im.size==(16,16) and im.getpalette()==r.b.TABLE
    assert set(im.convert('RGBA').getchannel('A').getdata())=={0,255}
    assert max(im.getdata())<32
    assert a['anchor']==[8,8] and a['frame_ms']==0
    assert hashlib.sha256(path.read_bytes()).hexdigest()==a['sha256']
    assert path.name==f"icon_{a['kind']}_16{'_alt' if a['optional'] else ''}.png"
    opaque=np.array(im)!=0
    assert ndimage.label(opaque)[1]==1,('one continuous shape',a['kind'])
    if not a['optional']:
        before=Image.open(r.R9/path.name)
        assert im.tobytes()!=before.tobytes(),a['kind']
for path,digest in receipt['sources'].items():
    assert hashlib.sha256((r.ROOT/path).read_bytes()).hexdigest()==digest,path

def image(kind):return np.array(Image.open(r.OUT/f'icon_{kind}_16.png'))
def old(kind):return np.array(Image.open(r.R9/f'icon_{kind}_16.png'))
assert np.array_equal(image('coat')!=0,image('coat_spent')!=0)
old_mask=np.array(r.read(r.ROOT/'assets/art/icons/coat.png'))!=0
assert np.array_equal(image('coat')!=0,old_mask)
assert np.array_equal(image('torch_unlit')[7:,:],image('torch_lit')[7:,:])
assert np.array_equal(ndimage.binary_fill_holes(image('knife')!=0),image('knife')!=0),'Solid knife material without alpha pinholes'
for kind in ['knife','shard','coat','coat_spent','torch_unlit','torch_lit']:
    assert np.count_nonzero(image(kind))>np.count_nonzero(old(kind)),('stronger mass',kind)
assert len(set(image('shard').ravel())-{0})<=4
assert len(set(image('seal').ravel())-{0})<=5
assert len((set(image('coat').ravel())-{0})&set(range(11,18)))<=3
reviews=sorted(r.BASE.glob('*_4x.png'));assert len(reviews)==5
for path in reviews:
    im=Image.open(path);native=Image.open(path.with_name(path.name.replace('_4x','_native')))
    assert native.resize((native.width*4,native.height*4),r.b.NEAREST).tobytes()==im.tobytes()
metrics=[]
for kind in r.REWORK:
    a,c=old(kind),image(kind)
    metrics.append({'kind':kind,'r9_opaque_pixels':int(np.count_nonzero(a)),
        'r10_opaque_pixels':int(np.count_nonzero(c)),
        'r9_opaque_inks':len(set(a.ravel())-{0}),'r10_opaque_inks':len(set(c.ravel())-{0})})
result={'revision':'r10','revised_states':7,'optional_club':1,'accepted_unchanged':8,
    'archived_r9_states':15,'review_pairs':len(reviews),
    'passed':['r9 archive byte hashes','accepted runtime files unchanged','16px palette and binary alpha',
        'one continuous silhouette per icon','same upright coat silhouette','registered reed body',
        'larger rejected-item silhouettes','four-ink glass','five-ink launcher Seal','exact 4x nearest'],
    'measurements':metrics,'godot_run':False,'human_acceptance':'awaiting owner art review'}
(r.BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
