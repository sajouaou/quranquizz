extends RefCounted
## Le souk (x 4980-8500) : un midi qui ne bouge pas, des étoffes partout, personne.
## On y court après l'argent : des pièces d'or fuient devant celui qui les suit, jusqu'à un coin calme
## où elles tombent en poussière. Une clé se cache dans les poches d'un vêtement, pour un coffre scellé.
## Aucune figure humaine, aucune statue : étals, tissus, étagères, tertres de terre.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Interactable := preload("res://scripts/world/interactable.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const I18n := preload("res://scripts/core/i18n.gd")

const COIN_START := 5250.0
const COIN_COUNT := 14
const CLEARING_X := 7440.0
const RACK_X := 6300.0

var coins: Array = []
var _dissolved: bool = false
var _rack_glow: Node2D
var _world: Node2D


func build(w: Node2D) -> void:
	_world = w
	w.add_ground(PackedVector2Array([
		Vector2(4980, 620), Vector2(5400, 620), Vector2(5800, 613), Vector2(6200, 620),
		Vector2(7000, 620), Vector2(7500, 616), Vector2(8000, 620), Vector2(8500, 620),
	]), 21)

	# Étagères qui montent jusqu'au ciel
	for tx in [5140.0, 6740.0, 7150.0]:
		w.add_prop("shelf_tower", Vector2(tx, 620), {"w": 200.0, "h": 560.0 + float(int(tx) % 90), "seed": int(tx)})
	# Étals au sol
	var stalls := [5420.0, 5760.0, 6900.0, 7260.0]
	for i in range(stalls.size()):
		w.add_prop("stall", Vector2(stalls[i], w.ground_at(stalls[i])), {"w": 220.0, "seed": 30 + i})
	# La boutique de vêtements, grand hall ouvert
	w.add_prop("shop_hall", Vector2(6300, 620), {"w": 620.0, "h": 300.0})
	# Cordes à linge
	w.add_prop("garment_line", Vector2(5540, 620), {"w": 480.0, "y": -250.0, "seed": 4})
	w.add_prop("garment_line", Vector2(6280, 620), {"w": 560.0, "y": -330.0, "seed": 5})
	w.add_prop("garment_line", Vector2(7040, 620), {"w": 420.0, "y": -270.0, "seed": 6}, false)
	w.add_prop("crates", Vector2(5960, 620), {"n": 3, "seed": 2}, true)
	w.add_prop("crates", Vector2(7000, 620), {"n": 2, "seed": 8}, true)
	# Chiffres qui s'élèvent : la course à l'accumulation
	var tags := ["×2", "×10", "+1", "1 000", "×3", "+50", "×100", "٣٠٠"]
	for i in range(tags.size()):
		w.add_prop("number_tag", Vector2(5100.0 + float(i) * 300.0, 560.0), {"text": tags[i], "size": 26 + (i % 3) * 8, "seed": 100 + i})

	# Un portant où fouiller : la clé est dans une poche
	var rack := Interactable.new()
	rack.id = "rack"
	rack.prompt_key = "market.rack"
	rack.position = Vector2(RACK_X, 620.0 - 80.0)
	rack.used.connect(_on_rack)
	rack.remember_in(w.save)
	w.pages_root.add_child(rack)
	if not w.save.has_item("key_chest"):
		_rack_glow = w.add_glow(Vector2(RACK_X + 4.0, 540.0), 52.0, Color(1.0, 0.85, 0.5, 0.35), 0.3)

	# Les pièces d'or qui fuient (déjà dissoutes si l'on a déjà traversé le souk)
	_dissolved = w.save.flag("ev_coins_gone")
	for i in range(0 if _dissolved else COIN_COUNT):
		var x := COIN_START + float(i) * 150.0
		var y := 620.0 - 96.0 - 26.0 * sin(float(i) * 0.9)
		var coin: Node2D = w.add_prop("coin", Vector2(x, y), {"r": 13.0, "seed": 500 + i, "alpha": 1.0}, true)
		coins.append({"node": coin, "limit": 7500.0 + float(i) * 16.0, "gone": false})

	# Le coin calme où le bruit s'arrête : de simples tertres, sans monument
	w.add_prop("mounds", Vector2(7930, 620), {"n": 3})
	w.add_prop("tree", Vector2(8300, 620), {"h": 190.0, "hue": 0.6, "seed": 77})
	# Transition vers la montagne
	for rx in [8420.0, 8560.0, 8700.0]:
		w.add_prop("rock", Vector2(rx, 620), {"w": 160.0 + float(int(rx) % 50), "h": 90.0 + float(int(rx) % 60), "color": Color("3b2f5c")}, false)


func _on_rack(_id: String) -> void:
	if _rack_glow != null:
		_rack_glow.queue_free()
		_rack_glow = null
	_world.give_item("key_chest")
	_world.toast_text(I18n.t("market.key_found"))


func process(w: Node2D, delta: float) -> void:
	if _dissolved:
		return
	var px: float = w.player.position.x
	for c in coins:
		if c["gone"]:
			continue
		var n: Node2D = c["node"]
		var d := n.position.x - px
		if d > 0.0 and d < 240.0 and n.position.x < float(c["limit"]):
			n.position.x = minf(n.position.x + 300.0 * delta, float(c["limit"]))
		elif d < 24.0 and d > -24.0 and absf(n.position.y - (w.player.position.y - 90.0)) < 70.0:
			# rattrapée en courant : elle se défait entre les doigts, sans rien apporter
			c["gone"] = true
			_dissolve(n)
	if px >= CLEARING_X:
		_dissolved = true
		for c in coins:
			if not c["gone"]:
				c["gone"] = true
				_dissolve(c["node"])
		Sfx.play_world("wind", -6.0, 0.9)
		w.trigger_event("coins_gone")


func _dissolve(n: Node2D) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "position:y", n.position.y - 40.0, 1.2)
	tw.parallel().tween_method(func(a: float) -> void: n.params["alpha"] = a, 1.0, 0.0, 1.2)
	tw.tween_callback(n.queue_free)
