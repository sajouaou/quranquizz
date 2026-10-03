extends Node2D
## Premier plan en parallaxe, dessiné en code (effet « 2.5D ») : ce qui passe DEVANT le personnage, plus vite que le décor.
## Herbes, roches ou stalagmites en bas de l'écran ; fanions, guirlandes, stalactites ou branches en haut ; grosses lueurs floues
## (bokeh) ; rayons de lumière obliques. Tout est sombre, flou et discret : il donne de la profondeur sans gêner la lecture.
## Ce nœud vit dans un CanvasLayer (coordonnées d'écran) : il lit la position de la caméra comme le fait backdrop.gd.
## Aucune figure : végétation, roche, tissu, lumière.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Gfx := preload("res://scripts/core/gfx.gd")

const FRONT := 1.45  # facteur de parallaxe de l'avant-plan : > 1, il défile plus vite que le monde
const BOKEH := 1.8
const RAYS := 0.9
const SPACING := 520.0  # un emplacement d'avant-plan tous les 520 px de monde

var world: Node2D
var camera: Camera2D
var t: float = 0.0
var _add: CanvasItemMaterial
var _glow_layer: Node2D


## Une couche additive (lueurs, rayons) dessinée par-dessus, avec son propre matériau.
class Glows:
	extends Node2D
	var owner_fg: Node2D

	func _draw() -> void:
		owner_fg.draw_glows(self)


func _ready() -> void:
	_add = CanvasItemMaterial.new()
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_layer = Glows.new()
	_glow_layer.owner_fg = self
	_glow_layer.material = _add
	add_child(_glow_layer)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	_glow_layer.queue_redraw()


static func _hash(i: int, salt: int) -> float:
	var h := (i * 73856093) ^ (salt * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFF) / 65535.0


func _view() -> Dictionary:
	var vp := get_viewport_rect().size
	var cam: Vector2 = camera.get_screen_center_position() if camera != null else Vector2(640, 420)
	return {"vp": vp, "cam": cam}


## Emplacements visibles pour un facteur de parallaxe : [{i, x (écran), zone}].
func _slots(vp: Vector2, cam: Vector2, factor: float, spacing: float, margin: float) -> Array:
	var out := []
	var first := int(floorf((cam.x - (vp.x * 0.5 + margin) / factor) / spacing))
	var last := int(ceilf((cam.x + (vp.x * 0.5 + margin) / factor) / spacing))
	for i in range(first, last + 1):
		var wx := (float(i) + _hash(i, 3) * 0.6) * spacing
		if wx < 0.0 or wx > world.world_w:
			continue
		out.append({"i": i, "x": (wx - cam.x) * factor + vp.x * 0.5, "wx": wx, "zone": world.zone_at(wx)})
	return out


func _draw() -> void:
	if world == null or camera == null or Gfx.low():
		return  # qualité basse : pas d'avant-plan
	var v := _view()
	var vp: Vector2 = v["vp"]
	var cam: Vector2 = v["cam"]
	var lift := (420.0 - cam.y) * 0.25  # un saut décale légèrement l'avant-plan
	var ground_col := _ground_color()
	for s in _slots(vp, cam, FRONT, SPACING, 260.0):
		var zone: String = s["zone"]
		if zone == "house" or zone == "home":
			continue
		var i: int = s["i"]
		var x: float = s["x"]
		match zone:
			"cave":
				_stalagmites(x, vp.y + 6.0 + lift, i, ground_col)
				_stalactites(x + 160.0, -6.0 + lift * 0.4, i)
			"peak", "graves":
				_rocks(x, vp.y + 8.0 + lift, i, ground_col)
				if zone == "graves":
					_branches(x + 120.0, -4.0, i)
			"market", "love", "parade":
				_tufts(x, vp.y + 8.0 + lift, i, ground_col)
				_bunting(x - 260.0, -4.0 + lift * 0.4, i, zone)
			_:
				_tufts(x, vp.y + 8.0 + lift, i, ground_col)
				_tufts(x + 240.0, vp.y + 8.0 + lift, i + 100, ground_col)


## Couleur de l'herbe d'avant-plan : le bord du sol, très assombri.
func _ground_color() -> Color:
	var sky := P.sky_at(camera.get_screen_center_position().x, world.chapter)
	return (sky["bottom"] as Color).lerp(P.NIGHT, 0.8)


func _soft_polygon(poly: PackedVector2Array, col: Color) -> void:
	# bords flous : un contour large et transparent autour de la forme pleine
	draw_polyline(poly + PackedVector2Array([poly[0]]), Color(col.r, col.g, col.b, col.a * 0.22), 16.0, true)
	draw_polyline(poly + PackedVector2Array([poly[0]]), Color(col.r, col.g, col.b, col.a * 0.35), 7.0, true)
	draw_colored_polygon(poly, col)


func _tufts(x: float, base_y: float, i: int, col: Color) -> void:
	var n := 6
	var w := 170.0 + _hash(i, 5) * 110.0
	var h := 30.0 + _hash(i, 6) * 34.0
	var pts := PackedVector2Array([Vector2(x - w * 0.5, base_y)])
	for k in range(n):
		var u := (float(k) + 0.5) / float(n)
		var blade_h := h * (0.45 + 0.55 * _hash(i * 13 + k, 8))
		var sway := sin(t * 0.9 + float(i) * 1.7 + float(k) * 0.6) * h * 0.14
		var bx := x - w * 0.5 + u * w
		pts.append(Vector2(bx - w / float(n) * 0.35, base_y - blade_h * 0.3))
		pts.append(Vector2(bx + sway, base_y - blade_h))
	pts.append(Vector2(x + w * 0.5, base_y))
	_soft_polygon(pts, Color(col.r, col.g, col.b, 0.80))


func _rocks(x: float, base_y: float, i: int, col: Color) -> void:
	var w := 120.0 + _hash(i, 9) * 120.0
	var h := 36.0 + _hash(i, 10) * 54.0
	var pts := PackedVector2Array([
		Vector2(x - w * 0.5, base_y), Vector2(x - w * 0.36, base_y - h * 0.6), Vector2(x - w * 0.1, base_y - h),
		Vector2(x + w * 0.14, base_y - h * 0.78), Vector2(x + w * 0.38, base_y - h * 0.42), Vector2(x + w * 0.5, base_y),
	])
	_soft_polygon(pts, Color(col.r, col.g, col.b, 0.94))


func _stalagmites(x: float, base_y: float, i: int, col: Color) -> void:
	for k in range(3):
		var w := 36.0 + _hash(i * 7 + k, 11) * 46.0
		var h := 50.0 + _hash(i * 7 + k, 12) * 100.0
		var cx := x + float(k) * 62.0 - 60.0
		_soft_polygon(PackedVector2Array([Vector2(cx - w * 0.5, base_y), Vector2(cx + (_hash(i + k, 14) - 0.5) * 10.0, base_y - h), Vector2(cx + w * 0.5, base_y)]), Color(col.r, col.g, col.b, 0.95))


func _stalactites(x: float, top_y: float, i: int) -> void:
	var col := Color(0.02, 0.02, 0.07, 0.9)
	for k in range(3):
		var w := 30.0 + _hash(i * 5 + k, 15) * 50.0
		var h := 40.0 + _hash(i * 5 + k, 16) * 90.0
		var cx := x + float(k) * 70.0 - 70.0
		_soft_polygon(PackedVector2Array([Vector2(cx - w * 0.5, top_y), Vector2(cx + w * 0.5, top_y), Vector2(cx + (_hash(i + k, 17) - 0.5) * 8.0, top_y + h)]), col)


func _branches(x: float, top_y: float, i: int) -> void:
	var col := Color(0.015, 0.02, 0.05, 0.9)
	var sway := sin(t * 0.5 + float(i)) * 6.0
	var pts := PackedVector2Array([Vector2(x, top_y), Vector2(x + 60.0 + sway, top_y + 70.0), Vector2(x + 150.0 + sway * 1.5, top_y + 96.0)])
	draw_polyline(pts, col, 7.0, true)
	draw_polyline(PackedVector2Array([pts[1], Vector2(pts[1].x + 50.0, pts[1].y + 60.0 + sway)]), col, 4.0, true)
	draw_polyline(PackedVector2Array([pts[1], Vector2(pts[1].x - 30.0, pts[1].y + 50.0)]), col, 3.5, true)


## Guirlande de fanions qui pend du haut de l'écran, translucide et floue.
func _bunting(x: float, top_y: float, i: int, zone: String) -> void:
	var span := 420.0 + _hash(i, 18) * 200.0
	var sag := 46.0 + _hash(i, 19) * 30.0
	var tint := Color(0.05, 0.02, 0.1)
	var seg := 14
	var prev := Vector2(x, top_y + 6.0)
	var rope := PackedVector2Array([prev])
	for k in range(1, seg + 1):
		var u := float(k) / float(seg)
		rope.append(Vector2(x + u * span, top_y + 6.0 + sin(u * PI) * sag))
	draw_polyline(rope, Color(tint, 0.65), 3.0, true)
	for k in range(1, seg):
		var p := rope[k]
		var flap := sin(t * 1.6 + float(k) * 0.9 + float(i)) * 3.0
		var fh := 26.0 + _hash(i * 17 + k, 20) * 16.0
		var c := tint
		if zone == "love":
			c = Color(0.28, 0.04, 0.14)
		elif zone == "parade":
			c = Color(0.25, 0.14, 0.03)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-9.0, 0.0), p + Vector2(9.0, 0.0), p + Vector2(flap, fh)]), Color(c, 0.6))


## Lueurs floues et rayons obliques, en mélange additif.
func draw_glows(c: Node2D) -> void:
	if world == null or camera == null or not Gfx.high():
		return  # lueurs floues et rayons : qualité haute seulement
	var v := _view()
	var vp: Vector2 = v["vp"]
	var cam: Vector2 = v["cam"]
	for s in _slots(vp, cam, BOKEH, 380.0, 220.0):
		var i: int = s["i"]
		var zone: String = s["zone"]
		if zone == "house" or zone == "home":
			continue
		var col := _bokeh_color(zone)
		var n := 2
		for k in range(n):
			var seed_i := i * 5 + k
			var r := 46.0 + _hash(seed_i, 21) * 70.0
			var x: float = float(s["x"]) + (_hash(seed_i, 22) - 0.5) * 300.0 + sin(t * 0.2 + float(seed_i)) * 14.0
			var y := vp.y * (0.12 + _hash(seed_i, 23) * 0.72) + cos(t * 0.15 + float(seed_i) * 1.3) * 10.0
			var a := col.a * (0.55 + 0.45 * sin(t * 0.6 + float(seed_i) * 2.1))
			DrawUtil.glow(c, Vector2(x, y), r, Color(col.r, col.g, col.b, a))
	# rayons de lumière : de larges bandes obliques très pâles qui descendent du haut
	for s in _slots(vp, cam, RAYS, 900.0, 300.0):
		var zone: String = s["zone"]
		if zone == "house" or zone == "home" or zone == "spirits":
			continue
		var i: int = s["i"]
		var x: float = s["x"]
		var w := 120.0 + _hash(i, 24) * 120.0
		var a := 0.05 + 0.025 * sin(t * 0.35 + float(i))
		var rc := _ray_color(zone)
		var slope := 260.0
		var quad := PackedVector2Array([Vector2(x, -20.0), Vector2(x + w, -20.0), Vector2(x + w - slope, vp.y * 0.9), Vector2(x - slope - w * 0.4, vp.y * 0.9)])
		var cols := PackedColorArray([Color(rc, a), Color(rc, a), Color(rc, 0.0), Color(rc, 0.0)])
		c.draw_polygon(quad, cols)


func _bokeh_color(zone: String) -> Color:
	match zone:
		"market":
			return Color(1.0, 0.72, 0.38, 0.13)
		"cave":
			return Color(0.5, 0.78, 1.0, 0.12)
		"peak":
			return Color(0.85, 0.9, 1.0, 0.10)
		"love":
			return Color(1.0, 0.5, 0.7, 0.14)
		"parade":
			return Color(1.0, 0.82, 0.4, 0.15)
		"spirits":
			return Color(0.9, 0.35, 0.85, 0.14)
		"graves":
			return Color(0.6, 0.72, 1.0, 0.09)
	return Color(1.0, 0.82, 0.55, 0.11)


func _ray_color(zone: String) -> Color:
	match zone:
		"cave":
			return Color(0.45, 0.65, 1.0)
		"peak", "graves":
			return Color(0.8, 0.85, 1.0)
		"love":
			return Color(1.0, 0.7, 0.8)
	return Color(1.0, 0.86, 0.6)
