# Codex C: dressing, possessions, portraits and atmosphere

This pack is prepared for Codex A to wire in. It does not change the renderer,
simulation, main scene, UI chrome, catalog, or original PNGs. Painted source
PNGs, exact built-in imagegen prompts, code drawings, deterministic reduction,
and contact sheets live in the corresponding `art_src/` folders.

**Primary revision:** use `painted_f1_*.png` / `painted_f2_*.png` for walls,
`finder_hurt_v2.png` / `finder_near_death_v2.png` for injured portraits, and the
existing unchanged `finder_fine.png` for fine. The first `f1_` / `f2_` wall
sets and original reactive portraits remain intact as alternates. The UI
materials in `assets/art/ui_offer/` are an offer for A, not an implemented skin.

## Rebuild and inspect

From the repository root, with Python and Pillow installed:

```powershell
python -B art_src/env/painted_v2/build_revision.py
```

This rebuilds only the primary painted walls, stronger portraits and UI offer,
then verifies all packs, including preservation hashes for the old PNGs.
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
The UI mockups are RGBA exceptions: they retain the saved screenshot's exact
renderer lighting colours in protected regions. All runtime material PNGs
and contact sheets still use the shared indexed palette and binary alpha.

| Set | Native size | 4x review sheet |
| --- | --- | --- |
| Primary walls, combined | 24 tiles, each 64 × 64 | `art_src/env/painted_v2/contact_sheet_4x.png` |
| Primary abbey stone | 12 tiles, each 64 × 64 | `art_src/env/painted_v2/floor1/contact_sheet_4x.png` |
| Primary older wet stone | 12 tiles, each 64 × 64 | `art_src/env/painted_v2/floor2/contact_sheet_4x.png` |
| Primary mixed tile repeats | 256 × 192 | `art_src/env/painted_v2/floor1/repeat_4x.png`, `floor2/repeat_4x.png` |
| Original / primary / wet comparison | Three 64 × 64 samples | `art_src/env/painted_v2/comparison/contact_sheet_4x.png` |
| First wall set, alternates + surfaces | 28 tiles, each 64 × 64 | `art_src/env/contact_sheet_4x.png` |
| Possessions | 13 icons, each 16 × 16 | `art_src/icons/contact_sheet_4x.png` |
| Primary Finder states | 3 portraits, each 32 × 32 | `art_src/portrait/v2/contact_sheet_4x.png` |
| Original Finder states, alternates | 3 portraits, each 32 × 32 | `art_src/portrait/contact_sheet_4x.png` |
| Story plates | title/splash 154 × 150; endings 128 × 80 | `art_src/screens/contact_sheet_4x.png` |
| UI material offer | Ten assets, sizes below | `art_src/ui_offer/contact_sheet_4x.png` |
| Whole-screen UI mockup, game + map | Two 154 × 342 screens | `art_src/ui_offer/mockup_screen_4x.png` |

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
| `arch` | Dark arched recess/opening picture; no transparent hole |
| `door` | Closed iron-banded wood inside the matching arch |

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

The door and arch **do not** create fixtures, locks, collision or passable
routes. Reserve door art for an actual closed door/lock if one is implemented;
remove/swap it with the authoritative open state. Use an arch only as a
decorative recess unless the renderer explicitly draws the space behind it.
Do not make a working gate or exit visually lie by casually assigning a door.

### Floor and ceiling

The first pack's `f1_floor.png`, `f1_ceiling.png`, `f2_floor.png`, and
`f2_ceiling.png` remain optional surface materials. No `painted_fN_floor` or
`painted_fN_ceiling` is supplied; the primary revision changes wall faces.

The current `_build_surfaces()` already computes `point`, world-space `u`,
`v`, floor/ceiling side, and lamp attenuation. Replace the procedural base
colour with a cached `Image.get_pixel(u, v)` from `fN_floor.png` or
`fN_ceiling.png`, then apply the existing light. Do not load images per pixel.
Keep the surface cache and include the selected floor material in its key.
These are orthographic materials, **not** perspective pictures. Map one tile
to one world cell, with the same orientation on every cell. The ceiling has
restrained stone ribs; floor two has pooled teal water, with no gameplay hazard.

## Loose possessions

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
the Finder entering a lamplit undercroft and has no baked lettering: draw
UNDERCROFT separately in VETKA. Splash contains an original moth-and-key mark
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

## UI material offer: non-tiling surfaces and small props

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

## First-pack verification receipt, 28 October 2026

- Godot 4.3 `--check-only` accepted `ambience.gd`.
- The focused FX run exited 0: **172 checks, 0 failures**. Godot printed a host
  root-certificate-store error before the result; the offline test itself passed.
- Offline validation checked **50 runtime PNGs**, the shared **31 opaque inks**,
  binary alpha, declared dimensions, mixed wall boundaries, source/output
  hashes, exact 4x nearest sheets, and every JSON display line at <=21 chars ×2.
- Two consecutive complete builds produced identical SHA-256 hashes for
  **83 PNG/JSON files**, including sources, sheets, prompts and manifests.
- No full game run, Android export, phone performance test, or integration
  acceptance was performed. No files were staged or committed by Codex C.

## Painted-wall/UI revision receipt, 28 October 2026

- Added **37 runtime PNGs**: 24 painted-substrate walls, two stronger injured
  portraits plus their strip, and ten UI offer assets. Both packs now verify
  together: **87 runtime PNGs**, shared 31 opaque inks, binary alpha, dimensions,
  exact 4x sheets, source/output hashes and mixed wall-edge checks.
- The primary abbey base retains **3968/4096 original pixels**; its complete
  62 × 62 interior is exact. Preservation hashes confirm the 34 recorded
  existing wall/portrait PNGs are byte-for-byte unchanged. Earlier pack assets
  also continue to match their recorded manifests.
- Two revision builds produced identical SHA-256 hashes for **80 PNG/JSON
  files**. The whole-screen mockup's protected dungeon, controls, compass and
  fine portrait regions match the saved screenshot at native sampling.
- This revision used **no Godot runs**. It has not been integrated or tested
  on the phone. No files were staged or committed by Codex C.
