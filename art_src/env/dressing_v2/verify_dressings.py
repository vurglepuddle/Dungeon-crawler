"""Focused offline art contracts: seams, real portal alpha and stable states."""
import sys
sys.dont_write_bytecode = True
import json
from PIL import Image
from build_dressings import BASE, ROOT, OUT, KINDS, INNER, APERTURE, FLAME, polygon, digest, main as build
from pipeline import TABLE, RGB, NEAREST


def luminance(im):
    return sum(0.2126*r+0.7152*g+0.0722*b for r, g, b in im.convert('RGB').crop((2, 2, 62, 62)).getdata())/3600


def main():
    old = json.loads((BASE/'preserved_hashes.json').read_text())
    for path, sha in old.items(): assert digest(ROOT/path) == sha, ('Old asset changed', path)
    info = json.loads((BASE/'manifest.json').read_text())
    for entry in info['files']+info['sources']+info['preview_files']:
        assert digest(ROOT/entry['path']) == entry['sha256'], entry['path']
    prompts = json.loads((BASE/'prompts.json').read_text())['paintings']
    assert len(prompts) == len(info['sources']) == 18
    for floor in (1, 2):
        base = Image.open(OUT/f'painted_f{floor}_plain_0.png')
        for kind in KINDS+('door_open_overlay',):
            im = Image.open(OUT/f'painted_f{floor}_{kind}_v2.png')
            assert im.size == (64, 64) and im.mode == 'P' and im.getpalette() == TABLE
            assert {a for *_, a in im.convert('RGBA').getdata()} <= {0, 255}
            for box in ((0, 0, 64, 2), (0, 62, 64, 64), (0, 0, 2, 64), (62, 0, 64, 64)):
                assert im.crop(box).tobytes() == base.crop(box).tobytes(), (kind, floor, box)
            assert im.crop((0, 0, 1, 64)).tobytes() == im.crop((63, 0, 64, 64)).tobytes()
            assert im.crop((0, 0, 64, 1)).tobytes() == im.crop((0, 63, 64, 64)).tobytes()
            assert (0 in set(im.getdata())) == (kind == 'door_open_overlay')
        closed, opened, overlay = [Image.open(OUT/f'painted_f{floor}_{kind}_v2.png') for kind in ('door', 'door_open', 'door_open_overlay')]
        inner, hole, fire = polygon(INNER), polygon(APERTURE), polygon(FLAME)
        assert all(a == b for a, b, mask in zip(closed.getdata(), opened.getdata(), inner.getdata()) if not mask)
        assert all(c == (0 if mask else a) for a, c, mask in zip(opened.getdata(), overlay.getdata(), hole.getdata()))
        assert sum(p == 0 for p in overlay.getdata()) >= 750
        # Left-hand slab remains opaque, while the centre/right passage really
        # sees through. No portcullis bars can be left across this aperture.
        assert all(overlay.getpixel((x, y)) for y in range(24, 53) for x in range(16, 24))
        assert all(not overlay.getpixel((x, y)) for y in range(24, 53) for x in range(29, 45))
        a, b = [Image.open(OUT/f'painted_f{floor}_sconce_{i}_v2.png') for i in range(2)]
        changes = [(x, y) for y in range(64) for x in range(64) if a.getpixel((x, y)) != b.getpixel((x, y))]
        assert len(changes) >= 25
        assert all(fire.getpixel(point) for point in changes)
    ratios = {}
    for kind in KINDS:
        a, b = [Image.open(OUT/f'painted_f{floor}_{kind}_v2.png') for floor in (1, 2)]
        ratios[kind] = round(luminance(b)/luminance(a), 3)
        assert ratios[kind] < 0.85, (kind, ratios[kind])
    for native in BASE.rglob('*native.png'):
        a = Image.open(native); b = Image.open(native.with_name(native.name.replace('native', '4x')))
        assert b.size == (a.width*4, a.height*4)
        assert a.resize(b.size, NEAREST).tobytes() == b.tobytes()
    mock = json.loads((BASE/'mockup_registration.json').read_text())
    for data in mock['observed_ray_depth_ranges'].values():
        assert set(data) == {'left/drain', 'right/chains', 'left/tapestry', 'right/sconce_0', 'left/crack', 'right/damp'}
        assert data['left/drain'][0] < 1.0 and data['left/drain'][1] < 1.5
        assert 1.5 <= data['right/sconce_0'][0] < 2.5
        assert 2.5 <= data['right/damp'][0] < 3.6
    result = {'runtime_pngs': 20, 'saved_paintings': 18, 'old_runtime_pngs_unchanged': len(old),
        'common_edge_ring_px': 2, 'floor2_to_floor1_luminance': ratios,
        'passed': ['palette and binary alpha', 'all old PNG hashes', 'common mixed-wall seams',
                   'pixel-identical arch around door states', 'real unobstructed portal alpha',
                   'stationary torch hardware/soot/stone outside flame mask', 'd1-d3 proof placement', 'exact nearest 4x'],
        'status': 'Offline art validation; no Godot runs, integration, gameplay test or phone acceptance.'}
    return result


if __name__ == '__main__':
    result = main()
    if '--rebuild' in sys.argv:
        runtime = [ROOT/entry['path'] for entry in json.loads((BASE/'layout.json').read_text())['registrations']]
        paths = sorted([p for p in BASE.rglob('*') if p.suffix in ('.png', '.json') and p.name not in ('verification.json', 'rebuild_receipt.json')]+runtime)
        before = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        build()
        after = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
        assert before == after, [p for p in before if before[p] != after[p]]
        result = main(); result['identical_rebuild_files'] = len(paths)
        (BASE/'rebuild_receipt.json').write_text(json.dumps({'files_compared': len(paths), 'identical': True, 'hashes': after}, indent=2)+'\n')
    (BASE/'verification.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
