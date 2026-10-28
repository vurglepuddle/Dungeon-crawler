class_name UndercroftSim
extends RefCounted
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
const DIRS := [[0,-1],[1,0],[0,1],[-1,0]]
const PACK_SIZE := 8
var _s: Dictionary = {}
var _events: Array = []

func _init(seed: String = "BELL42", floor_count: int = 2) -> void:
	var generated: Dictionary = Gen.new().generate(seed, floor_count)
	if not generated.ok:
		_s = {"status": "error", "error": generated.error}
		return
	_s = {"schema_version": 2, "rules_version": "m2.1", "generator_version": "m2.1",
		"content_version": "m2.1", "seed": generated.seed, "floor_count": floor_count,
		"floor": 1, "pos": generated.floors[0].start.duplicate(), "facing": 0,
		"turn": 0, "revision": 0, "hp": 6, "max_hp": 6, "status": "playing",
		"pack": [], "equipment": {"hand": "knife_start", "body": ""}, "belt": [],
		"floors": generated.floors, "items": generated.items}
	_visit()

func snapshot() -> Dictionary: return _s.duplicate(true)
func save_state() -> Dictionary: return snapshot()
func restore_state(raw: Dictionary) -> bool:
	var normalized = Codec.normalize(raw)
	if not normalized is Dictionary or not Codec.validate(normalized): return false
	_s = normalized.duplicate(true)
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
	return Catalog.item(_s.items[id].kind) if _s.items.has(id) else {}
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
		if fixture.pos == cell and fixture.type in ["gate","lock"] and not fixture.open: return false
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
		if item.location=="floor" and item.floor==_s.floor and item.pos==cell:
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
		if item.location=="floor" and item.floor==_s.floor and _near(item.pos):
			result.append(id)
	return result
func local_fixtures() -> Array:
	var result: Array=[]
	for fixture in _floor().fixtures:
		if _near(fixture.pos): result.append(fixture.duplicate(true))
	return result
func has_seal() -> bool:
	for id in _s.belt:
		if _s.items[id].kind == "seal": return true
	return false
func fixture_actions() -> Array:
	var result: Array=[]
	if _s.status!="playing": return result
	for fixture in local_fixtures():
		var kind: String=""
		var label: String=""
		match fixture.type:
			"latch":
				if not _fixture(fixture.gate_id).latched: kind="latch"; label="LATCH"
			"lock":
				if not fixture.open and _s.belt.has(fixture.key_id): kind="unlock"; label="UNLOCK"
			"stairs_up","stairs_down": kind="stairs"; label="UP" if fixture.type=="stairs_up" else "DOWN"
			"exit":
				if has_seal(): kind="leave"; label="LEAVE"
		if kind!="": result.append({"label":label,"action":{"type":kind,"target_id":fixture.id}})
	return result
func targets(selected: String) -> Array:
	if _s.status!="playing" or not _s.pack.has(selected): return []
	if not definition(selected).tags.has("HEAVY"): return []
	var result: Array=[]
	for fixture in _floor().fixtures:
		if fixture.type=="plate" and fixture.pos==front_pos():
			result.append({"target_id": fixture.id, "pos": fixture.pos.duplicate(),
				"verb": "PLACE", "action": {"type":"place","item_id":selected,"target_id":fixture.id}})
	return result
func legal_verbs(selected: String = "") -> Array:
	if _s.status!="playing": return []
	var front := inspect_front()
	if not front.monster.is_empty():
		return [{"label":"HIT","action":{"type":"hit","target_id":front.monster}},
			{"label":"GUARD","action":{"type":"guard"}},{"label":"WAIT","action":{"type":"wait"}}]
	var result: Array=[]
	var valid := targets(selected)
	if not valid.is_empty(): result.append({"label":"PLACE","action":valid[0].action})
	elif _s.pack.has(selected): result.append({"label":"DROP","action":{"type":"drop","item_id":selected}})
	else:
		var fixtures:=fixture_actions()
		if not fixtures.is_empty(): result.append(fixtures[0])
		if result.is_empty():
			var loot := reachable_items()
			if not loot.is_empty(): result.append({"label":"TAKE","action":{"type":"pickup","item_id":loot[0]}})
	result.append({"label":"GUARD","action":{"type":"guard"}})
	result.append({"label":"WAIT","action":{"type":"wait"}})
	return result.slice(0,3)
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
		if old=="windup":
			var cell: Array=actor.intent.cell.duplicate()
			var damage:=0
			var absorbed:=false
			if cell==_s.pos and not guarded:
				damage=1
				var coat_id: String=_s.equipment.body
				if not coat_id.is_empty() and not _s.items[coat_id].spent:
					damage=0; absorbed=true; _s.items[coat_id].spent=true
				_s.hp-=damage
			_event("attack_resolved","attack",{"actor_id":actor.id,"cell":cell,"damage":damage,
				"blocked":cell==_s.pos and guarded,"armour":absorbed})
			actor.intent={}
			actor.state="recovery"
			if _s.hp<=0: _s.status="lost"; return
			continue
		if old=="recovery": actor.state="idle"
		if _los(actor.pos,_s.pos,int(Catalog.CREATURES[actor.kind].sight)) and not _adjacent(actor.pos,_s.pos):
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
	if action.has("expected_revision") and action.expected_revision!=_s.revision: return _reject("Stale action.")
	var kind: String=action.get("type","")
	var id: String=action.get("item_id","")
	var target: String=action.get("target_id","")
	var fixture:=_fixture(target)
	var actor:=_actor(target)
	var destination: Array=[]
	match kind:
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
		"drop","place","equip","eat":
			if not _s.pack.has(id): return _reject("Select a pack item.")
			if kind=="place" and (fixture.get("type","")!="plate" or fixture.pos!=front_pos() or not definition(id).tags.has("HEAVY")): return _reject("No place for that.")
			if kind=="equip" and definition(id).slot not in ["hand","body"]: return _reject("Cannot wear that.")
			if kind=="eat" and (definition(id).heal<=0 or _s.hp>=_s.max_hp): return _reject("No healing needed.")
		"unequip":
			var slot: String=action.get("slot","")
			if slot not in ["hand","body"] or _s.equipment[slot].is_empty() or _s.pack.size()>=PACK_SIZE: return _reject("No room in the pack.")
		"latch","unlock","stairs","leave":
			if fixture.is_empty() or not _near(fixture.pos): return _reject("Get closer first.")
			if kind=="latch" and (fixture.type!="latch" or _fixture(fixture.gate_id).latched): return _reject("Already latched.")
			if kind=="unlock" and (fixture.type!="lock" or fixture.open or not _s.belt.has(fixture.key_id)): return _reject("Find the matching key.")
			if kind=="stairs" and fixture.type not in ["stairs_up","stairs_down"]: return _reject("No stair here.")
			if kind=="leave" and (fixture.type!="exit" or not has_seal()): return _reject("Find the Dawn Seal.")
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
		"hit":
			var damage:=attack_damage(actor.id)
			actor.hp=maxi(0,actor.hp-damage)
			_event("struck","player",{"target_id":actor.id,"damage":damage,"hp":actor.hp})
			if actor.hp==0:
				actor.state="dead"; actor.intent={}
				_event("monster_defeated","player",{"actor_id":actor.id})
		"guard","wait": _event("guarded" if kind=="guard" else "waited","player")
		"stairs":
			transition=true
			var old_floor: int=_s.floor
			_s.floor+=1 if fixture.type=="stairs_down" else -1
			_s.pos=(_floor().start if _s.floor>old_floor else _floor().landing).duplicate()
			_s.facing=0 if _s.floor>old_floor else 2
			_event("floor_changed","transition",{"from":old_floor,"to":_s.floor})
		"leave": _s.status="won"
	_mechanisms()
	if consumed and not transition and _s.status=="playing":
		_enemies(old_states,kind=="guard")
		_mechanisms()
	_visit()
	if _s.status!="playing": _event("run_ended","transition",{"status":_s.status})
	return {"accepted":true,"reason":"","consumed_turn":consumed,"revision":_s.revision,"events":_events.duplicate(true)}

func view_snapshot() -> Dictionary:
	var f:=floor_data()
	f.merge({"pos":_s.pos.duplicate(),"facing":_s.facing,"floor":_s.floor,
		"hp":_s.hp,"max_hp":_s.max_hp,"status":_s.status,"objects":[]})
	for id in _s.items:
		var item: Dictionary=_s.items[id]
		if item.location=="floor" and item.floor==_s.floor:
			f.objects.append({"id":id,"kind":item.kind,"pos":item.pos.duplicate()})
	return f
