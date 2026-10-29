extends RefCounted
const Family=preload("res://scripts/art/art_family.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const FLOORS=["dry_a","dry_b","dry_c","stain","chip","crack","wet_small","wet_hook","wet_corner","wet_split","wet_wide"]
const WEIGHTS=[[28,24,21,10,8,6,3,0,0,0,0],[14,12,10,6,5,5,10,10,10,9,9]]
static var _cells: Dictionary={}
static func path(seed: String,number: int,plane: String,x: int,y: int,family: Dictionary={}) -> String:
	if family.is_empty(): family=Family.for_floor(number)
	var key: String="%s/%d/%s/%d/%d"%[seed,number,plane,x,y]
	var cache_key: String=key+"/%d/%d"%[family.walls,family.weights]
	if _cells.has(cache_key): return _cells[cache_key]
	var roll: int=Paint.mix_hash(key)%100
	var names: Array=FLOORS if plane=="floor" else ["plain","root","drip"]
	var weights: Array=WEIGHTS[family.weights-1] if plane=="floor" else ([98,0,2] if family.weights==1 else [82,10,8])
	for i in range(names.size()):
		if roll<int(weights[i]):
			_cells[cache_key]="res://assets/art/env/%s_%s_%s.png"%[family.planes,plane,names[i]]
			return _cells[cache_key]
		roll-=int(weights[i])
	return ""

static func ground_cells(state: Dictionary) -> Dictionary:
	var result: Dictionary={}; var bindings: Dictionary=Faces.all(state)
	for fixture in state.fixtures:
		if fixture.type not in ["lift","stairs_down"]: continue
		if not bindings.has(fixture.id):
			push_error("Travel ground has no physical binding: "+fixture.id); continue
		var kind: String="stairs_down" if fixture.type=="stairs_down" else ("lift_working" if fixture.active else "lift_dead")
		result[Vector2i(fixture.pos[0],fixture.pos[1])]={"path":"res://assets/art/fixtures/fixture_v2_f%d_floor_%s_64.png"%[Family.for_floor(state.floor).fixtures,kind],"normal":bindings[fixture.id].normal}
	return result

static func ground_uv(u: int,v: int,normal: Array) -> Vector2i:
	# The two-pixel joint ring is world-aligned even when the deck rotates.
	if u<2 or u>=62 or v<2 or v>=62: return Vector2i(u,v)
	var travel: Array=[-normal[0],-normal[1]]
	if travel==[1,0]: return Vector2i(v,63-u)
	if travel==[0,1]: return Vector2i(63-u,63-v)
	if travel==[-1,0]: return Vector2i(63-v,u)
	return Vector2i(u,v)

static func room_cells(state: Dictionary) -> Dictionary:
	# One quiet landmark per actual three-wide room, never a corridor repeat.
	var result: Dictionary={}; var chosen: Array=[]
	for y in range(2,state.height-2):
		for x in range(2,state.width-2):
			var open: bool=true
			for dy in range(-1,2):
				for dx in range(-1,2):
					if state.tiles[(y+dy)*state.width+x+dx]!=0: open=false
			if not open or chosen.any(func(p): return maxi(absi(p.x-x),absi(p.y-y))<3): continue
			if state.fixtures.any(func(f): return f.pos==[x,y]): continue
			var index: int=Paint.mix_hash("%s/%d/room/%d/%d"%[state.seed,state.floor,x,y])%3
			result[Vector2i(x,y)]={"floor":"res://assets/art/env/%s_room_floor_%s.png"%[Family.at(state,[x,y]).planes,["drain","cracked","compass"][index]],"ceiling":"res://assets/art/env/%s_room_ceiling_%s.png"%[Family.at(state,[x,y]).planes,["roots","chain","boss"][index]]}
			chosen.append(Vector2i(x,y))
	return result
