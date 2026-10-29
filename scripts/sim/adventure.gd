extends RefCounted
## m5-only transitions. No clocks, presentation RNG or profile-file I/O.
const Gen=preload("res://scripts/gen/floor_gen.gd")
const Deep=preload("res://scripts/gen/the_deep.gd")
static func generate(seed: String,options: Dictionary) -> Dictionary:
	var count: int=options.get("deep_floors",1)
	var columns: int=options.get("columns",2); var rows: int=options.get("rows",2)
	if count<1 or count>3 or columns<1 or columns>4 or rows<1 or rows>4: return {"ok":false,"error":"Invalid Deep setting."}
	var run: Dictionary=Gen.new().generate(seed,3)
	if not run.ok: return run
	for i in range(count): Deep.build(run,i+4,columns,rows)
	Deep.winding(run)
	return run
static func active(sim) -> bool: return sim._s.rules_version=="m5.1"
static func dropped(sim,id: String,number: int,p: Array) -> void:
	var item: Dictionary=sim._s.items[id]
	item.location="floor"; item.floor=number; item.pos=p.duplicate(); item.slot=""
static func enter_deep(sim,scatter: bool) -> void:
	var s: Dictionary=sim._s
	var carried: Array=s.pack+[s.equipment.hand,s.equipment.body]+s.belt
	var ordinary: Array=[]
	var seal: String="f3_seal"
	for id in carried:
		if id=="" or s.items[id].kind=="seal": continue
		if s.items[id].kind!="key": ordinary.append(id)
		dropped(sim,id,s.floor,s.pos)
	s.pack=[]; s.equipment={"hand":"","body":""}; s.belt=[seal]
	s.items[seal].location="belt"; s.items[seal].floor=0; s.items[seal].pos=[]; s.items[seal].slot=""
	s.floor=4; s.pos=s.floors[3].start.duplicate(); s.facing=0; s.hp=5; s.status="playing"; s.fallen=true; s.act="deep"
	if scatter:
		var f: Dictionary=s.floors[3]
		var distances: Dictionary={Vector2i(s.pos[0],s.pos[1]):0}; var todo: Array=[s.pos]; var head:=0
		while head<todo.size():
			var p: Array=todo[head]; head+=1
			for d in sim.DIRS:
				var q: Array=[p[0]+d[0],p[1]+d[1]]; var k:=Vector2i(q[0],q[1])
				if q[0]<1 or q[1]<1 or q[0]>=f.width-1 or q[1]>=f.height-1 or distances.has(k): continue
				if f.tiles[q[1]*f.width+q[0]]!=0 and q!=[8,6]: continue
				distances[k]=distances[Vector2i(p[0],p[1])]+1; todo.append(q)
		var free: Array=[]
		for p in todo:
			if distances[Vector2i(p[0],p[1])]<12 or f.fixtures.any(func(v): return v.pos==p) or f.actors.any(func(v): return v.pos==p): continue
			if s.items.values().any(func(v): return v.location=="floor" and v.floor==4 and v.pos==p): continue
			free.append(p)
		free.sort_custom(func(a,b): return (a[0]+a[1]*f.width)<(b[0]+b[1]*f.width))
		ordinary.sort()
		for i in range(mini(3,mini(ordinary.size(),free.size()))):
			var index: int=(i*17+int(s.seed.hash()&0x7fffffff))%free.size()
			var p: Array=free.pop_at(index); dropped(sim,ordinary[i],4,p); s.items[ordinary[i]].yours=true
		sim._event("fell","transition",{"scattered":mini(3,ordinary.size())})
static func wake(sim) -> void:
	var s: Dictionary=sim._s; var old: Array=s.pos.duplicate()
	for id in s.pack+[s.equipment.body]:
		if id!="": dropped(sim,id,s.floor,old)
	s.pack=[]; s.equipment.body=""; s.hp=5; s.status="playing"; s.wakes+=1
	s.pos=sim._floor().start.duplicate(); s.facing=0
	for actor in sim._floor().actors:
		if actor.hp<=0 or actor.state=="peaceful": continue
		actor.state="recovery"; actor.intent={}
		if actor.pos!=s.pos: continue
		var moved:=false
		for y in range(1,sim._floor().height-1):
			for x in range(1,sim._floor().width-1):
				if not moved and absi(x-s.pos[0])+absi(y-s.pos[1])>=3 and sim.can_walk([x,y]): actor.pos=[x,y]; moved=true
	sim._event("woke","transition",{"dropped_at":old,"arrival":s.pos.duplicate()})
