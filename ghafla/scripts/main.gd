extends Node
## Point d'entrée : menu → note sur la fiction → cinématique → jeu. Relie le monde, l'interface, les dialogues
## et le Mushaf. Toute la logique de progression est ici ; le monde ne connaît ni l'interface ni les menus.

const Inputs := preload("res://scripts/core/inputs.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const SaveData := preload("res://scripts/core/save_data.gd")
const MushafData := preload("res://scripts/core/mushaf_data.gd")
const QuranText := preload("res://scripts/core/quran_text.gd")
const World := preload("res://scripts/world/world.gd")
const Cinematic := preload("res://scripts/cinematic/cinematic.gd")
const Cinematic2 := preload("res://scripts/cinematic/cinematic2.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const Dialogue := preload("res://scripts/ui/dialogue.gd")
const MushafBook := preload("res://scripts/ui/mushaf_book.gd")
const PauseMenu := preload("res://scripts/ui/pause_menu.gd")
const TitleMenu := preload("res://scripts/ui/title_menu.gd")
const NotePanel := preload("res://scripts/ui/note_panel.gd")
const EndCard := preload("res://scripts/ui/end_card.gd")
const TouchControls := preload("res://scripts/ui/touch_controls.gd")

enum State { TITLE, NOTE, CINEMATIC, PLAY, END }

const AUTOSAVE_EVERY := 4.0

var state: State = State.TITLE
var save: RefCounted
var mushaf: RefCounted
var world: Node2D
var cinematic: Node2D
var title: CanvasLayer
var note: Control
var end_card: Control

var ui_layer: CanvasLayer
var ui_root: Control
var hud: Control
var dialogue: Control
var book: Control
var pause_menu: Control
var touch: Control
var fade: ColorRect

var reactions: Dictionary = {}
var triggers: Dictionary = {}
var first_page: int = 0
var final_page: int = 0
var final_reaction: String = "final"
var chapter: int = 1
var paused_menu: bool = false

var _scene_queue: Array = []
var _book_from_pause: bool = false
var _autosave: float = 0.0
var _pool_index: Dictionary = {}
var _finale_done: bool = false
var _leaving: bool = false
var _dl_label: Label


func _ready() -> void:
	Inputs.ensure_actions()
	var root := get_tree().root
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	add_child(Sfx.new())
	var qt := QuranText.new()
	qt.name = "QuranText"
	add_child(qt)
	save = SaveData.get_instance()
	mushaf = MushafData.get_instance()
	Sfx.set_master(save.volume)
	chapter = save.chapter
	_load_data(chapter)
	_build_ui()
	show_title()


func _load_data(chap: int = 1) -> void:
	var suffix := "" if chap == 1 else "_%d" % chap
	reactions = {}
	triggers = {}
	first_page = 0
	final_page = 0
	final_reaction = "final"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue%s.json" % suffix))
	if typeof(parsed) == TYPE_DICTIONARY:
		reactions = parsed.get("reactions", {})
		for t in parsed.get("triggers", []):
			triggers[str(t["id"])] = t
	var pages: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_pages%s.json" % suffix))
	if typeof(pages) == TYPE_DICTIONARY:
		for d in pages.get("pages", []):
			if bool(d.get("first", false)):
				first_page = int(d["page"])
			if bool(d.get("final", false)):
				final_page = int(d["page"])
				final_reaction = str(d.get("reaction", "final"))


func _set_chapter(n: int) -> void:
	chapter = n
	_load_data(n)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	ui_layer.name = "UI"
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.name = "UiRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UiTheme.build()
	ui_layer.add_child(ui_root)

	touch = TouchControls.new()
	touch.name = "Touch"
	ui_root.add_child(touch)
	hud = Hud.new()
	hud.name = "Hud"
	hud.set_total(mushaf.total_pages)
	hud.mushaf_pressed.connect(_toggle_book)
	hud.pause_pressed.connect(_toggle_pause)
	ui_root.add_child(hud)
	dialogue = Dialogue.new()
	dialogue.name = "Dialogue"
	ui_root.add_child(dialogue)
	book = MushafBook.new()
	book.name = "MushafBook"
	book.closed.connect(_on_book_closed)
	ui_root.add_child(book)
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.setup(save)
	pause_menu.resume.connect(_toggle_pause)
	pause_menu.open_mushaf.connect(_open_book_from_pause)
	pause_menu.open_note.connect(_open_note_from_pause)
	pause_menu.to_title.connect(_back_to_title)
	pause_menu.touch_changed.connect(_apply_touch_setting)
	ui_root.add_child(pause_menu)

	# Fondu plein écran, au-dessus de tout (transitions entre les états)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 60
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade)
	_dl_label = Label.new()
	_dl_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_dl_label.offset_left = 20
	_dl_label.offset_top = -40
	_dl_label.offset_right = 520
	_dl_label.add_theme_font_size_override("font_size", 15)
	_dl_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	_dl_label.visible = false
	fade_layer.add_child(_dl_label)
	if QuranText.inst != null:
		QuranText.inst.progress.connect(_on_dl_progress)
	_set_play_ui(false)


func _set_play_ui(on: bool) -> void:
	hud.visible = on
	dialogue.visible = on
	touch.visible = on and _touch_wanted()


func _touch_wanted() -> bool:
	if save.touch_controls == 1:
		return true
	if save.touch_controls == 0:
		return false
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _apply_touch_setting() -> void:
	touch.visible = (state == State.PLAY) and _touch_wanted()
	hud.set_touch(_touch_wanted())


func _fade_to(color: Color, seconds: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(fade, "color", color, seconds)
	return tw


# ------------------------------------------------------------------------------------------------ menus

func show_title() -> void:
	_clear_run()
	state = State.TITLE
	get_tree().paused = false
	_set_play_ui(false)
	title = TitleMenu.new()
	title.name = "Title"
	title.setup(save, not OS.has_feature("web") and not OS.has_feature("mobile"))
	title.new_game.connect(_on_new_game)
	title.continue_game.connect(_on_continue)
	title.chapter1.connect(_on_chapter1)
	title.chapter2.connect(_on_chapter2)
	title.quit_game.connect(func() -> void: get_tree().quit())
	title.touch_changed.connect(_apply_touch_setting)
	add_child(title)
	fade.color = Color(0, 0, 0, 1)
	_fade_to(Color(0, 0, 0, 0), 1.0)


func _clear_run() -> void:
	_scene_queue.clear()
	_finale_done = false
	Sfx.stop_all_loops()
	for n in [title, note, cinematic, world, end_card]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	title = null
	note = null
	cinematic = null
	world = null
	end_card = null
	paused_menu = false
	pause_menu.close()
	if book.is_open():
		book.visible = false


func _on_new_game() -> void:
	save.reset_progress()
	_set_chapter(1)
	_after_title_choice(true)


func _on_continue() -> void:
	_set_chapter(save.chapter)
	_after_title_choice(false)


func _on_chapter1() -> void:
	save.switch_chapter(1)
	_set_chapter(1)
	_after_title_choice(false)


func _on_chapter2() -> void:
	save.switch_chapter(2)
	_set_chapter(2)
	_after_title_choice(false)


func _after_title_choice(is_new: bool) -> void:
	if title != null:
		title.queue_free()
		title = null
	if not save.note_seen:
		_show_note(func(download: bool) -> void:
			save.note_seen = true
			save.download_text = download
			save.save_file()
			_route_after_note(is_new))
	else:
		_route_after_note(is_new)


func _route_after_note(is_new: bool) -> void:
	var seen: bool = save.intro_seen if chapter == 1 else save.flag("c2_intro")
	if is_new or not seen:
		_play_cinematic()
	else:
		_start_world(true)


func _show_note(on_done: Callable) -> void:
	state = State.NOTE
	note = NotePanel.new()
	note.name = "Note"
	note.offer_download = true  # première partie : on prévient du téléchargement du texte et on demande
	note.accepted.connect(func() -> void:
		var download: bool = note.download
		note.queue_free()
		note = null
		on_done.call(download))
	ui_root.add_child(note)


func _open_note_from_pause() -> void:
	pause_menu.visible = false
	var n := NotePanel.new()
	n.accepted.connect(func() -> void:
		n.queue_free()
		pause_menu.visible = true)
	ui_root.add_child(n)


# ------------------------------------------------------------------------------------ texte du Mushaf

## Télécharge le texte de tout le Mushaf en tâche de fond (annoncé avant, sur l'écran de note).
func _start_text_download() -> void:
	if not save.download_text or QuranText.inst == null or QuranText.inst.is_complete():
		return
	QuranText.inst.prefetch_all()


func _on_dl_progress(done: int, total: int) -> void:
	var busy := total > 0 and done < total
	_dl_label.visible = busy and state != State.PLAY and state != State.END
	_dl_label.text = "Téléchargement du texte du Mushaf : %d / %d" % [done, total]
	if total > 0 and done >= total and state == State.PLAY:
		hud.toast("Le texte du Mushaf est téléchargé.")


# ------------------------------------------------------------------------------------------- cinématique

func _play_cinematic() -> void:
	state = State.CINEMATIC
	_set_play_ui(false)
	_start_text_download()
	cinematic = Cinematic.new() if chapter == 1 else Cinematic2.new()
	cinematic.name = "Cinematic"
	cinematic.finished.connect(_on_cinematic_finished)
	add_child(cinematic)
	cinematic.run()


func _on_cinematic_finished() -> void:
	# Fondu doré par-dessus, on détruit la cinématique, on bâtit le monde, puis la lumière se retire.
	fade.color = Color(1.0, 0.94, 0.78, 1.0)
	if cinematic != null:
		cinematic.queue_free()
		cinematic = null
	if chapter == 1:
		save.intro_seen = true
	else:
		save.set_flag("c2_intro")
	save.save_file()
	# On laisse une image passer avant la construction (le fondu est déjà à l'écran).
	await get_tree().process_frame
	_start_world(false)
	_fade_to(Color(1.0, 0.94, 0.78, 0.0), 2.2)


# ------------------------------------------------------------------------------------------------ monde

func _start_world(from_save: bool) -> void:
	state = State.PLAY
	get_tree().paused = false
	world = World.new()
	world.name = "World"
	add_child(world)
	world.page_collected.connect(_on_page_collected)
	world.story_trigger.connect(_on_story_trigger)
	world.zone_entered.connect(_on_zone_entered)
	world.item_collected.connect(func(id: String) -> void:
		if id == "key_chest":
			hud.set_key(true))
	world.toast.connect(func(text: String) -> void: hud.toast(text))
	world.prompt_changed.connect(hud.set_prompt)
	var spawn := Vector2(-1, -1)
	if from_save and save.player_x >= 0.0:
		spawn = Vector2(save.player_x, save.player_y)
	world.start(save, mushaf, spawn, chapter)
	book.setup(save, mushaf, world.placed_pages)
	_set_play_ui(true)
	if from_save:
		_start_text_download()
	hud.set_touch(_touch_wanted())
	hud.set_count(save.count())
	hud.set_key(save.has_item("key_chest"))
	if not save.flag("controls_hint"):
		save.set_flag("controls_hint")
		hud.show_controls_hint()
	if from_save:
		hud.set_objective(_objective_for_progress())
	_autosave = 0.0
	_finale_done = false


func _objective_for_progress() -> String:
	if chapter == 2:
		if final_page > 0 and save.has_page(final_page):
			return "Tu peux continuer à explorer le rêve."
		return "Suis la lumière et retrouve les pages, encore."
	if first_page > 0 and not save.has_page(first_page):
		return "Une page t'attend devant la porte."
	if final_page > 0 and save.has_page(final_page):
		return "Tu peux continuer à explorer le rêve."
	return "Retrouve les pages du Mushaf. Certaines se cachent."


func _process(delta: float) -> void:
	if state != State.PLAY or world == null or paused_menu:
		return
	_autosave += delta
	if _autosave >= AUTOSAVE_EVERY:
		_autosave = 0.0
		_save_position()


func _save_position() -> void:
	if world == null or world.player == null:
		return
	var p: Vector2 = world.player.last_safe
	if p == Vector2.ZERO:
		return
	save.player_x = p.x
	save.player_y = p.y
	save.save_file()


func _on_zone_entered(zone_id: String) -> void:
	# Ambiances : de l'air dehors, des gouttes dans la grotte. Aucune musique.
	match zone_id:
		"house", "home":
			Sfx.stop_all_loops()
		"cave":
			Sfx.fade_loop("air", -60.0, 2.0)
			Sfx.loop("drip", -12.0)
		_:
			Sfx.fade_loop("drip", -60.0, 1.5)
			Sfx.loop("air", -18.0 if zone_id != "peak" else -12.0)


func _on_page_collected(page: int, screen_pos: Vector2, data: Dictionary) -> void:
	hud.fly_page(screen_pos)
	hud.set_count(save.count())
	if page == final_page and final_page > 0:
		_run_finale()
		return
	var id := str(data.get("reaction", ""))
	if id == "" or not reactions.has(id):
		return
	var reaction: Dictionary = reactions[id]
	# On laisse la page rejoindre le Mushaf avant que le personnage réagisse
	await get_tree().create_timer(0.9).timeout
	if state != State.PLAY:
		return
	_enqueue_reaction(id, reaction)


func _enqueue_reaction(id: String, reaction: Dictionary) -> void:
	if str(reaction.get("style", "scene")) == "whisper":
		var pool: Array = reaction.get("pool", [])
		if pool.is_empty():
			return
		var i: int = int(_pool_index.get(id, 0))
		_pool_index[id] = i + 1
		dialogue.whisper(str(pool[i % pool.size()]))
		return
	_scene_queue.append({"lines": reaction.get("lines", []), "meaning": reaction.get("meaning", {}), "objective": str(reaction.get("objective", ""))})
	_pump_scenes()


func _on_story_trigger(id: String) -> void:
	if not triggers.has(id):
		return
	var t: Dictionary = triggers[id]
	if str(t.get("style", "scene")) == "whisper":
		for line in t.get("lines", []):
			dialogue.whisper(str(line))
		if t.has("objective"):
			hud.set_objective(str(t["objective"]))
	else:
		_scene_queue.append({"lines": t.get("lines", []), "meaning": {}, "objective": str(t.get("objective", ""))})
		_pump_scenes()


func _pump_scenes() -> void:
	if state != State.PLAY or world == null or dialogue.active or _scene_queue.is_empty():
		return
	var entry: Dictionary = _scene_queue.pop_front()
	world.player.frozen = true
	dialogue.show_scene(entry["lines"], entry["meaning"], func() -> void:
		var obj: String = str(entry.get("objective", ""))
		if obj != "":
			hud.set_objective(obj)
		if not _scene_queue.is_empty():
			_pump_scenes()
		elif world != null and not _finale_done:
			world.player.frozen = false)


# ------------------------------------------------------------------------------------------------ finale

func _run_finale() -> void:
	if _finale_done:
		return
	_finale_done = true
	save.finished = true
	save.save_file()
	world.player.frozen = true
	await get_tree().create_timer(1.6).timeout
	if state != State.PLAY or world == null:
		return
	# quelques mots avant la carte de fin
	var reaction: Dictionary = reactions.get(final_reaction, {})
	var done := func() -> void: _show_end_card()
	if reaction.is_empty():
		done.call()
	else:
		dialogue.show_scene(reaction.get("lines", []), reaction.get("meaning", {}), done)


func _show_end_card() -> void:
	state = State.END
	_fade_to(Color(1.0, 0.94, 0.78, 1.0), 1.6).finished.connect(func() -> void:
		end_card = EndCard.new()
		end_card.name = "EndCard"
		end_card.setup(save.count(), mushaf.total_pages, world.placed_pages.size(), chapter)
		end_card.keep_exploring.connect(_end_keep_exploring)
		end_card.next_chapter.connect(_end_next_chapter)
		end_card.to_title.connect(_back_to_title)
		ui_root.add_child(end_card)
		_fade_to(Color(1.0, 0.94, 0.78, 0.0), 0.8))


func _end_next_chapter() -> void:
	if end_card != null:
		end_card.queue_free()
		end_card = null
	_scene_queue.clear()
	if world != null:
		world.queue_free()
		world = null
	Sfx.stop_all_loops()
	_finale_done = false
	save.switch_chapter(2)
	_set_chapter(2)
	fade.color = Color(0, 0, 0, 1)
	_route_after_note(false)
	_fade_to(Color(0, 0, 0, 0), 1.0)


func _end_keep_exploring() -> void:
	if end_card != null:
		end_card.queue_free()
		end_card = null
	state = State.PLAY
	world.player.frozen = false
	hud.set_objective("Tu peux continuer à explorer le rêve.")


# --------------------------------------------------------------------------------------- entrées / pause

func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAY:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("mushaf"):
		_toggle_book()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if state != State.PLAY and not paused_menu:
		return
	if book.is_open():
		return
	paused_menu = not paused_menu
	if paused_menu:
		_save_position()
		get_tree().paused = true
		pause_menu.open()
	else:
		get_tree().paused = false
		pause_menu.close()


func _toggle_book() -> void:
	if state != State.PLAY or world == null:
		return
	if book.is_open():
		book.close_book()
	elif not paused_menu and not dialogue.active:
		book.open_book(0)


func _open_book_from_pause() -> void:
	_book_from_pause = true
	pause_menu.visible = false
	book.open_book(0)


func _on_book_closed() -> void:
	# Le livre remet l'arbre en marche ; si on venait de la pause, on y retourne.
	if _book_from_pause:
		_book_from_pause = false
		get_tree().paused = true
		pause_menu.open()


func _back_to_title() -> void:
	if _leaving:
		return  # un seul retour au menu, même si l'on clique plusieurs fois
	_leaving = true
	if world != null and state == State.PLAY:
		_save_position()
	save.save_file()
	# on ferme tout de suite le menu de pause : plus rien à cliquer pendant le fondu
	paused_menu = false
	pause_menu.close()
	get_tree().paused = false
	if world != null and world.player != null:
		world.player.frozen = true
	_fade_to(Color(0, 0, 0, 1), 0.5).finished.connect(func() -> void:
		_leaving = false
		show_title())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if world != null:
			_save_position()
		save.save_file()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED and world != null and state == State.PLAY:
		_save_position()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Bouton « retour » d'Android : pause en jeu, sinon on quitte
		if state == State.PLAY:
			_toggle_pause()
		elif state == State.TITLE:
			get_tree().quit()


# ------------------------------------------------------------------------------ aides pour les tests

func debug_teleport(x: float, y: float = -1.0) -> void:
	world.debug_teleport(x, y)


func debug_hide(path: String) -> void:
	var n := get_node_or_null(path)
	if n != null:
		n.visible = false
	else:
		print("[state] no node ", path)


func debug_children(path: String) -> void:
	var n := get_node_or_null(path) if path != "" else self
	var names := []
	for c in n.get_children():
		names.append(str(c.name) + ":" + c.get_class())
	print("[state] children ", names)


func debug_skip(section: String) -> void:
	world.backdrop.skip[section] = true


func debug_chapter(n: int) -> void:
	QuranText.inst.allow_network = false  # pas de réseau pendant les essais
	if title != null:
		title.queue_free()
		title = null
	save.note_seen = true
	save.switch_chapter(n)
	_set_chapter(n)
	_route_after_note(false)


func debug_state() -> void:
	print("[state] ", State.keys()[state], " pages=", save.count(), " paused=", paused_menu, " scenes=", _scene_queue.size())


func debug_new_game() -> void:
	_on_new_game()


func debug_skip_cinematic() -> void:
	if cinematic != null:
		cinematic.skip()


func debug_collect(page: int) -> void:
	if world != null and world.pickups.has(str(page)):
		world.collect_page(world.pickups[str(page)])


func debug_rect(path: String) -> void:
	var n := get_node_or_null(path)
	if n is Control:
		print("[state] rect ", path, " ", (n as Control).get_global_rect(), " anchors ", (n as Control).anchor_right, " ", (n as Control).anchor_bottom)
	else:
		print("[state] no control ", path)


func debug_advance(times: int) -> void:
	for i in range(times):
		if dialogue.active:
			dialogue.advance()
			dialogue.advance()


func debug_give_all() -> void:
	for p in world.placed_pages:
		if int(p) != final_page:
			save.add_page(int(p))
	hud.set_count(save.count())


func debug_touch(on: bool) -> void:
	save.touch_controls = 1 if on else 0
	_apply_touch_setting()


func debug_player() -> void:
	if world != null:
		print("[state] player ", world.player.global_position, " vel ", world.player.velocity)


func debug_collect_id(id: String) -> void:
	if world != null and world.pickups.has(id):
		world.collect_page(world.pickups[id])


func debug_book(page: int) -> void:
	book.open_book(page)


## Texte factice (mots latins) pour vérifier la mise en page sans écrire aucun texte coranique.
func debug_fake_text(page: int) -> void:
	var verses := []
	for pt in mushaf.parts_of_page(page):
		for v in range(int(pt[1]), int(pt[2]) + 1):
			var words := []
			for i in range(8 + (v * 7) % 9):
				words.append("mot" + str((v * 13 + i * 5) % 90))
			verses.append({"key": "%d:%d" % [pt[0], v], "text": " ".join(words)})
	DirAccess.make_dir_recursive_absolute("user://mushaf_text")
	var f := FileAccess.open("user://mushaf_text/page_%03d.json" % page, FileAccess.WRITE)
	f.store_string(JSON.stringify({"page": page, "verses": verses}))
