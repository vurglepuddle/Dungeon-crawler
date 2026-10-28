"""Pair actual Godot frames. Gallery samples are explicit renderer fixtures."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]/'build/m4b_shots'
BG=(12,16,28); INK=(211,200,164)
def native(phase,name):
 return Image.open(ROOT/phase/(name+'.png')).convert('RGB').resize((154,342),Image.Resampling.NEAREST)
def sheet(names,out,pairs_per_row=2,full=False):
 height=342 if full else 156
 w=312*pairs_per_row; h=((len(names)+pairs_per_row-1)//pairs_per_row)*(height+30)
 canvas=Image.new('RGB',(w,h),BG); draw=ImageDraw.Draw(canvas)
 for i,name in enumerate(names):
  x=(i%pairs_per_row)*312;y=(i//pairs_per_row)*(height+30)
  draw.text((x+2,y),name.replace('_',' '),fill=INK)
  for j,phase in enumerate(['before','after']):
   draw.text((x+j*156+2,y+12),phase,fill=(115,162,154))
   im=native(phase,name)
   if not full: im=im.crop((0,18,154,174))
   canvas.paste(im,(x+j*156,y+26))
 canvas.save(ROOT/(out+'_native.png'))
 canvas.resize((w*2,h*2),Image.Resampling.NEAREST).save(ROOT/(out+'_2x.png'))
main=['f1_tapestry','f2_chains','f1_lock_closed','f2_lock_open','f1_plate_down','f2_plate_up','f1_lever_side','f2_lever_front','web_intact','web_burning_1','cord_intact','cord_cut','f1_lift_approach','f2_lift_approach','f1_stairs_top','f2_stairs_top','cache_open','f2_room','hound_embers','web_burnt']
sheet(main,'m4b_sheet',4)
sheet([f'f{f}_{name}' for name in ['drain','chains','tapestry','crack','damp','sconce_0','sconce_1'] for f in [1,2]],'m4b_dressings')
sheet([f'f{f}_{name}' for f in [1,2] for name in ['lift_dead_underfoot','lift_working_underfoot','lift_approach','stairs_top']],'m4b_ground')
sheet(['spent_coat_pack','f1_plate_down'],'m4b_inventory',1,True)
print('Four comparison sheets; before/after actual Godot samples, nearest scaling.')
