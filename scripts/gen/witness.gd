class_name UndercroftWitness
extends RefCounted
## Ordinary commands only. Generator acceptance and regression tests share this.
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")

static func build(seed: String) -> Dictionary:
	var generated: Dictionary = Gen.new().generate(seed)
	if not generated.ok:
		return {"ok": false, "reason": generated.error, "actions": []}
	var sim = Sim.new(seed)
	var commands: Array = []
	var initial_hp: int = sim.snapshot().hp
	var actions: Array = [{"type": "pickup", "item_id": "stone"},
		{"type": "move", "step": "fwd"},
		{"type": "place", "item_id": "stone", "target_id": "plate"}]
	for action in actions:
		if not _commit(sim, action, commands):
			return {"ok": false, "reason": "Entry interaction rejected", "actions": commands}
	# Follow the embedded route, defeating the blocking Husk with guard/recovery.
	for cell in generated.route.slice(2, generated.route.size() - 1):
		var state: Dictionary = sim.snapshot()
		var delta: Array = [cell[0] - state.pos[0], cell[1] - state.pos[1]]
		var wanted: int = Sim.DIRS.find(delta)
		if wanted < 0:
			return {"ok": false, "reason": "Nonadjacent witness route", "actions": commands}
		while sim.snapshot().facing != wanted:
			if not _commit(sim, {"type": "turn", "delta": 1}, commands):
				return {"ok": false, "reason": "Turn rejected", "actions": commands}
		if cell == generated.husk:
			while sim.snapshot().husk.hp > 0:
				var command := {"type": "guard"} if sim.snapshot().husk.state == "windup" else {"type": "hit", "target_id": "husk"}
				if not _commit(sim, command, commands):
					return {"ok": false, "reason": "Combat rejected", "actions": commands}
		if not _commit(sim, {"type": "move", "step": "fwd"}, commands):
			return {"ok": false, "reason": "Walk rejected", "actions": commands}
	# The final route cell is the exit, directly ahead after the northbound arm.
	while sim.snapshot().facing != 0:
		if not _commit(sim, {"type": "turn", "delta": 1}, commands):
			return {"ok": false, "reason": "Final turn rejected", "actions": commands}
	if not _commit(sim, {"type": "leave", "target_id": "exit"}, commands):
		return {"ok": false, "reason": "Exit rejected", "actions": commands}
	var ending: Dictionary = sim.snapshot()
	return {"ok": ending.status == "won" and ending.hp == initial_hp,
		"reason": "", "actions": commands, "snapshot": ending}

static func _commit(sim, action: Dictionary, commands: Array) -> bool:
	var result: Dictionary = sim.apply(action)
	if not result.accepted:
		return false
	commands.append(action.duplicate(true))
	return true
