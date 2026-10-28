class_name UndercroftWitness
extends RefCounted
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
var sim
var actions: Array=[]
var error: String=""
var pressure: Array=[]
var use_bell:=false

static func build(seed: String, count: int=2, explore: bool=false,porter_policy: String="skip",tour: bool=false) -> Dictionary:
	var bot=UndercroftWitness.new()
	return bot.run(seed,count,explore,porter_policy,{},tour)

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
	if action.type=="stairs":
		for entry in sim.fixture_actions():
			if entry.action.type=="squeeze" and entry.action.target_id==action.target_id: action=entry.action.duplicate(); break
	var state: Dictionary=sim.snapshot()
	var landing: Array=state.pos
	if action.type=="move":
		var offset: int={"fwd":0,"back":2,"strafe_l":3,"strafe_r":1}[action.step]
		var d: Array=Sim.DIRS[(state.facing+offset)%4]
		landing=[state.pos[0]+d[0],state.pos[1]+d[1]]
	for actor in state.floors[state.floor-1].actors:
		var lane: Array=actor.intent.get("lane",[actor.intent.get("cell",[])])
		if actor.hp>0 and actor.state=="windup" and (lane.has(state.pos) or lane.has(landing)) and action.type not in ["turn","guard"]:
			var dodges: bool=action.type=="move" and not lane.has(landing)
			var lethal: bool=action.type=="hit" and action.get("target_id","")==actor.id and sim.attack_damage(actor.id)>=actor.hp
			var pacifies: bool=action.type in ["feed","dispel"] and action.get("target_id","")==actor.id
			if action.type=="toss" and sim.toss_preview(action.get("item_id","")).actor_id==actor.id and sim.definition(action.item_id).tags.has("FOOD") and actor.kind=="hound": pacifies=true
			if not dodges and not lethal and not pacifies:
				var listeners: Array=sim.ring_targets("bell_clapper") if use_bell else []
				var threats: Array=state.floors[state.floor-1].actors.filter(func(a): return a.hp>0 and a.state=="windup" and a.intent.cell==state.pos)
				var safe_bell: bool=not listeners.is_empty() and threats.all(func(a): return listeners.has(a.id))
				if not _raw({"type":"ring","item_id":"bell_clapper"} if safe_bell else {"type":"guard"}): return false
	if action.type=="move" and not sim.can_walk(landing): return true # A guarded lunge may now occupy it; go() replans.
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
			if f.actors.any(func(a): return a.hp>0 and a.state=="peaceful" and a.pos==next): continue
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

func _space(keep: Array=[]) -> bool:
	var state: Dictionary=sim.snapshot()
	if state.pack.size()<8: return true
	for id in state.pack:
		if not keep.has(id) and not sim.definition(id).tags.has("HEAVY"): return _commit({"type":"drop","item_id":id})
	for id in state.pack:
		if not keep.has(id): return _commit({"type":"drop","item_id":id})
	return false

func _explore() -> bool:
	var state: Dictionary=sim.snapshot()
	var ids: Array=[]
	for id in state.items:
		if (id.begins_with("f%d_"%state.floor) or id=="bell_clapper" and state.floor==1) and state.items[id].location=="floor" and not state.items[id].get("hidden",false) and sim.definition(id).slot!="belt":
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

func _acquire_tag(tag: String) -> String:
	var state: Dictionary=sim.snapshot()
	for id in state.pack+state.belt+[state.equipment.hand]:
		if id!="" and sim.definition(id).tags.has(tag): return id
	var candidates: Array=state.items.keys()
	if state.rules_version=="m4.1":
		candidates.sort_custom(func(a,b):
			var ia: Dictionary=state.items[a]; var ib: Dictionary=state.items[b]
			var da: int=absi(ia.pos[0]-state.pos[0])+absi(ia.pos[1]-state.pos[1]) if ia.pos.size()==2 else 1000
			var db: int=absi(ib.pos[0]-state.pos[0])+absi(ib.pos[1]-state.pos[1]) if ib.pos.size()==2 else 1000
			return da<db)
	for id in candidates:
		var item: Dictionary=state.items[id]
		if item.location!="floor" or item.floor!=state.floor or item.get("hidden",false) or not sim.definition(id).tags.has(tag): continue
		if _path(item.pos,true).is_empty() and absi(item.pos[0]-state.pos[0])+absi(item.pos[1]-state.pos[1])>1: continue
		if _space() and _pickup(id): return id
	return ""

func capability_rooms() -> bool:
	if not sim.Cap.enabled(sim): return true
	var food: String=""
	if sim.floor_data().actors.any(func(a): return a.kind=="hound" and a.hp>0 and a.state!="peaceful"): food=_acquire_tag("FOOD")
	var web:=_fixture("web")
	if not web.is_empty() and not web.open:
		var torch: String=""
		var s: Dictionary=sim.snapshot()
		for id in s.pack+[s.equipment.hand]:
			if id!="" and s.items[id].kind=="torch": torch=id; break
		if torch=="":
			for id in s.items:
				if s.items[id].kind=="torch" and s.items[id].location=="floor" and s.items[id].floor==s.floor: torch=id; break
		if torch=="" or not _space([food,torch]) or not _pickup(torch): return false
		if not sim.snapshot().items[torch].lit:
			var brazier:=_fixture("brazier")
			if not go(brazier.pos) or not _commit({"type":"light","item_id":torch,"target_id":brazier.id}): return false
		if not go(web.pos) or not _commit({"type":"burn","item_id":torch,"target_id":web.id}): return false
	for actor in sim.floor_data().actors:
		if actor.kind!="hound" or actor.hp<=0 or actor.state=="peaceful": continue
		if sim.snapshot().rules_version=="m4.1":
			if not _settle_hound(actor.id,food): return false
		elif food!="":
			if not sim.Cap.in_reach(sim,sim._actor(actor.id)) and not go(sim._actor(actor.id).pos): return false
			if sim._actor(actor.id).hp>0:
				var cell: Array=sim._actor(actor.id).pos
				var s: Dictionary=sim.snapshot()
				if not _face(Sim.DIRS.find([signi(cell[0]-s.pos[0]),signi(cell[1]-s.pos[1])])): return false
				if not _commit({"type":"feed","item_id":food,"target_id":actor.id} if sim._near(cell) else {"type":"toss","item_id":food}): return false
		else:
			while sim._actor(actor.id).hp>0:
				if not go(sim._actor(actor.id).pos) or not _commit({"type":"hit","target_id":actor.id}): return false
	var cord:=_fixture("cord")
	if not cord.is_empty() and not cord.open:
		var edge:=_acquire_tag("EDGE")
		if edge=="" or not go(cord.pos) or not _commit({"type":"cut","item_id":edge,"target_id":cord.id}): return false
	for actor in sim.floor_data().actors:
		if actor.kind!="ghost" or actor.hp<=0: continue
		var glow:=_acquire_tag("GLOW")
		if glow=="" or not go(actor.pos) or not _commit({"type":"dispel","item_id":glow,"target_id":actor.id}): return false
	return true

func _settle_hound(id: String,food: String) -> bool:
	# Re-plan after every committed step: an open-loop Hound can move away
	# from a stale goal. Never try to face a diagonal/non-cardinal vector.
	for _step in range(100):
		var actor: Dictionary=sim._actor(id); var s: Dictionary=sim.snapshot()
		if actor.hp<=0 or actor.state=="peaceful": return true
		var dx: int=actor.pos[0]-s.pos[0]; var dy: int=actor.pos[1]-s.pos[1]
		if (dx==0 or dy==0) and absi(dx)+absi(dy)<=2:
			if not _face(Sim.DIRS.find([signi(dx),signi(dy)])): return false
			if food!="" and sim.Cap.in_reach(sim,actor):
				if sim._near(actor.pos): return _commit({"type":"feed","item_id":food,"target_id":id})
				if sim.toss_preview(food).actor_id==id: return _commit({"type":"toss","item_id":food})
			if food=="" and sim._near(actor.pos):
				if not _commit({"type":"hit","target_id":id}): return false
				continue
		var path: Array=_path(actor.pos,true)
		if path.is_empty(): error="No route beside Hound"; return false
		if not _face(Sim.DIRS.find([path[0][0]-s.pos[0],path[0][1]-s.pos[1]])): return false
		var front: Dictionary=sim.inspect_front()
		if front.monster!="" and front.monster!=id:
			if not _commit({"type":"hit","target_id":front.monster}): return false
		elif not _commit({"type":"move","step":"fwd"}): return false
	error="Hound approach budget"; return false

func find_secret() -> bool:
	var panel:=_fixture("panel")
	if panel.is_empty() or panel.open: return true
	if not go(panel.pos): return false
	var edge:=_acquire_tag("EDGE")
	if edge=="" or not _commit({"type":"cut","item_id":edge,"target_id":panel.id}): return false
	return _space() and _pickup(panel.item_id)

func run(seed: String,count: int,explore: bool,porter_policy: String="skip",initial_state: Dictionary={},tour: bool=false) -> Dictionary:
	use_bell=porter_policy=="ring"
	sim=Sim.new(seed,count)
	if not initial_state.is_empty() and not sim.restore_state(initial_state): return {"ok":false,"reason":"Invalid initial state"}
	if sim.snapshot().status=="error": return {"ok":false,"reason":"Bad seed","actions":[]}
	var original: Dictionary=sim.snapshot().items
	for number in range(sim.snapshot().floor,count+1):
		var state: Dictionary=sim.snapshot()
		var ids: Array=[]
		var kinds: Array=[]
		var concealed: int=0
		for id in original:
			if original[id].floor==number and sim.definition(id).slot!="belt":
				if original[id].get("hidden",false): concealed+=1
				else: ids.append(id); kinds.append(original[id].kind)
		var report: Dictionary={"floor":number,"offered":ids.size(),"concealed":concealed,"offered_kinds":kinds,"free_on_entry":8-state.pack.size()}
		pressure.append(report)
		var plate:=_fixture("plate")
		if not plate.is_empty() and not _fixture("gate").latched:
			var stone: String="f%d_stone"%number
			if not _space() or not _pickup(stone): return _finish(false)
			if not go(plate.pos,false) or not _commit({"type":"drop","item_id":stone}): return _finish(false)
			var latch:=_fixture("latch")
			if not go(latch.pos) or not _commit({"type":"latch","target_id":latch.id}): return _finish(false)
		var early_deep: bool=(explore or tour) and number>=3 and sim.snapshot().rules_version=="m4.1"
		if early_deep and not capability_rooms(): return _finish(false)
		var lock:=_fixture("lock")
		if not lock.is_empty() and not lock.open:
			if not _pickup(lock.key_id): return _finish(false)
		if number==1 and porter_policy!="skip":
			if not _space() or not _pickup("bell_clapper"): return _finish(false)
		if not lock.is_empty() and not lock.open:
			if not go(lock.pos) or not _commit({"type":"unlock","target_id":lock.id}): return _finish(false)
		if number==1 and porter_policy!="skip":
			if porter_policy=="return":
				var porter:=_fixture("porter")
				if not porter.restored and (not go(porter.pos) or not _commit({"type":"return_item","target_id":porter.id,"item_id":"bell_clapper"})): return _finish(false)
			elif porter_policy in ["keep","ring"]:
				if sim.snapshot().items.bell_clapper.location=="pack" and not _commit({"type":"equip","item_id":"bell_clapper"}): return _finish(false)
		if (explore or tour) and not early_deep and not capability_rooms(): return _finish(false)
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
		if (explore or tour) and number==1 and not find_secret(): return _finish(false)
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
		if (explore or tour) and not find_secret(): return _finish(false)
		var exit:=_fixture("exit")
		if not go(exit.pos) or not _commit({"type":"leave","target_id":exit.id}): return _finish(false)
	return _finish(sim.snapshot().status=="won")

func _finish(ok: bool) -> Dictionary:
	return {"ok":ok,"reason":error,"actions":actions,"snapshot":sim.snapshot(),"pressure":pressure}
