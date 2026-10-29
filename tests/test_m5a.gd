extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Bot=preload("res://scripts/gen/deep_witness.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
const Legacy=preload("res://scripts/gen/witness.gd")
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(note)
func _initialize() -> void:
	var seeds:=200
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seeds=arg.trim_prefix("--seeds=").to_int()
	var sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"})
	check(Codec.validate(sim.snapshot()),"Fresh m5 skip validates")
	var old=Sim.new("BELL42",3)
	var modern=Sim.new("BELL42",3,{"profile":"m5.1"})
	check(old.snapshot().floors==modern.snapshot().floors.slice(0,3),"Abbey floor bytes match m4.1")
	for id in old._s.items: check(old._s.items[id]==modern._s.items[id],"Abbey item bytes: "+id)
	var core: Dictionary=Legacy.build("BELL42",3,false,"keep")
	check(core.ok,"Legacy core plan")
	var held: Array=[]
	for action in core.actions:
		held=modern._s.pack+[modern._s.equipment.hand,modern._s.equipment.body]
		check(modern.apply(action).accepted,"Ordinary Abbey step "+str(action))
		if modern._s.fallen: break
	check(modern._s.floor==4 and modern._s.hp==5 and modern._s.pack.is_empty() and modern._s.equipment.hand=="" and modern._s.belt==["f3_seal"],"Fall retains only Seal at 5 HP")
	check(modern._s.floors[3]==sim._s.floors[3],"Tutorial and skipped starts have identical Deep layout/actors/visibility")
	var scattered: Array=modern._s.items.values().filter(func(v): return v.get("yours",false))
	check(scattered.size()==mini(3,held.filter(func(id): return id!="").size()),"At most three carried ordinary possessions scatter")
	for item in scattered: check(item.kind!="key" and absi(item.pos[0]-8)+absi(item.pos[1]-8)>=8,"Lost thing is away from waking room")
	check(Codec.validate(modern.snapshot()),"Fall snapshot validates")
	var mortal=Sim.new("BELL42",3,{"profile":"m5.1"})
	for action in core.actions:
		if action.type=="guard": break
		check(mortal.apply(action).accepted,"Abbey death setup")
	for _beat in range(40):
		if mortal._s.wakes>0: break
		mortal.apply({"type":"wait"})
	check(mortal._s.wakes==1 and mortal._s.floor==1 and mortal._s.hp==5 and mortal._s.equipment.hand=="knife_start","Abbey death also wakes with weapon")
	check(Codec.validate(mortal.snapshot()),"Abbey wake snapshot validates")
	var low:=100000; var high:=0
	for i in range(seeds):
		var seed: String="DEEP"+Sim.Gen.ALPHABET[(i/32)%32]+Sim.Gen.ALPHABET[i%32]
		var bot=Bot.new(); var proof: Dictionary=bot.prove(seed)
		check(proof.ok,"Deep witness "+seed+": "+proof.reason)
		if not proof.ok:
			print("FAILED ",seed," pos ",bot.sim._s.pos," last ",bot.actions.slice(-6)); break
		check(Codec.validate(Codec.normalize(JSON.parse_string(JSON.stringify(proof.snapshot)))),"Won schema-3 JSON round trip")
		check(proof.snapshot.hp==5 and proof.snapshot.wakes==0,"Empty-hand witness needs no death/healing")
		low=mini(low,proof.snapshot.turn); high=maxi(high,proof.snapshot.turn)
		if i%25==24: print("Deep witnesses ",i+1,"/",seeds)
	for shape in [[1,1],[1,2],[2,1],[1,4],[4,1],[3,2]]:
		var proof: Dictionary=Bot.new().prove("BELL42",{"columns":shape[0],"rows":shape[1]})
		check(proof.ok,"Scaled block layout "+str(shape)+": "+proof.reason)
		if proof.ok: check(Codec.validate(proof.snapshot),"Scaled dimensions validate: "+str(shape))
	var later: Dictionary=Bot.new().prove("BELL42",{"deep_floors":2,"from_floor":5})
	check(later.ok,"Later Deep floor independently solvable from empty hands")
	if seeds==0: low=0
	print("M5a scaffold: ",checks," checks, ",failures," failures; Deep turns ",low,"-",high)
	quit(1 if failures else 0)
