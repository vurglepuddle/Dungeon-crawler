"""Build calm shared surfaces, torn map and matching mock-ups. No Godot."""
import sys
sys.dont_write_bytecode=True
from pathlib import Path
import hashlib
import importlib.util
import json
from PIL import Image
from build_calm import main as build_calm
from build_mockups import build_mockups,movement_proof,pair
from pipeline import ROOT,indexed,label

BASE=Path(__file__).resolve().parent
UI=ROOT/'art_src/ui_offer/torn_v2'


def main():
    build_calm()
    spec=importlib.util.spec_from_file_location('torn_map_builder',UI/'build_torn.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    module.main()
    previews=build_mockups()+movement_proof()
    sheet=indexed((828,412),1).convert('RGBA')
    text=indexed(sheet.size)
    label(text,(8,5),'UNDERCROFT / CALMER STONE AND THE TORN MAP',25)
    sheet.alpha_composite(text.convert('RGBA'))
    screens=[(BASE/f'mockup_f{floor}_{kind}_native.png',f'F{floor} / {kind.upper()}')
        for floor in (1,2) for kind in ('corridor','room')]
    screens.append((UI/'mockup_map_native.png','MAP / TORN LEAF'))
    for column,(path,caption) in enumerate(screens):
        sheet.paste(Image.open(path),(8+column*164,42))
        text=indexed(sheet.size);label(text,(8+column*164,388),caption,8)
        sheet.alpha_composite(text.convert('RGBA'))
    previews+=pair(BASE/'mockup_all_native.png',sheet)
    path=BASE/'manifest.json';data=json.loads(path.read_text())
    data['preview_files']=[{'path':p.relative_to(ROOT).as_posix(),
        'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in previews]
    path.write_text(json.dumps(data,indent=2)+'\n')
    from verify_calm import main as verify
    verify()


if __name__=='__main__':main()
