extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
const Store=preload("res://scripts/persistence/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func act(sim,action: Dictionary) -> Dictionary:
	var result: Dictionary=sim.apply(action)
	check(result.accepted,"Accept "+JSON.stringify(action)+": "+result.reason)
	check(Codec.validate(sim.snapshot()),"Action leaves a valid snapshot")
	return result
func _initialize() -> void:
	var record: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/qa/repro_stairs.json")))
	var stairs=Sim.new(record.seed,record.count)
	for action in record.actions.slice(0,record.actions.size()-1): check(stairs.apply(action).accepted,"Original occupied-stair setup uses ordinary actions")
	var stair_hash: String=stairs.state_hash()
	check(not stairs.apply(record.actions.back()).accepted and stairs.state_hash()==stair_hash,"Occupied normal stair arrival refuses atomically")
	var occupied: Dictionary=stairs.snapshot()
	var side_action: Array=stairs.fixture_actions().filter(func(v): return v.action.type=="squeeze")
	check(side_action.size()==1,"A blocked landing offers a visible SQUEEZE escape")
	act(stairs,side_action[0].action)
	check(stairs.snapshot().hp==occupied.hp and stairs.floor_data().actors==occupied.floors[0].actors,"Squeezing neither moves nor advances the waiting actor")
	var continuation=W.new()
	var escaped: Dictionary=continuation.run(record.seed,record.count,false,"keep",stairs.snapshot())
	check(escaped.ok,"The occupied-stair reproduction still has an ordinary full-run escape: "+escaped.reason)
	var bot=W.new(); bot.sim=Sim.new("BELL42")
	var sim=bot.sim
	check(Codec.validate(sim.snapshot()),"Fresh expanded run validates")
	check(bot._pickup("f1_torch"),"Ordinary pickup reaches the reed torch")
	check(not sim.definition("f1_torch").tags.has("FIRE"),"Cold reeds cannot burn a web")
	var unchanged: String=sim.state_hash()
	check(not sim.apply({"type":"burn","item_id":"f1_torch","target_id":"f1_web"}).accepted and sim.state_hash()==unchanged,"Unlit reeds cannot spend a turn or burn remotely")
	var food: String=bot._acquire_tag("FOOD")
	check(food!="","Renewable fire lesson has accessible food")
	check(bot.go(sim._fixture("f1_brazier").pos),"Reach brazier")
	act(sim,{"type":"light","item_id":"f1_torch","target_id":"f1_brazier"})
	check(sim.definition("f1_torch").tags==["FIRE","GLOW"],"Lit torch supplies both capabilities without consuming fuel")
	check(bot.go(sim._fixture("f1_web").pos),"Reach web")
	var before_fire: Dictionary=sim.snapshot()
	act(sim,{"type":"toss","item_id":"f1_torch"})
	check(sim._fixture("f1_web").open and sim.snapshot().items.f1_torch.location=="floor" and sim.reachable_items().has("f1_torch"),"Thrown FIRE opens the web and leaves the same torch recoverable")
	check(sim.restore_state(before_fire),"Restore ordinary pre-fire setup")
	var result:=act(sim,{"type":"burn","item_id":"f1_torch","target_id":"f1_web"})
	check(sim._fixture("f1_web").open and result.events.any(func(e): return e.type=="web_burnt"),"Fire opens the optional kennel permanently")
	check(sim._actor("f1_hound").state=="windup","Opening the kennel exposes the announced lunge")
	check(sim._actor("f1_hound").intent.lane.size()==2,"Hound announces two actual cells")
	var windup: Dictionary=sim.snapshot()
	for corrupt_lane in [null,true,0,"lane",{},[],[true],[[1,2],[3,4]]]:
		var malformed: Dictionary=windup.duplicate(true)
		malformed.floors[0].actors[1].intent.lane=corrupt_lane
		unchanged=sim.state_hash()
		check(not sim.restore_state(malformed) and sim.state_hash()==unchanged,"Malformed lunge lane refuses cleanly")
	unchanged=sim.state_hash()
	check(not sim.apply({"type":"feed","item_id":food,"target_id":"f1_hound"}).accepted and sim.state_hash()==unchanged,"FEED needs an adjacent Hound; distance two uses explicit TOSS")
	act(sim,{"type":"toss","item_id":food})
	check(sim._actor("f1_hound").state=="peaceful" and sim.snapshot().hp==6 and sim.snapshot().items[food].location=="consumed","Food cancels the lunge in one beat and remains consumed")
	check(Store.save_run(sim,{},"user://tests/m3e_fed.json",true),"Peaceful Hound saves")
	var clone=Sim.new(); check(clone.restore_state(Store.load_run("user://tests/m3e_fed.json").payload) and clone.state_hash()==sim.state_hash(),"Pacification round trip is exact")
	check(sim.restore_state(windup),"Restore ordinary pre-feed state")
	var preview: Dictionary=sim.toss_preview(food)
	check(preview.cells.size()==2 and preview.actor_id=="f1_hound","FOOD toss predicts the actual two-cell target")
	act(sim,{"type":"toss","item_id":food})
	check(sim._actor("f1_hound").state=="peaceful" and sim.snapshot().hp==6,"Thrown FOOD also cancels the pending lunge")
	check(sim.restore_state(windup),"Replay guard/dodge branch")
	act(sim,{"type":"guard"}); act(sim,{"type":"wait"})
	check(sim._actor("f1_hound").state=="windup" and sim._adjacent(sim._actor("f1_hound").pos,sim.snapshot().pos),"Hound prepares a fresh lunge from adjacent range")
	var adjacent: Dictionary=sim.snapshot()
	act(sim,{"type":"move","step":"back"})
	check(sim.snapshot().hp==5,"One backstep from adjacent range remains inside its two-cell lane")
	check(sim.restore_state(adjacent),"Restore adjacent lunge")
	act(sim,{"type":"move","step":"strafe_r"})
	check(sim.snapshot().hp==6 and sim._actor("f1_hound").state=="recovery","Strafing out of the marked lane dodges and earns recovery")
	check(sim.restore_state(adjacent),"Restore adjacent guard")
	act(sim,{"type":"guard"})
	check(sim.snapshot().hp==6 and sim._actor("f1_hound").state=="recovery","Guard remains a guaranteed answer")
	act(sim,{"type":"feed","item_id":food,"target_id":"f1_hound"})
	check(sim._actor("f1_hound").state=="peaceful","Direct FEED works at adjacent range")
	for key in ["schema_version","rules_version","pos"]:
		var invalid: Dictionary=sim.snapshot(); invalid[key]=true
		var before: String=sim.state_hash()
		check(not sim.restore_state(invalid) and sim.state_hash()==before,"Malformed top-level field refuses atomically: "+key)
	var proof: Dictionary=W.build("BELL42",2,false,"return")
	check(proof.ok,"Core restoration witness: "+proof.reason)
	var ending=Sim.new(); check(ending.restore_state(proof.snapshot),"Completed rules restore")
	for id in proof.snapshot.belt:
		check(ending.toss_preview(id).landing.is_empty(),"Protected belt possession has no toss lane")
	sim=Sim.new()
	for action in proof.actions:
		act(sim,action)
		if action.type=="stairs": break
	bot=W.new(); bot.sim=sim
	var cord: Dictionary=sim._fixture("f2_cord")
	check(bot.go(cord.pos),"Reach the EDGE grate")
	act(sim,{"type":"cut","item_id":"knife_start","target_id":cord.id})
	var glow: String=bot._acquire_tag("GLOW")
	check(bot.go(sim._actor("f2_ghost").pos),"Reach the Ghost with GLOW")
	var before_glow: Dictionary=sim.snapshot()
	act(sim,{"type":"toss","item_id":glow})
	check(sim._actor("f2_ghost").hp==0 and sim.snapshot().items[glow].location=="floor" and sim.snapshot().hp==6,"Thrown GLOW dispels the Ghost and remains recoverable")
	check(sim.restore_state(before_glow),"Restore ordinary pre-dispel state")
	check(bot.capability_rooms(),"EDGE and GLOW branch completes: "+bot.error)
	check(sim._fixture("f2_cord").open and sim._actor("f2_ghost").hp==0,"Cord is cut and Ghost dispelled")
	check(sim.snapshot().hp==6 and Codec.validate(sim.snapshot()),"Ghost branch remains damage free and valid")
	var full: Dictionary=W.build("BELL42",2,true,"return")
	check(full.ok,"Complete capability/secret exploration: "+full.reason)
	if full.ok:
		var panel: Dictionary=full.snapshot.floors[0].fixtures.filter(func(f): return f.type=="panel")[0]
		check(panel.revealed and panel.open and not full.snapshot.items[panel.item_id].hidden,"Return glow reveals an EDGE-opened hinted cache")
		check(full.snapshot.hp==6 and Codec.validate(full.snapshot),"Expanded exploration wins without damage")
		print("BELL42 expanded return: ",full.snapshot.turn," turns; ",JSON.stringify(full.pressure))
	var tour: Dictionary=W.build("BELL42",2,false,"return",true)
	check(tour.ok and tour.snapshot.hp==6,"Curated capability tour completes: "+tour.reason)
	print("BELL42 capability tour: ",tour.snapshot.turn," turns")
	for seed in ["QDAA","AAAAAA","DAWN22"]:
		for count in [1,3,4]:
			var alternate: Dictionary=W.build(seed,count,false,"return",true)
			check(alternate.ok and Codec.validate(alternate.snapshot),"Capability modules over alternate floor counts "+seed+"/"+str(count)+": "+alternate.reason)
	var seed_amount: int=8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seed_amount=int(arg.get_slice("=",1))
	var low:=100000; var high:=0
	for i in range(seed_amount):
		var seed: String="M3E"+Sim.Gen.ALPHABET[(i/32)%32]+Sim.Gen.ALPHABET[i%32]
		var route: Dictionary=W.build(seed,2,false,"return",true)
		check(route.ok,"Expanded witness "+seed+": "+route.reason)
		if not route.ok: continue
		var replay=Sim.new(seed)
		for action in route.actions: check(replay.apply(action).accepted,"Ordinary expanded witness action")
		check(replay.state_hash()==Codec.canonical(route.snapshot).sha256_text() and Codec.validate(route.snapshot) and route.snapshot.hp==6,"Exact expanded replay and save shape")
		check(route.snapshot.floors[0].actors.any(func(a): return a.kind=="hound" and a.state=="peaceful") and route.snapshot.floors[1].actors.any(func(a): return a.kind=="ghost" and a.hp==0),"Tour proves both new creature answers")
		for f in route.snapshot.floors:
			for fixture in f.fixtures:
				if fixture.type not in ["stairs_up","stairs_down"]: continue
				var space: int=0
				for d in Sim.DIRS:
					var cell: Array=[fixture.pos[0]+d[0],fixture.pos[1]+d[1]]
					if f.tiles[cell[1]*17+cell[0]]==0 and f.fixtures.all(func(v): return v.pos!=cell or v.type!="porter"): space+=1
				check(space>f.actors.size(),"Landing has more side spaces than possible living actors")
		low=mini(low,route.snapshot.turn); high=maxi(high,route.snapshot.turn)
		if i%25==24: print("Expanded witnesses: ",i+1,"/",seed_amount)
	print("M3e expanded witnesses: ",seed_amount," seeds, ",low,"-",high," turns")
	print("M3e mechanics: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
