extends Control
## Note de départ : cette histoire est une fiction symbolique. Elle est affichée avant la première partie
## et reste consultable depuis le menu (« À propos »).

const P := preload("res://scripts/core/palette.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const I18n := preload("res://scripts/core/i18n.gd")

signal accepted

const PARAGRAPH_KEYS := ["note.p1", "note.p2", "note.p3", "note.p4"]

var offer_download: bool = false  # première partie : on prévient du téléchargement du texte du Mushaf et on demande
var download: bool = true
var _button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.07, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = I18n.t("note.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", P.GOLD)
	box.add_child(title)
	for key in PARAGRAPH_KEYS:
		var l := Label.new()
		l.text = I18n.t(key)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 19 if offer_download else 21)
		box.add_child(l)
	if offer_download:
		var d := Label.new()
		d.text = I18n.t("note.download")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 19)
		d.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72))
		box.add_child(d)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		box.add_child(row)
		_button = _choice(row, I18n.t("note.download_yes"), true)
		_choice(row, I18n.t("note.download_no"), false)
	else:
		_button = Button.new()
		_button.text = I18n.t("note.ok")
		_button.custom_minimum_size = Vector2(260, 0)
		_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_button.pressed.connect(func() -> void: accepted.emit())
		box.add_child(_button)
	_button.grab_focus()


func _choice(row: Control, label: String, value: bool) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(func() -> void:
		download = value
		accepted.emit())
	row.add_child(b)
	return b
