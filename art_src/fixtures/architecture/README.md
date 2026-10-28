# Architecture on the accepted painted stone

Five original built-in imagegen requests supplied exit, up/down stairs,
two-state portcullis and two-state lift paintings. Exact requests and reference
roles: [../architecture_prompts.json](../architecture_prompts.json).
One targeted edit corrected the initial down-stair image, whose front-facing
risers read as an ascent. Its rejected source is retained as history; only
`sources/stairs_down.png` is used by the builder. See `down_correction.json`.

The owner's original `stone_wall.png` and C's current `painted_v2` material,
arch and door faces were inspected before generation. Frozen copies live in
`sources/`. Floor one uses C's `painted_f1_plain_0.png`, which preserves the
original painted interior and repairs only the seam ring. Floor two uses C's
actual darker/wetter repaint, not the earlier clean alternate wall family.
Those files are copied authoring inputs; C's files are never modified.

```powershell
python -B art_src/fixtures/build_architecture.py
python -B art_src/fixtures/build_glint.py
python -B art_src/anim/verify_art.py
```

Python/Pillow are offline authoring tools only. Rebuilding reads saved PNGs,
never calls imagegen, starts Godot or accesses a network. Every reduction,
projection and enlargement uses NEAREST and the original shared palette.

The builder reuses ONE aged painted arch from the exit source for every kind
and state. Its outer footprint and aperture follow C's centred arch layout.
Only the inset changes. Pixels outside the arch remain C's exact masonry;
every canonical face preserves the full two-pixel wall border. A floor-two
palette repaint follows C's tonal ramp, preserving warm functional lights.
Small native grey threads retain the dead lift's cobweb cue at 64 pixels;
two native daylight rows preserve the exit's thin light at distance.

Gate overlays use a separate explicit iron silhouette, so palette darkening
cannot erase a bar's opacity on floor two. Their apertures are genuinely
transparent, as the checkerboard contact sheet demonstrates. Canonical opaque
gate faces are also provided for preview and cases with no view behind.
Open/closed and dead/working strips contain two STATIC states, not an animation.

`../architecture_manifest.json` records source hashes, every output size,
UV/threshold anchor, floor, kind, side, depth and strip order. All runtime
files are new `architecture_*` names in `assets/art/fixtures/`. Nothing here
changes geometry, collision, interaction rules, saves, or rendering code.
See [ART.md](../../../docs/ART.md) for A's placement and occlusion contract.
