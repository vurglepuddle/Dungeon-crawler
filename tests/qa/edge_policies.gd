extends "res://tests/qa/adversarial.gd"

func fresh(label: String):
	context={"seed":"BELL42","count":2,"policy":label,"choice":"keep"}
	trace=[]
	var bot=Bot.new()
	require(bot.setup(Sim.new("BELL42",2).snapshot(),act),"EDGE_SETUP")
	return bot

func finish_check(bot) -> void:
	var outcome: Dictionary=bot.finish(context.get("choice","keep"))
	require(outcome.status=="reachable","EDGE_WIN",outcome.reason)
	require(bot.sim.snapshot().status=="won","EDGE_TERMINAL")
	save_probe(bot.sim.snapshot(),true)
	# Finished simulations must reject everything, preserving the complete hash.
	for action in [{"type":"wait"},{"type":"turn","delta":1},{"type":"drop","item_id":"f2_seal"}]:
		require(not act(bot.sim,action).accepted,"TERMINAL_REJECTION")

func _initialize() -> void:
	rng.seed=19931028
	var bot=fresh("body_plate_nonheavy_heavy_recovery")
	var plate: Dictionary=bot._fixture("plate")
	var gate: Dictionary=bot._fixture("gate")
	require(bot.pickup_any("f1_stone"),"PLATE_STONE")
	require(bot.go(plate.pos,false),"PLATE_BODY")
	require(bot._fixture("gate").open,"BODY_OPENS_GATE")
	save_probe(bot.sim.snapshot(),true)
	require(bot._face(0) and bot._commit({"type":"move","step":"back"}),"STEP_OFF_PLATE")
	require(not bot._fixture("gate").open,"BODY_RELEASE_CLOSES_GATE")
	require(bot._commit({"type":"place","item_id":"f1_stone","target_id":plate.id}),"PLACE_FROM_FRONT")
	require(bot._fixture("gate").open,"PLACED_WEIGHT_OPENS")
	require(bot._commit({"type":"pickup","item_id":"f1_stone"}),"RECOVER_BEFORE_LATCH")
	require(not bot._fixture("gate").open,"RECOVERED_WEIGHT_CLOSES")
	require(bot._commit({"type":"unequip","slot":"hand"}),"UNWIELD_KNIFE")
	require(bot.go(plate.pos,false) and bot._commit({"type":"drop","item_id":"knife_start"}),"DROP_NONHEAVY_ON_BODY_PLATE")
	require(bot._face(0) and bot._commit({"type":"move","step":"back"}),"LEAVE_NONHEAVY_PLATE")
	require(not bot._fixture("gate").open,"NONHEAVY_DOES_NOT_HOLD")
	require(bot.go(plate.pos,false) and bot._commit({"type":"drop","item_id":"f1_stone"}),"DROP_HEAVY_ON_PLATE")
	require(bot._face(0) and bot._commit({"type":"move","step":"back"}),"LEAVE_WEIGHTED_PLATE")
	require(bot._fixture("gate").open,"HEAVY_HOLDS_GATE")
	require(bot.solve_floor(),"SOLVE_WEIGHTED_FLOOR")
	require(bot.pickup_any("f1_stone"),"RECOVER_AFTER_LATCH")
	require(bot._fixture("gate").latched and bot._fixture("gate").open,"RECOVERED_LATCH_STAYS_OPEN")
	home_probe(bot.sim.snapshot())
	finish_check(bot)

	bot=fresh("eat_every_carried_heal_drop_everything_one_hp")
	require(bot.pickup_any("f1_bread_3") and bot.pickup_any("f1_tonic_4"),"COLLECT_HEALS")
	require(bot.go(bot.sim.floor_data().start,false) and bot._face(0),"HUNGER_REJOIN_ROUTE")
	var proof: Dictionary=Witness.build("BELL42",2,false,"keep")
	for action in proof.actions:
		if action.type=="hit": break
		require(bot._raw(action),"HUNGER_APPROACH")
	for _beat in range(24):
		if bot.sim.snapshot().hp<=1: break
		require(bot._raw({"type":"wait"}),"TAKE_HITS_TO_ONE")
	require(bot.sim.snapshot().hp==1,"REACHED_ONE_HP")
	save_probe(bot.sim.snapshot(),true)
	var food: Array=bot.sim.snapshot().pack.filter(func(id): return bot.sim.definition(id).heal>0)
	for id in food:
		require(bot._raw({"type":"eat","item_id":id}),"EAT_ALL_CARRIED_FOOD")
		for _beat in range(24):
			if bot.sim.snapshot().hp<=1: break
			require(bot._raw({"type":"wait"}),"TAKE_HITS_AGAIN")
		require(bot.sim.snapshot().hp==1,"REACHED_ONE_HP_AGAIN")
	for slot in ["hand","body"]:
		if bot.sim.snapshot().equipment[slot]!="": require(bot._commit({"type":"unequip","slot":slot}),"STRIP_EQUIPMENT")
	for id in bot.sim.snapshot().pack: require(bot._commit({"type":"drop","item_id":id}),"DROP_EVERYTHING")
	require(bot.sim.snapshot().hp==1 and bot.sim.snapshot().pack.is_empty() and bot.sim.snapshot().equipment.hand=="","ONE_HP_EMPTY_PACK")
	home_probe(bot.sim.snapshot())
	finish_check(bot)
	for id in food: require(bot.sim.snapshot().items[id].location=="consumed","CONSUMED_FOOD_PERSISTS")

	bot=fresh("spent_coat_exchange_does_not_recharge")
	require(bot.pickup_any("f1_coat") and bot._commit({"type":"equip","item_id":"f1_coat"}),"WEAR_COAT")
	require(bot.go(bot.sim.floor_data().start,false) and bot._face(0),"COAT_REJOIN_ROUTE")
	for action in proof.actions:
		if action.type=="hit": break
		require(bot._raw(action),"COAT_APPROACH")
	for _beat in range(24):
		if bot.sim.snapshot().items.f1_coat.spent: break
		require(bot._raw({"type":"wait"}),"ABSORB_COAT_BLOW")
	require(bot.sim.snapshot().items.f1_coat.spent,"COAT_SPENT_AFTER_BLOW")
	require(bot.sim.snapshot().hp==6,"COAT_ABSORBS_ONCE")
	require(bot._commit({"type":"unequip","slot":"body"}) and bot._commit({"type":"equip","item_id":"f1_coat"}),"SWAP_SPENT_COAT")
	for _beat in range(24):
		if bot.sim.snapshot().hp<6: break
		require(bot._raw({"type":"wait"}),"SPENT_COAT_TAKES_DAMAGE")
	require(bot.sim.snapshot().hp<6,"DAMAGE_THROUGH_SPENT_COAT")
	require(bot.sim.snapshot().items.f1_coat.spent,"COAT_REMAINS_SPENT")
	finish_check(bot)

	bot=fresh("ring_drop_stairs_late_return_bidirectional_lift")
	var home: Dictionary=bot._fixture("lift")
	require(not act(bot.sim,{"type":"ride","target_id":home.id}).accepted,"SLEEPING_LIFT_REJECTS")
	var ring_proof: Dictionary=Witness.build("BELL42",2,false,"ring")
	for action in ring_proof.actions:
		require(bot._raw(action),"RING_ROUTE")
		if action.type=="ring": break
	require(not bot.sim.ring_ready(),"RING_SPENT")
	save_probe(bot.sim.snapshot(),true)
	require(bot._commit({"type":"unequip","slot":"hand"}),"UNWIELD_CLAPPER")
	require(bot._commit({"type":"drop","item_id":"bell_clapper"}),"DROP_CLAPPER")
	require(bot.pickup_any("bell_clapper") and bot._commit({"type":"equip","item_id":"bell_clapper"}),"REPICK_EQUIP_CLAPPER")
	require(not act(bot.sim,{"type":"ring","item_id":"bell_clapper"}).accepted and not bot.sim.ring_ready(),"NO_ITEM_CHARGE_REFRESH")
	require(bot.sim.snapshot().floor==2,"FIRST_RING_ON_SECOND_FLOOR")
	for _roundtrip in range(6):
		var up: Dictionary=bot._fixture("stairs_up")
		require(bot.go(up.pos) and bot._commit({"type":"stairs","target_id":up.id}),"REPEATED_UP")
		require(bot.sim.snapshot().floors[1].bell_rung,"INACTIVE_CHARGE_PERSISTS")
		require(bot._commit({"type":"stairs","target_id":"f1_down"}),"REPEATED_DOWN")
		require(not bot.sim.ring_ready(),"NO_STAIRS_RING_REFRESH")
	home_probe(bot.sim.snapshot())
	# Bring the Seal all the way home before restoring the already-used clapper.
	var completion: Dictionary=bot.finish("keep")
	require(completion.status=="reachable","PREPARE_LATE_RETURN")
	var saved_actions: Array=trace.duplicate(true)
	var live=Sim.new("BELL42",2)
	trace=[]
	for action in saved_actions:
		if action.type=="leave": break
		act(live,action)
	bot=Bot.new(); bot.sim=live; bot.observer=act
	var porter: Dictionary=bot._fixture("porter")
	require(bot.go(porter.pos) and bot._commit({"type":"return_item","target_id":porter.id,"item_id":"bell_clapper"}),"LATE_USED_RETURN")
	require(bot.sim.snapshot().items.bell_clapper.location=="returned" and bot.sim.porter_state().restored,"RETURNED_OWNERSHIP")
	save_probe(bot.sim.snapshot(),true)
	require(bot.go(home.pos) and bot._commit({"type":"ride","target_id":"lift_home"}),"RIDE_HOME_TO_DEEP")
	require(bot._commit({"type":"ride","target_id":"lift_deep"}),"RIDE_DEEP_TO_HOME")
	require(not act(bot.sim,{"type":"return_item","target_id":porter.id,"item_id":"bell_clapper"}).accepted,"NO_SECOND_RETURN")
	finish_check(bot)
	var file:=FileAccess.open("res://tests/qa/results/edge_policies.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"findings":findings,"stats":stats},"\t")); file.close()
	print("QA EDGE POLICIES COMPLETE ",JSON.stringify({"checks":checks,"findings":findings,"stats":stats}))
	quit(1 if not findings.is_empty() else 0)
