# A lever you can face, and stone-cut stair marks

The front lever source is a built-in imagegen painting with a square-on iron
plate, brass shaft and knob, matching the existing side lever's materials.
The exact prompt and reference roles are in `prompt.json`. Both source states
are in `sources/lever_states.png`. The source housings share hinge y=465;
the builder uses that fixed source coordinate and a common scale, rather than
independently fitting each state's alpha crop. The outer rim, bolts and pivot
are registered identically across the two resulting states.

There are twelve opaque wall faces (two states, two floors, 64/40/24) and six
transparent front hardware sprites (two states, three old-size/hinge variants).
The wall faces preserve the floor-specific painted masonry exactly behind the
hardware. The hardware has an upright front plate: no perspective is baked in.
Existing side artwork remains unchanged. Match view orientation to the physical
wall normal when selecting front or side sprites; a canonical wall face instead
gets its perspective from the renderer's wall plane.

The same builder makes 36 `architecture_v3_*` stair faces/side variants. A clean
copy of the keystone replaces the old flat mark, then a small V or ^ is cut in
stone-valued grey. Only the 17x12 keystone repair region changes from v2. All
treads, lights, wall pixels and UV anchors outside that patch remain identical.
The original owner's painting and every accepted runtime asset are preserved.
`../keystone_carved/` contains full-face and enlarged old/new groove reviews.

Offline rebuild and validation from repository root:

```
python -B art_src/fixtures/build_wall_controls.py
python -B art_src/fixtures/verify_wall_controls.py
```

`manifest.json` covers all 54 new runtime PNGs and input/output hashes.
Validation checks fixed hinge/rim pixels, state remnants, palette and binary
alpha, exact nearest sizes/projections, anchors, isolated keystone edits and
six exact 4x review sheets. No Godot or generation service is used in rebuilding.

Review `lever_front_contact_4x.png`, `lever_hardware_contact_4x.png` and
`lever_corridor_f1_4x.png` / `lever_corridor_f2_4x.png`. Corridor sheets are
offline 148x150 ray-cast mock-ups with current lamp shading: near front, middle
front and side wall. They are placement previews, not engine playtest captures.
See `docs/ART.md` for exact names, sizes and integration choices.
