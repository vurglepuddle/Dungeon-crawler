"""Offline contracts for the 16px painted pack set; no engine or UI edits."""
import sys
sys.dont_write_bytecode=True
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
import build_pack_icons as b

data=json.loads((b.REVIEW/'manifest.json').read_text())
assert len(data['assets'])==15
records=[]
seen=set()
pack=b.indexed(b.read(b.ROOT/'assets/art/ui_offer/pack_leather.png'))
slate=b.indexed(b.read(b.ROOT/'assets/art/ui/slate.png'))
def lum(inks):
    colors=np.array(b.RGB)[inks]
    return colors@np.array([.2126,.7152,.0722])/255

for a in data['assets']:
    path=b.ROOT/a['path'];im=Image.open(path)
    assert path.parent==b.OUT and path.name==f"icon_{a['kind']}_16.png"
    assert im.size==(16,16) and im.mode=='P' and im.getpalette()==b.TABLE
    assert set(im.convert('RGBA').getchannel('A').getdata())=={0,255}
    assert max(im.getdata())<32
    assert a['anchor']==[8,8] and a['frame_ms']==0
    assert hashlib.sha256(path.read_bytes()).hexdigest()==a['sha256']
    assert a['sha256'] not in seen;seen.add(a['sha256'])
    pixels=np.array(im);opaque=pixels!=0
    assert opaque.sum()>=20, a['kind']
    back=np.array(pack.crop((1,3,17,19)))
    card=np.array(b.nine(slate,(24,22)).crop((4,3,20,19)))
    records.append({'kind':a['kind'],'opaque_pixels':int(opaque.sum()),
        'mean_luminance_difference_pack':round(float(np.abs(lum(pixels)-lum(back))[opaque].mean()),4),
        'mean_luminance_difference_slate':round(float(np.abs(lum(pixels)-lum(card))[opaque].mean()),4)})

def icon(kind):return np.array(Image.open(b.OUT/f'icon_{kind}_16.png'))
cold,lit=icon('torch_unlit'),icon('torch_lit')
assert np.array_equal(cold[8:,:],lit[8:,:]),'Same registered reed body below flame'
assert np.where(lit!=0)[0].min()<np.where(cold!=0)[0].min()
assert np.count_nonzero(cold[9:15,:])>=12,'Continuous legible grip'
for y in range(9,15):assert np.count_nonzero(cold[y])>=2
assert np.count_nonzero(np.isin(lit,[22,23,24,25,26,10]))>np.count_nonzero(np.isin(cold,[22,23,24,25,26,10]))
key=icon('key')
assert not np.any(key[4:6,3:5])
regions,count=ndimage.label(key==0)
assert regions[4,3]!=regions[0,0], 'Key bow must be a real closed hole'
coat,spent=icon('coat'),icon('coat_spent')
assert not np.array_equal(coat,spent)
assert np.array_equal(spent!=0,coat!=0),'Both coats retain the same clear garment silhouette'
old_coat=np.array(b.indexed(b.read(b.ROOT/'assets/art/icons/coat.png')))
assert np.array_equal(coat!=0,old_coat!=0),'Use the readable old garment coverage'
for path,digest in data['sources'].items():
    assert hashlib.sha256((b.ROOT/path).read_bytes()).hexdigest()==digest, path
reviews=sorted((b.REVIEW/'r10').glob('*_4x.png'))
assert len(reviews)==5
for path in reviews:
    im=Image.open(path);native=Image.open(path.with_name(path.name.replace('_4x','_native')))
    assert im.size==(native.width*4,native.height*4)
    assert native.resize(im.size,b.NEAREST).tobytes()==im.tobytes()

receipt={'runtime_icons':15,'review_pairs':5,
    'passed':['exact 16x16 canvas and centre anchor','fixed palette / binary alpha',
        'all states unique','source and output hashes','true closed key bow',
        'continuous registered reed grip','lit flame above cold head','same garment silhouette / clear spent state',
        'exact 4x nearest reviews'],
    'contrast_metrics_are_not_a_readability_verdict':True,'background_measurements':records,
    'windowed_godot_run':False,'phone_playtest':False}
(b.REVIEW/'verification.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(f'Painted pack: {len(seen)} icons; five review pairs; all asset contracts pass')
