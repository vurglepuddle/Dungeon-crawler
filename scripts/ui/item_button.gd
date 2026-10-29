extends Button
## Native 16px icons, explicitly centred; never Button's left-aligned icon.
var item_texture: Texture2D
var marked:=false
var ink:=Color("eeb95a")
var verb_icons:=false
var badge: String=""
const Paint=preload("res://scripts/art/presentation_art.gd")
const FONT=preload("res://assets/font/vetka.ttf")
static var _layouts: Dictionary={}
static func verb_layout(word: String,button_size: Vector2) -> Dictionary:
	if _layouts.is_empty(): _layouts=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/verb_layout.json"))
	if word=="PRY": word="CUT" # same measured three-letter stamp, spoken verb stays PRY
	if word=="UNEQUIP":
		return {"icon_path":"assets/art/ui_offer/verb_pack.png","icon_origin":[12,4],"text_origin_godot_top":[26,4]}
	var table: Array=_layouts.cards if button_size.x<=42 else _layouts.buttons
	for entry in table:
		if entry.verb==word: return entry
	return {}
func set_item(texture: Texture2D,selected: bool=false,colour: Color=Color("eeb95a")) -> void:
	item_texture=texture; marked=selected; ink=colour; queue_redraw()
func _draw() -> void:
	if marked:
		for corner in [Vector2(1,1),Vector2(size.x-2,1),Vector2(1,size.y-2),size-Vector2(2,2)]:
			var toward: Vector2=(size/2-corner).sign()
			draw_line(corner,corner+Vector2(toward.x*3,0),ink,1)
			draw_line(corner,corner+Vector2(0,toward.y*3),ink,1)
	if item_texture!=null: draw_texture(item_texture,((size-Vector2(16,16))/2).floor())
	if badge!="":
		var p:=Vector2(size.x-13,size.y-2)
		draw_string(FONT,p+Vector2.ONE,badge,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("0c101c"))
		draw_string(FONT,p,badge,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("efe3ba"))
	if verb_icons:
		var layout: Dictionary=verb_layout(text,size)
		var colour:=Color("eeb95a") if is_hovered() or is_pressed() else Color("d3c8a4")
		if disabled: colour=colour.darkened(0.5)
		if not layout.is_empty():
			draw_texture(Paint.texture("res://"+layout.icon_path),Vector2(layout.icon_origin[0],layout.icon_origin[1]))
			draw_string(FONT,Vector2(layout.text_origin_godot_top[0],layout.text_origin_godot_top[1]+FONT.get_ascent(16)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,colour)
		else:
			var extent:=FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
			draw_string(FONT,((size-extent)/2).floor()+Vector2(0,FONT.get_ascent(16)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,colour)
