class_name UndercroftStateCodec
extends RefCounted
const Catalog = preload("res://scripts/content/catalog.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")

static func normalize(value, depth: int=0):
	if depth>16: return null
	if value is float:
		return int(value) if is_finite(value) and absf(value)<9007199254740991.0 and value==floorf(value) else null
	if value is Array:
		var result: Array=[]
		for entry in value: result.append(normalize(entry,depth+1))
		return result
	if value is Dictionary:
		var result: Dictionary={}
		for key in value: result[key]=normalize(value[key],depth+1)
		return result
	return value

static func canonical(value) -> String:
	return JSON.stringify(value,"",true)

static func _cell(value, f: Dictionary) -> bool:
	return value is Array and value.size()==2 and value[0] is int and value[1] is int and value[0]>=0 and value[1]>=0 and value[0]<f.width and value[1]<f.height and f.tiles[value[1]*f.width+value[0]]==0

static func validate(s: Dictionary) -> bool:
	for key in ["schema_version","rules_version","generator_version","content_version","seed","floor_count","floor","pos","facing","turn","revision","hp","max_hp","status","pack","equipment","belt","floors","items"]:
		if not s.has(key): return false
	if not s.schema_version is int or s.schema_version!=2: return false
	for key in ["rules_version","generator_version","content_version","status"]:
		if not s[key] is String: return false
	var profiles: Dictionary={"m2.1":"m2.1","m3.1":"m3.1","m3.2":"m3.1","m3.3":"m3.3"}
	if not profiles.has(s.rules_version) or s.generator_version!=profiles[s.rules_version] or s.content_version!=s.rules_version: return false
	if not s.seed is String or Gen.normalize_seed(s.seed)!=s.seed: return false
	for key in ["floor_count","floor","facing","turn","revision","hp","max_hp"]:
		if not s[key] is int: return false
	if s.floor_count<1 or s.floor_count>4 or s.floor<1 or s.floor>s.floor_count or s.facing<0 or s.facing>3: return false
	if s.turn<0 or s.revision<s.turn or s.revision>10000000 or s.max_hp!=6 or s.hp<0 or s.hp>6: return false
	if s.status not in ["playing","won","lost"] or (s.status=="lost")!=(s.hp==0): return false
	if not s.floors is Array or s.floors.size()!=s.floor_count or not s.items is Dictionary or s.items.size()>128: return false
	if not s.pos is Array or s.pos.size()!=2 or not s.pos[0] is int or not s.pos[1] is int: return false
	if not s.pack is Array or s.pack.size()>8 or not s.belt is Array or s.belt.size()>s.floor_count+1: return false
	if not s.equipment is Dictionary or s.equipment.keys().size()!=2 or not s.equipment.has("hand") or not s.equipment.has("body"): return false
	if not s.equipment.hand is String or not s.equipment.body is String: return false
	var all_ids: Dictionary={}
	var fixtures_all: Dictionary={}
	var fixture_floors: Dictionary={}
	var floor_number:=0
	for f in s.floors:
		floor_number+=1
		if not f is Dictionary: return false
		for key in ["width","height","tiles","fixtures","actors","visited","start","landing"]:
			if not f.has(key): return false
		if not f.width is int or not f.height is int or f.width!=17 or f.height!=17 or not f.tiles is Array or f.tiles.size()!=289 or not f.visited is Array or f.visited.size()!=289: return false
		for tile in f.tiles:
			if not tile is int or tile not in [0,1]: return false
		for seen in f.visited:
			if not seen is bool: return false
		if f.has("bell_rung") and (not f.bell_rung is bool or s.rules_version not in ["m3.2","m3.3"]): return false
		if not _cell(f.start,f) or not _cell(f.landing,f): return false
		if not f.fixtures is Array or f.fixtures.size()>32 or not f.actors is Array or f.actors.size()>8: return false
		var fixture_ids: Dictionary={}
		for fixture in f.fixtures:
			if not fixture is Dictionary or not fixture.get("id") is String or not _cell(fixture.get("pos"),f): return false
			if all_ids.has(fixture.id): return false
			all_ids[fixture.id]=true; fixture_ids[fixture.id]=fixture
			fixtures_all[fixture.id]=fixture; fixture_floors[fixture.id]=floor_number
			if not fixture.get("type") is String or fixture.type not in ["plate","gate","latch","lock","stairs_up","stairs_down","exit","porter","lift","brazier","web","cord","panel"]: return false
			if fixture.type in ["brazier","web","cord","panel"] and s.rules_version!="m3.3": return false
			if fixture.type=="brazier" and not fixture.get("lit") is bool: return false
			if fixture.type in ["web","cord","panel"] and not fixture.get("open") is bool: return false
			if fixture.type=="panel":
				if not fixture.get("revealed") is bool or not fixture.get("item_id") is String: return false
				if not fixture.get("wall") is Array or fixture.wall.size()!=2 or not fixture.wall[0] is int or not fixture.wall[1] is int: return false
				if fixture.wall[0]<0 or fixture.wall[1]<0 or fixture.wall[0]>=17 or fixture.wall[1]>=17 or f.tiles[fixture.wall[1]*17+fixture.wall[0]]!=1: return false
				if not fixture.get("normal") is Array or fixture.normal not in [[0,-1],[1,0],[0,1],[-1,0]]: return false
				if [fixture.wall[0]+fixture.normal[0],fixture.wall[1]+fixture.normal[1]]!=fixture.pos or fixture.open and not fixture.revealed: return false
			for link in ["gate_id","plate_id","key_id","owner_id","destination_id"]:
				if fixture.has(link) and not fixture[link] is String: return false
			if fixture.type in ["gate","lock"] and not fixture.get("open") is bool: return false
			if fixture.type=="gate" and not fixture.get("latched") is bool: return false
			if fixture.type=="plate" and not fixture.get("pressed") is bool: return false
			if fixture.type=="porter" and (not fixture.get("restored") is bool or not fixture.get("item_id") is String): return false
			if fixture.type=="lift":
				if not fixture.get("active") is bool or not fixture.get("owner_id") is String or not fixture.get("destination_id") is String: return false
				if not fixture.get("destination_floor") is int or fixture.destination_floor<1 or fixture.destination_floor>s.floor_count: return false
		for fixture in f.fixtures:
			if fixture.type in ["plate","latch"] and (not fixture_ids.has(fixture.get("gate_id")) or fixture_ids[fixture.gate_id].type!="gate"): return false
			if fixture.type=="gate" and (not fixture_ids.has(fixture.get("plate_id")) or fixture_ids[fixture.plate_id].type!="plate"): return false
			if fixture.type=="lock":
				if not fixture.get("key_id") is String or not s.items.has(fixture.key_id) or not s.items[fixture.key_id] is Dictionary: return false
				if not s.items[fixture.key_id].get("kind") is String or s.items[fixture.key_id].kind!="key": return false
		var occupied: Array=[]
		for actor in f.actors:
			if not actor is Dictionary: return false
			for key in ["id","kind","pos","hp","state","intent"]:
				if not actor.has(key): return false
			if not actor.id is String or not actor.kind is String or not actor.state is String or all_ids.has(actor.id) or not Catalog.CREATURES.has(actor.kind) or not _cell(actor.pos,f): return false
			all_ids[actor.id]=true
			if not actor.hp is int or actor.hp<0 or actor.hp>Catalog.CREATURES[actor.kind].hp or actor.state not in ["idle","windup","recovery","dead","peaceful"] or not actor.intent is Dictionary: return false
			if actor.kind!="husk" and s.rules_version!="m3.3" or actor.state=="peaceful" and actor.kind!="hound": return false
			if (actor.hp==0)!=(actor.state=="dead"): return false
			if actor.state=="windup":
				if not _cell(actor.intent.get("cell"),f) or not actor.intent.get("due_in") is int or actor.intent.due_in!=1: return false
				if actor.kind=="hound":
					if not actor.intent.get("lane") is Array or actor.intent.lane.size()<1 or actor.intent.lane.size()>2: return false
					var previous: Array=actor.pos
					var direction: Array=[]
					for cell in actor.intent.lane:
						if not _cell(cell,f): return false
						var delta: Array=[cell[0]-previous[0],cell[1]-previous[1]]
						if delta not in [[0,-1],[1,0],[0,1],[-1,0]] or not direction.is_empty() and direction!=delta: return false
						direction=delta; previous=cell
					if not actor.intent.lane.has(actor.intent.cell): return false
			elif not actor.intent.is_empty(): return false
			if actor.hp>0:
				if occupied.has(actor.pos) or floor_number==s.floor and actor.pos==s.pos: return false
				occupied.append(actor.pos)
				for fixture in f.fixtures:
					if fixture.pos==actor.pos and (fixture.type=="porter" or fixture.type in ["gate","lock","web","cord"] and not fixture.open): return false
	# Validate links only after every floor and fixture has been checked.
	for fixture in fixtures_all.values():
		if fixture.type=="panel":
			var reward=s.items.get(fixture.item_id)
			if not reward is Dictionary or not reward.get("hidden") is bool or reward.hidden==fixture.open: return false
		if fixture.type=="porter":
			var item = s.items.get(fixture.item_id)
			if not item is Dictionary or not item.get("kind") is String or not item.get("location") is String or item.kind!="clapper": return false
			if fixture.restored!=(item.get("location")=="returned"): return false
			if fixture.restored and (not item.get("owner_id") is String or item.owner_id!=fixture.id): return false
		if fixture.type=="lift":
			var owner = fixtures_all.get(fixture.owner_id)
			var dest = fixtures_all.get(fixture.destination_id)
			if not owner is Dictionary or owner.type!="porter" or fixture.active!=owner.restored: return false
			if not dest is Dictionary or dest.type!="lift" or dest.owner_id!=fixture.owner_id: return false
			if not fixture.get("destination") is Array or fixture_floors[dest.id]!=fixture.destination_floor or fixture.destination!=dest.pos or dest.destination_id!=fixture.id: return false
	if not _cell(s.pos,s.floors[s.floor-1]): return false
	for fixture in s.floors[s.floor-1].fixtures:
		if fixture.pos==s.pos and (fixture.type=="porter" or fixture.type in ["gate","lock","web","cord"] and not fixture.open): return false
	var carried: Dictionary={}
	for id in s.pack+s.belt+[s.equipment.hand,s.equipment.body]:
		if not id is String: return false
		if id=="": continue
		if not id is String or not s.items.has(id) or carried.has(id): return false
		carried[id]=true
	for id in s.items:
		if not id is String: return false
		var item = s.items[id]
		if not item is Dictionary: return false
		for key in ["id","kind","location","floor","pos","slot","spent"]:
			if not item.has(key): return false
		for key in ["id","kind","location","slot"]:
			if not item[key] is String: return false
		if not item.pos is Array or item.id!=id or not Catalog.ITEMS.has(item.kind) or not item.spent is bool or not item.floor is int: return false
		if item.has("owner_id") and not item.owner_id is String: return false
		for key in ["lit","hidden"]:
			if item.has(key) and (not item[key] is bool or s.rules_version!="m3.3"): return false
		if item.kind=="torch" and (s.rules_version!="m3.3" or not item.get("lit") is bool): return false
		var definition: Dictionary=Catalog.ITEMS[item.kind]
		match item.location:
			"floor":
				if item.floor<1 or item.floor>s.floor_count or not _cell(item.pos,s.floors[item.floor-1]) or carried.has(id) or item.slot!="": return false
			"pack":
				if not s.pack.has(id) or definition.slot=="belt" or item.floor!=0 or item.pos!=[] or item.slot!="": return false
			"belt":
				if not s.belt.has(id) or definition.slot!="belt" or item.floor!=0 or item.pos!=[]: return false
			"equip":
				if item.slot not in ["hand","body"] or s.equipment[item.slot]!=id or definition.slot!=item.slot or item.floor!=0 or item.pos!=[]: return false
			"returned":
				var owner = fixtures_all.get(item.get("owner_id"))
				if item.kind!="clapper" or carried.has(id) or item.floor!=0 or item.pos!=[] or item.slot!="": return false
				if not owner is Dictionary or owner.type!="porter" or not owner.restored or owner.item_id!=id: return false
			"consumed":
				if definition.heal<=0 or carried.has(id) or item.floor!=0 or item.pos!=[]: return false
			_: return false
	for id in s.pack:
		if s.items[id].location!="pack": return false
	for id in s.belt:
		if s.items[id].location!="belt": return false
	for slot in ["hand","body"]:
		var id: String=s.equipment[slot]
		if id!="" and (s.items[id].location!="equip" or s.items[id].slot!=slot): return false
	if s.status=="won":
		var seal:=false
		for id in s.belt:
			if s.items[id].kind=="seal": seal=true
		if not seal or s.floor!=1: return false
	return true
