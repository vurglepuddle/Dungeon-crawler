extends SceneTree
const Ambience = preload("res://scripts/fx/ambience.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var fx = Ambience.new()
	var twin = Ambience.new()
	root.add_child(fx)
	root.add_child(twin)
	fx.set_process(false)
	twin.set_process(false)
	var completions: Array = []
	fx.fade_finished.connect(func(dark: bool): completions.append(dark))
	fx.set_view_rect(Rect2(151, 171, -148, -150))
	check(fx.view_rect == Rect2(3, 21, 148, 150), "View rectangle normalizes to local positive bounds")
	fx.set_floor(2)
	check(fx.floor_index == 2, "Lower floor enables water presentation")
	fx.set_floor(-1)
	check(fx.floor_index == 1, "Invalid floor clamps safely")
	fx.fade_out(0.2)
	fx._process(0.1)
	check(is_equal_approx(fx.fade_alpha(), 0.5), "Stair midpoint is half black")
	fx.fade_in(0.2)
	fx._process(0.1)
	check(is_equal_approx(fx.fade_alpha(), 0.25), "Reversing starts at the current fade")
	fx._process(1.0)
	check(fx.fade_alpha() == 0.0 and completions == [false], "Reversed fade finishes once without stale dark completion")
	fx.fade_out(0.0)
	check(fx.fade_alpha() == 1.0 and completions == [false, true], "Instant blackout completes synchronously")
	fx.fade_in(-1.0)
	check(fx.fade_alpha() == 0.0, "Negative fade time is immediate")
	fx.flash(Color.WHITE, 0.2, 8.0)
	check(fx._flash_amount == 0.35, "Flash strength is capped")
	fx._process(0.3)
	check(fx._flash_left == 0.0, "Flash clears after its duration")
	fx.flash(Color.WHITE, 0.0)
	check(fx._flash_left == 0.0, "Zero-time flash is safe")
	# Equal time and settings produce equal effects, without touching global RNG.
	fx._clock = 0.0
	twin._clock = 0.0
	for i in range(80):
		fx._process(0.05)
		twin._process(0.05)
		check(is_equal_approx(fx.lamp_gain(), twin.lamp_gain()), "Deterministic lamp phase")
		check(fx.lamp_gain() >= 0.977 and fx.lamp_gain() <= 0.993, "Lamp modulation remains subtle")
	fx.lamp_flicker_enabled = false
	check(fx.lamp_gain() == 1.0, "Lamp motion can be disabled")
	fx.set_view_rect(Rect2())
	await process_frame # Empty rectangle must also be safe during drawing.
	fx.free()
	twin.free()
	print("FX: %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
