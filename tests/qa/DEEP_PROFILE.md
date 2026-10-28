# M4a QA profile

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tests/qa/run.ps1`
from the worktree root. The default includes the nine original phases plus nine
deep phases. `-Suite legacy` or `-Suite deep` selects a cohort; `generation`,
`adversarial`, `save`, `reopen` and `edges` include both relevant profiles.
`-Suite difficulty` runs just the measured policies.

Defaults: `-Seeds 3072 -AdversarialSeeds 96 -DeepSeeds 2048
-DeepAdversarialSeeds 96 -DifficultySeeds 128 -DeepEdgeSeeds 16`.
Generation adds 69 alphabet/repeated-character/edge codes to each seed sweep.
The occupied-boundary test filters 64 seeds for suitable lure geometry and
requires at least four real occupied arrivals. All runtime state changes use
`apply`; clones only restore unmodified snapshots. Every user save file begins
`qa_m4a_`, including the legacy suite, to isolate the shared user-data directory.
The runner is sequential. Large sweeps and deep recovery have a two-hour
process ceiling; other phases retain 30 minutes. Full deep sweeps take tens of
minutes on this machine; the count parameters make focused reruns possible.

Deep phases:

- `deep_generation.gd`: three-floor connectivity, keyed gates, deterministic
  generation, landing space, codec, keep/return/tour witnesses and turn histograms.
- `deep_adversarial.gd`: four mutation policies anchored on floor three, both
  clapper choices, invariant checks, recovery wins and save continuations.
- `resume_samples.gd -- --input=deep_adversarial`: up to 512 frontier expansions
  per unresolved sample, each with an arbitrary-state recovery continuation.
  Exhaustion means inconclusive, never a proven softlock.
- `deep_edges.gd`: directed tells, spent armour, depleted carried heals, burns,
  cuts, full-pack storage, discarded equipment, belt rejection and stair dances.
- `deep_sidle.gd`: lure a living Husk onto floor two's down landing, descend,
  reject the occupied ordinary arrival, then SIDLE back four times per case.
- `deep_food.gd`: exhaust all bread/bone offered on floors one and two, enter
  three on 1 HP, and seek a win. Prior Hound feeding also consumes food.
- `deep_difficulty.gd`: deterministic navigation with three explicit policies.
  Careless takes the core route, ignores tells and never heals. Greedy tours,
  fills pockets, equips improvements, feeds/dispels and heals at 3 HP or less,
  while ignoring tells. Never-guard adds an early club/coat pickup to that tour
  and asserts zero GUARD actions. Greedy reserves food while a Hound is hostile.
  Death, win and planner failure are recorded separately. These are policy
  benchmarks, not estimates of human failure rates or optimal play.
- `deep_save.gd -- --phase=write`, then `--phase=read`: serialize directed
  checkpoints, exit the writer, reopen in a new process and replay complete
  recovery continuations. Also compare the exact production M3f hash, continue
  that fixture to a win, and reject rehashed wrong-type and mixed-profile inputs.
  Burn is an atomic sim action, so its persistent checkpoint is immediately
  after BURN; Hound checkpoints are actual pending lane attacks.

Results, full action traces, hashes and process manifests go to ignored
`tests/qa/results/`. The runner rejects script errors even on exit code zero.
The known root-certificate-store startup warning is recorded but is not a
gameplay failure. Nothing opens a window or touches the main checkout.
