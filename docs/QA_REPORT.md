# UNDERCROFT independent QA

28 October 2026. Codex D. Godot 4.3 stable, Windows, **headless only**.
Rules/content m3.2, generator m3.1, snapshot schema 2. No game code, existing
tests, project settings or other contributors' files edited. Nothing committed.

**Two confirmed findings: occupied stair arrivals overlap the Finder and a
living Husk; malformed save field types raise script exceptions. No proven
softlock, item loss, save divergence or native process crash found.**

## What ran

| Test | Completed coverage | Result |
| --- | --- | --- |
| Generation | 3,141 distinct seed codes; 6,932 generated runs; 11,698 floors | No failure |
| Full witnesses | 13,864 wins, keeping or returning the clapper; all endings validate, 6/6 HP | No failure |
| Independent witness replays | 760 routes, 73,882 accepted commands, matching ending hashes | No failure |
| Adversarial play | 768 trajectories: 96 seeds x two clapper policies x random/greedy/careless/spiteful policies | No invariant failure in this sweep |
| Adversarial action checks | 261,210 API calls: 217,159 accepted, 44,051 rejected; 22,042,000 individual assertions | No failure |
| Reachability from sampled living states | 3,059 states; 3,058 initial recovery wins, one initial budget exhaustion, subsequently won by extended search | All samples have witnessed wins |
| Adversarial deaths | Four actual deaths; kept separate from softlocks | Expected terminal outcomes |
| Random save round trips | 2,295 JSON/restore comparisons, including 192 disk saves; 18,360 lockstep continuation commands | Exact hashes/events match |
| Directed edge policies | 897 calls, 67,701 assertions; eight additional disk round trips | No failure |
| Fresh-process persistence | 401 disk checkpoints written, writer exited, a different process loaded them; 4,877 lockstep continuation commands | Exact hashes/events match |
| Malformed saves | 578 wrong-type payloads, eight truncation lengths, malformed envelopes/checksums, >4 MB input, eight primary/staging/backup combinations | Refused atomically, but 68 type cases raise script errors |
| Directed stair occupancy | Ordinary gameplay, reduced to 61 accepted commands | Confirmed overlap; saved/restored overlap also reproduces |

Counts include cloned recovery play and save continuations; they are not all
independent human sessions. The 22 million assertions are per-action checks,
not 22 million scenarios. Generation uses A's existing witness, with independent
replays of the stated subset. The adversarial and directed harness checks
invariants after every issued action, including rejected actions.

Assertions cover unique item ownership and location, protected belt continuity,
HP bounds, exact rejected-state/hash preservation, turn/revision changes,
event ordering, traversable fixture/actor cells, living actor collisions,
inactive-floor persistence and no stair/lift arrival enemy phase. RETURN's
documented activation of the remote lift is allowed. Runtime actions have no
RNG state; generation uses the documented seeded generator. Repeat generation
is checked on every 64th seed.

The directed routes exercise body-only plates, non-HEAVY and HEAVY drops,
PLACE, recovering weights before/after latching, consuming every carried heal,
discarding all carried equipment, winning bare-handed at 1 HP, spent-coat
swapping, empty/spent RING rejection, clapper drop/re-pick/equip, six stair
round trips, late return after collecting the Seal, sleeping lifts, restored
lifts in both directions and terminal-action rejection. No position, inventory,
fixture, HP or actor state was injected into a played run. Clones restore exact
public snapshots. Only the deliberately corrupt-save inputs are modified.

## Confirmed findings

### QA-01 — Wrong rule, medium: stairs permit an occupied arrival

**Seed:** `AAAAAA`, two floors. **Reproduction:**
[`tests/qa/repro_stairs.json`](../tests/qa/repro_stairs.json) contains the full
61-command sequence. It is reduced by deleting command subsequences; every
remaining command accepts, and the Finder finishes at 6/6 HP. This is a small
reproduction, not a claim of a globally shortest route.

Take and drop the first stone on the plate, draw the Husk into the entrance
room, circle it, collect the key and unlock the upper room. Lure the living
Husk onto the down-stair landing `[7,2]`, stand at `[8,2]` facing west, descend
with `{"type":"stairs","target_id":"f1_down"}`, then immediately use
`{"type":"stairs","target_id":"f2_up"}`. The second command accepts and
puts both the Finder and the living Husk on `[7,2]`.

The stairs branch in `scripts/sim/dungeon_sim.gd::apply` assigns the destination
without an occupancy check. RIDE already calls `_arrival_clear`. The codec also
accepts this overlapping snapshot: disk save, restore and continuation reproduce
it. A normal recovery route can still win; **this finding is not a softlock**.

**Suggested fix:** calculate and validate the stair destination before any
revision/turn/floor mutation, using the same arrival rule as RIDE. An occupied
destination must reject atomically. Also reject impossible actor/player and
blocking-fixture overlaps during snapshot validation.

**Regression:** `replay_stairs.gd` replays the accepted setup and requires the
final occupied arrival to reject without changing the state hash. It currently
exits 1, as expected for an unfixed bug. `boundaries.gd` retains the original
gameplay discovery route and proves the overlapping state is still escapable.

### QA-02 — Wrong rule, medium: corrupt saves raise script exceptions

**Seed:** `BELL42`; **gameplay actions:** none. Save a fresh run, change only
`payload.schema_version` from `2` to `true`, then call `Store.load_run`.
The old checksum may remain: validation runs before checksum verification.

`scripts/persistence/state_codec.gd:29` reports:

```text
SCRIPT ERROR: Invalid operands 'bool' and 'int' in operator '!='.
```

Other malformed types reach the same problem at lines 31, 50, 75, 91, 92,
99, 103, 111, 115 and 121. The 578-case type sweep found **68 such inputs**;
testing each through direct restore and disk load produced **136 script
errors**. All inputs were refused; direct rejection preserved the live hash.
No half-run adoption, item loss or native process termination was observed.
The defect is failure of clean refusal, not evidence of a native crash.

**Suggested fix:** guard the types of versions, dimensions, kinds, IDs and
other values before comparisons or reference lookups. Return false for every
invalid combination. Retain atomic adoption and normal integer normalization.

**Regressions:** `repro_save_type.gd` retains the single-field reproduction;
`save_fuzz.gd` retains the 578-case matrix and transaction recovery cases.
Godot returns exit 0 despite these script errors. `run.ps1` therefore scans
stderr and reports failure. The minimal reproduction corrupts all three slots
to avoid a valid fallback hiding which copy was tested; it emits three errors.

## Reachability and search limits

`recovery_bot.gd` inherits A's navigation and guard/counter behavior and adds
continuation from exact partial snapshots, missing health and moved resources.
It searches safe navigation paths, solves still-closed mechanisms, acquires the
Seal and returns home with ordinary actions. Failed continuations get up to
24 legal first-action alternatives. Failure is labelled **search budget
exhausted**, never "softlock".

The sole initial exhaustion was `QDBC`, return/spiteful policy, state hash
`841130f63a726979168cc3c4de8d0e4f361e853e2390b4015d032ddb2b70a82f`.
The player had brought floor two's stone upstairs and dropped it. The initial
planner headed downstairs without taking a weight. `resume_samples.gd`
reproduced the exact sampled hash and found a win after **13 expanded states**:
turn left, pick up `f2_stone` from its actual floor-one location, then continue
the ordinary stairs route. Its output preserves the exact reaching actions and
winning continuation. **Zero unresolved samples remain.**

This is positive evidence of escape from these sampled states, not exhaustive
proof over every reachable state or seed. Four deaths were ordinary lethal
play, not softlocks. The separately reproduced stair-overlap state also has a
successful recovery witness.

## Generation and loot distributions

The seed set is `QA` plus four base-alphabet digits for integers 0–3071,
plus every one-symbol seed, every sixfold repeated symbol, `BELL42`, `A99999`,
`9AAAAA`, `AZ29AZ` and `99999A`: **3,141 distinct codes**. This covers both
alphabet edges and repeated-character inputs. Every code ran with one and two
floors; the first 256 codes and all 69 edge/special codes also ran with three
and four floors. Each configuration ran both keep and return policies.

Every generated floor passes raw terrain connectivity, gate-cut, key-before-lock
and useful-loop checks. There are 2,823 distinct raw floor-layout sequences
across the tested configurations. All 13,864 witness endings validate and win
without damage. These turn counts describe the existing bot, not optimal play
or human duration:

| Floors | Choice | Runs | Min | Median | P95 | Max |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | keep | 3,141 | 38 | 44 | 48 | 50 |
| 1 | return | 3,141 | 30 | 35 | 39 | 40 |
| 2 | keep | 3,141 | 68 | 80 | 90 | 96 |
| 2 | return | 3,141 | 60 | 71 | 80 | 86 |
| 3 | keep | 325 | 100 | 118 | 130 | 138 |
| 3 | return | 325 | 81 | 97 | 108 | 115 |
| 4 | keep | 325 | 132 | 156 | 170 | 180 |
| 4 | return | 325 | 102 | 122 | 135 | 144 |

Ordinary loot excludes belt keys/Seal and includes the clapper. Counts are
original offerings, before player transfers. Repeated floor-one appearances
in different floor-count configurations are counted per generated run.

| Floor | Samples | Loot count: number of floors | Mean |
| --- | ---: | --- | ---: |
| 1 | 6,932 | 8: 1,434; 9: 1,380; 10: 1,346; 11: 1,426; 12: 1,346 | 9.98 |
| 2 | 3,791 | 4: 939; 5: 953; 6: 969; 7: 930 | 5.50 |
| 3 | 650 | 4: 154; 5: 194; 6: 134; 7: 168 | 5.49 |
| 4 | 325 | 4: 101; 5: 78; 6: 57; 7: 89 | 5.41 |

The adversarial sweep observed full packs on 5,133 action checks, 1 HP on 479,
body-only/no-item plate occupancy on 3,754, and plate occupancy with an item on
5,694. These count repeated observations and recovery clones, not unique states.

## Persistence evidence and rerunning

The fresh-process pair writes 401 checkpoints across four seeds, all four floor
counts and keep/return/ring policies. Checkpoints include 48 each on a body
plate, weighted plate, pending attack, after belt pickup, mid-run, before win
and after win; 16 after restoration, 36 after stairs, 12 just after RING and
one after actual death. The writer fully exits before the reader starts.
Every full state hash matches, all 4,877 continuation event/state pairs match,
and terminal saves do not offer Continue. This verifies the production
SaveStore in fresh desktop headless processes, not Android app lifecycle UI.

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/qa/run.ps1
```

The execution-policy setting applies only to that PowerShell process. All
Godot invocations use `--headless --path ... -s res://tests/qa/<file>.gd`.
The runner keeps one test process at a time, uses only isolated
`user://tests/qa/` slots, records its process IDs, and treats script errors as
failures even when Godot exits 0. It currently returns failure for QA-01/02.

Focused suites: `-Suite stairs`, `save`, `edges`, `reopen`, `adversarial` or
`generation`. `-Seeds N` and `-AdversarialSeeds N` reduce the two sweeps. The
adversarial suite automatically extends any inconclusive samples. The original
stair discovery route can be run directly with
`-s res://tests/qa/boundaries.gd`; the reduced regression is `replay_stairs.gd`.

Machine-readable JSON, logs and process manifests are regenerated under
`tests/qa/results/` and ignored by Git. The fixed reproduction JSON is kept
beside the runnable scripts. The known root-certificate-store startup diagnostic
appears in otherwise passing headless runs; it is not a new finding.

The six gameplay/generation/persistence/content sources had unchanged hashes
through this audit. Reference SHA-256 values:

```text
scripts/sim/dungeon_sim.gd              872968ec433f9ef69b72b991746d54110a3a27aa756fffaf5868032da30130b2
scripts/gen/floor_gen.gd                8ce4338b17d3e52c2645e2aaba455e3e0a2a14deb417e6f7485ecb9e9a4bf910
scripts/gen/witness.gd                  8ad5799f884d6adef2d528f6f31023cdb35b1f72d677ed07166bddd8069da5a8
scripts/persistence/state_codec.gd      b21a82097c71e6df13354392445f0cb3815319bd430ca7d47c3b9c2300b0223c
scripts/persistence/save_store.gd       6a6c364b20a6277453c01bb56ded8980270deb0b4a958772dcf4b58d87ed8bd4
scripts/content/catalog.gd              209fdc487bdce3f82bc945aab7525eb81ea23dc166d0b95c1a74d953760d7b51
```

## Not tested

No windowed scene, actual touch/UI event flow, Pixel 9a, Android export,
background/resume, OS force-kill, hardware durability, audio shutdown, visual
readability or human enjoyment/pacing was tested. A's ongoing view/UI work is
outside this audit. TOSS is not implemented in this rules profile: unknown
TOSS requests reject without changing state; actual throwing trajectories
cannot yet be exercised. FIRE/EDGE/FOOD/GLOW encounter modules beyond the
current healing/combat/weight rules are likewise not implemented. No claim of
all-seed or exhaustive all-state solvability is made.
