class_name UndercroftSim
extends RefCounted
## Authoritative deterministic M1 rules. Detached JSON-safe data at the boundary.

const Gen = preload("res://scripts/gen/floor_gen.gd")
const DIRS := [[0, -1], [1, 0], [0, 1], [-1, 0]]
const PACK_SIZE := 4
var _s: Dictionary = {}
var _events: Array = []

func _init(seed: String = "BELL42") -> void:
	var floor_data: Dictionary = Gen.new().generate(seed)
	if not floor_data.ok:
		_s = {"status": "error", "error": floor_data.error}
		return
	_s = {
		"schema_version": 1, "rules_version": "m1.1", "seed": floor_data.seed,
		"floor": 1, "turn": 0, "revision": 0, "status": "playing",
		"width": floor_data.width, "height": floor_data.height,
		"tiles": floor_data.tiles.duplicate(), "pos": floor_data.start.duplicate(),
		"facing": 0, "hp": 6, "max_hp": 6, "pack": [],
		"items": {"stone": {"id": "stone", "name": "Round stone", "tags": ["HEAVY"],
			"location": "floor", "pos": floor_data.stone.duplicate()}},
		"plate": {"id": "plate", "pos": floor_data.plate.duplicate(), "item": ""},
		"gate": {"id": "gate", "pos": floor_data.gate.duplicate(), "open": false},
		"husk": {"id": "husk", "pos": floor_data.husk.duplicate(), "hp": 2,
			"state": "idle", "intent": {}},
		"exit": {"id": "exit", "pos": floor_data.exit.duplicate()},
	}

func snapshot() -> Dictionary:
	return _s.duplicate(true)

func front_pos() -> Array:
	var d: Array = DIRS[_s.facing]
	return [_s.pos[0] + d[0], _s.pos[1] + d[1]]

func terrain(cell: Array) -> int:
	if cell[0] < 0 or cell[1] < 0 or cell[0] >= _s.width or cell[1] >= _s.height:
		return 1
	return _s.tiles[cell[1] * _s.width + cell[0]]

func contents(cell: Array) -> Dictionary:
	var result := {"pos": cell.duplicate(), "wall": terrain(cell) == 1,
		"gate": false, "gate_open": false, "plate": false, "item": "",
		"monster": "", "monster_state": "", "exit": false}
	if cell == _s.gate.pos:
		result.gate = true
		result.gate_open = _s.gate.open
	if cell == _s.plate.pos:
		result.plate = true
	if _s.items.stone.location == "floor" and cell == _s.items.stone.pos:
		result.item = "stone"
	if _s.items.stone.location == "plate" and cell == _s.plate.pos:
		result.item = "stone"
	if _s.husk.hp > 0 and cell == _s.husk.pos:
		result.monster = "husk"
		result.monster_state = _s.husk.state
	result.exit = cell == _s.exit.pos
	return result

func inspect_front() -> Dictionary:
	return contents(front_pos())

func _adjacent(a: Array, b: Array) -> bool:
	return absi(a[0] - b[0]) + absi(a[1] - b[1]) == 1

func can_pickup() -> bool:
	var item: Dictionary = _s.items.stone
	return _s.pack.size() < PACK_SIZE and (
		(item.location == "floor" and (item.pos == _s.pos or item.pos == front_pos())) or
		(item.location == "plate" and (_s.plate.pos == _s.pos or _s.plate.pos == front_pos())))

func targets(selected: String) -> Array:
	if _s.status != "playing" or selected != "stone" or not _s.pack.has(selected):
		return []
	if front_pos() == _s.plate.pos and _s.plate.item.is_empty():
		return [{"target_id": "plate", "pos": _s.plate.pos.duplicate(),
			"verb": "PLACE", "action": {"type": "place", "item_id": selected, "target_id": "plate"}}]
	return []

func legal_verbs(selected: String = "") -> Array:
	if _s.status != "playing":
		return []
	var front := inspect_front()
	if front.monster == "husk":
		return [{"label": "HIT", "action": {"type": "hit", "target_id": "husk"}},
			{"label": "GUARD", "action": {"type": "guard"}},
			{"label": "WAIT", "action": {"type": "wait"}}]
	var result: Array = []
	var valid := targets(selected)
	if not valid.is_empty():
		result.append({"label": valid[0].verb, "action": valid[0].action})
	elif selected.is_empty() and can_pickup():
		result.append({"label": "TAKE", "action": {"type": "pickup", "item_id": "stone"}})
	elif selected.is_empty() and (front.exit or _s.pos == _s.exit.pos):
		result.append({"label": "LEAVE", "action": {"type": "leave", "target_id": "exit"}})
	result.append({"label": "GUARD", "action": {"type": "guard"}})
	result.append({"label": "WAIT", "action": {"type": "wait"}})
	return result

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "consumed_turn": false,
		"revision": _s.get("revision", 0), "events": []}

func _event(kind: String, phase: String, data: Dictionary = {}) -> void:
	var event := {"type": kind, "sequence": _events.size(), "turn": _s.turn,
		"revision": _s.revision, "phase": phase}
	event.merge(data)
	_events.append(event)

func apply(action: Dictionary) -> Dictionary:
	if _s.status != "playing":
		return _reject("Run has ended.")
	if action.has("expected_revision") and action.expected_revision != _s.revision:
		return _reject("Stale action.")
	var kind: String = action.get("type", "")
	var destination: Array = []
	match kind:
		"turn":
			if action.get("delta", 0) not in [-1, 1]:
				return _reject("Bad turn.")
		"move":
			if action.get("step", "") not in ["fwd", "back", "strafe_l", "strafe_r"]:
				return _reject("Bad step.")
			var offset: int = {"fwd": 0, "back": 2, "strafe_l": 3, "strafe_r": 1}[action.step]
			var d: Array = DIRS[(_s.facing + offset) % 4]
			destination = [_s.pos[0] + d[0], _s.pos[1] + d[1]]
			if terrain(destination) == 1 or (destination == _s.gate.pos and not _s.gate.open):
				return _reject("The way is blocked.")
			if _s.husk.hp > 0 and destination == _s.husk.pos:
				return _reject("The Husk bars the way.")
		"pickup":
			if action.get("item_id", "") != "stone" or not can_pickup():
				return _reject("Nothing to take.")
		"place":
			if action.get("item_id", "") != "stone" or action.get("target_id", "") != "plate" or targets("stone").is_empty():
				return _reject("No place for that.")
		"hit":
			if action.get("target_id", "") != "husk" or _s.husk.hp <= 0 or front_pos() != _s.husk.pos:
				return _reject("Nothing to hit.")
		"leave":
			if action.get("target_id", "") != "exit" or not (_s.pos == _s.exit.pos or front_pos() == _s.exit.pos):
				return _reject("Find the exit first.")
		"guard", "wait":
			pass
		_:
			return _reject("Unknown action.")
	_events = []
	_s.revision += 1
	var consumed := kind != "turn"
	if consumed:
		_s.turn += 1
	var old_husk_state: String = _s.husk.state
	match kind:
		"turn":
			var before: int = _s.facing
			_s.facing = posmod(_s.facing + action.delta, 4)
			_event("facing_changed", "player", {"from": before, "to": _s.facing})
		"move":
			var before: Array = _s.pos.duplicate()
			_s.pos = destination
			_event("moved", "player", {"actor_id": "finder", "from": before, "to": destination.duplicate()})
		"pickup":
			_s.pack.append("stone")
			_s.items.stone.location = "pack"
			_s.items.stone.pos = []
			_s.plate.item = ""
			_event("item_moved", "player", {"item_id": "stone", "to": "pack"})
		"place":
			_s.pack.erase("stone")
			_s.items.stone.location = "plate"
			_s.items.stone.pos = _s.plate.pos.duplicate()
			_s.plate.item = "stone"
			_event("item_moved", "player", {"item_id": "stone", "to": "plate"})
			if not _s.gate.open:
				_s.gate.open = true
				_event("gate_latched", "mechanism", {"target_id": "gate", "open": true})
		"hit":
			_s.husk.hp -= 1
			_event("struck", "player", {"target_id": "husk", "damage": 1, "hp": _s.husk.hp})
			if _s.husk.hp <= 0:
				_s.husk.state = "dead"
				_s.husk.intent = {}
				_event("monster_defeated", "player", {"actor_id": "husk"})
		"guard", "wait":
			_event("guarded" if kind == "guard" else "waited", "player")
		"leave":
			_s.status = "won"
	if consumed and _s.status == "playing" and _s.husk.hp > 0:
		if old_husk_state == "windup":
			var hit_cell: Array = _s.husk.intent.cell.duplicate()
			var damage := 0
			if _s.pos == hit_cell:
				damage = 0 if kind == "guard" else 1
				_s.hp -= damage
			_event("attack_resolved", "attack", {"actor_id": "husk", "cell": hit_cell,
				"damage": damage, "blocked": _s.pos == hit_cell and kind == "guard"})
			_s.husk.state = "recovery"
			_s.husk.intent = {}
		elif old_husk_state == "recovery":
			_s.husk.state = "idle"
		if _s.hp <= 0:
			_s.status = "lost"
		elif _s.husk.state == "idle" and _adjacent(_s.pos, _s.husk.pos):
			_s.husk.state = "windup"
			_s.husk.intent = {"cell": _s.pos.duplicate(), "due_turn": _s.turn + 1}
			_event("intent_announced", "prepare", {"actor_id": "husk", "intent": _s.husk.intent.duplicate(true)})
	if _s.status != "playing":
		_event("run_ended", "transition", {"status": _s.status})
	return {"accepted": true, "reason": "", "consumed_turn": consumed,
		"revision": _s.revision, "events": _events.duplicate(true)}
