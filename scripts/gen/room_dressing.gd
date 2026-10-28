extends RefCounted
const Paint=preload("res://scripts/art/presentation_art.gd")
const DIRS=[[0,-1],[1,0],[0,1],[-1,0]]
const KINDS=["rubble","bone_heap","skeleton","pots","statue","candles","crate"]
static func place(run: Dictionary) -> void:
	for i in range(run.floors.size()):
		var f: Dictionary=run.floors[i]; f.props=[]
		var reserved: Array=[f.start,f.landing]
		for fixture in f.fixtures:
			reserved.append(fixture.pos)
			if fixture.has("wall"): reserved.append(fixture.wall)
		for actor in f.actors: reserved.append(actor.pos)
		for item in run.items.values():
			if item.location=="floor" and item.floor==i+1: reserved.append(item.pos)
		var candidates: Array=[]; var pillars: Array=[]
		for y in range(2,15):
			for x in range(2,15):
				var p: Array=[x,y]
				if reserved.any(func(r): return absi(x-r[0])+absi(y-r[1])<=1): continue
				var walls: Array=[]; var opens:=0
				for d in DIRS:
					if f.tiles[(y+d[1])*17+x+d[0]]==1: walls.append(d)
					else: opens+=1
				if f.tiles[y*17+x]==0 and walls.size()>0 and opens>=2:
					candidates.append({"pos":p,"wall":walls[0],"rank":Paint.mix_hash("%s/%d/prop/%d/%d"%[run.seed,i+1,x,y])})
				elif f.tiles[y*17+x]==1 and opens>=2: pillars.append(p)
		candidates.sort_custom(func(a,b): return a.rank<b.rank)
		for candidate in candidates:
			if f.props.size()>=2: break
			if f.props.any(func(p): return absi(p.pos[0]-candidate.pos[0])+absi(p.pos[1]-candidate.pos[1])<3): continue
			f.props.append({"id":"decor_%d_%d"%[i+1,f.props.size()],"kind":KINDS[candidate.rank%KINDS.size()],"pos":candidate.pos,"offset":[candidate.wall[0]*22,candidate.wall[1]*22]})
		# A pilaster uses an existing solid masonry recess. Its entire cell
		# already blocks movement and sight; decoration changes no routes.
		if not pillars.is_empty():
			var p: Array=pillars[Paint.mix_hash("%s/%d/pilaster"%[run.seed,i+1])%pillars.size()]
			f.props.append({"id":"decor_%d_pillar"%(i+1),"kind":"pillar","pos":p})
