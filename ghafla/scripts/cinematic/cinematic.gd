extends Node2D
## Cinématique d'ouverture. Aucun visage, jamais : des silhouettes, de la lumière, une chambre.
##  1. Un homme lit le Mushaf avec soin, le range, éteint la lampe et s'endort.
##  2. Un autre homme voit le Mushaf, hésite... et s'endort sans l'ouvrir.
##  3. Le soleil entre dans sa chambre : il se réveille en sursaut, il a manqué Fajr.
##  4. Il ouvre le Mushaf : les pages sont devenues blanches, l'encre s'envole.
## Note : histoire fictive et symbolique. Rien ici n'est une règle religieuse ni ne se moque de personne.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Rig := preload("res://scripts/cinematic/person_rig.gd")
const Assets := preload("res://scripts/core/assets.gd")
const Sfx := preload("res://scripts/core/sfx.gd")

signal finished

const FLOOR_Y := 560.0
const BED_END_X := 548.0
const TABLE_X := 700.0

var skipped: bool = false
var done: bool = false

var room: Node2D
var stage: Node2D
var rig_a: Node2D
var rig_b: Node2D
var blanket: Node2D
var closeup: Node2D
var cam: Camera2D
var _overlay: CanvasLayer
var _bars: Array = []
var _caption: Label
var _fade: ColorRect
var _skip_label: Label
var _cap_tween: Tween

const SIT_READ := {"hip": Vector2(0, -46), "body_rot": 0.20, "head_tilt": 0.30, "hand_f": Vector2(30, 32), "hand_b": Vector2(24, 30), "skirt": 0.0, "foot_f": Vector2(44, -2), "foot_b": Vector2(38, -2)}
const SIT_SLUMP := {"hip": Vector2(0, -46), "body_rot": 0.30, "head_tilt": 0.28, "hand_f": Vector2(22, 44), "hand_b": Vector2(16, 44), "skirt": 0.0, "foot_f": Vector2(44, -2), "foot_b": Vector2(38, -2)}
const STAND := {"hip": Vector2(0, -86), "body_rot": 0.0, "head_tilt": 0.0, "hand_f": Vector2(6, 50), "hand_b": Vector2(2, 50), "skirt": 1.0, "foot_f": Vector2(10, 0), "foot_b": Vector2(-10, 0)}
const LIE := {"hip": Vector2(0, -78), "body_rot": -PI / 2.0, "head_tilt": 0.0, "hand_f": Vector2(4, 44), "hand_b": Vector2(0, 44), "skirt": 0.0, "foot_f": Vector2(86, -78), "foot_b": Vector2(80, -78)}
const SIT_UP := {"hip": Vector2(0, -78), "body_rot": -0.12, "head_tilt": -0.05, "hand_f": Vector2(20, 40), "hand_b": Vector2(12, 40), "skirt": 0.0, "foot_f": Vector2(86, -78), "foot_b": Vector2(80, -78)}


# ----------------------------------------------------------------------------------- éléments dessinés

class Room:
	extends Node2D
	var warm: float = 1.0
	var night: float = 1.0
	var dawn: float = 0.0
	var lamp: float = 1.0
	var ray: float = 0.0
	var moon_t: float = 0.0
	var book_on_stand: bool = false
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var day_c := Color("7a5238").lerp(Color("6d7aa0"), 1.0 - warm)
		var night_c := Color("2a1d24").lerp(Color("141a33"), 1.0 - warm)
		var wall := night_c.lerp(day_c, (1.0 - night) * 0.75)
		DrawUtil.vgrad(self, Rect2(0, 0, 1280, FLOOR_Y), wall.lightened(0.05), wall.darkened(0.12))
		# plancher
		var floor_c := Color("4a3324").lerp(Color("2a2434"), 1.0 - warm)
		DrawUtil.vgrad(self, Rect2(0, FLOOR_Y, 1280, 160), floor_c.lightened(0.05 + (1.0 - night) * 0.15), floor_c.darkened(0.35))
		draw_rect(Rect2(0, FLOOR_Y - 16.0, 1280, 16.0), wall.darkened(0.3))
		for i in range(9):
			draw_line(Vector2(0, FLOOR_Y + 18.0 + float(i) * 16.0), Vector2(1280, FLOOR_Y + 18.0 + float(i) * 16.0), Color(0, 0, 0, 0.12), 2.0)
		_window()
		_furniture()

	func _window() -> void:
		var win := Rect2(930, 150, 200, 220)
		var top := Color("070a26").lerp(Color("4a3f86"), dawn)
		var mid := Color("101642").lerp(Color("c4627b"), dawn)
		var bot := Color("1a1f4a").lerp(Color("f8b98c"), dawn)
		DrawUtil.vgrad(self, Rect2(win.position, Vector2(win.size.x, win.size.y * 0.6)), top, mid)
		DrawUtil.vgrad(self, Rect2(win.position + Vector2(0, win.size.y * 0.6 - 1.0), Vector2(win.size.x, win.size.y * 0.4 + 1.0)), mid, bot)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in range(26):
			var sx := win.position.x + rng.randf() * win.size.x
			var sy := win.position.y + rng.randf() * win.size.y * 0.75
			draw_circle(Vector2(sx, sy), 1.2 + rng.randf(), Color(1, 0.96, 0.85, (1.0 - dawn) * (0.5 + 0.4 * sin(t * 2.0 + float(i)))))
		# croissant de lune qui descend
		var moon := Vector2(win.position.x + 60.0 + moon_t * 40.0, win.position.y + 40.0 + moon_t * 120.0)
		var ma := clampf(1.0 - dawn * 1.1, 0.0, 1.0)
		if ma > 0.02:
			draw_colored_polygon(DrawUtil.crescent(moon, 22.0, 0.42, -0.5), Color(0.96, 0.95, 0.88, ma))
		# soleil qui apparaît à l'horizon de la fenêtre
		if dawn > 0.55:
			var s := (dawn - 0.55) / 0.45
			draw_circle(Vector2(win.position.x + 70.0, win.end.y - 10.0 - s * 46.0), 24.0, Color(1.0, 0.92, 0.65, 0.95))
		# cadre, croisillons, rebord
		draw_rect(win, Color("1c1530"), false, 8.0)
		draw_line(win.position + Vector2(win.size.x * 0.5, 0), win.position + Vector2(win.size.x * 0.5, win.size.y), Color("1c1530"), 5.0)
		draw_line(win.position + Vector2(0, win.size.y * 0.5), win.position + Vector2(win.size.x, win.size.y * 0.5), Color("1c1530"), 5.0)
		draw_rect(Rect2(win.position.x - 12.0, win.end.y, win.size.x + 24.0, 10.0), Color("d9cdb5").darkened(night * 0.5))
		# rideaux
		var curtain := Color("8f5a7a").lerp(Color("4a4e78"), 1.0 - warm).darkened(night * 0.45)
		draw_colored_polygon(PackedVector2Array([Vector2(900, 140), Vector2(946, 140), Vector2(936, 380), Vector2(900, 380)]), curtain)
		draw_colored_polygon(PackedVector2Array([Vector2(1114, 140), Vector2(1160, 140), Vector2(1160, 380), Vector2(1124, 380)]), curtain)
		draw_line(Vector2(890, 140), Vector2(1170, 140), Color("3a2a44"), 5.0)

	func _furniture() -> void:
		var wood := Color("5b3d2a").lerp(Color("3a3448"), 1.0 - warm).darkened(night * 0.3)
		var wood_l := wood.lightened(0.12)
		# lit bas
		draw_rect(Rect2(90, 512, 480, 48), wood)
		draw_rect(Rect2(74, 462, 18, 98), wood.darkened(0.15))
		draw_rect(Rect2(100, 490, 460, 26), Color("e6ded0").darkened(night * 0.5))
		DrawUtil.rrect(self, Rect2(112, 470, 96, 28), Color("f2eadb").darkened(night * 0.5), 12.0)
		# table et étagère
		draw_rect(Rect2(640, 500, 150, 12), wood_l)
		draw_rect(Rect2(652, 512, 10, 48), wood)
		draw_rect(Rect2(768, 512, 10, 48), wood)
		draw_rect(Rect2(600, 300, 250, 10), wood_l)
		var rng := RandomNumberGenerator.new()
		rng.seed = 21
		var bx := 610.0
		while bx < 830.0:
			var bw := rng.randf_range(10.0, 18.0)
			var bh := rng.randf_range(34.0, 56.0)
			draw_rect(Rect2(bx, 300.0 - bh, bw, bh), Color.from_hsv(rng.randf_range(0.5, 0.95), 0.3, rng.randf_range(0.35, 0.6)).darkened(night * 0.35))
			bx += bw + 2.0
		# support (rehal) du Mushaf, sur la table : deux planchettes croisées, sans ornement
		var sx := TABLE_X - 10.0
		draw_line(Vector2(sx - 22.0, 500), Vector2(sx + 22.0, 448), wood.darkened(0.2), 5.0, true)
		draw_line(Vector2(sx + 22.0, 500), Vector2(sx - 22.0, 448), wood.darkened(0.2), 5.0, true)
		if book_on_stand:
			var pts := PackedVector2Array([Vector2(sx - 30.0, 494), Vector2(sx + 30.0, 494), Vector2(sx + 26.0, 434), Vector2(sx - 26.0, 434)])
			draw_colored_polygon(pts, Color("1f6f5c").darkened(night * 0.45))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("e9c46a").darkened(night * 0.3), 2.0, true)
			draw_colored_polygon(DrawUtil.star(Vector2(sx, 464), 13.0, 6.5, 8), Color("e9c46a").darkened(night * 0.3))
		# lampe de chevet
		var lx := 764.0
		draw_line(Vector2(lx, 500), Vector2(lx, 450), Color("2a1f38"), 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 26.0, 452), Vector2(lx + 26.0, 452), Vector2(lx + 16.0, 414), Vector2(lx - 16.0, 414)]), Color("f0d9a0").lerp(Color("6a6068"), 1.0 - lamp))
		# tapis
		DrawUtil.rrect(self, Rect2(230, 556, 420, 8), Color("8f3a52").lerp(Color("3a4a6a"), 1.0 - warm).darkened(night * 0.4), 3.0)


class BedCover:
	extends Node2D
	var color: Color = Color("3d4a8a")
	var x0: float = 330.0
	var x1: float = 560.0
	var top_y: float = 476.0
	var amount: float = 0.0  # 0 : pas de couverture ; 1 : tirée sur les jambes
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if amount <= 0.01:
			return
		var pts := PackedVector2Array()
		var n := 24
		var xs := lerpf(x1, x0, amount)
		for i in range(n + 1):
			var u := float(i) / float(n)
			var x := lerpf(xs, x1, u)
			var bump := sin(u * PI) * 12.0 + sin(u * 9.0 + t * 1.2) * 1.6
			pts.append(Vector2(x, top_y - bump))
		pts.append(Vector2(x1, 512.0))
		pts.append(Vector2(xs, 512.0))
		draw_colored_polygon(pts, color)
		draw_polyline(pts.slice(0, n + 1), color.lightened(0.18), 2.0, true)
		for i in range(4):
			var gx := lerpf(xs + 24.0, x1 - 24.0, float(i) / 3.0)
			draw_colored_polygon(DrawUtil.star(Vector2(gx, top_y + 14.0), 8.0, 4.0, 8), Color(0.91, 0.77, 0.42, 0.55))


class Light:
	extends Node2D
	var room: Node2D
	var lamp_glow: float = 0.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if room == null:
			return
		var lamp: float = room.lamp
		if lamp > 0.01:
			DrawUtil.glow(self, Vector2(764, 434), 380.0, Color(1.0, 0.78, 0.45, 0.42 * lamp))
			DrawUtil.glow(self, Vector2(764, 434), 120.0, Color(1.0, 0.9, 0.7, 0.35 * lamp))
		# clair de lune dans la chambre
		var moon: float = clampf(1.0 - float(room.dawn) * 1.3, 0.0, 1.0) * float(room.night) * 0.5
		if moon > 0.01:
			DrawUtil.glow(self, Vector2(1030, 260), 360.0, Color(0.6, 0.7, 1.0, 0.16 * moon))
		# rayon de soleil qui traverse la chambre et remonte sur le lit
		var ray: float = room.ray
		if ray > 0.001:
			var cx := lerpf(900.0, 330.0, ray)
			var quad := PackedVector2Array([Vector2(936, 200), Vector2(1126, 200), Vector2(cx + 120.0, 500), Vector2(cx - 120.0, 500)])
			var a := 0.30 * minf(1.0, ray * 2.0)
			var cols := PackedColorArray([Color(1.0, 0.86, 0.5, a), Color(1.0, 0.86, 0.5, a), Color(1.0, 0.88, 0.6, a * 0.5), Color(1.0, 0.88, 0.6, a * 0.5)])
			draw_polygon(quad, cols)
			DrawUtil.glow(self, Vector2(cx, 480), 200.0, Color(1.0, 0.86, 0.5, 0.45 * ray))


class CloseUp:
	extends Node2D
	## Le Mushaf en gros plan : l'encre quitte les lignes en particules dorées, les pages deviennent blanches.
	var ink: float = 1.0
	var bg: float = 0.0
	var flip: float = 0.0
	var flipping: bool = false
	var flips_done: int = 0
	var t: float = 0.0
	var _last_ink: float = 1.0
	var _motes: Array = []
	var _add: CanvasItemMaterial

	func _ready() -> void:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	func _process(delta: float) -> void:
		t += delta
		# l'encre qui s'envole : des particules naissent le long des lignes qui s'effacent
		if ink < _last_ink - 0.0005 and bg > 0.5:
			var vp := get_viewport_rect().size
			var c := vp * 0.5
			for i in range(int((_last_ink - ink) * 900.0) + 1):
				var side := -1.0 if randf() < 0.5 else 1.0
				var px := c.x + side * randf_range(30.0, 330.0)
				var py := c.y - 220.0 + randf() * 440.0
				_motes.append({"p": Vector2(px, py), "v": Vector2(randf_range(-20.0, 40.0), randf_range(-90.0, -30.0)), "life": randf_range(1.6, 3.4), "age": 0.0, "s": randf_range(1.0, 2.6)})
		_last_ink = ink
		var keep := []
		for m in _motes:
			m["age"] += delta
			m["p"] += m["v"] * delta + Vector2(sin(m["age"] * 2.0 + m["s"]) * 12.0 * delta, 0.0)
			m["v"] += Vector2(6.0, -20.0) * delta
			if m["age"] < m["life"]:
				keep.append(m)
		_motes = keep
		queue_redraw()

	func _draw() -> void:
		if bg <= 0.001:
			return
		var vp := get_viewport_rect().size
		var c := vp * 0.5
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.01, 0.01, 0.04, 0.82 * bg))
		var pw := 340.0
		var ph := 470.0
		var cover := Rect2(c.x - pw - 22.0, c.y - ph * 0.5 - 18.0, pw * 2.0 + 44.0, ph + 36.0)
		DrawUtil.rrect(self, cover, Color("1c3a2f", bg), 18.0, Color(0.91, 0.77, 0.42, 0.85 * bg), 3)
		for side in [-1.0, 1.0]:
			var r := Rect2(c.x + (0.0 if side > 0.0 else -pw) + side * 4.0, c.y - ph * 0.5, pw, ph)
			draw_rect(r, Color(P.PARCHMENT.r, P.PARCHMENT.g, P.PARCHMENT.b, bg))
			# page devenue blanche : elle s'éclaircit à mesure que l'encre s'en va
			draw_rect(r, Color(1, 1, 1, (1.0 - ink) * 0.7 * bg))
			_lines(r, side)
		DrawUtil.hgrad(self, Rect2(c.x - 26.0, c.y - ph * 0.5, 26.0, ph), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.3 * bg))
		DrawUtil.hgrad(self, Rect2(c.x, c.y - ph * 0.5, 26.0, ph), Color(0, 0, 0, 0.3 * bg), Color(0, 0, 0, 0.0))
		if flipping:
			var w := cos(flip * PI) * pw
			var top := c.y - ph * 0.5
			var lift := sin(flip * PI) * 14.0
			var quad := PackedVector2Array([Vector2(c.x, top), Vector2(c.x + w, top - lift), Vector2(c.x + w, top + ph + lift), Vector2(c.x, top + ph)])
			draw_colored_polygon(quad, Color(0.99, 0.98, 0.95, bg))
			DrawUtil.hgrad(self, Rect2(minf(c.x, c.x + w), top, absf(w), ph), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.12 * bg))
		# particules dorées (mélange additif)
		for m in _motes:
			var a := clampf(1.0 - float(m["age"]) / float(m["life"]), 0.0, 1.0)
			DrawUtil.glow(self, m["p"], 9.0 * float(m["s"]), Color(1.0, 0.86, 0.5, 0.75 * a))

	func _lines(r: Rect2, side: float) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + int(side * 10.0) + flips_done * 31
		var lines := 15
		var step := (r.size.y - 110.0) / float(lines)
		# ornement en tête de page
		var head_a := clampf(ink * 1.2, 0.0, 1.0) * bg
		draw_colored_polygon(DrawUtil.star(Vector2(r.get_center().x, r.position.y + 36.0), 12.0, 6.0, 8), Color(0.72, 0.53, 0.17, head_a))
		for i in range(lines):
			var y := r.position.y + 76.0 + step * (float(i) + 0.5)
			# les premières lignes s'effacent d'abord
			var la := clampf((ink * float(lines + 6) - float(i)) / 4.0, 0.0, 1.0) * bg
			if la <= 0.01:
				rng.randf()
				continue
			var x := r.position.x + 24.0
			var end_x := r.end.x - 24.0 if i < lines - 1 else r.position.x + r.size.x * 0.55
			while x < end_x:
				var seg := rng.randf_range(5.0, 12.0)
				var dy := rng.randf_range(-1.6, 1.6)
				draw_line(Vector2(x, y + dy), Vector2(minf(x + seg, end_x), y + dy), Color(0.25, 0.17, 0.06, 0.8 * la), 2.2, true)
				x += seg + rng.randf_range(2.0, 5.0)


# --------------------------------------------------------------------------------------------- mise en place

func _ready() -> void:
	room = Room.new()
	room.name = "Room"
	add_child(room)
	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	rig_a = Rig.new()
	rig_a.position = Vector2(BED_END_X, FLOOR_Y)
	stage.add_child(rig_a)
	rig_b = Rig.new()
	rig_b.position = Vector2(1400.0, FLOOR_Y)
	stage.add_child(rig_b)
	blanket = BedCover.new()
	blanket.name = "BedCover"
	stage.add_child(blanket)
	var light := Light.new()
	light.room = room
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = add
	add_child(light)

	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()

	_overlay = CanvasLayer.new()
	_overlay.layer = 30
	add_child(_overlay)
	closeup = CloseUp.new()
	closeup.bg = 0.0
	_overlay.add_child(closeup)
	for i in range(2):
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if i == 0 else Control.PRESET_BOTTOM_WIDE)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(0, 64)
		if i == 0:
			bar.offset_bottom = 64
		else:
			bar.offset_top = -64
		_overlay.add_child(bar)
		_bars.append(bar)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.anchor_left = 0.5
	_caption.anchor_right = 0.5
	_caption.anchor_top = 1.0
	_caption.anchor_bottom = 1.0
	_caption.offset_left = -560
	_caption.offset_right = 560
	_caption.offset_top = -150
	_caption.offset_bottom = -76
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_override("font", Assets.font_book())
	_caption.add_theme_font_size_override("font_size", 32)
	_caption.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_caption.add_theme_constant_override("outline_size", 8)
	_caption.modulate.a = 0.0
	_overlay.add_child(_caption)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_fade)
	_skip_label = Label.new()
	_skip_label.text = "Entrée · Échap : passer"
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.anchor_left = 1.0
	_skip_label.anchor_right = 1.0
	_skip_label.anchor_top = 1.0
	_skip_label.anchor_bottom = 1.0
	_skip_label.offset_left = -300
	_skip_label.offset_top = -40
	_skip_label.offset_right = -20
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.add_theme_font_size_override("font_size", 15)
	_skip_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_overlay.add_child(_skip_label)

	for rig in [rig_a, rig_b]:
		rig.shade_color = Color(0.03, 0.03, 0.08)
	# Hommes sans visage, contre-jour : silhouettes sombres teintées par la lumière de la pièce
	rig_a.shade = 0.35
	rig_b.shade = 0.55
	rig_b.thobe_color = Color("dcd6c8")
	blanket.color = Color("3d4a8a")
	blanket.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if done:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_skip"):
		skip()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.double_click:
		skip()


func skip() -> void:
	skipped = true


# ----------------------------------------------------------------------------------------------- utilitaires

func _wait(seconds: float) -> bool:
	# Attente qui rend la main tout de suite quand on passe la cinématique.
	var elapsed := 0.0
	while elapsed < seconds:
		if skipped or not is_inside_tree():
			return false
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return not skipped


func _tw(obj: Object, prop: String, to: Variant, dur: float, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	var tw := create_tween().set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(obj, prop, to, dur)


func _say(text: String, hold: float = 2.6) -> void:
	if _cap_tween != null and _cap_tween.is_valid():
		_cap_tween.kill()
	_caption.text = text
	_cap_tween = create_tween()
	_cap_tween.tween_property(_caption, "modulate:a", 1.0, 0.5)
	_cap_tween.tween_interval(hold)
	_cap_tween.tween_property(_caption, "modulate:a", 0.0, 0.7)


func _walk(rig: Node2D, to_x: float, dur: float, face: int) -> bool:
	rig.facing = face
	rig.walking = true
	rig.running = false
	_tw(rig, "position:x", to_x, dur, Tween.TRANS_LINEAR)
	var ok := await _wait(dur)
	rig.walking = false
	rig.pose(STAND, 0.3)
	return ok


func _zoom(to: float, dur: float) -> void:
	_tw(cam, "zoom", Vector2(to, to), dur)


# --------------------------------------------------------------------------------------------------- scénario

func run() -> void:
	room.warm = 1.0
	room.night = 1.0
	room.dawn = 0.0
	room.lamp = 1.0
	room.ray = 0.0
	room.moon_t = 0.0
	room.book_on_stand = false
	rig_a.position = Vector2(BED_END_X, FLOOR_Y)
	rig_a.facing = 1
	rig_a.pose(SIT_READ, 0.01)
	rig_a.book = 2.0
	_fade.color = Color(0, 0, 0, 1)
	await _run_steps()
	_finish()


func _finish() -> void:
	if done:
		return
	done = true
	# fondu au noir final avant de rendre la main
	_fade.color.a = 1.0
	closeup.bg = 0.0
	finished.emit()


func _run_steps() -> void:
	# ---- Ouverture : carton sur fond noir
	_say("Une nuit ordinaire.", 2.2)
	if not await _wait(3.2):
		return

	# ---- Premier homme : il lit, avec soin
	_tw(_fade, "color:a", 0.0, 1.6)
	_zoom(1.06, 14.0)
	if not await _wait(2.0):
		return
	if not await _wait(5.5):
		return
	# il tourne une page, lentement
	Sfx.play("page", -14.0, 0.85)
	rig_a.pose({"hand_f": Vector2(34, 26), "head_tilt": 0.36}, 0.6)
	if not await _wait(1.0):
		return
	rig_a.pose({"hand_f": Vector2(30, 32), "head_tilt": 0.30}, 0.6)
	if not await _wait(3.5):
		return
	# il ferme le Mushaf avec respect et le tient un instant contre lui
	rig_a.book = 1.0
	rig_a.pose({"hand_f": Vector2(22, 18), "hand_b": Vector2(18, 16), "body_rot": 0.10, "head_tilt": 0.18}, 1.2)
	if not await _wait(2.4):
		return
	# il se lève et le pose sur son support, plus haut que lui
	rig_a.pose({"skirt": 1.0}, 0.01)
	rig_a.pose(STAND, 1.0)
	rig_a.book = 1.0
	if not await _wait(1.2):
		return
	if not await _walk(rig_a, 640.0, 1.0, 1):
		return
	rig_a.pose({"hand_f": Vector2(44, 6), "hand_b": Vector2(38, 10), "body_rot": 0.10}, 0.8)
	if not await _wait(0.9):
		return
	rig_a.book = 0.0
	room.book_on_stand = true
	rig_a.pose(STAND, 0.8)
	if not await _wait(1.2):
		return
	# il éteint la lampe, le sommeil vient
	_tw(room, "lamp", 0.0, 1.2)
	if not await _wait(1.6):
		return
	if not await _walk(rig_a, BED_END_X, 1.0, -1):
		return
	rig_a.facing = 1
	rig_a.pose(SIT_SLUMP, 1.0)
	if not await _wait(1.4):
		return
	blanket.visible = true
	_tw(blanket, "amount", 1.0, 1.4)
	_tw(rig_a, "position:x", 300.0, 1.8)
	rig_a.pose(LIE, 1.8)
	rig_a.breath = 1.2
	if not await _wait(3.5):
		return

	# ---- Fondu enchaîné vers la chambre du second homme
	_tw(_fade, "color:a", 1.0, 1.4)
	if not await _wait(1.6):
		return
	rig_a.position.x = 1600.0
	blanket.visible = false
	blanket.amount = 0.0
	blanket.color = Color("4a5478")
	room.warm = 0.15
	room.night = 1.0
	room.dawn = 0.0
	room.lamp = 0.0
	room.ray = 0.0
	room.moon_t = 0.0
	room.book_on_stand = true
	cam.zoom = Vector2.ONE
	rig_b.position = Vector2(1400.0, FLOOR_Y)
	rig_b.facing = -1
	rig_b.pose(STAND, 0.01)
	_zoom(1.05, 30.0)
	_tw(_fade, "color:a", 0.0, 1.4)
	_say("Une autre chambre.", 2.4)
	if not await _wait(2.6):
		return

	# ---- Second homme : il entre, voit le Mushaf... et ne l'ouvre pas
	if not await _walk(rig_b, TABLE_X + 90.0, 3.6, -1):
		return
	rig_b.pose({"head_tilt": 0.28, "body_rot": 0.06}, 1.0)  # il regarde le Mushaf
	if not await _wait(2.8):
		return
	rig_b.pose({"head_tilt": 0.10, "body_rot": 0.10, "hand_f": Vector2(20, 46)}, 0.9)  # il hésite
	if not await _wait(1.6):
		return
	rig_b.pose({"head_tilt": -0.10, "body_rot": -0.04, "hand_f": Vector2(6, 50)}, 1.0)  # puis se détourne
	if not await _wait(1.4):
		return
	if not await _walk(rig_b, BED_END_X, 2.2, -1):
		return
	rig_b.facing = 1
	rig_b.pose(SIT_SLUMP, 1.2)
	if not await _wait(2.4):
		return
	blanket.visible = true
	_tw(blanket, "amount", 1.0, 1.4)
	_tw(rig_b, "position:x", 300.0, 1.8)
	rig_b.pose(LIE, 1.8)
	rig_b.breath = 1.2
	if not await _wait(3.4):
		return

	# ---- La nuit passe, l'aube arrive : le soleil entre dans la chambre
	_say("Le temps passe…", 2.4)
	_tw(room, "night", 0.35, 9.0)
	_tw(room, "dawn", 1.0, 9.0)
	_tw(room, "moon_t", 1.0, 9.0)
	_tw(room, "ray", 0.0, 0.01)
	if not await _wait(5.0):
		return
	_tw(room, "ray", 1.0, 5.5)
	if not await _wait(5.6):
		return

	# ---- Réveil en sursaut
	Sfx.play("heart", -6.0, 1.0)
	rig_b.pose(SIT_UP, 0.28, Tween.TRANS_BACK)
	rig_b.breath = 3.0
	# éclair de lumière dorée au réveil
	_fade.color = Color(1.0, 0.95, 0.8, 0.9)
	_tw(_fade, "color:a", 0.0, 1.2)
	if not await _wait(0.5):
		return
	Sfx.play("heart", -8.0, 0.95)
	_say("Astaghfirullah… le soleil ?!", 2.2)
	if not await _wait(2.6):
		return
	_say("Fajr… j'ai raté Fajr.", 2.6)
	rig_b.pose({"head_tilt": 0.25, "hand_f": Vector2(14, 30)}, 1.2)
	if not await _wait(3.4):
		return

	# ---- Il se lève et prend le Mushaf
	_tw(blanket, "amount", 0.0, 1.0)
	rig_b.pose(SIT_SLUMP, 0.6)
	if not await _wait(0.8):
		return
	_tw(rig_b, "position:x", BED_END_X, 0.8)
	rig_b.pose(STAND, 0.8)
	blanket.visible = false
	if not await _wait(1.0):
		return
	if not await _walk(rig_b, TABLE_X + 20.0, 1.6, 1):
		return
	rig_b.pose({"hand_f": Vector2(46, 4), "hand_b": Vector2(40, 8), "body_rot": 0.10}, 0.7)
	if not await _wait(0.9):
		return
	room.book_on_stand = false
	rig_b.book = 1.0
	rig_b.pose({"hand_f": Vector2(24, 20), "hand_b": Vector2(20, 18), "body_rot": 0.06, "head_tilt": 0.25}, 1.0)
	if not await _wait(1.4):
		return
	_say("Le Mushaf… Pourquoi est-il si léger ?", 2.8)
	if not await _wait(3.2):
		return

	# ---- Gros plan : l'encre s'envole, les pages blanchissent
	closeup.ink = 1.0
	closeup.flips_done = 0
	_tw(closeup, "bg", 1.0, 1.4)
	if not await _wait(2.6):
		return
	_tw(closeup, "ink", 0.0, 5.5, Tween.TRANS_LINEAR)
	if not await _wait(2.2):
		return
	_say("Les mots… ils s'en vont.", 2.4)
	if not await _wait(3.6):
		return
	# les pages défilent, toutes blanches
	for i in range(5):
		Sfx.play("page", -8.0, 0.8 + float(i) * 0.05)
		closeup.flipping = true
		closeup.flip = 0.0
		_tw(closeup, "flip", 1.0, 0.7, Tween.TRANS_SINE)
		if not await _wait(0.75):
			return
		closeup.flipping = false
		closeup.flips_done += 1
		if not await _wait(0.25):
			return
	if not await _wait(1.2):
		return
	_say("Les pages… elles sont vides.", 3.0)
	if not await _wait(3.8):
		return
	_tw(closeup, "bg", 0.0, 1.2)
	if not await _wait(1.4):
		return
	_say("Cette lumière, derrière la porte…", 2.6)
	if not await _wait(2.4):
		return
	_tw(_fade, "color", Color(1.0, 0.94, 0.78, 1.0), 1.4)
	if not await _wait(1.6):
		return
