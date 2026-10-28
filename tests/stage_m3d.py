"""Disposable resource-pack staging; never import/change another artist's WIP."""
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'build/m3d_export_stage'
STAGE.mkdir(parents=True,exist_ok=True)
def copy_file(path):
    source=ROOT/path
    target=STAGE/path
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)
for name in ['project.godot','export_presets.cfg']:
    copy_file(Path(name))
for directory in ['scripts','scenes','data','assets/font','assets/icon']:
    for path in (ROOT/directory).rglob('*'):
        if path.is_file(): copy_file(path.relative_to(ROOT))
for path in (ROOT/'assets/art').glob('*'):
    if path.is_file(): copy_file(path.relative_to(ROOT))
for directory in ['anim','fx','fixtures','creatures','icons','ui','ui_offer']:
    for path in (ROOT/'assets/art'/directory).rglob('*'):
        if path.is_file(): copy_file(path.relative_to(ROOT))
for path in (ROOT/'assets/art/env').glob('*'):
    if path.is_file() and (path.name.startswith('painted_f') or path.name.startswith(('f1_floor.','f2_floor.','f1_ceiling.','f2_ceiling.'))): copy_file(path.relative_to(ROOT))
for name in ['finder_fine','finder_hurt_v2','finder_near_death_v2']:
    for path in (ROOT/'assets/art/portrait').glob(name+'.png*'): copy_file(path.relative_to(ROOT))
for name in ['title','splash','win','death']:
    for path in (ROOT/'assets/art/screens').glob(name+'.png*'): copy_file(path.relative_to(ROOT))
print('Staged finalized runtime inputs only; props, room faces and new screens excluded.')
