extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
const Materials=preload("res://scripts/art/plane_materials.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var min_turns:=10000; var max_turns:=0
	for n in range(300):
		var seed: String="B3VJ5K" if n==0 else "F%05d"%n
		# Seed alphabet omits 0/1; use the generator's actual alphabet.
		if n>0:
			seed="F"; var value: int=n
			for _i in range(5): seed+=Sim.Gen.ALPHABET[value%32]; value/=32
		var sim=Sim.new(seed,1+n%4); var s: Dictionary=sim.snapshot()
		check(Codec.validate(Codec.normalize(JSON.parse_string(Codec.canonical(s)))),"Dressing snapshot round trip "+seed)
		for i in range(s.floor_count):
			var f: Dictionary=s.floors[i]
			var reserved: Array=[f.start,f.landing]
			for fixture in f.fixtures: reserved.append(fixture.pos)
			for actor in f.actors: reserved.append(actor.pos)
			for item in s.items.values():
				if item.location=="floor" and item.floor==i+1 and item.kind!="seal": check(not reserved.has(item.pos),"No loot on fixtures, actors or landings "+seed+"/"+item.id)
			for prop in f.get("props",[]):
				check(not reserved.has(prop.pos),"No props on interactables "+seed)
				check(not s.items.values().any(func(item): return item.location=="floor" and item.floor==i+1 and item.pos==prop.pos),"No prop conceals starting loot")
		var proof: Dictionary=W.build(seed,2,false,"return",true)
		check(proof.ok,"Dressed floor ordinary round-trip witness "+seed+": "+proof.reason)
		if proof.ok: min_turns=mini(min_turns,proof.snapshot.turn); max_turns=maxi(max_turns,proof.snapshot.turn)
	var sim=Sim.new("B3VJ5K")
	check(sim.apply({"type":"drop","item_id":"knife_start"}).accepted and sim.snapshot().equipment.hand=="" and sim.reachable_items().has("knife_start"),"Drop equipped knife directly onto own cell")
	check(sim.apply({"type":"pickup","item_id":"knife_start"}).accepted and sim.apply({"type":"equip","item_id":"knife_start"}).accepted,"Dropped equipment can be picked up and equipped again")
	check(sim.apply({"type":"turn","delta":1}).accepted,"Face dead lift")
	check(sim.apply({"type":"move","step":"fwd"}).accepted,"Enter lift landing")
	var hash_before: String=sim.state_hash()
	var dead: Dictionary=sim.apply({"type":"move","step":"fwd"})
	check(not dead.accepted and dead.reason=="The lift is dead." and sim.state_hash()==hash_before,"Forward into shut lift explains it without a beat")
	var proof: Dictionary=W.build("B3VJ5K",2,false,"return")
	var stair_selected_state: Dictionary={}
	sim=Sim.new("B3VJ5K")
	for action in proof.actions:
		if action.type in ["stairs","ride","leave"]:
			var fixture: Dictionary=sim._fixture(action.target_id)
			var bot=W.new(); bot.sim=sim
			check(bot.go(fixture.pos,false),"Walk onto travel landing")
			var face: Dictionary=Faces.all(sim.floor_data())[fixture.id]
			var toward: Array=[-face.normal[0],-face.normal[1]]
			check(bot._face(Sim.DIRS.find(toward)),"Face painted threshold")
			for _step in range(3):
				if sim.terrain(sim.front_pos())!=0: break
				check(sim.apply({"type":"move","step":"fwd"}).accepted,"Approach the actual wall face")
			check(sim.fixture_actions().any(func(entry): return entry.action.target_id==fixture.id),"Travel verb remains available at painted face")
			check(sim.legal_verbs("knife_start").any(func(entry): return entry.action.get("target_id","")==fixture.id),"An unrelated equipped item cannot hide a travel verb")
			var before: Dictionary=sim.snapshot()
			if action.type=="stairs" and stair_selected_state.is_empty(): stair_selected_state=before.duplicate(true)
			var result: Dictionary=sim.apply({"type":"move","step":"fwd"})
			check(result.accepted and sim.snapshot().turn==before.turn+1,"Forward activates travel in one beat")
		else: check(sim.apply(action).accepted,"Reference route continues after natural travel")
	check(sim.snapshot().status=="won" and sim.snapshot().hp==6,"Forward stairs, lift and exit preserve safe full run")
	# Presentation uses immutable cell coordinates, never camera-facing RNG.
	var path: String=Materials.path("BELL42",2,"floor",10,9)
	check(path==Materials.path("BELL42",2,"floor",10,9) and path.contains("calm_v3_floor_"),"Stable calm material selection")
	var app=load("res://scenes/main.tscn").instantiate(); app._save_path="user://tests/m3f_unit.json"
	root.add_child(app); current_scene=app; await process_frame
	check(app.new_run("B3VJ5K"),"Owner seed starts in real app")
	app._equipment_card("hand"); await process_frame; await process_frame
	check(app.controls.has("card_drop") and app.controls.card_use.text=="UNEQUIP","Equipped card has explicit UNEQUIP and DROP")
	check(app._card.get_global_rect().end.y<=342,"Equipped card fits phone")
	app._close_card(); app._busy=0
	app._command({"type":"turn","delta":1}); app._busy=0
	app._command({"type":"move","step":"fwd"}); app._busy=0
	app._equipment_card("hand"); await process_frame
	var before_hint: String=app.sim.state_hash()
	app._sleeping_lift()
	check(app._card==null and app.selected=="" and app.lines==["The lift is dead.","Ask the Bell Porter."],"A dead-lift tap dismisses an unrelated card so its hint is visible")
	check(app.sim.state_hash()==before_hint,"Dead-lift inspection never spends a turn or revision")
	check(app.new_run("B3VJ5K"),"Restore the owner fixture after the free hint probe")
	var full: Dictionary=app.sim.snapshot()
	for item in full.items.values():
		if full.pack.size()>=8: break
		if item.location!="floor" or item.get("hidden",false) or app.sim.definition(item.id).slot=="belt": continue
		item.location="pack"; item.floor=0; item.pos=[]; full.pack.append(item.id)
	check(app.sim.restore_state(full),"Authored full pack is a valid state")
	app._sync(); app._equipment_card("hand"); await process_frame; await process_frame
	check(app.controls.card_use.disabled and not app.controls.card_drop.disabled,"A full pack disables UNEQUIP but leaves equipped DROP usable")
	app._command({"type":"drop","item_id":"knife_start"}); app._busy=0
	check(app.state.pack.size()==8 and app.state.equipment.hand=="" and app.sim.reachable_items().has("knife_start"),"Equipped DROP needs no spare pack slot")
	var vines_present: bool=FileAccess.file_exists(app.OPTIONAL_OVERLAY) or ResourceLoader.exists(app.OPTIONAL_OVERLAY)
	check((app._optional_overlay.texture!=null)==vines_present and (not vines_present or app._optional_overlay.texture.get_size()==Vector2(154,342)) and app._optional_overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Optional native vine overlay loads only when present and never intercepts touch")
	check(app.sim.restore_state(stair_selected_state),"Selected-stair UI fixture restores")
	app.selected="knife_start"; app._sync()
	check(app.verbs.any(func(v): return v.action.get("target_id","")=="f1_down"),"DOWN remains in the real strip with an unrelated selected item")
	check(app.view.interaction_cues.any(func(c): return c.id=="f1_down" and c.threshold and not c.selected),"Unrelated selection keeps the stair's gold cue without pretending it accepts the knife")
	var pillar_picture: Dictionary=app.sim.view_snapshot(); pillar_picture.pos=[6,6]; pillar_picture.facing=3
	app.view.update_state(pillar_picture)
	check(app.view._sprites.any(func(sprite): return sprite.kind=="decor" and sprite.prop_kind=="pillar"),"Solid pilaster remains painted when adjacent")
	var friendly: Dictionary=app.sim.view_snapshot()
	var hound: Dictionary=friendly.actors.filter(func(actor): return actor.kind=="hound")[0]
	hound.state="peaceful"; hound.intent={}
	friendly.pos=[hound.pos[0]+1,hound.pos[1]]; friendly.facing=3
	friendly.objects.append({"id":"probe_food","kind":"bone","pos":hound.pos.duplicate(),"lit":false})
	app.view.update_state(friendly)
	check(absf(app.view.projection("probe_food").anchor.x-app.view.projection(hound.id).anchor.x)>8,"Loot at a pacified creature's feet stays visible beside its body")
	var picture: Dictionary=app.sim.view_snapshot()
	for facing in range(4):
		picture.facing=facing; app.view.update_state(picture)
		for wall in app.view._walls:
			check(not wall.path.ends_with("_arch.png") and (not wall.path.contains("arch_blocked") and not wall.path.contains("door_barricaded") or app.view.dressing_allowed(wall.cell)),"No misleading open dressing beside architectural openings")
	app._show_menu("title"); app._skip_splash(); app._menu_clock=0.7; app._update_menu_art()
	check(app._logo.visible and app._menu_art.texture==app.Paint.texture("res://assets/art/screens/title_flicker_1.png"),"Title uses separate logo and timed painted frames")
	app.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("M3f owner regressions: ",checks," checks, ",failures," failures; tour ",min_turns,"-",max_turns," turns")
	quit(1 if failures else 0)
