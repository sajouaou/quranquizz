extends Node2D
## Particules d'ambiance : poussières de lumière qui flottent autour de la caméra.

const DrawUtil := preload("res://scripts/core/draw_util.gd")

var world: Node2D
var _motes: Array = []
var _t: float = 0.0
var _add: CanvasItemMaterial


func _ready() -> void:
	_add = CanvasItemMaterial.new()
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _add


func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_t += delta
	var vp := get_viewport_rect().size
	var cam: Vector2 = world.player.camera.get_screen_center_position()
	var rect := Rect2(cam - vp * 0.5 - Vector2(120, 120), vp + Vector2(240, 240))
	while _motes.size() < 70:
		_motes.append(_spawn(rect, true))
	for i in range(_motes.size()):
		var m: Dictionary = _motes[i]
		m["p"] += m["v"] * delta + Vector2(sin(_t * 0.6 + m["ph"]) * 6.0 * delta, 0.0)
		if not rect.has_point(m["p"]):
			_motes[i] = _spawn(rect, false)
	queue_redraw()


func _spawn(rect: Rect2, anywhere: bool) -> Dictionary:
	var p := Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	if not anywhere:
		p = Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y - randf() * 30.0)
	return {"p": p, "v": Vector2(randf_range(-6.0, 6.0), randf_range(-22.0, -6.0)), "s": randf_range(0.8, 2.2), "ph": randf() * TAU}


func _draw() -> void:
	if world == null:
		return
	var z: String = world.zone
	var col := Color(1.0, 0.88, 0.6, 0.55)
	match z:
		"market":
			col = Color(1.0, 0.8, 0.55, 0.6)
		"cave":
			col = Color(0.6, 0.85, 1.0, 0.55)
		"peak":
			col = Color(0.9, 0.93, 1.0, 0.6)
	for m in _motes:
		var tw := 0.5 + 0.5 * sin(_t * 1.5 + m["ph"])
		DrawUtil.glow(self, m["p"], 5.0 * m["s"], Color(col.r, col.g, col.b, col.a * tw))
