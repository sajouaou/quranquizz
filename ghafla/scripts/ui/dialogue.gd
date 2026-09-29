extends Control
## Sous-titres et scènes de dialogue. Deux styles :
##  - scène : le joueur est immobilisé, on lit « sens approximatif » puis les pensées du personnage (E / clic pour avancer) ;
##  - murmure : une ligne discrète qui s'efface toute seule, sans bloquer.
## Un « sens approximatif » est une traduction de sens, jamais le texte du Coran.

const P := preload("res://scripts/core/palette.gd")
const UiTheme := preload("res://scripts/ui/ui_theme.gd")
const Assets := preload("res://scripts/core/assets.gd")

signal scene_started
signal scene_finished

var active: bool = false

var _panel: PanelContainer
var _kicker: Label
var _text: Label
var _hint: Label
var _whisper: Label
var _items: Array = []  # [{kind: "meaning"|"line", text, ref}]
var _index: int = 0
var _typing: Tween
var _done: Callable
var _whisper_queue: Array = []
var _whisper_busy: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.03, 0.03, 0.1, 0.9), P.GOLD_DEEP, 18, 2))
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -470
	_panel.offset_right = 470
	_panel.offset_top = -232
	_panel.offset_bottom = -34
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	_panel.visible = false
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	_kicker = Label.new()
	_kicker.add_theme_font_size_override("font_size", 17)
	_kicker.add_theme_color_override("font_color", P.GOLD)
	box.add_child(_kicker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 27)
	box.add_child(_text)
	_hint = Label.new()
	_hint.text = "E · Entrée · toucher : continuer"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	box.add_child(_hint)

	_whisper = Label.new()
	_whisper.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_whisper.anchor_left = 0.5
	_whisper.anchor_right = 0.5
	_whisper.anchor_top = 1.0
	_whisper.anchor_bottom = 1.0
	_whisper.offset_left = -520
	_whisper.offset_right = 520
	_whisper.offset_top = -120
	_whisper.offset_bottom = -60
	_whisper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_whisper.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_whisper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_whisper.add_theme_font_size_override("font_size", 25)
	_whisper.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	_whisper.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.95))
	_whisper.add_theme_constant_override("outline_size", 8)
	_whisper.modulate.a = 0.0
	_whisper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_whisper)


## Lance une scène : `meaning` = {text, ref} facultatif, puis les lignes de pensée.
func show_scene(lines: Array, meaning: Dictionary, on_done: Callable) -> void:
	_items.clear()
	if not meaning.is_empty():
		_items.append({"kind": "meaning", "text": str(meaning.get("text", "")), "ref": str(meaning.get("ref", ""))})
	for l in lines:
		_items.append({"kind": "line", "text": str(l)})
	if _items.is_empty():
		on_done.call()
		return
	_done = on_done
	_index = 0
	active = true
	_panel.visible = true
	_whisper.visible = false  # les murmures attendent la fin de la scène
	scene_started.emit()
	_show_item()


func _show_item() -> void:
	var it: Dictionary = _items[_index]
	if it["kind"] == "meaning":
		_kicker.text = "Sens approximatif de %s" % it["ref"]
		_text.text = "« %s »" % it["text"]
		_text.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72))
	else:
		_kicker.text = ""
		_text.text = it["text"]
		_text.add_theme_color_override("font_color", P.PARCHMENT)
	_text.visible_ratio = 0.0
	if _typing != null and _typing.is_valid():
		_typing.kill()
	var chars := maxi(1, _text.text.length())
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, minf(2.2, 0.018 * float(chars)))


func advance() -> void:
	if not active:
		return
	if _text.visible_ratio < 0.999:
		if _typing != null and _typing.is_valid():
			_typing.kill()
		_text.visible_ratio = 1.0
		return
	_index += 1
	if _index >= _items.size():
		_close()
	else:
		_show_item()


func _close() -> void:
	active = false
	_panel.visible = false
	_whisper.visible = true
	if not _whisper_busy:
		_next_whisper()
	var cb := _done
	_done = Callable()
	scene_finished.emit()
	if cb.is_valid():
		cb.call()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	elif event is InputEventScreenTouch and event.pressed:
		advance()


## Ligne discrète, en file d'attente, qui s'efface seule.
func whisper(text: String) -> void:
	_whisper_queue.append(text)
	if not _whisper_busy and not active:
		_next_whisper()


func _next_whisper() -> void:
	if _whisper_queue.is_empty() or active:
		_whisper_busy = false
		_whisper.modulate.a = 0.0
		return
	_whisper_busy = true
	_whisper.text = _whisper_queue.pop_front()
	var hold := clampf(1.8 + 0.045 * float(_whisper.text.length()), 2.5, 6.0)
	var tw := create_tween()
	tw.tween_property(_whisper, "modulate:a", 1.0, 0.6)
	tw.tween_interval(hold)
	tw.tween_property(_whisper, "modulate:a", 0.0, 0.9)
	tw.tween_callback(_next_whisper)
