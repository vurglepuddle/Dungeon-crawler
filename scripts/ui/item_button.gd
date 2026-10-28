extends Button
## Native 16px icons, explicitly centred; never Button's left-aligned icon.
var item_texture: Texture2D
var marked:=false
var ink:=Color("eeb95a")
func set_item(texture: Texture2D,selected: bool=false,colour: Color=Color("eeb95a")) -> void:
	item_texture=texture; marked=selected; ink=colour; queue_redraw()
func _draw() -> void:
	if marked:
		for corner in [Vector2(1,1),Vector2(size.x-2,1),Vector2(1,size.y-2),size-Vector2(2,2)]:
			var toward: Vector2=(size/2-corner).sign()
			draw_line(corner,corner+Vector2(toward.x*3,0),ink,1)
			draw_line(corner,corner+Vector2(0,toward.y*3),ink,1)
	if item_texture!=null: draw_texture(item_texture,((size-Vector2(16,16))/2).floor())
