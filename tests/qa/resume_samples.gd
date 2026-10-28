extends "res://tests/qa/adversarial.gd"

func _initialize() -> void:
	var data: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/qa/results/adversarial.json")))
	var results: Array=[]
	for record in data.unresolved:
		context=record.context; trace=[]
		var sim=Sim.new(context.seed,context.count)
		for action in record.actions:
			act(sim,action)
			if sim.state_hash()==record.state_hash: break
		record.actions=trace.duplicate(true)
		require(sim.state_hash()==record.state_hash,"SAMPLE_REPLAY_HASH")
		print("Unresolved sample: ",JSON.stringify({"context":context,"floor":sim.snapshot().floor,"pos":sim.snapshot().pos,"hp":sim.snapshot().hp,"pack":sim.snapshot().pack,"equipment":sim.snapshot().equipment,"fixtures":sim.floor_data().fixtures,"heavy":sim.snapshot().items.values().filter(func(item): return sim.definition(item.id).tags.has("HEAVY"))}))
		var origin: Dictionary=sim.snapshot()
		var pending: Array=[{"state":origin,"actions":[]}]
		var cursor:=0
		var visited: Dictionary={}
		var solved:=false
		while cursor<pending.size() and cursor<512:
			var node: Dictionary=pending[cursor]; cursor+=1
			trace=record.actions.duplicate(true)+node.actions
			var bot=Bot.new(); bot.setup(node.state,act)
			var outcome: Dictionary=bot.finish("keep")
			if outcome.status=="reachable":
				results.append({"context":context,"state_hash":record.state_hash,"reached_by":record.actions.duplicate(true),"status":"reachable","expanded":cursor,"prefix":node.actions,"continuation":outcome.actions})
				solved=true; break
			var branch_sim=Sim_from(node.state)
			for action in candidates(branch_sim,"random"):
				trace=record.actions.duplicate(true)+node.actions
				var clone=Sim_from(node.state)
				var result: Dictionary=act(clone,action)
				if not result.accepted or clone.snapshot().status!="playing": continue
				var state: Dictionary=clone.snapshot()
				var key_state: Dictionary=state.duplicate(true)
				key_state.erase("turn"); key_state.erase("revision")
				for f in key_state.floors: f.erase("visited")
				var key: String=Codec.canonical(key_state).sha256_text()
				if visited.has(key): continue
				visited[key]=true
				pending.append({"state":state,"actions":node.actions+[action]})
		if not solved: results.append({"context":context,"status":"search_budget_exhausted","expanded":cursor,"queued":pending.size()})
	var file:=FileAccess.open("res://tests/qa/results/resume_samples.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"results":results,"findings":findings,"checks":checks,"stats":stats},"\t")); file.close()
	print("QA RESUME SAMPLES ",JSON.stringify(results))
	quit(1 if not findings.is_empty() else 0)
