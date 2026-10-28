"""Check painted plane boundaries and screenshot framing without Godot."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hashlib
import json
from PIL import Image
from pipeline import ROOT, RGB, TABLE, NEAREST

BASE = Path(__file__).resolve().parent


def luma(im):
    return sum(2 * RGB[i][0] + 4 * RGB[i][1] + RGB[i][2] for i in im.getdata())


def main():
    receipt = json.loads((BASE / 'preserved_hashes.json').read_text())
    for name, digest in receipt.items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest, name
    data = json.loads((BASE / 'manifest.json').read_text())
    assert len(data['registrations']) == 16
    ring = ((0, 0, 64, 2), (0, 62, 64, 64), (0, 0, 2, 64), (62, 0, 64, 64))
    for registration in data['registrations']:
        image = Image.open(ROOT / registration['path'])
        assert image.mode == 'P' and image.size == (64, 64) and image.getpalette() == TABLE
        assert 0 not in set(image.getdata()) and max(image.getdata()) < 32
        assert image.crop((0, 0, 1, 64)).tobytes() == image.crop((63, 0, 64, 64)).tobytes()
        assert image.crop((0, 0, 64, 1)).tobytes() == image.crop((0, 63, 64, 64)).tobytes()
        if registration['base']:
            base = Image.open(ROOT / registration['base'])
            assert image.tobytes() != base.tobytes()
            for box in ring:
                assert image.crop(box).tobytes() == base.crop(box).tobytes(), registration
    for plane in ('floor', 'ceiling'):
        dry = Image.open(ROOT / f'assets/art/env/painted_f1_{plane}.png')
        wet = Image.open(ROOT / f'assets/art/env/painted_f2_{plane}.png')
        assert luma(wet) < luma(dry), plane
    for floor in (1, 2):
        floor_image = Image.open(ROOT / f'assets/art/env/painted_f{floor}_floor.png')
        inner = floor_image.crop((8, 8, 56, 56))
        boundary = floor_image.crop((0, 0, 64, 1))
        assert luma(boundary) / 64 < luma(inner) / (48 * 48) * 0.65
        for kind in ('corridor', 'room'):
            source_name = '03_corridor' if kind == 'corridor' else '01_room'
            source = Image.open(BASE / 'sources' / f'{source_name}.png').convert('RGBA').resize((154, 342), NEAREST)
            screen = Image.open(BASE / f'mockup_f{floor}_{kind}_native.png')
            for box in ((0, 0, 154, 21), (0, 171, 154, 342), (0, 21, 3, 171), (151, 21, 154, 171)):
                assert source.crop(box).tobytes() == screen.crop(box).tobytes(), (floor, kind, box)
    for native in BASE.rglob('*native.png'):
        with Image.open(native) as a, Image.open(native.with_name(native.name.replace('native', '4x'))) as b:
            assert b.size == (a.width * 4, a.height * 4)
            assert a.resize(b.size, NEAREST).tobytes() == b.tobytes()
    print(f'Painted planes verified: 16 opaque 64px textures; matching edges/rings; readable cell joints; darker wet level; preserved mock-up chrome; {len(receipt)} old C PNGs unchanged.')


if __name__ == '__main__':
    main()
