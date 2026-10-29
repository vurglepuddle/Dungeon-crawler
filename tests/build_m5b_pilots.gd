extends "res://tests/build_m5a_pilots.gd"
func _initialize() -> void:
	replay=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep","metals":true})
	lines=["# New metal-key rules, real taps, isolated run/profile, muted.","wait 4","call new_adventure BELL42 deep metals","waitidle","tapnamed wake_close","waitidle"]
	var proof: Dictionary=DeepBot.new().prove("BELL42",{"metals":true}); assert(proof.ok,proof.reason)
	var mapped:=false
	for action in proof.actions:
		if action.type=="unlock": add("shot metal_lock_before")
		emit(action)
		if not mapped and replay._s.pos==[8,7]:
			add("shot room_entry"); add("tapnamed map"); add("wait 4"); add("shot room_entry_map"); add("tapnamed map_close"); add("waitidle"); mapped=true
		if action.type=="pickup" and replay._s.items[action.item_id].kind=="key":
			add("tapnamed belt_key"); add("wait 4"); add("shot keys_"+action.item_id)
			add("tapnamed belt_"+action.item_id); add("wait 4"); add("shot card_"+action.item_id); add("tapnamed card_close"); add("waitidle")
		if action.type=="unlock": add("shot metal_lock_after")
	add("shot dawn_metals"); finish("m5b_metals")
	print("M5b real-tap witness: ",replay._s.turn," turns, HP ",replay._s.hp); quit()
