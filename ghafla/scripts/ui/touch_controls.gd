extends Control
## Commandes tactiles : ◀ ▶ à gauche, saut et action à droite. Multi-touch : on peut marcher et sauter en même temps.
## Le Mushaf et la pause ont leurs propres boutons dans le HUD. Sur PC, la souris peut aussi servir de doigt
## (uniquement s'il n'y a pas d'écran tactile), ce qui permet de tester sans téléphone.

const P := preload("res://scripts/core/palette.gd")

var _buttons: Dictionary = {}  # action -> {center: Vector2, radius: float, label: String}
var _pointers: Dictionary = {}  # index du doigt (-1 : souris) -> action
var _held: Dictionary = {}  # action -> bool
var mouse_ok: bool = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_ok = not DisplayServer.is_touchscreen_available()
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var s := size
	if s.x < 10.0:
		s = get_viewport_rect().size
	var m := 22.0
	var r := 62.0
	_buttons = {
		"move_left": {"center": Vector2(m + r, s.y - m - r), "radius": r, "label": "◀"},
		"move_right": {"center": Vector2(m + r * 3.0 + 22.0, s.y - m - r), "radius": r, "label": "▶"},
		"jump": {"center": Vector2(s.x - m - r, s.y - m - r), "radius": r + 8.0, "label": "↑"},
		"interact": {"center": Vector2(s.x - m - r * 3.0 - 30.0, s.y - m - r - 26.0), "radius": r - 8.0, "label": "E"},
	}
	queue_redraw()


func _draw() -> void:
	for a in _buttons.keys():
		var b: Dictionary = _buttons[a]
		var on: bool = _held.get(a, false)
		var c: Vector2 = b["center"]
		var r: float = b["radius"]
		draw_circle(c, r, Color(0.05, 0.04, 0.16, 0.55 if not on else 0.8))
		draw_arc(c, r, 0.0, TAU, 40, Color(0.91, 0.77, 0.42, 0.75 if not on else 1.0), 3.0, true)
		var ink := Color(1, 0.95, 0.8, 0.92)
		var k := r * 0.36
		match a:
			"move_left":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-k, 0), c + Vector2(k * 0.7, -k), c + Vector2(k * 0.7, k)]), ink)
			"move_right":
				draw_colored_polygon(PackedVector2Array([c + Vector2(k, 0), c + Vector2(-k * 0.7, -k), c + Vector2(-k * 0.7, k)]), ink)
			"jump":
				draw_polyline(PackedVector2Array([c + Vector2(-k, k * 0.5), c + Vector2(0, -k * 0.6), c + Vector2(k, k * 0.5)]), ink, 7.0, true)
			"interact":
				var font := ThemeDB.fallback_font
				var w := font.get_string_size("E", HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
				draw_string(font, c + Vector2(-w * 0.5, 16.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, ink)


func _action_at(pos: Vector2) -> String:
	var best := ""
	var best_d := 1.0e9
	for a in _buttons.keys():
		var b: Dictionary = _buttons[a]
		var d := pos.distance_to(b["center"])
		# zone de toucher un peu plus large que le bouton dessiné
		if d <= float(b["radius"]) * 1.25 and d < best_d:
			best = a
			best_d = d
	return best


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_pointer_set(event.index, _action_at(event.position) if event.pressed else "")
	elif event is InputEventScreenDrag:
		_pointer_set(event.index, _action_at(event.position))
	elif mouse_ok and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer_set(-1, _action_at(event.position) if event.pressed else "")
	elif mouse_ok and event is InputEventMouseMotion and _pointers.has(-1):
		_pointer_set(-1, _action_at(event.position))


func _pointer_set(index: int, action: String) -> void:
	var old: String = _pointers.get(index, "")
	if old == action:
		return
	if action == "":
		_pointers.erase(index)
	else:
		_pointers[index] = action
	_sync()


func _sync() -> void:
	var now := {}
	for a in _pointers.values():
		now[a] = true
	for a in _buttons.keys():
		var was: bool = _held.get(a, false)
		var is_on: bool = now.has(a)
		if was != is_on:
			_held[a] = is_on
			set_action(a, is_on)
	queue_redraw()


## Appuie ou relâche une action : l'état (pour Input.get_axis, is_action_pressed) et l'événement
## (pour les _unhandled_input qui écoutent is_action_pressed) sont tous deux mis à jour.
static func set_action(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = on
	Input.parse_input_event(ev)


func _exit_tree() -> void:
	_pointers.clear()
	_sync()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_pointers.clear()
		_sync()
