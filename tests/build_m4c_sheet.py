"""Actual Godot captures, plus exact-pixel checks for the owner's overlay."""
from pathlib import Path
import json
import shutil
from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / 'build/m4c_shots'
BG, INK, ACCENT = (12, 16, 28), (211, 200, 164), (115, 162, 154)


def native(path):
    return Image.open(path).convert('RGB').resize((154, 342), Image.Resampling.NEAREST)


for name in ['01_lock_closed', '02_lock_open_same_plane', '03_dawn_revealed_scar',
             '04_held_knife_pry', '05_tapped_open_cache']:
    dest = ROOT / (name + '.png')
    fallback = REPO / 'build/m4c_regression_shots' / dest.name
    if not dest.exists() and fallback.exists():
        shutil.copyfile(fallback, dest)

idle = native(ROOT / 'after/overlay_idle.png')
config = json.loads((REPO / 'data/ui/overlay_glints.json').read_text())
report = {'glints': [], 'candle': {}}
for index, skull in enumerate(config['skulls']):
    flare = native(ROOT / f'after/overlay_flare_{index}.png')
    differences = {(x, y) for y in range(342) for x in range(154)
                   if idle.getpixel((x, y)) != flare.getpixel((x, y))}
    expected = {tuple(point) for point in skull['sockets']}
    assert differences == expected, (skull['id'], differences, expected)
    for point in expected:
        assert idle.getpixel(point) == (76, 133, 133), point
        assert flare.getpixel(point) == (168, 194, 173), point
    report['glints'].append({'skull': skull['id'], 'changed_pixels': sorted(differences),
                             'exact_match': True})

candle = native(ROOT / 'after/candle_frame_1.png')
differences = {(x, y) for y in range(342) for x in range(154)
               if idle.getpixel((x, y)) != candle.getpixel((x, y))}
assert differences and all(148 <= x < 154 and 155 <= y < 161 for x, y in differences), differences
report['candle'] = {'changed_pixels': sorted(differences), 'only_flame': True}
(ROOT / 'overlay_pixel_checks.json').write_text(json.dumps(report, indent=2) + '\n')

panels = [
    ('Door closed / real taps', ROOT / '01_lock_closed.png'),
    ('Door opened / same plane', ROOT / '02_lock_open_same_plane.png'),
    ('Card above vines', ROOT / 'after/card_vines.png'),
    ('Rare eye flare / frozen sample', ROOT / 'after/overlay_flare_0.png'),
]
for name in ['corridor', 'room', 'door_closed', 'door_open']:
    for phase in ['before', 'after']:
        panels.append((f'F3 {name.replace("_", " ")} / {phase}',
                       ROOT / phase / f'f3_{name}.png'))

columns, pitch, row_height = 4, 158, 365
width, height = columns * pitch, 3 * row_height + 94
sheet = Image.new('RGB', (width, height), BG)
draw = ImageDraw.Draw(sheet)
for i, (label, path) in enumerate(panels):
    x, y = (i % columns) * pitch, (i // columns) * row_height
    draw.text((x + 2, y + 2), label, fill=INK)
    sheet.paste(native(path), (x, y + 19))

# Full screens show context; magnified pairs make the one-pixel change reviewable.
y = 3 * row_height
for i, skull in enumerate(config['skulls']):
    x = i * pitch
    draw.text((x + 2, y), skull['id'] + ' eyes: idle / flare', fill=ACCENT)
    points = skull['sockets']
    left, top = min(p[0] for p in points) - 1, min(p[1] for p in points) - 2
    box = (max(0, left), max(0, top), min(154, max(p[0] for p in points) + 2),
           min(342, top + 5))
    for j, im in enumerate([idle, native(ROOT / f'after/overlay_flare_{i}.png')]):
        crop = im.crop(box)
        crop = crop.resize((crop.width * 7, crop.height * 7), Image.Resampling.NEAREST)
        sheet.paste(crop, (x + j * 76 + 2, y + 18))
draw.text((2, height - 23), 'F3 pairs: accepted M4b pack / M4c. Other gallery frames are authored renderer samples.', fill=INK)
draw.text((2, height - 12), 'Eye checks: exactly the two configured pixels per skull. Candle: flame pixels only.', fill=ACCENT)
sheet.save(ROOT / 'm4c_sheet_native.png')
sheet.resize((width * 2, height * 2), Image.Resampling.NEAREST).save(ROOT / 'm4c_sheet_2x.png')
print('M4c sheet written; four exact socket-pair checks and candle flame check passed.')
