extends RefCounted
## Le dernier chemin (x 12400-17800) : une route de nuit, à flanc de colline, qui longe un cimetière sans y entrer.
## Un muret de pierre borde le chemin ; les tombes ne se voient que de loin, sur la colline (dessinées par backdrop.gd) :
## de simples dalles nues, sans inscription ni ornement. Les pages du Mushaf sont sur le chemin, jamais parmi les tombes.
## Le rêve y rappelle ce que le regret dit trop tard, et qu'il reste encore du temps. Fin du chapitre : la porte de l'aube.


func build(w: Node2D) -> void:
	w.add_ground(PackedVector2Array([
		Vector2(12400, 620), Vector2(13400, 620), Vector2(14200, 612), Vector2(15200, 620), Vector2(16400, 620), Vector2(17800, 620),
	]), 73)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	# Le muret qui sépare le chemin du cimetière, avec quelques ouvertures par où l'on voit la colline
	var x := 12560.0
	while x < 16900.0:
		var span := rng.randf_range(520.0, 900.0)
		w.add_prop("low_wall", Vector2(x + span * 0.5, w.ground_at(x + span * 0.5)), {"w": span, "h": rng.randf_range(54.0, 66.0), "seed": int(x)})
		x += span + rng.randf_range(150.0, 260.0)
	# Arbres sombres, pierres et quelques lanternes au bord de la route
	for tx in [12780.0, 13700.0, 14950.0, 15850.0, 16500.0]:
		w.add_prop("tree", Vector2(tx, w.ground_at(tx)), {"h": 210.0 + float(int(tx) % 50), "hue": 0.64, "seed": int(tx)})
	for lx in [13150.0, 14700.0, 16200.0]:
		w.add_prop("lamp_post", Vector2(lx, w.ground_at(lx)), {"h": 180.0})
	# la pierre au bord du chemin où une page attend, et quelques autres
	for r in [[14400.0, 110.0, 56.0], [13540.0, 80.0, 40.0], [15320.0, 130.0, 62.0], [16820.0, 90.0, 44.0]]:
		w.add_prop("rock", Vector2(r[0] + 70.0, w.ground_at(r[0] + 70.0) + 2.0), {"w": r[1], "h": r[2], "color": Color("3a3f66")})
	w.add_prop("bench", Vector2(15560.0, w.ground_at(15560.0)), {"w": 120.0})
	for mx in [12900.0, 14300.0, 15700.0]:
		w.add_prop("mist", Vector2(mx, 620), {"w": 1100.0}, true)
	# la porte de l'aube, au bout
	w.add_prop("gate_dawn", Vector2(17250, 620), {"w": 250.0, "h": 320.0})
	w.add_glow(Vector2(17250.0, 500.0), 460.0, Color(1.0, 0.86, 0.55, 0.30), 0.05)
