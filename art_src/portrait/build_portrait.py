"""Identity-preserving portrait reductions; original fine source stays exact."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'env'))
from PIL import Image
from pipeline import ROOT, NEAREST, reduce, indexed, save, contact, manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/portrait'

def main():
    assets={}
    for name in ('fine','hurt','near_death'):
        assets[name]=reduce(Image.open(BASE/'sources'/f'{name}.png'),(32,32))
        save(assets[name],OUT/f'finder_{name}.png')
    # Fine must remain byte-for-pixel identical to the accepted portrait.
    assert assets['fine'].convert('RGBA').tobytes()==Image.open(ROOT/'assets/art/finder.png').convert('RGBA').tobytes()
    assert len({im.tobytes() for im in assets.values()})==3
    strip=indexed((96,32))
    for i,im in enumerate(assets.values()):strip.paste(im,(i*32,0))
    save(strip,OUT/'finder_strip.png')
    contact(assets,BASE,columns=3,cell=(128,100),title='FINDER / THREE STATES')
    manifest(list(OUT.glob('*.png'))+list(BASE.glob('*sheet*.png')),BASE/'manifest.json',
        {'states':['fine','hurt','near_death'],'anchor':[16,16],
         'suggested_hp':{'fine':'4-6','hurt':'2-3 or immediate hit','near_death':'1'},
         'fine_pixel_match':'assets/art/finder.png'})
    print('3 distinct 32px portraits; fine exactly matches the accepted Finder.')

if __name__=='__main__':main()
