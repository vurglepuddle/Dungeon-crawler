"""Offline contracts for the new Watch family; never launches Godot."""
import sys
sys.dont_write_bytecode = True
import importlib.util
import json
from collections import Counter
from PIL import Image
from build_lower_watch import BASE, ROOT, OUT, RING, INNER, APERTURE, FLAME, digest, mask, main as build
from pipeline import TABLE, NEAREST
from selection import FLOORS, WEIGHTS, CEILING_WEIGHTS, pick, texture_name, mix_hash

PROP_BASE = ROOT/'art_src/props/lower_watch'


def check():
    preserved = json.loads((BASE/'preserved_hashes.json').read_text())
    for path, sha in preserved.items(): assert digest(ROOT/path) == sha, ('Preserved PNG changed',path)
    infos = [json.loads((p/'manifest.json').read_text()) for p in (BASE,PROP_BASE)]
    runtime = []
    for info in infos:
        for entry in info['files']+info['sources']+info.get('preview_files',[]):
            assert digest(ROOT/entry['path']) == entry['sha256'], entry['path']
        runtime += [ROOT/e['path'] for e in info['files'] if e['path'].startswith('assets/')]
    assert len(runtime) == len(set(runtime)) == 64
    assert [len(i['sources']) for i in infos] == [24,9]
    for directory,count in ((BASE,24),(PROP_BASE,9)):
        prompts = json.loads((directory/'prompts.json').read_text())['entries']
        assert len(prompts) == count and all(p['prompt'] and p['referenced_image_paths'] for p in prompts)
        assert {p['source'] for p in prompts} == {p.relative_to(directory).as_posix() for p in (directory/'sources').glob('*.png')}
    for path in runtime:
        im = Image.open(path)
        assert im.mode == 'P' and im.getpalette() == TABLE and max(im.getdata()) < 32, path
        assert set(im.convert('RGBA').getchannel('A').getdata()) <= {0,255}, path

    layout = json.loads((BASE/'layout.json').read_text())
    base = Image.open(OUT/'painted_f3_plain_0.png')
    assert len(layout['walls']) == 15 and len(layout['planes']) == 20
    for name in layout['walls']:
        im = Image.open(OUT/(name+'.png'))
        assert im.size == (64,64)
        for box in RING: assert im.crop(box).tobytes() == base.crop(box).tobytes(), (name,box)
        assert im.crop((0,0,1,64)).tobytes() == im.crop((63,0,64,64)).tobytes(), name
        assert im.crop((0,0,64,1)).tobytes() == im.crop((0,63,64,64)).tobytes(), name
        assert (0 in set(im.getdata())) == ('overlay' in name)
    for name in layout['planes']+layout['base_aliases']:
        plane = 'ceiling' if 'ceiling' in name else 'floor'
        reference = Image.open(OUT/('calm_v3_ceiling_plain.png' if plane == 'ceiling' else 'calm_v3_floor_dry_a.png'))
        im = Image.open(OUT/(name+'.png')); assert im.size == (64,64)
        assert 0 not in set(im.getdata()),name
        for box in RING: assert im.crop(box).tobytes() == reference.crop(box).tobytes(), (name,box)
    assert len({Image.open(OUT/f'calm_v3_f3_floor_{name}.png').tobytes() for name in FLOORS}) == 11

    closed,opened,overlay = [Image.open(OUT/f'painted_f3_{name}_v2.png') for name in ('door','door_open','door_open_overlay')]
    inner,hole,fire = mask(INNER),mask(APERTURE),mask(FLAME)
    assert all(a == b for a,b,m in zip(closed.getdata(),opened.getdata(),inner.getdata()) if not m)
    assert all(b == (0 if m else a) for a,b,m in zip(opened.getdata(),overlay.getdata(),hole.getdata()))
    assert all(overlay.getpixel((x,y)) == 0 for y in range(24,53) for x in range(29,45))
    assert all(overlay.getpixel((x,y)) != 0 for y in range(24,53) for x in range(16,24))
    a,b = [Image.open(OUT/f'painted_f3_sconce_{n}_v2.png') for n in (0,1)]
    changes = [(x,y) for y in range(64) for x in range(64) if a.getpixel((x,y)) != b.getpixel((x,y))]
    assert len(changes) >= 25 and all(fire.getpixel(p) for p in changes)

    props = json.loads((PROP_BASE/'layout.json').read_text())['registrations']
    assert len(props) == 27 and len({e['kind'] for e in props}) == 9
    for e in props:
        im = Image.open(ROOT/e['path']); w,h = e['canvas']
        assert im.size == (w,h) and e['anchor'] == [w//2,h] and not e['interactive']
        near = Image.open(ROOT/f"assets/art/props/f3_{e['kind']}_d1.png")
        assert im.tobytes() == near.resize(im.size,NEAREST).tobytes(),e['path']
        assert {0,255} == set(im.convert('RGBA').getchannel('A').getdata())
        upper = Image.open(ROOT/f"assets/art/props/f1_{e['kind']}_d{e['depth']}.png") if e['kind'] != 'puddle' else None
        if upper: assert upper.size == im.size
    assert all(sum(w) == 100 for w in list(WEIGHTS.values())+list(CEILING_WEIGHTS.values()))
    spec = importlib.util.spec_from_file_location('old_selection',BASE.parent/'calm_v3/selection.py')
    old = importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
    for floor in (1,2):
        for plane in ('floor','ceiling'):
            for x in range(-4,12):
                for y in range(-4,12): assert pick('BELL42',floor,plane,x,y) == old.pick('BELL42',floor,plane,x,y)
    for entry in layout['reference_samples']:
        key = f"{entry['seed']}/3/{entry['plane']}/{entry['x']}/{entry['y']}"
        assert old.mix_hash(key) == mix_hash(key) == entry['hash']
        assert entry['kind'] == pick(entry['seed'],3,entry['plane'],entry['x'],entry['y'])
        assert entry['path'] == texture_name(entry['seed'],3,entry['plane'],entry['x'],entry['y'])
    counts = Counter(pick('BELL42',3,'floor',x,y) for x in range(-50,50) for y in range(-50,50))
    assert set(counts) == set(FLOORS)
    mock = json.loads((BASE/'mockup_registration.json').read_text())
    overview = mock['views'][:6]
    assert {(v['floor'],v['scene']) for v in overview} == {(f,s) for f in (1,2,3) for s in ('room','corridor')}
    assert all({p['band'] for p in v['props']} == {1,2,3} for v in overview)
    assert {(v['floor'],v['scene'],v['back_depth']) for v in mock['views'][6:24]} == {(f,s,d) for f in (1,2,3) for s in ('room','corridor') for d in (1,2,3)}
    steps = Image.open(BASE/'mockup_steps_native.png')
    assert len({steps.crop((8+i*164,32,156+i*164,182)).tobytes() for i in range(3)}) == 3
    for directory in (BASE,PROP_BASE):
        for native in directory.rglob('*native.png'):
            im = Image.open(native); enlarged = Image.open(native.with_name(native.name.replace('native','4x')))
            assert enlarged.size == (im.width*4,im.height*4) and im.resize(enlarged.size,NEAREST).tobytes() == enlarged.tobytes()
    flavour = json.loads((ROOT/'data/text/flavour.json').read_text())
    assert flavour['floor_names']['3'] == ['The Lower Watch']
    for lines in list(flavour['floor_names'].values())+flavour['death_epitaphs']+[e['lines'] for e in flavour['hint_notes']]:
        assert 1 <= len(lines) <= 2 and all(0 < len(line) <= 21 and '\n' not in line for line in lines)
    return {'runtime_pngs':64,'environment_pngs':37,'prop_pngs':27,'saved_paintings':33,
            'preserved_pngs':len(preserved),'floor_hash_counts_10000_cells':dict(counts),
            'sconce_changed_pixels':len(changes),'passed':['shared palette and binary alpha','all preserved PNG hashes',
            '15 common-ring wall states','exact calm_v3 two-pixel plane seams','11 distinct stable floor slots',
            'unobstructed open portal and stationary arch','stationary two-frame torch hardware',
            '27 prop depth canvases and anchors','F1/F2 hash choices unchanged','d1-d3 same-camera comparisons',
            'three distinct forward steps','exact nearest 4x proofs','21-character two-line flavour'],
            'status':'Offline art checks only; no Godot runs, integration, gameplay test or phone acceptance.'}


if __name__ == '__main__':
    result = check()
    if '--rebuild' in sys.argv:
        paths = set()
        for directory in (BASE,PROP_BASE):
            paths.update(p for p in directory.rglob('*') if p.suffix in ('.png','.json') and p.name not in ('verification.json','rebuild_receipt.json'))
            paths.update(ROOT/e['path'] for e in json.loads((directory/'manifest.json').read_text())['files'])
        before = {p.relative_to(ROOT).as_posix():digest(p) for p in sorted(paths)}
        build()
        after = {p.relative_to(ROOT).as_posix():digest(p) for p in sorted(paths)}
        assert before == after,[p for p in before if before[p] != after[p]]
        result = check(); result['identical_rebuild_files'] = len(paths)
        (BASE/'rebuild_receipt.json').write_text(json.dumps({'files_compared':len(paths),'identical':True,'hashes':after},indent=2)+'\n')
    (BASE/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
