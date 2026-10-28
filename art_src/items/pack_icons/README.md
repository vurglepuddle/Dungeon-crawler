# Painted 16px pack illustrations

Fifteen new static PNGs in `assets/art/items/icon_<kind>_16.png`.
No C-owned icons, existing world sprites or source paintings are changed.

Rebuild offline from the repository root:

```powershell
python -B art_src/items/build_pack_icons.py
python -B art_src/items/verify_pack_icons.py
```

Pillow, numpy and scipy are the same local authoring dependencies used by the
earlier world-item pipeline. Runtime has no Python dependency.

The builder reads accepted original paintings under `art_src/items/sources/`.
Coat states share their original two-state painting. Cold reeds use the
accepted fixture painting; the lit state adds painted flame material from the
accepted burning-web painting. The Seal takes only the original painted disc,
masking off its pedestal. There was no new image generation in this batch.
Existing source prompts remain beside those paintings. The new builder is
the complete reproducible crop/reduction/edit record.

At 16px a few cues need deliberate cleanup: a material-coloured upper/left
rim, the knife edge/grip, the key's closed bow, brick-red tonic, coat tears and
stuffing, a stone chip, and a larger reed fan with a continuous leaning grip.
The reed fan/grip are reduced separately from the painting to preserve their
readability. Torch bodies below the fire stay exactly registered. The original
paintings remain untouched. All sampling/enlargement is nearest-neighbour;
the fixed palette and binary alpha are unchanged.

Review pairs (native and exact 4x):

- `icons_context`: for each kind, old/new on leather, then old/new on slate.
- `icons_pack_strip`: all fifteen states across two eight-slot strips,
  preserving the actual 152x22 leather and 19x22 slot geometry.
- `icons_card`: old/new on the actual slate material with Chrome's four-pixel
  fixed corners; several items are grouped per review card for comparison.
- `icons_world_match`: accepted world sprite beside old/new pack icons.
- `icons_torch_seal`: the optional reed and Seal replacements in isolation.

These are offline material/scale checks, not engine screenshots or a proposed
card redesign. The current card is text-first. No UI files are edited.
`manifest.json` records every source dependency and output hash; verification
checks fifteen unique icons, true key-hole alpha, continuous registered reed
grips, flame height, spent silhouette and all five exact 4x pairs. Contrast
measurements are reported for the real backgrounds, without treating a numeric
contrast result as human recognition or phone acceptance.

`docs/ART.md`, section **Painted pack icons at 16px**, has the complete A-facing
lookup/state mapping. Keep the HUD icons at native 16x16, centred at (8,8),
without dungeon lamp modulation or a world-object contact shadow.
