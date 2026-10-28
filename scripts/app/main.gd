extends Control
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Art = preload("res://scripts/art/item_art.gd")
const View = preload("res://scripts/view/dungeon_view.gd")
const Chrome=preload("res://scripts/ui/chrome.gd")
const ItemButton=preload("res://scripts/ui/item_button.gd")
const VIEW_RECT:=Rect2(3,21,148,150)
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
var _compass_swing: float=0
var _compass_velocity: float=0
var _music
var _settings_path: String="user://settings.cfg"
var _closing: bool=false

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
	# Pilots/tests keep preferences beside their isolated save, never in the
	# player's settings. Preferences are independent of run-state hashes.
	if Engine.has_meta("pilot") or _save_path!=Store.DEFAULT_PATH:
		_settings_path=_save_path.trim_suffix(".json")+"_settings.cfg"
	if not _save_path.begins_with("user://") or _save_path.contains("..") or not _save_path.ends_with(".json"):
		push_error("Invalid save path"); get_tree().quit(1); return
	view=View.new(); view.position=VIEW_RECT.position; view.size=VIEW_RECT.size; view.clip_contents=true; add_child(view)
	sfx=Sfx.new(); add_child(sfx)
	_music=get_node_or_null("/root/Music")
	_load_settings()
	_build_controls()
	_build_menu()
	_show_menu("title")

func _style(_fill: Color=Color("171d2b"),border: Color=Color("59616a"),padding: int=1) -> StyleBox:
	return Chrome.style(padding,border==GOLD)
func _button(key: String,rect: Rect2,text: String,callback: Callable,parent: Node=null,solid: bool=true) -> Button:
	var button=ItemButton.new()
	button.position=rect.position; button.custom_minimum_size=rect.size; button.size=rect.size
	button.text=text; button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_override("font",FONT); button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_hover_color",GOLD)
	button.add_theme_color_override("font_pressed_color",Color("efe3ba"))
	for key_style in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(key_style,_style() if solid else StyleBoxEmpty.new())
	button.pressed.connect(callback)
	button.button_down.connect(queue_redraw); button.button_up.connect(queue_redraw)
	(parent if parent!=null else self).add_child(button)
	controls[key]=button
	return button
func _label(text: String,parent: Node) -> Label:
	var label:=Label.new()
	label.text=text; label.add_theme_font_override("font",FONT); label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",INK); parent.add_child(label)
	return label
func _build_controls() -> void:
	_button("seed",Rect2(1,0,51,18),"",_open_seed,null,false)
	_button("floor_label",Rect2(98,0,22,18),"",_open_save_status,null,false)
	_button("map",Rect2(121,0,32,18),"MAP",_open_map,null,false)
	_button("portrait",Rect2(3,210,32,32),"",_portrait_help,null,false)
	_button("belt_key",Rect2(101,211,22,22),"",_belt_card.bind("key"),null,false)
	_button("belt_seal",Rect2(127,211,22,22),"",_belt_card.bind("seal"),null,false)
	for slot in ["hand","body"]:
		_button("equip_"+slot,Rect2(43 if slot=="hand" else 71,211,24,32),"",_equipment_card.bind(slot))
	for i in range(8): _button("pack%d"%i,Rect2(1+i*19,246,19,22),"",_select.bind(i),null,false)
	for i in range(3): _button("verb%d"%i,Rect2(2+i*50,269,48,22),"",_verb.bind(i))
	var names: Array=["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]
	for i in range(6): _button(names[i],Rect2(3+(i%3)*26,293+(i/3)*24,24,22),"",_movement.bind(names[i]),null,false)
	_button("compass",Rect2(85,294,66,44),"",_open_map,null,false)
	_button("hot_front",Rect2(0,0,18,18),"",_front_action,null,false)
	_button("hot_item",Rect2(0,0,18,18),"",_take,null,false)
	_button("hot_husk",Rect2(0,0,18,18),"",_look_husk,null,false)
func _build_menu() -> void:
	_menu=Panel.new(); _menu.size=Vector2(154,342)
	_menu.add_theme_stylebox_override("panel",Chrome.surface("slate",8))
	add_child(_menu)
	var column:=VBoxContainer.new(); column.position=Vector2(13,30); column.size=Vector2(128,284)
	column.add_theme_constant_override("separation",12); _menu.add_child(column)
	_label("LOST MOTH / 1993",column)
	_menu_title=_label("UNDERCROFT",column)
	_menu_note=_label("Lost things wait.\nBring one home.",column)
	_button("continue",Rect2(0,0,128,28),"CONTINUE",_continue,column)
	_button("retry",Rect2(0,0,128,28),"RETRY SEED",_retry,column)
	_button("start",Rect2(0,0,128,28),"NEW RUN",_open_seed,column)
	_button("sound",Rect2(0,0,128,24),"SFX ON" if sfx.enabled else "SFX OFF",_toggle_sound,column)
	_button("music",Rect2(0,0,128,24),"MUSIC ON" if _music!=null and _music.enabled else "MUSIC OFF",_toggle_music,column)
func _show_menu(mode: String) -> void:
	_close_modal(); _close_card(); _mode=mode; _busy=0
	for key in controls:
		if is_instance_valid(controls[key]): controls[key].visible=false
	view.visible=false; _menu.visible=true
	controls.start.visible=true; controls.sound.visible=true; controls.music.visible=true
	controls.continue.visible=mode=="title"
	controls.continue.disabled=not Store.can_continue(_save_path)
	controls.retry.visible=mode=="end"
	_menu_title.text="UNDERCROFT" if mode=="title" else ("HOME AGAIN" if state.status=="won" else "LOST PROPERTY")
	_menu_note.text="Lost things wait.\nBring one home." if mode=="title" else ("You brought back dawn.\n%s / %d turns."%[state.seed,state.turn] if state.status=="won" else "The Husk found you.\n%s / try again."%state.seed)
	if _music!=null:
		if mode=="title": _music.play("title")
		elif state.status=="won": _music.play("win")
		else: _music.stop()
	_refresh_save_indicator()
	queue_redraw()
func _toggle_sound() -> void:
	sfx.enabled=not sfx.enabled
	if not sfx.enabled: sfx.stop()
	controls.sound.text="SFX ON" if sfx.enabled else "SFX OFF"
	_save_settings()
func _toggle_music() -> void:
	if _music==null: return
	_music.set_enabled(not _music.enabled)
	controls.music.text="MUSIC ON" if _music.enabled else "MUSIC OFF"
	_save_settings()
func _load_settings() -> void:
	var settings:=ConfigFile.new()
	if settings.load(_settings_path)!=OK: return
	sfx.enabled=bool(settings.get_value("audio","sfx",true))
	if _music!=null: _music.set_enabled(bool(settings.get_value("audio","music",true)))
func _save_settings() -> void:
	var settings:=ConfigFile.new()
	settings.set_value("audio","sfx",sfx.enabled)
	settings.set_value("audio","music",_music.enabled if _music!=null else true)
	# Tests already create this folder through SaveStore; title-only pilot
	# settings also need the parent. No absolute Android path conversion.
	var directory:=DirAccess.open("user://")
	var subfolder: String=_settings_path.trim_prefix("user://").get_base_dir()
	if directory!=null and not subfolder.is_empty(): directory.make_dir_recursive(subfolder)
	settings.save(_settings_path)
func _retry() -> void:
	if _busy<=0 and not state.is_empty(): new_run(state.seed,state.floor_count)
func new_run(raw: String,count: int=2) -> bool:
	var seed:=Gen.normalize_seed(raw)
	if seed.is_empty(): return false
	var proof: Dictionary=Witness.build(seed,count)
	if not proof.ok: push_error("Generation failed: "+proof.reason); return false
	_close_modal(); _close_card()
	sim=Sim.new(seed,count); selected=""; _busy=0; _hurt_time=0; _mode="game"
	_compass_swing=0; _compass_velocity=0
	view.clear_strike()
	if _music!=null: _music.play("floor")
	lines=["Find the Dawn Seal.","Bring it home."]
	_save(true); _sync()
	return true
func _continue() -> void:
	var saved:=Store.load_run(_save_path)
	if saved.is_empty() or saved.payload.status!="playing": return
	var loaded=Sim.new(saved.payload.seed,saved.payload.floor_count)
	if not loaded.restore_state(saved.payload): return
	sim=loaded; _mode="game"; _busy=0; _hurt_time=0
	view.clear_strike()
	if _music!=null: _music.play("floor")
	selected=str(saved.ui.get("selected",""))
	lines=["Your place is kept.","The abbey is waiting."]
	_save_ok=true; _sync()
func _save(fresh: bool=false) -> void:
	if sim==null: return
	_save_ok=Store.save_run(sim,{"selected":selected},_save_path,fresh)
	_refresh_save_indicator()
func _refresh_save_indicator() -> void:
	if not controls.has("floor_label"): return
	controls.floor_label.text=("%d/%d"%[state.floor,state.floor_count]) if _save_ok and state.has("floor") else "!"
	controls.floor_label.add_theme_color_override("font_color",INK if _save_ok else Color("eeb95a"))
	if not _save_ok:
		controls.floor_label.visible=true; controls.floor_label.move_to_front()
	queue_redraw()
func _open_save_status() -> void:
	if _busy>0 or is_instance_valid(_modal): return
	var column:=_panel("Your place",72,210)
	_label("Saved in the abbey." if _save_ok else "Save unavailable.\nRun held in memory.\nTry saving again.",column)
	if not _save_ok: _modal_button("save_retry","RETRY SAVE",_retry_save,column)
	_modal_button("save_close","CLOSE",_close_modal,column)
func _retry_save() -> void:
	_close_modal(); _save(); _open_save_status()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED: _save()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if _closing: return
		_closing=true
		_save()
		_retire_audio()
		get_tree().quit()
func _exit_tree() -> void:
	_retire_audio()
func _retire_audio() -> void:
	# Stop/release scene-owned references before teardown, then give the mixer
	# two short quanta to handle its queued fade. AudioServer garbage collection
	# still needs the next engine frame. The pilot immediately quits after its
	# WM_CLOSE_REQUEST, so an awaited timer here would never finish.
	var had_playback: bool=false
	for source in [sfx,_music]:
		if not is_instance_valid(source): continue
		for child in source.get_children():
			if child is AudioStreamPlayer and child.has_stream_playback():
				had_playback=true
		source.stop()
	if had_playback: OS.delay_msec(50)
func _can_game() -> bool: return _mode=="game" and _busy<=0 and not is_instance_valid(_modal)
func _sync() -> void:
	state=sim.snapshot()
	if not state.items.has(selected) or state.items[selected].location not in ["pack","belt","equip"]: selected=""
	_menu.visible=false; view.visible=true
	for key in ["seed","floor_label","map","portrait","belt_key","belt_seal","equip_hand","equip_body","turn_l","turn_r","fwd","back","strafe_l","strafe_r","compass"]:
		controls[key].visible=true
	controls.seed.text=state.seed; _refresh_save_indicator()
	for i in range(8):
		var button: Button=controls["pack%d"%i]
		button.visible=true; button.text=""
		button.set_item(Art.inventory(state.items[state.pack[i]].kind) if i<state.pack.size() else null,i<state.pack.size() and state.pack[i]==selected,_selection_colour())
	for slot in ["hand","body"]:
		var id: String=state.equipment[slot]
		controls["equip_"+slot].set_item(Art.inventory(state.items[id].kind) if id!="" else null,id!="" and id==selected,_selection_colour())
		controls["equip_"+slot].text=""
	for kind in ["key","seal"]:
		var found:=false
		for id in state.belt:
			if state.items[id].kind==kind: found=true
		controls["belt_"+kind].set_item(Art.inventory(kind) if found else null)
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
	_view_action={}; view.interaction_cues=[]
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
	# Large bodies first; a small possession at their feet wins overlapping taps.
	markers.sort_custom(func(a,b):
		var ra: Rect2=view.projection(a.id).get("rect",Rect2())
		var rb: Rect2=view.projection(b.id).get("rect",Rect2())
		return ra.get_area()>rb.get_area() if ra.get_area()!=rb.get_area() else a.id<b.id)
	for marker in markers:
		var projection: Dictionary=view.projection(marker.id)
		if projection.is_empty(): continue
		var local_rect: Rect2=projection.rect
		var hit_rect:=Rect2(local_rect.get_center()-local_rect.size.max(Vector2(18,18))/2,local_rect.size.max(Vector2(18,18)))
		hit_rect.position.x=clampf(hit_rect.position.x,0,VIEW_RECT.size.x-hit_rect.size.x)
		hit_rect.position.y=clampf(hit_rect.position.y,0,VIEW_RECT.size.y-hit_rect.size.y)
		hit_rect.position+=VIEW_RECT.position
		var button: Button
		if controls.has(marker.key):
			button=controls[marker.key]
			for connection in button.pressed.get_connections(): button.pressed.disconnect(connection.callable)
			button.pressed.connect(marker.callback)
			button.position=hit_rect.position; button.custom_minimum_size=hit_rect.size; button.size=hit_rect.size
		else:
			button=_button(marker.key,hit_rect,"",marker.callback,null,false); _marker_names.append(marker.key)
		button.text=""; button.visible=true; button.move_to_front()
		view.interaction_cues.append({"id":marker.id,"rect":local_rect,"selected":selected!="","colour":_selection_colour() if selected!="" else GOLD})
	view.queue_redraw()

func _selection_colour() -> Color:
	if sim==null or selected=="": return GOLD
	return Art.accent(state.items[selected].kind) if state.items.has(selected) else GOLD
func _command(command: Dictionary) -> void:
	if not _can_game(): return
	_close_card()
	command=command.duplicate(true); command.expected_revision=state.revision
	# Capture the old pose/projection before a fatal hit removes the actor.
	var strike_target: Dictionary={}
	var strike_kind: String="hands"
	if command.type=="hit":
		strike_target=view.projection(command.get("target_id",""))
		var weapon_id: String=state.equipment.hand
		if weapon_id!="":
			var tags: Array=sim.definition(weapon_id).tags
			strike_kind="heavy" if tags.has("HEAVY") else ("edge" if tags.has("EDGE") else "hands")
	var result: Dictionary=sim.apply(command)
	if not result.accepted:
		lines=[result.reason,"Drop or use an item." if result.reason=="Your pack is full." else ""]
		sfx.play("bump"); queue_redraw(); return
	_bob=command.type=="move"
	match command.type:
		"move": sfx.play("step")
		"turn": _compass_velocity+=float(command.delta)*5.5
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
			"struck": view.show_strike(event.target_id,strike_target,strike_kind,event.damage)
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
			"bell_rung": lines=["The hollow ones reel.","One clear beat. HIT."]; sfx.play("ring")
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
	if not fixture.restored: message="My clapper is lost.\nReturn it; I can lift\nyou between landings.\nOr keep it to RING."
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
	var panel:=PanelContainer.new(); panel.position=Vector2(4,208); panel.size=Vector2(146,132)
	panel.add_theme_stylebox_override("panel",Chrome.surface("card",4))
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
	if state.items[id].kind=="clapper": _label("RING: once per floor." if sim.ring_ready() else "RING: spent here.",column)
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
	if state.items[id].kind=="clapper" and state.items[id].location in ["pack","equip"]:
		if row.get_child_count()>=3:
			row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
		_card_button("card_ring","RING",{"type":"ring","item_id":id},row)
		controls.card_ring.disabled=not sim.ring_ready()
	if row.get_child_count()>=3:
		row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
	_button("card_close",Rect2(0,0,42,20),"CLOSE",_dismiss_card,row)
	_card_names.append("card_close")
	add_child(panel); _card=panel; _dock_verbs(true); queue_redraw()
func _card_button(key: String,label: String,action: Dictionary,parent: Node) -> void:
	_button(key,Rect2(0,0,42,20),label,_command.bind(action),parent); _card_names.append(key)
func _dock_verbs(inspecting: bool) -> void:
	for i in range(3):
		if controls.has("verb%d"%i): controls["verb%d"%i].position=Vector2(2+i*50,179 if inspecting else 269)
func _close_card() -> void:
	_dock_verbs(false)
	if is_instance_valid(_card): _card.queue_free(); _card=null
	for key in _card_names: controls.erase(key)
	_card_names=[]
	queue_redraw()
func _dismiss_card() -> void:
	_close_card(); selected=""; _save(); _sync()
func _panel(title: String,top: int=32,height: int=276) -> VBoxContainer:
	_close_modal(); _close_card()
	var panel:=PanelContainer.new(); panel.position=Vector2(5,top); panel.size=Vector2(144,height)
	panel.add_theme_stylebox_override("panel",Chrome.surface("map" if title.begins_with("Visited") else "slate",7))
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
	var column:=_panel("Visited / floor %d"%state.floor,16,324)
	var map=preload("res://scripts/ui/map_view.gd").new()
	map.data=sim.view_snapshot(); map.custom_minimum_size=Vector2(128,231); column.add_child(map)
	_modal_button("map_close","CLOSE",_close_modal,column)
func _process(delta: float) -> void:
	# A damped instrument movement; never part of the simulation or input gate.
	var step: float=minf(delta,0.04)
	_compass_velocity+=(-_compass_swing*100.0-_compass_velocity*12.0)*step
	_compass_swing+=_compass_velocity*step
	if absf(_compass_swing)>0.001 or absf(_compass_velocity)>0.01: queue_redraw()
	if _busy>0:
		_busy=maxf(0,_busy-delta)
		view.motion=sin(_busy/0.13*PI)*1.4 if _bob else 0
		if _busy<=0:
			view.motion=0
			if not state.is_empty() and state.status!="playing": _show_menu("end")
	if _hurt_time>0:
		_hurt_time=maxf(0,_hurt_time-delta)
		view.flash=_hurt_time/0.32
		view.position.x=VIEW_RECT.position.x+(roundi(sin(_hurt_time*100)*2) if _hurt_time>0 else 0)
		view.queue_redraw(); queue_redraw()
	if _busy>0: view.queue_redraw()
func _text(at: Vector2,value: String,colour: Color=INK) -> void:
	draw_string(FONT,at+Vector2(0,FONT.get_ascent(16)),value,HORIZONTAL_ALIGNMENT_LEFT,-1,16,colour)
func _draw() -> void:
	draw_style_box(Chrome.surface("leather"),Rect2(Vector2.ZERO,size))
	if _mode!="game" or state.is_empty(): return
	draw_rect(Rect2(0,0,154,18),Color("0c101c"))
	draw_style_box(Chrome.surface("frame"),Rect2(0,18,154,156))
	draw_style_box(Chrome.surface("slate"),Rect2(0,174,154,34))
	if not is_instance_valid(_card):
		_text(Vector2(4,175),lines[0]); _text(Vector2(4,191),lines[1])
	draw_style_box(Chrome.surface("frame"),Rect2(1,208,36,38))
	var shudder:=Vector2(roundi(sin(_hurt_time*100)*2) if _hurt_time>0 else 0,0)
	draw_texture_rect(PORTRAIT,Rect2(Vector2(3,210)+shudder,Vector2(32,32)),false,Color(1,0.65,0.6) if _hurt_time>0 or state.hp<=2 else Color.WHITE)
	draw_rect(Rect2(3,242,32,3),Color("312018"))
	draw_rect(Rect2(3,242,roundi(32.0*state.hp/state.max_hp),3),Color("73a29a") if state.hp>2 else Color("965c48"))
	if _hurt_time>0:
		draw_rect(Rect2(3,210,32,32),Color("965c48"),false,2)
		for points in [[Vector2(19,224),Vector2(23,226)],[Vector2(26,222),Vector2(29,224)],[Vector2(23,233),Vector2(27,232)]]: draw_line(points[0]+shudder,points[1]+shudder,Color("312018"),1)
	# Belt loops sit behind the possessions; a narrow glass oil gauge makes
	# health read as a physical instrument without stealing an icon pitch.
	for x in [101,127]:
		draw_rect(Rect2(x,209,22,25),Color("312018"))
		for edge in [x,x+20]:
			draw_line(Vector2(edge,211),Vector2(edge,232),Color("80643c"),1)
			draw_rect(Rect2(edge,210,2,2),Color("a18750"))
	draw_rect(Rect2(96,211,5,31),Color("80643c"))
	draw_rect(Rect2(97,213,3,27),Color("0c101c"))
	var oil: int=roundi(25.0*state.hp/state.max_hp)
	draw_rect(Rect2(97,240-oil,3,oil),Color("4c8585") if state.hp>2 else Color("965c48"))
	draw_line(Vector2(97,214),Vector2(97,238),Color("73a29a"),1)
	_text(Vector2(101,232),"HP %d/%d"%[state.hp,state.max_hp])
	# One continuous recessed surface, eight invisible 19px touch pitches.
	draw_style_box(Chrome.surface("leather"),Rect2(0,246,154,22))
	draw_line(Vector2(3,247),Vector2(150,247),Color("5d4b30"),1)
	for x in [4,149]: draw_rect(Rect2(x,249,1,1),Color("a18750"))
	for i in range(8):
		if i>=state.pack.size(): draw_line(Vector2(8+i*19,264),Vector2(11+i*19,264),Color("5d4b30"),1)
	for key in ["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]:
		var button: Button=controls[key]
		draw_style_box(Chrome.style(1,button.is_pressed()),button.get_rect())
		_arrow(button.get_rect().get_center().floor(),key)
	_draw_compass()

func _draw_compass() -> void:
	var rect:=Rect2(85,294,66,44)
	draw_style_box(Chrome.style(),rect)
	var center:=Vector2(118,332)
	draw_arc(center,27,PI,TAU,25,Color("80643c"),2)
	draw_arc(center,23,PI,TAU,25,Color("a18750"),1)
	for index in range(7):
		var angle: float=PI+index*PI/6
		var direction:=Vector2(cos(angle),sin(angle))
		draw_line((center+direction*24).round(),(center+direction*27).round(),GOLD,1)
	var heading: String=["N","E","S","W"][state.facing]
	var width: float=FONT.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	_text(Vector2(roundf(118-width/2),296),heading)
	var needle:=Vector2(sin(_compass_swing),-cos(_compass_swing))
	var side:=Vector2(-needle.y,needle.x)*3
	draw_colored_polygon(PackedVector2Array([(center+needle*16).round(),(center-side).round(),(center+side).round()]),Color("eeb95a"))
	draw_circle(center,2,Color("bc7433"))

func _arrow(center: Vector2,key: String) -> void:
	if key.begins_with("turn"):
		var d: int=-1 if key=="turn_l" else 1
		draw_polyline(PackedVector2Array([center+Vector2(-d*5,6),center+Vector2(-d*5,-4),center+Vector2(d*5,-4)]),GOLD,1)
		draw_colored_polygon(PackedVector2Array([center+Vector2(d*7,-4),center+Vector2(d*2,-8),center+Vector2(d*2,0)]),GOLD)
	else:
		var d:=Vector2(0,-1) if key=="fwd" else (Vector2(0,1) if key=="back" else (Vector2(-1,0) if key=="strafe_l" else Vector2(1,0)))
		var side:=Vector2(-d.y,d.x)
		draw_line(center-d*5,center+d*4,GOLD,1)
		draw_colored_polygon(PackedVector2Array([center+d*7,center+d+side*4,center+d-side*4]),GOLD)
		if key.begins_with("strafe"): draw_line(center-d*7-side*3,center-d*7+side*3,GOLD,1)
func _public_state() -> Dictionary:
	var audio: Dictionary={"music":_music!=null and _music.enabled,"sfx":sfx.enabled}
	if sim==null:
		audio.merge({"status":"title","can_continue":Store.can_continue(_save_path)})
		return audio
	var public: Dictionary={"seed":state.seed,"floor":state.floor,"floor_count":state.floor_count,
		"pos":state.pos.duplicate(),"facing":state.facing,"hp":state.hp,"turn":state.turn,"revision":state.revision,
		"status":state.status,"pack":state.pack.duplicate(),"belt":state.belt.duplicate(),
		"equipment":state.equipment.duplicate(),"selected":selected,"porter":sim.porter_state(),"ring_ready":sim.ring_ready(),"front":sim.inspect_front(),
		"hash":sim.state_hash(),"save_ok":_save_ok}
	public.merge(audio)
	return public
func pilot_call(name_key: String,args: Array) -> String:
	match name_key:
		"busy": return "1" if _busy>0 or is_instance_valid(_modal) else "0"
		"state": return JSON.stringify(_public_state())
		"save_path": return _save_path
		"where":
			if args.is_empty(): return ""
			var key:=str(args[0])
			if key=="sfx": key="sound"
			if key=="view" and _mode=="game": return "77 96"
			if key=="new_seed": key="seed"
			if key=="save_status": key="floor_label"
			if key.ends_with("_object"): key=key.trim_suffix("_object")
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
