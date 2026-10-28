# UNDERCROFT independent QA

Historical M3 results follow first. QA-01 and QA-02 were fixed in M3e.
The [M4a deep-profile results](#m4a-deep-profile-29-october-2026) below are the
current audit; the earlier limitations describe that earlier rules profile.

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

## M4a deep profile, 29 October 2026

This audit uses the detached QA worktree at `9d637ad` (asset-only changes above
M4a gameplay commit `1da39f8`). All new played runs have three floors and
rules/content/generator **m4.1**, snapshot/envelope schema 2. The old one/two-floor
cohort remains in the default runner. No game code, assets, other contributors'
tests or main-checkout files were edited; no commit was made. Godot 4.3 ran
headless throughout. All shared-user-directory files now have `qa_m4a_` prefixes,
including those used by the older QA phases.

**Result: all 18 phases passed; no new confirmed softlock, data-loss, crash or
wrong-rule finding. All 3,337 sampled live randomized states have witnessed
wins after bounded recovery. No sample remains search-budget exhausted.**

The legacy nine-phase runner was rerun with `-Suite legacy -Seeds 256
-AdversarialSeeds 16`: 325 codes including edges, 2,600 witnesses, 128 mutation
trajectories, all 511 live samples recovered, 682 malformed type cases, and
401 fresh-process checkpoints/4,877 continuation commands. All nine passed;
the retained QA-01/02 regressions remain green. The nine new phases ran at their
full documented cohort sizes as separate headless invocations; their error
logs were also scanned with the runner's script-error rules. The complete
combined default command was not redundantly rerun after these passes.

### Deep generation

**2,117 seed codes, 6,351 floors, 6,351 witness wins, zero failures.** The sweep
uses 2,048 generated codes plus all 32 single alphabet characters, all 32
six-character repeats, and five named edge codes. Every carved floor is
connected; each gate cuts the core route, each key is reachable before its
lock, and every third floor has its keyed gate and the three expected deep
actors with 2/3/2 damage. All witness endings validate at 6/6 HP. The keep,
return and return-plus-capability-tour routes each cover all 2,117 codes.
Independent replays check 399 routes, 70,911 accepted actions and exact ending
hashes. All 12,702 start/landing side-capacity checks pass.

| Safe witness route | Runs | Minimum turns | Median | P90 | Maximum | Mean |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Keep clapper, core | 2,117 | 102 | 122 | 131 | 146 | 122.43 |
| Return clapper, core/lift | 2,117 | 83 | 104 | 113 | 126 | 103.63 |
| Return clapper, capability tour | 2,117 | 170 | 202 | 215 | 229 | 201.36 |

These are consumed simulation turns, not elapsed phone minutes; free rotations
are excluded. The capability tour visits the optional rooms but does not fill
the pack with every offering. The separate difficulty tourists do collect loot.

### Randomized deep play and recovery

| Check | Completed deep coverage | Result |
| --- | --- | --- |
| Cohort | 96 seeds x keep/return x random/greedy/careless/spiteful; 768 trajectories, every anchor on floor three | No invariant finding |
| Actions | 329,281 calls, including cloned recovery/save play; 271,237 accepted, 58,044 rejected | 57,069,422 assertions pass |
| Recovery | 3,337 live sampled states; 3,332 immediate recovery wins, five initially budget-limited | All five subsequently won |
| Extended recovery | Exact prefix/hash replay, up to 512 frontier expansions with planner continuations per sample | Needed only 19, 36, 39, 76 and 22 expansions |
| Random save fuzz | 2,645 JSON round trips, 171 also through production disk envelopes | Full hashes match |
| Random save continuation | 21,160 same-action comparisons on original/restored copies | Events and full hashes match |
| Deaths | 184 mutation trajectories ended dead | Expected terminal outcomes; never classified as softlocks |

The five initial recovery failures were a **QA planner limitation**, not game
bugs: after tossing a deep weight onto another floor, the single recovery
policy tried to solve the deep plate without fetching a replacement. Extended
search picks up a first-floor stone/club; one sample first rides the restored
lift home. Seeds/policies are `QA4AT` return/careless (three successive samples),
`QA4CA` return/spiteful, and `QA4C3` return/random. Their exact reached-by action
lists and winning prefixes/continuations are in `deep_adversarial.json` and
`deep_resume.json`. No failure of a bounded planner is reported as a softlock.

### Measured difficulty

Each row is 128 fixed deep seeds (`QH4AA` through `QH4D9`), with the same seeds
used for keeping/returning the clapper. These are explicit deterministic play
policies with competent inherited navigation, not measured human failure rates.
Careless uses the core route, ignores tells, never heals and skips optional
wards/feeding. Greedy tours the optional rooms, gathers until full, equips
improvements, feeds/dispels, and heals at 3 HP or below while ignoring tells.
It reserves food while a Hound is hostile. Never-guard adds an early club/coat
pickup to that tour and explicitly asserts zero accepted GUARD commands.
In fact all 768 difficulty runs issued zero accepted GUARDs. Planner failures
would be a separate outcome: there were none in this cohort.

| Policy / clapper | Wins | Deaths | Death floor | Living HP at Seal | Carried food at win: 0 / 1 / 2 / 3 |
| --- | ---: | ---: | --- | --- | --- |
| Careless / keep | 70/128 | 58 (45.31%) | All 3 | 2 | 70 / 0 / 0 / 0 |
| Careless / return | 34/128 | 94 (73.44%) | All 3 | 2 | 34 / 0 / 0 / 0 |
| Greedy / keep | 128/128 | 0 | None | 2-5, mean 4.46 | 65 / 57 / 6 / 0 |
| Greedy / return | 128/128 | 0 | None | 2-5, mean 4.38 | 55 / 56 / 16 / 1 |
| Never-guard / keep | 128/128 | 0 | None | 2-5, mean 4.46 | 65 / 57 / 6 / 0 |
| Never-guard / return | 128/128 | 0 | None | 2-5, mean 4.47 | 54 / 57 / 15 / 2 |

"Food" here means carried bread/bones with the FOOD capability, excluding
tonics and supplies left on floors. Greedy finishes with mean 0.625 carried
food, median 1, range 0-3; never-guard mean 0.633, median 1, range 0-3.
Careless wins carry none. Living greedy/never-guard Seal pickups have median
5 HP. Careless also has **22 Seal pickups with HP 0 on that same action**
(11 per clapper choice); those are deaths, excluded from the living-HP column.
Five additional careless/return runs collect the Seal alive but die before
leaving floor three. Careless overall dies 152/256 (59.38%), all on three.
Equipped, healing tourist play without GUARD is demonstrably viable: the
dedicated never-guard policy wins 256/256. This is not proof that all arbitrary
routes without GUARD can win.

### Directed adversarial cases and persistence

`deep_edges.gd` exercises 16 other seeds, both clapper choices, ten cases per
choice: 320 directed cases, 65,499 checked API calls, zero invariant failures.
The three repeated deep-tell cases deliberately die in all 96 runs (Husk,
Hound and Ghost). All 224 other cases have actual winning continuations,
including a spent early coat meeting the Hound, entering deep on 1 HP without
carried heals, burning/cutting the barriers, tossing away all ordinary carried
equipment including the lit torch, trying to drop/toss/eat/equip the protected
floor-three key or Seal and walking away, eight floor-two/three round trips,
and opening the storeroom with a full pack. Full-pack pickup rejects atomically;
freeing a pocket permits pickup and completion.

`deep_food.gd` separately gathers and exhausts **all FOOD items offered on
floors one and two**, including leftovers the full-pack tourist skipped. Prior
Hound feeding counts as consumption; the remainder are eaten beside the still
living second-floor Ghost. All 32 runs enter floor three at exactly 1 HP with
no early bread/bone remaining anywhere, and all have witnessed wins. This
supersedes the weaker "no carried heals" case as the food-exhaustion check.

`deep_sidle.gd` filters 64 seeds for a public lure route. It actually lures
the living second-floor Husk onto the down landing in 18 cases across both
clapper choices, then rejects ordinary occupied arrivals and SIDLEs back four
times per case: **72 occupied-arrival/SIDLE pairs**, zero overlaps or rejection
mutations. The large generation sweep additionally checks each start/landing
has at least as many intrinsically clear neighboring cells as actors on that
floor. With one actor occupying the landing, the remaining actors cannot fill
all those neighbors. Closed gates/webs/cords and porters are excluded from the
clear-neighbor count; loose items do not block walking.

Hostile save checkpoints are reached by public actions and their full prefix
action lists are independently replayed to the exact snapshot hash. They
include pending deep Hound lane attacks, immediate post-BURN state, floor-three
landings, spent armour, spent armour facing a Hound, 1 HP, full-pack storage,
before win, won, and lost. BURN commits atomically in the sim: there is no
persistent multi-turn burn state to save. Rendering midway through a burn or
lunge animation is outside these headless sim tests.

The writer saved **321 checkpoints** (32 of each of the ten deep categories,
plus the M3f fixture), fully exited, and a different Godot process loaded every
file. All 321 full hashes and **14,280 complete continuation action/event/hash
pairs** matched. Writer PID 130832 had exited before reader PID 123608 started.
Won/lost saves correctly refuse Continue. The directed warm-save probes add
320 round trips and 2,560 randomized lockstep continuation commands.

The production M3f fixture loads through SaveStore to its exact original hash,
`14bc4617236bd22d78840604a84d7d5a4d49c6a5debe23859c1b536fe622db23`,
retains two floors and m3.3, and continues to a win. The deep malformed-save
matrix rejects 915 wrong-type replacements, six mixed version triples, legacy
headers with deep damage fields, 15 out-of-range/wrong-type deep damage values,
eight truncation lengths, malformed envelope versions and a bad checksum.
Inputs are rehashed where appropriate so payload validation is exercised.
Every rejected restore preserves the complete prior hash; invalid backup/tmp
files prevent transaction recovery from concealing a bad primary. No script
exceptions, crashes or partial adoption occurred.

### Reproduction and limits

`tests/qa/run.ps1` defaults to all **18 phases**, including the nine legacy and
nine deep phases. `-Suite deep` runs the new cohort; the knobs are
`-DeepSeeds 2048 -DeepAdversarialSeeds 96 -DifficultySeeds 128 -DeepEdgeSeeds 16`.
The directed edge writer runs before the hostile-save reader/writer phases.
See `tests/qa/DEEP_PROFILE.md` for the policy definitions and individual tools.
JSON results, exact sampled action traces and process manifests are regenerated
under ignored `tests/qa/results/`.

Every issued adversarial/recovery/randomized save-probe action checks ownership, protected
belt continuity, HP, revision/turn, rejected-state preservation, event ordering,
floor persistence, actor/fixture cells and blocking overlaps. New checks include
web/cord occupancy and advertised SIDLE acceptance. No HP, position, inventory,
fixture or actor state is injected into any played run. Only malformed-save
inputs are deliberately altered; cloned sims restore unmodified snapshots.

No Pixel 9a, touch/UI route, Android export/lifecycle/force-stop, animation,
audio, wall-clock human play duration or frame timing was tested. These tests
exercise production simulation and persistence in fresh desktop headless
processes. The main checkout's concurrent art/view wiring is outside this
snapshot. Recovery search is bounded; successful continuations prove those
samples are winnable, but budget exhaustion does not prove a softlock. There
is no exhaustive all-seed/all-state solvability claim.
