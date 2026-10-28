extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const Witness = preload("res://scripts/gen/witness.gd")
var stats := {"checks":0,"failures":[],"type_cases":0,"accepted_corruptions":[],"truncations":0,"recovery_cases":0}
var path := "user://tests/qa/corrupt.json"

func check(ok: bool, message: String) -> void:
	stats.checks+=1
	if not ok: stats.failures.append(message); printerr("QA SAVE FAIL ",message)

func write(target: String, value: String) -> void:
	var file:=FileAccess.open(target,FileAccess.WRITE)
	check(file!=null,"Open isolated fuzz file")
	if file!=null: file.store_string(value); file.flush(); file.close()

func envelope(state: Dictionary) -> String:
	return JSON.stringify({"save_version":2,"payload":state,"ui":{},"sha256":Codec.canonical(Codec.normalize(state)).sha256_text()})

func set_path(state: Dictionary, keys: Array, replacement) -> void:
	var cursor = state
	for index in range(keys.size()-1): cursor=cursor[keys[index]]
	cursor[keys.back()]=replacement

func selected_paths(state: Dictionary) -> Array:
	var paths: Array=[]
	for key in state: paths.append([key])
	for key in state.equipment: paths.append(["equipment",key])
	for key in state.floors[0]:
		if key=="layout": continue
		paths.append(["floors",0,key])
	for key in ["tiles","visited","start","landing"]: paths.append(["floors",0,key,0])
	for index in range(state.floors[0].fixtures.size()):
		paths.append(["floors",0,"fixtures",index])
		for key in state.floors[0].fixtures[index]: paths.append(["floors",0,"fixtures",index,key])
	for key in state.floors[0].actors[0]: paths.append(["floors",0,"actors",0,key])
	for id in ["knife_start","f1_key","bell_clapper"]:
		paths.append(["items",id])
		for key in state.items[id]: paths.append(["items",id,key])
	return paths

func _initialize() -> void:
	var sim=Sim.new("BELL42")
	check(Store.save_run(sim,{},path,true),"Initialize isolated save dir")
	write(path+".tmp","invalid"); write(path+".bak","invalid")
	var original: Dictionary=sim.snapshot()
	var before: String=sim.state_hash()
	for keys in selected_paths(original):
		var value = original
		for key in keys: value=value[key]
		var replacements: Array=[null,true,1.5,"bad",[],{}]
		if value is bool: replacements=[null,0,1,"false",[],{}]
		if value is String: replacements=[null,false,0,[],{}]
		if value is Array: replacements=[null,true,0,"bad",{}]
		if value is Dictionary: replacements=[null,true,0,"bad",[]]
		for replacement in replacements:
			var corrupt: Dictionary=original.duplicate(true)
			set_path(corrupt,keys,replacement)
			stats.type_cases+=1
			print("FUZZ_CASE ",stats.type_cases," ",JSON.stringify(keys)," = ",JSON.stringify(replacement))
			var accepted = sim.restore_state(corrupt)
			if accepted!=false:
				stats.accepted_corruptions.append({"keys":keys,"replacement":replacement,"outcome":accepted})
				# Restore a known valid state after the probe, never continue this run.
				check(sim.restore_state(original),"Restore valid state after corrupt probe")
			else: check(sim.state_hash()==before,"Rejected restore is atomic "+JSON.stringify(keys))
			write(path,envelope(corrupt))
			var loaded = Store.load_run(path)
			check(loaded is Dictionary,"load_run always returns Dictionary "+JSON.stringify(keys))
			if accepted==false: check(loaded.is_empty(),"Disk rejects same invalid state "+JSON.stringify(keys))
	var valid: String=envelope(original)
	for length in [0,1,2,8,valid.length()/4,valid.length()/2,valid.length()-2,valid.length()-1]:
		write(path,valid.left(length))
		check(Store.load_run(path).is_empty(),"Truncation rejected at "+str(length))
		stats.truncations+=1
	for raw in ["null","[]","false","1","\"text\"","{","{\"save_version\":2}",valid.replace("\"save_version\":2","\"save_version\":99"),valid.replace(original.seed,"QZZZ")]:
		write(path,raw)
		check(Store.load_run(path).is_empty(),"Malformed envelope or checksum rejected")
	write(path,"x".repeat(4000001))
	check(Store.load_run(path).is_empty(),"Oversize rejected")
	var invalid_payload: Dictionary=original.duplicate(true)
	invalid_payload.items.f1_key.location="consumed"
	write(path,envelope(invalid_payload))
	check(Store.load_run(path).is_empty(),"Rehashed impossible consumed key rejected")
	# Transaction recovery matrix: valid primary wins regardless of revision/seed.
	var other=Sim.new("NEW222")
	other.apply({"type":"turn","delta":1})
	for primary in [true,false]:
		for staging in [true,false]:
			for backup in [true,false]:
				write(path,valid if primary else "broken")
				write(path+".tmp",envelope(other.snapshot()) if staging else "broken")
				write(path+".bak",valid if backup else "broken")
				var loaded: Dictionary=Store.load_run(path)
				var expected: String="BELL42" if primary else "NEW222" if staging else "BELL42" if backup else ""
				check(loaded.is_empty() if expected=="" else loaded.payload.seed==expected,"Primary/staging/backup precedence")
				stats.recovery_cases+=1
	# Terminal and replacement backup cohorts cannot resurrect older runs.
	var proof: Dictionary=Witness.build("BELL42",2,false,"return")
	check(sim.restore_state(proof.snapshot),"Terminal witness restore")
	check(Store.save_run(sim,{},path),"Terminal save")
	write(path,"broken")
	check(Store.load_run(path).payload.status=="won" and not Store.can_continue(path),"Finished run cannot continue via backup")
	check(Store.save_run(other,{},path,true),"Replacement run save")
	write(path,"broken")
	check(Store.load_run(path).payload.seed=="NEW222","Replacement backup belongs to new seed")
	var file:=FileAccess.open("res://tests/qa/results/save_fuzz.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(stats,"\t")); file.close()
	print("QA SAVE FUZZ COMPLETE ",JSON.stringify(stats))
	quit(1 if not stats.failures.is_empty() or not stats.accepted_corruptions.is_empty() else 0)
