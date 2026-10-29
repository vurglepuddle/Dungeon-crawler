"""Offline r11 Deep family. Saved paintings -> 64px shared-palette materials.

Never imports game code or invokes Godot. Existing Lower Watch paintings supply
registered dressing details; its runtime art, props and builders remain untouched.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hashlib
import importlib.util
import json
from PIL import Image, ImageDraw
from pipeline import ROOT, RGB, TABLE, NEAREST, indexed, reduce, save, contact, manifest, label

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/env'
WATCH = ROOT/'art_src/env/lower_watch'
RING = ((0,0,64,2),(0,62,64,64),(0,0,2,64),(62,0,64,64))
INNER = [(14,57),(14,21),(16,16),(20,12),(25,10),(31,9),(37,10),(43,13),(47,18),(49,24),(49,57)]
APERTURE = [(27,56),(27,15),(31,11),(36,12),(42,15),(46,20),(47,25),(47,56)]
FLAME = [(22,5),(40,5),(40,19),(37,20),(28,20),(28,24),(22,24)]
ARCH = [(10,61),(10,21),(12,14),(18,7),(26,4),(37,4),(46,8),(52,17),(54,26),(54,61)]
FLOORS = ('dry_a','dry_b','dry_c','stain','chip','crack','wet_small','wet_hook','wet_corner','wet_split','wet_wide')


def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def stencil(points):
    result = Image.new('L',(64,64))
    ImageDraw.Draw(result).polygon(points,fill=255)
    return result


def ring(im, reference):
    for box in RING: im.paste(reference.crop(box),box[:2])
    return im


def cold(im, source=False):
    """Stone stays on the slate ramp; pale bone/salt is a restrained accent."""
    grade = {6:5,7:6,8:6,9:7,10:8} if source else {6:5,7:6,8:7,9:8,10:9}
    grade.update({11:1,12:2,13:3,14:4,15:5,16:6,17:7,
                  18:1,19:2,20:3,21:3,22:4,23:5,24:6,25:7,26:8,
                  27:3,28:4,29:5,30:2,31:4})
    out = im.copy(); out.putdata([grade.get(i,i) for i in im.getdata()])
    return out


def painting(name):
    return cold(reduce(Image.open(BASE/'sources'/f'{name}.png'),(64,64)),source=True)


def watch_paint(name):
    return cold(reduce(Image.open(WATCH/'sources'/f'{name}.png'),(64,64)))


def paste_detail(im,name,points):
    result = im.copy()
    result.paste(watch_paint(name),(0,0),stencil(points))
    return result


def worn(im,variant):
    """Small native registration cuts; the material underneath remains painted."""
    result = im.copy(); d = ImageDraw.Draw(result)
    if variant == 1:
        # A shallow ancient circular carving on the huge upper block.
        d.arc((38,8,55,25),40,270,fill=2,width=1)
        d.arc((39,9,56,26),65,245,fill=5,width=1)
        d.line([(49,20),(45,23),(44,27)],fill=2,width=1)
    elif variant == 2:
        # Root fingers follow a mortar fault, with one pale bone in the joint.
        for p in ([(23,3),(24,12),(21,21),(23,30),(20,35)],
                  [(24,12),(29,17),(30,24)],[(21,21),(16,25),(15,30)]):
            d.line(p,fill=1,width=2); d.line([(x+1,y) for x,y in p],fill=3,width=1)
        d.line([(19,36),(25,35)],fill=6,width=1)
        d.point((19,35),fill=5); d.point((25,36),fill=5)
    return result


def walls():
    base = painting('wall')
    for y in range(64): base.putpixel((63,y),base.getpixel((0,y)))
    for x in range(64): base.putpixel((x,63),base.getpixel((x,0)))
    assets = {f'painted_f4_plain_{i}':ring(worn(base,i),base) for i in range(3)}
    masks = {
        'door':ARCH,'door_open':ARCH,
        'drain':[(13,29),(51,29),(51,55),(13,55)],
        'sconce_0':[(22,5),(40,5),(40,46),(22,46)],
        'sconce_1':[(22,5),(40,5),(40,46),(22,46)],
        'chains':[(17,6),(43,6),(47,53),(42,59),(20,56),(14,46)],
        'tapestry':[(17,8),(48,8),(47,56),(19,58)],
        'crack':[(27,15),(34,14),(43,33),(38,42),(44,59),(35,59),(33,42),(35,32)],
        'damp':[(39,9),(55,14),(56,57),(42,59),(36,42),(40,30)]}
    values = {k:paste_detail(base,'wall_'+k,m) for k,m in masks.items()}
    # Match the pre-existing registered arch exactly, even where its wall is new.
    opened = values['door'].copy()
    opened.paste(values['door_open'],(0,0),stencil(INNER)); values['door_open'] = opened
    # Only the fire changes; its warm emissive inks survive the cold grade.
    for kind in ('sconce_0','sconce_1'):
        raw = reduce(Image.open(WATCH/'sources'/f'wall_{kind}.png'),(64,64))
        values[kind].paste(raw,(0,0),stencil(FLAME))
    flicker = values['sconce_0'].copy()
    flicker.paste(values['sconce_1'],(0,0),stencil(FLAME)); values['sconce_1'] = flicker
    for kind,im in values.items(): assets[f'painted_f4_{kind}_v2'] = ring(im,base)
    overlay = assets['painted_f4_door_open_v2'].copy()
    overlay.paste(0,(0,0),stencil(APERTURE)); assets['painted_f4_door_open_overlay_v2'] = overlay
    for kind in ('arch_blocked','door_barricaded'):
        assets['painted_f4_'+kind] = ring(paste_detail(base,'wall_'+kind,ARCH),base)
    return assets


def plane_wear(im,kind):
    result = im.copy(); d = ImageDraw.Draw(result)
    if kind in ('stain','wet_small','wet_hook','wet_corner','wet_split','wet_wide'):
        shapes = {'stain':[(10,18),(22,15),(29,23),(24,34),(12,31)],
            'wet_small':[(39,38),(46,35),(52,42),(47,49),(40,47)],
            'wet_hook':[(20,8),(25,8),(25,25),(37,27),(34,32),(20,29)],
            'wet_corner':[(5,39),(16,35),(28,45),(23,56),(6,58)],
            'wet_split':[(17,8),(22,8),(29,27),(45,34),(44,39),(25,31)],
            'wet_wide':[(9,28),(24,22),(44,24),(56,38),(49,49),(26,43),(13,45)]}
        area = stencil(shapes[kind]); original = result.copy()
        # Irregular painted mineral dust, not an opaque flat patch or puddle.
        wear = reduce(Image.open(WATCH/'sources/floor_ash.png'),(64,64))
        for y in range(3,61):
            for x in range(3,61):
                ink = original.getpixel((x,y))
                if area.getpixel((x,y)) and ink >= 3:
                    salt = wear.getpixel((x,y)) in (7,8,9,10,28,29)
                    result.putpixel((x,y),min(6,ink+1) if salt else max(2,ink-1))
    if kind in ('chip','crack'):
        line = [(12,9),(20,17),(25,29),(33,34),(36,48),(48,57)]
        if kind == 'chip': line = [(42,11),(36,18),(41,27),(35,35)]
        d.line(line,fill=1,width=1)
        d.line([(x+1,y) for x,y in line],fill=5,width=1)
        d.line([(25,29),(16,33),(13,39)],fill=2,width=1)
    return result


def plane_detail(base,name,points,ink_only=False):
    result = base.copy(); detail = watch_paint(name); area = stencil(points)
    if ink_only:
        for y in range(64):
            for x in range(64):
                if detail.getpixel((x,y)) not in (1,2,6,7,8,9): area.putpixel((x,y),0)
    result.paste(detail,(0,0),area)
    return result


def planes():
    floor_ring = Image.open(OUT/'calm_v3_floor_dry_a.png')
    ceiling_ring = Image.open(OUT/'calm_v3_ceiling_plain.png')
    floor = painting('floor'); ceiling = painting('ceiling')
    t = Image.Transpose
    floors = {'dry_a':floor,'dry_b':floor.transpose(t.FLIP_LEFT_RIGHT),'dry_c':floor.transpose(t.ROTATE_180)}
    floors.update({k:plane_wear(floor,k) for k in FLOORS[3:]})
    floors = {k:ring(v,floor_ring) for k,v in floors.items()}
    ceilings = {'plain':ceiling,
        'root':plane_detail(ceiling,'ceiling_root',[(12,3),(49,3),(55,19),(44,41),(33,53),(22,49),(20,28)],True),
        'drip':plane_detail(ceiling,'ceiling_drip',[(21,20),(46,21),(49,40),(38,52),(26,43)],True)}
    ceilings = {k:ring(v,ceiling_ring) for k,v in ceilings.items()}
    assets = {'calm_v3_f4_floor_'+k:v for k,v in floors.items()}
    assets.update({'calm_v3_f4_ceiling_'+k:v for k,v in ceilings.items()})
    landmarks = {
        'floor_compass':plane_detail(floor,'floor_compass',[(13,13),(51,13),(51,51),(13,51)],True),
        'floor_cracked':floors['crack'].copy(),
        'floor_drain':plane_detail(floor,'floor_drain',[(19,19),(45,19),(45,45),(19,45)]),
        'ceiling_boss':plane_detail(ceiling,'ceiling_boss',[(19,17),(45,17),(47,42),(17,42)],True),
        'ceiling_chain':plane_detail(ceiling,'ceiling_chain',[(24,13),(40,13),(42,53),(23,53)],True),
        'ceiling_roots':ceilings['root'].copy()}
    for key,im in landmarks.items():
        assets['calm_v3_f4_room_'+key] = ring(im,ceiling_ring if key.startswith('ceiling') else floor_ring)
    assets['painted_f4_floor'] = floors['dry_a'].copy()
    assets['painted_f4_ceiling'] = ceilings['plain'].copy()
    return assets


def pair(im,stem):
    paths = []
    for suffix,view in [('native',im),('4x',im.resize((im.width*4,im.height*4),NEAREST))]:
        path = BASE/f'{stem}_{suffix}.png'
        if view.mode == 'P': save(view,path)
        else: view.save(path)
        paths.append(path)
    return paths


def views():
    # Reuse C's offline ray-sampling proof, without invoking its file-writing main.
    sys.path.insert(0,str(WATCH))
    spec = importlib.util.spec_from_file_location('deep_review_camera',WATCH/'build_views.py')
    camera = importlib.util.module_from_spec(spec); spec.loader.exec_module(camera)
    original_tex = camera.tex
    comparison = indexed((328,566),1).convert('RGBA')
    camera.caption(comparison,(8,5),'LOWER WATCH / DEEP - SAME CAMERA')
    paths, registrations = [],[]
    for row,(scene,back,tag) in enumerate((('corridor',3.5,'corridor'),('room',3.5,'room'),('room',1.25,'near_room'))):
        for col,family in enumerate((3,4)):
            camera.tex = original_tex if family == 3 else lambda name: original_tex(name.replace('_f3_','_f4_'))
            # Both proofs use floor3 hash/props: isolates materials; no F4 prop family.
            im,info = camera.render(3,scene,back=back)
            info.update({'material_family':family,'props_family':3,'comparison_slot_hash_floor':3})
            registrations.append(info); paths += pair(im,f'mockup_f{family}_{tag}')
            at = (8+col*164,32+row*176); comparison.paste(im,at)
            camera.caption(comparison,(at[0],at[1]+153),f'F{family} / {tag.upper().replace("_"," ")}')
    paths += pair(comparison,'mockup_comparison')
    camera.tex = original_tex
    corridor,_ = camera.render(3,'corridor',with_props=False)
    fall_sources = ROOT/'art_src/fx/fall/sources'; fall_sources.mkdir(parents=True,exist_ok=True)
    corridor.save(fall_sources/'lower_watch_corridor.png')
    (BASE/'mockup_registration.json').write_text(json.dumps({
        'status':'Offline 148x150 material proofs, not engine captures. Identical camera, lamp and F3 props/hash slots in each pair.',
        'camera':{'size':[148,150],'focal':74,'horizon':71,'far':3.6},'views':registrations},indent=2)+'\n')
    return paths


def verify(assets):
    expected = {p.stem.replace('_f3_','_f4_') for p in OUT.glob('*_f3_*.png')}
    assert set(assets) == expected, (set(assets)^expected)
    assert len(assets) == 37
    wall_base = assets['painted_f4_plain_0']
    for name,im in assets.items():
        assert im.size == (64,64) and im.mode == 'P' and im.getpalette() == TABLE
        assert set(im.convert('RGBA').getchannel('A').getdata()) <= {0,255}
        if name.startswith('calm_v3') or name in ('painted_f4_floor','painted_f4_ceiling'):
            ref = Image.open(OUT/('calm_v3_ceiling_plain.png' if 'ceiling' in name else 'calm_v3_floor_dry_a.png'))
        else: ref = wall_base
        for box in RING: assert im.crop(box).tobytes() == ref.crop(box).tobytes(),name
    for x in range(64): assert wall_base.getpixel((x,0)) == wall_base.getpixel((x,63))
    for y in range(64): assert wall_base.getpixel((0,y)) == wall_base.getpixel((63,y))
    for a,b,points in [('door_v2','door_open_v2',INNER),('sconce_0_v2','sconce_1_v2',FLAME)]:
        allowed = stencil(points)
        p,q = assets['painted_f4_'+a],assets['painted_f4_'+b]
        assert all(p.getpixel((x,y)) == q.getpixel((x,y)) for y in range(64) for x in range(64) if not allowed.getpixel((x,y)))
    overlay = assets['painted_f4_door_open_overlay_v2']; opened = assets['painted_f4_door_open_v2']; hole = stencil(APERTURE)
    assert all(overlay.getpixel((x,y)) == (0 if hole.getpixel((x,y)) else opened.getpixel((x,y))) for y in range(64) for x in range(64))
    assert len({assets['calm_v3_f4_floor_'+k].tobytes() for k in FLOORS}) == 11


def main():
    # Snapshot existing art before writing. First-run snapshot survives rebuilds.
    snapshot = BASE/'preserved_hashes.json'
    if not snapshot.exists():
        existing = list(OUT.glob('*.png'))+list((ROOT/'assets/art/fx').glob('*.png'))+list((ROOT/'assets/art/fixtures').glob('fixture_v2_lever_*.png'))
        existing = [p for p in existing if '_f4_' not in p.name and not p.name.startswith('fall_crumble_')]
        snapshot.write_text(json.dumps({p.relative_to(ROOT).as_posix():digest(p) for p in sorted(existing)},indent=2)+'\n')
    assets = dict(walls(),**planes()); verify(assets)
    paths = []
    for name,im in assets.items():
        path = OUT/f'{name}.png'; save(im,path); paths.append(path)
    contact({k.removeprefix('painted_f4_').removeprefix('calm_v3_f4_'):v for k,v in assets.items()},BASE,
        columns=5,cell=(166,100),title='UNDERCROFT / THE DEEP / F4 / BASALT, ROOT, BONE')
    previews = views()
    (BASE/'layout.json').write_text(json.dumps({'schema_version':1,'floor_family':4,'canvas':[64,64],'anchor':[0,0],
        'files':list(assets),'art_family_mapping':{'walls':4,'fixtures':2,'props':3,'planes':'calm_v3_f4','weights':2},
        'family_rule':'Use F4 material family for Deep floor numbers >=4; retain actual floor number in world-cell hash. F1-F3 unchanged.',
        'wall_path':'res://assets/art/env/painted_f4_{existing_suffix}.png',
        'plane_path':'res://assets/art/env/calm_v3_f4_{plane}_{existing_kind}.png',
        'room_path':'res://assets/art/env/calm_v3_f4_room_{existing_kind}.png',
        'uv':'One 64px tile per world cell; U east, V south; no view-relative rotation. Restore seam ring after quarter-turns.',
        'floor_slots':list(FLOORS),'wet_slots':'Cold mineral wear/root grime; no water or new gameplay.',
        'wall_ring':'Own plain_0 exact2px; opposite outer edges match.',
        'plane_ring':'Exact existing calm_v3 floor_dry_a / ceiling_plain 2px, including room landmarks and aliases.',
        'door_interior':INNER,'door_aperture':APERTURE,'fire_mask':FLAME,'sconce_ms':[250,250],
        'portal':'Use transparent door_open_overlay_v2 for actual open portal; opaque door_open_v2 reference only.',
        'prop_family':3,'fixture_family':2,'filter':'nearest'},indent=2)+'\n')
    preserved = json.loads(snapshot.read_text())
    assert all(digest(ROOT/p) == sha for p,sha in preserved.items()),'Existing art changed during build'
    manifest(paths+[BASE/'contact_sheet_native.png',BASE/'contact_sheet_4x.png'],BASE/'manifest.json',{
        'runtime_count':len(assets),'layout':'layout.json',
        'provenance':'Three new saved paintings; C Lower Watch saved paintings supply clipped registered dressing details. Native minor carving/root/wear registration; deterministic cold palette reduction.',
        'dependency_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':digest(p)} for p in
            sorted(list((WATCH/'sources').glob('*.png'))+[WATCH/'build_views.py',WATCH/'selection.py',
                BASE/'build_deep.py',BASE/'prompts.json',BASE.parent/'pipeline.py',
                ROOT/'art_src/spike/palette.gpl',ROOT/'assets/font/vetka.ttf',
                OUT/'calm_v3_floor_dry_a.png',OUT/'calm_v3_ceiling_plain.png'])],
        'preview_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':digest(p)} for p in previews],
        'preserved_existing_pngs':len(preserved)})
    print(f'Deep: {len(assets)} textures; exact F3 suffix parity, palette, binary alpha, ring, door/fire masks, eleven floor slots and {len(preserved)} existing PNG hashes passed.')


if __name__ == '__main__': main()
