"""Build only the new Lower Watch material family from saved paintings."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import hashlib
import importlib.util
import json
from PIL import Image, ImageDraw
from pipeline import ROOT, RGB, NEAREST, indexed, reduce, save, contact, manifest
from selection import FLOORS, WEIGHTS, CEILING_WEIGHTS, pick, texture_name, mix_hash

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/env'
RING = ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64))
INNER = [(14,57),(14,21),(16,16),(20,12),(25,10),(31,9),(37,10),(43,13),(47,18),(49,24),(49,57)]
APERTURE = [(27,56),(27,15),(31,11),(36,12),(42,15),(46,20),(47,25),(47,56)]
FLAME = [(22,5),(40,5),(40,19),(37,20),(28,20),(28,24),(22,24)]
WALL_KINDS = ('door','door_open','drain','sconce_0','sconce_1','chains','tapestry','crack','damp')


def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def mask(points):
    im = Image.new('L',(64,64)); ImageDraw.Draw(im).polygon(points,fill=255)
    return im


def warm_grade(im,fire=False):
    # Shared palette only: charcoal/iron, warm ash, subdued rust; no green inks.
    grade = {3:2,4:30,5:27,6:28,9:8,10:9,11:1,12:2,13:30,14:27,15:6,16:7,17:8,
             24:29,25:8,26:9}
    result = im.copy()
    for y in range(im.height):
        for x in range(im.width):
            i = im.getpixel((x,y))
            # The flame keeps its existing emissive amber/ivory ramp.
            actual_fire = fire and im.size == (64,64) and 22 <= x <= 40 and 5 <= y <= 24
            result.putpixel((x,y),i if actual_fire else grade.get(i,i))
    return result


def quiet(im,passes=2):
    for _ in range(passes):
        old = im.copy()
        for y in range(3,61):
            for x in range(3,61):
                if old.getpixel((x,y)) not in (4,5,6,7,8): continue
                values = sorted(old.getpixel((x+dx,y+dy)) for dy in (-1,0,1) for dx in (-1,0,1))
                im.putpixel((x,y),values[4])
    return im


def calm_watch_plane(im,plane):
    # The Watch is dry iron-grey under its ochre masonry. Keep broad flags
    # legible: remove isolated paint grain using actual ink luminance, never
    # palette-index order, while retaining the deepest joint/crack cores.
    grade = {27:5,28:6,29:7,8:7,9:8,23:28,24:29}
    if plane == 'ceiling': grade[30] = 4
    im.putdata([grade.get(i,i) for i in im.getdata()])
    luma = [0.2126*r+0.7152*g+0.0722*b for r,g,b in RGB]
    for _ in range(1):
        old = im.copy()
        for y in range(3,61):
            for x in range(3,61):
                if old.getpixel((x,y)) in (1,2): continue
                values = sorted((old.getpixel((x+dx,y+dy)) for dy in (-1,0,1) for dx in (-1,0,1)),key=lambda i:luma[i])
                im.putpixel((x,y),values[4])
    return im


def ring(im,base):
    for box in RING: im.paste(base.crop(box),box[:2])
    return im


def seamless(im):
    # The new wall has its own warm ring; every f3 wall uses this exact ring.
    for y in range(64): im.putpixel((63,y),im.getpixel((0,y)))
    for x in range(64): im.putpixel((x,63),im.getpixel((x,0)))
    return im


def paint(name,plane=None):
    im = reduce(Image.open(BASE/'sources'/f'{name}.png'),(64,64))
    if plane:
        quiet(im,2 if plane == 'floor' else 1)
        compress = {4:5,8:7,9:7,10:8} if plane == 'floor' else {4:3,5:4,6:5,7:6,8:7,9:7,10:8}
        im.putdata([compress.get(i,i) for i in im.getdata()])
    im = warm_grade(im,name.startswith('wall_sconce'))
    return calm_watch_plane(im,plane) if plane else im


def pair(image,stem):
    for suffix, im in [('native',image),('4x',image.resize((image.width*4,image.height*4),NEAREST))]:
        path = BASE/f'{stem}_{suffix}.png'
        if im.mode == 'P': save(im,path)
        else: im.save(path)


def walls():
    base = seamless(paint('wall_plain_0'))
    assets = {f'painted_f3_plain_{i}':ring(paint(f'wall_plain_{i}'),base) for i in range(3)}
    assets['painted_f3_plain_0'] = base
    values = {kind:paint('wall_'+kind) for kind in WALL_KINDS}
    opened = values['door'].copy(); opened.paste(values['door_open'],(0,0),mask(INNER)); values['door_open'] = opened
    flicker = values['sconce_0'].copy(); flicker.paste(values['sconce_1'],(0,0),mask(FLAME)); values['sconce_1'] = flicker
    for kind,im in values.items(): assets[f'painted_f3_{kind}_v2'] = ring(im,base)
    overlay = assets['painted_f3_door_open_v2'].copy(); overlay.paste(0,(0,0),mask(APERTURE))
    assets['painted_f3_door_open_overlay_v2'] = overlay
    for kind in ('arch_blocked','door_barricaded'): assets[f'painted_f3_{kind}'] = ring(paint('wall_'+kind),base)
    contact({k.removeprefix('painted_f3_').removesuffix('_v2'):v for k,v in assets.items()},BASE/'walls',columns=4,cell=(152,100),title='THE LOWER WATCH / SOOT, RUST, ASH')
    repeat = indexed((256,192),1)
    keys = ['plain_0','drain_v2','plain_1','sconce_0_v2','chains_v2','plain_2','tapestry_v2','crack_v2','damp_v2','arch_blocked','door_barricaded','door_v2']
    for i,key in enumerate(keys): repeat.paste(assets['painted_f3_'+key],((i%4)*64,(i//4)*64))
    pair(repeat,'wall_repeat')
    return assets


def planes():
    # Exact rings from calm_v3, including the ceiling's irregular rib endpoints.
    floor_ring = Image.open(OUT/'calm_v3_floor_dry_a.png')
    ceiling_ring = Image.open(OUT/'calm_v3_ceiling_plain.png')
    dry = ring(paint('floor_base','floor'),floor_ring)
    wear = paint('floor_wear','floor'); ash = paint('floor_ash','floor')
    t = Image.Transpose
    floors = {'dry_a':dry,'dry_b':dry.transpose(t.FLIP_LEFT_RIGHT),'dry_c':dry.transpose(t.ROTATE_180),
              'stain':wear,'chip':wear.transpose(t.FLIP_LEFT_RIGHT),'crack':wear.transpose(t.ROTATE_90),
              'wet_small':ash,'wet_hook':ash.transpose(t.FLIP_LEFT_RIGHT),'wet_corner':ash.transpose(t.FLIP_TOP_BOTTOM),
              'wet_split':ash.transpose(t.ROTATE_180),'wet_wide':ash.transpose(t.ROTATE_90)}
    floors = {k:ring(v,floor_ring) for k,v in floors.items()}
    ceilings = {kind:ring(paint('ceiling_'+('base' if kind == 'plain' else kind),'ceiling'),ceiling_ring) for kind in ('plain','root','drip')}
    assets = {'calm_v3_f3_floor_'+k:v for k,v in floors.items()}
    assets.update({'calm_v3_f3_ceiling_'+k:v for k,v in ceilings.items()})
    landmarks = {'floor_drain':ring(paint('floor_drain','floor'),floor_ring),
                 'floor_cracked':floors['crack'].copy(),'floor_compass':ring(paint('floor_compass','floor'),floor_ring),
                 'ceiling_roots':ceilings['root'].copy(),'ceiling_chain':ring(paint('ceiling_chain','ceiling'),ceiling_ring),
                 'ceiling_boss':ring(paint('ceiling_boss','ceiling'),ceiling_ring)}
    assets.update({'calm_v3_f3_room_'+k:v for k,v in landmarks.items()})
    contact(floors,BASE/'floors',columns=4,cell=(132,100),title='LOWER WATCH / READABLE DRY FLAGS')
    contact(ceilings,BASE/'ceilings',columns=3,cell=(144,100),title='LOWER WATCH / QUIET SOOT VAULT')
    contact(landmarks,BASE/'landmarks',columns=3,cell=(156,100),title='LOWER WATCH / OLD WATCH MARKS')
    repeat = indexed((320,256),1)
    for y in range(4):
        for x in range(5): repeat.paste(floors[pick('BELL42',3,'floor',x+8,y+8)],(x*64,y*64))
    pair(repeat,'floor_mixed')
    # Legacy-shaped base aliases support the older single-plane offer too.
    assets['painted_f3_floor'] = floors['dry_a'].copy()
    assets['painted_f3_ceiling'] = ceilings['plain'].copy()
    return assets


def main():
    assets = dict(walls(),**planes())
    for name,im in assets.items(): save(im,OUT/f'{name}.png')
    contact({name.removeprefix('painted_f3_').removeprefix('calm_v3_f3_'):im for name,im in assets.items()},BASE,
            columns=5,cell=(166,100),title='UNDERCROFT / THE LOWER WATCH / F3')
    samples = [{'seed':'BELL42','floor':3,'plane':plane,'x':x,'y':y,'hash':mix_hash(f'BELL42/3/{plane}/{x}/{y}'),
                'kind':pick('BELL42',3,plane,x,y),'path':texture_name('BELL42',3,plane,x,y)}
               for plane in ('floor','ceiling') for x,y in ((10,10),(10,9),(-1,5))]
    (BASE/'layout.json').write_text(json.dumps({'schema_version':1,'floor':3,'canvas':[64,64],'anchor':[0,0],
        'walls':[k for k in assets if k.startswith('painted_f3_') and k not in ('painted_f3_floor','painted_f3_ceiling')],
        'planes':[k for k in assets if k.startswith('calm_v3_f3_')], 'base_aliases':['painted_f3_floor','painted_f3_ceiling'],
        'wall_path':'res://assets/art/env/painted_f3_{same_existing_suffix}.png',
        'plane_path':'res://assets/art/env/calm_v3_f3_{plane}_{same_existing_kind}.png',
        'plane_one_line_mapping':'path.replace("calm_v3_", "calm_v3_f3_") if floor >= 3 else path',
        'wall_prop_mapping':'mini(floor, 3) in the existing painted_f%d and props/f%d path formats',
        'art_family_mapping':{'walls':3,'fixtures':2,'props':3,'planes':'calm_v3_f3','weights':2},
        'art_family_rule':'Use this dictionary only for number >= 3; keep upper-floor mapping unchanged. weights:2 is compatible; add the optional third weight row before selecting weights:3.',
        'room_landmark_mapping':'calm_v3_room_ becomes calm_v3_f3_room_ only on floor 3',
        'floor_slot_meaning':'wet_* filenames are compatibility slots; here they contain dry ash deposits, without water reflections.',
        'floor_weights':list(WEIGHTS[3]),'floor_names':list(FLOORS),'ceiling_weights':list(CEILING_WEIGHTS[3]),
        'reference_samples':samples,'cell_size':1,'floor_ceiling_ring_px':2,'plane_ring_reference':'corresponding calm_v3 plain base, exact pixels',
        'wall_ring':'own painted_f3_plain_0, exact 2px ring; opposite edges identical',
        'door_interior':INNER,'door_aperture':APERTURE,'torch_fire':FLAME,'torch_frame_ms':[250,250],
        'open_door':'Use door_open_overlay_v2 in the real lock portal; opaque door_open_v2 is only a flat-face/reference option.',
        'no_collision_changes':True,'filter':'nearest','runtime_source':'individual saved paintings, quiet stone reduction, shared-palette dry grade and registration only'},indent=2)+'\n')
    # Props have their own source folder/manifest but build with the same grade.
    spec = importlib.util.spec_from_file_location('watch_props',ROOT/'art_src/props/lower_watch/build_props.py')
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module); module.main()
    from build_views import build_views
    previews = build_views()
    paths = [OUT/f'{name}.png' for name in assets]+[p for p in BASE.rglob('*.png') if p.name.endswith(('_native.png','_4x.png')) and not p.name.startswith('mockup_')]
    manifest(paths,BASE/'manifest.json',{'runtime_count':len(assets),'floor':3,'layout':'layout.json',
        'preview_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':digest(p)} for p in previews]})
    print(f'Lower Watch: {len(assets)} env textures + 27 props; complete f3 wall, plane and room family. No existing art written.')


if __name__ == '__main__': main()
