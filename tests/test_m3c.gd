extends SceneTree
const W=preload("res://scripts/gen/witness.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m3c_ui.json"
	root.add_child(app); current_scene=app
	await process_frame
	check(app._music!=null and app._music._current_track=="title","Title selects the original score")
	for name in ["music","sound"]:
		check(app.controls[name].get_global_rect().end.y<=342,"Both audio controls fit: "+name)
		check(app.controls[name].size.y>=18,"Audio target minimum: "+name)
	app._music.set_enabled(true); app.sfx.enabled=true
	app._toggle_music()
	check(not app._music.enabled and app.sfx.enabled,"Music mute leaves SFX enabled")
	app._toggle_sound()
	check(not app._music.enabled and not app.sfx.enabled,"SFX can be muted independently")
	app._music.set_enabled(true); app.sfx.enabled=true; app._load_settings()
	check(not app._music.enabled and not app.sfx.enabled,"Independent preferences reload from isolated settings")
	app._toggle_music(); app._toggle_sound()
	check(app._music.enabled and app.sfx.enabled,"Both channels can be enabled again")
	check(app.new_run("BELL42"),"M3c UI run starts")
	check(app._music._current_track=="floor","Run changes to floor score")
	var hash_before: String=app.sim.state_hash()
	app._command({"type":"turn","delta":1})
	check(app._compass_velocity>0,"Turning kicks the physical compass needle")
	app._process(0.04)
	check(absf(app._compass_swing)>0.01,"Compass visibly swings independently of facing label")
	var turn_hash: String=app.sim.state_hash()
	for _i in range(200): app._process(0.016)
	check(absf(app._compass_swing)<0.001 and app.sim.state_hash()==turn_hash,"Compass settles without advancing simulation")
	app._busy=0; app._command({"type":"turn","delta":-1}); app._busy=0
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	var saw_plate:=false; var saw_lever:=false; var saw_hit:=false; var saw_porter:=false
	for action in proof.actions:
		while app._transitioning: await process_frame
		app._busy=0
		if action.type=="hit" and not saw_hit:
			var target: Dictionary=app.view.projection(action.target_id)
			check(not target.is_empty(),"Strike has a visible pre-hit target")
			app._command(action)
			check(app.view._strike.kind=="edge" and app.view._strike.damage>0,"Wielded EDGE produces slash and actual damage")
			check(app._busy<=0.13,"Strike never extends input gate to its 240ms lifetime")
			hash_before=app.sim.state_hash(); app.view._process(0.25)
			check(app.view._strike.is_empty() and app.sim.state_hash()==hash_before,"Effect expires without a simulation action")
			saw_hit=true
		else: app._command(action)
		if action.type=="hit" and not app.view._strike.is_empty():
			var dead: bool=not app.view._sprites.any(func(s): return s.id==action.target_id)
			if dead:
				check(app.view._strike.has("ghost") and app.view._strike.ghost.id==action.target_id,"Lethal hit retains a presentation-only recoil")
		if action.type in ["move","turn","stairs","ride"]:
			check(app.view._strike.is_empty(),"Camera changes clear old strike coordinates")
		check(app.state.revision==app.sim.snapshot().revision,"Scene follows committed action")
		if action.type=="drop" and action.item_id=="f1_stone":
			var sprites: Array=app.view._sprites
			var plate_index: int=-1; var stone_index: int=-1
			for i in range(sprites.size()):
				if sprites[i].id=="f1_plate": plate_index=i
				if sprites[i].id=="f1_stone": stone_index=i
			check(plate_index>=0 and stone_index>plate_index,"Stone is painted after its supporting plate")
			if plate_index>=0:
				var plate: Dictionary=sprites[plate_index]
				check(plate.rect.size.y<=20 and plate.rect.size.x>=40,"Pressed plate retains shallow floor aspect")
				check(plate.texture.resource_path.contains("plate_down"),"Own weight or stone selects pressed slab")
			saw_plate=true
		if action.type=="latch":
			var sprites: Array=app.view._sprites.filter(func(s): return s.id==action.target_id)
			check(sprites.size()==1,"Spent lever remains painted")
			if not sprites.is_empty():
				check(sprites[0].texture.resource_path.contains("_down_"),"Lever handle flips down after latch")
				check(absf(sprites[0].rect.get_center().x-74)>15,"Lever is attached to side wall, clear of actor centre")
			saw_lever=true
		if action.type=="return_item":
			var sprites: Array=app.view._sprites.filter(func(s): return s.kind=="porter")
			check(sprites.size()==1 and sprites[0].texture.resource_path.contains("porter_restored"),"Return selects painted restored Porter")
			saw_porter=true
		if app.state.status=="playing":
			for sprite in app.view._sprites:
				if sprite.kind!="husk": continue
				var pose: String="recoil" if sprite.state=="recovery" else sprite.state
				check(sprite.texture.resource_path.contains("bell_husk_"+pose),"Simulation pose selects registered painting: "+pose)
	check(saw_plate and saw_lever and saw_hit and saw_porter,"Full route exercised all phone fixtures")
	check(app.state.status=="won" and app.state.hp==6 and app.state.turn==66,"Art/audio preserve damage-free restoration route")
	app._show_menu("end")
	check(app._music._current_track=="win","Committed victory selects short win cue")
	var playback: WeakRef=weakref(app._music._playback)
	app._retire_audio()
	await create_timer(0.3).timeout
	check(playback.get_ref()==null and not app._music.is_playing(),"Stopped generator retires after the engine's deferred audio cleanup")
	check(app._music.play("title") and app._music.is_playing(),"Scene shutdown leaves the autoload reusable for another scene")
	app.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("M3c integration: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
