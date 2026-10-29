"""Small sheet of real-tap Godot captures; exact nearest-neighbour scaling."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / 'build/m5a_shots'
PANELS = [
    ('Abbey / before the Fall', '01_abbey_seal'),
    ('The Fall / shake placeholder', '02_the_fall'),
    ('Below / waking card', '03_waking_card'),
    ('Persistent skip choice', '04_start_choices'),
    ('Seal-woken passage', '09_woken_passage'),
    ('Explored Deep / panned map', '17_sprawling_map_panned'),
    ('Death / wake, no reset', '11_death_wake'),
    ('Dropped pack recovered', '12_pack_recovered'),
    ('The Winding / working lift', '13_the_winding'),
    ('Dawn / existing ending', '14_dawn'),
]
sheet = Image.new('RGB', (5 * 158, 2 * 364), (12, 16, 28))
draw = ImageDraw.Draw(sheet)
for i, (label, name) in enumerate(PANELS):
    x, y = (i % 5) * 158, (i // 5) * 364
    draw.text((x + 1, y + 2), label, fill=(211, 200, 164))
    frame = Image.open(ROOT / (name + '.png')).convert('RGB')
    frame = frame.resize((154, 342), Image.Resampling.NEAREST)
    sheet.paste(frame, (x, y + 18))
sheet.save(ROOT / 'm5a_sheet_native.png')
sheet.resize((sheet.width * 2, sheet.height * 2), Image.Resampling.NEAREST).save(ROOT / 'm5a_sheet_2x.png')
print('M5a real-tap sheet written.')
