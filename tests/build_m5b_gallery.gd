extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
var samples: Dictionary={}
func sample(name: String,s: Dictionary,number: int,pos: Array,face: int,extra: Dictionary={}) -> void:
	var state: Dictionary=s.duplicate(true); state.floor=number; state.pos=pos; state.facing=face; state.status="playing"
	state.act="abbey" if number<=3 else ("winding" if number==state.floor_count else "deep"); state.fallen=number>3
	samples[name]={"state":state,"extra":extra}
func _initialize() -> void:
	var sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep","metals":true})
	var s: Dictionary=sim.snapshot()
	sample("01_room_entry",s,4,[8,9],0)
	sample("02_room_map",s,4,[8,9],0,{"map":true})
	var abbey: Dictionary=Sim.new("BELL42",3,{"profile":"m5.1","metals":true}).snapshot()
	for metal in ["iron","bronze","gold"]:
		var id: String=abbey.items.keys().filter(func(k): return abbey.items[k].get("metal","")==metal)[0]
		var item: Dictionary=abbey.items[id]; item.location="belt"; item.floor=0; item.pos=[]; abbey.belt.append(id)
	var start: Array=abbey.pos
	sample("03_one_belt_icon",abbey,1,start,0)
	sample("04_key_list",abbey,1,start,0,{"keys":true})
	for metal in ["iron","bronze","gold"]:
		var x: int=abbey.pos[0]; var lock: Dictionary=abbey.floors[0].fixtures.filter(func(f): return f.type=="lock")[0]
		var state: Dictionary=abbey.duplicate(true)
		state.floors[0].actors=[]
		state.items[lock.key_id].metal=metal
		state.floors[0].fixtures.filter(func(f): return f.id==lock.id)[0].metal=metal
		var item: Dictionary=state.items[lock.key_id]; item.location="floor"; item.floor=1; item.pos=[x,6]; state.belt.erase(lock.key_id)
		sample("05_"+metal+"_lock_key",state,1,[x,7],0)
		state.items[lock.key_id].location="belt"; state.items[lock.key_id].floor=0; state.items[lock.key_id].pos=[]; state.belt.append(lock.key_id)
		sample("06_"+metal+"_card",state,1,[x,6],0,{"card":lock.key_id})
	# Winding always f4: isolate the Seal lighting without mutating paintings.
	sample("07_f4_near",s,5,[4,3],0)
	sample("08_f4_far",s,5,[4,6],0)
	# An actual horizontal block port, after opening the dawn; pure camera fixture.
	var n: int=4; var f: Dictionary=s.floors[3]; var seam_y: int=-1
	for y in range(1,16):
		if f.tiles[y*f.width+16]==0: seam_y=y; break
	assert(seam_y>0)
	sample("09_block_seam",s,n,[14,seam_y],1)
	sample("10_next_block",s,n,[17,seam_y],1)
	var file=FileAccess.open("res://build/m5b_gallery_samples.json",FileAccess.WRITE); file.store_string(JSON.stringify(samples)); file.close()
	var lines: Array=["# Authored frozen visual fixtures, not gameplay proofs.","wait 5"]
	for name in samples: lines.append_array(["call sample "+name,"wait 4","shot "+name])
	lines.append("close")
	file=FileAccess.open("res://tests/pilot/m5b_gallery.txt",FileAccess.WRITE); file.store_string("\n".join(lines)+"\n"); file.close()
	print("M5b visual fixtures: ",samples.size()); quit()
