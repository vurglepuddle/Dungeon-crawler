"""Focused pixel/layout contracts for the UI offer; never starts Godot."""
import sys
sys.dont_write_bytecode = True
import json
from pathlib import Path
from PIL import Image, ImageDraw
from build_ivy import BASE, ROOT, OUT, VERBS, COMPACT, FONT, RGB, NEAREST, digest, main as build


def no_ink(im, rect):
    x, y, w, h = rect
    assert not im.convert('RGBA').getchannel('A').crop((x, y, x+w, y+h)).getbbox(), rect


def positioned(name, pos=(0, 0)):
    im = Image.new('RGBA', (154, 342))
    im.alpha_composite(Image.open(OUT / f'{name}.png').convert('RGBA'), pos)
    return im


def protected_controls():
    # Insets describe only the already-painted three-pixel housing rims.
    rects = [(1, 0, 51, 18), (98, 0, 22, 18), (121, 0, 32, 18),
             (3, 210, 32, 32), (43, 211, 24, 32), (71, 211, 24, 32),
             (101, 211, 22, 22), (127, 211, 22, 22), (85, 294, 66, 44)]
    rects += [(1+i*19, 246, 19, 22) for i in range(8)]
    rects += [(2+i*50, 269, 48, 22) for i in range(3)]
    rects += [(3+i % 3*26, 293+i//3*24, 24, 22) for i in range(6)]
    return [(x+3, y+3, w-6, h-6) for x, y, w, h in rects]


def verify():
    old = json.loads((BASE / 'preserved_hashes.json').read_text())
    for path, sha in old.items(): assert digest(ROOT/path) == sha, ('Preserved file changed', path)
    registration = json.loads((BASE / 'layout.json').read_text())
    declared = json.loads((BASE / 'manifest.json').read_text())
    for record in declared['files'] + declared['sources'] + declared['preview_files']:
        assert digest(ROOT/record['path']) == record['sha256'], record['path']
    for name in ('ivy_game_border_v3', 'ivy_compass_v3', 'ivy_map_border_v3', 'ivy_torches_v3_0', 'ivy_torches_v3_1'):
        im = Image.open(OUT / f'{name}.png')
        mask = Image.open(BASE / 'masks' / f'{name}.png')
        assert all(not p or m for p, m in zip(im.getdata(), mask.getdata())), name
    compass = positioned('ivy_compass_v3', (85, 294))
    # Protect the complete dial and all heading alternatives, not just this N.
    no_ink(compass, (88, 297, 60, 38))
    no_ink(compass, (111, 297, 16, 9))
    game_layers = [positioned('ivy_game_border_v3'), compass,
                   positioned('ivy_torches_v3_0'), positioned('ivy_torches_v3_1')]
    for im in game_layers:
        for rect in protected_controls()+[(53, 0, 44, 18), (3, 21, 148, 150),
                                          (4, 175, 146, 30), (3, 210, 32, 35),
                                          (96, 211, 5, 31), (101, 232, 50, 10)]:
            no_ink(im, rect)
    paper = Image.open(ROOT/'assets/art/ui_offer/map_parchment_torn_v2.png')
    ivy_map = Image.open(OUT/'ivy_map_border_v3.png')
    no_ink(ivy_map, (8, 12, 128, 300))
    assert all(not vine or page for vine, page in zip(ivy_map.getdata(), paper.getdata()))
    torch_a, torch_b = [Image.open(OUT/f'ivy_torches_v3_{i}.png') for i in range(2)]
    delta = [(x, y) for y in range(342) for x in range(154) if torch_a.getpixel((x, y)) != torch_b.getpixel((x, y))]
    assert delta and all(x in (81, 82, 83, 151, 152, 153) and 300 <= y <= 303 for x, y in delta)
    for verb in VERBS:
        im = Image.open(OUT/f'verb_{verb.lower()}.png')
        assert im.size == (12, 12)
        assert set(im.getdata()) <= {0, 1, 9, 10, 25, 28}
    # Every ivory/bronze pixel has its full one-pixel dark silhouette boundary.
    for path in OUT.glob('verb_*.png'):
        im = Image.open(path)
        for y in range(im.height):
            for x in range(im.width):
                if im.getpixel((x, y)) in (0, 1): continue
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        xx, yy = x+dx, y+dy
                        assert 0 <= xx < im.width and 0 <= yy < im.height and im.getpixel((xx, yy)), (path.name, x, y, xx, yy)
    fit_count = 0
    for entries in (registration['buttons'], registration['button_24px_height'], registration['item_card_buttons_42x20']):
        for entry in entries:
            w, h = entry['button_size']; x, y = entry['icon_origin']
            iw, ih = entry['icon_size']; tx, ty = entry['text_origin_pillow']
            assert tx == x+iw+2 and x >= 2 and tx+entry['text_width'] <= w-2
            assert 0 <= y and y+ih <= h
            text = Image.new('L', (w, h)); d = ImageDraw.Draw(text); d.fontmode = '1'
            d.text((tx, ty), entry['verb'], font=FONT, fill=255)
            box = text.getbbox(); assert box and box[0] >= tx and box[2] <= w-2 and 2 <= box[1] < box[3] <= h-2
            assert not text.crop((x, y, x+iw+2, y+ih)).getbbox(), entry
            im = Image.open(ROOT/entry['icon_path']); assert list(im.size) == entry['icon_size']
            fit_count += 1
    game_ref = Image.open(BASE/'sources/m3e_entry.png').convert('RGBA').resize((154, 342), NEAREST)
    game = Image.open(BASE/'mockup_game_native.png')
    for rect in [(53, 0, 44, 18), (3, 21, 148, 150), (4, 175, 146, 30), (3, 210, 32, 35),
                 (43, 211, 58, 31), (101, 211, 48, 31), (3, 249, 148, 16), (88, 297, 60, 38)]:
        x, y, w, h = rect; box = (x, y, x+w, y+h)
        assert game.crop(box).tobytes() == game_ref.crop(box).tobytes(), ('Mock content changed', rect)
    map_ref = Image.open(BASE/'sources/torn_map.png').convert('RGBA')
    map_mock = Image.open(BASE/'mockup_map_native.png')
    for box in ((13, 28, 141, 288), (13, 313, 141, 328), (53, 0, 97, 18)):
        assert map_mock.crop(box).tobytes() == map_ref.crop(box).tobytes(), ('Map ink changed', box)
    for native in BASE.glob('*native.png'):
        large = Image.open(native.with_name(native.name.replace('native', '4x')))
        small = Image.open(native)
        assert small.resize(large.size, NEAREST).tobytes() == large.tobytes()
    return {'runtime_pngs': declared['runtime_count'], 'verb_count': len(VERBS), 'fit_cases': fit_count,
            'earlier_runtime_pngs_preserved': sum(p.startswith('assets/') for p in old),
            'owner_references_preserved': 2, 'protected': 'camera, world, text, contents, target interiors, portrait/health, all compass headings/dial, map ink',
            'torches_ms': [420, 580], 'status': 'Offline pixel/layout checks; no Godot run or phone acceptance.'}


if __name__ == '__main__':
    result = verify()
    if '--rebuild' in sys.argv:
        paths = sorted([p for p in BASE.rglob('*') if p.suffix in ('.png', '.json') and p.name not in ('verification.json', 'rebuild_receipt.json')]
                       + [OUT/f'{name}.png' for name in [Path(e['path']).stem for e in json.loads((BASE/'manifest.json').read_text())['files'] if e['path'].startswith('assets/')]])
        before = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        build()
        after = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        assert before == after, [p for p in before if before[p] != after[p]]
        result = verify()
        (BASE/'rebuild_receipt.json').write_text(json.dumps({'files_compared': len(before), 'identical': True, 'hashes': after}, indent=2)+'\n')
        result['identical_rebuild_files'] = len(before)
    (BASE/'verification.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
