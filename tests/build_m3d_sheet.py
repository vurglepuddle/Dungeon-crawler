"""Only actual windowed captures; nearest-neighbour native/2x sheets."""
from pathlib import Path
from PIL import Image, ImageFont, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/m3d_shots'
FONT=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)
def native(path):
    return Image.open(path).convert('RGB').resize((154,342),Image.Resampling.NEAREST)
sparkles=list(OUT.glob('sparkle_*.png'))
assert sparkles
# The selected pressure plate's actual cue occupies this native ROI. Choose
# the brightest observed burst from a full 2.2s cadence, not a painted overlay.
best=max(sparkles,key=lambda p:sum(sum(pixel) for pixel in native(p).crop((100,118,113,131)).getdata()))
native(best).save(OUT/'20_glint_selected.png')
frames=[
    ('LOST MOTH splash','00_splash'),('Painted title','01_title'),
    ('Dressed corridor','06_corridor_gate_open'),('Room / surfaces','02_room'),
    ('Exit in masonry','04_exit_arch'),('Down-stair arch','07_stairs_down'),
    ('Closed grate','12_gate_closed'),('Open passage','06_corridor_gate_open'),
    ('Dead lift','05_lift_dead'),('Working lift','10_lift_working'),
    ('Target sparkle','20_glint_selected'),('Ink / dashes / ?','09_ink_map'),
    ('Rail / icons','02_room'),('Hurt: 3 HP','14_hurt_face'),
    ('Near death: 1 HP','15_near_death_face'),('Death plate','16_death_plate'),
    ('Win plate','11_win_plate'),('Up-stair arch','19_stairs_up'),
    ('Provenance card','08_item_card'),('Survey continued','18_survey_continued'),
]
sheet=Image.new('RGB',(154*4,362*5),'#0c101c')
draw=ImageDraw.Draw(sheet)
for i,(caption,name) in enumerate(frames):
    x=(i%4)*154; y=(i//4)*362
    sheet.paste(native(OUT/(name+'.png')),(x,y+20))
    draw.text((x+3,y),caption,font=FONT,fill='#d3c8a4')
sheet.save(OUT/'m3d_sheet_native.png')
sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(OUT/'m3d_sheet_2x.png')
print('20 real capture panels; selected sparkle:',best.name)
