"""Shared offline helpers. Only callers' explicitly owned output paths are written."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RGB = []
for line in (ROOT / 'art_src/spike/palette.gpl').read_text().splitlines():
    parts = line.split()
    if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
        RGB.append(tuple(map(int, parts[:3])))
assert len(RGB) == 32
TABLE = [v for color in RGB for v in color] + [0] * (768 - 96)
NEAREST = Image.Resampling.NEAREST
FONT = ImageFont.truetype(str(ROOT / 'assets/font/vetka.ttf'), 16)


def canvas(size, color=0):
    out = Image.new('P', size, color)
    out.putpalette(TABLE)
    out.info['transparency'] = 0
    return out


def reduce(source):
    out = canvas(source.size)
    cache = {}
    data = []
    for r, g, b, a in source.convert('RGBA').getdata():
        if a < 128:
            data.append(0)
            continue
        color = r, g, b
        if color not in cache:
            cache[color] = min(range(1, 32), key=lambda i: 2*(r-RGB[i][0])**2 + 4*(g-RGB[i][1])**2 + (b-RGB[i][2])**2)
        data.append(cache[color])
    out.putdata(data)
    return out


def label(image, xy, text, ink=9):
    draw = ImageDraw.Draw(image)
    draw.fontmode = '1'
    draw.text(xy, text, font=FONT, fill=ink)


def paste(out, sprite, xy):
    out.paste(sprite, xy, sprite.convert('RGBA').getchannel('A'))


def save(image, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    assert image.mode == 'P' and image.getpalette() == TABLE
    assert max(image.getdata()) < 32
    image.save(path, transparency=0, optimize=False)
    return {'path': path.relative_to(ROOT).as_posix(), 'size': list(image.size),
            'opaque_colors': len(set(image.getdata()) - {0}),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def strip(frames):
    assert len(set(frame.size for frame in frames)) == 1
    w, h = frames[0].size
    out = canvas((w * len(frames), h))
    for i, frame in enumerate(frames):
        paste(out, frame, (i*w, 0))
    return out


def contact(path, title, rows):
    """Rows: (caption, [(state, indexed sprite)]). Label at native 16px."""
    width = 384
    height = 32 + sum(max(image.height for _, image in entries) + 42 for _, entries in rows)
    out = canvas((width, height), 1)
    label(out, (8, 4), title, 25)
    y = 30
    for caption, entries in rows:
        label(out, (8, y), caption)
        y += 19
        row_h = max(image.height for _, image in entries)
        step = width // len(entries)
        for i, (state, image) in enumerate(entries):
            paste(out, image, (i*step+(step-image.width)//2, y+row_h-image.height))
            label(out, (i*step+8, y+row_h+2), state)
        y += row_h+23
    native_path = Path(str(path).replace('_4x.png', '_native.png'))
    save(out, native_path)
    enlarged = out.resize((out.width*4, out.height*4), NEAREST)
    save(enlarged, path)
    assert enlarged.resize(out.size, NEAREST).tobytes() == out.tobytes()


def manifest(path, data):
    Path(path).write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
