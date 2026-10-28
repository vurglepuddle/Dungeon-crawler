# M3a architecture

One deterministic simulation owns a whole run. The scene presents its committed
results. See CONTRACT for exact data and DESIGN for what is playable.

- scripts/content/catalog.gd is a small JSON-safe definition table: capabilities,
  equipment role, damage, healing, provenance and optional item-purpose line. Item IDs are instances;
  their definitions drive rules and presentation.
- scripts/gen/floor_gen.gd builds all floors and item instances at creation,
  with the specified seed hash/PRNG. No timing, engine/global randomness or
  presentation state decides geometry. Floors are stored, never regenerated
  during descent or load.
- scripts/sim/dungeon_sim.gd owns inventory locations, equipment, belt, active
  floor, mechanisms, combat, stairs/lifts, restoration, exploration and terminal state. It is
  RefCounted with no nodes, filesystem, clock or input. Snapshot/query returns
  are detached. view_snapshot supplies current-floor drawable data.
- scripts/gen/witness.gd expands BFS navigation and interaction macros into
  ordinary commands through that same sim. It has no teleport, gate override,
  loot grant or damage immunity. The app requires a successful full-return
  witness before exposing a new run. Separate skip/keep/return policies prove the Porter choice. A greedy policy
  measures pack pressure; it is not a utility-optimal player model.
- scripts/persistence/state_codec.gd validates/normalises JSON-safe state and
  canonicalises it. save_store.gd handles staging, backup and recovery under
  user://. Persistence is outside the rules. CONTINUE adopts a fully validated
  snapshot, not a seed replay or freshly generated approximation. Codec accepts
  complete m2.1 and m3.1 cohorts; old runs keep old geometry and hashes. M3
  adds strict cross-floor owner/landing references and returned-item ownership.
- scripts/app/main.gd owns title/end flows, named touch controls, cards, map/
  seed/loot panels, feedback, selection, the short input gate and lifecycle
  saves. It saves before starting presentation and does not buffer actions.
- scripts/view/dungeon_view.gd uses 2D grid rays, nearest-sampled wall
  columns and sprite depth occlusion. A cached 154 x 118 floor/ceiling image
  casts world-aligned stone seams and ribs. Lamp falloff is shared by surfaces,
  walls and objects, reaching black at 3.6 cells. It rebuilds the surface image
  only when floor/position/facing changes, not on animation frames or card sync.
  There are no 3D nodes, physics or runtime image-processing dependencies.
- That view exposes detached projection(id) records: clipped object rect,
  anchor and depth. Closed gates project from their hit columns; own-cell
  objects/stairs have a bottom-of-view convention. The controller uses those
  exact records for labels and object buttons; it owns rule candidates and
  stable label collision placement. Transparent object buttons sit below all
  labels. Grouped TAKE markers name one cell's pile, with stable per-item aliases.
- scripts/art/fixture_art.gd draws larger stairs, plates and lift landings;
  item_art.gd retains small native item/inventory art. The painted Porter uses
  the same fixed palette as the R1 wall/Husk/portrait. Source, prompt, reduction
  script and 4x contact are in art_src/m3 (excluded from runtime import).
- scripts/audio/sfx.gd synthesises local PCM once for a small voice pool. A
  new warm restoration chord differs from the hostile wind-up bell. Close
  stops voices before quitting; its noise stream never touches gameplay RNG.
- scripts/ui/map_view.gd fits seen bounds and distinguishes known stairs,
  gates, owner, lift landings and Seal site. Its scale/marks cannot reveal
  unseen extents or mutate the simulation.

Data flow: seed -> bounded construction -> replayed full-run witness -> live
sim -> save -> events/snapshot -> visual/audio feedback -> touch command -> sim.
A free query, card or map cannot secretly advance enemy time. A floor change
freezes the departed floor and performs no arrival attack. All enemy intent
cells are stored; animation completion never resolves an attack.

Save replacement is intentionally small: write/flush/validate .tmp; preserve
a validated primary as .bak; replace the primary. Load prefers a valid primary,
then complete staging, then backup. New-run and terminal commits mirror the
new cohort to backup, preventing ordinary backup recovery from selecting an
old seed or resurrecting a finished run. This does not promise recovery from
loss of every valid copy or arbitrary hardware failure.

The existing Claude-owned autopilot drives real Button input through pilot_call.
M3 includes both owner choices, four room facings and a restoration close/
reopen pair. Historical M2 pilots remain alongside them. Headless checks separately cover rules, saves,
generation cuts/loops, both owner policies, exact M2 save compatibility,
projection/marker geometry, replay and pressure. Android lifecycle durability,
performance and comfort still require the owner's device.
