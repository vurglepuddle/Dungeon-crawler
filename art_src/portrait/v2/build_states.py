"""Stronger reactive expressions. Fine and the first portrait set are read-only."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
from PIL import Image,ImageDraw
from pipeline import ROOT,NEAREST,indexed,reduce,save,contact,manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/portrait'

def main():
    fine=Image.open(ROOT/'assets/art/portrait/finder_fine.png')
    assert fine.convert('RGBA').tobytes()==Image.open(ROOT/'assets/art/finder.png').convert('RGBA').tobytes()
    assets={'fine':fine}
    for key in ('hurt','near_death'):
        assets[key]=reduce(Image.open(BASE/'sources'/f'{key}.png'),(32,32))
        if key=='hurt':
            # Native cleanup of the painted cheek cut: the fixed palette otherwise
            # merges red blood with warm skin. Keep this scar five pixels long.
            d=ImageDraw.Draw(assets[key])
            d.line([(12,12),(14,14),(16,15)],fill=30)
            d.line([(13,12),(15,14),(17,15)],fill=31)
        save(assets[key],OUT/f'finder_{key}_v2.png')
    assert len({im.tobytes() for im in assets.values()})==3
    # Record face differences for review; visual inspection judges expression.
    differences={}
    for key in ('hurt','near_death'):
        a=assets[key].crop((10,7,27,24));b=fine.crop((10,7,27,24))
        differences[key]=sum(x!=y for x,y in zip(a.getdata(),b.getdata()))
        assert differences[key]>0,(key,differences[key])
    strip=indexed((96,32))
    for i,im in enumerate(assets.values()):strip.paste(im,(32*i,0))
    save(strip,OUT/'finder_strip_v2.png')
    save(strip.resize((768,256),NEAREST),BASE/'faces_8x.png')
    contact(assets,BASE,columns=3,cell=(112,82),title='FINDER / READ THE FACE')
    manifest([OUT/'finder_hurt_v2.png',OUT/'finder_near_death_v2.png',OUT/'finder_strip_v2.png',BASE/'faces_8x.png']+list(BASE.glob('*sheet*.png')),BASE/'manifest.json',
        {'fine_reference':'assets/art/portrait/finder_fine.png','fine_is_pixel_exact':True,
         'face_region_changed_pixels':differences,'face_region_total_pixels':289,
         'order':['fine','hurt_v2','near_death_v2'],'size':[32,32],'anchor':[16,16]})
    print('Reactive Finder v2: clear wince/cut and pale exhaustion; fine unchanged.',differences)

if __name__=='__main__':main()
