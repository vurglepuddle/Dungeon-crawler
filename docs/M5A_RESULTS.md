# M5a: the scaffold below the Abbey

Start with **build/m5a_shots/m5a_sheet_2x.png**. These ten frames come from
ordinary real-tap pilots, not authored snapshot captures: Abbey Seal, Fall,
waking card, persistent start choice, dawn passage, explored/panned map,
death/wake, recovered pack, Winding and dawn. Native sheet and full 3x shots
are beside it. The Fall painting is deliberately still a shake placeholder.

## Play

Run the project normally and choose NEW GAME. A fresh profile requires the
Abbey. Taking its Seal falls into the Deep; close the waking card and tap the
mark ahead. After that first Fall, NEW GAME also offers THE DEEP. Continue
still respects the loaded run's profile: old runs retain their trip home and
permanent-death epitaph. New games use m5.1/schema 3.

Defaults: three unchanged Abbey floors, one 33x33 Deep, one 9x9 Winding.
Parameters are `--deep-floors=1..3` and `--deep-blocks=COLSxROWS` (each 1..4).
They affect new adventures, not Continue. `Sim.new(seed,count,options)` exposes
the same settings; old two-argument constructors remain legacy. The viewport,
compass, accepted bevel cropping, lever scaling/hinges and slow hand timings
are preserved. All new depth art/music currently maps to the Lower Watch.

The four default blocks have ring/cross corridors, variable paired joins and
optional corded pockets. The mandatory chain runs backward from the exit:
web -> lit torch -> keyed store -> keys in a weight-held store -> stone
outside the waking room -> Seal-woken passage. A far-side latch protects
the key store. The default middle joins require another key; late fire joins
complete the large loop. Six to eight creatures are split between one roaming
encounter per block and optional corded pockets. There is plentiful junk,
one bread, one hidden tonic and one coat. No required item burns out or can
be eaten, and there are no pits or up stairs below.

The Fall commits Seal-only inventory, 5 HP and up to three scattered ordinary
possessions, never keys. Scatter is at least twelve terrain-path steps away,
on cells reachable as the floor opens. Those things say they are yours. They
are bonuses: the Deep needs no Abbey possession. Skip uses the same layout,
only the Seal and 5 HP, with no scattered items.

Death in either new act wakes at that floor's arrival with 5 HP, weapon and
belt retained. Pack and worn coat remain at the death site; progress and
enemy HP persist. Living wind-ups clear, and an occupied arrival is vacated.
Repeated-wake tests check a safe first step. The ordinary death pilot recovers
its two-item pile through the existing chooser. The Winding's working lift
reaches the existing dawn ending.

## Verification, kept bounded

| Cohort | Result |
| --- | --- |
| All 21 source suites, with accepted legacy results retained | **177,272 checks; 0 failures** |
| Included: 18 legacy source suites, parameterized sweeps at 64 | **168,774 checks; 0 failures** |
| Empty-hand Deep witnesses | **200 seeds; 191-207 turns; no damage, healing or wakes** |
| Additional rules fixtures: Fall, Abbey wake, scaled shapes, later-floor empty start | **156 checks; 0 failures** |
| Fresh generation, byte-identical Abbeys, spawn reservations and malformed m5 metadata | **7,624 checks; 0 failures; 200 seeds** |
| Current UI/profile/interrupt/drag/death/repeated-wake/obstruction tests | **118 checks; 0 failures** |
| Muted real-tap pilots | **5 new + 6 selected legacy = 11/11 passed** |
| Required painted source and packaged paths | **440 load** |
| Isolated exported resource pack: guard, legacy tour and empty-hand Deep | **777 checks; 0 failures** |

The 21-suite receipt counts each suite once. The 18 accepted legacy results
were retained with -FromSuite while the three M5 suites reran after the final
portal-mouth geometry correction. Separate focused follow-ups are not added
to that total.
The older suites with fixed seed loops retained those loops. We did not repeat
the full legacy 300-seed deep cohorts or D's full QA audit. Targeted M4a,
M3e UI and M4c UI regressions also passed after the travel-hotspot fix. The
authoritative receipt is **build/m5a_verification.json**, with individual logs;
build/m5a_pilot_results.json holds the eleven ordinary-pilot receipts.

The current fresh runner includes 21 source suites:

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_m5a_checks.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m5a_pilots.ps1
powershell -ExecutionPolicy Bypass -File tests/run_m5a_pack.ps1
python tests/build_m5a_sheet.py
```

Each new sweep/pilot is comfortably below ten minutes. `-FromSuite` and
`-FromPilot` resume verification without rerunning accepted earlier cohorts;
`-OnlyNew` limits windowed pilots to the five new routes. All pilots are
master-muted. Their explicit `--profile-path` values are under user://tests/;
Fall and skip share only a disposable unlock profile. Headless UI fixtures
also use an isolated profile. The owner's profile is not touched by testing.

New pilots: m5a_fall, m5a_skip_winding, m5a_death and m5a_save_a/b. BELL42's
empty-hand Deep/Winding route takes **205 turns**. Fall and skip compare the
same Deep; the generation cohort separately compares all three Abbey floor
bytes over 200 seeds. Supported rectangle fixtures include 1x1, 1x4, 4x1,
3x2 and 4x4; the final two-floor test starts floor five from empty hands.

## Presentation and limits

The Fall takes about 2.3 seconds; death uses a shorter dark beat. Their pending
cards persist separately from the simulation, so closing during either is safe.
Register B's future paintings as string paths in data/presentation/fall.json,
with frame_seconds (default 0.2). Empty/absent frames use the placeholder;
declared paths enter RequiredArt/export checks. No source paintings were edited.

The map keeps solid walked ink, dashed seen edges and unknown frontiers. Large
maps open centred on the Finder at eight pixels per cell and pan by real drag;
the pilot verifies panning both in the waking room and after exploring the chain.
Farther travel hotspots no longer intercept a nearer web's BURN tap.

The chain gives the larger floor a purpose, and the Seal's first deliberate
door is a clear change of act. This is still a scaffold: ring/cross block
patterns are recognisable, and the Fall/waking presentation needs B's paintings.
The next human test should judge useful confusion versus repetition before we
add floors or encounters. Bot turn counts are not human playtime measurements.

No APK/device acceptance, audible music review or phone map-performance pass
was done here. No new music, magic, traps, patrols or HP upgrades. D's harness
and report were untouched; concurrent owner/art edits remain intact. Nothing
was committed.
