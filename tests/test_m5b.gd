extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Bot=preload("res://scripts/gen/deep_witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
const Family=preload("res://scripts/art/art_family.gd")
const View=preload("res://scripts/view/dungeon_view.gd")
const Required=preload("res://scripts/art/required_art.gd")
const Survey=preload("res://scripts/ui/survey.gd")
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(note)
func _initialize() -> void:
	Engine.set_meta("pilot",true); _run.call_deferred()
func _run() -> void:
	var seeds:=200
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seeds=arg.trim_prefix("--seeds=").to_int()
	var old=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"})
	var old_hash: String=old.state_hash()
	var sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep","metals":true})
	check(Codec.validate(sim.snapshot()),"New metal-key run validates without schema migration")
	check(not old._s.has("key_metals") and old._s.items.values().all(func(i): return not i.has("metal")),"Existing M5a profile is generic")
	check(old.restore_state(old.save_state()) and old.state_hash()==old_hash,"Existing M5a state/hash remain exact")
	for f in sim._s.floors:
		for lock in f.fixtures:
			if lock.type!="lock": continue
			check(sim.key_fits(lock,lock.key_id),"Generated lock matches its required key")
			for id in sim._s.items:
				if sim._s.items[id].kind=="key": check(sim.key_fits(lock,id)==(lock.metal==sim._s.items[id].metal),"Only matching metal fits")
	var restored=Sim.new()
	check(restored.restore_state(sim.save_state()) and restored.state_hash()==sim.state_hash(),"New keys and family inputs round trip exactly")
	for malformed in [1,[],{},"copper",null]:
		var bad: Dictionary=sim.snapshot(); bad.items.d4_key.metal=malformed
		check(not Codec.validate(bad),"Malformed metal refuses cleanly")
		bad=sim.snapshot(); bad.floors[3].fixtures.filter(func(f): return f.type=="lock")[0].metal=malformed
		check(not Codec.validate(bad),"Malformed lock metal refuses cleanly")
	var lo:=100000; var hi:=0
	for i in range(seeds):
		var seed: String="METL"+Sim.Gen.ALPHABET[(i/32)%32]+Sim.Gen.ALPHABET[i%32]
		var proof: Dictionary=Bot.new().prove(seed,{"metals":true})
		check(proof.ok,"Empty-hand metal chain: "+seed+" "+proof.reason)
		if proof.ok:
			lo=mini(lo,proof.snapshot.turn); hi=maxi(hi,proof.snapshot.turn)
			check(Codec.validate(proof.snapshot),"Witness win persists")
		if i%50==0: print("Metal witness ",i,"/",seeds)
	# Four families, constant within each 16-cell block, no mutable RNG/state.
	var picture: Dictionary=sim.view_snapshot(); var families: Array=[]
	for y in [8,24]:
		for x in [8,24]:
			var a: Dictionary=Family.at(picture,[x,y]); families.append(a.walls)
			for yy in range(y-5,y+6):
				for xx in range(x-5,x+6): check(Family.at(picture,[xx,yy])==a,"Material is constant inside a block")
	families.sort(); check(families==[1,2,3,4],"Default Deep uses all four moods")
	var abbey: Dictionary=Sim.new("BELL42",3).view_snapshot()
	check(Family.at(abbey,[4,4])==Family.for_floor(1),"Abbey retains floor mapping")
	var view=View.new(); root.add_child(view); view.set_process(false)
	# Controlled room with doorway: all lit forward room cells, not only adjacent.
	picture=sim.view_snapshot(); picture.actors=[]; picture.objects=[]; picture.props=[]; picture.fixtures=[]
	picture.tiles.fill(1)
	for y in range(4,9):
		for x in range(6,11): picture.tiles[y*picture.width+x]=0
	picture.tiles[9*picture.width+8]=0; picture.pos=[8,8]; picture.facing=0
	view.update_state(picture)
	for c in [[7,6],[8,6],[9,6],[6,6],[10,6]]: check(view.visible_cells().has(c),"Room entry surveys a distant visible cell "+str(c))
	check(not view.visible_cells().has([8,10]),"Survey does not ink behind the camera")
	var survey=Survey.new(); survey.reset(sim._s.floor_count,sim._s.floors); survey.observe(4,view.visible_cells(),picture.pos,[])
	check(survey.floor_data(4).walked.count("1")==1 and survey.floor_data(4).seen.count("1")>10,"One step inks the forward room while retaining footsteps")
	var saved: Dictionary=survey.save(); var atlas=Survey.new()
	check(atlas.restore(saved,sim.snapshot()) and atlas.hash_value()==survey.hash_value(),"Expanded survey retains version-1 save format")
	picture.fixtures=[{"id":"blocked","type":"web","pos":[8,7],"open":false}]
	view.update_state(picture); check(not view.visible_cells().has([8,6]),"Opaque web does not leak survey through centre column")
	check(view.visible_landmarks().is_empty(),"No secret landmark is inferred from unknown masonry")
	check(view._light(0.5)>view._light(1.5) and view._light(2.1)>view._light(3.2) and view._light(3.6)==0,"Seal light has distinct near/far bands and darkness")
	var band: Array=[]
	for y in range(8):
		for x in range(8):
			var levels: Array=view._seal_levels(2.1)
			var gain: float=levels[1] if view._dithered_down(levels[2],x,y) else levels[0]
			if not band.has(gain): band.append(gain)
	check(band.size()==2 and absf(band[0]-band[1])<=0.2,"Light falls in gentle levels, each 8x8-dithered only into the next darker one")
	check(view._seal_band(0.5)==0.0 and view._seal_band(3.5)==1.0,"Full, undithered light in the core; black beyond the edge")
	var dawn: Dictionary=sim.view_snapshot(); view.update_state(dawn)
	check(not view.visible_landmarks().has("d4_dawn"),"Looking at a sleeping dawn wall never maps its secret")
	check(Required.issues().is_empty(),"Every required painting including 24 key/lock assets loads")
	view.queue_free(); await process_frame
	print("M5b: %d checks, %d failures; %d empty-hand seeds, turns %d-%d"%[checks,failures,seeds,lo,hi])
	quit(1 if failures else 0)
