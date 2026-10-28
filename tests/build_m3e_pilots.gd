extends "res://tests/build_m3_pilots.gd"
var checkpoint: Dictionary={}
var checkpoint_hash: String=""
var checkpoint_lines: Array=[]
var touring:=false
func select_item(id: String) -> void:
	var s: Dictionary=replay.snapshot()
	if s.pack.has(id): add("tapnamed pack%d"%s.pack.find(id))
	elif s.items[id].location=="equip": add("tapnamed equip_"+s.items[id].slot)
	else: add("tapnamed belt_"+s.items[id].kind)
	add("wait 3")
func emit(action: Dictionary) -> void:
	if action.type in ["guard","wait","hit"]:
		var legal: Array=replay.legal_verbs()
		var index: int=-1
		for i in range(legal.size()):
			if legal[i].action==action: index=i; break
		assert(index>=0)
		add("tapnamed verb%d"%index); add("waitidle"); assert(replay.apply(action).accepted)
		return
	if action.type in ["light","burn","cut","dispel","reveal"]:
		select_item(action.item_id)
		assert(replay.legal_verbs(action.item_id)[0].action==action)
		if action.type=="dispel": add("shot 06_ghost_before")
		if action.type=="cut" and action.target_id=="f1_panel": add("shot 08_seal_reveals_panel")
		add("tapnamed verb0")
		if action.type in ["burn","dispel"]:
			add("wait 2"); add("shot "+("02_burning_web" if action.type=="burn" else "07_ghost_dispelled"))
		add("waitidle"); assert(replay.apply(action).accepted)
		if action.type=="light": add("shot 01_brazier_torch")
		if action.type=="cut" and action.target_id=="f1_panel": add("shot 09_secret_open")
		return
	if action.type in ["feed","toss"]:
		select_item(action.item_id)
		assert(replay.toss_preview(action.item_id).actor_id=="f1_hound")
		add("shot 03_hound_windup"); add("tapnamed card_toss"); add("wait 3")
		add("call assert tossing "+action.item_id); add("shot 04_toss_preview")
		add("tapnamed verb0"); add("waitidle")
		assert(replay.apply({"type":"toss","item_id":action.item_id}).accepted)
		# Its calm perch can be behind the doorway. Photograph it from inside
		# the kennel using real movement, then return before continuing.
		var original: Dictionary=replay.snapshot()
		var photo=W.new(); photo.sim=Sim.new(original.seed,original.floor_count)
		assert(photo.sim.restore_state(original))
		assert(photo.go(photo.sim._actor("f1_hound").pos))
		var photographed: int=photo.actions.size()
		for step in photo.actions: emit(step)
		add("shot 05_hound_fed")
		assert(photo.go(original.pos,false)); assert(photo._face(original.facing))
		for step in photo.actions.slice(photographed): emit(step)
		if touring and checkpoint.is_empty():
			checkpoint=replay.snapshot(); checkpoint_hash=replay.state_hash(); checkpoint_lines=lines.duplicate()
		return
	super.emit(action)
	if action.type=="pickup" and action.item_id=="f2_seal": add("shot 12_seal_held")
	if action.type=="pickup" and action.item_id=="f1_secret_tonic": add("shot 13_cache_taken")
func _initialize() -> void:
	var proof: Dictionary=W.build("BELL42",2,false,"return",true)
	assert(proof.ok)
	_begin(); touring=true
	add("shot 00_entry")
	for action in proof.actions: emit(action)
	add("call assert status won"); add("call assert hp 6"); add("call assert secrets_found 1")
	add("call assert hash "+replay.state_hash()); add("call state"); add("shot 14_tour_won"); add("close")
	write_file("res://tests/pilot/m3e_tour.txt",lines)
	print("M3e real-tap tour: ",replay.snapshot().turn," turns, ",replay.snapshot().revision," commands; hp ",replay.snapshot().hp)
	write_file("res://tests/pilot/m3e_expected.json",[JSON.stringify({"witness_turns":proof.snapshot.turn,"gallery_turns":replay.snapshot().turn,"hp":replay.snapshot().hp,"revision":replay.snapshot().revision})])
	checkpoint_lines.append_array(["call assert save_ok true","call assert hash "+checkpoint_hash,"shot 15_lit_fed_before_close","close"])
	write_file("res://tests/pilot/m3e_save_a.txt",checkpoint_lines)
	write_file("res://tests/pilot/m3e_save_b.txt",["wait 4","tapnamed continue","waitidle","wait 3","call assert save_ok true","call assert hash "+checkpoint_hash,"call assert hp 6","shot 16_lit_fed_continued","close"])
	_begin(); touring=false
	for action in proof.actions:
		if action.type in ["feed","toss"]: break
		emit(action)
	# Ordinary guard/reset gives an adjacent tell: backstepping would remain
	# inside its second cell. This pilot takes the safe side step instead.
	emit({"type":"guard"}); emit({"type":"wait"}); add("shot 10_hound_adjacent_lane")
	emit({"type":"move","step":"strafe_r"}); add("shot 11_hound_dodged")
	add("call assert hp 6"); add("call assert hash "+replay.state_hash()); add("close")
	write_file("res://tests/pilot/m3e_dodge.txt",lines)
	var record: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/qa/repro_stairs.json")))
	replay=Sim.new(record.seed,record.count)
	lines=["# QA-01's unchanged ordinary setup, then the visible safe landing verb.","wait 4","call new_run "+record.seed,"wait 3","waitidle"]
	for action in record.actions.slice(0,record.actions.size()-1): emit(action)
	add("shot 17_blocked_stair_sidle")
	var side: Dictionary={"type":"squeeze","target_id":"f2_up"}
	add("tapnamed hot_front"); add("waitidle"); assert(replay.apply(side).accepted)
	add("call assert floor 1"); add("call assert hp 6"); add("call assert hash "+replay.state_hash())
	add("shot 18_safe_arrival"); add("close")
	write_file("res://tests/pilot/m3e_sidle.txt",lines)
	quit()
