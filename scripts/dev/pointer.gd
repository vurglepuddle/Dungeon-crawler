extends CanvasLayer
## Autoload "Pointer": a pixel-art pointing hand that follows the mouse on
## desktop, drawn inside the game at logical resolution so screen recordings
## show input crisply instead of a smeared OS cursor. Phones get nothing
## (touch needs no cursor). Pilots hide it unless run with --show-pointer, so
## automated screenshots stay unchanged.

const HOTSPOT := Vector2(4, 0) # tip of the index finger
const ART := [
	"....oo......",
	"...owwo.....",
	"...owwo.....",
	"...owwo.....",
	"...owwooo...",
	"...owwowwoo.",
	".oooowwowwoo",
	"owwowwwwwwso",
	"owwwwwwwwwso",
	".owwwwwwwwso",
	"..owwwwwwwso",
	"..owwwwwwsso",
	"...owwwwwso.",
	"...occcccdo.",
	"...occcccdo.",
	"...oooooooo.",
]
const INKS := {
	"o": Color("0d0b14"),
	"w": Color("efe3ba"),
	"s": Color("b6ae91"),
	"c": Color("4c8585"),
	"d": Color("22545a"),
}

var _hand: Sprite2D
var _up: Texture2D
var _down: Texture2D


func _ready() -> void:
	var piloted := Engine.has_meta("pilot") and not OS.get_cmdline_user_args().has("--show-pointer")
	if OS.has_feature("mobile") or DisplayServer.get_name() == "headless" or piloted:
		set_process_input(false) # input can still arrive before the deferred free
		queue_free()
		return
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_up = _texture(false)
	_down = _texture(true)
	_hand = Sprite2D.new()
	_hand.texture = _up
	_hand.centered = false
	_hand.offset = -HOTSPOT
	_hand.visible = false # until the mouse first moves over the window
	add_child(_hand)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if _hand == null:
		return
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_hand.position = event.position.floor()
		_hand.visible = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_hand.texture = _down if event.pressed else _up
	elif event is InputEventScreenTouch:
		_hand.texture = _down if event.pressed else _up


func _notification(what: int) -> void:
	if _hand == null:
		return
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_hand.visible = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		_hand.visible = true


## The pressed hand is a shade darker, like a finger leaning on the glass.
func _texture(pressed: bool) -> Texture2D:
	var image := Image.create(ART[0].length(), ART.size(), false, Image.FORMAT_RGBA8)
	for y in ART.size():
		for x in ART[y].length():
			var key: String = ART[y][x]
			if INKS.has(key):
				var ink: Color = INKS[key]
				if pressed and key in ["w", "s"]:
					ink = ink.darkened(0.18)
				image.set_pixel(x, y, ink)
	return ImageTexture.create_from_image(image)
