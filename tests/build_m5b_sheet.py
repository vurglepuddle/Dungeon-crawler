from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]/"build/m5b_shots"
panels=[("Room / entry", "01_room_entry"),("Forward room / surveyed","02_room_map"),("Belt stays one key","03_one_belt_icon"),("Metals / door states","04_key_list"),("Iron key + lock","05_iron_lock_key"),("Bronze key + lock","05_bronze_lock_key"),("Gold key + lock","05_gold_lock_key"),("Gold key card","06_gold_card"),("F4 / close light","07_f4_near"),("F4 / far darkness","08_f4_far"),("At a block seam","09_block_seam"),("Across that seam","10_next_block")]
sheet=Image.new("RGB",(4*158,3*364),(12,16,28)); draw=ImageDraw.Draw(sheet)
for i,(label,name) in enumerate(panels):
 x,y=(i%4)*158,(i//4)*364
 draw.text((x+1,y+2),label,fill=(211,200,164))
 frame=Image.open(root/(name+".png")).convert("RGB").resize((154,342),Image.Resampling.NEAREST)
 sheet.paste(frame,(x,y+18))
sheet.save(root/"m5b_sheet_native.png")
sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(root/"m5b_sheet_2x.png")
print("12-panel M5b sheet written.")
