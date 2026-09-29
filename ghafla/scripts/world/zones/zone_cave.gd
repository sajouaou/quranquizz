extends RefCounted
## La grotte (x 8500-12300) : une longue caverne dans la montagne, éclairée par les pages elles-mêmes
## et par quelques cristaux. Douze pages s'y trouvent (les douze pages de la sourate Al-Kahf), les unes
## visibles, les autres cachées, certaines sur des corniches. La dernière est scellée.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Interactable := preload("res://scripts/world/interactable.gd")

const CRYSTALS := [9300.0, 9820.0, 10130.0, 10560.0, 11000.0, 11420.0, 11700.0, 12000.0]
const COLORS := [Color(0.5, 0.85, 1.0, 0.5), Color(0.8, 0.6, 1.0, 0.5), Color(1.0, 0.8, 0.5, 0.5)]


func build(w: Node2D) -> void:
	w.add_ground(PackedVector2Array([
		Vector2(8500, 620), Vector2(9000, 620), Vector2(9600, 626), Vector2(10100, 614),
		Vector2(10700, 622), Vector2(11200, 616), Vector2(11800, 624), Vector2(12300, 620),
	]), 33)
	# L'entrée : grande voûte de roche devant laquelle on passe
	w.add_prop("rock_arch", Vector2(9000, 620), {"w": 560.0, "h": 520.0})
	w.add_prop("cave_ceiling", Vector2(9000, 0), {"w": 3300.0})
	# Stalactites et stalagmites le long du chemin
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var x := 9150.0
	while x < 12250.0:
		var h := rng.randf_range(60.0, 170.0)
		var y := 150.0 + 45.0 * sin((x - 9000.0) * 0.011) + 30.0 * sin((x - 9000.0) * 0.027 + 1.3) + 22.0 * absf(sin((x - 9000.0) * 0.05))
		w.add_prop("stalactite", Vector2(x, y - 4.0), {"w": rng.randf_range(26.0, 52.0), "h": h})
		if rng.randf() < 0.55:
			w.add_prop("stalagmite", Vector2(x + rng.randf_range(-60.0, 60.0), w.ground_at(x) + 2.0), {"w": rng.randf_range(30.0, 60.0), "h": rng.randf_range(40.0, 110.0)})
		x += rng.randf_range(120.0, 260.0)
	# Cristaux qui éclairent le chemin
	for i in range(CRYSTALS.size()):
		var cx: float = CRYSTALS[i]
		w.add_prop("crystal", Vector2(cx, w.ground_at(cx) + 2.0), {"h": 42.0 + float(i % 3) * 14.0, "color": COLORS[i % COLORS.size()], "seed": i, "light": 120.0})
	# La veine de lumière : toucher la roche révèle une page
	var vein := Interactable.new()
	vein.id = "vein_300"
	vein.prompt = "Toucher la veine de lumière"
	vein.draw_kind = "vein"
	vein.position = Vector2(10900.0, 620.0 - 90.0)
	vein.used.connect(func(_id: String) -> void:
		w.toast_text("La roche s'illumine.")
		w.reveal_page(300))
	vein.remember_in(w.save)
	w.pages_root.add_child(vein)
	# Lueur du dehors à l'entrée
	w.add_glow(Vector2(9000.0, 470.0), 340.0, Color(1.0, 0.85, 0.6, 0.20), 0.03)
