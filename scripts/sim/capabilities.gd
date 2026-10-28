extends RefCounted
## Explicit, deterministic capability actions. No view/audio or wall-clock state.
const ACTIONS=["light","burn","cut","feed","dispel","reveal","toss"]
static func enabled(sim) -> bool: return sim._s.rules_version in ["m3.3","m4.1"]
static func owned(sim,id: String) -> bool:
	return sim._s.items.has(id) and sim._s.items[id].location in ["pack","equip","belt"]
static func has(sim,id: String,tag: String) -> bool:
	return owned(sim,id) and sim.definition(id).tags.has(tag)
static func blocks(f: Dictionary) -> bool:
	return f.type in ["web","cord"] and not f.open
static func in_reach(sim,actor: Dictionary) -> bool:
	return actor.hp>0 and sim._los(sim._s.pos,actor.pos,2)
static func consume(sim,id: String) -> void:
	var item: Dictionary=sim._s.items[id]
	sim._s.pack.erase(id)
	if item.location=="equip": sim._s.equipment[item.slot]=""
	item.location="consumed"; item.slot=""; item.pos=[]; item.floor=0
static func feed(sim,actor: Dictionary,id: String,old_states: Dictionary) -> void:
	consume(sim,id); actor.state="peaceful"; actor.intent={}; old_states[actor.id]="pacified"
	# Step into the room's safest available perch. A fed Hound remains a body,
	# never an intangible actor allowed to overlap the Finder.
	var options: Array=[]
	for d in sim.DIRS:
		var cell: Array=[actor.pos[0]+d[0],actor.pos[1]+d[1]]
		if cell!=sim._s.pos and sim.can_walk(cell) and sim._floor().fixtures.all(func(f): return f.pos!=cell): options.append(cell)
	options.sort_custom(func(a,b): return absi(a[0]-sim._s.pos[0])+absi(a[1]-sim._s.pos[1])>absi(b[0]-sim._s.pos[0])+absi(b[1]-sim._s.pos[1]))
	if not options.is_empty(): actor.pos=options[0]
	sim._event("hound_fed","player",{"actor_id":actor.id,"item_id":id,"pos":actor.pos.duplicate()})
static func toss_preview(sim,id: String) -> Dictionary:
	var result: Dictionary={"cells":[],"landing":[],"actor_id":"","fixture_id":""}
	if not enabled(sim) or not owned(sim,id) or sim.definition(id).slot=="belt": return result
	var d: Array=sim.DIRS[sim._s.facing]
	for distance in range(1,3):
		var cell: Array=[sim._s.pos[0]+d[0]*distance,sim._s.pos[1]+d[1]*distance]
		if sim.terrain(cell)!=0: break
		var blocked:=false
		for f in sim._floor().fixtures:
			if f.pos!=cell: continue
			if blocks(f):
				result.fixture_id=f.id; blocked=true
				if f.type=="web" and has(sim,id,"FIRE"): result.landing=cell.duplicate(); result.cells.append(cell.duplicate())
			elif f.type=="porter" or f.type in ["gate","lock"] and not f.open: blocked=true
		if blocked: break
		result.cells.append(cell.duplicate()); result.landing=cell.duplicate()
		for actor in sim._floor().actors:
			if actor.hp>0 and actor.pos==cell: result.actor_id=actor.id; break
		if result.actor_id!="": break
	return result
static func targets(sim,id: String) -> Array:
	var result: Array=[]
	if not enabled(sim) or not owned(sim,id): return result
	for f in sim.local_fixtures():
		var verb: String=""
		if f.type=="brazier" and f.lit and sim._s.items[id].kind=="torch" and not sim._s.items[id].lit: verb="LIGHT"
		elif f.type=="web" and not f.open and has(sim,id,"FIRE"): verb="BURN"
		elif f.type in ["cord","panel"] and not f.open and (f.type!="panel" or f.revealed) and has(sim,id,"EDGE"): verb="CUT"
		elif f.type=="panel" and not f.revealed and has(sim,id,"GLOW"): verb="REVEAL"
		if verb!="": result.append({"target_id":f.id,"pos":f.pos.duplicate(),"verb":verb,"action":{"type":verb.to_lower(),"item_id":id,"target_id":f.id}})
	for actor in sim._floor().actors:
		if not in_reach(sim,actor): continue
		var verb: String="FEED" if actor.kind=="hound" and actor.state!="peaceful" and has(sim,id,"FOOD") else ("DISPEL" if actor.kind=="ghost" and has(sim,id,"GLOW") else "")
		if verb=="FEED" and not sim._near(actor.pos):
			if toss_preview(sim,id).actor_id==actor.id:
				result.append({"target_id":actor.id,"pos":actor.pos.duplicate(),"verb":"TOSS","action":{"type":"toss","item_id":id}})
			continue
		if verb!="": result.append({"target_id":actor.id,"pos":actor.pos.duplicate(),"verb":verb,"action":{"type":verb.to_lower(),"item_id":id,"target_id":actor.id}})
	return result
static func validate_action(sim,action: Dictionary) -> String:
	if not enabled(sim): return "That art is unknown."
	var id: String=action.get("item_id","")
	if action.type=="toss":
		return "No safe toss lane." if toss_preview(sim,id).landing.is_empty() else ""
	for entry in targets(sim,id):
		if entry.action.type==action.type and entry.target_id==action.get("target_id",""): return ""
	return "No matching target."
static func commit(sim,action: Dictionary,old_states: Dictionary) -> void:
	var id: String=action.get("item_id","")
	var target: String=action.get("target_id","")
	var f: Dictionary=sim._fixture(target)
	match action.type:
		"light":
			sim._s.items[id].lit=true; sim._event("torch_lit","player",{"item_id":id,"target_id":target})
		"burn","cut":
			f.open=true
			if f.type=="panel":
				sim._s.items[f.item_id].hidden=false
				sim._event("secret_found","player",{"target_id":target,"item_id":f.item_id})
			else: sim._event("web_burnt" if f.type=="web" else "cord_cut","player",{"target_id":target})
		"feed": feed(sim,sim._actor(target),id,old_states)
		"dispel":
			var actor: Dictionary=sim._actor(target)
			actor.hp=0; actor.state="dead"; actor.intent={}
			sim._event("ghost_dispelled","player",{"actor_id":target,"item_id":id})
		"reveal":
			f.revealed=true; sim._event("panel_revealed","player",{"target_id":target})
		"toss":
			var lane: Dictionary=toss_preview(sim,id)
			var actor: Dictionary=sim._actor(lane.actor_id)
			var web: Dictionary=sim._fixture(lane.fixture_id)
			if not web.is_empty() and web.type=="web" and has(sim,id,"FIRE"):
				web.open=true; sim._event("web_burnt","player",{"target_id":web.id})
			if not actor.is_empty() and actor.kind=="hound" and actor.state!="peaceful" and has(sim,id,"FOOD"):
				feed(sim,actor,id,old_states)
			else:
				var item: Dictionary=sim._s.items[id]
				sim._s.pack.erase(id)
				if item.location=="equip": sim._s.equipment[item.slot]=""
				item.location="floor"; item.slot=""; item.floor=sim._s.floor; item.pos=lane.landing.duplicate()
				if not actor.is_empty() and actor.kind=="ghost" and sim.definition(id).tags.has("GLOW"):
					actor.hp=0; actor.state="dead"; actor.intent={}
					sim._event("ghost_dispelled","player",{"actor_id":actor.id,"item_id":id})
				elif not actor.is_empty() and sim.definition(id).tags.has("HEAVY"):
					actor.hp=maxi(0,actor.hp-1)
					sim._event("struck","player",{"target_id":actor.id,"damage":1,"hp":actor.hp})
					if actor.hp==0: actor.state="dead"; actor.intent={}; sim._event("monster_defeated","player",{"actor_id":actor.id})
			sim._event("item_tossed","player",{"item_id":id,"cells":lane.cells,"pos":lane.landing})
static func glow_reveals(sim) -> void:
	if not enabled(sim) or not sim.has_seal(): return
	var d: Array=sim.DIRS[sim._s.facing]
	for f in sim._floor().fixtures:
		if f.type!="panel" or f.revealed: continue
		var dx: int=f.pos[0]-sim._s.pos[0]; var dy: int=f.pos[1]-sim._s.pos[1]
		var depth: int=dx*d[0]+dy*d[1]; var side: int=-dx*d[1]+dy*d[0]
		if depth>=0 and depth<=3 and absi(side)<=maxi(1,depth) and sim._clear_sight(f.pos):
			f.revealed=true; sim._event("panel_revealed","player",{"target_id":f.id,"by_seal":true})
static func hound_phase(sim,actor: Dictionary,old: String,guarded: bool) -> bool:
	if actor.kind!="hound": return false
	if old in ["peaceful","pacified"]: return true
	if old=="windup":
		var lane: Array=actor.intent.lane.duplicate(true)
		var hit: bool=lane.has(sim._s.pos)
		var damage: int=sim._resolve_damage(hit,guarded,sim.enemy_damage(actor))
		for cell in lane:
			if cell==sim._s.pos or not sim.can_walk(cell): break
			actor.pos=cell.duplicate()
		sim._event("attack_resolved","attack",{"actor_id":actor.id,"cell":actor.intent.cell.duplicate(),"lane":lane,"damage":damage,"blocked":hit and guarded,"armour":hit and not guarded and damage==0})
		actor.state="recovery"; actor.intent={}
		if sim._s.hp<=0: sim._s.status="lost"
		return true
	if old=="recovery": actor.state="idle"
	if not sim._los(actor.pos,sim._s.pos,3): return true
	var distance: int=absi(actor.pos[0]-sim._s.pos[0])+absi(actor.pos[1]-sim._s.pos[1])
	var d: Array=[signi(sim._s.pos[0]-actor.pos[0]),signi(sim._s.pos[1]-actor.pos[1])]
	if distance>2:
		var next: Array=[actor.pos[0]+d[0],actor.pos[1]+d[1]]
		if sim.can_walk(next) and next!=sim._s.pos:
			var before: Array=actor.pos.duplicate(); actor.pos=next
			sim._event("monster_moved","prepare",{"actor_id":actor.id,"from":before,"to":next.duplicate()})
	var lane: Array=[]
	for step in range(1,3):
		var cell: Array=[actor.pos[0]+d[0]*step,actor.pos[1]+d[1]*step]
		if not sim.can_walk(cell,true) or sim._floor().actors.any(func(other): return other.hp>0 and other.id!=actor.id and other.pos==cell): break
		lane.append(cell)
	if lane.has(sim._s.pos):
		actor.state="windup"; actor.intent={"cell":sim._s.pos.duplicate(),"lane":lane,"due_in":1}
		sim._event("intent_announced","prepare",{"actor_id":actor.id,"intent":actor.intent.duplicate(true)})
	return true
