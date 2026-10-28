"""Actual muted windowed captures, nearest-neighbour native and 2x sheets."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/m3e_shots'
FONT=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)
stats=json.loads((ROOT/'tests/pilot/m3e_expected.json').read_text())
frames=[
    ('Brazier / lit reeds','01_brazier_torch'),('Burning web','02_burning_web'),
    ('Hound: wind-up','03_hound_windup'),('TOSS preview','04_toss_preview'),
    ('Fed / peaceful','05_hound_fed'),('Ghost / held GLOW','06_ghost_before'),
    ('Wick dispelled','07_ghost_dispelled'),('Dawn finds a scar','08_seal_reveals_panel'),
    ('The hidden cache','09_secret_open'),('Dawn held up','12_seal_held'),
    ('Cache retrieved','13_cache_taken'),(f'Tour / {stats["gallery_turns"]} turns','14_tour_won'),
    ('Two-cell lunge','10_hound_adjacent_lane'),('A safe side step','11_hound_dodged'),
    ('Lit + fed, continued','16_lit_fed_continued'),('Blocked stair / SIDLE','17_blocked_stair_sidle'),
    ('Clear arrival','18_safe_arrival'),('Knife / entry room','00_entry'),
    ('Restored Porter','22_porter_restored'),('Working lift','25_lift_before_ride'),
]
sheet=Image.new('RGB',(154*4,362*5),'#0c101c')
draw=ImageDraw.Draw(sheet)
for i,(caption,name) in enumerate(frames):
    x=i%4*154; y=i//4*362
    capture=Image.open(OUT/(name+'.png')).convert('RGB').resize((154,342),Image.Resampling.NEAREST)
    sheet.paste(capture,(x,y+20)); draw.text((x+2,y),caption,font=FONT,fill='#d3c8a4')
sheet.save(OUT/'m3e_sheet_native.png')
sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(OUT/'m3e_sheet_2x.png')
print('20 panels from actual muted windowed pilots; native and 2x sheets saved.')
