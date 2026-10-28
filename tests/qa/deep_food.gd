extends "res://tests/qa/deep_edges.gd"
## Exhaust every bread/bone offered on floors 1 and 2 before descending to 3.
## The still-living second-floor Ghost supplies a public, one-damage HP sink.
func gather_food(bot) -> bool:
	for id in bot.sim.snapshot().items:
		var item: Dictionary=bot.sim.snapshot().items[id]
		if item.location=="floor" and item.floor==bot.sim.snapshot().floor and bot.sim.definition(id).tags.has("FOOD"):
			if not bot.pickup_any(id): return false
	return true

func eat_down(bot) -> bool:
	var ghost: Dictionary=bot.sim.floor_data().actors.filter(func(a): return a.kind=="ghost")[0]
	if not bot.go(ghost.pos): return false
	for _beat in range(32):
		if bot.sim.snapshot().hp<=1: break
		if not bot._raw({"type":"wait"}): return false
	for id in bot.sim.snapshot().pack.duplicate():
		if not bot.sim.definition(id).tags.has("FOOD"): continue
		if not bot._raw({"type":"eat","item_id":id}): return false
		for _beat in range(8):
			if bot.sim.snapshot().hp<=1: break
			if not bot._raw({"type":"wait"}): return false
	return bot.sim.snapshot().hp==1

func _initialize() -> void:
	rng.seed=41993; disk_path="user://qa_m4a_deep_food.json"
	var amount:=16; var exhausted:=0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	for index in range(amount):
		var seed: String="QF4"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		for choice in ["keep","return"]:
			var bot=setup_case(seed,choice,"all_early_food",true,"second_ghost")
			require(bot.sim.snapshot().floor==2,"FOOD_GHOST_ANCHOR")
			for id in bot.sim.snapshot().pack.duplicate():
				if not bot.sim.definition(id).tags.has("FOOD"): require(bot._commit({"type":"drop","item_id":id}),"FOOD_CLEAR_POCKETS")
			require(gather_food(bot) and eat_down(bot),"FOOD_SECOND_BATCH",bot.error)
			var up: Dictionary=bot._fixture("stairs_up")
			require(bot.go(up.pos) and bot._commit({"type":"stairs","target_id":up.id}),"FOOD_RETURN_ONE")
			require(gather_food(bot),"FOOD_GATHER_FIRST",bot.error)
			var down: Dictionary=bot._fixture("stairs_down")
			require(bot.go(down.pos) and bot._commit({"type":"stairs","target_id":down.id}),"FOOD_BACK_SECOND")
			require(eat_down(bot),"FOOD_FIRST_BATCH",bot.error)
			for item in bot.sim.snapshot().items.values():
				if item.floor in [1,2] and bot.sim.definition(item.id).tags.has("FOOD"): require(item.location=="consumed","NO_EARLY_WORLD_FOOD",item.id)
			down=bot._fixture("stairs_down")
			require(bot.go(down.pos) and bot._commit({"type":"stairs","target_id":down.id}),"NO_FOOD_REACH_THREE")
			require(bot.sim.snapshot().hp==1 and bot.sim.snapshot().floor==3,"EXHAUSTED_ONE_HP_ENTRY")
			home_probe(bot.sim.snapshot()); exhausted+=1
		print("QA DEEP FOOD ",index+1,"/",amount," findings ",findings.size())
	var file:=FileAccess.open("res://tests/qa/results/deep_food.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"findings":findings,"stats":stats,"exhausted":exhausted},"\t")); file.close()
	print("QA DEEP FOOD COMPLETE ",exhausted," trajectories ",findings.size()," findings")
	quit(1 if not findings.is_empty() else 0)
