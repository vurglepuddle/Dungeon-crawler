"""Offline proxy corridor proofs at the game's 148x150 column camera."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'calm_v3'))
import math
import json
from PIL import Image
from pipeline import ROOT, RGB, NEAREST, indexed, label
from selection import texture_name

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/env'
W, H, F, HORIZON, FAR = 148, 150, 74.0, 71, 3.6


def lamp(depth): return max(0.0, min(1.0, (FAR-depth)/2.7))


def tinted(ink, gain): return tuple(int(c*gain) for c in RGB[ink])+(255,)


def render(floor, scene='corridor', end='door', depth=1.0):
    textures = {p.stem: Image.open(p) for p in list(OUT.glob('painted_*.png'))+list(OUT.glob('calm_v3_*.png'))}
    view = Image.new('RGBA', (W, H), (5, 6, 9, 255))
    for y in range(H):
        plane = 'floor' if y > HORIZON else 'ceiling'
        z = F*0.5/(abs(y-HORIZON)+0.5)
        if z >= FAR: continue
        gain = lamp(z)*(0.86 if plane == 'floor' else 0.64)
        for x in range(W):
            lateral = (x+0.5-W/2)/F
            wx, wy = 10.5+lateral*z, 10.5-z
            name = texture_name('BELL42', floor, plane, math.floor(wx), math.floor(wy))
            ink = textures[name].getpixel((math.floor(wx*64)%64, math.floor(wy*64)%64))
            view.putpixel((x, y), tinted(ink, gain))
    depth_log = {}
    back = 3.5 if scene == 'corridor' else depth
    for x in range(W):
        lateral = (x+0.5-W/2)/F
        side_z = 0.5/abs(lateral) if lateral else 1e9
        z = min(side_z, back); side = side_z < back
        along = 10.5-z if side else 10.5+lateral*z
        tx = min(63, max(0, int((along-math.floor(along))*64)))
        kind = 'plain_'+str((math.floor(along)+(1 if lateral > 0 else 0))%3)
        if side and scene == 'corridor':
            # Real one-cell wall segments: centres lie at d1, d2 and d3.
            segment = 9-math.floor(along)
            table = ('drain', 'tapestry', 'crack') if lateral < 0 else ('chains', 'sconce_0', 'damp')
            if 0 <= segment < 3: kind = table[segment]
        elif not side: kind = end
        suffix = '' if kind.startswith('plain') else '_v2'
        wall = textures[f'painted_f{floor}_{kind}{suffix}']
        height = max(1, math.floor(F/z+0.5)); top = HORIZON-height//2
        gain = lamp(z)*(0.78 if side else 1.0)
        for y in range(max(0, top), min(H, top+height)):
            ty = min(63, max(0, int((y-top)*64/height)))
            view.putpixel((x, y), tinted(wall.getpixel((tx, ty)), gain))
        if side and not kind.startswith('plain'):
            key = f'{"right" if lateral > 0 else "left"}/{kind}'
            if key not in depth_log: depth_log[key] = [z, z]
            depth_log[key] = [min(z, depth_log[key][0]), max(z, depth_log[key][1])]
    return view, depth_log


def pair(image, stem):
    paths = []
    for suffix, im in [('native', image), ('4x', image.resize((image.width*4, image.height*4), NEAREST))]:
        path = BASE/f'{stem}_{suffix}.png'; im.save(path); paths.append(path)
    return paths


def build_views():
    paths = []; logs = {}
    sheet = indexed((344, 392), 1).convert('RGBA')
    caption = indexed(sheet.size); label(caption, (8, 5), 'PAINTED DRESSING / CORRIDOR', 25)
    sheet.alpha_composite(caption.convert('RGBA'))
    for floor in (1, 2):
        for i, end in enumerate(('door', 'door_open')):
            image, info = render(floor, end=end)
            name = f'mockup_corridor_f{floor}_{end}'; logs[name] = info
            paths += pair(image, name)
            xy = (8+i*164, 32+(floor-1)*176); sheet.paste(image, xy)
            caption = indexed(sheet.size); label(caption, (xy[0], xy[1]+153), f'F{floor} / '+('LOCKED' if i == 0 else 'OPEN'), 8)
            sheet.alpha_composite(caption.convert('RGBA'))
    paths += pair(sheet, 'mockup_corridor')
    # Door states at near depth, plus real alpha painted over continuing walls.
    sheet = indexed((508, 390), 1).convert('RGBA')
    caption = indexed(sheet.size); label(caption, (8, 5), 'ACTUAL LOCK / CLOSED, OPEN, LIVE ROUTE', 25)
    sheet.alpha_composite(caption.convert('RGBA'))
    for floor in (1, 2):
        for i, end in enumerate(('door', 'door_open', 'door_open_overlay')):
            if i < 2: image, _ = render(floor, scene='end', end=end, depth=1.0)
            else:
                image, _ = render(floor, scene='corridor', end='door_open')
                overlay = Image.open(OUT/f'painted_f{floor}_door_open_overlay_v2.png').convert('RGBA')
                # Match the near front-face projection, letting real deeper
                # proxy walls/floor show THROUGH the transparent passage.
                left, top, height = 37, 34, 74
                image.alpha_composite(overlay.resize((height, height), NEAREST), (left, top))
            xy = (8+i*164, 32+(floor-1)*174); sheet.paste(image, xy)
            caption = indexed(sheet.size); label(caption, (xy[0], xy[1]+152), f'F{floor} / '+('CLOSED' if i == 0 else 'OPEN' if i == 1 else 'SEE THROUGH'), 8)
            sheet.alpha_composite(caption.convert('RGBA'))
    paths += pair(sheet, 'mockup_doors')
    # All seven different paintings as front faces at d1/d2/d3, with the
    # renderer's real lamp factor. No distant duplicate art is supplied.
    sheet = indexed((508, 34+7*174), 1).convert('RGBA')
    caption = indexed(sheet.size); label(caption, (8, 5), 'F1 / DISTANCE 1, 2, 3 / REAL LAMP', 25)
    sheet.alpha_composite(caption.convert('RGBA'))
    for row, kind in enumerate(('drain', 'sconce_0', 'chains', 'tapestry', 'crack', 'damp', 'door')):
        for i, z in enumerate((1.0, 2.0, 3.0)):
            image, _ = render(1, scene='end', end=kind, depth=z)
            xy = (8+i*164, 32+row*174); sheet.paste(image, xy)
            caption = indexed(sheet.size); label(caption, (xy[0], xy[1]+152), kind.upper().replace('SCONCE_0', 'TORCH')+f' / {i+1}', 8)
            sheet.alpha_composite(caption.convert('RGBA'))
    paths += pair(sheet, 'mockup_depths')
    (BASE/'mockup_registration.json').write_text(json.dumps({'camera': {'size': [W, H], 'focal': F, 'horizon': HORIZON, 'far': FAR},
        'status': 'Offline orthographic-column material proofs in a proxy corridor; no Godot captures or live map placement.',
        'planes': 'Existing calm_v3 textures and stable BELL42 cell selector; unchanged accepted plain stone between dressings.',
        'wall_segments': {'d1': 'left drain, right chains', 'd2': 'left tapestry, right torch', 'd3': 'left fissure, right damp'},
        'observed_ray_depth_ranges': logs, 'depths': [1.0, 2.0, 3.0]}, indent=2)+'\n')
    return paths


if __name__ == '__main__': build_views()
