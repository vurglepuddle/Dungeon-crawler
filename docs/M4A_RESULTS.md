# M4a: the lower watch

Start with `build/m4a_shots/m4a_sheet_2x.png`, then start a new BELL42 run.
The twenty-panel sheet contains actual muted windowed captures of all three
phone fixes, the painted floor items, deep combat/padding, a fed Hound and
the third-floor Seal. One clearly labelled M3f frame compares the old stone.
The separate win capture is `17_deeper_home.png` beside the sheet.

No commit. Project/export settings, Pointer/autopilot, launcher, BRIEF,
COLLAB_LOG, B/C's authored art/text and D's harness/report are untouched.
Any concurrent art-author updates are outside this implementation.
The Android user:// replacement code
and separate audio preferences are unchanged. Pilots remain master-muted.

## The phone fixes

LIGHT now appears with cold reeds selected, equipped or simply in the pack.
Touching the brazier uses that same explicit action and keeps the same torch.
Selected reeds take priority, then hand, then pack order. No automatic action
is performed merely by walking past.

BURN now appears with lit reeds equipped or selected. Touching the web burns
it without throwing or unequipping. The real-tap pilot caught a second issue:
the Hound's inspection hitbox was intercepting the web's centre. Inspection
targets now respect closed webs/cords, so the visible obstacle receives the
tap. TOSS still works as an explicit alternative with its free lane preview.

Every visible travel face has a named target, including at a distance. A
distant touch says **Step closer.** without a turn, revision or movement.
A reachable stair chooses normal travel or SIDLE, a dead lift explains its
missing bell, and an exit without the Seal repeats the objective. Face taps
do not turn into general wall-bump commands. A blocked lift destination has
its own occupancy explanation instead of the misleading blocker message.

## The art and overlay registration

All twelve B world-item states use their full native 64x48 / 40x30 / 24x18
canvases and bottom-centre anchors. The stone is a faceted rock; cloth lies
flat; bottles/lamps stand on their bases. Spent padding uses coat_spent and
retains that state through dropping/recovery. The shadow fits cached opaque
bounds, rather than the transparent frame. There is no per-column texture
readback. Inventory icons stay native 16px; torch and Seal keep their existing
fixture sprites and animation. No source image was repainted or overwritten.

The frame remains exactly `(0,18,154,156)`, picture `(3,21,148,150)`, compass
box `(85,294,66,44)`. The owner's final native transparent overlay can be
copied to `assets/art/ui/owner_vines.png`. That layer is above chrome, picture
and needle, so its skull can cover the pivot. It hides while cards, modals or
the map are open. No camera-gap cutout is applied to the art: its intended
crest may overlap y10-24. The draft export has not been copied or wired.

## The deeper run

`docs/proposals/M4_DEPTH.md` was written before generation/combat changes.
The implemented portion is its bounded recombination, with ordinary new
games defaulting to three floors. Floor count remains a 1-4 parameter. The
pure API's old default remains two; retained M3 pilots pass 2, while
ordinary seed/random starts use the new three-floor default.

Floors one and two retain their damage, timing and easily missed branches.
On the Lower Watch, the Husk guards the spine, a Hound watches the key loop,
and a corded side chapel hides a Ghost. A webbed opposite storeroom holds a
tonic. A cold torch, food, fresh coat, lamp and shard are offered in the entry
area before commitment. The keyed gate always appears; the seed still varies
weight module, loop reach/side and ordinary loot. Returning the clapper still
links home to the deepest landing, now a more valuable shortcut.

Deep Husk/Ghost mistakes cost **2 HP**, a deep Hound **3 HP**. Intent and
inspection text name that power. HP, wind-up timing, lunge lane, guard and
recovery are unchanged. A coat absorbs one whole hit; FOOD can heal or settle
the Hound. The core witness still wins without eating or forced attrition.
This raises the stakes of a mistake while preserving a learnable safe route.

New deep runs use rules/content/generator **m4.1**, envelope/snapshot schema 2.
Continue keeps the stored count/profile and explicit floors, including M3f's
two-floor m3.3 runs. A genuine M3f production envelope was captured from the
accepted resource pack and added as `tests/fixtures/m3f_run.json`; its original
hash survives both the current production codec and Main's Continue path.
Legacy exact-hash suites remain green. New damage/title fields are validated
before use; no stored floor is decorated, upgraded or regenerated.

Three actors maximum preserve the occupied-landing escape: the actor blocking
the destination already uses one slot, so the other two cannot occupy all
three clear neighbouring cells. Initial loot/prop reservation still applies.

## Evidence and reproduction

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m4a_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m4a_pilots.ps1
python tests/build_m4a_sheet.py
powershell -ExecutionPolicy Bypass -File tests/run_m4a_pack.ps1
powershell -ExecutionPolicy Bypass -File tests/qa/run.ps1
```

The headless sweep covers **300 three-floor seeds**, core skip/keep/return
choices and an independently replayed capability tour. Core routes span
**84-146 turns**; tours **176-225**. The BELL42 real-tap route takes **193 turns,
6/6 HP**: it picks up padding, equips it during a deep tell, feeds the Hound,
finds the Seal, returns through the lift and wins. A separate real-input branch
drops the torn coat. A fresh-process save pair closes on floor three and
continues that exact hash/count. Every inherited pilot remains in the batch.

| Validation | Result |
| --- | --- |
| Sixteen source suites | **272,671 assertions; 0 failures** |
| Actual windowed pilots | **34/34; muted** |
| Three-floor exported PCK, loaded from an empty resource directory | **334 checks; 0 failures** |
| D's unchanged default QA runner | **9/9 phases; 0 findings or script errors** |

Receipts are `build/m4a_check_results.json`, `build/m4a_pilot_results.json`,
`build/m4a_pack_test.log` and D's ignored `tests/qa/results/`.
D's generation phase covered **3,141 seed codes / 6,932 runs**, with 13,864
keep/return witnesses and 760 independently replayed routes. Its adversarial
phase covered **768 trajectories / 270,092 actions / 2,299 save round trips**.
The one budget-limited search was resumed and proved reachable. Save fuzzing,
malformed field types, the occupied-stairs reproduction, edge policies and
the separate-process reopen pair all passed. D's default adversarial cohort
is still the older one/two-floor cohort; our 300-seed deep sweep supplies the
new-profile witness coverage, not a claim of deep adversarial fuzzing.

The witness now replans a moving Hound after each action, avoids attacking a
peaceful body simply to clear a route, retains food while collecting fire,
and can resume from the current stored floor. These are planner corrections,
not privileged gameplay hooks. Separate tests deliberately miss deep attacks,
heal with food, absorb a three-point lunge with one coat, validate spent art
state, and reject malformed damage fields. Ordinary action replay still
matches canonical snapshot hashes and takes no witness damage.

## Honest read and limits

The third floor gives the clapper/food/padding decisions better stakes without
adding a combat system. It is a fuller exploring route; an expert who misses
branches should still be faster. A perfect guard player can still finish at
6/6, deliberately. More damage does not by itself prove that a human will
eat. The owner needs to judge whether the recombination earns its extra walk.

**10-15 minutes remains a phone-play target**, not a measured acceptance.
Some bot tours are shorter than the proposal's 190-turn estimate. No corridor
was padded to hide that. Longer layouts, compulsory attrition and new enemies
remain proposals for review. No M4a APK/device session, new touch-comfort or
frame-time measurement has been performed here. D can extend adversarial
coverage specifically to the new deep profile after this handoff.
