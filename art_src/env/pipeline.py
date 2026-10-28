"""Shared offline polish helpers. Python + Pillow; never imported by the game."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
NEAREST = Image.Resampling.NEAREST
RGB = []
for line in (ROOT / 'art_src/spike/palette.gpl').read_text().splitlines():
    parts = line.split()
    if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
        RGB.append(tuple(map(int, parts[:3])))
assert len(RGB) == 32
TABLE = [v for rgb in RGB for v in rgb] + [0] * (768 - 96)

def indexed(size, ink=0):
    im = Image.new('P', size, ink)
    im.putpalette(TABLE)
    im.info['transparency'] = 0
    return im

def reduce(source, size):
    source = source.convert('RGBA').resize(size, NEAREST)
    result = indexed(size)
    cache = {}
    data = []
    for r, g, b, a in source.getdata():
        if a < 128:
            data.append(0)
            continue
        key = (r, g, b)
        if key not in cache:
            cache[key] = min(range(1, 32), key=lambda i:
                2*(r-RGB[i][0])**2 + 4*(g-RGB[i][1])**2 + (b-RGB[i][2])**2)
        data.append(cache[key])
    result.putdata(data)
    return result

def save(im, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    assert im.mode == 'P' and im.getpalette() == TABLE
    assert max(im.getdata()) < 32
    im.save(path, transparency=0, optimize=False)

def label(canvas, xy, text, ink=9):
    d = ImageDraw.Draw(canvas)
    d.fontmode = '1'
    font = ImageFont.truetype(str(ROOT / 'assets/font/vetka.ttf'), 16)
    d.text(xy, text, font=font, fill=ink)

def contact(assets, base, columns=4, cell=(140, 102), title='UNDERCROFT'):
    """Asset names label their cells; all previews retain integer pixel scales."""
    rows = (len(assets)+columns-1)//columns
    canvas = indexed((columns*cell[0]+16, rows*cell[1]+42), 1)
    label(canvas, (8, 5), title, 25)
    for i, (name, im) in enumerate(assets.items()):
        x, y = 8+(i%columns)*cell[0], 34+(i//columns)*cell[1]
        scale = 1
        assert im.width <= cell[0]-8 and im.height <= cell[1]-28
        preview = im.resize((im.width*scale, im.height*scale), NEAREST)
        canvas.paste(preview, (x+(cell[0]-preview.width)//2, y), preview.convert('RGBA').getchannel('A'))
        label(canvas, (x+2, y+cell[1]-23), name, 8)
    save(canvas, Path(base)/'contact_sheet_native.png')
    save(canvas.resize((canvas.width*4, canvas.height*4), NEAREST), Path(base)/'contact_sheet_4x.png')

def manifest(paths, path, extra=None):
    records = []
    union = set()
    for p in sorted(map(Path, paths)):
        with Image.open(p) as im:
            assert im.mode == 'P' and im.getpalette() == TABLE, p
            colours = set(im.convert('RGBA').getdata())
            assert {c[3] for c in colours} <= {0, 255}
            union |= colours
            records.append({'path': p.relative_to(ROOT).as_posix(), 'size':list(im.size),
                'opaque_bounds':im.convert('RGBA').getchannel('A').getbbox(),
                'colours':len(colours), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    assert len(union) <= 32
    sources = [{'path':p.relative_to(ROOT).as_posix(), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in sorted((Path(path).parent/'sources').glob('*.png'))]
    value = {'palette':'art_src/spike/palette.gpl', 'colours_union':len(union), 'files':records, 'sources':sources}
    value.update(extra or {})
    Path(path).write_text(json.dumps(value, indent=2)+'\n')
