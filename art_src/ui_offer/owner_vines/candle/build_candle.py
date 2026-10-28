"""Hand-placed candle extraction/flicker. --build writes this reviewed cut;
--check (the default) only checks it. Python + Pillow; never runs Godot.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[4]
BASE = Path(__file__).resolve().parent
TEMPLATES = BASE.parent/'templates'
ORIGINAL = TEMPLATES/'screen_154x342_done.png'
OVERLAY = ROOT/'assets/art/ui/owner_vines.png'
STRIP = ROOT/'assets/art/ui/owner_candle.png'
SOURCE = BASE/'source_original.png'
PATCH = TEMPLATES/'screen_154x342_no_candle.png'
ASE = TEMPLATES/'screen_154x342.ase'
BOX = (147,155,154,172)  # left, top, right exclusive, bottom exclusive
FLAME_BOX = (148,155,154,161)  # wick/collar starts at y161
CORNER = (140,148,154,176)
NEAREST = Image.Resampling.NEAREST
SOURCE_SHA = 'bb3c04c9f3b91ce77c780dcebf718fb0e9a4ef3c62a7a4b52160ac3a3269c2bd'
ASE_SHA = '24dc8a9a1391bf2a2594088ef3fca326d1488331be8b7fe70d8dc63302e8ec7f'

# Each span is inclusive. The hand mask follows the candle silhouette,
# including its dark contour. It excludes the vine tip and shared bar below.
CANDLE_SPANS = {
    155:(151,151),156:(150,152),157:(149,153),158:(149,153),
    159:(148,153),160:(148,153),161:(148,153),
    162:(147,153),163:(147,153),164:(147,153),165:(147,153),
    166:(148,153),167:(148,153),168:(148,153),169:(148,153),
    170:(148,153),171:(149,153),
}
# A one-pixel leftward draught in the upper flame; its lower attachment,
# collar, wick and entire wax body stay fixed. Values are shared GPL indices.
FLICKER_ROWS = {
    155:(150,[1]),
    156:(149,[1,21,1]),
    157:(148,[1,21,21,19,1]),
    158:(148,[1,21,25,21,21,1]),
    159:(148,[1,21,25,25,21,1]),
    160:(148,[1,21,25,25,21,1]),
}


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def blank(size,reference,ink=0):
    im = Image.new('P',size,ink); im.putpalette(reference.getpalette())
    im.info['transparency'] = 0
    return im


def png(im,path):
    path.parent.mkdir(parents=True,exist_ok=True)
    im.save(path,transparency=0,optimize=False)


def inside(p,box): return box[0] <= p[0] < box[2] and box[1] <= p[1] < box[3]


def diff(a,b):
    assert a.size == b.size
    a,b = a.convert('RGBA'),b.convert('RGBA')
    return [(x,y) for y in range(a.height) for x in range(a.width) if a.getpixel((x,y)) != b.getpixel((x,y))]


def pixels(): return {(x,y) for y,(left,right) in CANDLE_SPANS.items() for x in range(left,right+1)}


def frames(original):
    width,height = BOX[2]-BOX[0],BOX[3]-BOX[1]
    first = blank((width,height),original)
    for x,y in pixels():
        assert original.getpixel((x,y)),('Mask crossed transparency',x,y)
        first.putpixel((x-BOX[0],y-BOX[1]),original.getpixel((x,y)))
    second = first.copy()
    for y in range(FLAME_BOX[1],FLAME_BOX[3]):
        for x in range(FLAME_BOX[0],FLAME_BOX[2]): second.putpixel((x-BOX[0],y-BOX[1]),0)
    for y,(x,inks) in FLICKER_ROWS.items():
        for dx,ink in enumerate(inks): second.putpixel((x+dx-BOX[0],y-BOX[1]),ink)
    return first,second


def cut_overlay(original):
    result = original.copy()
    # Continue the existing 3px right edge using the restrained bronze ramp
    # immediately above it. Only old candle pixels are touched. At the corner,
    # continue the bar's exact five row colours from unobscured x140..147.
    bronze = (21,29,21,28,19)
    bar = {168:1,169:21,170:28,171:19}
    for x,y in pixels():
        if y >= 168: ink = bar[y]
        elif x >= 151: ink = (1,bronze[(y-155)%len(bronze)],18)[x-151]
        else: ink = 0
        result.putpixel((x,y),ink)
    return result


def composite(overlay,frame):
    # Paste only the opaque sprite silhouette; transparent cells leave the
    # restored edge visible. Exact paletted pixels, no colour conversion.
    result = overlay.copy()
    result.paste(frame,BOX[:2],frame.convert('RGBA').getchannel('A'))
    return result


def checker(size,reference,cell=4):
    result = blank(size,reference,1)
    for y in range(size[1]):
        for x in range(size[0]):
            if (x//cell+y//cell)%2: result.putpixel((x,y),2)
    return result


def paste_alpha(canvas,im,at): canvas.paste(im,at,im.convert('RGBA').getchannel('A'))


def title(im,at,label,size=16):
    d = ImageDraw.Draw(im); d.fontmode = '1'
    d.text(at,label,font=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),size),fill=9)


def sheets(original,overlay,first,second):
    crops = [original.crop(CORNER),overlay.crop(CORNER)]
    for frame in (first,second):
        corner = blank((CORNER[2]-CORNER[0],CORNER[3]-CORNER[1]),original)
        paste_alpha(corner,frame,(BOX[0]-CORNER[0],BOX[1]-CORNER[1])); crops.append(corner)
    sheet = blank((192,58),original,1)
    for n,(label,im) in enumerate(zip(('ORIG','CUT','F0','F1'),crops)):
        title(sheet,(n*48+4,2),label)
        background = checker(im.size,original,2); paste_alpha(background,im,(0,0))
        sheet.paste(background,(n*48+17,24))
    png(sheet,BASE/'corner_sheet.png')
    png(sheet.resize((sheet.width*12,sheet.height*12),NEAREST),BASE/'corner_sheet_12x.png')
    pair = blank((326,368),original,1)
    for n,frame in enumerate((first,second)):
        title(pair,(6+n*166,2),f'FRAME {n}',16)
        image = composite(overlay,frame); png(image,BASE/f'composite_{n}.png')
        background = checker(image.size,original,8); paste_alpha(background,image,(0,0))
        pair.paste(background,(6+n*166,22))
    png(pair,BASE/'full_screen_pair.png')
    png(pair.resize((pair.width*3,pair.height*3),NEAREST),BASE/'full_screen_pair_3x.png')


def build():
    assert sha(ORIGINAL) == SOURCE_SHA and sha(ASE) == ASE_SHA,'Owner source changed; inspect before rebuilding.'
    if not SOURCE.exists(): shutil.copyfile(ORIGINAL,SOURCE)
    assert sha(SOURCE) == SOURCE_SHA
    original = Image.open(SOURCE); first,second = frames(original); overlay = cut_overlay(original)
    strip = blank((first.width*2,first.height),original)
    strip.paste(first,(0,0)); strip.paste(second,(first.width,0))
    png(strip,STRIP); png(first,BASE/'frame_0.png'); png(second,BASE/'frame_1.png')
    png(overlay,OVERLAY); png(overlay,PATCH)
    sheets(original,overlay,first,second)
    layout = {'schema_version':1,'canvas':[154,342],'strip':'res://assets/art/ui/owner_candle.png',
              'strip_size':[14,17],'frames':2,'frame_size':[7,17],'offset':[147,155],
              'overlay_box_ltrb_exclusive':list(BOX),'flame_box_ltrb_exclusive':list(FLAME_BOX),
              'atlas_regions_xywh':[[0,0,7,17],[7,0,7,17]],'suggested_duration_ms':[430,270],
              'draw_order':'Draw candle-free owner_vines.png, then one candle frame at the offset, with the same existing visibility rules.',
              'filter':'nearest','alpha':'binary','source_original_sha256':SOURCE_SHA,'owner_ase_sha256':ASE_SHA,
              'extraction_spans_y_x_inclusive':CANDLE_SPANS,'flicker_rows_y_startx_indices':FLICKER_ROWS,
              'overlay_patch':'Only the original opaque candle mask. Restore 3px right rim and bottom bar beneath it; frame0 hides every changed underlay pixel.',
              'owner_working_template':'art_src/ui_offer/owner_vines/templates/screen_154x342_no_candle.png'}
    (BASE/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')


def check():
    assert sha(ORIGINAL) == sha(SOURCE) == SOURCE_SHA and sha(ASE) == ASE_SHA
    original,overlay,strip = [Image.open(p) for p in (ORIGINAL,OVERLAY,STRIP)]
    assert original.size == overlay.size == (154,342) and strip.size == (14,17)
    first,second = [strip.crop((i*7,0,(i+1)*7,17)) for i in (0,1)]
    expected0,_ = frames(original)
    assert not diff(first,expected0),'Frame0 differs from the owner candle pixels'
    assert not diff(overlay,Image.open(PATCH)),'Owner template and runtime cut disagree'
    changed_underlay = diff(original,overlay)
    assert changed_underlay and all(p in pixels() for p in changed_underlay)
    reconstructed = composite(overlay,first)
    mismatch = diff(reconstructed,original)
    assert not mismatch,('Frame0 reconstruction mismatches',mismatch)
    changes = [(x+BOX[0],y+BOX[1]) for x,y in diff(first,second)]
    assert changes and all(inside(p,FLAME_BOX) for p in changes),changes
    # The flame-only support includes its moving dark contour and transparent
    # draught cells. Every pixel at y161 and below is the fixed wick/wax.
    flame_inks = {original.getpixel(p) for p in pixels() if inside(p,FLAME_BOX)} | {0}
    assert all(second.getpixel((x,y)) in flame_inks for y in range(6) for x in range(7))
    assert first.crop((0,6,7,17)).tobytes() == second.crop((0,6,7,17)).tobytes()
    palette = []
    for line in (ROOT/'art_src/spike/palette.gpl').read_text().splitlines():
        parts = line.split()
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]): palette.append(tuple(map(int,parts[:3])))
    assert len(palette) == 32 and original.getpalette() == [c for rgb in palette for c in rgb]
    allowed = set(palette[1:])
    paths = [OVERLAY,STRIP,PATCH]+list(BASE.glob('*.png'))
    for path in paths:
        im = Image.open(path); assert im.mode == 'P' and im.getpalette() == original.getpalette(),path
        assert set(im.convert('RGBA').getchannel('A').getdata()) <= {0,255},path
        assert {p[:3] for p in im.convert('RGBA').getdata() if p[3]} <= allowed,path
    for stem,scale in (('corner_sheet',12),('full_screen_pair',3)):
        a,b = [Image.open(BASE/(s+'.png')) for s in (stem,f'{stem}_{scale}x')]
        assert b.size == (a.width*scale,a.height*scale) and a.resize(b.size,NEAREST).tobytes() == b.tobytes()
    assert not diff(Image.open(BASE/'composite_0.png'),original)
    assert not diff(Image.open(BASE/'composite_1.png'),composite(overlay,second))
    # Tight union bounds: neither frame can be made smaller without clipping.
    bounds = first.convert('RGBA').getchannel('A').getbbox(),second.convert('RGBA').getchannel('A').getbbox()
    assert (min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds)) == (0,0,7,17)
    result = {'frame0_exact_reconstruction':True,'mismatching_pixels':mismatch,'flame_box_ltrb_exclusive':list(FLAME_BOX),
              'strip_frame_size':[7,17],'overlay_offset':[147,155],'frame_diff_count':len(changes),'frame_diff_coordinates':changes,
              'patched_underlay_pixel_count':len(changed_underlay),'patched_underlay_coordinates':changed_underlay,
              'wick_and_wax_identical':True,'owner_done_and_ase_unchanged':True,'palette_and_binary_alpha':True,
              'exact_nearest_sheets':True,'godot_runs':0,
              'hashes':{p.relative_to(ROOT).as_posix():sha(p) for p in sorted(set(paths))}}
    (BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ('hashes','patched_underlay_coordinates','frame_diff_coordinates')},indent=2))


if __name__ == '__main__':
    if '--build' in sys.argv: build()
    check()
