"""Native real-tap captures; one clearly labelled historical comparison."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/m4a_shots'
FONT=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)
frames=[
 ('Pocket torch / LIGHT','m4a_shots','01_pocket_torch_light'),
 ('Brazier touched / lit','m4a_shots','02_torch_lit_by_tap'),
 ('Equipped / BURN','m4a_shots','03_equipped_torch_burn'),
 ('Web touched / burning','m4a_shots','04_tap_burning_web'),
 ('Far travel face','m4a_shots','05_distant_stair'),
 ('Step closer / free','m4a_shots','06_step_closer'),
 ('Near stairs / touch','m4a_shots','07_stair_in_reach'),
 ('Tap reaches next floor','m4a_shots','08_stair_tap_arrival'),
 ('M3f stone / before','m3f_shots','01_upper_materials'),
 ('Painted items / now','m4a_shots','18_world_items_entry'),
 ('Stone / real floor art','m4a_shots','19_world_stone_near'),
 ('Supplies on the floor','m4a_shots','20_items_room_0'),
 ('The Lower Watch','m4a_shots','09_lower_watch_entry'),
 ('Deep Continue / fresh','m4a_shots','10_deep_continue'),
 ('A two-point tell','m4a_shots','11_deep_two_point_tell'),
 ('Coat catches the hit','m4a_shots','12_padding_catches_blow'),
 ('Spent coat / dropped','m4a_shots','13_spent_coat_on_floor'),
 ('Food settles deep jaws','m4a_shots','14_deep_hound_fed'),
 ('Seal on floor three','m4a_shots','15_third_floor_seal'),
 ('Lower watch / map','m4a_shots','16_watch_map'),
]
sheet=Image.new('RGB',(154*4,362*5),'#0c101c'); draw=ImageDraw.Draw(sheet)
for i,(caption,directory,name) in enumerate(frames):
    path=ROOT/'build'/directory/(name+'.png')
    if not path.exists() and directory=='m3f_shots': continue
    frame=Image.open(path).convert('RGB').resize((154,342),Image.Resampling.NEAREST)
    x=i%4*154; y=i//4*362
    sheet.paste(frame,(x,y+20)); draw.text((x+2,y),caption,font=FONT,fill='#d3c8a4')
sheet.save(OUT/'m4a_sheet_native.png')
sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(OUT/'m4a_sheet_2x.png')
print('20 actual gameplay panels, native and 2x; final win capture is 17_deeper_home.png.')
