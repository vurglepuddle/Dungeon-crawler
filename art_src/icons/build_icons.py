"""Thirteen original integer-pixel drawings; no generated source or downloads."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'env'))
from PIL import ImageDraw
from pipeline import ROOT, NEAREST, indexed, save, contact, manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/icons'
KINDS=('knife','lamp','stone','bone','bread','torch','clapper','shard','tonic','club','coat','key','seal')

def icon(kind):
    im=indexed((16,16));d=ImageDraw.Draw(im)
    if kind=='knife':
        d.polygon([(5,10),(11,3),(13,2),(12,6),(7,12)],fill=6)
        d.line([(5,10),(12,3)],fill=10)
        d.line((4,9,8,12),fill=29)
        d.line((3,13,5,11),fill=20,width=2);d.point((3,13),fill=28)
    elif kind=='lamp':
        d.arc((5,2,10,7),180,360,fill=29)
        d.polygon([(5,6),(10,6),(11,8),(10,13),(5,13),(4,8)],fill=28)
        d.rectangle((6,8,9,11),fill=25);d.line((7,8,7,10),fill=10)
        d.line((4,6,11,6),fill=9);d.line((5,13,10,13),fill=29)
    elif kind=='stone':
        d.polygon([(3,7),(5,4),(10,3),(13,7),(12,11),(8,12),(3,11)],fill=5)
        d.polygon([(4,7),(6,5),(10,4),(11,6),(7,8)],fill=8)
        d.line([(4,10),(8,11),(11,10)],fill=4)
    elif kind=='bone':
        d.line((5,10,10,5),fill=8,width=3)
        for box in [(2,8,5,11),(4,10,7,13),(8,2,11,5),(10,4,13,7)]:d.ellipse(box,fill=9)
        d.line((5,9,9,5),fill=10)
    elif kind=='bread':
        d.polygon([(2,7),(4,4),(9,3),(12,5),(13,9),(11,12),(5,12),(2,10)],fill=22)
        d.polygon([(3,7),(5,5),(9,4),(11,6),(12,9),(8,10),(4,9)],fill=25)
        d.line((6,5,4,8),fill=28);d.line((10,6,8,9),fill=28)
    elif kind=='torch':
        d.line((6,13,9,7),fill=28,width=3);d.line((6,12,8,8),fill=23)
        d.polygon([(8,8),(6,5),(8,1),(9,4),(11,2),(12,6),(10,9)],fill=22)
        d.polygon([(8,7),(8,5),(9,3),(10,7)],fill=25);d.point((9,6),fill=10)
        d.line((7,8,10,9),fill=8)
    elif kind=='clapper':
        d.rectangle((7,2,8,9),fill=28);d.line((7,3,7,8),fill=9)
        d.ellipse((4,8,11,13),fill=28);d.ellipse((5,8,10,12),fill=24)
        d.line((6,9,8,9),fill=26)
    elif kind=='shard':
        d.polygon([(3,12),(6,5),(12,2),(10,11),(8,9)],fill=13)
        d.polygon([(4,11),(7,5),(11,3),(8,9)],fill=16)
        d.line([(4,11),(6,6),(11,3)],fill=10);d.line((9,7,9,9),fill=8)
    elif kind=='tonic':
        d.rectangle((6,2,9,4),fill=28)
        d.polygon([(6,5),(9,5),(9,6),(12,8),(12,12),(10,13),(5,13),(3,12),(3,8),(6,6)],fill=5)
        d.rectangle((4,9,11,11),fill=31);d.line((5,12,10,12),fill=30)
        d.line((4,8,5,7),fill=10);d.line((4,9,4,10),fill=9)
        d.rectangle((6,8,9,10),fill=8);d.point((7,9),fill=30)
    elif kind=='club':
        d.line((5,13,8,7),fill=27,width=3)
        d.polygon([(6,3),(9,2),(12,4),(11,8),(8,10),(5,7)],fill=5)
        d.line([(6,5),(7,3),(9,3)],fill=8)
        d.line((7,8,10,5),fill=4);d.line((5,12,6,10),fill=29)
    elif kind=='coat':
        d.polygon([(5,3),(6,4),(9,4),(10,3),(13,5),(14,9),(11,10),(10,8),(11,13),(4,13),(5,8),(4,10),(1,9),(2,5)],fill=13)
        d.line([(2,7),(3,5),(5,4)],fill=16);d.line((5,6,5,11),fill=15)
        d.line((7,5,7,12),fill=28);d.line((4,12,10,12),fill=12)
        d.point((8,7),fill=9);d.point((8,10),fill=9)
    elif kind=='key':
        d.ellipse((3,2,9,8),fill=24);d.ellipse((5,4,7,6),fill=0)
        d.line((8,8,12,12),fill=25,width=2)
        d.line((10,10,8,12),fill=29);d.line((12,12,10,14),fill=25)
        d.line((4,3,6,3),fill=10)
    elif kind=='seal':
        d.polygon([(5,2),(10,2),(13,5),(13,10),(10,13),(5,13),(2,10),(2,5)],fill=24)
        d.polygon([(5,3),(10,3),(12,5),(12,10),(10,12),(5,12),(3,10),(3,5)],fill=10)
        d.ellipse((5,5,10,10),fill=13)
        d.line((5,9,10,9),fill=26);d.arc((6,6,9,10),180,360,fill=26)
        d.point((7,4),fill=24);d.point((10,5),fill=24)
    # One-pixel eight-neighbour silhouette outline, including intentional holes.
    raw=im.copy()
    for y in range(16):
        for x in range(16):
            if raw.getpixel((x,y))==0 and any(raw.getpixel((nx,ny)) for nx in range(max(0,x-1),min(16,x+2)) for ny in range(max(0,y-1),min(16,y+2))):
                im.putpixel((x,y),1)
    bounds=im.convert('RGBA').getchannel('A').getbbox()
    crop=im.crop(bounds)
    assert crop.width<=16 and crop.height<=16
    centered=indexed((16,16));centered.paste(crop,((16-crop.width)//2,(16-crop.height)//2))
    return centered

def main():
    assets={kind:icon(kind) for kind in KINDS}
    atlas=indexed((16*len(KINDS),16))
    for i,(kind,im) in enumerate(assets.items()):
        save(im,OUT/f'{kind}.png');atlas.paste(im,(i*16,0))
        bounds=im.convert('RGBA').getchannel('A').getbbox()
        assert abs(bounds[0]-(16-bounds[2]))<=1 and abs(bounds[1]-(16-bounds[3]))<=1,kind
        # Every exposed body pixel has an outline neighbour inside the canvas.
        for y in range(16):
            for x in range(16):
                if im.getpixel((x,y))>1:
                    for dx,dy in ((0,1),(0,-1),(1,0),(-1,0)):
                        nx,ny=x+dx,y+dy
                        assert 0<=nx<16 and 0<=ny<16 and im.getpixel((nx,ny))>0,(kind,x,y)
    save(atlas,OUT/'items_strip.png')
    contact(assets,BASE,columns=7,cell=(104,66),title='UNDERCROFT / 16 PX POSSESSIONS')
    manifest(list(OUT.glob('*.png'))+list(BASE.glob('*sheet*.png')),BASE/'manifest.json',
        {'strip_order':list(KINDS),'cell_size':[16,16],'anchor':[8,8],'torch_status':'reserved FIRE item; not in current catalog'})
    print('13 centered icons; outline, palette and binary-alpha checks passed.')

if __name__=='__main__':main()
