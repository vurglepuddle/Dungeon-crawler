"""Focused shared-edge, readability, probability, alpha and mock-up checks."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import hashlib
import json
from collections import Counter
from PIL import Image
from pipeline import ROOT,RGB,TABLE,NEAREST
from selection import FLOOR_WEIGHTS,CEILING_WEIGHTS,pick,mix_hash

BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/env'
UI=ROOT/'art_src/ui_offer/torn_v2'
RING=((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64))


def luma(ink):
    r,g,b=RGB[ink]
    return 2*r+4*g+b


def mean(im):
    return sum(luma(i) for i in im.getdata())/(im.width*im.height)


def roughness(im):
    # Native adjacent-texel contrast, leaving the shared cell border out.
    return sum(abs(luma(im.getpixel((x,y)))-luma(im.getpixel((x+1,y))))+
        abs(luma(im.getpixel((x,y)))-luma(im.getpixel((x,y+1))))
        for y in range(4,59) for x in range(4,59))/(55*55*2)


def main():
    receipt=json.loads((BASE/'preserved_hashes.json').read_text())
    for name,digest in receipt.items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
    paths=list(OUT.glob('calm_v3_*.png'))
    assert len(paths)==20
    for path in paths:
        im=Image.open(path)
        assert im.mode=='P' and im.size==(64,64) and im.getpalette()==TABLE,path
        assert set(im.getdata())<=set(range(1,32)),path
        assert im.crop((0,0,1,64)).tobytes()==im.crop((63,0,64,64)).tobytes(),path
        assert im.crop((0,0,64,1)).tobytes()==im.crop((0,63,64,64)).tobytes(),path
        plane='ceiling' if 'ceiling' in path.stem else 'floor'
        base=Image.open(OUT/('calm_v3_ceiling_plain.png' if plane=='ceiling' else 'calm_v3_floor_dry_a.png'))
        for box in RING:
            assert im.crop(box).tobytes()==base.crop(box).tobytes(),(path,box)
    dry=Image.open(OUT/'calm_v3_floor_dry_a.png')
    old=Image.open(OUT/'painted_f1_floor.png')
    roof=Image.open(OUT/'calm_v3_ceiling_plain.png')
    old_roof=Image.open(OUT/'painted_f1_ceiling.png')
    ratio=roughness(dry)/roughness(old)
    assert ratio<0.65,ratio
    roof_ratio=mean(roof)/mean(old_roof)
    assert 0.35<roof_ratio<0.82,roof_ratio
    assert mean(dry.crop((0,0,64,1)))<mean(dry.crop((8,8,56,56)))*0.65
    shapes={};centres=[]
    for name in ('wet_small','wet_hook','wet_corner','wet_split','wet_wide'):
        wet=Image.open(OUT/f'calm_v3_floor_{name}.png')
        changed={(x,y) for y in range(64) for x in range(64) if dry.getpixel((x,y))!=wet.getpixel((x,y))}
        assert changed and all(4<=x<60 and 4<=y<60 for x,y in changed)
        shapes[name]=len(changed)
        centres.append((sum(x for x,y in changed)/len(changed),sum(y for x,y in changed)/len(changed)))
    assert len(set(shapes.values()))==5 and len(set(centres))==5
    rates={}
    for floor in (1,2):
        for table in (FLOOR_WEIGHTS,CEILING_WEIGHTS):
            assert sum(weight for name,weight in table[floor])==100
        assert len(FLOOR_WEIGHTS[floor])>=5
        observed=Counter(pick('BELL42',floor,'floor',x,y) for y in range(32) for x in range(64))
        assert set(observed)=={kind for kind,weight in FLOOR_WEIGHTS[floor]}
        rates[floor]=sum(count for kind,count in observed.items() if kind.startswith('wet_'))/2048
    assert abs(rates[1]-0.03)<0.02 and abs(rates[2]-0.48)<0.04,rates
    weights={f:sum(shapes.get(kind,0)*weight for kind,weight in table)/100 for f,table in FLOOR_WEIGHTS.items()}
    assert weights[2]>weights[1]*10,weights
    data=json.loads((BASE/'selection.json').read_text())
    for sample in data['reference_samples']:
        seed,floor,plane,x,y=(sample[k] for k in ('seed','floor','plane','x','y'))
        assert mix_hash(f'{seed}/{floor}/{plane}/{x}/{y}')==sample['hash']
        assert pick(seed,floor,plane,x,y)==sample['kind']
    paper=Image.open(ROOT/'assets/art/ui_offer/map_parchment_torn_v2.png')
    assert paper.mode=='P' and paper.size==(144,324) and paper.getpalette()==TABLE
    alpha=paper.convert('RGBA').getchannel('A')
    assert set(alpha.getdata())=={0,255}
    assert min(alpha.crop((8,12,136,312)).getdata())==255
    assert sum(a==0 for a in alpha.getdata())>500
    for box in ((0,0,1,324),(143,0,144,324),(0,0,144,1),(0,323,144,324)):
        assert 0 in set(alpha.crop(box).getdata())
    source=Image.open(UI/'sources/m3d_map.png').convert('RGBA').resize((154,342),NEAREST)
    mock=Image.open(UI/'mockup_map_native.png')
    registration=json.loads((UI/'mockup_registration.json').read_text())
    for x,y in registration['ink_positions']:
        assert source.getpixel((x,y))==mock.getpixel((x,y))
        assert alpha.getpixel((x-5,y-16))==255
    box=registration['button_box']
    assert source.crop(box).tobytes()==mock.crop(box).tobytes()
    for floor in (1,2):
        for kind in ('corridor','room'):
            source=Image.open(BASE/'sources'/f'm3d_{kind}.png').convert('RGBA').resize((154,342),NEAREST)
            mock=Image.open(BASE/f'mockup_f{floor}_{kind}_native.png')
            for box in ((0,0,154,21),(0,171,154,342),(0,21,3,171),(151,21,154,171)):
                assert source.crop(box).tobytes()==mock.crop(box).tobytes()
    for folder in (BASE,UI):
        for native in folder.rglob('*native.png'):
            with Image.open(native) as a,Image.open(native.with_name(native.name.replace('native','4x'))) as b:
                assert b.size==(a.width*4,a.height*4)
                assert a.resize(b.size,NEAREST).tobytes()==b.tobytes(),native
    metrics={'floor_adjacent_contrast_ratio':ratio,'ceiling_luminance_ratio':roof_ratio,
        'puddle_changed_pixels':shapes,'wet_frequency_sample':rates,'old_c_pngs_unchanged':len(receipt)}
    (BASE/'verification.json').write_text(json.dumps(metrics,indent=2)+'\n')
    print(f'Calm kit verified: 20 plane textures + torn map; shared rings; floor detail {ratio:.1%}; ceiling value {roof_ratio:.1%}; stable wet selection; map ink/alpha; {len(receipt)} earlier C PNGs unchanged.')


if __name__=='__main__':main()
