extends RefCounted
const Paint=preload("res://scripts/art/presentation_art.gd")
const FRAMES={"fist":["rest","punch"],"knife":["rest","slash"],"shard":["rest","slash"],"club":["rest","blow"],"stone":["rest","blow"],"bone":["rest","blow"],"clapper":["rest","blow","ring"],"lamp":["rest","sway"],"torch_unlit":["rest","use"],"torch_lit":["a","b"],"seal":["a","b"]}
var kind: String="fist"
var action_kind: String=""
var action_frame: String=""
var remaining: float=0
var time: float=0
func set_kind(value: String) -> void: kind=value if FRAMES.has(value) else "fist"
func animate(value: String,action: String) -> void:
	if not FRAMES.has(value): return
	action_kind=value
	action_frame="ring" if value=="clapper" and action=="ring" else FRAMES[value][1]
	remaining=0.45 if action=="ring" else 0.34 # long enough for a human to see the blow land
func advance(delta: float) -> void:
	time=fmod(time+delta,1400.0); remaining=maxf(0,remaining-delta)
func texture() -> Texture2D:
	var chosen: String=action_kind if remaining>0 else kind
	var frame: String=action_frame if remaining>0 else FRAMES[chosen][0]
	if remaining<=0 and chosen in ["seal","torch_lit"]: frame=FRAMES[chosen][int(time/(0.7 if chosen=="seal" else 0.15))%2]
	return Paint.texture("res://assets/art/hands/hand_%s_%s_56.png"%[chosen,frame])
