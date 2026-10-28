# M3e architecture

One deterministic simulation owns a whole run. The scene presents its committed
results. See CONTRACT for exact data and DESIGN for what is playable.

- scripts/content/catalog.gd is a small JSON-safe definition table: capabilities,
  equipment role, damage, healing, provenance and optional item-purpose line. Item IDs are instances;
  their definitions drive rules and presentation.
- scripts/gen/floor_gen.gd builds all floors and item instances at creation,
  with the specified seed hash/PRNG. No timing, engine/global randomness or
  presentation state decides geometry. Floors are stored, never regenerated
  during descent or load.
- scripts/gen/capability_rooms.gd appends small kennel/reliquary branches below
  the existing gate cuts, plus a hinted entrance-wall cache. Their brazier,
  torch, food access and lamp precede their optional obstacles. Floor count
  one puts both branches on its single floor. It uses no runtime RNG.
- scripts/sim/dungeon_sim.gd owns inventory locations, equipment, belt, active
  floor, mechanisms, combat, stairs/lifts, restoration, exploration and terminal state. It is
  RefCounted with no nodes, filesystem, clock or input. Snapshot/query returns
  are detached. view_snapshot supplies current-floor drawable data and seed;
  the latter is a read-only presentation addition, not a rule/state change.
- scripts/sim/capabilities.gd supplies deterministic target queries, toss lanes,
  validation/commit, fixed-lane Hound phases and active-floor Seal revelation.
  Static calls receive the sim; they retain no host reference or second state.
  The sim owns every final item/fixture/actor mutation and ordered event.
- scripts/gen/witness.gd expands BFS navigation and interaction macros into
  ordinary commands through that same sim. It has no teleport, gate override,
  loot grant or damage immunity. The app requires a successful full-return
  witness before exposing a new run. Separate skip/keep/return policies prove the Porter choice. A greedy policy
  measures pack pressure; it is not a utility-optimal player model.
  A separate tour flag visits capability branches and the return cache without
  collecting every ordinary offering. Navigation guards the whole Hound lane
  and chooses the explicit safe stair alternative when a landing is occupied.
- scripts/persistence/state_codec.gd validates/normalises JSON-safe state and
  canonicalises it. save_store.gd handles staging, backup and recovery under
  user://. Persistence is outside the rules. CONTINUE adopts a fully validated
  snapshot, not a seed replay or freshly generated approximation. Codec accepts
  complete m2.1, m3.1, m3.2 and m3.3 profiles; old runs keep old geometry and hashes. M3
  adds strict cross-floor owner/landing references and returned-item ownership.
- scripts/app/main.gd owns title/end flows, named touch controls, cards, map/
  seed/loot panels, feedback, selection, the short input gate and lifecycle
  saves. It saves before starting presentation and does not buffer actions.
- scripts/view/dungeon_view.gd uses 2D grid rays, nearest-sampled wall
  columns and sprite depth occlusion. A cached 148 x 150 floor/ceiling image
  casts world-aligned stone seams and ribs. Lamp falloff is shared by surfaces,
  walls and objects, reaching black at 3.6 cells. It rebuilds the surface image
  only when floor/position/facing changes, not on animation frames or card sync.
  There are no 3D nodes, physics or runtime image-processing dependencies.
- Architectural fixtures derive fixed backing wall normals from layout cells.
  The DDA wall face receives the canonical painting. Gates are real projected
  portal planes; their transparent overlays join per-column depth-sorted
  sprite layers. Actors on a threshold paint in front of its arch. Floor
  sprites for exit/stairs/lift are removed; logical fixture reach is unchanged.
- scripts/art/presentation_art.gd caches whole textures, images and 64-column
  AtlasTexture arrays. Stable mixed hashes choose painted wall variants by
  seed/floor/cell/normal. Sconce frame changes at 4fps, sparkle at a modest
  presentation tick. No image allocation/loading occurs on animation ticks.
- That view exposes projection(id) records using opaque sprite bounds and
  wall depth. It draws only tiny default glints or selected-item corner cues.
  The controller creates transparent object hit areas from these same records;
  there are no view labels/leader lines. Small objects get input priority over
  large bodies. Grouped TAKE targets retain stable per-item where aliases.
- scripts/ui/chrome.gd keeps the painted bronze nine-slice on buttons and
  compass. Larger slate/map/card/leather/frame surfaces stretch one continuous
  source once, with native bevels/studs and no repeated tiles. Offline sources
  and builder are in art_src/m3c; runtime assets are assets/art/ui.
  scripts/ui/item_button.gd draws full-bound 16px icons explicitly centred,
  with selection corners instead of per-pocket boxes. The root draws the
  compact pad, framed portrait, one glass HP vial, belt loops and half-dial
  compass. Damped needle motion and hurt shudder remain presentation only.
- During an item card, the controller docks the strip below the picture and
  preserves the hidden event text. Save failures update a persistent status
  control, never the event array. Looking also preserves the event array.
- item_art.gd routes known possessions to C's native icons, retaining code art
  for unknown kinds. fixture_art.gd remains an unused historical fallback for
  the architectural fixtures. The painted Porter uses
  the same fixed palette as the R1 wall/Husk/portrait. Source, prompt, reduction
  script and 4x contact are in art_src/m3 (excluded from runtime import).
- scripts/audio/sfx.gd synthesises local PCM once for a small voice pool. A
  new warm restoration chord differs from the hostile wind-up bell. Close
  stops voices before quitting; its noise stream never touches gameplay RNG.
- The B-owned Music autoload streams its original note-data scores. Main
  selects title/floor/floor2/win/death, stops on close and independently persists
  MUSIC/SFX preferences outside the run. B owns synthesis and pause/resume.
- The view loads registered state poses and three-frame strike effects from
  B's assets/art/anim and fx. It retains a killed target visually for 240ms,
  never in the sim. Wall levers use a world-fixed hinge and wall-plane depth;
  inset plates draw before their carried weight. Rule snapshots are unchanged.
- scripts/ui/map_view.gd fits seen bounds and distinguishes known stairs,
  gates, owner, lift landings and Seal site. Its scale/marks cannot reveal
  unseen extents or mutate the simulation.
- scripts/ui/survey.gd owns checked UI knowledge: seen/walked bit strings and
  discovered fixture IDs per floor. The view supplies same-camera ray cells
  and visible landmark projections, capped by walls and closed gates. Main
  captures this synchronously before saving a command. The old sim visited
  mask is retained for legacy hashes but is no longer the live map source.
- C's ambience Node2D sits between view and controls. Travel commits and saves
  the arrival survey before an out/black-sync/in sequence; tokens cancel old
  fades on reset/close. No callback advances combat. Portraits, menu plates
  and validated flavour are selected from committed state in main.

For packaged-resource acceptance, tests/stage_m3d.py copies only finalized
inputs into build/m3d_export_stage. Import/export there leaves source project
settings and C's new props/room faces untouched. An external SceneTree probe
loads the resulting PCK from an empty resource directory and checks runtime
art/alpha/JSON availability. It is not an APK/device performance test.

M3e uses tests/stage_m3e.py and run_m3e_pack.ps1 for that check. The staging
copy explicitly includes B's held items and excludes props, new screen assets
and the pending material proposals. Its probe completes the entire capability
tour from a resource pack, including transactional saves.

scripts/view/held_item.gd caches one native 48x56 right-hand frame at view-local
(100,94). Main chooses equipment, an explicitly used light, or the return
Seal; action poses and pulses stay entirely in presentation. The world view
also keeps short web/ghost transition ghosts after the corresponding sim
state is committed. Panels use B's transparent sigil on current painted stone,
with a wall-UV inset after opening. M3f selects the supplied calm_v3 floor/ceiling material per world cell.

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

RING remains pure simulation: deterministic cone/supercover sight, listener
IDs, cancelled intents, a stored floor.bell_rung charge and events. The enemy
phase skips just those stunned listeners on the ringing beat. No animation
or audio callback can decide recovery. An old M3a snapshot stays byte-for-byte
canonical until the new action upgrades its rules/content profile.

The Android storage implementation from 90f8e89 remains unchanged: user://
DirAccess handles with relative replacement. Font import/project filtering,
launcher art and export settings remain owner-managed. Art authoring and the
contact-sheet builder use offline Python only; the game has no Python/runtime
image-tool dependency. The new painted source/prompt/pipeline are in art_src/m3b.

M3f shares physical fixture attachments through scripts/sim/wall_faces.gd.
Forward collision and view projection consult the same wall/normal; the sim
caches immutable attachments per floor. The last generator pass reserves
fixture/actor/landing cells before moving conflicting loot to nearest empty
floor. scripts/gen/room_dressing.gd records sparse prop placements without
changing terrain; pilasters sit on solid wall recesses. The codec validates
optional prop metadata. Presentation suppresses decoration under dropped
possessions or visiting creatures. Old explicit floor snapshots are unchanged.

scripts/art/plane_materials.gd implements the supplied stable cell hash and
weights; the surface cache includes seed and material revision. Paint caches
accepted full-size wall controls, native UI surfaces, tiny verb stamps and
story frames. ItemButton draws measured stamps beside full VETKA words.
Main owns the optional owner_overlay.png layer, below modals and transparent
to input. Neither vines nor unreviewed authoring proposals enter staged export.

M4a: scripts/gen/deep_watch.gd recombines the established modules on floors
three onward before the final spawn-reservation/dressing pass. The Sim chooses
m4.1 for newly generated deep runs; explicit old snapshots remain m3.3. Actor
power is data, validated by StateCodec, and used by both enemy families' hit
resolution. Witness handles a moving Hound one action at a time, with bounded
replanning and peaceful bodies excluded from routes; stored-floor continuation
starts at the current floor rather than replaying earlier floors.

Main resolves pocket LIGHT/equipped BURN through the same pure target/action
queries. Visible travel hotspots have a reach-aware callback. Scene inspection
never drives a movement or enemy phase. Dedicated assets/art/items frames feed
the existing sorted/occluded sprite pass and cached opaque-bound shadows.
The optional owner vine layer has fixed registration and modal visibility.

## M4b presentation data

`art/art_family.gd::for_floor` is the single floor-to-family mapping. Its
record separates walls, fixtures, props and plane prefix/weight family, so a
Lower Watch environment can retain the existing fixture/prop kits. All current
deep visuals still borrow family two. There is no simulation family field.

`plane_materials.gd` derives fixed ground cells from the same `WallFaces`
bindings as travel. Negative binding normal determines the tile interior's
rotation; the two-pixel world seam stays unrotated. Actual lift activity is
part of the surface cache key. Room landmarks are stable presentation choices
in real 3x3 open areas; fixture ground takes precedence. Levers use the same
shared wall binding. Portal layers own web/cord/door paintings, with no second
billboard. The cache's opened face is opaque painted masonry and recess.

`art/required_art.gd` enumerates required runtime texture paths. Source tests
and an isolated exported PCK load every one. Paint logs missing loads; chrome,
waiting Porter and inventory paths never silently revert to procedural art.
The export staging helper consumes this same inventory, so a future family
change automatically includes its required files. Missing raw source files
fail staging even if stale imported copies exist. The old M1 texture helper remains available to historical tests, unused by
current world/inventory rendering. Optional owner vines are not required art.
