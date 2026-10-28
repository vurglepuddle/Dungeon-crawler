# M1: the first minute

28 October 2026. Implemented and exercised locally in Godot 4.3. No commit
made by Codex. Claude's project settings, autopilot, brief, proposal and
collaboration log were not edited.
Godot generated import metadata beside the copied art and the existing font;
the font itself is unchanged. Generated source-art import sidecars were moved
to an ignored local backup under build after adding the source exclusion.

## What to try

Run `E:/SD/GODOT/Godot.exe --path .` from this repository. It opens directly
into seed **BELL42**. The seed at the top opens a seed-entry panel; NEW chooses
a fresh code. Bent gold arrows turn freely. Straight green arrows step,
including sideways. The portrait explains the arrow distinction.

Take the stone ahead, step forward, select its pack icon and touch PLACE on
the plate. The gate latches open. Beyond it, the Husk raises an arm: GUARD,
then HIT during recovery; repeat. Walk past it, turn right at the dogleg,
then left at its end. The cyan doorway offers LEAVE. RETRY replays that seed.

The generated floor is 9 x 11 with an entry room, mandatory gate cut, one
combat corridor, dogleg and alcoves. This is a construction prototype, not
the full two-floor run. It uses the painted 64/40 px Husk, code 24 px Husk,
stone wall and Finder portrait from the spike. No sources were overwritten.
`art_src/.gdignore` keeps authoring images out of Godot import/export; game
copies live under assets/art. Four pack slots and one HEAVY item are active.
Equipment boxes are placeholders. No saves or audio exist in M1.

The scene uses the agreed 154 x 342 bands and VETKA 16 px. Valid selected-item
targets receive an explicit PLACE marker. The unselected monster is tappable
for inspection without a button obscuring its face. Item and plate markers
sit above their small floor artwork. Rules, generation and witness are pure
RefCounted objects; the 2D view uses grid rays and cached wall texture columns,
with depth occlusion and nearest sampling. No 3D scene or game dependency.

## Verification

```powershell
& E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/test_m1.gd
```

**13,469 checks; zero failures; 512 complete seed witnesses.** Counts include
individual accepted witness commands and their independent replay, not 13,469
different hand-authored scenarios. Every witness picks up the real item,
places it, opens the real gate, guards/counters the Husk and exits without
damage. Replaying its commands produces an identical full snapshot.

Other checks cover connected geometry, gate-cut prerequisites, generation
determinism, detached snapshots/events/targets, invalid and stale-command
purity, free turns during a pending attack, exact threatened cells, retreat,
recovery, cancelling a killed source, damage/death, terminal rejection,
retrieving a weight from a permanently latched gate, and native-font widths.
The sweep produced **16 distinct raw layouts**; every witness used 20 commands.
This limited variety is reported deliberately, not sold as broad replayability.

The **real windowed pilots both passed** at 462 x 1026, through the existing
autopilot and actual named Button targets. Windowed rendering was available;
no sandbox restriction prevented it.

```powershell
New-Item -ItemType Directory -Path build/m1_shots -Force | Out-Null
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m1_walk.txt --out=E:/SD/GODOT/Dungeon-crawler/build/m1_shots --timeout=45
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m1_lifecycle.txt --out=E:/SD/GODOT/Dungeon-crawler/build/m1_shots --timeout=45
```

- Walk pilot: **16 public-state assertions**, nine screenshots, win at 6/6
  health, turn 16, revision 20. It deliberately looks both ways during a
  wind-up, asserting unchanged beat and health. Placement uses the view's
  named hot_plate marker, not a debug action.
- Lifecycle pilot: **12 public-state assertions**, three screenshots; seed
  panel reports busy=1, cancel leaves revision unchanged, NEW makes a fresh
  run, ignoring tells causes death, and RETRY restores the original seed,
  health, empty pack and closed gate at turn/revision zero.
- Inspected the entry, marked plate, wind-up, recovery, win and seed-panel
  screenshots. Files are under `build/m1_shots/`, intentionally ignored by Git.
  The autopilot saves 3x nearest images. Local headless/lifecycle logs are in
  `build/m1_headless.log`, `build/m1_walk.log` and `build/m1_lifecycle.log`.

For automated Windows exit-code checks, launch the GUI Godot executable with
`Start-Process -Wait -PassThru` and read the returned process's `ExitCode`;
plain `& Godot.exe` can return before the GUI process sets `$LASTEXITCODE`.
The final headless, walk and lifecycle processes returned 0. An intentional failing
pilot assertion returned 1, even with a trailing pilot `quit`; scene assertions
defer their nonzero quit to avoid that same-frame overwrite.

Godot prints `Failed to read the root certificate store` at startup in this
environment, including before a scene loads. The game is offline and the
completed runs have no script/rendering errors. That engine diagnostic is
not claimed fixed. An initial wall-image format mismatch and a pilot empty
string parsing failure were corrected before the successful runs above.

## Honest assessment and remaining acceptance

Judging from the real-input pilot and its screenshots, the corridor has
atmosphere; seeing the painted Husk at this scale pays off.
Touching PLACE and seeing the gate open is a satisfying, readable small beat.
Combat teaches a predictable rhythm, and free looking feels appropriate.

It is not yet a compelling repeat run. The stone has one use, the route is
short and mostly forced, and the Husk repeats the same guard/hit answer.
That is enough to put a first minute in the owner's hands, not enough to
claim the whole design is fun. The next useful human evidence is whether
the controls and tells are understood without this walkthrough. Restoration
and multipurpose loot are still what should turn the promising wrapper into
Undercroft's own game.

Remaining rough edges: one monster pose is tinted/lowered in recovery rather
than fully redrawn; the near/far style transition is visible; masonry is still
busy; the exit is a code-drawn cyan panel; no map, sound, equipment rules or
larger inventory choices. The fixed intro and teaching messages are not a
tutorial campaign. New seeds vary geometry within a small family.

**Unverified:** Android export/install, device performance, phone touch and
keyboard comfort, OS interruption/resume, physical legibility and human fun.
No APK or phone run was attempted. M1 intentionally cannot preserve a run
through closing the app. The agreed M2 persistence/device gates remain open.
