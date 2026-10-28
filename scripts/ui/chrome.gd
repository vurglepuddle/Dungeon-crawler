extends RefCounted
static var _texture: Texture2D
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
