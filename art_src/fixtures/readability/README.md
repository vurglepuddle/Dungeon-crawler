# Architecture readability correction

The owner's final decision fixes the supplied painting as **STAIRS DOWN**:
`../architecture/sources/fe3439be-72ab-49d3-8af7-49e3b2e58160.png`.
That original is read in place and never modified. Its centered steps and
receding vaults replace the old impossible left-hand flight. The new matching
UP source has a steeper visible stack of front risers, a higher light and
ceiling arches climbing toward the landing. Both stair faces share the
owner's painted outer arch. Native recessed chevrons add a second cue.

`sources/lift_dead_closed.png` is a new painting of a shut rusty accordion
grille, latch/lock, slack chains and corner cobwebs, with no lamp. The builder
raises the existing painted metal edge values so the grille remains visible
after the game's lamp shading. The accepted working lift stays open and lit;
its original files are used unchanged for comparison and runtime integration.

`prompts.json` preserves the three initial generation requests. The two initial
stair sources are retained as unused history because the owner supplied and
selected the final down painting while work was in progress. The final up
request and exact reference role are in `up_matching_owner_prompt.json`.
All generation/editing used the built-in image tool; rebuilding is fully offline.

From the repository root:

```
python -B art_src/fixtures/build_architecture_readability.py
python -B art_src/fixtures/verify_architecture_readability.py
```

There are 54 new `assets/art/fixtures/architecture_v2_*` PNGs: 3 kinds, 2
floors, 3 front sizes and 6 projected sides each. The shared palette, sampling,
UV registration and side threshold anchors match the old batch. Sources,
runtime assets, palette/alpha contracts, anchors, exact samples and 4x review
sheets are covered by the manifest and validator.

Review sheets (each with paired native PNG):

- `architecture_v2_f1_contact_4x.png`, `architecture_v2_f2_contact_4x.png`
- `architecture_v2_sides_4x.png`
- `lift_closed_comparison_4x.png`: old dead / new shut / original working
- `corridor_f1_depths_4x.png`, `corridor_f2_depths_4x.png`
- `owner_down_evaluation_4x.png`: owner's painting directly at 64/40/24
- `original_corridor_reference_4x.png`: frozen original M3d capture for reference

Corridor previews are offline 148x150 ray-cast mock-ups with A's FOCAL=74,
HORIZON=71 and lamp formula `(3.6-depth)/2.7`, at wall distances .5/1.5/2.5.
They use actual current floor/ceiling material and preserved wall references.
They are not Godot captures, game-state tests, blind human tests or phone
acceptance. Review both floors: wet floor-two stone is darker but lit step
accents remain readable. At 24px, step rhythm and chevron support each other;
the tiny source brushwork and individual cobweb threads naturally collapse.

See `docs/ART.md` for exact filenames, sizes, anchors and the path swap for A.
