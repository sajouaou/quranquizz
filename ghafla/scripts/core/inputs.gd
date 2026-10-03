extends RefCounted
## Actions d'entrée déclarées en code : clavier (QWERTY et AZERTY), manette. Le tactile est géré par l'interface.

const ACTIONS := ["move_left", "move_right", "jump", "interact", "mushaf", "run", "pause", "ui_skip"]


static func ensure_actions() -> void:
	_action("move_left", [KEY_LEFT], [KEY_A, KEY_Q], -1, -1.0)
	_action("move_right", [KEY_RIGHT], [KEY_D], -1, 1.0)
	_action("jump", [KEY_SPACE, KEY_UP], [KEY_W, KEY_Z], JOY_BUTTON_A)
	_action("interact", [KEY_ENTER, KEY_KP_ENTER], [KEY_E], JOY_BUTTON_X)
	_action("mushaf", [KEY_TAB], [KEY_M], JOY_BUTTON_Y)
	_action("run", [KEY_SHIFT], [], JOY_BUTTON_B)
	_action("pause", [KEY_ESCAPE], [KEY_P], JOY_BUTTON_START)
	_action("ui_skip", [KEY_ESCAPE, KEY_ENTER], [], JOY_BUTTON_START)
	# Le stick gauche horizontal : axe 0.
	for entry in [["move_left", -1.0], ["move_right", 1.0]]:
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_LEFT_X
		ev.axis_value = entry[1]
		if not InputMap.action_has_event(entry[0], ev):
			InputMap.action_add_event(entry[0], ev)


static func _action(action: StringName, physical: Array, logical: Array, joy_button: int = -1, _axis: float = 0.0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)
	# Les touches « logiques » suivent la disposition du clavier (ZQSD sur AZERTY, WASD sur QWERTY).
	for key in physical:
		var ev := InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(action, ev)
	for key in logical:
		var ev := InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(action, ev)
	if joy_button >= 0:
		var jb := InputEventJoypadButton.new()
		jb.button_index = joy_button
		InputMap.action_add_event(action, jb)
