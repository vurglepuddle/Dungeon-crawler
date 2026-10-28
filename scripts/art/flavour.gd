extends RefCounted
static var _provenance: Dictionary={}
static var _flavour: Dictionary={}
static var _loaded: bool=false
static func _read(path: String) -> Dictionary:
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return {}
	var data: Dictionary=parser.data
	return data if data.get("schema_version")==1 else {}
static func _load_data() -> void:
	if _loaded: return
	_loaded=true
	_provenance=_read("res://data/text/provenance.json")
	_flavour=_read("res://data/text/flavour.json")
static func valid_lines(value) -> bool:
	return value is Array and value.size()>0 and value.size()<=2 and value.all(func(line): return line is String and line.length()<=21)
static func provenance(kind: String,fallback: String) -> String:
	_load_data()
	var lines=_provenance.get("items",{}).get(kind,[])
	return "\n".join(lines) if valid_lines(lines) else fallback
static func floor_name(number: int) -> String:
	_load_data()
	var lines=_flavour.get("floor_names",{}).get(str(number),[])
	return "\n".join(lines) if valid_lines(lines) else "Floor %d"%number
static func epitaph(seed: String,turn: int) -> String:
	_load_data()
	var entries: Array=_flavour.get("death_epitaphs",[])
	if entries.is_empty(): return "One more lost thing."
	var lines=entries[preload("res://scripts/art/presentation_art.gd").mix_hash(seed+str(turn))%entries.size()]
	return "\n".join(lines) if valid_lines(lines) else "One more lost thing."
