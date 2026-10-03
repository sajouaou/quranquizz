extends RefCounted
## La rue de l'ivresse (x 9600-12400) : nuit violette, néons, bouteilles. Trois tables, trois étapes :
## le vin est d'abord présenté avec ses torts et ses avantages, puis la prière est protégée, puis il est écarté.
## Décor seulement : verres, bouteilles, néons ; personne.


func build(w: Node2D) -> void:
	w.add_ground(PackedVector2Array([
		Vector2(9600, 620), Vector2(10400, 620), Vector2(11000, 614), Vector2(11600, 620), Vector2(12400, 620),
	]), 57)
	var i := 0
	var x := 9850.0
	while x < 12300.0:
		var h := 280.0 + float((i * 61) % 130)
		w.add_prop("facade", Vector2(x, 620), {"w": 240.0, "h": h, "seed": i + 90, "tint": Color("4a2a5a").lerp(Color("6a3a70"), float(i % 3) / 3.0), "style": "flat"})
		x += 330.0 + float((i * 37) % 70)
		i += 1
	for sx in [9900.0, 10650.0, 11400.0, 12150.0]:
		w.add_prop("bottle_shelf", Vector2(sx, 620), {"w": 200.0, "h": 260.0 + float(int(sx) % 80), "seed": int(sx)})
	var colors := [Color(1.0, 0.3, 0.7), Color(0.4, 0.6, 1.0), Color(0.9, 0.5, 0.2)]
	for k in range(6):
		w.add_prop("neon_tube", Vector2(9800.0 + float(k) * 470.0, 620), {"w": 240.0, "y": 300.0 + float((k * 37) % 90), "color": colors[k % 3]})
	# les trois tables, dans l'ordre de la révélation
	for tx in [10200.0, 11000.0, 11800.0]:
		w.add_prop("bar_table", Vector2(tx, w.ground_at(tx)), {"seed": int(tx)})
	for lx in [9750.0, 10600.0, 11400.0, 12250.0]:
		w.add_prop("lamp_post", Vector2(lx, w.ground_at(lx)), {"h": 180.0}, true)
