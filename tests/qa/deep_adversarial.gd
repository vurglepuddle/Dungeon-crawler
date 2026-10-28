extends "res://tests/qa/adversarial.gd"
## The old cohort remains unchanged; every anchor here actually reaches floor 3.
func candidates(sim, policy: String) -> Array:
	var choices: Array=super.candidates(sim,policy)
	for entry in sim.interaction_targets(): choices.append(entry.action)
	var s: Dictionary=sim.snapshot()
	for id in s.pack+s.belt+[s.equipment.hand,s.equipment.body]:
		if id=="": continue
		choices.append({"type":"toss","item_id":id})
		for entry in sim.targets(id): choices.append(entry.action)
	return choices

func invariants(state: Dictionary, before: Dictionary, result: Dictionary, action: Dictionary) -> void:
	super.invariants(state,before,result,action)
	for floor_data in state.floors:
		for actor in floor_data.actors:
			if actor.hp<=0: continue
			for fixture in floor_data.fixtures:
				if fixture.type in ["web","cord"] and not fixture.open:
					require(actor.pos!=fixture.pos,"DEEP_ACTOR_IN_BLOCKER",actor.id)
	if state.floor==3: stats.coverage["floor_three"]=stats.coverage.get("floor_three",0)+1
	for actor in state.floors[state.floor-1].actors:
		if actor.state=="windup":
			var key: String="tell_"+actor.kind+"_f"+str(state.floor)
			stats.coverage[key]=stats.coverage.get(key,0)+1
	# If a destination landing is occupied, the advertised legal alternative
	# must exist. Checking the actual squeeze transition is done in deep_edges.
	var blocked_travel:=false
	for fixture in state.floors[state.floor-1].fixtures:
		if fixture.type not in ["stairs_up","stairs_down"] or absi(fixture.pos[0]-state.pos[0])+absi(fixture.pos[1]-state.pos[1])>1: continue
		var target_floor: int=state.floor+(-1 if fixture.type=="stairs_up" else 1)
		if target_floor<1 or target_floor>state.floor_count: continue
		var destination: Dictionary=state.floors[target_floor-1]
		var landing: Array=destination.landing if fixture.type=="stairs_up" else destination.start
		if destination.actors.any(func(a): return a.hp>0 and a.pos==landing): blocked_travel=true
	if state.status=="playing" and blocked_travel:
		var sim=Sim_from(state)
		for entry in sim.fixture_actions():
			if entry.action.type=="squeeze":
				var clone=Sim_from(state)
				var outcome: Dictionary=clone.apply(entry.action)
				require(outcome.accepted and clone.snapshot().floor!=state.floor,"ADVERTISED_SIDLE_REJECTED")
				stats.coverage["sidle_available"]=stats.coverage.get("sidle_available",0)+1

func _initialize() -> void:
	rng.seed=4101993
	disk_path="user://qa_m4a_deep_fuzz.json"
	var amount:=96
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	for index in range(amount):
		var seed: String="QA4"+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32]
		for choice in ["keep","return"]:
			for policy in ["random","greedy","careless","spiteful"]:
				context={"seed":seed,"count":3,"choice":choice,"policy":policy}; trace=[]
				var proof: Dictionary=Witness.build(seed,3,policy=="greedy",choice,policy=="greedy")
				require(proof.ok,"DEEP_ANCHOR_WITNESS",proof.reason)
				var scan=Sim.new(seed,3)
				var anchors: Array=[]
				for step in range(proof.actions.size()-1):
					scan.apply(proof.actions[step])
					if scan.snapshot().floor==3: anchors.append(step+1)
				require(not anchors.is_empty(),"DEEP_ANCHOR_EXISTS")
				var cut: int=anchors[rng.randi_range(0,anchors.size()-1)]
				var sim=Sim.new(seed,3)
				for step in range(cut): act(sim,proof.actions[step])
				stats.trajectories+=1
				home_probe(sim.snapshot())
				for step in range(64):
					if sim.snapshot().status!="playing": break
					var choices: Array=candidates(sim,policy)
					act(sim,choices[rng.randi_range(0,choices.size()-1)])
					if step in [15,31,47,63] and sim.snapshot().status=="playing": home_probe(sim.snapshot())
					if step in [0,23,47,63]: save_probe(sim.snapshot(),step==23 and index%4==0)
				if sim.snapshot().status=="lost": stats.deaths+=1
		if index%4==0: print("QA DEEP ADV ",index+1,"/",amount," actions ",stats.actions," reachable ",stats.reachable," budget ",stats.search_budget_exhausted," findings ",findings.size())
	stats.checks=checks; stats.findings=findings; stats.unresolved=unresolved
	var file:=FileAccess.open("res://tests/qa/results/deep_adversarial.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(stats,"\t")); file.close()
	print("QA DEEP ADV COMPLETE ",JSON.stringify(stats))
	quit(1 if not findings.is_empty() else 0)
