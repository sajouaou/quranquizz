extends CanvasLayer
## Menu principal : le ciel du rêve en fond (le même décor que le jeu), des lucioles, quelques boutons.
## Les chapitres ont leur propre écran (« Chapitres ») : deux cartes au même endroit, avec la progression de chacun.

const P := preload("res://scripts/core/palette.gd")
const Assets := preload("res://scripts/core/assets.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Backdrop := preload("res://scripts/world/backdrop.gd")
const OptionsPanel := preload("res://scripts/ui/options_panel.gd")
const NotePanel := preload("res://scripts/ui/note_panel.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const MushafData := preload("res://scripts/core/mushaf_data.gd")
const I18n := preload("res://scripts/core/i18n.gd")

signal new_game
signal continue_game
signal quit_game
signal chapter1
signal chapter2
signal touch_changed
signal language_changed

const CHAPTERS := [1, 2]

var save: RefCounted
var can_quit: bool = true
var _root: Control
var _menu: VBoxContainer
var _menu_center: Control
var _chapters: Control
var _chapter_first: Button
var _options: PanelContainer
var _note: Control
var _first: Button
var _bg_layer: CanvasLayer
var _cam: Camera2D


## Lucioles et poussière dorée qui montent lentement.
class Motes:
	extends Control
	const P := preload("res://scripts/core/palette.gd")
	const DrawUtil := preload("res://scripts/core/draw_util.gd")
	var _m: Array = []
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var rng := RandomNumberGenerator.new()
		rng.seed = 91
		for i in range(46):
			_m.append({"x": rng.randf(), "y": rng.randf(), "s": rng.randf_range(1.4, 3.6), "v": rng.randf_range(0.008, 0.026), "p": rng.randf() * TAU, "w": rng.randf_range(0.4, 1.2)})

	func _process(delta: float) -> void:
		_t += delta
		for m in _m:
			m["y"] -= float(m["v"]) * delta
			if m["y"] < -0.05:
				m["y"] = 1.05
		queue_redraw()

	func _draw() -> void:
		var vp := size
		for m in _m:
			var x: float = float(m["x"]) * vp.x + sin(_t * float(m["w"]) + float(m["p"])) * 18.0
			var y: float = float(m["y"]) * vp.y
			var a: float = 0.35 + 0.35 * sin(_t * 1.6 + float(m["p"]))
			DrawUtil.glow(self, Vector2(x, y), 9.0 * float(m["s"]), Color(1.0, 0.88, 0.55, 0.45 * a))
			draw_circle(Vector2(x, y), float(m["s"]) * 0.7, Color(1.0, 0.95, 0.8, 0.75 * a))


## Filet doré avec une étoile au centre.
class Ornament:
	extends Control
	const P := preload("res://scripts/core/palette.gd")
	const DrawUtil := preload("res://scripts/core/draw_util.gd")

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var gold := Color(0.91, 0.77, 0.42)
		DrawUtil.hgrad(self, Rect2(c.x - 170.0, c.y - 1.0, 150.0, 2.0), Color(gold, 0.0), Color(gold, 0.85))
		DrawUtil.hgrad(self, Rect2(c.x + 20.0, c.y - 1.0, 150.0, 2.0), Color(gold, 0.85), Color(gold, 0.0))
		draw_colored_polygon(DrawUtil.star(c, 11.0, 5.5, 8), gold)
		draw_colored_polygon(DrawUtil.star(c, 5.0, 2.5, 8), Color(0.1, 0.06, 0.2))


## Illustration d'un chapitre : le ciel du chapitre, des collines, une lune ou un soleil, des étoiles.
class ChapterArt:
	extends Control
	const P := preload("res://scripts/core/palette.gd")
	const DrawUtil := preload("res://scripts/core/draw_util.gd")
	var chapter: int = 1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 140)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var sky: Dictionary = P.sky_at(0.0 if chapter == 1 else 7500.0, chapter)
		var top: Color = sky["top"]
		var mid: Color = sky["mid"]
		var bot: Color = sky["bottom"]
		if chapter == 1:
			top = Color("3b2c72")
		DrawUtil.vgrad(self, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.55)), top, mid)
		DrawUtil.vgrad(self, Rect2(r.position + Vector2(0, r.size.y * 0.55 - 1.0), Vector2(r.size.x, r.size.y * 0.45 + 1.0)), mid, bot)
		var rng := RandomNumberGenerator.new()
		rng.seed = 40 + chapter
		for i in range(22):
			draw_circle(Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.5), rng.randf_range(0.7, 1.6), Color(1, 0.96, 0.85, rng.randf_range(0.3, 0.8) * (0.4 + 0.6 * float(sky["stars"]))))
		if chapter == 1:
			draw_circle(Vector2(r.size.x * 0.74, r.size.y * 0.52), 17.0, Color(1.0, 0.92, 0.65, 0.95))
			DrawUtil.glow(self, Vector2(r.size.x * 0.74, r.size.y * 0.52), 70.0, Color(1.0, 0.85, 0.5, 0.35))
		else:
			draw_colored_polygon(DrawUtil.crescent(Vector2(r.size.x * 0.74, r.size.y * 0.3), 20.0, 0.42, -0.5), Color(0.96, 0.95, 0.88, 0.95))
		# collines et silhouettes
		var back := PackedVector2Array()
		var front := PackedVector2Array()
		var n := 24
		for i in range(n + 1):
			var u := float(i) / float(n)
			back.append(Vector2(u * r.size.x, r.size.y * (0.70 + 0.07 * sin(u * 5.0 + float(chapter)) + 0.04 * sin(u * 13.0))))
			front.append(Vector2(u * r.size.x, r.size.y * (0.84 + 0.05 * sin(u * 7.0 + 2.0 + float(chapter)))))
		back.append(Vector2(r.size.x, r.size.y))
		back.append(Vector2(0, r.size.y))
		front.append(Vector2(r.size.x, r.size.y))
		front.append(Vector2(0, r.size.y))
		draw_colored_polygon(back, Color(0.16, 0.1, 0.27, 0.85))
		# petite ville : coupoles et minarets
		var bx := r.size.x * 0.12
		var base := r.size.y * 0.74
		for i in range(5):
			var w := 20.0 + float((i * 7) % 11)
			var h := 22.0 + float((i * 13 + chapter * 5) % 26)
			draw_rect(Rect2(bx, base - h, w, h + 8.0), Color(0.13, 0.08, 0.22))
			if i % 2 == 0:
				draw_colored_polygon(DrawUtil.ellipse(Vector2(bx + w * 0.5, base - h), w * 0.5, w * 0.42, 16), Color(0.13, 0.08, 0.22))
			if i == 3:
				draw_rect(Rect2(bx + w * 0.5 - 2.0, base - h - 14.0, 4.0, 14.0), Color(0.13, 0.08, 0.22))
			if i % 2 == 1:
				draw_rect(Rect2(bx + 5.0, base - h + 8.0, 4.0, 6.0), Color(1.0, 0.82, 0.45, 0.8))
			bx += w + 6.0 + float((i * 5) % 9)
		draw_colored_polygon(front, Color(0.1, 0.06, 0.18))
		# fondu vers le bas de la carte
		DrawUtil.vgrad(self, Rect2(0, r.size.y - 26.0, r.size.x, 26.0), Color(0.04, 0.035, 0.11, 0.0), Color(0.04, 0.035, 0.11, 0.9))


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
	_root.theme = UiTheme.build()
	add_child(_root)

	# Voile : plus sombre en haut et en bas, pour que le titre et les boutons se lisent
	var shade := ColorRect.new()
	shade.color = Color(1, 1, 1, 1)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var smat := ShaderMaterial.new()
	var sshader := Shader.new()
	sshader.code = """
shader_type canvas_item;
void fragment() {
	float edge = smoothstep(0.25, 1.0, abs(UV.y - 0.45) * 2.0);
	float side = smoothstep(0.35, 1.0, abs(UV.x - 0.5) * 2.0);
	COLOR = vec4(0.02, 0.01, 0.08, 0.28 + edge * 0.30 + side * 0.18);
}
"""
	smat.shader = sshader
	shade.material = smat
	_root.add_child(shade)
	_root.add_child(Motes.new())

	_menu_center = CenterContainer.new()
	_menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_menu_center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 9)
	_menu.custom_minimum_size = Vector2(420, 0)
	_menu_center.add_child(_menu)

	var head := Control.new()
	head.custom_minimum_size = Vector2(420, 84)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.draw.connect(func() -> void: DrawUtil.glow(head, head.size * 0.5, 190.0, Color(1.0, 0.82, 0.45, 0.30)))
	_menu.add_child(head)
	var ar := Label.new()
	ar.text = "غفلة"
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.add_theme_font_override("font", Assets.font_arabic())
	ar.add_theme_font_size_override("font_size", 76)
	ar.add_theme_color_override("font_color", P.GOLD)
	ar.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	ar.add_theme_constant_override("outline_size", 10)
	head.add_child(ar)
	var title := Label.new()
	title.text = I18n.t("app.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	_menu.add_child(title)
	_menu.add_child(Ornament.new())
	var tag := Label.new()
	tag.text = I18n.t("menu.tagline")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(1, 0.94, 0.78, 0.9))
	tag.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	tag.add_theme_constant_override("outline_size", 6)
	_menu.add_child(tag)

	var has_save: bool = save != null and (save.intro_seen or save.flag("c2_intro")) and save.exists()
	if has_save:
		_first = _button(I18n.t("menu.continue", {"chapter": save.chapter, "count": save.count(), "total": MushafData.get_instance().total_pages}), func() -> void: continue_game.emit(), true)
	var nb := _button(I18n.t("menu.new_game") if has_save else I18n.t("menu.start"), func() -> void: new_game.emit())
	_compact(nb)
	if _first == null:
		_first = nb
		_primary(nb)
	_compact(_button(I18n.t("menu.chapters"), _show_chapters))
	_compact(_button(I18n.t("menu.settings"), _show_options))
	_compact(_button(I18n.t("menu.about"), _show_note))
	if can_quit:
		_compact(_button(I18n.t("menu.quit"), func() -> void: quit_game.emit()))

	var foot := Label.new()
	foot.text = I18n.t("menu.footer")
	foot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	foot.anchor_left = 0.5
	foot.anchor_right = 0.5
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_left = -300
	foot.offset_right = 300
	foot.offset_top = -30
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 15)
	foot.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_root.add_child(foot)

	_build_chapters()

	_options = OptionsPanel.new()
	_options.setup(save)
	_options.show_language = true
	_options.visible = false
	_options.closed.connect(_hide_options)
	_options.touch_changed.connect(func() -> void: touch_changed.emit())
	_options.language_changed.connect(func() -> void: language_changed.emit())
	var oc := CenterContainer.new()
	oc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oc.add_child(_options)
	_root.add_child(oc)
	_first.grab_focus()
	_animate_in()


## Les éléments du menu apparaissent l'un après l'autre.
func _animate_in() -> void:
	var i := 0
	for c in _menu.get_children():
		c.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.08 * float(i))
		tw.tween_property(c, "modulate:a", 1.0, 0.5)
		i += 1


func _button(text: String, cb: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	b.add_theme_font_size_override("font_size", 22)
	_menu.add_child(b)
	if primary:
		_primary(b)
	return b


## Boutons secondaires : un peu moins hauts, pour que tout le menu tienne à l'écran.
func _compact(b: Button) -> void:
	if b == _first:
		return
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat = (b.get_theme_stylebox(state, "Button") as StyleBoxFlat).duplicate()
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		b.add_theme_stylebox_override(state, sb)


## Bouton principal : fond doré, lettres sombres.
func _primary(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var bg := Color(0.84, 0.66, 0.27, 0.96)
		match state:
			"hover", "focus":
				bg = Color(0.93, 0.75, 0.36, 1.0)
			"pressed":
				bg = Color(1.0, 0.86, 0.5, 1.0)
		var sb := UiTheme.panel_style(bg, Color(1.0, 0.9, 0.6, 0.95), 12, 2)
		sb.content_margin_top = 9
		sb.content_margin_bottom = 9
		b.add_theme_stylebox_override(state, sb)
	for col in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(col, Color(0.1, 0.06, 0.16))


# ------------------------------------------------------------------------------------------------ chapitres

func _build_chapters() -> void:
	_chapters = CenterContainer.new()
	_chapters.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chapters.visible = false
	_root.add_child(_chapters)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_chapters.add_child(box)
	var t := Label.new()
	t.text = I18n.t("chapters.title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 46)
	t.add_theme_color_override("font_color", P.GOLD)
	t.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	t.add_theme_constant_override("outline_size", 8)
	box.add_child(t)
	box.add_child(Ornament.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for n in CHAPTERS:
		var card := _chapter_card(n)
		row.add_child(card)
		if _chapter_first == null:
			_chapter_first = card
	var back := Button.new()
	back.text = I18n.t("menu.back")
	back.custom_minimum_size = Vector2(220, 0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_hide_chapters)
	box.add_child(back)


func _chapter_card(n: int) -> Button:
	var prog := _chapter_progress(n)
	var current: bool = save != null and save.chapter == n and (save.intro_seen or save.flag("c2_intro"))
	var started: bool = prog.x > 0 or (save != null and (save.intro_seen if n == 1 else save.flag("c2_intro")))
	var done: bool = prog.y > 0 and prog.x >= prog.y  # terminé = toutes les pages du chapitre sont dans le Mushaf
	var card := Button.new()
	card.custom_minimum_size = Vector2(340, 372)
	card.clip_contents = true
	var border := P.GOLD if current else Color(0.91, 0.77, 0.42, 0.5)
	for state in ["normal", "hover", "pressed", "focus"]:
		var bg := Color(0.05, 0.04, 0.13, 0.93)
		var bc := border
		if state == "hover" or state == "focus":
			bg = Color(0.1, 0.08, 0.22, 0.97)
			bc = Color(1.0, 0.88, 0.55, 1.0)
		elif state == "pressed":
			bg = Color(0.16, 0.12, 0.3, 1.0)
		var sb := UiTheme.panel_style(bg, bc, 18, 3 if state != "normal" or current else 2)
		card.add_theme_stylebox_override(state, sb)
	card.pressed.connect(func() -> void:
		if n == 1:
			chapter1.emit()
		else:
			chapter2.emit())

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 8
	col.offset_top = 8
	col.offset_right = -8
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var art := ChapterArt.new()
	art.chapter = n
	col.add_child(art)
	col.add_child(_label(I18n.t("chapters.label", {"n": n}), 19, Color(P.GOLD, 0.9), true))
	col.add_child(_label(I18n.t("chapters.%d.name" % n), 27, Color.WHITE, true))
	var blurb := _label(I18n.t("chapters.%d.blurb" % n), 16, Color(1, 1, 1, 0.65), true)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(300, 64)
	blurb.add_theme_constant_override("line_spacing", -6)
	col.add_child(blurb)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 7)
	bar.show_percentage = false
	bar.max_value = float(maxi(1, prog.y))
	bar.value = float(prog.x)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.18)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = P.GOLD
	fg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	col.add_child(bar)
	var status := I18n.t("chapters.status.new")
	var counts := {"have": prog.x, "total": prog.y}
	if done:
		status = I18n.t("chapters.status.done", counts)
	elif started:
		status = I18n.t("chapters.status.current" if current else "chapters.status.started", counts)
	col.add_child(_label(status, 17, Color(1, 0.94, 0.78, 0.9), true))
	return card


func _label(text: String, size: int, color: Color, center: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Pages entières déjà retrouvées dans ce chapitre, sur celles que le chapitre permet de compléter (nombres réels, calculés depuis les données).
func _chapter_progress(n: int) -> Vector2i:
	if save == null:
		return Vector2i.ZERO
	var suffix := "" if n == 1 else "_%d" % n
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_pages%s.json" % suffix))
	if typeof(parsed) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	var pages: Array = MushafData.get_instance().pages_of_defs(parsed.get("pages", []))["complete"]
	var have := 0
	for pg in pages:
		if save.has_page(int(pg)):
			have += 1
	return Vector2i(have, pages.size())


func _show_chapters() -> void:
	_menu_center.visible = false
	_chapters.visible = true
	_chapters.modulate.a = 0.0
	create_tween().tween_property(_chapters, "modulate:a", 1.0, 0.25)
	if _chapter_first != null:
		_chapter_first.grab_focus()


func _hide_chapters() -> void:
	_chapters.visible = false
	_menu_center.visible = true
	_first.grab_focus()


# -------------------------------------------------------------------------------------- réglages et note

func _show_options() -> void:
	_menu_center.visible = false
	_options.visible = true
	_options.focus_first()


func _hide_options() -> void:
	_options.visible = false
	_menu_center.visible = true
	_first.grab_focus()


func _show_note() -> void:
	if _note != null:
		return
	_menu_center.visible = false
	_note = NotePanel.new()
	_note.accepted.connect(func() -> void:
		_note.queue_free()
		_note = null
		_menu_center.visible = true
		_first.grab_focus())
	_root.add_child(_note)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _options != null and _options.visible:
		_hide_options()
		get_viewport().set_input_as_handled()
	elif _chapters != null and _chapters.visible:
		_hide_chapters()
		get_viewport().set_input_as_handled()
