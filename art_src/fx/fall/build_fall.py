"""Three deliberately coarse screen-space crumble poses; Pillow, no Godot.

Stone fragments reuse the accepted Lower Watch painted floor. Cracks, binary
dust and motion silhouettes are drawn at the actual 148x150 view resolution.
"""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
import hashlib
import json
from PIL import Image, ImageDraw
from pipeline import ROOT, TABLE, NEAREST, indexed, label, save, manifest

BASE = Path(__file__).resolve().parent
OUT = ROOT/'assets/art/fx'
SIZE = (148,150)


def fragment(canvas,points,texture,offset=(0,0),shade=0):
    area = Image.new('L',SIZE); ImageDraw.Draw(area).polygon(points,fill=255)
    material = indexed(SIZE)
    for y in range(150):
        for x in range(148):
            i = texture.getpixel(((x+offset[0])%64,(y+offset[1])%64))
            # Grey chipped stone, no warm rim that would read as an explosion.
            i = {27:4,28:5,29:6,30:3,8:7,9:7,10:8}.get(i,i)
            if shade: i = {4:3,5:4,6:5,7:6,8:6}.get(i,i)
            material.putpixel((x,y),i)
    canvas.paste(material,(0,0),area)
    d = ImageDraw.Draw(canvas); d.line(points+[points[0]],fill=2,width=1)
    d.line(points[:2],fill=6 if not shade else 4,width=1)


def cracks(canvas,wide=False):
    d = ImageDraw.Draw(canvas)
    lines = [([(73,149),(69,139),(77,129),(71,118),(76,107),(73,96)],1),
             ([(69,139),(52,135),(38,129),(29,120)],1),
             ([(77,129),(92,126),(105,133),(123,139),(139,148)],1),
             ([(71,118),(56,115),(49,107)],1),
             ([(76,107),(88,106),(94,112)],1),
             ([(52,135),(49,146)],1),([(92,126),(91,117)],1)]
    for line,_ in lines:
        d.line(line,fill=1,width=3 if wide else 1)
        # Short exposed stone edges; leave most hairlines a single dark pixel.
        d.line([(x+1,y+1) for x,y in line[:3]],fill=5 if wide else 4,width=1)


def frames(texture):
    first = indexed(SIZE); cracks(first)
    split = indexed(SIZE); cracks(split,True); d = ImageDraw.Draw(split)
    d.polygon([(35,149),(43,137),(56,127),(62,114),(74,105),(85,113),
               (94,127),(110,137),(129,149)],fill=1)
    # Three recognisable pieces in frame1, smaller/darker versions in frame2.
    fragment(split,[(38,131),(61,126),(70,136),(48,144)],texture,(7,11))
    fragment(split,[(85,122),(103,129),(100,141),(82,134)],texture,(23,4))
    fragment(split,[(58,113),(72,108),(78,117),(64,123)],texture,(2,22))
    d = ImageDraw.Draw(split)
    d.polygon([(48,144),(70,136),(69,142),(50,149)],fill=3)
    d.polygon([(100,141),(103,129),(106,132),(104,146)],fill=2)
    dust1 = [(49,119,3,2,5),(59,104,2,2,6),(80,102,2,3,5),
             (92,113,3,2,6),(107,137,2,2,5),(32,140,3,2,4),
             (78,125,2,2,4),(61,133,3,2,6),(86,142,2,2,5)]
    for x,y,w,h,i in dust1: d.rectangle((x,y,x+w-1,y+h-1),fill=i)
    gone = indexed(SIZE); d = ImageDraw.Draw(gone)
    # Follow the corridor's floor wedge, keeping the walls and UI transparent.
    rim = [(0,149),(13,137),(29,123),(43,111),(54,101),(64,91),
           (78,90),(87,97),(99,109),(116,125),(133,140),(147,149)]
    d.polygon(rim+[(147,149),(0,149)],fill=1)
    d.line(rim,fill=3,width=1)
    for line in (rim[1:4],rim[5:8],rim[9:11]): d.line(line,fill=5,width=1)
    fragment(gone,[(33,134),(44,130),(49,137),(39,143)],texture,(7,11),1)
    fragment(gone,[(103,140),(113,144),(108,149),(100,146)],texture,(23,4),1)
    fragment(gone,[(68,119),(75,116),(79,121),(72,125)],texture,(2,22),1)
    d = ImageDraw.Draw(gone)
    for x,y,i in [(56,108,5),(63,101,4),(84,111,5),(91,121,4),
                  (51,142,3),(74,141,3),(122,137,4),(61,149,3)]:
        d.rectangle((x,y,x+1,y+1),fill=i)
    return [first,split,gone]


def main():
    sources = BASE/'sources'; sources.mkdir(parents=True,exist_ok=True)
    floor_path = sources/'lower_watch_floor.png'
    if not floor_path.exists(): floor_path.write_bytes((ROOT/'assets/art/env/painted_f3_floor.png').read_bytes())
    texture = Image.open(floor_path)
    assets = frames(texture); runtime = []
    for i,im in enumerate(assets):
        assert im.size == SIZE and im.mode == 'P' and im.getpalette() == TABLE
        assert not im.crop((0,0,148,90)).getbbox(), 'Keep the upper view clear'
        assert {a for *_,a in im.convert('RGBA').getdata()} == {0,255}
        p = OUT/f'fall_crumble_{i}.png'; save(im,p); runtime.append(p)
    # Show raw overlays on slate, with no scaling hidden in the native sheet.
    sheet = indexed((476,200),1); label(sheet,(8,5),'THE FALL / THREE HELD POSES / 700 MS EACH',25)
    for i,im in enumerate(assets):
        x = 8+i*156
        ImageDraw.Draw(sheet).rectangle((x,28,x+147,177),fill=3)
        sheet.paste(im,(x,28),im.convert('RGBA').getchannel('A'))
        label(sheet,(x,180),f'CRUMBLE {i}',8)
    save(sheet,BASE/'contact_sheet_native.png')
    save(sheet.resize((sheet.width*4,sheet.height*4),NEAREST),BASE/'contact_sheet_4x.png')
    background = Image.open(sources/'lower_watch_corridor.png').convert('RGBA')
    strip = indexed((476,200),1).convert('RGBA')
    text = indexed(strip.size); label(text,(8,5),'LOWER WATCH / FALL / OFFLINE VIEW',25)
    strip.alpha_composite(text.convert('RGBA'))
    for i,im in enumerate(assets):
        composed = Image.alpha_composite(background,im.convert('RGBA'))
        composed.save(BASE/f'mockup_frame_{i}_native.png')
        at = (8+i*156,28); strip.paste(composed,at)
        text = indexed(strip.size); label(text,(at[0],180),f'{i*700}-{(i+1)*700} MS',8)
        strip.alpha_composite(text.convert('RGBA'))
    strip.save(BASE/'mockup_strip_native.png')
    strip.resize((strip.width*4,strip.height*4),NEAREST).save(BASE/'mockup_strip_4x.png')
    manifest(runtime+[BASE/'contact_sheet_native.png',BASE/'contact_sheet_4x.png'],BASE/'manifest.json',{
        'runtime_count':3,'canvas':list(SIZE),'anchor':[0,0],'frame_ms':[700,700,700],
        'placement':'View-local top-left, exact148x150; clip to view. White unlit modulation. Above scene/held items, below HUD.',
        'alpha':'Binary; upper90rows always transparent. Opaque blue-black void intentional in frames1/2.',
        'provenance':'Native cracks, coarse dust and three fragment poses using the accepted painted Lower Watch floor. Offline proxy corridor supplied by deep/build_deep.py.',
        'preview_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
                         for p in sorted(BASE.glob('mockup_*.png'))]})
    print('Fall: 3 x148x150, fixed palette, binary alpha, upper90rows clear. Review strip built offline; no Godot.')


if __name__ == '__main__': main()
