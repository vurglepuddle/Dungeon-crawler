# M1 contract

28 October 2026. Rules `m1.1`, generator `m1.1`, snapshot schema 1. Implemented
M1 contracts only; subsequent milestones extend them explicitly.

## Sim boundary

`scripts/sim/dungeon_sim.gd`: `UndercroftSim extends RefCounted`.
No nodes, input polling, clocks, files or ambient RNG. JSON-safe dictionaries
and arrays cross the boundary, always detached. Player and tile coordinates
are integer `[x,y]`; x increases right, y down. Facing 0=N, 1=E, 2=S, 3=W.
Tile 0=floor, 1=wall, row-major. Stable IDs: finder, stone, plate, gate, husk,
exit. The selected item is a UI reference, never a second item location.

| Method | Result |
| --- | --- |
| `new(seed="BELL42")` | Construct a run; invalid seed has status `error` and error text |
| `snapshot()` | Full detached state: versions, seed, floor, turn, revision, status, grid, pos, facing, hp/max_hp, pack, items, plate, gate, husk, exit |
| `front_pos()` | Adjacent cell in facing direction |
| `contents(cell)` / `inspect_front()` | Cell pos/wall/gate/gate_open/plate/item/monster/monster_state/exit |
| `targets(selected_id)` | Valid selected-item targets: target_id, pos, verb, action |
| `legal_verbs(selected_id="")` | Ordered `{label, action}` entries for the action strip |
| `apply(action)` | `{accepted, reason, consumed_turn, revision, events}` |

Status is playing/won/lost/error. Pack is an ordered array of item IDs with
capacity 4. Item locations are floor/pack/plate. Husk has pos, hp, state
(idle/windup/recovery/dead) and intent `{cell, due_turn}` or `{}`. Gate open
is permanent once the plate has held the stone. Taking the stone back does
not close it. Complete snapshots contain generator state output, not witnesses.

## Commands and events

Every command may include `expected_revision`; a stale one is rejected without
mutation. Invalid input never consumes a turn or changes revision. Accepted
rotation increments revision without advancing the beat. All other accepted
commands increment both. Inspect/select/cancel are UI queries without revision.

```json
{"type":"turn","delta":-1}
{"type":"move","step":"fwd"}
{"type":"pickup","item_id":"stone"}
{"type":"place","item_id":"stone","target_id":"plate"}
{"type":"hit","target_id":"husk"}
{"type":"guard"}
{"type":"wait"}
{"type":"leave","target_id":"exit"}
```

Move step also accepts back/strafe_l/strafe_r, relative to facing. Hit needs a
living Husk directly ahead; damage 1, Husk health 2. Pickup reaches the current
or front cell. Place requires a carried HEAVY stone and the empty front plate.
Leave needs the exit on the current or front cell. M1 has no arbitrary drops,
throws, movement auto-repeat or queued inputs. Retry/new run replace the sim.

A beat resolves player action -> gate latch/cancelled attack source -> existing
Husk attack -> recovery/next intent -> terminal event. A wind-up strikes its
stored cell next beat even if the Finder moved elsewhere. Guard prevents its
1 damage only when that cell still contains the Finder. Rotation never fires
or cancels it. Recovery lasts until the next consumed action, allowing a hit
before the next wind-up. Killing the source cancels its pending strike. M1
Husk is stationary and starts winding up only next to the Finder. No AI beat
on scene construction. Movement onto a living monster is rejected.

Events always contain type, sequence (0-based), turn, revision, phase.

| Type | Extra payload |
| --- | --- |
| facing_changed | from, to |
| moved | actor_id, from, to |
| item_moved | item_id, to (location enum) |
| gate_latched | target_id, open |
| struck | target_id, damage, hp |
| monster_defeated | actor_id |
| guarded / waited | none |
| attack_resolved | actor_id, cell, damage, blocked |
| intent_announced | actor_id, intent |
| run_ended | status |

The renderer animates committed events, then uses the authoritative snapshot;
animation completion never advances the simulation. No saves in M1.

## Generation and proof

Seed alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, 1–6 symbols, strip whitespace
and uppercase; invalid symbols reject. FNV-1a on UTF-8 bytes initializes a
32-bit LCG (`1664525*s+1013904223`, masked to 32 bits), with `(s>>8)%limit`
for bounded choices. No engine random functions participate. M1 constructs a
9 x 11 connected floor with a mandatory gate cut, dogleg and optional alcoves.
`UndercroftWitness.build(seed)` returns ok/reason/actions/final snapshot and
uses ordinary commands for pickup, place, combat and traversal. App startup
requires a successful witness before exposing a floor. No fallback run hides
an error. The witness proves a damage-free win from the initial state, not
that every deliberate combat mistake is survivable.

## Real UI pilot contract

`scenes/main.tscn` root implements `pilot_call(name: String, args: Array) -> String`.

- `busy`: `"1"` during animation or an input gate/modal, otherwise `"0"`.
- `state`: compact JSON: seed, floor, pos, facing, hp, turn, revision, status,
  pack IDs, selected item ID or empty string, front cell contents. Includes
  gate_open as an observed progress flag. No privileged witness or hidden map.
- `where NAME`: logical-pixel centre `"x y"`. Static names: fwd, back, turn_l,
  turn_r, strafe_l, strafe_r, pack0..pack3, portrait, verb0..verb2, view, seed,
  new_seed. Modal names seed_input/seed_start/seed_cancel exist only while
  the seed-entry panel is open. Context hot_front/hot_item/hot_plate/hot_husk/hot_exit exist
  only while their corresponding visible adjacent hotspot exists. Unknown or
  currently absent controls return an empty string, never a bogus coordinate.
- `new_run SEED`: replace the run with that seed and return state. Invalid seed
  returns an error JSON and preserves the live run. Explicit debug reset only.
- `assert KEY VALUE`: compare a public-state value, report an error and quit
  with code 1 on mismatch. Used for pilot outcome checks, not gameplay actions.
  Strings are unquoted words or JSON-quoted strings (including `""`); arrays,
  booleans and integers use compact JSON. Modal controls use the same logical
  global coordinate space as controls attached directly to the scene root.

Named pilot taps run through actual Button controls and Godot input. No hook
teleports, grants loot or opens the gate. `tests/pilot/m1_walk.txt` starts BELL42
with the reset hook, then solves only by tapnamed/waitidle. Shots use the
existing autopilot's 3x nearest output; its `--out` directory must exist.
The run is immediately playable; tapping the displayed seed opens seed entry,
and NEW generates a new seed. Terminal buttons offer RETRY and NEW.

## Ownership

Codex: scripts except dev/autopilot.gd; scenes, data, assets/art, art_src,
headless tests and own pilots; DESIGN/CONTRACT/ARCHITECTURE and milestone results.
Claude: project.godot, export presets, autopilot, collaborator pilots,
COLLAB_LOG/BRIEF, export/install, Git integration/pushes and phone playtests.
One named writer per shared-document revision. No commits by Codex this turn.
