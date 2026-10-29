# R12: three metals

Entirely offline: the accepted `art_src/items/sources/key.png` supplies a small
painted metal patch. `build_keys.py` authors three new bow/bit silhouettes and
remaps that material to restrained shared-palette ramps. UI silhouettes are
drawn at16px first; floor silhouettes use the accepted diagonal pose and
64x48 /40x30 /24x18 canvases. No image generation or new sample dependency.

From the repository root:

```powershell
python -B art_src/items/keys_r12/build_keys.py
```

This writes only the three new `icon_key_METAL_16` files, nine new
`item_key_METAL_dD` files, twelve `fixtures/lock_plate_fF_METAL_64` files and
the r12 authoring/review receipts in these two new source directories. The
lock builder is invoked as part of the same build so metal ramps stay shared.
Pack, belt and card all use the same native16px icon; no second belt atlas.

`layout.json` lists exact sizes, anchors and selection tokens. `manifest.json`
records sources, dependencies and output hashes. `preserved_hashes.json`
freezes302 pre-existing PNGs including all accepted hand frames, the Fall,
f4 environment and old key art. None of their old builders is imported/run.

Review: `contact_sheet_native.png` / `contact_sheet_4x.png` show real pack,
belt and slate materials, monochrome silhouettes and all floor depths.
The last key on the bottom real pack tray is the accepted old reference.

After any owner hand edits, preserve those runtime pixels before rebuilding.
The Fall and held items are outside this builder's output list.
