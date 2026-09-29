extends Control
## Interface en jeu : compteur de pages, objectif, invite d'interaction, messages, petit Mushaf en haut à gauche.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")

signal mushaf_pressed
signal pause_pressed

var total: int = 604
var _count: int = 0
var _count_label: Label
var _bar: ProgressBar
var _objective: Label
var _toast: Label
var _prompt_panel: PanelContainer
var _prompt: Label
var _icon: Control
var _key_badge: Label
var _controls: Label
var _toast_tween: Tween
var _obj_tween: Tween
var _touch: bool = false
var _pulse: float = 0.0


class MushafIcon:
	extends Control
	var pulse: float = 0.0
	var fill: float = 0.0

	func _draw() -> void:
		var s := 1.0 + pulse * 0.25
		var c := size * 0.5
		draw_set_transform(c, 0.0, Vector2(s, s))
		var w := 34.0
		var h := 46.0
		DrawUtil.rrect(self, Rect2(-w / 2.0 + 2.0, -h / 2.0 + 3.0, w, h), Color(0, 0, 0, 0.3), 5.0)
		DrawUtil.rrect(self, Rect2(-w / 2.0, -h / 2.0, w, h), Color("1f6f5c"), 5.0, Color("e9c46a"), 2)
		draw_colored_polygon(DrawUtil.star(Vector2(0, -2), 10.0, 5.0, 8), Color("e9c46a"))
		# reflet doré proportionnel à la progression
		draw_rect(Rect2(-w / 2.0 + 4.0, h / 2.0 - 8.0, (w - 8.0) * fill, 3.0), Color("f5eedc"))


class FlyingPage:
	extends Control
	func _draw() -> void:
		DrawUtil.rrect(self, Rect2(-18, -25, 36, 50), Color("f5eedc"), 5.0, Color("b8862b"), 2)
		draw_colored_polygon(DrawUtil.star(Vector2(0, -15), 5.0, 2.6, 8), Color("b8862b"))
		for i in range(6):
			draw_line(Vector2(-11, -6.0 + float(i) * 5.0), Vector2(11, -6.0 + float(i) * 5.0), Color(0.35, 0.27, 0.12, 0.7), 1.6, true)
		DrawUtil.glow(self, Vector2.ZERO, 70.0, Color(1.0, 0.86, 0.5, 0.5))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	# En haut à gauche : petit Mushaf et compteur
	var top_left := HBoxContainer.new()
	top_left.position = Vector2(26, 20)
	top_left.add_theme_constant_override("separation", 12)
	add_child(top_left)
	_icon = MushafIcon.new()
	_icon.custom_minimum_size = Vector2(56, 64)
	top_left.add_child(_icon)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	top_left.add_child(col)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 30)
	_count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	_count_label.add_theme_constant_override("outline_size", 6)
	col.add_child(_count_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(150, 7)
	_bar.show_percentage = false
	_bar.max_value = 604.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.2)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = P.GOLD
	fg.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fg)
	col.add_child(_bar)
	_key_badge = Label.new()
	_key_badge.text = "Clé du coffre"
	_key_badge.add_theme_font_size_override("font_size", 16)
	_key_badge.add_theme_color_override("font_color", P.GOLD)
	_key_badge.visible = false
	col.add_child(_key_badge)

	# En haut à droite : boutons pour la souris et le tactile
	var top_right := HBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -300
	top_right.offset_right = -24
	top_right.offset_top = 22
	top_right.add_theme_constant_override("separation", 10)
	add_child(top_right)
	var b1 := Button.new()
	b1.text = "Mushaf"
	b1.focus_mode = Control.FOCUS_NONE
	b1.pressed.connect(func() -> void: mushaf_pressed.emit())
	top_right.add_child(b1)
	var b2 := Button.new()
	b2.text = "Pause"
	b2.focus_mode = Control.FOCUS_NONE
	b2.pressed.connect(func() -> void: pause_pressed.emit())
	top_right.add_child(b2)

	_objective = Label.new()
	_objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective.anchor_left = 0.5
	_objective.anchor_right = 0.5
	_objective.offset_left = -420
	_objective.offset_right = 420
	_objective.offset_top = 20
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.add_theme_font_size_override("font_size", 23)
	_objective.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	_objective.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.95))
	_objective.add_theme_constant_override("outline_size", 7)
	_objective.modulate.a = 0.0
	add_child(_objective)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.offset_left = -430
	_toast.offset_right = 430
	_toast.offset_top = 74
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.95))
	_toast.add_theme_constant_override("outline_size", 7)
	_toast.modulate.a = 0.0
	add_child(_toast)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.03, 0.03, 0.1, 0.8), P.GOLD, 22, 2))
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = -190
	_prompt_panel.offset_right = 190
	_prompt_panel.offset_top = -292
	_prompt_panel.offset_bottom = -246
	_prompt_panel.visible = false
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_panel)
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 23)
	_prompt_panel.add_child(_prompt)

	_controls = Label.new()
	_controls.text = "Flèches ou Q / D : marcher   ·   Espace : sauter   ·   E : agir   ·   M : Mushaf   ·   Échap : pause"
	_controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_controls.anchor_top = 1.0
	_controls.anchor_bottom = 1.0
	_controls.offset_left = 26
	_controls.offset_top = -44
	_controls.offset_right = 1250
	_controls.add_theme_font_size_override("font_size", 16)
	_controls.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_controls.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.9))
	_controls.add_theme_constant_override("outline_size", 5)
	_controls.modulate.a = 0.0
	add_child(_controls)
	set_count(0)


func set_touch(on: bool) -> void:
	_touch = on
	_controls.visible = not on


func set_total(n: int) -> void:
	total = n
	_bar.max_value = float(n)
	set_count(_count)


func set_count(n: int) -> void:
	_count = n
	_count_label.text = "%d / %d" % [n, total]
	_bar.value = float(n)
	(_icon as MushafIcon).fill = float(n) / float(maxi(1, total))
	_icon.queue_redraw()


func set_key(has_key: bool) -> void:
	_key_badge.visible = has_key


func set_prompt(text: String) -> void:
	if text == "":
		_prompt_panel.visible = false
		return
	var key := "Toucher" if _touch else "E"
	_prompt.text = "[%s]  %s" % [key, text]
	_prompt_panel.visible = true


func set_objective(text: String) -> void:
	_objective.text = text
	if _obj_tween != null and _obj_tween.is_valid():
		_obj_tween.kill()
	_obj_tween = create_tween()
	_obj_tween.tween_property(_objective, "modulate:a", 1.0, 0.8)
	_obj_tween.tween_interval(6.0)
	_obj_tween.tween_property(_objective, "modulate:a", 0.55, 1.5)


func toast(text: String, color: Color = Color(1, 0.95, 0.8)) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.35)
	_toast_tween.tween_interval(3.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)


func show_controls_hint() -> void:
	if _touch:
		return
	var tw := create_tween()
	tw.tween_property(_controls, "modulate:a", 1.0, 1.0)
	tw.tween_interval(14.0)
	tw.tween_property(_controls, "modulate:a", 0.0, 2.0)


## La page prise s'envole vers le petit Mushaf.
func fly_page(from_screen: Vector2) -> void:
	var page := FlyingPage.new()
	page.position = from_screen
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	var target := _icon.global_position + _icon.size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(page, "position", target, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(page, "scale", Vector2(0.4, 0.4), 1.0)
	tw.chain().tween_callback(func() -> void:
		page.queue_free()
		pulse_icon())


func pulse_icon() -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		(_icon as MushafIcon).pulse = v
		_icon.queue_redraw(), 0.0, 1.0, 0.18)
	tw.tween_method(func(v: float) -> void:
		(_icon as MushafIcon).pulse = v
		_icon.queue_redraw(), 1.0, 0.0, 0.35)
