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

## Architecture and the interaction glint

The next pack supplies **130 architectural PNGs and 16 glint PNGs**. All are
new files under `assets/art/fixtures/`; the earlier assets and C's wall faces
remain untouched. B supplies art and placement notes here; replacing the old
mid-cell fixtures in the renderer belongs to A. There was no Godot/game run
for this asset-only batch.

### Architecture review and matching C

| Sheet | Path |
| --- | --- |
| All floor-one faces at 64/40/24 px | `art_src/fixtures/architecture_f1_contact_4x.png` |
| All darker floor-two faces at 64/40/24 px | `art_src/fixtures/architecture_f2_contact_4x.png` |
| Left/right projections and depth variants | `art_src/fixtures/architecture_sides_contact_4x.png` |
| Gates over a checkerboard to show true apertures | `art_src/fixtures/architecture_gate_overlay_contact_4x.png` |
| New arch beside the exact neighbouring masonry | `art_src/fixtures/architecture_seams_contact_4x.png` |
| Gold and selected-target glints, both sizes | `art_src/fixtures/glint_contact_4x.png` |

Each has a paired `_native.png`; the review PNG is exactly 4x nearest-neighbour.
These are asset/projection reviews, not screenshots from the integrated game.

C's painted repaint was available. This pack freezes its
`assets/art/env/painted_f1_plain_0.png` and `painted_f2_plain_0.png`, plus its
painted arch/door references, under `art_src/fixtures/architecture/sources/`.
The floor-one material retains the owner's original dirty painted stone;
floor two is C's darker damp repaint of those same stones. No fallback to
the older clean three-shade masonry is used. The frozen source hashes are
recorded so a future material change is explicit, not picked up mid-build.

The centred arch follows C's footprint: outer rounded shape x9..54, crown y5;
inner opening x18..45, apex y15; threshold above the bottom two wall rows.
One painted, chipped arch is shared across every kind/state within a floor.
Outside the inset opening, the seven canonical faces are pixel-identical.
Their complete outer two-pixel border exactly matches the frozen C material.
C's decorative arch/door faces can remain decoration/fallback; these new names
are for functional architecture. Select the same `painted_fN_` wall family
around them so the room continues to look like one aged dungeon.

### Canonical wall faces

Pattern: `assets/art/fixtures/architecture_f{1,2}_{kind}_64.png`.
Every canonical face is **64x64, fully opaque, wall UV origin (0,0)**.
Its threshold reference point is **(32,62)**. There is no feet anchor for
placing this whole texture as a loose floor object.

| Kind | Intended fixture/state and visible cue |
| --- | --- |
| `exit` | Iron-banded oak door fitted into its arch; thin ivory daylight under the sill |
| `stairs_down` | Recessed below-floor well; a short diagonal flight drops into black, with visible tread tops |
| `stairs_up` | Broad front-facing risers climb toward a faint light high in the recess |
| `gate_closed` | Portcullis bars and braces lowered to the threshold |
| `gate_open` | Bars raised into the lintel; teeth remain high, lower opening clear |
| `lift_dead` | Dark cage platform flush with threshold, bowed slack chains, cold lamp and corner cobwebs |
| `lift_working` | Same platform height; chains taut, cobwebs gone, warm alcove lamp lit |

All seven kinds have both floor materials. Exit is currently meaningful on
floor one, but the second material is available if a later layout needs it.
Keep down and up as separate textures: the dark diagonal descent is deliberately
different from the tall lit upward flight, even at the 24 px review size.
The lift changes state once from the authoritative restoration flag; no extra
flicker/platform travel frames are required or supplied in this pack.

For state atlases, `architecture_fN_gate_strip_64.png` is **128x64**, closed
then open, and `architecture_fN_lift_strip_64.png` is **128x64**, dead then
working. Use per-frame UV origin (0,0). These are static state pairs, not loops.

### Wall placement, side projections and gate transparency

Use the canonical texture on the actual wall or architectural portal plane,
through the wall renderer's normal UV/perspective sampling. Select a stable
fixture face from the layout, keyed by floor/cell/wall normal. Keep that
orientation when the Finder turns; it must not face the camera like a billboard.
The existing fixture's reachable cell, actions and interaction range remain
the simulation's contract. A can derive/store its backing wall orientation
without moving its logical target into an unreachable solid wall cell.

Remove the old corresponding floor sprite once the face is active. Merely
loading the new PNG into the old floor-object rectangle would leave the door,
stairs and lift standing in the middle of a cell. The face projection and
interaction cue/hit area must agree, with at least an 18x18 logical touch target
where the interaction is available. Keep architecture behind nearer actors and
props and clipped to its wall/opening plane.

Optional baked side variants are
`architecture_fN_{kind}_{left,right}_d{1,2,3}.png`. They have transparent
triangular corner margins and the whole architectural face already skewed:

| Depth | Canvas | Left threshold anchor | Right threshold anchor |
| --- | --- | --- | --- |
| d1 | 32x64 | (16,58) | (15,58) |
| d2 | 20x40 | (10,36) | (9,36) |
| d3 | 12x24 | (6,21) | (5,21) |

The anchors mark the middle of the sloping threshold, not the bottom of the
canvas. The right version is a horizontal reflection. These fixed-angle
variants are for a renderer drawing preprojected wall decorations, like the
lever/cord path. If A samples the canonical 64x64 face through DDA columns or
a projected wall quad, use that face directly at all depths and sides; do not
apply perspective to an already-skewed version. The 40/24 px front previews on
the contact sheets are nearest samples of the canonical texture, not additional
runtime files that need loading.

For a gate with a real corridor behind it, use
`architecture_fN_gate_{closed,open}_overlay_64.png`. They share the same
64x64 UV origin and contain a **genuinely transparent aperture** between/under
the iron. Their side alternatives are
`architecture_fN_gate_{closed,open}_overlay_{left,right}_dN.png`, with the same
side sizes/anchors above. Draw the real room/corridor first, then the frame
and iron. Do not substitute the opaque `gate_open_64` black recess over the
view beyond, or add a fictitious solid wall/depth column across its opening.
Closed-gate collision and target reach still come from the simulation, not
from the gaps between painted bars. Opaque gate faces are useful as previews
or deliberately dark recesses; overlays are the passage-facing choice.

Floor-two paint is already darker and wetter. Apply normal distance light
once; avoid another floor-specific dark-blue tint. The exit crack, upper stair
light and working lift lamp deliberately retain warm highlights in that palette.

### Three-frame sparkle

Files: `assets/art/fixtures/glint_{gold,target}_{0,1,2}_{9,7}.png`.
The gold family marks an ordinary interactable. The target family uses mint/
teal and marks a valid target for the selected item; selection validity remains
the existing interaction logic. Both are original crisp integer pixel drawings
with binary alpha, no painted blur or opacity gradients.

| Size | Intended use | Canvas-centre anchor |
| --- | --- | --- |
| 9x9 | Near/middle target, or projected object height >=32 logical px | (4,4) |
| 7x7 | Smaller/far target | (3,3) |

Use at native screen-pixel size with nearest filtering; do not shrink the 9 px
frame fractionally to invent a far size. `glint_{gold,target}_strip_{9,7}.png`
contains the same three frames horizontally, **27x9** or **21x7**. Every frame
shares the anchor; place it at the existing projected object cue position.
Replace the old static gold mark, retaining any separate selection corners
that communicate a different state. Sparkle absence never disables an object
or shrinks/moves its hit area, and glints should not cover enemy attack tells.

Suggested burst: frame 0 for **70 ms**, frame 1 for **100 ms**, frame 2 for
**90 ms**, then draw nothing for **1940 ms**. Total period **2200 ms**.
The blank interval needs no fourth PNG. Stagger each object with a cached
stable phase from floor + object ID, independent of gameplay RNG. A simple
unmixed string checksum can put sequential IDs only one millisecond apart;
use a mixed hash so the objects do not twinkle in unison. For example:

```gdscript
func glint_phase(signature: String) -> int:
    var value: int = 2166136261
    for index in range(signature.length()):
        value = ((value ^ signature.unicode_at(index)) * 16777619) & 0xffffffff
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0xffffffff
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0xffffffff
    return (value ^ (value >> 16)) % 2200

# Cache phase per "%d:%s" % [floor_number, object_id].
# Use the same phase when switching gold/target colour.
var local_ms: int = (presentation_ms + phase_ms) % 2200
var frame: int = 0 if local_ms < 70 else (1 if local_ms < 170 else (2 if local_ms < 260 else -1))
# frame == -1: draw nothing; interaction remains available.
```

Use presentation time, not committed turns. Cache textures/phase values and
queue a redraw while a visible cue changes frame; a 20-30 Hz presentation tick
is adequate. Do not reload textures, allocate images or advance simulation RNG
per frame. Hide the cue on menus/end screens just like the existing world cues.

### Sources, rebuilding and checks

Painted sources and C's frozen reference pixels are under
`art_src/fixtures/architecture/sources/`; exact built-in imagegen requests are
in `art_src/fixtures/architecture_prompts.json`. The targeted down-stair
correction and retained rejected image are documented in that folder's README.
`build_architecture.py` recreates all faces, side projections, transparent
overlays, strips, manifests and review sheets. `build_glint.py` recreates the
pixel sparkle. Both run offline without starting Godot, and the game has no
Python or authoring-service dependency.

The shared palette still has exactly 31 opaque inks plus transparent index 0.
Current validation passes for **318 B runtime PNGs and 29 exact 4x contact
sheets across all batches**: SHA-256, sizes, palette tables, binary alpha and
strip pixels. The architecture builder additionally checks opaque canonical
faces, the exact common arch outside the inset, and C-matching border pixels.
Floor-one/two gate alpha is identical for the same state, so darker paint does
not destroy the iron silhouette. Repeated rebuilds reproduce all derived files.
Actual wall attachment, looking through an open gate, target occlusion and
phone readability remain A/owner integration acceptance.

## Finder's held items: bottom-right overlay

The held-item batch adds **23 poses and 11 horizontal strips (34 PNGs)** under
`assets/art/hands/`. The Finder has one worn brown full-finger leather glove,
ochre seams and a teal-wrapped sleeve, matched to the accepted portrait.
Every pose is a transparent **48x56** canvas, including fist and short items;
the visible silhouettes are approximately 40-56px tall. These are foreground
overlays at a fixed size, with **no distance/depth scaling**.

The anchor is **bottom-right (48,56)**, an exclusive edge coordinate. For the
148x150 view, draw the complete frame at **view-local (100,94)**. With the current
`VIEW_RECT` origin (3,21), this is root-logical (103,115). The sleeve meets the
bottom crop and is cut by the right/bottom view frame. Every pose, including
blows and ring lines, stays inside the rightmost 48 pixels: view x=0..99 remains
untouched. Keep this registration across items; do not center each opaque bbox.

Runtime filename pattern:
`assets/art/hands/hand_<kind>_<state>_56.png`.
Matching strip: `hand_<kind>_strip_56.png`. Strip cells are 48x56, left to right
in the table's order; two-state strips are 96x56, the clapper strip is 144x56.

| Kind / intended item | Frames in strip order | Suggested presentation timing |
| --- | --- | --- |
| `fist` / bare hands | `rest`, `punch` | Hold rest; punch 110ms, then rest |
| `knife` / rust knife | `rest`, `slash` | Slash 100ms, then rest |
| `shard` / glass shard | `rest`, `slash` | Slash 100ms, then rest |
| `club` / iron club | `rest`, `blow` | Overhead blow 140ms, then rest |
| `stone` / round stone | `rest`, `blow` | Overhead blow 140ms, then rest |
| `bone` / ham bone | `rest`, `blow` | Overhead blow 140ms, then rest |
| `clapper` / brass clapper | `rest`, `blow`, `ring` | Blow 140ms; ring/use 220ms; then rest |
| `lamp` / hooded lamp | `rest`, `sway` | Hold up at rest; sway 160ms after step/use |
| `torch_unlit` / unlit reed torch | `rest`, `use` | Use 120ms, then rest; switch kind when lit |
| `torch_lit` / lit reed torch | `a`, `b` | Loop 130ms + 170ms; same hand pixels in both |
| `seal` / held Dawn Seal | `a`, `b` | Loop 700ms + 700ms; same pose/alpha, core-only pulse |

These are compact action endpoints, so use the existing target effects to sell
contact. The heavy pose turns the weight down toward the target; it should
return directly to rest without moving the overlay across the corridor.
The clapper's extra ring pose includes native gold sound lines. The two lit
torch frames keep the painted hand/reeds fixed and change only the crisp native
flame. The Seal retains its sun rim, teal enamel and ivory arch core; its pulse
changes only the face's brightest inks, leaving the glove and sleeve fixed.

### Wiring for A

Select the held kind from the equipped weapon or the item explicitly being used;
`fist` is the unarmed fallback. The Seal can be selected for the walk home.
This is one visible right hand: lamp/torch/Seal art replaces the weapon overlay
while held up rather than adding a second copy of the sleeve. The assets do not
change equipment, lamp state or simulation timing themselves.

Cache textures or atlas regions; draw a single frame at native scale with
nearest filtering. Clip to the view. Draw after the world, creatures and world
glints, before the surrounding UI. Keep the authored warm window/flame/Seal
highlights visible when applying scene darkness; depth shading is inappropriate
for this foreground layer. Hide the overlay when the first-person view is hidden.
Use presentation milliseconds for pose resets/flicker/pulse, not committed turns
or simulation RNG. Starting an action selects its pose immediately, then resets
after the suggested duration; it does not delay the actual simulation action.

### Review and reproduction

| Review | Path |
| --- | --- |
| Every item and pose | `art_src/hands/hands_contact_4x.png` |
| Fist, EDGE and HEAVY poses | `art_src/hands/hands_weapons_4x.png` |
| Lamp, torches and Seal | `art_src/hands/hands_utility_4x.png` |
| Every rest pose over the corridor | `art_src/hands/hands_corridor_overview_4x.png` |
| Every pose of each item over the corridor | `art_src/hands/<kind>_mockup_4x.png` (all 11 table kinds) |

All 15 final review sheets have a paired `_native.png` and exact 4x nearest
enlargement. Mock-ups use a preserved copy of
`build/m3c_shots/03_corridor.png`: 462x1026 to 154x342 nearest, view crop
(3,21,148,150). They are offline composites for placement review, not captures
of completed engine integration. The builder asserts the entire x=0..99 strip
is byte-identical before/after every overlay.

Painted sources, exact built-in imagegen prompts, the shorter-torch correction,
frozen references and an initial reduction preview are kept in `art_src/hands/`.
`build_hands.py` rebuilds this batch offline; `verify_hands.py` verifies all 34
runtime PNG hashes, sizes, unchanged palette, binary alpha, strip pixels, bottom
crop and passive-frame stability, plus all 15 review enlargements and source
hashes. `hands_manifest.json` records exact frame order, anchors and opaque
bounds for every asset. No Godot run or phone acceptance is claimed for this
asset-only batch; A/owner still need to judge motion and contrast in play.

## Phone readability: shut lift and new stair faces

The owner's supplied painting
`art_src/fixtures/architecture/sources/fe3439be-72ab-49d3-8af7-49e3b2e58160.png`
is **STAIRS DOWN**, following the owner's final direction. The original stays
untouched. Its centered lit treads and receding vaults replace the impossible
old side flight. A new matching painting supplies **STAIRS UP**, with broad
front risers climbing toward a higher light and rising ceiling arches. Both
use the owner's outer arch and native carved down/up keystone chevrons.

The new **dead lift** is barred by a shut rusted folding grille: crossing iron
straps, a central latch/lock, slack chain loops, cobwebs and a broken bell-pull.
There is no lamp. Painted iron/rust edge values are strengthened for distance
readability. The working lift keeps its existing open, warm-lit art.

All **54 runtime PNGs are new files** in `assets/art/fixtures/`, with prefix
`architecture_v2_f`. Old assets, source paintings and renderer code are kept.
There is no animation in these faces: they are static architecture/state art.

### Exact filenames and placement for A

For `floor` 1 or 2 and `kind` `stairs_down`, `stairs_up` or `lift_dead`:

| File pattern | Exact size | Anchor / use |
| --- | --- | --- |
| `architecture_v2_f<floor>_<kind>_64.png` | 64x64 | Wall UV origin (0,0); canonical threshold (32,62) |
| `architecture_v2_f<floor>_<kind>_40.png` | 40x40 | UV origin (0,0); threshold (20,39); middle-distance face |
| `architecture_v2_f<floor>_<kind>_24.png` | 24x24 | UV origin (0,0); threshold (12,23); far face |
| `architecture_v2_f<floor>_<kind>_left_d1.png` | 32x64 | Projected threshold anchor (16,58) |
| `architecture_v2_f<floor>_<kind>_right_d1.png` | 32x64 | Projected threshold anchor (15,58) |
| `architecture_v2_f<floor>_<kind>_left_d2.png` | 20x40 | Projected threshold anchor (10,36) |
| `architecture_v2_f<floor>_<kind>_right_d2.png` | 20x40 | Projected threshold anchor (9,36) |
| `architecture_v2_f<floor>_<kind>_left_d3.png` | 12x24 | Projected threshold anchor (6,21) |
| `architecture_v2_f<floor>_<kind>_right_d3.png` | 12x24 | Projected threshold anchor (5,21) |

The current renderer samples canonical 64x64 faces by column and projects them
continuously. For these three kinds, swap `architecture_f%d_%s_64.png` to
`architecture_v2_f%d_%s_64.png`; preserve the existing path for `lift_working`,
`exit` and gates. Use the equivalent new side path if consuming the preprojected
variants. All previous UV, threshold, placement and occlusion rules still apply;
these remain wall faces, never middle-of-cell sprites. The 40/24 fronts are also
provided for review and renderers that select discrete distance art.

Floor two uses C's darker wet masonry outside the arch, a colder/darker arch
repaint, damp jamb streaks and preserved lamp-catching tread accents. Every
pixel outside the arch matches the frozen floor-specific masonry, including
the complete two-pixel seam ring. Both floors retain the shared 31 opaque inks
and transparent palette index 0; front faces are opaque, side padding is binary
transparent. Use nearest filtering.

### Review, sources and verification

All paths below start at `art_src/fixtures/readability/` and have paired native
PNGs with exact 4x nearest enlargement:

| Review | Filename |
| --- | --- |
| Floor-one fronts at 64/40/24 | `architecture_v2_f1_contact_4x.png` |
| Floor-two fronts at 64/40/24 | `architecture_v2_f2_contact_4x.png` |
| Both sides, all depths, both floors | `architecture_v2_sides_4x.png` |
| Old dead / new shut / original working lift | `lift_closed_comparison_4x.png` |
| Corridor, all three new faces plus working lift, depths 1-3 | `corridor_f1_depths_4x.png`, `corridor_f2_depths_4x.png` |
| Owner's accepted down painting, direct reductions | `owner_down_evaluation_4x.png` |
| Original M3d capture for comparison | `original_corridor_reference_4x.png` |

Corridor sheets are offline ray-cast mock-ups at 148x150 using the renderer's
FOCAL=74, HORIZON=71, lamp falloff and current floor/ceiling textures. Depths
1/2/3 correspond to wall distances 0.5/1.5/2.5, with projected face heights
148/49/30. They show actual dimming as well as the unshaded 64/40/24 contact
review. They are illustrative previews, not completed in-game captures.

I inspected the new source paintings before reducing, then reviewed fronts,
side projections, shut/working comparisons and lamp-shaded corridor distances.
At 24px the treads and keystone mark are the useful cues; fine cobwebs and
brushwork recede. No blind human classification or phone playtest is claimed.

Exact requests and preserved sources live in that folder. The unused initial
stair generations are retained as history; the final down source is always the
owner's original. `build_architecture_readability.py` rebuilds all runtime art
and main reviews offline, without Godot. `verify_architecture_readability.py`
checks 54 runtime PNGs, eight review sheets, input/output hashes, palette and
alpha, exact nearest sampling, original anchors and material seams.
