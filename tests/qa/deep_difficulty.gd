extends "res://tests/qa/deep_adversarial.gd"
const DeepBot=preload("res://tests/qa/deep_bot.gd")
var seal_hp: int=-1

func act(sim, action: Dictionary) -> Dictionary:
	var outcome: Dictionary=super.act(sim,action)
	if seal_hp<0 and sim.has_seal(): seal_hp=sim.snapshot().hp
	return outcome

func _initialize() -> void:
	var amount:=128
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	var groups: Dictionary={}; var records: Array=[]
	for index in range(amount):
		var seed: String="QH4"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		for choice in ["keep","return"]:
			for mode in ["careless","greedy","never_guard"]:
				context={"seed":seed,"count":3,"choice":choice,"policy":mode}; trace=[]; seal_hp=-1
				var bot=DeepBot.new(); bot.mode=mode
				bot.observer=act
				var initial: Dictionary={}
				# Never-guard is a prepared aggressive tourist: choose the available
				# club and coat before following the tour, with no tell reactions.
				if mode=="never_guard":
					bot.setup(Sim.new(seed,3).snapshot(),act)
					for id in ["f1_club","f1_coat"]:
						if bot.sim.snapshot().items.has(id) and bot.pickup_any(id): bot._commit({"type":"equip","item_id":id})
					initial=bot.sim.snapshot()
				var result: Dictionary=bot.run(seed,3,mode!="careless",choice,initial,mode!="careless")
				var state: Dictionary=bot.sim.snapshot()
				if mode=="never_guard": require(bot.accepted_guard_count==0,"NEVER_GUARD_POLICY")
				var key: String=mode+"/"+choice
				if not groups.has(key): groups[key]={"runs":0,"wins":0,"deaths":0,"inconclusive":0,"death_floors":{},"seal_hp":{},"win_food":{}}
				var group: Dictionary=groups[key]; group.runs+=1
				var outcome: String="win" if state.status=="won" else "death" if state.status=="lost" else "inconclusive"
				if outcome=="win":
					group.wins+=1
					var food: String=str(bot.total_food(state,true)); group.win_food[food]=group.win_food.get(food,0)+1
				elif outcome=="death":
					group.deaths+=1
					var floor_key: String=str(state.floor); group.death_floors[floor_key]=group.death_floors.get(floor_key,0)+1
				else: group.inconclusive+=1
				if seal_hp>=0:
					var hp: String=str(seal_hp); group.seal_hp[hp]=group.seal_hp.get(hp,0)+1
				records.append({"seed":seed,"choice":choice,"policy":mode,"outcome":outcome,"floor":state.floor,"hp":state.hp,"seal_hp":seal_hp,"food":bot.total_food(state,true),"reason":result.reason,"guards":bot.accepted_guard_count,"actions":trace.duplicate(true)})
		if index%8==0: print("QA DIFFICULTY ",index+1,"/",amount," ",JSON.stringify(groups))
	var file:=FileAccess.open("res://tests/qa/results/deep_difficulty.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"groups":groups,"records":records,"checks":checks,"stats":stats,"findings":findings},"\t")); file.close()
	print("QA DIFFICULTY COMPLETE ",JSON.stringify(groups)," findings ",findings.size())
	quit(1 if not findings.is_empty() else 0)
