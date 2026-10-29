class_name UndercroftSim
extends RefCounted
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const Cap=preload("res://scripts/sim/capabilities.gd")
const Adventure=preload("res://scripts/sim/adventure.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
const DIRS := [[0,-1],[1,0],[0,1],[-1,0]]
const PACK_SIZE := 8
var _s: Dictionary = {}
var _events: Array = []
var _face_cache: Dictionary={}
func wall_bindings() -> Dictionary:
	if not _face_cache.has(_s.floor): _face_cache[_s.floor]=Faces.all(_floor())
	return _face_cache[_s.floor]

func _init(seed: String = "BELL42", floor_count: int = 2, options: Dictionary={}) -> void:
	var modern: bool=options.get("profile","")=="m5.1"
	var generated: Dictionary = Adventure.generate(seed,options) if modern else Gen.new().generate(seed, floor_count)
	if modern and generated.ok: floor_count=generated.floors.size()
	if not generated.ok:
		_s = {"status": "error", "error": generated.error}
		return
	var profile: String="m5.1" if modern else ("m4.1" if floor_count>=3 else "m3.3")
	_s = {"schema_version": 3 if modern else 2, "rules_version": profile, "generator_version": profile,
		"content_version": profile, "seed": generated.seed, "floor_count": floor_count,
		"floor": 1, "pos": generated.floors[0].start.duplicate(), "facing": 0,
		"turn": 0, "revision": 0, "hp": 6, "max_hp": 6, "status": "playing",
		"pack": [], "equipment": {"hand": "knife_start", "body": ""}, "belt": [],
		"floors": generated.floors, "items": generated.items}
	if modern:
		if options.get("metals",false):
			_s.key_metals=true
			Adventure.metals(_s)
		_s.merge({"act":"abbey","fallen":false,"wakes":0,"deep_count":options.get("deep_floors",1),"deep_blocks":[options.get("columns",2),options.get("rows",2)]})
		if options.get("start","")=="deep": Adventure.enter_deep(self,false)
	_visit()

func snapshot() -> Dictionary: return _s.duplicate(true)
func save_state() -> Dictionary: return snapshot()
func restore_state(raw: Dictionary) -> bool:
	var normalized = Codec.normalize(raw)
	if not normalized is Dictionary or not Codec.validate(normalized): return false
	_s = normalized.duplicate(true)
	_face_cache={}
	return true
func state_hash() -> String: return Codec.canonical(_s).sha256_text()
func floor_data() -> Dictionary: return _s.floors[_s.floor-1].duplicate(true)
func _floor() -> Dictionary: return _s.floors[_s.floor-1]
func front_pos() -> Array:
	var d: Array = DIRS[_s.facing]
	return [_s.pos[0]+d[0], _s.pos[1]+d[1]]
func terrain(cell: Array) -> int:
	var f := _floor()
	if cell[0]<0 or cell[1]<0 or cell[0]>=f.width or cell[1]>=f.height: return 1
	return f.tiles[cell[1]*f.width+cell[0]]
func definition(id: String) -> Dictionary:
	if not _s.items.has(id): return {}
	var result: Dictionary=Catalog.item(_s.items[id].kind)
	if _s.items[id].kind=="torch" and _s.items[id].get("lit",false): result.tags=["FIRE","GLOW"]; result.purpose="BURN webs. No fuel."
	if _s.items[id].get("metal","")!="": result.name=_s.items[id].metal.capitalize()+" key"
	if _s.items[id].get("yours",false): result.provenance="Yours. It fell with you."
	return result
func toss_preview(id: String) -> Dictionary: return Cap.toss_preview(self,id)
func _fixture(id: String) -> Dictionary:
	for fixture in _floor().fixtures:
		if fixture.id == id: return fixture
	return {}
func _actor(id: String) -> Dictionary:
	for actor in _floor().actors:
		if actor.id == id: return actor
	return {}
func _near(cell: Array) -> bool: return cell == _s.pos or cell == front_pos()
func _adjacent(a: Array,b: Array) -> bool: return absi(a[0]-b[0])+absi(a[1]-b[1])==1
func can_walk(cell: Array, ignore_actors: bool = false) -> bool:
	if terrain(cell) != 0: return false
	for fixture in _floor().fixtures:
		if fixture.pos==cell and (fixture.type=="porter" or fixture.type in ["gate","lock"] and not fixture.open or Cap.blocks(fixture)): return false
	if not ignore_actors:
		for actor in _floor().actors:
			if actor.hp>0 and actor.pos==cell: return false
	return true
func contents(cell: Array) -> Dictionary:
	var result := {"pos": cell.duplicate(), "wall": terrain(cell)!=0, "fixtures": [],
		"items": [], "monster": "", "monster_state": ""}
	for fixture in _floor().fixtures:
		if fixture.pos == cell: result.fixtures.append(fixture.duplicate(true))
	for id in _s.items:
		var item: Dictionary = _s.items[id]
		if item.location=="floor" and item.floor==_s.floor and item.pos==cell and not item.get("hidden",false):
			result.items.append(id)
	for actor in _floor().actors:
		if actor.hp>0 and actor.pos==cell:
			result.monster=actor.id
			result.monster_state=actor.state
	return result
func inspect_front() -> Dictionary: return contents(front_pos())
func reachable_items() -> Array:
	var result: Array = []
	for id in _s.items:
		var item: Dictionary = _s.items[id]
		if item.location=="floor" and item.floor==_s.floor and _near(item.pos) and not item.get("hidden",false):
			result.append(id)
	return result
func local_fixtures() -> Array:
	var result: Array=[]
	for fixture in _floor().fixtures:
		if fixture_near(fixture): result.append(fixture.duplicate(true))
	return result
func fixture_near(fixture: Dictionary) -> bool:
	if _near(fixture.pos): return true
	if fixture.type not in ["exit","stairs_up","stairs_down","lift"]: return false
	var face: Dictionary=wall_bindings().get(fixture.id,{})
	if face.is_empty() or face.wall!=front_pos(): return false
	var d: Array=DIRS[_s.facing]
	return face.normal==[-d[0],-d[1]] and _clear_sight(fixture.pos)
func has_seal() -> bool:
	for id in _s.belt:
		if _s.items[id].kind == "seal": return true
	return false
func key_fits(lock: Dictionary,id: String) -> bool:
	if not _s.get("key_metals",false): return lock.key_id==id
	return _s.items.has(id) and _s.items[id].kind=="key" and _s.items[id].get("metal","")==lock.get("metal","missing")
func has_key(lock: Dictionary) -> bool:
	return _s.belt.any(func(id): return key_fits(lock,id))
func fixture_actions() -> Array:
	var result: Array=[]
	if _s.status!="playing": return result
	for fixture in local_fixtures():
		var kind: String=""
		var label: String=""
		match fixture.type:
			"latch":
				if not _fixture(fixture.gate_id).latched: kind="latch"; label="PULL"
			"lock":
				if not fixture.open and has_key(fixture): kind="unlock"; label="UNLOCK"
			"stairs_up","stairs_down":
				var arrival: Dictionary=_stair_arrival(fixture)
				kind="stairs" if _arrival_clear(arrival.floor,arrival.pos) else "squeeze"
				label=("UP" if fixture.type=="stairs_up" else "DOWN") if kind=="stairs" else "SIDLE"
			"panel":
				if Adventure.active(self) and fixture.get("passage",false) and not fixture.open and has_seal(): kind="wake"; label="WAKE"
			"lift":
				if fixture.active and _arrival_clear(fixture.destination_floor,fixture.destination): kind="ride"; label="RIDE"
			"porter":
				var item: Dictionary=_s.items[fixture.item_id]
				if not fixture.restored and item.location in ["pack","equip"]:
					result.append({"label":"RETURN","action":{"type":"return_item","target_id":fixture.id,"item_id":fixture.item_id}})
			"exit":
				if has_seal(): kind="leave"; label="LEAVE"
		if kind!="": result.append({"label":label,"action":{"type":kind,"target_id":fixture.id}})
	return result
func targets(selected: String) -> Array:
	if _s.status!="playing" or not _s.items.has(selected) or _s.items[selected].location not in ["pack","equip","belt"]: return []
	var result: Array=[]
	for fixture in local_fixtures():
		if fixture.type=="porter" and not fixture.restored and fixture.item_id==selected:
			result.append({"target_id":fixture.id,"pos":fixture.pos.duplicate(),"verb":"RETURN","action":{"type":"return_item","item_id":selected,"target_id":fixture.id}})
		elif fixture.type=="lock" and not fixture.open and key_fits(fixture,selected) and _s.belt.has(selected):
			result.append({"target_id":fixture.id,"pos":fixture.pos.duplicate(),"verb":"UNLOCK","action":{"type":"unlock","target_id":fixture.id}})
		elif fixture.type=="exit" and definition(selected).slot=="belt" and _s.items[selected].kind=="seal":
			result.append({"target_id":fixture.id,"pos":fixture.pos.duplicate(),"verb":"LEAVE","action":{"type":"leave","target_id":fixture.id}})
		elif fixture.type=="plate" and fixture.pos==front_pos() and _s.pack.has(selected) and definition(selected).tags.has("HEAVY"):
			result.append({"target_id":fixture.id,"pos":fixture.pos.duplicate(),"verb":"PLACE","action":{"type":"place","item_id":selected,"target_id":fixture.id}})
	for actor_id in ring_targets(selected):
		result.append({"target_id":actor_id,"pos":_actor(actor_id).pos.duplicate(),"verb":"RING","action":{"type":"ring","item_id":selected}})
	result.append_array(Cap.targets(self,selected))
	return result

func capability_targets(selected: String="") -> Array:
	var result: Array=Cap.targets(self,selected)
	# Explicit selection first, then the held tool. Only LIGHT reaches pockets.
	# Inferred tools never offer a throw; TOSS keeps its explicit preview.
	var candidates: Array=[_s.equipment.hand]+_s.pack
	for id in candidates:
		if id=="" or id==selected or not _s.items.has(id): continue
		for entry in Cap.targets(self,id):
			if entry.verb=="TOSS" or (id!=_s.equipment.hand and entry.verb!="LIGHT"): continue
			if not result.any(func(t): return t.target_id==entry.target_id and t.verb==entry.verb): result.append(entry)
	return result
func interaction_targets(selected: String="") -> Array:
	var result: Array=targets(selected)
	for entry in capability_targets(selected):
		if not result.any(func(t): return t.target_id==entry.target_id and t.verb==entry.verb): result.append(entry)
	# Hidden scars have no advertised capability until their dawn reveal.
	return result.filter(func(t): return t.verb!="REVEAL" or Adventure.active(self))

func _arrival_clear(number: int,cell: Array) -> bool:
	if number<1 or number>_s.floor_count or cell[0]<0 or cell[1]<0 or cell[0]>=_s.floors[number-1].width or cell[1]>=_s.floors[number-1].height: return false
	var f: Dictionary=_s.floors[number-1]
	if f.tiles[cell[1]*f.width+cell[0]]!=0: return false
	for actor in f.actors:
		if actor.hp>0 and actor.pos==cell: return false
	for fixture in f.fixtures:
		if fixture.pos==cell and (fixture.type=="porter" or fixture.type in ["gate","lock"] and not fixture.open or Cap.blocks(fixture)): return false
	return true
func _stair_arrival(fixture: Dictionary) -> Dictionary:
	var number: int=_s.floor+(1 if fixture.type=="stairs_down" else -1)
	if number<1 or number>_s.floor_count: return {"floor":_s.floor,"pos":_s.pos.duplicate()}
	return {"floor":number,"pos":(_s.floors[number-1].start if number>_s.floor else _s.floors[number-1].landing).duplicate()}
func _stair_side(arrival: Dictionary) -> Array:
	# Landings are small rooms. Stepping off to a clear side is an explicit
	# alternate action, with no displacement/remote turn of the waiting actor.
	for d in DIRS:
		var cell: Array=[arrival.pos[0]+d[0],arrival.pos[1]+d[1]]
		if _arrival_clear(arrival.floor,cell): return cell
	return []

func porter_state() -> Dictionary:
	for f in _s.floors:
		for fixture in f.fixtures:
			if fixture.type=="porter": return {"present":true,"restored":fixture.restored}
	return {"present":false,"restored":false}

func ring_ready() -> bool: return not _floor().get("bell_rung",false)

func _sight_blocked(cell: Array) -> bool:
	if terrain(cell)!=0: return true
	for fixture in _floor().fixtures:
		if fixture.pos==cell and (fixture.type in ["gate","lock"] and not fixture.open or Cap.blocks(fixture)): return true
	return false

func _clear_sight(cell: Array) -> bool:
	# Integer supercover ray between cell centres, including closed corners.
	var dx: int=cell[0]-_s.pos[0]
	var dy: int=cell[1]-_s.pos[1]
	var ax:=absi(dx); var ay:=absi(dy)
	var sx:=signi(dx); var sy:=signi(dy)
	var at: Array=_s.pos.duplicate()
	var nx:=1; var ny:=1
	for _step in range(_floor().width+_floor().height):
		if at==cell: return true
		var crossing_x: int=nx*ay
		var crossing_y: int=ny*ax
		if crossing_x<crossing_y: at[0]+=sx; nx+=2
		elif crossing_x>crossing_y: at[1]+=sy; ny+=2
		else:
			if _sight_blocked([at[0]+sx,at[1]]) or _sight_blocked([at[0],at[1]+sy]): return false
			at[0]+=sx; at[1]+=sy; nx+=2; ny+=2
		if _sight_blocked(at): return false
	return false

func ring_targets(id: String) -> Array:
	if _s.status!="playing" or _s.rules_version not in ["m3.1","m3.2","m3.3","m4.1","m5.1"] or not _s.items.has(id) or _s.items[id].kind!="clapper" or _s.items[id].location not in ["pack","equip"] or not ring_ready(): return []
	var result: Array=[]
	var direction: Array=DIRS[_s.facing]
	for actor in _floor().actors:
		if actor.hp<=0 or actor.kind!="husk": continue
		var dx: int=actor.pos[0]-_s.pos[0]
		var dy: int=actor.pos[1]-_s.pos[1]
		var depth: int=dx*direction[0]+dy*direction[1]
		var side: int=-dx*direction[1]+dy*direction[0]
		if depth>=1 and depth<=3 and absi(side)<=depth and _clear_sight(actor.pos): result.append(actor.id)
	return result

func legal_verbs(selected: String = "") -> Array:
	if _s.status!="playing": return []
	var front := inspect_front()
	var matches: Array=capability_targets(selected).filter(func(t): return t.verb!="REVEAL" or Adventure.active(self))
	if not matches.is_empty(): return _travel_verb([{"label":matches[0].verb,"action":matches[0].action},{"label":"GUARD","action":{"type":"guard"}},{"label":"HIT","action":{"type":"hit","target_id":front.monster}} if front.monster!="" else {"label":"WAIT","action":{"type":"wait"}}])
	if not ring_targets(selected).is_empty():
		var ringing: Array=[{"label":"RING","action":{"type":"ring","item_id":selected}}, {"label":"GUARD","action":{"type":"guard"}}]
		ringing.append({"label":"HIT","action":{"type":"hit","target_id":front.monster}} if front.monster!="" else {"label":"WAIT","action":{"type":"wait"}})
		return _travel_verb(ringing)
	if not front.monster.is_empty():
		var third: Dictionary={"label":"WAIT","action":{"type":"wait"}}
		for entry in fixture_actions():
			if entry.action.type in ["stairs","squeeze"]: third=entry; break
		return _travel_verb([{"label":"HIT","action":{"type":"hit","target_id":front.monster}},
			{"label":"GUARD","action":{"type":"guard"}},third])
	var result: Array=[]
	var valid := targets(selected)
	if not valid.is_empty(): result.append({"label":valid[0].verb,"action":valid[0].action})
	elif _s.pack.has(selected): result.append({"label":"DROP","action":{"type":"drop","item_id":selected}})
	else:
		var fixtures:=fixture_actions()
		if not fixtures.is_empty(): result.append(fixtures[0])
		if result.is_empty():
			var loot := reachable_items()
			if not loot.is_empty(): result.append({"label":"TAKE","action":{"type":"pickup","item_id":loot[0]}})
	result.append({"label":"GUARD","action":{"type":"guard"}})
	result.append({"label":"WAIT","action":{"type":"wait"}})
	return _travel_verb(result.slice(0,3))
func _travel_verb(entries: Array) -> Array:
	for entry in fixture_actions():
		if entry.action.type not in ["stairs","squeeze","ride","leave"]: continue
		if not entries.any(func(v): return v.action==entry.action):
			entries[entries.size()-1]=entry
		break
	return entries
func _visit() -> void:
	var f := _floor()
	# Reveal only the player's cell and directly visible cardinal rays.
	f.visited[_s.pos[1]*f.width+_s.pos[0]]=true
	for d in DIRS:
		for distance in range(1,4):
			var cell: Array=[_s.pos[0]+d[0]*distance,_s.pos[1]+d[1]*distance]
			if terrain(cell)!=0: break
			f.visited[cell[1]*f.width+cell[0]]=true
			if not can_walk(cell,true): break
func _event(kind: String, phase: String, data: Dictionary={}) -> void:
	var event: Dictionary={"type":kind,"phase":phase,"sequence":_events.size(),
		"turn":_s.turn,"revision":_s.revision,"floor":_s.floor}
	event.merge(data)
	_events.append(event)
func _reject(reason: String) -> Dictionary:
	return {"accepted":false,"reason":reason,"consumed_turn":false,"revision":_s.get("revision",0),"events":[]}
func _heavy_at(floor_index: int, cell: Array) -> bool:
	if _s.floor==floor_index and _s.pos==cell: return true
	for id in _s.items:
		var item: Dictionary=_s.items[id]
		if item.location=="floor" and item.floor==floor_index and item.pos==cell and definition(id).tags.has("HEAVY"): return true
	for actor in _s.floors[floor_index-1].actors:
		if actor.hp>0 and actor.pos==cell: return true
	return false
func _mechanisms() -> void:
	for index in range(_s.floor_count):
		var f: Dictionary=_s.floors[index]
		for plate in f.fixtures:
			if plate.type!="plate": continue
			plate.pressed=_heavy_at(index+1,plate.pos)
			var gate: Dictionary={}
			for candidate in f.fixtures:
				if candidate.id==plate.gate_id: gate=candidate; break
			var held: bool=_heavy_at(index+1,gate.pos)
			var open_now: bool=gate.latched or plate.pressed or held
			if gate.open != open_now:
				gate.open=open_now
				_event("gate_changed","mechanism",{"target_id":gate.id,"open":gate.open,"latched":gate.latched})
func _los(a: Array,b: Array,sight: int) -> bool:
	if a[0]!=b[0] and a[1]!=b[1]: return false
	var distance: int=absi(a[0]-b[0])+absi(a[1]-b[1])
	if distance>sight: return false
	var d: Array=[signi(b[0]-a[0]),signi(b[1]-a[1])]
	for step in range(1,distance):
		if not can_walk([a[0]+d[0]*step,a[1]+d[1]*step],true): return false
	return true
func _enemies(old_states: Dictionary, guarded: bool) -> void:
	for actor in _floor().actors:
		if actor.hp<=0: continue
		var old: String=old_states.get(actor.id,"idle")
		if old=="bell_stunned": continue
		if Cap.hound_phase(self,actor,old,guarded):
			if _s.status=="lost": return
			continue
		if old=="windup":
			var cell: Array=actor.intent.cell.duplicate()
			var damage:=0
			var absorbed:=false
			if cell==_s.pos and not guarded:
				damage=enemy_damage(actor)
				var coat_id: String=_s.equipment.body
				if not coat_id.is_empty() and not _s.items[coat_id].spent:
					damage=0; absorbed=true; _s.items[coat_id].spent=true
				_s.hp=maxi(0,_s.hp-damage)
			_event("attack_resolved","attack",{"actor_id":actor.id,"cell":cell,"damage":damage,
				"blocked":cell==_s.pos and guarded,"armour":absorbed})
			actor.intent={}
			actor.state="recovery"
			if _s.hp<=0: _s.status="lost"; return
			continue
		if old=="recovery": actor.state="idle"
		if actor.kind!="ghost" and _los(actor.pos,_s.pos,int(Catalog.CREATURES[actor.kind].sight)) and not _adjacent(actor.pos,_s.pos):
			var d: Array=[signi(_s.pos[0]-actor.pos[0]),signi(_s.pos[1]-actor.pos[1])]
			var next: Array=[actor.pos[0]+d[0],actor.pos[1]+d[1]]
			if can_walk(next) and next!=_s.pos:
				var before: Array=actor.pos.duplicate()
				actor.pos=next
				_event("monster_moved","prepare",{"actor_id":actor.id,"from":before,"to":next.duplicate()})
		if _adjacent(actor.pos,_s.pos):
			actor.state="windup"
			actor.intent={"cell":_s.pos.duplicate(),"due_in":1}
			_event("intent_announced","prepare",{"actor_id":actor.id,"intent":actor.intent.duplicate(true)})
func enemy_damage(actor: Dictionary) -> int: return int(actor.get("damage",1))
func _resolve_damage(hit: bool,guarded: bool,amount: int=1) -> int:
	if not hit or guarded: return 0
	var coat_id: String=_s.equipment.body
	if coat_id!="" and not _s.items[coat_id].spent:
		_s.items[coat_id].spent=true; return 0
	_s.hp=maxi(0,_s.hp-amount)
	return amount
func weapon_damage() -> int:
	var id: String=_s.equipment.hand
	return int(definition(id).get("damage",1)) if not id.is_empty() else 1
func attack_damage(target_id: String) -> int:
	var actor:=_actor(target_id)
	if actor.is_empty(): return 0
	var profile: Dictionary=Catalog.CREATURES[actor.kind]
	return mini(1,weapon_damage()) if profile.braced and actor.state!="recovery" else weapon_damage()

func apply(action: Dictionary) -> Dictionary:
	if _s.status!="playing": return _reject("Run has ended.")
	for field in ["type","item_id","target_id","slot","step"]:
		if action.has(field) and not action[field] is String: return _reject("Malformed action.")
	if action.has("expected_revision") and not action.expected_revision is int: return _reject("Malformed revision.")
	if action.has("expected_revision") and action.expected_revision!=_s.revision: return _reject("Stale action.")
	# A second forward step meets the architectural face, rather than bumping
	# uselessly against its masonry. Entering the landing itself stays a step;
	# strafes/backsteps never accidentally travel between floors.
	if action.get("type","")=="move" and action.get("step","")=="fwd" and terrain(front_pos())!=0:
		var faces: Dictionary=wall_bindings()
		for travel in local_fixtures():
			if travel.type not in ["exit","stairs_up","stairs_down","lift"] or not faces.has(travel.id): continue
			var face: Dictionary=faces[travel.id]
			var d: Array=DIRS[_s.facing]
			if face.normal!=[-d[0],-d[1]]: continue
			var forward: Dictionary={"type":"ride" if travel.type=="lift" else ("leave" if travel.type=="exit" else "stairs"),"target_id":travel.id}
			return apply(forward)
	var kind: String=action.get("type","")
	var id: String=action.get("item_id","")
	var target: String=action.get("target_id","")
	var fixture:=_fixture(target)
	var actor:=_actor(target)
	var destination: Array=[]
	if kind in Cap.ACTIONS:
		var refusal: String=Cap.validate_action(self,action)
		if refusal!="": return _reject(refusal)
	match kind:
		"light","burn","cut","feed","dispel","reveal","toss","wake": pass
		"turn":
			if action.get("delta",0) not in [-1,1]: return _reject("Bad turn.")
		"move":
			if action.get("step","") not in ["fwd","back","strafe_l","strafe_r"]: return _reject("Bad step.")
			var offset: int={"fwd":0,"back":2,"strafe_l":3,"strafe_r":1}[action.step]
			var d: Array=DIRS[(_s.facing+offset)%4]
			destination=[_s.pos[0]+d[0],_s.pos[1]+d[1]]
			if not can_walk(destination): return _reject("The way is blocked.")
		"pickup":
			if not reachable_items().has(id): return _reject("Nothing to take.")
			if definition(id).slot!="belt" and _s.pack.size()>=PACK_SIZE: return _reject("Your pack is full.")
		"drop":
			if not _s.items.has(id) or _s.items[id].location not in ["pack","equip"]: return _reject("Select a carried item.")
		"place","equip","eat":
			if not _s.pack.has(id): return _reject("Select a pack item.")
			if kind=="place" and (fixture.get("type","")!="plate" or fixture.pos!=front_pos() or not definition(id).tags.has("HEAVY")): return _reject("No place for that.")
			if kind=="equip" and definition(id).slot not in ["hand","body"]: return _reject("Cannot wear that.")
			if kind=="eat" and (definition(id).heal<=0 or _s.hp>=_s.max_hp): return _reject("No healing needed.")
		"unequip":
			var slot: String=action.get("slot","")
			if slot not in ["hand","body"] or _s.equipment[slot].is_empty() or _s.pack.size()>=PACK_SIZE: return _reject("No room in the pack.")
		"latch","unlock","stairs","squeeze","leave":
			if fixture.is_empty() or not fixture_near(fixture): return _reject("Get closer first.")
			if kind=="latch" and (fixture.type!="latch" or _fixture(fixture.gate_id).latched): return _reject("Already latched.")
			if kind=="unlock" and (fixture.type!="lock" or fixture.open or not has_key(fixture)): return _reject("Find the matching key.")
			if kind in ["stairs","squeeze"] and fixture.type not in ["stairs_up","stairs_down"]: return _reject("No stair here.")
			if kind in ["stairs","squeeze"]:
				var number: int=_s.floor+(1 if fixture.type=="stairs_down" else -1)
				if number<1 or number>_s.floor_count: return _reject("No landing there.")
				var arrival: Array=_s.floors[number-1].start if number>_s.floor else _s.floors[number-1].landing
				if kind=="stairs" and not _arrival_clear(number,arrival): return _reject("The landing is blocked.")
				if kind=="squeeze":
					if _arrival_clear(number,arrival): return _reject("The landing is clear.")
					destination=_stair_side({"floor":number,"pos":arrival})
					if destination.is_empty(): return _reject("No room beside it.")
			if kind=="leave" and (fixture.type!="exit" or not has_seal()): return _reject("Find the Dawn Seal.")
		"return_item":
			if fixture.get("type","")!="porter" or not _near(fixture.pos) or fixture.restored or fixture.item_id!=id: return _reject("That is not its owner.")
			if not _s.items.has(id) or _s.items[id].location not in ["pack","equip"]: return _reject("Bring its clapper.")
		"ride":
			if fixture.get("type","")!="lift" or not fixture_near(fixture) or not fixture.active: return _reject("The lift is dead.")
			if not fixture.get("final",false) and not _arrival_clear(fixture.destination_floor,fixture.destination): return _reject("The landing is blocked.")
		"ring":
			if ring_targets(id).is_empty(): return _reject("No Husk in sight." if ring_ready() else "The bell rests here.")
		"hit":
			if actor.is_empty() or actor.hp<=0 or actor.pos!=front_pos(): return _reject("Nothing to hit.")
		"guard","wait": pass
		_: return _reject("Unknown action.")
	_events=[]
	_s.revision+=1
	var consumed:=kind!="turn"
	if consumed: _s.turn+=1
	var old_states: Dictionary={}
	for enemy in _floor().actors: old_states[enemy.id]=enemy.state
	var transition:=false
	match kind:
		"light","burn","cut","feed","dispel","reveal","toss","wake": Cap.commit(self,action,old_states)
		"turn":
			_s.facing=posmod(_s.facing+action.delta,4)
			_event("facing_changed","player",{"to":_s.facing})
		"move":
			var before: Array=_s.pos.duplicate()
			_s.pos=destination
			_event("moved","player",{"from":before,"to":destination.duplicate()})
		"pickup":
			var item: Dictionary=_s.items[id]
			item.location="belt" if definition(id).slot=="belt" else "pack"
			item.pos=[]; item.floor=0
			if item.location=="belt": _s.belt.append(id)
			else: _s.pack.append(id)
			_event("item_moved","player",{"item_id":id,"to":item.location})
		"drop","place":
			var item: Dictionary=_s.items[id]
			if item.location=="equip": _s.equipment[item.slot]=""
			_s.pack.erase(id); item.location="floor"; item.floor=_s.floor; item.slot=""
			item.pos=fixture.pos.duplicate() if kind=="place" else _s.pos.duplicate()
			_event("item_moved","player",{"item_id":id,"to":"floor","pos":item.pos.duplicate()})
		"equip":
			var slot: String=definition(id).slot
			var old: String=_s.equipment[slot]
			_s.pack.erase(id)
			if not old.is_empty():
				_s.items[old].location="pack"; _s.items[old].slot=""; _s.pack.append(old)
			_s.items[id].location="equip"; _s.items[id].slot=slot; _s.equipment[slot]=id
			_event("equipped","player",{"item_id":id,"slot":slot})
		"unequip":
			var slot: String=action.slot
			var old: String=_s.equipment[slot]
			_s.items[old].location="pack"; _s.items[old].slot=""; _s.pack.append(old); _s.equipment[slot]=""
			_event("equipped","player",{"item_id":old,"slot":""})
		"eat":
			_s.pack.erase(id); _s.items[id].location="consumed"
			_s.hp=mini(_s.max_hp,_s.hp+int(definition(id).heal))
			_event("healed","player",{"item_id":id,"hp":_s.hp})
		"latch":
			var gate:=_fixture(fixture.gate_id)
			gate.latched=true
			_event("latched","mechanism",{"target_id":gate.id})
		"unlock":
			fixture.open=true
			_event("unlocked","mechanism",{"target_id":fixture.id})
		"return_item":
			var item: Dictionary=_s.items[id]
			_s.pack.erase(id)
			if item.location=="equip": _s.equipment[item.slot]=""
			item.location="returned"; item.slot=""; item.pos=[]; item.floor=0; item.owner_id=fixture.id
			fixture.restored=true
			for f in _s.floors:
				for landing in f.fixtures:
					if landing.type=="lift" and landing.owner_id==fixture.id: landing.active=true
			_event("restored","mechanism",{"owner_id":fixture.id,"item_id":id})
		"ride":
			transition=true
			if Adventure.active(self) and fixture.get("final",false):
				_s.status="won"
			else:
				var old_floor: int=_s.floor
				_s.floor=fixture.destination_floor; _s.pos=fixture.destination.duplicate(); _s.facing=0
				_event("lift_ride","transition",{"from":old_floor,"to":_s.floor,"target_id":fixture.destination_id})
		"ring":
			var listeners: Array=ring_targets(id)
			if _s.rules_version not in ["m3.3","m4.1","m5.1"]: _s.rules_version="m3.2"; _s.content_version="m3.2"
			_floor().bell_rung=true
			for listener in listeners:
				var husk:=_actor(listener)
				husk.state="recovery"; husk.intent={}; old_states[listener]="bell_stunned"
			_event("bell_rung","player",{"item_id":id,"actor_ids":listeners})
		"hit":
			var damage:=attack_damage(actor.id)
			actor.hp=maxi(0,actor.hp-damage)
			_event("struck","player",{"target_id":actor.id,"damage":damage,"hp":actor.hp})
			if actor.hp==0:
				actor.state="dead"; actor.intent={}
				_event("monster_defeated","player",{"actor_id":actor.id})
		"guard","wait": _event("guarded" if kind=="guard" else "waited","player")
		"stairs","squeeze":
			transition=true
			var old_floor: int=_s.floor
			_s.floor+=1 if fixture.type=="stairs_down" else -1
			_s.pos=destination.duplicate() if kind=="squeeze" else (_floor().start if _s.floor>old_floor else _floor().landing).duplicate()
			_s.facing=0 if _s.floor>old_floor else 2
			_event("floor_changed","transition",{"from":old_floor,"to":_s.floor})
			if kind=="squeeze": _event("landing_skirted","transition",{"target_id":fixture.id})
		"leave": _s.status="won"
	if Adventure.active(self):
		if kind=="pickup" and _s.items[id].kind=="seal" and _s.floor==3:
			Adventure.enter_deep(self,true); transition=true
		_s.act="abbey" if _s.floor<=3 else ("winding" if _s.floor==_s.floor_count else "deep")
	_mechanisms()
	if consumed and not transition and _s.status=="playing":
		_enemies(old_states,kind=="guard")
		_mechanisms()
	if Adventure.active(self) and _s.hp==0:
		Adventure.wake(self); _mechanisms()
	Cap.glow_reveals(self)
	_visit()
	if _s.status!="playing": _event("run_ended","transition",{"status":_s.status})
	return {"accepted":true,"reason":"","consumed_turn":consumed,"revision":_s.revision,"events":_events.duplicate(true)}

func view_snapshot() -> Dictionary:
	var f:=floor_data()
	f.merge({"pos":_s.pos.duplicate(),"facing":_s.facing,"floor":_s.floor,"seed":_s.seed,
		"hp":_s.hp,"max_hp":_s.max_hp,"status":_s.status,"objects":[],
		"key_metals":_s.get("key_metals",false),"deep_materials":Adventure.active(self) and _s.get("act","")=="deep",
		"seal_site":f.landing.duplicate() if _s.floor==(3 if Adventure.active(self) else _s.floor_count) else [],"seal_glow":has_seal()})
	for id in _s.items:
		var item: Dictionary=_s.items[id]
		if item.location=="floor" and item.floor==_s.floor and not item.get("hidden",false):
			f.objects.append({"id":id,"kind":item.kind,"pos":item.pos.duplicate(),"lit":item.get("lit",false),"spent":item.spent,"metal":item.get("metal","")})
	return f
