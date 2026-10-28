"""Offline screenshot assembly. Run the m3b_gallery pilot first."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / "build/m3b_shots"
FRAMES = [
    ("Title", "00_title"), ("Corridor", "03_corridor"),
    ("Room", "01_room"), ("Bell Porter", "22_porter_restored"),
    ("Item card", "21_clapper_return_target"), ("Seen map", "05_map"),
    ("A real hit", "06_hurt"), ("Selected PLACE", "04_selected_place"),
]
sheet = Image.new("RGB", (154*4, 362*2), "#0c101c")
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype(str(ROOT / "assets/font/vetka.ttf"), 16)
for index, (label, filename) in enumerate(FRAMES):
    x, y = (index % 4)*154, (index // 4)*362
    draw.text((x+3, y), label, font=font, fill="#d3c8a4", stroke_width=0)
    frame = Image.open(SHOTS / (filename + ".png"))
    sheet.paste(frame.resize((154,342), Image.Resampling.NEAREST), (x,y+20))
sheet.resize((1232,1448), Image.Resampling.NEAREST).save(SHOTS / "m3b_sheet_2x.png")
print(SHOTS / "m3b_sheet_2x.png")
