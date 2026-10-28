# M3b: the period interface

Start with `build/m3b_shots/m3b_sheet_2x.png`. It shows title, corridor, room,
Porter, clapper card, map, a real hit and selected PLACE. The individual PNGs
are beside it. The gallery is real input, not fabricated scene states.

Nothing committed. The owner's Android save fix, VETKA import/defaults,
project/export settings, autopilot, app icon and launcher framing are unchanged.
The three reference screenshots were used for discussion only and were not
saved to the repository. The material and arrangement are original.

Late parallel art/music/FX/manual work appeared after this validation. Those
files were left untouched and are outside these results. A subsequent editor
import also reordered the existing Autopilot section in project.godot and
added a scene UID; those late metadata edits were left intact. No setting
values, save implementation or font/icon files were changed by M3b.

## The screen

| Logical y | Height | Use |
| --- | --- | --- |
| 0-17 | 18 | Seed left; floor/status x98-119; MAP x121-152; x54-96 empty |
| 18-173 | 156 | Bronze frame around a 148 x 150 dungeon picture at (3,21) |
| 174-207 | 34 | Two event lines, native VETKA 16 |
| 208-245 | 38 | Framed Finder, HP bar, hand/coat and belt, numeric health |
| 246-267 | 22 | Eight boxless pockets, 19px pitch, native 16px icons |
| 268-291 | 24 | Three context verbs |
| 292-339 | 48 | Six 24 x 22 arrow tiles and a half-dial compass |
| 340-341 | 2 | Footer |

The picture is 50% taller than the old 100px drawing band. The slightly thinner
width accommodates a three-pixel material frame. Every touch target is at
least 18 x 18. Bent turns and straight steps remain distinct, and the compass
shows the facing without taking space in the portrait row. Tapping it opens
the map for free. NEW is removed from the bar; `new_seed` remains a pilot
alias to the seed control.

One painted dark bronze material supplies frame, panels and tiles. The centre
tiles at native resolution rather than stretching its grain into large blocks.
The pack is one dark surface, with small empty-position ticks and selection
corners. Inventory art is cropped to the full opaque bounds, fitted to 14 x 16
inside a 16 x 16 canvas, and explicitly centred in each control. Button's
left-aligned icon layout is no longer involved. The knife is readily visible.

No labels, boxes or pointer lines sit over the dungeon. Default usable objects
have a small pulsing gold fleck. Selected-item targets have small coloured
corner cues. Transparent hit areas share the painted object's projection and
occlusion, with small objects above larger bodies in input order. An underfoot
lift shows its platform, keeping the doorway ahead visible and separately
tappable. An entrance behind the Finder no longer appears upright at their feet.

Cards occupy y208-339. During inspection, verbs dock at y179 directly below
the picture; the event array is preserved and restored on closing. This is
essential: PLACE/RETURN/RING remains visible while its target glints. Belt keys
also mark matching locks, and the selected Seal marks the existing way home;
the later Seal reveal mechanic has not been added.

Turning and routine footsteps no longer replace the event lines. A failed
save sets a persistent ! in the floor/status control. Tapping it opens a small
status/retry panel; subsequent events remain readable. An injected failure
test covers a new pickup event during failure and a successful retry.

SOUND still controls SFX only. Music is not connected by this changeset; DESIGN/CONTRACT require
separate MUSIC and SFX controls when it arrives. The launcher art was retained.

## The kept clapper

RING costs one beat, once per floor, from pack or hand. Living Husks at forward
depth 1-3 in the facing 90-degree cone hear it when walls/closed gates do not
block the integer sight ray. Creatures do not block the sound. Listeners lose
their pending intent and enter recovery, without attacking or rearming on
that ringing beat. There is one clear action to counter or pass. Nonlisteners
still take their normal phase; ringing is not general invulnerability.

The card explains the charge, shows spent status and disables a spent RING.
The action has its own synthesized tone, event text and lowered/muted recovery
presentation. An empty call costs no turn or charge. Pack/equip, floor travel,
save/load and retrying cannot recharge a floor. A used clapper can still be
returned, permanently trading the tool for the lift. The old guard/counter
route remains available; neither gate nor objective requires ringing.

New runs use rules/content m3.2 and the unchanged m3.1 generator. Optional
floor.bell_rung is stored in schema 2. Actual M2 and M3a snapshots still load
without changing their exact hashes. The first RING in an M3a run upgrades
rules/content while retaining its saved floors and generator version. A
normal legacy M3a keep run still reaches its original 74-turn ending hash.

## Run and review

```powershell
& E:/SD/GODOT/Godot.exe --path .
```

New BELL42 shows the complete current run. Continue keeps the old run intact;
M2 saves do not acquire a retroactive Porter. The new UI applies to them too.

```powershell
New-Item -ItemType Directory -Force build/m3b_shots | Out-Null
& E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m3b_gallery.txt --out=E:/SD/GODOT/Dungeon-crawler/build/m3b_shots --save-path=user://tests/m3b_gallery.json --timeout=90
python tests/build_m3b_sheet.py
```

The gallery deliberately waits through one blow, then completes restoration
and the lift return: 66 turns, 5/6 HP. The other complete pilots remain safe.
`m3b_ring.txt` keeps the tool, rings a raised Husk and finishes at 74 turns,
6/6 HP. `m3_return.txt` and `m3_keep.txt` retain 66 and 74 turns at 6/6 HP.
Their existing builder regenerates hashes for current rules; named positions
come from the scene, including the moved/docked controls.

Both close/reopen pairs were run as separate windowed processes:

- `m3_save_a.txt`, then `m3_save_b.txt`, sharing an isolated save path: exact
  restoration state at turn 29, revision 36.
- `m3b_ring_save_a.txt`, then `m3b_ring_save_b.txt`, sharing another isolated
  save path: floor 2, turn 37, revision 43, spent charge, 6 HP and the Husk's
  recovery state. Reopening does not recharge or advance the creature.

Use the same `--save-path=user://tests/NAME.json` for the two halves of each
pair, and different paths between pairs. `tests/build_m3b_pilots.gd` rebuilds
the gallery/ring/pair pilots. Playback uses ordinary named taps; setup only
starts the seed, and assertions inspect public state.

## Verification

**88,441 checks, zero failures across five headless suites:**

| Suite | Checks |
| --- | ---: |
| tests/test_m3.gd | 58,957 |
| tests/test_m3b_ring.gd | 28,888 |
| tests/test_m3_lift.gd | 133 |
| tests/test_ui_layout.gd | 146 |
| tests/test_m3_view.gd | 317 |

Run each with `E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/NAME.gd`.
The main suite retains M2 rules/storage, 300 ordinary stairs witnesses and
300 repaired-lift witnesses with independent replay, greedy probes and other
floor counts. The new ring suite adds 300 damage-free ordinary-action/replay
routes, sight/range/wall exclusion, intent cancellation, counter timing,
ownership, charge persistence, empty-call purity and exact legacy compatibility.
Counts include individual command/assertion checks, not that many scenarios.

The updated scene checks cover the camera gap, all native icon bounds/centres,
boxless pockets, all card layouts, minimum targets, save-failure log behavior,
quiet projected controls, colour cues and the strip remaining above the card.
Glint timing cannot mutate the simulation. The dungeon's geometry/loot is
unchanged this turn: the prior 300-seed ranges remain 65-95 stairs turns and
60-85 restored turns.

Nine windowed pilots passed: return, keep, restoration close/reopen,
gallery, RING, spent-charge close/reopen and the four-facing room pilot. Screenshots were inspected at
native pixel scale and assembled with nearest scaling. The known Windows
certificate-store startup diagnostic remains. The earlier intermittent
ObjectDB shutdown warning appeared in one preview, but not the final nine
pilots; its engine cause remains unresolved. Save/reopen hashes matched.

## Art and remaining acceptance

`art_src/m3b/chrome_source.png` is the preserved painting generated with the
built-in imagegen tool. The exact prompt is in `prompts.json`.
`build_chrome.py` reduces it to the existing shared 32-entry palette, quietens
dark centre colours within that palette, and produces native `chrome_32.png`
plus `chrome_contact_8x.png`. The game copy is `assets/art/chrome_32.png`.
Python/Pillow is offline authoring only. No dependency was added to the game.
The existing wall, Finder, Husk and Porter paintings were kept.

The interface now gives the dungeon a clear stage, and the kept item has an
explicit tool action. Its best balance still needs more encounters: one Husk
per floor does not demonstrate its crowd value. The new cue subtlety, card
workflow and smaller pad need the owner's next phone session, not just bots.

Unverified: M3b APK export/install, Pixel 9a cutout fit and touch comfort,
Android save/pause durability after the owner's fix, phone performance and
audio balance. The 90f8e89 save implementation and zero-AA/hinting/subpixel
font settings were preserved, not device-recertified here. This changeset
connects no music and creates no new launcher icon.

The next turn still owns Hound, Ghost, FIRE/EDGE/FOOD/GLOW fixtures, TOSS,
the Seal's return reveal and the hinted secret. They were intentionally not
implemented during the interface round.
