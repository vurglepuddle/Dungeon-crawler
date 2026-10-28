extends "res://tests/build_m3_pilots.gd"
## Real-input gallery and retained-clapper tool/reopen evidence.
func emit(action: Dictionary) -> void:
	if action.type=="ring":
		var state: Dictionary=replay.snapshot()
		add("tapnamed equip_hand" if state.items[action.item_id].location=="equip" else "tapnamed pack%d"%state.pack.find(action.item_id))
		add("wait 4"); add("shot 07_clapper_ring_card")
		add("tapnamed card_ring"); add("waitidle")
		assert(replay.apply(action).accepted)
		add("call assert ring_ready false"); add("shot 08_ring_recovery")
		add("tapnamed equip_hand"); add("wait 4"); add("shot 09_spent_clapper")
		add("tapnamed card_close"); add("waitidle")
		return
	super.emit(action)

func _initialize() -> void:
	_gallery()
	_ring()
	quit()

func _gallery() -> void:
	_begin(); lines.insert(2,"shot 00_title")
	add("shot 01_room")
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	assert(proof.ok)
	var hurt:=false; var corridor:=false; var selected_plate:=false
	for action in proof.actions:
		if not hurt and action.type=="guard":
			# Same enemy phase as a guard, deliberately accept the first blow.
			emit({"type":"wait"}); lines.pop_back()
			add("wait 2"); add("shot 06_hurt"); add("waitidle")
			add("call assert hp 5"); hurt=true
		else: emit(action)
		var s: Dictionary=replay.snapshot()
		if not selected_plate and s.pack.has("f1_stone") and s.floor==1 and s.pos[1]==14:
			add("tapnamed pack%d"%s.pack.find("f1_stone")); add("wait 5")
			add("shot 02_item_card"); add("shot 04_selected_place")
			add("tapnamed card_close"); add("waitidle"); selected_plate=true
		if not corridor and s.floor==1 and s.pos[1]==11:
			add("shot 03_corridor"); corridor=true
		if action.type=="pickup" and action.item_id=="f2_seal":
			add("tapnamed map"); add("wait 4"); add("shot 05_map")
			add("tapnamed map_close"); add("waitidle")
	add("call assert status won"); add("call assert hp 5")
	add("call assert hash "+replay.state_hash()); add("shot 11_gallery_home"); add("quit")
	write_file("res://tests/pilot/m3b_gallery.txt",lines)
	print("Gallery: ",replay.snapshot().turn," turns, hp ",replay.snapshot().hp)

func _ring() -> void:
	_begin()
	var proof: Dictionary=W.build("BELL42",2,false,"ring")
	assert(proof.ok)
	var resume_lines: Array=[]
	var resume_hash: String=""
	for action in proof.actions:
		emit(action)
		if action.type=="ring" and resume_lines.is_empty():
			resume_lines=lines.duplicate(); resume_hash=replay.state_hash()
			resume_lines.append_array(["call assert ring_ready false","call assert hash "+resume_hash,"call state","close"])
	add("call assert status won"); add("call assert hp 6")
	add("call assert hash "+replay.state_hash()); add("call state"); add("shot 12_ring_home"); add("quit")
	write_file("res://tests/pilot/m3b_ring.txt",lines)
	assert(not resume_lines.is_empty())
	write_file("res://tests/pilot/m3b_ring_save_a.txt",resume_lines)
	write_file("res://tests/pilot/m3b_ring_save_b.txt",[
		"# Fresh process after A, same isolated --save-path.","wait 4","call assert status title","tapnamed continue","waitidle",
		"call assert ring_ready false","call assert hp 6","call assert hash "+resume_hash,
		"tapnamed equip_hand","wait 4","shot 10_ring_continued","tapnamed card_close","waitidle","call state","quit"])
	print("Ring: ",replay.snapshot().turn," turns, hp ",replay.snapshot().hp)
