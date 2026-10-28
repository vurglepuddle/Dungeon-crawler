# UNDERCROFT art handoff: Codex B

28 October 2026. New assets are ready for renderer review. They have not been
installed into a scene or phone-tested by B. Existing root `assets/art/` PNGs
are preserved. Painted sources were made with built-in imagegen; effects and
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

`python art_src/anim/verify_art.py` passes for **73 runtime PNGs and 13 exact
4x contact sheets**: hashes, dimensions, shared palette tables/indices, binary
alpha, and each strip frame match its individual PNG. Two consecutive builds
also reproduced identical derived files. This does not establish in-game or
phone acceptance. Keep `art_src/*` out of Android exports; only the new
`assets/art/anim/`, `assets/art/creatures/`, `assets/art/fx/` files are runtime art.
