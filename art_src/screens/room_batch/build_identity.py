"""Painted title and optional launcher art. Never writes assets/icon/ or old art."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'env'))
import math
from PIL import Image,ImageDraw,ImageFont
from pipeline import ROOT,NEAREST,indexed,reduce,save,label,manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/screens'
FONT=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)

def crop_alpha(source):
    im=source.convert('RGBA')
    bounds=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    assert bounds
    return im.crop(bounds)

def overlay(dst,src,at):
    dst.paste(src,at,src.convert('RGBA').getchannel('A'))

def fitted(source,size,margin=0):
    source=crop_alpha(source)
    ratio=min((size[0]-2*margin)/source.width,(size[1]-2*margin)/source.height)
    dims=(max(1,round(source.width*ratio)),max(1,round(source.height*ratio)))
    im=indexed(size);sprite=reduce(source,dims)
    overlay(im,sprite,((size[0]-sprite.width)//2,(size[1]-sprite.height)//2))
    return im

def slice_plate():
    source=Image.open(ROOT/'assets/art/ui_offer/brass_label.png')
    out=indexed((140,20));sw,sh=source.size
    xs=(0,9,sw-9,sw);ys=(0,3,sh-3,sh)
    tx=(0,9,131,140);ty=(0,3,17,20)
    for j in range(3):
        for i in range(3):
            patch=source.crop((xs[i],ys[j],xs[i+1],ys[j+1]))
            patch=patch.resize((tx[i+1]-tx[i],ty[j+1]-ty[j]),NEAREST)
            out.paste(patch,(tx[i],ty[j]))
    text="THE FINDER'S DESCENT"
    assert FONT.getlength(text)<=122
    label(out,(round((140-FONT.getlength(text))/2),2),text,1)
    return out

def radius_of_alpha(im):
    return max(math.hypot(x+0.5-im.width/2,y+0.5-im.height/2)
        for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))!=0)

def safe_foreground():
    source=crop_alpha(Image.open(BASE/'sources/icon_arch_seal_compact.png'))
    # Fit actual opaque pixels, not a circle crop. No foreground artwork is cut.
    for maximum in range(64,31,-1):
        art=fitted(source,(maximum,maximum))
        canonical=indexed((64,64));overlay(canonical,art,((64-maximum)//2,(64-maximum)//2))
        if radius_of_alpha(canonical)<=31.5:return canonical
    raise AssertionError('Icon cannot fit safe circle')

def icon_background(size):
    stone=Image.open(ROOT/'assets/art/stone_wall.png').resize(size,NEAREST)
    im=indexed(size,1)
    dark={1:1,2:1,3:1,4:2,5:2,6:3,7:3,8:3,9:4,10:4,11:11,12:11,13:11,14:12,15:12,16:13,17:13}
    for y in range(size[1]):
        for x in range(size[0]):im.putpixel((x,y),dark.get(stone.getpixel((x,y)),2))
    return im

def contact_and_previews(logo,subtitle,canonical,fg,bg,icon):
    native=indexed((464,438),1)
    label(native,(8,5),'UNDERCROFT / TITLE AND LAUNCHER OFFER',25)
    overlay(native,logo,(8,35));label(native,(8,78),'140 X 40 / PAINTED',8)
    overlay(native,subtitle,(8,100));label(native,(8,126),'VETKA 16 / 140 X 20',8)
    # Integer-downsampled icon/layer views are labelled; original files stay full size.
    overlay(native,icon.resize((64,64),NEAREST),(8,174));label(native,(8,244),'192 @ 1/3',8)
    overlay(native,fg.resize((108,108),NEAREST),(172,154));label(native,(172,268),'FG 432 @ 1/4',8)
    overlay(native,bg.resize((108,108),NEAREST),(328,154));label(native,(328,268),'BG 432 @ 1/4',8)
    full=bg.copy();overlay(full,fg,(0,0));preview=full.resize((108,108),NEAREST)
    # Presentation-only masks, not masks baked into the exported adaptive layers.
    for index,shape in enumerate(('round','squircle','safe zone')):
        result=indexed((108,108),1)
        if shape=='safe zone':
            result=preview.copy();ImageDraw.Draw(result).ellipse((21,21,86,86),outline=25)
        else:
            mask=Image.new('L',(108,108),0);d=ImageDraw.Draw(mask)
            if shape=='round':d.ellipse((18,18,89,89),fill=255)
            else:d.rounded_rectangle((18,18,89,89),radius=18,fill=255)
            result.paste(preview,(0,0),mask)
        native.paste(result,(8+index*150,306));label(native,(8+index*150,416),shape,8)
    save(native,BASE/'contact_sheet_native.png')
    save(native.resize((1856,1752),NEAREST),BASE/'contact_sheet_4x.png')
    save(full,BASE/'adaptive_composite_432.png')
    # A source-sized title proposal, with painted heading and room for controls below.
    title=Image.open(ROOT/'assets/art/screens/title.png').copy()
    overlay(title,logo,(7,6))
    proposal=indexed((154,184),1);proposal.paste(title,(0,0));overlay(proposal,subtitle,(7,158))
    save(proposal,BASE/'title_mockup_native.png')
    save(proposal.resize((616,736),NEAREST),BASE/'title_mockup_4x.png')

def main():
    logo=fitted(Image.open(BASE/'sources/logotype.png'),(140,40),margin=1)
    subtitle=slice_plate()
    canonical=safe_foreground()
    fg=indexed((432,432));overlay(fg,canonical.resize((256,256),NEAREST),(88,88))
    assert radius_of_alpha(fg)<=132.0
    bg=icon_background((108,108)).resize((432,432),NEAREST)
    assert 0 not in set(bg.getdata())
    legacy=icon_background((64,64));overlay(legacy,canonical,(0,0))
    icon=legacy.resize((192,192),NEAREST)
    outputs={'logotype_140':logo,'subtitle_plate_140':subtitle,'icon_offer_192':icon,
        'icon_offer_foreground_432':fg,'icon_offer_background_432':bg}
    for name,im in outputs.items():save(im,OUT/f'{name}.png')
    contact_and_previews(logo,subtitle,canonical,fg,bg,icon)
    manifest([OUT/f'{name}.png' for name in outputs]+list(BASE.glob('*.png')),BASE/'manifest.json',
        {'logotype':{'text':'UNDERCROFT','size':[140,40],'anchor':[70,20]},
         'subtitle':{'text':"THE FINDER'S DESCENT",'font':'VETKA','font_size':16,'size':[140,20]},
         'adaptive':{'layers':[432,432],'foreground_alpha_radius_px':radius_of_alpha(fg),'safe_circle_centre':[216,216],
            'safe_circle_radius_px':132,'background_opaque':True,'art_is_fitted_not_circle_clipped':True,
            'reference':'https://developer.android.com/develop/ui/compose/system/icon_design_adaptive'},
         'scope':'Offer only. assets/icon/ and Android/project export settings are unchanged.',
         'preview':'Mask outlines appear on review sheets only; exported layers are full square canvases.'})
    print('Painted 140px logotype + subtitle; icon 192 and adaptive 432 layers; all art inside 132px safe radius.')

if __name__=='__main__':main()
