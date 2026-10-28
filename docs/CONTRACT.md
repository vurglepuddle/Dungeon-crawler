# M3a contract

New runs use rules/content/generator m3.1; snapshot/envelope schema stays 2.
Exact m2.1 version cohorts remain readable and playable from stored floors.
Loading never regenerates a run, inserts fixtures, or changes its version/hash.
The M2 fixture in tests/fixtures proves the original 77-turn final hash still
matches. Unsupported version combinations fail closed.

## Coordinates, identity and ownership

World cells are integer [x,y], x right and y down. Facing 0=N, 1=E, 2=S, 3=W.
Floor numbers are 1-based. Each current floor is 17 x 17 with row-major tiles:
0=floor, 1=wall. IDs are stable, unique across the run; ordinary floor content
uses a floor prefix, while the Porter/clapper/lift IDs are run-wide. Item
definitions are separate IDs such as stone or club. Never use display names
or screen coordinates as rule identifiers.

Codex owns scripts except scripts/dev/autopilot.gd; scenes, content/data,
assets/art, art_src, headless tests and own pilots; DESIGN/CONTRACT/ARCHITECTURE
and results. Claude owns project/export settings, autopilot, collaborator
pilots, BRIEF/COLLAB_LOG, exports/device tests and Git. No commits this turn.

## Sim API

scripts/sim/dungeon_sim.gd: UndercroftSim extends RefCounted. No nodes, clock,
input, filesystem or ambient randomness. Boundary dictionaries/arrays are
detached. Static content is in scripts/content/catalog.gd.

| Method | Result |
| --- | --- |
| new(seed="BELL42", floor_count=2) | Construct all floors; invalid input has status error |
| snapshot() / save_state() | Complete JSON-safe state |
| restore_state(data) | Validate and adopt atomically; false leaves live state untouched |
| state_hash() | SHA-256 of canonical deterministic state |
| floor_data() | Detached current floor |
| view_snapshot() | Current drawable grid, actors, fixtures, floor objects, seen cells and Finder facts |
| front_pos(), terrain(cell), can_walk(cell, ignore_actors=false) | Shared spatial queries |
| contents(cell), inspect_front() | pos, wall, fixtures, item IDs, monster ID/state |
| definition(item_id) | Detached capability/effect/provenance definition |
| reachable_items(), local_fixtures() | Current/front interaction candidates |
| targets(selected_id) | Marked selected-item targets with verb and ordinary action |
| fixture_actions(), legal_verbs(selected_id="") | Currently usable fixture actions / ordered strip actions |
| weapon_damage(), attack_damage(target_id), has_seal() | Shared rule queries; attack_damage accounts for a braced target |
| apply(action) | accepted, reason, consumed_turn, revision, ordered events |

Snapshot root: schema_version, rules_version, generator_version,
content_version, seed, floor_count, floor, pos, facing, turn, revision,
hp/max_hp, status, pack, equipment, belt, floors, items. Status is
playing/won/lost/error (error is construction-only and never saved).

pack is ordered IDs, capacity 8. equipment is {hand:id-or-empty,body:id-or-empty};
belt is protected key/Seal IDs and has no pack cost. items is an ID-keyed table
of {id,kind,location,floor,pos,slot,spent}. location is floor/pack/equip/belt/
consumed/returned; floor positions exist only for floor items. A returned
clapper has owner_id, no slot/position/floor, and its matching Porter is
restored. It never remains in a pack/equipment reference. Every item has exactly
one location. spent records an individual coat's used protection. Selection
and open panels are UI state, not an extra inventory slot.

Each floor has width/height, tiles, fixtures, actors, visited, start and
landing. Fixtures are typed records: plate links gate_id; gate has plate_id,
open/latched; latch links gate_id; lock has key_id/open; exit/stairs_up/
stairs_down have positions. M3 floors also contain:

- porter: item_id for its clapper, restored boolean; a peaceful, blocking fixture.
- lift: owner_id, active boolean, destination_floor, destination cell and
  reciprocal destination_id. Both linked lifts agree with their owner's
  restored state. Destinations point to real landing fixtures on real floors.
- layout: generation metadata (loop_top/loop_bottom/branch/weight/keyed),
  used to describe/test structural modules; never a runtime movement override.

Actors have id/kind/pos/hp/state/intent.
Husk states: idle/windup/recovery/dead. Intent is {cell,due_in:1} or empty.
It resolves on the next consumed beat on its own floor, not a wall clock or
a global deadline while another floor is active.

## Commands

Every action may carry expected_revision. Rejected/stale actions mutate
nothing. Accepted actions increment revision; only rotation leaves turn
unchanged. Queries, selection, cards, map and seed cancellation are free.

| Type | Other fields / constraints |
| --- | --- |
| turn | delta -1 or 1 |
| move | step fwd/back/strafe_l/strafe_r relative to facing |
| pickup | item_id on own/front cell; ordinary pack capacity enforced; belt essentials bypass it |
| drop | selected pack item_id onto own cell |
| place | pack item_id with HEAVY, target_id is plate directly ahead |
| equip | pack item_id with hand/body role; old equipment enters vacated pocket |
| unequip | slot hand/body; needs a free pocket |
| eat | pack item_id with healing effect; needs missing health |
| latch | target_id of accessible current/front latch |
| unlock | target_id of accessible closed lock; matching key already on belt |
| stairs | target_id of current/front stairs |
| leave | current/front entrance exit, floor 1, Seal on belt |
| hit | target_id of living actor directly ahead |
| return_item | item_id is the nearby Porter's clapper, in pack or hand; target_id is that unrestored Porter |
| ride | current/front active lift target_id; destination must be walkable and unoccupied |
| guard / wait | no extra fields |

A body presses a plate. HEAVY floor items and living Husks do too. Stepping
off closes its unlatched gate unless another weight remains. The plate/gate
gap prevents simply walking across with body pressure. A far-side latch
makes opening permanent. Bodies/HEAVY objects in a doorway prevent crushing.
Keys are reusable and unlock gates permanently. Essentials cannot be dropped.

A consumed beat: player action -> mechanisms/source death -> stored attacks
-> recovery/straight-lane approach/next intents -> mechanisms -> seen-cell
update -> terminal result. Stable actor order. Free rotation never resolves
an attack. Threatened cells never expand or retarget. Guard blocks the physical
strike; coat protection can absorb one unguarded blow. A braced Husk limits
damage to 1; its recovery admits the full HEAVY counter of 2. A defeated source cannot
attack. A recovering Husk can approach again after the player's next action.

Stairs replace the active floor/position/facing and freeze the departed actors.
There is no arrival enemy phase. Down arrives at the next start facing north;
up arrives at the previous landing facing south. RIDE arrives at the linked
lift cell facing north, with no arrival enemy phase. RETURN removes the sole
item reference from pack/equipment, sets location returned with owner_id,
restores the owner and activates both lifts atomically. It costs one beat.
All floor/item state persists.
Leaving with the Seal wins; zero health loses. Terminal commands reject.

Events contain type, phase, sequence, turn, revision and floor. Types/payloads:

- facing_changed: to; moved: from/to.
- item_moved: item_id, to, and pos for a floor destination.
- equipped: item_id, slot (empty for unequip); healed: item_id, hp.
- gate_changed: target_id, open, latched; latched/unlocked: target_id.
- struck: target_id, damage, hp; monster_defeated: actor_id.
- guarded/waited: no extra payload.
- attack_resolved: actor_id, cell, damage, blocked, armour.
- monster_moved: actor_id, from/to; intent_announced: actor_id, intent.
- floor_changed: from/to; run_ended: status.
- restored: owner_id, item_id.
- lift_ride: from/to floor numbers, target_id of destination lift.

The controller saves committed state before animation. Events do not own a
second simulation; rendering re-syncs from the authoritative snapshot. One
manual command at a time, no repeat-walking, action buffering or stale input.

## Generation and witness

Same six-symbol seed alphabet/normalisation as M1:
ABCDEFGHJKLMNPQRSTUVWXYZ23456789, 1–6 symbols, uppercase/trim. FNV-1a over
UTF-8 initializes the 32-bit LCG (1664525*s+1013904223 masked to 32 bits;
(s>>8)%limit). No runtime randomness affects rules. All floors are prebuilt;
their generated output is saved, so no generator state is needed after load.

Floor count is 1-4. Entry/upper rooms are three cells wide. A floor has a
useful loop with variable reach/height, a side room and a variable landing.
Floor one teaches weight/latch plus keyed cuts; later floors choose weight,
keyed, or both. Every key precedes its lock; no gate bypass is introduced.
There is no random hidden mandatory connection. The lift is optional.

UndercroftWitness.build(seed,count=2,explore=false,porter_policy="skip")
returns ok/reason/actions/snapshot/pressure. Policies skip/keep/return use
ordinary commands only. Return repairs the lift and uses it on the way home;
keep carries the equipped clapper and returns by stairs. The one-floor lift
links entry and upper landing; multi-floor lifts link entrance and deepest
entry landing. The app admits only a damage-free stairs return witness.

A separate greedy policy equips better weapons/an initial coat and collects
ordinary loot until full. Per-floor reports include offered, offered_kinds,
free_on_entry, free_on_exit and left_on_floor. Original item membership is
recorded before any move, so imports and re-pickups are not extra offerings.
Belt essentials are excluded; the clapper counts as an ordinary offering.
Counts describe this greedy policy, not human utility or optimum routes.
Later floors offer a healing/FOOD item, an EDGE/GLOW item and distinct extras;
capability interactions beyond existing healing/combat remain M3b.

## Disk persistence

Default user://run.json; optional isolated --save-path=user://NAME.json.
With the autopilot active and no explicit path, the app automatically uses
user://tests/pilot.json so debug new_run cannot erase the normal playing save.
Only user:// JSON paths without traversal are writable/loadable. No absolute
Android save paths. Files over 4 MB or unsupported/corrupt state fail closed.

Envelope: {save_version:2,payload:complete_snapshot,ui:{selected},sha256}.
Hash covers canonical payload with sorted keys. JSON integer values are
normalised before validation/hash comparison. Validate versions, bounds,
references, item ownership/capacity, actors, equipment and belt before adoption.

Write/flush/validate .tmp; preserve a validated primary as .bak; replace primary.
Load prefers valid primary, then complete staging, then backup. A valid primary
is the last committed transaction; do not rank revisions from different runs.
New-run and terminal saves mirror the new snapshot into backup. Thus recovery
does not choose an old seed or offer Continue from a finished run's older
playing backup. No separate receipt/ledger framework is present.

Save every accepted command (including rotation), selection changes, pause and
close. Close/pause also capture the current selected ID. Menus/animation state
are not restored. Continue restores the exact sim and valid selection, with
panels closed. Save failure is visible and never reported as success.
OS/hardware durability beyond validated-file recovery remains device testing.

## Pilot boundary and named controls

The current scene root implements pilot_call(name,args)->String:

- busy: "1" during animation or a blocking seed/map/loot panel, else "0".
  Title/end menus and item cards have usable controls and are not busy.
- state: compact public JSON. In-game fields: seed, floor/floor_count, pos,
  facing, hp, turn, revision, status, pack/belt IDs, equipment, selected,
  front contents, porter:{present,restored}, opaque complete-state hash, save_ok. At initial title:
  {status:"title",can_continue:bool}.
- where NAME: logical global centre "x y"; absent/hidden/disabled controls
  return empty. No physical-window assumptions.
- new_run SEED [FLOOR_COUNT]: explicit reset/setup hook, returns public state.
- save_path: current user:// path.
- assert KEY VALUE: public value comparison; failure logs and defers exit 1.
  Compact JSON for arrays/numbers/bools; strings unquoted or JSON-quoted.

Static game names: seed, map, new_seed, portrait, equip_hand/equip_body,
belt_key/belt_seal, pack0..pack7, verb0..verb2, fwd/back/turn_l/turn_r/
strafe_l/strafe_r, view. World labels and object hit areas share the renderer's
projection/occlusion. Labels collide/stack in stable ID order, within the view.
hot_item opens one object or a chooser for one cell's pile. hot_item_ITEM_ID
is a stable where alias for that item's pile label; it does not move or grant
anything. The strip TAKE still offers all reachable loot. hot_front is the
first selected target or nearby usable fixture; hot_FIXTURE_ID names later
fixture labels. hot_plate/hot_exit/hot_stairs/hot_latch alias hot_front.
hot_husk inspects an adjacent Husk. hot_porter opens its free owner card;
porter_return commits RETURN, porter_close closes it. Selected clapper RETURN
and HEAVY PLACE remain tappable while the item card is open. A sleeping lift
can be inspected through hot_lift_home/hot_lift_deep. Every label also has a
KEY_object button covering its object, at least 18 x 18 logical pixels.
Item cards expose card_use/card_eat (where applicable), card_drop,
card_close. Title/end: continue, retry, start, sound.

Blocking panels: seed_input/seed_start/seed_random/seed_cancel;
map_close; loot_ITEM_ID, loot_prev/loot_next, loot_cancel. Loot is paginated
six entries at a time. Do not waitidle while a blocking panel is intentionally
open: wait a few frames, interact with its named controls, then waitidle.

tests/build_m3_pilots.gd emits return, keep, four-direction room and restoration
close/reopen pilots. M2 pilots/builders are historical fixtures for the M2
generator; use M3 pilots for new runs. Gameplay remains real named taps. Hooks
do not move the Finder, grant items, force gates or advance turns. Use isolated
save paths and create the screenshot directory. Run save A then B as fresh
processes sharing one save path. A closes after restoration; B checks the exact
saved hash, turn, owner/lift state and save_ok.
