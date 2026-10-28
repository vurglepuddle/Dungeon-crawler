# M3f: the owner's phone pass

Start with `build/m3f_shots/m3f_sheet_2x.png`. Its 24 panels include the ten
phone corrections, the new materials/props and clearly labelled historical
M3d comparisons. Individual native-game captures and the native sheet are
beside it. The before frames use BELL42; current owner examples use B3VJ5K,
so these are material/affordance comparisons, not identical camera replays.

No commit. Project/export settings, autopilot, Pointer, launcher, BRIEF,
COLLAB_LOG, D's harness/report and B/C's authored assets are untouched.
Concurrent changes to ENV_ART and owner-vine authoring files are their work.
The Android relative user:// save replacement remains unchanged.

## The ten phone findings

1. **Forward travel.** A forward step into the architectural face uses the
   stairs, working lift or exit. The landing remains walkable; entering it is
   a step, then forwarding into its face travels in one beat. Directly faced,
   underfoot and actual-mouth stairs retain their verb, including while an
   unrelated item is selected. Strafe/back never accidentally change floors.
   A blocked landing still refuses normal arrival and offers SIDLE. Without
   the Seal, the exit repeats the objective without a beat or confirmation.
2. **Equipment.** Equipped cards offer UNEQUIP into a free pocket and DROP
   directly onto the Finder's cell. Full pockets disable UNEQUIP, while DROP
   still works. Dropped possessions retain identity and can be recovered.
3. **Targets.** Four two-pixel corner brackets, six-pixel arms, a dark outline
   and a breathing brighter item tint replace the nearly invisible corners.
   Selected sparkles repeat every 900ms; ordinary glints keep their quieter
   staggered cadence. Travel arches have a small persistent keystone glint.
   Cues/hit targets follow the arch aperture, not its entire masonry tile.
4. **Keys.** The belt shows x2/x3. Multiple keys open a named list; each card
   names its floor gate and whether that gate is already open.
5. **False doors.** Decorative arches/doors use the bricked/rubble and boarded
   variants. Their selection excludes the full adjacent/diagonal ring around
   real thresholds and attached architecture faces. Open-looking decorative
   arches are no longer selected. B3VJ5K's floor-one gate has its own capture.
6. **The upper chrome.** C's message_slate, pack_leather, belt_loops and vial
   layers draw at their supplied native rectangles. Loose centred 16px icons
   retain the 19px pitch. Empty pockets have no dashes or boxes. Warm bronze
   frames return above the controls; the lower control ground stays dark.
7. **Readable travel architecture.** B's v3 marked steps and v2 shut dead cage
   replace the earlier faces. Forwarding into a dead lift says it is dead and
   its bell has no voice. Touching it points to the Porter, dismissing an
   unrelated open card so the hint is visible. Working lift stays open/lit.
8. **Clear spawn cells.** A final generator pass reserves every fixture,
   initial creature cell, landing and Seal site. Conflicting ordinary/hidden
   loot moves to nearest free floor; the Seal occupies its own pedestal.
   Props also avoid these cells and initial loot. Moving creatures may cross
   items later; decoration yields to visiting actors and dropped possessions.
   Loot beneath a pacified Hound draws beside its body and keeps its item tap.
9. **Head-on lever.** B's dedicated front hardware appears when facing its
   fixed wall; oblique views keep the side art. From its own cell, PULL and
   tapping work. The down handle remains after the latch is thrown.
10. **One health bar.** Only C's vertical glass vial remains, filled bottom-up
    by cropping the liquid, plus HP text. The portrait strip is removed.
    Hurt border, tint and portrait shudder remain independent feedback. Any
    fixed teal edge painted into the portrait is artwork, not another gauge.

## Art and deliberate differences from the mock-up

The calmer planes use C's exact world-cell hash and ordered weight tables:
seven floor variants on floor one, eleven below; puddles at 3% versus 48%.
The shared darker vault uses its matching per-cell plain/root/drip weights.
No procedural speckle is added. The surface cache includes seed/material
revision, so facing changes do not move puddles or reuse another seed's floor.

The torn map leaf uses 8/12/8/12 margins and real transparent edges over the
dungeon. Existing ink, dashes, frontier marks and saved survey stay intact.
C's measured verb stamps sit beside full VETKA words, including compact
siblings on long verbs; no text is reduced. The title has the painted logo;
all four story plates use the supplied two/three-frame timings and hold/loop
rules, without adding a delay or consuming any simulation time.

Sparse room props are decorative. Pillars are **pilasters on existing solid
masonry recesses**: the whole cell already blocks movement and sight. This
wires the painted pillar without introducing a new route cut, hidden item,
or apparently solid object on walkable floor. They remain painted up close.

The upper band's native material coordinates match the offer. Equipment
touch targets remain 24x32 at x43/71. UNEQUIP needs an 86px card button rather
than a 42px pitch so its full word and stamp fit. Cards/menus use a quiet
full-size slate instead of stretching the 34px message slab into long scars.
The optional UI candle/chain/brass plaque are not added over readable space;
the supplied view/controls already have their intended ornaments. The owner's
requested dark lower background is retained, rather than copying the mock-up's
brown lower housing.

The vine hook is one mouse-ignoring layer above chrome and below modals.
Drop an approved native transparent 154x342 PNG at
`assets/art/ui_offer/owner_overlay.png`; source and packaged resource lookup
are supported. Nothing loads from the unfinished owner-vines or v4 offers.
The staged exporter includes this canonical PNG if later supplied.

Pixel budget is unchanged: top 18; framed view 156 (148x150 picture); message
34; portrait/equipment/belt 38; pack 22; verbs 24; pad/compass 48; footer 2.
Total 342. The camera gap stays x53-96. Movement tiles remain 24x22; every
interactive target is at least 18x18. The six tiles and compass geometry stay.

## Reproduce and evidence

Use `E:/SD/GODOT/Godot.exe --path .` for ordinary play; choose B3VJ5K to compare
the owner's reported seed. Automated windowed runs always supply a pilot and
keep Autopilot's default master mute. No audible windowed run was launched.

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m3f_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m3f_pilots.ps1
python tests/build_m3f_sheet.py
powershell -ExecutionPolicy Bypass -File tests/run_m3f_pack.ps1
powershell -ExecutionPolicy Bypass -File tests/qa/run.ps1
```

The M3f pilot builder emits ordinary named taps, with no movement/state hooks.
Its owner route uses forward taps for down stairs, restored lift and final
exit; equipment/keys/lever/props are reached naturally. It wins at **170 turns,
6/6 HP**, including photography detours. BELL42's normal restoration route
remains 66; the full capability witness now takes 120, and its photo pilot 124.
Clearing initial loot from fixtures adds a small real cache-retrieval detour.
The 300-seed M3f two-floor tours span **114-146 turns**.

Validation receipts are `build/m3f_check_results.json`,
`build/m3f_pilot_results.json`, `build/m3f_pack_test.log` and D's ignored
`tests/qa/results/`.

| Check | Result |
| --- | --- |
| Fourteen headless suites, including new phone/spawn regressions | **188,051 assertions; 0 failures** |
| Active windowed pilot batch, including every inherited close/reopen pair | **26/26; muted** |
| Exported PCK, loaded from an empty resource directory | **194 checks; 0 failures** |
| D's unchanged default QA runner | **9/9 phases green; 0 script errors** |

D's generation pass covered 3,141 seed codes, 6,932 generated runs, 11,698
floors and 13,864 keep/return witnesses; 760 were independently replayed.
Its adversarial phase ran 768 trajectories and 270,785 action calls, with
2,292 save round trips and 192 production-store round trips. No rule finding
or softlock was found. One budget-limited sample was subsequently solved in
37 expansions through ordinary actions by D's unchanged resume search.
The type fuzzer refused all 682 corrupted cases without script errors. The
separate close/reopen phase restored 401 checkpoints in a fresh process and
replayed 4,877 continuation commands. QA-01's reproduction still refuses the
occupied normal arrival atomically; SIDLE's UI pilot remains green.

The ring test's authored arena now discards generated decoration before
replacing its masonry; the title test expects frame zero of the new painted
animation. All gameplay assertions and legacy exact-hash fixtures remain.
Pilot files were regenerated for fresh snapshots with reserved loot/props;
no saved cohort is rewritten. `git diff --check` is clean.

## Limits and read on fun

This is desktop verification, including fresh-process continue and packaged
resources. No M3f APK/device session, touch-comfort verdict or Android lifecycle
acceptance has been performed here. The supplied puddle/vault balance and
target brackets still deserve the owner's 1:1/7x phone judgment. The vignette
remains a small run rather than a larger content expansion.

My read: this improves trust and hand feel more than run depth. Walking into
the stairs, putting down the wielded knife and seeing which gate a key opens
remove friction from choices that were already enjoyable. The Porter and
the FOOD-versus-healing decision remain the best moments. No new mechanics
are needed to judge this phone build; the next useful evidence is human play.
