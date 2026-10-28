extends SceneTree
const W=preload("res://scripts/gen/witness.gd")
const Map=preload("res://scripts/ui/map_view.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m3_layout.json"; root.add_child(app); current_scene=app
	check(app.new_run("BELL42"),"View fixture starts")
	await process_frame
	var map=Map.new(); map.size=Vector2(128,231); map.data=app.sim.view_snapshot(); root.add_child(map)
	map.layout_seen()
	check(map.cell_size>=8,"Entry automap uses large cells")
	var saved_bounds: Rect2i=map.seen_bounds
	check(saved_bounds.size.x<17 and saved_bounds.size.y<17,"Unseen map extents do not set its scale")
	check(app.view.lamp(3.6)==0 and app.view.lamp(3.0)<app.view.lamp(1.0),"Lamp extinguishes distant surfaces")
	var surface=app.view._surfaces
	app._sync()
	check(app.view._surfaces==surface,"Free UI sync reuses floor/ceiling texture")
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	for action in proof.actions:
		var result: Dictionary=app.sim.apply(action)
		check(result.accepted,"View probe uses ordinary actions")
		app._sync()
		await process_frame
		for key in app.controls:
			if not key.begins_with("hot_") or not app.controls[key].is_visible_in_tree(): continue
			var control: Control=app.controls[key]
			var hit: Rect2=control.get_global_rect()
			check(app.VIEW_RECT.encloses(hit),"World target remains in dungeon picture: "+key)
			check(hit.size.x>=18 and hit.size.y>=18,"World touch target minimum: "+key)
			check(control.text=="" and control.get_theme_stylebox("normal") is StyleBoxEmpty,"World target has no label or box: "+key)
			check(app.pilot_call("where",[key+"_object"])==app.pilot_call("where",[key]),"Historical object alias remains valid: "+key)
		for cue in app.view.interaction_cues:
			check(not app.view.projection(cue.id).is_empty(),"Glint belongs to projected object")
		if action.type=="unlock":
			check(not app.view.projection(action.target_id).is_empty() or app.sim.fixture_actions().all(func(f): return f.action.type!="unlock"),"Unlocked gate clears its marker")
		if action.type=="return_item":
			check(not app.view.projection("bell_porter").is_empty(),"Porter has a visible painted projection")
			app._porter_card(app.sim.local_fixtures().filter(func(f): return f.type=="porter")[0])
			await process_frame; await process_frame
			check(app._modal.get_global_rect().end.y<=342,"Porter dialogue fits")
			app._close_modal()
		if action.type=="stairs":
			var up: Dictionary=app.sim.floor_data().fixtures.filter(func(f): return f.type=="stairs_up")[0]
			check(not app.view.projection(up.id).is_empty(),"Underfoot up-stair remains visible on arrival")
	var hash_before: String=app.sim.state_hash()
	app._open_map(); await process_frame
	check(app.sim.state_hash()==hash_before,"Map remains free")
	app._close_modal()
	# Depth/occlusion fixture: the lock remains a target even though it is a wall.
	var initial=load("res://scripts/sim/dungeon_sim.gd").new("BELL42")
	var s: Dictionary=initial.snapshot()
	var spine: int=s.pos[0]
	s.pos=[spine,6]; s.belt=["f1_key"]; s.items.f1_key.location="belt"; s.items.f1_key.floor=0; s.items.f1_key.pos=[]
	check(initial.restore_state(s),"Closed-lock view fixture validates")
	app.sim=initial; app.selected=""; app._sync()
	check(not app.view.projection("f1_lock").is_empty() and app.controls.hot_front.visible,"Closed lock projects its unlock marker")
	app.selected="f1_key"; app._sync()
	check(app.controls.verb0.text=="UNLOCK" and app.view.interaction_cues.any(func(c): return c.id=="f1_lock" and c.selected),"Selected belt key marks its matching lock")
	app.selected=""; app._sync()
	for item in app.state.items.values():
		if item.floor==1 and item.location=="floor" and item.pos[1]<=4: check(app.view.projection(item.id).is_empty(),"Closed lock occludes room loot")
	# Floor loot at a peaceful owner's feet must not sit behind its torso.
	s=initial.snapshot(); s.pos=[spine,3]; s.facing=3
	s.items.f1_stone.pos=[spine-1,3]
	check(initial.restore_state(s),"Owner/loot view fixture validates")
	app._sync()
	var item_projection: Dictionary=app.view.projection("f1_stone")
	var owner_projection: Dictionary=app.view.projection("bell_porter")
	check(not item_projection.rect.has_point(owner_projection.anchor),"Loot projects beside the owner's body")
	# Selected PLACE remains explicit in the strip, with coloured object cues.
	app.sim=load("res://scripts/sim/dungeon_sim.gd").new("BELL42")
	app.sim.apply({"type":"pickup","item_id":"f1_stone"})
	app.sim.apply({"type":"move","step":"fwd"})
	app.selected="f1_stone"; app._sync()
	check(app.controls.verb0.text=="PLACE" and app.controls.hot_front.visible,"Selected item exposes its actual world verb")
	app._open_card("f1_stone")
	check(app.controls.verb0.position.y==179 and app.controls.verb0.position.y+app.controls.verb0.size.y<=208,"Selected verb remains visible above item card")
	check(app.view.interaction_cues.size()==1 and app.view.interaction_cues[0].selected and app.view.interaction_cues[0].colour==app._selection_colour(),"Selected target glints in item colour")
	hash_before=app.sim.state_hash(); app.view._process(0.25)
	check(app.sim.state_hash()==hash_before,"Glint pulse cannot change sim state")
	print("M3b view: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
