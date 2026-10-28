"""M3c fixtures: preserved paintings + integer pixel flames, strands and sigils.

Python + Pillow. Uses the established shared palette and NEAREST only.
--native-only builds the code drawings while painted sources are being made.
"""
import sys
sys.dont_write_bytecode = True
import argparse
import hashlib
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, NEAREST, canvas, contact, manifest, paste, reduce, save, strip

BASE = Path(__file__).resolve().parent
SOURCES = BASE / 'sources'
OUT = ROOT / 'assets/art/fixtures'
HEIGHTS = [64, 40, 24]
ASSETS = []


def export(im, name, anchor, purpose, frame_ms=0, depth=None):
    entry = save(im, OUT / f'{name}.png')
    entry.update(anchor=list(anchor), purpose=purpose, frame_ms=frame_ms)
    if depth is not None: entry['depth'] = depth
    ASSETS.append(entry)
    return entry


def sizeset(name, states, size64, purpose, timing=0):
    rows = []
    for depth, height in enumerate(HEIGHTS, 1):
        size = (round(size64[0]*height/64), round(size64[1]*height/64))
        frames = [(state, im if im.size == size else im.resize(size, NEAREST)) for state, im in states]
        for state, im in frames:
            animated = state.startswith(('lit_', 'pulse_', 'burning_'))
            export(im, f'{name}_{state}_d{depth}', (size[0]//2, size[1]), purpose, timing if animated else 0, depth)
        export(strip([im for _, im in frames]), f'{name}_strip_d{depth}', (size[0]//2, size[1]), 'state strip; per-frame anchor', 0, depth).update(frame_count=len(frames), frame_order=[state for state,_ in frames], frame_size=list(size))
        rows.append((f'Depth {depth} / {size[0]} x {size[1]}', frames))
    contact(BASE / f'{name}_contact_4x.png', name.upper().replace('_', ' '), rows)


def crop_paint(name):
    im = Image.open(SOURCES / f'{name}.png').convert('RGBA')
    box = im.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    if box is None: raise ValueError(name)
    return im.crop(box)


def fitted(source, size, max_width, max_height):
    scale = min(max_width/source.width, max_height/source.height)
    resized = source.resize((max(1, round(source.width*scale)), max(1, round(source.height*scale))), NEAREST)
    out = canvas(size)
    left, top = (size[0]-resized.width)//2, size[1]-1-resized.height
    paste(out, reduce(resized), (left, top))
    return out, (left, top, resized.width, resized.height)


def flame(im, x, base, width, height, frame):
    """Editable pixel flame. Same palette; no alpha gradients or random sparks."""
    d = ImageDraw.Draw(im)
    def p(u, v): return round(x+(u-.5)*width), round(base-v*height)
    def poly(points, ink): d.polygon([p(*xy) for xy in points], fill=ink)
    if frame == 0:
        shape = [(0, .06), (.04, .44), (.25, .32), (.35, .82), (.51, 1), (.55, .57), (.72, .72), (.78, .34), (.94, .52), (1, .12), (.8, 0), (.22, 0)]
    else:
        shape = [(0, .12), (.15, .59), (.27, .44), (.23, .79), (.43, .62), (.66, 1), (.68, .58), (.84, .7), (.82, .33), (1, .2), (.86, 0), (.2, 0)]
    poly(shape, 21)
    poly([(.1, .09), (.2, .45), (.36, .31), (.43 if frame == 0 else .56, .83), (.59, .46), (.73, .59), (.86, .22), (.76, .04)], 23)
    poly([(.24, .04), (.28, .33), (.42, .26), (.54, .62), (.63, .29), (.76, .26), (.69, .02)], 25)
    poly([(.39, .02), (.4, .22), (.54, .38), (.62, .15), (.6, 0)], 10)


def brazier():
    cold, (_, top, _, height) = fitted(crop_paint('brazier_cold'), (64, 64), 56, 43)
    mouth = top+max(3, round(height*.11))
    lit = []
    for frame in range(2):
        im = cold.copy()
        # Fixed warm bed of coal, kept identical between flicker frames.
        d = ImageDraw.Draw(im)
        d.ellipse((21, mouth-1, 43, mouth+4), fill=20)
        d.line((24, mouth+2, 40, mouth+2), fill=24)
        flame(im, 32, mouth+2, 25, min(26, mouth+1), frame)
        lit.append(im)
    sizeset('brazier', [('cold', cold), ('lit_0', lit[0]), ('lit_1', lit[1])], (64, 64), 'floor brazier / torch LIGHT target', 180)


def torch():
    cold, (left, top, width, height) = fitted(crop_paint('reed_torch_unlit'), (32, 48), 18, 33)
    # Locate the bundle head so fire follows its slight lean, not the canvas centre.
    alpha = cold.convert('RGBA').getchannel('A')
    head = [(x, y) for y in range(top, min(top+9, 48)) for x in range(32) if alpha.getpixel((x, y)) >= 128]
    cx = round(sum(x for x, _ in head)/len(head))
    # Keep one broad pale reed continuous down the lower half; this is the
    # useful material cue after the painted grip reduces to a dark pixel.
    d = ImageDraw.Draw(cold)
    for y in range(top+round(height*.45), top+height):
        xs = [x for x in range(32) if alpha.getpixel((x, y)) >= 128]
        if xs:
            centre = round(sum(xs)/len(xs))
            d.point((centre, y), fill=8)
            if len(xs) >= 3: d.point((centre-1, y), fill=28)
    lit = []
    for frame in range(2):
        im = cold.copy()
        flame(im, cx, top+6, 17, min(20, top+6), frame)
        lit.append(im)
    sizeset('reed_torch', [('unlit', cold), ('lit_0', lit[0]), ('lit_1', lit[1])], (32, 48), 'floor pickup / reed torch state', 180)


def seal():
    first, _ = fitted(crop_paint('dawn_seal_pedestal'), (64, 64), 57, 61)
    second = first.copy()
    # Same outline and registration; only inner-disc palette steps change.
    brighter = {8: 9, 9: 10, 14: 15, 15: 16, 16: 17, 22: 23, 23: 24, 24: 25, 25: 26}
    for y in range(4, 42):
        for x in range(8, 56):
            if (x-32)**2+(y-23)**2 <= 15**2:
                ink = second.getpixel((x, y))
                if ink in brighter: second.putpixel((x, y), brighter[ink])
                dimmer = {10: 9, 26: 25, 25: 24, 17: 16}
                if first.getpixel((x, y)) in dimmer:
                    first.putpixel((x, y), dimmer[first.getpixel((x, y))])
    sizeset('dawn_seal', [('pulse_0', first), ('pulse_1', second)], (64, 64), 'Dawn Seal objective on floor pedestal', 700)


def web(size, state):
    im = canvas((size, size)); d = ImageDraw.Draw(im)
    def p(x, y): return round(x*(size-1)/63), round(y*(size-1)/63)
    def line(points, ink, width=1): d.line([p(*v) for v in points], fill=ink, width=max(1, round(width*size/64)))
    centre = (33, 29)
    anchors = [(2, 2), (20, 0), (44, 0), (63, 8), (63, 31), (63, 59), (43, 63), (17, 63), (0, 55), (0, 25)]
    burnt = state == 'burnt'
    for i, anchor in enumerate(anchors):
        if burnt:
            end = tuple(round(anchor[j]+(centre[j]-anchor[j])*(.20 if i%2 else .30)) for j in range(2))
            line([anchor, end], 3, 2)
            d.point(p(*end), fill=20 if i%2 else 22)
        else:
            line([anchor, centre], 3, 3)
            line([anchor, centre], 8, 2)
            if i%2 == 0: line([anchor, centre], 9)
    if not burnt:
        for fraction in [.24, .44, .65, .85]:
            points = [tuple(round(centre[j]+(a[j]-centre[j])*fraction) for j in range(2)) for a in anchors]
            points.append(points[0])
            sagged = []
            for a, b in zip(points, points[1:]):
                middle = tuple(round(((a[j]+b[j])*.5)*.88+centre[j]*.12) for j in range(2))
                sagged.extend([a, middle])
            sagged.append(points[-1])
            line(sagged, 7, 2)
            line(sagged, 9)
        # Broad sticky silk tangles at the four corridor attachments.
        for box in [(0, 0, 8, 5), (56, 0, 63, 6), (0, 57, 6, 63), (57, 57, 63, 63)]:
            d.line([p(box[0], box[1]), p(box[2], box[3])], fill=8, width=max(1, size//22))
    if state.startswith('burning'):
        d.ellipse([p(20, 17), p(47, 45)], fill=0)
        frame = int(state[-1])
        for x, y, width, height in [(18, 30, 15, 19), (49, 42, 15, 22), (34, 55, 17, 20)]:
            flame(im, round(x*size/64), round(y*size/64), max(4, round(width*size/64)), max(5, round(height*size/64)), frame)
    return im


def webs():
    rows = []
    for depth, size in enumerate(HEIGHTS, 1):
        states = [(state, web(size, state)) for state in ['intact', 'burning_0', 'burning_1', 'burnt']]
        for state, im in states:
            export(im, f'web_{state}_d{depth}', (size//2, size), 'corridor / doorway face overlay', 120 if state.startswith('burning') else 0, depth)
        export(strip([im for _, im in states]), f'web_strip_d{depth}', (size//2, size), 'four STATE frames; only middle two animate', 0, depth).update(frame_count=4, frame_order=[state for state,_ in states], frame_size=[size,size])
        rows.append((f'Depth {depth} / {size} x {size}', states))
    contact(BASE / 'web_contact_4x.png', 'WEB / FIRE OPENS THE WAY', rows)


def grate(size, cut):
    im = canvas((size, size)); d = ImageDraw.Draw(im)
    def p(x, y): return round(x*(size-1)/63), round(y*(size-1)/63)
    def line(points, ink, width=1): d.line([p(*v) for v in points], fill=ink, width=max(1, round(width*size/64)))
    def rectangle(box, ink): d.rectangle([p(box[0], box[1]), p(box[2], box[3])], fill=ink)
    rectangle((2, 1, 9, 62), 3); rectangle((54, 1, 61, 62), 3)
    rectangle((2, 1, 61, 7), 5); rectangle((3, 59, 60, 62), 5)
    line([(3, 8), (3, 58)], 7); line([(60, 8), (60, 58)], 2)
    end = 22 if cut else 58
    for x in [16, 26, 38, 48]:
        rectangle((x-2, 8, x+2, end), 1)
        line([(x, 8), (x, end)], 5, 2)
        line([(x-1, 8), (x-1, end)], 7)
    line([(11, 17), (52, 17)], 4, 4)
    if not cut: line([(11, 48), (52, 48)], 4, 3)
    ropes = [[(8, 10), (55, 55)], [(55, 10), (8, 55)]] if not cut else [[(8, 10), (18, 26), (13, 33)], [(55, 10), (46, 24), (51, 29)], [(8, 55), (17, 49)], [(55, 55), (49, 50)]]
    for points in ropes:
        line(points, 18, 5); line(points, 28, 3); line(points, 9)
    if not cut:
        rectangle((27, 28, 36, 36), 18)
        line([(28, 30), (35, 34), (28, 34), (35, 30)], 29, 2)
    else:
        for point in [(13, 33), (51, 29), (17, 49), (49, 50)]: d.point(p(*point), fill=10)
    for x in [6, 57]:
        for y in [5, 57]: d.point(p(x, y), fill=8)
    return im


def skew_side(source, size, right=False):
    out = canvas(size)
    for x in range(size[0]):
        u = x/max(1, size[0]-1)
        top = size[1]*.16*u
        bottom = size[1]-1-size[1]*.16*u
        for y in range(size[1]):
            if top <= y <= bottom:
                sy = min(source.height-1, max(0, round((y-top)/(bottom-top)*(source.height-1))))
                out.putpixel((x, y), source.getpixel((round(u*(source.width-1)), sy)))
    return ImageOps.mirror(out) if right else out


def cords():
    rows, side_rows = [], []
    for depth, size in enumerate(HEIGHTS, 1):
        frames = []
        side_size = (round(32*size/64), round(48*size/64))
        sides = []
        for cut, state in [(False, 'intact'), (True, 'cut')]:
            im = grate(size, cut)
            export(im, f'cord_grate_{state}_d{depth}', (size//2, size), 'EDGE cord on a front-facing opening', depth=depth)
            frames.append((state, im))
            for side in ['left', 'right']:
                skewed = skew_side(im, side_size, side == 'right')
                anchor = (side_size[0]//2 if side == 'left' else side_size[0]-1-side_size[0]//2, side_size[1]//2)
                export(skewed, f'cord_grate_{side}_{state}_d{depth}', anchor, 'wall-centre anchor / side opening EDGE cord', depth=depth)
                if side == 'left': sides.append((state, skewed))
        export(strip([im for _, im in frames]), f'cord_grate_strip_d{depth}', (size//2, size), 'intact / cut state strip', depth=depth).update(frame_count=2, frame_order=[state for state,_ in frames], frame_size=[size,size])
        rows.append((f'Depth {depth} / {size} x {size}', frames))
        side_rows.append((f'Depth {depth} / side wall', sides))
    contact(BASE / 'cord_grate_contact_4x.png', 'EDGE / THE CUT CORD', rows)
    contact(BASE / 'cord_side_contact_4x.png', 'EDGE / SIDE WALL OPTION', side_rows)


def panels():
    paths = [ [(21, 35), (43, 35)], [(24, 35), (24, 29), (27, 25), (32, 23), (37, 25), (40, 29), (40, 35)],
              [(32, 16), (32, 20)], [(21, 20), (25, 23)], [(43, 20), (39, 23)], [(16, 29), (20, 29)], [(44, 29), (48, 29)],
              [(28, 39), (36, 39)], [(32, 26), (32, 32)] ]
    rows = []
    for floor in ['f1', 'f2']:
        base = reduce(Image.open(SOURCES / f'panel_{floor}_base.png'))
        assert base.size == (64, 64)
        states = []
        for revealed, state in [(False, 'plain'), (True, 'revealed')]:
            im = base.copy(); d = ImageDraw.Draw(im)
            for path in paths:
                d.line(path, fill=11 if revealed else 2, width=3 if revealed else 2)
                d.line([(x+1, y+1) for x, y in path], fill=14 if revealed else 5)
                if revealed: d.line(path, fill=17)
            if revealed:
                d.line((25, 35, 39, 35), fill=25)
                d.line((29, 26, 34, 26), fill=9)
            export(im, f'panel_{floor}_{state}_64', (32, 64), 'opaque 64x64 wall UV variant; not a floor prop')
            states.append((state, im))
            # Same glyph as an overlay for arbitrary future wall materials.
            overlay = canvas((64, 64)); od = ImageDraw.Draw(overlay)
            for path in paths: od.line(path, fill=17 if revealed else 4)
            if floor == 'f1': export(overlay, f'panel_sigil_{state}_64', (32, 64), 'transparent wall-face overlay')
        # UV border must remain byte-identical to the frozen matching wall.
        for _, im in states:
            assert im.crop((0, 0, 64, 2)).tobytes() == base.crop((0, 0, 64, 2)).tobytes()
            assert im.crop((0, 62, 64, 64)).tobytes() == base.crop((0, 62, 64, 64)).tobytes()
        rows.append((f'{floor} / 64 x 64 wall UV', states))
    contact(BASE / 'panel_contact_4x.png', 'GLOW / THE SCORED DAWN', rows)


def icons():
    entries = []
    for lit, state in [(False, 'unlit'), (True, 'lit')]:
        im = canvas((16, 16)); d = ImageDraw.Draw(im)
        d.line((5, 14, 10, 5), fill=18, width=4)
        d.line((5, 14, 10, 5), fill=28, width=2)
        d.line((6, 13, 10, 6), fill=9)
        d.polygon([(7, 4), (9, 2), (12, 3), (12, 7), (9, 9), (7, 7)], fill=8)
        d.line((8, 4, 8, 7), fill=10); d.line((10, 3, 10, 7), fill=29)
        d.line((7, 7, 11, 9), fill=18, width=2)
        d.line((7, 8, 10, 10), fill=24)
        if lit: flame(im, 10, 7, 9, 7, 0)
        export(im, f'reed_torch_icon_{state}_16', (8, 8), '16x16 inventory icon; centred; no animation')
        entries.append((f'torch {state}', im))
    im = canvas((16, 16)); d = ImageDraw.Draw(im)
    d.ellipse((1, 1, 14, 14), fill=18)
    d.ellipse((2, 1, 13, 13), fill=24)
    d.ellipse((3, 2, 12, 12), fill=26)
    d.ellipse((4, 3, 11, 11), fill=12)
    d.ellipse((5, 4, 10, 10), fill=16)
    d.ellipse((6, 5, 9, 9), fill=10)
    d.line((6, 8, 9, 8), fill=24)
    for xy in [(7, 1), (2, 6), (13, 7), (8, 13), (3, 3), (11, 3), (3, 11), (11, 11)]: d.point(xy, fill=10)
    d.point((5, 2), fill=10)
    export(im, 'dawn_seal_icon_16', (8, 8), '16x16 essential belt icon; no pedestal')
    entries.append(('Dawn Seal', im))
    contact(BASE / 'icons_contact_4x.png', 'M3C / NATIVE 16 PX ICONS', [('Native VETKA-scale possessions', entries)])


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--native-only', action='store_true')
    args = parser.parse_args()
    webs(); cords(); panels(); icons()
    if not args.native_only: brazier(); torch(); seal()
    source_hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SOURCES.glob('*.png'))}
    manifest(BASE / 'manifest.json', {'palette': 'art_src/spike/palette.gpl', 'sources': source_hashes, 'native_only': args.native_only, 'assets': ASSETS})
    print(f'M3c fixtures: {len(ASSETS)} palette-indexed runtime PNGs')


if __name__ == '__main__': main()
