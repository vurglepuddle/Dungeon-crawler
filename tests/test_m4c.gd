extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
const View=preload("res://scripts/view/dungeon_view.gd")
const Art=preload("res://scripts/art/item_art.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const Required=preload("res://scripts/art/required_art.gd")
const Held=preload("res://scripts/view/held_item.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void:
	Engine.set_meta("pilot",true); _run.call_deferred()
func _run() -> void:
	var view=View.new(); root.add_child(view); view.set_process(false)
	var s: Dictionary=Sim.new("BELL42",3).view_snapshot(); s.actors=[]; s.objects=[]; s.props=[]
	# Real cell boundaries, all four camera approaches, both corridor axes.
	for axis in [0,1]:
		var tiles: Array=[]; tiles.resize(289); tiles.fill(1)
		for y in range(3,14):
			for x in range(3,14): tiles[y*17+x]=0
		if axis==1: tiles[8*17+7]=1; tiles[8*17+9]=1
		s.tiles=tiles
		for kind in ["lock","gate","web","cord"]:
			for d in range(4):
				s.pos=[8+Sim.DIRS[d][0]*2,8+Sim.DIRS[d][1]*2]; s.facing=(d+2)%4
				var f: Dictionary={"id":"probe","type":kind,"pos":[8,8],"open":false}
				s.fixtures=[f]; view.update_state(s)
				var closed: Dictionary=view._portals[0].duplicate(true)
				f.open=true; view.update_state(s)
				var opened: Dictionary=view._portals[0]
				check(closed.center==opened.center and closed.normal==opened.normal,"Same physical plane for "+kind+" approach "+str(d))
				check(closed.columns==opened.columns,"No depth, UV or projected-size jump on "+kind)
				if kind=="lock": check(closed.center==(Vector2(8.5,9) if axis==1 else Vector2(9,8.5)),"Lock retains the old entry boundary, not cell centre")
	# Cache remains a painted recess on one immutable solid wall.
	s.fixtures=[{"id":"cache","type":"panel","pos":[8,7],"wall":[8,6],"normal":[0,1],"open":false,"revealed":true}]; s.tiles[6*17+8]=1
	for d in range(4):
		s.pos=[8+Sim.DIRS[d][0]*2,8+Sim.DIRS[d][1]*2]; s.facing=(d+2)%4
		s.fixtures[0].open=false; view.update_state(s); var depths: Array=view._depths.duplicate(); var faces: Array=view._faces.keys()
		s.fixtures[0].open=true; view.update_state(s)
		check(depths==view._depths and faces==view._faces.keys(),"Opening a cache never moves its wall")
	view._burning={"x":0.0}; view._dispel={"age":0.0}; view._strike={"age":0.0}
	view._process(0.25)
	check(view._burning.has("x") and not view._dispel.is_empty() and not view._strike.is_empty(),"All world effects survive a human-readable quarter second")
	view._process(0.25)
	check(view._burning.is_empty() and view._dispel.is_empty() and view._strike.is_empty(),"World effects complete without changing a turn")
	var held=Held.new(); held.animate("knife","hit"); held.advance(0.15)
	check(is_equal_approx(held.remaining,0.45),"Claude's 0.6 second hand use is preserved")
	held.animate("clapper","ring"); check(held.remaining==0.8,"Claude's 0.8 second ring is preserved")
	var required: Dictionary=Required.paths()
	check(Required.issues().is_empty(),"All accepted F3/icon/candle paintings load")
	check(required.has("res://assets/art/ui/owner_candle.png"),"Missing candle is a required-asset finding")
	check(not required.has("res://assets/art/items/icon_club_16_alt.png"),"Unaccepted alternate club stays unused")
	for kind in Art.ICONS:
		check(Art.inventory(kind).get_size()==Vector2(16,16) and required.has(Art.icon_path(kind)),"Accepted per-kind icon is guarded: "+kind)
	var app=load("res://scenes/main.tscn").instantiate(); app._save_path="user://tests/m4c.json"; root.add_child(app); app.new_run("BELL42",3)
	var payload: Dictionary=app.sim.snapshot(); var panel: Dictionary=payload.floors[0].fixtures.filter(func(f): return f.type=="panel")[0]
	payload.pos=panel.pos.duplicate(); payload.facing=3
	check(app.sim.restore_state(payload),"Reach the hidden scar before dawn")
	app._sync(); var before: String=app.sim.state_hash()
	app._inspect_capability(app.sim._fixture(panel.id))
	check(not is_instance_valid(app._modal) and app.sim.state_hash()==before and app.lines==["Faint scratches.","You can't make them out."],"Unrevealed tap is puzzled, free and has no spoiler card")
	check(not app.view.interaction_cues.any(func(c): return c.id==panel.id) and not app.verbs.any(func(v): return v.label in ["PRY","CUT","REVEAL"]),"No secret glint or offered capability before revelation")
	app._open_card("knife_start"); check(app._optional_overlay.visible and app._card.get_index()>app._optional_overlay.get_index(),"Card covers live vines; vines stay visible")
	app._close_card(); app._open_map(); check(not app._optional_overlay.visible,"Only map hides the vines"); app._close_modal()
	check(app._optional_overlay.visible and app._overlay_life.candle.get_size()==Vector2(14,17),"Separate registered candle follows vines")
	var overlay: Image=app._optional_overlay.texture.get_image()
	for skull in app._overlay_life.config.skulls:
		for pos in skull.sockets: check(overlay.get_pixel(pos[0],pos[1]).is_equal_approx(Color("4c8585")),"Only exact owner teal socket coordinates animate")
	var tour: Dictionary=W.build("BELL42",3,false,"return",true); check(tour.ok,"Three-floor ordinary secret return witness")
	var reached=Sim.new("BELL42",3)
	for action in tour.actions:
		if action.type=="cut" and action.target_id==panel.id: break
		check(reached.apply(action).accepted,"Ordinary dawn return action")
	check(reached.has_seal() and reached._fixture(panel.id).revealed,"Third-floor Seal reveals the floor-one scar on return")
	if reached.snapshot().equipment.hand!="knife_start": check(reached.apply({"type":"equip","item_id":"knife_start"}).accepted,"Equip a blade for the scar")
	app.sim=reached; app.selected=""; app._busy=0; app._sync()
	check(app.verbs[0].label=="PRY" and app.verbs[0].action.item_id=="knife_start","Held knife offers PRY without selection")
	app.controls[app._world_markers[panel.id]].pressed.emit()
	check(app.sim._fixture(panel.id).open and not app.sim.snapshot().items[panel.item_id].hidden,"Tapping the scar uses the held EDGE and opens its cache")
	# The held rule covers GLOW too; selection still wins when two blades fit.
	var tags=Sim.new("BELL42",3); var carry: Dictionary=tags.snapshot(); var x: int=carry.floors[1].start[0]
	carry.floor=2; carry.pos=[x+1,14]; carry.facing=1
	carry.items.f3_watch_shard.location="pack"; carry.items.f3_watch_shard.floor=0; carry.items.f3_watch_shard.pos=[]; carry.pack.append("f3_watch_shard")
	check(tags.restore_state(carry),"Held/selected tag query fixture")
	check(tags.capability_targets()[0].verb=="CUT" and tags.capability_targets()[0].action.item_id=="knife_start","Held EDGE cuts a cord without selection")
	check(tags.capability_targets("f3_watch_shard")[0].action.item_id=="f3_watch_shard","Explicit selected EDGE precedes hand EDGE")
	carry.pos=[x+3,14]; carry.items.knife_start.location="pack"; carry.items.knife_start.slot=""; carry.pack.append("knife_start")
	carry.equipment.hand="f2_guide_lamp"; carry.items.f2_guide_lamp.location="equip"; carry.items.f2_guide_lamp.floor=0; carry.items.f2_guide_lamp.pos=[]; carry.items.f2_guide_lamp.slot="hand"
	check(tags.restore_state(carry) and tags.capability_targets().any(func(t): return t.verb=="DISPEL"),"Held GLOW offers DISPEL")
	var travel=Sim.new("BELL42",3)
	for action in tour.actions:
		if travel.snapshot().floor==2 and action.type=="stairs": break
		check(travel.apply(action).accepted,"Reach the third-floor travel ordinarily")
	app.sim=travel; app._busy=0; app.selected=""; app._sync()
	var down: Dictionary=travel._fixture("f2_down"); app._command({"type":"stairs","target_id":down.id})
	while app._transitioning: await process_frame
	check(app.state.floor==3 and app._music._current_track=="floor3","Travel selects the Lower Watch music")
	app._save(true); app._show_menu("title"); app._continue()
	check(app.state.floor==3 and app._music._current_track=="floor3","Continue retains floor-three music")
	app._overlay_life._process(10.0)
	check(app._overlay_life.frozen and app._overlay_life._active.is_empty() and app._overlay_life._candle_frame==0,"Pilots freeze all overlay randomness and candle frames")
	view.free(); app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M4c owner fixes: ",checks," checks, ",failures," failures"); quit(1 if failures else 0)
