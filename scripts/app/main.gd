extends Control
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Art = preload("res://scripts/art/item_art.gd")
const View = preload("res://scripts/view/dungeon_view.gd")
const Sfx = preload("res://scripts/audio/sfx.gd")
const FONT = preload("res://assets/font/vetka.ttf")
const PORTRAIT = preload("res://assets/art/finder.png")
const INK := Color("d3c8a4")
const GOLD := Color("eeb95a")
var sim
var state: Dictionary={}
var selected: String=""
var lines: Array=["Find the Dawn Seal.","Bring it home."]
var controls: Dictionary={}
var verbs: Array=[]
var view
var sfx
var _busy: float=0
var _hurt_time: float=0
var _bob: bool=false
var _mode: String="title"
var _save_path: String=Store.DEFAULT_PATH
var _save_ok: bool=true
var _floor_count: int=2
var _modal: Control
var _card: Control
var _dynamic_names: Array=[]
var _card_names: Array=[]
var _menu: Control
var _menu_title: Label
var _menu_note: Label
var _seed_input: LineEdit
var _seed_note: Label
var _view_action: Dictionary={}
var _marker_names: Array=[]
var _item_markers: Dictionary={}

func _ready() -> void:
	clip_contents=true
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().auto_accept_quit=false
	var explicit_save_path: bool=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-path="):
			_save_path=arg.trim_prefix("--save-path="); explicit_save_path=true
		if arg.begins_with("--floors="): _floor_count=clampi(arg.trim_prefix("--floors=").to_int(),1,4)
	if Engine.has_meta("pilot") and not explicit_save_path: _save_path="user://tests/pilot.json"
	if not _save_path.begins_with("user://") or _save_path.contains("..") or not _save_path.ends_with(".json"):
		push_error("Invalid save path"); get_tree().quit(1); return
	view=View.new(); view.size=Vector2(154,118); view.clip_contents=true; add_child(view)
	sfx=Sfx.new(); add_child(sfx)
	_build_controls()
	_build_menu()
	_show_menu("title")

func _style(fill: Color=Color("171d2b"),border: Color=Color("59616a"),padding: int=1) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=fill; box.border_color=border; box.set_border_width_all(1)
	box.content_margin_left=padding; box.content_margin_right=padding
	box.content_margin_top=padding; box.content_margin_bottom=padding
	return box
func _button(key: String,rect: Rect2,text: String,callback: Callable,parent: Node=null,solid: bool=true) -> Button:
	var button:=Button.new()
	button.position=rect.position; button.custom_minimum_size=rect.size; button.size=rect.size
	button.text=text; button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",FONT); button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_hover_color",GOLD)
	button.add_theme_color_override("font_pressed_color",Color("efe3ba"))
	for key_style in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(key_style,_style() if solid else StyleBoxEmpty.new())
	button.pressed.connect(callback)
	(parent if parent!=null else self).add_child(button)
	controls[key]=button
	return button
func _label(text: String,parent: Node) -> Label:
	var label:=Label.new()
	label.text=text; label.add_theme_font_override("font",FONT); label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",INK); parent.add_child(label)
	return label
func _build_controls() -> void:
	_button("seed",Rect2(2,0,51,18),"",_open_seed,null,false)
	_button("floor_label",Rect2(54,0,25,18),"",func(): pass,null,false)
	_button("map",Rect2(80,0,35,18),"MAP",_open_map,null,false)
	_button("new_seed",Rect2(117,0,36,18),"NEW",_open_seed,null,false)
	_button("portrait",Rect2(3,156,32,32),"",_portrait_help,null,false)
	_button("belt_key",Rect2(59,171,18,18),"",_belt_card.bind("key"),null,false)
	_button("belt_seal",Rect2(81,171,18,18),"",_belt_card.bind("seal"),null,false)
	for slot in ["hand","body"]:
		_button("equip_"+slot,Rect2(105 if slot=="hand" else 130,157,21,31),"",_equipment_card.bind(slot))
	for i in range(8): _button("pack%d"%i,Rect2(9+(i%4)*34,192+(i/4)*24,32,22),"",_select.bind(i))
	for i in range(3): _button("verb%d"%i,Rect2(3+i*50,239,48,22),"",_verb.bind(i))
	var names: Array=["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]
	for i in range(6):
		_button(names[i],Rect2(20+(i%3)*41,266+(i/3)*38,32,32),"",_movement.bind(names[i]),null,false)
	_button("hot_front",Rect2(3,91,72,22),"",_front_action)
	_button("hot_item",Rect2(98,91,54,22),"TAKE",_take)
	_button("hot_husk",Rect2(45,35,64,66),"",_look_husk,null,false)
func _build_menu() -> void:
	_menu=Panel.new(); _menu.size=Vector2(154,342)
	_menu.add_theme_stylebox_override("panel",_style(Color("0c101c"),Color("80643c"),8))
	add_child(_menu)
	var column:=VBoxContainer.new(); column.position=Vector2(13,30); column.size=Vector2(128,284)
	column.add_theme_constant_override("separation",12); _menu.add_child(column)
	_label("LOST MOTH / 1993",column)
	_menu_title=_label("UNDERCROFT",column)
	_menu_note=_label("Lost things wait.\nBring one home.",column)
	_button("continue",Rect2(0,0,128,28),"CONTINUE",_continue,column)
	_button("retry",Rect2(0,0,128,28),"RETRY SEED",_retry,column)
	_button("start",Rect2(0,0,128,28),"NEW RUN",_open_seed,column)
	_button("sound",Rect2(0,0,128,24),"SOUND ON",_toggle_sound,column)
func _show_menu(mode: String) -> void:
	_close_modal(); _close_card(); _mode=mode; _busy=0
	for key in controls:
		if is_instance_valid(controls[key]): controls[key].visible=false
	view.visible=false; _menu.visible=true
	controls.start.visible=true; controls.sound.visible=true
	controls.continue.visible=mode=="title"
	controls.continue.disabled=not Store.can_continue(_save_path)
	controls.retry.visible=mode=="end"
	_menu_title.text="UNDERCROFT" if mode=="title" else ("HOME AGAIN" if state.status=="won" else "LOST PROPERTY")
	_menu_note.text="Lost things wait.\nBring one home." if mode=="title" else ("You brought back dawn.\n%s / %d turns."%[state.seed,state.turn] if state.status=="won" else "The Husk found you.\n%s / try again."%state.seed)
	if mode=="end" and not _save_ok: _menu_note.text="Save failed.\nKeep the app open."
	queue_redraw()
func _toggle_sound() -> void:
	sfx.enabled=not sfx.enabled
	controls.sound.text="SOUND ON" if sfx.enabled else "SOUND OFF"
func _retry() -> void:
	if _busy<=0 and not state.is_empty(): new_run(state.seed,state.floor_count)
func new_run(raw: String,count: int=2) -> bool:
	var seed:=Gen.normalize_seed(raw)
	if seed.is_empty(): return false
	var proof: Dictionary=Witness.build(seed,count)
	if not proof.ok: push_error("Generation failed: "+proof.reason); return false
	_close_modal(); _close_card()
	sim=Sim.new(seed,count); selected=""; _busy=0; _hurt_time=0; _mode="game"
	lines=["Find the Dawn Seal.","Bring it home."]
	_save(true); _sync()
	return true
func _continue() -> void:
	var saved:=Store.load_run(_save_path)
	if saved.is_empty() or saved.payload.status!="playing": return
	var loaded=Sim.new(saved.payload.seed,saved.payload.floor_count)
	if not loaded.restore_state(saved.payload): return
	sim=loaded; _mode="game"; _busy=0; _hurt_time=0
	selected=str(saved.ui.get("selected",""))
	lines=["Your place is kept.","The abbey is waiting."]
	_save_ok=true; _sync()
func _save(fresh: bool=false) -> void:
	if sim==null: return
	_save_ok=Store.save_run(sim,{"selected":selected},_save_path,fresh)
	if not _save_ok:
		lines=["Save failed.","Keep the app open."]
		queue_redraw()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED: _save()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		_save()
		if is_instance_valid(sfx): sfx.stop()
		get_tree().quit()
func _can_game() -> bool: return _mode=="game" and _busy<=0 and not is_instance_valid(_modal)
func _sync() -> void:
	state=sim.snapshot()
	if not state.items.has(selected) or state.items[selected].location not in ["pack","belt","equip"]: selected=""
	_menu.visible=false; view.visible=true
	for key in ["seed","floor_label","map","new_seed","portrait","belt_key","belt_seal","equip_hand","equip_body","turn_l","turn_r","fwd","back","strafe_l","strafe_r"]:
		controls[key].visible=true
	controls.seed.text=state.seed; controls.floor_label.text="%d/%d"%[state.floor,state.floor_count]
	for i in range(8):
		var button: Button=controls["pack%d"%i]
		button.visible=true; button.text="" if i<state.pack.size() else "-"
		button.icon=Art.inventory(state.items[state.pack[i]].kind) if i<state.pack.size() else null
		button.add_theme_stylebox_override("normal",_style(Color("263044") if i<state.pack.size() and state.pack[i]==selected else Color("171d2b"),GOLD if i<state.pack.size() and state.pack[i]==selected else Color("59616a")))
	for slot in ["hand","body"]:
		var id: String=state.equipment[slot]
		controls["equip_"+slot].icon=Art.inventory(state.items[id].kind) if id!="" else null
		controls["equip_"+slot].text="" if id!="" else "-"
	for kind in ["key","seal"]:
		var found:=false
		for id in state.belt:
			if state.items[id].kind==kind: found=true
		controls["belt_"+kind].icon=Art.inventory(kind) if found else null
	verbs=sim.legal_verbs(selected)
	for i in range(3):
		controls["verb%d"%i].visible=i<verbs.size()
		controls["verb%d"%i].text=verbs[i].label if i<verbs.size() else ""
	view.update_state(sim.view_snapshot())
	_sync_markers()
	queue_redraw()

func _sync_markers() -> void:
	for key in _marker_names:
		if controls.has(key): controls[key].queue_free(); controls.erase(key)
	_marker_names=[]; _item_markers={}
	for key in ["hot_front","hot_item","hot_husk"]: controls[key].visible=false
	_view_action={}; view.marker_links=[]
	if state.status!="playing": return
	var markers: Array=[]
	var targets: Array=sim.targets(selected)
	if not targets.is_empty():
		for target in targets:
			markers.append({"key":"hot_front" if markers.is_empty() else "hot_"+target.target_id,"id":target.target_id,"label":target.verb,"callback":_command.bind(target.action)})
		_view_action=targets[0].action
	elif selected=="":
		for fixture in sim.fixture_actions():
			if fixture.action.type=="return_item": continue
			var key: String="hot_front" if markers.is_empty() else "hot_"+fixture.action.target_id
			markers.append({"key":key,"id":fixture.action.target_id,"label":fixture.label,"callback":_command.bind(fixture.action)})
			if _view_action.is_empty(): _view_action=fixture.action
	if selected=="":
		var piles: Dictionary={}
		for id in sim.reachable_items():
			var cell_key: String=JSON.stringify(state.items[id].pos)
			if not piles.has(cell_key): piles[cell_key]=[]
			piles[cell_key].append(id)
		for ids in piles.values():
			var key: String="hot_item" if _item_markers.is_empty() else "hot_take_"+ids[0]
			for id in ids: _item_markers[id]=key
			markers.append({"key":key,"id":ids[0],"label":"TAKE","callback":_take_ids.bind(ids)})
		var front: Dictionary=sim.inspect_front()
		if front.monster!="": markers.append({"key":"hot_husk","id":front.monster,"label":"HUSK","callback":_look_husk})
	if selected=="":
		for fixture in sim.local_fixtures():
			if fixture.type=="porter" and not markers.any(func(m): return m.id==fixture.id):
				markers.append({"key":"hot_porter","id":fixture.id,"label":"PORTER","callback":_porter_card.bind(fixture)})
			elif fixture.type=="lift" and not fixture.active:
				markers.append({"key":"hot_"+fixture.id,"id":fixture.id,"label":"ASLEEP","callback":_sleeping_lift})
	markers.sort_custom(func(a,b): return a.id<b.id)
	var occupied: Array=[]
	for marker in markers:
		var projection: Dictionary=view.projection(marker.id)
		if projection.is_empty(): continue
		var anchor: Vector2=projection.anchor
		var width: float=maxf(34,FONT.get_string_size(marker.label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+8)
		var preferred:=Rect2(clampf(anchor.x-width/2,1,153-width),clampf(projection.rect.position.y-19,20,98),width,18)
		var label_rect:=preferred
		if _marker_collides(label_rect,occupied):
			var best:=100000.0
			for y in [20,40,60,80,98]:
				for x in [clampf(anchor.x-width/2,1,153-width),1.0,153-width]:
					var candidate:=Rect2(x,y,width,18)
					var score: float=candidate.get_center().distance_squared_to(preferred.get_center())
					if not _marker_collides(candidate,occupied) and score<best: best=score; label_rect=candidate
		occupied.append(label_rect)
		var hit_rect: Rect2=projection.rect
		hit_rect.size=hit_rect.size.max(Vector2(18,18))
		hit_rect.position.x=clampf(hit_rect.position.x,0,154-hit_rect.size.x)
		hit_rect.position.y=clampf(hit_rect.position.y,19,118-hit_rect.size.y)
		var object_key: String=marker.key+"_object"
		_button(object_key,hit_rect,"",marker.callback,null,false); _marker_names.append(object_key)
		var button: Button
		if controls.has(marker.key):
			button=controls[marker.key]
			for connection in button.pressed.get_connections(): button.pressed.disconnect(connection.callable)
			button.pressed.connect(marker.callback)
			button.position=label_rect.position; button.custom_minimum_size=label_rect.size; button.size=label_rect.size
		else:
			button=_button(marker.key,label_rect,marker.label,marker.callback); _marker_names.append(marker.key)
		button.text=marker.label; button.visible=true; button.move_to_front()
		view.marker_links.append({"from":label_rect.get_center(),"to":anchor})
	# All labels must be above every transparent object hit area.
	for marker in markers:
		if controls.has(marker.key): controls[marker.key].move_to_front()
	view.queue_redraw()

func _marker_collides(rect: Rect2,others: Array) -> bool:
	for other in others:
		if rect.grow(1).intersects(other): return true
	return false
func _command(command: Dictionary) -> void:
	if not _can_game(): return
	_close_card()
	command=command.duplicate(true); command.expected_revision=state.revision
	var result: Dictionary=sim.apply(command)
	if not result.accepted:
		lines=[result.reason,"Drop or use an item." if result.reason=="Your pack is full." else ""]
		sfx.play("bump"); queue_redraw(); return
	lines=["The abbey listens.",""]
	_bob=command.type=="move"
	match command.type:
		"move": lines=["Footsteps in the dust.",""]; sfx.play("step")
		"turn": lines=["Looking is free.",""]
		"pickup":
			var definition: Dictionary=sim.definition(command.item_id)
			lines=[definition.name,definition.provenance]; sfx.play("pickup")
			if definition.slot=="belt": lines=[definition.name,"Take it home." if definition.name=="Dawn Seal" else "Kept safe on the belt."]
		"drop","place": lines=["You set it down.",""]; sfx.play("pickup")
		"equip","unequip": lines=["Equipment changed.",""]; sfx.play("pickup")
		"eat": lines=["A little less weary.",""]; sfx.play("pickup")
		"hit": lines=["Bronze rings.",""]; sfx.play("hit")
		"guard": lines=["You brace yourself.",""]
	for event in result.events:
		match event.type:
			"gate_changed":
				lines=["The gate opens." if event.open else "It shuts behind you.","Leave a HEAVY thing." if not event.open else ""]
				sfx.play("gate")
			"latched": lines=["Latched from this side.","The way stays open."]; sfx.play("gate")
			"unlocked": lines=["The key remembers.","The lock gives way."]; sfx.play("gate")
			"attack_resolved":
				if event.damage>0:
					lines=["Its arm finds you.","GUARD the raised arm."]; _hurt_time=0.32; sfx.play("hit")
				elif event.blocked: lines=["You catch its blow.","It reels. HIT now."]; sfx.play("guard")
				elif event.armour: lines=["The coat takes it.","Its padding is spent."]; _hurt_time=0.15; sfx.play("bump")
				else: lines=["Its blow finds air.","It reels. HIT now."]
			"intent_announced": lines=["A bell arm rises.","GUARD or step away."]; sfx.play("bell")
			"monster_moved": lines=["Heavy footsteps.",""]
			"monster_defeated": lines=["The bell falls silent.","The way is clear."]
			"restored": lines=["A bell finds its voice.","The lift wakes below."]; sfx.play("restore")
			"lift_ride": lines=["Chains sing in the dark.","Floor %d / landing."%event.to]; sfx.play("gate"); selected=""
			"floor_changed": lines=["A different silence.","Floor %d."%event.to]; selected=""
	_busy=0.13 if result.consumed_turn else 0.05
	if _hurt_time>0: _busy=0.24
	state=sim.snapshot()
	if not state.pack.has(selected): selected=""
	_save() # Commit storage before visual animation, including free rotation.
	_sync()
func _movement(key: String) -> void:
	if key in ["turn_l","turn_r"]: _command({"type":"turn","delta":-1 if key=="turn_l" else 1})
	else: _command({"type":"move","step":key})
func _verb(index: int) -> void:
	if not _can_game() or index>=verbs.size(): return
	if verbs[index].action.type=="pickup": _take()
	else: _command(verbs[index].action)
func _front_action() -> void:
	if not _can_game(): return
	if not _view_action.is_empty(): _command(_view_action)
func _sleeping_lift() -> void:
	if _can_game(): lines=["Its chains are still.","The Porter may know."]; queue_redraw()
func _porter_card(fixture: Dictionary) -> void:
	if not _can_game(): return
	var column:=_panel("The Bell Porter",65,240)
	var message: String="My voice is back.\nThe lift is yours."
	if not fixture.restored: message="My clapper is lost.\nReturn it; I can lift\nyou between landings.\nOr keep its HEAVY blow."
	_label(message,column)
	var item: Dictionary=state.items[fixture.item_id]
	if not fixture.restored and item.location in ["pack","equip"]:
		_modal_button("porter_return","RETURN CLAPPER",_return_from_card.bind(fixture),column)
	_modal_button("porter_close","CLOSE",_close_modal,column)
func _return_from_card(fixture: Dictionary) -> void:
	_close_modal(); _command({"type":"return_item","target_id":fixture.id,"item_id":fixture.item_id})
func _look_husk() -> void:
	if _can_game(): lines=["A hollow bell, awake.","GUARD, then HIT it."]; queue_redraw()
func _portrait_help() -> void:
	if _can_game():
		selected=""; _close_card(); _save(); _sync()
		lines=["Curves turn for free.","Straight arrows step."]; queue_redraw()
func _select(index: int) -> void:
	if not _can_game(): return
	if index>=state.pack.size():
		selected=""; _close_card(); _save(); _sync(); return
	selected=state.pack[index]; _save(); _sync(); _open_card(selected)
func _equipment_card(slot: String) -> void:
	if not _can_game(): return
	var id: String=state.equipment[slot]
	if id!="": selected=id; _save(); _sync(); _open_card(id)
func _belt_card(kind: String) -> void:
	if not _can_game(): return
	for id in state.belt:
		if state.items[id].kind==kind: selected=id; _save(); _sync(); _open_card(id); return
func _open_card(id: String) -> void:
	_close_card()
	var panel:=PanelContainer.new(); panel.position=Vector2(4,154); panel.size=Vector2(146,108)
	panel.add_theme_stylebox_override("panel",_style(Color("171d2b"),GOLD,4))
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",0); panel.add_child(column)
	var definition: Dictionary=sim.definition(id)
	_label(definition.name,column)
	var info: String=" ".join(definition.tags)
	if definition.slot=="body": info="Padding spent." if state.items[id].spent else "Blocks 1 hit, once."
	elif definition.slot=="hand": info+=": counter %d"%definition.damage if definition.damage>1 else ": hit 1"
	elif definition.heal>0: info+=": heal %d"%definition.heal
	if info.begins_with(": "): info=info.trim_prefix(": ")
	_label(info,column); _label(definition.provenance,column)
	if definition.has("purpose"): _label(definition.purpose,column)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
	if state.items[id].location=="pack":
		if definition.slot in ["hand","body"]:
			_card_button("card_use","WIELD" if definition.slot=="hand" else "WEAR",{"type":"equip","item_id":id},row)
			if definition.heal>0: _card_button("card_eat","EAT",{"type":"eat","item_id":id},row)
		elif definition.heal>0:
			_card_button("card_use","EAT",{"type":"eat","item_id":id},row)
		_card_button("card_drop","DROP",{"type":"drop","item_id":id},row)
	elif state.items[id].location=="equip":
		_card_button("card_use","PACK",{"type":"unequip","slot":state.items[id].slot},row)
	if row.get_child_count()>=3:
		row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
	_button("card_close",Rect2(0,0,42,22),"CLOSE",_dismiss_card,row)
	_card_names.append("card_close")
	add_child(panel); _card=panel
func _card_button(key: String,label: String,action: Dictionary,parent: Node) -> void:
	_button(key,Rect2(0,0,42,22),label,_command.bind(action),parent); _card_names.append(key)
func _close_card() -> void:
	if is_instance_valid(_card): _card.queue_free(); _card=null
	for key in _card_names: controls.erase(key)
	_card_names=[]
func _dismiss_card() -> void:
	_close_card(); selected=""; _save(); _sync()
func _panel(title: String,top: int=32,height: int=276) -> VBoxContainer:
	_close_modal(); _close_card()
	var panel:=PanelContainer.new(); panel.position=Vector2(5,top); panel.size=Vector2(144,height)
	panel.add_theme_stylebox_override("panel",_style(Color("171d2b"),GOLD,7))
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",7)
	panel.add_child(column); _label(title,column)
	add_child(panel); _modal=panel
	return column
func _modal_button(key: String,label: String,callback: Callable,parent: Node) -> void:
	_button(key,Rect2(0,0,128,24),label,callback,parent); _dynamic_names.append(key)
func _close_modal() -> void:
	if is_instance_valid(_modal): _modal.queue_free(); _modal=null
	for key in _dynamic_names: controls.erase(key)
	_dynamic_names=[]
func _open_seed() -> void:
	if _busy>0 or is_instance_valid(_modal): return
	var column:=_panel("Start a new run?",64,204)
	_label("Replaces this run.",column)
	_seed_input=LineEdit.new(); _seed_input.text=state.get("seed","BELL42"); _seed_input.max_length=6
	_seed_input.custom_minimum_size=Vector2(128,27)
	_seed_input.add_theme_font_override("font",FONT); _seed_input.add_theme_font_size_override("font_size",16)
	_seed_input.add_theme_stylebox_override("normal",_style(Color("0c101c"),Color("59616a"),5))
	column.add_child(_seed_input); controls.seed_input=_seed_input; _dynamic_names.append("seed_input")
	_seed_note=_label("No I, O, 0 or 1.",column)
	_modal_button("seed_start","START",_seed_submit,column)
	_modal_button("seed_random","RANDOM",_random_submit,column)
	_modal_button("seed_cancel","CANCEL",_close_modal,column)
func _seed_submit() -> void:
	if Gen.normalize_seed(_seed_input.text).is_empty():
		_seed_note.text="Invalid seed symbols."; return
	if not new_run(_seed_input.text,_floor_count): _seed_note.text="Floor failed its test."
func _random_submit() -> void:
	var rng:=RandomNumberGenerator.new(); rng.randomize()
	var seed: String=""
	for _i in range(6): seed+=Gen.ALPHABET[rng.randi_range(0,31)]
	if not new_run(seed,_floor_count): _seed_note.text="Floor failed its test."
func _take() -> void:
	if not _can_game(): return
	var loot: Array=sim.reachable_items()
	if loot.size()==1: _command({"type":"pickup","item_id":loot[0]}); return
	if loot.is_empty(): return
	_loot_page(loot,0)
func _take_ids(ids: Array) -> void:
	if not _can_game() or ids.is_empty(): return
	if ids.size()==1: _command({"type":"pickup","item_id":ids[0]})
	else: _loot_page(ids,0)
func _loot_page(loot: Array,page: int) -> void:
	var column:=_panel("Take which thing?",32,280)
	column.add_theme_constant_override("separation",4)
	for id in loot.slice(page*6,mini(loot.size(),page*6+6)):
		_modal_button("loot_"+id,sim.definition(id).name,_choose_loot.bind(id),column)
	if loot.size()>6:
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",6); column.add_child(row)
		if page>0:
			_button("loot_prev",Rect2(0,0,61,24),"PREV",_loot_page.bind(loot,page-1),row); _dynamic_names.append("loot_prev")
		if (page+1)*6<loot.size():
			_button("loot_next",Rect2(0,0,61,24),"NEXT",_loot_page.bind(loot,page+1),row); _dynamic_names.append("loot_next")
	_modal_button("loot_cancel","CANCEL",_close_modal,column)
func _choose_loot(id: String) -> void:
	_close_modal(); _command({"type":"pickup","item_id":id})
func _open_map() -> void:
	if not _can_game(): return
	var column:=_panel("Visited / floor %d"%state.floor,16,310)
	var map=preload("res://scripts/ui/map_view.gd").new()
	map.data=sim.view_snapshot(); map.custom_minimum_size=Vector2(128,231); column.add_child(map)
	_modal_button("map_close","CLOSE",_close_modal,column)
func _process(delta: float) -> void:
	if _busy>0:
		_busy=maxf(0,_busy-delta)
		view.motion=sin(_busy/0.13*PI)*1.4 if _bob else 0
		if _busy<=0:
			view.motion=0
			if not state.is_empty() and state.status!="playing": _show_menu("end")
	if _hurt_time>0:
		_hurt_time=maxf(0,_hurt_time-delta)
		view.flash=_hurt_time/0.32
		view.position.x=roundi(sin(_hurt_time*100)*2) if _hurt_time>0 else 0
		view.queue_redraw(); queue_redraw()
	if _busy>0: view.queue_redraw()
func _text(at: Vector2,value: String,colour: Color=INK) -> void:
	draw_string(FONT,at+Vector2(0,FONT.get_ascent(16)),value,HORIZONTAL_ALIGNMENT_LEFT,-1,16,colour)
func _draw() -> void:
	draw_rect(Rect2(0,0,154,342),Color("0c101c"))
	if _mode!="game" or state.is_empty(): return
	for y in [118,154,190,238,262]: draw_line(Vector2(0,y),Vector2(154,y),Color("59616a"))
	_text(Vector2(4,119),lines[0]); _text(Vector2(4,135),lines[1])
	draw_texture_rect(PORTRAIT,Rect2(3,156,32,32),false,Color(1,0.65,0.6) if _hurt_time>0 or state.hp<=2 else Color.WHITE)
	if _hurt_time>0:
		draw_rect(Rect2(3,156,32,32),Color("965c48"),false,2)
		for points in [[Vector2(19,170),Vector2(23,172)],[Vector2(26,168),Vector2(29,170)],[Vector2(23,179),Vector2(27,178)]]:
			draw_line(points[0],points[1],Color("312018"),1)
	_text(Vector2(41,155),"HP %d/%d"%[state.hp,state.max_hp])
	_text(Vector2(41,172),["N","E","S","W"][state.facing])
	for key in ["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]:
		var button: Button=controls[key]; var rect:=button.get_rect()
		draw_rect(rect,Color("263044") if button.is_pressed() else Color("171d2b"))
		draw_rect(rect,Color("80643c") if key.begins_with("turn") else Color("59616a"),false)
		_arrow(rect.get_center(),key)
func _arrow(center: Vector2,key: String) -> void:
	var colour:=GOLD if key.begins_with("turn") else Color("a8c2ad")
	if key.begins_with("turn"):
		var d: int=-1 if key=="turn_l" else 1
		draw_polyline(PackedVector2Array([center+Vector2(-d*7,8),center+Vector2(-d*7,-6),center+Vector2(d*7,-6)]),colour,2)
		draw_colored_polygon(PackedVector2Array([center+Vector2(d*9,-6),center+Vector2(d*2,-11),center+Vector2(d*2,-1)]),colour)
	else:
		var d:=Vector2(0,-1) if key=="fwd" else (Vector2(0,1) if key=="back" else (Vector2(-1,0) if key=="strafe_l" else Vector2(1,0)))
		var side:=Vector2(-d.y,d.x)
		draw_line(center-d*8,center+d*6,colour,2)
		draw_colored_polygon(PackedVector2Array([center+d*11,center+d*3+side*5,center+d*3-side*5]),colour)
		if key.begins_with("strafe"): draw_line(center-d*10-side*6,center-d*10+side*6,colour,2)
func _public_state() -> Dictionary:
	if sim==null: return {"status":"title","can_continue":Store.can_continue(_save_path)}
	var public: Dictionary={"seed":state.seed,"floor":state.floor,"floor_count":state.floor_count,
		"pos":state.pos.duplicate(),"facing":state.facing,"hp":state.hp,"turn":state.turn,"revision":state.revision,
		"status":state.status,"pack":state.pack.duplicate(),"belt":state.belt.duplicate(),
		"equipment":state.equipment.duplicate(),"selected":selected,"porter":sim.porter_state(),"front":sim.inspect_front(),
		"hash":sim.state_hash(),"save_ok":_save_ok}
	return public
func pilot_call(name_key: String,args: Array) -> String:
	match name_key:
		"busy": return "1" if _busy>0 or is_instance_valid(_modal) else "0"
		"state": return JSON.stringify(_public_state())
		"save_path": return _save_path
		"where":
			if args.is_empty(): return ""
			var key:=str(args[0])
			if key=="view" and _mode=="game": return "77 63"
			if key.begins_with("hot_item_"):
				key=_item_markers.get(key.trim_prefix("hot_item_"),key)
			if key in ["hot_plate","hot_exit","hot_stairs","hot_latch"]: key="hot_front"
			if controls.has(key) and is_instance_valid(controls[key]) and controls[key].is_visible_in_tree() and not (controls[key] is Button and controls[key].disabled):
				var center: Vector2=controls[key].get_global_rect().get_center()
				return "%d %d"%[roundi(center.x),roundi(center.y)]
			return ""
		"new_run":
			if args.is_empty() or not new_run(str(args[0]),int(args[1]) if args.size()>1 else _floor_count): return JSON.stringify({"error":"Invalid seed or floor."})
			return JSON.stringify(_public_state())
		"assert":
			if args.size()<2: return "error"
			var actual = _public_state().get(str(args[0]))
			var expected:=str(args[1])
			if actual is String and expected.begins_with('"'):
				var decoded = JSON.parse_string(expected)
				if decoded is String: expected=decoded
			var value: String=str(actual) if actual is String else JSON.stringify(actual)
			if value!=expected:
				push_error("Pilot assertion %s expected %s got %s"%[args[0],expected,value])
				get_tree().quit.call_deferred(1); return "failed"
			return "ok"
	return ""
