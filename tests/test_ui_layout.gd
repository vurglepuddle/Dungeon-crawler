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
	for key in ["fwd","back","turn_l","turn_r","strafe_l","strafe_r","map","seed","portrait","pack0","pack7","equip_hand","belt_seal"]:
		var control: Control=app.controls[key]
		check(control.size.x>=18 and control.size.y>=18,"Touch target "+key)
		check(app.pilot_call("where",[key])!="","Named control "+key)
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
		check(rect.position.x>=0 and rect.end.x<=154 and rect.end.y<=262,"Card fits bands: "+kind+" "+str(rect))
		check(app.pilot_call("where",["card_close"])!="","Card cancel exists "+kind)
		if kind=="bone": check(app.controls.has("card_use") and app.controls.has("card_eat"),"Multipurpose bone offers wield and eat")
		app._close_card()
		await process_frame
	app._sync()
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
	print("M2 UI layout: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
