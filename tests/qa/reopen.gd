extends "res://tests/qa/adversarial.gd"
var manifest_path: String="res://tests/qa/results/reopen_manifest.json"

func _initialize() -> void:
	rng.seed=1993
	if OS.get_cmdline_user_args().has("--phase=read"):
		var manifest: Dictionary=Codec.normalize(JSON.parse_string(FileAccess.get_file_as_string(manifest_path)))
		require(manifest.process_id!=OS.get_process_id(),"REOPEN_FRESH_PROCESS")
		for record in manifest.records:
			context={"seed":record.state.seed,"count":record.state.floor_count,"policy":"fresh_process_reopen","point":record.point}
			trace=[]
			var loaded: Dictionary=Store.load_run(record.path)
			require(not loaded.is_empty(),"REOPEN_DISK_LOAD")
			if loaded.is_empty(): continue
			var left=Sim_from(record.state)
			var right=Sim_from(loaded.payload)
			require(left.state_hash()==right.state_hash() and right.state_hash()==record.hash,"REOPEN_FULL_HASH")
			require(Store.can_continue(record.path)==(record.state.status=="playing"),"REOPEN_TERMINAL_CONTINUE")
			for action in record.continuation:
				var a: Dictionary=act(left,action)
				var b: Dictionary=act(right,action)
				require(a==b and left.state_hash()==right.state_hash(),"REOPEN_CONTINUATION")
				stats.lockstep_actions+=1
			stats.disk_roundtrips+=1
		var file:=FileAccess.open("res://tests/qa/results/reopen_read.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"process_id":OS.get_process_id(),"writer_process_id":manifest.process_id,"checks":checks,"stats":stats,"findings":findings},"\t")); file.close()
		print("QA REOPEN READ ",stats.disk_roundtrips," snapshots; ",stats.lockstep_actions," continuation commands; ",findings.size()," failures")
	else:
		var records: Array=[]
		for seed in ["BELL42","AAAAAA","999999","AZ29AZ"]:
			for count in [1,2,3,4]:
				for choice in ["keep","return","ring"]:
					context={"seed":seed,"count":count,"choice":choice,"policy":"fresh_process_write"}
					trace=[]
					var proof: Dictionary=Witness.build(seed,count,false,choice)
					require(proof.ok,"REOPEN_WITNESS")
					var sim=Sim.new(seed,count)
					var points: Dictionary={}
					for index in range(proof.actions.size()):
						var action: Dictionary=proof.actions[index]
						var point: String=""
						if index==proof.actions.size()-1: point="before_win"
						if index==proof.actions.size()/2: point="mid_run"
						if point!="" and not points.has(point):
							save_record(records,sim,proof.actions.slice(index,index+16),point)
							points[point]=true
						act(sim,action)
						point=""
						if action.type=="ring": point="just_after_ring"
						if action.type=="return_item": point="just_after_restoration"
						if action.type=="stairs": point="after_stairs"
						if action.type=="pickup" and sim.definition(action.item_id).get("slot","")=="belt": point="after_belt_pickup"
						if action.type=="leave": point="won"
						if sim.floor_data().actors.any(func(actor): return actor.state=="windup"): point="pending_attack"
						for fixture in sim.local_fixtures():
							if fixture.type=="plate" and fixture.pos==sim.snapshot().pos: point="weighted_plate" if action.type=="drop" else "on_plate"
						if point!="" and not points.has(point):
							save_record(records,sim,proof.actions.slice(index+1,index+17),point)
							points[point]=true
		# A terminal death is also reached by real actions and carried over the
		# process boundary; it cannot offer Continue through a backup.
		var death=Sim.new("BELL42",2)
		context={"seed":"BELL42","count":2,"policy":"intentional_death"}; trace=[]
		var death_proof: Dictionary=Witness.build("BELL42",2,false,"keep")
		for action in death_proof.actions:
			if action.type=="hit": break
			act(death,action)
		for _beat in range(24):
			if death.snapshot().status!="playing": break
			act(death,{"type":"wait"})
		require(death.snapshot().hp==0 and death.snapshot().status=="lost","DEATH_TERMINAL")
		save_record(records,death,[{"type":"wait"},{"type":"turn","delta":1}],"lost")
		var file:=FileAccess.open(manifest_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"process_id":OS.get_process_id(),"records":records},"\t")); file.close()
		print("QA REOPEN WRITE ",records.size()," snapshots; process ",OS.get_process_id(),"; ",findings.size()," failures")
	quit(1 if not findings.is_empty() else 0)

func save_record(records: Array, sim, continuation: Array, point: String) -> void:
	var path: String="user://tests/qa/reopen_%03d.json" % records.size()
	require(Store.save_run(sim,{},path,true),"REOPEN_SAVE")
	records.append({"path":path,"hash":sim.state_hash(),"state":sim.snapshot(),"continuation":continuation,"point":point})
