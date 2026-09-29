extends RefCounted
## La rue endormie (x 1935-4200) puis le pont de nuages (x 4200-4980).
## Le quartier que l'homme connaît... mais figé à l'aube qu'il a manquée, sans personne.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")

const TINTS := [Color("c7a4c8"), Color("d6b0b6"), Color("b9a2cf"), Color("dcbfa6"), Color("aab0d4")]


func build(w: Node2D) -> void:
	# Chaussée de la rue : presque plate, avec de légères ondulations
	var street := PackedVector2Array([
		Vector2(1935, 620), Vector2(2600, 620), Vector2(3000, 611), Vector2(3400, 626),
		Vector2(3800, 620), Vector2(4200, 620),
	])
	w.add_ground(street, 11)

	# Façades du quartier, au second plan
	var x := 2230.0
	var i := 0
	while x < 3760.0:
		var h := 250.0 + float((i * 53) % 110)
		w.add_prop("facade", Vector2(x, 620), {"w": 230.0 + float((i * 31) % 60), "h": h, "seed": i + 1, "tint": TINTS[i % TINTS.size()], "style": "dome" if i % 3 == 1 else "flat"})
		x += 330.0 + float((i * 47) % 70)
		i += 1
	# La mosquée du quartier, fermée et silencieuse, illuminée par l'aube
	w.add_prop("mosque", Vector2(3990, 620), {"w": 300.0, "h": 190.0, "tint": Color("dccbe0")})

	# Lampadaires et arbres
	for lx in [2130.0, 2580.0, 3040.0, 3500.0, 3900.0]:
		w.add_prop("lamp_post", Vector2(lx, w.ground_at(lx)), {"h": 190.0}, true)
	for tx in [2400.0, 2860.0, 3310.0, 3720.0]:
		w.add_prop("tree", Vector2(tx, w.ground_at(tx)), {"h": 210.0 + float(int(tx) % 40), "hue": 0.7 + float(int(tx) % 5) * 0.02, "seed": int(tx)})
	w.add_prop("bench", Vector2(3450.0, w.ground_at(3450.0)), {"w": 120.0})
	w.add_prop("grass_tufts", Vector2(2000.0, 620), {"n": 60, "seed": 4}, true)
	w.add_prop("grass_tufts", Vector2(3300.0, 620), {"n": 60, "seed": 8}, true)

	_build_bridge(w)


func _build_bridge(w: Node2D) -> void:
	# Mer de nuages : le vide sous le pont, doux et lumineux. On n'y tombe pas : le rêve ramène en arrière.
	w.add_prop("cloud_sea", Vector2(4590, 640), {"x0": 4100.0, "x1": 5100.0})
	# Pierres flottantes espacées d'un pas de course tranquille
	var stones := [
		Rect2(4240, 620, 170, 30), Rect2(4500, 604, 160, 30), Rect2(4760, 620, 170, 30),
	]
	for r in stones:
		w.add_stone(r, Color("6d5c8f"))
	# Un dernier tronçon avant le souk
	w.add_prop("lamp_post", Vector2(4340, 620), {"h": 170.0}, true)
	w.add_prop("lamp_post", Vector2(4860, 620), {"h": 170.0}, true)
