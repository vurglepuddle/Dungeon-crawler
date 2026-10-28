extends "res://scripts/gen/witness.gd"
## Reuses A's BFS/guard navigation; permits damaged, rearranged, partial runs.
## All changes to the sim go through apply(). Never edits a snapshot.
var observer: Callable

func setup(state: Dictionary, callback: Callable = Callable()) -> bool:
	sim = Sim.new(state.seed, state.floor_count)
	observer = callback
	return sim.restore_state(state)

func _raw(action: Dictionary) -> bool:
	var result: Dictionary = observer.call(sim, action) if observer.is_valid() else sim.apply(action)
	if not result.accepted:
		error = result.reason + " " + JSON.stringify(action)
		return false
	actions.append(action.duplicate(true))
	if sim.snapshot().status == "lost":
		error = "Recovery policy died"
		return false
	return true

func pickup_any(id: String) -> bool:
	var state: Dictionary = sim.snapshot()
	if state.items[id].location != "floor": return state.items[id].location in ["pack", "equip", "belt"]
	if state.items[id].floor != state.floor: return false
	if not go(state.items[id].pos): return false
	if sim.definition(id).slot != "belt" and not _space(): return false
	return _commit({"type":"pickup", "item_id":id})

func solve_floor() -> bool:
	var plate: Dictionary = _fixture("plate")
	var gate: Dictionary = _fixture("gate")
	if not gate.is_empty() and not gate.latched:
		var latch: Dictionary = _fixture("latch")
		# A player may have crossed without latching, or left a weight in place.
		if not go(latch.pos):
			error = ""
			var weight := ""
			var state: Dictionary = sim.snapshot()
			for id in state.pack:
				if sim.definition(id).tags.has("HEAVY"): weight = id; break
			if weight == "":
				for id in state.items:
					var item: Dictionary = state.items[id]
					if item.location == "floor" and item.floor == state.floor and sim.definition(id).tags.has("HEAVY"):
						if pickup_any(id): weight = id; break
						error = ""
			if weight == "" and state.equipment.hand != "" and sim.definition(state.equipment.hand).tags.has("HEAVY"):
				weight = state.equipment.hand
				if not _space() or not _commit({"type":"unequip", "slot":"hand"}): return false
			if weight == "": error = "No reachable weight found"; return false
			if not go(plate.pos, false) or not _commit({"type":"drop", "item_id":weight}) or not go(latch.pos): return false
		if not _fixture("gate").latched and not _commit({"type":"latch", "target_id":latch.id}): return false
	var lock: Dictionary = _fixture("lock")
	if not lock.is_empty() and not lock.open:
		if not pickup_any(lock.key_id) or not go(lock.pos) or not _commit({"type":"unlock", "target_id":lock.id}): return false
	return true

func finish(choice: String = "keep") -> Dictionary:
	error = ""
	if sim.snapshot().status != "playing": return {"status":sim.snapshot().status, "reason":"Terminal sample", "actions":actions}
	var count: int = sim.snapshot().floor_count
	if not sim.has_seal():
		for _floor_number in range(count + 1):
			if not solve_floor(): return result(false)
			if choice == "return" and sim.snapshot().floor == 1 and not sim.porter_state().restored:
				if pickup_any("bell_clapper"):
					var porter: Dictionary = _fixture("porter")
					if not go(porter.pos) or not _commit({"type":"return_item", "target_id":porter.id, "item_id":"bell_clapper"}): return result(false)
				error = ""
			if sim.snapshot().floor == count:
				if not pickup_any("f%d_seal" % count): return result(false)
				break
			var down: Dictionary = _fixture("stairs_down")
			if not go(down.pos) or not _commit({"type":"stairs", "target_id":down.id}): return result(false)
	for _floor_number in range(count + 1):
		if not solve_floor(): return result(false)
		if choice == "return" and sim.porter_state().restored:
			var lift: Dictionary = _fixture("lift")
			if count == 1:
				for fixture in sim.floor_data().fixtures:
					if fixture.id == "lift_deep": lift = fixture
			if not lift.is_empty() and (sim.snapshot().floor > 1 or count == 1):
				if not go(lift.pos) or not _commit({"type":"ride", "target_id":lift.id}): return result(false)
		if sim.snapshot().floor == 1:
			var exit: Dictionary = _fixture("exit")
			if not go(exit.pos) or not _commit({"type":"leave", "target_id":exit.id}): return result(false)
			return result(true)
		var up: Dictionary = _fixture("stairs_up")
		if not go(up.pos) or not _commit({"type":"stairs", "target_id":up.id}): return result(false)
	error = "Recovery floor budget exhausted"
	return result(false)

func result(ok: bool) -> Dictionary:
	return {"status":"reachable" if ok and sim.snapshot().status == "won" else "search_budget_exhausted", "reason":error, "actions":actions}
