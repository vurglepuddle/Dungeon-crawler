"""Offline painted bronze -> fixed spike palette, native 32px nine-slice."""
import importlib.util
import sys
from pathlib import Path
from PIL import Image

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
spec = importlib.util.spec_from_file_location("spike", BASE.parent / "spike/build_spike.py")
spike = importlib.util.module_from_spec(spec)
spec.loader.exec_module(spike)
source = Image.open(BASE / "chrome_source.png").convert("RGBA")
native = spike.reduce_palette(source.resize((32, 32), Image.Resampling.NEAREST))
# Keep the recessed bronze quiet: dark source shades use the palette's
# brown shadow, rather than scattered navy patches. Rim colours stay intact.
for y in range(3, 29):
    for x in range(3, 29):
        if native.getpixel((x, y)) in (1, 2, 3, 4, 11, 12, 13, 14):
            native.putpixel((x, y), 18)
native.save(BASE / "chrome_32.png", transparency=0)
native.save(ROOT / "assets/art/chrome_32.png", transparency=0)
native.resize((256, 256), Image.Resampling.NEAREST).save(BASE / "chrome_contact_8x.png", transparency=0)
print("Chrome: 32x32, shared 32-entry palette, nearest scaling")
