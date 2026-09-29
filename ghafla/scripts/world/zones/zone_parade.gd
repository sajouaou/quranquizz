extends RefCounted
## L'avenue d'or (x 6400-9600) : un cortège somptueux (bannières, chariots de coffres, un char doré où se tient un homme riche,
## silhouette sans visage) avance, puis la terre s'ouvre et l'engloutit, lui et ses richesses. Une page se révèle alors.
## Le cortège est un décor : personne n'est touché, et l'homme n'est jamais nommé par le jeu autrement que par la sourate.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Rig := preload("res://scripts/cinematic/person_rig.gd")
const Sfx := preload("res://scripts/core/sfx.gd")

const TRIGGER_X := 7950.0  # le joueur s'approche : le cortège se met en marche
const FORM_X := 8400.0  # centre du cortège au départ
const MARCH_PX := 200.0
const MARCH_SECONDS := 3.4
const CRACK_SECONDS := 1.2
const SINK_SECONDS := 3.4
const SINK_DEPTH := 340.0
const GROUND_TOP := Color("b98a4a")
const GROUND_BOTTOM := Color("3a2410")
const EDGE := Color("ffe08a")

var phase: String = "wait"  # wait, march, crack, sink, close, done
var _world: Node2D
var _t: float = 0.0
var _parade: Node2D
var _gap: Node2D
var _sides: Node2D
var _crack: float = 0.0
var _sink: float = 0.0
var _shift: float = 0.0


class Parade:
	extends Node2D
	var zone: RefCounted
	var rig: Node2D
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _banner(x: float, hue: float) -> void:
		draw_line(Vector2(x, 0), Vector2(x, -330), Color("5a3a1a"), 6.0, true)
		draw_circle(Vector2(x, -334), 7.0, Color("e9c46a"))
		var sway := sin(t * 2.0 + x) * 8.0
		var flag := PackedVector2Array([Vector2(x, -320), Vector2(x + 70.0 + sway, -300), Vector2(x + 60.0 + sway, -262), Vector2(x, -240)])
		draw_colored_polygon(flag, Color.from_hsv(hue, 0.7, 0.85))
		draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2], flag[3], flag[0]]), Color("e9c46a"), 2.0, true)
		draw_colored_polygon(DrawUtil.star(Vector2(x + 30.0 + sway * 0.5, -280), 11.0, 5.5, 8), Color("f5e6a8"))

	func _cart(x: float) -> void:
		draw_rect(Rect2(x - 70, -60, 140, 26), Color("6b4a2a"))
		draw_rect(Rect2(x - 70, -60, 140, 5), Color("3d2a1a"))
		for wx in [-46.0, 46.0]:
			var c := Vector2(x + wx, -26)
			draw_circle(c, 26.0, Color("3d2a1a"))
			draw_circle(c, 20.0, Color("6b4a2a"))
			for k in range(4):
				var a := float(k) * PI / 4.0 + float(zone.get("_wheel"))
				draw_line(c - Vector2(cos(a), sin(a)) * 20.0, c + Vector2(cos(a), sin(a)) * 20.0, Color("3d2a1a"), 2.0)
		# coffres dorés empilés
		for r in range(2):
			for k in range(3 - r):
				var bx := x - 54.0 + float(k) * 40.0 + float(r) * 20.0
				var by := -60.0 - 26.0 * float(r + 1)
				draw_rect(Rect2(bx, by, 36, 26), Color("c99a3a"))
				draw_rect(Rect2(bx, by, 36, 6), Color("e9c46a"))
				draw_rect(Rect2(bx + 15, by + 8, 6, 8), Color("6b4a1a"))

	func _chariot() -> void:
		# un char doré à quatre roues, sans monture : plateforme, colonnes nues, baldaquin
		var gold := Color("e9c46a")
		var dark := Color("9a7420")
		draw_rect(Rect2(-130, -74, 260, 22), gold)
		draw_rect(Rect2(-130, -74, 260, 5), gold.lightened(0.25))
		draw_rect(Rect2(-130, -54, 260, 4), dark)
		for wx in [-92.0, 92.0]:
			var c := Vector2(wx, -34)
			draw_circle(c, 36.0, dark)
			draw_circle(c, 29.0, gold)
			draw_circle(c, 8.0, dark)
			for k in range(6):
				var a := float(k) * PI / 6.0 + float(zone.get("_wheel"))
				draw_line(c - Vector2(cos(a), sin(a)) * 29.0, c + Vector2(cos(a), sin(a)) * 29.0, dark, 3.0)
		for cx in [-116.0, 116.0]:
			draw_rect(Rect2(cx - 5, -230, 10, 156), gold)
		draw_arc(Vector2(0, -230), 116.0, PI, TAU, 30, gold, 10.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(-132, -232), Vector2(132, -232), Vector2(112, -262), Vector2(-112, -262)]), Color("c74a5a"))
		draw_polyline(PackedVector2Array([Vector2(-132, -232), Vector2(-112, -262), Vector2(112, -262), Vector2(132, -232)]), gold, 3.0, true)
		DrawUtil.glow(self, Vector2(0, -150), 210.0, Color(1.0, 0.85, 0.45, 0.18))

	func _draw() -> void:
		var off := Vector2(0, float(zone.get("_sink")) * SINK_DEPTH)
		draw_set_transform(off, 0.0, Vector2.ONE)
		_banner(-580.0, 0.02)
		_banner(-450.0, 0.09)
		_cart(-300.0)
		_chariot()
		_cart(310.0)
		_banner(450.0, 0.09)
		_banner(580.0, 0.02)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if rig != null:
			rig.position = Vector2(0, -74.0) + off


class Crack:
	extends Node2D
	## layer « gap » : le fond noir de la faille (derrière le cortège) ; layer « sides » : le sol qui recouvre le cortège quand il s'enfonce.
	var zone: RefCounted
	var layer: String = "gap"

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var crack: float = zone.get("_crack")
		if crack <= 0.005:
			return
		var cx: float = FORM_X + float(zone.get("_shift"))
		var gw := 30.0 + crack * 210.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 91
		if layer == "gap":
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for i in range(9):
				var y := 616.0 + float(i) * 48.0
				var j := rng.randf_range(-14.0, 14.0)
				left.append(Vector2(cx - gw + j, y))
				right.append(Vector2(cx + gw - j, y))
			var poly := PackedVector2Array()
			for p in left:
				poly.append(p)
			for i in range(right.size() - 1, -1, -1):
				poly.append(right[i])
			draw_colored_polygon(poly, Color("0c0608"))
			DrawUtil.glow(self, Vector2(cx, 640.0), gw * 1.6, Color(1.0, 0.6, 0.25, 0.10 * crack))
		else:
			var span := 380.0
			var bottom_y := 1000.0
			var k := (bottom_y - 620.0) / 1180.0
			var low := GROUND_TOP.lerp(GROUND_BOTTOM, k)
			for side in [-1.0, 1.0]:
				var x0: float = cx + side * gw if side > 0.0 else cx - span
				var x1: float = cx + span if side > 0.0 else cx - gw
				if x1 - x0 < 1.0:
					continue
				draw_polygon(PackedVector2Array([Vector2(x0, 622.0), Vector2(x1, 622.0), Vector2(x1, bottom_y), Vector2(x0, bottom_y)]), PackedColorArray([GROUND_TOP, GROUND_TOP, low, low]))
				draw_line(Vector2(x0, 620.0), Vector2(x1, 620.0), EDGE, 4.0, true)
			# poussière qui s'élève de la faille
			for i in range(14):
				var u := float(i) / 14.0
				var age := fposmod(float(zone.get("_t")) * 0.6 + u, 1.0)
				var px := cx + (rng.randf() * 2.0 - 1.0) * gw
				draw_circle(Vector2(px, 620.0 - age * 190.0), 14.0 + age * 26.0, Color(0.85, 0.7, 0.45, 0.28 * crack * (1.0 - age)))


func build(w: Node2D) -> void:
	_world = w
	var ground := PackedVector2Array()
	for gx in range(6400, 9601, 200):
		ground.append(Vector2(float(gx), 620.0))
	w.add_ground(ground, 63)
	# colonnade de façades dorées, au second plan
	var x := 6600.0
	var i := 0
	while x < 9500.0:
		w.add_prop("facade", Vector2(x, 620), {"w": 250.0, "h": 300.0 + float((i * 41) % 110), "seed": i + 70, "tint": Color("d9b56a").lerp(Color("e8c880"), float(i % 3) / 3.0), "style": "dome"})
		x += 360.0 + float((i * 23) % 60)
		i += 1
	for lx in [6700.0, 7400.0, 8100.0, 8800.0, 9400.0]:
		w.add_prop("lamp_post", Vector2(lx, 620), {"h": 200.0}, true)
	if w.save.flag(w.ckey("ev_qarun_fell")):
		phase = "done"
		return
	_gap = Crack.new()
	_gap.zone = self
	_gap.layer = "gap"
	w.pages_root.add_child(_gap)
	_parade = Parade.new()
	_parade.zone = self
	_parade.position = Vector2(FORM_X, 620)
	w.pages_root.add_child(_parade)
	var rig := Rig.new()
	rig.thobe_color = Color("f4dc9a")
	rig.shade = 0.0
	_parade.add_child(rig)
	_parade.rig = rig
	_sides = Crack.new()
	_sides.zone = self
	_sides.layer = "sides"
	w.pages_root.add_child(_sides)


var _wheel: float = 0.0


func process(w: Node2D, delta: float) -> void:
	if phase == "done" or _parade == null:
		return
	_t += delta
	match phase:
		"wait":
			if w.player.position.x >= TRIGGER_X:
				phase = "march"
				_t = 0.0
				w.player.frozen = true  # il regarde passer le cortège
				w.toast_text("Un cortège… tout l'or du monde semble le suivre.")
		"march":
			var k := clampf(_t / MARCH_SECONDS, 0.0, 1.0)
			var nx := smoothstep(0.0, 1.0, k) * MARCH_PX
			_wheel += (nx - _shift) / 26.0
			_shift = nx
			_parade.position.x = FORM_X + _shift
			if _t >= MARCH_SECONDS:
				phase = "crack"
				_t = 0.0
				Sfx.play("wind", -4.0, 0.6)
		"crack":
			_crack = clampf(_t / CRACK_SECONDS, 0.0, 1.0)
			if _t >= CRACK_SECONDS + 0.4:
				phase = "sink"
				_t = 0.0
		"sink":
			_sink = smoothstep(0.0, 1.0, clampf(_t / SINK_SECONDS, 0.0, 1.0))
			if _t >= SINK_SECONDS:
				phase = "close"
				_t = 0.0
				_parade.visible = false
				w.toast_text("La terre l'a englouti, lui et sa demeure.")
				w.trigger_event("qarun_fell")
				w.player.frozen = false
		"close":
			_crack = 1.0 - clampf(_t / 2.2, 0.0, 1.0)
			if _t >= 2.2:
				phase = "done"
				_crack = 0.0
				for n in [_gap, _sides, _parade]:
					if is_instance_valid(n):
						n.queue_free()
