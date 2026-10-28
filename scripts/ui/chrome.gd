extends RefCounted
static var _texture: Texture2D
static var _surfaces: Dictionary={}
const Paint=preload("res://scripts/art/presentation_art.gd")
## Buttons retain the original painted bronze. Large surfaces never tile it.
static func surface(kind: String="slate",padding: int=2) -> StyleBox:
	if not _surfaces.has(kind):
		var path: String="res://assets/art/ui/%s.png"%kind
		# The offer's message strip is drawn at its native 150x34 in Main.
		# Large cards/menus have a full, quiet slate source of their own;
		# stretching the small strip there produces metre-long scratches.
		if kind=="card": path="res://assets/art/ui/slate.png"
		_surfaces[kind]=Paint.texture(path)
	var box: StyleBox
	if _surfaces[kind]!=null:
		var painted:=StyleBoxTexture.new(); painted.texture=_surfaces[kind]
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: painted.set_texture_margin(side,4)
		# One continuous painted source, stretched once, never repeated.
		painted.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		painted.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		box=painted
	else:
		var flat:=StyleBoxFlat.new(); flat.bg_color=Color("0f282d")
		flat.border_color=Color("326d71"); flat.set_border_width_all(1); box=flat
	box.content_margin_left=padding; box.content_margin_right=padding
	box.content_margin_top=padding; box.content_margin_bottom=padding
	return box
static func style(padding: int=2,highlight: bool=false) -> StyleBox:
	if _texture==null and ResourceLoader.exists("res://assets/art/chrome_32.png"):
		_texture=load("res://assets/art/chrome_32.png")
	var box: StyleBox
	if _texture!=null:
		var painted:=StyleBoxTexture.new(); painted.texture=_texture
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: painted.set_texture_margin(side,3)
		painted.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		painted.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		painted.modulate_color=Color(1.12,1.06,0.92) if highlight else Color.WHITE
		box=painted
	else:
		var placeholder:=StyleBoxFlat.new(); placeholder.bg_color=Color("312018")
		placeholder.border_color=Color("80643c"); placeholder.set_border_width_all(2); box=placeholder
	box.content_margin_left=padding; box.content_margin_right=padding
	box.content_margin_top=padding; box.content_margin_bottom=padding
	return box
