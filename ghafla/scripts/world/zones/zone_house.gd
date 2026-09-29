extends RefCounted
## La maison, en coupe : chambre à l'étage, escalier, salon, porte d'entrée.
## Le joueur commence dans sa chambre et doit ouvrir la porte : la lumière qui filtre est son premier guide.

const P := preload("res://scripts/core/palette.gd")
const DrawUtil := preload("res://scripts/core/draw_util.gd")
const Interactable := preload("res://scripts/world/interactable.gd")
const Sfx := preload("res://scripts/core/sfx.gd")

const LEFT := 80.0
const RIGHT := 1930.0
const CEIL := 110.0
const UP_Y := 340.0
const GROUND := 620.0
const STAIR_TOP_X := 900.0
const STAIR_BOT_X := 1300.0
const DOOR_X := 1930.0

var door_open: float = 0.0
var door_block: Dictionary = {}
var _world: Node2D
var _art: Node2D
var _beam: Node2D
var _t: float = 0.0


class Art:
	extends Node2D
	var zone: RefCounted

	func _draw() -> void:
		zone.draw_house(self)


class Beam:
	extends Node2D
	var zone: RefCounted

	func _draw() -> void:
		zone.draw_light(self)


func build(w: Node2D) -> void:
	_world = w
	# Sol de la chambre, escalier, sol du salon : une seule ligne continue
	w.add_collision_line(PackedVector2Array([Vector2(LEFT, UP_Y), Vector2(STAIR_TOP_X, UP_Y), Vector2(STAIR_BOT_X, GROUND), Vector2(DOOR_X + 40.0, GROUND)]))
	w.add_static_rect(Rect2(LEFT - 40.0, -1200.0, 50.0, 2100.0))  # mur de gauche
	w.add_static_rect(Rect2(LEFT, 60.0, DOOR_X - LEFT + 30.0, CEIL - 60.0))  # plafond
	w.add_static_rect(Rect2(STAIR_BOT_X, UP_Y, DOOR_X - STAIR_BOT_X + 30.0, 24.0))  # plancher de l'étage droit
	w.add_static_rect(Rect2(DOOR_X, -1200.0, 34.0, 1640.0))  # mur au-dessus de la porte
	door_block = w.add_static_rect(Rect2(DOOR_X, 440.0, 34.0, GROUND - 440.0))  # la porte : bloque tant qu'elle est fermée

	_art = Art.new()
	_art.zone = self
	w.back_props.add_child(_art)
	_beam = Beam.new()
	_beam.zone = self
	w.glow_layer.add_child(_beam)

	var door := Interactable.new()
	door.id = "door" if w.chapter == 1 else "door2"
	door.prompt = "Ouvrir la porte"
	door.position = Vector2(DOOR_X - 60.0, GROUND - 80.0)
	door.used.connect(func(_id: String) -> void: open_door())
	door.remember_in(w.save)
	w.pages_root.add_child(door)
	if w.save.flag(w.ckey("door_open")):
		door_open = 1.0
		door_block["on"] = false

	w.add_glow(Vector2(1340.0, 470.0), 210.0, Color(1.0, 0.75, 0.42, 0.34), 0.05)  # lampadaire du salon
	w.add_glow(Vector2(560.0, 245.0), 180.0, Color(1.0, 0.8, 0.5, 0.20), 0.03)  # fenêtre


func open_door() -> void:
	if door_open > 0.0:
		return
	_world.save.set_flag(_world.ckey("door_open"))
	Sfx.play("door", -2.0, 1.0)
	door_block["on"] = false
	var tw := _world.create_tween()
	tw.tween_property(self, "door_open", 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func process(_w: Node2D, delta: float) -> void:
	_t += delta
	_art.queue_redraw()
	_beam.queue_redraw()


# ---------------------------------------------------------------------------------------------------------
# Dessin
# ---------------------------------------------------------------------------------------------------------

func draw_house(c: Node2D) -> void:
	var outline := Color("1c1530")
	var sky := P.sky_at(0.0, _world.chapter if _world != null else 1)
	# herbe et sol à l'extérieur, à gauche de la maison
	c.draw_rect(Rect2(-600, GROUND, 700, 900), Color("3b2f5c"))
	c.draw_line(Vector2(-600, GROUND), Vector2(LEFT, GROUND), Color("8f7cb8"), 4.0, true)
	# Intérieurs : étage gauche (chambre), étage droit (bureau fermé), rez-de-chaussée, cuisine dans l'ombre
	DrawUtil.vgrad(c, Rect2(LEFT, CEIL, STAIR_TOP_X - LEFT, UP_Y - CEIL), Color("5b6491"), Color("454e7c"))
	DrawUtil.vgrad(c, Rect2(STAIR_TOP_X, CEIL, STAIR_BOT_X - STAIR_TOP_X, GROUND - CEIL), Color("6a5b80"), Color("54476a"))
	DrawUtil.vgrad(c, Rect2(STAIR_BOT_X, CEIL, DOOR_X - STAIR_BOT_X, UP_Y - CEIL), Color("3b3155"), Color("2e2645"))
	DrawUtil.vgrad(c, Rect2(STAIR_BOT_X, UP_Y + 24.0, DOOR_X - STAIR_BOT_X, GROUND - UP_Y - 24.0), Color("b58a62"), Color("8f6a48"))
	DrawUtil.vgrad(c, Rect2(LEFT, UP_Y + 24.0, STAIR_TOP_X - LEFT, GROUND - UP_Y - 24.0), Color("2b2342"), Color("201a34"))

	_draw_bedroom(c, sky)
	_draw_kitchen_shadow(c)
	_draw_study(c)
	_draw_stairs(c)
	_draw_living(c)

	# Planchers et dalles
	var slab := Color("d9cdb5")
	c.draw_rect(Rect2(LEFT, UP_Y, STAIR_TOP_X - LEFT, 24.0), Color("6e4b33"))
	c.draw_rect(Rect2(LEFT, UP_Y, STAIR_TOP_X - LEFT, 5.0), Color("8a6446"))
	c.draw_rect(Rect2(STAIR_BOT_X, UP_Y, DOOR_X - STAIR_BOT_X + 30.0, 24.0), slab)
	c.draw_rect(Rect2(LEFT, CEIL - 24.0, DOOR_X - LEFT + 30.0, 24.0), slab)
	c.draw_rect(Rect2(LEFT - 24.0, CEIL - 24.0, 24.0, GROUND - CEIL + 100.0), slab)
	c.draw_rect(Rect2(STAIR_BOT_X, GROUND, DOOR_X - STAIR_BOT_X + 34.0, 8.0), Color("6e4b33"))
	# Toit-terrasse avec petit muret
	c.draw_rect(Rect2(LEFT - 24.0, CEIL - 46.0, DOOR_X - LEFT + 54.0, 22.0), slab.darkened(0.06))
	# Contour de la coupe
	c.draw_polyline(PackedVector2Array([Vector2(LEFT - 24.0, GROUND + 90.0), Vector2(LEFT - 24.0, CEIL - 46.0), Vector2(DOOR_X + 34.0, CEIL - 46.0), Vector2(DOOR_X + 34.0, 440.0)]), outline, 5.0, true)
	c.draw_line(Vector2(DOOR_X, CEIL - 24.0), Vector2(DOOR_X, 440.0), outline, 3.0, true)
	c.draw_rect(Rect2(LEFT - 24.0, GROUND, DOOR_X - LEFT + 58.0, 900.0), Color("2e2447"))
	c.draw_rect(Rect2(DOOR_X, CEIL - 24.0, 34.0, 440.0 - CEIL + 24.0), Color("d9cdb5"))
	_draw_door(c)


func _draw_bedroom(c: Node2D, sky: Dictionary) -> void:
	# Fenêtre : ciel d'aube, soleil déjà levé
	var win := Rect2(470.0, 178.0, 116.0, 128.0)
	DrawUtil.vgrad(c, Rect2(win.position, Vector2(win.size.x, win.size.y * 0.55)), sky["top"], sky["mid"])
	DrawUtil.vgrad(c, Rect2(win.position + Vector2(0, win.size.y * 0.55 - 1.0), Vector2(win.size.x, win.size.y * 0.45 + 1.0)), sky["mid"], sky["bottom"])
	c.draw_circle(win.position + Vector2(38.0, 104.0), 15.0, Color(1.0, 0.92, 0.65, 0.95))
	c.draw_rect(win, Color("1c1530"), false, 6.0)
	c.draw_line(win.position + Vector2(win.size.x * 0.5, 0), win.position + Vector2(win.size.x * 0.5, win.size.y), Color("1c1530"), 4.0)
	c.draw_line(win.position + Vector2(0, win.size.y * 0.5), win.position + Vector2(win.size.x, win.size.y * 0.5), Color("1c1530"), 4.0)
	c.draw_rect(Rect2(win.position.x - 8.0, win.end.y, win.size.x + 16.0, 8.0), Color("e0d3b8"))
	# rideaux
	c.draw_colored_polygon(PackedVector2Array([Vector2(452, 170), Vector2(486, 170), Vector2(478, 306), Vector2(452, 306)]), Color("8f5a7a"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(570, 170), Vector2(604, 170), Vector2(604, 306), Vector2(578, 306)]), Color("8f5a7a"))
	c.draw_line(Vector2(446, 170), Vector2(610, 170), Color("3a2a44"), 4.0)

	# Lit bas, oreiller, couverture aux motifs géométriques
	var bed_x := 118.0
	c.draw_rect(Rect2(bed_x, 300.0, 300.0, 40.0), Color("5b3d2a"))
	c.draw_rect(Rect2(bed_x - 12.0, 262.0, 14.0, 78.0), Color("4a3122"))
	c.draw_rect(Rect2(bed_x + 8.0, 286.0, 282.0, 18.0), Color("e6ded0"))
	DrawUtil.rrect(c, Rect2(bed_x + 12.0, 272.0, 74.0, 24.0), Color("f2eadb"), 10.0)
	var blanket := PackedVector2Array([Vector2(bed_x + 96.0, 288.0), Vector2(bed_x + 290.0, 284.0), Vector2(bed_x + 296.0, 304.0), Vector2(bed_x + 96.0, 306.0)])
	c.draw_colored_polygon(blanket, Color("46528f"))
	for i in range(3):
		c.draw_colored_polygon(DrawUtil.star(Vector2(bed_x + 140.0 + float(i) * 60.0, 296.0), 9.0, 5.0, 8), Color("e9c46a", 0.7))
	# Table de chevet et support (rehal) vide : le Mushaf est resté dans les mains de l'homme
	c.draw_rect(Rect2(428.0, 292.0, 34.0, 48.0), Color("6b4a2f"))
	c.draw_rect(Rect2(428.0, 292.0, 34.0, 4.0), Color("8a6446"))
	c.draw_line(Vector2(437.0, 290.0), Vector2(453.0, 258.0), Color("3d2a1a"), 3.0, true)
	c.draw_line(Vector2(453.0, 290.0), Vector2(437.0, 258.0), Color("3d2a1a"), 3.0, true)
	# Tapis
	DrawUtil.rrect(c, Rect2(210.0, 334.0, 330.0, 6.0), Color("8f3a52"), 3.0)
	for i in range(6):
		c.draw_colored_polygon(DrawUtil.star(Vector2(240.0 + float(i) * 52.0, 337.0), 6.0, 3.0, 8), Color("e9c46a", 0.85))
	# Étagère de livres ordinaires et armoire
	c.draw_rect(Rect2(640.0, 232.0, 150.0, 8.0), Color("6b4a2f"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bx := 646.0
	while bx < 780.0:
		var bw := rng.randf_range(9.0, 16.0)
		var bh := rng.randf_range(34.0, 52.0)
		c.draw_rect(Rect2(bx, 232.0 - bh, bw, bh), Color.from_hsv(rng.randf_range(0.5, 0.95), 0.35, rng.randf_range(0.45, 0.7)))
		bx += bw + 2.0
	c.draw_rect(Rect2(800.0, 180.0, 84.0, 160.0), Color("4a3a5a"))
	c.draw_line(Vector2(842.0, 180.0), Vector2(842.0, 340.0), Color("2a1f38"), 3.0)
	c.draw_circle(Vector2(835.0, 262.0), 3.0, Color("e9c46a"))
	c.draw_circle(Vector2(849.0, 262.0), 3.0, Color("e9c46a"))
	# Plafonnier éteint
	c.draw_line(Vector2(520.0, CEIL), Vector2(520.0, 158.0), Color("2a1f38"), 2.0)
	c.draw_colored_polygon(DrawUtil.ellipse(Vector2(520.0, 166.0), 22.0, 12.0, 20), Color("cdbf9f"))


func _draw_kitchen_shadow(c: Node2D) -> void:
	# Cuisine plongée dans la pénombre sous la chambre : quelques formes seulement.
	var col := Color("3a3054")
	c.draw_rect(Rect2(140.0, 520.0, 200.0, 100.0), col)
	c.draw_rect(Rect2(150.0, 500.0, 180.0, 22.0), col.lightened(0.05))
	c.draw_line(Vector2(560.0, 380.0), Vector2(560.0, 440.0), col, 3.0)
	c.draw_line(Vector2(700.0, 380.0), Vector2(700.0, 420.0), col, 3.0)
	c.draw_circle(Vector2(560.0, 452.0), 16.0, col)
	c.draw_circle(Vector2(700.0, 430.0), 12.0, col)
	c.draw_rect(Rect2(60.0 + LEFT, 400.0, 70.0, 10.0), col)


func _draw_study(c: Node2D) -> void:
	# Bureau à l'étage droit, porte close : simple ombre de mobilier
	var col := Color("241c3a")
	c.draw_rect(Rect2(1420.0, 270.0, 220.0, 12.0), col)
	c.draw_rect(Rect2(1430.0, 282.0, 10.0, 58.0), col)
	c.draw_rect(Rect2(1620.0, 282.0, 10.0, 58.0), col)
	c.draw_rect(Rect2(1700.0, 170.0, 150.0, 170.0), col)
	var win := Rect2(1500.0, 170.0, 90.0, 80.0)
	c.draw_rect(win, Color("4a3f74"))
	c.draw_rect(win, Color("1c1530"), false, 4.0)


func _draw_stairs(c: Node2D) -> void:
	var steps := 10
	var run := (STAIR_BOT_X - STAIR_TOP_X) / float(steps)
	var rise := (GROUND - UP_Y) / float(steps)
	c.draw_colored_polygon(PackedVector2Array([Vector2(STAIR_TOP_X, UP_Y), Vector2(STAIR_BOT_X, GROUND), Vector2(STAIR_BOT_X, GROUND + 10.0), Vector2(STAIR_TOP_X, GROUND + 10.0)]), Color("3a2c4a"))
	for i in range(steps):
		var x := STAIR_TOP_X + run * float(i)
		var y := UP_Y + rise * float(i)
		c.draw_rect(Rect2(x, y, run + 1.0, GROUND - y), Color("5a4058").lerp(Color("3a2c4a"), float(i) / float(steps)))
		c.draw_rect(Rect2(x, y, run + 1.0, 5.0), Color("9a7658"))
	# rampe et poteaux
	c.draw_line(Vector2(STAIR_TOP_X - 4.0, UP_Y - 92.0), Vector2(STAIR_BOT_X + 4.0, GROUND - 92.0), Color("4a3122"), 6.0, true)
	for i in range(6):
		var t := float(i) / 5.0
		var p := Vector2(lerpf(STAIR_TOP_X, STAIR_BOT_X, t), lerpf(UP_Y, GROUND, t))
		c.draw_line(p + Vector2(0, -4.0), p + Vector2(0, -92.0), Color("4a3122"), 4.0)


func _draw_living(c: Node2D) -> void:
	# Salon : banquette basse, table basse, bibliothèque, lampadaire
	var floor_y := GROUND
	# banquette (coussins de majlis)
	DrawUtil.rrect(c, Rect2(1420.0, floor_y - 52.0, 210.0, 52.0), Color("8f3a52"), 12.0)
	DrawUtil.rrect(c, Rect2(1420.0, floor_y - 88.0, 30.0, 88.0), Color("7a3046"), 12.0)
	DrawUtil.rrect(c, Rect2(1440.0, floor_y - 70.0, 60.0, 34.0), Color("e0b458"), 10.0)
	DrawUtil.rrect(c, Rect2(1520.0, floor_y - 70.0, 60.0, 34.0), Color("46528f"), 10.0)
	c.draw_colored_polygon(DrawUtil.star(Vector2(1470.0, floor_y - 53.0), 8.0, 4.0, 8), Color("f2eadb", 0.8))
	# table basse et corbeille de dattes
	DrawUtil.rrect(c, Rect2(1660.0, floor_y - 34.0, 120.0, 10.0), Color("6b4a2f"), 4.0)
	c.draw_rect(Rect2(1670.0, floor_y - 24.0, 8.0, 24.0), Color("4a3122"))
	c.draw_rect(Rect2(1762.0, floor_y - 24.0, 8.0, 24.0), Color("4a3122"))
	c.draw_colored_polygon(DrawUtil.ellipse(Vector2(1720.0, floor_y - 40.0), 26.0, 8.0, 18), Color("8a6446"))
	for i in range(5):
		c.draw_circle(Vector2(1706.0 + float(i) * 8.0, floor_y - 44.0 - float(i % 2) * 3.0), 4.0, Color("4a2a1a"))
	# bibliothèque
	c.draw_rect(Rect2(1810.0, 420.0, 96.0, 200.0), Color("5a3d2a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for row in range(4):
		var by := 432.0 + float(row) * 48.0
		c.draw_rect(Rect2(1816.0, by + 40.0, 84.0, 4.0), Color("3d2a1a"))
		var bx := 1818.0
		while bx < 1892.0:
			var bw := rng.randf_range(7.0, 12.0)
			var bh := rng.randf_range(24.0, 38.0)
			c.draw_rect(Rect2(bx, by + 40.0 - bh, bw, bh), Color.from_hsv(rng.randf_range(0.0, 1.0), 0.3, rng.randf_range(0.5, 0.75)))
			bx += bw + 1.5
	# lampadaire
	c.draw_line(Vector2(1340.0, floor_y), Vector2(1340.0, 470.0), Color("3d2a1a"), 5.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(1316.0, 476.0), Vector2(1364.0, 476.0), Vector2(1354.0, 440.0), Vector2(1326.0, 440.0)]), Color("f0d9a0"))
	# tapis du salon
	DrawUtil.rrect(c, Rect2(1400.0, floor_y - 5.0, 420.0, 6.0), Color("2f6f6a"), 3.0)


func _draw_door(c: Node2D) -> void:
	var open := door_open
	var top := 440.0
	# encadrement en arc
	c.draw_rect(Rect2(DOOR_X - 8.0, top - 12.0, 50.0, 12.0), Color("d9cdb5"))
	# lumière du dehors, visible dans l'embrasure quand la porte s'ouvre
	if open > 0.01:
		DrawUtil.hgrad(c, Rect2(DOOR_X, top, 40.0, GROUND - top), Color(1.0, 0.86, 0.6, 0.5 * open), Color(1.0, 0.9, 0.7, 0.85 * open))
	# battant : vu de côté, il se replie en s'ouvrant
	var w := lerpf(32.0, 4.0, open)
	var leaf := Rect2(DOOR_X + 38.0 - w, top, w, GROUND - top)
	c.draw_rect(leaf, Color("7a5638"))
	c.draw_rect(leaf, Color("3d2a1a"), false, 3.0)
	if open < 0.5:
		c.draw_circle(Vector2(DOOR_X + 8.0, top + 96.0), 4.0, Color("e9c46a"))


func draw_light(c: Node2D) -> void:
	# Rayon de soleil de la fenêtre, filets de lumière sous la porte, halo de l'aube
	var flicker := 0.9 + 0.1 * sin(_t * 0.9)
	var beam := PackedVector2Array([Vector2(474.0, 182.0), Vector2(582.0, 182.0), Vector2(440.0, UP_Y), Vector2(212.0, UP_Y)])
	var cols := PackedColorArray([Color(1.0, 0.86, 0.55, 0.20 * flicker), Color(1.0, 0.86, 0.55, 0.20 * flicker), Color(1.0, 0.86, 0.55, 0.05), Color(1.0, 0.86, 0.55, 0.05)])
	c.draw_polygon(beam, cols)
	# la porte laisse filtrer une lumière dorée : elle attire le regard avant même d'être ouverte
	var pulse := 0.5 + 0.5 * sin(_t * 1.6)
	var door_light := 0.30 + 0.25 * pulse
	if door_open > 0.01:
		door_light = 0.55 * door_open + 0.15
		var spill := PackedVector2Array([Vector2(DOOR_X, 440.0), Vector2(DOOR_X, GROUND), Vector2(1560.0, GROUND), Vector2(1660.0, 470.0)])
		var sc := PackedColorArray([Color(1.0, 0.88, 0.62, 0.35 * door_open), Color(1.0, 0.88, 0.62, 0.35 * door_open), Color(1.0, 0.88, 0.62, 0.0), Color(1.0, 0.88, 0.62, 0.0)])
		c.draw_polygon(spill, sc)
	DrawUtil.glow(c, Vector2(DOOR_X + 20.0, 540.0), 160.0, Color(1.0, 0.86, 0.55, door_light * 0.6))
