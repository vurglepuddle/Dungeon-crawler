"""Original painted plates, nearest reduction; native VETKA logo lettering."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'env'))
from PIL import Image, ImageDraw, ImageFont
from pipeline import ROOT, NEAREST, indexed, reduce, save, contact, manifest, label
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/screens'

def fitted(source,size):
    # Centre crop, no stretched art, nearest-only sampling.
    w,h=source.size;tw,th=size
    if w*th>h*tw:
        nw=h*tw//th;x=(w-nw)//2;source=source.crop((x,0,x+nw,h))
    else:
        nh=w*th//tw;y=(h-nh)//2;source=source.crop((0,y,w,y+nh))
    return reduce(source,size)

def main():
    assets={}
    for name,size in [('title',(154,150)),('win',(128,80)),('death',(128,80))]:
        assets[name]=fitted(Image.open(BASE/'sources'/f'{name}.png'),size)
    # The emblem is painted; real typography is applied at its final pixel size.
    splash=indexed((154,150),1)
    emblem=fitted(Image.open(BASE/'sources/splash.png'),(96,84))
    splash.paste(emblem,(29,5))
    font=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)
    for text,y,ink in [('LOST MOTH',98,10),('1993',119,25)]:
        width=font.getlength(text)
        label(splash,(int((154-width)//2),y),text,ink)
    assets['splash']=splash
    for name,im in assets.items():save(im,OUT/f'{name}.png')
    contact(assets,BASE,columns=2,cell=(172,186),title='UNDERCROFT / STORY PLATES')
    manifest(list(OUT.glob('*.png'))+list(BASE.glob('*sheet*.png')),BASE/'manifest.json',
        {'title_text':'Separate VETKA label, not baked into title art',
         'splash_text':['LOST MOTH','1993'],'crop':'Aspect-preserving centre crop before nearest reduction'})
    print('Title 154x150; publisher 154x150; endings 128x80; shared palette.')

if __name__=='__main__':main()
