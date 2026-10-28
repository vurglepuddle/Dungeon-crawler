extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m2_layout.json"
	root.add_child(app); current_scene=app
	await process_frame
	check(app.new_run("BELL42"),"UI fixture starts")
	await process_frame
	var initial: String=app.sim.state_hash()
	for key in ["fwd","back","turn_l","turn_r","strafe_l","strafe_r","map","seed","portrait","pack0","pack7","equip_hand","belt_seal","compass","floor_label"]:
		var control: Control=app.controls[key]
		check(control.size.x>=18 and control.size.y>=18,"Touch target "+key)
		check(app.pilot_call("where",[key])!="","Named control "+key)
	check(app.view.get_rect()==Rect2(3,21,148,150),"Dungeon receives 150px of picture height")
	check(app.pilot_call("where",["new_seed"])==app.pilot_call("where",["seed"]),"NEW remains a pilot alias without a duplicate control")
	var cutout:=Rect2(54,0,43,18)
	for key in app.controls:
		var control: Control=app.controls[key]
		if control.is_visible_in_tree(): check(not control.get_global_rect().intersects(cutout),"Top camera area clear: "+key)
	for i in range(8):
		var rect: Rect2=app.controls["pack%d"%i].get_global_rect()
		check(rect==Rect2(1+i*19,246,19,22),"Eight pockets share one 19px-pitch row")
		check(app.controls["pack%d"%i].get_theme_stylebox("normal") is StyleBoxEmpty,"Pockets have no individual boxes")
	for kind in app.sim.Catalog.ITEMS:
		var icon: Image=app.Art.inventory(kind).get_image()
		var bounds:=icon.get_used_rect()
		check(icon.get_size()==Vector2i(16,16) and bounds.has_area(),"Native icon fits slot: "+kind)
		check(absf(bounds.get_center().x-8)<=1 and absf(bounds.get_center().y-8)<=1,"Opaque icon centred: "+kind)
	var kinds: Dictionary={}
	for id in app.state.items:
		var kind: String=app.state.items[id].kind
		if kinds.has(kind): continue
		kinds[kind]=true
		# Layout-only fixture: show ordinary cards in their carried form. This
		# detached view edit does not grant anything to the authoritative sim.
		if app.sim.definition(id).slot!="belt": app.state.items[id].location="pack"
		app._open_card(id)
		await process_frame
		await process_frame
		var rect: Rect2=app._card.get_global_rect()
		check(rect.position.x>=0 and rect.end.x<=154 and rect.end.y<=342,"Card fits bands: "+kind+" "+str(rect))
		check(app.pilot_call("where",["card_close"])!="","Card cancel exists "+kind)
		if kind=="bone": check(app.controls.has("card_use") and app.controls.has("card_eat"),"Multipurpose bone offers wield and eat")
		app._close_card()
		await process_frame
	app._sync()
	var kept_lines: Array=["A bell arm rises.","GUARD or step away."]
	app.lines=kept_lines.duplicate()
	var good_path: String=app._save_path
	app._save_path="res://invalid_save.json"
	app._save()
	check(not app._save_ok and app.lines==kept_lines,"Save failure never overwrites event log")
	check(app.controls.floor_label.text=="!" and app.controls.floor_label.is_visible_in_tree(),"Failure has persistent small indicator")
	var turn_before: int=app.state.turn
	app._command({"type":"turn","delta":1}); app._busy=0
	check(app.lines==kept_lines and app.state.turn==turn_before,"Looking preserves event text while save is failing")
	app._open_save_status(); await process_frame; await process_frame
	check(app.controls.has("save_retry") and app._modal.get_global_rect().end.y<=342,"Indicator opens readable retry panel")
	app._close_modal()
	app._command({"type":"turn","delta":-1}); app._busy=0
	app._command({"type":"pickup","item_id":"f1_stone"}); app._busy=0
	check(not app._save_ok and app.lines[0]=="Round stone","New gameplay events remain visible throughout save failure")
	var latest_event: Array=app.lines.duplicate()
	app._save_path=good_path; app._save()
	check(app._save_ok and app.controls.floor_label.text!="!" and app.lines==latest_event,"Successful retry clears indicator without replacing log")
	app._command({"type":"turn","delta":-1}); app._busy=0
	# Rotations are committed but free; subsequent panel checks use this state.
	initial=app.sim.state_hash()
	app._open_seed(); await process_frame; await process_frame
	check(app._modal.get_global_rect().end.y<=342,"Seed panel fits")
	check(app.controls.seed_input.get_global_rect().position.x>=12,"Seed field has padding")
	app._close_modal(); await process_frame
	var loot: Array=app.state.items.keys()
	app._loot_page(loot,0); await process_frame; await process_frame
	check(app.controls.has("loot_next") and not app.controls.has("loot_prev"),"First loot page navigation")
	check(app._modal.get_global_rect().end.y<=342,"Loot panel fits")
	app._loot_page(loot,1); await process_frame; await process_frame
	check(app.controls.has("loot_prev"),"Later loot page can go back")
	for key in app._dynamic_names:
		var rect: Rect2=app.controls[key].get_global_rect()
		check(rect.position.x>=5 and rect.end.x<=149 and rect.end.y<=312,"Loot control inside panel "+key)
	app._close_modal()
	check(app.sim.state_hash()==initial,"Cards and panels cannot mutate gameplay")
	print("M3b UI layout: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
