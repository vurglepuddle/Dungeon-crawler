# Finder's held items

Painted source cutouts generated with the built-in image tool. `prompts.json`
records the canonical glove request; `item_prompts.json` records every prop
request. The first source is the costume/style reference for all subsequent
sheets, alongside `sources/item_references.png` made from the accepted inventory
icons. The Seal also references the accepted pedestal painting, without carrying
the pedestal into the held pose. Reference roles are spelled out in the prompts.
`torch_revision_prompt.json` records the shorter torch correction; its rejected
long-shaft source is retained as `sources/torch_sheet_draft.png`.

`sources/corridor_reference.png` freezes `build/m3c_shots/03_corridor.png` at
462x1026 so review composites remain reproducible even when A replaces captures.
Mock-ups use its exact nearest-neighbour 148x150 view crop. They are offline
composites, not screenshots of completed in-game integration.

Rebuild, offline, from the repository root (Python, Pillow, NumPy, SciPy):

```
python art_src/hands/build_hands.py
python art_src/hands/verify_hands.py
```

The builder samples each sheet with one shared scale, fixed palette and binary
alpha, then registers every 48x56 frame at its bottom-right corner. Fist height
is limited to 44px; unlit reeds leave 10px for a native two-frame flame. All hand
and cuff pixels stay fixed between torch flicker and Seal pulse frames. Clapper
sound lines are authored at native resolution. No network, Godot, samples or
runtime Python is needed. Sources and the first reduction preview are retained.

Review `hands_contact_4x.png` for every pose, `hands_weapons_4x.png` and
`hands_utility_4x.png` for smaller subsets, `hands_corridor_overview_4x.png` for
all rest poses, and `<kind>_mockup_4x.png` for each item's action frames in context.
Every review sheet has a paired `_native.png` at exact logical resolution.
The manifest carries frame order, anchors, bounds, source and output hashes.
See `docs/ART.md` for the rendering/timing contract.
