class_name UndercroftFloorGen
extends RefCounted
const Catalog = preload("res://scripts/content/catalog.gd")
const Rooms=preload("res://scripts/gen/capability_rooms.gd")
const Dressing=preload("res://scripts/gen/room_dressing.gd")
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const WIDTH := 17
const HEIGHT := 17
var _rng: int = 1

static func normalize_seed(raw: String) -> String:
	var seed := raw.strip_edges().to_upper()
	if seed.is_empty() or seed.length() > 6: return ""
	for letter in seed:
		if not ALPHABET.contains(letter): return ""
	return seed

func _next(limit: int) -> int:
	_rng = (1664525 * _rng + 1013904223) & 0xffffffff
	return int((_rng >> 8) % limit)

func _carve(tiles: Array, x1: int, y1: int, x2: int, y2: int) -> void:
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			tiles[y * WIDTH + x] = 0

func generate(raw: String,count: int=2) -> Dictionary:
	var seed:=normalize_seed(raw)
	if seed.is_empty() or count<1 or count>4: return {"ok":false,"error":"Invalid seed or count."}
	_rng=2166136261
	for byte in seed.to_utf8_buffer(): _rng=((_rng^byte)*16777619)&0xffffffff
	var floors: Array=[]
	var items: Dictionary={"knife_start":{"id":"knife_start","kind":"knife","location":"equip","floor":0,"pos":[],"slot":"hand","spent":false}}
	for index in range(count):
		var number:=index+1
		var prefix: String="f%d_"%number
		var spine:=6+_next(5)
		var side: int=-1 if _next(2)==0 else 1
		var branch:=clampi(spine+side*(3+_next(4)),2,14)
		var loop_top:=6+_next(2)
		var landing_y:=1+_next(3)
		# Entry floor teaches both gates. Later floors choose a different module mix.
		var module:=0 if number==1 else _next(3)
		var weight_gate: bool=module!=2
		var keyed_gate: bool=module!=1
		var tiles: Array=[]; tiles.resize(WIDTH*HEIGHT); tiles.fill(1)
		_carve(tiles,spine-1,12,spine+1,15)
		_carve(tiles,spine,4,spine,12)
		_carve(tiles,spine-1,1,spine+1,4)
		_carve(tiles,mini(spine,branch),9,maxi(spine,branch),9)
		_carve(tiles,mini(spine,branch),loop_top,maxi(spine,branch),loop_top)
		_carve(tiles,branch,loop_top,branch,9)
		_carve(tiles,branch-1,7,branch+1,8)
		# One narrow side pocket varies which side of the loop holds the key.
		var key_x:=branch+(-1 if _next(2)==0 else 1)
		var key_y:=7+_next(2)
		var fixtures: Array=[]
		if weight_gate:
			fixtures.append_array([
				{"id":prefix+"plate","type":"plate","pos":[spine,13],"gate_id":prefix+"gate","pressed":false},
				{"id":prefix+"gate","type":"gate","pos":[spine,10],"plate_id":prefix+"plate","open":false,"latched":false},
				{"id":prefix+"latch","type":"latch","pos":[spine,9],"gate_id":prefix+"gate"}])
		if keyed_gate: fixtures.append({"id":prefix+"lock","type":"lock","pos":[spine,5],"key_id":prefix+"key","open":false})
		fixtures.append({"id":prefix+"up","type":"exit" if number==1 else "stairs_up","pos":[spine,15]})
		if number<count: fixtures.append({"id":prefix+"down","type":"stairs_down","pos":[spine,landing_y]})
		var visited: Array=[]; visited.resize(WIDTH*HEIGHT); visited.fill(false)
		floors.append({"width":WIDTH,"height":HEIGHT,"tiles":tiles,"fixtures":fixtures,
			"actors":[{"id":prefix+"husk","kind":"husk","pos":[spine,7],"hp":Catalog.CREATURES.husk.hp,"state":"idle","intent":{}}],
			"visited":visited,"start":[spine,15],"landing":[spine,landing_y],
			"layout":{"loop_top":loop_top,"loop_bottom":9,"branch":branch,"weight":weight_gate,"keyed":keyed_gate}})
		var offerings: Array=[["stone",spine,14]]
		if number==1: offerings.append_array([["club",spine+1,14],["coat",spine-1,13],["bread",spine-1,12],["tonic",spine+1,13]])
		var locations: Array=[[branch,7],[branch-1,8],[branch+1,8],[spine-1,3],[spine+1,3],[spine+1,12]]
		var pool: Array=["bread","tonic","bone","shard","lamp","club","coat"]
		var extra:=2+_next(5) if number==1 else 3+_next(4)
		for n in range(extra):
			var choices: Array=pool
			if number>1:
				choices=pool.filter(func(k): return offerings.all(func(o): return o[0]!=k))
				if n==0: choices=choices.filter(func(k): return k in ["bread","tonic","bone"])
				elif n==1: choices=choices.filter(func(k): return k in ["lamp","shard"])
			var kind: String=choices[_next(choices.size())]
			# Cap duplicate ordinary kinds at two; variety, not ten of one thing.
			if offerings.filter(func(o): return o[0]==kind).size()>=2:
				for candidate in pool:
					if offerings.filter(func(o): return o[0]==candidate).size()<2: kind=candidate; break
			offerings.append([kind,locations[n][0],locations[n][1]])
		if keyed_gate: offerings.append(["key",key_x,key_y])
		if number==count: offerings.append(["seal",spine,landing_y])
		for n in range(offerings.size()):
			var offer: Array=offerings[n]
			var id: String=prefix+str(offer[0])
			if items.has(id) or offer[0] in ["bread","tonic","bone","shard","lamp"]: id+="_%d"%n
			items[id]={"id":id,"kind":offer[0],"location":"floor","floor":number,"pos":[offer[1],offer[2]],"slot":"","spent":false}
	# A peaceful owner, a recoverable clapper, and two persistent lift landings.
	var first: Dictionary=floors[0]
	var last: Dictionary=floors[count-1]
	var low: Array=[first.start[0]+1,15]
	var high: Array=[last.start[0]+1,15] if count>1 else [first.landing[0]+1,first.landing[1]]
	first.fixtures.append({"id":"bell_porter","type":"porter","pos":[first.start[0]-1,3],"item_id":"bell_clapper","restored":false})
	first.fixtures.append({"id":"lift_home","type":"lift","pos":low,"owner_id":"bell_porter","active":false,"destination_floor":count,"destination":high.duplicate(),"destination_id":"lift_deep"})
	last.fixtures.append({"id":"lift_deep","type":"lift","pos":high,"owner_id":"bell_porter","active":false,"destination_floor":1,"destination":low.duplicate(),"destination_id":"lift_home"})
	items.bell_clapper={"id":"bell_clapper","kind":"clapper","location":"floor","floor":1,"pos":[first.layout.branch,8],"slot":"","spent":false}
	var result: Dictionary={"ok":true,"seed":seed,"floors":floors,"items":items}
	Rooms.decorate(result)
	_clear_spawn_cells(result)
	Dressing.place(result)
	return result

static func _clear_spawn_cells(run: Dictionary) -> void:
	# Later modules add owners/fixtures after ordinary offerings. Reserve their
	# final cells in one pass, including concealed rewards; never bury loot.
	for index in range(run.floors.size()):
		var f: Dictionary=run.floors[index]
		var reserved: Array=[f.start,f.landing]
		for fixture in f.fixtures: reserved.append(fixture.pos)
		for actor in f.actors: reserved.append(actor.pos)
		for item in run.items.values():
			if item.location!="floor" or item.floor!=index+1 or item.kind=="seal" or not reserved.has(item.pos): continue
			var best: Array=[]; var distance:=10000
			for y in range(1,16):
				for x in range(1,16):
					var p: Array=[x,y]
					if f.tiles[y*17+x]!=0 or reserved.has(p): continue
					var d: int=absi(x-item.pos[0])+absi(y-item.pos[1])
					if d<distance: best=p; distance=d
			assert(not best.is_empty(),"Every module reserves an empty loot cell")
			item.pos=best
