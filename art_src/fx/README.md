# Integer pixel effects and fixtures

These are original code drawings, with editable polygons and lines, no painted
source, antialiasing, filtering, randomness or downloads. Pillow is the only
authoring dependency; shared palette and VETKA labels come from `../anim/pipeline.py`.

```powershell
python art_src/fx/build_fx.py
python art_src/fx/build_fixtures.py
python art_src/anim/verify_art.py
```

Runtime assets go only into `assets/art/fx/`. Every effect has three 64x64
frames and a 192x64 strip; its labelled `*_contact_4x.png` is an exact nearest
enlargement. `damage_vetka_demo_4x.png` demonstrates native 16 px digit text;
the actual damage burst contains no baked-in number.

Levers are skewed onto side-wall backplates and have discrete up/down states,
including mirrored right-wall files. Plates are shallow floor trapezoids with
a one-pixel inset edge and no legs or cast shadow. Each fixture has three
native depth sizes. File names, anchors and intended placement are in
[ART.md](../../docs/ART.md) and the machine-readable manifests here.
