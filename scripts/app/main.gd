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
const Paint=preload("res://scripts/art/presentation_art.gd")
const Flavour=preload("res://scripts/art/flavour.gd")
const Survey=preload("res://scripts/ui/survey.gd")
const Ambience=preload("res://scripts/fx/ambience.gd")
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
var _survey=Survey.new()
var _ambience
var _transitioning: bool=false
var _transition_token: int=0
var _menu_art: TextureRect
var _menu_receipt: Label
var _splash_time: float=0
var _tossing: String=""
var _menu_clock: float=0
var _logo: TextureRect
var _optional_overlay: TextureRect
const OPTIONAL_OVERLAY="res://assets/art/ui_offer/owner_overlay.png"

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
	_ambience=Ambience.new(); _ambience.set_view_rect(VIEW_RECT); add_child(_ambience)
	sfx=Sfx.new(); add_child(sfx)
	_music=get_node_or_null("/root/Music")
	_load_settings()
	_build_controls()
	# The owner's cleaned PNG can be dropped here later. No backup vine art is
	# enabled implicitly. This single layer stays below cards and modals.
	_optional_overlay=TextureRect.new(); _optional_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_optional_overlay.size=Vector2(154,342); _optional_overlay.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(OPTIONAL_OVERLAY) or FileAccess.file_exists(OPTIONAL_OVERLAY): _optional_overlay.texture=Paint.texture(OPTIONAL_OVERLAY)
	add_child(_optional_overlay)
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
	if key.begins_with("verb") or key.begins_with("card_"):
		button.verb_icons=true
		for theme_key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]: button.add_theme_color_override(theme_key,Color.TRANSPARENT)
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
	_button("map",Rect2(121,0,32,18),"MAP",_open_map)
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
	_menu_art=TextureRect.new(); _menu_art.position=Vector2(0,20); _menu_art.size=Vector2(154,150)
	_menu_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; _menu_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_menu.add_child(_menu_art)
	_logo=TextureRect.new(); _logo.position=Vector2(7,26); _logo.size=Vector2(140,40)
	_logo.texture=Paint.texture("res://assets/art/screens/logotype_140.png"); _logo.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_menu.add_child(_logo)
	_menu_title=_label("UNDERCROFT",_menu); _menu_title.position=Vector2(3,179); _menu_title.size=Vector2(148,18); _menu_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_menu_note=_label("Lost things wait.\nBring one home.",_menu); _menu_note.position=Vector2(4,202); _menu_note.size=Vector2(146,34); _menu_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_menu_receipt=_label("",_menu); _menu_receipt.position=Vector2(3,156); _menu_receipt.size=Vector2(148,18); _menu_receipt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_button("continue",Rect2(13,244,128,26),"CONTINUE",_continue,_menu)
	_button("retry",Rect2(13,244,128,26),"RETRY SEED",_retry,_menu)
	_button("start",Rect2(13,276,128,26),"NEW RUN",_open_seed,_menu)
	_button("sound",Rect2(3,312,72,24),"SFX ON" if sfx.enabled else "SFX OFF",_toggle_sound,_menu)
	_button("music",Rect2(79,312,72,24),"MUSIC ON" if _music!=null and _music.enabled else "MUSIC OFF",_toggle_music,_menu)
	_button("splash_skip",Rect2(0,20,154,150),"",_skip_splash,_menu,false)
func _skip_splash() -> void:
	_splash_time=0; controls.splash_skip.visible=false
	_menu_clock=0; _logo.visible=true
	_update_menu_art()
func _update_menu_art() -> void:
	var ms: int=int(_menu_clock*1000)
	var family: String; var frame: int
	if _mode=="title":
		if _splash_time>0: family="splash_flutter"; frame=0 if ms%1200<900 else 1
		else: family="title_flicker"; frame=0 if ms%1080<680 else (1 if ms%1080<840 else 2)
	else:
		family="win_dawn" if state.status=="won" else "death_gutter"
		frame=(0 if ms<500 else (1 if ms<1150 else 2)) if state.status=="won" else (0 if ms<400 else (1 if ms<1100 else 2))
	_menu_art.texture=Paint.texture("res://assets/art/screens/%s_%d.png"%[family,frame])
func _show_menu(mode: String) -> void:
	_close_modal(); _close_card(); _mode=mode; _busy=0
	_menu_clock=0; _logo.visible=false
	_transition_token+=1; _transitioning=false
	_ambience.fade_in(0); _ambience.visible=false; _ambience.set_process(false)
	for key in controls:
		if is_instance_valid(controls[key]): controls[key].visible=false
	view.visible=false; _menu.visible=true
	_optional_overlay.visible=false
	controls.start.visible=true; controls.sound.visible=true; controls.music.visible=true
	controls.continue.visible=mode=="title"
	controls.continue.disabled=not Store.can_continue(_save_path)
	controls.retry.visible=mode=="end"
	_menu_receipt.visible=mode=="end"
	if mode=="title":
		_menu_art.position=Vector2(0,20); _menu_art.size=Vector2(154,150)
		_menu_art.texture=Paint.texture("res://assets/art/screens/splash.png"); _splash_time=1.4; controls.splash_skip.visible=true
	else:
		_menu_art.position=Vector2(13,62); _menu_art.size=Vector2(128,80)
		_menu_art.texture=Paint.texture("res://assets/art/screens/%s.png"%("win" if state.status=="won" else "death"))
		_menu_receipt.text="%s / %d turns"%[state.seed,state.turn]
	_menu_title.text="UNDERCROFT" if mode=="title" else ("HOME AGAIN" if state.status=="won" else "LOST PROPERTY")
	_menu_note.text="Lost things wait.\nBring one home." if mode=="title" else ("You brought back dawn.\n%s / %d turns."%[state.seed,state.turn] if state.status=="won" else "The Husk found you.\n%s / try again."%state.seed)
	if mode=="end" and state.status=="lost": _menu_note.text=Flavour.epitaph(state.seed,state.turn)
	if mode=="end" and state.status=="won": _menu_note.text="You brought back dawn.\nSomething returned."
	if _music!=null:
		if mode=="title": _music.play("title")
		elif state.status=="won": _music.play("win")
		else: _music.play("death")
	_refresh_save_indicator()
	_update_menu_art()
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
	_survey.reset(count); _reset_presentation()
	_compass_swing=0; _compass_velocity=0
	view.clear_strike()
	if _music!=null: _music.play("floor")
	lines=[Flavour.floor_name(1),"Find the Dawn Seal."]
	_sync(); _save(true)
	return true
func _continue() -> void:
	var saved:=Store.load_run(_save_path)
	if saved.is_empty() or saved.payload.status!="playing": return
	var loaded=Sim.new(saved.payload.seed,saved.payload.floor_count)
	if not loaded.restore_state(saved.payload): return
	sim=loaded; _mode="game"; _busy=0; _hurt_time=0
	_survey.restore(saved.ui.get("survey",{}),saved.payload); _reset_presentation()
	view.clear_strike()
	if _music!=null: _music.play("floor2" if saved.payload.floor>1 else "floor")
	selected=str(saved.ui.get("selected",""))
	lines=["Your place is kept.","The abbey is waiting."]
	_save_ok=true; _sync()
func _save(fresh: bool=false) -> void:
	if sim==null: return
	_save_ok=Store.save_run(sim,{"selected":selected,"survey":_survey.save()},_save_path,fresh)
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
		_transition_token+=1; _transitioning=false
		if is_instance_valid(_ambience): _ambience.fade_in(0)
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
func _can_game() -> bool: return _mode=="game" and _busy<=0 and not _transitioning and not is_instance_valid(_modal)
func _reset_presentation() -> void:
	_tossing=""; view.toss_lane=[]
	_transition_token+=1; _transitioning=false
	_ambience.fade_in(0); _ambience.visible=true; _ambience.set_process(true)
func _capture_survey() -> void:
	var picture: Dictionary=sim.view_snapshot()
	view.update_state(picture)
	_survey.observe(state.floor,view.visible_cells(),state.pos,view.visible_landmarks())
func _sync() -> void:
	state=sim.snapshot()
	if not state.items.has(selected) or state.items[selected].location not in ["pack","belt","equip"]: selected=""
	_menu.visible=false; view.visible=true
	_optional_overlay.visible=true
	for key in ["seed","floor_label","map","portrait","belt_key","belt_seal","equip_hand","equip_body","turn_l","turn_r","fwd","back","strafe_l","strafe_r","compass"]:
		controls[key].visible=true
	controls.seed.text=state.seed; _refresh_save_indicator()
	for i in range(8):
		var button: Button=controls["pack%d"%i]
		button.visible=true; button.text=""
		button.set_item(_item_icon(state.pack[i]) if i<state.pack.size() else null,i<state.pack.size() and state.pack[i]==selected,_selection_colour())
	for slot in ["hand","body"]:
		var id: String=state.equipment[slot]
		controls["equip_"+slot].set_item(_item_icon(id) if id!="" else null,id!="" and id==selected,_selection_colour())
		controls["equip_"+slot].text=""
	for kind in ["key","seal"]:
		var count:=0
		for id in state.belt:
			if state.items[id].kind==kind: count+=1
		controls["belt_"+kind].set_item(Art.inventory(kind) if count>0 else null)
		controls["belt_"+kind].badge="x%d"%count if count>1 else ""
	verbs=sim.legal_verbs(selected)
	view.toss_lane=[]
	if _tossing!="":
		var lane: Dictionary=sim.toss_preview(_tossing); view.toss_lane=lane.cells
		verbs=[{"label":"TOSS","action":{"type":"toss","item_id":_tossing}},{"label":"CANCEL","action":{"type":"cancel_toss"}}]
	for i in range(3):
		controls["verb%d"%i].visible=i<verbs.size()
		controls["verb%d"%i].disabled=_tossing!="" and i==0 and sim.toss_preview(_tossing).landing.is_empty()
		controls["verb%d"%i].text=verbs[i].label if i<verbs.size() else ""
	_capture_survey()
	view.held.set_kind(_held_kind())
	_ambience.set_floor(state.floor)
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
			markers.append({"key":"hot_front" if markers.is_empty() else "hot_"+target.target_id,"id":target.target_id,"label":target.verb,"callback":_open_toss.bind(target.action.item_id) if target.action.type=="toss" else _command.bind(target.action)})
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
			elif fixture.type in ["brazier","web","cord","panel"]:
				markers.append({"key":"hot_"+fixture.id,"id":fixture.id,"label":"LOOK","callback":_inspect_capability.bind(fixture)})
		for actor in state.floors[state.floor-1].actors:
			if actor.kind in ["hound","ghost"] and actor.hp>0 and absi(actor.pos[0]-state.pos[0])+absi(actor.pos[1]-state.pos[1])<=3:
				markers.append({"key":"hot_"+actor.id,"id":actor.id,"label":"LOOK","callback":_inspect_creature.bind(actor.id)})
	if selected!="":
		for entry in sim.fixture_actions():
			if entry.action.type in ["stairs","squeeze","ride","leave"] and not markers.any(func(m): return m.id==entry.action.target_id):
				markers.append({"key":"hot_"+entry.action.target_id,"id":entry.action.target_id,"label":entry.label,"callback":_command.bind(entry.action)})
		for fixture in sim.local_fixtures():
			if fixture.type=="lift" and not fixture.active:
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
		var item_target: bool=selected!="" and targets.any(func(t): return t.target_id==marker.id)
		view.interaction_cues.append({"id":marker.id,"rect":local_rect,"selected":item_target,"threshold":marker.label in ["DOWN","UP","RIDE","ASLEEP","LEAVE","SIDLE"],"colour":_selection_colour() if item_target else GOLD})
	view.queue_redraw()

func _selection_colour() -> Color:
	if sim==null or selected=="": return GOLD
	return Art.accent(state.items[selected].kind) if state.items.has(selected) else GOLD
func _item_icon(id: String) -> Texture2D:
	var item: Dictionary=state.items[id]
	if item.kind=="torch": return Paint.texture("res://assets/art/fixtures/reed_torch_icon_%s_16.png"%("lit" if item.lit else "unlit"))
	return Art.inventory(item.kind)
func _held_kind(id: String="") -> String:
	if id=="":
		id=selected if state.items.has(selected) and state.items[selected].kind in ["torch","lamp","seal"] else ""
		if id=="" and sim.has_seal(): return "seal"
		if id=="": id=state.equipment.hand
	if id=="" or not state.items.has(id): return "fist"
	var item: Dictionary=state.items[id]
	return "torch_lit" if item.kind=="torch" and item.lit else ("torch_unlit" if item.kind=="torch" else item.kind)
func _open_toss(id: String) -> void:
	if not _can_game(): return
	_close_card(); _tossing=id; selected=id
	lines=["Toss up to two steps.","Turn; TOSS to release."]; _sync()
func _cancel_toss() -> void:
	_tossing=""; _sync()
func _inspect_capability(fixture: Dictionary) -> void:
	if not _can_game(): return
	var column:=_panel({"brazier":"Banked coals","web":"Old web","cord":"Cord-bound grate","panel":"A scored dawn"}[fixture.type],62,242)
	var note: String={"brazier":"LIGHT a reed torch.\nThe coals keep burning.","web":"Dry silk blocks it.\nA FIRE would clear it.","cord":"A stout knot holds it.\nAn EDGE would cut it.","panel":"Dawn wakes the scar.\nAn EDGE can lift it."}[fixture.type]
	_label(note,column); _modal_button("fixture_close","CLOSE",_close_modal,column)
func _command(command: Dictionary) -> void:
	if not _can_game(): return
	_close_card()
	if command.type!="turn": _tossing=""
	var old_picture: Dictionary=view.state.duplicate(true)
	command=command.duplicate(true); command.expected_revision=state.revision
	# Capture the old pose/projection before a fatal hit removes the actor.
	var strike_target: Dictionary={}
	var strike_kind: String="hands"
	var hand_kind: String=_held_kind(command.get("item_id","") if command.type!="hit" else state.equipment.hand)
	if command.type=="hit" and state.equipment.hand=="": hand_kind="fist"
	if command.type=="hit":
		strike_target=view.projection(command.get("target_id",""))
		var weapon_id: String=state.equipment.hand
		if weapon_id!="":
			var tags: Array=sim.definition(weapon_id).tags
			strike_kind="heavy" if tags.has("HEAVY") else ("edge" if tags.has("EDGE") else "hands")
	elif command.type=="toss":
		strike_target=view.projection(sim.toss_preview(command.get("item_id","")).actor_id)
		if sim.definition(command.get("item_id","")).get("tags",[]).has("HEAVY"): strike_kind="heavy"
	var result: Dictionary=sim.apply(command)
	if not result.accepted:
		lines=[result.reason,"Drop or use an item." if result.reason=="Your pack is full." else ""]
		if result.reason=="The lift is dead.": lines[1]="Its bell has no voice."
		sfx.play("bump"); queue_redraw(); return
	if command.type in ["hit","ring","light","burn","cut","toss","dispel","place"]: view.held.animate(hand_kind,command.type)
	_bob=command.type=="move"
	match command.type:
		"move": sfx.play("step")
		"turn": _compass_velocity+=float(command.delta)*5.5
		"pickup":
			var definition: Dictionary=sim.definition(command.item_id)
			lines=[definition.name,Flavour.provenance(state.items[command.item_id].kind,definition.provenance)]; sfx.play("pickup")
			if definition.slot=="belt": lines=[definition.name,"Take it home." if definition.name=="Dawn Seal" else "Kept safe on the belt."]
			if definition.name=="Dawn Seal": selected=""
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
			"floor_changed": lines=[Flavour.floor_name(event.to),"Floor %d."%event.to]; selected=""
			"landing_skirted": lines=["You slip past a shape.","A clear step beside it."]
			"torch_lit": lines=["The reeds catch fire.","FIRE / GLOW. No fuel."]; sfx.play("pickup")
			"web_burnt": lines=["The dry web catches.","The way stays clear."]; view.show_burn(event.target_id); sfx.play("gate")
			"cord_cut": lines=["The cords fall away.","The grate hangs open."]; sfx.play("gate")
			"hound_fed": lines=["It takes the offering.","Warm ash. Quiet jaws."]; sfx.play("pickup")
			"ghost_dispelled": lines=["The wick gutters out.","Your light stays."]; view.show_dispel(event.actor_id); sfx.play("pickup")
			"item_tossed":
				if not result.events.any(func(e): return e.type in ["hound_fed","ghost_dispelled","web_burnt"]): lines=["It arcs through air.","The floor keeps it."]
				sfx.play("pickup")
			"panel_revealed":
				if not result.events.any(func(e): return e.type=="attack_resolved" and e.damage>0): lines=["Dawn finds an old scar.","An EDGE can lift it."]
			"secret_found": lines=["A hidden cache opens.","Something left behind."]; sfx.play("pickup")
		if event.type=="intent_announced":
			var creature: String=sim._actor(event.actor_id).kind
			if creature=="hound": lines=["It crouches. Two steps.","Sidestep or GUARD."]
			elif creature=="ghost": lines=["Its wick flares cold.","GLOW / GUARD."]
		if event.type=="attack_resolved" and event.damage>0:
			var creature: String=sim._actor(event.actor_id).kind
			if creature=="hound": lines=["The lunge finds you.","Leave the marked lane."]
			elif creature=="ghost": lines=["The cold finds you.","GLOW clears the wick."]
	_busy=0.13 if result.consumed_turn else 0.05
	if _hurt_time>0: _busy=0.24
	state=sim.snapshot()
	if not state.pack.has(selected): selected=""
	if command.type in ["burn","cut","feed","dispel","reveal"]: selected=""
	var travel: bool=result.events.any(func(e): return e.type in ["floor_changed","lift_ride"])
	if travel:
		_capture_survey(); _save()
		view.update_state(old_picture)
		_start_transition()
	else:
		_sync(); _save() # Geometry/knowledge capture is synchronous; save still precedes animation.
func _start_transition() -> void:
	_transitioning=true; _busy=1.0
	_transition_token+=1
	var token: int=_transition_token
	_ambience.fade_out(0.12)
	await _ambience.fade_finished
	if token!=_transition_token or not is_inside_tree(): return
	_sync()
	if _music!=null: _music.play("floor2" if state.floor>1 else "floor")
	_ambience.fade_in(0.18)
	await _ambience.fade_finished
	if token!=_transition_token or not is_inside_tree(): return
	_transitioning=false; _busy=0
func _movement(key: String) -> void:
	if key in ["turn_l","turn_r"]: _command({"type":"turn","delta":-1 if key=="turn_l" else 1})
	else: _command({"type":"move","step":key})
func _verb(index: int) -> void:
	if not _can_game() or index>=verbs.size(): return
	if verbs[index].action.type=="cancel_toss": _cancel_toss(); return
	if verbs[index].action.type=="toss" and _tossing=="": _open_toss(verbs[index].action.item_id); return
	if verbs[index].action.type=="pickup": _take()
	else: _command(verbs[index].action)
func _front_action() -> void:
	if not _can_game(): return
	if not _view_action.is_empty(): _command(_view_action)
func _sleeping_lift() -> void:
	if _can_game():
		_close_card(); selected=""; _sync(); _save()
		lines=["The lift is dead.","Ask the Bell Porter."]; queue_redraw()
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
func _inspect_creature(id: String) -> void:
	if not _can_game(): return
	var actor: Dictionary=sim._actor(id)
	var column:=_panel("Ash Hound" if actor.kind=="hound" else "Wick Ghost",62,242)
	_label("Two steps, then rest.\nStep aside or GUARD.\nFOOD buys its peace." if actor.kind=="hound" else "An unspent cold wick.\nGLOW would snuff it.\nGUARD its cold flare.",column)
	_modal_button("creature_close","CLOSE",_close_modal,column)
func _portrait_help() -> void:
	if _can_game():
		selected=""; _close_card(); _save(); _sync()
		lines=["Curves turn for free.","Straight arrows step."]; queue_redraw()
func _select(index: int) -> void:
	if not _can_game(): return
	_tossing=""
	if index>=state.pack.size():
		selected=""; _close_card(); _save(); _sync(); return
	selected=state.pack[index]; _save(); _sync(); _open_card(selected)
func _equipment_card(slot: String) -> void:
	if not _can_game(): return
	var id: String=state.equipment[slot]
	if id!="": selected=id; _save(); _sync(); _open_card(id)
func _belt_card(kind: String) -> void:
	if not _can_game(): return
	var ids: Array=state.belt.filter(func(id): return state.items[id].kind==kind)
	if ids.size()==1:
		selected=ids[0]; _save(); _sync(); _open_card(selected)
	elif ids.size()>1:
		var column:=_panel("Keys / %d"%ids.size(),80,230)
		for id in ids: _modal_button("belt_"+id,_key_gate(id),_choose_belt.bind(id),column)
		_modal_button("keys_close","CLOSE",_close_modal,column)
func _choose_belt(id: String) -> void:
	_close_modal(); selected=id; _save(); _sync(); _open_card(id)
func _key_gate(id: String) -> String:
	for i in range(state.floors.size()):
		for fixture in state.floors[i].fixtures:
			if fixture.type=="lock" and fixture.key_id==id: return "Floor %d gate%s"%[i+1," / open" if fixture.open else ""]
	return "An old gate key"
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
	_label(info,column); _label(Flavour.provenance(state.items[id].kind,definition.provenance),column)
	if definition.has("purpose"): _label(definition.purpose,column)
	if state.items[id].kind=="key": _label(_key_gate(id),column)
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
		_button("card_use",Rect2(0,0,86,20),"UNEQUIP",_command.bind({"type":"unequip","slot":state.items[id].slot}),row); _card_names.append("card_use")
		controls.card_use.disabled=state.pack.size()>=8
		_card_button("card_drop","DROP",{"type":"drop","item_id":id},row)
		row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
	if state.items[id].kind=="clapper" and state.items[id].location in ["pack","equip"]:
		if row.get_child_count()>=3:
			row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
		_card_button("card_ring","RING",{"type":"ring","item_id":id},row)
		controls.card_ring.disabled=not sim.ring_ready()
	if state.rules_version=="m3.3" and state.items[id].location in ["pack","equip"]:
		if row.get_child_count()>=3:
			row=HBoxContainer.new(); row.add_theme_constant_override("separation",3); column.add_child(row)
		_button("card_toss",Rect2(0,0,42,20),"TOSS",_open_toss.bind(id),row); _card_names.append("card_toss")
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
	var is_map: bool=title.begins_with("Visited")
	var background: StyleBox=Chrome.surface("slate",7)
	if is_map:
		var parchment:=StyleBoxTexture.new(); parchment.texture=Paint.texture("res://assets/art/ui_offer/map_parchment_torn_v2.png")
		for side in [SIDE_LEFT,SIDE_RIGHT]: parchment.set_texture_margin(side,8)
		for side in [SIDE_TOP,SIDE_BOTTOM]: parchment.set_texture_margin(side,12)
		parchment.content_margin_left=8; parchment.content_margin_right=8
		parchment.content_margin_top=12; parchment.content_margin_bottom=8
		background=parchment
	panel.add_theme_stylebox_override("panel",background)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",7)
	panel.add_child(column)
	var heading:=_label("MAP / %d"%state.floor if is_map else title,column)
	if is_map:
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		heading.add_theme_color_override("font_color",Color("4d2b1d"))
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
	map.data=sim.view_snapshot(); map.data.survey=_survey.floor_data(state.floor)
	map.custom_minimum_size=Vector2(128,231); column.add_child(map)
	_modal_button("map_close","CLOSE",_close_modal,column)
func _process(delta: float) -> void:
	if _mode in ["title","end"]:
		_menu_clock+=delta; _update_menu_art()
	if _mode=="title" and _splash_time>0:
		_splash_time=maxf(0,_splash_time-delta)
		if _splash_time<=0: _skip_splash()
	# A damped instrument movement; never part of the simulation or input gate.
	var step: float=minf(delta,0.04)
	_compass_velocity+=(-_compass_swing*100.0-_compass_velocity*12.0)*step
	_compass_swing+=_compass_velocity*step
	if absf(_compass_swing)>0.001 or absf(_compass_velocity)>0.01: queue_redraw()
	if _busy>0 and not _transitioning:
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
	# C's native upper materials; the pad/verb area keeps its dark ground.
	draw_rect(Rect2(0,0,154,268),Color("312018"))
	draw_rect(Rect2(53,0,44,18),Color("0c101c"))
	for rect in [Rect2(0,0,53,18),Rect2(97,0,57,18)]: draw_style_box(Chrome.style(),rect)
	draw_style_box(Chrome.style(),Rect2(0,18,154,156))
	draw_texture(Paint.texture("res://assets/art/ui_offer/message_slate.png"),Vector2(2,174))
	if not is_instance_valid(_card):
		_text(Vector2(4,175),lines[0]); _text(Vector2(4,191),lines[1])
	draw_style_box(Chrome.style(),Rect2(1,208,36,38))
	var shudder:=Vector2(roundi(sin(_hurt_time*100)*2) if _hurt_time>0 else 0,0)
	draw_texture_rect(Paint.texture(portrait_path()),Rect2(Vector2(3,210)+shudder,Vector2(32,32)),false)
	if _hurt_time>0: draw_rect(Rect2(3,210,32,32),Color("965c48"),false,2)
	draw_texture(Paint.texture("res://assets/art/ui_offer/belt_loops.png"),Vector2(99,210))
	# One glass vial, with only its liquid cropped from the bottom upward.
	var vial_origin:=Vector2(36,212)
	draw_texture(Paint.texture("res://assets/art/ui_offer/hp_vial_empty.png"),vial_origin)
	var liquid: int=roundi(18.0*state.hp/state.max_hp)
	if liquid>0: draw_texture_rect_region(Paint.texture("res://assets/art/ui_offer/hp_vial_full.png"),Rect2(vial_origin+Vector2(0,24-liquid),Vector2(6,liquid)),Rect2(0,24-liquid,6,liquid))
	_text(Vector2(101,232),"HP %d/%d"%[state.hp,state.max_hp])
	# A folded painted leather tray, without empty-slot dashes or boxes.
	draw_texture(Paint.texture("res://assets/art/ui_offer/pack_leather.png"),Vector2(1,246))
	for key in ["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]:
		var button: Button=controls[key]
		draw_style_box(Chrome.style(1,button.is_pressed()),button.get_rect())
		_arrow(button.get_rect().get_center().floor(),key)
	_draw_compass()
func portrait_path() -> String:
	var kind: String="finder_near_death_v2" if state.hp<=1 else ("finder_hurt_v2" if state.hp<=3 or _hurt_time>0 else "finder_fine")
	return "res://assets/art/portrait/%s.png"%kind

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
	public.survey_hash=_survey.hash_value()
	public.travel_pending=_transitioning
	public.tossing=_tossing
	public.toss_preview=sim.toss_preview(_tossing) if _tossing!="" else {}
	public.secrets_found=state.floors.reduce(func(total,f): return total+f.fixtures.filter(func(v): return v.type=="panel" and v.open).size(),0)
	return public
func pilot_call(name_key: String,args: Array) -> String:
	match name_key:
		"busy": return "1" if _busy>0 or _transitioning or is_instance_valid(_modal) else "0"
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
			# Architectural backing walls may be behind us on arrival. The
			# existing own-cell action is still available on its actual verb.
			if key=="hot_front" and not controls.hot_front.visible and not _view_action.is_empty():
				for i in range(verbs.size()):
					if verbs[i].action==_view_action: key="verb%d"%i; break
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
