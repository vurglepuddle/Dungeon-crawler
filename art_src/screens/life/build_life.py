"""Registered screen animation: saved paintings -> native light edits -> palette.

Never writes an original plate. Geometry stays in the original pixel clusters;
the edited paintings supply wing shape, extinguished glass and light fields.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'env'))
import hashlib
import json
from PIL import Image, ImageFilter
from pipeline import ROOT, RGB, NEAREST, indexed, reduce, save, contact, label, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/screens'
SOURCE = BASE / 'sources'
WARM = set(range(18, 30)) | {31}


def fitted(source, size):
    w, h = source.size
    tw, th = size
    if w * th > h * tw:
        nw = h * tw // th
        x = (w - nw) // 2
        source = source.crop((x, 0, x + nw, h))
    else:
        nh = w * th // tw
        y = (h - nh) // 2
        source = source.crop((0, y, w, y + nh))
    return source.convert('RGB').resize(size, NEAREST)


def ellipse(x, y, cx, cy, rx, ry):
    return max(0.0, 1.0 - ((x - cx) / rx) ** 2 - ((y - cy) / ry) ** 2)


def luma(rgb):
    return 2 * rgb[0] + 4 * rgb[1] + rgb[2]


def light_fields(kind, edit, size):
    # Blur only a numeric illumination field. Visible art is sampled nearest.
    original = fitted(Image.open(BASE.parent / 'sources' / f'{kind}.png'), size)
    edited = fitted(Image.open(SOURCE / f'{edit}.png'), size)
    return original.filter(ImageFilter.GaussianBlur(4)), edited.filter(ImageFilter.GaussianBlur(4))


def moth_frames():
    original = Image.open(OUT / 'splash.png').copy()
    folded = original.copy()
    emblem = reduce(fitted(Image.open(SOURCE / 'moth_fold.png'), (96, 84)), (96, 84))
    folded.paste(emblem, (29, 5))
    # Key and antennae are the publisher identity: copy their exact old pixels.
    for box in ((73, 30, 82, 73), (62, 14, 92, 32)):
        folded.paste(original.crop(box), box[:2])
    return [original, folded]


def title_frames():
    original = Image.open(OUT / 'title.png').copy()
    before, after = light_fields('title', 'title_low', original.size)
    frames = [original]
    for high in (False, True):
        work = original.convert('RGB')
        for y in range(55, original.height):
            for x in range(original.width):
                strength = max(ellipse(x, y, 100, 100, 22, 24),
                    ellipse(x, y, 88, 115, 48, 25),
                    ellipse(x, y, 135, 103, 18, 33),
                    ellipse(x, y, 47, 99, 33, 25))
                if strength <= 0:
                    continue
                rgb = RGB[original.getpixel((x, y))]
                # Warm lit surfaces respond more than the cool ambient stone.
                strength *= 1.0 if original.getpixel((x, y)) in WARM else 0.35
                ratio = luma(after.getpixel((x, y))) / max(1, luma(before.getpixel((x, y))))
                dim = min(0.25, max(0.17, 1.0 - ratio))
                gain = 1.0 + (dim * 0.65 if high else -dim) * strength
                work.putpixel((x, y), tuple(min(255, round(c * gain)) for c in rgb))
        frames.append(reduce(work, original.size))
    return frames


def win_frames():
    original = Image.open(OUT / 'win.png').copy()
    before, after = light_fields('win', 'win_light', original.size)
    frames = [original]
    for stage in (1, 2):
        work = original.convert('RGB')
        amount = 0.55 if stage == 1 else 1.0
        for y in range(original.height):
            for x in range(original.width):
                rgb = RGB[original.getpixel((x, y))]
                strength = max(ellipse(x, y, 91, 20, 47, 25),
                    ellipse(x, y, 80, 37, 48, 12),
                    ellipse(x, y, 33, 23, 23, 26) * 0.45)
                a, b = before.getpixel((x, y)), after.getpixel((x, y))
                delta = [max(0, min(55, b[c] - a[c])) for c in range(3)]
                target = [min(255, round(rgb[c] + delta[c] * strength * amount)) for c in range(3)]
                # One warm pulse; the final sunlit state settles slightly.
                if 75 <= x <= 100 and 32 <= y <= 54 and original.getpixel((x, y)) in WARM:
                    pulse = 0.25 if stage == 1 else 0.15
                    target = [min(255, round(rgb[c] * (1 + pulse))) for c in range(3)]
                work.putpixel((x, y), tuple(target))
        frame = reduce(work, original.size)
        # The dawn only grows; the Seal can pulse independently below it.
        for y in range(0, 32):
            for x in range(55, 128):
                old, new = frames[-1].getpixel((x, y)), frame.getpixel((x, y))
                if luma(RGB[new]) < luma(RGB[old]):
                    frame.putpixel((x, y), old)
        frames.append(frame)
    return frames


def death_frames():
    original = Image.open(OUT / 'death.png').copy()
    dark_reference = fitted(Image.open(SOURCE / 'death_dark.png'), original.size)
    dark = original.copy()
    cold_inks = (1, 2, 3, 4, 5, 11, 12, 13)
    for y in range(23, 80):
        for x in range(12, 83):
            ink = original.getpixel((x, y))
            if ink not in WARM and ink not in (9, 10):
                continue
            # Recolour lit clusters without resampling their outlines.
            target = dark_reference.getpixel((x, y))
            allowed = [i for i in cold_inks if luma(RGB[i]) <= luma(RGB[ink])]
            pick = min(allowed or [1], key=lambda i: sum(
                weight * (RGB[i][c] - target[c]) ** 2 for c, weight in enumerate((2, 4, 1))))
            dark.putpixel((x, y), pick)
    # The tiny flame is the sole geometry edit, replaced by painted cold glass.
    glass = reduce(dark_reference, original.size)
    flame_box = (43, 39, 49, 48)
    dark.paste(glass.crop(flame_box), flame_box[:2])
    ember_work = original.convert('RGB')
    for y in range(23, 80):
        for x in range(12, 83):
            a, b = RGB[original.getpixel((x, y))], RGB[dark.getpixel((x, y))]
            ember_work.putpixel((x, y), tuple(round(a[c] * 0.18 + b[c] * 0.82) for c in range(3)))
    ember = reduce(ember_work, original.size)
    ember.paste(dark.crop(flame_box), flame_box[:2])
    ember.putpixel((45, 45), 20)
    ember.putpixel((46, 45), 22)
    return [original, ember, dark]


def title_preview(frame):
    im = frame.copy()
    logo = Image.open(OUT / 'logotype_140.png')
    im.paste(logo, (7, 6), logo.convert('RGBA').getchannel('A'))
    return im


def write_previews(sets, sequences):
    names = {'splash': ['0 / OPEN', '1 / FOLD'],
        'title': ['0 / STEADY', '1 / LOW', '2 / WARM'],
        'win': ['0 / FIRST LIGHT', '1 / SEAL PULSE', '2 / DAWN - HOLD'],
        'death': ['0 / FLAME', '1 / EMBER', '2 / DARK - HOLD']}
    overview = indexed((532, 786), 1)
    label(overview, (8, 5), 'UNDERCROFT / A LITTLE LIFE', 25)
    previews = []
    for row, (kind, frames) in enumerate(sets.items()):
        folder = BASE / kind
        folder.mkdir(exist_ok=True)
        art = [title_preview(frame) for frame in frames] if kind == 'title' else frames
        assets = dict(zip(names[kind], art))
        contact(assets, folder, columns=3, cell=(172, 186), title=f'{kind.upper()} / REGISTERED FRAMES')
        label(overview, (8, 34 + row * 186), kind.upper(), 8)
        for column, (name, frame) in enumerate(assets.items()):
            x, y = 8 + column * 172, 52 + row * 186
            overview.paste(frame, (x + (172 - frame.width) // 2, y))
            label(overview, (x, y + 152), name, 8)
        enlarged = [frame.resize((frame.width * 4, frame.height * 4), NEAREST) for frame in art]
        timing = [duration or 2400 for duration in sequences[kind]['durations_ms']]
        options = {'loop': 0} if sequences[kind]['playback'] == 'loop' else {}
        gif = folder / 'preview_4x.gif'
        enlarged[0].save(gif, save_all=True, append_images=enlarged[1:],
            duration=timing, optimize=False, disposal=1, **options)
        previews.append({'path': gif.relative_to(ROOT).as_posix(),
            'sha256': hashlib.sha256(gif.read_bytes()).hexdigest()})
    save(overview, BASE / 'contact_sheet_native.png')
    save(overview.resize((overview.width * 4, overview.height * 4), NEAREST), BASE / 'contact_sheet_4x.png')
    return previews


def main():
    sets = {'splash': moth_frames(), 'title': title_frames(), 'win': win_frames(), 'death': death_frames()}
    suffixes = {'splash': 'flutter', 'title': 'flicker', 'win': 'dawn', 'death': 'gutter'}
    durations = {'splash': [900, 300], 'title': [680, 160, 240], 'win': [500, 650, 0], 'death': [400, 700, 0]}
    sequences = {}
    paths = []
    for kind, frames in sets.items():
        names = []
        for number, frame in enumerate(frames):
            path = OUT / f'{kind}_{suffixes[kind]}_{number}.png'
            save(frame, path)
            paths.append(path)
            names.append('res://' + path.relative_to(ROOT).as_posix())
        sequences[kind] = {'canvas': list(frames[0].size), 'anchor': [0, 0],
            'frames': names, 'durations_ms': durations[kind],
            'playback': 'loop' if kind in ('splash', 'title') else 'once_hold',
            'hold_frame': None if kind in ('splash', 'title') else 2}
    timing = {'schema_version': 1, 'clock': 'elapsed presentation milliseconds; reset on entry',
        'zero_duration': 'Only the last once_hold frame may use 0: hold indefinitely.',
        'sequences': sequences}
    (BASE / 'timings.json').write_text(json.dumps(timing, indent=2) + '\n', encoding='utf-8')
    previews = write_previews(sets, sequences)
    manifest(paths + list(BASE.rglob('*sheet*.png')), BASE / 'manifest.json',
        {'preview_files': previews, 'timings': 'art_src/screens/life/timings.json',
         'originals': json.loads((BASE / 'preserved_hashes.json').read_text()),
         'title_contact_has_separate_logotype': True})
    from verify_life import main as verify
    verify()


if __name__ == '__main__':
    main()
