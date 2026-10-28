"""Lower Watch prop family: new painted sources, existing canvases/anchors."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env/lower_watch'))
import json
from PIL import Image
from pipeline import ROOT, NEAREST, indexed, reduce, save, contact, manifest
from build_lower_watch import warm_grade

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/props'
FIT = {'rubble':(60,30),'bone_heap':(58,28),'skeleton':(54,54),'pots':(56,34),
       'pillar':(40,64),'statue':(60,34),'candles':(46,28),'crate':(50,44),'puddle':(60,14)}
DEPTHS = {1:(64,64),2:(40,40),3:(24,24)}
PUDDLE_DEPTHS = {1:(64,20),2:(40,12),3:(24,8)}


def main():
    assets, near, registrations, crops = {}, {}, [], {}
    for kind,maximum in FIT.items():
        source = Image.open(BASE/'sources'/f'{kind}.png').convert('RGBA')
        alpha = source.getchannel('A').point(lambda a:255 if a >= 128 else 0)
        bounds = alpha.getbbox(); assert bounds and alpha.getextrema() == (0,255), kind
        source = source.crop(bounds); crops[kind] = list(bounds)
        sizes = PUDDLE_DEPTHS if kind == 'puddle' else DEPTHS
        scale = min(maximum[0]/source.width,maximum[1]/source.height)
        target = (max(1,round(source.width*scale)),max(1,round(source.height*scale)))
        sprite = warm_grade(reduce(source,target))
        base = indexed(sizes[1]); base.paste(sprite,((base.width-sprite.width)//2,base.height-sprite.height))
        near[kind] = base
        for depth,size in sizes.items():
            im = base if depth == 1 else base.resize(size,NEAREST)
            name = f'f3_{kind}_d{depth}'; save(im,OUT/f'{name}.png'); assets[name] = im
            registrations.append({'path':f'assets/art/props/{name}.png','floor':3,'kind':kind,'depth':depth,
                'canvas':list(size),'anchor':[size[0]//2,size[1]],'interactive':False,
                'art_supplies_collision':False,'needs_solid_cell_if_blocking':kind == 'pillar',
                'state':'spent/unlit' if kind == 'candles' else 'rare iron seep' if kind == 'puddle' else 'static'})
        contact({f'D{d}':assets[f'f3_{kind}_d{d}'] for d in (1,2,3)},BASE/kind,
                columns=3,cell=(96,94),title='LOWER WATCH / '+kind.upper())
    contact(near,BASE,columns=3,cell=(148,100),title='LOWER WATCH / DRY, ASH-STAINED PROPS')
    (BASE/'layout.json').write_text(json.dumps({'schema_version':1,'floor':3,'registrations':registrations,
        'source_crop_bounds':crops,'path':'res://assets/art/props/f3_{same_kind}_d{same_depth}.png',
        'depth_thresholds':[1.5,2.5,3.6],'filter':'nearest','scale_rule':'Resize full registered d1 canvas, never refit separate depths.',
        'placement':'Keep current decorative reservation; no interactable/loot/travel/monster/puzzle cells or item-hiding placement. Pillar needs an actually blocked cell if used.',
        'puddle':'Rare iron-brown seep, not a floor-wide wet effect; use very sparsely on this predominantly dry level.',
        'candles':'Static unlit wax; no flame, glint, LIGHT action or fuel implied.'},indent=2)+'\n')
    manifest(list(OUT.glob('f3_*.png'))+list(BASE.rglob('*native.png'))+list(BASE.rglob('*4x.png')),BASE/'manifest.json',
             {'runtime_count':len(assets),'registrations':registrations,'layout':'layout.json','floor':3})
    print('Lower Watch props: 27 new PNGs, 9 painted families, exact existing d1/d2/d3 canvas and bottom-centre anchor conventions.')


if __name__ == '__main__': main()
