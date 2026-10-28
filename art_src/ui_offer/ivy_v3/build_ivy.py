"""Native pixel ivy and verb stamps. Offline, deterministic; Python + Pillow."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'env'))
import hashlib
import json
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pipeline import ROOT, RGB, TABLE, NEAREST, indexed, save, label, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/ui_offer'
FONT = ImageFont.truetype(str(ROOT / 'assets/font/vetka.ttf'), 16)
VERBS = 'TAKE GUARD WAIT HIT DROP PLACE WIELD WEAR EAT RETURN RING DOWN UP RIDE LEAVE PULL BURN CUT FEED TOSS LIGHT CANCEL PACK CLOSE UNLOCK LATCH SIDLE REVEAL DISPEL'.split()
COMPACT = {'RETURN': 6, 'CANCEL': 6, 'UNLOCK': 6, 'REVEAL': 6, 'DISPEL': 6, 'CLOSE': 6, 'WIELD': 8}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture_sources():
    """Capture once; a rebuild never refreshes evidence from a moving checkout."""
    sources = BASE / 'sources'
    sources.mkdir(parents=True, exist_ok=True)
    for src, target in [('build/m3e_shots/00_entry.png', 'm3e_entry.png'),
                        ('art_src/ui_offer/torn_v2/mockup_map_native.png', 'torn_map.png')]:
        dst = sources / target
        if not dst.exists():
            shutil.copyfile(ROOT / src, dst)
    receipt = BASE / 'preserved_hashes.json'
    if not receipt.exists():
        old = [p for group in ('env', 'icons', 'portrait', 'screens', 'ui_offer', 'props')
               for p in (ROOT / 'assets/art' / group).glob('*.png')]
        old += [ROOT / 'art_src/ui_offer' / name for name in ('vine_on_main_view.png', 'icons_on_buttons.png')]
        receipt.write_text(json.dumps({p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(old)}, indent=2) + '\n')


def outline(ink):
    mask = Image.frombytes('L', ink.size, bytes(255 if i else 0 for i in ink.getdata()))
    outer = mask.filter(ImageFilter.MaxFilter(3))
    result = indexed(ink.size)
    result.paste(1, (0, 0), outer)
    result.paste(ink, (0, 0), mask)
    return result


def icon(verb):
    im = indexed((12, 12)); d = ImageDraw.Draw(im)
    gold, light, shadow = 25, 10, 28
    if verb == 'TAKE':
        d.polygon([(4, 2), (8, 2), (7, 4), (10, 7), (9, 10), (3, 10), (2, 8), (3, 5), (5, 4)], fill=gold)
        d.line((4, 4, 8, 4), fill=shadow); d.line((3, 7, 3, 9), fill=light); d.point((7, 2), fill=light)
    elif verb == 'GUARD':
        d.polygon([(2, 2), (6, 1), (9, 2), (9, 7), (6, 10), (2, 7)], fill=gold)
        d.polygon([(4, 3), (7, 3), (7, 6), (6, 8), (4, 6)], fill=shadow)
        d.line((3, 3, 3, 6), fill=light); d.point((6, 2), fill=light)
    elif verb == 'WAIT':
        d.line((2, 1, 9, 1), fill=gold); d.line((2, 10, 9, 10), fill=gold)
        d.line([(3, 2), (3, 3), (7, 7), (8, 9)], fill=9)
        d.line([(8, 2), (8, 3), (4, 7), (3, 9)], fill=9)
        d.line((4, 9, 7, 9), fill=gold); d.point((5, 6), fill=light)
    elif verb == 'HIT':
        d.rectangle((3, 4, 9, 7), fill=gold); d.rectangle((4, 8, 8, 10), fill=shadow)
        for x, y in ((3, 3), (5, 2), (7, 2), (9, 3)):
            d.line((x, y, x, 5), fill=light)
        d.rectangle((2, 6, 4, 8), fill=gold); d.point((3, 6), fill=light)
    elif verb in ('DROP', 'DOWN', 'UP'):
        up = verb == 'UP'
        d.line((6, 2 if not up else 9, 6, 8 if not up else 3), fill=light, width=2)
        d.polygon([(3, 5), (8, 5), (6, 8)] if not up else [(3, 6), (8, 6), (6, 3)], fill=gold)
        if verb == 'DROP': d.line((2, 10, 9, 10), fill=shadow)
        else: d.line([(2, 9), (3, 9), (3, 7), (4, 7)], fill=shadow)
    elif verb == 'PLACE':
        d.polygon([(2, 7), (4, 7), (4, 8), (9, 8), (8, 10), (3, 10)], fill=gold)
        d.polygon([(6, 1), (8, 3), (6, 5), (4, 3)], fill=light)
        d.line((6, 6, 6, 7), fill=shadow)
    elif verb in ('WIELD', 'CUT'):
        d.polygon([(8, 1), (10, 1), (9, 4), (5, 8), (3, 6)], fill=9)
        d.line((5, 6, 9, 2), fill=light)
        d.line((2, 5, 6, 9), fill=gold); d.line((2, 9, 4, 7), fill=shadow, width=2)
        if verb == 'CUT': d.line((7, 9, 10, 8), fill=gold)
    elif verb == 'WEAR':
        d.polygon([(4, 2), (7, 2), (9, 3), (10, 5), (8, 6), (8, 10), (3, 10), (3, 6), (1, 5), (2, 3)], fill=gold)
        d.line((5, 3, 6, 3), fill=1); d.line((4, 5, 4, 9), fill=light); d.line((7, 6, 7, 10), fill=shadow)
    elif verb == 'EAT':
        d.ellipse((2, 3, 10, 10), fill=gold); d.rectangle((1, 6, 8, 9), fill=gold)
        d.line((3, 5, 6, 4), fill=light); d.point((8, 5), fill=light)
        d.ellipse((8, 2, 11, 5), fill=0); d.ellipse((9, 5, 12, 7), fill=0)
    elif verb == 'RETURN':
        d.line([(9, 2), (9, 7), (3, 7)], fill=light, width=2)
        d.polygon([(2, 7), (5, 4), (5, 10)], fill=gold)
    elif verb == 'RING':
        d.polygon([(5, 2), (7, 2), (8, 4), (8, 7), (9, 8), (3, 8), (4, 7), (4, 4)], fill=gold)
        d.point((6, 1), fill=light); d.line((5, 10, 7, 10), fill=light)
        d.line((1, 3, 1, 5), fill=9); d.line((10, 3, 10, 5), fill=9); d.line((5, 4, 5, 6), fill=light)
    elif verb == 'RIDE':
        d.rectangle((3, 2, 8, 7), fill=shadow); d.line((4, 3, 7, 3), fill=gold)
        d.line((2, 9, 9, 9), fill=light); d.line((5, 1, 5, 6), fill=9)
        d.line((1, 5, 1, 8), fill=gold); d.point((2, 7), fill=gold)
    elif verb == 'LEAVE':
        d.line([(4, 10), (2, 10), (2, 1), (7, 1), (7, 4)], fill=gold)
        d.line((5, 7, 9, 7), fill=light); d.polygon([(8, 5), (10, 7), (8, 9)], fill=gold)
    elif verb == 'PULL':
        d.polygon([(2, 9), (8, 9), (10, 10), (1, 10)], fill=gold)
        d.line((6, 8, 8, 3), fill=light, width=2); d.rectangle((7, 1, 9, 3), fill=gold)
        d.point((5, 9), fill=shadow)
    elif verb == 'BURN':
        d.polygon([(6, 1), (8, 4), (8, 6), (10, 4), (10, 8), (8, 10), (4, 10), (2, 8), (2, 6), (4, 3), (4, 6), (6, 4)], fill=gold)
        d.polygon([(6, 5), (7, 7), (8, 8), (7, 10), (4, 9)], fill=light)
    elif verb == 'FEED':
        d.line((4, 8, 8, 4), fill=9, width=2)
        for x, y in ((2, 7), (3, 9), (8, 2), (9, 3)): d.rectangle((x, y, x+1, y+1), fill=light)
    elif verb == 'TOSS':
        d.polygon([(1, 9), (3, 7), (5, 9), (3, 10)], fill=gold)
        for p in ((3, 5), (5, 3), (7, 3)): d.point(p, fill=light)
        d.line((9, 4, 9, 7), fill=9); d.polygon([(7, 6), (10, 6), (9, 8)], fill=gold)
    elif verb == 'LIGHT':
        d.line((5, 10, 6, 6), fill=shadow, width=2)
        d.line((4, 6, 8, 6), fill=gold)
        d.polygon([(6, 1), (8, 4), (7, 5), (4, 5), (4, 3)], fill=gold)
        d.line((6, 3, 6, 4), fill=light)
    elif verb in ('CANCEL', 'CLOSE'):
        d.line((3, 3, 8, 8), fill=9, width=2); d.line((8, 3, 3, 8), fill=gold, width=2)
        if verb == 'CLOSE': d.line([(2, 10), (2, 1), (9, 1), (9, 10)], fill=shadow)
    elif verb == 'PACK':
        d.rectangle((3, 3, 9, 10), fill=gold); d.line([(4, 2), (4, 1), (7, 1), (7, 2)], fill=9)
        d.line((4, 5, 8, 5), fill=shadow); d.rectangle((5, 6, 7, 8), fill=shadow); d.point((6, 6), fill=light)
    elif verb == 'UNLOCK':
        d.rectangle((2, 6, 8, 10), fill=gold); d.line([(4, 5), (4, 2), (7, 1), (9, 2), (9, 3)], fill=light)
        d.line((5, 8, 5, 9), fill=shadow)
    elif verb == 'LATCH':
        d.rectangle((2, 2, 9, 10), fill=shadow); d.line((3, 3, 3, 9), fill=gold)
        d.line((4, 6, 9, 6), fill=light, width=2); d.point((8, 8), fill=gold)
    elif verb == 'SIDLE':
        d.rectangle((2, 3, 3, 8), fill=gold); d.rectangle((7, 4, 8, 9), fill=9)
        d.line((3, 1, 8, 1), fill=light); d.point((7, 2), fill=light); d.point((4, 10), fill=shadow)
    elif verb == 'REVEAL':
        d.polygon([(1, 6), (4, 3), (7, 3), (10, 6), (7, 9), (4, 9)], fill=9)
        d.rectangle((5, 4, 6, 8), fill=shadow); d.point((5, 5), fill=light)
    elif verb == 'DISPEL':
        d.polygon([(6, 1), (7, 4), (10, 5), (8, 7), (9, 10), (6, 9), (3, 10), (4, 7), (1, 5), (5, 4)], fill=gold)
        d.line((5, 5, 6, 7), fill=light); d.point((6, 6), fill=1)
    else: raise ValueError(verb)
    return outline(im)


def compact_icon(verb, width):
    """Separate native drawings, never squeezed or filtered canonical icons."""
    im = indexed((width, 12)); d = ImageDraw.Draw(im)
    if verb == 'RETURN':
        d.line([(4, 2), (4, 7), (1, 7)], fill=10)
        d.line([(2, 5), (1, 7), (2, 9)], fill=25)
    elif verb in ('CANCEL', 'CLOSE'):
        d.line((1, 4, 4, 7), fill=10); d.line((4, 4, 1, 7), fill=25)
    elif verb == 'UNLOCK':
        d.rectangle((1, 6, 4, 9), fill=25); d.line([(2, 5), (2, 2), (4, 2)], fill=10)
        d.point((3, 8), fill=28)
    elif verb == 'REVEAL':
        d.polygon([(1, 5), (2, 3), (3, 3), (4, 5), (3, 8), (2, 8)], fill=9)
        d.line((2, 5, 2, 6), fill=28)
    elif verb == 'DISPEL':
        d.line((3, 2, 3, 9), fill=10); d.line((1, 5, 4, 5), fill=25)
        d.point((1, 8), fill=25)
    elif verb == 'WIELD':
        d.polygon([(4, 1), (6, 1), (5, 6), (3, 7)], fill=9)
        d.line((4, 2, 4, 5), fill=10); d.line((1, 7, 5, 7), fill=25)
        d.line((3, 8, 3, 10), fill=28)
    return outline(im)


def ring_mask(size, rect, inset=3):
    mask = Image.new('L', size); d = ImageDraw.Draw(mask)
    x, y, w, h = rect
    d.rectangle((x, y, x+w-1, y+h-1), fill=255)
    d.rectangle((x+inset, y+inset, x+w-inset-1, y+h-inset-1), fill=0)
    return mask


def vine(canvas, points, phase=0):
    """One-pixel aged stems; paired two-pixel leaves in irregular clusters."""
    d = ImageDraw.Draw(canvas)
    d.line(points, fill=11)
    for i, (x, y) in enumerate(points):
        if (i+phase) % 3 == 0:
            d.point((x, y), fill=15)
        else:
            d.point((x, y), fill=14)
        if i % 4 == phase % 4:
            dx, dy = ((1, 0) if i % 2 else (0, 1))
            d.point((x+dx, y+dy), fill=13)
            d.point((x+dx+dy, y+dy-dx), fill=15)


def wavy_horizontal(x0, x1, y, phase=0):
    offsets = (0, 0, 0, 1, 1, 0, -1, -1, 0, 0, 0, 0, 1, 0, 0, -1, 0)
    return [(x, y+offsets[(x-x0+phase) % len(offsets)]) for x in range(x0, x1+1)]


def wavy_vertical(y0, y1, x, phase=0):
    return [(x+(0, 0, 1, 1, 0, -1, -1, 0)[(y-y0+phase) % 8], y) for y in range(y0, y1+1)]


def clip(im, mask):
    result = indexed(im.size)
    result.paste(im, (0, 0), mask)
    return result


def sleepy_skull():
    # Round temples, horizontal sleepy eyes, tiny separated teeth; no brow slant.
    rows = ['..55555..', '.5888885.', '589999985', '589595985', '.5898985.', '..58885..', '...5.5...']
    colours = {'5': 1, '8': 8, '9': 10}
    im = indexed((9, 7))
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c in colours: im.putpixel((x, y), colours[c])
    return im


def build_overlays():
    masks = {}; overlays = {}
    allowed = Image.new('L', (154, 342)); a = ImageDraw.Draw(allowed)
    bands = [(0, 18, 154, 3), (0, 21, 3, 150), (151, 21, 3, 150), (0, 171, 154, 3),
             (0, 174, 3, 34), (151, 174, 3, 34), (0, 207, 154, 3),
             (0, 211, 2, 34), (151, 211, 3, 34), (37, 210, 3, 34),
             (0, 244, 154, 3), (0, 267, 154, 2),
             (0, 292, 3, 47), (80, 292, 5, 50), (0, 339, 85, 3)]
    for x, y, w, h in bands: a.rectangle((x, y, x+w-1, y+h-1), fill=255)
    a.rectangle((3, 242, 34, 244), fill=0)  # Existing portrait HP bar.
    raw = indexed((154, 342))
    for x0, x1, y, phase in ((5, 37, 19, 2), (117, 149, 19, 0), (0, 35, 172, 5), (62, 90, 172, 1),
                              (124, 153, 172, 4), (3, 23, 208, 3), (128, 153, 208, 1),
                              (3, 28, 245, 2), (56, 81, 245, 3), (115, 151, 245, 0),
                              (9, 37, 268, 1), (97, 132, 268, 5), (1, 26, 340, 0), (55, 82, 340, 4)):
        vine(raw, wavy_horizontal(x0, x1, y, phase), phase)
    for y0, y1, x, phase in ((22, 63, 1, 1), (100, 128, 1, 0), (149, 178, 1, 4),
                             (32, 78, 152, 3), (113, 144, 152, 2), (165, 195, 152, 0),
                             (183, 203, 1, 3), (214, 241, 1, 0), (218, 242, 152, 1),
                             (212, 232, 38, 3), (299, 327, 1, 2), (318, 340, 82, 4)):
        vine(raw, wavy_vertical(y0, y1, x, phase), phase)
    # Small actual coils and leaf pairs interrupt the stem rather than forming
    # a uniformly repeated zigzag. Their projection stays inside a 3px rim.
    d = ImageDraw.Draw(raw)
    for x, y in ((0, 43), (151, 61), (0, 113), (151, 177)):
        d.line([(x+1, y), (x+2, y+1), (x+2, y+3), (x, y+3), (x, y+1), (x+1, y+1)], fill=14)
        d.line((x, y+6, x+1, y+7), fill=15); d.point((x+2, y+6), fill=13)
    # Four-pixel bronze acorns/corner rosettes, entirely on the view rim.
    d = ImageDraw.Draw(raw)
    for x, y in ((0, 20), (150, 169), (0, 169)):
        d.rectangle((x, y, x+2, y+2), fill=27); d.point((x+1, y), fill=9); d.point((x+1, y+1), fill=29)
    overlays['ivy_game_border_v3'] = clip(raw, allowed); masks['ivy_game_border_v3'] = allowed
    # Housing at (85,294), original hit rect 66x44 plus a four-pixel footer.
    allowed = ring_mask((66, 48), (0, 0, 66, 44), 3)
    ImageDraw.Draw(allowed).rectangle((0, 44, 65, 47), fill=255)
    raw = indexed((66, 48))
    for x0, x1, y, phase in ((0, 19, 1, 2), (45, 65, 1, 0), (1, 22, 42, 1), (40, 64, 42, 4)):
        vine(raw, wavy_horizontal(x0, x1, y, phase), phase)
    vine(raw, wavy_vertical(3, 18, 1, 3), 3)
    vine(raw, wavy_vertical(20, 41, 64, 1), 1)
    skull = sleepy_skull(); raw.paste(skull, (29, 41), skull.convert('RGBA').getchannel('A'))
    overlays['ivy_compass_v3'] = clip(raw, allowed); masks['ivy_compass_v3'] = allowed
    overlays['sleepy_skull_v3'] = skull
    # Tiny optional torches live outside all control rectangles, in two gaps.
    torch_mask = Image.new('L', (154, 342)); td = ImageDraw.Draw(torch_mask)
    for x in (81, 151): td.rectangle((x, 299, x+2, 311), fill=255)
    for frame in range(2):
        im = indexed((154, 342)); d = ImageDraw.Draw(im)
        for x in (81, 151):
            d.line((x+1, 305, x+1, 311), fill=27); d.line((x, 305, x+2, 305), fill=25)
            d.point((x+1, 307), fill=29); d.point((x+1, 304), fill=25)
            d.line((x+frame, 301, x+1, 303), fill=24)
            d.point((x+1, 300+frame), fill=25); d.point((x+1, 303), fill=10)
        name = f'ivy_torches_v3_{frame}'; overlays[name] = im; masks[name] = torch_mask
    # The map leaf's eight-pixel margins already protect all map ink and CLOSE.
    paper = Image.open(ROOT / 'assets/art/ui_offer/map_parchment_torn_v2.png')
    allowed = Image.new('L', (144, 324), 255)
    ImageDraw.Draw(allowed).rectangle((8, 12, 135, 311), fill=0)
    # Only draw on real paper, leaving the irregular silhouette intact.
    allowed = Image.frombytes('L', allowed.size, bytes(255 if a and p else 0 for a, p in zip(allowed.getdata(), paper.getdata())))
    raw = indexed((144, 324))
    for y0, y1, side, phase in ((12, 66, 0, 2), (99, 153, 0, 0), (203, 264, 0, 3),
                                (31, 84, 1, 3), (144, 194, 1, 1), (265, 314, 1, 0)):
        points = []
        for y in range(y0, y1+1):
            opaque = [x for x in range(144) if paper.getpixel((x, y))]
            edge = opaque[-1] if side else opaque[0]
            x = max(136, edge-1) if side else min(7, edge+1)
            points.append((x, y))
        vine(raw, points, phase)
    for x0, x1, side, phase in ((14, 52, 0, 0), (98, 131, 0, 2), (6, 35, 1, 4), (91, 132, 1, 1)):
        points = []
        for x in range(x0, x1+1):
            opaque = [y for y in range(324) if paper.getpixel((x, y))]
            edge = opaque[-1] if side else opaque[0]
            y = max(312, edge-1) if side else min(11, edge+1)
            points.append((x, y))
        vine(raw, points, phase)
    overlays['ivy_map_border_v3'] = clip(raw, allowed); masks['ivy_map_border_v3'] = allowed
    return overlays, masks, bands


def composite(canvas, im, pos=(0, 0)):
    if canvas.mode == 'RGBA': canvas.alpha_composite(im.convert('RGBA'), pos)
    else: canvas.paste(im, pos, im.convert('RGBA').getchannel('A'))


def pair_save(im, stem):
    for suffix, result in [('native', im), ('4x', im.resize((im.width*4, im.height*4), NEAREST))]:
        path = BASE / f'{stem}_{suffix}.png'
        if result.mode == 'P': save(result, path)
        else: result.save(path)


def button_background(size):
    src = Image.open(ROOT / 'assets/art/chrome_32.png').convert('RGBA')
    # Same three-pixel corner/tiled middle construction as Chrome.style().
    w, h = size; result = Image.new('RGBA', size)
    for y in range(h):
        sy = y if y < 3 else (32-h+y if y >= h-3 else 3+(y-3) % 26)
        for x in range(w):
            sx = x if x < 3 else (32-w+x if x >= w-3 else 3+(x-3) % 26)
            result.putpixel((x, y), src.getpixel((sx, sy)))
    return result


def layout(verb, width=48, height=22, card=False):
    word = int(FONT.getlength(verb))
    iw = COMPACT.get(verb, 12) if word+14 > width-4 else 12
    assert iw+2+word <= width-4, (verb, width)
    x = (width-iw-2-word)//2
    glyph_y = (height-7)//2
    return {'verb': verb, 'button_size': [width, height], 'font': 'VETKA 16',
            'icon_path': f'assets/art/ui_offer/verb_{verb.lower()}'+(f'_compact{iw}' if iw != 12 else '')+'.png',
            'icon_size': [iw, 12], 'icon_origin': [x, (height-12)//2],
            'text_origin_pillow': [x+iw+2, glyph_y-2],
            'text_origin_godot_top': [x+iw+2, glyph_y-2],
            'text_width': word, 'group_width': iw+2+word,
            'gap_px': 2, 'minimum_side_padding': x}


def stamp_button(screen, verb, pos, icons, size=(48, 22)):
    entry = layout(verb, *size); x, y = pos
    screen.paste(button_background(size), pos)
    image = icons[Path(entry['icon_path']).stem]
    composite(screen, image, (x+entry['icon_origin'][0], y+entry['icon_origin'][1]))
    d = ImageDraw.Draw(screen); d.fontmode = '1'
    d.text((x+entry['text_origin_pillow'][0], y+entry['text_origin_pillow'][1]), verb, font=FONT, fill=RGB[9]+(255,))


def previews(icons, overlays):
    sheet = indexed((376, 34+6*48), 1)
    label(sheet, (8, 5), 'IVY / BRONZE VERB STAMPS', 25)
    for i, verb in enumerate(VERBS):
        x, y = 8+(i % 5)*74, 31+(i//5)*48
        composite(sheet, icons[f'verb_{verb.lower()}'], (x+3, y+1))
        if verb in COMPACT:
            composite(sheet, icons[f'verb_{verb.lower()}_compact{COMPACT[verb]}'], (x+25, y+1))
        label(sheet, (x, y+19), verb, 9)
    pair_save(sheet, 'contact_sheet')
    sheet = indexed((326, 32+10*30), 1)
    label(sheet, (7, 4), 'ALL VERBS / VETKA 16 / 48 x 22', 25)
    for i, verb in enumerate(VERBS):
        x, y = 6+(i % 3)*106, 29+(i//3)*30
        button = Image.new('RGBA', (48, 22)); stamp_button(button, verb, (0, 0), icons)
        composite(sheet, __import__('pipeline').reduce(button, button.size), (x, y))
        label(sheet, (x+53, y+5), str(layout(verb)['group_width']), 8)
    pair_save(sheet, 'fit_sheet')
    # All four border layers, shown on contrasting slate to expose alpha.
    sheet = indexed((494, 389), 1)
    label(sheet, (8, 4), 'DEAD IVY / NATIVE BORDER PIECES', 25)
    composite(sheet, overlays['ivy_game_border_v3'], (4, 30))
    composite(sheet, overlays['ivy_torches_v3_0'], (4, 30))
    composite(sheet, overlays['ivy_compass_v3'], (89, 324))
    composite(sheet, overlays['ivy_map_border_v3'], (170, 30))
    composite(sheet, overlays['sleepy_skull_v3'], (338, 52))
    composite(sheet, overlays['ivy_compass_v3'], (331, 76))
    label(sheet, (331, 136), 'SLEEPY KEEPER', 9)
    label(sheet, (8, 373), 'GAME / MAP / COMPASS', 8)
    pair_save(sheet, 'ornament_sheet')
    source = Image.open(BASE / 'sources/m3e_entry.png').convert('RGBA').resize((154, 342), NEAREST)
    game = source.copy()
    for i, verb in enumerate(('TAKE', 'GUARD', 'WAIT')): stamp_button(game, verb, (2+i*50, 269), icons)
    composite(game, overlays['ivy_game_border_v3'])
    composite(game, overlays['ivy_compass_v3'], (85, 294))
    composite(game, overlays['ivy_torches_v3_0'])
    pair_save(game, 'mockup_game')
    map_source = Image.open(BASE / 'sources/torn_map.png').convert('RGBA')
    map_screen = map_source.copy()
    composite(map_screen, overlays['ivy_map_border_v3'], (5, 16))
    # Existing 128x25 CLOSE target gets the same measured icon+word layout.
    stamp_button(map_screen, 'CLOSE', (13, 288), icons, (128, 25))
    pair_save(map_screen, 'mockup_map')
    pair = Image.new('RGBA', (316, 342), RGB[1]+(255,))
    pair.paste(game, (0, 0)); pair.paste(map_screen, (162, 0))
    pair_save(pair, 'mockup_screen')
    # Alternate icon row proves the long labels at their actual gameplay pitch.
    long_screen = game.copy()
    for i, verb in enumerate(('RETURN', 'REVEAL', 'DISPEL')): stamp_button(long_screen, verb, (2+i*50, 269), icons)
    pair_save(long_screen, 'mockup_long_verbs')


def main():
    BASE.mkdir(parents=True, exist_ok=True); capture_sources()
    icons = {f'verb_{v.lower()}': icon(v) for v in VERBS}
    icons.update({f'verb_{v.lower()}_compact{w}': compact_icon(v, w) for v, w in COMPACT.items()})
    overlays, masks, bands = build_overlays()
    assets = dict(icons, **overlays)
    for name, im in assets.items(): save(im, OUT / f'{name}.png')
    for name, mask in masks.items():
        folder = BASE / 'masks'; folder.mkdir(exist_ok=True)
        mask.save(folder / f'{name}.png')
    previews(icons, overlays)
    registrations = {
        'schema_version': 1, 'viewport': [154, 342], 'coordinate_rule': 'integer x,y,width,height; rect right/bottom exclusive',
        'accent': 'dead ivy: 11 shadow, 13/14 leaf, sparse 15 highlights; ivory skull; bronze torch',
        'camera_clear_rect': [53, 0, 44, 18], 'world_clear_rect': [3, 21, 148, 150],
        'game_allowed_bands': bands, 'housing_rim_px': 3,
        'assets': {
            'ivy_game_border_v3': {'rect': [0, 0, 154, 342], 'visible': 'normal game only; hide for map/cards/modals'},
            'ivy_compass_v3': {'rect': [85, 294, 66, 48], 'hit_rect_unchanged': [85, 294, 66, 44], 'skull_rect': [114, 335, 9, 7]},
            'ivy_map_border_v3': {'rect': [5, 16, 144, 324], 'paper': 'map_parchment_torn_v2.png', 'content_safe_local': [8, 12, 128, 300]},
            'ivy_torches_v3_0': {'rect': [0, 0, 154, 342], 'sequence': ['ivy_torches_v3_0', 'ivy_torches_v3_1'], 'frame_ms': [420, 580]},
            'ivy_torches_v3_1': {'rect': [0, 0, 154, 342]},
            'sleepy_skull_v3': {'size': [9, 7], 'anchor': [4, 7], 'included_in': 'ivy_compass_v3'},
        },
        'nine_slice_ltrb': [0, 0, 0, 0], 'resize': False, 'filter': 'nearest', 'mouse_filter': 'IGNORE',
        'draw_order': 'over current frame/housing, below glyphs, items, needle and dial marks; same normal state visibility as controls',
        'buttons': [layout(v) for v in VERBS],
        'item_card_buttons_42x20': [layout(v, 42, 20) for v in ('WIELD', 'WEAR', 'EAT', 'DROP', 'CLOSE', 'PACK', 'RING', 'TOSS')],
        'button_24px_height': [layout(v, 48, 24) for v in VERBS],
        'text_baseline_rule': 'Godot draw_string baseline = text_origin_godot_top + Vector2(0,FONT.get_ascent(16)); Pillow source uses font bbox y=2..9.',
        'card_rule': 'hide game/compass/torch overlays while inspecting: A docks verbs at y179 then; map uses map layer only',
        'mockup_status': 'Offline M3e game and earlier torn-map composites; current control rects, original dungeon/portrait/pack pixels, illustrative long-label row.'}
    (BASE / 'layout.json').write_text(json.dumps(registrations, indent=2) + '\n')
    (BASE / 'art_direction.json').write_text(json.dumps({
        'method': 'Original native pixel drawings, code-only: no generative prompt or model used for this exact-mask batch.',
        'references': ['art_src/ui_offer/vine_on_main_view.png', 'art_src/ui_offer/icons_on_buttons.png'],
        'brief': 'Thin dead-ivy coils on bronze rims, quiet clear stretches, sparse paired leaves. Rounded sleepy skull. No crest across the camera. Tiny gap-mounted torches. Ivory/bronze verb pictograms with a one-pixel dark outline.',
        'preserve': 'Owner reference bytes, all preceding runtime PNGs, VETKA at 16px, original hit rects and full verb words.',
        'canonical_icons': '12x12; seven separately drawn narrow siblings handle measured long-label/card fits.',
        'scripts': ['build_ivy.py', 'verify_ivy.py']}, indent=2) + '\n')
    manifest([OUT / f'{name}.png' for name in assets] + list(BASE.glob('*sheet_*.png')), BASE / 'manifest.json', {
        'runtime_count': len(assets), 'layout': 'layout.json', 'method': 'native pixel/code drawings, no antialiasing or resampling',
        'preview_files': [{'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p)} for p in sorted(BASE.glob('mockup_*.png'))]})
    print(f'Ivy offer built: {len(assets)} new runtime PNGs; {len(VERBS)} verbs; full-word VETKA16 fit records; native and 4x previews.')


if __name__ == '__main__': main()
