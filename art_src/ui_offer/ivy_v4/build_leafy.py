"""Leafy v4 offer, drawn at native resolution. No Godot, models or network."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'env'))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ivy_v3'))
import hashlib
import json
import shutil
from PIL import Image, ImageDraw
from pipeline import ROOT, RGB, NEAREST, indexed, save, label, manifest
from build_ivy import stamp_button

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/ui_offer'
OLD = BASE.parent / 'ivy_v3'
COMPASS_ORIGIN = (80, 291)
TRANSPOSE = Image.Transpose


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture():
    (BASE / 'sources').mkdir(parents=True, exist_ok=True)
    for source, name in [(OLD/'sources/m3e_entry.png', 'entry.png'),
                         (OLD/'sources/torn_map.png', 'map.png')]:
        if not (BASE/'sources'/name).exists(): shutil.copyfile(source, BASE/'sources'/name)
    receipt = BASE / 'preserved_hashes.json'
    if not receipt.exists():
        paths = [p for group in ('env', 'icons', 'portrait', 'screens', 'ui_offer', 'props')
                 for p in (ROOT/'assets/art'/group).glob('*.png')]
        paths += [BASE.parent/p for p in ('vine_on_main_view.png', 'icons_on_buttons.png')]
        # Preserve the whole accepted v3 source pack as well as its runtime art.
        paths += [p for p in OLD.rglob('*') if p.is_file()]
        receipt.write_text(json.dumps({p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(paths)}, indent=2)+'\n')


def composite(canvas, im, xy=(0, 0)):
    if canvas.mode == 'RGBA': canvas.alpha_composite(im.convert('RGBA'), xy)
    else: canvas.paste(im, xy, im.convert('RGBA').getchannel('A'))


def rect(mask, box, ink=255):
    x, y, w, h = box
    ImageDraw.Draw(mask).rectangle((x, y, x+w-1, y+h-1), fill=ink)


def touch_interiors():
    boxes = [(1, 0, 51, 18), (98, 0, 22, 18), (121, 0, 32, 18),
             (3, 210, 32, 32), (43, 211, 24, 32), (71, 211, 24, 32),
             (101, 211, 22, 22), (127, 211, 22, 22), (85, 294, 66, 44)]
    boxes += [(1+i*19, 246, 19, 22) for i in range(8)]
    boxes += [(2+i*50, 269, 48, 22) for i in range(3)]
    boxes += [(3+i%3*26, 293+i//3*24, 24, 22) for i in range(6)]
    return [(x+3, y+3, w-6, h-6) for x, y, w, h in boxes]


PROTECTED = touch_interiors() + [
    (53, 0, 44, 18), (8, 26, 138, 140), (4, 177, 146, 28),
    (3, 210, 32, 35), (43, 211, 52, 32), (101, 211, 48, 31),
    (96, 211, 5, 31), (3, 249, 148, 16),
    (108, 130, 43, 41),  # M3e held hand/blade at the near-right view edge.
    (81, 299, 3, 13), (151, 299, 3, 13),  # Optional v3 torch bodies/flames.
]
MAP_PROTECTED = [(12, 11, 120, 15), (16, 28, 112, 240), (8, 272, 128, 25)]


def leaf(size=5, turn=0):
    """Pointed leaf, asymmetrical shoulder and lit vein; 3x5 or 5x5 pixels."""
    if size == 5:
        im = indexed((5, 5)); d = ImageDraw.Draw(im)
        d.polygon([(0, 4), (0, 2), (1, 1), (3, 0), (4, 0), (4, 2), (3, 3), (1, 4)], fill=11)
        d.polygon([(1, 3), (1, 2), (2, 1), (3, 1), (3, 2), (2, 3)], fill=6)
        d.line((1, 3, 3, 1), fill=16)
        d.point((1, 2), fill=17); d.point((3, 0), fill=17)
        d.point((2, 1), fill=8)
    else:
        im = indexed((3, 5))
        for y, row in enumerate(('..s', '.hs', 'hms', 'vs.', 's..')):
            for x, c in enumerate(row):
                if c != '.': im.putpixel((x, y), {'s': 11, 'h': 17, 'm': 6, 'v': 16}[c])
    if turn: im = im.transpose({90: TRANSPOSE.ROTATE_90, 180: TRANSPOSE.ROTATE_180, 270: TRANSPOSE.ROTATE_270}[turn])
    return im


def stem(im, points, lit=False):
    """Dark silhouette, warm woody strand, and sparse sage catching lamp light."""
    d = ImageDraw.Draw(im)
    d.line(points, fill=1, width=3)
    d.line(points, fill=27, width=2)
    d.line(points, fill=6 if lit else 13, width=1)
    for i, p in enumerate(points):
        if i % 3 == 1: d.point(p, fill=16 if lit else 14)


def leaves(im, entries):
    for x, y, size, turn in entries: composite(im, leaf(size, turn), (x, y))


def clipped(im, allowed):
    result = indexed(im.size); result.paste(im, (0, 0), allowed)
    return result


def game_layer():
    allowed = Image.new('L', (154, 342))
    bands = [(0, 18, 154, 8), (0, 26, 8, 140), (146, 26, 8, 140),
             (0, 166, 154, 11), (0, 177, 4, 30), (150, 177, 4, 30),
             (0, 207, 154, 3), (0, 210, 3, 35), (35, 210, 8, 35),
             (150, 210, 4, 35), (0, 243, 154, 6), (0, 265, 154, 7),
             (0, 288, 154, 8), (0, 296, 3, 43), (0, 339, 80, 3)]
    for band in bands: rect(allowed, band)
    for box in PROTECTED+[(80, 291, 74, 51)]: rect(allowed, box, 0)
    underpasses = [(1, 38, 2, 2), (2, 111, 2, 2), (151, 83, 2, 2),
                   (40, 171, 2, 2), (73, 171, 2, 2), (24, 267, 2, 2)]
    for box in underpasses: rect(allowed, box, 0)
    im = indexed((154, 342))
    paths = [
        [(1, 40), (4, 31), (2, 24), (7, 21), (14, 19), (23, 22), (32, 20), (43, 20)],
        [(112, 20), (124, 22), (132, 19), (145, 21), (151, 26), (148, 34), (152, 43)],
        [(2, 35), (2, 45), (5, 51), (3, 59), (1, 65), (4, 72), (2, 81), (5, 87), (2, 97)],
        [(151, 44), (148, 52), (152, 61), (150, 71), (148, 79), (151, 88), (148, 95), (152, 106)],
        [(2, 108), (4, 118), (2, 127), (5, 134), (1, 145), (4, 154), (2, 164), (7, 171)],
        [(152, 114), (148, 121), (151, 131), (152, 144), (152, 161), (151, 171)],
        [(1, 168), (8, 172), (17, 169), (26, 172), (36, 170), (47, 172), (57, 169), (67, 172), (78, 170), (88, 172), (99, 170)],
        [(1, 176), (2, 184), (1, 194), (3, 204)],
        [(152, 177), (151, 187), (152, 195), (151, 207)],
        [(1, 212), (1, 227), (2, 239)],
        [(37, 211), (40, 220), (37, 229), (40, 239), (37, 246), (47, 246), (56, 245)],
        [(111, 246), (124, 244), (135, 246), (152, 245), (152, 231), (152, 216)],
        [(2, 267), (12, 269), (23, 267), (35, 270), (44, 268)],
        [(95, 268), (105, 266), (115, 269), (126, 267), (140, 269), (151, 267)],
        [(1, 293), (8, 292), (19, 294), (29, 291), (39, 294), (51, 292), (61, 294), (74, 292)],
        [(1, 298), (1, 316), (1, 338), (8, 340), (22, 340)],
        [(48, 340), (61, 340), (70, 340), (78, 338)],
    ]
    for i, points in enumerate(paths): stem(im, points, i % 3 == 0)
    # Coils are drawn as clear little loops, not a repeating zigzag pattern.
    for points in [[(3, 49), (6, 48), (6, 52), (3, 53), (2, 51), (4, 50)],
                   [(149, 91), (146, 90), (146, 94), (149, 96), (151, 94), (149, 93)],
                   [(55, 170), (57, 167), (61, 167), (62, 171), (59, 173), (57, 171)],
                   [(37, 225), (41, 224), (41, 228), (38, 229), (37, 227)]]:
        stem(im, points, True)
    entries = [(6, 20, 5, 0), (14, 18, 5, 180), (29, 19, 5, 90),
               (126, 19, 5, 0), (143, 21, 5, 180), (148, 27, 5, 270),
               (1, 44, 5, 0), (2, 51, 5, 180), (0, 81, 5, 90), (2, 88, 5, 270),
               (148, 50, 5, 0), (147, 57, 5, 180), (146, 94, 5, 90), (149, 101, 5, 270),
               (2, 125, 5, 0), (0, 133, 5, 180), (1, 156, 5, 90),
               (5, 168, 5, 0), (13, 170, 5, 180), (23, 167, 5, 90),
               (53, 167, 5, 0), (62, 170, 5, 180), (89, 168, 5, 270), (96, 167, 5, 0),
               (0, 185, 3, 0), (151, 192, 3, 180), (36, 216, 5, 90), (37, 233, 5, 270),
               (47, 244, 5, 0), (120, 244, 5, 180), (138, 243, 5, 90),
               (9, 266, 5, 0), (32, 266, 5, 180), (103, 266, 5, 90), (126, 266, 5, 270),
               (8, 290, 5, 0), (30, 290, 5, 180), (54, 290, 5, 90), (68, 291, 5, 270)]
    leaves(im, entries)
    return clipped(im, allowed), allowed, entries, underpasses


def compass_layer():
    # Work in screen coordinates; crop after masking so external curls can
    # straddle the old housing without touching its interior or the dial.
    allowed = Image.new('L', (154, 342)); rect(allowed, (80, 291, 74, 51))
    for box in PROTECTED+[(114, 335, 9, 7)]: rect(allowed, box, 0)
    im = indexed((154, 342))
    paths = [
        [(82, 298), (85, 293), (91, 295), (97, 292), (107, 295)],
        [(130, 294), (137, 292), (144, 295), (150, 293), (152, 299)],
        [(86, 311), (83, 315), (86, 323), (82, 329), (84, 336), (91, 338), (99, 335), (110, 339)],
        [(151, 313), (148, 319), (152, 326), (149, 335), (141, 339), (134, 336), (126, 338)],
        [(84, 317), (81, 316), (81, 321), (84, 322), (86, 320), (84, 319)],
        [(143, 337), (144, 334), (147, 335), (148, 338), (145, 340), (143, 338)],
    ]
    for points in paths: stem(im, points, True)
    entries = [(86, 291, 5, 0), (96, 292, 5, 180), (131, 291, 5, 90), (142, 292, 5, 270),
               (82, 314, 5, 0), (81, 324, 5, 180), (149, 314, 5, 180), (148, 326, 5, 0),
               (89, 336, 5, 0), (101, 337, 5, 90), (128, 336, 5, 180), (140, 336, 5, 270)]
    leaves(im, entries)
    im = clipped(im, allowed)
    # Owner-approved face, copied exactly, with no new art over its pixels.
    skull = Image.open(OUT/'sleepy_skull_v3.png')
    composite(im, skull, (114, 335)); rect(allowed, (114, 335, 9, 7))
    return im.crop((80, 291, 154, 342)), allowed.crop((80, 291, 154, 342)), entries


def map_layer():
    paper = Image.open(OUT/'map_parchment_torn_v2.png')
    allowed = Image.new('L', (144, 324))
    for box in [(0, 0, 144, 11), (0, 11, 14, 301), (130, 11, 14, 301), (0, 312, 144, 12)]: rect(allowed, box)
    for box in MAP_PROTECTED: rect(allowed, box, 0)
    allowed = Image.frombytes('L', allowed.size, bytes(255 if a and p else 0 for a, p in zip(allowed.getdata(), paper.getdata())))
    im = indexed(paper.size)
    entries = []
    # Follow the ragged silhouette, with wider leaves on the empty margins.
    for side, intervals in [(0, [(22, 71), (109, 161), (212, 259)]), (1, [(40, 91), (152, 211), (302, 316)])]:
        for y0, y1 in intervals:
            points = []
            for y in range(y0, y1+1):
                xs = [x for x in range(144) if paper.getpixel((x, y))]
                if side:
                    x = max(132, xs[-1]-3)+(1 if y % 13 in (5, 6, 7) else 0)
                else:
                    x = min(11, xs[0]+3)-(1 if y % 17 in (6, 7, 8) else 0)
                points.append((x, y))
            stem(im, points, True)
            for offset, turn in ((8, 0), (17, 180), (35, 90)):
                x, y = points[min(offset, len(points)-1)]
                entries.append((x-2, y-2, 5, turn))
    for x0, x1, side in [(16, 49, 0), (99, 132, 0), (8, 41, 1), (96, 132, 1)]:
        points = []
        for x in range(x0, x1+1):
            ys = [y for y in range(324) if paper.getpixel((x, y))]
            y = max(314, ys[-1]-2) if side else min(9, ys[0]+2)
            points.append((x, y))
        stem(im, points, True)
        x, y = points[len(points)//2]; entries.append((x-2, y-2, 5, 0))
    leaves(im, entries)
    return clipped(im, allowed), allowed, entries


def pair_save(im, name):
    for suffix, image in [('native', im), ('4x', im.resize((im.width*4, im.height*4), NEAREST))]:
        path = BASE/f'{name}_{suffix}.png'
        if image.mode == 'P': save(image, path)
        else: image.save(path)


def previews(assets):
    icons = {p.stem: Image.open(p) for p in OUT.glob('verb_*.png')}
    game = Image.open(BASE/'sources/entry.png').convert('RGBA').resize((154, 342), NEAREST)
    for i, verb in enumerate(('TAKE', 'GUARD', 'WAIT')): stamp_button(game, verb, (2+i*50, 269), icons)
    composite(game, assets['ivy_game_border_v4'])
    composite(game, assets['ivy_compass_v4'], COMPASS_ORIGIN)
    composite(game, Image.open(OUT/'ivy_torches_v3_0.png'))
    pair_save(game, 'mockup_game')
    map_image = Image.open(BASE/'sources/map.png').convert('RGBA')
    stamp_button(map_image, 'CLOSE', (13, 288), icons, (128, 25))
    composite(map_image, assets['ivy_map_border_v4'], (5, 16))
    pair_save(map_image, 'mockup_map')
    pair = Image.new('RGBA', (316, 342), RGB[1]+(255,))
    pair.paste(game, (0, 0)); pair.paste(map_image, (162, 0)); pair_save(pair, 'mockup_screen')
    previous = Image.open(OLD/'mockup_game_native.png').convert('RGBA')
    compare = Image.new('RGBA', (316, 360), RGB[1]+(255,))
    d = ImageDraw.Draw(compare); d.fontmode = '1'
    # Reuse VETKA palette labels without converting the screenshot colours.
    caption = indexed((316, 18), 1); label(caption, (4, 2), 'V3 / THIN', 8); label(caption, (166, 2), 'V4 / LEAFY', 17)
    compare.paste(caption.convert('RGBA'), (0, 0)); compare.paste(previous, (0, 18)); compare.paste(game, (162, 18))
    pair_save(compare, 'comparison')
    sheet = indexed((494, 395), 1)
    label(sheet, (8, 4), 'LEAFY IVY / V4 / SAGE AND IVORY', 17)
    composite(sheet, assets['ivy_game_border_v4'], (4, 30))
    composite(sheet, assets['ivy_compass_v4'], (84, 321))
    composite(sheet, Image.open(OUT/'ivy_torches_v3_0.png'), (4, 30))
    composite(sheet, assets['ivy_map_border_v4'], (170, 30))
    composite(sheet, assets['ivy_compass_v4'], (330, 60))
    for i, turn in enumerate((0, 90, 180, 270)): composite(sheet, leaf(5, turn), (337+i*13, 140))
    composite(sheet, leaf(3), (389, 140))
    label(sheet, (330, 164), '3-5 PX LEAVES', 9)
    label(sheet, (330, 182), '1-2 PX STEM', 8)
    label(sheet, (8, 376), 'GAME / MAP / COMPASS', 8)
    pair_save(sheet, 'contact_sheet')


def main():
    capture()
    game, gm, gl, under = game_layer()
    compass, cm, cl = compass_layer()
    map_image, mm, ml = map_layer()
    assets = {'ivy_game_border_v4': game, 'ivy_compass_v4': compass, 'ivy_map_border_v4': map_image}
    masks = dict(zip(assets, (gm, cm, mm)))
    for name, im in assets.items(): save(im, OUT/f'{name}.png')
    (BASE/'masks').mkdir(exist_ok=True)
    for name, mask in masks.items(): mask.save(BASE/'masks'/f'{name}.png')
    previews(assets)
    (BASE/'layout.json').write_text(json.dumps({
        'schema_version': 1, 'viewport': [154, 342], 'rect_order': 'x,y,width,height; exclusive right/bottom',
        'assets': {'ivy_game_border_v4': {'rect': [0, 0, 154, 342]},
                   'ivy_compass_v4': {'rect': [80, 291, 74, 51], 'hit_rect_unchanged': [85, 294, 66, 44], 'skull_rect': [114, 335, 9, 7]},
                   'ivy_map_border_v4': {'rect': [5, 16, 144, 324], 'paper': 'map_parchment_torn_v2.png'}},
        'protected_screen_rects': PROTECTED, 'protected_map_local_rects': MAP_PROTECTED,
        'view_decoration': 'Overhang only at outer view edges: x<8 or x>=146, y<26 or y>=166; held blade/hand rect additionally clear.',
        'touch_rule': 'All three-pixel-inset target interiors clear; leaves straddle existing housing rims and exterior gaps only.',
        'compass_rule': 'Expanded canvas includes outside curls; housing/hit rect unchanged. No alpha in (88,297,60,38), any heading/needle/dial/tick. Original v3 skull copied exactly.',
        'nine_slice_ltrb': [0, 0, 0, 0], 'resize': False, 'filter': 'nearest', 'mouse_filter': 'IGNORE',
        'visibility': 'normal game: game+compass+optional original torches; map: map only; hide all while cards/inspection/modals/other screens',
        'draw_order': 'Over existing frame; below text, items and compass marks. Do not also draw v3 vine layers.',
        'reused_icons': 'art_src/ui_offer/ivy_v3/layout.json: same full-word fit and compact icon selection; no changes',
        'reused_torches': {'paths': ['assets/art/ui_offer/ivy_torches_v3_0.png', 'assets/art/ui_offer/ivy_torches_v3_1.png'], 'rect': [0, 0, 154, 342], 'frame_ms': [420, 580]},
        'leaf_placements': {'game': gl, 'compass_screen': cl, 'map_local': ml}, 'bronze_underpasses': under,
        'accent': 'Dusty sage: 6 olive-grey, 16/17 pale green, 8 ivory tips; 11/13 shade; 27 woody stem.',
        'status': 'Offline source-preserving composites, same camera as v3; no runtime integration or Godot captures.'}, indent=2)+'\n')
    (BASE/'art_direction.json').write_text(json.dumps({
        'method': 'Native pixel/code drawing. No model prompt: reproducible build_leafy.py is the source.',
        'owner_reference': 'art_src/ui_offer/vine_on_main_view.png',
        'brief': 'Visible pointed 3-5px leaves in uneven pairs and clusters; 1-2px woody/sage stems weave across bronze with clear underpasses; stronger loops at corners, bottom of view, and compass. Dusty sage with tiny ivory-lit veins. Preserve all controls and original sleepy skull.',
        'difference_from_v3': 'Broader exterior allowances rather than clipping every leaf to a 3px strip. New compass canvas allows real outside curls. Map leaves can enter its blank margins, with actual map/header/CLOSE areas protected.',
        'kept': 'Every old runtime PNG, full v3 source pack, owner references, verb art and exact full-word label fits.'}, indent=2)+'\n')
    manifest([OUT/f'{name}.png' for name in assets]+list(BASE.glob('contact_sheet_*.png')), BASE/'manifest.json', {
        'runtime_count': 3, 'layout': 'layout.json', 'preview_files': [
            {'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p)}
            for p in sorted(list(BASE.glob('mockup_*.png'))+list(BASE.glob('comparison_*.png')))]})
    print('Leafy ivy v4: 3 new layers, native 3-5px leaves, expanded compass exterior, same-camera comparison and 4x proofs.')


if __name__ == '__main__': main()
