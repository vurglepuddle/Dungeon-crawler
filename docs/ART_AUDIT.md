# UNDERCROFT visual-source audit

29 October 2026. Codex D. Read-only inspection of the game, with a headless
texture inventory; no windows, game edits, art rebuilds or commit.

**The remaining ordinary object drawings are principally the pack icons,
pressure plate, side levers, web, cord grate and opened cache. Lift/stair cells
have no dedicated underfoot art. The engine boot splash is still the stock
engine image. Most scenery, creatures, hands and story screens are already
painted.** Compass/arrow geometry, map ink, digits and interaction cues are
deliberate code visuals, rather than missing paintings.

This records the **working tree**, alongside the phone build distinction:

- HEAD is `5810909`, M3f. A is concurrently editing the view/main for the next
  round. Function names below are the stable references; line numbers are approximate.
- **M3f enlarges native inventory icons for ordinary world possessions. A's
  uncommitted view now loads B's 36 dedicated world paintings**, including the
  spent coat. The paintings are therefore no longer unwired in this tree,
  but they are not in the owner's existing M3f phone build. Historical M3f
  screenshots still show the enlarged icons.
- C is repainting the known wall dressings and locked door. They remain listed
  for completeness, but are not additional commissions from this audit.
- A PNG does not necessarily mean a painting: the plate, side lever, icons,
  silk, ropes and effects are generated from explicit native pixel geometry.
  Conversely, texture sampling, lamp tint and a generated floor buffer do not
  make their underlying painted scenery placeholder art.

## Ten most visible remaining code-art or stand-in candidates

Ordered by normal-play exposure, excluding C's already assigned wall/lock work.
These are ten candidates, **not ten defects**; recommendations distinguish
object replacements from intentional interface drawing.

| Rank | Element | Actual source now | Existing painting / recommendation |
| ---: | --- | --- | --- |
| 1 | Pack, hand/body and belt item icons, including the spent coat's ordinary coat icon | `assets/art/icons/{kind}.png`; torch/Seal use `assets/art/fixtures/*_icon_*16.png`. All are native code-authored pixels. | No separate painted 16px replacement pack found. B's new world paintings are not HUD icons. **B/C: new native-size icons only if matching the painted object style is wanted**; preserve their readability and state differences. |
| 2 | Six movement arrows | `main.gd::_arrow`, around 865; lines and triangles over painted bronze | No replacement arrow set found. **Intentionally code-drawn**; retain crisp direction symbols, or have C supply a complete matched set if restyling. |
| 3 | Compass dial, ticks, needle and hub | `main.gd::_draw_compass`, around 847 | No painted dial/needle found. Ivy compass PNGs are transparent ornament, not replacement instruments. **Keep code needle/ticks**; a C-painted housing/dial is optional, not an unwired asset. |
| 4 | Pressure plate, pressed/unpressed, including underfoot | `assets/art/fx/plate_{up,down}_d{1,2,3}.png`; `art_src/fx/build_fixtures.py::plate` draws the shallow polygons | No painted plate found. **B: needs a painted inset plate pair** if replacing the flat object style; retain its shallow aspect, registration and visible state change. |
| 5 | Lever seen from the side | `assets/art/fx/lever_{left,right}_{up,down}_dN.png`; same builder's `lever` function | **Painted art already exists:** `assets/art/fixtures/lever_wall_f{1,2}_{up,down}_64.png`. **A: project the existing painted wall face for side views**. Front hardware paintings are already wired. |
| 6 | Underfoot lift platform and stair threshold/well | Ordinary `calm_v3_floor_*` material. Travel fixtures are excluded from the sprite pass; `_build_surfaces` never branches on a lift/stair cell. | Painted **wall** faces exist, but no dedicated floor-plane/underfoot lift or stair art was found. **B: new ground-plane art**, then A wires it. Do not revive the old procedural `lift_floor` sprite. |
| 7 | Web intact, burning and burnt | `assets/art/fixtures/web_{intact,burning_0,burning_1,burnt}_dN.png`; `build_m3c.py::web` draws strands and fire | No painted silk replacement found. **B: needs painted web states** if this environmental object should match the paintings; preserve aperture and burn readability. |
| 8 | Cord-bound grate, intact/cut | `assets/art/fixtures/cord_grate_{intact,cut}_dN.png`; `build_m3c.py::grate` draws bars, knot and frays | No painted cord-grate replacement found. The ordinary painted portcullis is a different object. **B: new tied/cut grate art**; do not substitute the keyed door or weight gate. |
| 9 | Opened secret-cache recess | `dungeon_view.gd::_draw`, around 503: black column rectangles with brown edge, over the painted wall | Plain/revealed sigils exist, but no painted open recess. **B/C: needs an opened stone-cache overlay/face** on the current masonry. |
| 10 | Engine boot image before LOST MOTH | Empty `application/boot_splash/image`, with `show_image=true`; stock engine splash | C's `assets/art/screens/splash.png` already exists, but is used only after scene startup. **Wire existing art as a custom boot image**, or have C prepare a portrait boot composition. Actual phone startup was not observed in this audit. |

For the last row, the effective project settings were read headlessly. Godot
4.3's [boot-logo implementation](https://github.com/godotengine/godot/blob/4.3/main/main.cpp#L2982)
selects its built-in splash when no custom image is supplied. This is separate
from the already painted, animated in-game publisher plate.

## Complete visible-element inventory

`P` = painted source, often palette-reduced or retouched. `N` = deliberately
authored native pixel art baked to PNG. `C` = runtime drawing. `S` = reused or
generic representation. Mixed sources are stated explicitly. Paths are repo-relative.
Rows are grouped by normal-play prominence; repeated states share a row only
when their source and recommendation are the same.

| Visible element / states | Current source and drawing path | Painted art already available? | Recommendation |
| --- | --- | --- | --- |
| Main wall masonry, plain variants and damp floor-two family | **P + N retouch:** `assets/art/env/painted_f{1,2}_plain_{0,1,2}.png`; view `_wall_path` / `_build_camera` | Wired; preserves the accepted `stone_wall.png` painting | Keep. Palette changes, seam repairs and deterministic variation are not stand-ins. |
| Sconces (two flames), tapestry, chains, drain, crack and damp wall dressing | **P base + N dressing:** `painted_fN_{sconce_0,sconce_1,tapestry,chains,drain,crack,damp}.png`; `art_src/env/build_env.py::dressing`, reused by `painted_v2/build_painted.py` | The wall is painted; these dressing shapes are native geometry on it | **C already repainting.** Track all variants, not only the sconce. |
| Closed decorative arch and barricaded broken door | **P base + N infill/barricade:** `painted_fN_arch_blocked.png`, `painted_fN_door_barricaded.png`; `art_src/env/closed_v4/build_closed.py` | Existing composite is wired; newer dressing is C's active work | C: include these when replacing coded wall additions; retain unmistakable blockage. Old open-looking `painted_fN_arch.png` is not selected by this view. |
| Locked keyed door | **P base + N door:** `painted_fN_door.png`; closed locks select it directly in `_build_camera`, around 265 | B's `architecture_fN_exit_64.png` is a painted **exit** door, not dedicated matching lock art | **C already repainting.** Do not report the painted exit as an unwired lock replacement. |
| Normal flagstone floor, wear and puddles | **P + N wear/water:** eleven `assets/art/env/calm_v3_floor_*.png`; `plane_materials.gd::path`, `_build_surfaces` | Wired. `art_src/env/calm_v3/build_calm.py` starts from painted stone and adds explicit wear/puddle geometry | Keep the accepted painting. The code water/crack/chip derivatives are disclosed here; C can repaint those details if the brief means zero drawn-on environmental additions. No old runtime procedural grain branch remains. |
| Vaulted ceiling, plain/root/drip | **P + N root/drip derivatives:** `calm_v3_ceiling_{plain,root,drip}.png`; same plane caster | Wired; the latest shared rib vault is active | Keep. Older rough-rock/old floor-specific ceilings are alternates, not missing wiring. |
| Floors three/four in A's in-progress deeper run | **S:** walls/architecture/props clamp to family two; plane selection clamps weights to floor two | No dedicated f3/f4 painted family found | Intentional reuse for now. C/B need new art only if deeper floors require a distinct visual identity; do not claim those new floors already have distinct paintings. |
| Ordinary floor possessions: knife, shard, club, stone, bone, bread, tonic, coat, key, clapper, lamp | **P, working tree:** `assets/art/items/item_<kind>_d{1,2,3}.png`; new `_build_camera` branch around 368 | B's 36-sprite pack is now referenced and all files load | **A already integrating.** M3f's enlarged `Art.inventory(kind)` pictures are the shipped stand-in; do not commission this pack again. |
| Spent coat on floor | **P, working tree:** `assets/art/items/item_coat_spent_dN.png`, selected by item `spent` | Now referenced | Finish A's integration. HUD still uses the ordinary coat icon; that is a separate state-art gap. |
| Floor reed torch, unlit/lit | **P reed bundle + N native flame:** `fixtures/reed_torch_{unlit,lit_0,lit_1}_dN.png`; `_painted_fixture` | Wired, with state-specific art | Keep the painted object. Flame silhouettes are intentional two-frame pixel animation. |
| Dawn Seal on pedestal | **P + palette pulse:** `fixtures/dawn_seal_pulse_{0,1}_dN.png` | Wired | Keep; not an enlarged pack icon. |
| Brazier/coals and flame | **P bowl + N coal/fire:** `fixtures/brazier_lit_{0,1}_dN.png` | Wired. `brazier_cold_dN.png` also exists | Keep. Current generation supplies lit renewable braziers; cold art is an unused supported offer, not an active fallback. |
| Bell Husk, idle/windup/recovery; brief lethal recoil | **P:** `anim/bell_husk_{idle,windup,recoil}_{64,40,24}.png` | Wired for all distances/poses | Keep. The old root `bell_husk_24.png` was code-drawn, but the current view never loads it. |
| Ash Hound, idle/windup/recovery/peaceful | **P:** `creatures/ash_hound_ember_{idle,windup,recoil}_{64,40,24}.png`; peaceful maps to idle | Wired. Matching glow overlays also exist | Keep base poses. Optional **wire existing** `ash_hound_ember_glow_*` as a separate un-dimmed pass if needed; current code instead raises the whole Hound's minimum brightness to 0.48. No dedicated peaceful pose exists or is required by this audit. |
| Wick Ghost, idle/windup/recovery/dispel | **P:** `creatures/wick_ghost_{idle,windup,recoil}_{64,40,24}.png`; recoil texture fades on dispel | Wired | Keep. Fading/tint is presentation, not missing frames. |
| Bell Porter waiting/restored | **P:** root `porter_{64,40,24}.png`, then `anim/porter_restored_{64,40,24}.png` | Wired | Keep. No procedural chest lamp replaces the restored painting. Missing waiting-file fallback is listed below. |
| Exit/home doorway | **P:** `fixtures/architecture_fN_exit_64.png`, sampled on a fixed wall face | Wired; copied border/masonry and two native daylight rows | Keep. A 64px canonical face also covers side/distant views; unused side previews are not missing integration. |
| Weight gate open/closed, visible room through iron | **P + N alpha silhouette:** `fixtures/architecture_fN_gate_{open,closed}_overlay_64.png` | Wired. Painted gate sheet is the source; explicit metal mask preserves transparent gaps | Keep. It is not the coded cord grate, and the opaque gate face is intentionally not used over a real passage. |
| Stairs up/down from room/corridor | **P + N carved marks:** `fixtures/architecture_v3_fN_stairs_{up,down}_64.png` | Wired. Owner's accepted down painting and matching up painting, with carved V/^ patch | Keep. Do not revive original M1 floor billboards or older v1/v2 stair signs. |
| Lift shut/dead and open/working from room/corridor | **P:** `architecture_v2_fN_lift_dead_64.png`, `architecture_fN_lift_working_64.png` | Wired | Keep. These are full wall faces, not floor-plane platform paintings. |
| Underfoot lift landing / stairs cell | **S:** ordinary painted floor; architecture lives only on its backing wall | Wall art exists; no dedicated ground counterpart found | **B: new ground-plane art if a recognizable platform/well is required underfoot**. Static evidence: sprite exclusion around view 303 and no fixture branch in `_build_surfaces`. Existing M3f `26_lift_home.png` also shows ordinary flags on the lift cell. |
| Plate up/down, normal and underfoot | **N:** `fx/plate_{up,down}_dN.png`, from `build_fixtures.py::plate`; clipped near frame when underfoot | No painted plate pair found | B replacement candidate; preserve inset proportions and support-item ordering. |
| Front-on lever up/down | **P:** `fixtures/lever_front_{up,down}_dN.png`, selected from fixed wall normal | Already wired; canonical `lever_wall_fN_*_64.png` also exists | Keep front art. Consider the wall-face implementation for a unified painted lever at all angles. |
| Side lever left/right, up/down | **N:** `fx/lever_<side>_<state>_dN.png` | Canonical painted lever wall faces exist | **Wire existing B wall faces** instead of requesting a new lever. Hardware must remain tied to one physical wall. |
| Web intact/burning/burnt | **N:** `fixtures/web_*_dN.png`; actual portal uses d1 as a 64px face, including burn transition | No painted replacement found | B replacement candidate; existing d2/d3 redraws are supplied/preloaded, but not selected by the 64-column portal path. |
| Cord/grate tied/cut | **N:** `fixtures/cord_grate_{intact,cut}_dN.png`; actual portal uses d1 | No painted replacement found | B replacement candidate. Left/right and smaller native options exist, but are also native drawings. |
| Secret wall plain/revealed glyph | **P wall + N mark:** `painted_fN_plain_0.png` plus `fixtures/panel_sigil_{plain,revealed}_64.png` | Overlay is wired. Older full `panel_fN_{plain,revealed}_64.png` composites exist | Keep the carved symbol as intentional pixel geometry; do not replace the accepted wall with the older full-panel masonry. |
| Opened secret recess | **C:** `_draw` fills the aperture with dark rectangles and brown edge | No painted opened-cache texture found | B/C new open-recess art; existing reveal sigil is not an open cavity. |
| Room rubble, bone heap, skeleton, pots, statue, candles, crate, pilaster | **P:** `props/f{1,2}_{kind}_d{1,2,3}.png`; generation `room_dressing.gd` and view prop branch | Wired for all eight families; actual seeded placement chooses a subset | Keep. These are not coded loot stand-ins. Pillar uses a solid masonry recess. |
| Optional standalone room puddle | `props/f2_puddle_dN.png` is **P**, but no placement in `RoomDressing.KINDS` | Exists, unused; ordinary wet floor variants are already wired | Optional alternative, not a missing water implementation. Avoid stacking it over existing pools. |
| Held fist, knife, shard, club, stone, bone, clapper, lamp, reeds, Seal | **P + native flame/pulse/ring details:** `hands/hand_<kind>_<frame>_56.png`; `held_item.gd` | All 23 referenced frames wired, including rest/use, clapper ring, lit torch and held Seal | Keep. Unsupported future kinds use fist; see fallback list. No game-hand placeholder remains for current equipable kinds. |
| Object/body contact shadows | **C:** `_draw_sprite`, around 450, per-column contact ellipse; ordinary item width now follows opaque bounds | B intentionally supplied world items without baked shadows | **Intentionally code-drawn**; painting a shadow into each frame would duplicate it. |
| EDGE/HEAVY/fist strikes and damage burst | **N:** `fx/{edge,heavy,hands,damage_burst}_{0,1,2}_64.png`; `art_src/fx/build_fx.py` | No painted replacement; these were deliberately authored as crisp native effects | Keep. Not missing creature animation. |
| Actual damage digits | **C + font:** VETKA 16, `_draw` around 526, native text with shadow | Correct font is wired; burst leaves space for it | **Intentionally code-drawn** actual values, never baked numbers. |
| Gold/selected sparkle and travel-keystone point | **N:** `fixtures/glint_{gold,target}_{0,1,2}_{7,9}.png`; keystone reuses gold frame zero | Wired native glint pack | Keep. Dynamic phase/tint and selected colour are intentional. |
| Selected-target corner brackets | **C:** view `_draw` lines around 552; inventory uses `item_button.gd::_draw` | No separate painted brackets supplied | Keep as precise, state-dependent UI cues. |
| TOSS preview and Hound lunge lane diamonds | **C:** view `_draw_lane` | No replacement supplied | Keep as legible tactical overlays. This is not projectile or creature placeholder art. |
| Red hurt border, portrait outline, hit flash/recoil/bob | **C modulation/border:** view `flash`, main `_hurt_time`; painted portraits/poses underneath | All state paintings wired | Keep feedback geometry; no need to commission a second hurt face or a full-screen painting. |
| Dust motes, floor-two drips, lamp veil, travel fade and capability flashes | **C:** `scripts/fx/ambience.gd::_draw` / `_ink` | None needed; explicitly texture-free effects | Keep intentional presentation particles, brightness and transition black. |
| Main bronze frame, buttons, top strip and compass housing background | **P + native edging:** `assets/art/chrome_32.png`; `Chrome.style` tiled nine-slice | Wired. `assets/art/ui/frame.png` is a separate unused material variant | Keep accepted bronze. There is a real flat-style missing-resource fallback below. |
| HUD backing field / camera opening | **C:** main `_draw` brown field `(0,0,154,268)` and dark camera gap `(53,0,44,18)`; painted layers cover most of it | Painted leather/slate/bronze already exists around it | Intentional backing/masking, not a missing large painting. C can supply a unified upper-panel material if wanted. Keep camera gap clear. |
| Message slab, pack tray and belt loops | **P:** `ui_offer/message_slate.png`, `pack_leather.png`, `belt_loops.png` | Wired at native sizes | Keep. Empty pack positions deliberately have no placeholder item/dashes. |
| Health vial, glass and variable fill | **P vial + drawn/derived liquid:** `ui_offer/hp_vial_empty.png`, `hp_vial_full.png`, cropped to actual HP | Wired | Keep. Dynamic crop is intentional. No old duplicate HP bar is drawn in current main. |
| Finder fine/hurt/near-death | **P:** `portrait/finder_fine.png`, `finder_hurt_v2.png`, `finder_near_death_v2.png` | Wired. Fine is pixel-identical to root `finder.png` | Keep; older injured variants/strips are alternatives, not missing wiring. |
| Pack/equipment/belt icons, torch states, key count badge | **N:** eleven ordinary `icons/*.png`, B's two reed icons and Seal icon; **C font** count badge | No dedicated painted 16px replacement pack. World item paintings now exist but have a different size/purpose | Disclose as native icon art; request B/C replacements only if eliminating coded object silhouettes. **Spent coat still shares the ordinary HUD coat icon.** Keep actual count text dynamic. |
| Movement symbols and compass instrument | **C** `_arrow` / `_draw_compass` over P bronze | No separate arrow/dial pack. C's ivy compass is transparent decorative trim | Keep functional shapes; C new art only for a specific restyle. Do not mislabel ivy as the missing dial. |
| Verb stamps on strip/cards | **N:** `ui_offer/verb_*.png` and compact variants selected by `data/ui/verb_layout.json`; `item_button.gd::verb_layout` | Wired. The sheet comprises native drawings, not paintings | Keep intentional 12px/compact glyphs and native VETKA words. UNEQUIP reuses `verb_pack.png`. Unknown labels fall back to centered text. |
| Item cards | **P material:** `Chrome.surface("card")` intentionally redirects to `ui/slate.png`; names, capabilities, provenance and verbs use VETKA | Material is wired. `ui/card.png` is supplied but not used | Keep current quiet slate, or **wire existing card material** if a verdigris card is desired. No missing item illustration is implied by a text-first card. |
| Porter/creature/fixture help, portrait help, keys chooser, loot chooser, save status/retry, new-run confirmation | **P slate + P bronze + C text/control layout:** `_panel`, `_label`, `_modal_button` | All required material assets are wired; decorative brass/candle offer remains unused | Keep readable controls. Optional existing props are decoration, not substitutes for modal illustrations. |
| Seed text field, caret, selection and focus/context-menu appearance | VETKA font and bronze normal style explicitly overridden; remaining LineEdit caret/selection/focus/menu visuals come from Godot's default theme | No dedicated painted edit/focus set found | **Intentionally code/widget UI**. Explicitly theme those states only if desired; no fallback font is used for the entered seed itself. |
| Automap parchment | **P-derived torn leaf:** `ui_offer/map_parchment_torn_v2.png`; `_panel` map branch | Wired. Old `map_parchment.png` and `ui/map.png` are alternatives | Keep the torn leaf; not a generic flat modal. |
| Map rooms, hatching, dashed exploration edges, question marks, gate/stair/lift/Porter/plate/web/cord/panel/brazier/Seal glyphs, facing marker | **C:** `scripts/ui/map_view.gd::_draw` | No painting needed for dynamic knowledge/position | **Intentionally code-drawn ink**, including glyphs and player triangle. Do not commission fixed map pictures. |
| All text, HP/status/save-failure `!`, headings and messages | `assets/font/vetka.ttf`, native 16px via `_label`, `_text`, item buttons and damage text | Real owner-approved font is wired; no temporary default font for these controls | Keep. Missing TTF is a preload failure, not a silent substitute. OS keyboard/system UI is outside game art. |
| Publisher splash and title illustration | **P + N typography/light derivatives:** `screens/splash_flutter_{0,1}.png`, `title_flicker_{0,1,2}.png`; original static plates also loaded | Wired and animated; painted `logotype_140.png` overlays title | Keep. LOST MOTH/1993 are actual VETKA lettering added to painted emblem, not placeholder type. |
| Death and win plates | **P + frame edits:** `screens/death_gutter_{0,1,2}.png`, `win_dawn_{0,1,2}.png`; static `death.png` / `win.png` retained | Wired, final frames held | Keep. Result text, seed and turn count remain dynamic. |
| Menu grounds/buttons and result text | **P slate/bronze + C VETKA layout** | Wired. `screens/subtitle_plate_140.png` exists but is not used | Optional **wire existing subtitle** if menu space permits. The current readable text is not a placeholder logo: painted title lettering is already present. |
| Engine boot splash, before the scene | **S:** built-in engine image; custom image path empty, show enabled | C's game splash painting exists, but isn't configured as boot art | **Wire existing splash** / C boot composition. Headless source/config finding; not a new phone observation. |
| Desktop/application and Android launcher/adaptive icon | Current custom painted Seal artwork in `assets/icon/icon_192.png`, `adaptive_fg_432.png`, `adaptive_bg_432.png`; project/export point here | Wired current custom icons. C's three `screens/icon_offer*` files are different alternatives, verified not pixel-identical | Keep approved launcher. The root `icon.svg` is a stock Godot file but **is not referenced** by project/export/current scripts. |
| Desktop pointing hand, up/down | **C pixel matrix:** `scripts/dev/pointer.gd::ART` / `_texture` | No replacement required | Intentional retro desktop cursor; disabled on mobile, headless and ordinary pilots. Not a Pixel 9a placeholder. |

## Existing art not drawn by the active paths

These are integration options, not a claim that every unused PNG is a defect.
All file existence was checked; the relevant runtime consumers were searched.

| Existing asset(s) | Current use / why unseen | Recommendation |
| --- | --- | --- |
| `assets/art/fixtures/lever_wall_f{1,2}_{up,down}_{64,40,24}.png` | Not referenced; front transparent paint is wired, side native sprites remain | **Highest-value existing painting to wire.** Use canonical 64px face on the fixed wall for all viewing angles. |
| `assets/art/creatures/ash_hound_ember_glow_{idle,windup,recoil}_{64,40,24}.png` | Base creature is used; glow pass is never loaded/drawn | Optional wire-existing improvement if the ember highlights need isolation from lamp dimming. |
| `assets/art/env/calm_v3_room_floor_{drain,cracked,compass}.png`, `calm_v3_room_ceiling_{roots,chain,boss}.png` | `Planes.path` only chooses the ordinary eleven floor / three ceiling names | Optional wire existing deliberate room landmarks; these are mixed painted bases/native landmark details. Earlier `painted_room_fN_*` and `room_fN_*` are superseded alternatives. |
| `assets/art/ui_offer/candle_{0,1}.png`, `brass_label.png` | Supplied painted/paint-derived UI decorations; no runtime reference | Optional existing ornaments for map/modal/footer areas; not a reason to crowd text or add small controls. |
| `assets/art/ui_offer/hanging_chain.png` | Supplied, no runtime reference | Optional native pixel ornament; **not a painting**. |
| `assets/art/screens/subtitle_plate_140.png` | Painted brass material with VETKA subtitle; no runtime reference | Wire only if wanted and it fits; do not duplicate the existing title logotype. |
| `assets/art/screens/icon_offer_192.png`, `icon_offer_foreground_432.png`, `icon_offer_background_432.png` | Current project/export uses `assets/icon/` instead; pixels differ | Alternate painted launcher offer, awaiting selection; not missing current launcher art. |
| `assets/art/ui/{card,frame,map}.png` | Active main uses bronze frame, torn parchment and slate for cards; these material variants are not loaded | Optional skin alternatives, not broken or unwired main screens. |
| `assets/art/ui_offer/ivy_{game_border,compass,map_border}_v4.png`, earlier v3 set, `sleepy_skull_v3.png`, `ivy_torches_v3_{0,1}.png` | No active reference. The optional owner overlay path is instead `assets/art/ui/owner_vines.png`, which is absent | These are **native code-authored ornaments**, not hidden paintings. Do not silently enable offers; retain the owner's cleaned-overlay handoff. The skull is already embedded in the v4 compass offer. |
| `assets/art/props/f2_puddle_dN.png`, `fixtures/brazier_cold_dN.png` | Painted alternatives without a current placement/state | Optional use only when content calls for them; current floor water and lit brazier are already represented. |
| Architecture strips, pre-skewed sides, 40/24px previews; creature/held strips; web/grate side variants | Active renderer samples canonical faces, individual states or d1 UV surfaces rather than these alternate encodings | **Not missing art integration.** Do not double-project or draw a second architecture layer. |
| Old full-panel masonry, original wall/plane families, earlier Hound/portraits/stairs | Superseded offers kept as history | Keep as source history; do not wire merely because the file is unused. |

The new `assets/art/items/item_*_dN.png` family is intentionally absent from
this unwired table: A's current view already references it. It **was** unwired
in M3f. The historical `tests/stage_m3f.py` allowlist also does not copy the
`assets/art/items/` directory, so the upcoming integration needs its own updated
packaging receipt; this audit did not create or test an updated export.

## Fallbacks and dormant placeholder paths

| Path / trigger | What a player would see | Current reachability / recommendation |
| --- | --- | --- |
| `item_art.gd::inventory`: ordinary icon neither exists as raw file nor registered resource | Old M1 `texture(kind)` procedural silhouette, cropped/resized into 16px | **Live conditional fallback.** All current required icon files are present; a missing packaged icon would still revive code art. Validate required assets instead of treating fallback drawings as final. Torch/Seal bypass this branch. |
| `Chrome.style`: `ResourceLoader.exists(chrome_32.png)` false | Brown `StyleBoxFlat`, two-pixel border | **Live missing-resource fallback.** It ignores a raw PNG if it is not a recognized resource. Painting exists; no new art needed. Keep a visible QA diagnostic / required-asset check. |
| `Chrome.surface`: painted texture resolves null | Flat teal `StyleBoxFlat` with a one-pixel border | **Live conditional fallback.** Painting exists; repair packaging/loading, not art. Loader errors may also be logged. |
| Waiting Porter files missing: `_porters.size()!=3` | Falls through to `Art.texture("porter")`, whose match has no Porter shape, producing a transparent image | **Live conditional disappearance**, not a painted fallback or a usable code Porter. Validate all three required waiting poses. Restored art already exists. |
| Unsupported future fixture routed through generic sprite `else` | `Art.texture(kind)` retains old plate/latch/stair/exit sketches or gives a transparent unknown kind | Existing known fixtures have explicit branches or wall faces; missing one is not automatically covered by a correct painting. Remove reliance on this as new fixture types are added. |
| Architecture has no `Faces.all` binding, or a latch finds no adjacent physical wall | `_architecture` / `_build_camera` skip that representation, leaving ordinary scenery rather than an old fixture picture | Source-confirmed conditional omission; no such generated placement was established in this art audit. Required face-binding validation is the appropriate guard, not a new fallback painting. |
| Unsupported held item kind | `Held.set_kind` chooses painted fist; unsupported use animation does nothing | **Live semantic fallback**, currently all legitimate hand equipment has frames. Intentional safe fallback, not proof of a missing current weapon painting. |
| Unrecognized Husk pose / peaceful Hound | Husk falls back to painted idle; peaceful Hound explicitly uses painted idle | Intentional pose reuse. No current idle/windup/recovery painting is missing. |
| Unknown verb not in measured layout | `item_button.gd::_draw` draws centered VETKA text without stamp | Live text fallback; no code icon is invented. Keep readable label and supply a stamp only for a real new verb. |
| Missing required `Paint.texture` file outside guarded paths | Null texture; some consumers then fail on `get_height`, `get_image`, or draw nothing | **No universal code-art fallback.** Raw PNG loading in `presentation_art.gd` is still the same painted file, not substitute art. All 356 enumerated paths loaded in this audit. |
| Engine boot image absent/empty or invalid | Built-in engine splash before the scene | Empty-path branch is active now. Existing C splash can replace it through boot settings. |
| `scripts/art/fixture_art.gd` | Contains old coded lift, `lift_floor`, stairs and plate images | **Dormant:** no current script references/preloads this module. Do not call this a live underfoot fallback. |
| Old root `assets/art/bell_husk_{64,40,24}.png` / `stone_wall.png` | The old distant Husk includes a coded drawing | Not selected by the current creature view. `stone_wall.png` survives as authoring/base history; current wall family is explicit. Presence in an all-resources export alone does not make the old sprite visible. |
| Root `icon.svg` | Stock Godot project icon | Dormant: project and Android launcher settings point at custom `assets/icon/` PNGs. Separate from the still-stock boot image. |

Missing-file fallback branches were inspected without deleting, renaming or
corrupting assets. Their triggers are source-confirmed; no missing-file failure
was induced in A's shared workspace.

## Verification and limits

Read `scripts/` rendering/UI consumers, project/export icon settings, the
referenced asset folders, `docs/ART.md`, `docs/ENV_ART.md`, relevant builders
and the M3e/M3f results. Inspected existing plate/icon/lever contact sheets and
M3f lift-arrival/whole-screen captures. Those captures are historical evidence,
not a new current-tree visual acceptance run.

`tests/qa/art_audit.gd` manually expands the current formatted texture paths,
loads **356 distinct textures** and verifies all 13 catalog kinds resolve to
16x16 inventory art. **Zero missing paths, zero failed textures, zero script
errors.** Counts include some eagerly loaded distance/state alternatives, so
they are not a claim that 356 different pictures appeared in gameplay. The
script also records effective boot settings and source hashes, and writes only
ignored evidence under `tests/qa/results/`. It never starts the main scene,
changes a save or rebuilds/imports art. The usual host certificate-store
startup diagnostic remains separate from script errors.

```powershell
E:/SD/GODOT/Godot.exe --headless --audio-driver Dummy --path . -s res://tests/qa/art_audit.gd
```

Evidence: `tests/qa/results/art_audit.json`, `.log`, `.err`. No phone, windowed
run, APK/PCK build or aesthetic acceptance was performed. A/C are editing
concurrently: recheck function bodies rather than relying on these approximate
line numbers. Source hashes in the receipt identify the inspected version.
