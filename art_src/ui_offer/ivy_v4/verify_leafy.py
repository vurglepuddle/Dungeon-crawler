"""Check new leafy overlays, unchanged v3 art, and protected screen pixels."""
import sys
sys.dont_write_bytecode = True
import json
from PIL import Image
from build_leafy import BASE, OLD, OUT, ROOT, PROTECTED, MAP_PROTECTED, COMPASS_ORIGIN, NEAREST, digest, leaf, main as build


def no_ink(image, box):
    x, y, w, h = box
    assert not image.convert('RGBA').getchannel('A').crop((x, y, x+w, y+h)).getbbox(), box


def verify():
    preserved = json.loads((BASE/'preserved_hashes.json').read_text())
    for path, sha in preserved.items(): assert digest(ROOT/path) == sha, ('Changed old file', path)
    layout = json.loads((BASE/'layout.json').read_text())
    record = json.loads((BASE/'manifest.json').read_text())
    for entry in record['files']+record['sources']+record['preview_files']:
        assert digest(ROOT/entry['path']) == entry['sha256'], entry['path']
    sizes = {'ivy_game_border_v4': (154, 342), 'ivy_compass_v4': (74, 51), 'ivy_map_border_v4': (144, 324)}
    for name, size in sizes.items():
        image = Image.open(OUT/f'{name}.png'); assert image.size == size
        mask = Image.open(BASE/'masks'/f'{name}.png')
        assert all(not p or m for p, m in zip(image.getdata(), mask.getdata())), name
    game = Image.open(OUT/'ivy_game_border_v4.png')
    compass = Image.new('RGBA', (154, 342))
    compass.alpha_composite(Image.open(OUT/'ivy_compass_v4.png').convert('RGBA'), COMPASS_ORIGIN)
    for image in (game, compass):
        for box in PROTECTED: no_ink(image, box)
    no_ink(compass, (88, 297, 60, 38))
    for box in layout['bronze_underpasses']: no_ink(game, box)
    skull = Image.open(OUT/'sleepy_skull_v3.png').convert('RGBA')
    assert compass.crop((114, 335, 123, 342)).tobytes() == skull.tobytes()
    map_image = Image.open(OUT/'ivy_map_border_v4.png')
    paper = Image.open(OUT/'map_parchment_torn_v2.png')
    for box in MAP_PROTECTED: no_ink(map_image, box)
    assert all(not p or page for p, page in zip(map_image.getdata(), paper.getdata()))
    # Require real intact leaf silhouettes, not clipped fragments or dots.
    intact = 0
    for x, y, size, turn in layout['leaf_placements']['game']:
        sample = leaf(size, turn)
        if all(not sample.getpixel((xx, yy)) or sample.getpixel((xx, yy)) == game.getpixel((x+xx, y+yy))
               for yy in range(sample.height) for xx in range(sample.width)):
            intact += 1
    assert intact >= 20, intact
    opaque = lambda im: sum(p != 0 for p in im.getdata())
    counts = {name: opaque(Image.open(OUT/f'{name}.png')) for name in sizes}
    previous = {name: opaque(Image.open(OUT/f'{name.replace("v4", "v3")}.png')) for name in sizes}
    assert counts['ivy_game_border_v4'] > previous['ivy_game_border_v4']*1.7
    assert counts['ivy_compass_v4'] > previous['ivy_compass_v4']*1.7
    assert sum(p in (8, 17) for p in game.getdata()) >= 65
    source = Image.open(BASE/'sources/entry.png').convert('RGBA').resize((154, 342), NEAREST)
    mock = Image.open(BASE/'mockup_game_native.png').convert('RGBA')
    # Compare all protected presentation content, except intentional verb relayout.
    boxes = [(53, 0, 44, 18), (8, 26, 138, 140), (4, 177, 146, 28),
             (3, 210, 32, 35), (43, 211, 58, 32), (101, 211, 48, 31),
             (3, 249, 148, 16), (108, 130, 43, 41), (88, 297, 60, 38)]
    for x, y, w, h in boxes:
        box = (x, y, x+w, y+h)
        assert source.crop(box).tobytes() == mock.crop(box).tobytes(), box
    # The accepted icons and words must be pixel-identical to the v3 proof.
    old_mock = Image.open(OLD/'mockup_game_native.png').convert('RGBA')
    for i in range(3):
        box = (5+i*50, 272, 47+i*50, 288)
        assert mock.crop(box).tobytes() == old_mock.crop(box).tobytes(), box
    old_map = Image.open(BASE/'sources/map.png').convert('RGBA')
    new_map = Image.open(BASE/'mockup_map_native.png').convert('RGBA')
    for x, y, w, h in MAP_PROTECTED[:2]:
        box = (x+5, y+16, x+w+5, y+h+16)
        assert old_map.crop(box).tobytes() == new_map.crop(box).tobytes(), box
    old_close = Image.open(OLD/'mockup_map_native.png').convert('RGBA')
    assert old_close.crop((13, 288, 141, 313)).tobytes() == new_map.crop((13, 288, 141, 313)).tobytes()
    for native in BASE.glob('*native.png'):
        small = Image.open(native); large = Image.open(native.with_name(native.name.replace('native', '4x')))
        assert large.size == (small.width*4, small.height*4)
        assert small.resize(large.size, NEAREST).tobytes() == large.tobytes()
    return {'runtime_pngs': 3, 'earlier_runtime_pngs_preserved': sum(p.startswith('assets/') for p in preserved),
            'owner_reference_pngs_preserved': 2, 'entire_v3_source_pack_preserved': True,
            'intact_game_leaf_stamps': intact, 'opaque_pixels_v4': counts, 'opaque_pixels_v3': previous,
            'protected': 'camera, view core and held weapon, text/icons/health, touch interiors, entire compass dial/heading, map ink/header/CLOSE',
            'status': 'Offline pixel checks and composites; no Godot run or phone acceptance.'}


if __name__ == '__main__':
    result = verify()
    if '--rebuild' in sys.argv:
        paths = sorted([p for p in BASE.rglob('*') if p.suffix in ('.png', '.json') and p.name not in ('verification.json', 'rebuild_receipt.json')]
                       + [OUT/f'{name}.png' for name in ('ivy_game_border_v4', 'ivy_compass_v4', 'ivy_map_border_v4')])
        before = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        build()
        after = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        assert before == after
        result = verify(); result['identical_rebuild_files'] = len(paths)
        (BASE/'rebuild_receipt.json').write_text(json.dumps({'files_compared': len(paths), 'identical': True, 'hashes': after}, indent=2)+'\n')
    (BASE/'verification.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
