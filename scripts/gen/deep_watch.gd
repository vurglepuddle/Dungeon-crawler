extends RefCounted
const Rooms=preload("res://scripts/gen/capability_rooms.gd")
## Existing modules recombined; three actors, unchanged terrain bounds.
static func decorate(run: Dictionary) -> void:
	for i in range(2,run.floors.size()):
		var f: Dictionary=run.floors[i]; var number: int=i+1
		var x: int=f.start[0]; var prefix: String="f%d_"%number
		f.title="The Lower Watch." if number==3 else "The Last Watch."
		f.actors[0].damage=2
		Rooms._carve(f,x-5,13,x-3,15); Rooms._carve(f,x-2,14,x-2,14)
		Rooms._carve(f,x+3,13,x+5,15); Rooms._carve(f,x+2,14,x+2,14)
		f.fixtures.append_array([
			{"id":prefix+"brazier","type":"brazier","pos":[x-1,15],"lit":true},
			{"id":prefix+"web","type":"web","pos":[x-2,14],"open":false},
			{"id":prefix+"cord","type":"cord","pos":[x+2,14],"open":false}])
		f.actors.append_array([
			{"id":prefix+"hound","kind":"hound","pos":[f.layout.branch,8],"hp":3,"state":"idle","intent":{},"damage":3},
			{"id":prefix+"ghost","kind":"ghost","pos":[x+4,14],"hp":2,"state":"idle","intent":{},"damage":2}])
		Rooms._item(run,prefix+"torch","torch",number,[x-1,14],{"lit":false})
		Rooms._item(run,prefix+"watch_bread","bread",number,[x-1,12])
		Rooms._item(run,prefix+"watch_coat","coat",number,[x+1,13])
		Rooms._item(run,prefix+"watch_shard","shard",number,[x+1,12])
		Rooms._item(run,prefix+"guide_lamp","lamp",number,[x+1,14])
		Rooms._item(run,prefix+"store_tonic","tonic",number,[x-4,14])
		Rooms._item(run,prefix+"wick_tonic","tonic",number,[x+4,15])
