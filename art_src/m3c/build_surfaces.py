"""Quiet single-piece materials; no runtime dependencies and no tiled fills."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
PALETTE = [tuple(map(int, line.split()[:3])) for line in
           (ROOT / 'art_src/spike/palette.gpl').read_text().splitlines()
           if line.strip() and line.lstrip()[0].isdigit()]
SOURCE = Image.open(HERE / 'slate_source.png').convert('RGB')
OUT = ROOT / 'assets/art/ui'
OUT.mkdir(parents=True, exist_ok=True)

def make(kind, size, offset):
    w, h = size
    # Fit ONE full, nonperiodic source patch. Stable crops vary between panels.
    sw, sh = SOURCE.size
    crop = SOURCE.crop((offset, 0, sw, sh-offset))
    field = ImageOps.fit(crop, size, method=Image.Resampling.BOX).convert('L')
    field = ImageOps.autocontrast(field)
    image = Image.new('RGB', size)
    p = image.load()
    for y in range(h):
        for x in range(w):
            v = field.getpixel((x, y))
            if kind == 'leather':
                index = 1 if v < 145 else (18 if v < 211 else 30)
            elif kind == 'map':
                index = 11 if v < 114 else (12 if v < 235 else 13)
            elif kind == 'card':
                index = 11 if v < 208 else 12
            else:
                index = 1 if v < 99 else (11 if v < 227 else 12)
            p[x, y] = PALETTE[index]
    d = ImageDraw.Draw(image)
    # Native copper casing with a cool enamel inset, muted on text surfaces.
    d.rectangle((0, 0, w-1, h-1), outline=PALETTE[18])
    d.line((1, h-2, w-2, h-2, w-2, 1), fill=PALETTE[1])
    d.line((1, h-3, 1, 1, w-3, 1), fill=PALETTE[28])
    d.line((2, h-3, 2, 2, w-3, 2), fill=PALETTE[13])
    if kind != 'frame':
        for x, y, sx, sy in [(3,3,1,1), (w-4,3,-1,1), (3,h-4,1,-1), (w-4,h-4,-1,-1)]:
            d.line((x, y+sy*3, x, y, x+sx*3, y), fill=PALETTE[28])
            d.point((x, y), fill=PALETTE[29])
    result = Image.new('P', size)
    result.putpalette(sum((list(c) for c in PALETTE), []))
    lookup = {c:i for i,c in enumerate(PALETTE)}
    result.putdata([lookup[c] for c in image.getdata()])
    result.save(OUT / (kind+'.png'))
    return image

panels = [('slate',(154,342),0), ('map',(144,324),79),
          ('card',(146,132),131), ('leather',(154,134),197), ('frame',(154,156),241)]
sheet = Image.new('RGB', (154*len(panels), 342), PALETTE[1])
for i, (kind, size, offset) in enumerate(panels):
    panel = make(kind, size, offset)
    sheet.paste(panel, (154*i, 0))
    assert len(panel.getcolors(100000)) <= 32
sheet.resize((sheet.width*2, sheet.height*2), Image.Resampling.NEAREST).save(HERE/'surfaces_2x.png')
print('5 nonrepeating native surfaces; shared palette, 2x review sheet.')
