extends "res://tests/build_m3_pilots.gd"
const View=preload("res://scripts/view/dungeon_view.gd")
const Survey=preload("res://scripts/ui/survey.gd")
var camera
var survey
func _begin() -> void:
	replay=Sim.new("BELL42"); survey=Survey.new(); survey.reset(2)
	if camera==null:
		camera=View.new(); root.add_child(camera)
	_record()
	lines=["# Real taps; only new_run resets the fixture.","wait 4","shot 00_splash","tapnamed splash_skip","wait 3","shot 01_title","call new_run BELL42 2","waitidle","wait 3"]
func _record() -> void:
	var s: Dictionary=replay.snapshot()
	camera.update_state(replay.view_snapshot()); survey.observe(s.floor,camera.visible_cells(),s.pos,camera.visible_landmarks())
func emit(action: Dictionary) -> void:
	super.emit(action); _record()
func _initialize() -> void:
	_build.call_deferred()
func _build() -> void:
	_gallery(); _gate(); _death(); _resume(); camera.free(); quit()
func turn_to(facing: int) -> void:
	while replay.snapshot().facing!=facing: emit({"type":"turn","delta":1})
func _gallery() -> void:
	_begin(); add("shot 02_room")
	turn_to(2); add("shot 04_exit_arch")
	turn_to(1); emit({"type":"move","step":"fwd"}); add("shot 05_lift_dead")
	emit({"type":"move","step":"back"}); turn_to(0)
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	var glint:=false; var corridor:=false; var stairs:=false
	for action in proof.actions:
		if action.type=="stairs" and not stairs:
			var facing: int=replay.snapshot().facing
			turn_to(0)
			var closer: bool=replay.can_walk(replay.front_pos())
			if closer: emit({"type":"move","step":"fwd"})
			add("shot 07_stairs_down")
			if closer: emit({"type":"move","step":"back"})
			turn_to(facing); stairs=true
		if action.type=="ride":
			var facing: int=replay.snapshot().facing
			emit({"type":"move","step":"fwd"}); turn_to(1); add("shot 10_lift_working")
			turn_to(facing); emit({"type":"move","step":"back"})
		emit(action)
		var s: Dictionary=replay.snapshot()
		if action.type=="stairs":
			var facing: int=s.facing
			turn_to(2); add("shot 19_stairs_up"); turn_to(facing)
		if not corridor and s.floor==1 and s.pos[1]==11:
			add("shot 06_corridor_gate_open"); corridor=true
		if not glint and s.floor==1 and s.pos[1]==14 and s.pack.has("f1_stone"):
			add("tapnamed pack%d"%s.pack.find("f1_stone")); add("wait 3"); add("shot 08_item_card")
			for i in range(22): add("wait 6"); add("shot sparkle_%02d"%i)
			add("tapnamed card_close"); add("waitidle"); glint=true
		if action.type=="pickup" and action.item_id=="f2_seal":
			add("tapnamed map"); add("wait 4"); add("shot 09_ink_map")
			add("tapnamed map_close"); add("waitidle")
	add("call assert status won"); add("call assert hp 6"); add("call assert hash "+replay.state_hash())
	add("shot 11_win_plate"); add("call state"); add("close")
	write_file("res://tests/pilot/m3d_gallery.txt",lines)
	print("M3d gallery: ",replay.snapshot().turn," turns; hp ",replay.snapshot().hp)
func _gate() -> void:
	_begin()
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	for action in proof.actions:
		if action.type=="drop" and action.item_id=="f1_stone": break
		emit(action)
	for step in ["strafe_l","fwd","strafe_r"]: emit({"type":"move","step":step})
	add("shot 12_gate_closed"); add("tapnamed map"); add("wait 4"); add("shot 13_closed_gate_map")
	add("tapnamed map_close"); add("waitidle"); add("call assert hp 6"); add("call assert hash "+replay.state_hash()); add("close")
	write_file("res://tests/pilot/m3d_gate.txt",lines)
func _death() -> void:
	_begin()
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	for action in proof.actions:
		emit(action)
		if replay.snapshot().floors[0].actors[0].state=="windup": break
	var hurt:=false; var near:=false
	while replay.snapshot().status=="playing":
		emit({"type":"wait"})
		var hp: int=replay.snapshot().hp
		if hp==3 and not hurt: add("shot 14_hurt_face"); hurt=true
		if hp==1 and not near: add("shot 15_near_death_face"); near=true
	add("call assert status lost"); add("call assert hp 0"); add("call assert hash "+replay.state_hash())
	add("shot 16_death_plate"); add("close")
	write_file("res://tests/pilot/m3d_death.txt",lines)
func _resume() -> void:
	_begin()
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	for action in proof.actions:
		emit(action)
		if action.type=="stairs": break
	var s: Dictionary=replay.snapshot()
	add("call assert hash "+replay.state_hash()); add("call assert survey_hash "+survey.hash_value())
	add("shot 17_survey_before_close"); add("close")
	write_file("res://tests/pilot/m3d_save_a.txt",lines)
	var midfade: Array=lines.slice(0,lines.size()-5)
	# Remove the final waitidle after the stair tap, then close while its
	# committed destination is still behind the presentation fade.
	if midfade[-1]=="waitidle": midfade.pop_back()
	midfade.append_array(["wait 1","call assert floor %d"%s.floor,"call assert travel_pending true",
		"call assert hash "+replay.state_hash(),"call assert survey_hash "+survey.hash_value(),"close"])
	write_file("res://tests/pilot/m3d_fade_save_a.txt",midfade)
	write_file("res://tests/pilot/m3d_save_b.txt",[
		"# Fresh process after A with the same isolated slot.","wait 4","tapnamed continue","waitidle",
		"call assert hash "+replay.state_hash(),"call assert survey_hash "+survey.hash_value(),
		"call assert floor %d"%s.floor,"tapnamed map","wait 4","shot 18_survey_continued",
		"tapnamed map_close","waitidle","close"])
	write_file("res://tests/pilot/m3d_fade_save_b.txt",[
		"wait 4","tapnamed continue","waitidle","call assert travel_pending false",
		"call assert hash "+replay.state_hash(),"call assert survey_hash "+survey.hash_value(),"close"])
