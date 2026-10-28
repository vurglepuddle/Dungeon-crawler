# UNDERCROFT art handoff: Codex B

28 October 2026. The first batch was accepted and committed as `a7844e4`.
M3c additions below are ready for A's integration; B has not phone-tested them.
Existing root `assets/art/` PNGs are preserved. Painted sources were made with built-in imagegen; effects and
fixtures are native integer pixel drawings. Every runtime PNG shares the
existing `art_src/spike/palette.gpl`: 31 opaque colours and transparent index 0,
with binary alpha and nearest filtering.

## Review sheets

All paths below are relative to the repository root. Every `_4x.png` has a
matching `_native.png`; enlargement is exactly 4x nearest-neighbour.

| Set | 4x contact sheet |
| --- | --- |
| All creature frames side by side at 64 px height | `art_src/anim/tells_64_contact_4x.png` |
| Bell Husk, three poses at all distances | `art_src/anim/bell_husk_contact_4x.png` |
| Old waiting Porter beside restored pose | `art_src/anim/porter_contact_4x.png` |
| Ash Hound | `art_src/creatures/ash_hound_contact_4x.png` |
| Wick Ghost | `art_src/creatures/wick_ghost_contact_4x.png` |
| EDGE slash | `art_src/fx/edge_contact_4x.png` |
| HEAVY impact | `art_src/fx/heavy_contact_4x.png` |
| Bare hands | `art_src/fx/hands_contact_4x.png` |
| Damage burst | `art_src/fx/damage_burst_contact_4x.png` |
| VETKA 16 px damage-number example | `art_src/fx/damage_vetka_demo_4x.png` |
| Side-wall lever up/down, depths 1-3 | `art_src/fx/lever_contact_4x.png` |
| Inset pressure plate up/down, depths 1-3 | `art_src/fx/plate_contact_4x.png` |
| Optional reduction comparison | `art_src/anim/reduction_compare_4x.png` |

## Creature files and registration

`{state}` means `idle`, `windup`, or `recoil`; `{h}` means `64`, `40`, or `24`.
Coordinates are measured from the full canvas's top-left. A bottom anchor at
`y=height` is the boundary immediately below the last pixel, not a pixel index.

| File pattern | 64 px canvas / anchor | 40 px canvas / anchor | 24 px canvas / anchor |
| --- | --- | --- | --- |
| `assets/art/anim/bell_husk_{state}_{h}.png` | 64x64 / (32,64) | 40x40 / (20,40) | 24x24 / (12,24) |
| `assets/art/anim/porter_restored_{h}.png` | 70x64 / (35,64) | 44x40 / (22,40) | 26x24 / (13,24) |
| `assets/art/creatures/ash_hound_{state}_{h}.png` | 96x64 / (48,64) | 60x40 / (30,40) | 36x24 / (18,24) |
| `assets/art/creatures/wick_ghost_{state}_{h}.png` | 80x64 / (40,64) | 50x40 / (25,40) | 30x24 / (15,24) |

The anchors mean feet/bottom-centre; the Ghost's is its hover baseline.
Each three-pose set also has `{name}_strip_{h}.png`, a horizontal sheet exactly
three canvas widths wide and one canvas height tall, in idle/windup/recoil
order. Individual PNGs and strip crops are byte-identical in indexed pixels.

Select distance with the existing `<1.5`, `<2.5`, otherwise-far thresholds.
Keep canvas size and aspect ratio across states. Do not crop every state to its
opaque bounds or scale every pose to fill the canvas: that would enlarge the
Hound crouch and erase the tell. Use opaque bounds for interaction/occlusion
only. These are state poses, not a repeating three-frame animation.

- Husk idle has two low hands; wind-up holds the viewer-left stone fist above
  the bell crown; recoil tilts the bell and slumps. Map simulation `recovery`
  to `recoil`. Remove the old extra four-pixel recovery drop/tint if selecting
  the new pose; its posture already communicates recovery on the same feet.
- Porter keeps the old waiting files and swaps to `porter_restored_{h}.png`
  when restored. Its palms rise and its circular chest lights. The new files
  exactly match the old canvas dimensions; replace the procedural chest glow
  with this pose, or keep any extra glow subtle enough to retain the dark rim.
- Hound lowers and widens before its lunge; recoil has lifted forelegs and
  its muzzle thrown back. A pacified Hound can use idle. No new simulation
  enemy or FOOD interaction is implemented here.
- Ghost brightens and raises its sleeves for wind-up. Recoil has an empty hood
  and separated cloth. On dispel, show recoil and fade the whole sprite over
  about 180 ms, then remove it; this needs no extra image frames. Keep the
  existing large danger cue and short text as reinforcement for all tells.

At 24 px, the Ghost wind-up reads best: a bright wide V against its narrow
idle. The raised Husk fist remains clear, and its recovery lean reads well.
The Hound crouch is visibly flatter, but its dark idle and recoil are weakest
against a dark dungeon. Its eyes/teeth become tiny, so use silhouette and the
lane cue. The restored Porter's bright circular chest survives, while its
fingers and actual clapper are necessarily lost. These judgements are from
the reduction sheets; final lamp/background/phone acceptance is still needed.

## Attack and number effects

All effects use a **64x64 canvas, anchor (32,32)** at the target's torso/centre,
not its feet. Paths are `assets/art/fx/{name}_{i}_64.png`, where names are
`edge`, `heavy`, `hands`, `damage_burst`, and `i` is 0, 1, 2. Alternatively,
`{name}_strip_64.png` is 192x64, horizontal frames in that order.

Suggested playback: 80 ms per frame, 240 ms total, once per accepted hit.
EDGE is a thin diagonal cut; HEAVY has a broad blunt amber burst; hands have
a compact four-way knock. They contain no weapon or full-screen flash.
Keep combat time in the simulation; effect completion must not advance a turn.
At greater distance, use nearest scaling if necessary rather than smooth filtering.

Damage burst pixels leave x17..46, y22..40 free for native **VETKA 16 px** text.
Centre the actual damage value at local x32, baseline y31; a dark one-pixel
shadow can sit at (+1,+1). One to three digits fit. Draw digits at native 16 px
even for distant enemies: scale the burst separately if necessary. Move number
and burst upward together by 0/2/4 px over the three frames. The demo uses 1/2/3
as examples; the production burst has no baked-in text.

## Wall lever and floor plate

Lever files: `assets/art/fx/lever_{left|right}_{up|down}_d{1|2|3}.png`.
The perspective is already skewed for a side wall. Use left files on the
viewer's left wall, mirrored right files on the right. These use a **wall
hinge anchor**, the intentional exception to the floor/feet convention:

| Depth | Canvas | Left hinge anchor | Right hinge anchor |
| --- | --- | --- | --- |
| 1 | 32x40 | (16,22) | (15,22) |
| 2 | 20x26 | (10,14) | (9,14) |
| 3 | 12x16 | (6,8) | (5,8) |

Place the hinge on the wall face about hand height, using wall projection and
occlusion. Do not draw it at the ordinary floor-object ground coordinate.
Swap `up` to `down` immediately when used; keep the spent lever visible.
The current latch target disappears once latched, so rendering the used state
must not depend solely on that active-target list. Keep the interaction target
at least 18x18 logical px, even where the far decoration is smaller.

Plate files: `assets/art/fx/plate_{up|down}_d{1|2|3}.png`, where `down` means
pressed by the Finder or a HEAVY object. All are front-on floor trapezoids:

| Depth | Canvas | Floor bottom-centre anchor |
| --- | --- | --- |
| 1 | 64x20 | (32,20) |
| 2 | 40x12 | (20,12) |
| 3 | 24x8 | (12,8) |

Draw them flush with the flagstone plane. Their border is only one pixel deep;
there are no legs, standing pedestal, vertical fascia or floating shadow.
Preserve the listed shallow aspect ratio: the old minimum 24 px fixture height
would turn the distant plate upright again. Underfoot can use d1 clipped by the
view's bottom edge, with its own floor projection instead of the old tall box.
The dimmer pressed centre and changed rim indicate the sunk state.

## Rebuild and checks

Build instructions and exact prompts: `art_src/anim/README.md`,
`art_src/anim/prompts.json`, `art_src/creatures/README.md`, `art_src/fx/README.md`.
Saved paintings are untouched under the relevant `sources/` folders.
Machine-readable manifests beside the builders list every runtime path, exact
size, anchor, source/extraction metadata and SHA-256.

The first-batch `python art_src/anim/verify_art.py` passed for **73 runtime PNGs and 13 exact
4x contact sheets**: hashes, dimensions, shared palette tables/indices, binary
alpha, and each strip frame match its individual PNG. Two consecutive builds
also reproduced identical derived files. This does not establish in-game or
phone acceptance. Keep `art_src/*` out of Android exports; only the new
`assets/art/anim/`, `assets/art/creatures/`, `assets/art/fx/` files are runtime art.

## M3c: FIRE, EDGE, GLOW and the objective

This batch adds **78 fixture PNGs plus 21 new Hound PNGs**, all using the same
palette, binary alpha and nearest filtering. Original Hound and first-batch
files remain available. No simulation, renderer, controller, catalog or scene
was changed by B. Runtime fixture root: `assets/art/fixtures/`.

### Review sheets

Every sheet has a matching `_native.png` beside its exact 4x enlargement.

| Set | Contact sheet |
| --- | --- |
| Standing brazier, cold / two lit frames | `art_src/fixtures/brazier_contact_4x.png` |
| Reed torch, unlit / two lit frames | `art_src/fixtures/reed_torch_contact_4x.png` |
| Thick corridor web, intact / two burning / burnt | `art_src/fixtures/web_contact_4x.png` |
| Cord-bound grate, intact / cut | `art_src/fixtures/cord_grate_contact_4x.png` |
| Side-wall grate option, intact / cut | `art_src/fixtures/cord_side_contact_4x.png` |
| Scored panel, both floor masonry families | `art_src/fixtures/panel_contact_4x.png` |
| Torch unlit/lit and Seal inventory icons | `art_src/fixtures/icons_contact_4x.png` |
| Dawn Seal on pedestal, two pulse frames | `art_src/fixtures/dawn_seal_contact_4x.png` |
| Ember Hound, three poses at all distances | `art_src/creatures/ash_hound_ember_contact_4x.png` |
| Old/new Hound at 24 px, including lamp-tint comparison | `art_src/creatures/ash_hound_lamp_compare_4x.png` |

### Depth canvases and anchors

`d1`, `d2`, `d3` use the existing `<1.5`, `<2.5`, otherwise-far distance bands.
Coordinates below refer to the complete transparent canvas. The bottom anchor
is a boundary at `y=height`. Do not crop each state's opaque bounds before
drawing: the cold/unlit canvas deliberately reserves space for fire, and the
object must stay still when its flame starts. Opaque bounds remain useful for
hit testing; preserve the minimum 18x18 logical-pixel touch target separately.

| Filename pattern under `assets/art/fixtures/` | d1 canvas / anchor | d2 canvas / anchor | d3 canvas / anchor |
| --- | --- | --- | --- |
| `brazier_{cold,lit_0,lit_1}_dN.png` | 64x64 / (32,64) | 40x40 / (20,40) | 24x24 / (12,24) |
| `reed_torch_{unlit,lit_0,lit_1}_dN.png` | 32x48 / (16,48) | 20x30 / (10,30) | 12x18 / (6,18) |
| `web_{intact,burning_0,burning_1,burnt}_dN.png` | 64x64 / (32,64) | 40x40 / (20,40) | 24x24 / (12,24) |
| `cord_grate_{intact,cut}_dN.png` | 64x64 / (32,64) | 40x40 / (20,40) | 24x24 / (12,24) |
| `dawn_seal_{pulse_0,pulse_1}_dN.png` | 64x64 / (32,64) | 40x40 / (20,40) | 24x24 / (12,24) |

Brazier, dropped torch and Seal use the ordinary floor bottom-centre anchor.
The brazier is a squat standing iron bowl: `cold` is inert; lit frames are
the renewable LIGHT source. The torch is a bundle of reeds with a leather grip;
its world sprite has one continuous pale stem so it remains legible at distance.
Do not stretch its far 12x18 canvas to the old minimum 24-pixel fixture height.
The Seal's low pedestal is part of its world sprite; its icon has no pedestal.

Web and front grate instead fill a **doorway/corridor face**, with their bottom
edge on the opening's threshold. Project onto that opening's plane; they are
not small loose props halfway across a floor cell. Transparent areas reveal
the existing view beyond. The intact cord ties the grate shut; `cut` leaves
frayed ends and the grate raised into the lintel. It does not represent a
separate key lock. Retain the used/cut or burnt decoration after the action,
even when the corresponding active interaction target has disappeared.

For a side opening, use `cord_grate_{left,right}_{intact,cut}_dN.png` instead.
The skew is already baked into these optional variants:

| Depth | Side canvas | Left wall-centre anchor | Right wall-centre anchor |
| --- | --- | --- | --- |
| d1 | 32x48 | (16,24) | (15,24) |
| d2 | 20x30 | (10,15) | (9,15) |
| d3 | 12x18 | (6,9) | (5,9) |

These are wall-centre anchors like the lever's wall hinge, not floor-object
coordinates. Keep them on the correct wall face and use its occlusion.

### Fixed states and animation

| Set | Animation | Suggested timing | Fixed states |
| --- | --- | --- | --- |
| Brazier | `lit_0`, `lit_1`, repeat | 180 ms each | `cold` |
| Reed torch world | `lit_0`, `lit_1`, repeat | 180 ms each | `unlit` |
| Web | `burning_0`, `burning_1` | 120 ms each; two cycles if desired | `intact`, then permanently `burnt` |
| Dawn Seal | `pulse_0`, `pulse_1`, repeat | 700 ms each | None while displayed |
| Cord/grate | No loop; swap when cut | Immediate | `intact`, `cut` |
| Marked panel | No loop; select from GLOW/reveal state | Immediate | `plain`, `revealed` |
| Inventory icons | No animation | Static | Unlit/lit torch; Seal |

All flame changes are just two frames. The web's four-image state strip is
**not a four-frame repeating animation**: only its two burning images alternate.
The burning images share one partly opened web topology, so flicker does not
regrow silk. Burnt leaves only short charred strands at the edges. Commit
mechanics/save state before playing the fire transition; it never spends
additional turns or re-blocks an opened route after loading.

Each front-facing set also has `{name}_strip_dN.png`, horizontal frames in the
same order as its filename row above. There are three frames for brazier and
torch, four web states, two for cord/grate and Seal. `manifest.json` records
the exact frame size/count/order; individual files match the strip crops.

### Scored wall panels and icons

The marked panel is a **64x64 wall UV texture**, not a ground billboard.
Use `panel_{f1,f2}_{plain,revealed}_64.png`, selecting the matching wall family.
All four are opaque. UV origin is top-left; bottom-centre reference is (32,64).
The ordinary wall renderer supplies projection at depths 1-3 and any side wall;
do not enlarge a second pre-rendered billboard over it. The outer two-pixel
ring is unchanged from the corresponding frozen C wall sample, so seams hold.

Plain shows a faint scored dawn arch and rays, enough to recognise a taught
clue. Revealed adds quiet mint/gold light under GLOW. Revelation alone does
not open the wall: EDGE/secret rules remain the simulation's decision. The
transparent `panel_sigil_{plain,revealed}_64.png` overlays carry the same mark
for other wall materials; use the same 64x64 face UV and anchor.

Icons are `reed_torch_icon_unlit_16.png`, `reed_torch_icon_lit_16.png` and
`dawn_seal_icon_16.png`: **16x16, centre anchor (8,8)**, no animation. They are
new files in `assets/art/fixtures/`; they do not overwrite C's possession icons.
The torch icon must follow the actual item's lit state. The Seal icon matches
the world's gold rim, teal enamel and luminous sun core.

### Ember Hound replacement

New body files are `assets/art/creatures/ash_hound_ember_{idle,windup,recoil}_{64,40,24}.png`.
They preserve the first batch's canvas sizes: 96x64 / (48,64), 60x40 / (30,40),
36x24 / (18,24). Their three horizontal strips use idle/windup/recoil order.
Use the complete new set together; do not alternate it with the old dark set.
Recovery still selects recoil; feeding can retain idle. There are no extra
animation frames or changes to the announced lunge.

The body now has lighter cool ash planes, connected warm cracks and rim light
around ears, muzzle, shoulder, feet and tail. At 24 px the crouch and recoiling
neck remain visibly distinct. All three read better than the original under
the comparison's dim tint, though a uniformly darkened emissive edge is still
dark. An optional aligned colour layer addresses that renderer limitation:

`ash_hound_ember_glow_{idle,windup,recoil}_{64,40,24}.png`

These nine files contain only the hottest amber inks from the matching body.
They have the identical canvas and bottom-centre anchor. After drawing the
body with lamp tint, draw its glow file in the same rectangle with about
0.85 RGB gain, without applying the lamp factor again. This is an ordinary
colour pass, not additive blending, a shader requirement, or another animation
frame. The lamp-comparison sheet shows approximate 35% body / 85% glow output,
re-quantized to the shared palette. Actual in-game/phone acceptance is pending.

### Reproducibility and current validation

Prompts, source/ref metadata and complete build instructions:
`art_src/fixtures/prompts.json`, `art_src/fixtures/README.md`.
Rebuild with `python -B art_src/fixtures/build_m3c.py` and
`python -B art_src/creatures/build_ember_hound.py`; preserved paintings and wall
snapshots are the inputs. The manifest beside each builder gives every path,
anchor, timing, SHA-256 and strip layout. Builds never start Godot or write old
art. Keep authoring sources/review sheets out of the Android export.

The expanded `python -B art_src/anim/verify_art.py` passes for **172 total B
runtime PNGs and 23 exact 4x contact sheets**, including both batches. It checks
manifest hashes, dimensions, palette tables, binary alpha and every strip
frame. The new Seal phases also have identical alpha at every depth and differ
only in their coloured core. A repeated rebuild reproduces all derived files.
