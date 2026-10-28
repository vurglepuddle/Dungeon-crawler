extends RefCounted
## Optional encounters attach below the weight gate, never bypass its cut.
static func _carve(f: Dictionary,x1: int,y1: int,x2: int,y2: int) -> void:
	for y in range(y1,y2+1):
		for x in range(x1,x2+1): f.tiles[y*17+x]=0
static func _item(run: Dictionary,id: String,kind: String,floor_number: int,pos: Array,extra: Dictionary={}) -> void:
	var item: Dictionary={"id":id,"kind":kind,"location":"floor","floor":floor_number,"pos":pos,"slot":"","spent":false}
	item.merge(extra); run.items[id]=item
static func decorate(run: Dictionary) -> void:
	var count: int=run.floors.size()
	var first: Dictionary=run.floors[0]
	var x: int=first.start[0]
	_carve(first,x-5,13,x-3,15); _carve(first,x-2,14,x-2,14)
	first.fixtures.append_array([
		{"id":"f1_brazier","type":"brazier","pos":[x-1,15],"lit":true},
		{"id":"f1_web","type":"web","pos":[x-2,14],"open":false},
		{"id":"f1_panel","type":"panel","pos":[x-1,13],"wall":[x-2,13],"normal":[1,0],"revealed":false,"open":false,"item_id":"f1_secret_tonic"}])
	first.actors.append({"id":"f1_hound","kind":"hound","pos":[x-4,14],"hp":3,"state":"idle","intent":{}})
	_item(run,"f1_torch","torch",1,[x-1,14],{"lit":false})
	_item(run,"f1_kennel_coat","coat",1,[x-4,13])
	_item(run,"f1_secret_tonic","tonic",1,[x-1,13],{"hidden":true})
	var number: int=mini(count,2)
	var second: Dictionary=run.floors[number-1]
	x=second.start[0]
	_carve(second,x+3,13,x+5,15); _carve(second,x+2,14,x+2,14)
	second.fixtures.append({"id":"f%d_cord"%number,"type":"cord","pos":[x+2,14],"open":false})
	second.actors.append({"id":"f%d_ghost"%number,"kind":"ghost","pos":[x+4,14],"hp":2,"state":"idle","intent":{}})
	_item(run,"f%d_guide_lamp"%number,"lamp",number,[x+1,14])
	_item(run,"f%d_wick_tonic"%number,"tonic",number,[x+4,15])
