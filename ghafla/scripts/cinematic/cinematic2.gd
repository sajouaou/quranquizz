extends "res://scripts/cinematic/cinematic.gd"
## Cinématique du chapitre 2 (toujours un rêve). L'homme se retrouve dans sa chambre d'enfant, un soir : il se voit petit,
## absorbé par ses jeux, pendant que ses parents l'appellent (à la prière, puis pour un petit service) ; il continue à jouer.
## Il est là en spectateur (silhouette transparente), sans visage comme tous les autres. À la fin, la page de Luqman apparaît.
## Histoire fictive ; personne n'est ridiculisé : l'enfant est un enfant, les parents sont doux, c'est l'adulte qui se regarde.

const KID_SIT := {"hip": Vector2(0, -30), "body_rot": 0.16, "head_tilt": 0.30, "hand_f": Vector2(30, 34), "hand_b": Vector2(24, 36), "skirt": 0.0, "foot_f": Vector2(72, -2), "foot_b": Vector2(56, -2)}
const KID_REACH := {"hand_f": Vector2(40, 22), "hand_b": Vector2(24, 34), "body_rot": 0.38}
const KID_STACK := {"hand_f": Vector2(24, 44), "hand_b": Vector2(18, 40), "body_rot": 0.22}

var rig_m: Node2D  # la mère
var rig_g: Node2D  # l'adulte, en spectateur
var toys: Node2D
var _extra_ready: bool = false


class Toys:
	extends Node2D
	const P := preload("res://scripts/core/palette.gd")
	const DrawUtil := preload("res://scripts/core/draw_util.gd")
	## Les jouets de l'enfant : des cubes de bois empilés en pyramide et une balle, posés sur le plancher, et la page
	## de Luqman qui apparaît à la fin. Chaque cube a une face, un dessus et un côté (volume), et repose sur un autre
	## ou sur le sol : rien ne flotte. Les cubes apparaissent un à un, de bas en haut, à mesure que l'enfant les pose.
	const SIZE := 28.0
	const FLOOR := 560.0
	# [colonne (en demi-cubes), étage, couleur] : trois cubes au sol, deux dessus, un au sommet
	const CUBES := [[0, 0, "d95a4a"], [2, 0, "e8b84a"], [4, 0, "4a8fd9"], [1, 1, "5aa86a"], [3, 1, "b866c8"], [2, 2, "e8804a"]]
	const ORIGIN_X := 418.0
	var blocks: float = 1.0  # 0 : aucun cube ; 1 : la pyramide entière
	var page: float = 0.0
	var page_pos: Vector2 = Vector2(860, 430)
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _cube(x: float, y: float, col: Color, a: float) -> void:
		var d := 9.0  # profondeur visible du dessus et du côté
		draw_rect(Rect2(x, y - SIZE, SIZE, SIZE), Color(col, a))
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - SIZE), Vector2(x + SIZE, y - SIZE), Vector2(x + SIZE + d, y - SIZE - d * 0.6), Vector2(x + d, y - SIZE - d * 0.6)]), Color(col.lightened(0.28), a))
		draw_colored_polygon(PackedVector2Array([Vector2(x + SIZE, y - SIZE), Vector2(x + SIZE + d, y - SIZE - d * 0.6), Vector2(x + SIZE + d, y - d * 0.6), Vector2(x + SIZE, y)]), Color(col.darkened(0.3), a))
		draw_rect(Rect2(x, y - SIZE, SIZE, SIZE), Color(col.darkened(0.35), a * 0.6), false, 1.5)

	func _draw() -> void:
		if blocks > 0.01:
			# ombre de la pile sur le plancher
			draw_set_transform(Vector2(ORIGIN_X + SIZE * 1.6, FLOOR + 3.0), 0.0, Vector2(1.0, 0.14))
			DrawUtil.glow(self, Vector2.ZERO, 86.0, Color(0, 0, 0, 0.36 * minf(1.0, blocks * 2.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in range(CUBES.size()):
			var a := clampf(blocks * float(CUBES.size()) - float(i), 0.0, 1.0)
			if a <= 0.0:
				continue
			var c: Array = CUBES[i]
			var x := ORIGIN_X + float(c[0]) * (SIZE + 2.0) * 0.5
			var y := FLOOR - float(c[1]) * SIZE
			_cube(x, y - (1.0 - a) * 10.0, Color(str(c[2])), a)  # le cube descend se poser
		# la balle, à côté de la pile
		if blocks > 0.01:
			var b := Vector2(ORIGIN_X + 122.0, FLOOR - 12.0)
			var ba := minf(1.0, blocks * 3.0)
			draw_set_transform(b + Vector2(0, 14.0), 0.0, Vector2(1.0, 0.25))
			DrawUtil.glow(self, Vector2.ZERO, 22.0, Color(0, 0, 0, 0.4 * ba))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(b, 12.0, Color(0.86, 0.34, 0.27, ba))
			draw_arc(b, 12.0, 0.6, 2.4, 14, Color(0.55, 0.16, 0.14, ba), 2.5, true)
			draw_circle(b + Vector2(-4.0, -4.5), 3.5, Color(1.0, 0.8, 0.72, 0.8 * ba))
		if page > 0.01:
			var bob := sin(t * 2.0) * 6.0
			var c := page_pos + Vector2(0, bob)
			DrawUtil.glow(self, c, 150.0 * page, Color(1.0, 0.86, 0.5, 0.5 * page))
			DrawUtil.rrect(self, Rect2(c.x - 22.0, c.y - 30.0, 44, 60), Color(P.PARCHMENT, page), 6.0, Color(P.GOLD_DEEP, page), 2)
			draw_colored_polygon(DrawUtil.star(Vector2(c.x, c.y - 18.0), 6.0, 3.2, 8), Color(P.GOLD_DEEP, page))
			for i in range(6):
				draw_line(Vector2(c.x - 14.0, c.y - 6.0 + float(i) * 6.0), Vector2(c.x + 14.0, c.y - 6.0 + float(i) * 6.0), Color(0.35, 0.27, 0.12, 0.7 * page), 1.8, true)


func _setup_extra() -> void:
	if _extra_ready:
		return
	_extra_ready = true
	rig_m = Rig.new()
	rig_m.position = Vector2(1500.0, FLOOR_Y)
	rig_m.thobe_color = Color("2f6a5a")
	rig_m.veil = true
	stage.add_child(rig_m)
	rig_g = Rig.new()
	rig_g.position = Vector2(1500.0, FLOOR_Y)
	rig_g.modulate = Color(1, 1, 1, 0.0)
	stage.add_child(rig_g)
	toys = Toys.new()
	toys.blocks = 0.0
	stage.add_child(toys)
	stage.move_child(toys, shadows.get_index() + 1)  # derrière les personnages : l'enfant est assis devant ses cubes
	shadows.rigs = [rig_a, rig_b, rig_m, rig_g]


func run() -> void:
	_setup_extra()
	room.warm = 1.0
	room.night = 0.12
	room.dawn = 0.55
	room.lamp = 0.5
	room.ray = 0.0
	room.moon_t = 0.6
	room.book_on_stand = true
	blanket.visible = false
	for r in [rig_a, rig_b, rig_m, rig_g]:
		r.shade_color = Color(0.05, 0.04, 0.09)
		r.book = 0.0
		r.reset_pose()
	rig_a.shade = 0.30  # le père
	rig_a.position = Vector2(1500.0, FLOOR_Y)
	rig_m.shade = 0.30
	rig_b.scale = Vector2(0.62, 0.62)  # l'enfant
	rig_b.shade = 0.15
	rig_b.thobe_color = Color("5a8fd0")
	rig_b.position = Vector2(360.0, FLOOR_Y)
	rig_b.facing = 1
	rig_b.pose(KID_SIT, 0.01)
	rig_g.shade = 0.10
	toys.blocks = 0.5  # trois cubes déjà posés au sol quand la scène s'ouvre
	_fade.color = Color(0, 0, 0, 1)
	await _run_steps()
	_finish()


func _run_steps() -> void:
	_say(I18n.t("c2.another_evening"), 2.2)
	if not await _wait(3.0):
		return
	_tw(_fade, "color:a", 0.0, 1.6)
	_zoom(1.05, 40.0)
	if not await _wait(1.8):
		return
	# L'enfant joue : des cubes qu'il empile, avec application
	_tw(toys, "blocks", 1.0, 4.6)  # un cube de plus à chaque geste de l'enfant
	for i in range(3):
		rig_b.pose(KID_REACH, 0.7)
		if not await _wait(0.8):
			return
		rig_b.pose(KID_STACK, 0.7)
		if not await _wait(0.8):
			return
	_say(I18n.t("c2.long_ago"), 2.4)
	if not await _wait(2.4):
		return

	# L'adulte apparaît, en spectateur, près de la table
	rig_g.position = Vector2(900.0, FLOOR_Y)
	rig_g.facing = -1
	rig_g.pose(STAND, 0.01)
	_tw(rig_g, "modulate:a", 0.55, 1.6)
	if not await _wait(2.0):
		return
	rig_g.pose({"hand_f": Vector2(20, 26), "head_tilt": 0.12}, 1.0)
	_say(I18n.t("c2.remember"), 2.6)
	if not await _wait(2.8):
		return

	# Le père entre et l'appelle : c'est l'heure de la prière
	_say(I18n.t("c2.father"), 3.2)
	if not await _walk(rig_a, 640.0, 2.6, -1):
		return
	rig_b.pose({"head_tilt": 0.5, "body_rot": 0.32}, 0.6)
	if not await _wait(1.0):
		return
	rig_b.pose(KID_REACH, 0.5)  # il fait semblant de ne pas entendre
	if not await _wait(0.7):
		return
	rig_b.pose(KID_STACK, 0.5)
	if not await _wait(1.6):
		return
	_say(I18n.t("c2.child_more"), 2.2)
	if not await _wait(2.4):
		return
	rig_a.pose({"body_rot": 0.05, "head_tilt": 0.18, "hand_f": Vector2(14, 44)}, 1.0)
	if not await _wait(2.0):
		return

	# La mère arrive à son tour : un petit service
	_say(I18n.t("c2.mother"), 3.0)
	if not await _walk(rig_m, 560.0, 2.8, -1):
		return
	rig_b.pose(KID_REACH, 0.5)
	if not await _wait(0.9):
		return
	rig_b.pose(KID_STACK, 0.5)
	if not await _wait(1.8):
		return
	rig_m.pose({"head_tilt": 0.2, "hand_f": Vector2(12, 42)}, 1.0)
	if not await _wait(2.2):
		return
	# Ils repartent doucement, sans un mot de reproche
	if not await _walk(rig_m, 1500.0, 3.4, 1):
		return
	rig_a.facing = 1
	if not await _walk(rig_a, 1500.0, 3.4, 1):
		return

	# L'adulte a vu la scène ; le rêve se défait
	rig_g.pose({"head_tilt": 0.32, "hand_f": Vector2(18, 20), "hand_b": Vector2(14, 22)}, 1.2)
	_say(I18n.t("c2.it_was_me"), 2.6)
	if not await _wait(3.2):
		return
	_tw(toys, "blocks", 0.0, 2.0)
	_tw(rig_b, "modulate:a", 0.0, 2.0)
	_tw(room, "night", 0.7, 3.0)
	_tw(room, "lamp", 0.0, 2.5)
	if not await _wait(3.0):
		return

	# La page de Luqman apparaît
	toys.page_pos = Vector2(860.0, 430.0)
	_tw(toys, "page", 1.0, 2.4)
	Sfx.play("page", -8.0, 0.9)
	_say(I18n.t("c2.page"), 3.0)
	if not await _wait(3.6):
		return
	_say(I18n.t("c2.much_left"), 2.6)
	if not await _wait(2.6):
		return
	_tw(_fade, "color", Color(1.0, 0.94, 0.78, 1.0), 1.6)
	if not await _wait(1.8):
		return
