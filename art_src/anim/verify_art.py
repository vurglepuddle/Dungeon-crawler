"""Validate manifest hashes, palette contracts, frame strips and 4x contacts."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
from pathlib import Path
from PIL import Image
from pipeline import ROOT, TABLE, NEAREST

SOURCES = [ROOT / 'art_src/anim', ROOT / 'art_src/creatures', ROOT / 'art_src/fx', ROOT / 'art_src/fixtures']


def main():
    assets = []
    for folder in SOURCES:
        for path in folder.glob('*manifest.json'):
            assets.extend(json.loads(path.read_text())['assets'])
    seen = set()
    for record in assets:
        path = ROOT / record['path']
        assert record['path'] not in seen, path
        seen.add(record['path'])
        assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'], path
        with Image.open(path) as im:
            assert list(im.size) == record['size'], path
            assert im.mode == 'P' and im.getpalette() == TABLE, path
            assert im.info.get('transparency') == 0 and max(im.getdata()) < 32, path
            assert set(im.convert('RGBA').getchannel('A').getdata()) <= {0, 255}, path
            assert len(set(im.getdata())-{0}) == record['opaque_colors'], path
            assert im.getbbox(), path
            if '_strip_' in path.name:
                states = record.get('frame_order', [str(i) for i in range(3)] if path.parent.name == 'fx' else ['idle', 'windup', 'recoil'])
                w = im.width//len(states)
                assert w*len(states) == im.width
                if 'frame_size' in record: assert record['frame_size'] == [w,im.height], path
                for i,state in enumerate(states):
                    stem, height = path.stem.rsplit('_strip_', 1)
                    frame_path = path.with_name(f'{stem}_{state}_{height}.png')
                    with Image.open(frame_path) as frame:
                        assert im.crop((i*w, 0, (i+1)*w, im.height)).tobytes() == frame.tobytes(), path
    contacts = 0
    for folder in SOURCES:
        for path in folder.glob('*_4x.png'):
            native_path = path.with_name(path.name.replace('_4x.png', '_native.png'))
            if not native_path.exists():
                continue
            with Image.open(path) as scaled, Image.open(native_path) as native:
                assert scaled.size == (native.width*4, native.height*4), path
                assert scaled.getpalette() == TABLE and native.getpalette() == TABLE, path
                assert scaled.tobytes() == native.resize(scaled.size, NEAREST).tobytes(), path
            contacts += 1
    print(f'Art: {len(assets)} runtime PNGs; {contacts} exact 4x contacts; hashes, sizes, shared palette, binary alpha and strip frames verified')


if __name__ == '__main__':
    main()
