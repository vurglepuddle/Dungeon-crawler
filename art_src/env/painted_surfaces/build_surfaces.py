"""Primary painted plane materials. Writes new filenames; preserves all old art."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'room_faces'))
import hashlib
import json
from PIL import Image
from pipeline import ROOT, RGB, NEAREST, indexed, reduce, save, contact, manifest
from build_faces import decorate

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/env'
RING = ((0, 0, 64, 2), (0, 62, 64, 64), (0, 0, 2, 64), (62, 0, 64, 64))
KINDS = {'floor': ('drain', 'cracked', 'compass'), 'ceiling': ('roots', 'chain', 'boss')}


def nearest(rgb):
    return min(range(1, 32), key=lambda i: sum(weight * (rgb[c] - RGB[i][c]) ** 2
        for c, weight in enumerate((2, 4, 1))))


def base_material(floor, plane):
    source = Image.open(BASE / 'sources' / f'f{floor}_{plane}.png').convert('RGB')
    if floor == 2:
        # Keep wet stone readable while making the second level visibly older.
        gains = (0.83, 0.87, 0.91) if plane == 'floor' else (0.90, 0.93, 0.95)
        lut = [max(0, min(255, round(v * gain))) for gain in gains for v in range(256)]
        source = source.point(lut)
    im = reduce(source, (64, 64))
    if plane == 'floor':
        # The strong shared outer joint marks ONE world cell. Internal flag
        # joins remain the painting's quieter, irregular lines.
        for y in range(64):
            for x in range(64):
                edge = min(x, y, 63 - x, 63 - y)
                if edge < 2:
                    ink = 2 if floor == 1 else 11
                    # Sparse sediment in the inner lip, never a bright dot.
                    if edge == 1 and (x * 3 + y * 5) % 11 < 2:
                        ink = 3 if floor == 1 else 12
                    im.putpixel((x, y), ink)
    # Opposite boundary texels agree exactly. A two-pixel ring is then shared
    # unchanged by every variant; ceilings retain their painted crossing ribs.
    for y in range(64):
        a, b = RGB[im.getpixel((0, y))], RGB[im.getpixel((63, y))]
        ink = nearest(tuple((a[c] + b[c]) // 2 for c in range(3)))
        im.putpixel((0, y), ink)
        im.putpixel((63, y), ink)
    for x in range(64):
        a, b = RGB[im.getpixel((x, 0))], RGB[im.getpixel((x, 63))]
        ink = nearest(tuple((a[c] + b[c]) // 2 for c in range(3)))
        im.putpixel((x, 0), ink)
        im.putpixel((x, 63), ink)
    return im


def repeat_proof(materials, floor, plane):
    canvas = indexed((192, 192), 1)
    kinds = KINDS[plane]
    for y in range(3):
        for x in range(3):
            name = f'painted_f{floor}_{plane}'
            if x == 1:
                name = f'painted_room_f{floor}_{plane}_{kinds[y]}'
            canvas.paste(materials[name], (x * 64, y * 64))
    folder = BASE / f'floor{floor}'
    save(canvas, folder / f'{plane}_repeat_native.png')
    save(canvas.resize((768, 768), NEAREST), folder / f'{plane}_repeat_4x.png')


def main():
    materials = {}
    registrations = []
    for floor in (1, 2):
        subset = {}
        for plane, kinds in KINDS.items():
            base = base_material(floor, plane)
            name = f'painted_f{floor}_{plane}'
            materials[name] = base
            subset[plane.upper()] = base
            registrations.append({'path': f'assets/art/env/{name}.png', 'floor': floor,
                'plane': plane, 'kind': 'base', 'base': None})
            for kind in kinds:
                name = f'painted_room_f{floor}_{plane}_{kind}'
                materials[name] = decorate(base, f'{plane}_{kind}', floor)
                subset[f'{plane[:1].upper()} / {kind}'] = materials[name]
                registrations.append({'path': f'assets/art/env/{name}.png', 'floor': floor,
                    'plane': plane, 'kind': kind,
                    'base': f'assets/art/env/painted_f{floor}_{plane}.png'})
        folder = BASE / f'floor{floor}'
        folder.mkdir(exist_ok=True)
        contact(subset, folder, columns=4, cell=(128, 98), title=f'FLOOR {floor} / PAINTED PLANES')
        for plane in KINDS:
            repeat_proof(materials, floor, plane)
    for name, image in materials.items():
        save(image, OUT / f'{name}.png')
    contact({name.replace('painted_room_', '').replace('painted_', ''): im for name, im in materials.items()},
        BASE, columns=4, cell=(164, 100), title='UNDERCROFT / THE STONE BELOW AND ABOVE')
    from build_mockups import build_mockups
    previews = build_mockups()
    preview_records = [{'path': p.relative_to(ROOT).as_posix(),
        'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in previews]
    paths = [OUT / f'{name}.png' for name in materials]
    paths += [p for p in BASE.rglob('*.png') if p not in previews and 'sources' not in p.parts]
    manifest(paths, BASE / 'manifest.json', {'preview_files': preview_records,
        'registrations': registrations, 'cell_world_size': 1, 'uv_texels_per_cell': 64,
        'uv': 'U +world X, V +world Y; north = -V. Sample floor(world_coord*64) modulo 64.',
        'ceiling_geometry': 'Painted rib relief on the existing flat plane; no actual curved mesh.',
        'primary_bases': 'painted_f{1,2}_{floor,ceiling}.png',
        'primary_variants': 'painted_room_f{1,2}_{floor|ceiling}_{kind}.png',
        'originals': 'art_src/env/painted_surfaces/preserved_hashes.json'})
    from verify_surfaces import main as verify
    verify()


if __name__ == '__main__':
    main()
