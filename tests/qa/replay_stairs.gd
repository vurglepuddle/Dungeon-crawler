extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")

func replay(seed: String, count: int, actions: Array) -> Dictionary:
	var sim=Sim.new(seed,count)
	for action in actions:
		if not sim.apply(action).accepted: return {"overlap":false}
	var state: Dictionary=sim.snapshot()
	var overlap: bool=state.status=="playing" and state.floors[state.floor-1].actors.any(func(actor): return actor.hp>0 and actor.pos==state.pos)
	return {"overlap":overlap,"snapshot":state}

func _initialize() -> void:
	var minimize: bool=OS.get_cmdline_user_args().has("--minimize")
	var path: String="res://tests/qa/results/stair_overlap.json" if minimize else "res://tests/qa/repro_stairs.json"
	var record: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)))
	var actions: Array=record.actions
	if minimize:
		var chunks:=2
		while actions.size()>=2:
			var width:=ceili(float(actions.size())/chunks)
			var reduced:=false
			for start in range(0,actions.size(),width):
				var candidate: Array=actions.slice(0,start)+actions.slice(start+width)
				if replay(record.seed,record.count,candidate).overlap:
					actions=candidate; chunks=maxi(2,chunks-1); reduced=true; break
			if reduced: continue
			if chunks>=actions.size(): break
			chunks=mini(actions.size(),chunks*2)
		var ending: Dictionary=replay(record.seed,record.count,actions)
		var file:=FileAccess.open("res://tests/qa/repro_stairs.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"seed":record.seed,"count":record.count,"actions":actions,"ending_pos":ending.snapshot.pos,"ending_hp":ending.snapshot.hp},"\t")); file.close()
		print("Minimized stair overlap: ",actions.size()," ordinary accepted commands, ending ",ending.snapshot.pos," HP ",ending.snapshot.hp)
		quit(0)
	else:
		var sim=Sim.new(record.seed,record.count)
		for index in range(actions.size()-1):
			if not sim.apply(actions[index]).accepted:
				printerr("QA reproduction setup rejected at ",index); quit(1); return
		var before: String=sim.state_hash()
		var result: Dictionary=sim.apply(actions.back())
		var passed: bool=not result.accepted and sim.state_hash()==before
		print("QA occupied stair arrival must reject atomically: ","PASS" if passed else "FAIL")
		quit(0 if passed else 1)
