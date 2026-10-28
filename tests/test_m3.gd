extends "res://tests/test_m2.gd"
## Retains M2's rules/storage/generator regressions, then proves both owner choices.
func _initialize() -> void:
	_rules()
	_storage()
	_legacy()
	_restoration()
	if not OS.get_cmdline_user_args().has("--focused"):
		_sweep()
		_owner_sweep()
	print("M3 RESULTS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

func _legacy() -> void:
	var legacy: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m2_snapshot.json")))
	check(Codec.validate(legacy),"Actual M2 snapshot remains accepted")
	var sim=Sim.new("DAWN22")
	check(sim.restore_state(legacy),"M2 snapshot restores without regeneration")
	check(sim.state_hash()==Codec.canonical(legacy).sha256_text(),"M2 adoption preserves exact state hash")
	var bot=Witness.new()
	var proof: Dictionary=bot.run("BELL42",2,false,"skip",legacy)
	check(proof.ok and proof.snapshot.turn==77,"Original M2 floor still finishes in 77 turns")
	check(Codec.canonical(proof.snapshot).sha256_text()=="00e68697f0f17b17b3dbd07654c7bfa6c0762ef3f3f4beb31c4eb940123ef654","Original M2 rules preserve full final hash")
	var path: String="user://tests/m3_legacy.json"
	_write(path,JSON.stringify({"save_version":2,"payload":legacy,"ui":{"selected":""},"sha256":Codec.canonical(legacy).sha256_text()}))
	check(Store.can_continue(path) and Store.load_run(path).payload==legacy,"M2 envelope loads through production store")
	check(Store.save_run(sim,{},path) and Store.load_run(path).payload==legacy,"M2 continue can be saved without changing its version cohort")

func _restoration() -> void:
	var proof: Dictionary=Witness.build("BELL42",2,false,"return")
	check(proof.ok,"Return policy reaches home "+proof.reason)
	var sim=Sim.new("BELL42")
	var before:=sim.state_hash()
	for action in [{"type":"return_item","target_id":"bell_porter","item_id":"f1_stone"},{"type":"ride","target_id":"lift_home"}]:
		check(not sim.apply(action).accepted and sim.state_hash()==before,"Wrong/distant return and dead lift reject atomically")
	for action in proof.actions:
		if action.type=="return_item": break
		act(sim,action)
	check(sim.targets("bell_clapper").any(func(t): return t.verb=="RETURN"),"Selected clapper marks its owner")
	act(sim,{"type":"equip","item_id":"bell_clapper"})
	check(sim.weapon_damage()==3,"Clapper is a usable HEAVY club")
	act(sim,{"type":"return_item","target_id":"bell_porter","item_id":"bell_clapper"})
	var s: Dictionary=sim.snapshot()
	check(s.items.bell_clapper.location=="returned" and s.equipment.hand=="" and not s.pack.has("bell_clapper"),"Equipped return transfers sole ownership")
	check(sim.porter_state().restored and s.floors[0].fixtures.filter(func(f): return f.type=="lift")[0].active and s.floors[1].fixtures.filter(func(f): return f.type=="lift")[0].active,"Both landings wake together")
	check(Codec.validate(s),"Returned location validates")
	var path: String="user://tests/m3_owner.json"
	check(Store.save_run(sim,{"selected":""},path,true),"Restoration saves transactionally")
	var resumed=Sim.new()
	check(resumed.restore_state(Store.load_run(path).payload) and resumed.state_hash()==sim.state_hash(),"Restoration survives a storage roundtrip")
	before=sim.state_hash()
	for action in [{"type":"return_item","target_id":"bell_porter","item_id":"bell_clapper"},{"type":"pickup","item_id":"bell_clapper"},{"type":"drop","item_id":"bell_clapper"}]:
		check(not sim.apply(action).accepted and sim.state_hash()==before,"Returned clapper cannot be duplicated/recovered")
	for broken in ["owner","landing","active","returned"]:
		var invalid: Dictionary=s.duplicate(true)
		match broken:
			"owner": invalid.items.bell_clapper.owner_id="missing"
			"landing": invalid.floors[0].fixtures.filter(func(f): return f.type=="lift")[0].destination=[0,0]
			"active": invalid.floors[1].fixtures.filter(func(f): return f.type=="lift")[0].active=false
			"returned": invalid.items.bell_clapper.kind="stone"
		check(not sim.restore_state(invalid) and sim.state_hash()==before,"Invalid restoration graph rejected: "+broken)
	# Use the actual post-restore route to verify no arrival attack or lost time.
	sim=Sim.new()
	for action in proof.actions:
		var prior: Dictionary=sim.snapshot()
		var result: Dictionary=act(sim,action)
		if action.type=="ride":
			check(sim.snapshot().floor==1 and sim.snapshot().hp==prior.hp and sim.snapshot().turn==prior.turn+1,"Lift crosses floors in one beat without arrival damage")
	check(sim.snapshot().status=="won" and sim.snapshot().hp==6,"Restoration playthrough wins undamaged")

func _owner_sweep() -> void:
	var low:=100000; var high:=0
	var pressure: Array=[]
	for i in range(300):
		var seed: String="TEST"+Gen.ALPHABET[i/32]+Gen.ALPHABET[i%32]
		var proof: Dictionary=Witness.build(seed,2,false,"return")
		check(proof.ok,"Restored lift witness "+seed+" "+proof.reason)
		if not proof.ok: continue
		var offered_kinds: Dictionary={}
		for item in proof.snapshot.items.values():
			# Original ID membership remains stable after pickup/drop/equip.
			if item.id.begins_with("f2_") and Catalog.ITEMS[item.kind].slot!="belt": offered_kinds[item.kind]=true
		check(offered_kinds.size()>=4,"Later floor offers distinct ordinary capabilities")
		var replay=Sim.new(seed)
		for action in proof.actions: check(replay.apply(action).accepted,"Ordinary restoration command")
		check(replay.state_hash()==Codec.canonical(proof.snapshot).sha256_text() and Codec.validate(proof.snapshot),"Restoration replay/ownership identical")
		check(replay.porter_state().restored and replay.snapshot().status=="won","Restored route finishes")
		low=mini(low,proof.snapshot.turn); high=maxi(high,proof.snapshot.turn)
		if i<64:
			var keep: Dictionary=Witness.build(seed,2,false,"keep")
			check(keep.ok and keep.snapshot.equipment.hand=="bell_clapper" and Codec.validate(keep.snapshot),"Keep-clapper stairs route remains viable")
			var greedy: Dictionary=Witness.build(seed,2,true)
			pressure.append(greedy.pressure)
		if i%50==49: print("Porter progress %d/300"%(i+1))
	for count in [1,3,4]:
		for seed in ["BELL42","DAWN22","ABC234","ZZZZZZ"]:
			for policy in ["keep","return"]:
				var proof: Dictionary=Witness.build(seed,count,false,policy)
				check(proof.ok and Codec.validate(proof.snapshot),"Owner policy with floor count "+str(count)+" "+policy)
	print("Porter: 300 returned/replayed + 64 keep + 24 alternate-count witnesses; restored turns %d-%d"%[low,high])
	for policy in ["skip","keep","return"]:
		var proof: Dictionary=Witness.build("BELL42",2,false,policy)
		print("BELL42 ",policy,": ",proof.snapshot.turn," turns / ",proof.actions.size()," actions")
	var file:=FileAccess.open("res://build/m3_pressure.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(pressure))
