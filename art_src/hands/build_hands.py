"""Offline held-item reduction and fixed bottom-right registration.

Painted sources are preserved. All sampling and review enlargement is NEAREST;
the shared 31 opaque inks and transparent index 0 are unchanged.
"""
import sys
sys.dont_write_bytecode = True
import hashlib
from pathlib import Path
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, NEAREST, canvas, contact, label, manifest, paste, reduce, save, strip

BASE = Path(__file__).resolve().parent
SOURCE = BASE / 'sources'
OUT = ROOT / 'assets/art/hands'
SIZE = (48, 56)
ORDER = ['fist', 'knife', 'shard', 'club', 'stone', 'bone', 'clapper',
         'lamp', 'torch_unlit', 'torch_lit', 'seal']
STATES = {
    'fist': ['rest', 'punch'], 'knife': ['rest', 'slash'],
    'shard': ['rest', 'slash'], 'club': ['rest', 'blow'],
    'stone': ['rest', 'blow'], 'bone': ['rest', 'blow'],
    'clapper': ['rest', 'blow', 'ring'], 'lamp': ['rest', 'sway'],
    'torch_unlit': ['rest', 'use'], 'torch_lit': ['a', 'b'],
    'seal': ['a', 'b'],
}
ASSETS = []


def source_frames(kind, count):
    """Keep the principal connected silhouette in each explicitly equal cell."""
    source = Image.open(SOURCE / f'{kind}_sheet.png').convert('RGBA')
    frames = []
    for index in range(count):
        frame = source.crop((round(source.width*index/count), 0,
                             round(source.width*(index+1)/count), source.height))
        rgba = np.array(frame)
        components, total = ndimage.label(rgba[:, :, 3] >= 128)
        counts = np.bincount(components.ravel()); counts[0] = 0
        assert total and counts.max() > 1000, kind
        rgba[:, :, 3] = np.where(components == counts.argmax(), 255, 0)
        clean = Image.fromarray(rgba)
        frames.append(clean.crop(clean.getbbox()))
    return frames


def registered(kind, count=2, max_height=56):
    frames = source_frames(kind, count)
    # One scale across a pose sheet. Never normalize each frame independently.
    scale = min(SIZE[0]/max(im.width for im in frames),
                max_height/max(im.height for im in frames))
    result = []
    for frame in frames:
        size = (max(1, round(frame.width*scale)), max(1, round(frame.height*scale)))
        native = reduce(frame.resize(size, NEAREST))
        out = canvas(SIZE)
        paste(out, native, (SIZE[0]-size[0], SIZE[1]-size[1]))
        result.append(out)
    return result


def torch_flame(base, frame):
    """Two native flame silhouettes; painted reed, glove and cuff stay identical."""
    out = base.copy()
    rows = np.array(base)
    top = base.getbbox()[1]
    xs = np.where(rows[top:min(top+4, 56)] != 0)[1]
    cx = int(np.median(xs))
    d = ImageDraw.Draw(out)
    if frame == 0:
        shape = [(cx-3, top+3), (cx-4, top-1), (cx-1, top-5),
                 (cx, top-10), (cx+2, top-6), (cx+4, top-3), (cx+3, top+3)]
        core = [(cx-1, top+2), (cx-1, top-3), (cx+1, top-6), (cx+2, top+2)]
    else:
        shape = [(cx-3, top+3), (cx-4, top-2), (cx-2, top-6),
                 (cx+2, top-9), (cx+1, top-4), (cx+4, top-1), (cx+3, top+3)]
        core = [(cx-1, top+2), (cx, top-5), (cx+2, top-2), (cx+2, top+2)]
    d.polygon(shape, fill=22)
    d.polygon([(cx-2, top+2), (cx-2, top-3), (cx+1, top-7),
               (cx+3, top-2), (cx+2, top+3)], fill=25)
    d.polygon(core, fill=10)
    return out


def seal_pulse(base):
    out = base.copy()
    # Warm the face only, not the glove or sleeve; exact same alpha/pose.
    mapping = {25:26, 26:10, 9:10}
    for y in range(26):
        for x in range(28):
            if ((x-17)/10)**2 + ((y-14)/11)**2 > 1:
                continue
            ink = out.getpixel((x,y))
            out.putpixel((x,y), mapping.get(ink, ink))
    return out


def add_ring_lines(frame):
    out = frame.copy()
    d = ImageDraw.Draw(out)
    # Inspected against the reduced bulb registration; fixed native pixels.
    d.line([(3,12),(1,15),(1,18),(3,21)], fill=25)
    d.line([(7,14),(6,16),(7,19)], fill=26)
    d.line([(37,10),(40,13),(40,17),(38,20)], fill=25)
    return out


def export(kind, frames):
    states = STATES[kind]
    for state, frame in zip(states, frames):
        record = save(frame, OUT / f'hand_{kind}_{state}_56.png')
        record.update(kind=kind, state=state, anchor=[48,56],
                      opaque_bounds=list(frame.getbbox()), view_position=[100,94])
        ASSETS.append(record)
    record = save(strip(frames), OUT / f'hand_{kind}_strip_56.png')
    record.update(kind=kind, anchor=[48,56], frame_size=[48,56], frame_order=states)
    ASSETS.append(record)


def review_pair(path, image):
    native = path.with_name(path.name.replace('_4x.png', '_native.png'))
    save(image, native)
    save(image.resize((image.width*4, image.height*4), NEAREST), path)


def screenshot_view():
    screenshot = Image.open(SOURCE / 'corridor_reference.png').convert('RGBA')
    assert screenshot.size == (462,1026), 'Freeze the original 3x review screenshot'
    logical = screenshot.resize((154,342), NEAREST)
    return reduce(logical.crop((3,21,151,171)))


def mockups(all_frames):
    view = screenshot_view()
    overview = canvas((4*156+8, 3*176+36), 1)
    label(overview, (8,4), 'Finder / rest poses over frozen corridor', 25)
    for index, kind in enumerate(ORDER):
        frames = all_frames[kind]
        out = canvas((8+156*len(frames), 190), 1)
        label(out, (8,2), f'{kind} / composited view', 25)
        for i, (state, frame) in enumerate(zip(STATES[kind], frames)):
            composited = view.copy()
            paste(composited, frame, (100,94))
            # Central geometry must be byte-identical to the screenshot.
            assert composited.crop((0,0,100,150)).tobytes() == view.crop((0,0,100,150)).tobytes()
            paste(out, composited, (8+i*156,20))
            label(out, (8+i*156,171), state)
            if i == 0:
                x,y = 8+(index%4)*156, 28+(index//4)*176
                paste(overview, composited, (x,y))
                label(overview, (x,y+151), kind)
        review_pair(BASE / f'{kind}_mockup_4x.png', out)
    review_pair(BASE / 'hands_corridor_overview_4x.png', overview)


def main():
    all_frames = {kind:registered(kind, 3 if kind=='clapper' else 2,
                                 44 if kind=='fist' else 56)
                  for kind in ORDER[:8]}
    all_frames['clapper'][2] = add_ring_lines(all_frames['clapper'][2])
    all_frames['torch_unlit'] = registered('torch', 2, 46)
    all_frames['torch_lit'] = [torch_flame(all_frames['torch_unlit'][0], i) for i in range(2)]
    seal = registered('seal', 1)[0]
    all_frames['seal'] = [seal, seal_pulse(seal)]
    for kind in ORDER:
        export(kind, all_frames[kind])
    rows = [(kind, list(zip(STATES[kind], all_frames[kind]))) for kind in ORDER]
    contact(BASE / 'hands_contact_4x.png', 'Finder / held item poses / 48 x 56', rows)
    contact(BASE / 'hands_weapons_4x.png', 'Finder / glove, edge and heavy', rows[:7])
    contact(BASE / 'hands_utility_4x.png', 'Finder / light and the Dawn Seal', rows[7:])
    mockups(all_frames)
    source_hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in sorted(SOURCE.glob('*.png'))}
    manifest(BASE / 'hands_manifest.json', {
        'frame_size':[48,56], 'anchor':[48,56], 'view_size':[148,150],
        'view_position':[100,94], 'sources':source_hashes, 'assets':ASSETS,
        'note':'Review mockups composite frozen screenshot pixels; no engine capture implied.'})
    print(f'Hands: {len(ASSETS)} runtime PNGs; {sum(len(v) for v in all_frames.values())} poses; 15 review sheets')


if __name__ == '__main__':
    main()
