extends "res://tests/build_m3_pilots.gd"
const Faces=preload("res://scripts/sim/wall_faces.gd")
func begin_run(seed: String="BELL42",count: int=2) -> void:
	replay=Sim.new(seed,count)
	lines=["# Ordinary real taps, isolated saves, muted by Autopilot.","wait 4","call new_run %s %d"%[seed,count],"waitidle","wait 3"]
func plan(bot) -> void:
	for action in bot.actions: emit(action)
func bot_here():
	var bot=W.new(); var s: Dictionary=replay.snapshot()
	bot.sim=Sim.new(s.seed,s.floor_count); assert(bot.sim.restore_state(s)); return bot
func tap_action(action: Dictionary,name: String) -> void:
	add("tapnamed "+name); add("waitidle"); assert(replay.apply(action).accepted)
func finish(name: String) -> void:
	add("call assert hash "+replay.state_hash()); add("call assert hp %d"%replay.snapshot().hp); add("close")
	write_file("res://tests/pilot/"+name+".txt",lines)
func emit(action: Dictionary) -> void:
	if action.type=="drop" and replay.snapshot().items[action.item_id].location=="equip":
		add("tapnamed equip_"+replay.snapshot().items[action.item_id].slot); add("wait 3"); tap_action(action,"card_drop"); return
	if action.type in ["guard","hit","wait"]:
		var options: Array=replay.legal_verbs()
		var index: int=-1
		for i in range(options.size()):
			if options[i].action==action: index=i; break
		assert(index>=0,"Ordinary combat verb")
		tap_action(action,"verb%d"%index); return
	if action.type in ["light","burn","cut","feed","dispel","reveal","toss"]:
		var s: Dictionary=replay.snapshot(); var id: String=action.item_id
		add("tapnamed "+("pack%d"%s.pack.find(id) if s.pack.has(id) else ("equip_"+s.items[id].slot if s.items[id].location=="equip" else "belt_"+s.items[id].kind)))
		add("wait 3")
		if action.type=="toss":
			add("tapnamed card_toss"); add("wait 3"); tap_action(action,"verb0")
		else: tap_action(action,"hot_"+action.target_id)
		return
	super.emit(action)
func _initialize() -> void:
	_torch_pack(); _equipped_burn(); _travel_taps(); _deep(); _items(); quit()
func _torch_pack() -> void:
	begin_run(); var bot=bot_here()
	assert(bot._pickup("f1_torch") and bot.go(bot.sim._fixture("f1_brazier").pos)); plan(bot)
	add("shot 01_pocket_torch_light")
	tap_action({"type":"light","item_id":"f1_torch","target_id":"f1_brazier"},"hot_f1_brazier")
	add("shot 02_torch_lit_by_tap"); finish("m4a_light")
func _equipped_burn() -> void:
	begin_run(); var bot=bot_here()
	assert(bot._pickup("f1_torch") and bot.go(bot.sim._fixture("f1_brazier").pos)); plan(bot)
	tap_action({"type":"light","item_id":"f1_torch","target_id":"f1_brazier"},"verb0")
	emit({"type":"equip","item_id":"f1_torch"})
	bot=bot_here(); assert(bot.go(bot.sim._fixture("f1_web").pos)); plan(bot)
	add("shot 03_equipped_torch_burn")
	add("tapnamed hot_f1_web"); add("wait 2"); add("shot 04_tap_burning_web"); add("waitidle")
	assert(replay.apply({"type":"burn","item_id":"f1_torch","target_id":"f1_web"}).accepted)
	finish("m4a_burn")
func _travel_taps() -> void:
	begin_run(); var proof: Dictionary=W.build("BELL42",2,false,"return"); assert(proof.ok)
	for action in proof.actions:
		if action.type=="stairs": break
		emit(action)
	var stair: Dictionary=replay._fixture("f1_down")
	var bot=bot_here()
	assert(bot.go([stair.pos[0]+1,stair.pos[1]+1],false) and bot._face(0)); plan(bot)
	assert(not replay.fixture_near(stair))
	add("shot 05_distant_stair")
	add("tapnamed hot_f1_down"); add("waitidle"); add("call assert hash "+replay.state_hash())
	add('call assert message ["Step closer.",""]')
	add("shot 06_step_closer")
	bot=bot_here(); assert(bot.go(stair.pos,false) and bot._face(0)); plan(bot)
	add("shot 07_stair_in_reach"); tap_action({"type":"stairs","target_id":stair.id},"hot_f1_down")
	add("call assert floor 2"); add("shot 08_stair_tap_arrival"); finish("m4a_travel")
func _deep() -> void:
	begin_run("BELL42",3)
	var proof: Dictionary=W.build("BELL42",3,false,"return",true); assert(proof.ok,proof.reason)
	for action in proof.actions:
		emit(action)
		if replay.snapshot().floor==3: break
	add("shot 09_lower_watch_entry")
	var checkpoint: Dictionary=replay.snapshot(); var checkpoint_hash: String=replay.state_hash()
	write_file("res://tests/pilot/m4a_save_a.txt",lines+["call assert hash "+checkpoint_hash,"call assert save_ok true","close"])
	write_file("res://tests/pilot/m4a_save_b.txt",["wait 4","tapnamed continue","waitidle","call assert floor_count 3","call assert floor 3","call assert hash "+checkpoint_hash,"call assert save_ok true","shot 10_deep_continue","close"])
	var bot=bot_here(); assert(bot._pickup("f3_watch_coat")); plan(bot)
	proof=W.new().run("BELL42",3,false,"return",replay.snapshot(),true); assert(proof.ok,proof.reason)
	var caught:=false
	for action in proof.actions:
		if not caught and action.type=="guard" and replay._actor("f3_husk").state=="windup":
			add("shot 11_deep_two_point_tell")
			emit({"type":"equip","item_id":"f3_watch_coat"})
			add("shot 12_padding_catches_blow"); caught=true
			# A separate real-input branch drops the padding while the Husk
			# recovers, proving its spent floor paint without altering the tour.
			var kept_lines: Array=lines.duplicate(); var kept_state: Dictionary=replay.snapshot()
			emit({"type":"drop","item_id":"f3_watch_coat"}); add("shot 13_spent_coat_on_floor")
			finish("m4a_spent_coat")
			lines=kept_lines; assert(replay.restore_state(kept_state))
		else: emit(action)
		if action.type in ["feed","toss"] and replay._actor("f3_hound").state=="peaceful": add("shot 14_deep_hound_fed")
		if action.type=="pickup" and action.item_id=="f3_seal":
			add("shot 15_third_floor_seal"); add("tapnamed map"); add("wait 4"); add("shot 16_watch_map"); add("tapnamed map_close"); add("waitidle")
	add("call assert floor_count 3"); add("call assert status won"); add("shot 17_deeper_home")
	finish("m4a_deep")
	print("M4a real-tap deep run: ",replay.snapshot().turn," turns; HP ",replay.snapshot().hp,"; supplied coat spent ",replay.snapshot().items.f3_watch_coat.spent)
func _items() -> void:
	begin_run("B3VJ5K",2); add("shot 18_world_items_entry")
	emit({"type":"move","step":"fwd"}); add("shot 19_world_stone_near")
	for facing in range(3): emit({"type":"turn","delta":1}); add("shot 20_items_room_%d"%facing)
	finish("m4a_items")
