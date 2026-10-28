extends SceneTree

const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const FONT = preload("res://assets/font/vetka.ttf")
var checks := 0
var failures := 0

func _initialize() -> void:
	_rules()
	_generation()
	_copy_widths()
	print("M1 RESULTS: %d checks, %d failures, 512 full seed witnesses" % [checks, failures])
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func command(sim, action: Dictionary) -> void:
	check(sim.apply(action).accepted, "Required action rejected: " + JSON.stringify(action))

func entry(sim) -> void:
	command(sim, {"type": "pickup", "item_id": "stone"})
	command(sim, {"type": "move", "step": "fwd"})
	command(sim, {"type": "place", "item_id": "stone", "target_id": "plate"})

func approach(sim) -> void:
	entry(sim)
	for _i in range(3):
		command(sim, {"type": "move", "step": "fwd"})
	check(sim.snapshot().husk.state == "windup", "Husk announces on approach")

func _rules() -> void:
	check(Gen.normalize_seed(" bell42 ") == "BELL42", "Seed normalization")
	for bad in ["", "123456", "TOOLONG", "OOPS", "I", "AA/BB"]:
		check(Gen.normalize_seed(bad) == "", "Bad seed rejected: " + bad)
	var invalid = Sim.new("?")
	check(invalid.snapshot().status == "error", "Bad sim seed errors explicitly")
	var sim = Sim.new("BELL42")
	var detached: Dictionary = sim.snapshot()
	detached.pos[0] = -99
	detached.items.stone.location = "gone"
	check(sim.snapshot().pos[0] != -99 and sim.snapshot().items.stone.location == "floor", "Snapshot is deeply detached")
	var before: String = JSON.stringify(sim.snapshot())
	for action in [{"type": "nonsense"}, {"type": "turn", "delta": 2},
		{"type": "turn", "delta": 1, "expected_revision": 999},
		{"type": "move", "step": "teleport"}, {"type": "pickup", "item_id": "fake"},
		{"type": "place", "item_id": "stone", "target_id": "plate"},
		{"type": "hit", "target_id": "husk"}, {"type": "leave", "target_id": "exit"}]:
		check(not sim.apply(action).accepted, "Invalid action rejected")
		check(JSON.stringify(sim.snapshot()) == before, "Rejected action is pure")
	command(sim, {"type": "turn", "delta": -1})
	check(sim.snapshot().facing == 3 and sim.snapshot().turn == 0 and sim.snapshot().revision == 1, "Free turn revision/beat contract")
	command(sim, {"type": "turn", "delta": 1})
	check(sim.inspect_front().item == "stone", "Stone visible directly ahead")
	command(sim, {"type": "pickup", "item_id": "stone"})
	check(sim.snapshot().pack == ["stone"] and sim.snapshot().items.stone.location == "pack", "Pickup transfers ownership")
	check(not sim.apply({"type": "pickup", "item_id": "stone"}).accepted, "Duplicate pickup rejected")
	command(sim, {"type": "move", "step": "fwd"})
	var targets: Array = sim.targets("stone")
	check(targets.size() == 1 and targets[0].verb == "PLACE", "Selected tool marks valid plate")
	targets[0].action.type = "bad"
	check(sim.targets("stone")[0].action.type == "place", "Target actions detached")
	command(sim, {"type": "move", "step": "fwd"})
	before = JSON.stringify(sim.snapshot())
	check(not sim.apply({"type": "move", "step": "fwd"}).accepted, "Closed gate blocks movement")
	check(JSON.stringify(sim.snapshot()) == before, "Blocked movement costs nothing")
	command(sim, {"type": "move", "step": "back"})
	var placed: Dictionary = sim.apply({"type": "place", "item_id": "stone", "target_id": "plate"})
	check(placed.accepted and sim.snapshot().gate.open, "Plate latches gate")
	check(placed.events[0].type == "item_moved" and placed.events[1].type == "gate_latched", "Player item action precedes mechanism")
	for i in range(placed.events.size()):
		check(placed.events[i].sequence == i and placed.events[i].turn == sim.snapshot().turn, "Ordered event envelope")
	check(sim.snapshot().pack.is_empty() and sim.snapshot().plate.item == "stone", "Placement transfers item once")
	command(sim, {"type": "pickup", "item_id": "stone"})
	check(sim.snapshot().gate.open and sim.snapshot().plate.item == "" and sim.snapshot().pack == ["stone"], "Retrieve weight without shutting gate")
	check(not sim.targets("bogus").size(), "Unknown selection has no targets")
	# Guard, free-looking and exact threatened cells.
	sim = Sim.new("BELL42")
	approach(sim)
	var turn: int = sim.snapshot().turn
	var intent: Dictionary = sim.snapshot().husk.intent
	command(sim, {"type": "turn", "delta": -1})
	command(sim, {"type": "turn", "delta": 1})
	check(sim.snapshot().turn == turn and sim.snapshot().hp == 6 and sim.snapshot().husk.intent == intent, "Looking does not fire/reset intent")
	var guarded: Dictionary = sim.apply({"type": "guard"})
	check(guarded.accepted and sim.snapshot().hp == 6 and sim.snapshot().husk.state == "recovery", "Guard blocks announced strike")
	command(sim, {"type": "hit", "target_id": "husk"})
	check(sim.snapshot().husk.hp == 1 and sim.snapshot().husk.state == "windup", "Recovery hit precedes next wind-up")
	command(sim, {"type": "guard"})
	command(sim, {"type": "hit", "target_id": "husk"})
	check(sim.snapshot().husk.hp == 0 and sim.snapshot().husk.intent.is_empty() and sim.snapshot().hp == 6, "Two safe counter cycles defeat Husk")
	# Retreat: next attack hits the old cell, not the new position.
	sim = Sim.new("BELL42")
	approach(sim)
	var old_cell: Array = sim.snapshot().pos
	var retreat: Dictionary = sim.apply({"type": "move", "step": "back"})
	check(sim.snapshot().hp == 6 and sim.snapshot().pos != old_cell, "Retreat avoids strike")
	var attack: Dictionary = retreat.events.filter(func(e): return e.type == "attack_resolved")[0]
	check(attack.cell == old_cell and attack.damage == 0, "Attack never retargets")
	attack.cell[0] = -9
	check(sim.snapshot().pos[0] != -9, "Returned event cannot mutate state")
	# Kill the attack source during wind-up: no posthumous damage.
	sim = Sim.new("BELL42")
	approach(sim)
	command(sim, {"type": "hit", "target_id": "husk"})
	check(sim.snapshot().hp == 5, "Unguarded wind-up hit deals one")
	command(sim, {"type": "wait"})
	var lethal: Dictionary = sim.apply({"type": "hit", "target_id": "husk"})
	check(sim.snapshot().husk.hp == 0 and sim.snapshot().hp == 5, "Lethal hit cancels pending attack")
	check(lethal.events.filter(func(e): return e.type == "attack_resolved").is_empty(), "No dead-source attack event")
	# Death freezes the sim, while new construction resets the same seed.
	sim = Sim.new("BELL42")
	approach(sim)
	for _i in range(20):
		if sim.snapshot().status == "playing":
			command(sim, {"type": "wait"})
	check(sim.snapshot().status == "lost" and sim.snapshot().hp == 0, "Repeated ignored tells cause death")
	before = JSON.stringify(sim.snapshot())
	check(not sim.apply({"type": "turn", "delta": 1}).accepted and JSON.stringify(sim.snapshot()) == before, "Terminal actions rejected without mutation")
	check(Sim.new("BELL42").snapshot().hp == 6 and Sim.new("BELL42").snapshot().revision == 0, "Restart is a fresh deterministic run")

func _reachable(definition: Dictionary, gate_blocked: bool) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array = [definition.start]
	seen[Vector2i(definition.start[0], definition.start[1])] = true
	var cursor := 0
	while cursor < queue.size():
		var cell: Array = queue[cursor]
		cursor += 1
		for d in Sim.DIRS:
			var next := Vector2i(cell[0] + d[0], cell[1] + d[1])
			if next.x < 0 or next.x >= definition.width or next.y < 0 or next.y >= definition.height:
				continue
			if definition.tiles[next.y * definition.width + next.x] == 1 or (gate_blocked and [next.x, next.y] == definition.gate):
				continue
			if not seen.has(next):
				seen[next] = true
				queue.append([next.x, next.y])
	return seen

func _generation() -> void:
	var layouts: Dictionary = {}
	var actions_min := 999
	var actions_max := 0
	for i in range(512):
		var seed := "TEST" + Gen.ALPHABET[i / 32] + Gen.ALPHABET[i % 32]
		var definition: Dictionary = Gen.new().generate(seed)
		check(definition == Gen.new().generate(seed), "Seed generation deterministic: " + seed)
		var connected := _reachable(definition, false)
		check(connected.size() == definition.tiles.count(0), "Every floor cell connected: " + seed)
		var locked := _reachable(definition, true)
		check(not locked.has(Vector2i(definition.exit[0], definition.exit[1])) and locked.has(Vector2i(definition.stone[0], definition.stone[1])) and locked.has(Vector2i(definition.plate[0], definition.plate[1])), "Gate cut and prerequisites: " + seed)
		layouts[JSON.stringify(definition.tiles)] = true
		var witness: Dictionary = Witness.build(seed)
		check(witness.ok, "Witness win: " + seed + " " + witness.reason)
		var replay = Sim.new(seed)
		for action in witness.actions:
			check(replay.apply(action).accepted, "Ordinary witness action accepted: " + seed)
		check(JSON.stringify(replay.snapshot()) == JSON.stringify(witness.snapshot), "Replay snapshot identical: " + seed)
		check(replay.snapshot().status == "won" and replay.snapshot().hp == 6 and replay.snapshot().gate.open and replay.snapshot().husk.hp == 0, "Full replay wins unhurt after mechanisms/combat: " + seed)
		actions_min = mini(actions_min, witness.actions.size())
		actions_max = maxi(actions_max, witness.actions.size())
	check(layouts.size() >= 12, "Constructive M1 generator has actual geometry variation")
	print("Generation: %d distinct raw layouts; witness commands %d-%d" % [layouts.size(), actions_min, actions_max])
	var fixed: Dictionary = Witness.build("BELL42")
	print("BELL42 witness: " + JSON.stringify(fixed.actions))

func _copy_widths() -> void:
	# Audit the actual quoted UI feedback strings against the native font.
	var source := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	var expression := RegEx.new()
	expression.compile('"([^"\\n]*)"')
	for found in expression.search_all(source):
		var value: String = found.get_string(1)
		if value.contains(" ") and not value.contains("res://") and not value.contains("%") and not value.contains("expected"):
			check(FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 146, "UI copy exceeds 146px: " + value)
