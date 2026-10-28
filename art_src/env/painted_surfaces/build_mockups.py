"""Offline UV/column material proofs using the view's current camera formula.

Reference screenshot chrome is preserved. Simple proxy rooms are authored for
material inspection; these PNGs are art mock-ups, not Godot playtest captures.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import math
from PIL import Image
from pipeline import ROOT, RGB, NEAREST, indexed, label

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/env'
WIDTH, HEIGHT, FOCAL, HORIZON, FAR = 148, 150, 74.0, 71, 3.6
VIEW_BOX = (3, 21, 151, 171)


def lamp(depth):
    return min(1.0, max(0.0, (FAR - depth) / 2.7))


def rgb(ink, gain):
    return tuple(max(0, min(255, int(c * gain))) for c in RGB[ink]) + (255,)


def render_view(floor, kind):
    # Camera faces north at a real cell centre; UVs stay in world space.
    origin = (10.5, 10.5)
    forward = (0, -1)
    right = (-forward[1], forward[0])
    half_width = 0.5 if kind == 'corridor' else 1.5
    textures = {p.stem: Image.open(p) for p in OUT.glob('painted_*.png')}
    view = Image.new('RGBA', (WIDTH, HEIGHT), (5, 6, 9, 255))
    for y in range(HEIGHT):
        floor_side = y > HORIZON
        depth = FOCAL * 0.5 / (abs(y - HORIZON) + 0.5)
        if depth >= FAR:
            continue
        plane = 'floor' if floor_side else 'ceiling'
        gain = lamp(depth) * (0.86 if floor_side else 0.64)
        for x in range(WIDTH):
            lateral = (x + 0.5 - WIDTH * 0.5) / FOCAL
            wx = origin[0] + (forward[0] + right[0] * lateral) * depth
            wy = origin[1] + (forward[1] + right[1] * lateral) * depth
            cell = (math.floor(wx), math.floor(wy))
            name = f'painted_f{floor}_{plane}'
            if kind == 'room' and cell == (10, 9):
                name = f'painted_room_f{floor}_{plane}_{"compass" if floor_side else "boss"}'
            u, v = math.floor(wx * 64) % 64, math.floor(wy * 64) % 64
            view.putpixel((x, y), rgb(textures[name].getpixel((u, v)), gain))
    for x in range(WIDTH):
        lateral = (x + 0.5 - WIDTH * 0.5) / FOCAL
        side_depth = half_width / abs(lateral) if lateral else 1e9
        depth = min(side_depth, 3.5)
        side = side_depth < 3.5
        along = (origin[1] - depth) if side else (origin[0] + lateral * depth)
        u = along - math.floor(along)
        if (side and lateral > 0) or not side:
            u = 1.0 - u
        tx = min(63, max(0, int(u * 64)))
        salt = (math.floor(along) + (1 if lateral > 0 else 0)) % 3
        name = f'painted_f{floor}_plain_{salt}'
        if kind == 'room' and side and math.floor(along) == 9 and lateral < 0:
            name = f'painted_f{floor}_sconce_0'
        wall = textures[name]
        h = max(1, math.floor(FOCAL / depth + 0.5))
        top = HORIZON - h // 2
        gain = lamp(depth) * (0.78 if side else 1.0)
        for y in range(max(0, top), min(HEIGHT, top + h)):
            ty = min(63, max(0, int((y - top) * 64 / h)))
            view.putpixel((x, y), rgb(wall.getpixel((tx, ty)), gain))
    return view


def pair(path, image):
    image.save(path)
    enlarged = path.with_name(path.name.replace('native', '4x'))
    image.resize((image.width * 4, image.height * 4), NEAREST).save(enlarged)
    return [path, enlarged]


def build_mockups():
    previews = []
    screen_sheet = indexed((664, 412), 1).convert('RGBA')
    heading = indexed(screen_sheet.size, 0)
    label(heading, (8, 5), 'UNDERCROFT / PAINTED SURFACE MOCK-UPS', 25)
    screen_sheet.alpha_composite(heading.convert('RGBA'))
    view_sheet = indexed((336, 380), 1).convert('RGBA')
    heading = indexed(view_sheet.size, 0)
    label(heading, (8, 5), '148 x 150 / SAME CAMERA', 25)
    view_sheet.alpha_composite(heading.convert('RGBA'))
    for floor in (1, 2):
        for column, kind in enumerate(('corridor', 'room')):
            source_name = '03_corridor' if kind == 'corridor' else '01_room'
            source = Image.open(BASE / 'sources' / f'{source_name}.png').convert('RGBA')
            screen = source.resize((154, 342), NEAREST)
            view = render_view(floor, kind)
            screen.paste(view, VIEW_BOX[:2])
            previews += pair(BASE / f'mockup_f{floor}_{kind}_native.png', screen)
            slot = (floor - 1) * 2 + column
            screen_sheet.paste(screen, (8 + slot * 164, 42))
            tags = indexed(screen_sheet.size, 0)
            label(tags, (8 + slot * 164, 388), f'F{floor} / {kind.upper()}', 8)
            screen_sheet.alpha_composite(tags.convert('RGBA'))
            x, y = 8 + column * 164, 34 + (floor - 1) * 174
            view_sheet.paste(view, (x, y))
            tags = indexed(view_sheet.size, 0)
            label(tags, (x, y + 152), f'F{floor} / {kind.upper()}', 8)
            view_sheet.alpha_composite(tags.convert('RGBA'))
    previews += pair(BASE / 'mockup_screen_native.png', screen_sheet)
    previews += pair(BASE / 'mockup_view_native.png', view_sheet)
    return previews


if __name__ == '__main__':
    build_mockups()
