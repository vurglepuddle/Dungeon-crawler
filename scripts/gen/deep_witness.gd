extends "res://scripts/gen/witness.gd"
## An ordinary-action proof from empty hands, never relying on scattered loot.
var expected_wakes:=0
func _commit(action: Dictionary) -> bool:
	if action.type=="hit" and sim._actor(action.target_id).kind=="ghost":
		action={"type":"dispel","target_id":action.target_id,"item_id":"f3_seal"}
	return super._commit(action)
func _raw(action: Dictionary) -> bool:
	var result: Dictionary=sim.apply(action)
	if not result.accepted:
		error=result.reason+" "+JSON.stringify(action); return false
	actions.append(action.duplicate(true))
	if sim._s.hp!=5 or sim._s.wakes!=expected_wakes: error="Deep witness took damage"; return false
	return true
func _open(kind: String) -> bool:
	for _pass in range(4):
		var changed:=false
		for f in sim.floor_data().fixtures:
			if f.type!=kind or f.open: continue
			if kind=="lock" and not sim.has_key(f): continue
			if not sim._near(f.pos) and _path(f.pos,true).is_empty(): continue
			if not go(f.pos): return false
			if not _commit({"type":"unlock","target_id":f.id} if kind=="lock" else {"type":"burn","target_id":f.id,"item_id":"d%d_torch"%sim._s.floor}): return false
			changed=true
		if not changed: break
	return true
func prove(seed: String,options: Dictionary={}) -> Dictionary:
	var settings: Dictionary={"profile":"m5.1","start":"deep"}; settings.merge(options,true)
	sim=Sim.new(seed,3,settings); actions=[]; error=""
	if sim._s.get("status")=="error": return {"ok":false,"reason":sim._s.error}
	var first: int=settings.get("from_floor",4)
	if first>4 and first<sim._s.floor_count:
		sim._s.floor=first; sim._s.pos=sim._floor().start.duplicate(); sim._visit()
	for n in range(first,sim._s.floor_count):
		var p: String="d%d_"%n
		if not go(sim._fixture(p+"dawn").pos) or not _commit({"type":"wake","target_id":p+"dawn"}): break
		if not _pickup(p+"stone") or not _pickup(p+"shard") or not _commit({"type":"equip","item_id":p+"shard"}): break
		if not go(sim._fixture(p+"plate").pos,false) or not _commit({"type":"drop","item_id":p+"stone"}): break
		if not go(sim._fixture(p+"latch").pos) or not _commit({"type":"latch","target_id":p+"latch"}): break
		if not _pickup(p+"key") or not _pickup(p+"fire_key") or not _open("lock"): break
		if not _pickup(p+"torch") or not go(sim._fixture(p+"brazier").pos) or not _commit({"type":"light","item_id":p+"torch","target_id":p+"brazier"}): break
		if not _open("web") or not go(sim._fixture(p+"down").pos) or not _commit({"type":"stairs","target_id":p+"down"}): break
	if error=="" and sim._s.floor==sim._s.floor_count:
		if go(sim._fixture("winding_lift").pos): _commit({"type":"ride","target_id":"winding_lift"})
	return {"ok":error=="" and sim._s.status=="won","reason":error,"actions":actions,"snapshot":sim.snapshot()}
