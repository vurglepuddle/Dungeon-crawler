# M5b: reading the Deep

Start with **build/m5b_shots/m5b_sheet_2x.png** (native version beside it).
The 12-panel sheet shows room entry/survey, the single belt icon and metal
chooser, all three world keys/lock plates, an illustrated card, the f4 light
pool near/far and a real block seam. Fourteen full-size frozen presentation
captures are beside it. These are explicitly authored valid snapshots, not
claims of a continuous gameplay route. **build/m5b_shots/real/** contains the
ordinary real-tap route's room map, collected-key cards/list, lock states and
dawn. Its BELL42 Deep run takes **205 turns**, finishing at **5 HP, zero wakes**.

## What changed

- Fresh interactive Abbey/Deep starts annotate keys/locks with iron, bronze or
  gold. Only a matching metal unlocks; keys remain reusable, belt-only and
  immune to drop/toss. Selected-key targeting uses the same predicate.
- The belt remains **one generic key icon plus count**. Tapping it opens the
  illustrated list even for one key. Each row gives metal and live door state;
  its card explains reuse and matching local destinations (original destination
  when away). Large parameterized runs scroll the list, keeping CLOSE in reach.
  B's 24 new paintings cover cards/list, world keys and matching-family lock plates.
- Survey follows all camera columns through the lighted forward area, including
  partial cells and wall slivers, rather than requiring a full floor sample.
  A room's visible cells need not each be walked. Seen remains dashed; walked
  remains solid. Closed obstructions stop rays. Unrevealed panel landmarks are
  suppressed in discovery **and** rendering, including old saved landmark masks.
  This is line of sight, not a room flood-fill or a 360-degree reveal.
- The carried Seal makes a radial pool with six hard gains and a 4x4 ordered
  edge. The nearest floor/walls are brightest; f4 is readable within about two
  cells and fades into black. Slate receives exposure; pale stone is capped
  to retain its highlights. Source textures are untouched. No new art/material
  is baked into the owner's overlay.
- Seeded Deep blocks choose f1-f4 wall/floor/ceiling families. The default 2x2
  uses all four; the seam falls on the existing 16-cell block boundary. The
  Winding stays f4; fixtures keep the accepted f2 kit. No geometry, creatures,
  combat, length or difficulty tuning changed.
- The Fall counter stays on floor three through the crumble/fade, then switches
  at the waking card. Claude's frame holds, moving crumble, removed pedestal
  Seal, selected-only Seal hand and painted arrows are retained. Pilot busy
  includes hotspot-layout settlement; wall-action pilots also allow two frames.

## Compatibility

Schema/profile remain **3 / m5.1**. `key_metals:true` is an optional marker for
fresh current-rule runs. Unflagged old m5.1 runs keep generic keys, exact sim
snapshots/hashes and their existing progress. m3/m4 compatibility is unchanged.
NEW GAME opts in; Continue never upgrades implicitly. The old scripted
`new_adventure SEED START` remains a historical fixture; append `metals` for
current rules, or pass `metals:true` in Sim options. Retry retains the loaded
run's key rules. Seen/walked saves remain version 1. DESIGN, CONTRACT and
ARCHITECTURE describe these seams.

View frame **(0,18,154,156)**, picture **(3,21,148,150)** and compass
**(85,294,66,44)** are unchanged. Owner/other-worker artwork, project settings,
autopilot, pointer and QA harness were not edited. Existing uncommitted art
changes remain theirs. No commits were made.

## Verification

| Cohort | Result |
| --- | --- |
| All 21 existing source suites, run once | **162,253 checks; 0 failures** |
| New empty-hand metal-key witnesses | **200 seeds; 191-207 turns; no damage/healing/wakes** |
| Broad M5b sim/render/asset assertions | **936 checks; 0 failures** |
| Final focused survey/persistence/secret follow-up, 4 seeds | **547 checks; 0 failures** |
| Current UI, wrong-metal refusal, Fall HUD, key list/card/Continue and multi-Deep belt | **189 checks; 0 failures** |
| Muted gameplay pilots | **12/12: 5 M5a + 6 selected legacy + 1 new metals** |
| Frozen visual gallery | **14/14 captures; 12-panel sheet** |
| D's bounded unmodified QA runner | **18/18 phases passed; zero findings/script errors** |
| Required source and isolated exported paintings | **507 loaded** |
| Isolated PCK: legacy tour, new metal Deep and codec | **844 checks; 0 failures** |

Focused rows overlap the broad cohorts and are not added into an inflated
aggregate. The 21-suite run used 32 seeds for its parameterized legacy/Deep
cohorts; fixed historical loops kept their own counts. The separate new metal
sweep used 200 seeds. D ran Seeds=64, DeepSeeds=128, adversarial samples 8/8,
difficulty 16 and DeepEdgeSeeds=4. Its extra fixed edge codes make the Deep
generation phase **197 seeds / 591 witnesses**, with 219 replayed witnesses.
Deep adversarial coverage included **64 trajectories, 277 sampled states and
221 save round trips**, no findings. D's harness still constructs generic
M5a profiles; the metal rule's empty-hand and negative/round-trip proofs are
ours. A larger metal-aware adversarial promotion is still D's follow-up.

**build/m5b_verification.json** records the receipts. All windowed runs used
pilots and remained muted. Saves/profiles use isolated user://tests paths.
No owner profile was unlocked/reset by this work.

## Reproduce

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m5b_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m5b_pilots.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m5b_gallery.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m5a_pack.ps1
```

Use -OnlyNew on the first two runners for focused work. The new check runner
limits each new suite to nine minutes; each gameplay pilot has a six-minute
limit. D's bounded invocation is recorded in the verification JSON. Normal
play is unchanged: launch the project, NEW GAME, or Continue an existing run.

## Read on the result / unverified

The four material moods give the maze useful bearings while keeping its loops
confusing. The Seal now feels like something that helps you read the dark,
and explicit metal/door state removes the mystery of two keys opening three
doors. This is a clarity pass, not a claim that the combat or maze variety is
finished. No phone acceptance or mobile frame-time profiling was performed;
the owner should judge light exposure, dashed-room readability and the key
list on the Pixel before further tuning. No longer-floor or combat changes
were added.
