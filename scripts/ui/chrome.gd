extends RefCounted
static var _texture: Texture2D
static var _surfaces: Dictionary={}
const Paint=preload("res://scripts/art/presentation_art.gd")
## Buttons retain the original painted bronze. Large surfaces never tile it.
## Surfaces drop their sources' painted bevel (outer 4 px): the owner found its
## yellow/teal edge lines dated on screens, menus and cards alike.
static func surface(kind: String="slate",padding: int=2) -> StyleBox:
	if not _surfaces.has(kind):
		var path: String="res://assets/art/ui/%s.png"%kind
		# The offer's message strip is drawn at its native 150x34 in Main.
		# Large cards/menus have a full, quiet slate source of their own;
		# stretching the small strip there produces metre-long scratches.
		if kind=="card": path="res://assets/art/ui/slate.png"
		_surfaces[kind]=Paint.texture(path)
	var box:=StyleBoxTexture.new(); box.texture=_surfaces[kind]
	box.region_rect=Rect2(Vector2(4,4),box.texture.get_size()-Vector2(8,8))
	box.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.content_margin_left=padding; box.content_margin_right=padding
	box.content_margin_top=padding; box.content_margin_bottom=padding
	return box
static func style(padding: int=2,highlight: bool=false) -> StyleBox:
	if _texture==null: _texture=Paint.texture("res://assets/art/chrome_32.png")
	var box:=StyleBoxTexture.new(); box.texture=_texture
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: box.set_texture_margin(side,3)
	box.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.modulate_color=Color(1.12,1.06,0.92) if highlight else Color.WHITE
	box.content_margin_left=padding; box.content_margin_right=padding
	box.content_margin_top=padding; box.content_margin_bottom=padding
	return box
