extends Node2D
## Décor dessiné en code. Chaque « kind » est un élément du monde : lampadaire, arbre, façade, étal, cristal…
## Règle de contenu : aucune statue, aucune idole, aucune figure. Bâtiments, tissus, roches, ciel. (Les rares silhouettes sans visage du chapitre 2 sont dessinées par les zones concernées.)
## L'origine du nœud est au sol ; les dessins montent vers -y.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Sfx := preload("res://scripts/core/sfx.gd")
const Gfx := preload("res://scripts/core/gfx.gd")

var kind: String = ""
var params: Dictionary = {}
var world: Node2D
var t: float = 0.0
var _animated: bool = false
var _rng: RandomNumberGenerator
var _phase: float = 0.0
var _last_cam_x: float = -1.0e9

const EXTRUDED := ["facade", "mosque", "shop_hall"]  # bâtiments dessinés en volume


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = int(params.get("seed", int(position.x) * 31 + 7))
	_phase = _rng.randf() * TAU
	_animated = kind in ["cloud_sea", "garment_line", "coin", "awning_flags", "tree", "grass_tufts", "number_tag", "heart_garland", "heart_balloon", "candle_table", "bench_pair", "neon_tube", "mist", "bar_table"]
	set_process(_animated or kind in EXTRUDED)
	match kind:
		"lamp_post":
			var h: float = params.get("h", 190.0)
			world.add_glow(global_position + Vector2(0, -h), 140.0, Color(1.0, 0.8, 0.5, 0.42), 0.06)
			Sfx.emitter(self, "hum", Vector2(0, -h), -33.0, 360.0, randf_range(0.95, 1.05))  # la flamme, très discrète
		"garment_line", "awning_flags":
			Sfx.emitter(self, "cloth", Vector2(0, -150.0), -27.0, 480.0, randf_range(0.9, 1.1))
		"candle_table":
			world.add_glow(global_position + Vector2(0, -74), 120.0, Color(1.0, 0.75, 0.4, 0.34), 0.1)
		"neon_tube":
			Sfx.emitter(self, "hum", Vector2(float(params.get("w", 200.0)) * 0.5, -float(params.get("y", 200.0))), -28.0, 420.0, 1.25)  # le tube qui bourdonne
			world.add_glow(global_position + Vector2(float(params.get("w", 200.0)) * 0.5, -float(params.get("y", 200.0))), 200.0, params.get("color", Color(1.0, 0.3, 0.7, 0.25)), 0.08)
		"crystal":
			add_to_group("cave_light")
			set_meta("radius", float(params.get("light", 110.0)))
			world.add_glow(global_position + Vector2(0, -float(params.get("h", 40.0)) * 0.5), 90.0, params.get("color", Color(0.5, 0.85, 1.0, 0.5)), 0.08)


func _process(delta: float) -> void:
	t += delta
	# Rien n'est redessiné hors de l'écran : c'est la principale économie du jeu (le monde est long, l'écran est étroit)
	var cx := _camera_x()
	var reach: float = 900.0 + float(params.get("w", 300.0))
	if absf(global_position.x - cx) > reach:
		return
	if kind in EXTRUDED:
		# Un bâtiment n'est redessiné que si la caméra a bougé : son mur de côté dépend de l'endroit d'où on le regarde
		if Gfx.low() or absf(cx - _last_cam_x) < 2.0:
			return
		_last_cam_x = cx
	queue_redraw()


func _camera_x() -> float:
	if world == null or world.player == null:
		return global_position.x
	return world.player.camera.get_screen_center_position().x


## Volume d'un bâtiment (perspective à un point de fuite, au centre de l'écran) : on voit le mur de côté qui regarde
## vers le centre, d'autant plus large que le bâtiment est loin sur le côté. En marchant, les façades « tournent ».
## À appeler avant de dessiner la façade ; top est la hauteur du toit, depth la profondeur du bâtiment.
func _side_wall(w: float, top: float, tint: Color, depth: float = 70.0) -> void:
	if Gfx.low():
		return  # qualité basse : façades plates, jamais redessinées
	var dx := global_position.x - _camera_x()
	var k := clampf(dx / 620.0, -1.0, 1.0)
	if absf(k) < 0.03:
		return
	var d := depth * absf(k)
	var s := -signf(k)  # le mur visible est du côté du centre de l'écran
	var x0 := s * w * 0.5
	var x1 := x0 + s * d
	var rise := d * 0.30  # le fond du bâtiment remonte un peu vers la ligne d'horizon, le toit descend
	var wall := tint.darkened(0.34)
	var quad := PackedVector2Array([Vector2(x0, 0.0), Vector2(x0, -top), Vector2(x1, -top + rise), Vector2(x1, -rise * 0.25)])
	draw_polygon(quad, PackedColorArray([wall, wall, wall.darkened(0.25), wall.darkened(0.25)]))
	# une rangée de fenêtres étroites sur le mur de côté, écrasées par la perspective
	if d > 26.0:
		var rows := maxi(1, int((top - 100.0) / 90.0))
		for j in range(rows):
			var wy := -top + 56.0 + float(j) * 90.0
			var a := Vector2(lerpf(x0, x1, 0.35), wy + rise * 0.35)
			var b := Vector2(lerpf(x0, x1, 0.65), wy + rise * 0.65)
			draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, 40), a + Vector2(0, 44)]), Color(0.12, 0.09, 0.2, 0.75))
	draw_line(Vector2(x0, 0.0), Vector2(x0, -top), tint.darkened(0.5), 2.0, true)
	# ombre du bâtiment sur le sol, du côté opposé à la lumière
	draw_set_transform(Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.1))
	DrawUtil.glow(self, Vector2.ZERO, w * 0.72, Color(0, 0, 0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Largeur de l'ombre portée au sol, par sorte de décor posé sur le sol (les bâtiments et le fond n'en ont pas).
const SHADOW_WIDTH := {
	"lamp_post": 46.0, "tree": 130.0, "bench": 150.0, "stall": 230.0, "shelf_tower": 130.0, "crates": 110.0,
	"post": 36.0, "rose_bush": 90.0, "bench_pair": 250.0, "bar_table": 130.0, "bottle_shelf": 150.0,
	"dead_tree": 100.0, "candle_table": 80.0, "rock": 120.0, "crystal": 60.0, "stalagmite": 70.0,
}


func _contact_shadow() -> void:
	if not SHADOW_WIDTH.has(kind):
		return
	var w: float = float(params.get("w", SHADOW_WIDTH[kind])) if kind in ["stall", "rock"] else float(SHADOW_WIDTH[kind])
	draw_set_transform(Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.16))
	DrawUtil.glow(self, Vector2.ZERO, w * 0.62, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	_contact_shadow()
	match kind:
		"lamp_post":
			_lamp_post()
		"tree":
			_tree()
		"bench":
			_bench()
		"facade":
			_facade()
		"mosque":
			_mosque()
		"cloud_sea":
			_cloud_sea()
		"stall":
			_stall()
		"garment_line":
			_garment_line()
		"shelf_tower":
			_shelf_tower()
		"shop_hall":
			_shop_hall()
		"crates":
			_crates()
		"coin":
			_coin()
		"number_tag":
			_number_tag()
		"rock_arch":
			_rock_arch()
		"stalactite":
			_stalactite()
		"stalagmite":
			_stalagmite()
		"crystal":
			_crystal()
		"rock":
			_rock()
		"gate_dawn":
			_gate_dawn()
		"grass_tufts":
			_grass_tufts()
		"cave_wall":
			_cave_wall()
		"cave_ceiling":
			_cave_ceiling()
		"post":
			_post()
		"heart_garland":
			_heart_garland()
		"rose_bush":
			_rose_bush()
		"bench_pair":
			_bench_pair()
		"candle_table":
			_candle_table()
		"heart_balloon":
			_heart_balloon()
		"bar_table":
			_bar_table()
		"bottle_shelf":
			_bottle_shelf()
		"neon_tube":
			_neon_tube()
		"low_wall":
			_low_wall()
		"mist":
			_mist()
		"dead_tree":
			_dead_tree()


# ----------------------------------------------------------------------------------------------- rue

func _lamp_post() -> void:
	var h: float = params.get("h", 190.0)
	var col := Color("2c2340")
	draw_rect(Rect2(-9, -10, 18, 10), col)
	draw_line(Vector2(0, 0), Vector2(0, -h), col, 6.0, true)
	draw_line(Vector2(0, -h), Vector2(0, -h - 6), col, 6.0)
	var glass := PackedVector2Array([Vector2(-15, -h), Vector2(15, -h), Vector2(10, -h - 30), Vector2(-10, -h - 30)])
	draw_colored_polygon(glass, Color(1.0, 0.86, 0.55, 0.95))
	draw_polyline(PackedVector2Array([glass[0], glass[1], glass[2], glass[3], glass[0]]), col, 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -h - 30), Vector2(14, -h - 30), Vector2(0, -h - 44)]), col)


func _tree() -> void:
	var h: float = params.get("h", 200.0)
	var hue: float = params.get("hue", 0.72)
	var sway := sin(t * 0.7 + _phase) * 3.0
	var trunk := Color.from_hsv(0.07, 0.3, 0.22)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(5 + sway * 0.3, -h * 0.6), Vector2(-5 + sway * 0.3, -h * 0.6)]), trunk)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 3))
	for i in range(9):
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, h * 0.28)
		var c := Vector2(cos(a) * r + sway, -h * 0.72 + sin(a) * r * 0.7)
		var rad := rng.randf_range(h * 0.14, h * 0.24)
		draw_circle(c, rad, Color.from_hsv(hue + rng.randf_range(-0.04, 0.04), 0.42, rng.randf_range(0.36, 0.52)))
	for i in range(7):
		var a := rng.randf() * TAU
		var r := rng.randf_range(h * 0.05, h * 0.3)
		var p := Vector2(cos(a) * r + sway, -h * 0.72 + sin(a) * r * 0.7)
		var tw := 0.5 + 0.5 * sin(t * 2.0 + float(i))
		draw_circle(p, 2.4, Color(1.0, 0.9, 0.6, 0.5 + 0.4 * tw))


func _bench() -> void:
	var w: float = params.get("w", 110.0)
	var col := Color("4a3122")
	draw_rect(Rect2(-w / 2.0, -42, w, 8), col)
	draw_rect(Rect2(-w / 2.0, -74, w, 6), col)
	draw_rect(Rect2(-w / 2.0 + 6, -74, 6, 40), col)
	draw_rect(Rect2(w / 2.0 - 12, -74, 6, 40), col)
	draw_rect(Rect2(-w / 2.0 + 8, -34, 8, 34), col)
	draw_rect(Rect2(w / 2.0 - 16, -34, 8, 34), col)


func _facade() -> void:
	var w: float = params.get("w", 240.0)
	var h: float = params.get("h", 300.0)
	var tint: Color = params.get("tint", Color("c9a9c4"))
	var style: String = params.get("style", "flat")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 1))
	var dark := tint.darkened(0.35)
	_side_wall(w, h, tint)
	draw_rect(Rect2(-w / 2.0, -h, w, h), tint)
	DrawUtil.vgrad(self, Rect2(-w / 2.0, -h * 0.45, w, h * 0.45), Color(0, 0, 0, 0.0), Color(0.08, 0.04, 0.16, 0.22))  # le bas de la façade est dans l'ombre de la rue
	draw_rect(Rect2(-w / 2.0, -h, w, 12), tint.lightened(0.12))
	draw_rect(Rect2(-w / 2.0 - 6, -h - 10, w + 12, 12), tint.lightened(0.2))
	draw_rect(Rect2(-w / 2.0, -14, w, 14), dark)
	if style == "dome":
		draw_colored_polygon(DrawUtil.ellipse(Vector2(0, -h - 10), w * 0.28, w * 0.24, 24), tint.lightened(0.05))
		draw_line(Vector2(0, -h - 10 - w * 0.24), Vector2(0, -h - 10 - w * 0.24 - 16), dark, 3.0)
	var cols := maxi(2, int(w / 70.0))
	var rows := maxi(1, int((h - 100.0) / 90.0))
	for i in range(cols):
		for j in range(rows):
			var wx := -w / 2.0 + (float(i) + 0.5) * (w / float(cols))
			var wy := -h + 50.0 + float(j) * 90.0
			var lit := rng.randf() > 0.55
			_arched_window(Vector2(wx, wy), 26.0, 44.0, lit, dark)
	# porte close
	draw_rect(Rect2(-18, -74, 36, 60), Color("4a3122"))
	draw_circle(Vector2(0, -74), 18.0, Color("4a3122"))
	draw_circle(Vector2(9, -44), 2.5, P.GOLD)


func _arched_window(pos: Vector2, w: float, h: float, lit: bool, frame: Color) -> void:
	var glass := Color(1.0, 0.84, 0.5, 0.92) if lit else Color("2b2246")
	draw_rect(Rect2(pos.x - w / 2.0, pos.y, w, h), glass)
	draw_circle(Vector2(pos.x, pos.y), w / 2.0, glass)
	draw_rect(Rect2(pos.x - w / 2.0 - 3, pos.y, 3, h), frame)
	draw_rect(Rect2(pos.x + w / 2.0, pos.y, 3, h), frame)
	draw_arc(Vector2(pos.x, pos.y), w / 2.0 + 1.5, PI, TAU, 14, frame, 3.0, true)
	draw_rect(Rect2(pos.x - w / 2.0 - 4, pos.y + h, w + 8, 4), frame)
	if lit:
		draw_line(Vector2(pos.x, pos.y - w / 2.0), Vector2(pos.x, pos.y + h), frame.darkened(0.2), 2.0)


func _mosque() -> void:
	# Petite mosquée de quartier, vue de l'extérieur (aucune personne) : coupole, minaret, fenêtres allumées.
	var w: float = params.get("w", 300.0)
	var h: float = params.get("h", 190.0)
	var tint: Color = params.get("tint", Color("d7c4d6"))
	var dark := tint.darkened(0.35)
	_side_wall(w, h, tint, 90.0)
	draw_rect(Rect2(-w / 2.0, -h, w, h), tint)
	DrawUtil.vgrad(self, Rect2(-w / 2.0, -h * 0.45, w, h * 0.45), Color(0, 0, 0, 0.0), Color(0.08, 0.04, 0.16, 0.2))
	draw_rect(Rect2(-w / 2.0 - 5, -h - 8, w + 10, 10), tint.lightened(0.18))
	draw_rect(Rect2(-w / 2.0, -12, w, 12), dark)
	# grande coupole et deux petites
	draw_colored_polygon(DrawUtil.ellipse(Vector2(0, -h - 6), w * 0.26, w * 0.22, 28), tint.lightened(0.08))
	draw_line(Vector2(0, -h - 6 - w * 0.22), Vector2(0, -h - 6 - w * 0.22 - 22), dark, 3.0)
	draw_circle(Vector2(0, -h - 6 - w * 0.22 - 24), 4.0, P.GOLD)
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(DrawUtil.ellipse(Vector2(sx * w * 0.36, -h - 4), w * 0.1, w * 0.09, 18), tint.lightened(0.04))
	# minaret
	var mx := w * 0.5 + 24.0
	draw_rect(Rect2(mx - 14, -h - 140, 28, h + 140), tint.darkened(0.04))
	draw_rect(Rect2(mx - 20, -h - 60, 40, 8), dark)
	draw_rect(Rect2(mx - 18, -h - 140, 36, 8), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(mx - 16, -h - 140), Vector2(mx + 16, -h - 140), Vector2(mx, -h - 196)]), tint.lightened(0.08))
	draw_circle(Vector2(mx, -h - 200), 4.0, P.GOLD)
	for i in range(3):
		_arched_window(Vector2(mx, -h - 118 + float(i) * 34.0), 8.0, 16.0, true, dark)
	# fenêtres et porte
	for i in range(4):
		var wx := -w / 2.0 + (float(i) + 0.5) * (w / 4.0)
		_arched_window(Vector2(wx, -h + 44.0), 26.0, 50.0, i % 2 == 0, dark)
	draw_rect(Rect2(-24, -84, 48, 72), Color("4a3122"))
	draw_circle(Vector2(0, -84), 24.0, Color("4a3122"))


func _post() -> void:
	var h: float = params.get("h", 200.0)
	draw_line(Vector2(0, 0), Vector2(0, -h), Color("3d2a1a"), 8.0, true)


func _cloud_sea() -> void:
	# Mer de nuages sous le pont de pierres : le vide du rêve, doux et rassurant
	var x0: float = params.get("x0", 0.0) - position.x
	var x1: float = params.get("x1", 800.0) - position.x
	var top := 30.0
	DrawUtil.vgrad(self, Rect2(x0, top, x1 - x0, 700.0), Color(1.0, 0.78, 0.78, 0.0), Color(0.98, 0.7, 0.72, 0.95))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in range(34):
		var cx := lerpf(x0, x1, rng.randf()) + sin(t * 0.25 + float(i)) * 14.0
		var cy := top + 20.0 + rng.randf() * 240.0
		var rx := rng.randf_range(90.0, 210.0)
		draw_colored_polygon(DrawUtil.ellipse(Vector2(cx, cy), rx, rx * 0.22, 22), Color(1.0, 0.88, 0.86, 0.22 + rng.randf() * 0.25))


# ----------------------------------------------------------------------------------------------- souk

func _stall() -> void:
	var w: float = params.get("w", 220.0)
	var seed_i: int = int(params.get("seed", 3))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var cloth_a := Color.from_hsv(rng.randf(), 0.55, 0.85)
	var cloth_b := Color.from_hsv(fmod(rng.randf() + 0.5, 1.0), 0.45, 0.9)
	var wood := Color("4a3122")
	# poteaux
	draw_rect(Rect2(-w / 2.0, -190, 8, 190), wood)
	draw_rect(Rect2(w / 2.0 - 8, -190, 8, 190), wood)
	# auvent à rayures, qui ondule légèrement
	var n := 8
	var seg := (w + 30.0) / float(n)
	for i in range(n):
		var x := -w / 2.0 - 15.0 + seg * float(i)
		var sway := sin(t * 1.4 + float(i) * 0.7 + _phase) * 2.0
		var col := cloth_a if i % 2 == 0 else cloth_b
		draw_colored_polygon(PackedVector2Array([Vector2(x, -190), Vector2(x + seg, -190), Vector2(x + seg, -150 + sway), Vector2(x + seg * 0.5, -140 + sway), Vector2(x, -150 + sway)]), col)
	# table et tissus pliés
	draw_rect(Rect2(-w / 2.0 + 10, -62, w - 20, 10), Color("6b4a2f"))
	draw_rect(Rect2(-w / 2.0 + 20, -52, 6, 52), wood)
	draw_rect(Rect2(w / 2.0 - 26, -52, 6, 52), wood)
	var x2 := -w / 2.0 + 18.0
	while x2 < w / 2.0 - 60.0:
		var stack := rng.randi_range(2, 5)
		var col2 := Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.6), rng.randf_range(0.7, 0.95))
		for k in range(stack):
			draw_rect(Rect2(x2, -62 - float(k + 1) * 9.0, 44.0, 9.0), col2.darkened(0.05 * float(k % 2)))
		x2 += 52.0
	# jarres
	draw_colored_polygon(DrawUtil.ellipse(Vector2(w / 2.0 - 36.0, -84.0), 12.0, 20.0, 14), Color("b8794a"))


func _garment_line() -> void:
	# Corde tendue avec des vêtements suspendus, qui balancent au vent : pas de mannequin, pas de silhouette.
	var w: float = params.get("w", 420.0)
	var y0: float = params.get("y", -230.0)
	var sag := 18.0
	var pts := PackedVector2Array()
	for i in range(21):
		var u := float(i) / 20.0
		pts.append(Vector2(lerpf(-w / 2.0, w / 2.0, u), y0 + sin(u * PI) * sag))
	draw_polyline(pts, Color("3d2a1a"), 3.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 4))
	var n := int(w / 52.0)
	for i in range(n):
		var u := (float(i) + 0.5) / float(n)
		var hx := lerpf(-w / 2.0, w / 2.0, u)
		var hy := y0 + sin(u * PI) * sag
		var sway := sin(t * 1.6 + float(i) * 0.9 + _phase) * 6.0
		var col := Color.from_hsv(rng.randf(), rng.randf_range(0.25, 0.6), rng.randf_range(0.75, 0.98))
		var len := rng.randf_range(70.0, 118.0)
		var wide := rng.randf_range(34.0, 48.0)
		var shape := rng.randi_range(0, 2)
		var poly := PackedVector2Array()
		if shape == 0:  # tunique longue
			poly = PackedVector2Array([Vector2(hx - 6, hy), Vector2(hx + 6, hy), Vector2(hx + wide * 0.5 + sway, hy + len), Vector2(hx - wide * 0.5 + sway, hy + len)])
		elif shape == 1:  # écharpe
			poly = PackedVector2Array([Vector2(hx - 12, hy), Vector2(hx + 12, hy), Vector2(hx + 12 + sway, hy + len * 0.9), Vector2(hx - 12 + sway, hy + len * 0.9)])
		else:  # étoffe large
			poly = PackedVector2Array([Vector2(hx - wide * 0.5, hy), Vector2(hx + wide * 0.5, hy), Vector2(hx + wide * 0.5 + sway, hy + len * 0.7), Vector2(hx - wide * 0.5 + sway, hy + len * 0.7)])
		draw_colored_polygon(poly, col)
		draw_line(poly[2], poly[3], col.darkened(0.2), 3.0)
		draw_circle(Vector2(hx, hy), 3.0, Color("3d2a1a"))


func _shelf_tower() -> void:
	# Étagères qui montent jusqu'au ciel, remplies d'étoffes pliées : le magasin sans fin
	var w: float = params.get("w", 200.0)
	var h: float = params.get("h", 520.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 9))
	var wood := Color("4a3122")
	draw_rect(Rect2(-w / 2.0, -h, 8, h), wood)
	draw_rect(Rect2(w / 2.0 - 8, -h, 8, h), wood)
	var y := 0.0
	while y < h:
		draw_rect(Rect2(-w / 2.0, -y - 6, w, 6), wood)
		var x := -w / 2.0 + 14.0
		while x < w / 2.0 - 40.0:
			var stack := rng.randi_range(1, 4)
			var col := Color.from_hsv(rng.randf(), rng.randf_range(0.25, 0.55), rng.randf_range(0.65, 0.92))
			for k in range(stack):
				draw_rect(Rect2(x, -y - 6.0 - float(k + 1) * 10.0, 40.0, 10.0), col.darkened(0.05 * float(k % 2)))
			x += 46.0
		y += 88.0


func _shop_hall() -> void:
	# La boutique de vêtements : grand hall ouvert sur la rue, portants pleins d'habits
	var w: float = params.get("w", 620.0)
	var h: float = params.get("h", 300.0)
	var tint := Color("8f5a7a")
	_side_wall(w, h, tint.darkened(0.4), 90.0)
	draw_rect(Rect2(-w / 2.0, -h, w, h), tint.darkened(0.55))
	DrawUtil.vgrad(self, Rect2(-w / 2.0 + 14, -h + 40, w - 28, h - 40), tint.darkened(0.35), tint.darkened(0.5))
	draw_rect(Rect2(-w / 2.0 - 8, -h - 14, w + 16, 34), tint)
	for i in range(int(w / 40.0)):
		var x := -w / 2.0 + float(i) * 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, -h + 20), Vector2(x + 40.0, -h + 20), Vector2(x + 20.0, -h + 40)]), tint.lightened(0.2 if i % 2 == 0 else 0.05))
	# portants d'habits alignés
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for r in range(3):
		var rx := -w / 2.0 + 90.0 + float(r) * 190.0
		draw_line(Vector2(rx - 60, -150), Vector2(rx + 60, -150), Color("2a1f38"), 4.0)
		draw_line(Vector2(rx - 60, -150), Vector2(rx - 60, 0), Color("2a1f38"), 4.0)
		draw_line(Vector2(rx + 60, -150), Vector2(rx + 60, 0), Color("2a1f38"), 4.0)
		for k in range(7):
			var gx := rx - 52.0 + float(k) * 17.0
			var col := Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.6), rng.randf_range(0.7, 0.95))
			var len := rng.randf_range(70.0, 118.0)
			draw_colored_polygon(PackedVector2Array([Vector2(gx, -148), Vector2(gx + 14, -148), Vector2(gx + 16, -148 + len), Vector2(gx - 2, -148 + len)]), col)


func _crates() -> void:
	var n: int = params.get("n", 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 2))
	var x := 0.0
	for i in range(n):
		var s := rng.randf_range(38.0, 56.0)
		draw_rect(Rect2(x, -s, s, s), Color("7a5638"))
		draw_rect(Rect2(x, -s, s, s), Color("3d2a1a"), false, 3.0)
		draw_line(Vector2(x, -s), Vector2(x + s, 0), Color("3d2a1a"), 2.0)
		x += s + 6.0


func _coin() -> void:
	# Pièce d'or unie (aucune inscription, aucune effigie) : elle scintille et fuit devant celui qui la poursuit
	var r: float = params.get("r", 13.0)
	var squash := absf(sin(t * 2.6 + _phase)) * 0.75 + 0.25
	var a: float = params.get("alpha", 1.0)
	var pts := DrawUtil.ellipse(Vector2.ZERO, r * squash, r, 18)
	draw_colored_polygon(pts, Color(0.93, 0.76, 0.28, a))
	draw_polyline(DrawUtil.ellipse(Vector2.ZERO, r * squash * 0.68, r * 0.68, 16), Color(0.72, 0.52, 0.14, a), 2.0, true)
	draw_circle(Vector2(-r * squash * 0.3, -r * 0.35), 2.0, Color(1.0, 0.97, 0.8, a))


func _number_tag() -> void:
	# Chiffres qui s'élèvent lentement : la course à l'accumulation
	var s: String = params.get("text", "×2")
	var a := 0.22 + 0.12 * sin(t * 1.4 + _phase)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, -fposmod(t * 14.0 + _phase * 20.0, 180.0)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(params.get("size", 28)), Color(1.0, 0.92, 0.7, a))


# ----------------------------------------------------------------------------------------------- grotte

func _rock_arch() -> void:
	# Entrée de la grotte : grande voûte de roche sombre, avec la lumière du dehors qui s'y engouffre
	var w: float = params.get("w", 560.0)
	var h: float = params.get("h", 520.0)
	var rock := Color("2d2745")
	var rock_light := Color("463d66")
	var left_pts := PackedVector2Array([Vector2(-w / 2.0 - 260.0, 0), Vector2(-w / 2.0 - 200.0, -h * 0.5), Vector2(-w / 2.0 - 60.0, -h * 0.86), Vector2(-w / 2.0 + 60.0, -h * 1.02), Vector2(-w / 2.0 + 120.0, -h * 0.92), Vector2(-w / 2.0 + 30.0, -h * 0.62), Vector2(-w / 2.0 + 10.0, -h * 0.3), Vector2(-w / 2.0 + 30.0, 0)])
	var right_pts := PackedVector2Array([Vector2(w / 2.0 - 30.0, 0), Vector2(w / 2.0 - 10.0, -h * 0.3), Vector2(w / 2.0 - 30.0, -h * 0.62), Vector2(w / 2.0 - 120.0, -h * 0.92), Vector2(w / 2.0 - 60.0, -h * 1.02), Vector2(w / 2.0 + 60.0, -h * 0.86), Vector2(w / 2.0 + 200.0, -h * 0.5), Vector2(w / 2.0 + 260.0, 0)])
	var top_pts := PackedVector2Array([Vector2(-w / 2.0 + 60.0, -h * 1.02), Vector2(-w * 0.2, -h * 1.14), Vector2(w * 0.1, -h * 1.1), Vector2(w / 2.0 - 60.0, -h * 1.02), Vector2(w / 2.0 - 120.0, -h * 0.92), Vector2(w * 0.1, -h * 0.98), Vector2(-w * 0.2, -h * 1.0), Vector2(-w / 2.0 + 120.0, -h * 0.92)])
	draw_colored_polygon(left_pts, rock)
	draw_colored_polygon(right_pts, rock)
	draw_colored_polygon(top_pts, rock)
	draw_polyline(left_pts, rock_light, 4.0, true)
	draw_polyline(right_pts, rock_light, 4.0, true)
	# stalactites à l'entrée
	for i in range(9):
		var x := lerpf(-w / 2.0 + 90.0, w / 2.0 - 90.0, float(i) / 8.0)
		var len := 30.0 + float((i * 37) % 60)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 12.0, -h * 0.98), Vector2(x + 12.0, -h * 0.98), Vector2(x + float(i % 3 - 1) * 3.0, -h * 0.98 + len)]), rock)


func _cave_wall() -> void:
	# Paroi de la grotte à hauteur du joueur (repère visuel, ne bloque rien)
	var w: float = params.get("w", 600.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 5))
	for i in range(int(w / 40.0)):
		var x := float(i) * 40.0
		var h := rng.randf_range(20.0, 90.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 40.0, 0), Vector2(x + 20.0, -h)]), Color("241f3d"))


func _stalactite() -> void:
	var w: float = params.get("w", 40.0)
	var h: float = params.get("h", 120.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, 0), Vector2(w / 2.0, 0), Vector2(w * 0.08, h), Vector2(-w * 0.05, h * 0.9)]), Color("332c52"))
	draw_line(Vector2(-w * 0.2, 4), Vector2(-w * 0.02, h * 0.85), Color("5a4f80"), 2.0, true)


func _stalagmite() -> void:
	var w: float = params.get("w", 50.0)
	var h: float = params.get("h", 90.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, 0), Vector2(w / 2.0, 0), Vector2(w * 0.08, -h), Vector2(-w * 0.05, -h * 0.92)]), Color("3a3260"))
	draw_line(Vector2(-w * 0.2, -4), Vector2(-w * 0.02, -h * 0.85), Color("6a5f92"), 2.0, true)


func _crystal() -> void:
	var h: float = params.get("h", 40.0)
	var col: Color = params.get("color", Color(0.5, 0.85, 1.0, 1.0))
	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.003 + _phase)
	for i in range(3):
		var off := float(i - 1) * 12.0
		var hh := h * (1.0 - 0.28 * absf(float(i - 1)))
		var pts := PackedVector2Array([Vector2(off - 7.0, 0), Vector2(off + 7.0, 0), Vector2(off + 3.0, -hh), Vector2(off - 2.0, -hh - 8.0)])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.9 * pulse))
		draw_polyline(PackedVector2Array([pts[0], pts[3], pts[2], pts[1]]), Color(1, 1, 1, 0.6), 1.5, true)


# ----------------------------------------------------------------------------------------------- sommet

func _rock() -> void:
	var w: float = params.get("w", 120.0)
	var h: float = params.get("h", 70.0)
	var col: Color = params.get("color", Color("3b3560"))
	var pts := PackedVector2Array([Vector2(-w / 2.0, 0), Vector2(-w * 0.42, -h * 0.6), Vector2(-w * 0.1, -h), Vector2(w * 0.25, -h * 0.82), Vector2(w * 0.5, 0)])
	draw_colored_polygon(pts, col)
	draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.1, -h), Vector2(w * 0.25, -h * 0.82), Vector2(w * 0.05, -h * 0.4)]), col.lightened(0.12))


func _gate_dawn() -> void:
	# Porte de lumière au bout du chemin : deux piliers nus et un arc, sans ornement figuré
	var h: float = params.get("h", 300.0)
	var w: float = params.get("w", 240.0)
	var col := Color("cbb8d8")
	draw_rect(Rect2(-w / 2.0, -h, 22, h), col)
	draw_rect(Rect2(w / 2.0 - 22.0, -h, 22, h), col)
	draw_arc(Vector2(0, -h), w / 2.0 - 11.0, PI, TAU, 40, col, 22.0, true)
	var glow_a := 0.5 + 0.2 * sin(t * 1.2)
	DrawUtil.vgrad(self, Rect2(-w / 2.0 + 22.0, -h - 20.0, w - 44.0, h + 20.0), Color(1.0, 0.9, 0.65, 0.0), Color(1.0, 0.86, 0.55, glow_a * 0.6))


func _grass_tufts() -> void:
	var n: int = params.get("n", 8)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 6))
	for i in range(n):
		var x := float(i) * 26.0 + rng.randf() * 10.0
		var h := rng.randf_range(14.0, 30.0)
		var sway := sin(t * 1.3 + float(i)) * 3.0
		draw_line(Vector2(x, 0), Vector2(x + sway, -h), Color(0.6, 0.55, 0.85, 0.85), 2.0, true)


func _cave_ceiling() -> void:
	# Voûte de la grotte : masse de roche avec un bord inférieur irrégulier (décor, pas de collision)
	var w: float = params.get("w", 3400.0)
	var line := PackedVector2Array()
	var x := 0.0
	while x <= w:
		var y := 150.0 + 45.0 * sin(x * 0.011) + 30.0 * sin(x * 0.027 + 1.3) + 22.0 * absf(sin(x * 0.05))
		line.append(Vector2(x, y))
		x += 36.0
	DrawUtil.fill_to(self, line, -700.0, Color("1d1832"))
	draw_polyline(line, Color("3d345f"), 3.0, true)


# ------------------------------------------------------------------------ second rêve : la ville des amoureux
# Aucune personne : des décors de fête (guirlandes, roses, tables pour deux) ; c'est leur vide qui parle.

func _heart(c: Vector2, sz: float, col: Color) -> void:
	draw_circle(c + Vector2(-sz * 0.5, -sz * 0.25), sz * 0.55, col)
	draw_circle(c + Vector2(sz * 0.5, -sz * 0.25), sz * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-sz * 1.02, -sz * 0.02), c + Vector2(sz * 1.02, -sz * 0.02), c + Vector2(0, sz * 1.15)]), col)


func _heart_garland() -> void:
	# deux poteaux et une guirlande de cœurs qui ondule
	var w: float = params.get("w", 520.0)
	var h: float = params.get("h", 250.0)
	var n: int = params.get("n", 9)
	var col := Color("2c2340")
	draw_line(Vector2(0, 0), Vector2(0, -h), col, 6.0, true)
	draw_line(Vector2(w, 0), Vector2(w, -h), col, 6.0, true)
	var pts := PackedVector2Array()
	for i in range(21):
		var u := float(i) / 20.0
		pts.append(Vector2(u * w, -h + sin(u * PI) * 46.0 + sin(t * 1.4 + u * 6.0) * 3.0))
	draw_polyline(pts, Color(0.95, 0.75, 0.8, 0.9), 2.0, true)
	for i in range(n):
		var u := (float(i) + 0.5) / float(n)
		var p := Vector2(u * w, -h + sin(u * PI) * 46.0 + sin(t * 1.4 + u * 6.0) * 3.0 + 16.0)
		var pulse := 1.0 + 0.08 * sin(t * 2.2 + float(i))
		_heart(p, 11.0 * pulse, Color.from_hsv(0.96 + float(i % 3) * 0.015, 0.75, 0.95))


func _rose_bush() -> void:
	var w: float = params.get("w", 110.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 4))
	draw_colored_polygon(DrawUtil.ellipse(Vector2(0, -22), w * 0.5, 26.0, 20), Color("2f5a3f"))
	draw_colored_polygon(DrawUtil.ellipse(Vector2(-w * 0.12, -30), w * 0.34, 22.0, 20), Color("3b7050"))
	for i in range(9):
		var p := Vector2(rng.randf_range(-w * 0.42, w * 0.42), rng.randf_range(-46.0, -14.0))
		draw_circle(p, 6.5, Color("c72a4a"))
		draw_circle(p + Vector2(-1, -1), 3.2, Color("e5506e"))


func _cup(p: Vector2, steam: bool = true) -> void:
	draw_rect(Rect2(p.x - 7, p.y - 12, 14, 12), Color("efe6d4"))
	draw_arc(Vector2(p.x + 8, p.y - 7), 5.0, -PI / 2.0, PI / 2.0, 8, Color("efe6d4"), 2.0, true)
	if steam:
		for k in range(2):
			var sx := p.x - 3.0 + float(k) * 6.0
			var off := sin(t * 2.0 + float(k) * 2.0) * 3.0
			draw_line(Vector2(sx, p.y - 15), Vector2(sx + off, p.y - 27), Color(1, 1, 1, 0.32), 2.0, true)


func _bench_pair() -> void:
	_bench()
	var w: float = params.get("w", 130.0)
	_cup(Vector2(-w * 0.2, -44))
	_cup(Vector2(w * 0.2, -44))


func _candle_table() -> void:
	# une table ronde pour deux, deux tasses, une bougie ; les chaises sont vides
	var wood := Color("5a3a28")
	draw_rect(Rect2(-3, -70, 6, 70), wood)
	draw_colored_polygon(DrawUtil.ellipse(Vector2(0, -72), 46.0, 8.0, 22), wood.lightened(0.1))
	for sx in [-1.0, 1.0]:
		draw_rect(Rect2(sx * 70.0 - 16.0, -44, 32, 5), wood)
		draw_rect(Rect2(sx * 70.0 + (14.0 if sx > 0.0 else -18.0), -84, 4, 84), wood)
		draw_rect(Rect2(sx * 70.0 - 14.0, -39, 4, 39), wood)
		draw_rect(Rect2(sx * 70.0 + 10.0, -39, 4, 39), wood)
	_cup(Vector2(-22, -80), false)
	_cup(Vector2(22, -80), false)
	draw_rect(Rect2(-3, -100, 6, 20), Color("f3ead6"))
	var fl := 1.0 + 0.12 * sin(t * 9.0 + _phase)
	draw_colored_polygon(DrawUtil.ellipse(Vector2(0, -106), 4.0 * fl, 8.0 * fl, 10), Color(1.0, 0.82, 0.4))


func _heart_balloon() -> void:
	var len_s: float = params.get("len", 150.0)
	var bob := sin(t * 1.2 + _phase) * 8.0
	var top := Vector2(sin(t * 0.8 + _phase) * 6.0, -len_s + bob)
	draw_line(Vector2.ZERO, top + Vector2(0, 24), Color(1, 1, 1, 0.35), 1.5, true)
	_heart(top, 16.0, Color.from_hsv(0.97, 0.7, 0.95, 0.92))


# ------------------------------------------------------------------------------ second rêve : lieux de l'ivresse

func _bar_table() -> void:
	var wood := Color("2e1a2c")
	draw_rect(Rect2(-60, -72, 120, 10), wood.lightened(0.15))
	draw_rect(Rect2(-52, -62, 8, 62), wood)
	draw_rect(Rect2(44, -62, 8, 62), wood)
	var sway := sin(t * 1.6 + _phase)
	# bouteilles et verres : des formes de verre, sans rien d'autre
	for i in range(3):
		var bx := -34.0 + float(i) * 34.0
		var col := Color(0.35 + 0.2 * float(i % 2), 0.75, 0.55, 0.85) if i != 1 else Color(0.85, 0.5, 0.25, 0.85)
		draw_rect(Rect2(bx - 7, -108, 14, 36), col)
		draw_rect(Rect2(bx - 3, -122, 6, 16), col)
		draw_rect(Rect2(bx - 5, -124, 10, 4), Color("d9c9a0"))
	for gx in [-52.0, 50.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(gx - 8, -96), Vector2(gx + 8, -96), Vector2(gx + 3, -80), Vector2(gx - 3, -80)]), Color(1.0, 0.8, 0.55, 0.7))
		draw_line(Vector2(gx, -80), Vector2(gx, -73), Color(1, 1, 1, 0.5), 2.0)
	DrawUtil.glow(self, Vector2(0, -90), 90.0 + sway * 6.0, Color(1.0, 0.55, 0.85, 0.22))


func _bottle_shelf() -> void:
	var w: float = params.get("w", 220.0)
	var h: float = params.get("h", 300.0)
	var wood := Color("2a1730")
	draw_rect(Rect2(-w / 2.0, -h, w, h), wood)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 3))
	var rows := int(h / 80.0)
	for r in range(rows):
		var y := -h + 20.0 + float(r) * 80.0
		draw_rect(Rect2(-w / 2.0 + 6.0, y + 52.0, w - 12.0, 6.0), wood.lightened(0.2))
		var x := -w / 2.0 + 16.0
		while x < w / 2.0 - 16.0:
			var bh := rng.randf_range(28.0, 46.0)
			var col := Color.from_hsv(rng.randf_range(0.0, 1.0), 0.45, 0.85, 0.75)
			draw_rect(Rect2(x, y + 52.0 - bh, 12, bh), col)
			draw_rect(Rect2(x + 4, y + 52.0 - bh - 9, 4, 9), col)
			x += rng.randf_range(20.0, 28.0)


func _neon_tube() -> void:
	var w: float = params.get("w", 200.0)
	var y: float = params.get("y", 200.0)
	var col: Color = params.get("color", Color(1.0, 0.3, 0.7))
	var flick := 0.85 + 0.15 * sin(t * 7.0 + _phase) * sin(t * 2.3)
	var pts := PackedVector2Array()
	for i in range(25):
		var u := float(i) / 24.0
		pts.append(Vector2(u * w, -y + sin(u * TAU * 1.5) * 16.0))
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.25 * flick), 12.0, true)
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.95 * flick), 4.0, true)
	draw_polyline(pts, Color(1, 1, 1, 0.7 * flick), 1.5, true)


# ---------------------------------------------------------------------------------- second rêve : les tombes
# Des tertres de terre et de simples dalles, sans inscription ni ornement.

func _low_wall() -> void:
	# Muret de pierres sèches, coiffé de dalles : il borde le chemin et laisse le cimetière de l'autre côté
	var w: float = params.get("w", 400.0)
	var h: float = params.get("h", 60.0)
	var col := Color("4a4f78")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 4))
	draw_set_transform(Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.06))
	DrawUtil.glow(self, Vector2.ZERO, w * 0.56, Color(0, 0, 0, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.vgrad(self, Rect2(-w / 2.0, -h, w, h), col, col.darkened(0.3))
	# assises de pierres : joints décalés d'un rang à l'autre
	var rows := 3
	for r in range(rows):
		var y := -h + 10.0 + float(r) * (h - 10.0) / float(rows)
		draw_line(Vector2(-w / 2.0, y), Vector2(w / 2.0, y), Color(0, 0, 0, 0.22), 1.5)
		var sx := -w / 2.0 + rng.randf_range(20.0, 60.0)
		while sx < w / 2.0 - 10.0:
			draw_line(Vector2(sx, y), Vector2(sx, y + (h - 10.0) / float(rows)), Color(0, 0, 0, 0.2), 1.5)
			sx += rng.randf_range(44.0, 86.0)
	# couronnement : le dessus des dalles (vu légèrement d'en haut) et leur tranche
	draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0 - 5.0, -h), Vector2(w / 2.0 + 5.0, -h), Vector2(w / 2.0 - 3.0, -h - 9.0), Vector2(-w / 2.0 + 3.0, -h - 9.0)]), col.lightened(0.22))
	draw_rect(Rect2(-w / 2.0 - 5.0, -h, w + 10.0, 7.0), col.lightened(0.08))


func _mist() -> void:
	var w: float = params.get("w", 900.0)
	for i in range(5):
		var x := fposmod(float(i) * w * 0.22 + t * (8.0 + float(i) * 3.0), w) - w * 0.1
		draw_colored_polygon(DrawUtil.ellipse(Vector2(x, -12.0 - float(i % 3) * 10.0), 190.0, 26.0, 20), Color(0.7, 0.75, 1.0, 0.07))


func _dead_tree() -> void:
	var h: float = params.get("h", 160.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(params.get("seed", 5))
	var col := Color("1c1a30")
	draw_line(Vector2(0, 0), Vector2(0, -h), col, 8.0, true)
	for i in range(6):
		var y := -h * (0.35 + float(i) * 0.11)
		var dir := -1.0 if i % 2 == 0 else 1.0
		var end := Vector2(dir * rng.randf_range(30.0, 70.0), y - rng.randf_range(20.0, 50.0))
		draw_line(Vector2(0, y), end, col, 4.0, true)
		draw_line(end, end + Vector2(dir * 14.0, -18.0), col, 2.5, true)
