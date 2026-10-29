extends RefCounted
## Independent of run snapshots. Pilots derive an isolated path from their save.
static func fallen(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return false
	var raw=parser.data
	return raw is Dictionary and raw.get("fallen") is bool and raw.fallen
static func mark(path: String) -> bool:
	if not path.begins_with("user://") or path.contains(".."): return false
	var directory: String=path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory): DirAccess.make_dir_recursive_absolute(directory)
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string('{"fallen":true}'); file.flush(); file.close()
	var dir=DirAccess.open(directory)
	if dir==null: return false
	if dir.file_exists(path.get_file()): dir.remove(path.get_file())
	return dir.rename(path.get_file()+".tmp",path.get_file())==OK
