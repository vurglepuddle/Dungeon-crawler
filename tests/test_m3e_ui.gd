extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m3e_ui.json"; root.add_child(app); current_scene=app
	await process_frame
	check(app.new_run("BELL42"),"Expanded app run starts")
	var proof: Dictionary=W.build("BELL42",2,false,"return",true)
	var pure=Sim.new("BELL42")
	for action in proof.actions:
		while app._transitioning: await process_frame
		app._busy=0
		if action.type=="toss":
			var before: String=app.sim.state_hash()
			app._open_toss(action.item_id)
			check(app._public_state().tossing==action.item_id and app.view.toss_lane.size()==2,"Public preview matches the two real lane cells")
			check(app.sim.state_hash()==before,"Opening a preview spends no beat or revision")
			for key in ["verb0","verb1"]:
				check(app.controls[key].size.x>=18 and app.controls[key].size.y>=18,"Toss confirm/cancel have usable touch targets")
			app._cancel_toss()
			check(app.sim.state_hash()==before and app.view.toss_lane.is_empty(),"Cancellation clears only presentation")
		check(pure.apply(action).accepted,"Pure reference action")
		app._command(action)
		check(app.sim.state_hash()==pure.state_hash(),"UI route matches pure sim after "+action.type)
		if action.type=="toss": check(app.lines[0]=="It takes the offering.","Consumed FOOD reports feeding rather than a floor landing")
		if action.type=="burn":
			check(app.view._burning.has(action.target_id) and app.sim._fixture(action.target_id).open,"Fire animation follows an already open saved web")
			check(app.selected=="","Completed burning restores ordinary world affordances")
		if action.type=="dispel":
			check(not app.view._dispel.is_empty() and app.sim._actor(action.target_id).hp==0,"Ghost recoil is presentation after a committed dispel")
			var before: String=app.sim.state_hash(); app.view._process(0.3)
			check(app.view._dispel.is_empty() and app.sim.state_hash()==before,"Ghost fade cannot resolve another action")
		if action.type=="pickup" and action.item_id=="f2_seal": check(app.view.held.kind=="seal","Dawn is held up automatically for the return")
		if action.type=="cut" and action.target_id=="f1_panel":
			check(app.view._faces.values().any(func(f): return f.id=="f1_panel" and f.texture_path.ends_with("fixture_v2_f1_cache_open_64.png") and f.panel_state==""),"Secret uses the painted inset cache face without runtime rectangles")
	check(app.state.status=="won" and app.state.hp==6 and app._public_state().secrets_found==1,"Whole app tour wins unharmed with the cache opened")
	app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M3e UI: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
