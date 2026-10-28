extends "res://tests/qa/save_fuzz.gd"
const Recovery=preload("res://tests/qa/recovery_bot.gd")
const LEGACY_HASH="14bc4617236bd22d78840604a84d7d5a4d49c6a5debe23859c1b536fe622db23"
var manifest_path="res://tests/qa/results/deep_reopen_manifest.json"

func reject(sim, original: Dictionary, corrupt: Dictionary, label: String) -> void:
	var before: String=sim.state_hash()
	check(not sim.restore_state(corrupt),"Invalid restore refused: "+label)
	check(sim.state_hash()==before,"Rejected restore atomic: "+label)
	write(path,envelope(corrupt))
	check(Store.load_run(path).is_empty(),"Rehashed invalid envelope refused: "+label)
	check(sim.restore_state(original),"Valid state remains loadable")

func deep_paths(state: Dictionary) -> Array:
	var paths: Array=[]
	for key in state.floors[2]:
		if key!="layout": paths.append(["floors",2,key])
	for index in range(state.floors[2].fixtures.size()):
		for key in state.floors[2].fixtures[index]: paths.append(["floors",2,"fixtures",index,key])
	for index in range(state.floors[2].actors.size()):
		for key in state.floors[2].actors[index]: paths.append(["floors",2,"actors",index,key])
		if state.floors[2].actors[index].state=="windup":
			for key in state.floors[2].actors[index].intent: paths.append(["floors",2,"actors",index,"intent",key])
	for id in state.items:
		if state.items[id].floor==3:
			for key in state.items[id]: paths.append(["items",id,key])
	return paths

func malformed(original: Dictionary) -> void:
	var sim=Sim.new(original.seed,3); check(sim.restore_state(original),"Hostile baseline restore")
	# Independent file with invalid backups: malformed primary cannot be masked
	# by the documented transaction-recovery behavior.
	write(path+".tmp","invalid"); write(path+".bak","invalid")
	for keys in deep_paths(original):
		var value=original
		for key in keys: value=value[key]
		var replacements: Array=[null,true,1.5,[],{}]
		if value is bool: replacements=[null,0,1,[],{}]
		if value is String: replacements=[null,false,0,[],{}]
		if value is Array: replacements=[null,true,0,"bad",{}]
		if value is Dictionary: replacements=[null,true,0,"bad",[]]
		for replacement in replacements:
			var corrupt: Dictionary=original.duplicate(true); set_path(corrupt,keys,replacement)
			stats.type_cases+=1
			print("DEEP_FUZZ ",stats.type_cases," ",JSON.stringify(keys)," ",JSON.stringify(replacement))
			reject(sim,original,corrupt,JSON.stringify(keys))
	for mask in range(1,7):
		var corrupt: Dictionary=original.duplicate(true)
		var keys: Array=["rules_version","content_version","generator_version"]
		for index in range(3): corrupt[keys[index]]="m3.3" if mask & (1<<index) else "m4.1"
		reject(sim,original,corrupt,"mixed profile mask "+str(mask)); stats.recovery_cases+=1
	var wrong: Dictionary=original.duplicate(true)
	for key in ["rules_version","content_version","generator_version"]: wrong[key]="m3.3"
	reject(sim,original,wrong,"legacy headers with deep damage fields")
	for actor_index in range(3):
		for damage in [-1,0,4,"3",null]:
			wrong=original.duplicate(true); wrong.floors[2].actors[actor_index].damage=damage
			reject(sim,original,wrong,"invalid deep damage "+str(damage))
	var text: String=envelope(original)
	for length in [0,1,2,8,text.length()/4,text.length()/2,text.length()-2,text.length()-1]:
		write(path,text.left(length)); check(Store.load_run(path).is_empty(),"Truncated schema 2 refused"); stats.truncations+=1
	for value in [null,false,0,1,3,"2",[],{}]:
		var env: Dictionary=JSON.parse_string(text); env.save_version=value
		write(path,JSON.stringify(env)); check(Store.load_run(path).is_empty(),"Wrong envelope schema refused")
	write(path,text.replace(original.seed,"CORRUPT")); check(Store.load_run(path).is_empty(),"Bad checksum refused")

func _initialize() -> void:
	path="user://qa_m4a_deep_corrupt.json"
	if OS.get_cmdline_user_args().has("--phase=read"):
		var manifest: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string(manifest_path)))
		check(manifest.process_id!=OS.get_process_id(),"Writer fully exited; fresh process")
		var continued:=0
		for record in manifest.records:
			var loaded: Dictionary=Store.load_run(record.path)
			check(not loaded.is_empty(),"Reopen hostile snapshot")
			if loaded.is_empty(): continue
			var left=Sim.new(record.state.seed,record.state.floor_count)
			var right=Sim.new(record.state.seed,record.state.floor_count)
			check(left.restore_state(record.state) and right.restore_state(loaded.payload),"Restore both copies")
			check(left.state_hash()==record.hash and right.state_hash()==record.hash,"Fresh process full hash")
			check(Store.can_continue(record.path)==(record.state.status=="playing"),"Continue status")
			for action in record.continuation:
				var a: Dictionary=left.apply(action); var b: Dictionary=right.apply(action)
				check(a==b and left.state_hash()==right.state_hash(),"Identical full continuation and events")
				continued+=1
		stats.reopened=manifest.records.size(); stats.continuation_actions=continued; stats.writer_process_id=manifest.process_id
	else:
		var source: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/qa/results/deep_edges.json")))
		check(not source.checkpoints.is_empty(),"Targeted edge checkpoints required; run deep_edges first")
		var records: Array=[]; var categories: Dictionary={}; var hostile: Dictionary={}
		for checkpoint in source.checkpoints:
			var s: Dictionary=checkpoint.state
			var sim=Sim.new(s.seed,3)
			# Prefixes also contain intentional rejected belt/full-pack commands.
			for action in checkpoint.actions: sim.apply(action)
			check(sim.state_hash()==checkpoint.hash,"Checkpoint exact action-list reproduction")
			var json_state=JSON.parse_string(JSON.stringify(s))
			check(sim.restore_state(json_state) and sim.state_hash()==checkpoint.hash,"JSON round trip full hash")
			var recovery=Recovery.new(); recovery.setup(s)
			var outcome: Dictionary=recovery.finish(checkpoint.context.choice)
			var continuation: Array=outcome.actions
			if continuation.is_empty(): continuation=[{"type":"wait"},{"type":"turn","delta":1}]
			var target: String="user://qa_m4a_deep_reopen_%04d.json" % records.size()
			check(Store.save_run(sim,{},target,true),"Save hostile checkpoint")
			records.append({"state":s,"hash":checkpoint.hash,"path":target,"point":checkpoint.point,"continuation":continuation})
			categories[checkpoint.point]=categories.get(checkpoint.point,0)+1
			if checkpoint.point=="mid_lunge" and hostile.is_empty(): hostile=s
		for required in ["mid_lunge","just_after_deep_burn","floor_three_landing","spent_coat_meets_hound","before_win"]:
			check(categories.has(required),"Hostile moment covered: "+required)
		var legacy_path: String="user://qa_m4a_m3f_fixture.json"
		write(legacy_path,FileAccess.get_file_as_string("res://tests/fixtures/m3f_run.json"))
		var legacy: Dictionary=Store.load_run(legacy_path)
		check(not legacy.is_empty(),"Production M3f fixture loads")
		if not legacy.is_empty():
			var sim=Sim.new("BELL42",3)
			check(sim.restore_state(legacy.payload) and sim.state_hash()==LEGACY_HASH,"Exact M3f fixture hash")
			var old: Dictionary=Witness.new().run("BELL42",2,false,"return",legacy.payload,true)
			check(old.ok and old.snapshot.status=="won","Continue legacy profile to win")
			check(sim.snapshot().rules_version=="m3.3" and sim.snapshot().floor_count==2,"Legacy stays two floors m3.3")
			records.append({"state":legacy.payload,"hash":LEGACY_HASH,"path":legacy_path,"point":"m3f_fixture","continuation":old.actions})
		if not hostile.is_empty(): malformed(hostile)
		write(manifest_path,JSON.stringify({"process_id":OS.get_process_id(),"records":records}))
		stats.snapshots=records.size(); stats.categories=categories; stats.legacy_hash=LEGACY_HASH
	var suffix: String="read" if OS.get_cmdline_user_args().has("--phase=read") else "write"
	write("res://tests/qa/results/deep_save_"+suffix+".json",JSON.stringify(stats,"\t"))
	print("QA DEEP SAVE ",suffix," ",JSON.stringify(stats))
	quit(1 if not stats.failures.is_empty() else 0)
