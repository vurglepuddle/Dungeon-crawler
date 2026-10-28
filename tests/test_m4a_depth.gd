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
func _initialize() -> void:
	var file:=FileAccess.open("user://tests/m4a_legacy_continue.json",FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string("res://tests/fixtures/m3f_run.json")); file.close()
	var old: Dictionary=Store.load_run("user://tests/m4a_legacy_continue.json")
	check(not old.is_empty() and old.payload.floor_count==2,"Production store reads an actual M3f two-floor envelope")
	var sim=Sim.new("BELL42",3)
	check(sim.restore_state(old.payload) and sim.state_hash()=="14bc4617236bd22d78840604a84d7d5a4d49c6a5debe23859c1b536fe622db23","M3f Continue keeps its original profile, floors and exact hash")
	var legacy: Dictionary=W.new().run("BELL42",2,false,"return",old.payload,true)
	print("Legacy tour: ",legacy.ok," / ",legacy.snapshot.turn," / ",legacy.reason)
	check(legacy.ok and legacy.snapshot.floor_count==2 and legacy.snapshot.rules_version=="m3.3" and legacy.snapshot.hp==6,"Continued old capability tour remains a safe two-floor run")
	# Miss one announced deep blow, then use padding/healing through actions.
	var bot=W.new(); bot.sim=Sim.new("BELL42",3)
	var plan: Dictionary=W.build("BELL42",3,false,"keep")
	check(plan.ok,"Three-floor reference exists: "+plan.reason)
	for action in plan.actions:
		var s: Dictionary=bot.sim.snapshot()
		if s.floor==3 and s.floors[2].actors.any(func(a): return a.kind=="husk" and a.state=="windup" and a.intent.cell==s.pos): break
		check(bot.sim.apply(action).accepted,"Reach deep tell ordinarily")
	var poised: Dictionary=bot.sim.snapshot()
	check(poised.floor==3,"Reached the lower watch")
	var before: int=poised.hp
	check(bot.sim.apply({"type":"wait"}).accepted and bot.sim.snapshot().hp==before-2,"Missed deep Husk tell costs two HP")
	var wounded: Dictionary=bot.sim.snapshot()
	var carried: Dictionary=wounded.duplicate(true)
	var food: String="f3_watch_bread"
	carried.items[food].location="pack"; carried.items[food].floor=0; carried.items[food].pos=[]; carried.pack.append(food)
	check(bot.sim.restore_state(carried),"Authored carried ration is a valid wounded state")
	check(bot.sim.apply({"type":"eat","item_id":food}).accepted and bot.sim.snapshot().hp>before-2,"Ordinary food heals a deep wound")
	# W's zero-damage policy applies during setup, so deliberate wounds use
	# direct apply and valid snapshots rather than weakening its guarantee.
	check(Codec.validate(wounded),"Wounded deep state saves")
	var lunge: Dictionary=poised.duplicate(true)
	lunge.floors[2].actors[0].kind="hound"; lunge.floors[2].actors[0].hp=3; lunge.floors[2].actors[0].damage=3
	lunge.floors[2].actors[0].intent.lane=[lunge.pos.duplicate()]
	check(bot.sim.restore_state(lunge) and bot.sim.apply({"type":"wait"}).accepted and bot.sim.snapshot().hp==3,"Missed deep lunge costs three HP")
	var padding: Dictionary=lunge.duplicate(true); var coat: String="f3_watch_coat"
	padding.items[coat].location="pack"; padding.items[coat].floor=0; padding.items[coat].pos=[]; padding.pack.append(coat)
	check(bot.sim.restore_state(padding) and bot.sim.apply({"type":"equip","item_id":coat}).accepted,"Put on fresh padding during the announced tell")
	check(bot.sim.snapshot().hp==6 and bot.sim.snapshot().items[coat].spent,"One coat absorbs the whole three-point lunge")
	check(bot.sim.apply({"type":"drop","item_id":coat}).accepted and bot.sim.view_snapshot().objects.any(func(o): return o.id==coat and o.spent),"Dropped padding retains spent world-art state")
	for malformed in [null,true,0,4,"3",[],{}]:
		var bad: Dictionary=poised.duplicate(true); bad.floors[2].actors[0].damage=malformed
		check(not sim.restore_state(bad),"Malformed/out-of-range deep damage refuses cleanly")
	var amount:=300
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=arg.trim_prefix("--seeds=").to_int()
	var low:=10000; var high:=0; var core_low:=10000; var core_high:=0
	for n in range(amount):
		var seed: String="M4A"+Sim.Gen.ALPHABET[(n/32)%32]+Sim.Gen.ALPHABET[n%32]
		for policy in ["skip","keep","return"]:
			var proof: Dictionary=W.build(seed,3,false,policy)
			check(proof.ok,"Deep core "+seed+"/"+policy+": "+proof.reason)
			if not proof.ok: continue
			core_low=mini(core_low,proof.snapshot.turn); core_high=maxi(core_high,proof.snapshot.turn)
		var tour: Dictionary=W.build(seed,3,false,"return",true)
		check(tour.ok,"Deep tour "+seed+": "+tour.reason)
		if not tour.ok: continue
		low=mini(low,tour.snapshot.turn); high=maxi(high,tour.snapshot.turn)
		var replay=Sim.new(seed,3)
		for action in tour.actions: check(replay.apply(action).accepted,"Ordinary deep tour action")
		check(replay.state_hash()==Codec.canonical(tour.snapshot).sha256_text() and Codec.validate(tour.snapshot) and tour.snapshot.hp==6,"Three-floor exact no-damage replay/save")
		check(replay._s.floors[2].actors.size()==3 and replay._s.floors[2].actors[1].state=="peaceful","Deep tour demonstrates FOOD before fetching its key")
		if n%50==49: print("Deep progress ",n+1,"/",amount)
	print("M4a deep: ",checks," checks, ",failures," failures; core ",core_low,"-",core_high,"; tour ",low,"-",high)
	quit(1 if failures else 0)
