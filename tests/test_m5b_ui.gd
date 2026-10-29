extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Bot=preload("res://scripts/gen/deep_witness.gd")
const Legacy=preload("res://scripts/gen/witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(note)
func _initialize() -> void:
	Engine.set_meta("pilot",true); _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._profile_path="user://tests/m5b_ui_profile.json"; app._save_path="user://tests/m5b_ui.json"; root.add_child(app)
	app._open_seed(); app._seed_input.text="BELL42"; app._seed_submit()
	check(app.state.get("key_metals",false),"Interactive new Abbey opts into metals")
	var proof: Dictionary=Legacy.build("BELL42",3,false,"keep"); check(proof.ok,"Ordinary Abbey plan")
	for action in proof.actions:
		if action.type=="pickup" and action.item_id=="f3_seal": break
		check(app.sim.apply(action).accepted,"Metal Abbey uses unchanged ordinary route")
	app._sync(); app._busy=0; app._command({"type":"pickup","item_id":"f3_seal"})
	check(app.controls.floor_label.text=="3/5" and app._fall_hud_floor==3,"Fall HUD keeps old floor while committed state is already Deep")
	while app._transitioning: await process_frame
	check(app.controls.floor_label.text=="4/5" and app._fall_hud_floor==0,"Waking card displays the Deep floor")
	app._wake_close()
	proof=Bot.new().prove("BELL42",{"metals":true}); check(proof.ok,"Metal Deep plan")
	# Use the empty-hands start: scattered possessions are unnecessary.
	app.new_adventure("BELL42","deep",{"metals":true}); app._wake_close()
	var checked_wrong:=false
	for action in proof.actions:
		if action.type=="unlock" and not checked_wrong:
			var before: String=app.sim.state_hash(); var raw: Dictionary=app.sim.snapshot(); var lock: Dictionary=app.sim._fixture(action.target_id)
			var matching: Array=raw.belt.filter(func(id): return app.sim.key_fits(lock,id))
			for id in matching: raw.belt.erase(id); raw.items[id].location="floor"; raw.items[id].floor=raw.floor; raw.items[id].pos=raw.pos.duplicate()
			var wrong=Sim.new(); check(wrong.restore_state(raw),"Wrong-metal snapshot is structurally valid")
			var h: String=wrong.state_hash(); check(not wrong.apply(action).accepted and wrong.state_hash()==h,"Wrong metal refuses without a turn or mutation")
			check(app.sim.state_hash()==before,"Negative test never touches live run"); checked_wrong=true
		check(app.sim.apply(action).accepted,"Ordinary metal route step")
		if action.type=="unlock" and checked_wrong: break
	check(checked_wrong,"Route exercises a real negative unlock")
	app._sync(); app._busy=0; app._belt_card("key"); await process_frame
	check(app.controls.belt_key.item_texture==app.Art.inventory("key") and app.controls.belt_key.badge=="x2","Belt stays generic with count")
	for id in ["d4_key","d4_fire_key"]:
		check(app.controls.has("belt_"+id) and app.controls["belt_"+id].text.contains("key"),"Key list names metal and door")
		check(app.controls["belt_"+id].get_global_rect().end.y<342,"Key list fits screen")
	app._choose_belt("d4_fire_key"); check(app._card!=null,"Key list opens illustrated card")
	app._close_card(); app._save(); var hash: String=app.sim.state_hash(); app._show_menu("title"); app._continue()
	check(app.sim.state_hash()==hash and app.state.get("key_metals",false),"Continue preserves new key rules")
	# Required metadata refuses cleanly, even where a lock references malformed key data.
	for malformed in [1,[],{},null]:
		var bad: Dictionary=app.sim.snapshot(); bad.items.d4_key=malformed
		check(not Codec.validate(bad),"Malformed referenced key refuses cleanly")
	app.new_adventure("BELL42","deep",{"metals":true,"deep_floors":3}); app._wake_close()
	for id in app.sim._s.items:
		var item: Dictionary=app.sim._s.items[id]
		if item.kind!="key": continue
		item.location="belt"; item.floor=0; item.pos=[]; app.sim._s.belt.append(id)
	check(Codec.validate(app.sim.snapshot()),"Parameterized multi-Deep belt can retain all keys")
	app._sync(); app._busy=0; app._belt_card("key"); await process_frame
	check(app.controls.keys_close.get_global_rect().end.y<342,"Large key collection scrolls without hiding CLOSE")
	app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M5b UI: %d checks, %d failures"%[checks,failures]); quit(1 if failures else 0)
