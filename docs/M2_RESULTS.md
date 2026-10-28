# M2: down, back, and kept between sessions

The complete small run is implemented. Start with BELL42, explore the side
room for its key, descend, take the Dawn Seal and bring it home. New runs
default to two floors; floor count is a parameter, tested at one, three and
four as well. No project settings, export presets, autopilot, BRIEF or
COLLAB_LOG edits. Nothing committed by Codex.

## What exists

- Two persistent 17 x 17 floors: rooms, corridors, a useful middle loop,
  body/item pressure plate, far-side latch, keyed gate and approaching Husk.
- The Finder presses a plate. Stepping off closes its unlatched gate. DROP
  works at the Finder's feet, PLACE ahead, and a lasting HEAVY weight bridges
  the gap to the gate. The accessible far latch makes the way home permanent.
- Eight pockets, item cards with provenance, two equipment slots, protected
  key/Seal belt, healing and persistent spent armour. Eleven definitions.
  HEAVY counters do 2 during recovery; the Husk's braced arm limits impatient
  strikes to 1. Starter equipment still has a damage-free solution.
- Seen-cell automap with a large facing marker; title, Continue, new seed,
  death/retry and win screens. Cards, map, looking and inspection are free.
- Save before animation after every accepted action, including rotation;
  save again on pause/close. Versioned user://run.json, validated .tmp/.bak
  recovery, complete floor/item/intent state and selected-item restoration.
- Seven locally synthesised PCM SFX: step, bump, hit, guard, bell, gate,
  pickup. No samples or music. A real hit adds a red view border, a short
  view knock and hurt portrait treatment. Seed entry has padded, opaque
  content. Loot piles have button pagination; no required scrolling gesture.
- Existing painted art retained, code item/stair/Seal icons added, cooler
  tint below. No new generated paintings or converter changes were needed.

## Run and review

From the repository root:

```powershell
& E:/SD/GODOT/Godot.exe --path .
```

NEW RUN opens a seed dialog; START uses that seed, RANDOM chooses another.
The same controls are available during play through NEW. MAP is free. Select
a pocket to inspect/use an item; CLOSE clears selection. Marked world targets
remain tappable while the item card is open. Equipment/belt icons open cards.
DROP/use/equip can free a full pocket; failed pickup never destroys loot.

Normal play saves to user://run.json. Pilots automatically default to an
isolated user://tests/pilot.json; explicit --save-path overrides that choice.
The following paths keep the full run and resume pair independent:

```powershell
New-Item -ItemType Directory -Path build/m2_shots -Force | Out-Null
New-Item -ItemType File -Path build/.gdignore -Force | Out-Null
$shots = Join-Path (Get-Location) 'build/m2_shots'
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m2_full_run.txt "--out=$shots" --save-path=user://m2_full.json --timeout=90
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m2_save_a.txt "--out=$shots" --save-path=user://m2_resume.json --timeout=60
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m2_save_b.txt "--out=$shots" --save-path=user://m2_resume.json --timeout=30
```

Run A and B as separate processes, in that order. A really closes through
WM_CLOSE_REQUEST. B starts at the title and taps Continue. It checks floor 2,
turn 27, revision 33, 6 health, carried/selected f2_stone, and the exact full
simulation hash (including floor one). Panels reopen closed, selection intact.

Additional pilots: m2_feedback.txt covers equipment, spent coat, a real hit,
healing, map and padded seed dialog; m2_death.txt deliberately ignores tells
and retries through the death screen. Use an isolated save path as above.
tests/build_m2_pilots.gd regenerates these Codex-owned fixtures from ordinary
commands. There are no movement/loot/gate debug shortcuts in their playback.
M1 pilots remain historical; their tiny-floor routes are superseded.

## Evidence

```powershell
& E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/test_m2.gd
& E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/test_ui_layout.gd
```

**32,705 headless rule/storage/generation checks, zero failures.** This includes
300 complete down-and-back witnesses, 64 greedy exploration runs and 12 runs
at alternate floor counts. The 300 seeds produced 294 distinct pairs of raw
floor layouts, with direct witness lengths of 77–81 committed turns. Counts
include per-command acceptance/replay checks, not that many distinct scenarios.

Checks cover gate cuts, useful loops, key-before-lock placement, connected
geometry, deterministic replay, body pressure, DROP, recovering a latched
weight, substituting a different HEAVY item, guard/recovery, approach after a
dodge, braced damage, armour, death, inventory/belt ownership, invalid/stale
purity, JSON roundtrip, malformed/versioned saves, staging/backup recovery,
new-run backup cohorts and terminal backup Continue rejection.

**65 real-scene headless layout checks, zero failures:** native touch targets,
named coordinates, every item card inside its screen bands (including the
bone's WIELD/EAT choices), seed padding, paginated loot bounds and no gameplay
mutation from cards/panels. Layout fixtures are distinct from gameplay pilots.
The migrated M1 runner executes focused current-rule regressions; the original
13,469-check M1 result belongs to the earlier milestone. Its current migrated
runner passes 128 checks. Seven synthesised streams were also checked for
valid 22,050 Hz, 16-bit PCM data. For quick changes,
test_m2.gd also accepts user argument --focused to omit the broad sweep.

**Windowed real-input pilots passed:** full run, save A/reopen B, feedback and
death/retry. BELL42 returns with the Seal at **6/6 health, turn 77, revision 91**.
The save pair verifies an actual process boundary and nonempty selected pack.
Snapshots inspected include gameplay, lower floor, map, hurt feedback, coat
card, padded seed dialog and ending. Screenshots/logs are under build/ and
intentionally untracked. The game remains independent of Python.

For reliable automated Windows exit codes, use Start-Process -Wait -PassThru
and inspect ExitCode; plain invocation of the GUI executable can return early.
The known Godot root-certificate-store diagnostic still prints at startup in
this environment. It is separate from the passing game/script checks; no
network or external service is used by the game.

## Pack pressure

Across all 64 greedy seeds, these values were identical:

| Policy / floor | Ordinary offerings | Free pockets on entry | Free on exit | Original offerings left |
| --- | --- | --- | --- | --- |
| Minimal witness / either | 10 | 8 | 8 | 10 |
| Greedy / floor 1 | 10 | 8 | 0 | 1 |
| Greedy / floor 2 | 10 | 0 | 0 | 9 |

The minimal route leaves its weight behind after latching. Greedy recovers
it, equips a club/coat and fills pockets; before the next essential weight it
can deliberately drop an ordinary carried item. Keys/Seal never need a pocket.
Offerings are unique original ordinary items, excluding belt essentials;
recovering a dropped stone is not another offering. Imported dropped items
are excluded from the next floor's original-offering count.
BELL42 takes 131 committed turns under that greedy policy, versus 77 on the
minimal witness. These are bot turn counts, not timed human play.

This probe establishes real capacity pressure. It does not establish optimal
loot values: the bot is greedy, retains duplicates and does not model human
preferences. Player choices and the future EDGE/GLOW modules still need tuning.

## Honest view and remaining acceptance

Judging from the real-tap runs and screenshots, there is now a coherent short
outing: side-room exploration, equipment choices, a readable creature, a goal
below and a reliable way home. The original atmosphere survives the larger
rooms. Body pressure and DROP resolve the awkward M1 interaction directly.

I would still expect repetition after a few runs. Both floors share their
gate/Husk vocabulary, some capabilities await M3, and the Porter/lift payoff
is not implemented yet. The direct 77-turn route is short; fifteen-minute
human play and third-run appeal are not proven by a fast pilot. Do not pad
the map to manufacture duration. Restoration and a few different encounters
are the next meaningful expansion, after human review of this loop.

Unverified: M2 Android export/install, phone performance/audio/keyboard/touch
comfort, Android backgrounding/force-kill durability, physical legibility and
human enjoyment/duration. The earlier M1 APK build does not certify M2.
Desktop orderly close/reopen is verified; arbitrary OS/hardware interruption
and simultaneous loss of every valid save copy are outside that evidence.
Art remains a prototype in places: one Husk pose, cooler-tinted shared walls,
code stair/Seal icons and a portrait overlay rather than new painted states.
