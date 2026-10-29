extends "res://tests/build_m4a_pilots.gd"
const DeepBot=preload("res://scripts/gen/deep_witness.gd")
func begin_adventure(start: String) -> void:
	replay=Sim.new("BELL42",3,{"profile":"m5.1","start":start})
	lines=["# Ordinary real taps; isolated run AND profile paths required.","wait 4","call new_adventure BELL42 "+start,"waitidle"]
	if start=="deep": add("wait 3"); add("tapnamed wake_close"); add("waitidle")
func emit(action: Dictionary) -> void:
	# Empty pocket taps dismiss a selected tool before picking up ground loot.
	if action.type=="pickup" and replay._s.pack.size()<8:
		add("tapnamed pack%d"%replay._s.pack.size()); add("wait 2")
	if action.type=="wake": tap_action(action,"hot_"+action.target_id); return
	if action.type in ["unlock","latch","stairs","ride"]:
		tap_action(action,"hot_"+action.target_id); return
	super.emit(action)
func _initialize() -> void:
	begin_adventure("abbey")
	var proof: Dictionary=W.build("BELL42",3,false,"keep"); assert(proof.ok)
	for action in proof.actions:
		if action.type=="pickup" and action.item_id=="f3_seal":
			add("shot 01_abbey_seal")
			add("tapnamed hot_item_f3_seal"); add("wait 12"); add("shot 02_the_fall"); add("waitidle")
			assert(replay.apply(action).accepted); break
		emit(action)
	add("shot 03_waking_card"); add("call assert profile_fallen true")
	add("tapnamed wake_close"); add("waitidle"); add("call assert act deep"); finish("m5a_fall")
	# Fresh-process UI skip uses the profile unlocked by the Fall pilot.
	replay=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"})
	lines=["wait 4","tapnamed start","wait 4","shot 04_start_choices","tapnamed seed_deep","waitidle","shot 05_skipped_waking","tapnamed wake_close","waitidle"]
	add("call assert floor 4"); add("call assert hp 5")
	add("tapnamed map"); add("wait 4"); add("shot 06_deep_map_centred")
	add("swipe right 77 145"); add("wait 4"); add("shot 07_deep_map_panned"); add("call assert map_pan [10,0]"); add("call state")
	add("tapnamed map_close"); add("waitidle")
	var deep: Dictionary=DeepBot.new().prove("BELL42"); assert(deep.ok,deep.reason)
	for action in deep.actions:
		if action.type=="wake": add("shot 08_dawn_mark")
		if action.type=="stairs":
			add("tapnamed map"); add("wait 4"); add("shot 16_sprawling_map")
			add("swipe left 77 145"); add("wait 3"); add("call assert map_pan [-10,0]")
			add("shot 17_sprawling_map_panned"); add("tapnamed map_close"); add("waitidle")
		if action.type=="ride": add("shot 13_the_winding")
		emit(action)
		if action.type=="wake": add("shot 09_woken_passage")
		if action.type=="light": add("shot 10_deep_fire")
	add("shot 14_dawn"); add("call assert status won"); finish("m5a_skip_winding")
	# Full close/reopen retains a waking card, not a half-played fall movie.
	begin_adventure("deep")
	add("tapnamed map"); add("wait 3"); add("tapnamed map_close"); add("waitidle"); finish("m5a_save_a")
	write_file("res://tests/pilot/m5a_save_b.txt",["wait 4","tapnamed continue","waitidle","call assert act deep","call assert hp 5","call assert hash "+replay.state_hash(),"shot 15_deep_continue","close"])
	_death_wake(deep.actions)
	print("M5a pilots: Fall, UI skip/map/Winding, death/recovery and save pair; Deep ",deep.snapshot.turn," turns."); quit()
func _death_wake(route: Array) -> void:
	begin_adventure("deep")
	for action in route:
		if replay._s.pack.has("d4_torch") and replay._s.items.d4_torch.lit: break
		emit(action)
	assert(replay._s.floor==4 and replay._s.pack.has("d4_torch"),"Death route reaches a live threat with a carried tool")
	var bot=deep_bot_here()
	assert(bot._pickup("d4_coat"),bot.error)
	# The coat joins the torch in the death pile, exercising the chooser.
	for action in bot.actions: emit(action)
	var live: Array=replay._floor().actors.filter(func(a): return a.hp>0 and a.state!="peaceful" and (replay._near(a.pos) or not bot._path(a.pos,true).is_empty()))
	assert(not live.is_empty(),"A reachable live encounter remains")
	bot=deep_bot_here(); assert(bot.go(live[0].pos),bot.error)
	for action in bot.actions:
		if action.type in ["hit","dispel"] and action.get("target_id","")==live[0].id: break
		emit(action)
	var fallen_at: Array=replay._s.pos.duplicate(); var dropped: Array=replay._s.pack.duplicate()
	for _beat in range(30):
		if replay._s.wakes>0: break
		var options: Array=replay.legal_verbs(); var index: int=options.find(options.filter(func(v): return v.label=="WAIT")[0])
		add("tapnamed verb%d"%index); add("waitidle"); assert(replay.apply({"type":"wait"}).accepted)
	assert(replay._s.wakes==1,"Ordinary waits cause a wake")
	add("shot 11_death_wake"); add("tapnamed wake_close"); add("waitidle")
	bot=DeepBot.new(); bot.sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"}); assert(bot.sim.restore_state(replay.snapshot())); bot.expected_wakes=1
	assert(bot.go(fallen_at),bot.error)
	for id in dropped: assert(bot._pickup(id),bot.error)
	for action in bot.actions: emit(action)
	add("shot 12_pack_recovered"); add("call assert wakes 1"); finish("m5a_death")
func deep_bot_here():
	var bot=DeepBot.new(); bot.sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"})
	assert(bot.sim.restore_state(replay.snapshot())); return bot
