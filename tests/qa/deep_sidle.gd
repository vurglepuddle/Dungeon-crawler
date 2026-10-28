extends "res://tests/qa/deep_edges.gd"
## Lure a living floor-two Husk onto the downward landing, descend beside it,
## and return by SIDLE. This is a public-action version of the old stair bug.
func lure_plate(bot) -> bool:
	var plate: Dictionary=bot._fixture("plate")
	if not bot.pickup_any("f2_stone") or not bot.go(plate.pos,false) or not bot._raw({"type":"drop","item_id":"f2_stone"}) or not bot._face(0): return false
	for _step in range(3):
		if not bot._raw({"type":"move","step":"fwd"}): return false
	if not bot._face(2): return false
	for _step in range(4):
		if not bot._raw({"type":"move","step":"fwd"}): return false
	if not bot._raw({"type":"wait"}) or not bot._face(0) or not bot._raw({"type":"move","step":"strafe_l"}): return false
	for _step in range(2):
		if not bot._raw({"type":"move","step":"fwd"}): return false
	if not bot._face(1) or not bot._raw({"type":"move","step":"fwd"}): return false
	var latch: Dictionary=bot._fixture("latch")
	return bot.go(latch.pos) and bot._commit({"type":"latch","target_id":latch.id})

func _initialize() -> void:
	var amount:=64; var exercised:=0; var skipped:=0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	for index in range(amount):
		var seed: String="QS4"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		var generated=Sim.new(seed,3)
		var f: Dictionary=generated.snapshot().floors[1]
		if f.landing[1]<2 or f.layout.loop_top!=6 or not f.layout.keyed or not f.layout.weight: skipped+=2; continue
		for choice in ["keep","return"]:
			context={"seed":seed,"count":3,"choice":choice,"policy":"occupied_deep_boundary"}; trace=[]
			var bot=Bot.new(); bot.setup(generated.snapshot(),act)
			if not bot.solve_floor() or not bot.pickup_any("bell_clapper"): continue
			if choice=="return":
				var porter: Dictionary=bot._fixture("porter")
				if not bot.go(porter.pos) or not bot._commit({"type":"return_item","item_id":"bell_clapper","target_id":porter.id}): continue
			var down: Dictionary=bot._fixture("stairs_down")
			if not bot.go(down.pos) or not bot._commit({"type":"stairs","target_id":down.id}): continue
			if not lure_plate(bot): print("SIDLE setup plate ",seed," ",bot.error); continue
			var x: int=f.start[0]; var branch: int=f.layout.branch
			if not bot.go([branch,9],false): continue
			var lock: Dictionary=bot._fixture("lock")
			if not bot.pickup_any(lock.key_id) or not bot.go([branch,6],false) or not bot.go([x,6],false): continue
			if not bot.go(lock.pos) or not bot._commit({"type":"unlock","target_id":lock.id}): continue
			# The side loop broke sight. Rejoin the spine within four cells and
			# let the Husk close before leading it through the now-open lock.
			if not bot.go([x,7],false): continue
			for _beat in range(8):
				if bot.sim.floor_data().actors[0].state=="windup": break
				bot._raw({"type":"guard"})
			if not bot.go([x,f.landing[1]-1],false): continue
			for _beat in range(8):
				if bot.sim.floor_data().actors[0].pos==f.landing: break
				bot._raw({"type":"guard"})
			if bot.sim.floor_data().actors[0].hp<=0 or bot.sim.floor_data().actors[0].pos!=f.landing:
				print("SIDLE setup no lure ",seed," ",choice," landing ",f.landing," pos ",bot.sim.snapshot().pos," actor ",bot.sim.floor_data().actors[0])
				skipped+=1; continue
			if not bot._face(0) or not bot._raw({"type":"move","step":"strafe_l"}) or not bot._face(2) or not bot._raw({"type":"move","step":"fwd"}) or not bot._face(1): continue
			down=bot._fixture("stairs_down")
			if not bot._raw({"type":"stairs","target_id":down.id}): continue
			for _dance in range(4):
				var up: Dictionary=bot._fixture("stairs_up")
				require(bot.go(up.pos),"SIDLE_APPROACH_THREE")
				require(not act(bot.sim,{"type":"stairs","target_id":up.id}).accepted,"OCCUPIED_DEEP_STAIRS_REJECT")
				require(bot.sim.fixture_actions().any(func(e): return e.label=="SIDLE" and e.action.type=="squeeze"),"OCCUPIED_DEEP_SIDLE_VISIBLE")
				require(bot._raw({"type":"squeeze","target_id":up.id}),"OCCUPIED_DEEP_SIDLE_ACCEPTS")
				require(bot.sim.snapshot().floor==2 and bot.sim.snapshot().pos!=f.landing,"SIDLE_DISTINCT_CELL")
				down=bot._fixture("stairs_down")
				require(bot.go(down.pos) and bot._raw({"type":"stairs","target_id":down.id}),"SIDLE_DANCE_BACK")
			exercised+=1
			home_probe(bot.sim.snapshot())
		print("QA DEEP SIDLE ",index+1,"/",amount," exercised ",exercised," findings ",findings.size())
	require(exercised>=4,"SIDLE_COVERAGE","Need at least four actual occupied boundary cases")
	var file:=FileAccess.open("res://tests/qa/results/deep_sidle.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"findings":findings,"stats":stats,"exercised":exercised,"skipped":skipped},"\t")); file.close()
	print("QA DEEP SIDLE COMPLETE ",exercised," cases ",findings.size()," findings")
	quit(1 if not findings.is_empty() else 0)
