extends "res://tests/test_m2.gd"
## Boundary cases beyond the two full witness policies.
func _initialize() -> void:
	var proof: Dictionary=Witness.build("BELL42",2,false,"return")
	var sim=Sim.new()
	for action in proof.actions:
		act(sim,action)
		if action.type=="return_item": break
	var bot=Witness.new(); bot.sim=sim
	var lift: Dictionary=fixture(sim,"lift")
	check(bot.go(lift.pos),"Reach restored entrance landing normally")
	var unblocked: Dictionary=sim.snapshot()
	var blocked: Dictionary=unblocked.duplicate(true)
	blocked.floors[1].actors[0].pos=lift.destination.duplicate()
	check(sim.restore_state(blocked),"Authored occupied landing validates")
	var before: String=sim.state_hash()
	check(not sim.apply({"type":"ride","target_id":lift.id}).accepted and sim.state_hash()==before,"Occupied landing rejects before time or state changes")
	check(sim.restore_state(unblocked),"Restore unoccupied landing")
	var actors: Array=sim.snapshot().floors[1].actors.duplicate(true)
	act(sim,{"type":"ride","target_id":lift.id})
	check(sim.snapshot().floor==2 and sim.snapshot().pos==lift.destination,"Lift works from entrance down to deepest landing")
	check(sim.snapshot().floors[1].actors==actors and sim.snapshot().hp==6,"No enemy arrival beat down lift")
	var deep: Dictionary=fixture(sim,"lift")
	act(sim,{"type":"ride","target_id":deep.id})
	check(sim.snapshot().floor==1 and sim.snapshot().pos==lift.pos,"Lift works back up immediately")
	check(Codec.validate(sim.snapshot()),"Bidirectional trip preserves owner graph")
	# It is legal to keep the weapon through the objective, then return it late.
	sim=Sim.new()
	proof=Witness.build("BELL42",2,false,"keep")
	for action in proof.actions:
		if action.type=="leave": break
		act(sim,action)
	check(sim.has_seal() and sim.snapshot().equipment.hand=="bell_clapper","Late return starts with Seal and wielded club")
	bot=Witness.new(); bot.sim=sim
	var porter: Dictionary=fixture(sim,"porter")
	check(bot.go(porter.pos),"Owner still reachable on the way home")
	check(bot._commit({"type":"return_item","target_id":porter.id,"item_id":"bell_clapper"}),"Late equipped return succeeds")
	check(sim.porter_state().restored,"No objective-based restoration expiry")
	var exit: Dictionary=fixture(sim,"exit")
	check(bot.go(exit.pos) and bot._commit({"type":"leave","target_id":exit.id}),"Late restoration can still finish by stairs")
	check(sim.snapshot().status=="won" and Codec.validate(sim.snapshot()),"Late-return ending validates")
	print("M3 lift boundaries: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
