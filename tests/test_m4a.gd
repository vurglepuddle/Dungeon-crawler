extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate(); app._save_path="user://tests/m4a_unit.json"
	root.add_child(app); current_scene=app; await process_frame
	var directory:=DirAccess.open("user://"); directory.make_dir_recursive("tests")
	var legacy_file:=FileAccess.open(app._save_path,FileAccess.WRITE)
	legacy_file.store_string(FileAccess.get_file_as_string("res://tests/fixtures/m3f_run.json")); legacy_file.close()
	app._continue()
	check(app.state.floor_count==2 and app.state.rules_version=="m3.3" and app.sim.state_hash()=="14bc4617236bd22d78840604a84d7d5a4d49c6a5debe23859c1b536fe622db23","Actual Continue keeps the M3f two-floor cohort without upgrading")
	check(app.new_run("BELL42",2),"Two-floor interaction fixture starts")
	var bot=W.new(); bot.sim=Sim.new("BELL42")
	check(bot._pickup("f1_torch") and bot.go(bot.sim._fixture("f1_brazier").pos),"Reach brazier carrying cold reeds")
	for action in bot.actions: check(app.sim.apply(action).accepted,"Ordinary torch setup")
	app._sync()
	check(app.verbs[0].label=="LIGHT" and app.selected=="","Pocketed torch offers LIGHT without selection")
	var light: String=app.pilot_call("where",["hot_f1_brazier"])
	check(light!="","Painted brazier has a named actual tap")
	var key: String=app._world_markers.f1_brazier
	app.controls[key].pressed.emit(); app._busy=0
	check(app.state.items.f1_torch.lit,"Brazier callback lights the same pocketed reeds")
	app._command({"type":"equip","item_id":"f1_torch"}); app._busy=0
	bot=W.new(); bot.sim=Sim.new("BELL42"); check(bot.sim.restore_state(app.state),"Equipped torch fixture adopts")
	check(bot.go(bot.sim._fixture("f1_web").pos),"Walk to web with lit torch equipped")
	for action in bot.actions: check(app.sim.apply(action).accepted,"Ordinary web approach")
	app._sync()
	check(app.selected=="" and app.verbs[0].label=="BURN","Equipped lit reeds offer BURN after selection clears")
	key=app._world_markers.f1_web; app.controls[key].pressed.emit(); app._busy=0
	check(app.sim._fixture("f1_web").open and app.state.equipment.hand=="f1_torch","Web tap burns without throwing or unequipping")
	check(Codec.validate(app.sim.snapshot()),"Direct light/burn save validates")
	check(app.VIEW_RECT==Rect2(3,21,148,150) and app.controls.compass.get_rect()==Rect2(85,294,66,44),"Owner overlay registration is exact")
	app._open_map(); await process_frame
	check(not app._optional_overlay.visible,"Overlay hides while the map is open")
	app._close_modal(); app._busy=0; app._equipment_card("hand"); await process_frame
	check(not app._optional_overlay.visible,"Overlay hides while a card is open")
	app._close_card(); check(app._optional_overlay.visible,"Overlay returns above the needle after closing panels")
	app._travel_tap("f1_up")
	check(app.lines[0]=="Step closer.","Remote exit inspection explains reach")
	# Art registration is tested from dedicated native canvases, not opaque
	# bounds refitted to a common icon size.
	for kind in ["knife","shard","club","stone","bone","bread","tonic","coat","coat_spent","key","clapper","lamp"]:
		for d in range(1,4):
			var texture=app.Paint.texture("res://assets/art/items/item_%s_d%d.png"%[kind,d])
			check(texture.get_size()==[Vector2(64,48),Vector2(40,30),Vector2(24,18)][d-1],"World item canvas "+kind+"/"+str(d))
	app.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("M4a interactions: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
