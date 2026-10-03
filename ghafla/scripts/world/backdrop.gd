extends Node2D
## Ciel et arrière-plans en parallaxe, dessinés en code. Chaque zone du monde fige un moment
## différent de la journée : l'aube manquée, un midi immobile, la nuit de la grotte, puis l'aube qui revient.
## Aucune figure : uniquement du ciel, des formes géométriques et des silhouettes de bâtiments.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Gfx := preload("res://scripts/core/gfx.gd")

const WORLD_W := 15600.0

var camera: Camera2D
var chapter: int = 1
var world_w: float = WORLD_W
var t: float = 0.0
var _stars: Array = []
var _far: PackedVector2Array
var _near: PackedVector2Array
var _city: Array = []  # {x, w, h, kind}
var _city_mid: Array = []  # deuxième rangée de bâtiments, plus proche et plus haute (profondeur)
var _mid: PackedVector2Array
var _rock_far: PackedVector2Array
var _rock_near: PackedVector2Array
var _drips: Array = []
var _glow_add: CanvasItemMaterial
var skip: Dictionary = {}  # débogage : sections à ne pas dessiner


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in range(220):
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.72, rng.randf() * TAU))
	_far = DrawUtil.hills(rng, -200.0, world_w + 400.0, 0.0, 120.0, 60.0)
	_near = DrawUtil.hills(rng, -200.0, world_w + 400.0, 0.0, 70.0, 50.0)
	_rock_far = DrawUtil.hills(rng, -200.0, world_w + 400.0, 0.0, 200.0, 45.0)
	_rock_near = DrawUtil.hills(rng, -200.0, world_w + 400.0, 0.0, 120.0, 35.0)
	var x := -100.0
	while x < world_w + 300.0:
		var w := rng.randf_range(80.0, 190.0)
		var kind := "block"
		var r := rng.randf()
		if r > 0.86:
			kind = "minaret"
		elif r > 0.6:
			kind = "dome"
		_city.append({"x": x, "w": w, "h": rng.randf_range(50.0, 190.0), "kind": kind, "seed": rng.randi()})
		_city[_city.size() - 1]["lit"] = _lit_windows(_city[_city.size() - 1])
		x += w + rng.randf_range(-10.0, 40.0)
	for i in range(28):
		_drips.append(Vector3(rng.randf(), rng.randf(), rng.randf() * 3.0))
	_glow_add = CanvasItemMaterial.new()
	_glow_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Plans intermédiaires (tirés après les autres : la disposition existante ne change pas)
	_mid = DrawUtil.hills(rng, -200.0, world_w + 400.0, 0.0, 60.0, 40.0)
	x = -100.0
	while x < world_w + 300.0:
		var w2 := rng.randf_range(130.0, 260.0)
		var kind2 := "dome" if rng.randf() > 0.72 else "block"
		_city_mid.append({"x": x, "w": w2, "h": rng.randf_range(110.0, 290.0), "kind": kind2, "seed": rng.randi()})
		_city_mid[_city_mid.size() - 1]["lit"] = _lit_windows(_city_mid[_city_mid.size() - 1])
		x += w2 + rng.randf_range(-20.0, 60.0)


var _last_cam: Vector2 = Vector2(-1.0e9, 0.0)
var _since_draw: float = 0.0


## Le fond est le dessin le plus coûteux du jeu : il n'est refait que si la caméra a bougé, sinon quelques fois par seconde
## seulement (scintillement des étoiles, aiguilles des horloges). En qualité basse, un peu moins souvent encore.
func _process(delta: float) -> void:
	t += delta
	_since_draw += delta
	var cam := camera.get_screen_center_position() if camera != null else Vector2(640, 420)
	var moved := cam.distance_to(_last_cam) > 0.4
	var idle_period: float = Gfx.pick(0.2, 0.1, 0.066)
	if (moved and (not Gfx.low() or _since_draw >= 0.033)) or _since_draw >= idle_period:
		_last_cam = cam
		_since_draw = 0.0
		queue_redraw()


## Fenêtres allumées d'un bâtiment, tirées une fois pour toutes (positions relatives au coin haut-gauche).
static func _lit_windows(b: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rs := RandomNumberGenerator.new()
	rs.seed = b["seed"]
	for i in range(int(float(b["w"]) / 26.0)):
		for j in range(int(float(b["h"]) / 40.0)):
			if rs.randf() > 0.82:
				out.append(Vector2(10.0 + float(i) * 26.0, 14.0 + float(j) * 40.0))
	return out


func _weights(x: float) -> Dictionary:
	if chapter == 2:
		# ville puis collines : pas de grotte, pas de sommet
		return {"city": 1.0 - smoothstep(9300.0, 9900.0, x), "cave": 0.0, "peak": 0.0, "hills": 1.0}
	return {
		"city": 1.0 - smoothstep(8500.0, 9100.0, x),
		"cave": smoothstep(8900.0, 9400.0, x) * (1.0 - smoothstep(12000.0, 12500.0, x)),
		"peak": smoothstep(12300.0, 12900.0, x),
		"hills": 0.0,
	}


func _draw() -> void:
	var vp := get_viewport_rect().size
	var cam := camera.get_screen_center_position() if camera != null else Vector2(640, 420)
	var sky := P.sky_at(cam.x, chapter)
	var w := _weights(cam.x)
	var horizon := vp.y * 0.66 + (420.0 - cam.y) * 0.16

	# Ciel : trois bandes de dégradé
	DrawUtil.vgrad(self, Rect2(0, 0, vp.x, horizon * 0.55), sky["top"], sky["mid"])
	DrawUtil.vgrad(self, Rect2(0, horizon * 0.55 - 1.0, vp.x, horizon * 0.45 + 1.0), sky["mid"], sky["bottom"])
	DrawUtil.vgrad(self, Rect2(0, horizon - 1.0, vp.x, vp.y - horizon + 2.0), sky["bottom"], (sky["bottom"] as Color).darkened(0.45))

	if not skip.has("stars"):
		_draw_stars(vp, cam, sky["stars"])
	if not skip.has("moon"):
		_draw_moon_sun(vp, cam, sky, horizon)
	if not skip.has("clocks"):
		_draw_clocks(vp, cam, w["city"], horizon)
	_draw_rings(vp, cam, w["peak"], horizon)

	# Silhouettes lointaines
	var far_col := (sky["bottom"] as Color).lerp(sky["mid"], 0.55).darkened(0.25)
	var near_col := (sky["bottom"] as Color).lerp(P.NIGHT, 0.55)
	if (w["peak"] > 0.01 or w["city"] > 0.01 or w["hills"] > 0.01) and not skip.has("far"):
		_draw_hills(_far, cam, 0.12, vp, horizon + 6.0, DrawUtil.with_alpha(far_col, 1.0 - w["cave"]))
	if w["city"] > 0.01 and not skip.has("city"):
		_draw_city(cam, vp, horizon + 46.0, (sky["bottom"] as Color).lerp(P.NIGHT, 0.5), w["city"])
	# Deuxième rangée de bâtiments, plus proche et voilée de brume : le ciel, la ville lointaine, la ville proche, les collines, le monde
	if w["city"] > 0.01 and not skip.has("mid") and not Gfx.low():
		var mid_col := ((sky["bottom"] as Color).lerp(P.NIGHT, 0.62)).lerp(sky["mid"], 0.12)
		_draw_city(cam, vp, horizon + 120.0, mid_col, w["city"] * 0.95, 0.4, _city_mid)
	if (w["peak"] > 0.01 or w["city"] > 0.01 or w["hills"] > 0.01) and not skip.has("near"):
		_draw_hills(_near, cam, 0.5, vp, horizon + 150.0, DrawUtil.with_alpha(near_col, 1.0 - w["cave"]))
	if (w["peak"] > 0.01 or w["hills"] > 0.01) and not skip.has("mid"):
		_draw_hills(_mid, cam, 0.7, vp, horizon + 214.0, DrawUtil.with_alpha(near_col.darkened(0.18), 1.0 - w["cave"]))
	if w["cave"] > 0.01:
		_draw_cave(vp, cam, w["cave"])
	# Brume au sol
	var fog := DrawUtil.with_alpha(sky["bottom"], 0.22 * (1.0 - w["cave"]))
	DrawUtil.vgrad(self, Rect2(0, horizon + 60.0, vp.x, vp.y - horizon), Color(fog.r, fog.g, fog.b, 0.0), fog)


func _draw_stars(vp: Vector2, cam: Vector2, amount: float) -> void:
	if amount < 0.02:
		return
	var count: int = mini(_stars.size(), int(Gfx.pick(70, 140, 220)))
	for k in range(count):
		var s: Vector3 = _stars[k]
		var px: float = fposmod(s.x * vp.x - cam.x * 0.02, vp.x)
		var py: float = s.y * vp.y * 0.9
		var tw := 0.55 + 0.45 * sin(t * (0.6 + fmod(s.z, 1.7)) + s.z)
		var size := 1.0 + fmod(s.z, 1.3)
		# un petit carré coûte bien moins qu'un disque (un seul quadrilatère), et à cette taille on ne voit pas la différence
		draw_rect(Rect2(px - size, py - size, size * 2.0, size * 2.0), Color(1.0, 0.96, 0.85, amount * tw * 0.85))


func _draw_moon_sun(vp: Vector2, cam: Vector2, sky: Dictionary, horizon: float) -> void:
	var glow_amt: float = sky["glow"]
	var star_amt: float = sky["stars"]
	# Lueur de l'aube, mélange additif
	var sun_pos := Vector2(vp.x * 0.30 - cam.x * 0.015, horizon - 24.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glow_amt > 0.02:
		DrawUtil.glow(self, sun_pos, 420.0, Color(1.0, 0.72, 0.42, 0.34 * glow_amt))
		draw_circle(sun_pos, 30.0, Color(1.0, 0.9, 0.62, 0.55 * glow_amt))
		DrawUtil.glow(self, sun_pos, 90.0, Color(1.0, 0.95, 0.75, 0.5 * glow_amt))
	# Croissant de lune
	var moon := Vector2(vp.x * 0.80 - cam.x * 0.01, vp.y * 0.16)
	var a := clampf(star_amt * 1.3, 0.0, 1.0)
	if a > 0.05:
		DrawUtil.glow(self, moon, 150.0, Color(0.85, 0.9, 1.0, 0.16 * a))
		draw_colored_polygon(DrawUtil.crescent(moon, 40.0, 0.42, -0.5), Color(0.96, 0.95, 0.88, 0.92 * a))


func _draw_clocks(vp: Vector2, cam: Vector2, amount: float, horizon: float) -> void:
	# Le temps qui fuit : de grandes horloges suspendues dans le ciel, aux aiguilles qui reculent.
	var street := smoothstep(1700.0, 2400.0, cam.x) * (1.0 - smoothstep(8400.0, 8900.0, cam.x))
	var alpha := amount * street * 0.30
	if alpha < 0.01:
		return
	var defs := [[0.16, 0.30, 120.0], [0.52, 0.20, 78.0], [0.86, 0.34, 150.0], [1.25, 0.24, 96.0]]
	for d in defs:
		var cx := fposmod(d[0] * vp.x * 1.8 - cam.x * 0.09, vp.x * 1.8) - vp.x * 0.3
		var c := Vector2(cx, vp.y * d[1] + sin(t * 0.3 + d[0] * 5.0) * 6.0)
		var r: float = d[2]
		var col := Color(1.0, 0.93, 0.78, alpha)
		draw_arc(c, r, 0.0, TAU, 64, col, 2.5, true)
		draw_arc(c, r * 0.94, 0.0, TAU, 64, Color(col.r, col.g, col.b, alpha * 0.4), 1.0, true)
		for i in range(12):
			var ang := TAU * float(i) / 12.0
			var dir := Vector2(cos(ang), sin(ang))
			draw_line(c + dir * r * 0.86, c + dir * r * 0.95, col, 2.0, true)
		var m: float = -t * 0.7 - float(d[0])
		draw_line(c, c + Vector2(cos(m), sin(m)) * r * 0.75, col, 2.0, true)
		var h: float = m / 12.0
		draw_line(c, c + Vector2(cos(h), sin(h)) * r * 0.5, col, 3.0, true)


func _draw_rings(vp: Vector2, cam: Vector2, amount: float, horizon: float) -> void:
	# « Sept cieux superposés » : sept anneaux translucides au-dessus du sommet.
	if amount < 0.02:
		return
	var c := Vector2(vp.x * 0.5 - (cam.x - 14200.0) * 0.05, horizon - 250.0)
	for i in range(7):
		var r := 90.0 + float(i) * 46.0
		var a := amount * (0.26 - float(i) * 0.02)
		var start := t * (0.05 + float(i) * 0.01) * (1.0 if i % 2 == 0 else -1.0)
		draw_arc(c, r, start, start + TAU * 0.86, 90, Color(0.86, 0.9, 1.0, a), 2.0, true)
		draw_arc(c, r + 5.0, start + 0.6, start + TAU * 0.5, 60, Color(1.0, 0.9, 0.7, a * 0.5), 1.0, true)


func _draw_hills(line: PackedVector2Array, cam: Vector2, f: float, vp: Vector2, base_y: float, color: Color) -> void:
	if color.a < 0.01:
		return
	var left := cam.x * f - vp.x * 0.62
	var right := cam.x * f + vp.x * 0.62
	var pts := PackedVector2Array()
	for p in line:
		if p.x >= left - 60.0 and p.x <= right + 60.0:
			pts.append(Vector2(p.x - cam.x * f + vp.x * 0.5, p.y + base_y))
	if pts.size() < 2:
		return
	var lowest := vp.y + 10.0
	for q in pts:
		lowest = maxf(lowest, q.y + 10.0)
	DrawUtil.fill_to(self, pts, lowest, color)


func _draw_city(cam: Vector2, vp: Vector2, base_y: float, color: Color, amount: float, f: float = 0.28, rows: Array = []) -> void:
	var list: Array = rows if not rows.is_empty() else _city
	var left := cam.x * f - vp.x * 0.62
	var right := cam.x * f + vp.x * 0.62
	var col := DrawUtil.with_alpha(color, amount)
	for b in list:
		if b["x"] + b["w"] < left or b["x"] > right:
			continue
		var x: float = b["x"] - cam.x * f + vp.x * 0.5
		var w: float = b["w"]
		var h: float = b["h"]
		var top := base_y - h
		draw_rect(Rect2(x, top, w, h + 400.0), col)
		match b["kind"]:
			"dome":
				draw_colored_polygon(DrawUtil.ellipse(Vector2(x + w * 0.5, top), w * 0.42, w * 0.34, 20), col)
				draw_line(Vector2(x + w * 0.5, top - w * 0.34), Vector2(x + w * 0.5, top - w * 0.34 - 14.0), col, 2.0)
			"minaret":
				var mx := x + w * 0.5
				draw_rect(Rect2(mx - 7.0, top - 120.0, 14.0, 122.0), col)
				draw_rect(Rect2(mx - 11.0, top - 96.0, 22.0, 6.0), col)
				draw_colored_polygon(PackedVector2Array([Vector2(mx - 9.0, top - 120.0), Vector2(mx + 9.0, top - 120.0), Vector2(mx, top - 148.0)]), col)
		# fenêtres allumées, comme des veilleuses : presque toutes éteintes
		var lit_col := Color(1.0, 0.84, 0.5, 0.55 * amount)
		for o in b["lit"]:
			draw_rect(Rect2(x + o.x, top + o.y, 8.0, 12.0), lit_col)


func _draw_cave(vp: Vector2, cam: Vector2, amount: float) -> void:
	DrawUtil.vgrad(self, Rect2(0, 0, vp.x, vp.y), Color(0.03, 0.035, 0.09, amount), Color(0.09, 0.08, 0.17, amount))
	# Parois lointaines et proches, avec des stalactites qui pendent du plafond
	_draw_hills(_rock_far, cam, 0.25, vp, vp.y * 0.86, Color(0.07, 0.07, 0.14, amount))
	var top_line := PackedVector2Array()
	var left := cam.x * 0.35 - vp.x * 0.62
	var x := floorf(left / 60.0) * 60.0
	while x < cam.x * 0.35 + vp.x * 0.62:
		var h := 60.0 + 70.0 * absf(sin(x * 0.013) * cos(x * 0.0071)) + 40.0 * absf(sin(x * 0.041))
		top_line.append(Vector2(x - cam.x * 0.35 + vp.x * 0.5, h))
		x += 30.0
	if top_line.size() > 1:
		DrawUtil.fill_to(self, top_line, -10.0, Color(0.05, 0.05, 0.11, amount))
	# poussière luminescente
	for d in _drips:
		var px: float = fposmod(d.x * vp.x - cam.x * 0.15 + t * 6.0 * (0.5 + d.z * 0.3), vp.x)
		var py: float = fposmod(d.y * vp.y - t * 5.0 * (0.4 + d.z * 0.2), vp.y)
		draw_circle(Vector2(px, py), 1.4 + d.z * 0.3, Color(0.6, 0.85, 1.0, 0.25 * amount))
