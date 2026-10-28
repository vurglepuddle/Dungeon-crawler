# M3e: choose another use

Start with `build/m3e_shots/m3e_sheet_2x.png`, then play the left entrance
branch on BELL42. The sheet contains twenty actual muted windowed captures,
including burning silk, both Hound states, the toss preview, a fading Ghost,
the return mark/cache, held reeds/Seal and an occupied stair's safe arrival.
The native sheet and individual captures are beside it.

Nothing committed. Project/export settings, Pointer, autopilot, launcher,
BRIEF/COLLAB_LOG, D's harness/report and B/C's authored inputs are unchanged.
SaveStore's envelope type guards changed; its Android relative user://
staging/rename algorithm did not. No new painting was required.

## What is playable

The banked brazier is renewable. LIGHT a reed torch, then BURN the web into
the kennel. The reeds stay lit and supply FIRE/GLOW without a fuel clock.
The web opens permanently before its two brief flame frames play.

An Ash Hound crouches before a fixed two-cell lunge. From adjacency, a single
backstep is still in danger; strafing escapes. Guard/counter remains safe.
FEED works directly ahead. At distance two, selected FOOD offers TOSS:
open its free lane preview and explicitly release. The offering is consumed,
the intent cancels, and the Hound becomes peaceful and moves to a clear perch.
The creature stays solid. Its kennel offers a coat.

CUT the cord grate with an EDGE to enter the other branch. A lamp is offered
outside. Owned GLOW dispels its Wick Ghost without consuming the light;
ordinary guard/counter combat also works. Its recoil fades after the saved
removal. A tonic waits within. Both branches fit a one-floor run; with two or
more floors, the kennel is on one and the Ghost branch on two.

TOSS reaches up to two forward cells and stops at blockers. Ordinary items
land on recoverable floor. HEAVY deals one impact damage, FOOD feeds a Hound,
FIRE opens a web, and GLOW dispels a Ghost. Thrown reeds/lamps then remain on
the floor. Keys, Seal and returned property cannot be thrown. Opening or
cancelling a preview spends nothing. A throw costs one beat.

One scored wall near the entrance has a free inspection hint: dawn wakes the
scar; an EDGE lifts it. The Seal reveals it automatically in forward sight
on the walk home. A carried GLOW can also reveal it early. CUT opens a dark
inset and exposes its concealed tonic. The sigil overlays the accepted
painted masonry rather than substituting the older blocky stone. This is a
cache, not a hidden mandatory route or a new room.

The web and cord guard optional rewards. The main Seal route remains viable
after food is eaten, lights are abandoned or the clapper is returned. This
keeps the new lessons available without making every run a tag checklist.

B's native right-hand kit is wired at view-local (100,94), complete 48x56
frames: equipment at rest/use, explicitly used lamp/reeds, and the Seal held
up automatically after pickup. Pulse, flame, recoil, glints and hand motion
are presentation only. Completed capability uses clear selection so normal
inspection/pickup cues return. Map glyphs include the new observed fixtures.

## Both QA findings

**QA-01:** normal stairs validate destination occupancy before any mutation.
The codec rejects living actor/player overlap, actor/actor overlap and living
occupancy inside a closed blocker. Merely rejecting the return could strand
someone below a frozen creature, so a blocked stair exposes **SIDLE** (API
`squeeze`). It arrives on a clear adjacent landing cell without moving the
waiting creature or adding an arrival enemy phase. Generated landings have
more clear side spaces than possible living creatures on their floor; the
300-seed sweep checks this bound. The unchanged 61-command reproduction's
normal arrival rejects atomically; the new real-UI pilot then takes SIDLE.
A complete ordinary recovery from that reached state also wins.

**QA-02:** field types are checked before comparisons, indexing, dictionary
lookups and typed assignment. Save headers/checksums also receive type guards.
Bad restore still refuses atomically. No script exception is treated as a
successful refusal. Current runs use rules/content/generator **m3.3**, with
snapshot/envelope schema **2**. Stored m2.1/m3.1/m3.2 floors retain their exact
cohorts and hashes; their captured ending regressions still pass.

## Reproduce

Run the normal project in Godot 4.3. NEW RUN uses current content; Continue
keeps an older run's original content. Use a fresh BELL42 to see the branches.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3e_checks.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/qa/run.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3e_pilots.ps1
python tests/build_m3e_sheet.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3e_pack.ps1
```

Execution-policy overrides affect only these processes. All windowed launches
use a pilot, its default master mute, isolated user://tests slots and no
--with-sound flag. No code unmutes the bus. The runner preserves previous
milestone captures, writing new ones into m3e_shots/m3e_regression_shots.
Regenerate this round's five pilots with Godot's headless `-s
res://tests/build_m3e_pilots.gd`; inherited builders remain beside it.

## Verification

**13 headless suites: 173,628 checks, zero failures.** Eleven inherited
suites contribute 121,573, the new mechanics/replay suite 51,737, and the new
UI-versus-pure-sim route comparison 318. The mechanics suite replays **300
two-floor capability tours** and checks alternate one/three/four-floor runs,
food versus healing, lunge dodges/guard, thrown FIRE/GLOW recovery, malformed
lanes, exact pacification saves, secrets and stair recovery. The UI comparison
also verifies free preview/cancel, touch sizes, committed-effect ordering and
automatic held Seal. Latest per-suite receipts/logs are in build/.

**25 muted windowed pilots pass:** five new tour/dodge/save-A/save-B/SIDLE
pilots plus all twenty inherited regressions. The lit-torch/peaceful-Hound
pair uses fresh processes and exact hashes. Existing restoration, RING,
survey, mid-fade close/reopen and audio-preference pairs remain green.

**D's unchanged default runner passes all nine phases**, including its full
3,141-code generation audit: 6,932 runs, 11,698 floors, 13,864 successful
keep/return witnesses and 760 independent route replays. Its updated-content
adversarial audit records 768 trajectories, 268,530 API calls, 2,292 save
round trips and **zero findings**. Three initial search-budget exhaustions
all recover in the extension (25, 121 and 222 expanded states); zero samples
remain unresolved. Nine actual deaths are kept separate from softlocks.
The save matrix checks **677 corrupted field types** with zero accepted
corruptions and zero script errors, plus truncations/transaction recovery.
The fresh-process pair reads 401 checkpoints and compares 4,877 continuation
commands. These are finite audits, not an exhaustive all-state proof.

**178 packaged-resource checks also pass.** The disposable staging copy
includes held items and current runtime inputs while excluding C's pending
props/screens/material proposals. From an empty resource directory, the
exported PCK loads its hands and completes the full capability tour with
saves. Total own-suite plus pack checks: **173,806**. This is a resource-pack
test, not an APK or Android acceptance test.

## Length, pressure and remaining acceptance

BELL42: ordinary restoration **66 turns**, keep/RING **74**, capability tour
**118**, greedy collection **190**, all at 6/6 HP. The real-tap screenshot
tour takes **122**, adding four actual kennel photography steps. Across 300
new tour seeds: **114-144 turns**. D's wider two-floor ordinary routes retain
return **60-86** and keep **68-96**. These are bot choices, not optimal paths
or measured human minutes.

BELL42 offers **11 visible ordinary pickups versus 8 free entry slots** on
floor one, plus **one concealed reward** offered only after opening its cache.
Floor two offers **6**. The greedy bot enters it with **0 free slots** and
leaves **5** offerings; belt keys/Seal are excluded from this measurement.
The capability tour deliberately carries less than the greedy collector.

No APK/device acceptance was performed here. Phone touch comfort, first-time
branch discovery, sustained rendering performance and platform lifecycle
behaviour need the next human session. The host's known root-certificate
startup diagnostic remains; it is separate from script failures. Test music
was muted, so this round makes no new listening judgment.

Deferred: C's decorative room props and blocking pillar, logotype/menu life,
and the owner's pending floor/ceiling/parchment repaint. Their source files
are left alone. The previous accepted materials remain wired.

My read: FOOD now buys peace instead of merely restoring a number, and the
Seal makes the return trip answer an earlier clue. These are better reasons
to carry something. The optional entrance branches can still be overlooked;
the next phone pass should judge their invitation and the two-cell tell
before more content is added. This is a stronger small run, not yet proof of
third-run longevity.
