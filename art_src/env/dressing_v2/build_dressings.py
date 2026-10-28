"""Reduce saved imagegen paintings; preserve registration, seams and old art."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hashlib
import json
from PIL import Image, ImageDraw
from pipeline import ROOT, RGB, NEAREST, indexed, reduce, save, contact, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/env'
KINDS = ('door', 'door_open', 'drain', 'sconce_0', 'sconce_1', 'chains', 'tapestry', 'crack', 'damp')
INNER = [(14, 57), (14, 21), (16, 16), (20, 12), (25, 10), (31, 9),
         (37, 10), (43, 13), (47, 18), (49, 24), (49, 57)]
APERTURE = [(27, 56), (27, 15), (31, 11), (36, 12), (42, 15), (46, 20), (47, 25), (47, 56)]
FLAME = [(22, 5), (40, 5), (40, 19), (37, 20), (28, 20), (28, 24), (22, 24)]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def polygon(points):
    im = Image.new('L', (64, 64)); ImageDraw.Draw(im).polygon(points, fill=255)
    return im


def edges(im, floor):
    # One common 2px ring: all new faces meet any accepted painted wall.
    base = Image.open(OUT/f'painted_f{floor}_plain_0.png')
    for box in ((0, 0, 64, 2), (0, 62, 64, 64), (0, 0, 2, 64), (62, 0, 64, 64)):
        im.paste(base.crop(box), box[:2])
    return im


def pair(im, name):
    for suffix, image in [('native', im), ('4x', im.resize((im.width*4, im.height*4), NEAREST))]:
        p = BASE/f'{name}_{suffix}.png'
        if image.mode == 'P': save(image, p)
        else: image.save(p)


def main():
    inner, hole, flame = polygon(INNER), polygon(APERTURE), polygon(FLAME)
    (BASE/'masks').mkdir(exist_ok=True)
    for name, image in [('door_interior', inner), ('door_aperture', hole), ('sconce_flame', flame)]:
        image.save(BASE/'masks'/f'{name}.png')
    assets, registrations = {}, []
    for floor in (1, 2):
        faces = {kind: reduce(Image.open(BASE/'sources'/f'f{floor}_{kind}.png'), (64, 64)) for kind in KINDS}
        # Keep the exact arch/jambs/threshold between actual lock states.
        opened = faces['door'].copy(); opened.paste(faces['door_open'], (0, 0), inner)
        faces['door_open'] = opened
        # Keep every torch fixture and wall pixel outside the moving fire fixed.
        flicker = faces['sconce_0'].copy(); flicker.paste(faces['sconce_1'], (0, 0), flame)
        faces['sconce_1'] = flicker
        for kind, im in faces.items(): faces[kind] = edges(im, floor)
        overlay = faces['door_open'].copy(); overlay.paste(0, (0, 0), hole)
        faces['door_open_overlay'] = overlay
        for kind, im in faces.items():
            name = f'painted_f{floor}_{kind}_v2'; save(im, OUT/f'{name}.png')
            assets[name] = im
            registrations.append({'path': f'assets/art/env/{name}.png', 'floor': floor, 'kind': kind,
                'canvas': [64, 64], 'anchor': [0, 0], 'frame_ms': 250 if kind.startswith('sconce_') else None,
                'role': 'transparent portal plane for opened functional lock' if kind == 'door_open_overlay' else 'opaque wall-face texture',
                'interactive': kind in ('door', 'door_open', 'door_open_overlay'),
                'art_supplies_collision': False})
        labels = {'door': 'LOCKED', 'door_open': 'OPEN', 'drain': 'DRAIN', 'sconce_0': 'TORCH A', 'sconce_1': 'TORCH B',
                  'chains': 'CHAINS', 'tapestry': 'HANGING', 'crack': 'FISSURE', 'damp': 'DAMP', 'door_open_overlay': 'OPEN ALPHA'}
        contact({labels[k]: v for k, v in faces.items()}, BASE/f'floor{floor}', columns=5, cell=(112, 98), title=f'PAINTED DRESSING / FLOOR {floor}')
        repeat = indexed((256, 192), 1)
        for i, kind in enumerate(('plain_0', 'drain', 'plain_1', 'sconce_0', 'chains', 'plain_2', 'tapestry', 'crack', 'plain_0', 'damp', 'door', 'door_open')):
            im = Image.open(OUT/f'painted_f{floor}_{kind}.png') if kind.startswith('plain') else faces[kind]
            repeat.paste(im, ((i%4)*64, (i//4)*64))
        pair(repeat, f'floor{floor}_repeat')
    contact({f'F{r["floor"]} '+{'sconce_0': 'TORCH A', 'sconce_1': 'TORCH B', 'door_open_overlay': 'OPEN ALPHA',
                               'door_open': 'OPEN', 'tapestry': 'HANGING'}.get(r['kind'], r['kind'].upper()): assets[Path(r['path']).stem]
             for r in registrations}, BASE, columns=5, cell=(112, 98), title='UNDERCROFT / PAINTED DRESSING V2')
    old_new = {}
    for kind in ('door', 'drain', 'sconce_0', 'chains', 'tapestry', 'crack', 'damp'):
        short = {'sconce_0': 'TORCH', 'tapestry': 'HANGING'}.get(kind, kind.upper())
        old_new['OLD '+short] = Image.open(OUT/f'painted_f1_{kind}.png')
        old_new['F1 '+short] = assets[f'painted_f1_{kind}_v2']
        old_new['F2 '+short] = assets[f'painted_f2_{kind}_v2']
    contact(old_new, BASE/'comparison', columns=3, cell=(116, 98), title='OLD / PAINTED ABBEY / PAINTED DEEP')
    (BASE/'layout.json').write_text(json.dumps({'schema_version': 1, 'registrations': registrations,
        'sampling': 'Existing 64px wall-column UVs; no depth-specific copies, nearest filtering.',
        'plain_walls': 'Keep accepted painted_fN_plain_0/1/2. Sealed arch_blocked/door_barricaded are also unchanged.',
        'random_dressing_rule': 'Preserve current hash/placement; for sconce,drain,chains,tapestry,crack,damp append _v2 after the complete old stem, including sconce frame number.',
        'lock_closed': 'In closed lock solid-cell override use painted_fN_door_v2.png, not decorative barricaded art.',
        'lock_open': 'In _architecture() route only kind==lock && fixture.open to painted_fN_door_open_overlay_v2.png. Leave actual gate/web/cord portal paths intact. Open locks remain passable.',
        'opaque_open': 'painted_fN_door_open_v2.png is a full opaque reference/flat face; use alpha overlay in a live walk-through corridor so world/actors remain visible.',
        'sconce_sequence': ['sconce_0_v2', 'sconce_1_v2'], 'frame_ms': [250, 250],
        'shared_ring_px': 2, 'door_inner_polygon': INNER, 'open_portal_aperture_polygon': APERTURE,
        'flicker_polygon': FLAME, 'method': '18 saved individual imagegen paintings -> nearest resize -> shared 31 opaque inks + transparent index0 -> registration and seam repair only.',
        'integration_status': 'Asset offer only; no code, interaction or simulation changes.'}, indent=2)+'\n')
    from build_views import build_views
    previews = build_views()
    files = [OUT/f'{name}.png' for name in assets]+[p for p in BASE.rglob('*.png') if p.name.endswith(('_native.png', '_4x.png')) and not p.name.startswith('mockup_')]
    manifest(files, BASE/'manifest.json', {'runtime_count': len(assets), 'layout': 'layout.json',
        'preview_files': [{'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p)} for p in previews],
        'sources_method': 'Built-in imagegen, one painting per face/frame/floor. Prompts in prompts.json; reduction is deterministic.'})
    print(f'Painted dressing v2: {len(assets)} runtime faces/portal layers; both floors; common 2px edges; registered open/closed doors and 2-frame torches.')


if __name__ == '__main__': main()
