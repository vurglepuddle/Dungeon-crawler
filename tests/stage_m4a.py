"""Copy finalized runtime inputs to a disposable export project; preserve WIP."""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'build/m4a_export_stage'
STAGE.mkdir(parents=True,exist_ok=True)
def copy(path):
    dest=STAGE/path
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/path,dest)
for name in ['project.godot','export_presets.cfg']: copy(Path(name))
for directory in ['scripts','scenes','data','assets/font','assets/icon']:
    for path in (ROOT/directory).rglob('*'):
        if path.is_file(): copy(path.relative_to(ROOT))
for path in (ROOT/'assets/art').glob('*'):
    if path.is_file(): copy(path.relative_to(ROOT))
for directory in ['anim','fx','fixtures','creatures','hands','icons','ui','props','items']:
    for path in (ROOT/'assets/art'/directory).rglob('*'):
        if path.is_file(): copy(path.relative_to(ROOT))
for floor in [1,2]:
    names=[f'f{floor}_floor',f'f{floor}_ceiling']
    names += [f'painted_f{floor}_{suffix}' for suffix in ['plain_0','plain_1','plain_2','sconce_0','sconce_1','crack','damp','chains','tapestry','drain','arch_blocked','door_barricaded','door']]
    for name in names:
        for path in (ROOT/'assets/art/env').glob(name+'.png*'): copy(path.relative_to(ROOT))
for name in ['finder_fine','finder_hurt_v2','finder_near_death_v2']:
    for path in (ROOT/'assets/art/portrait').glob(name+'.png*'): copy(path.relative_to(ROOT))
for name in ['title','splash','win','death','logotype_140'] + [f'{family}_{i}' for family,count in [('splash_flutter',2),('title_flicker',3),('win_dawn',3),('death_gutter',3)] for i in range(count)]:
    for path in (ROOT/'assets/art/screens').glob(name+'.png*'): copy(path.relative_to(ROOT))
(ROOT/'build/m4a_pack_probe').mkdir(parents=True,exist_ok=True)
for path in (ROOT/'assets/art/env').glob('calm_v3_*.png*'): copy(path.relative_to(ROOT))
for name in ['message_slate','pack_leather','belt_loops','hp_vial_empty','hp_vial_full','brass_label','candle_0','candle_1','hanging_chain','map_parchment_torn_v2']:
    for path in (ROOT/'assets/art/ui_offer').glob(name+'.png*'): copy(path.relative_to(ROOT))
for path in (ROOT/'assets/art/ui_offer').glob('verb_*.png*'): copy(path.relative_to(ROOT))
for path in (ROOT/'assets/art/ui').glob('owner_vines.png*'): copy(path.relative_to(ROOT))
print('M4a staged: world items and deep rules included; draft vines excluded.')
