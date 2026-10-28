# Painted fixtures v2

Original source paintings, fixed-palette reduction and review images for the
remaining fixture placeholders. Existing accepted assets are read-only.

Rebuild from repository root, offline:

```powershell
python -B art_src/fixtures/painted_v2/build.py
python -B art_src/fixtures/painted_v2/verify.py
```

Requires Pillow and numpy. The builder never calls an image service or Godot.
`sources/` retains the eight unmodified imagegen outputs. `prompts.json` and
`web_prompts.json` retain every exact request, including reference images and
transparency settings; `generation_results.json` and
`web_generation_results.json` identify the corresponding original outputs.
For a new generation, reference `sources/web.png` in place of the transient
external path in `web_prompts.json`. Existing sources are the reproducible
inputs; generative reruns are creative revisions rather than byte-identical
rebuilds.

Plate, silk/fire, cord grate, lift deck, stair ground and cache were painted
before reduction. Side levers project the accepted painted front hardware,
which retains its source under `../lever_front/`. The spent icon extends C's
existing 16px glyph with cloth sampled from the accepted painted spent coat
under `art_src/items/sources/coat.png`, then native tears/stuffing/hem cleanup.
No native vector fixture is enlarged and presented as a painted source.

`build.py` records all source dependencies, output hashes, dimensions, anchors
and old paths in `manifest.json`. `verify.py` checks 65 runtime PNGs and ten
native/4x review pairs. The exact runtime swaps, floor override rule and cache
integration are documented in `docs/ART.md` under **Painted fixture replacements
v2**. No engine or phone validation is implied by the offline ray-cast reviews.
