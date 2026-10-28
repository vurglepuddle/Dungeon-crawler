# Painted world pickups

Twelve kinds/states replace the old world-item placeholders: knife, shard,
club, stone, bone, bread, tonic, coat, coat_spent, key, clapper and lamp.
The eleven built-in imagegen requests are recorded as exact common-prefix plus
item-specific text in `prompts.json`, `prompts_2.json`, `prompts_3.json`.
`sources/icon_references.png` is a labelled board of C's accepted inventory
icons; every generation used it as an identity/material reference. The two
coats were painted together to preserve their identity. Source PNGs are kept.

Offline rebuild (Python, Pillow, NumPy, SciPy), from repository root:

```
python -B art_src/items/build_items.py
python -B art_src/items/verify_items.py
```

The builder extracts the principal alpha silhouette, reduces with NEAREST to
the existing shared palette, and registers bottom-centre. Each distance gets a
small material-coloured upper/left rim retouch at its own native resolution.
Coats keep the same near footprint while the spent padding is flattened.
Tonic liquid planes are corrected to the palette's brick-red ramp so they do
not turn orange-brown; the cork and label retain their original values.

Runtime files: `assets/art/items/item_<kind>_d<1|2|3>.png`. Canvases are 64x48,
40x30 and 24x18; anchors are (32,48), (20,30), (12,18). The 64/40/24 convention
here describes canvas width. All frames are static. No baked shadow or ground
patch: the renderer supplies the contact shadow using the opaque footprint,
not the transparent canvas width. Manifest records exact bounds and hashes.

Review sheets, each with paired native PNG and exact 4x enlargement:

- `items_contact_4x.png`: C's icon followed by all three world depths, every item
- `items_weapons_4x.png`, `items_supplies_4x.png`: shorter review subsets
- `coat_states_4x.png`, `coat_room_comparison_4x.png`: padded / torn and spent
- `room_items_overview_4x.png`: two groups of six, both floors, mixed depths
- `room_f1_set1_4x.png`, `room_f1_set2_4x.png`, and corresponding `f2` files
- `torch_seal_match_4x.png`: unchanged existing fixture art at all three depths

Room previews are offline 148x150 projections on the actual preserved floor,
ceiling and wall materials, with renderer-style lamp shading and review-only
contact ellipses. They are not Godot captures or phone acceptance. Set one:
near knife/stone, middle bone/tonic, far coat/key. Set two: near club/bread,
middle shard/lamp, far spent coat/clapper. Far objects start just inside the
third depth band and dim naturally toward the far cutoff.

Existing reed-torch unlit/two-flame and Dawn Seal pedestal/two-pulse artwork
already matches the inventory and held art's material/shape conventions. Keep
those assets and timings. The game currently selects their dedicated B fixture
icons rather than C's older torch/Seal icons; no repaint is required.

The validator checks all 36 runtime files, source/output hashes, palette and
binary alpha, exact native retouch, anchors, coat collapse, key-ring holes at
every depth and eleven exact 4x review sheets. No Godot, network or runtime
Python is involved. See `docs/ART.md` for A's loader and placement contract.
