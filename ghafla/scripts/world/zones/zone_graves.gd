extends RefCounted
## Les tombes (x 12400-17800) : une nuit profonde et des tertres de terre, de simples dalles sans inscription ni ornement.
## Le rêve y rappelle ce que le regret dit trop tard, et qu'il reste encore du temps. Fin du chapitre : la porte de l'aube.


func build(w: Node2D) -> void:
	w.add_ground(PackedVector2Array([
		Vector2(12400, 620), Vector2(13400, 620), Vector2(14200, 612), Vector2(15200, 620), Vector2(16400, 620), Vector2(17800, 620),
	]), 73)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var x := 12600.0
	while x < 17000.0:
		w.add_prop("mounds", Vector2(x, 620), {"n": 2 + int(rng.randf() * 2.0)})
		var k := 1 + int(rng.randf() * 3.0)
		for j in range(k):
			w.add_prop("grave_stone", Vector2(x + float(j) * 150.0 + 40.0, 620), {"w": rng.randf_range(30.0, 46.0), "h": rng.randf_range(70.0, 130.0), "lean": rng.randf_range(-0.05, 0.05), "color": Color("5a608a").lerp(Color("8088b8"), rng.randf())}, rng.randf() < 0.4)
		x += rng.randf_range(300.0, 460.0)
	for tx in [13000.0, 14000.0, 15100.0, 16000.0]:
		w.add_prop("dead_tree", Vector2(tx, 620), {"h": 150.0 + float(int(tx) % 60), "seed": int(tx)})
	for mx in [12900.0, 14300.0, 15700.0]:
		w.add_prop("mist", Vector2(mx, 620), {"w": 1100.0}, true)
	# la porte de l'aube, au bout
	w.add_prop("gate_dawn", Vector2(17250, 620), {"w": 250.0, "h": 320.0})
	w.add_glow(Vector2(17250.0, 500.0), 460.0, Color(1.0, 0.86, 0.55, 0.30), 0.05)
