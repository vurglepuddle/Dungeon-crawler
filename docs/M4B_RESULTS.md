# M4b: painted kit wired

Start with `build/m4b_shots/m4b_sheet_2x.png`. More focused comparisons:
`m4b_dressings_2x.png`, `m4b_ground_2x.png`, `m4b_inventory_2x.png` in the same
folder. Native sheets and every full-screen 3x Godot capture remain beside
them under before/ and after/. The main sheet crops the dungeon picture;
the inventory sheet keeps the whole screen.

## Scope

No commit and no depth tuning. New-game floor count, difficulty, encounters,
generation, turn economy and the M4a save profiles are unchanged. The owner's
three-floor phone verdict still precedes another design/tuning pass.

All requested current paintings are wired:

- C's seven dressing states per floor and both sconce prewarm paths use v2.
  The closed key door is painted wood; an open lock uses its own transparent
  wood/arch overlay through the existing portal projection.
- B's floor-specific inset plates and painted side levers replace the flat
  sprites. A lever's shared WallFaces binding chooses front versus side and
  its physical hinge. The accepted head-on paintings are retained.
- Silk and cord use canonical v2 d1 portal faces. Burning holds two 120ms
  frames, then burnt remnants; cut cord leaves a genuinely transparent route.
  No billboard doubles the portal.
- Lift decks and down-stair thresholds override the fixture's world cell,
  not the Finder's cell. Negative binding normal orients the inner painting;
  the two-pixel seam ring never rotates. Lift activity enters the surface key,
  so returning the clapper refreshes ground while standing still.
- The open cache is B's full painted face, replacing the code rectangles.
  Spent coats use coat_spent in pack, equipment and cards.
- Hound ember layers draw at 0.85 gain over normally dimmed bodies, clipped
  by the same columns/portals. Quiet floor/ceiling landmarks sit in real
  three-wide rooms, never in corridors; special fixture ground wins priority.

Intentional map ink, digits, glints, lanes, arrows and compass geometry remain.
The 1993 splash is still the accepted game screen; no boot/project setting was
changed here. All current deep visuals still borrow the floor-two kit. The
single ArtFamily mapping now has separate walls/fixtures/props/plane settings,
so the forthcoming environment can change without demanding floor-three props
or travel fixtures that do not exist yet. Incoming Lower Watch music/pack art
is outside this wiring pass.

The view frame is pixel-exact (0,18,154,156), picture (3,21,148,150), compass
(85,294,66,44). The owner's optional vine PNG arrived during the pass and the
existing hook picked it up. It was neither repainted nor moved. Earlier before
captures predate its arrival, so the outline difference is separate from the
listed material swaps. Cards/map still hide it, and its hub remains above
the compass needle. Concurrent project/music/manual/flavour/art-author changes
were preserved; they are not authored by this implementation.

## Required assets

RequiredArt lists the complete runtime texture inventory. The source check
loads every path, including waiting Porter sizes, all inventory states,
chrome, animated paintings, portals, hands, portraits and screens. The export
probe repeats the check from an empty resource directory using the actual PCK.
Export staging reads the same runtime inventory and requires raw source files,
so a stale staging/import cache cannot hide a lost painting. Future family
paths are included automatically.
A deliberately missing inventory entry is rejected in both checks without
renaming/deleting a real asset. Paint logs failed required loads. Chrome has
no StyleBoxFlat substitution, inventory has no M1 silhouette fallback, and
waiting Porter has no conditional transparent disappearance. The historical
M1 texture function remains dormant for its old tests.

## Reproduction and validation

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m4b_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4b_pilots.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4b_gallery.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4b_pack.ps1
powershell -ExecutionPolicy Bypass -File tests/qa/run.ps1
```

The gallery uses **45 labelled, authored renderer fixtures**, including both
art families, actual lift landings and both down-stair landings, fixed fire
frames and an opened cache/lock. These are real Godot/Main renders with
explicit snapshot setup, not a claim of ordinary walking through all those
poses. Before images use the pre-change renderer; the added floor-two stairs
baseline was captured from the accepted M4a PCK. The separate 34 pilots use
ordinary real taps, including the full deep run and fresh-process save pair.
All windows have pilots and remain master-muted.

| Validation | Result |
| --- | --- |
| Seventeen source suites | **274,738 checks; 0 failures** |
| Ordinary windowed tap pilots | **34/34 passed; muted** |
| Authored visual fixtures | **45 before / 45 after captures** |
| Required runtime textures | **381 source and packaged paths load** |
| Isolated exported PCK, guard + complete three-floor tour | **716 checks; 0 failures** |

Receipts: build/m4b_check_results.json, m4b_pilot_results.json,
m4b_pack_test.log and m4b_after.log. The unchanged 300-seed deep regression
still spans **84-146 core / 176-225 tour turns**, taking no witness damage.
Two historical assertions were updated for deliberate presentation changes:
the painted cache face replaces the generated aperture, and a valid optional
vine overlay may now exist. All other inherited checks remain in the batch.

D's unchanged default runner completed **9/9 phases, 0 findings/script errors**.
Generation covered 3,141 seed codes and 6,932 runs. Adversarial play covered
**768 trajectories / 270,092 actions / 2,299 save round trips**.
Its one budget-limited sample was resumed and proved reachable. Save fuzzing,
malformed-type refusal, occupied stairs, edge policies and separate-process
reopen all passed. Receipt: build/m4b_qa_runner.json; the phase output is in
build/m4b_qa.log. D's separate concurrent deep investigations are outside this
receipt; their harness/report files were preserved.

## Limits and read

The paintings make fixtures look like parts of the same place. The wooden
lock and cache are particularly clear improvements. At the normal eye height,
standing against a lift/stair face shows only a narrow strip of one's own
floor; the approach comparisons show the deck/treads better. No camera was
shifted to exaggerate that difference. The optional landmarks are deliberately
sparse so the quieter accepted floor remains dominant.

This pass should make the existing decisions easier to read; it makes no new
claim about difficulty or 10-15-minute pacing. No M4b APK or device playtest,
new touch-comfort measurement, or phone frame-time acceptance was performed.
D's QA report/harness and B/C's authored source assets were not edited.
