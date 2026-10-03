extends Control
## Menu de pause (l'arbre de scène est mis en pause par main.gd).

const P := preload("res://scripts/core/palette.gd")
const OptionsPanel := preload("res://scripts/ui/options_panel.gd")
const I18n := preload("res://scripts/core/i18n.gd")

signal resume
signal open_mushaf
signal open_note
signal to_title
signal touch_changed
signal language_changed

var save: RefCounted
var _menu: PanelContainer
var _options: PanelContainer
var _first: Button


func setup(save_data: RefCounted) -> void:
	save = save_data


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.07, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_menu = PanelContainer.new()
	_menu.custom_minimum_size = Vector2(420, 0)
	center.add_child(_menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_menu.add_child(box)
	var title := Label.new()
	title.text = I18n.t("pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", P.GOLD)
	box.add_child(title)
	_first = _button(box, I18n.t("pause.resume"), func() -> void: resume.emit())
	_button(box, I18n.t("pause.mushaf"), func() -> void: open_mushaf.emit())
	_button(box, I18n.t("pause.settings"), _show_options)
	_button(box, I18n.t("pause.note"), func() -> void: open_note.emit())
	_button(box, I18n.t("pause.menu"), func() -> void: to_title.emit())

	_options = OptionsPanel.new()
	_options.setup(save)
	_options.show_language = true
	_options.visible = false
	_options.closed.connect(_hide_options)
	_options.touch_changed.connect(func() -> void: touch_changed.emit())
	_options.language_changed.connect(func() -> void: language_changed.emit())
	center.add_child(_options)


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func open() -> void:
	visible = true
	_hide_options()


func close() -> void:
	visible = false


func show_options() -> void:
	_show_options()


func _show_options() -> void:
	_menu.visible = false
	_options.visible = true
	_options.focus_first()


func _hide_options() -> void:
	_options.visible = false
	_menu.visible = true
	_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		if _options.visible:
			_hide_options()
		else:
			resume.emit()
		get_viewport().set_input_as_handled()
