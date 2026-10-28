"""Three native-pixel sparkle frames, gold/selected teal, 9px and 7px.

No painted source, filtering, opacity gradients, RNG or runtime dependency.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
from PIL import ImageDraw
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, canvas, contact, manifest, save, strip

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/fixtures'
TIMING = [70, 100, 90]


def glint(size, frame, selected=False):
    im = canvas((size,size)); d = ImageDraw.Draw(im)
    c = size//2
    tip, middle, inner = (13,16,17) if selected else (23,25,26)
    if frame == 0:
        d.line((c-1,c,c+1,c),fill=middle)
        d.line((c,c-1,c,c+1),fill=middle)
        d.point((c,c),fill=10)
    elif frame == 1:
        for distance in range(1,c+1):
            ink = inner if distance == 1 else (middle if distance < c else tip)
            for point in [(c-distance,c),(c+distance,c),(c,c-distance),(c,c+distance)]:
                d.point(point,fill=ink)
        if size == 9:
            for point in [(c-1,c-1),(c+1,c-1),(c-1,c+1),(c+1,c+1)]:d.point(point,fill=middle)
        d.point((c,c),fill=10)
    else:
        d.point((c,c),fill=tip)
        d.line((c-2,c-2,c-1,c-1),fill=middle)
        d.line((c+1,c+1,c+2,c+2),fill=tip)
    return im


def main():
    assets,rows = [],[]
    for family in ['gold','target']:
        for size in [9,7]:
            frames = [glint(size,i,family=='target') for i in range(3)]
            for i,im in enumerate(frames):
                entry=save(im,OUT/f'glint_{family}_{i}_{size}.png')
                entry.update(anchor=[size//2,size//2],frame=i,frame_ms=TIMING[i],family=family,
                             purpose='decorative interaction cue / fixed centre in screen pixels')
                assets.append(entry)
            entry=save(strip(frames),OUT/f'glint_{family}_strip_{size}.png')
            entry.update(anchor=[size//2,size//2],frame_count=3,frame_size=[size,size],frame_order=['0','1','2'])
            assets.append(entry)
            rows.append((f'{family} / {size} px / near' if size==9 else f'{family} / {size} px / far',
                         [('bud / 70ms',frames[0]),('peak / 100ms',frames[1]),('fall / 90ms',frames[2])]))
    contact(BASE/'glint_contact_4x.png','INTERACTION / THREE FRAME GLINT',rows)
    manifest(BASE/'glint_manifest.json',{'assets':assets,'frame_ms':TIMING,'burst_ms':sum(TIMING),
             'cycle_ms':2200,'quiet_ms':2200-sum(TIMING),'blank_interval':'draw nothing; no fourth image',
             'phase':'stable per floor/object id; presentation only; independent of gameplay RNG',
             'suggested_phase_hash':'FNV1a32 with double 0x45d9f3b avalanche, modulo 2200'})
    print('Glints: 12 frames + 4 strips, 9px / 7px, gold and valid-target teal')


if __name__=='__main__':main()
