class_name UndercroftSaveStore
extends RefCounted
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const DEFAULT_PATH := "user://run.json"

static func _read(path: String) -> Dictionary:
	if not path.begins_with("user://") or path.contains("..") or not FileAccess.file_exists(path): return {}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>4000000: return {}
	var parser:=JSON.new()
	if parser.parse(file.get_as_text())!=OK: return {}
	var parsed = parser.data
	if not parsed is Dictionary or parsed.get("save_version")!=2 or not parsed.get("payload") is Dictionary or not parsed.get("ui") is Dictionary: return {}
	var normalized = Codec.normalize(parsed.payload)
	if not normalized is Dictionary or not Codec.validate(normalized): return {}
	if parsed.get("sha256")!=Codec.canonical(normalized).sha256_text(): return {}
	return {"payload":normalized,"ui":parsed.ui,"source":path}

static func load_run(path: String=DEFAULT_PATH) -> Dictionary:
	# A valid primary is the last committed transaction. Staging then backup
	# recover interrupted replacement; do not compare revisions across new runs.
	for candidate in [path,path+".tmp",path+".bak"]:
		var data:=_read(candidate)
		if not data.is_empty(): return data
	return {}

static func can_continue(path: String=DEFAULT_PATH) -> bool:
	var data:=load_run(path)
	return not data.is_empty() and data.payload.status=="playing"

static func _write(path: String,text: String) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text); file.flush()
	return file.get_error()==OK

static func save_run(sim,ui: Dictionary={},path: String=DEFAULT_PATH,new_run: bool=false) -> bool:
	if not path.begins_with("user://") or path.contains("..") or not path.ends_with(".json"): return false
	var payload: Dictionary=sim.save_state()
	if not Codec.validate(payload): return false
	# Stay on user:// paths: globalize_path() + *_absolute() silently failed on Android.
	var directory:=path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory) and DirAccess.make_dir_recursive_absolute(directory)!=OK: return _fail(path,"make dir")
	var dir:=DirAccess.open(directory)
	if dir==null: return _fail(path,"open dir")
	var text:=JSON.stringify({"save_version":2,"payload":payload,"ui":ui,
		"sha256":Codec.canonical(payload).sha256_text()})
	if not _write(path+".tmp",text) or _read(path+".tmp").is_empty(): return _fail(path,"write tmp")
	var previous:=_read(path)
	var mirror: bool=new_run or payload.status!="playing"
	if mirror:
		if not _write(path+".bak",text) or _read(path+".bak").is_empty(): return false
	elif not previous.is_empty():
		var old_text:=FileAccess.get_file_as_string(path)
		if not _write(path+".bak",old_text) or _read(path+".bak").is_empty(): return false
	if dir.file_exists(path.get_file()) and dir.remove(path.get_file())!=OK: return _fail(path,"remove old")
	return dir.rename(path.get_file()+".tmp",path.get_file())==OK or _fail(path,"rename")

static func _fail(path: String,step: String) -> bool:
	push_error("Save failed at %s: %s" % [step,path])
	return false
