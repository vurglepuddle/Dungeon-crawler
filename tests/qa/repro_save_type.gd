extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Store = preload("res://scripts/persistence/save_store.gd")

func _initialize() -> void:
	var sim=Sim.new("BELL42")
	var path: String="user://qa_m4a_legacy_repro_type.json"
	if not Store.save_run(sim,{},path,true): quit(1); return
	var envelope: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	# A single corrupted type must be refused without a script error, even when
	# the old checksum no longer matches. Validation currently runs before hashing.
	envelope.payload.schema_version=true
	for suffix in ["", ".tmp", ".bak"]:
		var file:=FileAccess.open(path+suffix,FileAccess.WRITE)
		file.store_string(JSON.stringify(envelope)); file.close()
	var loaded: Dictionary=Store.load_run(path)
	print("QA malformed schema type refused: ",loaded.is_empty(),"; log must contain no SCRIPT ERROR")
	quit(0 if loaded.is_empty() else 1)
