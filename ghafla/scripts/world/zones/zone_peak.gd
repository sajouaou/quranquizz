extends RefCounted
## Le sommet (x 12300-15600) : un sentier qui monte sous les étoiles, et sept anneaux dans le ciel.
## En haut, une porte de lumière : celle de l'aube qui revient.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")


func build(w: Node2D) -> void:
	var line := PackedVector2Array([
		Vector2(12300, 620), Vector2(12600, 610), Vector2(12900, 585), Vector2(13150, 545),
		Vector2(13400, 500), Vector2(13560, 500), Vector2(13800, 455), Vector2(14050, 395),
		Vector2(14250, 395), Vector2(14500, 320), Vector2(14750, 250), Vector2(14950, 205),
		Vector2(15600, 205),
	])
	w.add_ground(line, 45)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1515
	var x := 12380.0
	while x < 15050.0:
		var side := rng.randf() < 0.5
		w.add_prop("rock", Vector2(x, w.ground_at(x) + 4.0), {"w": rng.randf_range(90.0, 220.0), "h": rng.randf_range(50.0, 150.0), "color": Color("3b3560").lerp(Color("5a5088"), rng.randf() * 0.5)}, side)
		x += rng.randf_range(160.0, 330.0)
	# La porte de l'aube
	w.add_prop("gate_dawn", Vector2(15300, 205), {"w": 250.0, "h": 320.0})
	w.add_glow(Vector2(15300.0, 120.0), 460.0, Color(1.0, 0.86, 0.55, 0.32), 0.05)
