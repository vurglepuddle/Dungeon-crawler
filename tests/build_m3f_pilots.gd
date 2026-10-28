extends "res://tests/build_m3e_pilots.gd"
const Faces=preload("res://scripts/sim/wall_faces.gd")
var natural_travel:=false
func emit(action: Dictionary) -> void:
	if action.type in ["drop","unequip"] and (action.type=="unequip" or replay.snapshot().items[action.item_id].location=="equip"):
		var slot: String=action.slot if action.type=="unequip" else replay.snapshot().items[action.item_id].slot
		add("tapnamed equip_"+slot); add("wait 3")
		add("tapnamed "+("card_use" if action.type=="unequip" else "card_drop")); add("waitidle")
		assert(replay.apply(action).accepted); return
	if natural_travel and action.type in ["stairs","ride","leave"]:
		var fixture: Dictionary=replay._fixture(action.target_id)
		var bot=W.new(); bot.sim=Sim.new(replay.snapshot().seed,2); assert(bot.sim.restore_state(replay.snapshot()))
		assert(bot.go(fixture.pos,false))
		var face: Dictionary=Faces.all(bot.sim.floor_data())[fixture.id]
		assert(bot._face(Sim.DIRS.find([-face.normal[0],-face.normal[1]])))
		for step in bot.actions: emit(step)
		for _step in range(3):
			if replay.terrain(replay.front_pos())!=0: break
			emit({"type":"move","step":"fwd"})
		add("shot "+("20_stairs_forward" if action.type=="stairs" else ("22_lift_working_forward" if action.type=="ride" else "23_exit_forward")))
		emit({"type":"move","step":"fwd"}); return
	if action.type=="return_item": add("shot 14_porter_clear_floor")
	super.emit(action)
	if action.type=="drop" and action.item_id=="f1_stone": add("shot 11_stone_on_plate")
	if action.type=="unlock":
		var floor_number: int=replay.snapshot().floor
		add("shot 15_f%d_owner_gate_open"%floor_number)
		for n in range(4):
			emit({"type":"turn","delta":1}); add("shot 15_f%d_gate_direction_%d"%[floor_number,n])
	if action.type=="pickup" and replay.snapshot().items[action.item_id].kind=="key":
		var keys: Array=replay.snapshot().belt.filter(func(id): return replay.snapshot().items[id].kind=="key")
		if keys.size()>1:
			add("shot 21_two_belt_keys"); add("tapnamed belt_key"); add("wait 3"); add("shot 21_key_list")
			add("tapnamed belt_f1_key"); add("wait 3"); add("shot 21_key_gate_card"); add("tapnamed card_close"); add("waitidle")
func _initialize() -> void:
	replay=Sim.new("B3VJ5K")
	lines=["# Owner's seed; real taps, no state injection. Muted by Autopilot.","wait 4","shot 00_splash","tapnamed splash_skip","wait 3","shot 00_title","call new_run B3VJ5K","wait 3","waitidle","shot 01_upper_materials"]
	add("tapnamed equip_hand"); add("wait 3"); add("shot 02_equipped_drop_card"); add("tapnamed card_close"); add("waitidle")
	emit({"type":"drop","item_id":"knife_start"}); add("shot 03_equipment_dropped")
	emit({"type":"pickup","item_id":"knife_start"}); emit({"type":"equip","item_id":"knife_start"})
	emit({"type":"unequip","slot":"hand"}); add("shot 04_unequipped_to_pack"); emit({"type":"equip","item_id":"knife_start"})
	emit({"type":"turn","delta":1}); emit({"type":"move","step":"fwd"}); add("shot 05_dead_lift_grille")
	var hash_before: String=replay.state_hash()
	add("tapnamed fwd"); add("waitidle"); add("call assert hash "+hash_before); add("shot 06_lift_explained")
	add("tapnamed hot_lift_home"); add("waitidle"); add("shot 07_lift_tapped")
	emit({"type":"move","step":"back"}); emit({"type":"turn","delta":-1})
	var bot=W.new(); bot.sim=Sim.new("B3VJ5K"); assert(bot.sim.restore_state(replay.snapshot()))
	for id in ["f1_stone","f1_club","f1_coat","f1_bread_3","f1_tonic_4","f1_torch"]: assert(bot._pickup(id))
	assert(bot.go(bot.sim._fixture("f1_plate").pos))
	for action in bot.actions: emit(action)
	add("shot 08_filled_pack_tray")
	select_item("f1_stone"); add("shot 08_bright_place_brackets"); add("tapnamed card_close"); add("waitidle")
	bot=W.new(); bot.sim=Sim.new("B3VJ5K"); assert(bot.sim.restore_state(replay.snapshot()))
	assert(bot.go(bot.sim._fixture("f1_plate").pos,false)); assert(bot._commit({"type":"drop","item_id":"f1_stone"}))
	assert(bot.go(bot.sim._fixture("f1_latch").pos,false))
	var face: Dictionary=Faces.all(bot.sim.floor_data())["f1_latch"]
	assert(bot._face(Sim.DIRS.find([-face.normal[0],-face.normal[1]])))
	for action in bot.actions: emit(action)
	add("shot 09_lever_head_on_up")
	emit({"type":"latch","target_id":"f1_latch"}); add("shot 10_lever_head_on_down")
	# Sparse dressing on genuinely empty cells, and a solid masonry pilaster.
	bot=W.new(); bot.sim=Sim.new("B3VJ5K"); assert(bot.sim.restore_state(replay.snapshot()))
	for prop in bot.sim.floor_data().get("props",[]):
		if not bot.go(prop.pos): continue
		for step in bot.actions: emit(step)
		bot.actions=[]
		add("shot 12_prop_"+prop.kind)
	var proof: Dictionary=W.new().run("B3VJ5K",2,false,"return",replay.snapshot(),true)
	assert(proof.ok,proof.reason); natural_travel=true
	for action in proof.actions: emit(action)
	add("call assert status won"); add("call assert hp 6"); add("call assert hash "+replay.state_hash()); add("shot 24_owner_home"); add("close")
	write_file("res://tests/pilot/m3f_owner.txt",lines)
	print("M3f owner gallery: ",replay.snapshot().turn," turns; hp ",replay.snapshot().hp)
	quit()
