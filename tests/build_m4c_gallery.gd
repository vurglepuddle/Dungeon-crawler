extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
var samples: Dictionary={}
func sample(name: String,s: Dictionary,number: int,pos: Array,face: int,extra: Dictionary={}) -> void:
	var state: Dictionary=s.duplicate(true); state.floor=number; state.pos=pos; state.facing=face; state.status="playing"
	samples[name]={"state":state,"extra":extra}
func _initialize() -> void:
	var sim=Sim.new("B3VJ5K",3); var initial: Dictionary=sim.snapshot()
	var tour: Dictionary=W.build("B3VJ5K",3,false,"return",true); assert(tour.ok)
	for action in tour.actions: assert(sim.apply(action).accepted)
	var done: Dictionary=sim.snapshot(); var x: int=initial.floors[2].start[0]
	sample("f3_corridor",done,3,[x,11],0)
	sample("f3_room",done,3,[x,15],0)
	sample("f3_door_closed",initial,3,[x,6],0)
	sample("f3_door_open",done,3,[x,6],0)
	var at: Array=initial.floors[0].start
	sample("card_vines",initial,1,at,0,{"card":"knife_start"})
	sample("overlay_idle",initial,1,at,0)
	for i in range(4): sample("overlay_flare_%d"%i,initial,1,at,0,{"flare":i})
	sample("candle_frame_1",initial,1,at,0,{"candle":1})
	var file=FileAccess.open("res://build/m4c_gallery_samples.json",FileAccess.WRITE); file.store_string(JSON.stringify(samples)); file.close()
	var lines: Array=["# Authored frozen presentation fixtures, not a gameplay route.","wait 5"]
	for name in samples: lines.append_array(["call sample "+name,"wait 4","shot "+name])
	lines.append("close")
	file=FileAccess.open("res://tests/pilot/m4c_gallery.txt",FileAccess.WRITE); file.store_string("\n".join(lines)+"\n"); file.close()
	print("M4c visual fixtures: ",samples.size()); quit()
