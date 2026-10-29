extends RefCounted
## Lower Watch has its own environment/props and retains floor-two fixtures.
static func for_floor(number: int) -> Dictionary:
	# The Winding wears B's dark Deep slate; the Deep keeps the Lower Watch until
	# families are chosen per block (the owner: "some rooms in that style - just not all").
	if number>=5: return {"walls":4,"fixtures":2,"props":3,"planes":"calm_v3_f4","weights":2}
	if number==4: return {"walls":3,"fixtures":2,"props":3,"planes":"calm_v3_f3","weights":2}
	if number==3: return {"walls":3,"fixtures":2,"props":3,"planes":"calm_v3_f3","weights":2}
	var base: int=clampi(number,1,2)
	return {"walls":base,"fixtures":base,"props":base,"planes":"calm_v3","weights":base}

static var _blocks: Dictionary={}
static func at(state: Dictionary,cell: Array) -> Dictionary:
	if not state.get("deep_materials",false): return for_floor(state.floor)
	var block:=Vector2i(clampi(cell[0]/16,0,(state.width-2)/16),clampi(cell[1]/16,0,(state.height-2)/16))
	var key: String="%s/%d/%d/%d"%[state.seed,state.floor,block.x,block.y]
	if _blocks.has(key): return _blocks[key]
	# Four-block cycle gives each block a distinct mood, independent of route.
	var offset: int=preload("res://scripts/art/presentation_art.gd").mix_hash(state.seed+"/deep-family/"+str(state.floor))%4
	var walls: int=1+posmod(offset+block.x+block.y*2,4)
	_blocks[key]={"walls":walls,"fixtures":2,"props":mini(walls,3),"planes":"calm_v3_f%d"%walls if walls>=3 else "calm_v3","weights":2 if walls>1 else 1}
	return _blocks[key]
