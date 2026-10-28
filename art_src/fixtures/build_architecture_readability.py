"""New wall faces for the phone readability correction; never rewrites old art.

Owner painting is DOWN by explicit final direction. UP is a matching new source.
Review ray casting is offline Python, independent of the running Godot workers.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from pathlib import Path
from PIL import Image, ImageDraw
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, RGB, NEAREST, canvas, contact, label, manifest, paste, reduce, save
from build_architecture import arch_mask, side_projection, side_anchor, preserve_border, deep_repaint

BASE = Path(__file__).resolve().parent / 'readability'
SOURCE = BASE / 'sources'
OUT = ROOT / 'assets/art/fixtures'
OLD = ROOT / 'art_src/fixtures/architecture/sources'
OWNER = OLD / 'fe3439be-72ab-49d3-8af7-49e3b2e58160.png'
KINDS = ['stairs_down','stairs_up','lift_dead']
HEIGHTS = [64,40,24]
ASSETS = []
INPUTS = {OWNER}


def read(path):
    INPUTS.add(path)
    return Image.open(path).copy()


def painting(path):
    return reduce(read(path).convert('RGBA').resize((64,64),NEAREST))


def carve(face, down):
    """Wide recessed chevron with a pale lower bevel, on the existing keystone."""
    d = ImageDraw.Draw(face)
    points = [(26,7),(32,13),(38,7)] if down else [(26,13),(32,7),(38,13)]
    d.line(points,fill=2,width=4)
    d.line([(x,y+1) for x,y in points],fill=9,width=2)


def floor_two(face, kind):
    out = deep_repaint(face, kind.startswith('stairs'))
    # Step lips are caught by the Finder's lamp, not damp masonry. Retain the
    # ivory/sand accents inside the opening while making the stone colder.
    if kind.startswith('stairs'):
        opening = arch_mask(True)
        for y in range(64):
            for x in range(64):
                if opening.getpixel((x,y)) and face.getpixel((x,y)) in [9,10,25,26]:
                    out.putpixel((x,y),face.getpixel((x,y)))
    # Sparse moisture seams on the jamb, not on the tread or metal silhouette.
    d = ImageDraw.Draw(out)
    for path in [[(15,33),(15,38),(14,41)],[(48,43),(48,47),(47,49)]]:
        d.line(path,fill=12)
    return out


def export(im, floor, kind, suffix, **metadata):
    record = save(im, OUT/f'architecture_v2_f{floor}_{kind}_{suffix}.png')
    record.update(floor=floor,kind=kind,**metadata)
    ASSETS.append(record)


def faces():
    down = painting(OWNER)
    up = painting(SOURCE/'stairs_up_matching_owner.png')
    lift = painting(SOURCE/'lift_dead_closed.png')
    opening, outer = arch_mask(True), arch_mask()
    # Retain the painted accordion silhouette and wear, but lift its steel/rust
    # values above the near-black recess. No new lamp or glow is introduced.
    metal = {4:6,5:7,6:8,20:22,21:23,27:6,28:7,29:8}
    for y in range(16,61):
        for x in range(18,46):
            if opening.getpixel((x,y)):
                ink=lift.getpixel((x,y))
                lift.putpixel((x,y),metal.get(ink,ink))
    all_faces = {}
    for floor in [1,2]:
        wall = reduce(read(OLD/f'painted_f{floor}_base.png'))
        for kind, inset in [('stairs_down',down),('stairs_up',up),('lift_dead',lift)]:
            if kind.startswith('stairs'):
                # Both stair faces share the owner's arch; do not re-use the
                # rejected old staircase or its impossible left-hand flight.
                face = reduce(read(OLD/'painted_f1_base.png'))
                face.paste(down,(0,0),outer)
                face.paste(inset,(0,0),opening)
                carve(face,kind=='stairs_down')
            else:
                face = read(OUT/'architecture_f1_lift_dead_64.png')
                face.paste(inset,(0,0),opening)
            if floor == 2:
                inset_frame = floor_two(face,kind)
                face = wall.copy()
                face.paste(inset_frame,(0,0),outer)
            # Preserve old material seams and every UV/threshold coordinate.
            preserve_border(face,wall)
            all_faces[(floor,kind)] = face
            for depth,height in enumerate(HEIGHTS,1):
                export(face.resize((height,height),NEAREST),floor,kind,str(height),
                       anchor=[0,0],wall_uv=True,depth=depth,
                       threshold_anchor=[height//2,round(62*height/64)])
            for depth,size in enumerate([(32,64),(20,40),(12,24)],1):
                for side in ['left','right']:
                    projected = side_projection(face,size,side=='right')
                    export(projected,floor,kind,f'{side}_d{depth}',
                           anchor=list(side_anchor(size,side=='right')),depth=depth,
                           projection=side,anchor_kind='centre of projected wall threshold')
    return all_faces


def review_pair(path, im):
    save(im,path.with_name(path.name.replace('_4x','_native')))
    save(im.resize((im.width*4,im.height*4),NEAREST),path)


def gain(depth):
    return max(0,min(1,(3.6-depth)/2.7))


def corridor(face, floor, distance, lit=True):
    """148x150, FOCAL 74, HORIZON 71, one-cell corridor, UV64 sampling.

    Matches A's projection and lamp equation; no game state, particles or RNG.
    Kept in indexed palette for consistent exact-4x review exports.
    """
    width,height,focal,horizon = 148,150,74.,71
    wall = reduce(read(OLD/f'painted_f{floor}_base.png'))
    ground = reduce(read(ROOT/f'assets/art/env/f{floor}_floor.png'))
    roof = reduce(read(ROOT/f'assets/art/env/f{floor}_ceiling.png'))
    out = canvas((width,height),1)
    shade_cache = {}
    def shade(ink, amount):
        if not lit:
            return ink
        key = ink,round(amount,3)
        if key not in shade_cache:
            r,g,b = [v*amount for v in RGB[ink]]
            shade_cache[key] = min(range(1,32),key=lambda i:2*(r-RGB[i][0])**2+4*(g-RGB[i][1])**2+(b-RGB[i][2])**2)
        return shade_cache[key]
    for y in range(height):
        floor_side = y>horizon
        depth = focal*.5/(abs(y-horizon)+.5)
        if depth>=3.6:
            continue
        for x in range(width):
            ray_x = (x+.5-width*.5)/focal
            u = int((.5+ray_x*depth)*64)%64
            v = int(depth*64)%64
            ink = (ground if floor_side else roof).getpixel((u,v))
            out.putpixel((x,y),shade(ink,gain(depth)*(.86 if floor_side else .64)))
    for x in range(width):
        ray_x = (x+.5-width*.5)/focal
        side_depth = .5/abs(ray_x) if ray_x else 10000
        side = side_depth < distance
        depth = min(side_depth,distance)
        h = max(1,round(focal/depth))
        top = horizon-h//2
        u = int((depth%1 if side else (.5+ray_x*depth)%1)*64)
        for y in range(max(0,top),min(height,top+h)):
            v = min(63,int((y-top)*64/h))
            ink = (wall if side else face).getpixel((u,v))
            out.putpixel((x,y),shade(ink,gain(depth)*(.78 if side else 1)))
    return out


def reviews(all_faces):
    owner_source = read(OWNER)
    contact(BASE/'owner_down_evaluation_4x.png','OWNER / accepted as DOWN',
            [(f'{h}px',[(str(h),reduce(owner_source.resize((h,h),NEAREST)))]) for h in HEIGHTS])
    for floor in [1,2]:
        rows = []
        for h in HEIGHTS:
            rows.append((f'F{floor} / {h}px / front',[(k.replace('stairs_',''),all_faces[(floor,k)].resize((h,h),NEAREST)) for k in KINDS]))
        contact(BASE/f'architecture_v2_f{floor}_contact_4x.png',f'READABILITY / FLOOR {floor}',rows)
    side_rows = []
    for floor in [1,2]:
        for depth,size in enumerate([(32,64),(20,40),(12,24)],1):
            for side in ['left','right']:
                side_rows.append((f'F{floor} / {side} / D{depth}',[(k.replace('stairs_',''),side_projection(all_faces[(floor,k)],size,side=='right')) for k in KINDS]))
    contact(BASE/'architecture_v2_sides_4x.png','READABILITY / SIDE WALLS',side_rows)
    comparisons = []
    for floor in [1,2]:
        for h in HEIGHTS:
            entries = []
            for caption,im in [('old dead',read(OUT/f'architecture_f{floor}_lift_dead_64.png')),
                              ('shut dead',all_faces[(floor,'lift_dead')]),
                              ('working',read(OUT/f'architecture_f{floor}_lift_working_64.png'))]:
                entries.append((caption,im.resize((h,h),NEAREST)))
            comparisons.append((f'F{floor} / {h}px / state change',entries))
    contact(BASE/'lift_closed_comparison_4x.png','LIFT / SHUT TO WORKING',comparisons)
    for floor in [1,2]:
        # Three grid distances: directly adjacent, one cell away, two away.
        sheet = canvas((3*156+8,4*177+32),1)
        label(sheet,(8,4),f'F{floor} / corridor / lamp shaded',25)
        for row,kind in enumerate(KINDS+['lift_working']):
            face = all_faces[(floor,kind)] if kind in KINDS else read(OUT/f'architecture_f{floor}_lift_working_64.png')
            for col,distance in enumerate([.5,1.5,2.5]):
                x,y = 8+col*156,28+row*177
                paste(sheet,corridor(face,floor,distance),(x,y))
                label(sheet,(x,y+151),f'{kind.replace("stairs_","")} D{col+1}')
        review_pair(BASE/f'corridor_f{floor}_depths_4x.png',sheet)
    original = read(SOURCE/'corridor_reference.png').convert('RGBA')
    logical = original.resize((154,342),NEAREST)
    review_pair(BASE/'original_corridor_reference_4x.png',reduce(logical))


def main():
    all_faces = faces()
    reviews(all_faces)
    source_hashes = {path.relative_to(ROOT).as_posix():hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in sorted(INPUTS)}
    manifest(BASE/'manifest.json',{
        'owner_down_source':OWNER.relative_to(ROOT).as_posix(),
        'direction':'Owner final decision: supplied painting is stairs down; preserve geometry.',
        'sources':source_hashes,'assets':ASSETS,
        'canonical_uv_anchor':[0,0],'canonical_threshold_anchor':[32,62],
        'new_prefix':'architecture_v2_f','working_lift':'Reuse original architecture_f%d_lift_working_*',
        'mockup':'Offline corridor projection, not a Godot integration capture; grid distances .5/1.5/2.5.'})
    print(f'Architecture readability: {len(ASSETS)} new runtime PNGs; old faces and owner source preserved')


if __name__ == '__main__':
    main()
