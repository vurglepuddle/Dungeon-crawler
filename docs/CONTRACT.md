# M4a contract

New one/two-floor runs use m3.3; new three/four-floor runs use rules/content/
generator m4.1. Snapshot/envelope schema stays 2.
Exact m2.1, m3.1 and m3.2 cohorts remain readable and playable from stored
floors. Loading never regenerates or changes a hash. The first RING in a legacy
M3a run upgrades rules/content to m3.2 while retaining its generator and floors.
Unsupported profile combinations fail closed. Captured M2 and M3a fixtures
prove their original ending hashes still match when no new action is used.

M3d's checked survey remains optional metadata under ui. M3e adds capability
rooms, actor/item/fixture fields and explicit capability/throw actions. Older
stored geometry is never decorated or regenerated. The stair occupancy/type
validation corrections apply to every accepted profile. Existing legacy
ending hashes still match along their ordinary unoccupied routes.

## Coordinates, identity and ownership

World cells are integer [x,y], x right and y down. Facing 0=N, 1=E, 2=S, 3=W.
Floor numbers are 1-based. Each current floor is 17 x 17 with row-major tiles:
0=floor, 1=wall. IDs are stable, unique across the run; ordinary floor content
uses a floor prefix, while the Porter/clapper/lift IDs are run-wide. Item
definitions are separate IDs such as stone or club. Never use display names
or screen coordinates as rule identifiers.

Codex owns scripts except scripts/dev/autopilot.gd and scripts/dev/pointer.gd; scenes, content/data,
assets/art, art_src, headless tests and own pilots; DESIGN/CONTRACT/ARCHITECTURE
and results. Claude owns project/export settings, autopilot, collaborator
pilots, BRIEF/COLLAB_LOG, exports/device tests and Git. No commits this turn.
Parallel B owns its new creature/fixture/effect/music sources and data; C owns
env/icons/screens/portrait art, scripts/fx, data/text and its manual/polish docs.
The primary Codex alone wires those contributions into the scene. D owns
tests/qa and QA_REPORT; its harness is unchanged. Authored B/C inputs remain
read-only. M3f wires accepted props/pilasters, the logotype/menu frames, calm planes,
verb stamps and torn parchment. The accepted owner vine overlay is registered
at its original pixels, above the view and needle, below pop-ups.

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
| ring_ready(), ring_targets(item_id) | Unspent current-floor charge / eligible living Husk IDs |
| toss_preview(item_id) | Detached {cells,landing,actor_id,fixture_id}; at most two forward cells, no mutation |
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
| drop | pack or equipped item_id onto own cell; no spare pocket needed |
| place | pack item_id with HEAVY, target_id is plate directly ahead |
| equip | pack item_id with hand/body role; old equipment enters vacated pocket |
| unequip | slot hand/body; needs a free pocket |
| eat | pack item_id with healing effect; needs missing health |
| latch | target_id of accessible current/front latch |
| unlock | target_id of accessible closed lock; matching key already on belt |
| stairs | target_id of current/front stairs; destination must be unoccupied and traversable |
| squeeze | same stair target; only when normal arrival is occupied, choosing the first clear adjacent cell in N/E/S/W order; UI label SIDLE |
| leave | current/front entrance exit, floor 1, Seal on belt |
| hit | target_id of living actor directly ahead |
| return_item | item_id is the nearby Porter's clapper, in pack or hand; target_id is that unrestored Porter |
| ride | current/front active lift target_id; destination must be walkable and unoccupied |
| ring | item_id is an owned clapper in pack/hand, current floor unspent, at least one eligible Husk |
| guard / wait | no extra fields |
| light | owned unlit torch item_id; target_id is a current/front lit brazier |
| burn | owned FIRE item_id; target_id is a current/front closed web |
| cut | owned EDGE item_id; target_id is a current/front closed cord grate or revealed panel |
| feed | owned FOOD item_id; target_id is a current/front unpacified living Hound |
| dispel | owned GLOW item_id; target_id is a living Ghost within two straight unobstructed cells |
| reveal | owned GLOW item_id; target_id is a current/front unrevealed panel |
| toss | ordinary owned pack/hand item_id; nonempty safe preview; explicit release costs one beat |

Capability actions require m3.3. LIGHT, BURN, CUT, REVEAL and DISPEL retain the
source. FEED consumes its food, including an equipped bone. TOSS removes one
carried reference and lands that same instance; FOOD instead becomes consumed
on feeding a Hound. FIRE opens a struck web; GLOW dispels a struck Ghost;
HEAVY deals one damage. A protected belt item has no toss lane. A closed wall,
gate, cord or unburnable web stops the lane before itself. Lit reeds can open
the web and land on its newly cleared floor. No item enters masonry or a pit.
Targets expose TOSS at distance two; the UI opens its preview before allowing
release. Opening, rotating a preview and cancelling it never throw an item.

m3.3 adds torch.lit and cache-item.hidden booleans. Hidden rewards remain floor
instances, excluded from reachable_items/contents/view objects until their
panel opens. New fixtures are brazier {lit}, web/cord {open}, and panel
{wall,normal,revealed,open,item_id}. A panel's wall is adjacent masonry;
its pos is the reachable floor cell. Only the current floor can be revealed.
Owned Seal GLOW reveals forward panels through clear sight, up to three cells
deep; it does not open them. A carried GLOW source can also reveal one early.

Actors additionally support hound (3 HP) and ghost (2 HP). Hound windup intent
is {cell,lane:[one-or-two-cells],due_in:1}, with a cardinal contiguous lane.
It attacks the stored lane, then advances only through unoccupied traversable
cells, stopping before the Finder. One backstep from adjacency stays in range;
guard or a side step answers it. Feeding cancels its intent and sets peaceful
with positive HP; it remains solid and may step into a clear perch. Ghosts
remain in their optional branch and can also be fought by guard/counter.

New ordered events: torch_lit, web_burnt, cord_cut, hound_fed,
ghost_dispelled, item_tossed, panel_revealed, secret_found and landing_skirted.
They carry the involved item_id/target_id/actor_id; item_tossed also carries
cells/pos. Hound attack_resolved includes its stored lane. Displaying flame,
recoil, held items or light pulses never changes these committed results.

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

Normal occupied stairs reject before revision, time, floor or mechanism
mutation. SIDLE is a separate ordinary transition to a clear neighbouring
landing cell; it preserves both floors' actor arrays and gives no arrival
enemy phase. With a creature directly ahead, the strip retains HIT/GUARD and
exposes the nearby stair action in its third slot. This keeps the trip usable
when its wall face is out of view. Generated landing side space exceeds the
floor's possible living actor count; the sweep checks that bound. The witness
chooses this ordinary alternative when recovery needs it.

The codec validates types before comparisons, lookups and typed assignments.
It also rejects living actor/player overlap, duplicate living actor positions
and living occupancy in blocking fixtures. Invalid restore remains atomic.
The save envelope likewise guards version/checksum field types. Android's
relative user:// staging/rename algorithm is unchanged.

RING costs one beat and sets optional floor.bell_rung=true. It reaches living
Husks at forward depth 1-3 and lateral magnitude <= depth, with an integer
supercover ray clear of walls/closed gates, including blocked corners. Actors
do not block the sound. Listener intents are cleared and states become
recovery; they neither resolve the old strike nor rearm on the ringing beat.
Their next ordinary phase resumes the normal recovery rules. Nonlisteners
still take their ordinary phase. No target/spent/wrong-owner attempts mutate
anything. Dropping, equipping, stairs, save and load never reset bell_rung.
Optional bell_rung values must be bool and require the m3.2 rules profile.
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
- bell_rung: item_id, actor_ids (stable listener order).
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
returns ok/reason/actions/snapshot/pressure. Policies skip/keep/return/ring use
ordinary commands only. Return repairs the lift and uses it on the way home;
keep carries the equipped clapper and returns by stairs. Ring keeps it and
substitutes RING for a guard only when all incoming threats are listeners. The one-floor lift
links entry and upper landing; multi-floor lifts link entrance and deepest
entry landing. The app admits only a damage-free stairs return witness.

A separate greedy policy equips better weapons/an initial coat and collects
ordinary loot until full. Per-floor reports include offered, offered_kinds,
free_on_entry, free_on_exit and left_on_floor. Original item membership is
recorded before any move, so imports and re-pickups are not extra offerings.
Belt essentials are excluded; the clapper counts as an ordinary offering.
Counts describe this greedy policy, not human utility or optimum routes.
Later floors offer a healing/FOOD item, an EDGE/GLOW item and distinct extras;
capability interactions beyond existing healing/combat remain M3e.

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
  front contents, porter:{present,restored}, ring_ready, opaque complete-state
  hash, survey_hash, travel_pending, save_ok, tossing, toss_preview,
  secrets_found, music and sfx. At initial title:
  {status:"title",can_continue:bool,music:bool,sfx:bool}.
- where NAME: logical global centre "x y"; absent/hidden/disabled controls
  return empty. No physical-window assumptions.
- new_run SEED [FLOOR_COUNT]: explicit reset/setup hook, returns public state.
- save_path: current user:// path.
- assert KEY VALUE: public value comparison; failure logs and defers exit 1.
  Compact JSON for arrays/numbers/bools; strings unquoted or JSON-quoted.

Static names: seed, map, floor_label (also save_status), portrait,
equip_hand/equip_body, belt_key/belt_seal, pack0..pack7, verb0..verb2,
fwd/back/turn_l/turn_r/strafe_l/strafe_r, compass, view. new_seed is a where
alias to seed; no duplicate NEW button occupies the camera gap. Frame/view
and normal band geometry are documented in DESIGN and M3B_RESULTS.

World controls contain no text or visible style boxes. They cover opaque
sprite bounds (minimum 18 x 18, clamped inside the view); small possessions
win overlapping hits over larger bodies. Gold glints identify default targets;
selected valid targets get item-colour corner cues. The view exposes projection
records and interaction_cues; neither is authoritative state.

M3d architecture uses projected wall/portal bounds instead of floor sprites.
Facing-independent backing walls retain the original logical target cells.
When an own-cell face is behind the camera, its strip verb remains usable.
where hot_front (and existing aliases) resolves to that real verb button if
there is no visible world button for the same action. This creates no hidden
screen target and does not bypass the action validator.

The view exposes visible_cells() and visible_landmarks(), using its camera,
FOV, range and wall layout. Closed gates/doors/webs/cords stop survey knowledge even
where painted iron has apertures. The old sim visited mask stays unchanged
for rule/hash compatibility; the live map never reads that coarse mask.

ui.survey is optional: {version:1,floors:[{seen:String,walked:String,
landmarks:Array[String]}],sha256:String}. Bit strings contain exactly 289
binary characters. Walked is a subset of seen and cannot mark masonry.
Landmarks are unique fixture IDs on that floor. sha256 covers the canonical
floors array. Absent/invalid metadata starts a blank survey without discarding
a validated run; the current viewpoint/position are then observed. No old
visited bits are imported. survey_hash describes this separate knowledge;
hash continues to describe the deterministic rules payload only.

Main observes the committed viewpoint before saving, including free turns.
Travel records arrival knowledge and saves before fading the old picture.
At black it syncs arrival, then fades in. Tokens cancel stale fades on reset
and close. The input gate covers this sequence; there is no arrival attack.
WM_CLOSE_REQUEST during a fade still saves the committed destination.

The map uses solid ink for walked ground, dashed ink for seen ground and
hatching for seen masonry. '?' consults known-edge membership without reading
hidden neighbour terrain. A functional glyph requires a visible projection
before discovery. Map animation and queries cannot mutate the simulation.

hot_item opens one object's/pile's pickup. hot_item_ITEM_ID remains a stable
where alias to its pile control. The strip TAKE offers all nearby loot.
hot_front is the first selected target or usable fixture; hot_FIXTURE_ID names
later fixture targets. hot_plate/hot_exit/hot_stairs/hot_latch alias hot_front.
hot_husk inspects an adjacent Husk; hot_porter opens the owner card;
porter_return commits RETURN, porter_close closes it. A sleeping lift uses
hot_lift_home/hot_lift_deep. KEY_object remains a where alias to KEY.

Item-card controls: card_use/card_eat where applicable, card_drop, card_close,
card_ring for an owned clapper, card_toss for an ordinary m3.3 possession.
A spent RING is disabled. The TOSS strip offers confirm/cancel; moving ends
the preview and turning updates its lane. Preview state is not saved or
replayed on Continue. Item cards leave the
full picture visible and dock verbs at y179 while open; ordinary verb y is269.
The log contents survive inspection, free rotation and failed saves.
A failed save sets ! on floor_label; save_retry/save_close belong to its free
status panel. Title/end: continue, retry, start, sound (also where sfx), music,
splash_skip. The splash leaves the run controls immediately available.
The independent switches read SFX ON/OFF and MUSIC ON/OFF.

Audio preferences use user://settings.cfg, ConfigFile section audio, bool keys
music/sfx; absent settings default enabled. They are outside snapshot/hash and
new-run replacement. Pilots and isolated tests derive *_settings.cfg beside
their own save path, so they cannot change a player's preferences. The existing
Android run-save implementation is untouched. Music requests title at title,
floor/floor2 on new/continue, win once on committed victory, and the death cue
on loss.
B's player handles pause/resume; main stops it on WM_CLOSE_REQUEST. M3d uses
floor2 on deeper floors and the short death cue on committed loss. Portrait
thresholds are fine 4-6, hurt 2-3 and near-death 1; near-death wins over flash.

Husk state maps idle->idle, windup->windup, recovery->recoil. Canvas anchors
stay fixed across states. Hit presentation keeps a target/pose briefly through
a lethal strike; that ghost has no collision, intent or simulation ownership.
struck events select EDGE/HEAVY/hands from the pre-action weapon and display
the event damage at the pre-action target. Effects last 480ms without adding
an input gate. No presentation timer changes saved state. Plate depth variants
keep their shallow aspect; plate first, possession second at equal depth.
Lever wall placement is fixed in world coordinates, not selected from camera
direction. Used gate.latched state selects the down handle independently of
the active target list. No rule/content/generator/schema versions change.

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

M3b adds tests/build_m3b_pilots.gd for an eight-frame gallery, full RING route
and a separate close/reopen pair with a spent charge and pending recovery.
The original M3 pilot builder regenerates its names/hashes for current rules.
All gameplay in playback is still actual taps. The gallery deliberately takes
one blow in place of a guard; that is not a damage-free witness.

tests/build_m3c_pilots.gd emits an expanded phone gallery, separate full runs
capturing HEAVY and bare-hand impacts, and an independent audio preference
close/reopen pair. tests/run_m3c_pilots.ps1 runs 13 windowed pilots, including
the retained-clapper and restoration reopen regressions. Hound/Ghost cells in
the contact sheet are explicitly labelled asset previews, not playable scenes.

M3d adds gallery/gate/death, survey A/B and mid-fade A/B pilots, all using
ordinary taps. Mid-fade A asserts travel_pending true and saves the committed
destination; fresh-process B asserts false and both exact hashes.
tests/run_m3d_pilots.ps1 runs these seven plus thirteen M3c regressions, using
new isolated slots and separate screenshot folders. The autopilot is unchanged.
The external art probe is named probe_m3d_pack.gd because it requires
--main-pack instead of a source-tree test run.

M3e adds a capability tour (actual FOOD toss), adjacent Hound dodge,
lit-torch/peaceful-Hound close/reopen, and QA-01's occupied stair through SIDLE.
The reference tour is now 120 turns; the screenshot pilot takes 124, adding four
real steps into/out of the kennel to photograph its peaceful occupant.
run_m3e_pilots.ps1 runs those five plus the twenty inherited regressions.
Every windowed run supplies a pilot and retains the autopilot's default master
mute; --with-sound is never passed. Pointer/autopilot remain owner-managed.
run_m3e_checks.ps1 runs thirteen headless suites, including 300 replayed tours
and a pure-sim/UI route comparison. D's harness remains independent and intact.
stage_m3e.py/run_m3e_pack.ps1 include held-item resources and prove the full
tour using an exported PCK from an empty resource directory. No APK/device
acceptance is implied by a desktop packaged-resource test.

## M3f phone corrections

No schema/profile bump: snapshots store explicit floors; existing runs are
never redecorated or regenerated. Fresh m3.3 floors add optional `props` arrays.
Each entry has string `id`, permitted `kind`, integer `pos`, and optional
integer hundredth-cell `offset` in [-25,25]. Ordinary props occupy floor;
pilasters occupy existing wall cells. The codec checks these fields before
use; canonical JSON contains no fractional coordinates. Loaded old floors
without props render normally. These new spawn choices change fresh-run
hashes; exact legacy fixtures keep theirs.

`move {step:"fwd"}` into a wall uses an accessible attached stairs/exit/lift
face when its normal matches facing. The landing can be underfoot, directly
ahead, or behind the Finder at the physical wall's mouth. Other movement
is unchanged. `scripts/sim/wall_faces.gd` is the shared attachment rule;
`fixture_near(fixture)` and `wall_bindings()` are pure queries. Attachments
are cached per floor and reset on restore, never stored in the snapshot.
Normal stair/ride/leave validation, turn cost, departure freeze, no arrival
attack, revision and transition events remain authoritative. Blocked normal
arrivals refuse; SIDLE stays explicit. A dead lift refuses atomically with
`The lift is dead.`; the UI adds the missing-bell hint. Exit without the Seal
refuses with its existing objective text.

`drop {item_id}` accepts pack or equipped possessions, clears the equipment
slot if needed and puts that same identity on the player's current cell.
It needs no free pocket. Protected belt items still refuse. UNEQUIP remains
`unequip {slot}` and requires a free pocket. Lever action type stays `latch`;
its public label is PULL. The fixed wall supports a head-on pose and tap from
its own cell; spent handles remain down.

Belt counts are presentation only. `belt_key` opens one card or a named list
when multiple keys exist. `belt_ITEM_ID` chooses a key; `keys_close` closes
the list. Key cards state the matching floor gate and its open status.
`card_use` remains the UNEQUIP pilot control on an equipped card; `card_drop`
works for equipment as well as pack items. All existing where aliases remain.

Art selection: calm_v3 plane weights and exact world-cell hash are in
`scripts/art/plane_materials.gd`; no simulation RNG, frame or facing enters
the choice. UI verb stamp layouts are copied to `data/ui/verb_layout.json`;
runtime never reads art_src. Travel glints use the arch aperture projection.
Story frames use presentation elapsed time, reset per menu, loop only on
splash/title and hold the last result frame. The splash remains skippable.

Optional overlay path: `res://assets/art/ui/owner_vines.png`, native
154x342 transparent PNG. Main creates one mouse-ignoring layer above chrome
and below cards/modals; missing file means no overlay. Only the accepted owner
export is loaded. No project setting or export preset is changed.

`run_m3f_checks.ps1` adds phone/spawn regressions to the thirteen existing
suites. `run_m3f_pilots.ps1` adds the B3VJ5K owner route to all twenty-five
active pilots, retaining isolated saves and master mute. The owner route
uses real forward taps for stairs, working lift and final exit. D's harness
is unchanged. `run_m3f_pack.ps1` exports only accepted runtime inputs and
probes a full tour from an empty resource directory; vines/WIP are excluded.

## M4a depth and direct interactions

Ordinary new-game UI defaults to three floors; --floors=1..4 remains available.
The pure Sim constructor and main.new_run(seed,count=2) retain their explicit
API default for existing callers. Pilot new_run without a count uses the UI
floor count. Retained M3 pilots now pass 2 explicitly. Continue reads the
stored count/profile, including m3.3 two-floor runs, without upgrading them.
An actual M3f envelope is retained as tests/fixtures/m3f_run.json and checked
through both the production codec and Main's Continue path.

m4.1 adds an optional integer actor.damage in [1,3], validated before use.
New deep actors store 2 for Husk/Ghost and 3 for Hound. Missing fields mean
one, so all prior profiles retain their rules. HP remains bounded at 0..6;
coats absorb one full hit, guard absorbs the hit, and no timing/HP inflation
is added. RING retains m4.1 instead of applying the legacy m3.2 upgrade.
Optional floor.title is a string of at most 22 characters. New deeper floors
have three actors, a keyed gate and both optional capability modules.

capability_targets(selected) resolves the explicit selection first, then the
held tool for all capabilities. Only LIGHT additionally searches the pack.
Implicit candidates never offer TOSS. interaction_targets combines these with
existing item targets; unrevealed scars advertise no REVEAL/LOOK target or
capability verb. Hidden inspection targets behind closed capability fixtures
cannot intercept a torch target's real tap. Existing action validation remains
authoritative; inference does not invent a new action or spend a free beat.

All projected travel faces have named hotspots, including at a distance.
Main's travel tap calls the normal action when reachable, says Step closer
without mutation when distant, explains an inactive lift, and uses SIDLE for
an occupied stair arrival. The general blocker message is not used for face
inspection. pilot where hot_FIXTURE_ID resolves its actual target even when
that fixture also uses the historical hot_front name. Public state adds the
two feedback lines as message; assert joins multiword expected values.

view_snapshot objects include spent, and the renderer uses the twelve new
world-item states at native depth canvases. Torch and Seal paths are unchanged.
Shadows use cached opaque bounds. No texture readback occurs per drawn column.
The camera, viewport bands, touch targets and compass registration are unchanged.
The owner's owner_vines.png layer renders above the needle and view edges,
below cards/modals/menus. Only the map hides it. No draft vine PNG is loaded.

The deep witness visits capability modules before the key when touring,
replans after moving Hounds and walks around peaceful bodies. Its safe route
proves zero damage without food on core paths; its tour proves food and wards
as alternative answers. It can resume from a stored current floor. Tests
separately exercise deliberate deep hits, coat absorption and healing.
run_m4a_checks.ps1 runs sixteen suites. run_m4a_pilots.ps1 adds eight muted
real-input pilots to the twenty-six inherited ones, including a deep Continue
pair. D's unchanged default QA runner remains a separate audit.

## M4b painted assets

No action, event, coordinate, save profile, generation or difficulty change.
World families are resolved only by `ArtFamily.for_floor(number)`, with
independent wall/fixture/prop indices and ordinary-plane prefix/weights.
Floors three onward use Lower Watch walls, props and calm_v3_f3 planes;
fixtures retain floor two. Earlier floors keep their accepted families.

`RequiredArt.paths()` returns required texture paths and their category;
`issues(optional_paths)` reports missing/unloadable images. Both source and
packaged checks must pass this inventory, including all three waiting Porter
sizes, ordinary/spent inventory states, chrome, animation states and portal
textures. Optional owner_vines.png is excluded from the requirement. Native
M1 silhouette/StyleBoxFlat fallbacks are not production missing-art policy.

Travel ground belongs to its fixture's world cell. Orient from negative
WallFaces binding normal, retaining the source's outer two-pixel ring. Lift
activity invalidates cached surfaces without movement. A single representation
of lever hardware uses that same physical wall binding. Web burning holds two
240ms painted portal frames; web/cord portals have no extra billboard. Open
locks use the transparent wooden-door overlay. Open caches use a complete
painted face, with no generated dark aperture rectangle. Coat spent selects
the torn 16px icon in all Main inventory/equipment/card paths.

The frame remains (0,18,154,156), picture (3,21,148,150), compass box
(85,294,66,44). This pass adds no gameplay pilot calls. The sample call exists
only in tests/capture_m4b.gd, a labelled authored visual-fixture harness; normal
Main does not implement it. The 34 ordinary tap pilots remain separate.

## M4c presentation and capability contract

Portal records carry an immutable world-space center and normal, independent
of open state and camera approach. Closed/open locks share their south/east
cell entry boundary; gate/web/cord retain their existing center planes. Cache
states remain textures on the same solid wall. Source checks compare centers,
normals, depth columns, UVs and projected sizes across both axes/four approaches.
Simulation coordinates and passability are unchanged.

effect_times.gd owns strike-frame 0.16, web-frame 0.24, dispel 0.36 and hurt
0.64 seconds. The accepted held-item timings stay in held_item.gd. A separate
hurt gate timer preserves the prior input gate while the feedback continues.
OverlayLife has a private presentation RNG, never a simulation stream or save
field. data/ui/overlay_glints.json holds skull pairs, palette, timing and rarity.
data/ui/overlay_candle.json holds the separate candle registration and beat.
Pilot metadata freezes both; authored capture fixtures may set a static frame.
The candle is a required asset, but a missing strip draws nothing at runtime.

Unrevealed scar taps only change message lines, with no card or turn. Once
revealed, an EDGE offers PRY, using the existing cut action shape and cost.
Cords retain CUT. Selection wins over the hand; only LIGHT reaches pockets;
TOSS is never inferred. Main uses Music.play_floor(actual_floor) on Continue
and after travel. No save version, simulation rule or witness route changed.

## M5a profile and dimensions

The existing `Sim.new(seed,count)` and Main/pilot `new_run` remain legacy
entrypoints. New interactive games use `new_adventure(seed,start,options)`.
The sim constructor's optional third dictionary selects
`{"profile":"m5.1","start":"abbey"|"deep","deep_floors":1,"columns":2,"rows":2}`.
Only m5.1 uses snapshot schema 3; all three version strings are m5.1. Existing
schema-2 profiles and their canonical hashes are not migrated. The staged
save envelope remains save_version 2, with its existing checksum and backup.

Schema 3 adds `act` (abbey/deep/winding), `fallen` (boolean), `wakes` (integer),
`deep_count` (1..3), and `deep_blocks` ([columns,rows], each 1..4). Total floors
are 3 + deep_count + 1. Floors 1..3 keep their m4.1 generation bytes and 17x17
dimensions. Deep dimensions are columns*16+1 by rows*16+1; Winding is 9x9.
All tile/visited indexes use the owning floor's width. Rendering, survey,
codec and room dressing use those dimensions. The historical item-art pixel
coordinates are artwork, not map indexes, and are retained.

Each Deep floor starts from its own empty-hand solvability contract. Down
stairs point at the next arrival; up stairs/exits/ordinary lifts are invalid
there. The Winding lift has `final:true`, no owner and a self destination;
it wins without a return to floor one. Legacy lift links and win validation
remain unchanged. Schema-3 fixture capacity scales to 128 for larger blocks.

The new `wake` action takes `target_id`, with no item_id required. It is a
one-beat, normal-revision action on a local `panel` with `passage:true`, while
carrying the Seal. It sets open/revealed and changes that panel's wall tile
to floor, emitting `dawn_opened`. Its portal stays at the old wall's front
plane. Ordinary panels retain their cache reward link, reveal and PRY rules.
In m5 Abbey floors, carried GLOW can reveal those old caches. New Deep dawn
passages do not passively reveal themselves.

Picking up the floor-three Seal emits `fell` and immediately commits floor 4,
5 HP, Seal-only inventory and the scatter. New item metadata `yours:true`
marks scattered possessions. No keys scatter. Candidate cells are unoccupied
and at least twelve terrain-path steps from waking, treating the dawn passage
as eventually open. The floor's own tools prove recovery need not depend on
these possessions. At zero HP, m5 emits `woke`, increments wakes, drops pack
and coat at the death cell, clears living wind-ups and returns to the current
arrival with 5 HP, belt and hand retained. These transitions are atomic and
emit no legacy run_ended/lost event. Presentation spends no simulation turns.

ProfileStore owns user://profile.json, just `{"fallen":true}`, independently
of a run. `--profile-path=user://...json` overrides it. Pilots and custom save
paths derive an isolated sibling profile if none was specified. No pilot or
headless fixture writes the owner's profile. Main saves `ui.waking` so an
interrupted Fall/wake resumes at the appropriate card. New calls:
`pilot_call("profile_path")`, `pilot_call("new_adventure",[seed,start])`.
Public state adds act, wakes, profile_fallen and map_pan. wake_close names the
card button; busy clears when that readable card is ready for a tap. Existing
pilot new_run stays legacy. Config flags: --deep-floors=N, --deep-blocks=CxR.

Large maps use eight-pixel cells, Finder-centred origin plus drag offset.
Only presentation pans; no knowledge or simulation state changes. Seen/walked
bitstrings retain their existing format, sized from the saved floor settings.
Closed travel obstructions cannot register a farther stair hotspot over the
nearer BURN/use target. Fall frame paths and hold time are read from
data/presentation/fall.json; an empty list uses the shake placeholder. Listed
paintings enter RequiredArt/export validation. Input and held-item timings
remain the accepted M4c values.
