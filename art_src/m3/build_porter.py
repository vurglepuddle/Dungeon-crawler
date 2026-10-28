"""Offline derivative pipeline; preserves the painting, shares R1's 32 entries."""
import importlib.util
import sys
sys.dont_write_bytecode = True
from pathlib import Path
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
spec = importlib.util.spec_from_file_location("spike", BASE.parent / "spike/build_spike.py")
spike = importlib.util.module_from_spec(spec)
spec.loader.exec_module(spike)
source, bounds = spike.sprite_crop(Image.open(BASE / "porter_source.png"))
sheet = Image.new("RGB", (240, 100), "#0c101c")
draw = ImageDraw.Draw(sheet)
for index, height in enumerate((64, 40, 24)):
    sprite = spike.at_height(source, height)
    sprite.save(BASE / f"porter_{height}.png", transparency=0)
    sprite.save(ROOT / f"assets/art/porter_{height}.png", transparency=0)
    sheet.paste(sprite.convert("RGBA"), (index * 80 + (80-sprite.width)//2, 72-height), sprite.convert("RGBA"))
    draw.text((index*80+22, 82), f"{height} px", fill="#d3c8a4")
sheet.resize((960, 400), Image.Resampling.NEAREST).save(BASE / "porter_contact_4x.png")
print("Porter: 64/40/24, binary alpha, shared palette; crop", bounds)
