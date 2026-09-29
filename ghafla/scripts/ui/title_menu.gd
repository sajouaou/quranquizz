extends CanvasLayer
## Menu principal : le ciel du rêve en fond (le même décor que le jeu), quelques boutons.

const P := preload("res://scripts/core/palette.gd")
const Assets := preload("res://scripts/core/assets.gd")
const Backdrop := preload("res://scripts/world/backdrop.gd")
const OptionsPanel := preload("res://scripts/ui/options_panel.gd")
const NotePanel := preload("res://scripts/ui/note_panel.gd")

signal new_game
signal continue_game
signal quit_game
signal chapter1
signal chapter2
signal touch_changed

var save: RefCounted
var can_quit: bool = true
var _root: Control
var _menu: VBoxContainer
var _options: PanelContainer
var _note: Control
var _first: Button
var _bg_layer: CanvasLayer
var _cam: Camera2D


func setup(save_data: RefCounted, allow_quit: bool) -> void:
	save = save_data
	can_quit = allow_quit


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Fond : ciel et collines du jeu, avec une caméra qui dérive lentement
	_bg_layer = CanvasLayer.new()
	_bg_layer.layer = -10
	add_child(_bg_layer)
	var backdrop := Backdrop.new()
	_cam = Camera2D.new()
	_cam.position = Vector2(2300.0, 420.0)
	add_child(_cam)
	_cam.make_current()
	backdrop.camera = _cam
	_bg_layer.add_child(backdrop)
	var drift := create_tween().set_loops()
	drift.tween_property(_cam, "position:x", 3300.0, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_property(_cam, "position:x", 2300.0, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.08, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	_menu.custom_minimum_size = Vector2(420, 0)
	center.add_child(_menu)

	var ar := Label.new()
	ar.text = "غفلة"
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.add_theme_font_override("font", Assets.font_arabic())
	ar.add_theme_font_size_override("font_size", 92)
	ar.add_theme_color_override("font_color", P.GOLD)
	ar.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	ar.add_theme_constant_override("outline_size", 10)
	_menu.add_child(ar)
	var title := Label.new()
	title.text = "Ghafla"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	_menu.add_child(title)
	var tag := Label.new()
	tag.text = "Un rêve. Des pages à retrouver."
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(1, 0.94, 0.78, 0.9))
	tag.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	tag.add_theme_constant_override("outline_size", 6)
	_menu.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	_menu.add_child(gap)

	if save != null and (save.intro_seen or save.flag("c2_intro")) and save.exists():
		var n: int = save.count()
		_first = _button("Continuer  (chapitre %d, %d / 604 pages)" % [save.chapter, n], func() -> void: continue_game.emit())
	var new_label := "Nouvelle partie" if _first != null else "Commencer"
	var nb := _button(new_label, func() -> void: new_game.emit())
	if _first == null:
		_first = nb
	if save != null and save.intro_seen and save.chapter == 2:
		_button("Reprendre le chapitre 1", func() -> void: chapter1.emit())
	if save != null and save.chapter == 2 and save.flag("c2_intro"):
		pass  # « Continuer » reprend déjà le chapitre 2
	else:
		_button("Chapitre 2 : les leçons oubliées", func() -> void: chapter2.emit())
	_button("Réglages", _show_options)
	_button("À propos de l'histoire", _show_note)
	if can_quit:
		_button("Quitter", func() -> void: quit_game.emit())

	var foot := Label.new()
	foot.text = "Prototype · histoire fictive · sans musique"
	foot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	foot.anchor_left = 0.5
	foot.anchor_right = 0.5
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_left = -300
	foot.offset_right = 300
	foot.offset_top = -46
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 16)
	foot.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_root.add_child(foot)

	_options = OptionsPanel.new()
	_options.setup(save)
	_options.visible = false
	_options.closed.connect(_hide_options)
	_options.touch_changed.connect(func() -> void: touch_changed.emit())
	var oc := CenterContainer.new()
	oc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oc.add_child(_options)
	_root.add_child(oc)
	_first.grab_focus()


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	_menu.add_child(b)
	return b


func _show_options() -> void:
	_menu.visible = false
	_options.visible = true
	_options.focus_first()


func _hide_options() -> void:
	_options.visible = false
	_menu.visible = true
	_first.grab_focus()


func _show_note() -> void:
	if _note != null:
		return
	_menu.visible = false
	_note = NotePanel.new()
	_note.accepted.connect(func() -> void:
		_note.queue_free()
		_note = null
		_menu.visible = true
		_first.grab_focus())
	_root.add_child(_note)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _options != null and _options.visible:
		_hide_options()
		get_viewport().set_input_as_handled()
