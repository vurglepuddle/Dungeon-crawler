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
		for key in ["hot_front","hot_item","hot_husk","hot_porter","hot_lift_deep"]:
			if not app.controls.has(key) or not app.controls[key].is_visible_in_tree(): continue
			var label_rect: Rect2=app.controls[key].get_global_rect()
			check(label_rect.position.x>=0 and label_rect.end.x<=154 and label_rect.position.y>=19 and label_rect.end.y<=118,"Marker remains in view: "+key)
			var object_key: String=key+"_object"
			check(app.controls.has(object_key),"Marker has an object hit area: "+key)
			if app.controls.has(object_key):
				var object_rect: Rect2=app.controls[object_key].get_global_rect()
				check(object_rect.size.x>=18 and object_rect.size.y>=18,"Object touch target minimum: "+key)
				check(app.get_children().find(app.controls[key])>app.get_children().find(app.controls[object_key]),"Label is above object input: "+key)
		var visible_labels: Array=[]
		for key in app.controls:
			if key.begins_with("hot_") and not key.ends_with("_object") and app.controls[key].is_visible_in_tree():
				var rect: Rect2=app.controls[key].get_global_rect()
				for other in visible_labels: check(not rect.intersects(other),"Markers do not overlap")
				visible_labels.append(rect)
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
	# Depth/occlusion fixture: the lock can be labelled even though it is a wall.
	var initial=load("res://scripts/sim/dungeon_sim.gd").new("BELL42")
	var s: Dictionary=initial.snapshot()
	var spine: int=s.pos[0]
	s.pos=[spine,6]; s.belt=["f1_key"]; s.items.f1_key.location="belt"; s.items.f1_key.floor=0; s.items.f1_key.pos=[]
	check(initial.restore_state(s),"Closed-lock view fixture validates")
	app.sim=initial; app.selected=""; app._sync()
	check(not app.view.projection("f1_lock").is_empty() and app.controls.hot_front.visible,"Closed lock projects its unlock marker")
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
	print("M3 view: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
