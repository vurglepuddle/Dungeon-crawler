extends "res://tests/qa/deep_adversarial.gd"
## All hostile checkpoints are reached with public actions, then serialized for
## the separate writer/reader process test. No generated state is edited.
var checkpoints: Array=[]
var case_counts: Dictionary={}
var points_seen: Dictionary={}
var active_case: String=""
var capture_points:=true

func home_probe(state: Dictionary) -> void:
	capture_points=false
	super.home_probe(state)
	capture_points=true

func save_probe(state: Dictionary, disk: bool) -> void:
	capture_points=false
	super.save_probe(state,disk)
	capture_points=true

func point(sim, label: String) -> void:
	if not capture_points: return
	var key: String=context.seed+"/"+context.choice+"/"+label
	if points_seen.has(key): return
	points_seen[key]=true
	checkpoints.append({"context":context.duplicate(true),"point":label,"state":sim.snapshot(),"hash":sim.state_hash(),"actions":trace.duplicate(true)})

func act(sim, action: Dictionary) -> Dictionary:
	var before: Dictionary=sim.snapshot()
	if action.type=="leave": point(sim,"before_win")
	var outcome: Dictionary=super.act(sim,action)
	if outcome.accepted:
		var s: Dictionary=sim.snapshot()
		if s.floor==3:
			if before.floor!=3: point(sim,"floor_three_landing")
			if action.type=="burn": point(sim,"just_after_deep_burn")
			for actor in s.floors[2].actors:
				if actor.kind=="hound" and actor.state=="windup": point(sim,"mid_lunge")
			if s.equipment.body!="" and s.items[s.equipment.body].spent: point(sim,"spent_coat_deep")
			if s.hp==1: point(sim,"one_hp_deep")
		if action.type=="ring": point(sim,"after_ring")
		if s.status=="won": point(sim,"won")
		if s.status=="lost": point(sim,"lost")
	return outcome

func setup_case(seed: String, choice: String, label: String, tour: bool=false, stage: String="entry"):
	context={"seed":seed,"count":3,"choice":choice,"policy":label}; trace=[]; active_case=label
	case_counts[label]=case_counts.get(label,0)+1
	var proof: Dictionary=Witness.build(seed,3,tour,choice,tour)
	require(proof.ok,"EDGE_DEEP_PROOF",proof.reason)
	var sim=Sim.new(seed,3)
	for action in proof.actions:
		if stage=="husk_tell" and action.type=="hit" and action.target_id=="f3_husk": break
		if stage=="second_ghost" and action.type=="dispel" and action.target_id=="f2_ghost": break
		if action.type=="leave": point(sim,"before_win")
		act(sim,action)
		if stage=="entry" and sim.snapshot().floor==3: break
		if stage=="key" and action.type=="pickup" and action.item_id=="f3_key": break
		if stage=="seal" and sim.has_seal(): break
	var bot=Bot.new(); require(bot.setup(sim.snapshot(),act),"DEEP_EDGE_RESTORE")
	return bot

func finish_case(bot, label: String) -> void:
	home_probe(bot.sim.snapshot())
	var outcome: Dictionary=bot.finish(context.choice)
	# A failed planner is not proof of a game softlock. Keep it as unresolved.
	if outcome.status!="reachable": print("QA EDGE planner budget ",label," ",outcome.reason)
	else: case_counts["wins"]=case_counts.get("wins",0)+1
	save_probe(bot.sim.snapshot(),true)

func open_plate(bot) -> bool:
	var gate: Dictionary=bot._fixture("gate")
	if gate.is_empty() or gate.latched: return true
	var stone: String="f%d_stone" % bot.sim.snapshot().floor
	var plate: Dictionary=bot._fixture("plate")
	var latch: Dictionary=bot._fixture("latch")
	return bot.pickup_any(stone) and bot.go(plate.pos,false) and bot._commit({"type":"drop","item_id":stone}) and bot.go(latch.pos) and bot._commit({"type":"latch","target_id":latch.id})

func travel_to_three(bot) -> bool:
	while bot.sim.snapshot().floor<3:
		if not bot.solve_floor(): return false
		if bot.sim.snapshot().floor==1:
			if not bot.pickup_any("bell_clapper"): return false
			if context.choice=="return":
				var porter: Dictionary=bot._fixture("porter")
				if not bot.go(porter.pos) or not bot._commit({"type":"return_item","item_id":"bell_clapper","target_id":porter.id}): return false
			else:
				if not bot._commit({"type":"equip","item_id":"bell_clapper"}): return false
		var down: Dictionary=bot._fixture("stairs_down")
		if not bot.go(down.pos) or not bot._commit({"type":"stairs","target_id":down.id}): return false
	return true

func spend_early(seed: String, choice: String, food: bool):
	context={"seed":seed,"count":3,"choice":choice,"policy":"eat_early" if food else "spent_coat_hound"}; trace=[]
	var bot=Bot.new(); bot.setup(Sim.new(seed,3).snapshot(),act)
	if food:
		for id in ["f1_bread_3","f1_tonic_4"]: require(bot.pickup_any(id),"EARLY_FOOD_PICKUP")
	else:
		require(bot.pickup_any("f1_coat") and bot._commit({"type":"equip","item_id":"f1_coat"}),"EARLY_COAT")
	require(bot.go(bot.sim.floor_data().start,false) and bot._face(0),"EARLY_REJOIN")
	var proof: Dictionary=Witness.build(seed,3,false,choice)
	for action in proof.actions:
		if action.type=="hit": break
		require(bot._raw(action),"EARLY_APPROACH")
	for _beat in range(32):
		if (food and bot.sim.snapshot().hp<=1) or (not food and bot.sim.snapshot().items.f1_coat.spent): break
		bot._raw({"type":"wait"})
	if food:
		require(bot.sim.snapshot().hp==1,"EARLY_ONE_HP")
		for id in bot.sim.snapshot().pack.duplicate():
			if bot.sim.definition(id).heal<=0: continue
			require(bot._raw({"type":"eat","item_id":id}),"EARLY_EAT")
			for _beat in range(24):
				if bot.sim.snapshot().hp<=1: break
				bot._raw({"type":"wait"})
		require(bot.sim.snapshot().hp==1,"EARLY_FOOD_SPENT_ONE_HP")
	else: require(bot.sim.snapshot().items.f1_coat.spent and bot.sim.snapshot().hp==6,"EARLY_COAT_SPENT")
	require(travel_to_three(bot),"EARLY_REACHED_THREE",bot.error)
	case_counts[context.policy]=case_counts.get(context.policy,0)+1
	return bot

func _initialize() -> void:
	rng.seed=411993; disk_path="user://qa_m4a_deep_edges.json"
	var amount:=16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	for index in range(amount):
		var seed: String="QE4"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		for choice in ["keep","return"]:
			# Deliberately absorb repeated deep tells. Death is an expected outcome,
			# never classified as a softlock. Read the actual actor each time.
			for kind in ["husk","hound","ghost"]:
				var bot=setup_case(seed,choice,"take_"+kind,false,"husk_tell" if kind=="husk" else "entry")
				if kind!="husk": require(open_plate(bot),"DEEP_TELL_PLATE")
				if kind=="ghost":
					var cord: Dictionary=bot._fixture("cord")
					var edge: String=bot._acquire_tag("EDGE")
					require(edge!="" and bot.go(cord.pos) and bot._commit({"type":"cut","target_id":cord.id,"item_id":edge}),"APPROACH_GHOST_CUT")
				var actor: Dictionary=bot.sim.floor_data().actors.filter(func(a): return a.kind==kind)[0]
				require(bot.go(actor.pos),"APPROACH_DEEP_TELL",bot.error)
				for _beat in range(32):
					if bot.sim.snapshot().status!="playing" or bot.sim.snapshot().hp==1: break
					act(bot.sim,{"type":"wait"})
				require(bot.sim.snapshot().status=="lost" or bot.sim.snapshot().hp==1,"TAKE_TELL_TERMINATES",kind)
				case_counts["intentional_deaths"]=case_counts.get("intentional_deaths",0)+int(bot.sim.snapshot().status=="lost")
				save_probe(bot.sim.snapshot(),true)

			var bot=spend_early(seed,choice,false)
			require(open_plate(bot),"SPENT_HOUND_PLATE")
			var hound: Dictionary=bot.sim.floor_data().actors.filter(func(a): return a.kind=="hound")[0]
			require(bot.go(hound.pos),"SPENT_MEET_HOUND",bot.error)
			point(bot.sim,"spent_coat_meets_hound")
			finish_case(bot,"spent_coat_hound")
			bot=spend_early(seed,choice,true)
			require(bot.sim.snapshot().pack.all(func(id): return bot.sim.definition(id).heal==0),"NO_CARRIED_HEALS_ENTRY_THREE")
			finish_case(bot,"early_food_one_hp")

			bot=setup_case(seed,choice,"burn_cut_toss_everything")
			require(open_plate(bot),"CAPABILITY_PLATE")
			require(bot.capability_rooms(),"DEEP_CAPABILITY_ROOMS",bot.error)
			for fixture in bot.sim.floor_data().fixtures:
				if fixture.type in ["web","cord"]: require(fixture.open,"ALL_DEEP_BARRIERS_OPEN")
			for slot in ["hand","body"]:
				if bot.sim.snapshot().equipment[slot]!="": require(bot._space() and bot._commit({"type":"unequip","slot":slot}),"STRIP_DEEP")
			for id in bot.sim.snapshot().pack.duplicate():
				var tossed:=false
				for direction in range(4):
					if not bot._face(direction): continue
					var outcome: Dictionary=act(bot.sim,{"type":"toss","item_id":id})
					if outcome.accepted: tossed=true; break
				require(tossed,"DEEP_TOSS_OWNED",id)
			require(bot.sim.snapshot().pack.is_empty() and bot.sim.snapshot().equipment.hand=="","DEEP_EMPTY_PACK")
			finish_case(bot,"burn_cut_toss_everything")

			for stage in ["key","seal"]:
				bot=setup_case(seed,choice,"protected_"+stage,false,stage)
				var id: String="f3_"+stage
				for verb in ["drop","toss","eat","equip"]: require(not act(bot.sim,{"type":verb,"item_id":id}).accepted,"DEEP_PROTECTED_REJECT")
				require(bot.go(bot.sim.floor_data().start,false),"WALK_AWAY_BELT",bot.error)
				finish_case(bot,"protected_"+stage)

			bot=setup_case(seed,choice,"full_pack_store",true)
			# The full-pack tour brings a torch and eight pockets to floor three.
			require(bot.sim.snapshot().pack.size()==8,"FULL_PACK_ENTRY_THREE")
			var torch: String=""
			for id in bot.sim.snapshot().pack+[bot.sim.snapshot().equipment.hand]:
				if id!="" and bot.sim.snapshot().items[id].kind=="torch": torch=id; break
			if torch=="":
				torch="f3_torch"
				require(bot._space() and bot.pickup_any(torch),"FULL_PACK_GET_DEEP_TORCH")
			require(torch!="","FULL_PACK_HAS_TORCH")
			var web: Dictionary=bot._fixture("web")
			if not bot.sim.snapshot().items[torch].lit:
				var brazier: Dictionary=bot._fixture("brazier")
				require(bot.go(brazier.pos) and bot._commit({"type":"light","item_id":torch,"target_id":brazier.id}),"FULL_LIGHT")
			require(bot.go(web.pos) and bot._commit({"type":"burn","item_id":torch,"target_id":web.id}),"FULL_BURN")
			require(bot.go(bot.sim.snapshot().items.f3_store_tonic.pos),"FULL_REACH_STORE",bot.error)
			require(not act(bot.sim,{"type":"pickup","item_id":"f3_store_tonic"}).accepted,"FULL_STORE_REJECTS_AT_CAPACITY")
			require(bot._space() and bot._commit({"type":"pickup","item_id":"f3_store_tonic"}),"FULL_STORE_RECOVERS")
			point(bot.sim,"full_pack_storeroom")
			finish_case(bot,"full_pack_store")

			bot=setup_case(seed,choice,"stair_dance")
			for _dance in range(8):
				var up: Dictionary=bot._fixture("stairs_up")
				require(bot.go(up.pos) and bot._commit({"type":"stairs","target_id":up.id}),"DEEP_DANCE_UP")
				var down: Dictionary=bot._fixture("stairs_down")
				require(bot.go(down.pos) and bot._commit({"type":"stairs","target_id":down.id}),"DEEP_DANCE_DOWN")
			finish_case(bot,"stair_dance")
		print("QA DEEP EDGES ",index+1,"/",amount," findings ",findings.size()," checkpoints ",checkpoints.size())
	var file:=FileAccess.open("res://tests/qa/results/deep_edges.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"findings":findings,"stats":stats,"cases":case_counts,"checkpoints":checkpoints},"\t")); file.close()
	print("QA DEEP EDGES COMPLETE ",JSON.stringify({"cases":case_counts,"findings":findings,"stats":stats,"checkpoints":checkpoints.size()}))
	quit(1 if not findings.is_empty() else 0)
