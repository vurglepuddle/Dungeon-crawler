extends "res://tests/qa/recovery_bot.gd"
## QA policies only. Reuses A's navigation/tour and all actual sim actions.
var mode: String="safe"
var accepted_guard_count: int=0

func _raw(action: Dictionary) -> bool:
	var ok: bool=super._raw(action)
	if ok and action.type=="guard": accepted_guard_count+=1
	return ok

func _commit(action: Dictionary) -> bool:
	if mode=="safe": return super._commit(action)
	if action.type=="stairs":
		for entry in sim.fixture_actions():
			if entry.action.type=="squeeze" and entry.action.target_id==action.target_id: action=entry.action.duplicate(); break
	if mode in ["greedy","never_guard"] and action.type!="turn":
		var state: Dictionary=sim.snapshot()
		if state.hp<=3:
			for id in state.pack:
				var reserved_food: bool=sim.definition(id).tags.has("FOOD") and sim.floor_data().actors.any(func(a): return a.kind=="hound" and a.hp>0 and a.state!="peaceful")
				if sim.definition(id).heal>0 and not reserved_food and id!=action.get("item_id",""):
					if not _raw({"type":"eat","item_id":id}): return false
					break
	# Aggressive policies ignore announced attacks. They do not receive the
	# base witness's implicit GUARD or its six-HP assertion.
	if action.type=="move":
		var s: Dictionary=sim.snapshot()
		var offset: int={"fwd":0,"back":2,"strafe_l":3,"strafe_r":1}[action.step]
		var d: Array=Sim.DIRS[(s.facing+offset)%4]
		if not sim.can_walk([s.pos[0]+d[0],s.pos[1]+d[1]]): return true
	return _raw(action)

func total_food(state: Dictionary, carried_only: bool) -> int:
	var count:=0
	for item in state.items.values():
		if item.location in ["consumed","returned"]: continue
		if carried_only and item.location not in ["pack","equip","belt"]: continue
		if Catalog.ITEMS[item.kind].tags.has("FOOD"): count+=1
	return count
