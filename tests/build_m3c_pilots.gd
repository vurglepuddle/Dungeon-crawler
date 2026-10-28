extends "res://tests/build_m3_pilots.gd"
## Capture ordinary BELL42 play, never place an actor or force a pose.
func _initialize() -> void:
	_begin(); lines.insert(2,"shot 00_title")
	add("shot 01_room")
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	assert(proof.ok)
	var windup:=false; var hurt:=false; var corridor:=false
	var plate:=false; var strike:=false; var lever:=false
	for action in proof.actions:
		if action.type=="latch" and not lever:
			add("shot 30_lever_up")
			emit(action); add("shot 31_lever_down"); lever=true
		elif action.type=="guard" and not hurt:
			# Same enemy phase, but accept one blow to inspect portrait shudder.
			emit({"type":"wait"}); lines.pop_back()
			add("wait 1"); add("shot 06_hurt"); add("waitidle")
			add("call assert hp 5"); hurt=true
		elif action.type=="hit" and not strike:
			emit(action); lines.pop_back()
			add("wait 1"); add("shot 33_strike_early")
			add("wait 3"); add("shot 33_strike")
			add("wait 3"); add("shot 33_strike_late"); add("waitidle"); strike=true
		else: emit(action)
		var snapshot: Dictionary=replay.snapshot()
		if not plate and action.type=="drop" and action.item_id=="f1_stone":
			# Back off a pressed plate, inspect it with the weight still on top.
			emit({"type":"move","step":"back"}); add("shot 34_plate_stone")
			emit({"type":"move","step":"fwd"}); plate=true
		if not corridor and snapshot.floor==1 and snapshot.pos[1]==11:
			add("shot 03_corridor"); corridor=true
		if not windup and snapshot.floors[0].actors.any(func(a): return a.state=="windup"):
			add("shot 32_husk_windup"); windup=true
		if action.type=="pickup" and action.item_id=="f2_seal":
			add("tapnamed map"); add("wait 4"); add("shot 05_map")
			add("tapnamed map_close"); add("waitidle")
	add("call assert status won"); add("call assert hp 5")
	add("call assert hash "+replay.state_hash()); add("call state")
	add("shot 11_gallery_home"); add("quit")
	write_file("res://tests/pilot/m3c_gallery.txt",lines)
	print("M3c gallery: ",replay.snapshot().turn," turns, hp ",replay.snapshot().hp)
	_audio()
	_strikes("heavy")
	_strikes("hands")
	quit()

func _strikes(kind: String) -> void:
	_begin()
	if kind=="hands":
		add("tapnamed equip_hand"); add("wait 3"); add("tapnamed card_use"); add("waitidle")
		assert(replay.apply({"type":"unequip","slot":"hand"}).accepted)
		# Unequipping preserves the selected (now packed) knife. Close its
		# card explicitly before reaching for unrelated world possessions.
		add("tapnamed pack0"); add("wait 3"); add("tapnamed card_close"); add("waitidle")
	var proof: Dictionary=W.build("BELL42",2,false,"keep" if kind=="heavy" else "return")
	var captured:=false
	for action in proof.actions:
		var before: Dictionary=replay.snapshot()
		var weapon: String=before.equipment.hand
		emit(action)
		if not captured and action.type=="hit" and (weapon=="" if kind=="hands" else weapon=="bell_clapper"):
			lines.pop_back(); add("wait 4"); add("shot 36_strike_"+kind); add("waitidle"); captured=true
	assert(captured)
	add("call assert status won"); add("call assert hp 6")
	add("call assert hash "+replay.state_hash()); add("call state"); add("close")
	write_file("res://tests/pilot/m3c_"+kind+".txt",lines)
	print("M3c ",kind,": ",replay.snapshot().turn," turns, hp ",replay.snapshot().hp)

func _audio() -> void:
	write_file("res://tests/pilot/m3c_audio_a.txt",[
		"# Fresh isolated save/settings path, then B in a separate process.",
		"wait 4","call assert music true","call assert sfx true",
		"tapnamed music","tapnamed sound","call assert music false","call assert sfx false",
		"shot 35_audio_off","call new_run BELL42 2","waitidle","close"])
	write_file("res://tests/pilot/m3c_audio_b.txt",[
		"wait 4","call assert music false","call assert sfx false",
		"tapnamed music","call assert music true","call assert sfx false",
		"tapnamed sound","call assert music true","call assert sfx true",
		"tapnamed continue","waitidle","call assert turn 0","call assert hp 6","close"])
