extends RefCounted
## Shared physical wall attachment: renderer and forward interaction agree.
static func binding(f: Dictionary,fixture: Dictionary,used: Dictionary={}) -> Dictionary:
	if fixture.type=="panel": return {"wall":fixture.wall,"normal":fixture.normal}
	var directions: Array=[[0,-1],[-1,0],[1,0],[0,1]] if fixture.type=="stairs_down" else [[0,1],[1,0],[-1,0],[0,-1]]
	if fixture.type=="lift": directions=[[1,0],[0,1],[0,-1],[-1,0]]
	if fixture.type=="latch": directions=[[-1,0],[1,0],[0,-1],[0,1]]
	for d in directions:
		for distance in range(1,2 if fixture.type=="latch" else 4):
			var p: Array=[fixture.pos[0]+d[0]*distance,fixture.pos[1]+d[1]*distance]
			if p[0]<0 or p[1]<0 or p[0]>=f.width or p[1]>=f.height: break
			if f.tiles[p[1]*f.width+p[0]]!=1: continue
			var n: Array=[-d[0],-d[1]]
			if used.has(key(p,n)): break
			return {"wall":p,"normal":n}
	return {}
static func key(p: Array,n: Array) -> String: return "%d:%d:%d:%d"%[p[0],p[1],n[0],n[1]]
static func all(f: Dictionary) -> Dictionary:
	var result: Dictionary={}; var used: Dictionary={}
	for fixture in f.fixtures:
		if fixture.type not in ["exit","stairs_up","stairs_down","lift","panel","latch"]: continue
		var face: Dictionary=binding(f,fixture,used)
		if face.is_empty(): continue
		result[fixture.id]=face
		# Levers are hardware on their cell wall, not replacement masonry.
		if fixture.type!="latch": used[key(face.wall,face.normal)]=true
	return result
