extends RefCounted
## La ville des amoureux (x 1935-6400) : guirlandes de cœurs, roses, tables pour deux, ballons.
## Personne : des chaises vides et des tasses fumantes. Le rêve montre l'apparence de l'amour, sans lendemain,
## et rien d'indécent ni de moqueur : seulement du décor.

const TINTS := [Color("e4a9be"), Color("d9b0c8"), Color("f0b8b0"), Color("cfa6d0"), Color("e8c0a8")]


func build(w: Node2D) -> void:
	w.add_ground(PackedVector2Array([
		Vector2(1935, 620), Vector2(2800, 620), Vector2(3300, 614), Vector2(4200, 620),
		Vector2(5000, 616), Vector2(5600, 620), Vector2(6400, 620),
	]), 41)
	# façades illuminées, au second plan
	var x := 2200.0
	var i := 0
	while x < 6100.0:
		var h := 260.0 + float((i * 47) % 120)
		w.add_prop("facade", Vector2(x, 620), {"w": 230.0 + float((i * 29) % 70), "h": h, "seed": i + 40, "tint": TINTS[i % TINTS.size()], "style": "dome" if i % 4 == 1 else "flat"})
		x += 320.0 + float((i * 43) % 80)
		i += 1
	# guirlandes de cœurs entre des poteaux
	for gx in [2350.0, 3250.0, 4150.0, 5050.0, 5750.0]:
		w.add_prop("heart_garland", Vector2(gx, 620), {"w": 520.0, "h": 250.0, "n": 9}, true)
	for lx in [2600.0, 3500.0, 4400.0, 5300.0, 6000.0]:
		w.add_prop("lamp_post", Vector2(lx, w.ground_at(lx)), {"h": 190.0}, true)
	# roses, bancs et tables pour deux
	for rx in [2500.0, 3050.0, 3900.0, 4550.0, 5450.0]:
		w.add_prop("rose_bush", Vector2(rx, w.ground_at(rx)), {"w": 120.0, "seed": int(rx)}, true)
	w.add_prop("bench_pair", Vector2(3350.0, w.ground_at(3350.0)), {"w": 130.0})
	w.add_prop("bench_pair", Vector2(4720.0, w.ground_at(4720.0)), {"w": 130.0})
	for cx in [4250.0, 5150.0, 5450.0]:
		w.add_prop("candle_table", Vector2(cx, w.ground_at(cx)), {})
	for bx in [2450.0, 3800.0, 4950.0, 5900.0]:
		w.add_prop("heart_balloon", Vector2(bx, w.ground_at(bx)), {"len": 190.0 + float(int(bx) % 60), "seed": int(bx)}, true)
	# au bout de la rue, la mosquée du quartier, fermée et silencieuse, dans la lumière du soir
	w.add_prop("mosque", Vector2(6250, 620), {"w": 300.0, "h": 190.0, "tint": Color("dccbe0")})
