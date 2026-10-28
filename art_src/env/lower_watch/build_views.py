"""Same-camera corridor/room comparisons across all three floor families."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import json
import math
from PIL import Image
from pipeline import ROOT, RGB, NEAREST, indexed, label
from selection import texture_name

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/env'
W, H, F, HORIZON, FAR = 148,150,74.0,71,3.6
TEXTURES = {}


def tex(name):
    if name not in TEXTURES: TEXTURES[name] = Image.open(OUT/f'{name}.png')
    return TEXTURES[name]


def lamp(z): return max(0.0,min(1.0,(FAR-z)/2.7))


def tint(index,gain): return tuple(int(c*gain) for c in RGB[index])+(255,)


def render(floor,scene,back=3.5,step=0,with_props=True):
    image = Image.new('RGBA',(W,H),(5,6,9,255))
    width = 0.5 if scene == 'corridor' else 1.5
    origin_y = 10.5-step
    for y in range(H):
        plane = 'floor' if y > HORIZON else 'ceiling'
        z = F*0.5/(abs(y-HORIZON)+0.5)
        if z >= FAR: continue
        gain = lamp(z)*(0.86 if plane == 'floor' else 0.64)
        for x in range(W):
            lateral = (x+0.5-W/2)/F
            wx, wy = 10.5+lateral*z,origin_y-z
            name = texture_name('BELL42',floor,plane,math.floor(wx),math.floor(wy))
            if scene == 'room' and plane == 'floor' and (math.floor(wx),math.floor(wy)) == (10,9):
                name = ('calm_v3_f3_' if floor == 3 else 'calm_v3_')+'room_floor_compass'
            image.putpixel((x,y),tint(tex(name).getpixel((math.floor(wx*64)%64,math.floor(wy*64)%64)),gain))
    ray_depths = []; seen = set()
    for x in range(W):
        lateral = (x+0.5-W/2)/F
        side_z = width/abs(lateral) if lateral else 1e9
        z = min(side_z,back); side = side_z < back
        along = origin_y-z if side else 10.5+lateral*z
        tx = min(63,max(0,int((along-math.floor(along))*64)))
        kind = 'plain_'+str((math.floor(along)+(1 if lateral > 0 else 0))%3)
        if side:
            segment = 9-math.floor(along)
            kinds = ('drain_v2','tapestry_v2','crack_v2') if lateral < 0 else ('chains_v2','sconce_0_v2','damp_v2')
            if 0 <= segment < 3: kind = kinds[segment]; seen.add(kind)
        elif scene == 'corridor': kind = 'door_v2'
        else:
            cell = math.floor(along)
            kind = 'tapestry_v2' if cell == 10 else 'arch_blocked' if cell == 9 else 'door_barricaded' if cell == 11 else kind
        wall = tex(f'painted_f{floor}_{kind}')
        height = max(1,math.floor(F/z+0.5)); top = HORIZON-height//2
        gain = lamp(z)*(0.78 if side else 1.0)
        for y in range(max(0,top),min(H,top+height)):
            ty = min(63,max(0,int((y-top)*64/height)))
            image.putpixel((x,y),tint(wall.getpixel((tx,ty)),gain))
        ray_depths.append(z)
    registrations = []
    if with_props:
        props = [('pots',-.55,1.0),('rubble',.7,2.0),('crate',-.1,3.0)] if scene == 'room' else [('candles',-.25,1.0),('bone_heap',.25,2.0),('pots',-.15,3.0)]
        for kind, lateral, world_z in reversed(props):
            z = world_z-step
            if not 0.45 <= z < back: continue
            depth = 1 if z < 1.5 else 2 if z < 2.5 else 3
            sprite = Image.open(ROOT/f'assets/art/props/f{floor}_{kind}_d{depth}.png').convert('RGBA')
            cx = int(W/2+lateral*F/z); foot = int(HORIZON+F*0.5/z)
            left, top = cx-sprite.width//2,foot-sprite.height
            gain = lamp(z)
            for yy in range(sprite.height):
                for xx in range(sprite.width):
                    x,y = left+xx,top+yy
                    if not (0 <= x < W and 0 <= y < H) or z >= ray_depths[x]: continue
                    r,g,b,a = sprite.getpixel((xx,yy))
                    if a: image.putpixel((x,y),(int(r*gain),int(g*gain),int(b*gain),255))
            registrations.append({'kind':kind,'depth':z,'band':depth,'canvas':list(sprite.size),'anchor':[cx,foot]})
    return image,{'floor':floor,'scene':scene,'back_depth':back,'step':step,'props':registrations,'visible_dressing':sorted(seen)}


def pair(image,stem):
    paths = []
    for suffix,im in [('native',image),('4x',image.resize((image.width*4,image.height*4),NEAREST))]:
        p = BASE/f'{stem}_{suffix}.png'; im.save(p); paths.append(p)
    return paths


def caption(canvas,at,text):
    overlay = indexed(canvas.size); label(overlay,at,text,8); canvas.alpha_composite(overlay.convert('RGBA'))


def build_views():
    TEXTURES.clear()
    paths, registrations = [],[]
    overview = indexed((508,392),1).convert('RGBA')
    caption(overview,(8,5),'F1 / ABBEY     F2 / DAMP     F3 / WATCH')
    for floor in (1,2,3):
        for row,scene in enumerate(('corridor','room')):
            view,info = render(floor,scene); registrations.append(info)
            paths += pair(view,f'mockup_f{floor}_{scene}')
            at = (8+(floor-1)*164,32+row*176); overview.paste(view,at)
            caption(overview,(at[0],at[1]+153),f'F{floor} / {scene.upper()}')
    paths += pair(overview,'mockup_comparison')
    # Each row presents one actual front-wall distance, with both widths for
    # every floor. Nearby props are occluded by that wall where appropriate.
    depths = indexed((1000,566),1).convert('RGBA')
    caption(depths,(8,5),'SAME CAMERA / CORRIDOR + ROOM / F1, F2, F3 / DEPTHS 1-3')
    for row,z in enumerate((1.0,2.0,3.0)):
        for floor in (1,2,3):
            for i,scene in enumerate(('corridor','room')):
                view,info = render(floor,scene,back=z); registrations.append(info)
                col = (floor-1)*2+i; at = (8+col*164,32+row*176)
                depths.paste(view,at); caption(depths,(at[0],at[1]+153),f'F{floor} '+('COR' if i == 0 else 'ROOM')+f' / D{row+1}')
    paths += pair(depths,'mockup_depths')
    # World-coordinate sampling remains fixed while the camera advances.
    steps = indexed((508,216),1).convert('RGBA'); caption(steps,(8,5),'LOWER WATCH / THREE FORWARD SQUARES')
    for i in range(3):
        view,info = render(3,'corridor',step=i,with_props=False); registrations.append(info)
        at = (8+i*164,32); steps.paste(view,at); caption(steps,(at[0],at[1]+153),f'STEP {i+1}')
    paths += pair(steps,'mockup_steps')
    (BASE/'mockup_registration.json').write_text(json.dumps({'camera':{'size':[W,H],'focal':F,'horizon':HORIZON,'far':FAR},
        'status':'Offline proxy-room material proofs, same camera/lamps across floors. Not engine captures or proposed spawn coordinates.',
        'overview':'Corridor and room on each floor with decorative d1/d2/d3 props and wall segments.',
        'depths':'Each floor/width shown with front plane at1,2,3 cells. Far props are hidden by the front wall.',
        'steps':'F3 stable global cell UV/hash, camera moves three squares; no simulation RNG.',
        'views':registrations},indent=2)+'\n')
    return paths


if __name__ == '__main__': build_views()
