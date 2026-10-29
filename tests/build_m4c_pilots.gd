extends "res://tests/build_m4a_pilots.gd"
func _initialize() -> void:
	begin_run("B3VJ5K",2)
	var proof: Dictionary=W.build("B3VJ5K",2,false,"return")
	for action in proof.actions:
		if action.type=="unlock":
			add("shot 01_lock_closed"); emit(action); add("shot 02_lock_open_same_plane"); break
		emit(action)
	finish("m4c_lock")
	begin_run("BELL42",3)
	proof=W.build("BELL42",3,false,"return",true); assert(proof.ok)
	for action in proof.actions:
		if action.type=="cut" and action.target_id=="f1_panel": break
		emit(action)
	add("shot 03_dawn_revealed_scar")
	# Prove the owner's sequence explicitly: equip after discovering the scar.
	if replay.snapshot().equipment.hand=="knife_start":
		add("tapnamed equip_hand"); add("wait 3")
		tap_action({"type":"unequip","slot":"hand"},"card_use")
	emit({"type":"equip","item_id":"knife_start"})
	add("shot 04_held_knife_pry")
	tap_action({"type":"cut","target_id":"f1_panel","item_id":"knife_start"},"hot_f1_panel")
	add("shot 05_tapped_open_cache"); finish("m4c_pry")
	print("M4c lock/held-blade real-tap pilots written."); quit()
