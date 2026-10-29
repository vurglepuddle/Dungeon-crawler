extends RefCounted
## Blocks share their outer wall, with two independently usable ports per join.
## Dependency pockets are cul-de-sacs; the surrounding loops cannot bypass them.
const Catalog=preload("res://scripts/content/catalog.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const SIDE=17
static func carve(f: Dictionary,a: Array,b: Array) -> void:
	for y in range(a[1],b[1]+1):
		for x in range(a[0],b[0]+1): f.tiles[y*f.width+x]=0
static func at(origin: Array,x: int,y: int) -> Array: return [origin[0]+x,origin[1]+y]
static func item(run: Dictionary,id: String,kind: String,n: int,p: Array) -> void:
	run.items[id]={"id":id,"kind":kind,"location":"floor","floor":n,"pos":p,"slot":"","spent":false}
	if kind=="torch": run.items[id].lit=false
static func blank(w: int,h: int,start: Array,title: String) -> Dictionary:
	var tiles: Array=[]; tiles.resize(w*h); tiles.fill(1)
	var visited: Array=[]; visited.resize(w*h); visited.fill(false)
	return {"width":w,"height":h,"tiles":tiles,"fixtures":[],"actors":[],"visited":visited,"start":start,"landing":start.duplicate(),"props":[],"title":title,"layout":{}}
static func build(run: Dictionary,n: int,columns: int=2,rows: int=2) -> void:
	var f: Dictionary=blank(columns*(SIDE-1)+1,rows*(SIDE-1)+1,[8,8],"The Deep")
	var prefix: String="d%d_"%n
	var blocks: Array=[]
	# Serpentine registration works for rectangular arrangements, including 1xN.
	for row in range(rows):
		for j in range(columns): blocks.append([(j if row%2==0 else columns-1-j)*16,row*16])
	for o in blocks:
		carve(f,at(o,3,3),at(o,13,3)); carve(f,at(o,3,13),at(o,13,13))
		carve(f,at(o,3,3),at(o,3,13)); carve(f,at(o,13,3),at(o,13,13))
		carve(f,at(o,3,8),at(o,13,8)); carve(f,at(o,8,3),at(o,8,13))
		carve(f,at(o,7,7),at(o,9,9))
	for i in range(blocks.size()):
		var o: Array=blocks[i]; var roll: int=Paint.mix_hash(run.seed+prefix+str(i))
		if roll%2==0: carve(f,at(o,2,2),at(o,4,4))
		if roll%3!=0: carve(f,at(o,12,12),at(o,14,14))
		if roll%5<3: carve(f,at(o,1,10),at(o,3,10))
	var b: Array=blocks[mini(1,blocks.size()-1)]
	var c: Array=blocks[mini(2,blocks.size()-1)]
	var end: Array=blocks.back()
	# All neighbour joins have two ports. Late fire joins close the big loop.
	for i in range(blocks.size()):
		for j in range(i+1,blocks.size()):
			var a: Array=blocks[i]; var z: Array=blocks[j]
			if absi(a[0]-z[0])+absi(a[1]-z[1])!=16: continue
			var join_roll: int=Paint.mix_hash(run.seed+prefix+str(i)+"/"+str(j))
			for offset in [4+join_roll%3,10+(join_roll/8)%3]:
				var p: Array
				if a[0]!=z[0]:
					p=[mini(a[0],z[0])+16,a[1]+offset]
					carve(f,[p[0]-3,p[1]],[p[0]+3,p[1]])
				else:
					p=[a[0]+offset,mini(a[1],z[1])+16]
					carve(f,[p[0],p[1]-3],[p[0],p[1]+3])
				var id: String=prefix+"join_%d_%d_%d"%[i,j,offset]
				if j>=3 or (i==0 and j>1): f.fixtures.append({"id":id,"type":"web","pos":p,"open":false})
				elif i==1 and j==2: f.fixtures.append({"id":id,"type":"lock","pos":p,"key_id":prefix+"key","open":false})
	# The waking room is isolated until a deliberate Seal tap opens its north wall.
	for p in [[6,8],[10,8],[8,10],[8,6]]: f.tiles[p[1]*f.width+p[0]]=1
	f.fixtures.append({"id":prefix+"dawn","type":"panel","pos":[8,7],"wall":[8,6],"normal":[0,1],"open":false,"revealed":false,"item_id":"","passage":true})
	# A weight-held key store. The return-side latch makes withdrawing safe.
	carve(f,at(b,10,10),at(b,11,11)); carve(f,at(b,11,12),at(b,11,12))
	f.fixtures.append_array([
		{"id":prefix+"plate","type":"plate","pos":at(b,9,13),"pressed":false,"gate_id":prefix+"gate"},
		{"id":prefix+"gate","type":"gate","pos":at(b,11,12),"open":false,"latched":false,"plate_id":prefix+"plate"},
		{"id":prefix+"latch","type":"latch","pos":at(b,11,11),"gate_id":prefix+"gate"}])
	item(run,prefix+"key","key",n,at(b,10,10)); item(run,prefix+"fire_key","key",n,at(b,10,11))
	# Only fire is inside a separately keyed, one-entry store.
	carve(f,at(c,5,10),at(c,6,11)); carve(f,at(c,5,12),at(c,5,12))
	f.fixtures.append({"id":prefix+"fire_lock","type":"lock","pos":at(c,5,12),"key_id":prefix+"fire_key","open":false})
	item(run,prefix+"torch","torch",n,at(c,5,10))
	f.fixtures.append({"id":prefix+"brazier","type":"brazier","pos":at(c,6,13),"lit":true})
	# Every route to the downward stair meets this final FIRE cut.
	carve(f,at(end,8,1),at(end,8,3)); f.landing=at(end,8,1)
	f.fixtures.append({"id":prefix+"last_web","type":"web","pos":at(end,8,2),"open":false})
	f.fixtures.append({"id":prefix+"down","type":"stairs_down","pos":f.landing.duplicate()})
	item(run,prefix+"stone","stone",n,[8,4])
	item(run,prefix+"shard","shard",n,[7,3])
	item(run,prefix+"bread","bread",n,at(b,3,9))
	item(run,prefix+"coat","coat",n,at(c,12,3))
	# A few seed-selected dead ends and sparse ordinary junk, no extra healing.
	var reserved: Array=[f.start,f.landing]
	for fixture in f.fixtures: reserved.append(fixture.pos)
	for value in run.items.values():
		if value.location=="floor" and value.floor==n: reserved.append(value.pos)
	var candidates: Array=[]
	for o in blocks:
		for p in [at(o,3,5),at(o,13,10),at(o,5,3),at(o,10,13),at(o,8,12),at(o,3,11),at(o,11,8)]:
			if not reserved.has(p): candidates.append(p)
	# One roaming encounter per block. Extra creatures live in optional corded
	# pockets, so a mandatory route never starts between alternating blows.
	var count: int=6+Paint.mix_hash(run.seed+prefix)%3
	var main_count: int=mini(count,blocks.size())
	for i in range(main_count):
		var p: Array=at(blocks[i],8,12)
		var kind: String=["husk","hound","ghost"][i%3]
		f.actors.append({"id":prefix+"actor_%d"%i,"kind":kind,"pos":p,"hp":Catalog.CREATURES[kind].hp,"state":"idle","intent":{},"damage":2})
	var pocket_cells: Array=[]
	for o in blocks:
		for x in [5,11]:
			carve(f,at(o,x-1 if x==11 else x,5),at(o,x if x==11 else x+1,6))
			carve(f,at(o,x,4),at(o,x,4))
			# Portal paintings need a one-cell mouth, even beside a wider corner.
			for side in [-1,1]: f.tiles[(o[1]+4)*f.width+o[0]+x+side]=1
			f.fixtures.append({"id":prefix+"cord_%d_%d_%d"%[o[0],o[1],x],"type":"cord","pos":at(o,x,4),"open":false})
			for y in [5,6]:
				for xx in ([x-1,x] if x==11 else [x,x+1]): pocket_cells.append(at(o,xx,y))
	for i in range(main_count,count):
		var index: int=(i-main_count)*4%pocket_cells.size()
		while reserved.has(pocket_cells[index]): index=(index+1)%pocket_cells.size()
		var p: Array=pocket_cells[index]; reserved.append(p)
		var kind: String=["husk","hound","ghost"][i%3]
		f.actors.append({"id":prefix+"actor_%d"%i,"kind":kind,"pos":p,"hp":Catalog.CREATURES[kind].hp,"state":"idle","intent":{},"damage":2})
	for mouth in [at(b,11,12),at(c,5,12)]:
		for side in [-1,1]: f.tiles[mouth[1]*f.width+mouth[0]+side]=1
	candidates=candidates.filter(func(p): return f.actors.all(func(a): return a.pos!=p))
	for i in range(mini(10,candidates.size())):
		var p: Array=candidates[i]
		item(run,prefix+"junk_%d"%i,["bone","stone","club","bone"][i%4],n,p)
	var quiet: Array=pocket_cells.filter(func(p): return not reserved.has(p) and f.actors.all(func(a): return a.pos!=p))
	if not quiet.is_empty(): item(run,prefix+"quiet_tonic","tonic",n,quiet.back())
	f.layout={"blocks":[columns,rows],"need_order":[prefix+"dawn",prefix+"stone",prefix+"plate",prefix+"key",prefix+"fire_key",prefix+"fire_lock",prefix+"torch",prefix+"brazier",prefix+"last_web",prefix+"down"]}
	run.floors.append(f)
static func winding(run: Dictionary) -> void:
	var f: Dictionary=blank(9,9,[4,6],"The Winding")
	carve(f,[3,2],[5,6]); f.landing=[4,2]
	f.fixtures.append({"id":"winding_lift","type":"lift","pos":[4,2],"active":true,"owner_id":"","destination_id":"winding_lift","destination_floor":run.floors.size()+1,"destination":[4,6],"final":true})
	run.floors.append(f)
