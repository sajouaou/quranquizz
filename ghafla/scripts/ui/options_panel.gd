extends PanelContainer
## Réglages : volume et contrôles tactiles. Utilisé par le menu principal et par la pause.

const P := preload("res://scripts/core/palette.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Sfx := preload("res://scripts/core/sfx.gd")

signal closed
signal touch_changed

const TOUCH_LABELS := ["Contrôles tactiles : automatique", "Contrôles tactiles : oui", "Contrôles tactiles : non"]

var save: RefCounted
var _slider: HSlider
var _touch_button: Button
var _back: Button


func setup(save_data: RefCounted) -> void:
	save = save_data


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var title := Label.new()
	title.text = "Réglages"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", P.GOLD)
	box.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Volume des bruitages"
	box.add_child(vol_label)
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.05
	_slider.value = save.volume if save != null else 0.8
	_slider.custom_minimum_size = Vector2(0, 28)
	_slider.value_changed.connect(_on_volume)
	box.add_child(_slider)

	var note := Label.new()
	note.text = "Le jeu n'a pas de musique : seulement des sons du quotidien (pas, papier, vent)."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 17)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	box.add_child(note)

	_touch_button = Button.new()
	_touch_button.pressed.connect(_cycle_touch)
	box.add_child(_touch_button)
	_refresh_touch()

	_back = Button.new()
	_back.text = "Retour"
	_back.pressed.connect(func() -> void: closed.emit())
	box.add_child(_back)


func focus_first() -> void:
	if _slider != null:
		_slider.grab_focus()


func _on_volume(v: float) -> void:
	if save == null:
		return
	save.volume = v
	Sfx.set_master(v)
	Sfx.play("page", -8.0, 1.0)
	save.save_file()


func _cycle_touch() -> void:
	if save == null:
		return
	# -1 automatique -> 1 oui -> 0 non -> -1
	match save.touch_controls:
		-1:
			save.touch_controls = 1
		1:
			save.touch_controls = 0
		_:
			save.touch_controls = -1
	save.save_file()
	_refresh_touch()
	touch_changed.emit()


func _refresh_touch() -> void:
	var idx := 0
	if save != null:
		match save.touch_controls:
			1:
				idx = 1
			0:
				idx = 2
	_touch_button.text = TOUCH_LABELS[idx]
