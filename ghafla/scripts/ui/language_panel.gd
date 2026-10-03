extends Control
## Choix de la langue au tout premier démarrage (ensuite : Réglages). Chaque langue est écrite dans sa propre langue,
## la question est posée dans toutes à la fois : cet écran n'a donc besoin d'aucune traduction.

const P := preload("res://scripts/core/palette.gd")
const Assets := preload("res://scripts/core/assets.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const I18n := preload("res://scripts/core/i18n.gd")

signal chosen(code: String)

var _first: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(420, 0)
	center.add_child(box)
	var ar := Label.new()
	ar.text = "غفلة"
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.add_theme_font_override("font", Assets.font_arabic())
	ar.add_theme_font_size_override("font_size", 72)
	ar.add_theme_color_override("font_color", P.GOLD)
	box.add_child(ar)
	var question := Label.new()
	var names := PackedStringArray()
	for l in I18n.languages():
		names.append(str(l.get("choose", l["name"])))
	question.text = "  ·  ".join(names)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 24)
	question.add_theme_color_override("font_color", Color(1, 0.94, 0.78, 0.9))
	box.add_child(question)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)
	for l in I18n.languages():
		var b := Button.new()
		b.text = str(l["name"])
		var code := str(l["code"])
		b.pressed.connect(func() -> void: chosen.emit(code))
		box.add_child(b)
		if _first == null or code == I18n.lang:  # la langue de l'appareil est proposée en premier
			_first = b
	_first.grab_focus()


func _draw() -> void:
	var vp := get_viewport_rect().size
	DrawUtil.vgrad(self, Rect2(Vector2.ZERO, vp), Color("1a1440"), Color("3a2458"))
	DrawUtil.glow(self, Vector2(vp.x * 0.5, vp.y * 0.3), 420.0, Color(1.0, 0.8, 0.45, 0.16))
