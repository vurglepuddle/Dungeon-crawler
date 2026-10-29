extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
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
	DirAccess.make_dir_recursive_absolute("user://tests")
	var profile=FileAccess.open("user://tests/m5a_ui_profile.json",FileAccess.WRITE); profile.store_string('{"fallen":false}'); profile.close()
	app._profile_path="user://tests/m5a_ui_profile.json"
	app._save_path="user://tests/m5a_ui.json"; root.add_child(app)
	check(app._profile_path!="user://profile.json","Tests isolate the persistent profile")
	for text in ['{"fallen":1}','[]','{bad']:
		profile=FileAccess.open("user://tests/m5a_bad_profile.json",FileAccess.WRITE); profile.store_string(text); profile.close()
		check(not app.Profile.fallen("user://tests/m5a_bad_profile.json"),"Malformed unlock profile refuses without script errors")
	app._open_seed(); check(not app.controls.has("seed_deep"),"The first tutorial cannot be skipped through the UI"); app._close_modal()
	app.new_adventure("BELL42")
	var proof: Dictionary=Legacy.build("BELL42",3,false,"keep")
	for action in proof.actions:
		if action.type=="pickup" and action.item_id=="f3_seal": break
		check(app.sim.apply(action).accepted,"Ordinary pre-Fall action")
	app._sync(); app._command({"type":"pickup","item_id":"f3_seal"})
	check(app._transitioning and app.state.floor==4 and app.Profile.fallen(app._profile_path),"Fall commits atomically and unlocks profile before animation")
	while app._transitioning: await process_frame
	check(app.controls.has("wake_close") and app._optional_overlay.visible,"Waking card is above vines")
	app._wake_close(); app._open_map()
	var map=app._map_control; map.layout_seen()
	check(map.cell_size==8 and map._center(app.state.pos).distance_to(map.size/2)<0.01,"Deep map opens centred on Finder at readable pitch")
	var drag:=InputEventScreenDrag.new(); drag.relative=Vector2(24,16); map._gui_input(drag); map.layout_seen()
	check(map.pan==Vector2(24,16),"Real drag input pans the map")
	app._close_modal(); app._open_seed()
	check(app.controls.has("seed_deep"),"Profile unlock exposes THE DEEP choice")
	app._seed_input.text="BELL42"; app._deep_submit()
	check(app.state.floor==4 and app.state.hp==5 and app.state.pack.is_empty(),"Skip starts empty at 5 HP with same card")
	app._save(); app._show_menu("title"); app._continue()
	check(app.controls.has("wake_close") and app._pending_wake=="fall","Continue restores an undismissed waking card")
	app._wake_close()
	# An imminent blow in a valid schema-3 snapshot tests the death transaction.
	var s: Dictionary=app.sim.snapshot(); var f: Dictionary=s.floors[3]
	s.pos=[8,4]; s.hp=1; f.tiles[6*f.width+8]=0; var dawn: Dictionary=f.fixtures.filter(func(v): return v.get("passage",false))[0]; dawn.open=true; dawn.revealed=true
	var actor: Dictionary=f.actors[0]; actor.pos=[8,3]; actor.state="windup"; actor.intent={"cell":s.pos.duplicate(),"due_in":1}; actor.kind="husk"; actor.hp=2
	s.items.d4_shard.location="equip"; s.items.d4_shard.floor=0; s.items.d4_shard.pos=[]; s.items.d4_shard.slot="hand"; s.equipment.hand="d4_shard"
	for id in ["d4_torch","d4_coat"]:
		s.items[id].location="pack"; s.items[id].floor=0; s.items[id].pos=[]; s.pack.append(id)
	s.pack.erase("d4_coat"); s.items.d4_coat.location="equip"; s.items.d4_coat.slot="body"; s.items.d4_coat.spent=true; s.equipment.body="d4_coat"
	check(app.sim.restore_state(s),"Hostile pre-death state is valid")
	app._sync(); app._command({"type":"wait"})
	check(app.state.hp==5 and app.state.wakes==1 and app.state.equipment.hand=="d4_shard" and app.state.belt==["f3_seal"],"Death preserves Seal/weapon and wakes at 5")
	check(app.state.pos==f.start and app.state.pack.is_empty() and app.state.equipment.body=="" and app.state.items.d4_torch.pos==[8,4] and app.state.items.d4_coat.pos==[8,4],"Pack/ worn coat drop at death site; waking uses current arrival")
	check(app.sim._floor().actors.all(func(a): return a.state!="windup"),"No actor wakes mid-blow")
	check(Codec.validate(app.sim.snapshot()),"Post-death state saves cleanly")
	while app._transitioning: await process_frame
	app._wake_close(); app._save(true); app._show_menu("title"); app._continue()
	check(app.state.wakes==1 and app.state.floor==4,"New-profile Continue retains progress")
	for repetition in range(3):
		s=app.sim.snapshot(); s.pos=[8,4]; s.hp=1
		actor=s.floors[3].actors[0]; actor.pos=[8,3]; actor.state="windup"; actor.intent={"cell":[8,4],"due_in":1}
		check(app.sim.restore_state(s),"Repeated hostile state validates")
		app.sim.apply({"type":"wait"})
		check(app.sim._s.wakes==repetition+2 and Codec.validate(app.sim.snapshot()),"Repeated deaths preserve valid progress and unique items")
		check(app.sim.apply({"type":"move","step":"fwd"}).accepted and app.sim._s.hp==5,"Arrival provides a safe first step")
	# A farther stair hotspot must not cover the web's BURN target.
	s=app.sim.snapshot(); f=s.floors[3]
	s.pos=[f.landing[0],f.landing[1]+2]; s.facing=0
	s.items.d4_torch.location="pack"; s.items.d4_torch.floor=0; s.items.d4_torch.pos=[]; s.items.d4_torch.lit=true; s.pack.append("d4_torch")
	check(app.sim.restore_state(s),"Nested web/stair UI fixture validates")
	app.selected="d4_torch"; app._busy=0; app._sync()
	check(not app._world_markers.has("d4_down"),"Blocked distant stairs cannot steal a web tap")
	app.controls[app._world_markers.d4_last_web].pressed.emit()
	check(app.sim._fixture("d4_last_web").open,"Real web target burns the near obstruction")
	app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M5a UI: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
