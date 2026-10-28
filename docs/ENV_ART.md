# Codex C: dressing, possessions, portraits and atmosphere

This pack is prepared for Codex A to wire in. It does not change the renderer,
simulation, main scene, UI chrome, catalog, or original PNGs. Painted source
PNGs, exact built-in imagegen prompts, code drawings, deterministic reduction,
and contact sheets live in the four corresponding `art_src/` folders.

## Rebuild and inspect

From the repository root, with Python and Pillow installed:

```powershell
python -B art_src/env/build_all.py
```

Or run `build_env.py`, `build_icons.py`, `build_portrait.py`, and
`build_screens.py` in their respective folders. No API, network, model or
Godot is used by the rebuild. The saved paintings are the reproducible input;
rerunning imagegen from the recorded prompts can produce different paintings.

Every runtime PNG and sheet is indexed against `art_src/spike/palette.gpl`:
31 opaque inks and transparent index 0. All sampling/enlargement is nearest
neighbour; no dithering or translucent fringes. Text on sheets uses native
VETKA 16, rendered without antialiasing. Manifests record hashes, dimensions,
opaque bounds and source hashes. Generated sources themselves keep their
original unrestricted colour and resolution. No old art is overwritten.

| Set | Native size | 4x review sheet |
| --- | --- | --- |
| Environment, combined | 28 tiles, each 64 × 64 | `art_src/env/contact_sheet_4x.png` |
| Abbey stone | 14 tiles, each 64 × 64 | `art_src/env/floor1/contact_sheet_4x.png` |
| Older wet stone | 14 tiles, each 64 × 64 | `art_src/env/floor2/contact_sheet_4x.png` |
| Mixed tile repeats | 256 × 192 | `art_src/env/floor1/repeat_4x.png`, `floor2/repeat_4x.png` |
| Possessions | 13 icons, each 16 × 16 | `art_src/icons/contact_sheet_4x.png` |
| Finder states | 3 portraits, each 32 × 32 | `art_src/portrait/contact_sheet_4x.png` |
| Story plates | title/splash 154 × 150; endings 128 × 80 | `art_src/screens/contact_sheet_4x.png` |

## Wall faces: texture selection only

Runtime root: `assets/art/env/`. Prefix `f1_` means abbey limestone; `f2_`
means the older, colder courses below. Each prefix has these suffixes:

| Suffix, before `.png` | Intended use |
| --- | --- |
| `plain_0`, `plain_1`, `plain_2` | Common quiet wall faces; small wear variations |
| `sconce_0`, `sconce_1` | One fixed iron bracket; two flame states, suggested 4 fps |
| `crack` | Long single fracture, purely decorative |
| `damp` | Moss-coloured damp trails and a wet foot |
| `chains` | Two hanging lengths, no interactive promise |
| `tapestry` | Faded dawn-and-bell cloth, useful near the Porter |
| `drain` | Low iron grate, opaque background |
| `arch` | Dark arched recess/opening picture; no transparent hole |
| `door` | Closed iron-banded wood inside the matching arch |
| `floor`, `ceiling` | Optional world-space surface samples, described below |

Wall anchor is the whole face: UV origin top left, U rightwards, V downwards,
64 × 64, fully opaque. Every wall variant within a floor shares the outer
two-pixel ring. Opposite endpoint rows/columns also match exactly. Mixed tile
repeat sheets show the shared seams. Floor-two shades are deliberately darker;
avoid stacking another strong blue/dark floor tint over them.

The original paintings supply broad surface clusters. The builder compresses
their contrast, rebuilds aligned mortar, and adds editable integer-pixel
dressing. This is hybrid art, not 24 independent generated paintings.

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

Runtime: `assets/art/portrait/finder_fine.png`, `finder_hurt.png`,
`finder_near_death.png`. All 32 × 32, opaque, top-left drawing origin, centre
anchor `(16,16)`. `finder_strip.png` is 96 × 32 in that order.

Fine is reduced from a preserved copy of the original painted source and is
pixel-identical to `assets/art/finder.png`. Hurt and near-death are separate
identity-preserving imagegen edits of that same original, with fixed hood,
strap, pose and crop. No colour-tint substitute or new character.

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

## Verification receipt, 28 October 2026

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
