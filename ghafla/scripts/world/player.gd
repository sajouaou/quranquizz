extends Node2D
## Le personnage : marche, course, saut, interaction. Sans visage (voir person_rig.gd).
## Les déplacements sont gérés par collision.gd (pas de moteur physique) : un homme qui marche sur un sol,
## des marches douces, quelques plateformes. Sur ce type de jeu, c'est plus simple et plus prévisible.

const Rig := preload("res://scripts/cinematic/person_rig.gd")

signal jumped
signal landed(hard: bool)
signal footstep
signal interact_target_changed(target: Node)

const WALK_SPEED := 250.0
const RUN_SPEED := 400.0
const ACCEL := 1900.0
const FRICTION := 2400.0
const AIR_CONTROL := 0.75
const GRAVITY := 1500.0
const JUMP_V := -560.0
const COYOTE := 0.10
const BUFFER := 0.12
const STEP_UP := 16.0
const SNAP_DOWN := 30.0
const INTERACT_RANGE := 96.0

var rig: Node2D
var camera: Camera2D
var collision: RefCounted
var velocity: Vector2 = Vector2.ZERO
var frozen: bool = false:
	set(v):
		frozen = v
		if v:
			velocity.x = 0.0
var facing: int = 1
var target: Node = null
var last_safe: Vector2 = Vector2.ZERO
var input_x: float = 0.0  # utilisé par les tests pour piloter le personnage sans clavier
var input_jump: bool = false
var input_run: bool = false
var use_scripted_input: bool = false

var _grounded: bool = true
var _coyote: float = 0.0
var _buffer: float = 0.0
var _was_grounded: bool = true
var _fall_speed: float = 0.0
var _step_cell: int = 0
var _safe_timer: float = 0.0
var _visual: Node2D
var _look: float = 0.0
var _idle_time: float = 0.0
var _jump_held_prev: bool = false


func _ready() -> void:
	_visual = Node2D.new()
	_visual.scale = Vector2(0.92, 0.92)
	add_child(_visual)
	rig = Rig.new()
	_visual.add_child(rig)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.5
	camera.drag_vertical_enabled = true
	camera.drag_top_margin = 0.18
	camera.drag_bottom_margin = 0.12
	camera.offset = Vector2(0, -105)
	add_child(camera)
	camera.make_current()
	last_safe = global_position


func is_on_floor() -> bool:
	return _grounded


func _read_input() -> Dictionary:
	if use_scripted_input:
		return {"dir": input_x, "run": input_run, "jump_pressed": input_jump and not _jump_held_prev, "jump_held": input_jump}
	return {
		"dir": Input.get_axis("move_left", "move_right"),
		"run": Input.is_action_pressed("run"),
		"jump_pressed": Input.is_action_just_pressed("jump"),
		"jump_held": Input.is_action_pressed("jump"),
	}


func _physics_process(delta: float) -> void:
	if collision == null:
		return
	var inp := _read_input()
	var dir := 0.0
	var running := false
	var jump_pressed := false
	var jump_held := false
	if not frozen:
		dir = inp["dir"]
		running = inp["run"]
		jump_pressed = inp["jump_pressed"]
		jump_held = inp["jump_held"]
	_jump_held_prev = bool(inp["jump_held"])

	# --- Horizontal
	var wanted := dir * (RUN_SPEED if running else WALK_SPEED)
	var control := 1.0 if _grounded else AIR_CONTROL
	if absf(wanted) > 0.1:
		velocity.x = move_toward(velocity.x, wanted, ACCEL * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * control * delta)
	if absf(velocity.x) > 0.01:
		var res: Array = collision.resolve_x(position.x + velocity.x * delta, position.y, signf(velocity.x))
		position.x = res[0]
		if res[1]:
			velocity.x = 0.0

	# --- Saut (tolérance de bord et de pression anticipée)
	if _grounded:
		_coyote = COYOTE
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	if jump_pressed:
		_buffer = BUFFER
	else:
		_buffer = maxf(_buffer - delta, 0.0)
	if _buffer > 0.0 and _coyote > 0.0 and not frozen:
		velocity.y = JUMP_V
		_grounded = false
		_buffer = 0.0
		_coyote = 0.0
		jumped.emit()

	# --- Vertical
	if _grounded:
		var sy: float = collision.surface_between(position.x, position.y - STEP_UP, position.y + SNAP_DOWN)
		if sy == INF:
			_grounded = false
		else:
			position.y = sy
			velocity.y = 0.0
	if not _grounded:
		var g := GRAVITY
		if velocity.y < 0.0 and not jump_held:
			g *= 2.4  # saut plus court quand on relâche la touche
		velocity.y = minf(velocity.y + g * delta, 1100.0)
		var new_y := position.y + velocity.y * delta
		if velocity.y >= 0.0:
			var sy2: float = collision.surface_between(position.x, position.y - 1.0, new_y + 0.5)
			if sy2 != INF:
				position.y = sy2
				velocity.y = 0.0
				_grounded = true
			else:
				position.y = new_y
		else:
			var fixed_y: float = collision.resolve_head(position.x, new_y)
			if is_nan(fixed_y):
				position.y = new_y
			else:
				position.y = fixed_y
				velocity.y = 0.0
	_fall_speed = maxf(_fall_speed, velocity.y)
	if _grounded and not _was_grounded:
		landed.emit(_fall_speed > 700.0)
	if _grounded:
		_fall_speed = 0.0
	_was_grounded = _grounded

	_animate(delta, dir, running)
	_update_target()


func _animate(delta: float, dir: float, running: bool) -> void:
	if absf(dir) > 0.05:
		facing = 1 if dir > 0.0 else -1
		rig.facing = facing
		_idle_time = 0.0
	else:
		_idle_time += delta
	rig.walking = _grounded and absf(velocity.x) > 25.0
	rig.running = running and rig.walking
	rig.airborne = not _grounded
	if rig.walking:
		var cell := int(floorf(rig.phase / PI))
		if cell != _step_cell:
			_step_cell = cell
			footstep.emit()
	elif not rig.airborne and not frozen:
		# Repos : posture neutre (sauf si une cinématique a pris la main).
		rig.foot_f = rig.foot_f.lerp(Vector2(10, 0), 0.25)
		rig.foot_b = rig.foot_b.lerp(Vector2(-10, 0), 0.25)
		rig.hip = rig.hip.lerp(Vector2(0, -86), 0.25)
		rig.hand_f = rig.hand_f.lerp(Vector2(6, 50), 0.2)
		rig.hand_b = rig.hand_b.lerp(Vector2(2, 50), 0.2)
		rig.body_rot = lerpf(rig.body_rot, 0.0, 0.2)
	rig.breath = 0.8 if not rig.walking else 0.0

	# Caméra : regarde un peu devant soi
	var ahead := 130.0 if absf(velocity.x) > 30.0 else 60.0
	_look = lerpf(_look, float(facing) * ahead, 1.0 - exp(-3.0 * delta))
	camera.offset = Vector2(_look, -105.0)

	# Dernière position sûre (respawn si l'on tombe dans le vide)
	_safe_timer += delta
	if _safe_timer > 0.4 and _grounded and position.y < 1000.0:
		_safe_timer = 0.0
		last_safe = position


func _update_target() -> void:
	var best: Node = null
	var best_d := INTERACT_RANGE * INTERACT_RANGE
	var chest := position + Vector2(0, -70)
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node2D) or not n.can_interact():
			continue
		var d := chest.distance_squared_to((n as Node2D).global_position + Vector2(0, float(n.get("focus_dy") if n.get("focus_dy") != null else 0.0)))
		if d < best_d:
			best_d = d
			best = n
	if best != target:
		target = best
		interact_target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if frozen or target == null:
		return
	if event.is_action_pressed("interact"):
		do_interact()
		get_viewport().set_input_as_handled()


func do_interact() -> void:
	if frozen or target == null:
		return
	if target.has_method("interact"):
		target.interact(self)


## Immobile depuis n secondes ? (indices « patience » du jeu)
func idle_time() -> float:
	return _idle_time if _grounded else 0.0


func teleport(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	last_safe = pos
	_grounded = false
	camera.reset_smoothing()


func respawn() -> void:
	teleport(last_safe)
