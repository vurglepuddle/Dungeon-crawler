extends RefCounted
## Presentation knowledge, separate from deterministic rules/legacy hashes.
const Art=preload("res://scripts/art/presentation_art.gd")
var floors: Array=[]
func reset(count: int) -> void:
	floors=[]
	for _i in range(count): floors.append({"seen":"0".repeat(289),"walked":"0".repeat(289),"landmarks":[]})
func restore(raw,simulation: Dictionary) -> bool:
	reset(simulation.floor_count)
	if not raw is Dictionary or raw.get("version")!=1 or not raw.get("floors") is Array: return false
	if raw.floors.size()!=floors.size() or raw.get("sha256")!=JSON.stringify(raw.floors,"",true).sha256_text(): return false
	for i in range(floors.size()):
		var entry=raw.floors[i]
		if not entry is Dictionary or entry.keys().size()!=3 or not entry.get("landmarks") is Array: return false
		var allowed: Array=simulation.floors[i].fixtures.map(func(f): return f.id)
		var unique: Dictionary={}
		for id in entry.landmarks:
			if not id is String or not allowed.has(id) or unique.has(id): return false
			unique[id]=true
		for key in ["seen","walked"]:
			if not entry.get(key) is String or entry[key].length()!=289: return false
			for bit in entry[key]:
				if bit not in ["0","1"]: return false
		for cell in range(289):
			if entry.walked[cell]=="1" and (entry.seen[cell]!="1" or simulation.floors[i].tiles[cell]!=0): return false
	floors=raw.floors.duplicate(true)
	return true
func observe(floor_number: int,report: Array,pos: Array,landmarks: Array=[]) -> void:
	if floor_number<1 or floor_number>floors.size(): return
	var entry: Dictionary=floors[floor_number-1]
	for cell in report:
		var index: int=cell[1]*17+cell[0]
		if index>=0 and index<289: entry.seen[index]="1"
	var index: int=pos[1]*17+pos[0]
	entry.seen[index]="1"; entry.walked[index]="1"
	for id in landmarks:
		if not entry.landmarks.has(id): entry.landmarks.append(id)
	entry.landmarks.sort()
func save() -> Dictionary:
	return {"version":1,"floors":floors.duplicate(true),"sha256":hash_value()}
func hash_value() -> String: return JSON.stringify(floors,"",true).sha256_text()
func floor_data(number: int) -> Dictionary:
	return floors[number-1].duplicate() if number>=1 and number<=floors.size() else {}
