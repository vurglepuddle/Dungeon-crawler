extends "res://tests/test_m2.gd"
func _initialize() -> void:
	_rules_ring()
	_legacy_ring()
	if not OS.get_cmdline_user_args().has("--focused"): _ring_sweep()
	print("M3b ring: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

func _arena():
	var sim=Sim.new("BELL42")
	var s: Dictionary=sim.snapshot()
	s.floors[0].erase("props") # The authored arena replaces the generated masonry.
	s.pos=[8,9]; s.facing=0
	# An authored open room gives independent sight/occlusion cases.
	for y in range(4,13):
		for x in range(3,14): s.floors[0].tiles[y*17+x]=0
	for f in s.floors[0].fixtures:
		if f.type=="gate": f.open=true; f.latched=true
		if f.type=="lock": f.open=true
	s.equipment.hand="bell_clapper"; s.pack=["knife_start"]
	s.items.knife_start.location="pack"; s.items.knife_start.slot=""
	s.items.bell_clapper.location="equip"; s.items.bell_clapper.slot="hand"; s.items.bell_clapper.floor=0; s.items.bell_clapper.pos=[]
	s.floors[0].actors=[
		{"id":"husk_near","kind":"husk","pos":[8,8],"hp":2,"state":"windup","intent":{"cell":[8,9],"due_in":1}},
		{"id":"husk_side","kind":"husk","pos":[10,7],"hp":2,"state":"idle","intent":{}},
		{"id":"husk_far","kind":"husk","pos":[8,5],"hp":2,"state":"idle","intent":{}},
		{"id":"husk_back","kind":"husk","pos":[8,12],"hp":2,"state":"idle","intent":{}},
		{"id":"husk_blocked","kind":"husk","pos":[6,6],"hp":2,"state":"idle","intent":{}}]
	s.floors[0].tiles[7*17+7]=1
	check(sim.restore_state(s),"Ring arena validates")
	return sim

func _rules_ring() -> void:
	var sim=_arena()
	var targets: Array=sim.ring_targets("bell_clapper")
	check(targets==["husk_near","husk_side"],"Cone/range/wall exclude hidden, rear and far Husks")
	check(sim.targets("bell_clapper").any(func(t): return t.verb=="RING"),"Selected clapper marks ordinary ring targets")
	var before: Dictionary=sim.snapshot()
	var result: Dictionary=act(sim,{"type":"ring","item_id":"bell_clapper"})
	var after: Dictionary=sim.snapshot()
	check(result.consumed_turn and after.turn==before.turn+1 and after.hp==6,"RING spends one beat and cancels incoming strike")
	check(after.floors[0].bell_rung,"Per-floor charge spent")
	for actor in after.floors[0].actors:
		if targets.has(actor.id): check(actor.state=="recovery" and actor.intent.is_empty(),"Every listener reels without rearming on the same beat")
	check(after.floors[1]==before.floors[1],"Inactive floor frozen")
	check(result.events.any(func(e): return e.type=="bell_rung" and e.actor_ids==targets),"Ring event names exactly the listeners")
	check(not result.events.any(func(e): return e.type=="attack_resolved" and e.actor_id=="husk_near"),"Cleared wind-up never resolves after ringing")
	check(sim.attack_damage("husk_near")==3,"RING provides the full HEAVY counter window")
	act(sim,{"type":"hit","target_id":"husk_near"})
	check(sim.snapshot().floors[0].actors[0].hp==0 and sim.snapshot().hp==6,"One-beat counter is safe")
	var hash_before:=sim.state_hash()
	check(not sim.apply({"type":"ring","item_id":"bell_clapper"}).accepted and sim.state_hash()==hash_before,"Spent RING rejects atomically")
	var path: String="user://tests/m3b_ring.json"
	check(Store.save_run(sim,{},path,true),"Spent bell persists through production store")
	var loaded=Sim.new()
	check(loaded.restore_state(Store.load_run(path).payload) and not loaded.ring_ready() and loaded.state_hash()==sim.state_hash(),"Save/continue cannot recharge the floor")
	var s: Dictionary=loaded.snapshot(); s.floors[0].bell_rung="yes"
	check(not loaded.restore_state(s),"Bad charge type rejected")
	act(sim,{"type":"unequip","slot":"hand"})
	act(sim,{"type":"equip","item_id":"bell_clapper"})
	check(not sim.ring_ready(),"Pack/equip cannot recharge")
	# Same item may still ring on a different floor; returning later remains legal.
	s=sim.snapshot(); s.floor=2; s.pos=s.floors[1].start.duplicate(); s.facing=0
	check(sim.restore_state(s) and sim.ring_ready(),"A different floor has its own charge")
	s.floor=1; s.pos=[8,3]; s.facing=3
	check(sim.restore_state(s),"Owner remains reachable after using the bell")
	act(sim,{"type":"return_item","item_id":"bell_clapper","target_id":"bell_porter"})
	check(sim.porter_state().restored and sim.ring_targets("bell_clapper").is_empty(),"Spent clapper can be returned; returned item cannot ring")
	# A blank call costs neither charge nor time, including from a full pack.
	sim=Sim.new(); hash_before=sim.state_hash()
	check(not sim.apply({"type":"ring","item_id":"f1_stone"}).accepted and sim.state_hash()==hash_before,"Wrong item never rings")
	s=sim.snapshot(); s.pack=["bell_clapper"]; s.items.bell_clapper.location="pack"; s.items.bell_clapper.floor=0; s.items.bell_clapper.pos=[]
	check(sim.restore_state(s),"Carried clapper fixture validates")
	hash_before=sim.state_hash()
	check(not sim.apply({"type":"ring","item_id":"bell_clapper"}).accepted and sim.state_hash()==hash_before and sim.ring_ready(),"Empty sight costs nothing")

func _legacy_ring() -> void:
	var old: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m3a_snapshot.json")))
	var sim=Sim.new()
	check(sim.restore_state(old) and sim.state_hash()=="cfff4ee3992c2e9865e5282d25e7ccd3614f4e1550eab28b8ea958f8460abdcb","M3a snapshot adopts with exact hash")
	var proof: Dictionary=Witness.new().run("BELL42",2,false,"keep",old)
	check(proof.ok and proof.snapshot.turn==74 and proof.snapshot.rules_version=="m3.1","M3a normal route retains version and timing")
	check(Codec.canonical(proof.snapshot).sha256_text()=="23bb3c9db7f002fd87ac8a5a30ab0f2a962e238965b10b0891a3da55a6304076","M3a ending hash remains exact")
	proof=Witness.new().run("BELL42",2,false,"ring",old)
	check(proof.ok and proof.snapshot.rules_version=="m3.2" and proof.snapshot.generator_version=="m3.1" and Codec.validate(proof.snapshot),"First RING upgrades legacy rules/content without regenerating floors")

func _ring_sweep() -> void:
	for i in range(300):
		var seed: String="TEST"+Gen.ALPHABET[i/32]+Gen.ALPHABET[i%32]
		var proof: Dictionary=Witness.build(seed,2,false,"ring")
		check(proof.ok,"Safe bell route "+seed+" "+proof.reason)
		if not proof.ok: continue
		var sim=Sim.new(seed)
		for action in proof.actions: check(sim.apply(action).accepted,"Ordinary bell command")
		check(sim.state_hash()==Codec.canonical(proof.snapshot).sha256_text() and Codec.validate(proof.snapshot),"Bell replay/charge state identical")
		check(proof.snapshot.status=="won" and proof.snapshot.hp==6,"Bell witness returns undamaged")
		check(proof.actions.any(func(a): return a.type=="ring"),"Keep-bell policy uses its distinct tool")
		if i%50==49: print("Bell progress %d/300"%(i+1))
