"""Verify production contracts and composited-review scaling without Godot."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from pipeline import ROOT, TABLE, NEAREST

BASE = Path(__file__).resolve().parent


def main():
    manifest = json.loads((BASE / 'hands_manifest.json').read_text())
    seen = set()
    for relative, expected in manifest['sources'].items():
        assert hashlib.sha256((ROOT/relative).read_bytes()).hexdigest() == expected, relative
    for record in manifest['assets']:
        path = ROOT / record['path']
        assert record['path'] not in seen, path
        seen.add(record['path'])
        assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'], path
        with Image.open(path) as image:
            assert list(image.size) == record['size'], path
            assert image.mode == 'P' and image.getpalette() == TABLE, path
            assert image.info.get('transparency') == 0, path
            assert max(image.getdata()) < 32 and image.getbbox(), path
            assert set(image.convert('RGBA').getchannel('A').getdata()) == {0,255}, path
            assert len(set(image.getdata()) - {0}) == record['opaque_colors'], path
            if 'frame_order' in record:
                states = record['frame_order']
                assert image.size == (48*len(states), 56), path
                for i,state in enumerate(states):
                    frame_path = path.with_name(path.name.replace('strip',state))
                    with Image.open(frame_path) as frame:
                        assert image.crop((48*i,0,48*(i+1),56)).tobytes() == frame.tobytes(), path
            else:
                assert image.size == (48,56), path
                assert list(image.getbbox()) == record['opaque_bounds'], path
                assert record['view_position'] == [100,94] and record['anchor'] == [48,56], path
                assert image.crop((0,55,48,56)).getbbox(), 'Sleeve must meet bottom crop'
    for kind in ['torch_lit','seal']:
        with Image.open(ROOT/f'assets/art/hands/hand_{kind}_a_56.png') as a, \
             Image.open(ROOT/f'assets/art/hands/hand_{kind}_b_56.png') as b:
            assert a.tobytes() != b.tobytes(), kind
            # No wrist/sleeve motion in passive flicker or pulse.
            assert a.crop((0,36,48,56)).tobytes() == b.crop((0,36,48,56)).tobytes(), kind
            if kind == 'seal':
                assert a.convert('RGBA').getchannel('A').tobytes() == b.convert('RGBA').getchannel('A').tobytes()
    contacts = 0
    for path in BASE.glob('*_4x.png'):
        with Image.open(path) as scaled, Image.open(path.with_name(path.name.replace('_4x','_native'))) as native:
            assert scaled.size == (native.width*4,native.height*4), path
            assert scaled.getpalette() == TABLE and native.getpalette() == TABLE, path
            assert scaled.tobytes() == native.resize(scaled.size,NEAREST).tobytes(), path
        contacts += 1
    assert len(list(BASE.glob('*_mockup_4x.png'))) == 11
    print(f'Hands verified: {len(seen)} runtime PNGs; {contacts} exact 4x review sheets; palette, alpha, hashes, strips, crop and passive-frame stability')


if __name__ == '__main__':
    main()
