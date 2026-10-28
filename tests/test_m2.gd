extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
const FONT = preload("res://assets/font/vetka.ttf")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func act(sim,action: Dictionary) -> Dictionary:
	var result: Dictionary=sim.apply(action)
	check(result.accepted,"Accepted "+JSON.stringify(action)+" "+result.reason)
	return result
func fixture(sim,kind: String) -> Dictionary:
	for f in sim.floor_data().fixtures:
		if f.type==kind: return f
	return {}
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	if not FileAccess.file_exists("res://build/.gdignore"):
		var ignored:=FileAccess.open("res://build/.gdignore",FileAccess.WRITE)
		if ignored!=null: ignored.store_string("")
	_rules()
	_storage()
	if not OS.get_cmdline_user_args().has("--focused"): _sweep()
	print("M2 RESULTS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
func _rules() -> void:
	var sim=Sim.new("BELL42")
	check(Codec.validate(sim.snapshot()),"Initial snapshot valid")
	check(Gen.normalize_seed(" bell42 ")=="BELL42","Seed normalized")
	for raw in ["","I","OO","AA/BB","TOOLONG"]: check(Gen.normalize_seed(raw)=="","Invalid seed rejected")
	var detached: Dictionary=sim.snapshot()
	detached.items.knife_start.kind="coat"
	check(sim.definition("knife_start").slot=="hand","Deep snapshot detached")
	var before:=sim.state_hash()
	for action in [{"type":"unknown"},{"type":"turn","delta":2},{"type":"turn","delta":1,"expected_revision":999},
		{"type":"drop","item_id":"f1_key"},{"type":"leave","target_id":"f1_up"},{"type":"move","step":"teleport"}]:
		check(not sim.apply(action).accepted and sim.state_hash()==before,"Rejected command purity")
	act(sim,{"type":"pickup","item_id":"f1_stone"})
	act(sim,{"type":"move","step":"fwd"})
	act(sim,{"type":"move","step":"fwd"})
	check(fixture(sim,"plate").pressed and fixture(sim,"gate").open,"Finder body presses plate")
	act(sim,{"type":"move","step":"fwd"})
	check(not fixture(sim,"plate").pressed and not fixture(sim,"gate").open,"Gate closes after stepping off")
	act(sim,{"type":"move","step":"fwd"})
	before=sim.state_hash()
	check(not sim.apply({"type":"move","step":"fwd"}).accepted and sim.state_hash()==before,"Body alone cannot bridge plate/gate gap")
	act(sim,{"type":"move","step":"back"})
	act(sim,{"type":"move","step":"back"})
	act(sim,{"type":"drop","item_id":"f1_stone"})
	act(sim,{"type":"move","step":"fwd"})
	check(fixture(sim,"gate").open and sim.snapshot().items.f1_stone.location=="floor","DROP at own cell holds plate after departure")
	var bot=Witness.new(); bot.sim=sim
	check(bot.go(fixture(sim,"latch").pos),"Reach far-side latch through actual moves")
	check(bot._commit({"type":"latch","target_id":fixture(sim,"latch").id}),"Operate far latch")
	check(fixture(sim,"gate").latched,"Gate latched")
	check(bot.go(sim.snapshot().items.f1_stone.pos),"Return to dropped weight")
	check(bot._commit({"type":"pickup","item_id":"f1_stone"}),"Recover weight")
	check(fixture(sim,"gate").open,"Weight retrieval cannot trap Finder")
	# JSON roundtrip and malformed-save rejection preserve live state.
	var raw = JSON.parse_string(JSON.stringify(sim.snapshot()))
	var restored=Sim.new("OTHER")
	check(restored.restore_state(raw) and restored.state_hash()==sim.state_hash(),"JSON roundtrip")
	for broken in ["version","ownership","position","reference","intent","type"]:
		var invalid: Dictionary=sim.snapshot()
		match broken:
			"version": invalid.rules_version="future"
			"ownership": invalid.pack.append(invalid.pack[0])
			"position": invalid.pos=[-1,4]
			"reference": invalid.floors[0].fixtures[1].plate_id="missing"
			"intent": invalid.floors[0].actors[0].state="windup"; invalid.floors[0].actors[0].intent={}
			"type": invalid.items.f1_key=123
		before=restored.state_hash()
		check(not restored.restore_state(invalid) and restored.state_hash()==before,"Restore rejects "+broken+" without mutation")
	# Compact authored combat fixture, with normal actions thereafter.
	sim=_combat(false,false)
	act(sim,{"type":"wait"})
	var state: Dictionary=sim.snapshot()
	check(state.floors[0].actors[0].pos[1]==8 and state.floors[0].actors[0].state=="windup","Husk approaches then announces")
	var turn: int=state.turn
	act(sim,{"type":"turn","delta":-1}); act(sim,{"type":"turn","delta":1})
	check(sim.snapshot().turn==turn and sim.snapshot().hp==6,"Turning preserves pending intent")
	var old_cell: Array=sim.snapshot().pos
	var retreat:=act(sim,{"type":"move","step":"back"})
	var attacks: Array=retreat.events.filter(func(e): return e.type=="attack_resolved")
	check(attacks.size()==1 and attacks[0].cell==old_cell and attacks[0].damage==0,"Retreat dodges exact old cell")
	act(sim,{"type":"wait"})
	check(sim.snapshot().floors[0].actors[0].pos[1]==9 and sim.snapshot().floors[0].actors[0].state=="windup","Husk steps in after recovery")
	act(sim,{"type":"guard"}); act(sim,{"type":"hit","target_id":"f1_husk"})
	act(sim,{"type":"guard"}); act(sim,{"type":"hit","target_id":"f1_husk"})
	check(sim.snapshot().hp==6 and sim.snapshot().floors[0].actors[0].hp==0,"Starter guard/counter path remains safe")
	sim=_combat(true,false); act(sim,{"type":"wait"}); act(sim,{"type":"guard"})
	act(sim,{"type":"hit","target_id":"f1_husk"})
	check(sim.snapshot().floors[0].actors[0].hp==0 and sim.snapshot().hp==6,"HEAVY weapon one-shots after guard")
	sim=_combat(true,false); act(sim,{"type":"wait"})
	check(sim.attack_damage("f1_husk")==1,"Wind-up brace protects against an immediate HEAVY one-shot")
	act(sim,{"type":"hit","target_id":"f1_husk"})
	check(sim.snapshot().hp==5 and sim.snapshot().floors[0].actors[0].hp==1,"Impatient strike trades health instead of bypassing tell")
	sim=_combat(false,true); act(sim,{"type":"wait"}); act(sim,{"type":"wait"})
	check(sim.snapshot().hp==6 and sim.snapshot().items.f1_coat.spent,"Coat absorbs first blow")
	for _i in range(2): act(sim,{"type":"wait"})
	check(sim.snapshot().hp==5,"Spent coat cannot absorb again")
	var copy=Sim.new(); check(copy.restore_state(JSON.parse_string(JSON.stringify(sim.snapshot()))) and copy.snapshot().items.f1_coat.spent,"Spent armour survives roundtrip")
	sim=_combat(false,false)
	for _i in range(20):
		if sim.snapshot().status=="playing": act(sim,{"type":"wait"})
	check(sim.snapshot().status=="lost" and sim.snapshot().hp==0,"Ignored tells cause death")
	before=sim.state_hash(); check(not sim.apply({"type":"guard"}).accepted and sim.state_hash()==before,"Death freezes rules")
	_inventory()
	# Capability substitution: food is light, but the FOOD+HEAVY bone works.
	sim=Sim.new("BELL42")
	var setup: Dictionary=sim.snapshot()
	setup.pos=[setup.pos[0],13]; setup.floors[0].visited[13*17+setup.pos[0]]=true
	setup.floors[0].fixtures[0].pressed=true; setup.floors[0].fixtures[1].open=true
	for id in ["f1_bread_3","f1_bone_5"]:
		setup.pack.append(id); setup.items[id].location="pack"; setup.items[id].floor=0; setup.items[id].pos=[]
	check(sim.restore_state(setup),"Capability fixture valid")
	act(sim,{"type":"drop","item_id":"f1_bread_3"}); act(sim,{"type":"move","step":"fwd"})
	check(not fixture(sim,"gate").open,"FOOD alone does not hold weight plate")
	act(sim,{"type":"move","step":"back"}); act(sim,{"type":"drop","item_id":"f1_bone_5"}); act(sim,{"type":"move","step":"fwd"})
	check(fixture(sim,"gate").open,"Different HEAVY definition holds weight plate")
	for kind in Catalog.ITEMS:
		var definition: Dictionary=Catalog.ITEMS[kind]
		for value in [definition.name,definition.provenance]:
			check(FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x<=132,"Card text fits: "+value)
func _combat(heavy: bool,coat: bool):
	var sim=Sim.new("BELL42")
	var state: Dictionary=sim.snapshot()
	var x: int=state.pos[0]; state.pos=[x,9]
	state.floors[0].visited[9*17+x]=true
	state.floors[0].fixtures[1].latched=true; state.floors[0].fixtures[1].open=true
	if heavy: state.items.knife_start.kind="club"
	if coat:
		state.equipment.body="f1_coat"; state.items.f1_coat.location="equip"
		state.items.f1_coat.slot="body"; state.items.f1_coat.floor=0; state.items.f1_coat.pos=[]
	check(sim.restore_state(state),"Authored combat fixture valid")
	return sim
func _inventory() -> void:
	var sim=Sim.new("BELL42")
	var state: Dictionary=sim.snapshot()
	for id in state.items:
		if state.pack.size()==8: break
		if state.items[id].floor==1 and Catalog.ITEMS[state.items[id].kind].slot!="belt":
			state.pack.append(id); state.items[id].location="pack"; state.items[id].floor=0; state.items[id].pos=[]
	for id in ["f1_key","f2_seal"]:
		state.items[id].floor=1; state.items[id].pos=[state.pos[0],14]
	check(sim.restore_state(state),"Full-pack fixture valid")
	act(sim,{"type":"pickup","item_id":"f1_key"}); act(sim,{"type":"pickup","item_id":"f2_seal"})
	check(sim.snapshot().pack.size()==8 and sim.snapshot().belt.size()==2,"Essential belt bypasses pack capacity")
	var before:=sim.state_hash()
	check(not sim.apply({"type":"drop","item_id":"f1_key"}).accepted and sim.state_hash()==before,"Essential cannot drop")
	act(sim,{"type":"equip","item_id":"f1_club"})
	check(sim.snapshot().pack.size()==8 and sim.snapshot().equipment.hand=="f1_club" and sim.snapshot().pack.has("knife_start"),"Equipment swap transfers old item without capacity loss")
	act(sim,{"type":"equip","item_id":"f1_coat"})
	check(sim.snapshot().pack.size()==7 and sim.snapshot().equipment.body=="f1_coat","Wear coat frees one pack slot")
	before=sim.state_hash()
	check(not sim.apply({"type":"eat","item_id":"f1_bread_3"}).accepted and sim.state_hash()==before,"Food not wasted at full health")
func _write(path: String,text: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(text); file.flush()
func _storage() -> void:
	var path: String="user://tests/m2_storage.json"
	var sim=Sim.new("BELL42")
	check(Store.save_run(sim,{},path,true),"Initial staged save")
	var loaded:=Store.load_run(path)
	check(not loaded.is_empty() and loaded.payload.revision==0,"Initial load")
	act(sim,{"type":"turn","delta":1})
	check(Store.save_run(sim,{"selected":""},path),"Save after free committed action")
	var valid_text:=FileAccess.get_file_as_string(path)
	_write(path,"broken")
	check(Store.load_run(path).payload.revision==0,"Corrupt primary falls back to last good backup")
	check(Store.save_run(sim,{},path),"Corrupt primary cannot poison next backup")
	_write(path,"broken"); _write(path+".bak","broken"); _write(path+".tmp",valid_text)
	check(Store.load_run(path).payload.revision==1,"Complete staging recovers interrupted replacement")
	_write(path+".tmp","broken")
	check(Store.load_run(path).is_empty(),"All invalid slots fail closed")
	check(not Store.save_run(sim,{},"res://run.json") and not Store.save_run(sim,{},"user://../escape.json"),"Save paths restricted to user storage")
	check(Store.load_run("user://../escape.json").is_empty(),"Load traversal rejected")
	var other=Sim.new("NEW222")
	check(Store.save_run(other,{},path,true),"New run replaces save cohort")
	_write(path,"broken")
	check(Store.load_run(path).payload.seed=="NEW222","Backup of new run cannot resurrect previous seed")
	var proof: Dictionary=Witness.build("BELL42")
	check(sim.restore_state(proof.snapshot),"Restore terminal fixture")
	check(Store.save_run(sim,{},path),"Save terminal run")
	_write(path,"broken")
	check(not Store.can_continue(path) and Store.load_run(path).payload.status=="won","Terminal backup cannot offer Continue")
func _connected(f: Dictionary,blocked: Array=[]) -> Dictionary:
	var seen: Dictionary={}
	var queue: Array=[f.start]; seen[Vector2i(f.start[0],f.start[1])]=true
	var cursor:=0
	while cursor<queue.size():
		var cell: Array=queue[cursor]; cursor+=1
		for d in Sim.DIRS:
			var next: Array=[cell[0]+d[0],cell[1]+d[1]]; var key:=Vector2i(next[0],next[1])
			if next[0]<0 or next[0]>=17 or next[1]<0 or next[1]>=17 or f.tiles[next[1]*17+next[0]]!=0 or blocked.has(next): continue
			if not seen.has(key): seen[key]=true; queue.append(next)
	return seen
func _sweep() -> void:
	var layouts: Dictionary={}
	var low:=100000; var high:=0
	var pressure: Array=[]
	for i in range(300):
		var seed: String="TEST"+Gen.ALPHABET[i/32]+Gen.ALPHABET[i%32]
		var generated: Dictionary=Gen.new().generate(seed,2)
		check(generated==Gen.new().generate(seed,2),"Deterministic generated run "+seed)
		layouts[JSON.stringify(generated.floors.map(func(f): return f.tiles))]=true
		for f in generated.floors:
			check(_connected(f).size()==f.tiles.count(0),"Every floor cell connected")
			var gate: Dictionary=f.fixtures[1]; var lock: Dictionary=f.fixtures[3]
			check(not _connected(f,[gate.pos]).has(Vector2i(f.landing[0],f.landing[1])),"Weight gate cuts floor")
			var locked:=_connected(f,[lock.pos])
			check(not locked.has(Vector2i(f.landing[0],f.landing[1])),"Key gate cuts final room")
			var key_item: Dictionary=generated.items[lock.key_id]
			check(locked.has(Vector2i(key_item.pos[0],key_item.pos[1])),"Matching key lies before its lock")
			var spine: int=f.start[0]
			check(_connected(f,[[spine,8]]).has(Vector2i(spine,6)),"Useful middle loop survives main corridor cut")
		var proof: Dictionary=Witness.build(seed)
		check(proof.ok,"Full down-and-back witness "+seed+" "+proof.reason)
		if not proof.ok: continue
		var replay=Sim.new(seed)
		for action in proof.actions:
			check(replay.apply(action).accepted,"Ordinary witness command")
		check(replay.state_hash()==Codec.canonical(proof.snapshot).sha256_text(),"Independent replay identical")
		check(Codec.validate(proof.snapshot),"Completed snapshot validates")
		check(proof.snapshot.status=="won" and proof.snapshot.floor==1 and proof.snapshot.hp==6,"Win returns home undamaged")
		low=mini(low,proof.snapshot.turn); high=maxi(high,proof.snapshot.turn)
		if i<64:
			var greedy: Dictionary=Witness.build(seed,2,true)
			check(greedy.ok,"Greedy exploration "+seed+" "+greedy.reason)
			check(Codec.validate(greedy.snapshot),"Greedy snapshot validates")
			pressure.append(greedy.pressure)
		if i%50==49: print("Witness progress %d/300"%(i+1))
	for count in [1,3,4]:
		for seed in ["BELL42","DAWN22","ABC234","ZZZZZZ"]:
			var proof: Dictionary=Witness.build(seed,count)
			check(proof.ok and proof.snapshot.floor_count==count and Codec.validate(proof.snapshot),"Floor-count parameter "+str(count))
	print("Sweep: 300 full witnesses; 64 greedy runs; 12 alternate-count runs; %d distinct run layouts; turns %d-%d"%[layouts.size(),low,high])
	print("BELL42 route "+JSON.stringify({"turns":Witness.build("BELL42").snapshot.turn,"greedy":Witness.build("BELL42",2,true).pressure}))
	var file:=FileAccess.open("res://build/m2_pressure.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(pressure))
	else: failures+=1; push_error("Cannot write pressure report")
