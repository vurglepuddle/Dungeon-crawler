"""Offline presentation offer, not a change to A's UI. All art is non-tiling.

The mockups composite preserved M3b screenshots; they are NOT game captures
of an implemented interface. Native VETKA and existing controls are retained.
"""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'env'))
import json
import hashlib
from PIL import Image,ImageDraw,ImageFont
from pipeline import ROOT,RGB,NEAREST,indexed,reduce,save,label,manifest
BASE=Path(__file__).resolve().parent
OUT=ROOT/'assets/art/ui_offer'
FONT=ImageFont.truetype(str(ROOT/'assets/font/vetka.ttf'),16)

def material(name,size):
    source=Image.open(BASE/'sources'/f'{name}.png').convert('RGB')
    if name in ('slate','leather'):
        # Trim only the generated black surround; no connected material is erased.
        mask=source.point(lambda p:255 if p>28 else 0).convert('L').point(lambda p:255 if p>0 else 0)
        bounds=mask.getbbox()
        if bounds:source=source.crop(bounds)
    return reduce(source,size)

def sprite(name,size,stretch=False):
    source=Image.open(BASE/'sources'/f'{name}.png').convert('RGBA')
    bounds=source.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    assert bounds,name
    source=source.crop(bounds)
    if stretch:return reduce(source,size)
    ratio=min(size[0]/source.width,size[1]/source.height)
    target=(max(1,round(source.width*ratio)),max(1,round(source.height*ratio)))
    reduced=reduce(source,target)
    result=indexed(size)
    result.paste(reduced,((size[0]-target[0])//2,size[1]-target[1]))
    return result

def overlay(canvas,im,xy):
    rgba=im.convert('RGBA')
    canvas.paste(im if canvas.mode=='P' else rgba,xy,rgba.getchannel('A'))

def preview_save(im,path):
    # Actual saved screenshots contain renderer lighting colours beyond 31 inks.
    # Keep those pixels exact in mockups; only runtime art uses indexed palette.
    im.save(path,optimize=False)

def preview_text(canvas,xy,text,ink):
    d=ImageDraw.Draw(canvas);d.fontmode='1'
    d.text(xy,text,font=FONT,fill=RGB[ink]+(255,))

def fill_vial(empty,liquid,fraction):
    result=empty.copy()
    h=round(18*max(0,min(1,fraction)))
    if h:overlay(result,liquid.crop((0,24-h,6,24)),(0,24-h))
    return result

def chain():
    im=indexed((8,34));d=ImageDraw.Draw(im)
    d.ellipse((1,0,6,5),fill=1,outline=28)
    for n,y in enumerate(range(3,30,5)):
        if n%2:
            d.line((4,y,4,y+6),fill=1,width=3)
            d.line((3,y+1,3,y+5),fill=5);d.point((4,y+1),fill=7)
        else:
            d.ellipse((1,y,6,y+7),outline=1,width=2)
            d.line((2,y+1,2,y+4),fill=6);d.line((5,y+3,5,y+5),fill=4)
    d.point((3,1),fill=14)
    return im

def build_assets():
    assets={}
    assets['message_slate']=material('slate',(150,34))
    # Explicit quiet reading region: compress any light fleck without tiling it.
    for y in range(2,32):
        for x in range(3,145):
            ink=assets['message_slate'].getpixel((x,y))
            if ink not in (1,2,3):assets['message_slate'].putpixel((x,y),2)
    assets['map_parchment']=material('parchment',(144,324))
    for y in range(14,310):
        for x in range(12,132):
            # Reserve a quiet writing field; unique painted wear stays at edges.
            assets['map_parchment'].putpixel((x,y),9)
    d=ImageDraw.Draw(assets['map_parchment'])
    d.line([(12,70),(59,71),(93,70),(131,72)],fill=8)
    d.line([(12,163),(65,162),(131,163)],fill=8)
    d.line([(12,254),(80,253),(131,254)],fill=8)
    d.line([(73,14),(72,110),(73,199),(71,309)],fill=8)
    assets['pack_leather']=material('leather',(152,22))
    assets['belt_loops']=sprite('belt',(53,24),stretch=True)
    assets['hp_vial_empty']=sprite('vial',(6,28))
    d=ImageDraw.Draw(assets['hp_vial_empty'])
    # Fixed two-pixel liquid aperture, independent of source-image imperfections.
    d.rectangle((2,6,3,23),fill=1)
    d.line((1,5,1,24),fill=5);d.line((4,5,4,24),fill=3)
    d.point((1,7),fill=9);d.point((1,8),fill=9)
    assets['hp_vial_full']=indexed((6,28))
    d=ImageDraw.Draw(assets['hp_vial_full'])
    d.rectangle((2,6,3,23),fill=14);d.line((2,7,2,22),fill=16)
    d.line((2,6,3,6),fill=17)
    assets['candle_0']=sprite('candle',(12,24))
    # Native-pixel flame only: body and saucer are identical between frames.
    assets['candle_1']=assets['candle_0'].copy()
    top=assets['candle_0'].convert('RGBA').getchannel('A').getbbox()[1]
    flame_bottom=top+max(3,round((24-top)*0.36))
    for y in range(flame_bottom):
        for x in range(12):assets['candle_1'].putpixel((x,y),0)
    d=ImageDraw.Draw(assets['candle_1'])
    d.polygon([(5,flame_bottom-1),(4,flame_bottom-4),(6,flame_bottom-6),(7,flame_bottom-7),(8,flame_bottom-3),(7,flame_bottom-1)],fill=22)
    d.polygon([(5,flame_bottom-2),(6,flame_bottom-5),(7,flame_bottom-3),(6,flame_bottom-1)],fill=25)
    d.point((6,flame_bottom-3),fill=10)
    assert assets['candle_0'].crop((0,flame_bottom,12,24)).tobytes()==assets['candle_1'].crop((0,flame_bottom,12,24)).tobytes()
    assets['hanging_chain']=chain()
    assets['brass_label']=sprite('brass',(64,18),stretch=True)
    d=ImageDraw.Draw(assets['brass_label'])
    d.rectangle((10,3,53,14),fill=29)
    d.line((11,14,52,14),fill=28)
    # Verdigris is the single accent family, already present in the 31 inks.
    d=ImageDraw.Draw(assets['brass_label']);d.line((5,5,5,12),fill=14)
    for name,im in assets.items():save(im,OUT/f'{name}.png')
    return assets

def contact_sheet(assets):
    sheet=indexed((500,530),1)
    label(sheet,(8,5),'UNDERCROFT / UI MATERIAL OFFER',25)
    placements={'message_slate':(10,34),'pack_leather':(10,106),'belt_loops':(10,168),
        'hp_vial_empty':(10,232),'hp_vial_full':(140,232),'candle_0':(10,306),
        'candle_1':(140,306),'hanging_chain':(10,380),'brass_label':(10,454),
        'map_parchment':(340,34)}
    for name,xy in placements.items():
        overlay(sheet,assets[name],xy)
        label(sheet,(xy[0],xy[1]+assets[name].height+3),name,8)
    # Health strip proves 0..6 HP uses a shared empty body and clipped liquid.
    for n in range(7):overlay(sheet,fill_vial(assets['hp_vial_empty'],assets['hp_vial_full'],n/6),(185+n*16,390))
    label(sheet,(185,424),'HP 0 1 2 3 4 5 6',8)
    save(sheet,BASE/'contact_sheet_native.png')
    save(sheet.resize((2000,2120),NEAREST),BASE/'contact_sheet_4x.png')

def mockups(assets):
    original=Image.open(BASE/'sources/m3b_room_reference.png').convert('RGBA').resize((154,342),NEAREST)
    screen=original.copy()
    overlay(screen,assets['message_slate'],(2,174))
    preview_text(screen,(4,175),'Find the Dawn Seal.',9);preview_text(screen,(4,191),'Bring it home.',9)
    overlay(screen,assets['pack_leather'],(1,246))
    overlay(screen,assets['belt_loops'],(99,210))
    overlay(screen,fill_vial(assets['hp_vial_empty'],assets['hp_vial_full'],1.0),(36,212))
    # Existing art only, representative possessions to show boxless readability.
    for i,kind in enumerate(('stone','bread','tonic','clapper','shard')):
        overlay(screen,Image.open(ROOT/f'assets/art/icons/{kind}.png'),(2+i*19,249))
    overlay(screen,Image.open(ROOT/'assets/art/icons/key.png'),(104,213))
    overlay(screen,Image.open(ROOT/'assets/art/icons/seal.png'),(130,213))
    # Buttons, compass, top strip and dungeon view are exactly preserved.
    protected=[(0,0,154,174),(0,268,154,342),(43,211,95,243),(3,210,35,242)]
    for box in protected:assert screen.crop(box).tobytes()==original.crop(box).tobytes(),box
    preview_save(screen,BASE/'mockup_game_native.png')
    preview_save(screen.resize((616,1368),NEAREST),BASE/'mockup_game_4x.png')
    map_reference=Image.open(BASE/'sources/m3b_map_reference.png').convert('RGBA').resize((154,342),NEAREST)
    map_indexed=reduce(map_reference,(154,342))
    map_screen=screen.copy()
    map_screen.paste(map_reference.crop((0,0,154,16)),(0,0))
    overlay(map_screen,assets['map_parchment'],(5,16))
    # Preserve seen geometry/markers from the saved map; no unseen cells invented.
    glyph_inks={1,6,10,15,23,25,29}
    for y in range(48,279):
        for x in range(12,140):
            ink=map_indexed.getpixel((x,y))
            if ink in glyph_inks:map_screen.putpixel((x,y),RGB[5 if ink==6 else ink]+(255,))
    overlay(map_screen,assets['brass_label'],(19,22))
    preview_text(map_screen,(37,23),'MAP',1)
    overlay(map_screen,assets['hanging_chain'],(5,48))
    overlay(map_screen,assets['candle_0'],(133,313))
    # Keep the actual existing CLOSE button intact; presentation only.
    map_screen.paste(map_reference.crop((12,284,140,308)),(12,284))
    preview_save(map_screen,BASE/'mockup_map_native.png')
    preview_save(map_screen.resize((616,1368),NEAREST),BASE/'mockup_map_4x.png')
    pair=Image.new('RGBA',(316,342),RGB[1]+(255,));pair.paste(screen,(0,0));pair.paste(map_screen,(162,0))
    preview_save(pair,BASE/'mockup_screen_native.png')
    preview_save(pair.resize((1264,1368),NEAREST),BASE/'mockup_screen_4x.png')

def main():
    assets=build_assets();contact_sheet(assets);mockups(assets)
    entries={
        'message_slate':{'rect':[2,174,150,34],'nine_slice_ltrb':[3,2,4,2],'text_origin':[4,175]},
        'map_parchment':{'rect':[5,16,144,324],'nine_slice_ltrb':[8,12,8,12],'content_padding_ltrb':[7,7,7,7]},
        'pack_leather':{'rect':[1,246,152,22],'nine_slice_ltrb':[2,1,3,3],'icon_pitch':19,'icon_origin':[2,249]},
        'belt_loops':{'rect':[99,210,53,24],'nine_slice_ltrb':[0,0,0,0],'resize':False,'item_centres':[[112,221],[138,221]]},
        'hp_vial_empty':{'rect':[36,212,6,28],'nine_slice_ltrb':[0,0,0,0],'resize':False},
        'hp_vial_full':{'rect':[36,212,6,28],'liquid_aperture':[2,6,2,18],'fill_direction':'bottom to top','nine_slice_ltrb':[0,0,0,0],'resize':False},
        'candle_0':{'size':[12,24],'anchor':[6,24],'fps':4,'nine_slice_ltrb':[0,0,0,0],'resize':False},
        'candle_1':{'size':[12,24],'anchor':[6,24],'fps':4,'nine_slice_ltrb':[0,0,0,0],'resize':False},
        'hanging_chain':{'size':[8,34],'anchor':[4,0],'nine_slice_ltrb':[0,0,0,0],'resize':False},
        'brass_label':{'size':[64,18],'nine_slice_ltrb':[9,3,9,3],'label_ink':'0c101c','inner_text_rect':[10,1,44,16]}}
    (BASE/'rects.json').write_text(json.dumps({'schema_version':1,'accent':'verdigris; shared palette teal ramp','tiling':False,
        'nine_slice_order':'left top right bottom','stretch_mode':'STRETCH, never TILE','assets':entries,
        'mockup_status':'Offline illustrative composite of saved M3b screenshots; not implemented or a live gameplay capture.'},indent=2)+'\n')
    manifest(list(OUT.glob('*.png'))+list(BASE.glob('contact_sheet*.png')),BASE/'manifest.json',
        {'runtime_count':len(assets),'logical_viewport':[154,342],'mockup_preserves':'Dungeon, buttons, compass, equipment controls and fine portrait',
         'accent_family':'verdigris','layout':'rects.json','note':'Illustrative composite; packed objects are representative, not the saved run inventory.',
         'preview_files':[{'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
             for p in sorted(BASE.glob('mockup_*.png'))]})
    print('UI offer: 10 non-tiling assets, 4x contact sheet, game/map mockups; protected screen regions unchanged.')

if __name__=='__main__':main()
