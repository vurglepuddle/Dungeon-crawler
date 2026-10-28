"""Editable native pixel drawings: skewed side-wall lever and floor inset slab."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from PIL import ImageDraw, ImageOps
from pipeline import ROOT, canvas, contact, manifest, save

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/fx'
LEVER_SIZES = [(32, 40), (20, 26), (12, 16)]
PLATE_SIZES = [(64, 20), (40, 12), (24, 8)]


def lever(size, down):
    im = canvas(size); d = ImageDraw.Draw(im)
    w, h = size
    def p(x, y): return round(x*(w-1)/31), round(y*(h-1)/39)
    def poly(points, ink): d.polygon([p(*v) for v in points], fill=ink)
    def line(points, ink, width=1): d.line([p(*v) for v in points], fill=ink, width=max(1, round(width*w/32)))
    poly([(3, 2), (27, 9), (27, 33), (3, 39)], 1)
    poly([(4, 3), (26, 10), (26, 32), (4, 37)], 5)
    poly([(7, 6), (23, 11), (23, 30), (7, 34)], 18)
    line([(4, 3), (4, 37)], 8)
    line([(5, 4), (25, 10)], 7)
    line([(26, 11), (26, 32), (5, 38)], 3)
    for x, y in [(8, 10), (21, 13), (8, 31), (21, 28)]:
        d.point(p(x, y), fill=8)
    poly([(11, 16), (21, 18), (21, 25), (11, 27)], 3)
    poly([(13, 18), (20, 19), (20, 24), (13, 25)], 23)
    tip = (11, 32) if down else (11, 8)
    line([(17, 22), tip], 1, 6)
    line([(16, 22), tip], 24, 3)
    line([(15, 22), (tip[0]-1, tip[1])], 26)
    x, y = tip
    poly([(x-4, y-2), (x+2, y-3), (x+5, y), (x+2, y+3), (x-4, y+2)], 19)
    poly([(x-3, y-2), (x+1, y-2), (x+3, y), (x, y+1), (x-3, y+1)], 25)
    d.point(p(x-2, y-2), fill=26)
    return im


def plate(size, pressed):
    im = canvas(size); d = ImageDraw.Draw(im)
    w, h = size
    # Every outer edge is at most one pixel deep: no standing legs/fascia/shadow.
    d.polygon([(w//5, 0), (w-1-w//5, 0), (w-1, h-2), (w-1, h-1), (0, h-1), (0, h-2)], fill=1)
    d.polygon([(w//5, 1), (w-1-w//5, 1), (w-2, h-2), (1, h-2)], fill=5)
    inset = [(w//5+2, 2), (w-3-w//5, 2), (w-5, h-3), (4, h-3)]
    d.polygon(inset, fill=3 if pressed else 27)
    d.line([(w//5, 1), (w-1-w//5, 1)], fill=3 if pressed else 8)
    d.line([(2, h-2), (w-3, h-2)], fill=6 if pressed else 8)
    cx, cy = w//2, h//2
    d.line([(cx-w//10, cy+1), (cx, cy-1), (cx+w//10, cy+1), (cx, cy+2), (cx-w//10, cy+1)], fill=5 if pressed else 29)
    if w >= 40:
        d.line([(w//4, h//2), (w//4+4, h//2)], fill=4 if pressed else 28)
        d.point((w*3//4, h*2//3), fill=6)
    return im


def main():
    assets = []
    lever_rows, plate_rows = [], []
    for i, (size, ps) in enumerate(zip(LEVER_SIZES, PLATE_SIZES), 1):
        states = []
        for down, name in [(False, 'up'), (True, 'down')]:
            im = lever(size, down)
            for side in ['left', 'right']:
                side_im = im if side == 'left' else ImageOps.mirror(im)
                side_im.putpalette(im.getpalette()); side_im.info['transparency'] = 0
                entry = save(side_im, OUT / f'lever_{side}_{name}_d{i}.png')
                entry.update(depth=i, anchor=[round(16*(size[0]-1)/31), round(22*(size[1]-1)/39)], anchor_kind='wall hinge')
                if side == 'right': entry['anchor'][0] = size[0]-1-entry['anchor'][0]
                assets.append(entry)
            states.append((name, im))
        lever_rows.append((f'Depth {i} / {size[0]} x {size[1]}', states))
        entries = []
        for pressed, name in [(False, 'up'), (True, 'down')]:
            im = plate(ps, pressed)
            entry = save(im, OUT / f'plate_{name}_d{i}.png')
            entry.update(depth=i, anchor=[ps[0]//2, ps[1]], anchor_kind='floor bottom centre')
            assets.append(entry)
            entries.append((name, im))
        plate_rows.append((f'Depth {i} / {ps[0]} x {ps[1]}', entries))
    contact(BASE / 'lever_contact_4x.png', 'SIDE WALL LEVER / LEFT', lever_rows)
    contact(BASE / 'plate_contact_4x.png', 'INSET PRESSURE PLATE', plate_rows)
    manifest(BASE / 'fixtures_manifest.json', {'assets': assets, 'lever_states': 'discrete swap, never tween', 'plate_edge_depth_px': 1})
    print(f'Fixtures: {len(assets)} assets')


if __name__ == '__main__':
    main()
