"""Native integer pixel drawings, never painted, blurred or antialiased."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from PIL import ImageDraw
from pipeline import ROOT, FONT, canvas, contact, label, manifest, paste, save, strip

BASE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/art/fx'


def edge(frame):
    im = canvas((64, 64)); d = ImageDraw.Draw(im)
    if frame == 0:
        d.line((17, 43, 36, 24), fill=13, width=3)
        d.line((18, 42, 36, 24), fill=17)
    elif frame == 1:
        d.line((10, 51, 52, 9), fill=13, width=3)
        d.line((11, 50, 52, 9), fill=10)
        d.line((13, 51, 49, 15), fill=16)
        d.line((37, 13, 42, 13), fill=9)
        d.line((40, 10, 40, 16), fill=10)
    else:
        for x, y in [(15, 46), (28, 33), (42, 19), (52, 9)]:
            d.line((x, y, x+3, y-3), fill=16)
        d.point((10, 52), fill=8)
    return im


def heavy(frame):
    im = canvas((64, 64)); d = ImageDraw.Draw(im)
    if frame == 0:
        d.rectangle((28, 26, 36, 34), fill=23)
        d.rectangle((30, 28, 34, 32), fill=26)
        d.line((22, 22, 26, 25), fill=9, width=2)
        d.line((38, 36, 42, 40), fill=9, width=2)
    elif frame == 1:
        d.polygon([(32, 10), (36, 24), (47, 17), (41, 28), (55, 31), (41, 35), (48, 46), (36, 39), (32, 54), (28, 39), (16, 46), (23, 35), (9, 31), (23, 28), (17, 17), (28, 24)], fill=22)
        d.polygon([(32, 17), (35, 27), (44, 24), (39, 31), (45, 36), (35, 35), (32, 45), (29, 35), (20, 38), (25, 31), (21, 26), (29, 27)], fill=25)
        d.rectangle((28, 28, 36, 34), fill=10)
    else:
        for box in [(12, 13, 16, 16), (47, 11, 50, 15), (53, 31, 57, 34), (43, 48, 47, 52), (16, 48, 20, 51), (6, 30, 9, 33)]:
            d.rectangle(box, fill=23)
        d.line((25, 24, 29, 27), fill=8, width=2)
        d.line((37, 37, 41, 42), fill=8, width=2)
    return im


def hands(frame):
    im = canvas((64, 64)); d = ImageDraw.Draw(im)
    if frame == 0:
        d.rectangle((29, 28, 34, 33), fill=8)
        d.rectangle((31, 29, 33, 31), fill=10)
    elif frame == 1:
        d.line((22, 30, 27, 30), fill=10, width=2)
        d.line((36, 30, 41, 30), fill=10, width=2)
        d.line((31, 21, 31, 26), fill=10, width=2)
        d.line((31, 35, 31, 40), fill=10, width=2)
        d.rectangle((29, 28, 34, 33), fill=9)
    else:
        for xy in [(19, 27, 21, 29), (42, 32, 44, 34), (30, 17, 32, 19), (30, 42, 32, 44)]:
            d.rectangle(xy, fill=7)
    return im


def damage(frame):
    """Keep x=17..46,y=22..40 free for three native VETKA digits."""
    im = canvas((64, 64)); d = ImageDraw.Draw(im)
    offsets = [(0, 25), (3, 21), (7, 17)]
    expansion, top = offsets[frame]
    ink = [10, 25, 8][frame]
    for x in (13-expansion, 49+expansion):
        d.line((x, top, x-2, top-3), fill=ink)
        d.line((x, 42+expansion//2, x+2, 45+expansion//2), fill=ink)
    d.line((29, top-7, 29, top-4), fill=ink)
    d.line((35, 49+expansion, 35, 51+expansion), fill=ink)
    return im


def main():
    assets = []
    for name, draw in [('edge', edge), ('heavy', heavy), ('hands', hands), ('damage_burst', damage)]:
        frames = [draw(i) for i in range(3)]
        for i, im in enumerate(frames):
            assets.append(save(im, OUT / f'{name}_{i}_64.png'))
        assets.append(save(strip(frames), OUT / f'{name}_strip_64.png'))
        contact(BASE / f'{name}_contact_4x.png', name.upper().replace('_', ' '), [('64 px / 80 ms per frame', [(str(i), im) for i, im in enumerate(frames)])])
    demo = []
    for i in range(3):
        im = damage(i)
        text = str(i+1)
        left = (64-round(FONT.getlength(text)))//2
        label(im, (left+1, 23), text, 1)
        label(im, (left, 22), text, 10)
        demo.append(im)
    contact(BASE / 'damage_vetka_demo_4x.png', 'VETKA 16 PX DIGITS', [('Digits are runtime text', [(str(i), im) for i, im in enumerate(demo)])])
    manifest(BASE / 'manifest.json', {'frames': 3, 'frame_size': [64, 64], 'anchor': [32, 32], 'frame_ms': 80, 'assets': assets})
    print(f'FX: {len(assets)} indexed palette assets')


if __name__ == '__main__':
    main()
