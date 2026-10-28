"""Real windowed captures plus explicitly labelled future creature previews."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'build/m3c_shots'
FONT = ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)
INK = '#d3c8a4'
BG = '#0c101c'

def preview(name):
    image = Image.new('RGB',(154,342),BG)
    draw = ImageDraw.Draw(image)
    draw.text((4,4),'ASSET PREVIEW',font=FONT,fill=INK)
    for i, pose in enumerate(['idle','windup','recoil']):
        sprite = Image.open(ROOT/f'assets/art/creatures/{name}_{pose}_64.png').convert('RGBA')
        y = 30+i*95
        image.paste(sprite,((154-sprite.width)//2,y),sprite)
        draw.text((4,y+65),pose.upper(),font=FONT,fill=INK)
    draw.text((4,321),'Not in this build.',font=FONT,fill='#eeb95a')
    image.save(OUT/f'preview_{name}.png')

preview('ash_hound')
preview('wick_ghost')
frames = [
    ('Title / audio','00_title'), ('Corridor','03_corridor'),
    ('Room','01_room'), ('Restored Porter','22_porter_restored'),
    ('Slate map','05_map'), ('Item card','21_clapper_return_target'),
    ('Raised fist','32_husk_windup'), ('EDGE strike','33_strike'),
    ('Lever up','30_lever_up'), ('Lever down','31_lever_down'),
    ('Inset / weight','34_plate_stone'), ('Hurt / shudder','06_hurt'),
    ('HEAVY strike','36_strike_heavy'), ('Hands strike','36_strike_hands'),
    ('Hound: art only','preview_ash_hound'), ('Ghost: art only','preview_wick_ghost'),
]
sheet = Image.new('RGB',(154*4,362*4),BG)
draw = ImageDraw.Draw(sheet)
for i, (caption,name) in enumerate(frames):
    frame = Image.open(OUT/(name+'.png')).convert('RGB')
    # Pilots save at 3x; previews are already native.
    if frame.size != (154,342): frame=frame.resize((154,342),Image.Resampling.NEAREST)
    x=(i%4)*154
    y=(i//4)*362
    sheet.paste(frame,(x,y+20))
    draw.text((x+3,y),caption,font=FONT,fill=INK)
sheet.save(OUT/'m3c_sheet_native.png')
sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(OUT/'m3c_sheet_2x.png')
print('16 panels: 14 real captures, 2 labelled asset previews; 2x nearest.')
