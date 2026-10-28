"""Focused asset/registration/timing checks. No Godot process or game changes."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'env'))
import hashlib
import json
from PIL import Image
from pipeline import ROOT, RGB, TABLE, NEAREST

BASE = Path(__file__).resolve().parent


def luminance(ink):
    r, g, b = RGB[ink]
    return 2 * r + 4 * g + b


def frame_at(sequence, elapsed_ms):
    assert elapsed_ms >= 0
    durations = sequence['durations_ms']
    if sequence['playback'] == 'loop':
        elapsed_ms %= sum(durations)
    for index, duration in enumerate(durations):
        if duration == 0 or elapsed_ms < duration:
            return index
        elapsed_ms -= duration
    raise AssertionError('A once_hold sequence must finish with an indefinite hold')


def main():
    data = json.loads((BASE / 'timings.json').read_text())
    receipt = json.loads((BASE / 'preserved_hashes.json').read_text())
    external_changes = []
    for name, digest in receipt.items():
        actual = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
        if name.startswith('assets/icon/'):
            # Claude owns launcher selection and is changing it concurrently.
            if actual != digest:
                external_changes.append(name)
            continue
        assert actual == digest, name
    sets = {}
    count = 0
    for kind, sequence in data['sequences'].items():
        frames = [Image.open(ROOT / name.removeprefix('res://')) for name in sequence['frames']]
        assert 2 <= len(frames) <= 3 and len(frames) == len(sequence['durations_ms'])
        assert len({frame.tobytes() for frame in frames}) == len(frames), kind
        assert sequence['anchor'] == [0, 0]
        original = Image.open(ROOT / f'assets/art/screens/{kind}.png')
        assert frames[0].tobytes() == original.tobytes(), kind
        for frame in frames:
            assert list(frame.size) == sequence['canvas'] == list(original.size)
            assert frame.mode == 'P' and frame.getpalette() == TABLE
            assert set(frame.getdata()) <= set(range(1, 32)) # Fully opaque plates.
        durations = sequence['durations_ms']
        assert frame_at(sequence, 0) == 0
        cursor = 0
        for index, duration in enumerate(durations):
            assert frame_at(sequence, cursor) == index
            if duration:
                assert frame_at(sequence, cursor + duration - 1) == index
                cursor += duration
        if sequence['playback'] == 'loop':
            assert all(duration > 0 for duration in durations)
            assert frame_at(sequence, cursor) == 0
            assert frame_at(sequence, cursor * 1000) == 0
        else:
            assert durations[-1] == 0 and sequence['hold_frame'] == len(frames) - 1
            assert frame_at(sequence, 86_400_000) == len(frames) - 1
        sets[kind] = frames
        count += len(frames)
    for frame in sets['splash'][1:]:
        for box in ((0, 89, 154, 150), (73, 30, 82, 73), (62, 14, 92, 32)):
            assert frame.crop(box).tobytes() == sets['splash'][0].crop(box).tobytes(), box
    for frame in sets['title'][1:]:
        assert frame.crop((0, 0, 154, 55)).tobytes() == sets['title'][0].crop((0, 0, 154, 55)).tobytes()
    dawn = [sum(luminance(i) for i in frame.crop((55, 0, 128, 32)).getdata()) for frame in sets['win']]
    assert dawn[0] < dawn[1] < dawn[2], dawn
    seal = [sum(luminance(i) for i in frame.crop((75, 32, 101, 55)).getdata()) for frame in sets['win']]
    assert seal[1] > seal[2] > seal[0], seal
    lamp = [sum(luminance(i) for i in frame.crop((86, 90, 114, 120)).getdata()) for frame in sets['title']]
    assert lamp[1] < lamp[0] < lamp[2], lamp
    darkness = [sum(luminance(i) for i in frame.crop((12, 23, 83, 80)).getdata()) for frame in sets['death']]
    assert darkness[0] > darkness[1] > darkness[2], darkness
    assert not set(sets['death'][2].crop((43, 39, 49, 48)).getdata()) & {10, 24, 25, 26}
    for kind in sets:
        with Image.open(BASE / kind / 'preview_4x.gif') as gif:
            assert gif.n_frames == len(sets[kind]), kind
            assert ('loop' in gif.info) == (kind in ('splash', 'title')), kind
            for index, duration in enumerate(data['sequences'][kind]['durations_ms']):
                gif.seek(index)
                assert gif.info['duration'] == (duration or 2400), kind
    for native in BASE.rglob('*native.png'):
        with Image.open(native) as a, Image.open(native.with_name(native.name.replace('native', '4x'))) as b:
            assert b.size == (a.width * 4, a.height * 4)
            assert a.resize(b.size, NEAREST).tobytes() == b.tobytes()
    owned_count = sum(not name.startswith('assets/icon/') for name in receipt)
    print(f'Life verified: {count} opaque frames; 2/3 per set; fixed type/key/logo area; growing dawn; fading lamp; loop/hold boundaries; {owned_count} old C PNGs unchanged.')
    if external_changes:
        print(f'Outside C ownership: {len(external_changes)} launcher PNGs changed since snapshot; not overwritten or restored.')


if __name__ == '__main__':
    main()
