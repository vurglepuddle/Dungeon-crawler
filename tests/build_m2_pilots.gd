extends SceneTree
const W = preload("res://scripts/gen/witness.gd")
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
var replay
var lines: Array=[]
func add(value: String) -> void: lines.append(value)
func emit(action: Dictionary) -> void:
	var state: Dictionary=replay.snapshot()
	match action.type:
		"turn": add("tapnamed turn_l" if action.delta<0 else "tapnamed turn_r")
		"move": add("tapnamed "+action.step)
		"pickup":
			add("tapnamed hot_item")
			if replay.reachable_items().size()>1:
				add("wait 3"); add("tapnamed loot_"+action.item_id)
		"drop","equip","eat","place":
			add("tapnamed pack%d"%state.pack.find(action.item_id)); add("wait 2")
			add("tapnamed "+("card_drop" if action.type=="drop" else ("hot_plate" if action.type=="place" else "card_use")))
		"guard": add("tapnamed verb1")
		"hit": add("tapnamed verb0")
		"latch","unlock","stairs","leave": add("tapnamed hot_front")
		"wait": add("tapnamed verb2")
	add("waitidle")
	var result: Dictionary=replay.apply(action)
	assert(result.accepted)
func write_file(path: String,entries: Array) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string("\n".join(entries)+"\n")
func _initialize() -> void:
	var proof: Dictionary=W.build("BELL42")
	assert(proof.ok)
	replay=Sim.new("BELL42")
	lines=["# Generated from the ordinary-action witness by tests/build_m2_pilots.gd.","# Use --save-path=user://m2_full.json (resume pair: user://m2_resume.json).","wait 4","call new_run BELL42","wait 3","waitidle","call save_path","shot 01_m2_entry"]
	var resume_lines: Array=[]
	var resume_state: Dictionary={}
	var floor_before:=1
	for action in proof.actions:
		emit(action)
		var state: Dictionary=replay.snapshot()
		if state.floor!=floor_before:
			add("call assert floor %d"%state.floor); add("shot floor_%d_turn_%d"%[state.floor,state.turn])
			floor_before=state.floor
		if action.type=="pickup" and action.item_id=="f2_stone" and resume_lines.is_empty():
			resume_state=state.duplicate(true)
			resume_lines=lines.duplicate()
			resume_lines.append_array(["tapnamed pack0","wait 3","call assert selected f2_stone"])
		if action.type=="pickup" and replay.definition(action.item_id).name=="Dawn Seal": add("shot 03_seal_taken")
	add("call assert status won"); add("call assert hp 6")
	add("call assert turn %d"%replay.snapshot().turn); add("call assert hash "+replay.state_hash())
	add("call state"); add("shot 05_home_again"); add("quit")
	write_file("res://tests/pilot/m2_full_run.txt",lines)
	var resumed=Sim.new("BELL42"); assert(resumed.restore_state(resume_state))
	resume_lines.append_array(["call assert save_ok true","call assert hash "+resumed.state_hash(),"call state","shot 06_before_close","close"])
	write_file("res://tests/pilot/m2_save_a.txt",resume_lines)
	var pair: Array=["# Start a fresh process on --save-path=user://m2_resume.json after m2_save_a.","wait 4","call assert status title","tapnamed continue","waitidle"]
	for key in ["floor","hp","turn","revision"]: pair.append("call assert %s %s"%[key,str(resume_state[key])])
	pair.append_array(["call assert hash "+resumed.state_hash(),"call assert pack [\"f2_stone\"]","call assert selected f2_stone","call assert save_ok true","call state","tapnamed map","wait 4","shot 07_continued_map","tapnamed map_close","waitidle","shot 08_continued","quit"])
	write_file("res://tests/pilot/m2_save_b.txt",pair)
	print("M2 pilots built. Full turns %d, actions %d. Resume floor %d turn %d revision %d hash %s"%[proof.snapshot.turn,proof.actions.size(),resume_state.floor,resume_state.turn,resume_state.revision,resumed.state_hash()])
	_feedback()
	_death()
	quit()

func _feedback() -> void:
	var bot=W.new(); bot.sim=Sim.new("BELL42")
	assert(bot._pickup("f1_club")); assert(bot._commit({"type":"equip","item_id":"f1_club"}))
	assert(bot._pickup("f1_coat")); assert(bot._commit({"type":"equip","item_id":"f1_coat"}))
	assert(bot._pickup("f1_stone"))
	assert(bot.go(bot._fixture("plate").pos,false)); assert(bot._commit({"type":"drop","item_id":"f1_stone"}))
	assert(bot.go(bot._fixture("latch").pos)); assert(bot._commit({"type":"latch","target_id":"f1_latch"}))
	replay=Sim.new("BELL42")
	lines=["# Equipment, real hurt feedback, healing, free map and padded seed dialog.","wait 4","call new_run BELL42","wait 3"]
	for action in bot.actions: emit(action)
	# Consume the coat's one protection, then deliberately take the next strike.
	for _i in range(3): emit({"type":"wait"})
	lines.pop_back(); add("wait 2"); add("shot 09_hurt_border_face"); add("waitidle")
	add("call assert hp 5")
	emit({"type":"hit","target_id":"f1_husk"})
	add("shot 10_heavy_counter")
	add("tapnamed equip_body"); add("wait 3"); add("shot 11_spent_coat_card"); add("tapnamed card_close")
	for _i in range(3): emit({"type":"move","step":"back"})
	emit({"type":"turn","delta":1}); emit({"type":"move","step":"fwd"})
	emit({"type":"pickup","item_id":"f1_tonic_4"}); emit({"type":"eat","item_id":"f1_tonic_4"})
	add("call assert hp 6")
	add("tapnamed map"); add("wait 3"); add("shot 12_map"); add("tapnamed map_close"); add("waitidle")
	add("call assert hash "+replay.state_hash())
	add("tapnamed seed"); add("wait 3"); add("shot 13_padded_seed"); add("tapnamed seed_cancel"); add("waitidle")
	add("call assert hash "+replay.state_hash()); add("quit")
	write_file("res://tests/pilot/m2_feedback.txt",lines)

func _death() -> void:
	var proof: Dictionary=W.build("BELL42")
	replay=Sim.new("BELL42")
	lines=["# Deliberately ignore the first Husk, then retry through the end screen.","wait 4","call new_run BELL42","wait 3"]
	for action in proof.actions:
		emit(action)
		if replay.snapshot().floors[0].actors[0].state=="windup": break
	while replay.snapshot().status=="playing": emit({"type":"wait"})
	add("call assert status lost"); add("call assert hp 0"); add("shot 14_death")
	add("tapnamed retry"); add("wait 3"); add("waitidle")
	add("call assert hp 6"); add("call assert turn 0"); add("call assert seed BELL42")
	add("call assert hash "+Sim.new("BELL42").state_hash()); add("shot 15_retried"); add("quit")
	write_file("res://tests/pilot/m2_death.txt",lines)
