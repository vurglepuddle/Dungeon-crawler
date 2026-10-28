# Round 1: Codex's counterproposal

28 October 2026. A proposal for Claude and the owner to review, not an agreed
contract. This turn adds design and isolated art experiments only.

## What deserves keeping

The Undercroft of Lost Things is an excellent setting because the loot already
has a reason to exist. Keep the Finder, odd practical objects, a small pack,
owners, predictable monsters, reproducible runs and a knowledge-only Ledger.
Keep the deterministic sim and real-touch autopilot discipline from Warren.
The owner's phone baseline is a design constraint, not a later UI adjustment.

I want the central pleasure to be **finding another use for something familiar**.
An unfamiliar item and an unfamiliar rule arriving together are usually a guess,
not a discovery. Teach a few materials and then change their context.

## Where I disagree

1. **The hand is a selection model, not one verb.** Tap item, then portrait
   could mean eat, equip, inspect or accidentally consume something valuable.
   Tap distant object could mean inspect or throw. Combining on a slot competes
   with ordinary rearrangement. Keep tap-to-select, but give selection a border
   and name, and show explicit relevant verbs: `Use`, `Wear`, `Toss`, `Drop`.
   No automatic combination or throwing. Inspecting and cancelling are free.
2. **Ten tags are already a content engine.** IRON, HOLY and ROT bring exception
   rules, extra icons, copy, counters and balancing before we have a satisfying
   corridor. Tags also do not imply solutions: lamp oil is not FIRE until lit;
   something heavy may be immovable; glowing does not necessarily hurt ghosts.
   Start with five capabilities, explicit target rules and visible feedback.
   Do not make the player destroy their sword by learning that slime eats iron.
3. **A 25–35 minute, five-floor run is too much for the first slice.** It hides
   the ending from our early testers and multiplies the content needed to avoid
   repetition. Aim for 12–18 minutes and two floors. Measure actual phone time;
   do not pad it with walking to satisfy the number.
4. **Each turn costing a beat is hostile to first-person readability.** Turning
   to identify a threat should not itself trigger an unseen attack. Rotate and
   inspect freely. Steps, strikes and physical interactions advance the world.
   Equipping costs a beat; selecting or moving items between pack slots does not.
5. **GRAB is expensive and potentially unfair early on.** A required object
   stolen by a monster that flees across a pit creates more recovery logic than
   encounter value. Defer thieves. A bell creature with a large wind-up and an
   immobile lantern ghost give us stronger silhouettes and simpler contracts.
6. **Secrets must be readable discoveries.** No searching every wall pixel.
   A cracked panel repeats a clue already taught in plain sight. Its tap target
   is at least 18 px even when the visual mark is small. Secrets are bonuses.
7. **Owners need consequences beyond a reward table.** Repeating “give object,
   get better object” will be solved by the third run. Returning should change
   the place, and keeping the object should remain a viable choice.

On the open questions: **one Finder**, no party abstraction yet. **No light
clock**: permanent ambient visibility, with GLOW as an interaction capability;
time pressure comes from an announced nearby attack. **Yes to throwing later
in the slice**, but only an explicit `Toss` verb with a two-cell corridor preview.
No arcs, catching, projectile inventory damage or throwing essential objects.

## My addition: returning things repairs the dungeon

Owners are broken services, not just quest dispensers. The **Bell Porter** has
lost its clapper. Its abandoned lift no longer works. Keep the clapper as a
strong HEAVY tool, or return it: the Porter becomes friendly and restores a
short lift connection to a previously visible landing. We change a few cells
and an actor state, not rebuild the floor. The ordinary stairs remain usable.

The first encounter is legible: an empty bell, a clapper-shaped socket, a dead
lift visible beside it. Selecting the clapper shows `Return` at the socket;
the card says `Restores the lift.` Its HEAVY use has already been demonstrated.
The player knows the trade before confirming. Returning is permanent for this
run. The Porter does not also drop a superior club that erases the choice.
The lift connects the lower landing to the entrance, useful on both descent
and return. A delayed return is allowed: the decision includes when to give
up the tool. If keeping it for every fight and returning it at the end clearly
dominates, adjust landing placement/shortcut value after playtesting; do not
invent a quest expiry or pretend the original trade survived the evidence.

This makes the floor's history visible and gives a later return journey a payoff.
For the slice, do **one restoration owner** well. Later, a miller's missing hand
might restart a waterwheel, or a knight's name might turn a patrol into an escort.
Those are expansion ideas, not slice commitments. Restoration never holds the
only route to the objective hostage, and rewards never conceal essential tools.

## The complete slice

**Premise:** retrieve the abbey's lost Dawn Seal from the second floor and leave
through the entrance. The Porter and its clapper are an optional side story.
No final boss gate. The final puzzle is taking something home with what remains
in your pack; the repaired lift makes that easier if you chose to restore it.

Two persistent floors, each approximately 11 x 13 cells including walls, with
5–7 small chambers, short connecting corridors and a visible loop. Bounds are
a starting budget, not a promise of dense maze packing. About 3 encounters per
floor, one main gate, one optional puzzle, one clearly hinted secret. Floor 1
teaches; floor 2 recombines. Aim for roughly 120–200 committed actions across
the run, including return, then tune from human play. No new enemies spawn on
the return, and cleared threats stay cleared. The return should take about
1–2 minutes, with the lift reducing it further. Reject winding filler layouts.

Five carrying mechanics:

1. Read a short first-person space, move on a grid, exploit a loop or retreat.
2. Manage eight pack slots and two equipment slots; choose multipurpose loot.
3. Apply five predictable capabilities to a small family of fixtures/creatures.
4. Resolve a single clearly announced enemy attack, then exploit its recovery.
5. Return one lost component to restore a useful part of the floor.

Loop: see clue/threat -> inspect/select -> act -> observe one clear result ->
choose loot/route -> descend -> obtain Seal -> return -> leave. A short title
card and a complete run ending come before any elaborate journal or lore UI.

### Combat that fits the view

Finder starts at 6 health, shown as a number and a compact bar, with one wielded
item and one worn item. Base hit does 1; a club does 2 to an appropriate target.
Enemies have 2–4 health, deterministic damage and no hidden accuracy rolls.
Bare hands always work on required-route enemies. Optional ghosts may need GLOW.
No durability, hunger, random hit chance, levelling, mana or status pile-up.

An enemy cycles `approach -> wind-up -> strike -> recovery`. A wind-up snapshots
its threatened cells and due beat. A strike never expands or retargets those
cells after the player acts. Killing/stunning the source cancels its attack.
The player can retreat, sidestep where space exists, strike during recovery,
or guard. Guard consumes a beat and blocks the one announced adjacent physical
strike; it cannot attack as well. Avoidance must work in a one-cell corridor,
not require a sidestep into a wall. No ranged damage from an unseen monster.

Free rotation does not advance AI, regenerate anything or cancel a tell. It
lets the player inspect a flank. For the slice, place encounters so only one
hostile can threaten the Finder at once. This is a generator invariant, not
an undocumented global “only one monster attacks” rule.

Three enemy kinds, introduced separately:

| Enemy | Readable tell | Response / interesting interaction |
| --- | --- | --- |
| Bell Husk | Huge raised arm; hits its adjacent front cell for 1 | Backstep or guard, strike in recovery; HEAVY deals 2 |
| Ash Hound | Crouch; lunges along its announced two-cell lane for 1 | Step out/guard; FOOD makes it nonhostile permanently |
| Wick Ghost | Brightens; drains the adjacent marked cell for 1 | A GLOW item used on it dispels it; optional branches only |

The Bell Porter reuses the Husk body with a distinct passive pose and socket;
it does not unexpectedly attack a player who declines to return its clapper.
Threats are represented by pose **and** a large danger indicator with short
text such as `Arm raised.` / `Step back or guard.` Colour is supplementary.

### Slice items and rules

Five capabilities: **HEAVY, EDGE, FIRE, FOOD, GLOW**. EDGE is our short label
for a cutting edge. Display at most two short capability words on a card.
Keys match explicit lock IDs; ownership matches explicit owner IDs. Neither
is a universal chemistry tag. Item definitions state `consumed_on_use` for each
valid use; “has tag” alone never means “destroy it”. No recipe graph.

Thirteen definitions is the ceiling, not thirteen obligatory pickups per run:

| Item | Capabilities | Uses / limit |
| --- | --- | --- |
| Rust knife | EDGE | Starter weapon; cut optional cord; reusable |
| Hooded lamp | GLOW | Starter; reveal markings/repel ghost; no fuel clock |
| Round stone | HEAVY | Weight, club, toss; common recoverable tool |
| Ham bone | FOOD, HEAVY | Feed hound **or** eat for 1 health **or** weight/club |
| Dry bread | FOOD | Feed hound or eat for 1; consumed |
| Reed torch | FIRE, GLOW | Light at brazier; burn web or dispel ghost; reusable |
| Brass clapper | HEAVY | 3 damage to Husks; weight or permanently return to Porter |
| Glass shard | EDGE | Alternative cutter, weaker weapon; reusable |
| Red tonic | — | Heal 2, consumed; never a puzzle prerequisite |
| Iron club | HEAVY | 2 physical damage; candidate optional reward |
| Padded coat | — | Absorbs 1 damage once per run; spent state stays on item |
| Abbey key | — | Identified gate; reusable; essential belt slot |
| Dawn Seal | — | Run objective; essential belt slot |

Essential belt slots are visible, separate from pack capacity and cannot be
dropped, consumed, returned to an owner or thrown. All ordinary loot consumes
one slot, no stacking or weight arithmetic. Selecting an item never creates
a ninth pack slot: “hand” is a reference to its existing location. A full pack
offers `Leave` or a deliberate swap with a floor item, never auto-deletes loot.
To preserve the owner's equipment pleasure, the club and coat are genuine early
comparisons; the paper prototype must establish that their choices feel useful.

Environmental FIRE comes from permanent braziers with renewable reed torches;
providing another torch costs one beat and never depends on remaining inventory
supplies. Each mandatory web has its brazier on the accessible side. We do not
claim every FIRE source is interchangeable with an unlit torch.

### Concrete puzzle/encounter modules

- **Weight and latch:** put any HEAVY object on a plate, walk through, operate
  a latch from the far side. Latch holds the gate open, so taking back the weight
  cannot trap you. Both sides of the plate remain reachable.
- **Web and brazier:** a web blocks an alcove or main-route doorway; a fixed
  brazier and torch supply are before it. `Light` then `Burn`, no invisible oil
  chemistry. Burning opens permanently. On floor 2 a ghost makes the torch's
  second use attractive, with the lamp still an alternative.
- **Hound at the bend:** a telegraphed fighter guards tempting loot. Feed it a
  bone, keep the bone and fight, or take a longer visible loop. Food is optional.
- **Porter's landing:** clapper in a side room, inert lift seen earlier. Keep
  its combat utility or restore the shortcut. The loop and stairs remain open.
- **Scored panel:** an obvious teaching panel has a cut cord; later a similar
  mark hints at a secret that any EDGE item opens. No compulsory hidden wall.
- **The keyed gate:** find a named key in a reachable side chamber before the
  matching gate; a carved symbol links them. No random key colours to memorize.

Do not combine all six in every run. Select a small compatible set so floor
shape, item substitutions and return decisions vary without changing the rules.
Introduce the first Husk in a retreatable corridor, away from an inventory
puzzle. Let each new mechanic earn a clear successful use before mixing it.

### Death, win, meta

At zero health, the run ends with a seed and a plain cause of death. `Retry seed`
starts over with no retained equipment. Leaving with the Seal wins; leaving
without it offers `Keep exploring` or explicit `Abandon run`. No resurrection,
permanent stat growth, unlock-dependent seed solutions or insurance economy.

The Ledger records discovered valid interactions and owner restorations after
their first observed result, not every failed tap. Initially it is a few short
cards, not a searchable encyclopedia. The ending records returned/kept clapper,
turn count and seed. The daily seed is deferred: reproducible manual seed entry
already provides shared runs without date/clock questions.

## A screen with an actual pixel budget

Proposed fixed bands total exactly 342 logical pixels:

| y / height | Contents |
| --- | --- |
| 0 / 118 | First-person view, large local interaction hotspots |
| 118 / 36 | Two VETKA 16 px lines, 2 px padding top/bottom |
| 154 / 36 | 32 px portrait, health, facing, two equipment targets |
| 190 / 48 | Eight 32 x 22 px pack targets, four across, two rows |
| 238 / 24 | Contextual action strip; at most three 22 px-high buttons |
| 262 / 80 | Two-row movement pad with 32 px buttons, guard/wait access |

Six movement buttons: turn left, forward, turn right; strafe left, back,
strafe right. Turning arrow glyphs must differ from strafe arrows. A contextual
combat strip replaces the ordinary action strip with `Hit`, `Guard`, `Wait`.
Tapping a creature selects it for that strip; tapping it never auto-throws.
No swipe is required to play, and swipes wait until explicit taps are proven.

Item details use a temporary large card over the pack/control region, with
short name, two tags, two-line effect and explicit action/cancel. No small
tooltip text. Looking and inspecting are free; committing `Use`, `Wear`,
`Toss`, `Drop`, pickup, movement, hit, guard or wait costs a beat. Invalid
actions spend nothing. A near item hotspot is at least 18 x 18; if several
would overlap, a simple target chooser provides 22 px rows. Distant objects
can be inspected, but ordinary use requires adjacency. `Toss` previews only
legal two-cell-or-shorter facing lanes, and its final tap commits one beat.

The 32 px portrait is large enough to deserve real art. Tiny four-person
portraits, persistent 11-line logs, inventory grids of barely tappable icons
and a minimap squeezed into the view would undermine the brief. A free map
overlay shows visited cells only and a large facing marker. It cannot issue
movement or reveal hidden secrets. Extra phone height goes into margins/view,
never into smaller text. Check actual font bounds, not character count alone.

## Generation: build a solution, then challenge it

Use connected room/corridor graphs embedded into a bounded grid, not random
tile noise. Start with an entrance, objective/stairs spine and at least one
loop. Insert authored **small interaction modules** with declared entry/exit
ports, prerequisites, grants and occupied cells. Seeded choices rotate, mirror,
connect and decorate them. This is procedural assembly with meaningful
variation, not a claim that unconstrained randomness makes good puzzles.

1. Define a dependency DAG: reachable key -> keyed gate; accessible brazier ->
   torch -> web; reusable weight -> plate -> far latch. Optional ghost and
   restoration rewards never supply mandatory prerequisites.
2. Embed modules, connect corridors, reject overlaps/dead branches, check
   doorway widths, retreat spaces, visual occlusion and return connections.
   Require a useful loop, not merely a graph-theoretic cycle in a tiny closet.
3. Place keys/tools in the correct reachable region before each blocker.
   Recompute reachability after each grant; test the locked cut itself so
   accidental corridor bypasses cannot trivialize an intended main gate.
4. Assemble a candidate witness from walking BFS plus small authored action
   macros. Macros expand to **ordinary sim commands**, including rotations,
   pickup, equipment, inventory capacity, enemy beats and stair transitions.
5. Replay the complete down-and-back run through the production resolver.
   Accept only a real win, with matching owner/lock/object states and no damage
   from the guaranteed starting kit, even from one positive health. The
   witness cannot teleport, force gates, grant tools, freeze enemies or rely
   on optional food, coat, club, restoration or Ledger knowledge.
6. Bound candidate attempts by count, e.g. 12 per floor, never wall-clock time.
   If no full-run witness validates, use a small known validated fallback run
   deterministically, mark it in diagnostics and validate its full replay too.
   A failed fallback is an explicit generation error, never “probably playable”.

Use separate explicit seeded integer PRNG streams for layout, encounters and
loot, with algorithm/version recorded and test vectors; presentation has a
different stream. Never use engine/global `rand*`, dictionary iteration order,
frame timing or platform string hashes to decide rules. Six-character seed
codes normalize to a specified alphabet and byte sequence. Snapshot all floors
at run creation so future content changes cannot regenerate a saved descent.

**The proof has a boundary.** The witness proves an executable solution from
the actual initial state for every accepted run, not that every mistake is
survivable or that the game is fun. Certified generation and exploratory
recovery testing must be reported separately. We do not claim all possible
six-character seeds were exhaustively enumerated.

### Preventing softlocks after the witness

| Risk | Contract |
| --- | --- |
| Eat/burn/return only needed capability | Essential path uses reusable starting gear, persistent grants or reachable renewable fixtures; optional consumables are excluded from its proof |
| Thief takes required tool | No thief in slice; future theft excludes belt items and must leave an ordinary reachable recovery route |
| Key/Seal dropped into pit | Belt items cannot drop/toss; no item-swallowing pits or destructive containers in slice |
| Ordinary tool stranded | Drops/tosses land only on reachable supported floor, never wall/closed gate/void; verify recovery path before offering target |
| Plate shuts behind player | Far-side latch permanently opens gate; no crushing; fixture cannot destroy its weight |
| Return clapper removes only HEAVY | Common stones and mandatory plate supplies are available independently; restoration is not a capability dependency |
| Full pack blocks quest | Belt is separate; swap/leave is explicit; dropped items persist; no capacity-limited mandatory delivery |
| Descent strands a key/opens wrong floor | Stairs remain two-way, all floor state persists; no one-way collapse on required path |
| Creature blocks a necessary room | Required enemies have repeatable starter-kit counters; no health-drain clock, invulnerability dependency or off-screen attack |
| Save loses an item in a selected hand | Selection is view state; item ownership is always a real pack/equipment/belt/floor location |

Every irreversible rule affecting progression gets a fixture test. For later
messy systems, require a concrete recovery rule before admission; a starting
witness is insufficient authorization to add destructive interactions.

## Architecture and data boundary

Agree a short `docs/CONTRACT.md` before parallel edits. Carry the successful
pattern, not Warren's game rules or a copied giant framework.
The sim has no nodes, clock, input polling, filesystem or presentation state;
resource loading, saves and animation live outside it.

| Module | Responsibility |
| --- | --- |
| `scripts/sim/` | Plain RefCounted sim, action validation, ordered turn phases, combat, capabilities, fixtures, detached queries |
| `scripts/gen/` | Seed codec/PRNG, graph embedding, module assembly, witness construction/replay, diagnostics |
| `scripts/content/` + `data/` | Validated item/enemy/module JSON and centralized short display strings |
| `scripts/persistence/` | Snapshot validation, canonical JSON/hash, staged save/backup, Ledger store |
| `scripts/view/` | Perspective visibility, drawable surfaces, sprite placement, animation and hotspots |
| `scripts/ui/` | Touch controls, inventory/card/map/title/end screens; commands only through controller |
| `scripts/app/` | Controller, sim/view connection, input gate, save scheduling and lifecycle |
| `scripts/audio/` | Local sound/music from committed data; no runtime downloads |
| `scripts/dev/` + `tests/` | Debug hooks, real-UI pilots, headless checks, witness and recovery bots |

Proposed API, with exact fields frozen together before implementation:

```text
new_run(seed_code) -> Sim
apply({type, ..., expected_revision})
  -> {accepted, reason, consumed_turn, revision, events}
snapshot() -> detached full rendering state
inspect(target_id) -> detached facts + legal action descriptors
preview(action) -> exact result on an isolated clone; no RNG/state mutation
save_state() -> complete JSON-safe deterministic state
restore(validated_state) -> Sim
```

World coordinates are integer `[x,y]`, row-major tiles, north is `[0,-1]`;
facing is 0/1/2/3 clockwise from north. Stable run-wide actor, item and fixture
IDs. Every item has exactly one location; selected item is UI state. Actions
address IDs, not labels or screen coordinates. Invalid/stale requests leave
turn, revision and RNG untouched. Accepted free sim actions (e.g. rotation or
pack rearrangement) increment revision and save, without advancing the beat.

A consumed beat resolves player action -> mechanism changes/cancelled intents
-> previously advertised hostile attacks -> actor movement/recovery -> next
intents -> terminal/transition. Stable ID ordering resolves ties. Transition
is last; there is no surprise enemy beat on arrival. Events carry sequence,
revision, turn, phase, source and relevant old/new values. Floor transition
carries an authoritative replacement snapshot. Rendering never calculates
damage or advances the sim when an animation finishes.

The view receives only perceivable actor/fixture facts plus known visited map
cells; full simulation state and privileged witnesses are not display hints.
Threat visibility queries belong to shared rules, with spatial projection in
the view. The controller saves the committed state **before** animation and
on pause/close. One manual action at a time; no auto-repeat or buffered movement
in the first playable. Transition, modal, death and resume discard stale input.
Later buffering must carry expected revision and target identity.

### Pseudo-3D renderer

Godot 2D CanvasItem drawing in the 154 x 118 view. Examine a short grid frustum,
three cells deep and at most two cells either side. Determine occlusion by
grid rays/portal visibility so sprites never show through a closed side wall.
Use fixed integer corner tables for frontal wall rectangles and side-wall,
ceiling and floor trapezoids. Draw far-to-near, surfaces before objects at that
depth; closed doors occlude exactly like walls. No 3D nodes or physics.

Bake stone texture into a small atlas of front/side wall patches at each depth
using an offline nearest-sampled projection script. Runtime only blits patches,
doors, fixtures and sprites at integer positions with nearest filtering. The
geometry tables also project semantic hotspots; visual hit-testing does not
invent interaction range. Monster drawings at 64/40/24 px tall are discrete
distance variants. The 24 px version needs silhouette/eye/arm cleanup after
reduction, not blind optimism about a high-resolution illustration. Targeted
floor/ceiling shading must preserve contrast against the monster outlines.

### Content and save formats

JSON content tables have string IDs, enums, bounded integers, string keys,
visual keys and explicit state transitions; no embedded scripts or expressions.
Module definitions include ASCII grid, ports, fixtures and witness macros.
Loader errors identify the definition and stop before run construction. Use
text-grid sprites or PNG atlases; source art and offline tools stay in `art_src/`.
The installed game uses only Godot and committed resources, no Python or services.

Save root: `schema_version`, `rules_version`, `content_version`,
`generator_version`, canonical `seed`, PRNG states, `revision`, `turn`, `status`,
all generated floor geometry/state, player health/facing/location, inventory,
equipment, belt, actors/intents, item locations, visited cells and run choices.
Persist any state an attack/coat/fixture needs for the next beat. Hash canonical
JSON with sorted dictionary keys and integer rule values; the hash detects
corruption, not cheating. Validate schema, bounds, ownership and references
before replacing the current sim. Unsupported versions fail clearly; do not
silently reinterpret a save through new content.

`user://run.json`, staged `.tmp`, known-good `.bak`; write, flush, parse and
validate staged data before replacement. Include revision in validated slots
to recover the newest complete compatible state after interruption. A corrupt
primary must never overwrite a good backup. Ledger is a separately versioned
`user://ledger.json` with the same discipline. A persistence wrapper assigns a
session ID outside deterministic gameplay. Save a terminal snapshot and then
an idempotent Ledger receipt `{session_id, terminal_revision, outcome}` before
presenting a durably saved ending. On load, reconcile any valid terminal slot
into Ledger first; a receipt disqualifies older playing backups for that session.
Continue offers only playing sessions without a terminal receipt. Keep the
receipt when pruning ordinary discovery cards. This guards against resurrecting
a finished run through an older backup or duplicating discoveries; simultaneous
loss of every valid terminal record is outside that recovery guarantee.
Actual force-close and reopen on Android remain device acceptance, not a
desktop assertion.

### Evidence and tests

- **Focused headless checks:** rejected-action purity, detached queries, free
  vs consumed actions, stable resolution order, exact non-retargeting tells,
  item ownership/capacity, capability rules, essential protection, gate latches,
  two-way stairs, terminal state, PRNG vectors, snapshot/replay equivalence,
  corrupt/interrupted/unsupported save handling. Test meaningful rules, not
  trivial accessor implementations.
- **Generation:** fixed regression seeds first; at each stable generation
  milestone replay 1,000 seeds through the complete run, report steps, fallback
  frequency and failures. Check variety by normalized layouts/module choices,
  not only seed count. Later milestone sweeps can grow if failures justify it.
  Do not rerun the broad suite for prose/art-only changes.
- **Exploration/recovery bot:** deviate from witness, eat/drop/return every
  optional item, fill the pack, revisit both floors and attempt invalid throws.
  Replan through real actions. Report completed, dead, proven progression
  softlock and search-budget-unknown separately; unknown is not proof of safety.
- **Real UI:** Claude's pilot sends actual taps through the live control tree,
  asserts public state/revision and takes screenshots at 154 x 342 and integer
  desktop enlargement. Cover pickup, full-pack swap, wrong use, cancel, cast
  facing, deliberate throw, combat, stairs, restore, end, resume and pause
  during animation. Debug hooks may query/arrange a test fixture, but cannot
  substitute direct sim calls for the action being tested.
- **Phone/human:** Claude and the owner check VETKA text, touch targets, arrow
  distinction, contrast, navigation clarity, fun, interruption and save/close/
  reopen. Screenshot success does not establish phone comfort. No broad bot
  count establishes that three consecutive runs are interesting.

## Ownership and milestones

Suggested ownership follows Claude's current split, not the older Warren split:

| Writer | Files / responsibility |
| --- | --- |
| Codex | `scripts/sim/`, `gen/`, `content/`, `persistence/`, `view/`, `ui/`, `app/`, `audio/`; `data/`, game `scenes/`, `assets/art/`, `art_src/`, headless tests; draft contract/architecture/design |
| Claude | `project.godot`, `export_presets.cfg`, export/install workflow, `scripts/dev/autopilot.gd`, `tests/pilot/`, `docs/COLLAB_LOG.md`, phone playtests, Git integration/pushes |
| Shared review, named writer | `docs/DESIGN.md`, `CONTRACT.md`, `ARCHITECTURE.md`; UI/art acceptance and scope cuts |

Claude's existing untracked `scripts/` stay untouched this turn. No collaborator
edits another's owned files during parallel work without a concrete handoff.
Codex can supply a main scene; Claude connects `run/main_scene` in settings.
Contract fixtures and a minimal startup path are agreed before either side
builds against them. All milestones end with something inspectable in the UI.

| Milestone | Deliverable / stopping gate |
| --- | --- |
| **M0: now** | Review this proposal and art spike; agree narrow slice, action costs, ownership and minimal contract. No game implementation in this turn. |
| **M1: earliest first playable** | One tiny generated connected floor; first-person walls/door, six movement buttons, facing, VETKA feedback, pickup + four temporary pack slots, one HEAVY plate/latching gate, one Husk with wind-up/guard/recovery, exit and restart. Placeholder code art. A real UI pilot walks, picks up, opens gate, survives monster and exits. Complete this before building the larger inventory, owner or art system. |
| **M2: a small run worth keeping** | Eight-slot pack, item cards, two equipment slots, keys/belt, snapshot persistence, title/continue/death/win; two persistent floors and Seal return. Witness certifies full run; pause/save/close/reopen phone check. Stop and tune walk speed, combat clarity, loot choices and run duration. |
| **M3: its own identity** | FIRE/EDGE/FOOD/GLOW interactions, hound/ghost, explicit toss, Bell Porter restoration and a hinted secret. Implement one module at a time with UI pilot and regression. Add no further systems if three consecutive human runs are dull; change these interactions first. |
| **M4: slice finish** | Accepted art variants, original sound/music or fresh documented public-domain music, concise Ledger, layout/content variation, stable-seed sweep, error UI, Android lifecycle acceptance and owner playtest. No more floors or party system. |

The important stop is after M1: can a corridor, a strange object and a single
predictable creature already produce a good minute? If not, more tags and
portrait art will not repair the core. M2 proves a complete small run; M3 is
conditional on that run being worth extending.

## Art spike and recommendation

The isolated experiment lives in `art_src/spike/`. See its README for the
prompts, exact offline processing, asset sizes, validation and limitations.
Recommended direction is **hybrid**: painted/reduced monsters, masonry and
portraits; hand-authored UI, hotspot indicators and 16 px inventory symbols.
Keep a procedural/text-grid source for fast pose changes and readable distant
variants. Final acceptance depends on looking at the actual reduced sprites,
not the attractive source illustration. No game resources reference the spike.
