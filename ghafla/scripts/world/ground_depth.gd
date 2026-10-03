extends Node2D
## Le sol vu en perspective (effet « 2.5D ») : des joints de dallage qui partent du bord du chemin vers le bas de l'écran
## en s'écartant, comme les lignes d'un sol qui fuit vers un point situé au centre de l'image. Quand le personnage avance,
## ces lignes pivotent : le sol devient un plan qui s'étend vers le spectateur, et non une simple bande de couleur.
## Redessiné seulement quand la caméra bouge. Rien dans la maison (elle est vue en coupe).

const P := preload("res://scripts/core/palette.gd")
const Gfx := preload("res://scripts/core/gfx.gd")

const STEP := 130.0  # un joint tous les 130 px de monde
const DEPTH := 260.0  # longueur des joints, vers le bas de l'écran
const SPREAD := 0.62  # écartement : 0 = joints verticaux, 1 = très ouverts

var world: Node2D
var _last: Vector2 = Vector2(-1.0e9, 0.0)
var _was_low: bool = false


func _process(_delta: float) -> void:
	if world == null or world.player == null:
		return
	var cam: Vector2 = world.player.camera.get_screen_center_position()
	if cam.distance_to(_last) > 1.5 or _was_low != Gfx.low():
		_last = cam
		_was_low = Gfx.low()
		queue_redraw()


func _draw() -> void:
	if world == null or world.player == null or Gfx.low():
		return
	var cam: Vector2 = world.player.camera.get_screen_center_position()
	var half := get_viewport_rect().size.x * 0.62
	var sky := P.sky_at(cam.x, world.chapter)
	var base: Color = (sky["bottom"] as Color).lerp(P.NIGHT, 0.7)
	var x := floorf((cam.x - half * 1.7) / STEP) * STEP
	while x < cam.x + half * 1.7:
		var zone: String = world.zone_at(x)
		var gy: float = world.collision.ground_height(x, INF)
		if gy != INF and zone != "house" and zone != "home" and x > 0.0 and x < world.world_w:
			var top := Vector2(x, gy + 3.0)
			var bottom := Vector2(x + (x - cam.x) * SPREAD, gy + DEPTH)
			var mid := top.lerp(bottom, 0.45)
			draw_polyline_colors(PackedVector2Array([top, mid, bottom]), PackedColorArray([Color(base, 0.30), Color(base, 0.16), Color(base, 0.0)]), 2.0, true)
		x += STEP
