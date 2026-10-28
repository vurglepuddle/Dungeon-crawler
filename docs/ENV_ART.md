# Codex C: dressing, possessions, portraits and atmosphere

Codex C supplies this art kit for Codex A's integration. It does not change the renderer,
simulation, main scene, UI chrome, catalog, or original PNGs. Painted source
PNGs, exact built-in imagegen prompts, code drawings, deterministic reduction,
and contact sheets live in the corresponding `art_src/` folders.

**Primary revision:** use `painted_f1_*.png` / `painted_f2_*.png` for walls;
the latest **painted dressing** faces are `painted_fN_<kind>_v2.png` for
door/open door, drain, two sconce frames, chains, tapestry, crack and damp.
Use the matching `door_open_overlay_v2` for an opened live lock portal.
The large-block plain walls remain unchanged. See **Painted dressing v2**.
The decorative blockages are `painted_fN_arch_blocked.png` and
`painted_fN_door_barricaded.png` (both floors). Retire the old open-looking
`painted_fN_arch.png` from random dressing. Keep actual lock/gate art distinct.
the latest plane offer is the shared `calm_v3_floor_*` / `calm_v3_ceiling_*`
family, with `calm_v3_room_*` for matching landmark faces. The earlier
`painted_fN_floor/ceiling` and `painted_room_fN_*` set remains an alternate.
Use `map_parchment_torn_v2.png` for the new transparent map-leaf offer;
`finder_hurt_v2.png` / `finder_near_death_v2.png` for injured portraits, and the
existing unchanged `finder_fine.png` for fine. The first `f1_` / `f2_` wall
sets and original reactive portraits remain intact as alternates. The UI
materials in `assets/art/ui_offer/` are selected and wired by A.
Decorative `assets/art/props/`, earlier alternate `room_fN_*` surface
faces, a painted title logotype and an optional launcher set are also supplied. Placement,
collision and launcher selection remain A/Claude's integration decisions.
The latest ivy offer is **v4**: visibly leafy sage/ivory vines that weave
across the bronze, with larger exterior compass curls. Use the new three
`ivy_*_v4` layers in place of the thinner v3 border layers; retain the
accepted v3 sleepy skull, torch frames and 29 measured verb icons. It is all
native pixel art; A still chooses and wires the offer. The preceding addition closes
the misleading decorative doorways with solid infill and nailed barricades.
The preceding plane offer follows the F1 corridor:
calmer flags, a darker shared rib vault, varied puddles and a torn map leaf.
All previous art remains intact. See
**Small life in the story plates** below for exact playback and hold timings.
`POLISH.md` records the A/B/C features now visible in A's current source.

## Rebuild and inspect

From the repository root, with Python and Pillow installed:

```powershell
python -B art_src/env/dressing_v2/build_dressings.py
python -B art_src/env/dressing_v2/verify_dressings.py --rebuild
python -B art_src/env/verify_polish.py
```

This rebuilds only the painted dressing v2 faces, two open portal layers,
registration and proofs, from the 18 saved source paintings. For leafy ivy:

```powershell
python -B art_src/ui_offer/ivy_v4/build_leafy.py
python -B art_src/ui_offer/ivy_v4/verify_leafy.py --rebuild
```

These rebuild only the leafy v4 layers, registration and proofs; the focused
verifier also rebuilds once and compares hashes. It never rebuilds or writes
v3. The previous icon pack's builder remains
`python -B art_src/ui_offer/ivy_v3/build_ivy.py`. The closed-face
builder remains `python -B art_src/env/closed_v4/build_closed.py`.
For the preceding calm-plane / torn-map offer:

```powershell
python -B art_src/env/calm_v3/build_revision.py
python -B art_src/env/verify_polish.py
```

This rebuilds the calm shared plane family, torn map leaf and all new mock-ups.
It runs focused checks, including the pre-batch hashes of 182 earlier C PNGs.
For the preceding painted-plane proposal:

```powershell
python -B art_src/env/painted_surfaces/build_surfaces.py
python -B art_src/env/verify_polish.py
```

These rebuild only the earlier painted plane materials and mock-ups, then verify
the combined C kit. For the preceding screen-animation batch:

```powershell
python -B art_src/screens/life/build_life.py
python -B art_src/env/verify_polish.py
```

These build/check only the screen frames and verify the combined kit.
For the preceding room/identity batch:

```powershell
python -B art_src/props/build_room_pack.py
```

This rebuilds only room props, the new floor/ceiling faces, logotype and icon
offer, then verifies all C packs and the earlier PNG preservation receipts.
`python -B art_src/env/painted_v2/build_revision.py` remains the previous
painted-wall/portrait/UI-offer revision builder; it does not rebuild this batch.
`art_src/env/build_all.py` remains the first pack's original builder. Individual
revision builders are `env/painted_v2/build_painted.py`,
`portrait/v2/build_states.py`, and `ui_offer/build_offer.py` under `art_src/`.
No API, network, model or
Godot is used by the rebuild. The saved paintings are the reproducible input;
rerunning imagegen from the recorded prompts can produce different paintings.

Every runtime PNG and sheet is indexed against `art_src/spike/palette.gpl`:
31 opaque inks and transparent index 0. All sampling/enlargement is nearest
neighbour; no dithering or translucent fringes. Text on sheets uses native
VETKA 16, rendered without antialiasing. Manifests record hashes, dimensions,
opaque bounds and source hashes. Generated sources themselves keep their
original unrestricted colour and resolution. No old art is overwritten.
The UI and plane-material mockups are RGBA exceptions: they retain the saved
screenshot's renderer lighting colours in protected regions, and the latter
apply the actual lamp factors to the sampled planes. All runtime material PNGs
and contact sheets still use the shared indexed palette and binary alpha.

| Set | Native size | 4x review sheet |
| --- | --- | --- |
| Current painted wall dressings v2 | Twenty 64 x 64 faces/portal layers | `art_src/env/dressing_v2/contact_sheet_4x.png` |
| Painted dressing per floor | Ten 64 x 64 faces each | `art_src/env/dressing_v2/floor{1,2}/contact_sheet_4x.png` |
| Old shapes / painted F1 / painted F2 | Seven rows of comparison | `art_src/env/dressing_v2/comparison/contact_sheet_4x.png` |
| Painted dressing corridor | Four 148 x 150 views, d1-d3 side segments | `art_src/env/dressing_v2/mockup_corridor_4x.png` |
| Actual wooden lock door states | Closed / opaque open / transparent live route, both floors | `art_src/env/dressing_v2/mockup_doors_4x.png` |
| Painted dressing distance proof | Seven faces at depths 1, 2 and 3 | `art_src/env/dressing_v2/mockup_depths_4x.png` |
| Current leafy ivy, v4 | Game 154 x 342; compass 74 x 51; map 144 x 324 | `art_src/ui_offer/ivy_v4/contact_sheet_4x.png` |
| Current game and leafy torn-map offer | Two 154 x 342 screens | `art_src/ui_offer/ivy_v4/mockup_screen_4x.png` |
| V3 versus v4, same camera | Two 154 x 342 game screens | `art_src/ui_offer/ivy_v4/comparison_4x.png` |
| Earlier thin dead-ivy pieces, v3 | Game 154 x 342; compass 66 x 48; map 144 x 324 | `art_src/ui_offer/ivy_v3/ornament_sheet_4x.png` |
| Current verb stamps | 29 at 12 x 12; seven separate compact siblings | `art_src/ui_offer/ivy_v3/contact_sheet_4x.png` |
| All full-word verb fits | Actual 48 x 22 buttons, VETKA 16 | `art_src/ui_offer/ivy_v3/fit_sheet_4x.png` |
| Earlier thin-ivy game/map proof | Two 154 x 342 screens | `art_src/ui_offer/ivy_v3/mockup_screen_4x.png` |
| Primary walls, combined | 24 tiles, each 64 × 64 | `art_src/env/painted_v2/contact_sheet_4x.png` |
| Primary abbey stone | 12 tiles, each 64 × 64 | `art_src/env/painted_v2/floor1/contact_sheet_4x.png` |
| Primary older wet stone | 12 tiles, each 64 × 64 | `art_src/env/painted_v2/floor2/contact_sheet_4x.png` |
| Primary mixed tile repeats | 256 × 192 | `art_src/env/painted_v2/floor1/repeat_4x.png`, `floor2/repeat_4x.png` |
| Closed decorative arches/doors | Four 64 × 64 faces | `art_src/env/closed_v4/contact_sheet_4x.png` |
| Closed dressing beside a genuine open gate | Four 148 × 150 corridor views | `art_src/env/closed_v4/mockup_side_4x.png` |
| Closed dressing from the front | Four 148 × 150 corridor views | `art_src/env/closed_v4/mockup_front_4x.png` |
| Original / primary / wet comparison | Three 64 × 64 samples | `art_src/env/painted_v2/comparison/contact_sheet_4x.png` |
| First wall set, alternates + surfaces | 28 tiles, each 64 × 64 | `art_src/env/contact_sheet_4x.png` |
| Current calm shared planes + landmarks | Twenty 64 × 64 tiles | `art_src/env/calm_v3/contact_sheet_4x.png` |
| Shared calm floor family | Eleven 64 × 64 variants | `art_src/env/calm_v3/floors/contact_sheet_4x.png` |
| Shared darker vault | Three 64 × 64 variants | `art_src/env/calm_v3/ceilings/contact_sheet_4x.png` |
| Mixed calm floor repeats | 5 × 4 actual hashed cells per level | `art_src/env/calm_v3/floor{1,2}_mixed_4x.png` |
| Current whole-screen comparison + map | Five 154 × 342 screens | `art_src/env/calm_v3/mockup_all_4x.png` |
| Current world view comparison | Four 148 × 150 views | `art_src/env/calm_v3/mockup_view_4x.png` |
| Movement comparison | Three cell-centred corridor positions | `art_src/env/calm_v3/mockup_steps_4x.png` |
| Torn map material + silhouette | 144 × 324, real binary alpha | `art_src/ui_offer/torn_v2/contact_sheet_4x.png` |
| Torn leaf with A's existing ink map | 154 × 342 | `art_src/ui_offer/torn_v2/mockup_map_4x.png` |
| Earlier painted planes, alternates | Sixteen 64 × 64 tiles | `art_src/env/painted_surfaces/contact_sheet_4x.png` |
| Earlier planes, by floor | Eight 64 × 64 tiles each | `art_src/env/painted_surfaces/floor{1,2}/contact_sheet_4x.png` |
| Earlier mixed plane repeats | 3 × 3 cells per plane/floor | `art_src/env/painted_surfaces/floor{1,2}/{floor,ceiling}_repeat_4x.png` |
| Walls + planes, view mock-ups | Four 148 × 150 views | `art_src/env/painted_surfaces/mockup_view_4x.png` |
| Walls + planes, screen mock-ups | Four 154 × 342 screens | `art_src/env/painted_surfaces/mockup_screen_4x.png` |
| Possessions | 13 icons, each 16 × 16 | `art_src/icons/contact_sheet_4x.png` |
| Primary Finder states | 3 portraits, each 32 × 32 | `art_src/portrait/v2/contact_sheet_4x.png` |
| Original Finder states, alternates | 3 portraits, each 32 × 32 | `art_src/portrait/contact_sheet_4x.png` |
| Story plates | title/splash 154 × 150; endings 128 × 80 | `art_src/screens/contact_sheet_4x.png` |
| Screen animation, combined | Eleven full plates; 2–3 frames per set | `art_src/screens/life/contact_sheet_4x.png` |
| Screen animation, each set | Same native sizes as the original plates | `art_src/screens/life/{splash,title,win,death}/contact_sheet_4x.png` |
| UI material offer | Ten assets, sizes below | `art_src/ui_offer/contact_sheet_4x.png` |
| Whole-screen UI mockup, game + map | Two 154 × 342 screens | `art_src/ui_offer/mockup_screen_4x.png` |
| Room props, dry/wet overview | Seventeen near samples | `art_src/props/contact_sheet_4x.png` |
| Each room prop at depths 1–3 | Registered full canvases | `art_src/props/{kind}/contact_sheet_4x.png` |
| Overhead / underfoot interest | Twelve 64 × 64 faces | `art_src/env/room_faces/contact_sheet_4x.png` |
| Painted logotype / launcher offer | Sizes below; layer thumbnails labelled | `art_src/screens/room_batch/contact_sheet_4x.png` |
| Title illustration with logo/subtitle | 154 × 184 proposal | `art_src/screens/room_batch/title_mockup_4x.png` |

## Wall faces: texture selection only

Runtime root: `assets/art/env/`. Primary prefix `painted_f1_` means the
owner's favourite painted abbey wall; `painted_f2_` repaints that exact masonry
as older, wetter and darker. Old `f1_` / `f2_` textures are smaller-bricked,
flatter **alternates**, not the default replacement. Do not mix alternate and
primary wall faces in one room: their masonry and boundary rings differ.
Each primary prefix has these wall suffixes:

| Suffix, before `.png` | Intended use |
| --- | --- |
| `plain_0`, `plain_1`, `plain_2` | Original painted stone; local shifted-stone crop / damp stain variants |
| `sconce_0`, `sconce_1` | One fixed iron bracket; two flame states, suggested 4 fps |
| `crack` | Long single fracture, purely decorative |
| `damp` | Moss-coloured damp trails and a wet foot |
| `chains` | Two hanging lengths, no interactive promise |
| `tapestry` | Faded dawn-and-bell cloth, useful near the Porter |
| `drain` | Low iron grate, opaque background |
| `arch` | Earlier open-looking recess, preserved; retire from random decoration |
| `door` | Existing closed iron-banded door used by the live lock path |
| `arch_blocked` | New decorative arch filled solid with large blocking stones |
| `door_barricaded` | New decorative broken door with nailed beam and diagonal brace |

Wall anchor is the whole face: UV origin top left, U rightwards, V downwards,
64 × 64, fully opaque. Every wall variant within a floor shares the outer
two-pixel ring. Opposite endpoint rows/columns also match exactly. Mixed tile
repeat sheets show the shared seams. Floor-two shades are deliberately darker;
avoid stacking another strong blue/dark floor tint over them.

The primary set starts from a preserved exact copy of `assets/art/stone_wall.png`.
`painted_f1_plain_0.png` retains **3968/4096 pixels (96.875%)** exactly, including
the complete 62 × 62 interior. Only the outermost row/column ring is reconciled
to close the seams. No block grid is rebuilt. Plain 1 changes two small stone
interiors with shifted source crops; plain 2 adds a localized stain. The darker
floor uses a deterministic palette repaint and broad damp trails while retaining
the same original stones, chips, cracks and mortar. Existing editable pixel
dressing is composited on this painted substrate, with shared two-pixel edges.
`stone_wall.png` itself and every first-set PNG remain byte-for-byte unchanged.

**Codex A's renderer hook:** cache one array of 64 `AtlasTexture` strips per
texture, as the renderer currently does for `stone_wall.png`. During DDA,
record the struck cell and signed wall normal (not only the existing `side`
boolean). Pick the texture once per `(seed, floor, cell.x, cell.y, normal)`;
all columns hitting that face must share it. Use a fixed integer hash with
explicit arithmetic and modulo, not global RNG, an engine-dependent hash, or
per-column randomness. Plain variants should dominate; use sparse dressing
away from readable fixtures. Keep U orientation consistent across frames.

Select sconce frame with `int(presentation_seconds * 4) % 2`, redraw at that
rate only while a sconce is visible, and reuse cached strips. The flame has
baked local warmth but does not illuminate adjacent faces or the simulation.
Distance light and side shading still apply. A large lamp halo is unnecessary.

Wall dressing is painted on already-solid faces. Use the new blocked arch
and barricaded door for decoration; actual locks and gates follow their
authoritative fixture state and existing art paths, as detailed below.

### Floor and ceiling

The first pack's `f1_floor.png`, `f1_ceiling.png`, `f2_floor.png`, and
`f2_ceiling.png` remain alternate surface materials. The later painted and
calm families are documented below; the current offer is `calm_v3_*`.

The current `_build_surfaces()` already computes `point`, world-space `u`,
`v`, floor/ceiling side, and lamp attenuation. Replace the procedural base
colour with a cached `Image.get_pixel(u, v)` from `fN_floor.png` or
`fN_ceiling.png`, then apply the existing light. Do not load images per pixel.
Keep the surface cache and include the selected floor material in its key.
These are orthographic materials, **not** perspective pictures. Map one tile
to one world cell, with the same orientation on every cell. The ceiling has
restrained stone ribs; floor two has pooled teal water, with no gameplay hazard.

## Painted dressing v2: no flat shapes on the stone

These replace the first painted-wall set's code-drawn subjects with **18
individual built-in imagegen paintings**: nine faces/states on each floor.
Every subject is painted into the original favourite large-block masonry,
then reduced by nearest-neighbour to 64 x 64 and the shared 31 opaque inks.
There are no new code-drawn grate bars, chains, banners or damp silhouettes.
The only subsequent pixel operations register states, restore the accepted
two-pixel edge ring and cut the live doorway aperture. All old art remains.

Saved high-resolution paintings and the exact prompt/reference for every
one are in `art_src/env/dressing_v2/sources/` and `prompts.json`. Floor 2 is
an individually painted darker/wetter edit of each finished floor-1 subject,
using the existing deep stone as material reference. Its chipped joints,
porous moss and water/mineral trails retain the same physical objects.
Iron carries rust flakes and contact shadows; low-front warm lamp catches
protruding edges, with cooler dark crevices. No new UI, collision, fixture or
simulation behaviour is included.

### Files, size and registration

All files below are under **`assets/art/env/`**, replacing `N` with `1` or
`2`. All are **64 x 64**, top-left anchor `(0,0)`, and use the existing
wall-column UVs and nearest sampling. There are no d1/d2/d3 sprite copies:
one face is sampled at every distance. Scale and colour are already baked
into the texture; retain the renderer's normal distance/side lamp factor.

| New basename, `.png` | Intended use and painted details |
| --- | --- |
| `painted_fN_door_v2` | Functional locked door: carved worn stone arch, split oak grain, blackened iron straps/rivets, lock plate/keyhole and ring pull |
| `painted_fN_door_open_v2` | Same arch and threshold, left-hinged leaf swung inward, dark passage beyond; full opaque face/reference |
| `painted_fN_door_open_overlay_v2` | Same opened painting with real binary-alpha passage, for the live walk-through lock portal |
| `painted_fN_drain_v2` | Rusted iron grate recessed in chipped stone; deep gaps, lit stone lip and irregular dirt/mineral streaks below |
| `painted_fN_sconce_0_v2`, `_sconce_1_v2` | Two torch flames over the same forged basket/bracket, mounting plate, soot-stained wall and warm bounced light |
| `painted_fN_chains_v2` | Heavy uneven rusted links, wall rings, one closed and one broken cuff, iron depth and cast shadows |
| `painted_fN_tapestry_v2` | Folded, torn, moth-eaten cloth; faded bell woven into the sagging fabric, frayed hems and rod shadow |
| `painted_fN_crack_v2` | Fissure breaking stone through the joint, dark core, broken chips and a lit projecting lip |
| `painted_fN_damp_v2` | Porous olive/grey-green moss and mineral trails following mortar and stone grain; untouched stone between trails |

The opaque open face is useful for flat previews, but **the live opened lock
must use the transparent overlay**. An opaque black painting would hide the
world behind the door. The overlay's alpha aperture has no bars; its left
wooden leaf remains opaque. No portcullis art is reused for this door.

The arch, jambs and threshold outside the saved `door_interior` mask are
pixel-identical between closed and open states. The hole and inward leaf
remain registered when the lock opens. Both torches run **250 ms per frame**,
two frames, looping as before. Only the saved `sconce_flame` polygon changes;
the bracket, mounting hardware, remaining wall and soot remain fixed.
Mask PNGs and their native polygons are in `dressing_v2/masks/` and
`layout.json`. There is no extra full-wall flicker or moving masonry.

Every face, including the alpha overlay, preserves the exact two-pixel
border of its accepted `painted_fN_plain_0.png`. Opposite edge rows/columns
match, so the new faces join any existing plain variant or sealed dressing.
Mixed tile proofs are `floor1_repeat_4x.png` and `floor2_repeat_4x.png`.
The original wall, all three plain variants and the accepted sealed arch /
permanently barricaded decorative door are unchanged.

### Exact swaps for Codex A

1. In `dungeon_view.gd::_wall_path`, preserve the current stable hash and
   placement exclusions. Only `drain`, `chains`, `tapestry`, `crack`, `damp`
   and the fully expanded `sconce_0` / `sconce_1` choose the new `_v2` suffix.
   Keep `plain_0/1/2`, `arch_blocked` and `door_barricaded` paths as they are.
   The two animated sconce paths also need swapping in the prewarm loop.
2. In `_build_camera`'s **closed lock solid-cell override**, change
   `painted_fN_door.png` to `painted_fN_door_v2.png`. This is the actual key
   door, distinct from the randomly placed decorative barricades.
3. In `_architecture`, choose
   `painted_fN_door_open_overlay_v2.png` for **`kind == "lock"` with
   `fixture.open`**. Keep the existing portal-plane projection and binary
   alpha drawing, so the true deeper floor/walls/actors show through.
   Leave the gate, web and cord paths alone. Keep opened locks passable and
   preserve their current fixture IDs/hit handling; do not insert a solid
   wall face at an opened lock's cell.
4. Keep native sampling, lamp/side shading and the existing two-frame cadence.
   No new item, cue, blocker, atlas or turn-state change is required.

`dressing_v2/layout.json` is the machine-readable handoff, with file roles,
registration, masks, timing and the same path rules. This pack does not edit
the renderer or implement those swaps.

### Painting and in-view review

- `art_src/env/dressing_v2/contact_sheet_4x.png`: both complete floor sets.
- `floor1/contact_sheet_4x.png`, `floor2/contact_sheet_4x.png`: each set alone,
  including the optional opaque-open reference and production alpha overlay.
- `comparison/contact_sheet_4x.png`: old flat dressing / painted F1 / painted
  F2 for all seven original subjects.
- `mockup_corridor_4x.png`: both floors, showing a drain and chains at d1,
  tapestry and torch at d2, fissure and damp at d3. The far door is naturally
  almost black at the current renderer's 3.5-cell lamp limit.
- `mockup_doors_4x.png`: each actual door closed, open as an opaque face,
  and open as a portal showing the deeper corridor, at a readable near depth.
- `mockup_depths_4x.png`: seven faces viewed head-on at depths 1, 2 and 3,
  with the actual distance lamp factor, to judge what survives at phone scale.

All proofs have exact native counterparts. The material views are offline
proxy corridors at the same **148 x 150, focal 74, horizon 71** column
camera, using the accepted calm plane family and normal lamp/side factors.
They are illustrative material proofs, not live captures, proposed fixture
placements or a claim the runtime paths have changed. No text or monsters
were added to the views.

Rebuild with `build_dressings.py` and run `verify_dressings.py --rebuild`,
then the combined `verify_polish.py`, as shown above. The focused check
guards the old PNG hashes, all shared edges, exact arch/fixture registration,
unobstructed portal alpha, two-frame fire mask, darker floor-2 luminance,
real d1-d3 proof placement and exact 4x enlargement. Rerunning from the saved
paintings is deterministic; rerunning imagegen from the prompts may differ.
No Godot runs or commits by C. A/Claude still perform integration/phone review.

## Closed decorative arches and broken doors

The owner's phone review found that an opaque decorative arch beside a real
gate still looked like a route. These four **new** faces remove the dark
walk-through silhouette while keeping the approved painted wall substrate:

| Runtime file under `assets/art/env/` | Visible blockage |
| --- | --- |
| `painted_f1_arch_blocked.png` | Abbey arch infilled sill-to-crown with broad mortared blocking stones, including a cracked lower stone and wedged chunk |
| `painted_f2_arch_blocked.png` | The same solid infill, darker and damp with restrained teal weathering |
| `painted_f1_door_barricaded.png` | Split planks, broken/sagging iron bands, a thick nailed horizontal beam and diagonal brace; no handle/keyhole |
| `painted_f2_door_barricaded.png` | The same permanent barricade, weathered darker and wetter |

Every file is **64 × 64, fully opaque**, shared palette, anchor/UV origin
`(0,0)`. The original `painted_fN_plain_0.png` is copied exactly outside an
arched interior patch. The full two-pixel ring and opposite outer row/column
values match the existing wall family, so the new faces mix with every
accepted painted wall variant. No old arch, door or wall PNG is overwritten.
Floor two repaints the same physical stones/planks; the closure does not
change shape with floor number. Narrow mortar and split-plank cracks remain;
the central face is visibly occupied by stone or timber.

**Codex A's exact hook:** the current `_wall_path()` gives `roll == 6` the
decorative suffix `arch`. Change that choice to `arch_blocked`. To offer both
new blockages at that same density, use another stable bit of the existing
face hash to choose `arch_blocked` or `door_barricaded`; the existing
`painted_f%d_%s.png` path format then works unchanged. Cache this choice per
face, like the other dressing. Choose these only for ordinary solid wall faces.

The actual closed-lock override currently loads `painted_f%d_door.png` and
attaches the fixture ID. **Keep that functional texture path** and its
authoritative open-state handling. B's real gate/exit/stair architecture and
transparent portal overlays keep their existing paths too. The new images
have no fixture ID, action, glint, keyhole, collision or movement rule; their
job is to make ordinary blocking masonry visibly impassable. This is a
decorative path substitution, not a global replacement of every door image.

Review files, all with native and exact nearest 4x partners:

- `art_src/env/closed_v4/contact_sheet_4x.png`: four wall-face textures.
- `mockup_side_4x.png`: the four variants on the right corridor wall beside
  B's genuine open gate ahead, matching the reported oblique ambiguity.
- `mockup_front_4x.png`: each blocked face as a solid corridor end wall.
- `floor1_repeat_4x.png` / `floor2_repeat_4x.png`: each new pair mixed with
  accepted plain walls to show the shared boundaries.

The mock-ups use the same 148 × 150 camera, UV projection and light falloff
as the earlier offline material proofs, with the calm plane offer. They are
authoring comparisons in proxy corridors, not game captures. B's open-gate
overlay is read-only; all mock-up output is inside C's art source directory.
The supplied corridor screenshot is preserved as a framing reference.

Rebuild with `python -B art_src/env/closed_v4/build_closed.py`. Saved paintings,
exact built-in imagegen prompts, manifests and preservation hashes are beside
the builder. `verify_closed.py` checks the palette, opaque canvas, exact
substrate outside the patch, shared rings, repeat edges, 4x proofs and a
regression guard against a broad connected near-black opening. Original
source PNGs are retained; rebuilding is offline and needs no Godot process.

## Decorative room props: depths 1–3

Runtime root: `assets/art/props/`. These are original painted sources reduced
to the same palette and B's registration conventions in `docs/ART.md`.
All nine subjects have their own `art_src/props/{kind}/contact_sheet_4x.png`;
the overview sheet shows all dry/wet near variants together. Original source
PNGs and exact built-in imagegen prompts are retained in `art_src/props/`.

| Kind | Subject | Floor-one / floor-two variants |
| --- | --- | --- |
| `rubble` | Fallen carved masonry and mortar debris | Dust / wet stone and damp stains |
| `bone_heap` | Low bones with a clearly visible skull | Dry ivory / dark wet undersides |
| `skeleton` | Slumped remains with hanging skull and cloth scraps | Dust / damp cloth and bone shadows |
| `pots` | Two broken earthenware pots and large shards | Dust / dark glaze and wet lower edges |
| `pillar` | Complete worn stone pillar, base through capital | Dust / cold damp stone |
| `statue` | Toppled hooded stone saint, broken shoulder and open hand | Dust / wet folds and mossy shadows |
| `candles` | Three spent stubs in accumulated floor wax | Dust / damp dirt; both remain unlit |
| `crate` | Closed lost-property crate, rope handle, faded label | Dust / soaked wood and worn label |
| `puddle` | Very shallow irregular water decal | Floor two only |

Static paths are `f{1,2}_{kind}_d{1,2,3}.png`, except puddle, which is only
`f2_puddle_dN.png`. There are **51 runtime prop PNGs**. Labels are fading paint
marks, not tiny readable text. Crates are not loot containers, bones are not
the FOOD item, and these candles are not LIGHT sources. No action, fixture,
glint, item card, actor, state machine, or collision is supplied by the art.

| Prop type | d1 canvas / anchor | d2 canvas / anchor | d3 canvas / anchor |
| --- | --- | --- | --- |
| Eight standing/low clutter families | 64 × 64 / `(32,64)` | 40 × 40 / `(20,40)` | 24 × 24 / `(12,24)` |
| Puddle decal | 64 × 20 / `(32,20)` | 40 × 12 / `(20,12)` | 24 × 8 / `(12,8)` |

Anchors are the bottom-centre **boundary**, exactly as in B's brazier and Seal.
Select d1 below 1.5 depth, d2 below 2.5, otherwise d3 inside the existing view
range. Each source is fitted once to its d1 canvas, reserving true scale:
rubble and bones stay low, the skeleton sits higher, the pillar fills the
height. Every d2/d3 is an exact nearest resize of the **whole d1 canvas**.
Wet variants preserve alpha and silhouette at every depth. Never crop/refit
each opaque bound or enlarge low clutter to fill a square.

**Codex A:** cache the three textures for a chosen floor/kind, then append
render-only props to the depth-sorted sprite pass using the existing projected
floor coordinate minus the registered anchor. Keep wall/actor occlusion. Do
not route them through reachable-items, fixture actions, or interaction cues.
The puddle keeps its shallow height; the old minimum 22/24px sprite-height
clamp would make it stand upright. Its transparent regions expose the floor.

Placement remains yours: use deterministic empty-cell/corner candidates and
exclude interactables, loose loot, gates, plates, stairs, landings, exits,
encounter lanes and their needed sightlines. Do not stack clutter over an
item or create a new hidden-item puzzle. A skeleton leaning against a wall
needs a wall-adjacent placement, not the middle of an open room.

The **pillar is the special case**: its native image spans the full canvas
height. If it is used as a cell-blocking architectural pillar, generation,
collision and visibility must agree. Project its top and base to ceiling and
floor (approximately `FOCAL / depth` total height), scaling the sampled canvas
with nearest filtering. Do not rely on the PNG to block movement, place a
blocking-looking pillar over a traversable cell, or hide a wall face behind it
without supporting transparent-column occlusion. A owns that integration and
any route/solvability checks; a non-walkable wall recess is a simpler art use.

The prop manifest gives every runtime path, canvas, anchor, kind, floor, depth,
source crop and SHA-256. Rebuild just this set with:

```powershell
python -B art_src/props/build_props.py
```

## Current offer: calm shared flags and a darker rib vault

This follows the owner's review of the first painted-plane proposal. The F1
corridor is the material reference for both floors. The new ceiling uses that
same abbey X-rib vault everywhere; floor two adds sparse roots/drip stains,
not the earlier rough-rock ceiling. Painted stone faces are quieter, joints
remain readable, and floor two gets water more often through selection rather
than a different repeating base texture. All older files remain unchanged.

Runtime root: `assets/art/env/`. Every plane below is **64 × 64, opaque**,
top-left anchor `(0,0)`, using the same shared palette. One texture repeat is
one movement cell. All eleven floors share the **same full two-pixel border
ring**, including across floor numbers. All ceiling variants share a second
common border ring. Any floor/floor or ceiling/ceiling combination tiles.

### Floor names and selection weights

Use `calm_v3_floor_{name}.png`. Weights are percentages, in table order:

| Name | Material / landmark within the cell | Floor 1 | Floor 2 |
| --- | --- | ---: | ---: |
| `dry_a` | Quiet painted flags, worn joints | 28 | 14 |
| `dry_b` | Different stone arrangement / wear | 24 | 12 |
| `dry_c` | Third stone arrangement / wear | 21 | 10 |
| `stain` | One small old brown stain | 10 | 6 |
| `chip` | A shallow chipped flag edge | 8 | 5 |
| `crack` | Short, fine branched fracture | 6 | 5 |
| `wet_small` | Small irregular pool low on the left | 3 | 10 |
| `wet_hook` | Two-lobed hooked basin on the left | 0 | 10 |
| `wet_corner` | Larger angular pool in the lower right | 0 | 10 |
| `wet_split` | Two separate pools at different positions | 0 | 9 |
| `wet_wide` | Broad uneven basin across the middle | 0 | 9 |
| **Total** | Same assets and border colours on both levels | **100** | **100** |

Floor one uses seven variants, with a small puddle on 3% of cells. Floor two
uses all eleven, with wet variants weighted at 48% and several larger shapes.
These are distribution weights, not a promise about every short corridor.
The five pools have different footprints, centroids and reflection positions;
none touches the outer cell joint. Water follows the stone's existing colour
clusters beneath it. These are static shallow damp patches, not pits, hazards,
items, animated liquid or interaction cues.

### Ceiling names and selection weights

Use `calm_v3_ceiling_{name}.png`:

| Name | Floor 1 | Floor 2 | Appearance |
| --- | ---: | ---: | --- |
| `plain` | 98 | 82 | The darker, quieter F1 rib vault |
| `root` | 0 | 10 | Same vault plus one small root at a corner |
| `drip` | 2 | 8 | Same vault plus one short damp stain |

The new plain vault has about **69% of the previous F1 ceiling's mean
luminance**, before the unchanged renderer lighting. Its original corner-to-
centre rib layout remains. The calm dry floor's adjacent-texel contrast is
about **47% of the previous painted F1 floor**, measured inside the border.
These are offline image metrics, not a claim about phone perception or speed.
`art_src/env/calm_v3/verification.json` stores the measurements.

### Stable per-cell choice: exact rule for A

Use the existing `PresentationArt.mix_hash`, with the exact UTF-8 key:

```text
{seed}/{floor}/{plane}/{cell_x}/{cell_y}
example: BELL42/2/floor/10/9
roll = PresentationArt.mix_hash(key) % 100
```

Clamp floor to 1–2 for material selection. `plane` is literally `floor` or
`ceiling`; cell coordinates are signed integers from `floor(point.x)` and
`floor(point.y)`. Walk the applicable table in order, subtracting each weight
until `roll < weight`; that row names the image. Skip zero-weight rows.
Cache the resulting image per seed/floor/plane/cell; never choose by screen
column, UV texel, camera facing, frame, turn or simulation RNG. A turn away
and back must show the same puddle, and walking one cell must reveal the next
cell's already-fixed choice. Keep world north and the existing UV projection.

`art_src/env/calm_v3/selection.py` is a small authoring reference with an exact
port of the current hash, and `selection.json` records ordered weights and
known input/hash/choice samples for A's integration checks. Do not load Python
or `art_src/` at runtime; copy these constants/rule into A's presentation code.

**A's integration:** replace the single `f%d_floor.png` and `f%d_ceiling.png`
choice in `_build_surfaces()` with the cached world-cell choice above. Keep
the current 64-texel UV scale, horizon, lamp function and floor/ceiling gains.
Disable the existing procedural `grain` lightened/darkened branch **for this
material family**: its added speckles would undo the quieter painting. Keep
the surface cache keyed by material revision as well as the current view.

Six matching landmark alternatives are also supplied as
`calm_v3_room_floor_{drain,cracked,compass}.png` and
`calm_v3_room_ceiling_{roots,chain,boss}.png`. They use the same border rings.
The cracked/root faces match the restrained ordinary crack/root; the other
landmarks are rebased and subdued. They are **outside the ordinary weight
tables**: A may retain deliberate room landmarks. The compass still points
toward negative world Y; do not rotate that face.

### Current mock-ups

- `art_src/env/calm_v3/mockup_all_4x.png`: corridor and room on both floors,
  plus the torn map, using the supplied M3d framing/UI.
- `mockup_view_4x.png`: those four views without the surrounding interface.
- `mockup_steps_4x.png`: three static floor-two corridor views one cell apart;
  the actual stable selector changes the visible wet patches along the route.
- `floor1_mixed_4x.png` / `floor2_mixed_4x.png`: twenty hashed world cells per
  floor, showing shared joints and the different dry/wet distribution.

All have native and exact nearest 4x partners. These are offline material
mock-ups using the same camera/UV/light equations and simple proxy spaces,
with the added procedural grain intentionally disabled. They are not new
Godot captures or reconstructed BELL42 gameplay. The M3d interface outside
the view is preserved; floor-two material captions identify the level while
the copied source interface retains its original state text.

Recipe and preserved sources: `art_src/env/calm_v3/`. Rebuild the complete
revision, including the torn map and focused checks, with
`python -B art_src/env/calm_v3/build_revision.py`. No Godot runs are needed.

## Previous painted floor and ceiling planes: alternates

This earlier painted proposal superseded the original cleaner `fN_floor.png`
and `fN_ceiling.png` bases. It remains intact as an alternate after the owner's
latest calm/shared-family direction above. Match its `painted_room_fN_*`
derivatives if choosing this older family; its borders differ from calm v3.

| New runtime base under `assets/art/env/` | Material |
| --- | --- |
| `painted_f1_floor.png` | Worn, uneven abbey flags; grime joints, chipped edges, scuffed faces, small stains and subdued damp |
| `painted_f1_ceiling.png` | Stone rib vault: diagonal X ribs meet at the cell centre; rough infill, soot at the crossing and a little damp |
| `painted_f2_floor.png` | Older, darker slick flags; cold standing water and sediment in low joints, mineral stains and worn ochre-grey edges |
| `painted_f2_ceiling.png` | Rough-hewn eroded rock vault; damp ridges, mineral/drip trails and sparse roots in a fissure |

**Stone ribs were chosen over timber** because the space is an abbey
undercroft. A thick diagonal X reads as a vault at the 148px view width, and
its corner connections continue into neighbouring cells. The game still
samples a flat ceiling plane; the ribs supply painted relief, not curved
geometry. No new wall height, collision, shadows or mesh is required.

All four bases and all twelve matching variants are **64 × 64, fully opaque,
indexed to the shared 31-colour palette**, with top-left origin `(0,0)`.
They are painted from the approved stone wall's material reference and reduced
with nearest-neighbour sampling. Broad irregular painted stone clusters stay
visible; no smooth procedural replacement or dither pass is applied. Floor
two receives a restrained cold/darker palette pass after painting, before
reduction. Keep the current renderer's lamp/floor/ceiling factors.

### Rebased room faces

Use the same six kinds per floor, with the new prefix:

- `painted_room_f{1,2}_floor_drain.png`
- `painted_room_f{1,2}_floor_cracked.png`
- `painted_room_f{1,2}_floor_compass.png`
- `painted_room_f{1,2}_ceiling_roots.png`
- `painted_room_f{1,2}_ceiling_chain.png`
- `painted_room_f{1,2}_ceiling_boss.png`

The existing editable native decoration recipe is drawn over each new painted
base. Every face preserves that base's complete outer **two-pixel ring**.
Opposite outer rows/columns match exactly, so base/base, base/variant and
variant/variant joins agree on either axis. Mixed 3 × 3 repeat proofs are in
`art_src/env/painted_surfaces/floor{1,2}/`. The old room faces and their old
build script remain untouched.

### One cell, one texture repeat

**One 64px texture = one world cell**, not one individual flagstone. The floor
cell perimeter has a continuous two-pixel grime joint on each side of the
boundary: four texels across a repeated join. Internal flag joins are quieter
and irregular. The perimeter follows the movement grid, so its perspective
transverse lines mark whole steps. It is dark under the same lamp lighting,
not an overlaid grid; do not add another code flagstone seam pass.

The current renderer already uses the following world sampling contract:

```text
canvas = 148 x 150; focal = 74; horizon = 71; far = 3.6
floor_side = y > horizon
depth = focal * 0.5 / (abs(y - horizon) + 0.5)
point = origin + (forward + right * ((x + 0.5 - 74) / 74)) * depth
u = floor(point.x * 64) modulo 64
v = floor(point.y * 64) modulo 64
gain = lamp(depth) * (0.86 for floor, 0.64 for ceiling)
```

U increases with world X; V increases with world Y. The compass's small arrow
points toward **negative V / world north**. Sample the same world-aligned UVs
for every facing. Do not rotate/mirror compass tiles or rotate the texture
with the camera. Roots, chains and drip streaks are part of the sampled
ceiling plane; they do not extend as hanging billboards into the view.
Use the existing floor-two ambience for any moving drops; these plane
textures stay static.

**Earlier painted family only:** replace the two base image paths in `_build_surfaces()` from
`f%d_floor.png` / `f%d_ceiling.png` to `painted_f%d_floor.png` /
`painted_f%d_ceiling.png`, keeping the existing one-based floor clamp and
current sampling. For cell variants, change `room_f%d_...` to
`painted_room_f%d_...`. Cache images and stable cell/plane choices outside the
pixel loop; invalidate the surface cache when the material family changes.
No extra scale, offset, tint or second darkness multiplier is needed. Use
ordinary bases most often and reserve compass/boss/drain faces as landmarks.
The texture kit supplies no placement, interactable, or movement rules.

### Whole-picture mock-ups

`art_src/env/painted_surfaces/mockup_view_4x.png` places the four material
comparisons together: corridor and room for each floor. The corresponding
`mockup_screen_4x.png` shows them inside the supplied M3c framing and UI.
Individual pairs are `mockup_f{1,2}_{corridor,room}_native.png` and `_4x.png`.
Each preview is an exact nearest 4x enlargement of its native counterpart.

The offline authoring sampler reproduces the current view's 148 × 150 camera,
world-cell UVs, 64px wall columns, lamp falloff and plane factors. Simple
north-facing proxy spaces let the same material be compared in a narrow
corridor and a three-cell-wide room. The room includes one compass and vault
boss to show mixed-face joins. This is a material proposal, **not a Godot
capture or a reconstruction of BELL42's simulation**. No actors/items are
placed by the mock-up script. For that reason the supplied screenshots'
messages and floor indicator remain their original UI, including on the
floor-two material examples; captions identify the material floor.

The source references are immutable copies of
`build/m3c_shots/03_corridor.png` and `01_room.png`, saved in this set's
`sources/`. Their UI outside `(3,21,148,150)` is preserved pixel-for-pixel
after native nearest reduction. All art is authored inside C's directories;
the real renderer/UI are untouched.

Recipe: `art_src/env/painted_surfaces/build_surfaces.py`, with saved painting
sources, exact built-in imagegen prompts, manifest and preservation receipt
beside it. `verify_surfaces.py` checks all sixteen planes, mixed-family rings,
wrap edges, darker wet level, readable perimeter contrast, exact 4x proofs
and protected screenshot UI. No Godot process is needed.

## Earlier floor and ceiling faces: alternates

Runtime root: `assets/art/env/`; these twelve older images are **64 × 64 opaque
world-UV textures**, not perspective billboards or room backgrounds:

- `room_f{1,2}_floor_drain.png`
- `room_f{1,2}_floor_cracked.png`
- `room_f{1,2}_floor_compass.png`
- `room_f{1,2}_ceiling_roots.png`
- `room_f{1,2}_ceiling_chain.png`
- `room_f{1,2}_ceiling_boss.png`

The substrate has scuffed detail sampled from the approved painted stone;
existing flagstone joints/ribs remain. Floor two adds cold dampness and worn
metal. Each image retains the complete outer two-pixel ring of its existing
`fN_floor.png` or `fN_ceiling.png` family, so mixed variants join correctly.
The compass rose has a small arrow toward **negative world Y (north)**.
Do not rotate that texture randomly or imply that it points toward the Seal.

**Codex A:** in `_build_surfaces()`, select a cached image once per world cell
and plane using a stable presentation hash, sample existing `(u,v)`, and apply
the current lamp/ceiling factor. Include material/floor selection in the cache
key. Use ordinary faces most often and reserve compass/boss/drains as landmarks.
Roots and chain lie on the sampled ceiling plane, with painted relief. They
do not create physically dangling geometry, animation, or collision; an actual
hanging chain would need a separate ceiling-anchored projection in the view.
The drain is floor detail, not a pit or collectible. No mechanic is implied.

Sources/recipe and sheet: `art_src/env/room_faces/`. Rebuild this set with:

```powershell
python -B art_src/env/room_faces/build_faces.py
```

## Loose possessions (first pack)

Runtime: `assets/art/icons/{kind}.png`; each is exactly 16 × 16, transparent,
centered by its opaque bounds within half a pixel, with a one-pixel dark
eight-neighbour outline. Anchor `(8,8)`; loose-floor sprites may use bottom
centre `(8,16)` as their ground point. Keep native transparent padding.

Kinds: `knife lamp stone bone bread torch clapper shard tonic club coat key seal`.
The torch is supplied for the reserved FIRE module; it is not a catalog entry
in the current slice. `items_strip.png` is 208 × 16 in the order above.

**Codex A:** route `UndercroftItemArt.inventory(kind)` to these textures and
cache them by kind. Keep the UI's existing full-canvas centering; don't crop
and stretch each icon again. They can also replace the ordinary loose-world
item pictures if wanted, preserving the renderer's existing projections,
occlusion, shadow and minimum size. Leave fixture and monster art on their own
paths. Retain old procedural art as a fallback for unknown kinds.

## Reactive Finder

Primary runtime: `assets/art/portrait/finder_fine.png`, `finder_hurt_v2.png`,
`finder_near_death_v2.png`. All 32 × 32, opaque, top-left drawing origin, centre
anchor `(16,16)`. `finder_strip_v2.png` is 96 × 32 in that order.
The old injured images and `finder_strip.png` remain unchanged as alternates.

Fine is reduced from a preserved copy of the original painted source and is
pixel-identical to `assets/art/finder.png`. The v2 injured images are separate
identity-preserving imagegen edits of the same original. Hurt has a pronounced
wince, clenched mouth and diagonal cheek cut, with a five-pixel native scar
cleanup after reduction to prevent its red-brown colour merging with skin.
Near-death has pale cool skin, half-closed eyes, brow blood and a slipped-back
hood exposing the same dark curls. Identity, pose, strap and framing hold.
`art_src/portrait/v2/faces_8x.png` gives a larger expression-only comparison.

**Codex A:** draw at the existing portrait rectangle. Suggested thresholds
for the current 6 HP: fine at 4–6, hurt at 2–3, near-death at 1; a brief hit
reaction may choose hurt while health is otherwise high. Near-death takes
priority over a hurt flash. Keep the health bar and touch target. The old
scratch/tint overlay is redundant over these portraits and may be removed.

## Story plates and publisher

Runtime: `assets/art/screens/title.png`, `splash.png`, `win.png`, `death.png`.
All opaque, top-left origin. Title and splash are 154 × 150. The title shows
the Finder entering a lamplit undercroft and has no baked lettering: overlay
the new painted logotype, or use a separate VETKA label. Splash contains an original moth-and-key mark
with real native VETKA `LOST MOTH` and `1993`, added after reduction so the
lettering is crisp. No UI frames or panels are painted into these assets.

Win and death are 128 × 80, sized to fit the menu's current 128px content
column. Win combines dawn over the abbey and the raised Seal; death is a
guttering lamp on flagstones. Keep seed/result text and existing actions
outside the illustrations. Reflow the title menu to fit its 150px art;
do not merely add it to the existing VBox's full list and overflow the phone.

**Codex A:** add TextureRects or draw the plates within the menu you own.
Make the publisher splash skippable with CONTINUE/NEW RUN reachable promptly;
no mandatory startup delay. Select win/death only from committed run status.
Nearest filtering, no mipmaps or lossy compression. Reference runtime paths
only, and exclude the `art_src/` tree in the Android export preset so saved
paintings and contact sheets do not inflate the APK.

## Small life in the story plates

Eleven **new** runtime PNGs beside the original plates; all fully opaque,
31-colour palette, top-left anchor `(0,0)`, no added border or crop. The four
original plates are unchanged. Frame 0 of every set has exactly the original
plate's indexed pixels, so it is also the static fallback.

| Set / filenames under `assets/art/screens/` | Canvas | Frame durations, in order | Playback |
| --- | --- | --- | --- |
| `splash_flutter_0.png`, `splash_flutter_1.png` | 154 × 150 | 900 / 300 ms | Open / gently folded; loop every 1200 ms |
| `title_flicker_0.png` through `_2.png` | 154 × 150 | 680 / 160 / 240 ms | Steady / low / warm; loop every 1080 ms |
| `win_dawn_0.png` through `_2.png` | 128 × 80 | 500 / 650 / indefinite | First light / Seal pulse / brighter dawn; hold frame 2 from 1150 ms |
| `death_gutter_0.png` through `_2.png` | 128 × 80 | 400 / 700 / indefinite | Flame / two-pixel ember / cold glass; hold frame 2 from 1100 ms |

The publisher's original key body, antennae and `LOST MOTH / 1993` lettering
are copied pixel-for-pixel between poses. Only the painted wings fold. Title
lighting varies on nearby steps, floor and lower columns, leaving all pixels
in the top 55 rows untouched. The logotype remains a separate static overlay
at `(7,6)` within the title illustration; it is **not baked into runtime
frames**. The title contact sheets/GIF add that same overlay for review.
There is no moving mote: the lamp provides enough motion on its own.

Win keeps the hand, abbey and Seal geometry fixed: the gold pulse rises in
frame 1 and settles in frame 2 while dawn continues to brighten. Death removes
the flame and warm floor reflections, retaining cold stone detail and the
nearby key. The dark frame is a legible picture, not a full-screen blackout.

**Codex A:** preload/cache the small PNG arrays with the existing art cache.
Swap the plate texture only at a frame boundary using elapsed **menu
presentation** time, reset when entering that screen. The table uses
half-open intervals: win 0 is `[0,500)`, 1 is `[500,1150)`, 2 is everything
afterwards; death changes at 400 and 1100 ms. Loop only splash/title; never
wrap the result sequences back to their first frame. Pause the clock while
the app is suspended. Keep current plate rects, nearest filtering and the
separate logo/subtitle/text layers. At this source checkpoint those plate
rects are `(0,20,154,150)` for splash/title and `(13,62,128,80)` for results;
the animation needs no layout change if A moves those rects later.

Keep splash skip and existing menu/retry buttons usable throughout. The
current 1400 ms splash display already allows one complete 1200 ms flutter;
do not extend it to show more cycles. End holds last until the existing user
action; they add no input lock, simulation turns, save writes or RNG calls.
Static frame 0 remains available if animation is disabled. Import only
runtime PNGs into gameplay; `art_src/` stays excluded from Android exports.

Offline recipe and review files:

- `art_src/screens/life/build_life.py`: rebuild all eleven frames, five
  native/4x sheet pairs and four tiny three-or-fewer-frame GIF previews.
- `art_src/screens/life/timings.json`: machine-readable copy of the table,
  resource paths, canvas sizes and anchors. For `once_hold`, its final
  duration `0` means **indefinite**, not a zero-length frame. This is an
  authoring record; A can copy its values into presentation code.
- `art_src/screens/life/{splash,title,win,death}/preview_4x.gif`: timing
  previews. Splash/title loop; win/death play once and retain their last
  frame. Reload a result GIF to replay it. Their last duration is 2400 ms
  for viewers; the game holds it indefinitely.
- `art_src/screens/life/prompts.json` and `sources/`: four exact built-in
  imagegen edit prompts and preserved edited paintings. Wings and cold
  glass come from those paintings; lighting fields are projected onto the
  original native pixel clusters to avoid scenery shimmer. Only numeric
  light fields are blurred; visible image sampling and enlargement remain
  nearest-neighbour. The ember uses two native palette pixels.
- `art_src/screens/life/verify_life.py`: registration, distinct frame counts,
  opaque palette, original plate preservation, lamp/glow direction, dawn
  growth, GIF timing, exact 4x scale and loop/hold boundary checks.

The preservation receipt captures the 155 earlier C runtime PNGs unchanged.
It also retains an informational snapshot of Claude's three launcher PNGs;
those changed concurrently during this batch and are outside C ownership.
Neither verifier restores or overwrites launcher choices. The older room
receipt is retained, with its launcher entries now treated as historical
rather than a lock on Claude's accepted changes.

## Painted logotype, subtitle and launcher option

Runtime files under `assets/art/screens/`:

| Filename | Size | Anchor / use |
| --- | --- | --- |
| `logotype_140.png` | 140 × 40, transparent | Centre `(70,20)`; painted UNDERCROFT heading |
| `subtitle_plate_140.png` | 140 × 20, transparent corners | Centre `(70,10)`; THE FINDER'S DESCENT |
| `icon_offer_192.png` | 192 × 192, opaque | Optional legacy/application icon only |
| `icon_offer_foreground_432.png` | 432 × 432, transparent | Adaptive foreground, centred at `(216,216)` |
| `icon_offer_background_432.png` | 432 × 432, opaque | Adaptive full-bleed background |

The logotype is a new painted source: all ten letters remain explicit, with
carved stone, worn bronze edges, small verdigris traces and a bell in the O.
It is reduced with nearest sampling and the shared palette, not synthesized
from the body font. It occupies a full 140 × 40 canvas with transparent padding;
keep its native aspect ratio and centre it at x77 on the 154px title screen.
The subtitle uses the existing painted brass material and actual VETKA 16,
rendered without antialiasing. No runtime font change is required.

`art_src/screens/room_batch/title_mockup_4x.png` shows the unchanged 154 × 150
title painting with the logo at `(7,6)` and subtitle below at `(7,158)`, on a
154 × 184 proposal canvas. This is an offline art layout, not an implemented
menu. A must keep CONTINUE/NEW RUN/audio controls readable and within the full
screen; the logo can overlay the existing title picture rather than consume
another 40px row. Existing `title.png`, `splash.png`, `win.png`, and `death.png`
are untouched.

The icon option puts the Dawn Seal inside a compact worn arch, with the same
gold/teal/bright-dawn language as B's Seal. Both original and compact source
paintings remain saved. A complete silhouette is fitted into the safe region;
no artwork is circularly cut to manufacture safety. Only review previews show
round/squircle masks or a gold guide circle. Foreground/background exports are
full square layers, with no baked outer disc, mask, outer shadow or lettering.

The 432px layers use a 108px authoring layout enlarged exactly 4x. The entire
foreground is checked inside a **264px-diameter circle**, centre `(216,216)`,
equivalent to the central 66dp zone in the 108dp layer. The background has no
transparent pixels and fills the complete layer. This follows the foreground,
background and safe-zone guidance in the [official Android adaptive-icon
documentation](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
Our foreground's measured maximum alpha radius is about 127.36px, below the
132px limit. The standalone icon is exactly a 3x nearest enlargement of its
64px composition; adaptive pixels come from a 4x enlargement. All output still
uses the shared 31 opaque inks and binary alpha.

**Claude/A:** choosing these is a separate integration step. If accepted, point
the existing app-icon and Android adaptive foreground/background settings at
the respective offered files; keep their 192/432 sizes. `assets/icon/`, project
settings and export presets have not been touched. This is not a launcher or
phone acceptance test, and no existing launcher art has been replaced.

The source paintings, exact built-in imagegen prompts, manifest, 4x contact
sheet, round/squircle/safe-zone previews and rebuild live in
`art_src/screens/room_batch/`. The original taller icon exploration is kept as
source history; the compact version builds the exported offer.

```powershell
python -B art_src/screens/room_batch/build_identity.py
```

## Current UI offer: visibly leafy ivy, v4

V4 follows the owner's request for actual visible leaves rather than teal
border dashes. It replaces only the three v3 vine layers. **All v3 assets,
source files, verb icons, layout proofs and the two owner references remain
byte-for-byte intact.** No game/UI source or original PNG is changed.

Leaves are individually drawn **3 x 5 or 5 x 5 native pixels**, with pointed
tips, asymmetrical shoulders and short lit veins. The sage/olive body uses
palette 6 and 16, 17 lights the edges, and a tiny 8 ivory highlight catches
the lamp. Palette 11/13 supplies foliage shade; warm 27 and sage/grey form
the **1–2 px stem**, with a dark silhouette for contrast. Uneven clusters
gather at view corners, the lower view rim and the compass. Clear little
coils and six transparent underpasses let the original bronze show above
the stem where it winds behind the frame.

The old three-pixel clipping bands made wider leaves impossible. V4 gives
foliage a few pixels of space at the outside of the world view and in unused
gaps around controls. It retains the same three-pixel housing-rim rule;
**all touch-target interiors remain empty**. World overhang is confined to
the outer five pixels of the view at most: the core `(8,26,138,140)` is clear,
and the M3e near-right hand/blade rect `(108,130,43,41)` is separately protected.
The entire camera opening `(53,0,44,18)` stays clear. Text, icons, portrait,
health bars and oil gauge are protected, including the existing verb labels
and compass heading, needle, arcs and ticks.

### V4 files and A's placement

New runtime files live in `assets/art/ui_offer/`. Rects are native
`(x,y,width,height)`, exclusive at right/bottom:

| PNG basename | Canvas | Place at | Change from v3 |
| --- | --- | --- | --- |
| `ivy_game_border_v4` | 154 x 342 | `(0,0)` | Visible leafy coils on view/panel rims and outside control contents |
| `ivy_compass_v4` | 74 x 51 | **`(80,291)`** | Expanded canvas includes external curls; actual compass remains `(85,294,66,44)` |
| `ivy_map_border_v4` | 144 x 324 | `(5,16)` | Leaf clusters on the blank ragged margins, clipped to real paper alpha |

**A must use the new compass origin.** Its entire inner `(88,297,60,38)` is
still clear. Five-pixel leaves straddle the housing rim and empty space
outside it. The owner-approved `sleepy_skull_v3.png` is copied exactly at
`(114,335)` inside this layer; do not draw the skull again. Existing optional
`ivy_torches_v3_0/1.png` remain at `(0,0)`, with 420/580 ms timing, and the new
vines leave their small flame/body rectangles clear.

Use nearest filtering, integer placement, `mouse_filter = IGNORE`, no tiling
or resizing, and **zero 9-slice margins**. Draw vines over existing bronze,
below text/items/dial marks. Swap the layers rather than stacking v3 and v4.
Normal game uses game + compass + optional old torches; map uses only the new
map vine layer. Hide them during cards/inspection, modals and other screens,
as for v3. Existing 29 verb icons, compact glyph choices and full-word VETKA
16 layout are unchanged: keep `ivy_v3/layout.json` for those. The new
`art_src/ui_offer/ivy_v4/layout.json` records all overlay positions, protected
rects, leaf placements, underpasses and reuse/state rules.

The map leaves may enter up to 14 pixels of its empty side margins rather
than being cut into fragments by the old eight-pixel strip. Three local
clear rectangles protect its header `(12,11,120,15)`, body `(16,28,112,240)`
and complete CLOSE target `(8,272,128,25)`. Existing map ink and glyphs are
unchanged. Every vine pixel lies on opaque torn paper, keeping the irregular
silhouette. The old paper itself and its content/9-slice contract do not
change; the fixed-size overlay is a separate decoration layer.

### V4 proofs and build

- `art_src/ui_offer/ivy_v4/mockup_screen_4x.png`: full game and map together.
- `mockup_game_4x.png` and `mockup_map_4x.png`: individual screen proofs.
- `comparison_4x.png`: v3 and v4 at the same camera, size and icon layout.
- `contact_sheet_4x.png`: all three layers, enlarged compass placement and
  the native leaf stamps. All these files have exact native counterparts.

These are offline composites of the same saved M3e view and torn-map proof
used for v3. V4 does not imply changed game state or an integrated capture.
The builder uses native pixel drawing only; its code and
`art_direction.json` are the reproducible source, with no image model prompt.
The two original owner references stay where they were supplied.

Run the v4 commands above. Focused checks verify palette/alpha registrations,
39 complete game leaf stamps, clear protected content and controls, the exact
old skull and verb/button pixels, actual bronze underpasses, map alpha and
unchanged map/header/CLOSE, preservation of all 249 earlier C runtime PNGs
and the entire v3 source pack, and an identical rebuild. The v4 game/compass
layers each contain roughly **2.9 times** v3's opaque pixels; that measures
the broader silhouettes, not device acceptance. Phone review remains with
A/Claude. No Godot runs or commits by C.

## Previous UI offer: thin dead ivy v3, sleepy keeper and verb stamps

This offer follows the owner's two saved chrome elaborations. Both reference
PNGs remain byte-identical at `art_src/ui_offer/vine_on_main_view.png` and
`icons_on_buttons.png`. All new runtime files are in `assets/art/ui_offer/`;
the deterministic native drawings, masks, source captures, registration,
art-direction record and proofs are in `art_src/ui_offer/ivy_v3/`. These tiny
assets are code-drawn directly on the palette: no painted resize, smoothing,
dither or model prompt is involved. Existing chrome and all earlier C art stay
unchanged.

The foliage uses the existing teal ramp: 11 for aged stem shadow, 13/14 for
dead-ivy leaves, and sparse 15 highlights. Stems are one pixel, with small
paired leaves/coils confined to three-pixel frame rims. Quiet gaps keep the
world central. The compass has a round ivory skull with level, sleepy eyes
and two tiny teeth, rather than slanted brows. Small bronze corner rosettes
sit on the view rim. There is no crest across the camera opening.

### Placement and protected areas

All rects below are native `(x, y, width, height)`; right/bottom are exclusive.
All textures have binary alpha. Use nearest filtering, integer placement,
no tiling, and **no resizing or 9-slicing**: margins are `(0,0,0,0)`.

| PNG basename | Size | Place at | Use |
| --- | --- | --- | --- |
| `ivy_game_border_v3` | 154 x 342 | `(0,0)` | View rim, message sides, panel dividers, pack rim and outside movement controls |
| `ivy_compass_v3` | 66 x 48 | `(85,294)` | Three-pixel housing rim plus skull/footer; hit rect remains 66 x 44 |
| `ivy_map_border_v3` | 144 x 324 | `(5,16)` | Follows the actual torn leaf's opaque silhouette; use with `map_parchment_torn_v2` |
| `ivy_torches_v3_0`, `_1` | 154 x 342 each | `(0,0)` | Optional tiny gap-mounted flames beside the compass |
| `sleepy_skull_v3` | 9 x 7 | `(114,335)` if separate | Already included in the compass layer; do not draw twice |

The skull sits on the last three pixels of the housing rim and extends four
pixels below it, ending at the screen bottom. Its standalone bottom anchor is
`(4,7)`. The torches occupy `x81..83` and `x151..153`, `y300..311`, outside
the compass and movement hit rects. Play frame 0 for **420 ms**, frame 1 for
**580 ms**, loop; only four flame rows change. These are optional presentation
frames; use a local clock, without changing turn state or simulation RNG.

The overlays are empty throughout the entire camera opening
`(53,0,44,18)`, including the owner's x54–96 requirement. The whole dungeon
interior `(3,21,148,150)` is also untouched. Message text, item/portrait/health
pixels, the oil gauge, and touch-target interiors are protected. Housing-rim
decoration stays in the existing three-pixel borders; the compass inner
`(88,297,60,38)` remains entirely clear, including every heading, needle angle,
arc and tick. Pack decorations stay on its top/bottom rims. No control moves
or gains a hit area. The masks are saved under `ivy_v3/masks/`, and the
focused verifier checks every opaque pixel against them and the clear rects.

The map layer is clipped to opaque paper and stays outside the local content
safe rect `(8,12,128,300)`. The previous parchment's `8,12,8,12` margins remain
its content contract; the new vine layer itself is fixed-size and must not be
stretched. It does not reintroduce a rectangular outline or fill the torn alpha.

**Codex A:** draw these as non-interactive decoration (`mouse_filter = IGNORE`)
over the existing frame/housing, with text, items and compass marks above them.
Use the game, compass and optional torch layers only during the normal game
view. Hide them for cards/inspection, map, modals and other screens: inspection
currently docks verbs at y179. The map uses only its own vine layer over the
torn parchment. Keep existing touch controls, camera cutout and dial drawing.
`layout.json` contains the exact registrations and state rules.

### Verb names, full-word fit and native compact siblings

`verb_<lowercase verb>.png` supplies a **12 x 12** icon for all 21 requested
verbs: TAKE, GUARD, WAIT, HIT, DROP, PLACE, WIELD, WEAR, EAT, RETURN, RING,
DOWN, UP, RIDE, LEAVE, PULL, BURN, CUT, FEED, TOSS and LIGHT. It also covers
the eight additional labels found in the current UI/simulation: CANCEL,
PACK, CLOSE, UNLOCK, LATCH, SIDLE, REVEAL and DISPEL. Motifs include a pouch,
shield, hourglass, fist, bone, lever, torch and a little throwing arc. Colours
are 9/10 ivory, 25 bronze-gold and 28 bronze shade, with a one-pixel index-1
outline. Every coloured icon pixel has its complete dark silhouette boundary.

The layout is **icon + 2 px gap + full VETKA word at 16 px**, centred as one
group, with at least two pixels of side clearance. The current gameplay verb
controls are **48 x 22**, rather than the brief's nominal 24 px height; both
22- and 24-pixel height layouts are measured in `layout.json`. Icons centre
vertically at y5/y6, and VETKA's seven ink rows centre beside them. For custom
drawing, use the saved local `text_origin_godot_top`, adding the font's
`get_ascent(16)` for the `draw_string` baseline, as the current `_text` helper
does. Use full words and the existing typeface/size.

**Fit constraint:** RETURN/UNLOCK/CANCEL/REVEAL are 36 px wide. A 12 px icon
plus the gap would make a 50 px group before padding. Therefore separate,
hand-drawn **6 x 12** siblings carry `_compact6` suffixes for those words and
DISPEL. RETURN still reads in full: `6 + 2 + 36 = 44`, leaving two pixels on
each side of a 48 px button. These are narrow native glyphs, not compressed
canonical icons. A must select the recorded PNG; drawing its 12 px sibling
with the long word will overflow. DISPEL's group is 42 px wide.

The existing **42 x 20 item-card** controls have separate fit records:
`verb_wield_compact8.png` and `verb_close_compact6.png` keep WIELD and CLOSE
within 38 px. Other listed card verbs use the canonical 12 px icons. On the
wide map CLOSE control use the canonical CLOSE icon. A should apply the
same measured group treatment to both card and gameplay labels, retain the
2 px icon/text gap, and avoid automatic icon expansion. The proof includes
all 29 labels at the actual 48 x 22 pitch; 66 layout cases cover gameplay,
24 px height and the relevant item-card controls. No runtime UI code changed.

### Review files and reproducibility

- `art_src/ui_offer/ivy_v3/mockup_screen_4x.png`: game and torn map together.
- `mockup_game_4x.png`, `mockup_map_4x.png`: individual full-screen proofs.
- `mockup_long_verbs_4x.png`: RETURN, REVEAL and DISPEL at the actual pitch.
- `contact_sheet_4x.png`: all icon drawings, with compact siblings beside them.
- `fit_sheet_4x.png`: all gameplay verbs on their current bronze buttons;
  the number beside each is the total icon/gap/word width.
- `ornament_sheet_4x.png`: transparent game/map/compass pieces on dark slate.

These are offline composites, using the saved M3e entry view and the earlier
torn-map proof. World, portrait, pack, health and dial pixels remain identical;
the three verb labels are intentionally laid out again with icons. The long
verb row is an illustrative fit proof, not a claim those three actions are
offered together. The map's existing seen geometry and glyphs are preserved;
only its CLOSE button is laid out again. Every proof has an exact nearest
4x enlargement. The source captures are copied once, so rebuilding does not
silently refresh them while A works.

Run `python -B art_src/ui_offer/ivy_v3/build_ivy.py`, then
`python -B art_src/ui_offer/ivy_v3/verify_ivy.py --rebuild`, then the combined
`python -B art_src/env/verify_polish.py`. The saved preservation receipt covers
all 207 earlier C runtime PNGs and both owner references. No Godot or network
is needed; phone review remains part of A/Claude's integration.

## Current map offer: torn parchment with real transparency

New runtime file: `assets/art/ui_offer/map_parchment_torn_v2.png`, **144 × 324**,
the current map panel's exact native size. Draw it at `(5,16)` on the 154 × 342
screen, anchor `(0,0)`. The original `map_parchment.png` remains unchanged.

This is one painted leaf with a singed, torn, asymmetric outer silhouette and
binary transparent pixels beyond it. Broad grime blends inward into a quiet
pale writing field; no rectangular inner paper fill or ruled folds are baked
in. The source's irregular outer alpha is preserved at native reduction,
detached flecks are removed, and unusually deep side bites are compressed
within the existing eight-pixel side margins. There is no rectangular backing
under the leaf in the offer.

**A's swap:** change the existing map `StyleBoxTexture` texture path to the
new file. Retain texture margins **left/top/right/bottom = 8/12/8/12** and
STRETCH, with nearest filtering and no mipmaps/lossy compression. Native size
is preferred. Use content padding **8/12/8/12**; the fully opaque safe writing
rectangle is `(8,12,128,300)` within the texture. The current 128px map minimum,
heading and CLOSE button fit. Keep A's ink map transparent over the paper;
draw the leaf directly over the game, with its alpha revealing the view at
the ragged edge. Do not add a flat panel fill, rectangular outline/shadow,
second old parchment, or per-widget beige backing beneath it. These would
bring back the rectangle the owner asked to hide.

Source, exact imagegen edit prompt, build script and margin JSON are in
`art_src/ui_offer/torn_v2/`. Its `contact_sheet_4x.png` shows the material and
opaque silhouette side by side; `rects.json` records the size/rect/margins.
`mockup_map_4x.png` puts the leaf over a saved M3d world view, with the saved
map's existing heading, ink positions, Finder pin, top rail and CLOSE button.
The old background/fold lines are omitted. This is an offline art composite;
it introduces no new explored cells, glyphs, map rules or actual UI changes.

Rebuild just the leaf and map mock-up with
`python -B art_src/ui_offer/torn_v2/build_torn.py`; the calm revision builder
also runs it and assembles the five-screen comparison. Preserve the original
saved source paintings; all runtime art is indexed to the shared palette,
with alpha strictly 0/255. No Godot run is needed.

## Earlier UI material offer: non-tiling surfaces and small props

Runtime root: `assets/art/ui_offer/`. Source paintings, exact built-in imagegen
prompts, native cleanup, `rects.json`, contact sheet and mockups are in
`art_src/ui_offer/`. These do not edit or implement `chrome.gd`, any controls,
the compass, or the scene. A chooses which pieces belong in the interface.

All panel paints are made for their whole logical rectangle. They are not
32px tiles. Use a TextureRect at native size, or StyleBoxTexture with both
axis stretch modes **STRETCH**, never TILE. The margins below preserve edges
if a panel must change size; they are **left, top, right, bottom**. Prefer the
native size so individual scratches, folds and wear do not move or repeat.

| File, before `.png` | Native size | Intended logical rect `(x,y,w,h)` | 9-slice L,T,R,B |
| --- | --- | --- | --- |
| `message_slate` | 150 × 34 | `(2,174,150,34)` | `3,2,4,2` |
| `map_parchment` | 144 × 324 | `(5,16,144,324)` | `8,12,8,12` |
| `pack_leather` | 152 × 22 | `(1,246,152,22)` | `2,1,3,3` |
| `belt_loops` | 53 × 24 | `(99,210,53,24)` | `0,0,0,0`; native only |
| `hp_vial_empty` | 6 × 28 | `(36,212,6,28)` | `0,0,0,0`; native only |
| `hp_vial_full` | 6 × 28 | Same as empty | `0,0,0,0`; native only |
| `candle_0`, `candle_1` | 12 × 24 | Optional decoration; bottom-centre anchor `(6,24)` | `0,0,0,0`; native only |
| `hanging_chain` | 8 × 34 | Optional decoration; top-centre anchor `(4,0)` | `0,0,0,0`; native only |
| `brass_label` | 64 × 18 | Optional short heading; top-left origin | `9,3,9,3` |

The message slab is charcoal slate, with a quiet dark reading field and sparse
mineral wear at the rim. Keep the two VETKA lines at `(4,175)` and `(4,191)`.
The leather tray has a folded corner and stitched lower edge, no pocket boxes;
icons start at `(2,249)` and retain the existing 19px pitch. The belt's keepers
leave spans for the current key/Seal centres `(112,221)` and `(138,221)`.
Keep the existing belt touch targets and protected inventory rules.

The map is a single worn parchment with a quiet writing field and storage
folds. Its supplied rect matches `_open_map()`'s current `_panel(...,16,324)`
and the panel width 144 from `main.gd`; it is not guessed from a scaled gallery.
The mockup darkens seen map squares from `777970` to `59616a` so the marks read
on light paper, keeping symbols and explored geometry. A should choose inks
for all map symbols with that light surface in mind. Do not shrink the map or
font to accommodate props. Short brass labels use dark ink `0c101c`, native
VETKA 16, inside local `(10,1,44,16)`. Long labels need a larger plate, not a
smaller font. No labels are baked into the material assets.

Verdigris is the **one accent hue family**, using the existing teal palette
ramp in a few insets and the HP liquid. Bronze, slate, leather and parchment
remain material colours. There is no added palette, glow shader or UI texture
tiling. The little hanging chain is native pixel work; the second candle flame
is a native pixel derivative of its painted first frame. The wax body/saucer
stay identical. Suggested candle playback is 4 fps, only while visible.

### Filling the HP vial

This is a **health indicator**, not lamp oil or a new fuel clock. Draw
`hp_vial_empty.png` first. The full layer contains only liquid, with transparent
pixels everywhere except local `(2,6,2,18)`. For a fraction `hp/max_hp`, clamp
to 0–1 and take `fill_px = round(18 * fraction)`. If nonzero, draw the source
region `(0,24-fill_px,6,fill_px)` from `hp_vial_full.png` at vial origin plus
`(0,24-fill_px)`. This fills bottom-up without scaling the liquid or its rim.
The sheet shows all seven current 0–6 HP levels. The gauge is decorative;
numeric health and existing accessible touch targets remain authoritative.

### Whole-screen mockups

- `art_src/ui_offer/mockup_game_native.png` / `mockup_game_4x.png`:
  one 154 × 342 game screen with slate, leather, loops and the HP vial.
- `art_src/ui_offer/mockup_map_native.png` / `mockup_map_4x.png`:
  one 154 × 342 map screen with parchment, brass MAP plate, a margin chain
  at `(5,48)` and a candle in the unused footer at `(133,313)`.
- `art_src/ui_offer/mockup_screen_native.png` / `mockup_screen_4x.png`:
  the pair side by side, 316 × 342 native / 1264 × 1368 at 4x.

These are **offline illustrative composites**, not captures of an implemented
skin. Representative possessions show loose-icon readability; they are not the
saved screenshot's inventory. The game mockup preserves the entire dungeon
picture and upper strip, buttons, compass, equipment controls, and fine portrait
pixel-for-pixel from the nearest-downsampled M3b capture. No palette remapping
changes the screenshot's world lighting. Map seen bounds/geometry come from
the preserved map capture. Its existing CLOSE button is retained.

The offer's manifest separates indexed runtime/contact-sheet files from RGBA
mockup previews and records hashes for both. Source screenshots remain intact
in `art_src/ui_offer/sources/`. Keep all of `art_src/` out of Android exports.

## Ambience Node2D API

Script: `scripts/fx/ambience.gd`. Add after the dungeon view and before UI
controls. Either parent it to the view and use local `(0,0,148,150)`, or add
beside the view and pass `VIEW_RECT` `(3,21,148,150)`. Do not add the view offset
twice. Node2D takes no mouse/touch input. All drawing is clipped numerically
to the requested local rectangle; no shader or particles resource is needed.

| Call/property | Meaning |
| --- | --- |
| `set_view_rect(Rect2)` | Local clip rectangle; negative sizes are normalized |
| `set_floor(int)` | One-based; drips appear at 2 or deeper |
| `flash(Color, seconds=0.18, amount=0.18)` | Optional local colour veil; amount capped at 0.35 |
| `fade_out(seconds=0.22)` | Animate from current opacity to black |
| `fade_in(seconds=0.28)` | Animate from current opacity to clear |
| `fade_finished(dark: bool)` | Completion signal; zero/negative duration emits synchronously |
| `fade_alpha()` | Current black opacity for transition coordination |
| `lamp_gain()` | Read-only deterministic light gain, normally 0.977–0.993 |
| `dust_enabled`, `drips_enabled`, `lamp_flicker_enabled` | Independent optional effects |
| `intensity` | Clampable 0–1 presentation strength; does not disable stair fades |

The node draws 12 dust pixels, at most 3 short drips, a very subtle lamp veil,
an optional flash and transition black, at 20 redraws/second. No gameplay RNG,
input, audio, save files, textures, emitter nodes or per-frame image allocation.
`lamp_gain()` already drives the veil: don't multiply the renderer by it too,
or flicker is applied twice. Drips are decorative, not geometrically occluded
world droplets. Disable them where the visible scene makes them implausible.

**Codex A:** hide and disable processing on title/end screens; show and resume
for the view. Call `set_floor` from committed floor state, not guessed visuals.
On stairs/lift, commit and save the accepted action first, hold the existing
input gate, fade the old picture out, synchronize the new view at black, then
fade in and release input. Do not delay saving until the fade. Connect or await
the signal before invoking a zero-time fade. A reversed fade replaces its old
completion; menu/new-run/resume paths should clear with `fade_in(0)` and reset
their own input lock. The node itself never owns or locks gameplay.

Focused checks:

```powershell
E:/SD/GODOT/Godot.exe --headless --path . --check-only --script res://scripts/fx/ambience.gd
E:/SD/GODOT/Godot.exe --headless --path . --script res://tests/test_fx.gd
python -B art_src/env/verify_polish.py
```

## Flavour wiring

`data/text/provenance.json` maps current catalog kind IDs to one/two-line
arrays, plus the reserved torch. `flavour.json` supplies numbered floor names,
six death couplets and eight hint records with stable IDs and descriptive
`when` hooks. Those hook strings are integration suggestions, not registered
events. Every display line is at most 21 characters, at most two lines per
entry. Keep the arrays as lines or join with `"\n"`; never rewrap at spaces
into three lines. Schema version is 1.

**Codex A:** parse once, validate the schema/line limits, fall back to existing
catalog text when missing. Route provenance into cards, optional floor names
into a readable transition/card, hints to the corresponding existing inspect
or event path, and epitaphs to loss results. Do not overwrite urgent combat or
save messages with flavour. Pick epitaphs using presentation-only deterministic
seed/turn indexing; never advance simulation RNG. Keep the catalog's Porter
purpose and RING status text. No new mandatory items or mechanics are implied.

The box manual is `docs/MANUAL.md`. Further optional work and cost estimates
are in `docs/POLISH.md`. This pack needs integration and Pixel 9a visual review;
the asset checks and focused FX test do not claim phone performance acceptance.





## Leafy ivy v4 revision receipt, 28 October 2026

- Added **three runtime PNGs**: broader leafy game, compass and map layers.
  The combined C kit verifies at **252 runtime PNGs**, with the shared 31
  opaque inks, binary alpha and exact nearest 4x proofs.
- All **249 earlier C runtime PNGs**, both owner references and the entire
  v3 source pack remain byte-for-byte unchanged. The accepted skull, verb
  icons, full words and button contents are preserved.
- Focused checks pass for 39 intact native leaf stamps, six bronze
  underpasses, camera/content/control clearance, compass dial/heading, map
  ink/alpha/header/CLOSE, and an identical **22-file** PNG/JSON rebuild.
- A swaps the three vine layers, places the expanded compass canvas at
  **`(80,291)`**, and retains old icons/torches. Full-screen/map, side-by-side
  and contact proofs are under `art_src/ui_offer/ivy_v4/`; `layout.json`
  supplies the exact registrations. No Godot runs, staging or commits by C.

## Painted dressing v2 receipt, 29 October 2026

- Added **20 runtime PNGs** from **18 saved individual imagegen paintings**:
  nine opaque faces/states per floor and two live open-door alpha overlays.
  The combined C kit verifies at **272 runtime PNGs** with the shared 31
  opaque inks, binary alpha, common wall edges and exact nearest 4x proofs.
- All **252 preceding C runtime PNGs** plus the original favourite
  `assets/art/stone_wall.png` remain byte-for-byte unchanged. No renderer,
  gameplay, UI, fixture data or interaction code was edited.
- Focused checks pass for every two-pixel seam ring, opposite edges,
  stationary arch/threshold between door states, actual unobstructed portal
  alpha, and fixed torch hardware/soot/masonry outside the two-frame fire
  mask. F2 mean interior luminance is 59–72% of its corresponding F1 face.
- The corridor proof places six dressings across actual d1/d2/d3 wall
  segments; separate near-door and distance sheets show the opened live
  route and what survives the existing lamp falloff. These are offline
  proxy views, not engine or phone acceptance.
- Rebuilding produced identical hashes for **74 PNG/JSON files**; see
  `art_src/env/dressing_v2/rebuild_receipt.json` and `verification.json`.
  A swaps the six dressing families, the closed lock override, and only
  the opened lock's portal path. No Godot runs, staging or commits by C.
