class_name UndercroftWitness
extends RefCounted
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
var sim
var actions: Array=[]
var error: String=""
var pressure: Array=[]
var use_bell:=false

static func build(seed: String, count: int=2, explore: bool=false,porter_policy: String="skip") -> Dictionary:
	var bot=UndercroftWitness.new()
	return bot.run(seed,count,explore,porter_policy)

func _raw(action: Dictionary) -> bool:
	var result: Dictionary=sim.apply(action)
	if not result.accepted:
		error=result.reason+" "+JSON.stringify(action)
		return false
	actions.append(action.duplicate(true))
	if sim.snapshot().hp!=6:
		error="Witness took damage"
		return false
	return true

func _commit(action: Dictionary) -> bool:
	var state: Dictionary=sim.snapshot()
	for actor in state.floors[state.floor-1].actors:
		if actor.hp>0 and actor.state=="windup" and actor.intent.cell==state.pos and action.type not in ["turn","guard"]:
			var dodges: bool=action.type=="move"
			var lethal: bool=action.type=="hit" and action.get("target_id","")==actor.id and sim.attack_damage(actor.id)>=actor.hp
			if not dodges and not lethal:
				var listeners: Array=sim.ring_targets("bell_clapper") if use_bell else []
				var threats: Array=state.floors[state.floor-1].actors.filter(func(a): return a.hp>0 and a.state=="windup" and a.intent.cell==state.pos)
				var safe_bell: bool=not listeners.is_empty() and threats.all(func(a): return listeners.has(a.id))
				if not _raw({"type":"ring","item_id":"bell_clapper"} if safe_bell else {"type":"guard"}): return false
	return _raw(action)

func _face(direction: int) -> bool:
	while sim.snapshot().facing!=direction:
		var delta: int=posmod(direction-sim.snapshot().facing,4)
		if not _commit({"type":"turn","delta":-1 if delta==3 else 1}): return false
	return true

func _path(goal: Array, adjacent: bool) -> Array:
	var start: Array=sim.snapshot().pos
	var f: Dictionary=sim.floor_data()
	var todo: Array=[start]
	var previous: Dictionary={Vector2i(start[0],start[1]):Vector2i(-1,-1)}
	var found:=Vector2i(-1,-1)
	var cursor:=0
	while cursor<todo.size():
		var cell: Array=todo[cursor]; cursor+=1
		var distance: int=absi(cell[0]-goal[0])+absi(cell[1]-goal[1])
		if distance==0 or adjacent and distance==1:
			found=Vector2i(cell[0],cell[1]); break
		for d in Sim.DIRS:
			var next: Array=[cell[0]+d[0],cell[1]+d[1]]
			var key:=Vector2i(next[0],next[1])
			if not previous.has(key) and sim.can_walk(next,true):
				previous[key]=Vector2i(cell[0],cell[1]); todo.append(next)
	if found.x<0: return []
	var reversed: Array=[]
	var key:=found
	while previous[key]!=Vector2i(-1,-1):
		reversed.push_front([key.x,key.y]); key=previous[key]
	return reversed

func go(goal: Array, adjacent: bool=true) -> bool:
	for _step in range(400):
		var state: Dictionary=sim.snapshot()
		var distance: int=absi(state.pos[0]-goal[0])+absi(state.pos[1]-goal[1])
		if distance==0 or adjacent and distance==1:
			if distance==1: return _face(Sim.DIRS.find([goal[0]-state.pos[0],goal[1]-state.pos[1]]))
			return true
		var path:=_path(goal,adjacent)
		if path.is_empty(): error="No route to "+str(goal); return false
		var next: Array=path[0]
		if not _face(Sim.DIRS.find([next[0]-state.pos[0],next[1]-state.pos[1]])): return false
		var front: Dictionary=sim.inspect_front()
		if not front.monster.is_empty():
			if not _commit({"type":"hit","target_id":front.monster}): return false
		elif not _commit({"type":"move","step":"fwd"}): return false
	error="Route budget exhausted"; return false

func _fixture(kind: String) -> Dictionary:
	for fixture in sim.floor_data().fixtures:
		if fixture.type==kind: return fixture
	return {}

func _pickup(id: String) -> bool:
	var state: Dictionary=sim.snapshot()
	if state.items[id].location!="floor": return true
	if not go(state.items[id].pos): return false
	return _commit({"type":"pickup","item_id":id})

func _space() -> bool:
	var state: Dictionary=sim.snapshot()
	if state.pack.size()<8: return true
	for id in state.pack:
		if not sim.definition(id).tags.has("HEAVY"): return _commit({"type":"drop","item_id":id})
	return _commit({"type":"drop","item_id":state.pack[0]})

func _explore() -> bool:
	var state: Dictionary=sim.snapshot()
	var ids: Array=[]
	for id in state.items:
		if (id.begins_with("f%d_"%state.floor) or id=="bell_clapper" and state.floor==1) and state.items[id].location=="floor" and sim.definition(id).slot!="belt":
			ids.append(id)
	for id in ids:
		state=sim.snapshot()
		if state.pack.size()>=8: continue
		if not _pickup(id): return false
		var definition: Dictionary=sim.definition(id)
		if definition.slot=="body" and state.equipment.body=="":
			if not _commit({"type":"equip","item_id":id}): return false
		elif definition.slot=="hand" and definition.damage>sim.weapon_damage():
			if not _commit({"type":"equip","item_id":id}): return false
	return true

func run(seed: String,count: int,explore: bool,porter_policy: String="skip",initial_state: Dictionary={}) -> Dictionary:
	use_bell=porter_policy=="ring"
	sim=Sim.new(seed,count)
	if not initial_state.is_empty() and not sim.restore_state(initial_state): return {"ok":false,"reason":"Invalid initial state"}
	if sim.snapshot().status=="error": return {"ok":false,"reason":"Bad seed","actions":[]}
	var original: Dictionary=sim.snapshot().items
	for number in range(1,count+1):
		var state: Dictionary=sim.snapshot()
		var ids: Array=[]
		var kinds: Array=[]
		for id in original:
			if original[id].floor==number and sim.definition(id).slot!="belt": ids.append(id); kinds.append(original[id].kind)
		var report: Dictionary={"floor":number,"offered":ids.size(),"offered_kinds":kinds,"free_on_entry":8-state.pack.size()}
		pressure.append(report)
		var plate:=_fixture("plate")
		if not plate.is_empty():
			var stone: String="f%d_stone"%number
			if not _space() or not _pickup(stone): return _finish(false)
			if not go(plate.pos,false) or not _commit({"type":"drop","item_id":stone}): return _finish(false)
			var latch:=_fixture("latch")
			if not go(latch.pos) or not _commit({"type":"latch","target_id":latch.id}): return _finish(false)
		var lock:=_fixture("lock")
		if not lock.is_empty():
			if not _pickup(lock.key_id): return _finish(false)
		if number==1 and porter_policy!="skip":
			if not _space() or not _pickup("bell_clapper"): return _finish(false)
		if not lock.is_empty():
			if not go(lock.pos) or not _commit({"type":"unlock","target_id":lock.id}): return _finish(false)
		if number==1 and porter_policy!="skip":
			if porter_policy=="return":
				var porter:=_fixture("porter")
				if not go(porter.pos) or not _commit({"type":"return_item","target_id":porter.id,"item_id":"bell_clapper"}): return _finish(false)
			elif porter_policy in ["keep","ring"]:
				if not _commit({"type":"equip","item_id":"bell_clapper"}): return _finish(false)
		if explore and not _explore(): return _finish(false)
		state=sim.snapshot()
		report.free_on_exit=8-state.pack.size()
		report.left_on_floor=0
		for id in ids:
			if state.items[id].location=="floor": report.left_on_floor+=1
		if number<count:
			var down:=_fixture("stairs_down")
			if not go(down.pos) or not _commit({"type":"stairs","target_id":down.id}): return _finish(false)
		elif not _pickup("f%d_seal"%number): return _finish(false)
	for number in range(count,0,-1):
		if sim.snapshot().floor!=number: continue
		var lift:=_fixture("lift")
		if count==1:
			for landing in sim.floor_data().fixtures:
				if landing.id=="lift_deep": lift=landing
		if porter_policy=="return" and not lift.is_empty() and lift.active and (number>1 or count==1):
			if not go(lift.pos) or not _commit({"type":"ride","target_id":lift.id}): return _finish(false)
			if count>1: continue
		var up:=_fixture("exit" if number==1 else "stairs_up")
		if not go(up.pos): return _finish(false)
		if not _commit({"type":"leave" if number==1 else "stairs","target_id":up.id}): return _finish(false)
	if sim.snapshot().status=="playing" and sim.snapshot().floor==1:
		var exit:=_fixture("exit")
		if not go(exit.pos) or not _commit({"type":"leave","target_id":exit.id}): return _finish(false)
	return _finish(sim.snapshot().status=="won")

func _finish(ok: bool) -> Dictionary:
	return {"ok":ok,"reason":error,"actions":actions,"snapshot":sim.snapshot(),"pressure":pressure}
