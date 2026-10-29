# M4c: doors stay put, tools work in hand

Start with **build/m4c_shots/m4c_sheet_2x.png**. Its first two frames are an
ordinary-tap closed/open lock pair, without movement between them. The card
frame shows vines underneath. Four before/after pairs show the Lower Watch's
corridor, room and closed/open wooden door. Magnified socket pairs make the
one-pixel flare reviewable. A native sheet and full 3x captures sit beside it.

## What changed

- Locks now draw both states on one world plane at their entry boundary.
  Opening no longer changes a full solid cell into an inset portal. Gate,
  web and cord planes remain fixed; cache faces remain on their solid wall.
  The focused check compares physical planes and all projected depth/UV/size
  columns on both corridor axes from all four camera approaches.
- Three strike frames hold 160ms each; two web-burn frames hold 240ms each;
  Ghost dispel lasts 360ms; hurt flash/shudder lasts 640ms. Claude's hand
  timings remain untouched: use 600ms, ring 800ms, torch frame 300ms, Seal
  1000ms. A separate hurt gate clock preserves the previous input gate rather
  than making the longer hurt picture slow later actions. Simulation is unchanged.
- Vines stay visible under cards and pop-ups; only the map hides them. The
  source PNG is never modified. Exact socket pairs/palette/timing live in
  data/ui/overlay_glints.json. A private presentation RNG schedules a flare
  every 8-22 seconds, with an 18% paired-eye chance, lasting 300ms. Candle
  frames sit at C's (147,155), 7x17 each, on an irregular 430/270ms beat.
  The candle-free overlay and strip are C's delivered files. Both animations
  freeze under pilot metadata, and the candle is in the required-asset guard.
- Every pack/equipment/belt state uses B's accepted painted icon map in
  item_art.gd: including spent coat, cold/lit reed and the standard club.
  The alternate club remains unused. Travel and Continue call play_floor
  with the actual floor, including The Watch Beneath the Bell on three.
- ArtFamily maps floors three onward to Lower Watch walls, dressings, doors,
  blocked decorations, props, calm_v3_f3 flags/vaults and room landmarks.
  Fixtures retain floor two. F1/F2 and all difficulty/generation remain intact.
- Hidden scar taps give only “Faint scratches. / You can't make them out.”
  No turn, spoiler card, verb or glint. The third-floor Seal reveals it on
  return. Revealed panels offer PRY with a selected or held EDGE; cords keep
  CUT. All capabilities resolve selection first, then the hand; only LIGHT
  searches pockets. Throwing still requires the existing explicit preview.

The frame (0,18,154,156), picture (3,21,148,150) and compass
(85,294,66,44) are unchanged. No save migration or rule-profile change.

## Reproduce

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m4c_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4c_pilots.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4c_gallery.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4c_pack.ps1
```

New ordinary pilots: m4c_lock.txt taps the lock and captures both states;
m4c_pry.txt walks three floors, brings dawn home, puts the knife in the pack,
equips it again through its card, and taps the revealed panel without selecting
it. Both finish with the ordinary deterministic state hash and six HP.

The eleven gallery samples use explicitly restored, labelled renderer fixtures,
not a claim of playing to each pose. Their frozen flares are authored test
frames. overlay_pixel_checks.json proves each flare changes exactly its two
configured sockets, from palette 15 to 17, and the candle changes only its
flame box. The four F3 baselines come from the accepted M4b PCK, rendered with
the same snapshots. The live lock pair comes from the new tap pilot instead.

## Validation

| Check | Result |
| --- | --- |
| Eighteen source suites | **275,242 checks; 0 failures** |
| New M4c focused suite, included above | **504 checks; 0 failures** |
| Ordinary windowed tap pilots | **36/36 passed; muted** |
| Required runtime textures | **440 source and packaged paths load** |
| Empty-directory exported PCK guard + complete three-floor tour | **775 checks; 0 failures** |
| Authored visual fixtures | **11 current captures + 4 accepted-pack baselines** |
| Overlay pixel comparisons | **4 exact socket-pair checks + candle flame check passed** |
| D's unchanged QA runner, bounded all-phase rerun | **18/18 phases passed; 0 script errors/findings** |

Receipts: build/m4c_check_results.json, m4c_pilot_results.json,
m4c_pack_test.log, m4c_after.log and m4c_shots/overlay_pixel_checks.json.
The new cache pilot was additionally rerun after making its post-reveal
unequip/equip sequence explicit; its current log and screenshots replace the
earlier version. All 300 deep seeds still span **84-146 core / 176-225 tour
turns**, with zero witness damage.

D's harness/report were untouched. This focused pass reran every QA phase
with smaller sweep parameters, rather than repeating D's separately accepted
full deep audit:

```powershell
powershell -ExecutionPolicy Bypass -File tests/qa/run.ps1 -Seeds 128 -AdversarialSeeds 16 -DeepSeeds 128 -DeepAdversarialSeeds 16 -DifficultySeeds 32 -DeepEdgeSeeds 8
```

Receipt: build/m4c_qa_runner.json; phase logs remain in tests/qa/results/.
The deep save phases refused all **915 type corruptions**, then reopened
**161 snapshots** in a fresh process and replayed **7,184 continuation actions**.
These are this bounded run's numbers, not the default sweep's counts.

## Limits and handoff

All windows used muted pilots; no audible output or phone session was run.
The resource PCK was checked independently, but an APK/device export and the
owner's judgment of slower motion/music remain unverified. This pass does
not retune depth, enemies, loot, food or run length. Nothing was committed.
Owner project settings and concurrent artist files were preserved.
