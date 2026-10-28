"""New ember-lit derivative set. The accepted old Hound is never overwritten."""
import sys
sys.dont_write_bytecode = True
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'anim'))
from PIL import Image
from build_creatures import build_set
from pipeline import ROOT, canvas, contact, manifest, paste, reduce, save

BASE = Path(__file__).resolve().parent
STATES = ['idle', 'windup', 'recoil']


def lamp_tint(source, strength):
    rgba = source.convert('RGBA')
    rgba.putdata([(round(r*strength), round(g*strength), round(b*strength), a) for r,g,b,a in rgba.getdata()])
    return reduce(rgba)


def main():
    build_set('ash_hound_ember', BASE / 'sources/ash_hound_ember_sheet.png', BASE, (96, 64))
    emission_assets = []
    for height in [64,40,24]:
        for state in STATES:
            source = reduce(Image.open(ROOT / f'assets/art/creatures/ash_hound_ember_{state}_{height}.png'))
            glow = canvas(source.size)
            glow.putdata([ink if ink in [23,24,25,26] else 0 for ink in source.getdata()])
            entry = save(glow, ROOT / f'assets/art/creatures/ash_hound_ember_glow_{state}_{height}.png')
            entry.update(state=state, anchor=[source.width//2,height], purpose='optional emissive colour overlay; same canvas and pose; draw after lamp tint')
            emission_assets.append(entry)
    manifest(BASE / 'ash_hound_ember_glow_manifest.json', {'assets': emission_assets, 'body_prefix': 'ash_hound_ember', 'overlay_gain': .85})
    old = [reduce(Image.open(ROOT / f'assets/art/creatures/ash_hound_{state}_24.png')) for state in STATES]
    new = [reduce(Image.open(ROOT / f'assets/art/creatures/ash_hound_ember_{state}_24.png')) for state in STATES]
    emitted = []
    for state, body in zip(STATES,new):
        im = lamp_tint(body,.35)
        overlay = lamp_tint(Image.open(ROOT / f'assets/art/creatures/ash_hound_ember_glow_{state}_24.png'),.85)
        paste(im,overlay,(0,0)); emitted.append(im)
    contact(BASE / 'ash_hound_lamp_compare_4x.png', 'HOUND / 24 PX IN LAMP DARK', [
        ('Old / full source brightness', list(zip(STATES, old))),
        ('Ember / full source brightness', list(zip(STATES, new))),
        ('Old / 35 percent lamp tint', list(zip(STATES, [lamp_tint(im,.35) for im in old]))),
        ('Ember / 35 percent lamp tint', list(zip(STATES, [lamp_tint(im,.35) for im in new]))),
        ('Ember / tint plus glow overlay', list(zip(STATES,emitted)))])
    print('Ember Hound: 12 body/strip PNGs and 9 optional emission overlays; old files preserved')


if __name__ == '__main__': main()
