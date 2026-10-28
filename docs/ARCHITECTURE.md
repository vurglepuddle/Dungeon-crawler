# M2 architecture

One deterministic simulation owns a whole run. The scene presents its committed
results. See CONTRACT for exact data and DESIGN for what is playable.

- scripts/content/catalog.gd is a small JSON-safe definition table: capabilities,
  equipment role, damage, healing and provenance. Item IDs are instances;
  their definitions drive rules and presentation.
- scripts/gen/floor_gen.gd builds all floors and item instances at creation,
  with the specified seed hash/PRNG. No timing, engine/global randomness or
  presentation state decides geometry. Floors are stored, never regenerated
  during descent or load.
- scripts/sim/dungeon_sim.gd owns inventory locations, equipment, belt, active
  floor, mechanisms, combat, stairs, exploration and terminal state. It is
  RefCounted with no nodes, filesystem, clock or input. Snapshot/query returns
  are detached. view_snapshot supplies current-floor drawable data.
- scripts/gen/witness.gd expands BFS navigation and interaction macros into
  ordinary commands through that same sim. It has no teleport, gate override,
  loot grant or damage immunity. The app requires a successful full-return
  witness before exposing a new run. A separate greedy policy measures pack
  pressure; it is not a utility-optimal player model.
- scripts/persistence/state_codec.gd validates/normalises JSON-safe state and
  canonicalises it. save_store.gd handles staging, backup and recovery under
  user://. Persistence is outside the rules. CONTINUE adopts a fully validated
  snapshot, not a seed replay or freshly generated approximation.
- scripts/app/main.gd owns title/end flows, named touch controls, cards, map/
  seed/loot panels, feedback, selection, the short input gate and lifecycle
  saves. It saves before starting presentation and does not buffer actions.
- scripts/view/dungeon_view.gd uses 2D grid rays, cached nearest-sampled wall
  columns and sprite depth occlusion. There are no 3D nodes or physics. Item/
  fixture art is drawn locally by scripts/art/item_art.gd. M2 uses the existing
  painted Husk/portrait/wall and a cooler wall tint on the lower floor.
- scripts/audio/sfx.gd synthesises seven short PCM effects once, then plays
  a small local voice pool. Its noise stream never touches gameplay RNG.
- scripts/ui/map_view.gd displays seen cells/fixtures and facing, without
  mutating or moving the sim.

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
M2 includes a full return pilot, a close/reopen pair and a focused equipment/
hurt/healing/map/seed pilot. Headless checks separately cover rules, saves,
generation cuts/loops, replay and pressure. Android lifecycle durability,
performance and comfort still require the owner's device.
