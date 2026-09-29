extends Control
## Fin du prototype : l'aube se lève pour de bon. Rien de triomphant, aucun jugement.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Assets := preload("res://scripts/core/assets.gd")

signal keep_exploring
signal to_title
signal next_chapter

var count: int = 0
var total: int = 604
var placed: int = 0
var chapter: int = 1
var _t: float = 0.0
var _box: VBoxContainer
var _buttons: HBoxContainer


func setup(collected: int, total_pages: int, placed_pages: int, chapter_number: int = 1) -> void:
	count = collected
	total = total_pages
	placed = placed_pages
	chapter = chapter_number


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 18)
	_box.custom_minimum_size = Vector2(820, 0)
	_box.modulate.a = 0.0
	center.add_child(_box)

	var ar := Label.new()
	ar.text = "غفلة"
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.add_theme_font_override("font", Assets.font_arabic())
	ar.add_theme_font_size_override("font_size", 78)
	ar.add_theme_color_override("font_color", Color("6b4a10"))
	_box.add_child(ar)
	if chapter == 1:
		_line("Le jour se lève. Cette fois, tu es déjà debout.", 34, Color("3a2a10"))
		_line("%d pages sur %d ont été retrouvées. Dans ce prototype, %d pages seulement sont cachées dans le rêve ; le reste du chemin est à construire." % [count, total, placed], 21, Color("4a3a20"))
	else:
		_line("Ces leçons, il n'est jamais trop tard pour les suivre.", 34, Color("3a2a10"))
		_line("Chapitre 2 terminé : %d pages sur %d sont dans le Mushaf. Le rêve n'est pas fini : il reste tout le reste à retrouver." % [count, total], 21, Color("4a3a20"))
	_line("Ghafla est une histoire imaginée. Elle ne remplace ni la lecture du Coran, ni l'enseignement de gens de science.", 18, Color("6a5a40"))

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	_box.add_child(_buttons)
	if chapter == 1:
		var bn := Button.new()
		bn.text = "Chapitre 2 : les leçons oubliées"
		bn.pressed.connect(func() -> void: next_chapter.emit())
		_buttons.add_child(bn)
	var b1 := Button.new()
	b1.text = "Continuer à explorer"
	b1.pressed.connect(func() -> void: keep_exploring.emit())
	_buttons.add_child(b1)
	var b2 := Button.new()
	b2.text = "Menu principal"
	b2.pressed.connect(func() -> void: to_title.emit())
	_buttons.add_child(b2)
	_buttons.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_box, "modulate:a", 1.0, 2.2)
	tw.tween_property(_buttons, "modulate:a", 1.0, 0.8)
	tw.tween_callback(func() -> void: b1.grab_focus())


func _line(text: String, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k: float = clampf(_t / 2.5, 0.0, 1.0)
	# L'aube : du doré vers un ciel clair, avec des rayons doux
	DrawUtil.vgrad(self, Rect2(Vector2.ZERO, vp), Color("f3d9a4").lerp(Color("fff1cf"), k), Color("f8e7c2").lerp(Color("ffe2a3"), k))
	var sun := Vector2(vp.x * 0.5, vp.y * 0.86)
	DrawUtil.glow(self, sun, 620.0, Color(1.0, 0.85, 0.5, 0.55 * k))
	for i in range(9):
		var a := -PI * 0.5 + (float(i) - 4.0) * 0.17 + sin(_t * 0.3 + float(i)) * 0.02
		draw_line(sun, sun + Vector2(cos(a), sin(a)) * 900.0, Color(1.0, 0.9, 0.6, 0.10 * k), 46.0)
