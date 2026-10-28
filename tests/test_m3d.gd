extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Survey=preload("res://scripts/ui/survey.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m3d_unit.json"; root.add_child(app); current_scene=app
	await process_frame
	check(app.controls.splash_skip.visible,"Publisher is immediately skippable")
	check(app.controls.start.get_global_rect().end.y<=342 and app.controls.continue.get_global_rect().end.y<=342,"Run controls available under splash")
	app._skip_splash()
	check(app._menu_art.texture==Paint.texture("res://assets/art/screens/title.png"),"Skip reveals the painted title")
	check(app.new_run("BELL42"),"Visual run starts")
	var initial_hash: String=app.sim.state_hash()
	var entry: Dictionary=app._survey.floor_data(1)
	check(entry.walked.count("1")==1 and entry.seen.count("1")>1,"Walked is distinct from glimpsed on entry")
	var spine: int=app.state.pos[0]
	check(entry.seen[16*17+spine]=="0","View survey does not reveal the wall behind the camera")
	check(not entry.landmarks.has("f1_up"),"Standing on the exit cell cannot reveal its arch behind the camera")
	var masks: Dictionary=app._survey.save()
	var atlas=Survey.new()
	check(atlas.restore(masks,app.state) and atlas.hash_value()==app._survey.hash_value(),"Survey checksum round trips")
	var corrupted: Dictionary=masks.duplicate(true); corrupted.floors[0].seen="1".repeat(289)
	check(not atlas.restore(corrupted,app.state) and atlas.floor_data(1).seen.count("1")==0,"Bad survey checksum falls back to blank knowledge")
	corrupted=masks.duplicate(true); corrupted.floors[0].walked[0]="1"; corrupted.floors[0].seen[0]="1"
	corrupted.sha256=JSON.stringify(corrupted.floors,"",true).sha256_text()
	check(not atlas.restore(corrupted,app.state),"Walked masonry is rejected even with a valid checksum")
	for _i in range(2): app._busy=0; app._command({"type":"turn","delta":1})
	check(app.view.projection("f1_up").get("architecture",false),"Exit is the south wall face")
	check(app._survey.floor_data(1).landmarks.has("f1_up"),"Looking at the exit discovers its map glyph")
	check(not app.view._sprites.any(func(s): return s.id=="f1_up"),"No loose exit sprite remains")
	app._busy=0; app._command({"type":"turn","delta":-1})
	check(app.view.projection("lift_home").get("architecture",false),"Dead lift occupies its east wall alcove")
	var face_layout: String=JSON.stringify(app.view._faces,"",true)
	app._busy=0; app._command({"type":"turn","delta":1})
	check(face_layout==JSON.stringify(app.view._faces,"",true),"Architecture orientation is independent of the camera")
	check(app.controls.map.get_theme_stylebox("normal") is StyleBoxTexture,"MAP is a painted physical button")
	app._busy=0; app._open_map(); await process_frame
	var map=app._modal.get_child(0).get_child(1)
	check(map.data.survey.walked.count("1")==1,"Opening map cannot manufacture footsteps")
	check(map.frontier_cells().size()>0,"Unsurveyed edges retain question marks")
	app._close_modal()
	var survey_hash: String=app._survey.hash_value()
	app._save()
	var store=preload("res://scripts/persistence/save_store.gd")
	var stored: Dictionary=store.load_run(app._save_path)
	check(stored.ui.survey.sha256==survey_hash,"Every action save includes the survey")
	app._survey.reset(2); app._continue()
	check(app._survey.hash_value()==survey_hash,"Continue restores walked/seen bits exactly")
	var snapshot: Dictionary=Sim.new("BELL42").snapshot()
	snapshot.pos=[spine,11]; snapshot.facing=0
	check(app.sim.restore_state(snapshot),"Closed-gate sightline fixture validates")
	app._sync()
	check(app.view.visible_cells().all(func(c): return c[1]>=10),"Closed bars never reveal survey knowledge beyond them")
	check(app.view._depths[74]>1.5 and app.view._portals.any(func(p): return p.id=="f1_gate" and p.columns.size()>0),"Grate paints over the real corridor without inventing a solid render wall")
	for fixture in snapshot.floors[0].fixtures:
		if fixture.id=="f1_gate": fixture.open=true; fixture.latched=true
	check(app.sim.restore_state(snapshot),"Open-gate sightline fixture validates")
	app._sync()
	check(app.view.visible_cells().any(func(c): return c[1]<10),"Opening a gate reveals only actual forward rays")
	snapshot.floors[0].actors[0].pos=[spine,10]
	check(app.sim.restore_state(snapshot),"Actor standing in open threshold validates")
	app._sync()
	var layers: Array=app.view._column_layers[74]
	var portal_index: int=-1; var actor_index: int=-1
	for i in range(layers.size()):
		if layers[i].has("portal") and layers[i].portal.id=="f1_gate": portal_index=i
		if layers[i].has("sprite") and layers[i].sprite.id=="f1_husk": actor_index=i
	check(portal_index>=0 and actor_index>portal_index,"An actor on the threshold paints in front of the arch, retaining its tell")
	var distant: Dictionary=app.sim.view_snapshot(); distant.pos=[spine,5]; distant.facing=0
	for fixture in distant.fixtures:
		if fixture.type=="lock": fixture.open=true
	app.view.update_state(distant)
	check(app.view.visible_cells().has([spine,3]) and app.view.projection("f1_down").is_empty(),"Seeing a stair's logical cell cannot discover its unlit distant backing face")
	app._sync()
	var now: String=app.sim.state_hash()
	app.view._process(1.0); app._ambience._process(1.0)
	check(now==app.sim.state_hash(),"Sconces, sparkle, dust and flicker cannot advance rules")
	for hp in [6,4,3,2,1]:
		app.state.hp=hp; app._hurt_time=0
		var path: String=app.portrait_path()
		check(path.contains("near_death_v2") if hp==1 else (path.contains("hurt_v2") if hp<=3 else path.contains("finder_fine")),"Authored face threshold %d"%hp)
	app.state.hp=1; app._hurt_time=0.2
	check(app.portrait_path().contains("near_death_v2"),"Near-death face wins over transient hurt")
	var signatures: Dictionary={}
	for index in range(100):
		var alphabet: String=Sim.Gen.ALPHABET
		var sim=Sim.new("DD"+alphabet[index/32]+alphabet[index%32],1+index%4)
		var full: Dictionary=sim.snapshot()
		for number in range(full.floor_count):
			var picture: Dictionary=full.floors[number].duplicate(true)
			picture.floor=number+1; picture.seed=full.seed
			app.view.state=picture; app.view._architecture()
			var required: Array=picture.fixtures.filter(func(f): return f.type in ["exit","stairs_up","stairs_down","lift","panel"])
			check(app.view._faces.size()==required.size(),"Every architectural fixture gets one distinct backing wall")
			for fixture in required:
				check(app.view._faces.values().any(func(f): return f.id==fixture.id),"Backed architecture: "+fixture.id)
			var key: String=JSON.stringify(app.view._faces,"",true)
			picture.facing=3; app.view._architecture()
			check(JSON.stringify(app.view._faces,"",true)==key,"Stable world faces over seed/floor sweep")
			signatures[key]=true
	check(signatures.size()>=10,"Architecture sweep covers distinct backing-wall arrangements")
	app._ambience.set_process(false); app.queue_free(); await process_frame
	await create_timer(0.3).timeout
	print("M3d presentation/survey: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
