extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Bot = preload("res://tests/qa/recovery_bot.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
var rng := RandomNumberGenerator.new()
var checks := 0
var findings: Dictionary = {}
var context: Dictionary = {}
var trace: Array = []
var stats := {"trajectories":0,"actions":0,"accepted":0,"rejected":0,"deaths":0,"sampled_states":0,"reachable":0,"search_budget_exhausted":0,"save_roundtrips":0,"lockstep_actions":0,"disk_roundtrips":0,"action_types":{},"coverage":{}}
var unresolved: Array = []
var disk_path := "user://tests/qa/fuzz.json"

func require(ok: bool, code: String, detail: String = "") -> void:
	checks += 1
	if not ok and not findings.has(code):
		findings[code] = {"detail":detail,"context":context.duplicate(true),"actions":trace.duplicate(true)}
		printerr("QA CONFIRMED ",code,": ",detail," ",JSON.stringify(context))

func cell_ok(cell: Array, floor_data: Dictionary) -> bool:
	return cell.size()==2 and cell[0]>=0 and cell[1]>=0 and cell[0]<floor_data.width and cell[1]<floor_data.height and floor_data.tiles[cell[1]*floor_data.width+cell[0]]==0

func invariants(state: Dictionary, before: Dictionary, result: Dictionary, action: Dictionary) -> void:
	require(state.hp>=0 and state.hp<=state.max_hp, "HP_BOUNDS")
	require(state.revision==before.revision+int(result.accepted), "REVISION")
	require(state.turn==before.turn+int(result.accepted and result.consumed_turn), "TURN")
	require(result.revision==state.revision, "RESULT_REVISION")
	for id in before.belt: require(state.belt.has(id) and state.items[id].location=="belt", "BELT_LOSS", id)
	var carried: Dictionary = {}
	for id in state.pack+state.belt+[state.equipment.hand,state.equipment.body]:
		if id=="": continue
		require(not carried.has(id), "DUPLICATE_ITEM", id)
		carried[id]=true
	require(state.items.size()==before.items.size(), "ITEM_TABLE_LOSS")
	for id in state.items:
		var item: Dictionary=state.items[id]
		var references: int = state.pack.count(id)+state.belt.count(id)+int(state.equipment.hand==id)+int(state.equipment.body==id)
		require(references==int(item.location in ["pack","equip","belt"]), "ITEM_LOCATION", id)
		if item.location=="pack": require(state.pack.has(id), "PACK_LOCATION", id)
		if item.location=="belt": require(state.belt.has(id), "BELT_LOCATION", id)
		if item.location=="equip": require(state.equipment.get(item.slot,"")==id, "EQUIP_LOCATION", id)
		if item.location=="floor": require(item.floor>=1 and item.floor<=state.floor_count and cell_ok(item.pos,state.floors[item.floor-1]), "ITEM_CELL", id)
		require(item.location in ["floor","pack","equip","belt","returned","consumed"], "BAD_LOCATION", id)
	for number in range(state.floor_count):
		var f: Dictionary=state.floors[number]
		var occupied: Dictionary={}
		for fixture in f.fixtures:
			require(cell_ok(fixture.pos,f), "FIXTURE_CELL", fixture.id)
		for actor in f.actors:
			require(cell_ok(actor.pos,f), "ACTOR_CELL", actor.id)
			if actor.hp<=0: continue
			var key:=str(actor.pos)
			require(not occupied.has(key), "ACTOR_OVERLAP", actor.id)
			occupied[key]=true
			for fixture in f.fixtures:
				if fixture.type=="porter" or fixture.type in ["gate","lock"] and not fixture.open:
					require(actor.pos!=fixture.pos, "ACTOR_IN_BLOCKER", actor.id+"/"+fixture.id)
			if state.floor==number+1: require(actor.pos!=state.pos, "PLAYER_ACTOR_OVERLAP", actor.id+" at "+str(actor.pos))
		if number+1!=before.floor and number+1!=state.floor:
			var expected: Dictionary=before.floors[number].duplicate(true)
			if result.accepted and action.type=="return_item":
				for fixture in expected.fixtures:
					if fixture.type=="lift" and fixture.owner_id==action.target_id: fixture.active=true
			require(f==expected, "INACTIVE_FLOOR_CHANGED", str(number+1))
	if state.floor!=before.floor:
		require(state.floors[before.floor-1].actors==before.floors[before.floor-1].actors, "DEPARTURE_ENEMY_TURN")
		require(state.floors[state.floor-1].actors==before.floors[state.floor-1].actors, "ARRIVAL_ENEMY_TURN")
		require(state.items==before.items, "TRAVEL_CHANGED_ITEMS")
		require(state.hp==before.hp, "ARRIVAL_DAMAGE")
	for index in range(result.events.size()):
		var event: Dictionary=result.events[index]
		require(event.sequence==index and event.turn==state.turn and event.revision==state.revision, "EVENT_ORDER")
	if state.hp==1: stats.coverage["one_hp"]=stats.coverage.get("one_hp",0)+1
	if state.pack.size()==8: stats.coverage["full_pack"]=stats.coverage.get("full_pack",0)+1
	for fixture in state.floors[state.floor-1].fixtures:
		if fixture.type=="plate" and fixture.pos==state.pos:
			var with_item: bool=state.items.values().any(func(item): return item.location=="floor" and item.floor==state.floor and item.pos==state.pos)
			var label: String="on_plate_with_item" if with_item else "on_plate_without_item"
			stats.coverage[label]=stats.coverage.get(label,0)+1
	if result.accepted:
		stats.action_types[action.type]=stats.action_types.get(action.type,0)+1

func act(sim, action: Dictionary) -> Dictionary:
	var before: Dictionary=sim.snapshot()
	var before_hash: String=sim.state_hash() if not action.type in ["turn","guard","wait"] else ""
	trace.append(action.duplicate(true))
	var result: Dictionary=sim.apply(action)
	var state: Dictionary=sim.snapshot()
	stats.actions+=1
	stats["accepted" if result.accepted else "rejected"]+=1
	if not result.accepted:
		require(state==before and (before_hash=="" or sim.state_hash()==before_hash), "REJECT_MUTATION", JSON.stringify(action))
	invariants(state,before,result,action)
	return result

func candidates(sim, policy: String) -> Array:
	var state: Dictionary=sim.snapshot()
	var choices: Array=[{"type":"turn","delta":-1},{"type":"turn","delta":1}]
	for step in ["fwd","back","strafe_l","strafe_r"]:
		choices.append({"type":"move","step":step})
	choices.append({"type":"wait"})
	if policy!="careless": choices.append({"type":"guard"})
	var front: Dictionary=sim.inspect_front()
	if front.monster!="":
		choices.append({"type":"hit","target_id":front.monster})
		if policy in ["greedy","careless"]: choices.append(choices.back())
	for id in sim.reachable_items():
		choices.append({"type":"pickup","item_id":id})
		if policy=="greedy": choices.append(choices.back()); choices.append(choices.back())
	for entry in sim.fixture_actions(): choices.append(entry.action)
	for id in state.pack:
		choices.append({"type":"drop","item_id":id})
		choices.append({"type":"equip","item_id":id})
		choices.append({"type":"eat","item_id":id})
		choices.append({"type":"ring","item_id":id})
		if policy=="spiteful": choices.append({"type":"drop","item_id":id})
		for target in sim.targets(id): choices.append(target.action)
	for slot in ["hand","body"]: choices.append({"type":"unequip","slot":slot})
	for fixture in sim.local_fixtures():
		for kind in ["stairs","ride","return_item","unlock","latch","leave"]:
			choices.append({"type":kind,"target_id":fixture.id,"item_id":"bell_clapper"})
	for id in state.belt:
		for kind in ["drop","eat","equip","place","ring"]: choices.append({"type":kind,"item_id":id,"target_id":"f1_plate"})
	choices.append({"type":"toss","item_id":"knife_start"})
	choices.append({"type":"wait","expected_revision":state.revision-1})
	return choices

func save_probe(state: Dictionary, disk: bool) -> void:
	var left=Sim.new(state.seed,state.floor_count)
	var right=Sim.new(state.seed,state.floor_count)
	require(left.restore_state(state),"CLONE_RESTORE")
	var roundtrip = JSON.parse_string(JSON.stringify(state))
	require(right.restore_state(roundtrip),"JSON_RESTORE")
	require(left.state_hash()==right.state_hash(),"ROUNDTRIP_HASH")
	stats.save_roundtrips+=1
	if disk:
		require(Store.save_run(left,{"selected":state.pack[0] if not state.pack.is_empty() else ""},disk_path,true),"DISK_WRITE")
		var loaded: Dictionary=Store.load_run(disk_path)
		require(not loaded.is_empty() and right.restore_state(loaded.payload) and right.state_hash()==left.state_hash(),"DISK_HASH")
		stats.disk_roundtrips+=1
	var old_trace: Array=trace.duplicate(true)
	for _step in range(8):
		var choices: Array=candidates(left,"random")
		var action: Dictionary=choices[rng.randi_range(0,choices.size()-1)]
		var a: Dictionary=act(left,action)
		var b: Dictionary=act(right,action)
		require(a==b and left.state_hash()==right.state_hash(),"CONTINUATION_DIVERGENCE")
		stats.lockstep_actions+=1
	trace=old_trace

func home_probe(state: Dictionary) -> void:
	stats.sampled_states+=1
	if state.status=="lost": return
	if state.status=="won": stats.reachable+=1; return
	var old_trace: Array=trace.duplicate(true)
	var bot=Bot.new()
	require(bot.setup(state,act),"PLANNER_CLONE")
	var outcome: Dictionary=bot.finish(context.get("choice","keep"))
	if outcome.status=="reachable":
		stats.reachable+=1
	else:
		# A bounded set of legal first actions with a fresh recovery continuation.
		# Failure is explicitly INCONCLUSIVE; this is not exhaustive state search.
		var recovered:=false
		var branches: Array=candidates(Sim_from(state),"random")
		for index in range(mini(24,branches.size())):
			trace=old_trace.duplicate(true)
			var retry=Bot.new()
			if not retry.setup(state,act): continue
			if not retry._raw(branches[index]) or retry.sim.snapshot().status!="playing": continue
			if retry.finish("keep").status=="reachable": recovered=true; break
		if recovered: stats.reachable+=1
		else:
			stats.search_budget_exhausted+=1
			unresolved.append({"context":context.duplicate(true),"reason":outcome.reason,"actions":old_trace.duplicate(true),"state_hash":Codec.canonical(state).sha256_text()})
	trace=old_trace

func Sim_from(state: Dictionary):
	var sim=Sim.new(state.seed,state.floor_count)
	sim.restore_state(state)
	return sim

func _initialize() -> void:
	rng.seed=19931028
	var amount:=96
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	for index in range(amount):
		var seed: String="QD"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		for choice in ["keep","return"]:
			for policy in ["random","greedy","careless","spiteful"]:
				context={"seed":seed,"count":2,"choice":choice,"policy":policy}
				trace=[]
				var proof: Dictionary=Witness.build(seed,2,policy=="greedy",choice)
				require(proof.ok,"ANCHOR_WITNESS",proof.reason)
				var sim=Sim.new(seed,2)
				var cut:=rng.randi_range(0,proof.actions.size()-2)
				for step in range(cut): act(sim,proof.actions[step])
				stats.trajectories+=1
				home_probe(sim.snapshot())
				for step in range(48):
					if sim.snapshot().status!="playing": break
					var choices: Array=candidates(sim,policy)
					var action: Dictionary=choices[rng.randi_range(0,choices.size()-1)]
					act(sim,action)
					if step in [15,31,47] and sim.snapshot().status=="playing": home_probe(sim.snapshot())
					if step in [0,23,47]: save_probe(sim.snapshot(),step==23 and index%4==0)
				if sim.snapshot().status=="lost": stats.deaths+=1
		if index%4==0: print("QA adversarial ",index+1,"/",amount," seeds; ",stats.actions," actions; ",stats.reachable," reachable; ",stats.search_budget_exhausted," inconclusive; ",findings.size()," findings")
	stats.checks=checks
	stats.findings=findings
	stats.unresolved=unresolved
	var file:=FileAccess.open("res://tests/qa/results/adversarial.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(stats,"\t")); file.close()
	print("QA ADVERSARIAL COMPLETE ",JSON.stringify(stats))
	quit(1 if not findings.is_empty() else 0)
