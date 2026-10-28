extends "res://tests/qa/adversarial.gd"

func step_absolute(bot, direction: int) -> bool:
	return bot._face(direction) and bot._commit({"type":"move","step":"fwd"})

func _initialize() -> void:
	rng.seed=1993
	for seed in ["BELL42","AAAAAA","999999","QDAA"]:
		context={"seed":seed,"count":2,"policy":"lure_husk_to_stair"}
		trace=[]
		var sim=Sim.new(seed,2)
		var state: Dictionary=sim.snapshot()
		if state.floors[0].landing[1]==1: continue
		var proof: Dictionary=Witness.build(seed,2,false,"keep")
		for action in proof.actions:
			if action.type=="hit": break
			act(sim,action)
		var bot=Bot.new(); bot.sim=sim; bot.observer=act
		print("Stair lure start ",seed," ",JSON.stringify({"pos":sim.snapshot().pos,"actor":sim.floor_data().actors[0],"landing":sim.floor_data().landing}))
		# Draw the guard into the entry room and go round it without hitting it.
		for direction in [2,2,2,2]: require(step_absolute(bot,direction),"LURE_SETUP")
		require(bot._commit({"type":"wait"}),"LURE_WAIT")
		for direction in [3,0,0,1,0,0,0]: require(step_absolute(bot,direction),"LURE_AROUND")
		print("Lure passed ",JSON.stringify({"pos":sim.snapshot().pos,"actor":sim.floor_data().actors[0]}))
		var lock: Dictionary=bot._fixture("lock")
		require(bot.pickup_any(lock.key_id),"LURE_KEY")
		require(bot.go(lock.pos) and bot._commit({"type":"unlock","target_id":lock.id}),"LURE_UNLOCK")
		var spine: int=sim.floor_data().start[0]
		require(bot.go([spine,1],false),"LURE_NORTH")
		if sim.floor_data().landing[1]==2: require(bot._commit({"type":"wait"}),"LURE_TO_TWO")
		require(step_absolute(bot,1),"LURE_EAST")
		while sim.snapshot().pos[1]<sim.floor_data().landing[1]: require(step_absolute(bot,2),"LURE_SOUTH")
		require(bot._face(3),"LURE_FACE")
		var before: Dictionary=sim.snapshot()
		print("Stair departure ",JSON.stringify({"pos":before.pos,"actor":before.floors[0].actors[0],"landing":before.floors[0].landing}))
		var down: Dictionary=bot._fixture("stairs_down")
		require(bot._commit({"type":"stairs","target_id":down.id}),"LURE_DOWN")
		var up: Dictionary=bot._fixture("stairs_up")
		require(bot._commit({"type":"stairs","target_id":up.id}),"LURE_UP")
		if findings.has("PLAYER_ACTOR_OVERLAP"):
			var file:=FileAccess.open("res://tests/qa/results/stair_overlap.json",FileAccess.WRITE)
			file.store_string(JSON.stringify({"seed":seed,"count":2,"actions":trace,"snapshot":sim.snapshot()},"\t")); file.close()
			save_probe(sim.snapshot(),true)
			home_probe(sim.snapshot())
			break
	var file:=FileAccess.open("res://tests/qa/results/boundaries.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"findings":findings,"stats":stats},"\t")); file.close()
	print("QA BOUNDARIES COMPLETE ",JSON.stringify({"checks":checks,"findings":findings,"stats":stats}))
	quit(1 if not findings.is_empty() else 0)
